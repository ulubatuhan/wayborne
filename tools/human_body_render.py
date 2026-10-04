"""Render the CC0 human base meshes into the wardrobe's own body parts.

`tools/wardrobe_mannequin.py` draws the bare body procedurally - a union of
discs along each bone, light grey with the volume in the shading. It was
always a placeholder (CLAUDE.md's B-00), and the route out of it was decided
after seven rounds of asking an image model for nine aligned parts failed:
render a real body instead, from a CC0 3D model, exactly the way the animals
stopped being drawn by hand (`tools/beast_skin.py`).

The source is Blender Studio's CC0 "Human Base Meshes" bundle, whose
`GEO-body_male_realistic` / `GEO-body_female_realistic` are anatomically real
and cleanly quad-topologised. They arrive UNRIGGED, which is not a blocker
and not a surprise: `tools/beast_prep_blend.py` already fits a skeleton to an
unrigged CC0 mesh (the bear) and bone-heat weights it. Here it is easier
still, because the target skeleton is not guessed - `FigureRig` already owns
it, and `docs/wardrobe/rig_spec.json` exports it.

    python3 tools/human_body_render.py --measure          # fit only, print it
    python3 tools/human_body_render.py                    # render all six

Writes `docs/wardrobe/body_render_<gender>_<weight>.png` on the paint canvas
(768x1152): the whole figure, in one piece.

**The shipped body is not cut out of this picture.** `tools/wardrobe_cut.py`
divides a GARMENT, which arrives as one painting and can only be divided
after the fact; the body has a 3D source and does not have to be. Measured,
cutting it showed every joint, because a piece cut in one pose and then
turned about its own pivot stops meeting its neighbour the moment the pose
changes - see `tools/human_body_parts.py`, which renders each part on its
own and is what writes `data/assets/characters/wardrobe/body*/`. This file
stays as the source of the mesh, the fit, the pose and the camera - that
half is shared - and as the one whole-figure picture to look at.

Three decisions are worth their reasons:

- **The pose is retargeted to `paint_joints` exactly, bone lengths included.**
  `wardrobe_cut.py` builds each bone's region from the *mannequin* drawn in
  that pose, grown by REGION_GROW; a limb rendered at the model's own
  proportions instead of the rig's would drift out of its own region near the
  joints and be decided by the nearest-region fallback. A bone that stretches
  is wrong for an animation (BeastRig forbids it for exactly that reason) and
  right for one still frame that has to line up with a fixed template.
- **The body is rendered light neutral grey, not skin.** `WalkFigure._body_tone`
  multiplies a colour into each part - skin on the head and hands, the shirt
  on the torso and arms - so a body painted with a skin tone could never be
  re-tinted. Same contract as the mannequin's own ALBEDO, and the reason the
  player's skin-tone choice keeps working.
- **Body weight is a front-to-back thickness, not an all-axis scale.** The
  camera looks along X, so widening X is invisible; what reads in a side view
  is Y. Thickness is scaled about the body's own Y centreline per height, so
  the silhouette grows without the figure drifting off its feet.
"""

import argparse
import json
import math
import os
import sys
import tempfile
import zipfile

import bpy
import numpy as np
from mathutils import Matrix, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC_PATH = os.path.join(ROOT, "docs", "wardrobe", "rig_spec.json")
OUT_DIR = os.path.join(ROOT, "docs", "wardrobe")
BUNDLE_ZIP = os.path.join(
    ROOT, "art_source", "models", "human-base-meshes-bundle-v1.0.0.zip"
)
INNER_BLEND = "human_base_meshes_bundle.blend"

MESH = {"male": "GEO-body_male_realistic", "female": "GEO-body_female_realistic"}
GENDERS = ("female", "male")
WEIGHTS = ("lean", "average", "heavy")
# The mannequin's own scale table, so a body weight means the same thing
# before and after this tool replaces it.
WEIGHT_SCALE = {"lean": 0.88, "average": 1.0, "heavy": 1.16}

# The canvas, and the figure's place on it, come from the paint reference -
# the cut tool reads the same constants, so a render at this size needs no
# fitting at all.
CANVAS = (768, 1152)
SCALE = 2.15
GROUND_Y = CANVAS[1] - 80

