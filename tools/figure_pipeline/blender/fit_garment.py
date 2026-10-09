"""Hazir rig'li bir 3B giysiyi (Quaternius "Modular Character Outfits",
CC0) bizim MPFB bedenimize giydirir.

Giysi kendi bedenine (Quaternius'un temel karakteri, T-poz, ~1.82 m) gore
modellenmis; bizimki MPFB, A-poz, varyanta gore boy ve kilo. Uc adim:

1. Iskelet hizalama. Iki rig de UE adlandirmasini kullaniyor (pelvis,
   spine_0N, upperarm_l, calf_r ...). Giysinin her kemigi, MPFB'deki esinin
   dinlenme basina ve ucuna oturtuluyor - uzunluk dahil (human_body_render.
   bone_matrix: en kucuk donus, kemigin kendi ekseni boyunca olcek). Pozlanan
   giysi bakiliyor: artik MPFB'nin orantilarinda.
2. Sarma. Bir giysi bedeni sarmali: her giysi noktasi bedenin en yakin
   yuzeyinin en az `eps` disinda olmali. Iceride kalan noktalar disari itilir,
   itme miktari agin uzerinde yumusatilir (tek tek itilen noktalar kumas
   yerine diken uretir). eps katmana gore: ic giysi (pantolon) ince, dis giysi
   (tunik, omuzluk) kalin - ust uste binen iki giysi ayni yuzeye itilip
   birbirinin icinden gecmesin.
3. Agirlik. Kemik agirliklari bedenin en yakin yuzunden enterpole edilip
   giysiye kopyalanir, giysi MPFB rig'ine baglanir. Ayni agirlik = ayni
   deformasyon: dinlenmede sarilan beden yururken de sarili kalir. Bu, MPFB'nin
   "silme grubu" olmadan (2B bindirmede beden her zaman cizildigi icin) ten
   tasmasini kapatan sey (QUESTIONS #13).

Giysinin ten malzemeli yuzleri (Quaternius parcalari bazen ciplak el/bilek
tasiyor, MI_Regular_*) silinir: ten bizim bedenimizden gelir.
"""
import os

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

import fig_weights  # noqa: F401  (ayni dizinde; cagiranlar zaten yukluyor)

SKIN_MATERIAL_PREFIX = "MI_Regular"
SMOOTH_ITERATIONS = 12


# Uc kemikler: boylari bir sey olcmuyor, yalniz kemigin nereye cizildigi.
# Quaternius'un kafa kemigi 8.3 cm, MPFB'ninki 15.6 cm - gerilince kukuleta
# dikeyde 1.88 kat uzadi (kafanin iki kati yukseklikte sivri bir kule). Bu
# kemikler yalniz dondurulur, boyuna gerilmez.
NO_STRETCH = {"head", "hand_l", "hand_r", "ball_l", "ball_r"}


def bone_matrix(pose_bone, head, tail, stretch=True):
    """tools/human_body_render.py ile ayni: en kucuk donus + eksen boyu olcek
    (stretch False: yalniz donus)."""
    direction = tail - head
    rest_dir = pose_bone.bone.tail_local - pose_bone.bone.head_local
    if direction.length < 1e-6 or rest_dir.length < 1e-6:
        return pose_bone.matrix
    rotation = rest_dir.normalized().rotation_difference(direction.normalized())
    basis = rotation.to_matrix() @ pose_bone.bone.matrix_local.to_3x3()
    k = direction.length / pose_bone.bone.length if stretch and pose_bone.bone.length > 1e-6 else 1.0
    basis = (basis @ Matrix.Diagonal((1.0, k, 1.0))).to_4x4()
    basis.translation = head
    return basis


def import_piece(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    arm = next(o for o in new if o.type == "ARMATURE")
    meshes = [o for o in new if o.type == "MESH" and o.vertex_groups]
    for o in new:
        if o.type == "MESH" and not o.vertex_groups:  # Quaternius'un bos Icosphere'i
            bpy.data.objects.remove(o, do_unlink=True)
    return arm, meshes


def native_box(arm, meshes, rig):
    """Parcanin kendi bedenindeki sinir kutusu, iki iskeletin kalca yuksekligi
    oraninda olceklenmis - giydirilmis giysinin olmasi gereken boyut. Orani
    bozulmus bir giysiyi (gerilmis kafa kemigi kukuletayi 1.88 kat uzatmisti,
    kimse olcmedigi icin gorulmedi) qa/outfit_check.py bununla yakalar."""
    q = (arm.matrix_world @ next(b for b in arm.data.bones if b.name.lower() == "pelvis").head_local).z
    m = (rig.matrix_world @ rig.data.bones["pelvis"].head_local).z
    k = m / q if q > 1e-6 else 1.0
    lo, hi = [1e9] * 3, [-1e9] * 3
    for obj in meshes:
        for co in rc_evaluated(obj):
            for a in range(3):
                lo[a] = min(lo[a], co[a] * k)
                hi[a] = max(hi[a], co[a] * k)
    return lo, hi


def align_skeleton(arm, rig):
    """Giysi iskeletini MPFB'nin dinlenme kemiklerine oturtur (ust kemikten
    alta, cunku cocuk ebeveynin pozunu miras aliyor)."""
    target = {b.name.lower(): (rig.matrix_world @ b.head_local, rig.matrix_world @ b.tail_local)
              for b in rig.data.bones if b.use_deform}
    inv = arm.matrix_world.inverted()
    # Her kemik kendi boyuna gerildigi icin ebeveynin olcegi cocuga gecmemeli:
    # gerilmis bir ebeveynin altindaki cocugun dunya matrisi ancak kesme
    # (shear) ile ifade edilebilir, Blender onu tasiyamaz ve giysi uzar.
    for b in arm.data.bones:
        b.inherit_scale = "NONE"
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    order = []

    def walk(b):
        order.append(b.name)
        for c in b.children:
            walk(c)
    for b in arm.data.bones:
        if b.parent is None:
            walk(b)
    for name in order:
        key = name.lower()
        if key not in target:
            continue
        pb = arm.pose.bones[name]
        head, tail = target[key]
        bpy.context.view_layer.update()
        pb.matrix = bone_matrix(pb, inv @ head, inv @ tail, key not in NO_STRETCH)
    bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")


def bake_pose(mesh):
    """Armature degistiricisini uygular; nokta artik dunyada MPFB oraninda."""
    bpy.context.view_layer.objects.active = mesh
    for m in list(mesh.modifiers):
        if m.type == "ARMATURE":
            bpy.ops.object.modifier_apply(modifier=m.name)
    mw = mesh.matrix_world.copy()
    mesh.parent = None
    mesh.matrix_world = mw
    mesh.data.transform(mesh.matrix_world)
    mesh.matrix_world = Matrix.Identity(4)
    mesh.vertex_groups.clear()


def weld_seams(mesh, dist=1e-5):
    """UV dikisinde ikiye bolunmus koseleri birlestirir. Kaynak her dikiste
    ayni konumda iki kose tasiyor; sarma ve itme onlari ayri ayri oynatinca
    dikis aciliyordu (pantolonun yaninda bacak boyu beyaz bir cizgi). UV
    kose-yuz (loop) duzeyinde tutuldugu icin doku bozulmuyor."""
    bm = bmesh.new()
    bm.from_mesh(mesh.data)
    before = len(bm.verts)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=dist)
    after = len(bm.verts)
    bm.to_mesh(mesh.data)
    bm.free()
    mesh.data.update()
    return before - after


