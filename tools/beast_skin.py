"""Turn a skinned 3D animal (glTF) into a BeastRig skin: one continuous
picture per depth layer plus a weighted 2D mesh that bends over it.

Why not parts: a body cut into rigid pieces rotates each piece around its
own pivot, so at every joint two edges either pull apart (a gap) or cross
(an overlap). Overlap margins only trade one for the other. 2D skeletal
animation solves it the way Spine/DragonBones/Godot's Polygon2D do: the
animal is ONE image, a mesh of triangles covers it, and every mesh vertex
follows a weighted blend of bones. The joint bends; nothing separates.

The weights are not guessed. A skinned glTF already carries the modeller's
per-vertex bone weights; each mesh vertex takes the weights of the 3D
surface visible at that point (a ray from the camera), mapped from the
model's bones onto BeastRig's sixteen.

Three layers, because a single picture has no pixels behind what covers
it: `far` (the two far legs, drawn first, darkened), `tail` (it hangs
behind the near thigh) and `main` (everything else). Each is rendered on its
own, so whatever swings out from behind something else has pixels to show.

    python3 tools/beast_skin.py Horse.gltf horse
    python3 tools/beast_skin.py Bull.gltf ox
    python3 tools/beast_skin.py Wolf.gltf wolf

Writes data/assets/characters/beasts/<species>/skin.tres and one
skin_<layer>.png per layer. Needs numpy, scipy, pillow, pygltflib, trimesh (+rtree) and
pyrender (headless: `LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a`). The source
models used so far are Quaternius' "Ultimate Animated Animal Pack" (CC0).
"""

import argparse
import base64
import json
import math
import os
import sys

import numpy as np
import pygltflib
import pyrender
import trimesh
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BEASTS = os.path.join(ROOT, "data", "assets", "characters", "beasts")
SPEC = json.load(open(os.path.join(ROOT, "docs", "beasts", "beast_rig_spec.json")))
REF_H = float(SPEC["ref_h"])

# Height of the back at the withers, in figure heights - BeastRig.SPECIES.back.
# The art is scaled so its withers sit where the procedural animal's did, so
# riders, wagons and combat slots keep the sizes they were laid out for. This
# is a design target, not a measurement of the source mesh - the scale in
# skeleton() forces whatever the raw glTF's proportions are onto this ratio,
# so a value here is "how tall should this read next to the player", chosen
# to sit inside the family's existing span (wolf .50 .. horse .66).
SPECIES_BACK = {
    "horse": 0.66, "ox": 0.62, "wolf": 0.50, "bear": 0.58, "boar": 0.46,
    "horse_white": 0.66, "donkey": 0.55, "stag": 0.60, "deer": 0.48, "husky": 0.40,
}

TEXELS_PER_REF = 2.0     # texture resolution: 2 texels per REF_H pixel
SUPERSAMPLE = 2          # rendered at 2x and filtered down (anti-aliasing)
GRID_STEP = 6.0          # mesh cell size in REF_H pixels
TOP_BONES = 3            # influences kept per mesh vertex
SMOOTH_ITERATIONS = 16   # weight diffusion passes across each joint (see smooth_weights)
HINGE_BAND = 0.12        # see hinge_roots
# Back to front. A picture has no pixels behind what covers it, so anything
# that moves out from behind something else is its own layer: the far legs
# swing out from behind the body, and the tail hangs behind the near thigh
# (in the main picture those tail pixels are thigh, and swung with the leg).
LAYERS = ("far", "tail", "main")


# --- glTF -----------------------------------------------------------------

_COMP = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
_NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def _accessor(g, bufs, idx):
    a = g.accessors[idx]
    bv = g.bufferViews[a.bufferView]
    n = _NCOMP[a.type]
    dt = np.dtype(_COMP[a.componentType])
    start = (bv.byteOffset or 0) + (a.byteOffset or 0)
    stride = bv.byteStride or n * dt.itemsize
    raw = np.frombuffer(bufs[bv.buffer], dtype=np.uint8)
    rows = np.stack([raw[start + i * stride:start + i * stride + n * dt.itemsize] for i in range(a.count)])
    out = rows.view(dt).reshape(a.count, n)
    if a.normalized and dt != np.float32:
        out = out.astype(np.float32) / np.iinfo(dt).max
    return out if n > 1 else out[:, 0]