ALBEDO = 0.86          # the game multiplies a colour in - see the docstring
AMBIENT = 0.50
# The flat tones the render is posterised into, over the mannequin's own
# range (ALBEDO * (AMBIENT .. AMBIENT+DIFFUSE)). Few bands on purpose: this
# is a flat-ink game, not a shaded one.
FLAT_TONES = (0.50, 0.68, 0.84, 0.96)

# Anthropometric fractions of the shoulder->fingertip line. The elbow and the
# wrist sit inside the band where an A-pose deltoid touches the torso, so no
# slab can see them; everything else here is measured off the mesh.
ELBOW_FRACTION = 0.423
WRIST_FRACTION = 0.755
# Half the shoulder joints' separation and half the hip joints', as fractions
# of height. Both sit inside the body where no cross-section can see them.
SHOULDER_HALF = 0.095
HIP_HALF = 0.050
# Gap that counts as a real split between two body parts. The mesh is a quad
# grid, so neighbouring vertices on one ring already sit up to ~26 mm apart
# in the groin; measured, a real crotch gap is 39-41 mm, so a threshold under
# that reads ring spacing as a split and puts the crotch at 0.58H instead of
# 0.47H. Scaled by height so both genders use one number.
SPLIT_GAP = 0.022


# --------------------------------------------------------------------------
# measuring the mesh


def spans(xs, gap):
    xs = np.sort(xs)
    cuts = np.where(np.diff(xs) > gap)[0]
    out, start = [], 0
    for c in cuts:
        out.append([xs[start], xs[c]])
        start = c + 1
    out.append([xs[start], xs[-1]])
    merged = [out[0]]
    for lo, hi in out[1:]:
        if lo - merged[-1][1] <= gap:
            merged[-1][1] = max(merged[-1][1], hi)
        else:
            merged.append([lo, hi])
    return [tuple(s) for s in merged]


def slab(v, z, half):
    return v[np.abs(v[:, 2] - z) < half]


def armpit_z(v, h, z0):
    """Highest height whose slab splits into arm | torso | arm."""
    for z in np.linspace(z0 + 0.60 * h, z0 + 0.86 * h, 160)[::-1]:
        b = slab(v, z, 0.004 * h)
        if len(b) >= 40 and len(spans(b[:, 0], SPLIT_GAP * h)) >= 3:
            return z
    return z0 + 0.79 * h


def crotch_z(v, h, z0):
    """Where the body stops being one piece: the floor of the mid-sagittal strip.

    Two island-counting versions of this were wrong before it was defined
    this way. Counting islands in a slab is satisfied by the arms, which in
    an A-pose hang past the crotch; counting only *central* islands is then
    satisfied by the quad grid's own ring spacing in the groin. Both returned
    the top of their search range. The strip right on the body's centre plane
    needs neither threshold: mesh exists there from the crown down to the
    crotch and nowhere below it, because that is where the legs part.
    """
    # Swept: at 0.003-0.006 of height the answer is steady (male 0.477H,
    # female 0.464H, both at the anatomical 0.48H); wider strips catch the
    # inner thighs below the crotch and slide down to 0.35H.
    strip = v[np.abs(v[:, 0]) < 0.005 * h]
    return float(strip[:, 2].min()) if len(strip) else z0 + 0.47 * h


def leg_track(v, h, z0, crotch):
    """(z, centre x, width) of the +x leg, from below the crotch to the floor."""
    out = []
    for z in np.linspace(crotch - 0.01 * h, z0 + 0.004 * h, 120):
        b = slab(v, z, 0.006 * h)
        if len(b) < 20:
            continue
        cand = [s for s in spans(b[:, 0], SPLIT_GAP * h) if 0.5 * (s[0] + s[1]) > 0]
        if not cand:
            continue
        lo, hi = min(cand, key=lambda s: s[0])
        out.append((z, 0.5 * (lo + hi), hi - lo))
    return out


def width_dip(trackpoints, h, z0, lo_frac, hi_frac):
    """Height of the narrowest cross-section inside a band - a joint."""
    band = [p for p in trackpoints if lo_frac <= (p[0] - z0) / h <= hi_frac]
    return min(band, key=lambda p: p[2]) if band else None


