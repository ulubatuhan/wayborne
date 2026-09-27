"""Turn finished animal art into the per-part PNGs BeastRig reads.

The game looks for data/assets/characters/beasts/<layer>/<part>.png
(see scripts/character/beast_rig.gd). <layer> is a species (horse, ox, wolf,
bear, boar) or a layer drawn over it (horse_tack, ox_yoke).

Two ways in:

1. whole - ONE painting of the whole animal, side view facing right, in the
   mid-stride pose of docs/beasts/<species>_pose_reference.jpg. The tool
   fits the painting onto that pose (by its bounding box), assigns every
   pixel to the nearest bone's mannequin region, and unrotates each piece
   into its part canvas. The near and far legs come out separately (the far
   ones as <part>_far.png), because the pose keeps all four legs apart.

       python3 tools/beast_cut.py whole horse_painting.png horse

   A layer drawn over the animal (a saddle and bridle) cannot be fitted by
   its own bounding box - paint it on the pose canvas itself (1536x1024,
   same place as the animal) and pass --no-fit:

       python3 tools/beast_cut.py whole horse_tack.png horse_tack --species horse --no-fit

2. sheet - a part sheet painted over docs/beasts/<species>_sheet_template.png
   (3x3 cells of 384x256 = 1152x768). Every cell with art becomes that part.

       python3 tools/beast_cut.py sheet wolf_sheet.png wolf

Transparency: Gemini exports JPG, so remove the background first and hand in
a PNG with alpha; --key removes a flat backdrop by the colour of its corners.
After cutting run `godot --headless --import`.
"""

import argparse
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import beast_templates as bt  # noqa: E402
from wardrobe_ingest import load_rgba, MIN_ALPHA  # noqa: E402

ROOT = bt.ROOT
BEASTS = os.path.join(ROOT, "data", "assets", "characters", "beasts")
OUT_ROOT = [BEASTS]
# Mannequin regions are grown by this much before pixels are assigned: the
# painted animal is fuller than the mannequin.
REGION_GROW = 1.35
# Every piece keeps this many pixels of its neighbours, so a joint that bends
# shows fur, not a gap.
OVERLAP_PX = 6
# Which region wins where two overlap, lowest first: what is drawn nearer the
# viewer claims the pixel. The tail beats the body because it hangs over the
# rump in every painting even though the rig draws it underneath.
PRIORITY = [
    "hind_far_upper", "hind_far_lower", "hind_far_foot",
    "fore_far_upper", "fore_far_lower", "fore_far_foot",
    "body", "tail",
    "hind_near_upper", "hind_near_lower", "hind_near_foot",
    "fore_near_upper", "fore_near_lower", "fore_near_foot",
    "neck", "head",
]


def out_dir(layer):
    path = os.path.join(OUT_ROOT[0], layer)
    os.makedirs(path, exist_ok=True)
    return path


def grown_volume(species):
    v = dict(bt.VOLUME[species])
    for key, value in v.items():
        if isinstance(value, tuple):
            v[key] = (value[0] * REGION_GROW, value[1] * REGION_GROW)
        elif key in ("belly", "rump", "chest", "hump", "foot"):
            v[key] = value * REGION_GROW
    return v


def region_masks(spec, species):
    """bone -> boolean mask of its (grown) mannequin region on the pose canvas."""
    v = grown_volume(species)
    masks = {}
    for bone in PRIORITY:
        entry = spec["bones"][bone]
        image = Image.new("L", bt.PAINT_CANVAS, 0)
        draw = ImageDraw.Draw(image)
        bt.mannequin_part(draw, v, entry["part"], bt.paint_point(spec, species, entry["a"]),
                          bt.paint_point(spec, species, entry["b"]), bt.PAINT_SCALE, 255, 255)
        masks[bone] = np.asarray(image) > 0
    return masks


def fit_to_pose(image, spec, species):
    """Scale and move the painting so its bounding box sits on the pose's:
    same height-and-width scale (averaged), bottoms and centres aligned."""
    alpha = np.asarray(image)[..., 3]
    ys, xs = np.nonzero(alpha >= MIN_ALPHA)
    if xs.size == 0:
        raise SystemExit("  ! no opaque pixels")
    union = np.zeros(bt.PAINT_CANVAS[::-1], bool)
    for mask in region_masks(spec, species).values():
        union |= mask
    ry, rx = np.nonzero(union)
    scale = ((rx.max() - rx.min()) / (xs.max() - xs.min()) + (ry.max() - ry.min()) / (ys.max() - ys.min())) / 2
    src_c = ((xs.min() + xs.max()) / 2, ys.max())
    dst_c = ((rx.min() + rx.max()) / 2, ry.max())
    inv = 1.0 / scale
    # output (x, y) -> input: (x - dst) / scale + src
    data = (inv, 0, src_c[0] - dst_c[0] * inv, 0, inv, src_c[1] - dst_c[1] * inv)
    return image.transform(bt.PAINT_CANVAS, Image.AFFINE, data, resample=Image.BICUBIC)


