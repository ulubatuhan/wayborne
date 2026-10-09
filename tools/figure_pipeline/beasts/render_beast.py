"""Hayvan kare hatti: bir turun 3B modelini kendi animasyonlariyla pozlayip her
kareyi insanlarla ayni bes derinlik katmaninda render eder.

    python3 -I tools/figure_pipeline/beasts/render_beast.py --species horse [--clips walk,dead] [--out DIR]

Insan hattiyla (blender/render_frames.py) ayni kurallar, ayni kamera ve isik:
katman uyeligi nokta basina kemik agirligindan, diger katmanlar kamera
isininda saydam ama golgeye katiliyor, arka yuzler kamera isininda saydam.
Bes katmanin hayvandaki karsiligi (cizim sirasi, arkadan one):
  back_arm   = uzak on bacak       back_leg  = uzak arka bacak
  torso_head = govde, boyun, bas, kuyruk
  front_leg  = yakin arka bacak    front_arm = yakin on bacak
Oyunun kare oynaticisi (BodyFrames) boylece hayvan icin de degismeden calisiyor.

Insandan tek fark renk: insan gri render edilip oyunda tenle carpiliyor, hayvanin
rengi kendi malzemesinden. Her katman iki kez render ediliyor - golge (insanla
ayni gri malzeme, ayni dort tona indiriliyor) ve albedo (malzemenin kendi rengi,
isiksiz) - paketleyici ikisini carpiyor (pack_beasts.py). Boylece hayvan
insanla ayni ton bantlarinda golgeleniyor; iki ayri isik modeli iki ayri
produksiyon gibi gorunurdu.

Cikti: build/beasts/out/<tur>/<klip>/fNN/{shade,albedo}_{full,<katman>}.png, joints.json
"""
import json
import math
import os
import sys
import time

import bpy
from mathutils import Vector

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "blender"))
sys.path.insert(0, os.path.join(PIPE, "beasts"))
import fig_shading  # noqa: E402
import fig_weights  # noqa: E402
import synth_actions  # noqa: E402

MODELS = os.path.join(ROOT, "art_source", "models", "animals")
OUT = os.path.join(ROOT, "build", "beasts", "out")
LAYERS = ["back_arm", "back_leg", "torso_head", "front_leg", "front_arm"]
FORE = ("FrontUpperLeg", "FrontLowerLeg", "IKFrontLeg", "FF.")
HIND = ("BackLeg", "BackUpperLeg", "BackLowerLeg", "IKBackLeg", "FFB.")


def arg(argv, name, default=None):
    return argv[argv.index(name) + 1] if name in argv else default


def load_cfg():
    return json.load(open(os.path.join(PIPE, "beasts", "beasts.json")))


