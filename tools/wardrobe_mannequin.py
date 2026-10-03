"""The bare body every person is drawn on: a jointed mannequin, one set of
parts per gender x body weight.

SUPERSEDED, and re-running it overwrites what replaced it. The shipped body
is now rendered from a real CC0 human mesh - `tools/human_body_render.py`
plus `tools/wardrobe_cut.py` - so running this tool puts the procedural
mannequin back over six real bodies. It stays because it is the only thing
that can regenerate a body for a rig that has changed shape, and because the
regions `wardrobe_cut.py` assigns by were first built from it.

Wardrobe looks for `wardrobe/body_<gender>_<weight>/<part>.png` and falls
back to `wardrobe/body/`. Until clothing is painted, this mannequin *is* the
figure: the game tints each part by what that person wears (shirt on the
torso and arms, trousers on the legs, boots on the feet, skin on head and
hands - see WalkFigure._body_tone), so a painted jacket later simply lands
on top of a body that already has the right shape.

Why a mannequin and not a painted nude: the parts are multiplied by a
colour, so they are painted as light neutral grey with the volume in the
shading. Each part is a union of discs along its bone (a profile of radii
and front/back offsets, side view facing right), shaded from its own
distance field as a rounded tube lit from the top left, with an ink rim so
the joints read as separate segments - the wooden-drawing-mannequin look,
and the same inked language as the rest of the world.

Canvas, pivot and bone end of every part come from docs/wardrobe/rig_spec.json
(1 pixel = 1 REF_H pixel), so the parts hang on FigureRig's bones exactly
like any painted item.

    python3 tools/wardrobe_mannequin.py
"""

import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "assets", "characters", "wardrobe")
SPEC = json.load(open(os.path.join(ROOT, "docs", "wardrobe", "rig_spec.json")))

SS = 4                       # supersampling
ALBEDO = 0.86                # light grey: the game multiplies a colour in
AMBIENT, DIFFUSE = 0.50, 0.62
LIGHT = np.array([-0.45, -0.62, 0.64])   # from the top left, towards the viewer
INK = np.array([0.13, 0.11, 0.10])
INK_PX = 5.0                 # rim width in REF px: ~1 screen px on the road

GENDERS = ("female", "male")
WEIGHTS = ("lean", "average", "heavy")
# Limb thickness per body weight; the torso has its own belly term.
WEIGHT_SCALE = {"lean": 0.88, "average": 1.0, "heavy": 1.16}
DEFAULT = ("male", "average")    # wardrobe/body/ - crew and enemies


def _interp(table, t):
    ts = [row[0] for row in table]
    return [float(np.interp(t, ts, [row[k] for row in table])) for k in range(1, len(table[0]))]


def limb_discs(pivot, end, table, scale, samples=90):
    """Discs along pivot->end. `table` rows are (t, radius, front_offset);
    t outside 0..1 rounds the ends. Front is the bone's right-hand normal,
    which is forward for every downward bone of a right-facing figure."""
    p, e = np.array(pivot, float), np.array(end, float)
    u = (e - p) / np.linalg.norm(e - p)
    front = np.array([-u[1], u[0]]) * -1.0
    length = np.linalg.norm(e - p)
    discs = []
    for t in np.linspace(table[0][0], table[-1][0], samples):
        r, off = _interp(table, t)
        c = p + u * t * length + front * off * scale
        discs.append((c[0], c[1], r * scale))
    return discs