def arm_line(v, h, z0, armpit):
    """Shoulder, elbow, wrist and fingertip of the +x arm.

    Only the fingertip and the arm's lower stretch can be measured: above it
    the deltoid touches the torso and no cross-section separates them. Two
    earlier passes both tried to recover the shoulder from that stretch alone
    - a line fit, then a least-squares solve - and both extrapolated roughly
    2.5x past their own data, putting the joint 10 cm out and behind the
    body. So the shoulder is a ratio of height, and the measurement is spent
    where it is actually available: the elbow and wrist are read off the
    arm's own measured centres rather than assumed to lie on a straight line
    between the shoulder and the tip. They do not: measured, the male arm is
    straight to 13 mm but the female model's A-pose carries a slight bend, so
    no single line fits it better than 38 mm whatever shoulder it is given.
    """
    tip = v[np.argmax(v[:, 0])]
    shoulder = np.array([SHOULDER_HALF * h, 0.0, armpit + 0.055 * h])
    samples = []
    for z in np.linspace(armpit - 0.03 * h, tip[2] + 0.02 * h, 90):
        b = slab(v, z, 0.006 * h)
        if len(b) < 20:
            continue
        lo, hi = spans(b[:, 0], SPLIT_GAP * h)[-1]
        if lo <= 0 or hi - lo > 0.055 * h:
            continue
        m = b[(b[:, 0] >= lo - 1e-9) & (b[:, 0] <= hi + 1e-9)]
        samples.append((z, 0.5 * (lo + hi), float(m[:, 1].mean())))

    def at(fraction):
        """The arm's own centre at a height, falling back to the straight line."""
        z = shoulder[2] + fraction * (tip[2] - shoulder[2])
        straight = shoulder + fraction * (tip - shoulder)
        near = [s for s in samples if abs(s[0] - z) < 0.02 * h]
        if not near:
            return straight, abs(straight[0] - straight[0])
        s = min(near, key=lambda s: abs(s[0] - z))
        return np.array([s[1], s[2], z]), abs(s[1] - straight[0])

    elbow, e_err = at(ELBOW_FRACTION)
    wrist, w_err = at(WRIST_FRACTION)
    return shoulder, elbow, wrist, tip, max(e_err, w_err)


def axis_y(v, h, z, z_half, x_half):
    """The body's own front-to-back centre at a height, on the centre plane."""
    band = v[(np.abs(v[:, 2] - z) < z_half * h) & (np.abs(v[:, 0]) < x_half * h)]
    return float(0.5 * (band[:, 1].min() + band[:, 1].max())) if len(band) else 0.0


def measure(v):
    """A-pose 3D joints of a standing human mesh, X across, -Y forward, Z up."""
    v = v.copy()
    v[:, 0] -= v[:, 0].mean()
    z0 = float(v[:, 2].min())
    h = float(v[:, 2].max() - z0)
    armpit = armpit_z(v, h, z0)
    crotch = crotch_z(v, h, z0)
    # The skull's own centre, which is what the rig's `head` joint means: the
    # paint pose puts the crown exactly `head_radius` above it.
    skull = v[v[:, 2] > armpit + 0.145 * h]
    skull_y = float(0.5 * (skull[:, 1].min() + skull[:, 1].max())) if len(skull) else 0.0

    legs = leg_track(v, h, z0, crotch)
    knee = width_dip(legs, h, z0, 0.22, 0.36)
    ankle = width_dip(legs, h, z0, 0.04, 0.14)

    shoulder, elbow, wrist, tip, arm_error = arm_line(v, h, z0, armpit)
    foot = v[v[:, 2] < z0 + 0.06 * h]
    foot = foot[foot[:, 0] > 0]

    j = {
        "height": h,
        "ground": z0,
        "armpit": armpit,
        "crotch": crotch,
        "arm_error": arm_error,
        "hip": np.array([0.0, 0.0, crotch + 0.055 * h]),
        "shoulder": np.array([0.0, 0.0, armpit + 0.055 * h]),
        # The neck and the skull get their own front-to-back axis, and that is
        # the whole of the "head sits too far forward" fix. Every other joint
        # here is pinned to Y=0, which is the MESH's origin - not the body's
        # own centre line, and nobody had checked the difference. Measured, the
        # chest sits +0.9 REF px off that origin and the hip +3.9, so pinning
        # them there costs nothing; the neck sits +9.8 and the skull +11.0
        # (female: +17.4 and +13.0), so a neck bone on Y=0 runs outside the
        # neck it is supposed to drive, and the retarget - which puts that bone
        # on the figure's own vertical axis - carried the whole head forward by
        # the difference. Measured on the part itself, the skull centred +16..
        # +20 px forward of the shoulder pivot against the rig's own +6.
        "neck_base": np.array([0.0, axis_y(v, h, armpit + 0.085 * h, 0.015, 0.05), armpit + 0.055 * h]),
        "head": np.array([0.0, skull_y, armpit + 0.125 * h]),
        "head_top": np.array([0.0, skull_y, float(v[:, 2].max())]),
        "thigh": np.array([HIP_HALF * h, 0.0, crotch + 0.045 * h]),
        "knee": np.array([knee[1], 0.0, knee[0]]),
        # The rig puts the ankle ON the ground and runs the foot bone flat
        # along it, so the leg's whole length is knee -> ground. Fitting the
        # 3D ankle at its anatomical height instead (measured 0.094H) and
        # then retargeting it to the ground stretched the shin by a third
        # and sank the sole 65 px below the ground line, against the
        # mannequin's own 17. The sole is this rig's ankle.
        "ankle": np.array([ankle[1], 0.0, z0 + 0.012 * h]),
        "ankle_rest": np.array([ankle[1], 0.0, ankle[0]]),
        "toe": np.array([ankle[1], float(foot[:, 1].min()), z0 + 0.012 * h]),
        "arm": shoulder,
        "elbow": elbow,
        "wrist": wrist,
        "tip": tip,
    }
    return j


