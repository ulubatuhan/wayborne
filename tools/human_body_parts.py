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
the body has to stay separate part canvases. The answer for a person is the
other one the mannequin already uses - **never cut at all**. Each part is its
own closed mesh, rendered alone in its own canvas, so there is no seam to show:
parts simply overlap, exactly like the mannequin's tubes, but with the real
body's silhouette. Two things follow from that and are not inherited from the
garment route: there are no back-limb files (see PART_BONES) and no contour
(see INK_DEFAULT).

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

# A part's two ends are not the same problem, and one weight threshold cannot
# answer both. Measured, with a single 0.16 share: `upper_arm` ran to x=-0.084
# against a shoulder joint at -0.171, so half the chest swung with the arm and
# read as a pauldron, and `thigh` carried the pelvis from 0.619H down against a
# hip joint at 0.533H, so the seat split between two swinging legs and the hips
# read as nothing at all. Raising the share to 0.45 fixed both and opened every
# joint instead: with no overlap left, a bent knee and elbow showed daylight.
#
# So the two ends are answered separately. A part takes everything its OWN
# bones touch at all (`PART_MIN`) - that is the reach past the far joint, where
# the neighbour is the next limb and the overlap is wanted - and then gives
# back whatever the GIRDLE strongly owns (`GIRDLE_MAX`), which is the near end,
# where the neighbour is the torso. The girdle itself is the torso's, at the
# same permissive share, so a limb's trimmed root always lands inside mass the
# torso already carries - the overlap is guaranteed by construction rather than
# by a number. The draw order is what makes it read: the torso is drawn over
# both thighs and under the front arm.
TORSO_BONES = ("spine", "clavicle.L", "clavicle.R")

PART_MIN = 0.12
TORSO_MIN = 0.02

# How much of a vertex the girdle may own before a limb gives it up. The head
# is looser because it is drawn OVER the torso: its neck has to reach down into
# the collar, and trimming it hard leaves the chin floating over a gap.
GIRDLE_MAX = {"upper_arm": 0.25, "thigh": 0.25, "head": 0.45}

# rig_spec bone -> the armature bones that make up that part. The rig has no
# neck: its `head` bone runs shoulder -> head and carries the whole head, so
# the part is the neck and the skull together.
#
# **No back limbs.** A garment cut from one painting can have a far sleeve
# that genuinely differs, which is what `wardrobe_cut.py`'s BACK_MIN_SHARE is
# for. A body rendered part by part cannot: both sides are posed to the same
# `rest_joints` (the spec stores one value for `elbow_front` and `elbow_back`)
# on a symmetric mesh, so the two renders come out identical - measured, area
# ratio 1.00 and mean tone within 2/255 on every limb. Writing them is not
# merely redundant, it is a loss: `Wardrobe` PREFERS a `<part>_back.png` over
# its own `BACK_SHADE`, so a far limb would be drawn at full brightness and
# the only thing separating it from the near one would be gone.
PART_BONES = {
    "torso": ("spine", "clavicle.L", "clavicle.R"),
    "head": ("neck", "skull"),
    "upper_arm_front": ("upper_arm.L",),
    "forearm_front": ("forearm.L",),
    "hand_front": ("hand.L",),
    "thigh_front": ("thigh.L",),
    "shin_front": ("shin.L",),
    "foot_front": ("foot.L",),
}


def rest_spec(spec):
    """The same spec, read in the pose the part PNGs actually live in."""
    out = dict(spec)
    out["paint_joints"] = spec["rest_joints"]
    return out


def part_mesh(body, bone_names, name, minimum, girdle_max=1.0):
    """A closed mesh of just this part, posed, with its cut ends capped.

    The cap matters: an open tube renders its own dark interior at the joint,
    and the neighbour does not always cover it (a part drawn later sits on top
    of the one before it, so the later part's open end is in plain view).
    """
    deps = bpy.context.evaluated_depsgraph_get()
    evaluated = body.evaluated_get(deps)
    mesh = evaluated.to_mesh()

    def indices(names):
        return {body.vertex_groups[n].index for n in names if n in body.vertex_groups}

    own, girdle = indices(bone_names), indices(TORSO_BONES)
    keep = set()
    for index, vertex in enumerate(body.data.vertices):
        if sum(g.weight for g in vertex.groups if g.group in own) < minimum:
            continue
        if girdle_max < 1.0 and sum(
                g.weight for g in vertex.groups if g.group in girdle) > girdle_max:
            continue
        keep.add(index)

    bm = bmesh.new()
    bm.from_mesh(mesh)
    evaluated.to_mesh_clear()
    bm.verts.ensure_lookup_table()
    cull = [v for i, v in enumerate(bm.verts) if i not in keep]
    bmesh.ops.delete(bm, geom=cull, context="VERTS")
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


# The mesh's hand is an A-pose hand: five fingers, slightly spread. Rendered
# whole it is correct and unreadable - at the 45 px figure the road draws, five
# separate sticks read as a claw, which is why the mannequin drew a mitten with
# a thumb in the first place ("hands grip, they do not wave"). The fingers are
# closed into one mass in 2D rather than posed in 3D: posing them would mean
# inventing finger bones the rig does not have and cannot drive, for a shape
# that is three pixels wide on screen.
HAND_CLOSE_PX = 5


