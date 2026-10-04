"""Render the human body ONE PART AT A TIME, the way the mannequin draws it.

`tools/human_body_render.py` renders the whole figure in `FigureRig.paint_pose()`
and `tools/wardrobe_cut.py` cuts it into nine parts. That is the right route for
a GARMENT, which arrives as one painting and can only be divided after the fact.
It is the wrong route for the BODY, and the measurement that settled it was an
A/B against the mannequin in the rest pose: every joint showed the cut. Pulling
the ink inward turned it into a black notch, leaving it outward into a white
seam - two faces of the same cut, and no threshold closes it, because a piece
cut in one pose and then turned about its own pivot stops meeting its neighbour
the moment the pose changes.

This is the same wall the animals already hit (Wardrobe & Rig Rules: "A walking
animal is one skin, not nine parts"). They answered it with one continuous skin.
A person cannot: `Wardrobe` hangs removable garment layers on the same bones, so
the body has to stay nine separate part canvases. The answer for a person is the
other one the mannequin already uses - **never cut at all**. Each part is its
own closed mesh, rendered alone in its own canvas, so there is no seam to show:
parts simply overlap, exactly like the mannequin's tubes, but with the real
body's silhouette.

    python3 tools/human_body_parts.py                 # all six variants
    python3 tools/human_body_parts.py --gender male --weight average

Writes straight into `data/assets/characters/wardrobe/body_<gender>_<weight>/`
(and `body/` for the default), so `wardrobe_cut.py` is not involved.
"""

import argparse
import os
import sys

import bpy      # must come first: bmesh only exists once bpy has initialised
import bmesh
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import human_body_render as render
import wardrobe_cut as cut
import wardrobe_paint_reference as ref

OUT_ROOT = cut.OUT_ROOT

# A vertex belongs to a part if the bone owns at least this much of it. Low on
# purpose: a part has to reach PAST its own joint, or two neighbours meet on a
# line instead of overlapping and the joint opens as soon as it bends. This is
# the mannequin's own overlap, expressed in weights rather than in pixels.
WEIGHT_MIN = 0.16

# rig_spec bone -> the armature bones that make up that part. The rig has no
# neck: its `head` bone runs shoulder -> head and carries the whole head, so
# the part is the neck and the skull together.
PART_BONES = {
    "torso": ("spine", "clavicle.L", "clavicle.R"),
    "head": ("neck", "skull"),
    "upper_arm_front": ("upper_arm.L",),
    "forearm_front": ("forearm.L",),
    "hand_front": ("hand.L",),
    "thigh_front": ("thigh.L",),
    "shin_front": ("shin.L",),
    "foot_front": ("foot.L",),
    "upper_arm_back": ("upper_arm.R",),
    "forearm_back": ("forearm.R",),
    "hand_back": ("hand.R",),
    "thigh_back": ("thigh.R",),
    "shin_back": ("shin.R",),
    "foot_back": ("foot.R",),
}

# A back limb is only written when it really differs from its front twin; a
# darkened copy of the front is what the game falls back to, and it is better
# than a near-duplicate file. The far upper arm is the usual casualty.
BACK_MIN_SHARE = cut.BACK_MIN_SHARE


def rest_spec(spec):
    """The same spec, read in the pose the part PNGs actually live in."""
    out = dict(spec)
    out["paint_joints"] = spec["rest_joints"]
    return out


def part_mesh(body, bone_names, name):
    """A closed mesh of just this part, posed, with its cut ends capped.

    The cap matters: an open tube renders its own dark interior at the joint,
    and the neighbour does not always cover it (a part drawn later sits on top
    of the one before it, so the later part's open end is in plain view).
    """
    deps = bpy.context.evaluated_depsgraph_get()
    evaluated = body.evaluated_get(deps)
    mesh = evaluated.to_mesh()

    groups = [body.vertex_groups[n].index for n in bone_names if n in body.vertex_groups]
    keep = set()
    for index, vertex in enumerate(body.data.vertices):
        if sum(g.weight for g in vertex.groups if g.group in groups) >= WEIGHT_MIN:
            keep.add(index)

    bm = bmesh.new()
    bm.from_mesh(mesh)
    evaluated.to_mesh_clear()
    bm.verts.ensure_lookup_table()
    drop = [v for i, v in enumerate(bm.verts) if i not in keep]
    bmesh.ops.delete(bm, geom=drop, context="VERTS")
    if not bm.faces:
        bm.free()
        return None
    boundary = [e for e in bm.edges if e.is_boundary]
    if boundary:
        bmesh.ops.holes_fill(bm, edges=boundary, sides=0)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])

    data = bpy.data.meshes.new(name)
    bm.to_mesh(data)
    bm.free()
    for poly in data.polygons:
        poly.use_smooth = True
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    return obj


