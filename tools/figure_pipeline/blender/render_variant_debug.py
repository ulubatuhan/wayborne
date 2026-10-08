"""Asama 1 kapisi: bir varyanti paint pozuna sokup GERCEK govde uzerine
paint_joints isaretlerini basan bir debug goruntusu uretir (kilavuz 8.4,
"sapma 1 pikselden buyukse dur").

    python3 tools/figure_pipeline/blender/render_variant_debug.py male_medium
"""
import json
import os
import sys

import bpy
from mathutils import Matrix, Vector

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(ROOT, "tools"))
SCRATCH = "/tmp/claude-0/-home-user-wayborne/6087156a-0315-56cc-b7aa-69cad162629d/scratchpad"
sys.path.insert(0, SCRATCH)
sys.path.insert(0, os.path.join(PIPE, "blender"))

import human_body_render as hbr  # noqa: E402
import quaternius_render as qr  # noqa: E402
import make_variant as mv  # noqa: E402

OUT_ROOT = os.path.join(ROOT, "build", "figures", "variants")

# MPFB 'game_engine' kemik adlari Quaternius'unkiyle neredeyse birebir ayni
# (bkz. SETUP.md) - tek fark bas kemiginin kucuk harfle 'head' olmasi.
MPFB_BONE_MAP = dict(qr.BONE_MAP)
MPFB_HEAD_BONE = "head"


def pose_mpfb(rig, spec, joints):
    """qr.pose_outfit() ile ayni mantik, yalnizca HEAD_BONE adi farkli."""
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="POSE")
    limb_roles = ("upper_arm", "forearm", "hand", "thigh", "shin", "foot")
    for role in limb_roles:
        a_key, b_key = hbr.POSE_TARGET[role]
        for side in ("front", "back"):
            quat_name = MPFB_BONE_MAP[(role, side)]
            pb = rig.pose.bones[quat_name]
            a = hbr.target_world(spec, joints, a_key % side if "%s" in a_key else a_key)
            b = hbr.target_world(spec, joints, b_key % side if "%s" in b_key else b_key)
            a[0] = b[0] = pb.bone.head_local[0]
            bpy.context.view_layer.update()
            pb.matrix = hbr.bone_matrix(pb, Vector(a), Vector(b))

    neck_a = hbr.target_world(spec, joints, "shoulder")
    neck_b = hbr.target_world(spec, joints, "head")
    direction = Vector(neck_b - neck_a).normalized()
    bpy.context.view_layer.update()
    neck_pb = rig.pose.bones["neck_01"]
    neck_tail = Vector(neck_a) + direction * neck_pb.bone.length
    neck_pb.matrix = hbr.bone_matrix(neck_pb, Vector(neck_a), neck_tail)
    bpy.context.view_layer.update()
    head_pb = rig.pose.bones[MPFB_HEAD_BONE]
    head_pb.matrix = hbr.bone_matrix(
        head_pb, neck_tail, neck_tail + direction * head_pb.bone.length
    )
    bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")


def main():
    variant_id = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else sys.argv[-1]
    out_dir = os.path.join(OUT_ROOT, variant_id)
    blend_path = os.path.join(out_dir, "%s.blend" % variant_id)

    bpy.ops.wm.open_mainfile(filepath=blend_path)
    mv.ensure_mpfb()
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    basemesh = next(o for o in bpy.data.objects if o.type == "MESH")

    spec = json.load(open(hbr.SPEC_PATH))
    m, ground, shoulder_z = mv.figure_scale(rig, spec)
    joints = {"height": m * hbr.figure_height(spec), "ground": ground}
    pose_mpfb(rig, spec, joints)

    cam = hbr.setup_scene(joints, spec)
    mat = hbr.grey_material()
    basemesh.data.materials.clear()
    basemesh.data.materials.append(mat)
    # Mask modifier'i (vertex_group='body') BIRAKIYORUZ - create_human()'in
    # "Hide helpers" maskesi, helper-skirt/helper-tights/JointCubes gibi dev
    # duz yardimci geometriyi gizliyor. Kaldirmak (ilk denemede yapildi) o
    # yardimci yuzeylerin govdenin alt yarisini kaplayan opak bir dikdortgen
    # olarak render'a girmesine yol acti - bacaklar render edilmiyor degildi,
    # altlarinda duran bu yardimci yuzeyin arkasinda kalmislardi.

    img_path = os.path.join(out_dir, "debug_render_raw.png")
    hbr.render_to(img_path)

    # paint_joints'i ayni kameradan piksel uzayina duserek isaretle (world_to_camera_view).
    from bpy_extras.object_utils import world_to_camera_view
    scene = bpy.context.scene
    marks = {}
    for name, (px, py) in spec["paint_joints"].items():
        world = Vector(hbr.target_world(spec, joints, name))
        ndc = world_to_camera_view(scene, cam, world)
        cx = ndc.x * hbr.CANVAS[0]
        cy = (1.0 - ndc.y) * hbr.CANVAS[1]
        marks[name] = [cx, cy]

    with open(os.path.join(out_dir, "debug_marks.json"), "w") as f:
        json.dump(marks, f, indent=1)

    from PIL import Image, ImageDraw
    im = Image.open(img_path).convert("RGBA")
    draw = ImageDraw.Draw(im)
    for name, (cx, cy) in marks.items():
        r = 4
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 0, 255, 255), width=2)
        draw.text((cx + 6, cy - 6), name, fill=(255, 0, 255, 255))
    out_img = os.path.join(out_dir, "debug_joints.png")
    im.save(out_img)
    print("yazildi:", out_img)


if __name__ == "__main__":
    main()
