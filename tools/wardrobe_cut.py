"""Cut one whole-figure garment painting into the rig's nine part canvases.

The human counterpart of `tools/beast_cut.py whole`, and it exists for the
same measured reason. Asking an image model for nine disjoint parts aligned
to joint markers (`tools/wardrobe_ingest.py sheet`) failed seven rounds
running - the same wall the animals hit before `beast_cut.py whole` replaced
it. One coherent side view is something a painter, a model or a 3D render can
all deliver; nine aligned cells is not.

So the garment is painted ONCE, worn, in `FigureRig.paint_pose()` - the pose
`tools/wardrobe_paint_reference.py` draws the mannequin in - and this tool
gives every painted pixel to the bone whose body region it sits on, then
unrotates each piece into that part's own canvas, where the game expects it.

    python3 tools/wardrobe_cut.py jacket_painting.png jacket_wool
    python3 tools/wardrobe_cut.py sword.png weapon_tier_2 --only weapon
    python3 tools/wardrobe_cut.py hood.jpg hat_hood --key

The painting must be on `wardrobe_paint_reference.py`'s canvas (768x1152),
which is what the painter paints over, so nothing is scaled or fitted here -
unlike the beast tool, whose paintings arrive at arbitrary sizes. A delivery
at a different size is rejected rather than guessed at.

Only the garment is drawn, not the body under it: each item is its own layer
in `Wardrobe.SLOT_LAYERS`, so a jacket carrying a copy of the torso would
paint over the shirt beneath it.
"""

import argparse
import json
import math
import os

import numpy as np
from PIL import Image
from scipy import ndimage

import wardrobe_paint_reference as ref

ROOT = ref.ROOT
OUT_ROOT = os.path.join(ROOT, "data", "assets", "characters", "wardrobe")

MIN_ALPHA = 24
# How far a bone's body region reaches past the mannequin, in canvas px. A
# garment is bigger than the limb inside it; without this, a sleeve's cuff
# falls outside every region and is decided by the nearest-region fallback
# alone, which near a joint can pick the wrong side of it.
REGION_GROW = 14
# A piece keeps this much of its neighbour so a bent joint shows cloth rather
# than a gap - beast_cut.py's OVERLAP_PX, same reason. Measured, not guessed:
# rebuild the mannequin from its own cut parts and redraw it in the *rest*
# pose (the furthest pose from the one it was cut in, so every region that
# hid behind the torso while painting has swung into view), then count the
# silhouette the rebuild loses. A hole shows the background through the cloth
# and reads as a bug; an overlap only lays cloth on matching cloth, so the
# two errors are not worth the same and the sweep is read with that in mind:
#
#   grow/overlap   14/6    14/12   14/20   22/12   22/20   30/20
#   holes          4.95%   4.16%   3.41%   5.19%   4.33%   5.27%
#   overlap        5.28%   6.63%   9.16%   8.95%   11.43%  14.03%
#
# 14/12 nearly halves the holes for a little overlap. Growing the regions
# further makes it *worse* in both columns - an over-grown region steals its
# neighbour's pixels, which is the stacked-fur failure beast_cut.py already
# recorded. In the pose the garment is actually painted in, 14/12 loses
# 0.04% of the silhouette.
OVERLAP_PX = 12
# A back limb's piece is kept only if it recovered at least this share of its
# front counterpart's area; below it, the game's own darkened-front fallback
# is the better picture. See where it is applied for the measurement.
BACK_MIN_SHARE = 0.55

# Which bone wins where two regions overlap: whatever is drawn nearer the
# viewer claims the pixel. FigureRig.DRAW_ORDER is already exactly that
# (painter's algorithm, later = nearer), so it is read rather than restated.


def part_file(bone, entry):
    """Where a bone's cut piece is written. The back limb gets its own
    `<part>_back.png`, which Wardrobe prefers over darkening the front art -
    so painting both sleeves buys real back art instead of a shaded copy."""
    return "%s_back.png" % entry["part"] if entry.get("back") else "%s.png" % entry["part"]


def bone_order(spec):
    return [b for b in spec["draw_order"] if b in spec["bones"]]


def region_masks(spec):
    """bone -> boolean mask of its (grown) mannequin region on the paint
    canvas. Built by drawing the real mannequin part through the very same
    transform the reference image used, so the regions and the body the
    painter saw are the same shape by construction."""
    source = ref.body_dir(*ref.DEFAULT)
    masks = {}
    for bone in bone_order(spec):
        entry = spec["bones"][bone]
        path = os.path.join(source, "%s.png" % entry["part"])
        canvas = Image.new("RGBA", ref.CANVAS, (0, 0, 0, 0))
        if os.path.exists(path):
            pivot, rest, a, b = ref.part_placement(spec, bone)
            ref.paste_part(canvas, Image.open(path).convert("RGBA"), pivot, rest, a, b)
        mask = np.asarray(canvas)[..., 3] > 0
        if REGION_GROW:
            mask = ndimage.binary_dilation(mask, iterations=REGION_GROW)
        masks[bone] = mask
    return masks


def label_pixels(alpha, masks, order):
    """Every painted pixel -> the index (1-based) of its bone in `order`."""
    labels = np.zeros(alpha.shape, np.int32)
    for index, bone in enumerate(order, start=1):
        labels[masks[bone]] = index
    missing = alpha & (labels == 0)
    if missing.any():
        _, (iy, ix) = ndimage.distance_transform_edt(labels == 0, return_indices=True)
        labels[missing] = labels[iy[missing], ix[missing]]
    labels[~alpha] = 0
    return labels