def _boundary_loops(bm):
    """Agin acik kenar halkalari: kenar listesi, cevre uzunlugu."""
    edges = [e for e in bm.edges if e.is_boundary]
    seen, loops = set(), []
    for e in edges:
        if e.index in seen:
            continue
        stack, loop = [e], []
        seen.add(e.index)
        while stack:
            cur = stack.pop()
            loop.append(cur)
            for v in cur.verts:
                for nb in v.link_edges:
                    if nb.is_boundary and nb.index not in seen:
                        seen.add(nb.index)
                        stack.append(nb)
        loops.append((loop, sum(x.calc_length() for x in loop)))
    return loops


def fill_holes(mesh, openings):
    """Kaynagin kesip attigi yuzeyleri kapatir. Quaternius ust giysinin
    altinda kalan kumasi silmis: korucu pantolonunun arkasinda belin
    altinda buyuk bir delik var (ceketin altinda kalsin diye), koylu
    pantolonunun kasiginda kucuk delikler. Bizde her kalem tek basina da
    giyilebilir. En uzun `openings` halka giysinin gercek agizlaridir (bel,
    iki paca; gomlekte boyun, bel, iki kol); gerisi kapatilir, yeni yuz
    bedenin kivrimina oturabilsin diye bolunur, UV'si kenardaki koselerin
    kendi UV'sinden alinir. Doner: kapatilan delik sayisi."""
    bm = bmesh.new()
    bm.from_mesh(mesh.data)
    bm.edges.ensure_lookup_table()
    loops = sorted(_boundary_loops(bm), key=lambda x: -x[1])
    holes = loops[openings:]
    if not holes:
        bm.free()
        return 0
    uv = bm.loops.layers.uv.active
    before = set(bm.faces)
    for loop, _len in holes:
        bmesh.ops.holes_fill(bm, edges=loop, sides=0)
    new = [f for f in bm.faces if f not in before]
    tri = bmesh.ops.triangulate(bm, faces=new)["faces"]
    sub = bmesh.ops.subdivide_edges(bm, edges=list({e for f in tri for e in f.edges}), cuts=2,
                                    use_grid_fill=True)
    new = [f for f in bm.faces if f not in before]
    if uv is not None:
        for f in new:
            for lp in f.loops:
                src = [o for o in lp.vert.link_loops if o.face in before]
                if src:
                    lp[uv].uv = src[0][uv].uv
                else:
                    # ic kose: en yakin eski kosenin UV'si
                    best = min((o for o in bm.verts if o.link_loops and any(x.face in before for x in o.link_loops)),
                               key=lambda o: (o.co - lp.vert.co).length_squared, default=None)
                    if best is not None:
                        lp[uv].uv = next(x for x in best.link_loops if x.face in before)[uv].uv
    bm.to_mesh(mesh.data)
    bm.free()
    mesh.data.update()
    return len(holes)


def drop_skin_faces(mesh):
    skin = {i for i, m in enumerate(mesh.data.materials) if m and m.name.startswith(SKIN_MATERIAL_PREFIX)}
    if not skin:
        return
    bm = bmesh.new()
    bm.from_mesh(mesh.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index in skin], context="FACES")
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bm.to_mesh(mesh.data)
    bm.free()


def body_bvh(body):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(dg)
    me = ev.to_mesh()
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.transform(body.matrix_world)
    bm.normal_update()
    tree = BVHTree.FromBMesh(bm)
    ev.to_mesh_clear()
    return tree, bm


