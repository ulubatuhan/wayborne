"""The pose a garment is painted in, drawn with the real mannequin.

`docs/wardrobe/rig_reference.png` shows the *rest* pose, which is the pose
each finished part PNG lives in - but it is useless to paint on, because
there the back limb hides exactly behind the front one. A jacket painted on
it would have no back sleeve to cut out. `FigureRig.paint_pose()` opens the
limbs (the human counterpart of `BeastRig.PAINT_PHASE`, same reasoning); this
tool draws the mannequin in that pose so the painter has a body to dress, and
`tools/wardrobe_cut.py` cuts the result back into the nine part canvases.

Unlike the beast tool, this does not draw a procedural stand-in: the real
mannequin art already exists (`tools/wardrobe_mannequin.py`), so the
reference is the body the game actually draws, hung on its own bones by the
same transform `FigureRig.part_transform()` uses.

    python3 tools/wardrobe_paint_reference.py

Writes `docs/wardrobe/paint_pose_<gender>_<weight>.png` plus a marker-free
`paint_pose_reference.png` (male/average) - the one handed to a painter.
"""

import json
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC_PATH = os.path.join(ROOT, "docs", "wardrobe", "rig_spec.json")
BODY_ROOT = os.path.join(ROOT, "data", "assets", "characters", "wardrobe")
OUT_DIR = os.path.join(ROOT, "docs", "wardrobe")

# The canvas every whole-figure painting lives on. Tall rather than wide: a
# standing person is, and the cut tool reads this same constant, so a painting
# delivered at this size needs no fitting at all.
CANVAS = (768, 1152)
# REF_H (512) figure px -> canvas px. Chosen so the body fills the frame with
# roughly a head's clearance all round - room for a hat, a hood's drape or a
# held weapon to reach past the silhouette without touching an edge, and no
# more, since every wasted pixel is detail the painter does not spend on the
# garment. `tools/wardrobe_cut.py` reads these three constants, so a painting
# delivered at this canvas size needs no fitting at all.
SCALE = 2.15
GROUND_Y = CANVAS[1] - 80

BACKDROP = (236, 236, 234, 255)
MARKER = (214, 58, 48, 255)
GROUND_LINE = (190, 190, 186, 255)

VARIANTS = [(g, w) for g in ("male", "female") for w in ("lean", "average", "heavy")]
DEFAULT = ("male", "average")


def load_spec():
    with open(SPEC_PATH) as handle:
        return json.load(handle)


def origin(spec):
    """Canvas position of the pose's (0,0) - the point on the ground the
    figure stands on. Centred horizontally over the pose's own extent, so an
    open stride does not drift off one side."""
    xs = [p[0] for p in spec["paint_joints"].values()]
    return (CANVAS[0] / 2 - (min(xs) + max(xs)) / 2 * SCALE, GROUND_Y)


def joint(spec, name):
    ox, oy = origin(spec)
    x, y = spec["paint_joints"][name]
    return (ox + x * SCALE, oy + y * SCALE)


def part_placement(spec, bone):
    """(pivot, rest_vector, a, b) for a bone, all in canvas pixels except
    pivot/rest_vector which stay in the part canvas's own space."""
    entry = spec["bones"][bone]
    part = spec["parts"][entry["part"]]
    pivot = tuple(part["pivot"])
    rest = (part["end"][0] - pivot[0], part["end"][1] - pivot[1])
    return pivot, rest, joint(spec, entry["a"]), joint(spec, entry["b"])


def paste_part(canvas, image, pivot, rest, a, b):
    """FigureRig.part_transform in PIL terms: put the part's pivot on joint A
    and turn its rest direction onto the bone's current direction."""
    if math.hypot(*rest) < 1e-4 or math.hypot(b[0] - a[0], b[1] - a[1]) < 1e-4:
        return
    theta = math.atan2(b[1] - a[1], b[0] - a[0]) - math.atan2(rest[1], rest[0])
    cos_t, sin_t = math.cos(theta) * SCALE, math.sin(theta) * SCALE
    # forward: out = A + R*(in - pivot). PIL needs the inverse, out -> in.
    det = cos_t * cos_t + sin_t * sin_t
    ia, ib = cos_t / det, sin_t / det
    ox = a[0] - (cos_t * pivot[0] - sin_t * pivot[1])
    oy = a[1] - (sin_t * pivot[0] + cos_t * pivot[1])
    data = (ia, ib, -ia * ox - ib * oy, -ib, ia, ib * ox - ia * oy)
    placed = image.transform(CANVAS, Image.AFFINE, data, resample=Image.BICUBIC)
    canvas.alpha_composite(placed)


def body_dir(gender, weight):
    path = os.path.join(BODY_ROOT, "body_%s_%s" % (gender, weight))
    return path if os.path.isdir(path) else os.path.join(BODY_ROOT, "body")


def render(spec, gender, weight, markers, transparent=False):
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0) if transparent else BACKDROP)
    draw = ImageDraw.Draw(canvas)
    if not transparent:
        draw.line([(0, GROUND_Y), (CANVAS[0], GROUND_Y)], fill=GROUND_LINE, width=2)

    source = body_dir(gender, weight)
    for bone in spec["draw_order"]:
        entry = spec["bones"].get(bone)
        if entry is None:
            continue
        path = os.path.join(source, "%s.png" % entry["part"])
        if not os.path.exists(path):
            continue
        image = Image.open(path).convert("RGBA")
        if entry.get("back"):
            # Wardrobe.BACK_SHADE: the game darkens a back limb that has no
            # art of its own. Without it the reference reads as one leg.
            red, green, blue, alpha = image.split()
            image = Image.merge("RGBA", (
                red.point(lambda v: int(v * 0.72)),
                green.point(lambda v: int(v * 0.72)),
                blue.point(lambda v: int(v * 0.72)),
                alpha,
            ))
        pivot, rest, a, b = part_placement(spec, bone)
        paste_part(canvas, image, pivot, rest, a, b)

    if markers:
        for name in spec["paint_joints"]:
            if name in ("weapon_tip", "toe_back", "toe_front"):
                continue
            x, y = joint(spec, name)
            draw.ellipse([x - 4, y - 4, x + 4, y + 4], fill=MARKER)
            draw.text((x + 7, y - 7), name, fill=(70, 70, 70, 255))
    return canvas


def main():
    spec = load_spec()
    for gender, weight in VARIANTS:
        image = render(spec, gender, weight, markers=True)
        path = os.path.join(OUT_DIR, "paint_pose_%s_%s.png" % (gender, weight))
        image.save(path)
        print("  ->", os.path.relpath(path, ROOT), CANVAS)
    clean = render(spec, DEFAULT[0], DEFAULT[1], markers=False)
    path = os.path.join(OUT_DIR, "paint_pose_reference.png")
    clean.save(path)
    print("  ->", os.path.relpath(path, ROOT), CANVAS, "(markersiz - ressama verilen)")


if __name__ == "__main__":
    main()