def label_pixels(image, masks):
    alpha = np.asarray(image)[..., 3] >= MIN_ALPHA
    labels = np.zeros(alpha.shape, np.int32)
    for index, bone in enumerate(PRIORITY, start=1):
        labels[masks[bone]] = index
    # Painted pixels outside every region go to the nearest region.
    missing = alpha & (labels == 0)
    if missing.any():
        _, (iy, ix) = ndimage.distance_transform_edt(labels == 0, return_indices=True)
        labels[missing] = labels[iy[missing], ix[missing]]
    labels[~alpha] = 0
    return labels


def unrotate(piece, spec, species, bone):
    """The piece on the pose canvas -> its part canvas (pivot on the A joint,
    the bone lying along its rest direction), at REF_H scale."""
    entry = spec["bones"][bone]
    part = entry["part"]
    w, h = spec["parts"][part]["canvas"]
    pvx, pvy = spec["parts"][part]["pivot"]
    ex, ey = spec["species"][species]["ends"][part]
    a = bt.paint_point(spec, species, entry["a"])
    b = bt.paint_point(spec, species, entry["b"])
    theta = math.atan2(b[1] - a[1], b[0] - a[0]) - math.atan2(ey - pvy, ex - pvx)
    k = bt.PAINT_SCALE
    ca, sa = math.cos(theta) * k, math.sin(theta) * k
    data = (ca, -sa, a[0] - (ca * pvx - sa * pvy), sa, ca, a[1] - (sa * pvx + ca * pvy))
    return piece.transform((w, h), Image.AFFINE, data, resample=Image.BICUBIC)


def cut_whole(spec, path, layer, species, key, fit):
    image = load_rgba(path, key)
    if fit:
        image = fit_to_pose(image, spec, species)
    elif image.size != bt.PAINT_CANVAS:
        image = image.resize(bt.PAINT_CANVAS, Image.LANCZOS)
    masks = region_masks(spec, species)
    labels = label_pixels(image, masks)
    rgba = np.asarray(image)
    written = []
    for index, bone in enumerate(PRIORITY, start=1):
        own = labels == index
        if own.sum() < 40:
            continue
        keep = ndimage.binary_dilation(own, iterations=OVERLAP_PX) & (labels > 0)
        piece = rgba.copy()
        piece[..., 3] = np.where(keep, piece[..., 3], 0)
        out = unrotate(Image.fromarray(piece, "RGBA"), spec, species, bone)
        entry = spec["bones"][bone]
        # Fore and hind share one foot part; the fore foot (cut last) wins.
        name = entry["part"] + ("_far" if entry["far"] else "")
        out.save(os.path.join(out_dir(layer), name + ".png"), optimize=True)
        written.append(name)
    return written


def cut_sheet(spec, path, layer, key):
    cell = spec["cell"]
    order = spec["part_order"]
    rows = (len(order) + bt.COLUMNS - 1) // bt.COLUMNS
    size = (cell[0] * bt.COLUMNS, cell[1] * rows)
    image = load_rgba(path, key)
    if image.size != size:
        image = image.resize(size, Image.LANCZOS)
    written = []
    for index, part in enumerate(order):
        w, h = spec["parts"][part]["canvas"]
        cx, cy = (index % bt.COLUMNS) * cell[0], (index // bt.COLUMNS) * cell[1]
        ox, oy = (cell[0] - w) // 2, (cell[1] - h) // 2
        crop = image.crop((cx + ox, cy + oy, cx + ox + w, cy + oy + h))
        if np.asarray(crop)[..., 3].max() < MIN_ALPHA:
            continue
        crop.save(os.path.join(out_dir(layer), part + ".png"), optimize=True)
        written.append(part)
    return written


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="mode", required=True)
    whole = sub.add_parser("whole")
    whole.add_argument("image")
    whole.add_argument("layer")
    whole.add_argument("--species", help="skeleton to cut by (default: the layer name before '_')")
    whole.add_argument("--no-fit", action="store_true", help="the painting is already on the pose canvas")
    whole.add_argument("--key", action="store_true")
    sheet = sub.add_parser("sheet")
    sheet.add_argument("image")
    sheet.add_argument("layer")
    sheet.add_argument("--key", action="store_true")
    for p in (whole, sheet):
        p.add_argument("--out", help="write here instead of data/assets/characters/beasts")
    args = parser.parse_args()
    if args.out:
        OUT_ROOT[0] = args.out

    spec = json.load(open(bt.SPEC))
    if args.mode == "whole":
        species = args.species or args.layer.split("_")[0]
        if species not in spec["species"]:
            raise SystemExit("unknown species: %s (one of %s)" % (species, ", ".join(spec["species_order"])))
        written = cut_whole(spec, args.image, args.layer, species, args.key, not args.no_fit)
    else:
        written = cut_sheet(spec, args.image, args.layer, args.key)
    print("  %s -> %s" % (args.layer, ", ".join(written) if written else "(nothing)"))


if __name__ == "__main__":
    main()
