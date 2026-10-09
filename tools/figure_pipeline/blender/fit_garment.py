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


def fit(path, body, rig, eps, inner=(), gap=0.003):
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
        pushed += wrap(mesh, tree, eps)
        if snug_head(mesh, body, eps):
            snugged = True
            pushed += wrap(mesh, tree, eps)
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
    meshes[0]["snugged"] = snugged
    return meshes[0], pushed
