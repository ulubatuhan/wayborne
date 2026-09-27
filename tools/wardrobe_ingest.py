"""Turn finished wardrobe art into the per-part PNGs the game reads.

The game looks for data/assets/characters/wardrobe/<item_id>/<part>.png
(see scripts/character/wardrobe.gd). <item_id> is an OutfitPiece or
Equipment id - hat_felt, jacket_wool, armor_tier_2, weapon_tier_1 ...

Two ways in:

1. A part sheet painted over docs/wardrobe/part_sheet_template.png (3x3
   cells of 256x384 = 768x1152, or any image of the same 2:3 shape - it is
   rescaled). Every cell that has art becomes that part; empty cells are
   skipped, so a pair of boots only fills "shin" and "foot".

       python3 tools/wardrobe_ingest.py sheet boots_sheet.png shoes_boots

2. A single image of one part, e.g. a sword painted on its own. The art's
   bounding box is scaled to fit the part canvas and placed on the pivot
   (for a weapon: the grip sits on the pivot, blade hanging down).

       python3 tools/wardrobe_ingest.py part sword.png weapon_tier_1 weapon

Transparency: Gemini exports JPG, so remove the background first (the
person generating the art does this) and hand in a PNG with alpha. If the
image has no alpha at all, --key removes a flat backdrop by the colour of
its corners.

After ingesting, run `godot --headless --import` so the game imports the
new PNGs (the game also reads a not-yet-imported PNG straight from disk).
"""

import argparse
import json
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(ROOT, "docs", "wardrobe", "rig_spec.json")
WARDROBE = os.path.join(ROOT, "data", "assets", "characters", "wardrobe")
CELL = (256, 384)
COLUMNS = 3
# A cell with no pixel more opaque than this is empty.
MIN_ALPHA = 24
# --key: distance (0-255 RGB) from the corner colour that counts as backdrop.
KEY_TOLERANCE = 38.0
KEY_RAMP = 22.0
# Single-part placement: share of the part canvas the art may fill.
FIT = 0.92
# A lone weapon: how far above the grip (pivot) the pommel starts, as a
# share of the weapon's height. Swords and axes are gripped near the top.
WEAPON_GRIP = 0.16


def load_rgba(path, key):
    image = Image.open(path).convert("RGBA")
    rgba = np.asarray(image).astype(np.float32)
    if key or rgba[..., 3].min() >= 255.0:
        if not key:
            print("  ! image has no transparency - pass --key to remove a flat backdrop")
        else:
            corners = np.array([rgba[0, 0, :3], rgba[0, -1, :3], rgba[-1, 0, :3], rgba[-1, -1, :3]])
            backdrop = np.median(corners, axis=0)
            distance = np.sqrt(((rgba[..., :3] - backdrop) ** 2).sum(axis=2))
            rgba[..., 3] = np.clip((distance - KEY_TOLERANCE) / KEY_RAMP, 0.0, 1.0) * 255.0
    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


def out_dir(item_id):
    path = os.path.join(WARDROBE, item_id)
    os.makedirs(path, exist_ok=True)
    return path


def ingest_sheet(spec, path, item_id, key):
    order = spec["part_order"]
    rows = (len(order) + COLUMNS - 1) // COLUMNS
    size = (CELL[0] * COLUMNS, CELL[1] * rows)
    image = load_rgba(path, key)
    aspect = image.width / image.height
    if abs(aspect - size[0] / size[1]) > 0.02:
        print(f"  ! sheet is {image.width}x{image.height}, expected a {size[0]}x{size[1]} shape - rescaling anyway")
    if image.size != size:
        image = image.resize(size, Image.LANCZOS)
    written = []
    for index, part in enumerate(order):
        w, h = spec["parts"][part]["canvas"]
        cx, cy = (index % COLUMNS) * CELL[0], (index // COLUMNS) * CELL[1]
        ox, oy = (CELL[0] - w) // 2, (CELL[1] - h) // 2
        crop = image.crop((cx + ox, cy + oy, cx + ox + w, cy + oy + h))
        if np.asarray(crop)[..., 3].max() < MIN_ALPHA:
            continue
        crop.save(os.path.join(out_dir(item_id), part + ".png"), optimize=True)
        written.append(part)
    return written


def ingest_part(spec, path, item_id, part, key):
    entry = spec["parts"][part]
    w, h = entry["canvas"]
    px, py = entry["pivot"]
    image = load_rgba(path, key)
    alpha = np.asarray(image)[..., 3]
    ys, xs = np.nonzero(alpha >= MIN_ALPHA)
    if xs.size == 0:
        raise SystemExit("  ! no opaque pixels in " + path)
    art = image.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    if part == "weapon":
        top_room = h * FIT
        scale = min(w * FIT / art.width, top_room / art.height)
        art = art.resize((max(1, round(art.width * scale)), max(1, round(art.height * scale))), Image.LANCZOS)
        x = round(px - art.width / 2)
        y = round(py - art.height * WEAPON_GRIP)
        y = max(0, min(y, h - art.height))
    else:
        scale = min(w * FIT / art.width, h * FIT / art.height)
        art = art.resize((max(1, round(art.width * scale)), max(1, round(art.height * scale))), Image.LANCZOS)
        x = round((w - art.width) / 2)
        y = round((h - art.height) / 2)
    canvas.alpha_composite(art, (x, y))
    canvas.save(os.path.join(out_dir(item_id), part + ".png"), optimize=True)
    return [part]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="mode", required=True)
    sheet = sub.add_parser("sheet")
    sheet.add_argument("image")
    sheet.add_argument("item_id")
    sheet.add_argument("--key", action="store_true")
    single = sub.add_parser("part")
    single.add_argument("image")
    single.add_argument("item_id")
    single.add_argument("part")
    single.add_argument("--key", action="store_true")
    args = parser.parse_args()

    spec = json.load(open(SPEC))
    if args.mode == "sheet":
        written = ingest_sheet(spec, args.image, args.item_id, args.key)
    else:
        if args.part not in spec["parts"]:
            raise SystemExit("unknown part: %s (one of %s)" % (args.part, ", ".join(spec["part_order"])))
        written = ingest_part(spec, args.image, args.item_id, args.part, args.key)
    print("  %s -> %s" % (args.item_id, ", ".join(written) if written else "(nothing - every cell was empty)"))


if __name__ == "__main__":
    main()