def _quat(q):
    x, y, z, w = q
    return np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ])


def _local(node):
    if node.matrix:
        return np.array(node.matrix).reshape(4, 4).T
    m = np.eye(4)
    m[:3, :3] = _quat(node.rotation or [0, 0, 0, 1]) @ np.diag(node.scale or [1, 1, 1])
    m[:3, 3] = node.translation or [0, 0, 0]
    return m


def _srgb(c):
    c = np.clip(np.asarray(c, dtype=np.float64), 0.0, 1.0)
    return np.where(c <= 0.0031308, 12.92 * c, 1.055 * np.power(c, 1 / 2.4) - 0.055)


def load_model(path):
    """The mesh posed in its authored rest pose (linear blend skinning with
    the scene's own node transforms), rest joint positions and per-vertex
    joint weights. Bind and rest differ for some models (the wolf's tail is
    stored straight and hangs at rest); skinning to rest keeps mesh and
    skeleton in agreement either way."""
    g = pygltflib.GLTF2().load(path)
    bufs = [base64.b64decode(b.uri.split(",", 1)[1]) for b in g.buffers]
    worlds = {}
    parent_of = {}

    def walk(i, parent):
        worlds[i] = parent @ _local(g.nodes[i])
        for c in g.nodes[i].children or []:
            parent_of[c] = i
            walk(c, worlds[i])

    for r in g.scenes[g.scene].nodes:
        walk(r, np.eye(4))
    skin = g.skins[0]
    names = [g.nodes[i].name for i in skin.joints]
    joint_index = {j: k for k, j in enumerate(skin.joints)}
    ibm = _accessor(g, bufs, skin.inverseBindMatrices).reshape(-1, 4, 4).transpose(0, 2, 1)
    skin_mats = np.stack([worlds[j] @ ibm[k] for k, j in enumerate(skin.joints)])
    # The skinned body, never the first mesh node in file order - Stag lists
    # its antlers (a separate, unskinned mesh) before the body.
    mesh_node = next(i for i, n in enumerate(g.nodes) if n.skin is not None)

    pos, faces, joints, weights, colors = [], [], [], [], []
    base = 0
    for p in g.meshes[g.nodes[mesh_node].mesh].primitives:
        v = _accessor(g, bufs, p.attributes.POSITION).astype(np.float64)
        f = _accessor(g, bufs, p.indices).astype(np.int64).reshape(-1, 3)
        j = _accessor(g, bufs, p.attributes.JOINTS_0).astype(np.int64)
        w = _accessor(g, bufs, p.attributes.WEIGHTS_0).astype(np.float64)
        w /= np.maximum(w.sum(1, keepdims=True), 1e-9)
        vh = np.c_[v, np.ones(len(v))]
        posed = np.zeros_like(v)
        for k in range(4):
            posed += w[:, k:k + 1] * np.einsum("nij,nj->ni", skin_mats[j[:, k]], vh)[:, :3]
        col = g.materials[p.material].pbrMetallicRoughness.baseColorFactor
        pos.append(posed); faces.append(f + base); joints.append(j); weights.append(w)
        colors.append(np.tile(np.r_[_srgb(col[:3]), 1.0], (len(f), 1)))
        base += len(v)

    # A rigid attachment (the stag's antlers): its own mesh, no skin of its
    # own, hung under one of this skin's bones. It moves as one piece with
    # that bone, so it is posed by the node's own world transform and folded
    # in at full weight to that one bone - the weighting pipeline downstream
    # (rig_weights, hinge_roots) then treats it exactly like skinned geometry.
    for i, n in enumerate(g.nodes):
        if n.mesh is None or n.skin is not None or i == mesh_node:
            continue
        anc = parent_of.get(i)
        while anc is not None and anc not in joint_index:
            anc = parent_of.get(anc)
        if anc is None:
            continue
        bone_k = joint_index[anc]
        for p in g.meshes[n.mesh].primitives:
            v = _accessor(g, bufs, p.attributes.POSITION).astype(np.float64)
            f = _accessor(g, bufs, p.indices).astype(np.int64).reshape(-1, 3)
            vh = np.c_[v, np.ones(len(v))]
            posed = (worlds[i] @ vh.T).T[:, :3]
            col = g.materials[p.material].pbrMetallicRoughness.baseColorFactor
            pos.append(posed); faces.append(f + base)
            joints.append(np.full((len(v), 4), bone_k, dtype=np.int64))
            weights.append(np.c_[np.ones(len(v)), np.zeros((len(v), 3))])
            colors.append(np.tile(np.r_[_srgb(col[:3]), 1.0], (len(f), 1)))
            base += len(v)

    rest = {g.nodes[j].name: worlds[j][:3, 3].copy() for j in skin.joints}
    return {
        "positions": np.vstack(pos), "faces": np.vstack(faces),
        "joints": np.vstack(joints), "weights": np.vstack(weights),
        "face_colors": np.vstack(colors), "joint_names": names, "rest": rest,
    }


