"""Web derlemesi icin atlas sayfalarini kucultur (yalnizca CI'de, depoya yazilmaz).

Sorun: tarayici sekmesi ~2 GB'ta doluyor (SBOX_FATAL_MEMORY_EXCEEDED); Web
export tum .pck'yi bellege aliyor ve atlaslar ~1,25 GB tutuyordu. Figur, giysi
ve hayvan atlaslari ekranda ~5 kat kucuk cizildigi icin sayfalari kucultmek
gorunumu belirgin bozmuyor.

Her `frames.tres` icin: sayfa PNG'leri `faktor` kadar kucultulur, `rects`
(sayfa, x, y, w, h) ayni oranda yeniden hesaplanir (kenarlar komsu parcaya
tasmasin diye sol-ust ve sag-alt ayri yuvarlanir), `texel_scale` carpilir;
`offsets` render pikselinde kaldigi icin dokunulmaz. Boylece `BodyFrames`
cizilen boyutu ayni tutar.

Kullanim: python3 tools/web_shrink.py [--body 4] [--outfit 2] [--beast 2]
"""
import argparse
import glob
import os
import re
import sys

from PIL import Image

Image.MAX_IMAGE_PIXELS = None
ROOT = os.path.join("data", "assets", "characters", "frames")


def shrink_set(folder: str, factor: int) -> tuple[int, int]:
    tres = os.path.join(folder, "frames.tres")
    text = open(tres, encoding="utf-8").read()
    pages = re.search(r"pages = PackedStringArray\((.*?)\)", text).group(1)
    names = [p.strip().strip('"').replace("res://", "") for p in pages.split(",")]
    sizes = []
    before = after = 0
    for path in names:
        im = Image.open(path)
        w, h = im.size
        before += w * h
        nw, nh = max(1, round(w / factor)), max(1, round(h / factor))
        sizes.append((w, h, nw, nh))
        # Premultiplied alpha ile kucult: seffaf kenar rengi siyah sizdirmasin.
        small = im.convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
        small.save(path, compress_level=6)
        after += nw * nh
    m = re.search(r"rects = PackedInt32Array\((.*?)\)", text, re.S)
    nums = [int(x) for x in m.group(1).split(",")]
    for r in range(0, len(nums) - 4, 5):
        page, x, y, w, h = nums[r:r + 5]
        if w <= 0:
            continue
        ow, oh, nw, nh = sizes[page]
        sx, sy = nw / ow, nh / oh
        nx0, ny0 = round(x * sx), round(y * sy)
        nx1, ny1 = round((x + w) * sx), round((y + h) * sy)
        nums[r + 1], nums[r + 2] = nx0, ny0
        nums[r + 3], nums[r + 4] = max(1, nx1 - nx0), max(1, ny1 - ny0)
    text = text.replace(m.group(0), "rects = PackedInt32Array(" + ", ".join(map(str, nums)) + ")")
    ts = re.search(r"texel_scale = ([0-9.]+)", text)
    if ts:
        new = float(ts.group(1)) * factor
        text = text.replace(ts.group(0), "texel_scale = %s" % new)
    else:
        text = text.replace("rects = PackedInt32Array", "texel_scale = %s\nrects = PackedInt32Array" % float(factor), 1)
    open(tres, "w", encoding="utf-8").write(text)
    return before, after


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--body", type=int, default=4)
    ap.add_argument("--outfit", type=int, default=2)
    ap.add_argument("--beast", type=int, default=2)
    args = ap.parse_args()
    factors = {"body": args.body, "outfit": args.outfit, "beast": args.beast}
    total_b = total_a = 0
    for folder in sorted(glob.glob(os.path.join(ROOT, "*"))):
        kind = os.path.basename(folder).split("_")[0]
        f = factors.get(kind, 1)
        if f <= 1 or not os.path.isfile(os.path.join(folder, "frames.tres")):
            continue
        b, a = shrink_set(folder, f)
        total_b += b
        total_a += a
    print("sayfa piksel: %.1f Mpx -> %.1f Mpx" % (total_b / 1e6, total_a / 1e6))
    return 0


if __name__ == "__main__":
    sys.exit(main())