def import_model(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if path.endswith((".glb", ".gltf")):
        bpy.ops.import_scene.gltf(filepath=path)
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    mesh = next(o for o in bpy.data.objects
                if o.type == "MESH" and any(m.type == "ARMATURE" for m in o.modifiers))
    for o in list(bpy.data.objects):
        # Paketlerde bir yardimci kure var (iskelete bagli degil); render'a girmesin.
        if o.type == "MESH" and o is not mesh and o.parent is not rig:
            bpy.data.objects.remove(o, do_unlink=True)
    return rig, mesh


def limb_of(bone):
    if bone.startswith(HIND):
        return "hind"
    if bone.startswith(FORE):
        return "fore"
    return ""


def near_suffix(rig):
    """Kamera -X'te: yakin taraf on bacak kokunun X'i negatif olan."""
    for sfx in (".L", ".R"):
        b = rig.data.bones.get("FrontUpperLeg" + sfx)
        if b is not None:
            x = (rig.matrix_world @ b.head_local).x
            return sfx if x < 0 else (".R" if sfx == ".L" else ".L")
    return ".R"


def layer_weights(mesh, rig):
    """Nokta basina (uzak on, uzak arka, yakin arka, yakin on) agirlik payi -
    fig_shading.LIMB_CHANNEL sirasi (back_arm, back_leg, front_leg, front_arm)."""
    near = near_suffix(rig)
    deform = {b.name for b in rig.data.bones if b.use_deform}
    names = {g.index: g.name for g in mesh.vertex_groups}
    out = []
    for v in mesh.data.vertices:
        tot = 0.0
        acc = [0.0, 0.0, 0.0, 0.0]
        for g in v.groups:
            n = names.get(g.group)
            if n not in deform:
                continue
            tot += g.weight
            limb = limb_of(n)
            if not limb:
                continue
            is_near = n.endswith(near)
            ch = {("fore", False): 0, ("hind", False): 1, ("hind", True): 2, ("fore", True): 3}[(limb, is_near)]
            acc[ch] += g.weight
        out.append([a / tot if tot > 1e-9 else 0.0 for a in acc])
    return out


def base_color_source(mat):
    """(sabit renk, doku dugumu ya da None) - malzemenin kendi rengi."""
    if mat is None or not mat.use_nodes:
        return (0.8, 0.8, 0.8, 1.0), None
    bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf is None:
        return (0.8, 0.8, 0.8, 1.0), None
    inp = bsdf.inputs["Base Color"]
    if inp.is_linked and inp.links[0].from_node.type == "TEX_IMAGE":
        return tuple(inp.default_value), inp.links[0].from_node
    return tuple(inp.default_value), None


def albedo_material(cfg, layer, src_mat, core, root):
    """Malzemenin kendi rengi, isiksiz (emisyon), katman maskesi insan
    malzemesiyle ayni dugumlerle: fig_shading'in "id" modundan kopyalanmadi,
    onun ciktisinin emisyonu degistiriliyor."""
    mode = ("id:" + layer) if layer else "id"
    mat = fig_shading.body_material(cfg, mode, core=core, root=root,
                                    name_suffix="_alb_%s" % (src_mat.name if src_mat else "none"))
    nt = mat.node_tree
    idem = next(n for n in nt.nodes if n.type == "EMISSION" and n.inputs["Color"].is_linked
                and n.inputs["Color"].links[0].from_node.type == "COMBINE_COLOR")
    nt.links.remove(idem.inputs["Color"].links[0])
    color, tex = base_color_source(src_mat)
    if tex is not None:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = tex.image
        t.interpolation = tex.interpolation
        uv_in = tex.inputs["Vector"]
        if uv_in.is_linked and uv_in.links[0].from_node.type == "UVMAP":
            uv = nt.nodes.new("ShaderNodeUVMap")
            uv.uv_map = uv_in.links[0].from_node.uv_map
            nt.links.new(uv.outputs[0], t.inputs["Vector"])
        nt.links.new(t.outputs["Color"], idem.inputs["Color"])
    else:
        idem.inputs["Color"].default_value = color
    return mat


def sample_frames(action_spec, n, cycle):
    name, a, b = action_spec
    if n == 1:
        return [(name, a)]
    if cycle:
        return [(name, a + (b - a) * i / n) for i in range(n)]
    return [(name, a + (b - a) * i / (n - 1)) for i in range(n)]


def set_pose(rig, action_name, t):
    act = bpy.data.actions.get(action_name)
    if act is None:
        raise SystemExit("aksiyon yok: %s" % action_name)
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = act
    # Nesne donusu ve konumu aksiyonlar arasinda tasinmasin.
    rig.rotation_euler = (0.0, 0.0, 0.0)
    rig.location = (0.0, 0.0, 0.0)
    f0, f1 = act.frame_range
    f = f0 + (f1 - f0) * t
    bpy.context.scene.frame_set(int(math.floor(f)), subframe=f - math.floor(f))


def evaluated(mesh):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg)
    mw = mesh.matrix_world
    return [mw @ v.co for v in ev.data.vertices]


def body_vertices(mesh, lw, core):
    return [i for i, w in enumerate(lw) if max(w) < core]


TRUNK_EXCLUDE = ("Neck", "Head", "Ear", "Tail", "Horn", "Jaw", "Eye", "HeadNose")


def trunk_vertices(mesh, rig, body_idx):
    """Govde koseleri, bas/boyun/kuyruk haric: cidago bunlarin tepesi. Ilk
    surum bas ve kulaklari da sayiyordu; basi govdeden yuksek tasiyan
    turlerde (at, esek, geyik, kopek) olcek cidago yerine kulak ucuna gore
    kuruldu ve hayvan %25 kucuk render edildi (test_action_frames yakaladi)."""
    names = {g.index: g.name for g in mesh.vertex_groups}
    out = []
    for i in body_idx:
        groups = mesh.data.vertices[i].groups
        tot = sum(g.weight for g in groups)
        head = sum(g.weight for g in groups if names.get(g.group, "").startswith(TRUNK_EXCLUDE))
        if tot > 0 and head / tot < 0.5:
            out.append(i)
    return out


def withers_height(rest, body_idx):
    """Gövdenin en yüksek noktasi (bas/boyun haric: onlar torso_head katmaninda
    ama govde kemiklerine agirlikli degil) - tools/beast_skin.py'nin olcek
    hedefiyle ayni anlam: cidago."""
    return max(rest[i].z for i in body_idx)