def unrotate(piece, spec, bone):
    """The piece on the paint canvas -> its part canvas, pivot on joint A and
    the bone turned back onto the part's rest direction. The exact inverse of
    what FigureRig.part_transform will do to it at draw time."""
    entry = spec["bones"][bone]
    part = spec["parts"][entry["part"]]
    canvas = (int(part["canvas"][0]), int(part["canvas"][1]))
    pivot, rest, a, b = ref.part_placement(spec, bone)
    theta = math.atan2(b[1] - a[1], b[0] - a[0]) - math.atan2(rest[1], rest[0])
    cos_t, sin_t = math.cos(theta) * ref.SCALE, math.sin(theta) * ref.SCALE
    # PIL maps output (part canvas) -> input (paint canvas), which is the
    # forward transform itself, so no inversion is needed here.
    data = (
        cos_t, -sin_t, a[0] - (cos_t * pivot[0] - sin_t * pivot[1]),
        sin_t, cos_t, a[1] - (sin_t * pivot[0] + cos_t * pivot[1]),
    )
    return piece.transform(canvas, Image.AFFINE, data, resample=Image.BICUBIC)


def key_backdrop(image):
    """Drop a flat backdrop a painter delivered as JPG, sampled at the corners."""
    pixels = np.asarray(image).astype(int)
    corners = [pixels[0, 0, :3], pixels[0, -1, :3], pixels[-1, 0, :3], pixels[-1, -1, :3]]
    seed = np.median(np.array(corners), axis=0)
    flat = np.abs(pixels[..., :3] - seed).sum(axis=2) < 40
    # Only backdrop connected to the border goes; a grey inside the garment stays.
    keep = np.zeros(flat.shape, bool)
    keep[0, :] = keep[-1, :] = keep[:, 0] = keep[:, -1] = True
    outside = ndimage.binary_propagation(flat & keep, mask=flat)
    out = pixels.copy()
    out[outside, 3] = 0
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def cut(spec, image_path, item_id, key, only, overlap=None, grow=None):
    image = Image.open(image_path).convert("RGBA")
    if image.size != ref.CANVAS:
        raise SystemExit(
            "  ! %s is %dx%d; the paint canvas is %dx%d (paint over "
            "docs/wardrobe/paint_pose_reference.png, do not resize it)"
            % (os.path.basename(image_path), image.size[0], image.size[1], *ref.CANVAS)
        )
    if key:
        image = key_backdrop(image)

    alpha = np.asarray(image)[..., 3] >= MIN_ALPHA
    if not alpha.any():
        raise SystemExit("  ! no opaque pixels - is the backdrop still there? (--key)")

    margin = OVERLAP_PX if overlap is None else overlap
    order = bone_order(spec)
    masks = region_masks(spec)
    labels = label_pixels(alpha, masks, order)

    pixels = np.asarray(image)
    pieces = {}
    for index, bone in enumerate(order, start=1):
        entry = spec["bones"][bone]
        if only and entry["part"] not in only:
            continue
        own = labels == index
        if not own.any():
            continue
        # Keep a margin of each neighbour, so a bent joint shows cloth.
        keep = ndimage.binary_dilation(own, iterations=margin) & (labels > 0)
        piece = pixels.copy()
        piece[~keep, 3] = 0
        cut_piece = unrotate(Image.fromarray(piece, "RGBA"), spec, bone)
        area = int((np.asarray(cut_piece)[..., 3] >= MIN_ALPHA).sum())
        if area:
            pieces[bone] = (part_file(bone, entry), entry["part"], cut_piece, area)

    out_dir = os.path.join(OUT_ROOT, item_id)
    os.makedirs(out_dir, exist_ok=True)
    written, dropped = [], []
    for bone, (name, part, cut_piece, area) in pieces.items():
        if not spec["bones"][bone].get("back"):
            cut_piece.save(os.path.join(out_dir, name))
            written.append(name)
            continue
        # A back limb is only worth its own file if the painting really showed
        # it. The far upper arm, for one, hides behind the torso in any side
        # view and comes back a sliver (measured: 73 px against the front
        # arm's 3447). Shipping that sliver is worse than shipping nothing,
        # because Wardrobe prefers a `_back.png` over its own BACK_SHADE
        # fallback - so a scrap of sleeve would replace a correct dark one.
        front = next((p for b, p in pieces.items()
                      if p[1] == part and not spec["bones"][b].get("back")), None)
        if front and area >= front[3] * BACK_MIN_SHARE:
            cut_piece.save(os.path.join(out_dir, name))
            written.append(name)
        else:
            dropped.append(name)
    return out_dir, written, dropped


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("image", help="the whole-figure painting, on the paint canvas")
    parser.add_argument("item_id", help="OutfitCatalog / EquipmentCatalog id, e.g. jacket_wool")
    parser.add_argument("--key", action="store_true", help="drop a flat backdrop first (JPG delivery)")
    parser.add_argument("--overlap", type=int, default=None,
                        help="override OVERLAP_PX (the body wants more than a garment)")
    parser.add_argument("--only", nargs="+", metavar="PART",
                        help="write only these parts (e.g. --only weapon)")
    args = parser.parse_args()

    spec = ref.load_spec()
    out_dir, written, dropped = cut(spec, args.image, args.item_id, args.key,
                                    set(args.only or []), args.overlap)
    if not written:
        raise SystemExit("  ! nothing written - no painted pixels landed on any bone")
    print("  ->", os.path.relpath(out_dir, ROOT))
    for name in written:
        print("     ", name)
    for name in dropped:
        print("      (%s atlandi - arka uzuv yeterince gorunmuyor, oyun on" % name)
        print("       resmi karartarak kullanacak)")
    print("  godot --headless --import")


if __name__ == "__main__":
    main()
