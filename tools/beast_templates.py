"""Animal part-sheet templates for the artist (and for Gemini as a reference).

Reads docs/beasts/beast_rig_spec.json - written by tests/export_rig_spec.gd
from BeastRig, so the templates can never disagree with the game - and draws,
for every species (horse, ox, wolf, bear, boar):

  docs/beasts/<species>_sheet_template.png   1152x768, 3x3 cells of 384x256,
                                             one body part per cell: grey
                                             mannequin + joint markers - the
                                             layout tools/wardrobe_ingest.py
                                             ("beast" mode) slices
  docs/beasts/<species>_reference.png        the assembled mannequin in its
                                             rest pose, side view facing right
  docs/beasts/<species>_pose_reference.jpg   1536x1024: the pose a WHOLE
                                             animal is painted in (mid-stride,
                                             far legs darker) - the reference
                                             image for Gemini; tools/beast_cut.py
                                             cuts that painting into parts

Red dot = the joint the part hangs from (pivot). Blue dot = the joint at the
other end of the bone in the rest pose. Paint the animal around the grey
mannequin; nothing of the markers may stay in the final art.

    python3 tools/beast_templates.py
"""

import json
import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(ROOT, "docs", "beasts", "beast_rig_spec.json")
OUT = os.path.join(ROOT, "docs", "beasts")

COLUMNS = 3
SHEET_BG = (236, 236, 236, 255)
MANNEQUIN = (150, 150, 156, 150)
MANNEQUIN_LINE = (96, 96, 104, 255)
PIVOT = (214, 40, 40, 255)
END = (40, 90, 214, 255)
BOX = (120, 120, 120, 255)

# Body volume per species at REF_H (256 px): belly depth below the back line,
# rump behind the hip, chest ahead of the shoulder, hump over the withers, and
# start->end widths of the tapered parts.
VOLUME = {
    "horse": {"belly": 92, "rump": 30, "chest": 26, "hump": 0, "neck": (54, 34), "head": (40, 22),
              "tail": (14, 8), "fore_upper": (30, 18), "fore_lower": (16, 12),
              "hind_upper": (46, 20), "hind_lower": (18, 12), "foot": 14, "ears": 1},
    "ox": {"belly": 100, "rump": 26, "chest": 28, "hump": 30, "neck": (58, 40), "head": (42, 30),
           "tail": (8, 6), "fore_upper": (34, 20), "fore_lower": (18, 14),
           "hind_upper": (48, 22), "hind_lower": (20, 14), "foot": 14, "ears": 0},
    "wolf": {"belly": 58, "rump": 20, "chest": 22, "hump": 0, "neck": (44, 30), "head": (34, 14),
             "tail": (22, 10), "fore_upper": (22, 14), "fore_lower": (12, 10),
             "hind_upper": (34, 14), "hind_lower": (14, 10), "foot": 12, "ears": 1},
    "bear": {"belly": 96, "rump": 30, "chest": 30, "hump": 18, "neck": (66, 52), "head": (50, 30),
             "tail": (10, 6), "fore_upper": (40, 30), "fore_lower": (30, 26),
             "hind_upper": (50, 30), "hind_lower": (30, 24), "foot": 18, "ears": 1},
    "boar": {"belly": 82, "rump": 22, "chest": 26, "hump": 16, "neck": (62, 50), "head": (48, 22),
             "tail": (6, 4), "fore_upper": (28, 18), "fore_lower": (14, 10),
             "hind_upper": (38, 18), "hind_lower": (14, 10), "foot": 12, "ears": 1},
}


def font(size):
    for path in ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def tapered(draw, a, b, w_a, w_b, fill=MANNEQUIN, outline=MANNEQUIN_LINE):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    length = max(math.hypot(dx, dy), 0.001)
    nx, ny = -dy / length, dx / length
    poly = [(ax + nx * w_a / 2, ay + ny * w_a / 2), (bx + nx * w_b / 2, by + ny * w_b / 2),
            (bx - nx * w_b / 2, by - ny * w_b / 2), (ax - nx * w_a / 2, ay - ny * w_a / 2)]
    draw.polygon(poly, fill=fill, outline=outline)
    for point, w in [(a, w_a), (b, w_b)]:
        r = w / 2
        draw.ellipse([point[0] - r, point[1] - r, point[0] + r, point[1] + r], fill=fill, outline=outline)