def torso_discs(pivot, end, gender, weight):
    """Side-view profile, shoulder (t=0) to hip (t=1): (t, front, back) in
    REF px from the spine line. Bust and a longer seat for women, a belly
    for the heavy build."""
    if gender == "female":
        table = [(-0.13, 8, -10), (-0.04, 20, -22), (0.05, 24, -25), (0.22, 33, -26), (0.34, 28, -23),
                 (0.56, 17, -18), (0.82, 19, -25), (1.0, 20, -28), (1.10, 14, -22), (1.16, 6, -10)]
    else:
        table = [(-0.13, 8, -10), (-0.04, 22, -24), (0.05, 27, -28), (0.18, 31, -29), (0.34, 28, -26),
                 (0.56, 20, -20), (0.82, 20, -22), (1.0, 20, -24), (1.10, 14, -18), (1.16, 6, -8)]
    k = WEIGHT_SCALE[weight] ** 0.7
    p, e = np.array(pivot, float), np.array(end, float)
    length = np.linalg.norm(e - p)
    discs = []
    for t in np.linspace(table[0][0], table[-1][0], 120):
        front, back = _interp(table, t)
        if weight == "heavy":
            bell = np.exp(-((t - 0.70) / 0.2) ** 2)
            front += 15 * bell
            back -= 3 * bell
        front, back = front * k, back * k
        c = p + np.array([0.0, 1.0]) * t * length
        discs.append((c[0] + (front + back) / 2, c[1], (front - back) / 2))
    return discs


def head_discs(pivot, end, gender, weight):
    """Neck from the shoulder point up, then a faceless skull with a nose
    and chin so the figure still reads which way it faces."""
    px, py = pivot
    ex, ey = end
    neck = {"female": 8.0, "male": 9.5}[gender] * {"lean": 0.92, "average": 1.0, "heavy": 1.15}[weight]
    discs = [(px + (ex - px) * s, py + (ey + 26 - py) * s, neck) for s in np.linspace(0, 1, 24)]
    jaw = 1.12 if weight == "heavy" else (0.95 if gender == "female" else 1.0)
    discs += [
        (ex - 2, ey - 3, 27.0),            # cranium
        (ex - 12, ey, 22.0),               # occiput
        (ex + 8, ey + 8, 18.0 * jaw),      # cheek and jaw
        (ex + 14, ey + 20, 8.0 * jaw),     # chin
        (ex + 24, ey + 4, 4.2),            # nose
    ]
    return discs


LIMBS = {
    # part: (t, radius, front offset) - REF px at average build. A side view
    # thigh is about two thirds of the torso's depth; thinner reads as stilts.
    "thigh": [(-0.10, 19.0, 0), (0.0, 20.5, 0.5), (0.28, 19.5, 2.5), (0.62, 15.5, 1.0), (0.92, 13.0, 0), (1.06, 12.4, 0)],
    "shin": [(-0.07, 13.0, 0), (0.0, 13.2, 0), (0.25, 14.8, -3.0), (0.58, 11.0, -0.6), (0.94, 8.8, 0), (1.05, 8.6, 0)],
    "upper_arm": [(-0.10, 12.5, 0), (0.0, 13.0, 0), (0.16, 13.5, 1.2), (0.60, 11.0, 0), (1.0, 9.8, 0), (1.08, 9.4, 0)],
    "forearm": [(-0.08, 9.8, 0), (0.0, 10.0, 0), (0.25, 11.0, -1.2), (0.70, 8.6, 0), (1.0, 7.4, 0), (1.05, 7.0, 0)],
    "hand": [(-0.20, 7.0, 0), (0.0, 7.8, 0), (0.50, 8.4, 0.6), (1.0, 6.8, 0), (1.25, 5.4, 0)],
}


def path_discs(points, samples=80):
    """Discs along a polyline of (x, y, r) control points, densely
    interpolated - a few loose discs read as a string of beads."""
    pts = np.array(points, float)
    seg = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(pts[:, :2], axis=0), axis=1))]
    at = np.linspace(0.0, seg[-1], samples)
    return [tuple(np.interp(a, seg, pts[:, k]) for k in range(3)) for a in at]


def foot_discs(pivot, end, scale):
    """Heel, ankle, instep, ball, toe: a flat-soled foot on the ground line."""
    px, py = pivot
    ex, _ = end
    return [(x, y, r * scale) for x, y, r in path_discs([
        (px - 8, py - 4, 8.5), (px + 2, py - 6, 9.5), (px + 16, py - 2, 7.5),
        (ex + 3, py + 1, 6.8), (ex + 11, py + 2.2, 5.2),
    ])]