# --------------------------------------------------------------------------
# the armature, and the pose it is retargeted to

# bone -> (head joint, tail joint, parent, sided). FigureRig's own fifteen
# bones collapse to these: the two sides share one definition and are built
# with mirrored X, so the front limb is simply the one nearer the camera.
CHAIN = [
    ("spine", "hip", "shoulder", None, False),
    # `neck_base`, not `shoulder`: see measure(). The two are the same point in
    # the 2D rig and ten pixels apart on a real body.
    ("neck", "neck_base", "head", "spine", False),
    ("skull", "head", "head_top", "neck", False),
    ("clavicle", "shoulder", "arm", "spine", True),
    ("upper_arm", "arm", "elbow", "clavicle", True),
    ("forearm", "elbow", "wrist", "upper_arm", True),
    ("hand", "wrist", "tip", "forearm", True),
    ("thigh", "thigh", "knee", None, True),
    ("shin", "knee", "ankle", "thigh", True),
    ("foot", "ankle", "toe", "shin", True),
]

# bone -> the two paint_joints it must land on, per side. "front" is the limb
# the viewer sees whole; it is drawn nearer the camera for the same reason.
POSE_TARGET = {
    "spine": ("hip", "shoulder"),
    "neck": ("shoulder", "head"),
    "upper_arm": ("shoulder", "elbow_%s"),
    # The clavicle is deliberately absent here. It runs across the body,
    # which a side view cannot show, so it has no 2D counterpart to retarget
    # to; left out of this table it keeps its rest direction and simply rides
    # its parent spine to the posed shoulder, which is exactly what it is
    # for - catching the chest and shoulder vertices so they do not follow
    # the upper arm's swing.

    "forearm": ("elbow_%s", "hand_%s"),
    "hand": ("hand_%s", "fingers_%s"),
    "thigh": ("hip", "knee_%s"),
    "shin": ("knee_%s", "ankle_%s"),
    "foot": ("ankle_%s", "toe_%s"),
}

SIDES = {"front": "L", "back": "R"}


def sided(name, side):
    return "%s.%s" % (name, SIDES[side])


def build_armature(joints, name):
    arm = bpy.data.armatures.new(name)
    obj = bpy.data.objects.new(name, arm)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    made = {}
    two_sided = {bone for bone, _, _, _, two in CHAIN if two}
    for bone, a, b, parent, two in CHAIN:
        for side in (("front", "back") if two else (None,)):
            key = sided(bone, side) if side else bone
            eb = arm.edit_bones.new(key)
            ha, hb = joints[a].copy(), joints[b].copy()
            if side:
                # front limbs sit nearer the camera, which looks down -X
                sign = -1.0 if side == "front" else 1.0
                ha[0], hb[0] = sign * abs(ha[0]), sign * abs(hb[0])
            eb.head, eb.tail = Vector(ha), Vector(hb)
            eb.roll = 0.0
            if parent:
                # An arm hangs off the (single) spine, a shin off its own
                # side's thigh - so the parent is sided only if it has sides.
                eb.parent = made[sided(parent, side) if parent in two_sided else parent]
                eb.use_connect = False
            made[key] = eb
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