def ink_part(image, width):
    """A hard contour round the whole part - it is a closed shape now, so its
    entire outline is a real silhouette and every bit of it should carry one."""
    pixels = np.asarray(image.convert("RGBA")).copy()
    alpha = pixels[..., 3] >= cut.MIN_ALPHA
    if not alpha.any():
        return image
    edge = alpha & ~ndimage.binary_erosion(alpha, iterations=int(width))
    for channel, value in enumerate(cut.INK):
        pixels[edge, channel] = int(round(value * 255))
    return Image.fromarray(pixels, "RGBA")


def build(gender, weight, spec, tmp_dir):
    pose_spec = rest_spec(spec)
    for other in list(bpy.context.collection.objects):
        if other.name not in render.MESH.values():
            bpy.data.objects.remove(other, do_unlink=True)

    body = render.prepare_mesh(gender, weight)
    for mod in list(body.modifiers):
        if mod.type == "SUBSURF":
            body.modifiers.remove(mod)      # keep topology aligned with the weights
    joints = render.measure(render.world_vertices(body))
    rig = render.build_armature(joints, "rig_%s" % gender)

    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")

    material = render.grey_material()
    body.data.materials.clear()
    body.data.materials.append(material)
    render.pose(rig, pose_spec, joints)
    bpy.context.view_layer.update()

    cam = render.setup_scene(joints, pose_spec)
    # Fewer samples than the whole-figure render: the result is posterised into
    # four flat tones, so sampling noise is quantised away long before it can
    # show, and this run is fourteen renders per variant rather than one.
    bpy.context.scene.cycles.samples = 24
    rig.hide_render = True
    body.hide_render = True
    for other in bpy.data.objects:
        if other.type in {"MESH", "CURVE", "SURFACE", "META", "FONT"}:
            other.hide_render = True

    out_dir = os.path.join(OUT_ROOT, "body_%s_%s" % (gender, weight))
    os.makedirs(out_dir, exist_ok=True)
    written, areas = {}, {}
    for bone, bones in PART_BONES.items():
        entry = spec["bones"][bone]
        piece = part_mesh(body, bones, "part_%s" % bone)
        if piece is None:
            continue
        piece.data.materials.append(material)
        piece.hide_render = False
        path = os.path.join(tmp_dir, "%s.png" % bone)
        render.render_to(path)
        render.flatten(path)
        bpy.data.objects.remove(piece, do_unlink=True)

        image = cut.unrotate(Image.open(path).convert("RGBA"), pose_spec, bone)
        image = ink_part(image, cut.INK_PX)
        area = int((np.asarray(image)[..., 3] >= cut.MIN_ALPHA).sum())
        if not area:
            continue
        written[bone] = (cut.part_file(bone, entry), image)
        areas[entry["part"]] = max(areas.get(entry["part"], 0), area)

    dropped = []
    for bone, (name, image) in sorted(written.items()):
        entry = spec["bones"][bone]
        if entry.get("back"):
            front = areas.get(entry["part"], 0)
            if front and (np.asarray(image)[..., 3] >= cut.MIN_ALPHA).sum() < front * BACK_MIN_SHARE:
                dropped.append(name)
                continue
        image.save(os.path.join(out_dir, name), optimize=True)
    return out_dir, sorted(n for n, _ in written.values() if n not in dropped), dropped


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", default=render.BUNDLE_ZIP)
    parser.add_argument("--gender", nargs="+", default=list(render.GENDERS))
    parser.add_argument("--weight", nargs="+", default=list(render.WEIGHTS))
    parser.add_argument("--tmp", default="/tmp/body_parts")
    args = parser.parse_args()

    os.makedirs(args.tmp, exist_ok=True)
    render.open_bundle(args.bundle)
    spec = render.load_spec()
    for gender in args.gender:
        for weight in args.weight:
            out_dir, written, dropped = build(gender, weight, spec, args.tmp)
            print("  ->", os.path.relpath(out_dir, render.ROOT), "(%d parts)" % len(written))
            for name in dropped:
                print("      (%s atlandi - arka uzuv on resminden ayirt edilmiyor)" % name)
            if (gender, weight) == ("male", "average"):
                default = os.path.join(OUT_ROOT, "body")
                os.makedirs(default, exist_ok=True)
                for name in os.listdir(out_dir):
                    if name.endswith(".png"):
                        Image.open(os.path.join(out_dir, name)).save(
                            os.path.join(default, name), optimize=True)


if __name__ == "__main__":
    main()
