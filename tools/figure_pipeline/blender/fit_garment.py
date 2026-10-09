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
import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

import fig_weights  # noqa: F401  (ayni dizinde; cagiranlar zaten yukluyor)

SKIN_MATERIAL_PREFIX = "MI_Regular"
SMOOTH_ITERATIONS = 12


def bone_matrix(pose_bone, head, tail):
    """tools/human_body_render.py ile ayni: en kucuk donus + eksen boyu olcek."""
    direction = tail - head
    rest_dir = pose_bone.bone.tail_local - pose_bone.bone.head_local
    if direction.length < 1e-6 or rest_dir.length < 1e-6:
        return pose_bone.matrix
    rotation = rest_dir.normalized().rotation_difference(direction.normalized())
    basis = rotation.to_matrix() @ pose_bone.bone.matrix_local.to_3x3()
    k = direction.length / pose_bone.bone.length if pose_bone.bone.length > 1e-6 else 1.0
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
        pb.matrix = bone_matrix(pb, inv @ head, inv @ tail)
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


def fit(path, body, rig, eps):
    """Doner: MPFB rig'ine bagli tek giysi agi (parcanin aglari birlestirilir)
    ve itilen nokta sayisi. Beden dinlenme pozunda olmali."""
    arm, meshes = import_piece(path)
    align_skeleton(arm, rig)
    prev = _masks(body, True)
    tree, bm = body_bvh(body)
    pushed = 0
    for mesh in meshes:
        bake_pose(mesh)
        drop_skin_faces(mesh)
        pushed += wrap(mesh, tree, eps)
        transfer_weights(mesh, body, rig)
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
    return meshes[0], pushed