def load_spec():
    with open(SPEC_PATH) as handle:
        return json.load(handle)


def paint_origin(spec):
    xs = [p[0] for p in spec["paint_joints"].values()]
    return CANVAS[0] / 2 - (min(xs) + max(xs)) / 2 * SCALE


def target_world(spec, joints, name):
    """A paint_joint as a world position: 2D +x is forward (-Y), 2D -y is up."""
    x, y = spec["paint_joints"][name]
    m = joints["height"] / figure_height(spec)
    return np.array([0.0, -x * m, joints["ground"] - y * m])


def figure_height(spec):
    """The pose's own height in REF px - the head's crown, not its joint."""
    return -spec["paint_joints"]["head"][1] + spec["head_radius"]


def pose(obj, spec, joints):
    """Put every bone's head and tail on its paint_joint, length included."""
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="POSE")
    order = [b for b, _, _, _, _ in CHAIN]
    for bone, _, _, _, two in CHAIN:
        if bone not in POSE_TARGET:
            continue
        a_key, b_key = POSE_TARGET[bone]
        for side in (("front", "back") if two else (None,)):
            key = sided(bone, side) if side else bone
            pb = obj.pose.bones[key]
            sfx = side if side else ""
            a = target_world(spec, joints, a_key % sfx if "%s" in a_key else a_key)
            b = target_world(spec, joints, b_key % sfx if "%s" in b_key else b_key)
            if side:
                depth = -1.0 if side == "front" else 1.0
                a[0] = b[0] = depth * limb_depth(joints)
            bpy.context.view_layer.update()
            pb.matrix = bone_matrix(pb, Vector(a), Vector(b))

    # The skull takes the neck's direction but never its length. The rig has
    # no skull bone at all - its `head` bone runs shoulder -> head and the
    # whole head hangs off it as one part - so the neck here is retargeted to
    # that bone and stretches 31% to reach it. Letting the skull inherit that
    # stretch drew a second, taller head above the real one.
    neck_a = target_world(spec, joints, "shoulder")
    neck_b = target_world(spec, joints, "head")
    direction = Vector(neck_b - neck_a).normalized()
    skull = obj.pose.bones["skull"]
    bpy.context.view_layer.update()
    skull.matrix = bone_matrix(
        skull, Vector(neck_b), Vector(neck_b) + direction * skull.bone.length
    )
    bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")
    return order


def limb_depth(joints):
    """How far a limb sits off the centre plane. The camera looks along X, so
    this never shows in the picture - it only decides which limb occludes."""
    return 0.055 * joints["height"]


def bone_matrix(pose_bone, head, tail):
    """World matrix putting the bone's head on `head` and its axis on `tail`.

    The rotation is the MINIMAL one from the bone's rest direction to the
    target, applied to the bone's own rest matrix - never a basis built from
    scratch. A hand-built basis has to invent the bone's roll (its spin about
    its own axis), and inventing it rotated every limb and the torso about
    their own length: measured, the first version turned the body far enough
    that the head rendered nearly front-on in what is supposed to be a side
    view, and the clavicle's shoulder vertices splayed into flat wings.
    """
    direction = tail - head
    rest_dir = (pose_bone.bone.tail_local - pose_bone.bone.head_local)
    if direction.length < 1e-6 or rest_dir.length < 1e-6:
        return pose_bone.matrix
    rotation = rest_dir.normalized().rotation_difference(direction.normalized())
    basis = rotation.to_matrix() @ pose_bone.bone.matrix_local.to_3x3()
    # Only the bone's own axis is scaled - local Y. Scaling all three would
    # thicken the limb as well as lengthen it, a different picture entirely.
    k = direction.length / pose_bone.bone.length if pose_bone.bone.length > 1e-6 else 1.0
    basis = (basis @ Matrix.Diagonal((1.0, k, 1.0))).to_4x4()
    basis.translation = head
    return basis


# --------------------------------------------------------------------------
# the mesh itself