def body_polygon(v, pivot, end, k=1.0):
    (px, py), (ex, ey) = pivot, end
    belly, rump, chest, hump = v["belly"] * k, v["rump"] * k, v["chest"] * k, v["hump"] * k
    poly = [(px - rump, py + belly * 0.35), (px - rump * 0.4, py - 6 * k), (px, py - 8 * k)]
    if hump:
        poly += [((px + ex) / 2 + (ex - px) * 0.25, py - 10 * k), (ex - 10 * k, ey - hump)]
    poly += [(ex, ey - 6 * k), (ex + chest, ey + belly * 0.45), ((px + ex) / 2, ey + belly),
             (px - rump * 0.3, py + belly * 0.9)]
    return poly


def body_shape(draw, v, pivot, end, k=1.0, fill=MANNEQUIN, outline=MANNEQUIN_LINE):
    draw.polygon(body_polygon(v, pivot, end, k), fill=fill, outline=outline)


def head_shape(draw, v, pivot, end, k=1.0, fill=MANNEQUIN, outline=MANNEQUIN_LINE):
    w_a, w_b = v["head"]
    tapered(draw, pivot, end, w_a * k, w_b * k, fill, outline)
    if v["ears"]:
        px, py = pivot
        draw.polygon([(px - 6 * k, py - w_a * k * 0.3), (px - 2 * k, py - w_a * k * 0.95),
                      (px + 8 * k, py - w_a * k * 0.35)], fill=fill, outline=outline)


def foot_shape(draw, v, pivot, end, k=1.0, fill=MANNEQUIN, outline=MANNEQUIN_LINE):
    # The foot joint sits on the ground line: the sole is at the pivot.
    (px, py), (ex, _) = pivot, end
    height = v["foot"] * k
    draw.polygon([(px - 8 * k, py - height), (ex - 2 * k, py - height * 0.6), (ex + 4 * k, py),
                  (px - 10 * k, py)], fill=fill, outline=outline)


def mannequin_part(draw, v, part, pivot, end, k=1.0, fill=MANNEQUIN, outline=MANNEQUIN_LINE):
    if part == "body":
        body_shape(draw, v, pivot, end, k, fill, outline)
    elif part == "head":
        head_shape(draw, v, pivot, end, k, fill, outline)
    elif part == "foot":
        foot_shape(draw, v, pivot, end, k, fill, outline)
    else:
        w_a, w_b = v[part]
        tapered(draw, pivot, end, w_a * k, w_b * k, fill, outline)


def markers(draw, pivot, end):
    for point, colour in [(pivot, PIVOT), (end, END)]:
        x, y = point
        draw.ellipse([x - 5, y - 5, x + 5, y + 5], fill=colour)
        draw.line([(x - 10, y), (x + 10, y)], fill=colour, width=1)
        draw.line([(x, y - 10), (x, y + 10)], fill=colour, width=1)


def part_canvas(spec, species, part):
    entry = spec["parts"][part]
    w, h = entry["canvas"]
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    pivot = tuple(entry["pivot"])
    end = tuple(spec["species"][species]["ends"][part])
    mannequin_part(draw, VOLUME[species], part, pivot, end)
    markers(draw, pivot, end)
    draw.rectangle([0, 0, w - 1, h - 1], outline=BOX)
    return image


