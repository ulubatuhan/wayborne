"""Faz 1.3: Godot'dan gelen kemik acilarini MPFB varyantina uygular (YALNIZ DONUS)
ve her kare icin 5 derinlik katmanini, tek parca render'i, magenta (ic yuz)
test render'larini ve eklem isaretlerini uretir.

    python3 -I tools/figure_pipeline/blender/render_clip.py [--frames 0,6] [--no-magenta]

Kurallar config/*.json'dan okunur ve qa/check_config.py ile basta dogrulanir.
"""
import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "blender"))
sys.path.insert(0, os.path.join(PIPE, "qa"))
import fig_shading  # noqa: E402
import fig_weights  # noqa: E402
import make_variant as mv  # noqa: E402
import check_config  # noqa: E402

CFG = os.path.join(PIPE, "config")
OUT = os.path.join(ROOT, "build", "figures", "faz1")


def cfg(name):
    return json.load(open(os.path.join(CFG, name)))


def screen_to_world_abducted(angle, lateral_sign, abduction_rad):
    """Kol icin: sagital yon, disa (lateral_sign yonunde X) abduction_rad kadar acilmis."""
    dx, dy = math.cos(angle), math.sin(angle)
    c, s = math.cos(abduction_rad), math.sin(abduction_rad)
    return Vector((lateral_sign * s, -dx * c, -dy * c)).normalized()


def screen_to_world(angle):
    """Ekran acisi (x saga, y asagi) -> dunya yonu. Ekran sagi = dunya -Y,
    ekran yukari = dunya +Z (config/camera.json). Yanal (X) bilesen 0: sagital."""
    dx, dy = math.cos(angle), math.sin(angle)
    return Vector((0.0, -dx, -dy)).normalized()


def update():
    bpy.context.view_layer.update()


def bone_dir(rig, name):
    pb = rig.pose.bones[name]
    return (pb.tail - pb.head).normalized(), pb.head.copy()


def rotate_about_head(rig, name, target_dir):
    """Kemigi kendi basi etrafinda, mevcut (ebeveynle pozlanmis) yonunden hedef
    yone EN KUCUK donusle dondurur. Olcek/uzunluk degismez."""
    pb = rig.pose.bones[name]
    cur, head = bone_dir(rig, name)
    q = cur.rotation_difference(target_dir)
    m = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head)
    pb.matrix = m @ pb.matrix
    update()


def keep_world_rotation(rig, name, rest_world_rot):
    """Kemigin dunya yonelimini dinlenme pozundakine geri getirir (ayak tabani duz)."""
    pb = rig.pose.bones[name]
    head = pb.head.copy()
    cur_rot = pb.matrix.to_quaternion()
    q = rest_world_rot @ cur_rot.inverted()
    m = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head)
    pb.matrix = m @ pb.matrix
    update()


def reset_pose(rig, arm_obj):
    for pb in rig.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    arm_obj.location = (0.0, 0.0, 0.0)
    update()


def apply_frame(rig, frame, layers, rest_foot_rot, retarget=None):
    F, B = layers["front_side"], layers["back_side"]
    retarget = retarget or cfg("retarget.json")
    abd = math.radians(float(retarget.get("arm_abduction_deg", 0.0)))
    b = frame["bones"]
    # govde: kalca -> omuz (FigureRig torso a=omuz, b=kalca; tersi)
    torso_up = screen_to_world(b["torso"] + math.pi)
    pel = rig.pose.bones["pelvis"]
    neck = rig.pose.bones["neck_01"]
    cur = (neck.head - pel.head).normalized()
    q = cur.rotation_difference(torso_up)
    head = pel.head.copy()
    pel.matrix = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head) @ pel.matrix
    update()
    for side, s in (("front", F), ("back", B)):
        out = -1.0 if s == "r" else 1.0  # _r -X tarafinda, _l +X (rig dinlenme konumlari)
        rotate_about_head(rig, "upperarm_" + s, screen_to_world_abducted(b["upper_arm_" + side], out, abd))
        rotate_about_head(rig, "lowerarm_" + s, screen_to_world_abducted(b["forearm_" + side], out, abd))
        rotate_about_head(rig, "thigh_" + s, screen_to_world(b["thigh_" + side]))
        rotate_about_head(rig, "calf_" + s, screen_to_world(b["shin_" + side]))
        keep_world_rotation(rig, "foot_" + s, rest_foot_rot["foot_" + s])


def body_vertex_set(body):
    gi = body.vertex_groups["body"].index
    return [v.index for v in body.data.vertices if any(g.group == gi and g.weight > 0.5 for g in v.groups)]


def evaluated_coords(body):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(dg)
    mw = body.matrix_world
    return [mw @ v.co for v in ev.data.vertices]


def chin_vertex(body, rig, rest_coords):
    """Menton: orta hatta (|x|<4 mm), YALNIZ bas kemigine >= 0.5 agirlikli ve kafa
    tabaninin (head kemiginin basi) en az 3 cm onunde kalan noktalar icinde en
    alcak olani. Girtlak/boyun on yuzu neck_01'e agirlikli oldugu icin disarida
    kalir; cene alti bas kemigine aittir.
    Ilk surum "boyun on yuzu"nu neck_01'in orta yuksekliginde aliyordu: bu rig'de
    o yukseklik dudak hizasi, filtre yalniz burnu birakti (crop ile goruldu).
    Koordinatlar DINLENME pozunda degerlendirilmis mesh'ten (v.co taban mesh)."""
    names = {g.index: g.name for g in body.vertex_groups}
    deform = {b.name for b in rig.data.bones if b.use_deform}
    hb = rig.matrix_world @ rig.data.bones["head"].head_local
    cand = []
    for v in body.data.vertices:
        gnames = [names.get(g.group) for g in v.groups]
        if "body" not in gnames:
            continue
        tot = sum(g.weight for g in v.groups if names.get(g.group) in deform)
        hw = sum(g.weight for g in v.groups if names.get(g.group) == "head")
        c = rest_coords[v.index]
        if tot > 0 and abs(c.x) < 0.004 and hw / tot >= 0.5 and c.y < hb.y - 0.03:
            cand.append(v.index)
    return min(cand, key=lambda i: rest_coords[i].z)