def prepare_mesh(name, weight):
    src = bpy.data.objects[MESH[name]]
    obj = src.copy()
    obj.data = src.data.copy()
    bpy.context.collection.objects.link(obj)
    # The previous variant's render hid every other object in the bundle, the
    # source mesh included, and a copy inherits that flag - so without this
    # only the first variant of a run rendered anything at all.
    obj.hide_render = False
    obj.matrix_world = Matrix.Translation((0, 0, 0)) @ src.matrix_world
    for mod in list(obj.modifiers):
        obj.modifiers.remove(mod)
    v = np.array([obj.matrix_world @ p.co for p in obj.data.vertices])
    dx = v[:, 0].mean()
    obj.location.x -= dx
    bpy.context.view_layer.update()
    thicken(obj, WEIGHT_SCALE[weight])
    for poly in obj.data.polygons:
        poly.use_smooth = True
    sub = obj.modifiers.new("Subdivision", "SUBSURF")
    sub.levels = sub.render_levels = 1
    return obj


def thicken(obj, k):
    """Scale front-to-back thickness about the body's own Y centre per height.

    Scaling every axis would widen the stance and move the feet apart; only
    Y reads in a side view, which is the one the parts are cut from.
    """
    if abs(k - 1.0) < 1e-6:
        return
    co = np.array([p.co[:] for p in obj.data.vertices])
    z = co[:, 2]
    lo, hi = z.min(), z.max()
    bins = np.clip(((z - lo) / max(hi - lo, 1e-9) * 48).astype(int), 0, 47)
    centre = np.zeros(49)
    for b in range(48):
        m = co[bins == b]
        centre[b] = 0.5 * (m[:, 1].min() + m[:, 1].max()) if len(m) else 0.0
    centre[48] = centre[47]
    smooth = np.convolve(centre, np.ones(5) / 5.0, mode="same")
    for i, p in enumerate(obj.data.vertices):
        c = smooth[bins[i]]
        p.co[1] = c + (p.co[1] - c) * k


def world_vertices(obj):
    mw = obj.matrix_world
    return np.array([(mw @ p.co)[:] for p in obj.data.vertices])


# --------------------------------------------------------------------------
# render


def setup_scene(joints, spec):
    scene = bpy.context.scene
    # Cycles on the CPU, not EEVEE: EEVEE is a GPU rasteriser and wants EGL,
    # which a headless container has no reason to carry. The body is one
    # 15k-vertex mesh under a single sun, so the CPU cost is seconds.
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 64
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = CANVAS
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"

    m = joints["height"] / figure_height(spec)
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    # Blender applies ortho_scale to the LARGER resolution axis, which here is
    # the canvas's height (1152) and not its width.
    cam_data.ortho_scale = max(CANVAS) / SCALE * m
    cam = bpy.data.objects.new("cam", cam_data)
    bpy.context.collection.objects.link(cam)
    ox = paint_origin(spec)
    # canvas (ox, GROUND_Y) is the pose's origin, which is world (0,0,ground)
    cx = (CANVAS[0] / 2 - ox) / SCALE * m
    cy = (GROUND_Y - CANVAS[1] / 2) / SCALE * m
    cam.location = (-4.0, -cx, joints["ground"] + cy)
    cam.rotation_euler = (math.radians(90), 0.0, math.radians(-90))
    scene.camera = cam

    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = AMBIENT
    scene.world = world

    sun_data = bpy.data.lights.new("sun", "SUN")
    sun_data.energy = 2.0
    sun = bpy.data.objects.new("sun", sun_data)
    bpy.context.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(58), 0.0, math.radians(-128))
    return cam


def grey_material():
    mat = bpy.data.materials.new("body")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (ALBEDO, ALBEDO, ALBEDO, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.88
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.04
    return mat


def render_to(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def flatten(path):
    """Posterise the render into a few flat tones.

    A smooth render is the wrong language for this game: everything else is
    drawn as flat ink (`ArtDraw.inked`), and a softly shaded body dropped
    into that reads as a different production - measured on a real frame, it
    nearly vanished against the combat ground. Quantising to a handful of
    bands, over the mannequin's own tonal range, keeps the form the 3D model
    gives while speaking the flat language the rest of the screen speaks.

    The contour is NOT drawn here. It belongs on each cut part, so that the
    joints read as joints - see wardrobe_cut.py's --ink.
    """
    from PIL import Image

    img = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255.0
    body = img[..., 3] > 0.35
    if not body.any():
        return
    lum = img[..., 0]
    lo, hi = np.percentile(lum[body], [2.0, 98.0])
    span = max(float(hi - lo), 1e-4)
    level = np.clip((lum - lo) / span, 0.0, 1.0)
    index = np.clip((level * len(FLAT_TONES)).astype(int), 0, len(FLAT_TONES) - 1)
    tone = np.array(FLAT_TONES, dtype=np.float32)[index]
    out = img.copy()
    out[..., :3] = np.where(body[..., None], tone[..., None], img[..., :3])
    Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8)).save(path)