# --- Bone mapping -----------------------------------------------------------

def rig_bone(name):
    """A model bone -> the BeastRig bone its vertices follow. The model's
    legs have more segments than BeastRig's (a real hind leg bends at stifle
    AND hock); segments are fused so the IK joint is the one BeastRig bends:
    elbow in front, hock behind (BeastRig: 'the hind hock bends back')."""
    side = "near" if name.endswith(".L") else "far" if name.endswith(".R") else ""
    if name == "Head" or name.startswith("Ear"):
        return "head"
    if name.startswith("Neck"):
        return "neck"
    if name.startswith("Tail"):
        return "tail"
    if name.startswith("FrontUpperLeg"):
        return "fore_%s_upper" % side
    if name.startswith(("FrontLowerLeg", "IKFrontLeg")):
        return "fore_%s_lower" % side
    if name.startswith("FF."):
        return "fore_%s_foot" % side
    if name.startswith(("BackLeg", "BackUpperLeg")):
        return "hind_%s_upper" % side
    if name.startswith(("BackLowerLeg", "IKBackLeg")):
        return "hind_%s_lower" % side
    if name.startswith("FFB."):
        return "hind_%s_foot" % side
    # Body, Back, Torso*, the shoulder blades and any control bone.
    return "body"


def rig_weights(model, bones):
    index = {b: i for i, b in enumerate(bones)}
    per_joint = np.array([index[rig_bone(n)] for n in model["joint_names"]])
    out = np.zeros((len(model["positions"]), len(bones)))
    for k in range(4):
        np.add.at(out, (np.arange(len(out)), per_joint[model["joints"][:, k]]), model["weights"][:, k])
    out /= np.maximum(out.sum(1, keepdims=True), 1e-9)
    return hinge_roots(model, out, bones)


def hinge_roots(model, w, bones):
    """Skin above a leg's pivot belongs to the body. The model weights part
    of the shoulder and croup to the upper leg bone; rotating that bone about
    a pivot below them swings those vertices the opposite way to the leg -
    into the chest as the leg reaches forward, where the mesh folds over
    itself. Above the pivot the upper-leg weight is handed to the body over
    a short band (HINGE_BAND of the leg's height), so the root acts as a
    hinge."""
    p = model["positions"]
    r = model["rest"]
    ground = p[:, 1].min()
    body = bones.index("body")
    for end, root in (("fore", "FrontUpperLeg"), ("hind", "BackLeg")):
        for side, suffix in (("near", ".L"), ("far", ".R")):
            upper = bones.index("%s_%s_upper" % (end, side))
            ry = r[root + suffix][1]
            band = HINGE_BAND * (ry - ground)
            t = np.clip((p[:, 1] - ry) / band, 0.0, 1.0)
            moved = w[:, upper] * t
            w[:, upper] -= moved
            w[:, body] += moved
    return w