def wrap(mesh, tree, eps):
    """Iceride ya da yuzeye eps'ten yakin noktalari disari it, itmeyi agda
    yumusat, sonra kisiti bir kez daha uygula (yumusatma bir noktayi geri
    iceri cekmis olabilir). Doner: itilen nokta sayisi."""
    verts = mesh.data.vertices
    n = len(verts)
    nbr = [[] for _ in range(n)]
    for e in mesh.data.edges:
        a, b = e.vertices
        nbr[a].append(b)
        nbr[b].append(a)

    def needed():
        d = [Vector() for _ in range(n)]
        hit = 0
        for i, v in enumerate(verts):
            loc, normal, _f, _dist = tree.find_nearest(v.co)
            if loc is None:
                continue
            s = (v.co - loc).dot(normal)
            if s < eps:
                d[i] = normal * (eps - s)
                hit += 1
        return d, hit

    disp, pushed = needed()
    for _ in range(SMOOTH_ITERATIONS):
        nxt = []
        for i in range(n):
            if not nbr[i]:
                nxt.append(disp[i])
                continue
            avg = sum((disp[j] for j in nbr[i]), Vector()) / len(nbr[i])
            # en az kendi ihtiyaci kadar: yumusatma bir noktayi iceri sokmasin
            nxt.append(avg if avg.length > disp[i].length else disp[i])
        disp = nxt
    for i, v in enumerate(verts):
        v.co += disp[i]
    disp, _ = needed()
    for i, v in enumerate(verts):
        v.co += disp[i]
    mesh.data.update()
    return pushed


SLEEVE_OVER = 0.01  # m; bel seridi belin bu kadar ustune cikar
SLEEVE_ARM_LIMIT = 0.05  # kol/el agirligi bundan fazla olan beden yuzu alinmaz


def waist_sleeve(mesh, body, rig, waist_bone, eps, hip_bone="pelvis"):
    """Pantolona kalcadan bele kadar bir bel seridi ekler. Quaternius'un
    pantolonlari dusuk belli; bizim bedende ust kenar 1.04 m'de, belin en
    dar yeri (spine_02) 1.09 m'de - kalcanin ustu acik kaliyordu (oyuncu
    gordu). Pantolonu yukari germek denendi ve birakildi: korucu
    pantolonunun arkasi bele sarilan ince bir bant ile kalcayi saran bir
    panelden olusuyor, germek ikisini ayirip arada oyuk birakti; her yeni
    pantolon baska bir topoloji getirir. Bunun yerine bedenin kendi yuzeyi,
    kalcadan bele kadar, kumasin yarim mesafesinde bir serit olarak
    cikariliyor: pantolon olan yerde onun altinda kaliyor, olmayan yerde
    (bel, arka) beli dolduruyor. UV'si en yakin pantolon kosesinden: serit
    pantolonun kendi dokusunu tasir. Doner: eklenen yuz sayisi."""
    mw = rig.matrix_world
    z0 = (mw @ rig.data.bones[hip_bone].head_local).z
    z1 = (mw @ rig.data.bones[waist_bone].head_local).z + SLEEVE_OVER
    dg = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(dg)
    me = ev.to_mesh()
    arm_groups = {g.index for g in body.vertex_groups
                  if g.name.lower().startswith(("upperarm", "lowerarm", "hand", "thumb", "index",
                                                "middle", "ring", "pinky"))}
    co = [body.matrix_world @ v.co for v in me.vertices]
    nrm = [(body.matrix_world.to_3x3() @ v.normal).normalized() for v in me.vertices]
    armw = [sum(g.weight for g in v.groups if g.group in arm_groups) for v in me.vertices]
    faces = [list(p.vertices) for p in me.polygons
             if all(z0 <= co[i].z <= z1 and armw[i] <= SLEEVE_ARM_LIMIT for i in p.vertices)]
    ev.to_mesh_clear()
    if not faces:
        return 0
    # Doku: serit yuz basina TEK bir kumas noktasinin UV'sini alir - kose
    # kose en yakin UV dikis/kemer adalarina dusup acik renkli yamalar
    # birakiyordu. Kumas noktasi pantolonun govdesinden (ust kenarin en az
    # 3 cm alti), kenar detaylarindan degil.
    uvl = mesh.data.uv_layers.active
    puv = {}
    if uvl is not None:
        for poly in mesh.data.polygons:
            for li in poly.loop_indices:
                puv.setdefault(mesh.data.loops[li].vertex_index, uvl.data[li].uv.copy())
    ptop = max((mesh.matrix_world @ v.co).z for v in mesh.data.vertices)
    cloth = [v for v in mesh.data.vertices if z0 - 0.08 <= (mesh.matrix_world @ v.co).z <= ptop - 0.03]
    kd = KDTree(max(1, len(cloth)))
    for v in cloth:
        kd.insert(mesh.matrix_world @ v.co, v.index)
    kd.balance()
    bm = bmesh.new()
    bm.from_mesh(mesh.data)
    uv = bm.loops.layers.uv.active
    inv = mesh.matrix_world.inverted()
    made = {}
    # Ust kenar belin hizasina duzlenir: govdenin ag satirlarini izleyen
    # kenar basamakliydi. Ust satirdaki kose z1'e cekilir (yuzeyde kalir).
    top_band = z1 - 0.02
    for f in faces:
        for i in f:
            if i not in made:
                p = co[i] + nrm[i] * (eps * 0.5)
                if co[i].z >= top_band:
                    p.z = z1
                made[i] = bm.verts.new(inv @ p)
    bm.verts.ensure_lookup_table()
    added = 0
    for f in faces:
        try:
            nf = bm.faces.new([made[i] for i in f])
        except ValueError:
            continue
        added += 1
        if uv is not None and cloth:
            _c, k, _d = kd.find(mesh.matrix_world @ nf.calc_center_median())
            if k in puv:
                for lp in nf.loops:
                    lp[uv].uv = puv[k]
    bm.to_mesh(mesh.data)
    bm.free()
    mesh.data.update()
    return added