def marker_indices(mesh, rig, rest, body_idx):
    """Eyer (sirtin ustu, govdenin ortasinda) ve bas: karelerde izlenen
    noktalar. Eyer = govde koselerinden, govde uzunlugunun ortasina en yakin
    sutundaki en yuksek orta hat noktasi."""
    ys = [rest[i].y for i in body_idx]
    mid = (min(ys) + max(ys)) * 0.5
    span = max(ys) - min(ys)
    col = [i for i in body_idx if abs(rest[i].y - mid) < span * 0.06 and abs(rest[i].x) < 0.15 * span]
    saddle = max(col, key=lambda i: rest[i].z)
    head_bone = rig.data.bones.get("Head")
    hz = (rig.matrix_world @ head_bone.head_local) if head_bone else rest[saddle]
    head = min(range(len(rest)), key=lambda i: (rest[i] - hz).length)
    return {"saddle": saddle, "head": head}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    cfg = load_cfg()
    species = arg(argv, "--species")
    spec = cfg["species"][species]
    clips = arg(argv, "--clips", ",".join(cfg["clips"])).split(",")
    out_root = arg(argv, "--out", os.path.join(OUT, species))
    only = [int(x) for x in arg(argv, "--frames").split(",")] if "--frames" in argv else None
    layers_cfg = json.load(open(os.path.join(PIPE, "config", "layers.json")))
    core, root = layers_cfg["core_threshold"], layers_cfg["root_threshold"]

    rig, mesh = import_model(os.path.join(MODELS, spec["model"]))
    actions = cfg["actions"][spec["actions"]]
    if spec["actions"] == "synth":
        synth_actions.build(rig, species)

    for m in mesh.modifiers:
        if m.type == "MASK":
            m.show_viewport = False
    lw = layer_weights(mesh, rig)
    fig_weights.write_attr(mesh, lw)
    set_pose(rig, actions["idle"][0], actions["idle"][1])
    rest = evaluated(mesh)
    body_idx = body_vertices(mesh, lw, core)
    ground_z = min(v.z for v in rest)
    ys = [v.y for v in rest]
    centre_y = (min(ys) + max(ys)) * 0.5
    withers = withers_height(rest, trunk_vertices(mesh, rig, body_idx)) - ground_z
    marks = marker_indices(mesh, rig, rest, body_idx)

    camcfg = dict(json.load(open(os.path.join(PIPE, "config", "camera.json"))))
    camcfg["canvas"] = list(cfg["canvas"])
    camcfg["ground_px"] = list(cfg["anchor_px"])
    camcfg["samples"] = int(cfg["samples"])
    camcfg["px_per_meter"] = float(spec["back"]) * float(cfg["fig_px"]) / withers
    fig_shading.setup_render(camcfg)
    bpy.context.scene.render.use_persistent_data = True
    fig_shading.setup_camera(camcfg, centre_y, ground_z)

    src_mats = list(mesh.data.materials)
    modes = [("shade", None)] + [("shade", n) for n in LAYERS] + [("albedo", None)] + [("albedo", n) for n in LAYERS]
    mats = {}
    for kind, layer in modes:
        if kind == "shade":
            m = fig_shading.body_material(camcfg, ("layer:" + layer) if layer else "full", core=core, root=root)
            mats[(kind, layer)] = [m] * len(src_mats)
        else:
            mats[(kind, layer)] = [albedo_material(camcfg, layer, s, core, root) for s in src_mats]

    os.makedirs(out_root, exist_ok=True)
    json.dump({"species": species, "px_per_meter": camcfg["px_per_meter"], "withers_m": withers,
               "back": spec["back"], "anchor_px": cfg["anchor_px"], "canvas": cfg["canvas"],
               "withers_px": withers * camcfg["px_per_meter"], "withers_from": "trunk"},
              open(os.path.join(out_root, "meta.json"), "w"), indent=1)
    for clip in clips:
        ccfg = cfg["clips"][clip]
        for i, (act, t) in enumerate(sample_frames(actions[clip], int(ccfg["frames"]), bool(ccfg.get("cycle")))):
            if only is not None and i not in only:
                continue
            set_pose(rig, act, t)
            coords = evaluated(mesh)
            if spec["actions"] == "synth" and clip in ("dead", "downed"):
                # Uretilen yatis pozu zemini bilmiyor: en alcak noktayi zemine indir.
                rig.location.z += ground_z - min(v.z for v in coords)
                bpy.context.view_layer.update()
                coords = evaluated(mesh)
            d = os.path.join(out_root, clip, "f%02d" % i)
            os.makedirs(d, exist_ok=True)
            t0 = time.time()
            for kind, layer in modes:
                # Albedo isiksiz emisyon: gurultu yok, ornekler yalniz kenar
                # yumusatmasi icin (olculdu: 128 ornekte kare basina 12 render
                # ~5 dk, cogu albedoda).
                bpy.context.scene.cycles.samples = camcfg["samples"] if kind == "shade" else int(cfg["albedo_samples"])
                for slot, m in enumerate(mats[(kind, layer)]):
                    mesh.data.materials[slot] = m
                bpy.context.scene.render.filepath = os.path.join(d, "%s_%s.png" % (kind, layer or "full"))
                bpy.ops.render.render(write_still=True)
            j = {k: list(fig_shading.world_to_px(camcfg, coords[v].y, coords[v].z, centre_y, ground_z))
                 for k, v in marks.items()}
            j["action"] = [act, t]
            json.dump(j, open(os.path.join(d, "joints.json"), "w"), indent=1)
            print("kare", species, clip, i, "%.1f sn" % (time.time() - t0), flush=True)


if __name__ == "__main__":
    main()