# --- Skeleton in REF_H pixels --------------------------------------------------

def skeleton(model, beast_key, rig_w, bones):
    """Bind joints in REF_H pixels, facing right: x forward, y down, ground
    at y = 0, x = 0 halfway between shoulder and hip (where BeastRig puts
    the figure's ground point)."""
    r = model["rest"]
    p = model["positions"]
    ground = p[:, 1].min()
    fore_root, hind_root = r["FrontUpperLeg.L"], r["BackLeg.L"]
    zc = 0.5 * (fore_root[2] + hind_root[2])
    body_i = index_of(bones, "body")
    body = rig_w[:, body_i] > 0.5
    span = abs(fore_root[2] - hind_root[2])

    def topline(z):
        near = body & (np.abs(p[:, 2] - z) < 0.08 * span)
        return p[near, 1].max()

    scale = REF_H * SPECIES_BACK[beast_key] / (topline(fore_root[2]) - ground)

    def px(z, y):
        return [round((z - zc) * scale, 3), round(-(y - ground) * scale, 3)]

    def at(j):
        return px(r[j][2], r[j][1])

    joints = {
        "shoulder_top": px(fore_root[2], topline(fore_root[2])),
        "hip_top": px(hind_root[2], topline(hind_root[2])),
        "saddle": px(zc, topline(zc)),
        "neck_base": at("Neck1"),
        "poll": at("Head"),
        "tail_root": at("Tail1"),
    }
    head = rig_w[:, index_of(bones, "head")] > 0.5
    tip = p[head][np.argmax(p[head][:, 2])]
    joints["muzzle"] = px(tip[2], tip[1])
    tail = rig_w[:, index_of(bones, "tail")] > 0.5
    far_tail = p[tail][np.argmin(p[tail][:, 2])]
    joints["tail_tip"] = px(far_tail[2], far_tail[1])
    for end, root, knee, foot in (("fore", "FrontUpperLeg", "FrontLowerLeg", "FF"),
                                  ("hind", "BackLeg", "BackLowerLeg", "FFB")):
        for side, suffix in (("near", ".L"), ("far", ".R")):
            key = "%s_%s_" % (end, side)
            joints[key + "root"] = at(root + suffix)
            joints[key + "knee"] = at(knee + suffix)
            f = r[foot + suffix]
            joints[key + "foot"] = px(f[2], ground)
            paw = rig_w[:, index_of(bones, key + "foot")] > 0.3
            front = p[paw][:, 2].max() if paw.any() else f[2]
            joints[key + "toe"] = px(max(front, f[2] + 0.05 * span), ground)
    return joints, scale, ground, zc


def index_of(bones, name):
    return bones.index(name)


# --- Rendering -------------------------------------------------------------

def _look_at(eye, target):
    f = target - eye
    f = f / np.linalg.norm(f)
    s = np.cross(f, [0, 1, 0]); s = s / np.linalg.norm(s)
    u = np.cross(s, f)
    m = np.eye(4)
    m[:3, 0], m[:3, 1], m[:3, 2], m[:3, 3] = s, u, -f, eye
    return m