# --------------------------------------------------------------------------


def open_bundle(path):
    if path.lower().endswith(".zip"):
        tmp = tempfile.mkdtemp(prefix="humanbase")
        outer = zipfile.ZipFile(path)
        names = outer.namelist()
        if INNER_BLEND in names:
            blend = outer.extract(INNER_BLEND, tmp)
        else:
            # archive.org wraps the real zip in a second one
            inner_name = next(n for n in names if n.endswith(".zip"))
            inner = zipfile.ZipFile(outer.extract(inner_name, tmp))
            blend = inner.extract(INNER_BLEND, tmp)
        path = blend
    bpy.ops.wm.open_mainfile(filepath=path)


def fit(gender):
    obj = bpy.data.objects[MESH[gender]]
    return measure(world_vertices(obj))


def build(gender, weight, spec, out_dir):
    for o in list(bpy.context.collection.objects):
        if o.name not in MESH.values():
            bpy.data.objects.remove(o, do_unlink=True)
    body = prepare_mesh(gender, weight)
    joints = measure(world_vertices(body))
    rig = build_armature(joints, "rig_%s" % gender)

    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    # Linear blend, deliberately. Dual-quaternion skinning
    # (use_deform_preserve_volume) was tried for the shoulder, which rotates
    # ~90 degrees out of the A-pose, and measured worse on both counts: it
    # ballooned the upper back, tore the chest and waist into self-
    # intersecting shards and clenched the feet, while region coverage fell
    # 98.6% -> 95.9%. The shoulder is isolated with a clavicle bone instead.

    body.data.materials.clear()
    body.data.materials.append(grey_material())
    pose(rig, spec, joints)
    rig.hide_render = True

    cam = setup_scene(joints, spec)
    # Every other object in the bundle has to be hidden, not just unlinked
    # from this collection. The bundle lays its fifty pieces - heads, hands,
    # feet, skulls, jaws, eyes - out in a row along X, and the camera looks
    # straight down X, so each one stacks on the figure: the first render
    # came back with a second skull above the head and a jaw across the hip.
    keep = {body.name, rig.name, cam.name}
    for other in bpy.data.objects:
        if other.name not in keep:
            other.hide_render = other.type in {"MESH", "CURVE", "SURFACE", "META", "FONT"}
    path = os.path.join(out_dir, "body_render_%s_%s.png" % (gender, weight))
    render_to(path)
    flatten(path)
    return path, joints


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", default=BUNDLE_ZIP)
    parser.add_argument("--out", default=OUT_DIR)
    parser.add_argument("--measure", action="store_true", help="fit only, no render")
    parser.add_argument("--gender", nargs="+", default=list(GENDERS))
    parser.add_argument("--weight", nargs="+", default=list(WEIGHTS))
    args = parser.parse_args()

    open_bundle(args.bundle)
    spec = load_spec()
    if args.measure:
        for gender in args.gender:
            j = fit(gender)
            h, z0 = j["height"], j["ground"]
            print("== %s  H=%.3f  armpit=%.3fH crotch=%.3fH  arm line error %.1f mm"
                  % (gender, h, (j["armpit"] - z0) / h, (j["crotch"] - z0) / h,
                     j["arm_error"] * 1000))
            for key in ("hip", "shoulder", "head", "thigh", "knee", "ankle",
                        "toe", "arm", "elbow", "wrist", "tip"):
                p = j[key]
                print("   %-9s x=%+.3f y=%+.3f z=%.3f (%.3fH)"
                      % (key, p[0], p[1], p[2], (p[2] - z0) / h))
        return
    for gender in args.gender:
        for weight in args.weight:
            path, _ = build(gender, weight, spec, args.out)
            print("  wrote", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()
