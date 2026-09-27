"""Wardrobe templates for the artist (and for Gemini as a reference image).

Reads docs/wardrobe/rig_spec.json - written by tests/export_rig_spec.gd from
FigureRig, so the templates can never disagree with the game - and draws:

  docs/wardrobe/templates/<part>.png   one canvas per part, transparent,
                                       mannequin segment + joint markers
  docs/wardrobe/part_sheet_template.png  all nine parts on one 768x1152
                                       sheet (3x3 cells of 256x384) - the
                                       layout tools/wardrobe_ingest.py slices
  docs/wardrobe/rig_reference.png      the assembled mannequin in its rest
                                       pose, side view facing right

Red dot = the joint the part hangs from (pivot). Blue dot = the joint at the
other end of the bone in the rest pose. Paint the garment around the grey
mannequin; nothing of the markers may stay in the final art.

    python3 tools/wardrobe_templates.py
"""

import json
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(ROOT, "docs", "wardrobe", "rig_spec.json")
OUT = os.path.join(ROOT, "docs", "wardrobe")

CELL = (256, 384)
COLUMNS = 3
SHEET_BG = (236, 236, 236, 255)
MANNEQUIN = (150, 150, 156, 150)
MANNEQUIN_LINE = (96, 96, 104, 255)
PIVOT = (214, 40, 40, 255)
END = (40, 90, 214, 255)
BOX = (120, 120, 120, 255)

# Body volume around each bone at REF_H, start width -> end width (px). The
# procedural figure is a stick figure; clothing has to be drawn for a real
# body, so the mannequin carries that body.
WIDTHS = {
    "upper_arm": (26, 20),
    "forearm": (20, 16),
    "thigh": (40, 30),
    "shin": (28, 20),
}


def font(size):
    for path in ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def tapered(draw, a, b, w_a, w_b, fill, outline):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    length = max((dx * dx + dy * dy) ** 0.5, 0.001)
    nx, ny = -dy / length, dx / length
    poly = [(ax + nx * w_a / 2, ay + ny * w_a / 2), (bx + nx * w_b / 2, by + ny * w_b / 2),
            (bx - nx * w_b / 2, by - ny * w_b / 2), (ax - nx * w_a / 2, ay - ny * w_a / 2)]
    draw.polygon(poly, fill=fill, outline=outline)
    for point, w in [(a, w_a), (b, w_b)]:
        r = w / 2
        draw.ellipse([point[0] - r, point[1] - r, point[0] + r, point[1] + r], fill=fill, outline=outline)


def mannequin_part(draw, part, pivot, end, head_r):
    px, py = pivot
    ex, ey = end
    if part == "torso":
        draw.polygon([(px - 50, py), (px + 50, py), (ex + 39, ey + 10), (ex - 39, ey + 10)],
                     fill=MANNEQUIN, outline=MANNEQUIN_LINE)
    elif part == "head":
        draw.rectangle([px - 9, ey, px + 9, py], fill=MANNEQUIN, outline=MANNEQUIN_LINE)
        draw.ellipse([ex - head_r * 0.92, ey - head_r, ex + head_r * 0.92, ey + head_r],
                     fill=MANNEQUIN, outline=MANNEQUIN_LINE)
    elif part == "hand":
        draw.ellipse([px - 11, py - 11, px + 11, py + 11], fill=MANNEQUIN, outline=MANNEQUIN_LINE)
    elif part == "foot":
        # The ankle joint sits on the ground line: the sole is at the pivot.
        draw.polygon([(px - 12, py - 22), (px + 6, py - 22), (ex + 18, py - 8), (ex + 18, py),
                      (px - 14, py)], fill=MANNEQUIN, outline=MANNEQUIN_LINE)
    elif part == "weapon":
        # No body here: the hand closes around the grip at the pivot, the
        # blade hangs down past the blue marker.
        draw.line([pivot, end], fill=MANNEQUIN_LINE, width=3)
    else:
        w_a, w_b = WIDTHS[part]
        tapered(draw, pivot, end, w_a, w_b, MANNEQUIN, MANNEQUIN_LINE)


def markers(draw, pivot, end):
    for point, colour in [(pivot, PIVOT), (end, END)]:
        x, y = point
        draw.ellipse([x - 5, y - 5, x + 5, y + 5], fill=colour)
        draw.line([(x - 10, y), (x + 10, y)], fill=colour, width=1)
        draw.line([(x, y - 10), (x, y + 10)], fill=colour, width=1)


