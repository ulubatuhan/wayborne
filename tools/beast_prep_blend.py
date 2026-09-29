"""Bring a non-Quaternius animal .blend into the shape tools/beast_skin.py reads.

beast_skin.py was written against Quaternius' animal pack: a skinned glTF,
Y up, the animal facing +z, the near legs at +x, bones named Neck1/Head/
Tail1/FrontUpperLeg.L/FrontLowerLeg.L/FF.L/BackLeg.L/BackLowerLeg.L/FFB.L.
Two animals came from elsewhere and need normalising first:

- boar: rigged, but its bones are body.001_L.003-style and it faces -z.
  The bones are renamed by role (the vertex groups follow the rename) and
  the rig is turned round.
- bear: an unrigged mesh (CC0, Phelippeau Rudy). It gets a skeleton fitted
  to its measured feet/rump/nose and bone-heat weights. Its textures were a
  polar bear, and each fur face maps a whole fur swatch while the small
  faces carry the eyes, nose and claws - the per-face image assignment of the
  old file was lost, so faces are split between the two images by UV span.
  The fur is recoloured brown: Wayborne's bear is a forest animal, and a
  white bear on a steppe road states a climate the map does not have.

Run with the `bpy` module (pip install bpy):

    python3 tools/beast_prep_blend.py boar boar.blend /tmp/boar.glb
    python3 tools/beast_prep_blend.py bear Bear.blend /tmp/bear.glb

then feed the .glb to tools/beast_skin.py.
"""

import math
import os
import sys
import tempfile

import bpy
import numpy as np
from mathutils import Matrix, Vector
from PIL import Image

# Old boar bone -> Quaternius role. The rig is turned 180 degrees about Z,
# so the model's _L legs (+X) end up on the far side (.R) and _R on the near.
BOAR_SIDES = {"_L": ".R", "_R": ".L"}
BOAR_LEG = {
    "body.001%s": "FrontShoulder", "body.001%s.001": "FrontUpperLeg",
    "body.001%s.003": "FrontUpperLeg2", "body.001%s.002": "FrontLowerLeg",
    "body.001%s.004": "FF",
    "body%s": "BackShoulder", "body%s.001": "BackLeg", "body%s.003": "BackUpperLeg",
    "body%s.002": "BackLowerLeg", "body%s.004": "FFB",
}
BOAR_SPINE = {
    "ROOT": "Root", "Hips": "Body", "body": "Back", "body.001": "Torso",
    "body.002": "Neck1", "head": "Head", "nose": "HeadNose",
    "tail": "Rump", "tail.001": "Tail1", "tail.002": "Tail2", "tail.003": "Tail3",
    "tail.004": "CtrlTail",
}

# Brown bear: fur luminance -> umber, darks stay dark (eyes, nose, claws).
BEAR_FUR = np.array([0.34, 0.22, 0.13])
BEAR_FUR_GAMMA = 1.8
FUR_UV_SPAN = 0.4


def material(name, image, uv_name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = image
    uv = nt.nodes.new("ShaderNodeUVMap")
    uv.uv_map = uv_name
    nt.links.new(uv.outputs["UV"], tex.inputs["Vector"])
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return m


def keep_uv(mesh_obj, uv_name):
    for u in list(mesh_obj.data.uv_layers):
        if u.name != uv_name:
            mesh_obj.data.uv_layers.remove(u)


def export(path):
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", export_animations=False,
        export_apply=True, use_selection=False, export_cameras=False, export_lights=False,
    )


def prep_boar():
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    mesh = next(o for o in bpy.data.objects if o.type == "MESH")
    arm.data.pose_position = "REST"
    for old, new in BOAR_SPINE.items():
        arm.data.bones[old].name = new
    for side, flipped in BOAR_SIDES.items():
        for pattern, role in BOAR_LEG.items():
            arm.data.bones[pattern % side].name = role + flipped
    arm.rotation_euler.z += math.pi
    keep_uv(mesh, "UVMap")
    img = next(i for i in bpy.data.images if i.name.startswith("boar"))
    mesh.data.materials.clear()
    mesh.data.materials.append(material("boar", img, "UVMap"))


def recolour(image, tmpdir):
    px = np.array(image.pixels[:]).reshape(image.size[1], image.size[0], 4)
    lum = px[..., :3] @ np.array([0.299, 0.587, 0.114])
    px[..., :3] = BEAR_FUR * np.power(np.clip(lum, 0, 1), BEAR_FUR_GAMMA)[..., None]
    path = os.path.join(tmpdir, image.name)
    Image.fromarray((np.flipud(px) * 255).round().astype(np.uint8), "RGBA").save(path)
    return bpy.data.images.load(path)