def render_layer(tm, colors, view, texels_per_unit):
    """Side view from +x, flipped so +z (the animal's front) is +u. `view`
    is (zmin, zmax, ymin, ymax) in world units; one texel is 1/texels_per_unit."""
    zmin, zmax, ymin, ymax = view
    ss = SUPERSAMPLE
    w = int(round((zmax - zmin) * texels_per_unit)) * ss
    h = int(round((ymax - ymin) * texels_per_unit)) * ss
    colored = trimesh.Trimesh(tm.vertices, tm.faces, face_colors=(colors * 255).astype(np.uint8), process=False)
    # No custom material: pyrender drops per-face colours when one is given.
    scene = pyrender.Scene(bg_color=[0, 0, 0, 0], ambient_light=[0.42, 0.42, 0.42])
    scene.add(pyrender.Mesh.from_trimesh(colored, smooth=False))
    centre = np.array([0.0, (ymin + ymax) / 2, (zmin + zmax) / 2])
    eye = centre + [30.0, 0, 0]
    scene.add(pyrender.OrthographicCamera(xmag=(zmax - zmin) / 2, ymag=(ymax - ymin) / 2, znear=0.1, zfar=100.0),
              pose=_look_at(eye, centre))
    scene.add(pyrender.DirectionalLight(color=[1, 1, 1], intensity=2.6), pose=_look_at(eye + [0, 6, 5], centre))
    scene.add(pyrender.DirectionalLight(color=[1, 0.95, 0.9], intensity=1.1), pose=_look_at(eye + [0, -3, -6], centre))
    r = pyrender.OffscreenRenderer(w, h)
    rgba, _ = r.render(scene, flags=pyrender.RenderFlags.RGBA)
    r.delete()
    img = np.asarray(Image.fromarray(rgba, "RGBA").transpose(Image.FLIP_LEFT_RIGHT)).astype(np.float64) / 255.0
    # Filter down in premultiplied alpha, or the dark background bleeds into
    # every edge as a halo.
    pre = img.copy()
    pre[..., :3] *= pre[..., 3:4]
    pre = pre.reshape(h // ss, ss, w // ss, ss, 4).mean(axis=(1, 3))
    a = pre[..., 3:4]
    pre[..., :3] = np.where(a > 1e-6, pre[..., :3] / np.maximum(a, 1e-6), 0.0)
    return (np.clip(pre, 0, 1) * 255).round().astype(np.uint8)


# --- The 2D mesh -------------------------------------------------------------

def build_mesh(tm, vweights, alpha, origin_ref, to_world):
    """A grid of GRID_STEP cells over every opaque texel. Each grid vertex
    takes the bone weights of the surface the camera sees there; vertices
    off the surface (the rim of edge cells) copy their nearest seen one."""
    th, tw = alpha.shape
    step_tx = GRID_STEP * TEXELS_PER_REF
    nx = int(math.ceil(tw / step_tx)) + 1
    ny = int(math.ceil(th / step_tx)) + 1
    solid = ndimage.binary_dilation(alpha > 8, iterations=2)
    keep = np.zeros((ny - 1, nx - 1), bool)
    for cy in range(ny - 1):
        for cx in range(nx - 1):
            x0, y0 = int(cx * step_tx), int(cy * step_tx)
            keep[cy, cx] = solid[y0:int(y0 + step_tx) + 1, x0:int(x0 + step_tx) + 1].any()

    used = np.zeros((ny, nx), bool)
    used[:-1, :-1] |= keep; used[1:, :-1] |= keep; used[:-1, 1:] |= keep; used[1:, 1:] |= keep
    gx, gy = np.meshgrid(np.arange(nx), np.arange(ny))
    tex = np.stack([gx * step_tx, gy * step_tx], -1).astype(np.float64)
    ref = origin_ref + tex / TEXELS_PER_REF

    # Weights: cast a ray at every grid vertex, front to back.
    world = to_world(ref.reshape(-1, 2))
    origins = np.c_[np.full(len(world), 30.0), world[:, 1], world[:, 0]]
    dirs = np.tile([-1.0, 0.0, 0.0], (len(world), 1))
    locs, ray_i, tri_i = tm.ray.intersects_location(origins, dirs, multiple_hits=False)
    bary = trimesh.triangles.points_to_barycentric(tm.triangles[tri_i], locs)
    w = np.zeros((len(world), vweights.shape[1]))
    hit = np.zeros(len(world), bool)
    fv = tm.faces[tri_i]
    w[ray_i] = sum(bary[:, k:k + 1] * vweights[fv[:, k]] for k in range(3))
    hit[ray_i] = True
    hit_grid = hit.reshape(ny, nx)
    _, (iy, ix) = ndimage.distance_transform_edt(~hit_grid, return_indices=True)
    w = w.reshape(ny, nx, -1)[iy, ix]

    w = smooth_weights(w, hit_grid & used)

    vid = -np.ones((ny, nx), int)
    vid[used] = np.arange(used.sum())
    verts = ref[used]
    uvs = tex[used] / [tw, th]
    wts = w[used]
    tris = []
    for cy, cx in zip(*np.nonzero(keep)):
        a, b, c, d = vid[cy, cx], vid[cy, cx + 1], vid[cy + 1, cx + 1], vid[cy + 1, cx]
        tris += [a, b, c, a, c, d]
    order = np.argsort(-wts, axis=1)[:, :TOP_BONES]
    top = np.take_along_axis(wts, order, 1)
    top /= np.maximum(top.sum(1, keepdims=True), 1e-9)
    return verts, uvs, np.array(tris, int), order, top


def smooth_weights(w, surface, iterations=SMOOTH_ITERATIONS):
    """Widen every joint's blend band. The sampled weights can switch bone
    from one grid vertex to the next, and a cell whose corners follow two
    bones that rotate apart folds over itself (measured: the shoulder and
    hip roots, the inside of the knee). Averaging with the surface
    neighbours spreads the rotation over several cells. Only surface
    vertices take part, so a leg never averages with the belly across the
    transparent gap between them; rim vertices copy their nearest surface
    vertex afterwards, as before."""
    w = w.copy()
    for _ in range(iterations):
        total = np.zeros_like(w)
        count = np.zeros(surface.shape)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            shifted = np.roll(np.roll(w, dy, 0), dx, 1)
            ok = np.roll(np.roll(surface, dy, 0), dx, 1) & surface
            if dy == 1: ok[0, :] = False
            if dy == -1: ok[-1, :] = False
            if dx == 1: ok[:, 0] = False
            if dx == -1: ok[:, -1] = False
            total += np.where(ok[..., None], shifted, 0.0)
            count += ok
        mean = np.where(count[..., None] > 0, total / np.maximum(count, 1)[..., None], w)
        w = np.where(surface[..., None], 0.5 * (w + mean), w)
    _, (iy, ix) = ndimage.distance_transform_edt(~surface, return_indices=True)
    return w[iy, ix]


# --- Output ---------------------------------------------------------------

def _packed(kind, values, fmt):
    return "%s(%s)" % (kind, ", ".join(fmt % v for v in values))


def write_tres(path, data):
    lines = [
        '[gd_resource type="Resource" script_class="BeastSkin" load_steps=2 format=3]',
        "",
        '[ext_resource type="Script" path="res://scripts/character/beast_skin.gd" id="1_skin"]',
        "",
        "[resource]",
        'script = ExtResource("1_skin")',
        "ref_h = %.1f" % REF_H,
        "joint_names = " + _packed("PackedStringArray", data["joint_names"], '"%s"'),
        "joint_points = " + _packed("PackedVector2Array", np.ravel(data["joint_points"]), "%.3f"),
        "layer_textures = " + _packed("PackedStringArray", data["layer_textures"], '"%s"'),
        "layer_far = " + _packed("PackedInt32Array", data["layer_far"], "%d"),
        "layer_vertex_offsets = " + _packed("PackedInt32Array", data["layer_vertex_offsets"], "%d"),
        "layer_index_offsets = " + _packed("PackedInt32Array", data["layer_index_offsets"], "%d"),
        "vertices = " + _packed("PackedVector2Array", np.ravel(data["vertices"]), "%.3f"),
        "uvs = " + _packed("PackedVector2Array", np.ravel(data["uvs"]), "%.5f"),
        "indices = " + _packed("PackedInt32Array", data["indices"], "%d"),
        "bone_names = " + _packed("PackedStringArray", data["bone_names"], '"%s"'),
        "bone_ids = " + _packed("PackedInt32Array", np.ravel(data["bone_ids"]), "%d"),
        "bone_weights = " + _packed("PackedFloat32Array", np.ravel(data["bone_weights"]), "%.4f"),
        "",
    ]
    open(path, "w").write("\n".join(lines))


def build(gltf_path, beast_key, out_root):
    model = load_model(gltf_path)
    bones = list(SPEC["draw_order"])
    rig_w = rig_weights(model, bones)
    joints, scale, ground, zc = skeleton(model, beast_key, rig_w, bones)

    far_bones = [i for i, b in enumerate(bones) if "_far_" in b]
    faces = model["faces"]
    far_share = rig_w[faces][:, :, far_bones].sum(axis=2).mean(axis=1)
    tail_share = rig_w[faces][:, :, index_of(bones, "tail")].mean(axis=1)
    far = far_share > 0.5
    tail = ~far & (tail_share > 0.5)
    layer_faces = {"far": far, "tail": tail, "main": ~far & ~tail}

    out_dir = os.path.join(out_root, beast_key)
    os.makedirs(out_dir, exist_ok=True)
    texels_per_unit = scale * TEXELS_PER_REF
    data = {k: [] for k in ("layer_textures", "layer_far", "vertices", "uvs", "indices", "bone_ids", "bone_weights")}
    data["layer_vertex_offsets"], data["layer_index_offsets"] = [0], [0]

    for layer in LAYERS:
        tm = trimesh.Trimesh(model["positions"], faces[layer_faces[layer]], process=False)
        colors = model["face_colors"][layer_faces[layer]]
        lo, hi = tm.bounds
        pad = 0.04 * (hi[1] - lo[1])
        zmin, ymax = lo[2] - pad, hi[1] + pad
        tw = int(math.ceil((hi[2] + pad - zmin) * texels_per_unit))
        th = int(math.ceil((ymax - (lo[1] - pad)) * texels_per_unit))
        # The view is fitted to a whole number of texels, so a texel is
        # exactly 1 / TEXELS_PER_REF REF_H pixels - the mesh's UVs rely on it.
        view = (zmin, zmin + tw / texels_per_unit, ymax - th / texels_per_unit, ymax)
        img = render_layer(tm, colors, view, texels_per_unit)
        assert img.shape[:2] == (th, tw), (img.shape, th, tw)
        origin_ref = np.array([(zmin - zc) * scale, -(ymax - ground) * scale])

        def to_world(ref_xy):
            return np.c_[ref_xy[:, 0] / scale + zc, ground - ref_xy[:, 1] / scale]

        verts, uvs, tris, ids, wts = build_mesh(tm, rig_w, img[..., 3], origin_ref, to_world)
        name = "skin_%s.png" % layer
        Image.fromarray(img, "RGBA").save(os.path.join(out_dir, name), optimize=True)
        data["layer_textures"].append(name)
        data["layer_far"].append(1 if layer == "far" else 0)
        data["vertices"].extend(verts.tolist())
        data["uvs"].extend(uvs.tolist())
        data["indices"].extend(tris.tolist())
        data["bone_ids"].extend(ids.tolist())
        data["bone_weights"].extend(wts.tolist())
        data["layer_vertex_offsets"].append(len(data["vertices"]))
        data["layer_index_offsets"].append(len(data["indices"]))
        print("  %s: %dx%d texels, %d vertices, %d triangles" % (layer, tw, th, len(verts), len(tris) // 3))

    data["bone_names"] = bones
    data["joint_names"] = list(joints)
    data["joint_points"] = [joints[k] for k in joints]
    write_tres(os.path.join(out_dir, "skin.tres"), data)
    print("  %s -> %s (scale %.1f ref px per unit)" % (gltf_path, out_dir, scale))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("gltf")
    parser.add_argument("species", choices=SPEC["species_order"])
    parser.add_argument("--out", default=BEASTS)
    args = parser.parse_args()
    build(args.gltf, args.species, args.out)


if __name__ == "__main__":
    main()