def close_gaps(image, radius):
    """Fuse what is separate by less than `radius`, keeping the outer shape."""
    pixels = np.asarray(image.convert("RGBA")).copy()
    alpha = pixels[..., 3] >= cut.MIN_ALPHA
    closed = ndimage.binary_closing(alpha, ndimage.generate_binary_structure(2, 2),
                                    iterations=int(radius))
    added = closed & ~alpha
    if not added.any():
        return image
    # New pixels take the colour of the nearest painted one, so the fill is the
    # hand's own tone rather than a flat patch of one band.
    _, (iy, ix) = ndimage.distance_transform_edt(~alpha, return_indices=True)
    pixels[added] = pixels[iy[added], ix[added]]
    pixels[added, 3] = 255
    return Image.fromarray(pixels, "RGBA")


# The body ships WITHOUT a contour, and that is a reversal. The first version
# inked every part's whole perimeter on the general rule that this is a flat-ink
# game - but a part is a closed shape, so its perimeter includes the end buried
# inside the body, and the ink landed there too: a hard arc over the deltoid
# (read as a pauldron), a line under the seat (read as shorts), a ring at the
# neck (read as a collar). The ends are the one place a line is wrong, and they
# are also the only place the parts have to meet. Rejected by the player on
# sight; `--ink` keeps the switch rather than the argument.
INK_DEFAULT = 0


def ink_part(image, width):
    """A hard contour round the whole part."""
    pixels = np.asarray(image.convert("RGBA")).copy()
    alpha = pixels[..., 3] >= cut.MIN_ALPHA
    if not alpha.any():
        return image
    edge = alpha & ~ndimage.binary_erosion(alpha, iterations=int(width))
    for channel, value in enumerate(cut.INK):
        pixels[edge, channel] = int(round(value * 255))
    return Image.fromarray(pixels, "RGBA")


def drop(obj):
    """Remove an object AND the datablock behind it.

    Removing only the object leaves the mesh orphaned in `bpy.data`, which a
    run of six variants does eight times each, on top of a fresh copy of the
    whole body per variant. Blender keeps them all for the life of the
    process and Cycles walks the file on every render.
    """
    data = obj.data if obj.type == "MESH" else None
    bpy.data.objects.remove(obj, do_unlink=True)
    if data is not None and data.users == 0:
        bpy.data.meshes.remove(data)


def build(gender, weight, spec, tmp_dir, into="", ink=INK_DEFAULT):
    pose_spec = rest_spec(spec)
    for other in list(bpy.context.collection.objects):
        if other.name not in render.MESH.values():
            drop(other)

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

    out_dir = os.path.join(OUT_ROOT, into or "body_%s_%s" % (gender, weight))
    os.makedirs(out_dir, exist_ok=True)
    # Anything a previous run left behind - a back limb from the version that
    # still wrote them, a part a changed threshold now drops - would otherwise
    # keep being served, since the game finds art by path and never lists it.
    for stale in os.listdir(out_dir):
        if stale.endswith(".png"):
            os.remove(os.path.join(out_dir, stale))

    written = {}
    for bone, bones in PART_BONES.items():
        entry = spec["bones"][bone]
        part = entry["part"]
        piece = part_mesh(
            body, bones, "part_%s" % bone,
            TORSO_MIN if part == "torso" else PART_MIN,
            GIRDLE_MAX.get(part, 1.0),
        )
        if piece is None:
            continue
        piece.data.materials.append(material)
        piece.hide_render = False
        path = os.path.join(tmp_dir, "%s.png" % bone)
        render.render_to(path)
        render.flatten(path)
        drop(piece)

        image = cut.unrotate(Image.open(path).convert("RGBA"), pose_spec, bone)
        if part == "hand":
            image = close_gaps(image, HAND_CLOSE_PX)
        if ink > 0:
            image = ink_part(image, ink)
        area = int((np.asarray(image)[..., 3] >= cut.MIN_ALPHA).sum())
        if not area:
            continue
        written[bone] = cut.part_file(bone, entry)
        image.save(os.path.join(out_dir, written[bone]), optimize=True)
    return out_dir, sorted(written.values())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", default=render.BUNDLE_ZIP)
    parser.add_argument("--gender", nargs="+", default=list(render.GENDERS))
    parser.add_argument("--weight", nargs="+", default=list(render.WEIGHTS))
    parser.add_argument("--tmp", default="/tmp/body_parts")
    # A scratch body id to write into instead of the shipped folders, so the
    # game can show the new art beside the old one before it replaces it.
    parser.add_argument("--into", default="")
    parser.add_argument("--ink", type=int, default=INK_DEFAULT,
                        help="contour width in REF px; 0 (the default) draws none")
    args = parser.parse_args()

    os.makedirs(args.tmp, exist_ok=True)
    render.open_bundle(args.bundle)
    spec = render.load_spec()
    for gender in args.gender:
        for weight in args.weight:
            out_dir, written = build(
                gender, weight, spec, args.tmp, args.into, args.ink)
            print("  ->", os.path.relpath(out_dir, render.ROOT), "(%d parts)" % len(written))
            if not args.into and (gender, weight) == ("male", "average"):
                default = os.path.join(OUT_ROOT, "body")
                os.makedirs(default, exist_ok=True)
                for stale in os.listdir(default):
                    if stale.endswith(".png"):
                        os.remove(os.path.join(default, stale))
                for name in os.listdir(out_dir):
                    if name.endswith(".png"):
                        Image.open(os.path.join(out_dir, name)).save(
                            os.path.join(default, name), optimize=True)


if __name__ == "__main__":
    main()