def bear_skeleton(v):
    """Joints from the mesh's own landmarks (the animal faces -Y after the
    turn, near side +X): feet from the lowest vertices, nose and rump from
    the ends, heights as fractions of the standing height."""
    ground = v[:, 2].min()
    height = v[:, 2].max() - ground
    low = v[v[:, 2] - ground < 0.15 * height]
    mid = np.median(v[:, 1])
    front = low[low[:, 1] < mid]
    hind = low[low[:, 1] >= mid]
    fy, hy = np.median(front[:, 1]), np.median(hind[:, 1])
    fx, hx = np.abs(front[:, 0]).mean(), np.abs(hind[:, 0]).mean()
    nose = v[np.argmin(v[:, 1])]
    rump_y = v[:, 1].max()
    h = lambda f: ground + f * height
    bones = {
        "Body": ((0, hy, h(0.60)), (0, 0.5 * (fy + hy), h(0.64)), None),
        "Torso": ((0, 0.5 * (fy + hy), h(0.64)), (0, fy, h(0.66)), "Body"),
        "Neck1": ((0, fy, h(0.66)), (0, fy - 0.45 * (fy - nose[1]), h(0.60)), "Torso"),
        "Head": ((0, fy - 0.45 * (fy - nose[1]), h(0.60)), (0, nose[1], nose[2]), "Neck1"),
        "Tail1": ((0, rump_y - 0.08 * height, h(0.66)), (0, rump_y, h(0.55)), "Body"),
    }
    for sign, side in ((1, ".L"), (-1, ".R")):
        x_f, x_h = sign * fx, sign * hx
        # A straight leg leaves the two-bone knee solve degenerate (the rest
        # pose then misses the art by a fraction of a pixel), so each knee
        # carries the bend BeastRig gives it: elbow forward, hock back.
        knee_f = (x_f, fy - 0.03 * height, h(0.30))
        hock = (x_h, hy + 0.05 * height, h(0.30))
        bones["FrontUpperLeg" + side] = ((x_f, fy, h(0.60)), knee_f, "Torso")
        bones["FrontLowerLeg" + side] = (knee_f, (x_f, fy, h(0.06)), "FrontUpperLeg" + side)
        bones["FF" + side] = ((x_f, fy, h(0.06)), (x_f, fy - 0.10 * height, h(0.01)), "FrontLowerLeg" + side)
        bones["BackLeg" + side] = ((x_h, hy, h(0.62)), hock, "Body")
        bones["BackLowerLeg" + side] = (hock, (x_h, hy, h(0.06)), "BackLeg" + side)
        bones["FFB" + side] = ((x_h, hy, h(0.06)), (x_h, hy - 0.10 * height, h(0.01)), "BackLowerLeg" + side)
    return bones


def prep_bear():
    mesh = next(o for o in bpy.data.objects if o.type == "MESH")
    me = mesh.data
    me.transform(Matrix.Rotation(math.pi, 4, "Z") @ mesh.matrix_world)
    mesh.matrix_world = Matrix.Identity(4)
    v = np.array([p.co[:] for p in me.vertices])

    arm_data = bpy.data.armatures.new("bear_rig")
    arm = bpy.data.objects.new("bear_rig", arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    made = {}
    for name, (head, tail, parent) in bear_skeleton(v).items():
        b = arm_data.edit_bones.new(name)
        b.head, b.tail = Vector(head), Vector(tail)
        if parent:
            b.parent = made[parent]
        made[name] = b
    bpy.ops.object.mode_set(mode="OBJECT")

    for o in bpy.context.view_layer.objects:
        o.select_set(o in (mesh, arm))
    with bpy.context.temp_override(active_object=arm, object=arm,
                                   selected_objects=[mesh, arm], selected_editable_objects=[mesh, arm]):
        bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    if not any(len(g.name) for g in mesh.vertex_groups):
        raise SystemExit("bone heat produced no weights")

    tmpdir = tempfile.mkdtemp()
    fur = recolour(next(i for i in bpy.data.images if i.name.startswith("hair")), tmpdir)
    detail = recolour(next(i for i in bpy.data.images if i.name.startswith("Ours")), tmpdir)
    uv_name = me.uv_layers.active.name
    me.materials.clear()
    me.materials.append(material("bear_fur", fur, uv_name))
    me.materials.append(material("bear_detail", detail, uv_name))
    uv = me.uv_layers.active.data
    for p in me.polygons:
        us = [uv[l].uv[0] for l in p.loop_indices]
        vs = [uv[l].uv[1] for l in p.loop_indices]
        p.material_index = 0 if min(max(us) - min(us), max(vs) - min(vs)) >= FUR_UV_SPAN else 1


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    species, src, out = argv
    bpy.ops.wm.open_mainfile(filepath=src)
    {"boar": prep_boar, "bear": prep_bear}[species]()
    export(out)
    print("wrote", out)


if __name__ == "__main__":
    main()