HEAD_MARGIN = (0.025, 0.03, 0.035)  # m; kafa ile kukuleta arasi pay (yan, on-arka, tepe)


def snug_head(mesh, body, eps):
    """Kafaya giyilen kismi bizim kafanin olcusune indirir. Quaternius'un
    karakterleri stilize, kafalari buyuk: kukuletanin kafa kismi 30x33x38 cm,
    MPFB'nin kafasi 17x22x23 - kukuleta kafanin 10 cm ustune bir kule gibi
    cikiyordu (oyuncu gordu, hicbir olcu gormedi). Her nokta, altindaki beden
    noktasinin kafa agirligi kadar (yumusak gecis: pelerin yerinde kalir)
    kafanin merkezine dogru, eksen eksen olceklenir; sonra beden yeniden
    sarilir. Kafaya degmeyen giysiye dokunmaz. Doner: oynayan nokta sayisi."""
    gi = body.vertex_groups.get("head")
    if gi is None:
        return 0
    # Degerlendirilmis ag (maskeler yardimcilari dusuruyor): konum ve agirlik
    # ayni agdan, yoksa indeksler kayar.
    dg = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(dg)
    me = ev.to_mesh()
    bco = [body.matrix_world @ v.co for v in me.vertices]
    hw = [sum(g.weight for g in v.groups if g.group == gi.index) for v in me.vertices]
    ev.to_mesh_clear()
    head = [c for c, w in zip(bco, hw) if w >= 0.5]
    kd = KDTree(len(bco))
    for k, c in enumerate(bco):
        kd.insert(c, k)
    kd.balance()
    wts = []
    for v in mesh.data.vertices:
        _c, k, _d = kd.find(v.co)
        wts.append(hw[k])
    cap = [v.co.copy() for v, w in zip(mesh.data.vertices, wts) if w >= 0.5]
    if not head or len(cap) < 20:
        return 0
    lo = [min(c[a] for c in head) for a in range(3)]
    hi = [max(c[a] for c in head) for a in range(3)]
    centre = Vector([(lo[a] + hi[a]) * 0.5 for a in range(3)])
    glo = [min(c[a] for c in cap) for a in range(3)]
    ghi = [max(c[a] for c in cap) for a in range(3)]
    # Her eksenin iki yonu ayri: kukuletanin fazlasi tepede, altta degil -
    # merkeze gore simetrik olcek tepeyi ancak %4 indiriyordu.
    pos, neg = [], []
    for a in range(3):
        c = centre[a]
        pos.append(min(1.0, (hi[a] - c + HEAD_MARGIN[a]) / (ghi[a] - c)) if ghi[a] - c > 1e-6 else 1.0)
        neg.append(min(1.0, (c - lo[a] + HEAD_MARGIN[a]) / (c - glo[a])) if c - glo[a] > 1e-6 else 1.0)
    moved = 0
    for v, w in zip(mesh.data.vertices, wts):
        if w <= 0.0:
            continue
        d = v.co - centre
        k = [pos[a] if d[a] > 0 else neg[a] for a in range(3)]
        v.co = centre + Vector([d[a] * (1.0 + (k[a] - 1.0) * w) for a in range(3)])
        moved += 1
    mesh.data.update()
    return moved