def discs_for(part, gender, weight):
    spec = SPEC["parts"][part]
    pivot, end = spec["pivot"], spec["end"]
    limb_scale = WEIGHT_SCALE[weight] * (0.93 if gender == "female" else 1.0)
    if part == "torso":
        return torso_discs(pivot, end, gender, weight)
    if part == "head":
        return head_discs(pivot, end, gender, weight)
    if part == "foot":
        return foot_discs(pivot, end, 0.94 if gender == "female" else 1.0)
    if part == "hand":
        # A mitten with a thumb: hands grip, they do not wave.
        discs = limb_discs(pivot, end, LIMBS["hand"], 0.94 if gender == "female" else 1.0)
        p, e = np.array(pivot, float), np.array(end, float)
        u = (e - p) / np.linalg.norm(e - p)
        thumb = p + u * 0.35 * np.linalg.norm(e - p) + np.array([u[1], -u[0]]) * 4.0
        return discs + [(thumb[0], thumb[1], 4.6)]
    return limb_discs(pivot, end, LIMBS[part], limb_scale)


def render(part, gender, weight):
    w, h = SPEC["parts"][part]["canvas"]
    W, H = w * SS, h * SS
    yy, xx = np.mgrid[0:H, 0:W]
    mask = np.zeros((H, W), bool)
    for cx, cy, r in discs_for(part, gender, weight):
        cx, cy, r = cx * SS, cy * SS, r * SS
        x0, x1 = max(0, int(cx - r - 2)), min(W, int(cx + r + 3))
        y0, y1 = max(0, int(cy - r - 2)), min(H, int(cy + r + 3))
        if x0 >= x1 or y0 >= y1:
            continue
        sub = (xx[y0:y1, x0:x1] - cx) ** 2 + (yy[y0:y1, x0:x1] - cy) ** 2 <= r * r
        mask[y0:y1, x0:x1] |= sub
    # Nothing may touch the canvas edge, or the rim would be cut open.
    mask[:SS * 2, :] = mask[-SS * 2:, :] = False
    mask[:, :SS * 2] = mask[:, -SS * 2:] = False

    dist = ndimage.distance_transform_edt(mask)
    radius = max(np.percentile(dist[mask], 99), 1.0)
    d = np.minimum(dist, radius)
    height = np.sqrt(np.clip(d * (2 * radius - d), 0, None))
    height = ndimage.gaussian_filter(height, SS * 1.2)
    gy, gx = np.gradient(height)
    normal = np.dstack([-gx, -gy, np.full_like(gx, 1.0)])
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    light = LIGHT / np.linalg.norm(LIGHT)
    lambert = np.clip(normal @ light, 0, 1)
    shade = np.clip(ALBEDO * (AMBIENT + DIFFUSE * lambert), 0, 1)

    rgb = np.dstack([shade] * 3)
    rim = mask & (dist <= INK_PX * SS)
    rgb[rim] = INK
    rgba = np.dstack([rgb, mask.astype(float)])
    # Filter down in premultiplied alpha, as the beast renders do.
    pre = rgba.copy()
    pre[..., :3] *= pre[..., 3:4]
    pre = pre.reshape(h, SS, w, SS, 4).mean(axis=(1, 3))
    a = pre[..., 3:4]
    pre[..., :3] = np.where(a > 1e-6, pre[..., :3] / np.maximum(a, 1e-6), 0.0)
    return Image.fromarray((np.clip(pre, 0, 1) * 255).round().astype(np.uint8), "RGBA")


BODY_PARTS = ("head", "torso", "upper_arm", "forearm", "hand", "thigh", "shin", "foot")


def main():
    for gender in GENDERS:
        for weight in WEIGHTS:
            ids = ["body_%s_%s" % (gender, weight)]
            if (gender, weight) == DEFAULT:
                ids.append("body")
            for part in BODY_PARTS:
                img = render(part, gender, weight)
                for item_id in ids:
                    folder = os.path.join(OUT, item_id)
                    os.makedirs(folder, exist_ok=True)
                    img.save(os.path.join(folder, part + ".png"), optimize=True)
            print("wrote", ", ".join(ids))


if __name__ == "__main__":
    main()