def part_canvas(spec, part, background=(0, 0, 0, 0)):
    entry = spec["parts"][part]
    w, h = entry["canvas"]
    image = Image.new("RGBA", (w, h), background)
    draw = ImageDraw.Draw(image, "RGBA")
    mannequin_part(draw, part, tuple(entry["pivot"]), tuple(entry["end"]), spec["head_radius"])
    markers(draw, tuple(entry["pivot"]), tuple(entry["end"]))
    draw.rectangle([0, 0, w - 1, h - 1], outline=BOX)
    return image


def cell_offset(spec, part):
    w, h = spec["parts"][part]["canvas"]
    return ((CELL[0] - w) // 2, (CELL[1] - h) // 2)


def sheet(spec):
    order = spec["part_order"]
    rows = (len(order) + COLUMNS - 1) // COLUMNS
    image = Image.new("RGBA", (CELL[0] * COLUMNS, CELL[1] * rows), SHEET_BG)
    draw = ImageDraw.Draw(image, "RGBA")
    label = font(18)
    for index, part in enumerate(order):
        cx, cy = (index % COLUMNS) * CELL[0], (index // COLUMNS) * CELL[1]
        draw.rectangle([cx, cy, cx + CELL[0] - 1, cy + CELL[1] - 1], outline=(200, 200, 200, 255))
        ox, oy = cell_offset(spec, part)
        image.alpha_composite(part_canvas(spec, part), (cx + ox, cy + oy))
        draw.text((cx + 8, cy + 6), part, fill=(90, 90, 90, 255), font=label)
    return image


def reference(spec):
    joints = {k: tuple(v) for k, v in spec["rest_joints"].items()}
    ref_h = spec["ref_h"]
    width, height = 360, int(ref_h) + 40
    ox, oy = 150, height - 20
    image = Image.new("RGBA", (width, height), SHEET_BG)
    draw = ImageDraw.Draw(image, "RGBA")

    def at(name):
        x, y = joints[name]
        return (ox + x, oy + y)

    tapered(draw, at("shoulder"), at("elbow_back"), 26, 20, MANNEQUIN, MANNEQUIN_LINE)
    tapered(draw, at("elbow_back"), at("hand_back"), 20, 16, MANNEQUIN, MANNEQUIN_LINE)
    for side in ["back", "front"]:
        tapered(draw, at("hip"), at("knee_" + side), 40, 30, MANNEQUIN, MANNEQUIN_LINE)
        tapered(draw, at("knee_" + side), at("ankle_" + side), 28, 20, MANNEQUIN, MANNEQUIN_LINE)
        ax, ay = at("ankle_" + side)
        draw.polygon([(ax - 12, ay - 22), (ax + 6, ay - 22), (ax + 42, ay - 8), (ax + 42, ay),
                      (ax - 14, ay)], fill=MANNEQUIN, outline=MANNEQUIN_LINE)
    sx, sy = at("shoulder")
    hx, hy = at("hip")
    draw.polygon([(sx - 50, sy), (sx + 50, sy), (hx + 39, hy + 10), (hx - 39, hy + 10)],
                 fill=MANNEQUIN, outline=MANNEQUIN_LINE)
    cx, cy = at("head")
    r = spec["head_radius"]
    draw.ellipse([cx - r * 0.92, cy - r, cx + r * 0.92, cy + r], fill=MANNEQUIN, outline=MANNEQUIN_LINE)
    draw.line([at("hand_front"), at("weapon_tip")], fill=MANNEQUIN_LINE, width=3)
    tapered(draw, at("shoulder"), at("elbow_front"), 26, 20, MANNEQUIN, MANNEQUIN_LINE)
    tapered(draw, at("elbow_front"), at("hand_front"), 20, 16, MANNEQUIN, MANNEQUIN_LINE)
    for name in joints:
        x, y = at(name)
        draw.ellipse([x - 3, y - 3, x + 3, y + 3], fill=PIVOT)
    draw.line([(0, oy), (width, oy)], fill=(160, 160, 160, 255))
    small = font(11)
    for name in ["shoulder", "hip", "head", "knee_front", "ankle_front", "elbow_front", "hand_front"]:
        x, y = at(name)
        draw.text((x + 8, y - 6), name, fill=(60, 60, 60, 255), font=small)
    return image


def main():
    spec = json.load(open(SPEC))
    os.makedirs(os.path.join(OUT, "templates"), exist_ok=True)
    for part in spec["part_order"]:
        path = os.path.join(OUT, "templates", part + ".png")
        part_canvas(spec, part).save(path, optimize=True)
        print("  ->", os.path.relpath(path, ROOT))
    for name, image in [("part_sheet_template.png", sheet(spec)), ("rig_reference.png", reference(spec))]:
        path = os.path.join(OUT, name)
        image.save(path, optimize=True)
        print("  ->", os.path.relpath(path, ROOT), image.size)


if __name__ == "__main__":
    main()