def mesh_bvh(obj):
    """Nesnenin degerlendirilmis (pozlanmis) agi, dunyada."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    me = ev.to_mesh()
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.transform(obj.matrix_world)
    tree = BVHTree.FromBMesh(bm)
    ev.to_mesh_clear()
    bm.free()
    return tree


REACH = 0.08  # bir giysinin bedenden en fazla bu kadar uzakta bir alt katmani olabilir


def heights_over(p, n, trees, reach=REACH):
    """Beden yuzeyindeki p noktasindan normal boyunca, alt giysilerin en dis
    yuzeyinin yuksekligi (yoksa None). Ince kabuk iki kez kesilebilir; en
    uzaktaki sayilir."""
    best = None
    for tree in trees:
        t0 = 0.0
        while t0 < reach:
            hit, _nrm, _f, d = tree.ray_cast(p + n * (t0 + 1e-4), n, reach - t0)
            if hit is None:
                break
            t0 += 1e-4 + d
            best = t0 if best is None else max(best, t0)
    return best


def inner_heights(body_tree, inner):
    """Alt giysilerin her noktasi icin (altindaki beden noktasi, yuksekligi).
    KD-agaci beden noktalari uzerinde: ust giysinin bir noktasi kendi altindaki
    beden noktasinin cevresindeki alt giysi noktalarini bulabilsin."""
    pts, hs = [], []
    for obj in inner:
        for co in rc_evaluated(obj):
            loc, nrm, _f, _d = body_tree.find_nearest(co)
            if loc is None:
                continue
            pts.append(loc)
            hs.append((co - loc).dot(nrm))
    kd = KDTree(len(pts))
    for k, p in enumerate(pts):
        kd.insert(p, k)
    kd.balance()
    return kd, hs


def rc_evaluated(obj):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    me = ev.to_mesh()
    out = [obj.matrix_world @ v.co for v in me.vertices]
    ev.to_mesh_clear()
    return out


def layer_over(mesh, body_tree, inner, gap):
    """Dis giysiyi alt giysilerin ustune oturtur: her noktasi, altindaki beden
    noktasinin `radius` cevresindeki her alt giysi noktasindan en az `gap`
    daha disarida olmali. Yalniz bedene gore sarmak yetmiyordu - her kalem
    bedeni sariyordu ama pantolonun beli gomlegin icinden disari tasiyordu.
    Tek noktadan olcmek de yetmedi: yelegin agi gomleginkinden seyrek, iki
    kosesi gomlegin ustunde olsa da aradaki yuzden gomlegin ince detayi
    cikiyordu (qa/outfit_check.py, %4.8). Yaricap bu yuzden dis giysinin kendi
    kenar boyunda. Itme wrap() gibi agda yumusatilir. Doner: itilen."""
    if not inner:
        return 0
    kd, hs = inner_heights(body_tree, inner)
    verts = mesh.data.vertices
    n = len(verts)
    nbr = [[] for _ in range(n)]
    lens = []
    for e in mesh.data.edges:
        a, b = e.vertices
        nbr[a].append(b)
        nbr[b].append(a)
        lens.append((verts[a].co - verts[b].co).length)
    lens.sort()
    radius = max(0.01, lens[int(len(lens) * 0.9)] if lens else 0.01)

    def needed():
        d = [Vector() for _ in range(n)]
        hit = 0
        for i, v in enumerate(verts):
            loc, normal, _f, _dist = body_tree.find_nearest(v.co)
            if loc is None:
                continue
            near = kd.find_range(loc, radius)
            if not near:
                continue
            under = max(hs[k] for _co, k, _d in near)
            s = (v.co - loc).dot(normal)
            if s < under + gap:
                d[i] = normal * (under + gap - s)
                hit += 1
        return d, hit

    disp, pushed = needed()
    for _ in range(SMOOTH_ITERATIONS):
        nxt = []
        for i in range(n):
            if not nbr[i]:
                nxt.append(disp[i])
                continue
            avg = sum((disp[j] for j in nbr[i]), Vector()) / len(nbr[i])
            nxt.append(avg if avg.length > disp[i].length else disp[i])
        disp = nxt
    for i, v in enumerate(verts):
        v.co += disp[i]
    disp, _ = needed()
    for i, v in enumerate(verts):
        v.co += disp[i]
    mesh.data.update()
    return pushed


RESOLVE_ROUNDS = 6
MIN_FLOOR = 0.004  # m; alt giysi geri cekilirken bedenin bu kadar ustunde kalir
RESOLVE_REACH = 0.03


def _pokes(mesh, body_tree, inner):
    """(alt giysi, kose indeksi, dunya konumu, normal, dis giysiye uzaklik)
    - dis giysinin disinda kalan alt giysi koseleri (qa/outfit_check.poke'un
    kurali: bedene dogru gidince bedenden once dis giysiye carpiyor)."""
    bm = bmesh.new()
    bm.from_mesh(mesh.data)
    bm.transform(mesh.matrix_world)
    bm.faces.ensure_lookup_table()
    otree = BVHTree.FromBMesh(bm)
    out = []
    for obj in inner:
        for k, co in enumerate(rc_evaluated(obj)):
            loc, nrm, _f, _d = body_tree.find_nearest(co)
            if loc is None:
                continue
            start = co + nrm * 1e-4
            bhit, _n, _i, bd = body_tree.ray_cast(start, -nrm, 1.0)
            ohit, _n2, fi, od = otree.ray_cast(start, -nrm, RESOLVE_REACH)
            if ohit is not None and (bhit is None or od < bd):
                out.append((obj, k, co, nrm, od, [v.index for v in bm.faces[fi].verts], loc))
    bm.free()
    return out


def resolve_pokes(mesh, body_tree, inner, gap, floor):
    """Ikinci asama, qa/outfit_check.poke ile AYNI kural. Once dis giysi
    itilir: carpilan yuzun koseleri alt giysi noktasinin `gap` disina. Bu
    birkac turda cogunu cozuyor ama her seyi degil - kukuletanin boyun kismi
    yelegin yakasinin altina giren bir astar tasiyor; astari disari itmek
    onu dis kabuga carptiriyor ve tur tur yakinsamiyordu (dinlenmede 141
    ortulen yaka noktasinin 22'si disarida kaldi). Kalanlar icin ters yon:
    alt giysi noktasi dis giysinin `gap` altina cekilir, ama bedenden `floor`
    kadar yukarida kalir. Doner: tasinan kose sayisi."""
    if not inner:
        return 0
    total = 0
    for _ in range(RESOLVE_ROUNDS):
        found = _pokes(mesh, body_tree, inner)
        if not found:
            return total
        push = {}
        inv = mesh.matrix_world.inverted().to_3x3()
        for _obj, _k, _co, nrm, od, fverts, _loc in found:
            need = inv @ (nrm * (od + gap + 1e-4))
            for i in fverts:
                cur = push.get(i)
                if cur is None or need.length > cur.length:
                    push[i] = need
        for i, d in push.items():
            mesh.data.vertices[i].co += d
        mesh.data.update()
        total += len(push)
    for _ in range(RESOLVE_ROUNDS):
        moved = _pull_or_hide(mesh, body_tree, inner, gap, floor)
        if not moved:
            break
        total += moved
    return total


def _pull_or_hide(mesh, body_tree, inner, gap, floor):
    total = 0
    hidden = set()
    for obj, k, co, nrm, od, fverts, loc in _pokes(mesh, body_tree, inner):
        target = co - nrm * (od + gap)
        if (target - loc).dot(nrm) < floor:
            # Alt giysi bedene yapisik, daha iceri inemez: dis giysinin
            # buradaki yuzu (kukuletanin boyun astari) alt giysinin altinda
            # kaliyor - o yuz siliniyor, zaten hep ortulu.
            hidden.add(tuple(sorted(fverts)))
            continue
        obj.data.vertices[k].co = obj.matrix_world.inverted() @ target
        obj.data.update()
        total += 1
    if hidden:
        bm = bmesh.new()
        bm.from_mesh(mesh.data)
        kill = [f for f in bm.faces if tuple(sorted(v.index for v in f.verts)) in hidden]
        bmesh.ops.delete(bm, geom=kill, context="FACES")
        bm.to_mesh(mesh.data)
        bm.free()
        mesh.data.update()
        total += len(kill)
    return total


BODY_REACH = 0.05  # m; bu kadar yakindaki kumas bedeni ortmeli
BODY_DEPTH = 0.03  # m; bedenin icinden bu kadar asagidan bakilir


COVER_MAX_PUSH = 0.03  # m; bir kosenin toplam en fazla itilmesi


def cover_body(mesh, body, body_tree, eps, keep_below=None):
    """Bedenin kumasin icinden cikmasini kapatir. wrap() kumasin KOSELERINI
    bedenin disinda tutuyor, ama seyrek bir kumas yuzunun ortasindan bedenin
    bir kivrimi (uyluk, kasik, gogus) disari cikabiliyordu - onden bakinca
    pantolonda ve gomlekte beyaz delikler vardi (oyunda giysi bedenin ustune
    cizildigi icin gorunmuyordu). Kural: kumasa yakin her beden noktasinin
    altindan (bedenin icinden) disari bakilinca once beden yuzeyine, sonra
    kumasa varilmali; kumasa once variliyorsa carpilan yuzun koseleri
    disari itilir. Itme wrap() gibi agda yumusatilir ve kose basina
    COVER_MAX_PUSH ile sinirli: ilk surum yuzun koselerini tur tur
    sinirsiz itiyordu ve korucu pantolonunun ice kivrik bel bandi kanat
    gibi acilip arkada delik birakti. keep_below: bu yukseklikten asagidaki
    koseler yukari itilmez (ayakkabi tabani). Doner: itilen kose sayisi."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(dg)
    me = ev.to_mesh()
    pts = [body.matrix_world @ v.co for v in me.vertices]
    ev.to_mesh_clear()
    verts = mesh.data.vertices
    n = len(verts)
    nbr = [[] for _ in range(n)]
    for e in mesh.data.edges:
        a, b = e.vertices
        nbr[a].append(b)
        nbr[b].append(a)
    spent = [0.0] * n
    total = 0
    for _ in range(RESOLVE_ROUNDS):
        bm = bmesh.new()
        bm.from_mesh(mesh.data)
        bm.faces.ensure_lookup_table()
        gtree = BVHTree.FromBMesh(bm)
        disp = [Vector() for _ in range(n)]
        hit_any = False
        for co in pts:
            g = gtree.find_nearest(co)
            if g[0] is None or g[3] > BODY_REACH:
                continue
            loc, nrm, _f, _d = body_tree.find_nearest(co)
            if loc is None:
                continue
            # Bedenin icinde kal: ince bir yerde (parmaklar) 3 cm asagisi
            # bedenin obur yuzunun disina, tabanin altina dusuyordu; oradan
            # bakinca ilk carpilan ayakkabinin tabaniydi ve taban yukari,
            # ayagin icine itiliyordu - beden alttan cikti.
            back = body_tree.ray_cast(loc - nrm * 1e-4, -nrm, BODY_DEPTH * 2.0)
            depth = BODY_DEPTH if back[0] is None else min(BODY_DEPTH, back[3] * 0.5)
            start = loc - nrm * depth
            hit, _n, fi, gd = gtree.ray_cast(start, nrm, depth + BODY_REACH)
            if hit is None or gd >= depth + eps:
                continue
            need = nrm * (depth + eps - gd + 1e-4)
            for v in bm.faces[fi].verts:
                if need.length > disp[v.index].length:
                    disp[v.index] = need
                    hit_any = True
        bm.free()
        if not hit_any:
            break
        for _s in range(SMOOTH_ITERATIONS // 2):
            nxt = []
            for i in range(n):
                if not nbr[i]:
                    nxt.append(disp[i])
                    continue
                avg = sum((disp[j] for j in nbr[i]), Vector()) / len(nbr[i])
                nxt.append(avg if avg.length > disp[i].length else disp[i])
            disp = nxt
        moved = 0
        for i in range(n):
            room = COVER_MAX_PUSH - spent[i]
            if room <= 0.0 or disp[i].length < 1e-7:
                continue
            d = disp[i] if disp[i].length <= room else disp[i].normalized() * room
            if keep_below is not None and verts[i].co.z < keep_below and d.z > 0.0:
                # tabanin alti: burun kapaginin buyuk yuzleri parmaklarin ustune
                # itilirken alt koseleri de kaldiriyordu, taban delindi.
                d = Vector((d.x, d.y, 0.0))
            verts[i].co += d
            spent[i] += d.length
            moved += 1
        mesh.data.update()
        total += moved
        if not moved:
            break
    return total


def transfer_weights(mesh, body, rig):
    for vg in body.vertex_groups:
        if vg.name not in mesh.vertex_groups:
            mesh.vertex_groups.new(name=vg.name)
    bpy.context.view_layer.objects.active = mesh
    dt = mesh.modifiers.new("dt", "DATA_TRANSFER")
    dt.object = body
    dt.use_vert_data = True
    dt.data_types_verts = {"VGROUP_WEIGHTS"}
    dt.vert_mapping = "POLYINTERP_NEAREST"
    dt.layers_vgroup_select_src = "ALL"
    dt.layers_vgroup_select_dst = "NAME"
    bpy.ops.object.modifier_apply(modifier=dt.name)
    mesh.parent = rig
    mesh.matrix_parent_inverse = rig.matrix_world.inverted()
    am = mesh.modifiers.new("rig", "ARMATURE")
    am.object = rig


INHERIT_REACH = 0.04  # m; alt giysi bundan uzaksa agirlik bedenden kalir


def inherit_weights(mesh, inner):
    """Dis giysinin altinda bir alt giysi varsa agirliklarini ondan alir.
    Bedenden aktarmak dinlenmede dogruydu ama yururken degil: kivrimli
    yerlerde (omuz, koltuk alti) dis giysinin en yakin beden noktasi alttaki
    giysininkinden farkli, iki giysi farkli bukuluyor ve gomlek yelegin
    icinden cikiyordu (olculdu: dinlenmede 9 nokta, yuruyuste %4.8)."""
    if not inner:
        return 0
    src = []
    for obj in inner:
        names = {g.index: g.name for g in obj.vertex_groups}
        coords = rc_evaluated(obj)
        for v, co in zip(obj.data.vertices, coords):
            src.append((co, [(names[g.group], g.weight) for g in v.groups if g.weight > 0.0]))
    kd = KDTree(len(src))
    for k, (co, _w) in enumerate(src):
        kd.insert(co, k)
    kd.balance()
    groups = {}
    taken = 0
    for v in mesh.data.vertices:
        co, k, dist = kd.find(mesh.matrix_world @ v.co)
        if co is None or dist > INHERIT_REACH:
            continue
        # Once indeksler: kaldirmak v.groups'u yerinde degistiriyor ve eleman
        # referanslari kayiyordu - eski govde agirligi yarim kaliyordu
        # (omuzda upperarm 0.99 + spine_03 0.78, olculdu).
        for gi in [g.group for g in v.groups]:
            mesh.vertex_groups[gi].remove([v.index])
        for name, w in src[k][1]:
            if name not in groups:
                groups[name] = mesh.vertex_groups.get(name) or mesh.vertex_groups.new(name=name)
            groups[name].add([v.index], w, "REPLACE")
        taken += 1
    return taken


def _masks(body, on):
    """MPFB bedeni yardimci aglar tasiyor (etek, tayt, eklem yardimcilari) ve
    MASK degistiricisiyle gizliyor; render betikleri olcum icin bu maskeyi
    gorunumde kapatiyor. Sarma ve agirlik aktarimi yardimcilari gormemeli:
    gorunce pantolon bacaklarin arasindaki etek yardimcisina sarilip
    sisiyordu (olculdu)."""
    prev = []
    for m in body.modifiers:
        if m.type == "MASK":
            prev.append((m, m.show_viewport))
            m.show_viewport = on
    bpy.context.view_layer.update()
    return prev


SOLE_REACH = 0.07  # m; bir koseyi o ayaga sayan yan uzaklik
HEEL_ROOM = 0.01  # m; ayakkabinin topugu bedenin topugunun bu kadar arkasina kadar uzar
SOLE_STATION = 0.02  # m; taban inisi topuktan buruna bu araliklarla olculur
SOLE_MAX_RISE = 0.03  # m; zeminin bundan yukarisindaki alt yuz taban sayilmaz


def _smooth(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3.0 - 2.0 * t)


def add_sole(mesh, body, rig, sole, heel):
    """Ayakkabiya duz, kalin bir taban verir; wrap'tan once calisir.
    Hizalanan kaynak ayakkabinin alti MPFB ayaginin altina oturmuyordu:
    kaynagin burnu yukari kalkik, MPFB'nin ayagi duz - burunda beden alttan
    cikiyor, wrap da burnu disari itip buruşturuyordu; taban corap gibi
    okunuyordu. Her ayakta zemin duz bir duzlem (bedenin tabani). Ayak izinin
    her noktasindan alttan yukari bakilip ayakkabinin alt yuzu bulunur
    (kose degil yuz: dusuk poligonlu tabanda koseler 2 cm'den seyrek);
    topuktan buruna her SOLE_STATION'da bunlarin en yuksegi, o duzlemin
    `sole` kadar (topukta bir de `heel` kadar) altina inecek kadar asagi
    kaydirilir. Istasyonlar arasi dogrusal ve yumusatilmis: tek bir uc
    burnu sisirip palyaco ayakkabisi yapiyordu, tek bir en alt kose de
    ortayi "yeterince asagida" gosterip parmaklari tabandan cikariyordu.
    Kayma ayak bileginde sifir, zeminde tam: ayakkabi bukulmeden kesilir,
    konc yerinde kalir; hicbir kose yukari cekilmez. Topuk da bedenin
    topugunun arkasina kadar uzar. Doner: islenen kose sayisi."""
    body_pts = rc_evaluated(body)
    verts = mesh.data.vertices
    feet = []
    for side in ("l", "r"):
        ankle = rig.matrix_world @ rig.data.bones["foot_" + side].head_local
        zs = sorted(c.z for c in body_pts if c.z < 0.06 and abs(c.x - ankle.x) < SOLE_REACH)
        feet.append((ankle, zs[len(zs) // 50] if zs else 0.0))

    def foot_of(co):
        return min(range(len(feet)), key=lambda i: abs(feet[i][0].x - co.x))

    # 1) Topuk boyu: iri bedenlerde bedenin topugu kaynak ayakkabinin
    # topugundan ~3 cm geride, cover_body'nin itme siniri bunu kapatamiyor ve
    # topuk arkadan cikiyordu. Bilegin arkasi gerekirse uzatilir.
    for i, (ankle, floor) in enumerate(feet):
        mine = [v for v in verts if foot_of(v.co) == i and v.co.z < ankle.z
                and abs(v.co.x - ankle.x) < SOLE_REACH]
        body_back = max((c.y for c in body_pts if ankle.z > c.z > floor + 0.005
                         and abs(c.x - ankle.x) < SOLE_REACH), default=ankle.y)
        shoe_back = max((v.co.y for v in mine), default=ankle.y)
        if shoe_back - ankle.y < 1e-3:
            continue
        stretch = max(1.0, (body_back + HEEL_ROOM - ankle.y) / (shoe_back - ankle.y))
        for v in verts:
            if foot_of(v.co) != i or v.co.y <= ankle.y or abs(v.co.x - ankle.x) > SOLE_REACH * 1.5:
                continue
            # topuk duvari bilegin hemen altina kadar butun uzar, ustunde soner
            ws = _smooth((ankle.z + 0.02 - v.co.z) / 0.04)
            v.co.y = ankle.y + (v.co.y - ankle.y) * (1.0 + (stretch - 1.0) * ws)
    mesh.data.update()

    # 2) Taban: istasyon istasyon alt yuz, zeminin altina.
    tree = mesh_bvh(mesh)
    profiles = []
    for ankle, floor in feet:
        prints = [c for c in body_pts if c.z < floor + 0.006 and abs(c.x - ankle.x) < SOLE_REACH]
        stations = {}
        for c in prints:
            hit = tree.ray_cast(Vector((c.x, c.y, floor - 0.2)), Vector((0.0, 0.0, 1.0)), 0.2 + SOLE_MAX_RISE)
            if hit[0] is None:  # alt yuz zeminin SOLE_MAX_RISE ustunde degil: konc ya da delik
                continue
            k = round(c.y / SOLE_STATION)
            stations[k] = max(stations.get(k, -1.0), hit[0].z)
        need = {}
        for k, bottom in stations.items():
            h = _smooth((k * SOLE_STATION - (ankle.y - 0.02)) / 0.04)
            need[k] = max(0.0, bottom - (floor - sole - heel * h))
        keys = sorted(need)
        profiles.append((keys, {k: max(need[k], 0.5 * (need.get(k - 1, need[k]) + need.get(k + 1, need[k])))
                                for k in keys}))

    def drop_at(y, keys, prof):
        if not keys:
            return 0.0
        f = y / SOLE_STATION
        if f <= keys[0]:
            return prof[keys[0]]
        if f >= keys[-1]:
            return prof[keys[-1]]
        lo = max(k for k in keys if k <= f)
        hi = min(k for k in keys if k >= f)
        return prof[lo] if hi == lo else prof[lo] + (prof[hi] - prof[lo]) * (f - lo) / (hi - lo)

    moved = 0
    for v in verts:
        i = foot_of(v.co)
        ankle, floor = feet[i]
        if abs(v.co.x - ankle.x) > SOLE_REACH * 1.5 or v.co.z >= ankle.z:
            continue
        w = _smooth((ankle.z - v.co.z) / (ankle.z - floor))
        v.co.z -= w * drop_at(v.co.y, *profiles[i])
        moved += 1
    mesh.data.update()
    return moved


def fit(path, body, rig, eps, inner=(), gap=0.003, waist_bone=None, openings=0,
        sole=0.0, heel=0.0):
    """Doner: MPFB rig'ine bagli tek giysi agi (parcanin aglari birlestirilir)
    ve itilen nokta sayisi. Beden dinlenme pozunda olmali. `inner`: bu giysinin
    altina giyilebilecek, zaten giydirilmis giysiler (cizim sirasi kucuk olan
    her kalem, her varyant) - giysi hepsinin ustune oturtulur."""
    arm, meshes = import_piece(path)
    native = native_box(arm, meshes, rig)
    align_skeleton(arm, rig)
    prev = _masks(body, True)
    tree, bm = body_bvh(body)
    pushed = 0
    snugged = False
    for mesh in meshes:
        bake_pose(mesh)
        drop_skin_faces(mesh)
        weld_seams(mesh)
        if openings:
            fill_holes(mesh, openings)
        if sole > 0.0:
            add_sole(mesh, body, rig, sole, heel)
        pushed += wrap(mesh, tree, eps)
        if snug_head(mesh, body, eps):
            snugged = True
            pushed += wrap(mesh, tree, eps)
        pushed += cover_body(mesh, body, tree, eps,
                             min(c.z for c in rc_evaluated(body)) if sole > 0.0 else None)
        if waist_bone and waist_sleeve(mesh, body, rig, waist_bone, eps):
            snugged = True
        if not os.environ.get("WAYBORNE_NO_LAYERING"):  # qa: eski davranisi yeniden uretmek icin
            pushed += layer_over(mesh, tree, inner, gap)
            pushed += resolve_pokes(mesh, tree, inner, gap, MIN_FLOOR)
        transfer_weights(mesh, body, rig)
        if not os.environ.get("WAYBORNE_NO_LAYERING"):
            inherit_weights(mesh, inner)
    bm.free()
    for m, v in prev:
        m.show_viewport = v
    bpy.data.objects.remove(arm, do_unlink=True)
    meshes = [m for m in meshes if len(m.data.vertices)]
    if len(meshes) > 1:
        bpy.ops.object.select_all(action="DESELECT")
        for m in meshes:
            m.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()
    meshes[0]["native_min"], meshes[0]["native_max"] = native
    meshes[0]["snugged"] = snugged  # kaynaktan bilerek farkli: kafaya oturtuldu ya da beli uzatildi
    meshes[0]["waist_bone"] = waist_bone or ""
    meshes[0]["sole"] = sole
    return meshes[0], pushed