def sheet(spec, species):
    cell = spec["cell"]
    order = spec["part_order"]
    rows = (len(order) + COLUMNS - 1) // COLUMNS
    image = Image.new("RGBA", (cell[0] * COLUMNS, cell[1] * rows), SHEET_BG)
    draw = ImageDraw.Draw(image, "RGBA")
    label = font(18)
    for index, part in enumerate(order):
        cx, cy = (index % COLUMNS) * cell[0], (index // COLUMNS) * cell[1]
        draw.rectangle([cx, cy, cx + cell[0] - 1, cy + cell[1] - 1], outline=(200, 200, 200, 255))
        w, h = spec["parts"][part]["canvas"]
        image.alpha_composite(part_canvas(spec, species, part), (cx + (cell[0] - w) // 2, cy + (cell[1] - h) // 2))
        draw.text((cx + 8, cy + 6), "%s · %s" % (species, part), fill=(90, 90, 90, 255), font=label)
    return image


def reference(spec, species):
    joints = {k: tuple(v) for k, v in spec["species"][species]["rest_joints"].items()}
    width, height = 560, 320
    ox, oy = 250, height - 30
    image = Image.new("RGBA", (width, height), SHEET_BG)
    draw = ImageDraw.Draw(image, "RGBA")
    v = VOLUME[species]

    def at(name):
        x, y = joints[name]
        return (ox + x, oy + y)

    for bone in spec["draw_order"]:
        entry = spec["bones"][bone]
        fill = (120, 120, 126, 150) if entry["far"] else MANNEQUIN
        mannequin_part(draw, v, entry["part"], at(entry["a"]), at(entry["b"]), fill=fill)
    for name in joints:
        x, y = at(name)
        draw.ellipse([x - 3, y - 3, x + 3, y + 3], fill=PIVOT)
    draw.line([(0, oy), (width, oy)], fill=(160, 160, 160, 255))
    draw.text((10, 8), species, fill=(60, 60, 60, 255), font=font(16))
    return image


# The whole-animal painting canvas (tools/beast_cut.py reads the same numbers).
PAINT_CANVAS = (1536, 1024)
PAINT_SCALE = 2.6
PAINT_GROUND = 950


def paint_origin(spec, species):
    """Where the paint pose's ground point sits on the painting canvas: the
    animal centred horizontally, feet on PAINT_GROUND."""
    joints = spec["species"][species]["paint_joints"].values()
    xs = [p[0] for p in joints]
    return (PAINT_CANVAS[0] / 2 - (min(xs) + max(xs)) / 2 * PAINT_SCALE, PAINT_GROUND)


def paint_point(spec, species, name):
    ox, oy = paint_origin(spec, species)
    x, y = spec["species"][species]["paint_joints"][name]
    return (ox + x * PAINT_SCALE, oy + y * PAINT_SCALE)


def paint_reference(spec, species, markers_on=True):
    """The pose a whole animal is painted in: mid-stride, four legs apart,
    flat grey ground, far legs a shade darker."""
    image = Image.new("RGBA", PAINT_CANVAS, (140, 140, 140, 255))
    draw = ImageDraw.Draw(image, "RGBA")
    v = VOLUME[species]
    for bone in spec["draw_order"]:
        entry = spec["bones"][bone]
        fill = (96, 96, 102, 255) if entry["far"] else (190, 190, 196, 255)
        mannequin_part(draw, v, entry["part"], paint_point(spec, species, entry["a"]),
                       paint_point(spec, species, entry["b"]), PAINT_SCALE, fill, (40, 40, 44, 255))
    if markers_on:
        draw.line([(0, PAINT_GROUND), (PAINT_CANVAS[0], PAINT_GROUND)], fill=(70, 70, 70, 255), width=2)
    return image


def main():
    spec = json.load(open(SPEC))
    for species in spec["species_order"]:
        for name, image in [("%s_sheet_template.png" % species, sheet(spec, species)),
                            ("%s_reference.png" % species, reference(spec, species))]:
            path = os.path.join(OUT, name)
            image.save(path, optimize=True)
            print("  ->", os.path.relpath(path, ROOT), image.size)
        path = os.path.join(OUT, "%s_pose_reference.jpg" % species)
        paint_reference(spec, species).convert("RGB").save(path, quality=90)
        print("  ->", os.path.relpath(path, ROOT), PAINT_CANVAS)


if __name__ == "__main__":
    main()
