"""no_backfaces hakeminin eski yontemde BASARISIZ oldugunu gosterir (kural 1).

Eski yontem (render_passes.py): FigureRig kemigi basina katman (14), eski
bone_map.json (on=_l), w>=0.02 vertex grubu + vertex_group_smooth + Mask
modifier (yuz bazinda kesim), backface culling YOK, eski kamera/poz
(human_body_render.setup_scene, render_variant_debug.pose_mpfb).
Burada ayni yontem, arka yuzler duz magenta boyanarak render edilir; katmanlar
eski ressam sirasiyla birlestirilir ve gorunen magenta sayilir.

    python3 -I tools/figure_pipeline/blender/validate_old_backfaces.py
"""
import json
import os
import sys

import bpy

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(PIPE, "blender"))
import human_body_render as hbr  # noqa: E402
import make_variant as mv  # noqa: E402
import render_variant_debug as rvd  # noqa: E402
import fig_shading  # noqa: E402

OUT = os.path.join(ROOT, "build", "figures", "faz1", "validation", "old_magenta")
OLD_ORDER = ["upper_arm_back", "forearm_back", "hand_back", "thigh_back", "shin_back", "foot_back",
             "thigh_front", "shin_front", "foot_front", "torso", "head",
             "upper_arm_front", "forearm_front", "hand_front"]


def main():
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "build/figures/variants/male_medium/male_medium.blend"))
    mv.ensure_mpfb()
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    body = next(o for o in bpy.data.objects if o.type == "MESH")
    spec = json.load(open(hbr.SPEC_PATH))
    m, ground, _ = mv.figure_scale(rig, spec)
    joints = {"height": m * hbr.figure_height(spec), "ground": ground}
    rvd.pose_mpfb(rig, spec, joints)
    hbr.setup_scene(joints, spec)
    sc = bpy.context.scene
    sc.cycles.samples = 8
    sc.cycles.use_denoising = False

    cfg = json.load(open(os.path.join(PIPE, "config", "camera.json")))
    mat = fig_shading.body_material(cfg, "magenta")
    body.data.materials.clear()
    body.data.materials.append(mat)

    old_map = json.load(open(os.path.join(PIPE, "config", "bone_map.json")))
    names = {g.index: g.name for g in body.vertex_groups}
    deform = {b.name for b in rig.data.bones if b.use_deform}
    for layer in OLD_ORDER:
        group_bones = set(old_map[layer])
        vg = body.vertex_groups.new(name="old_" + layer)
        for v in body.data.vertices:
            tot = sum(g.weight for g in v.groups if names.get(g.group) in deform)
            w = sum(g.weight for g in v.groups if names.get(g.group) in group_bones)
            if tot > 1e-9 and w / tot >= 0.02:
                vg.add([v.index], 1.0, "REPLACE")
        bpy.context.view_layer.objects.active = body
        body.vertex_groups.active_index = vg.index
        bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
        bpy.ops.object.vertex_group_smooth(group_select_mode="ACTIVE", factor=0.5, repeat=4)
        bpy.ops.object.mode_set(mode="OBJECT")
        mod = body.modifiers.new("old_mask_" + layer, "MASK")
        mod.vertex_group = vg.name
        sc.render.filepath = os.path.join(OUT, layer + ".png")
        bpy.ops.render.render(write_still=True)
        body.modifiers.remove(mod)
    # tek parca (karsilastirma icin): eski govde tam, magenta
    sc.render.filepath = os.path.join(OUT, "_full.png")
    bpy.ops.render.render(write_still=True)
    print("TAMAM", OUT)


if __name__ == "__main__":
    main()