def project(camcfg, p, ground_y):
    return list(fig_shading.world_to_px(camcfg, p.y, p.z, ground_y, 0.0))


def joints_px(rig, camcfg, layers, coords, chin_idx, ground_y):
    F, B = layers["front_side"], layers["back_side"]
    mw = rig.matrix_world
    P = lambda name, end="head": project(camcfg, mw @ getattr(rig.pose.bones[name], end), ground_y)
    j = {
        "neck": P("neck_01"), "head_top_hint": P("head", "tail"),
        "chin": project(camcfg, coords[chin_idx], ground_y), "facing": 1,
    }
    for side, s in (("front", F), ("back", B)):
        j[side + "_shoulder"] = P("upperarm_" + s)
        j[side + "_elbow"] = P("lowerarm_" + s)
        j[side + "_wrist"] = P("hand_" + s)
        j[side + "_fingertip"] = P("middle_03_" + s, "tail")
        j[side + "_hip"] = P("thigh_" + s)
        j[side + "_knee"] = P("calf_" + s)
        j[side + "_ankle"] = P("foot_" + s)
        j[side + "_toe"] = P("ball_" + s, "tail")
    j["pelvis"] = P("pelvis")
    return j


def render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    only = None
    if "--frames" in argv:
        only = [int(x) for x in argv[argv.index("--frames") + 1].split(",")]
    do_magenta = "--no-magenta" not in argv

    layers, camcfg, clipcfg = cfg("layers.json"), cfg("camera.json"), cfg("clip.json")
    out_root = OUT
    if "--diag-camera" in argv:  # yalniz teshis: config'i degistirmeden baska kamera ayari
        camcfg = json.load(open(argv[argv.index("--diag-camera") + 1]))
        out_root = argv[argv.index("--diag-out") + 1]
    clip = json.load(open(os.path.join(OUT, "clip_walk.json")))

    bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "build/figures/variants", clipcfg["variant"],
                                                   clipcfg["variant"] + ".blend"))
    mv.ensure_mpfb()
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    body = next(o for o in bpy.data.objects if o.type == "MESH")
    os.makedirs(OUT, exist_ok=True)
    rb = os.path.join(OUT, "rig_bones.json")
    json.dump({"deform_bones": sorted(b.name for b in rig.data.bones if b.use_deform)}, open(rb, "w"))
    check_config.check(rb)

    # Sorgular icin "Hide helpers" maskesi viewport'ta kapali (indeksler sabit),
    # render'da acik (yardimci geometri gorunmez).
    for m in body.modifiers:
        if m.type == "MASK":
            m.show_viewport = False
            m.show_render = True
    reset_pose(rig, rig)
    rest_foot_rot = {n: rig.pose.bones[n].matrix.to_quaternion() for n in
                     ("foot_l", "foot_r")}
    fig_weights.write_attr(body, fig_weights.layer_weights(body, rig, layers))
    chin_idx = chin_vertex(body, rig, evaluated_coords(body))
    body_idx = body_vertex_set(body)

    fig_shading.setup_render(camcfg)
    fig_shading.setup_camera(camcfg, 0.0, 0.0)
    modes = ["full"] + ["layer:" + n for n in layers["layers"]]
    if do_magenta:
        modes += ["magenta"] + ["magenta:" + n for n in layers["layers"]]
    mats = {m: fig_shading.body_material(camcfg, m, core=layers["core_threshold"],
                                         root=layers["root_threshold"]) for m in modes}

    meta = {"frames": []}
    for fr in clip["frames"]:
        i = fr["index"]
        if only is not None and i not in only:
            continue
        reset_pose(rig, rig)
        apply_frame(rig, fr, layers, rest_foot_rot)
        # Kok otelemesi (OLCEK DEGIL): kalca dunya y=0'da, en alcak govde noktasi z=0'da.
        coords = evaluated_coords(body)
        minz = min(coords[k].z for k in body_idx)
        pel_y = (rig.matrix_world @ rig.pose.bones["pelvis"].head).y
        rig.location = (0.0, -pel_y, -minz)
        update()
        coords = evaluated_coords(body)
        d = os.path.join(out_root, "frames", "f%02d" % i)
        os.makedirs(d, exist_ok=True)
        for m in modes:
            body.data.materials.clear()
            body.data.materials.append(mats[m])
            name = m.replace("layer:", "").replace(":", "_")
            render(os.path.join(d, name + ".png"))
        j = joints_px(rig, camcfg, layers, coords, chin_idx, 0.0)
        # kemik uzunluklari (yalniz karsilastirma icin; olcum pikselden)
        j["_bone_len_m"] = {n: (rig.pose.bones[n].tail - rig.pose.bones[n].head).length
                            for n in ("upperarm_r", "lowerarm_r", "thigh_r", "calf_r")}
        json.dump(j, open(os.path.join(d, "joints.json"), "w"), indent=1)
        meta["frames"].append({"index": i, "root_offset": [0.0, -pel_y, -minz]})
        print("kare", i, "tamam")
    json.dump(meta, open(os.path.join(OUT, "render_meta.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
