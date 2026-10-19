"""Harita etiketlerinin altındaki yolu kapatan hale (görev 8.5).

    python -I tools/worldmap/cm/patch_labels.py <karo_klasörü> <harita.geojson> <çıktı_klasörü> [--preview klasör]

Kent adlarının bazılarının (ör. Vastrevar) altından yol geçiyordu: `cm_full._text`
yazının çevresine yalnızca ince, saydam bir kâğıt halesi koyuyordu. Haritanın
çizildiği makinede "IM FELL English SC" kurulu olmadığı için cairo yazıları düz
bir sans ile basmıştı - tasarımın istediği yazı tipi değil.

Etiketler haritaya en son çizildiği için tam haritayı yeniden üretmeden
düzeltilebilir; her etiket GeoJSON'da (metin, konum, `font_px`) var:

1. Oyunun karo piramidinin en ayrıntılı seviyesi (`4/`, 16x16 karo, haritanın
   16012x16013 pikseli sol üstte) tek bir tuvalde birleştirilir.
2. Her etiket için eski sans yazının (Arial ile yaklaşık) ve yeni yazının
   (`data/assets/fonts/IMFellEnglishSC.ttf`, harf aralığı 0.12) glif maskelerinin
   birleşimi yazı boyunun `HALO_SHARE` payı kadar genişletilip yumuşatılır: yol ve
   eski yazı bu halenin altında kalır. Hale rengi bölgenin kendi kâğıdı (açık
   piksellerin ortancası).
3. Yazı mürekkeple (`cm_full.INK`) IM FELL ile yeniden basılır.
4. 4. seviyede yalnızca değişen karolar, alt seviyelerin hepsi yeniden yazılır
   (`mapview/make_tiles.py` ile aynı küçültme ve JPEG ayarı).

Konum: GeoJSON koordinatı doğrudan karo tuvalinin pikseli.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

Image.MAX_IMAGE_PIXELS = None
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
FONT = os.path.join(ROOT, "data", "assets", "fonts", "IMFellEnglishSC.ttf")
OLD_FONT_CANDIDATES = ["C:/Windows/Fonts/arial.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]
INK = np.array([0.17, 0.12, 0.09], np.float32)
TRACK = 0.12
HALO_SHARE = 0.34
TILE = 1024
LEVEL = 4
GRID = 16


def _font(path, fs):
    return ImageFont.truetype(path, max(1, int(round(fs))))


def _draw_text(draw, font, text, x, base, tr, fill):
    for ch in text:
        draw.text((x, base), ch, font=font, fill=fill, anchor="ls")
        x += font.getlength(ch) + tr


def _width(font, text, tr):
    return sum(font.getlength(ch) + tr for ch in text) - tr


def label_masks(text, fs):
    """(yeni glif maskesi, hale maskesi, sol üst köşenin cx/taban çizgisine göre kayması)."""
    new_font = _font(FONT, fs)
    old_path = next((p for p in OLD_FONT_CANDIDATES if os.path.exists(p)), FONT)
    old_font = _font(old_path, fs)
    tr = fs * TRACK
    tw = max(_width(new_font, text, tr), _width(old_font, text, tr))
    pad = int(fs * (HALO_SHARE + 0.7))
    w = int(tw) + 2 * pad
    h = int(fs * 1.8) + 2 * pad
    base = pad + int(fs * 1.2)
    glyph = Image.new("L", (w, h), 0)
    old = Image.new("L", (w, h), 0)
    _draw_text(ImageDraw.Draw(glyph), new_font, text, (w - _width(new_font, text, tr)) / 2.0, base, tr, 255)
    _draw_text(ImageDraw.Draw(old), old_font, text, (w - _width(old_font, text, tr)) / 2.0, base, tr, 255)
    union = Image.fromarray(np.maximum(np.asarray(glyph), np.asarray(old)))
    r = max(3, int(fs * HALO_SHARE))
    k = 2 * (r // 3) + 1
    halo = union
    for _ in range(3):
        halo = halo.filter(ImageFilter.MaxFilter(k))
    halo = halo.filter(ImageFilter.GaussianBlur(r * 0.3))
    return glyph, halo, (w / 2.0, base)


def patch(canvas, lab):
    fs = float(lab["font_px"])
    glyph, halo, (ox, oy) = label_masks(lab["text"], fs)
    x0 = int(round(lab["x"] - ox))
    y0 = int(round(lab["y"] - oy))
    box = (x0, y0, x0 + glyph.size[0], y0 + glyph.size[1])
    if box[0] < 0 or box[1] < 0 or box[2] > canvas.size[0] or box[3] > canvas.size[1]:
        return None
    crop = np.asarray(canvas.crop(box), np.float32) / 255.0
    g = np.asarray(glyph, np.float32) / 255.0
    hal = np.clip(np.asarray(halo, np.float32) / 255.0 * 1.3, 0.0, 1.0)
    lum = crop @ np.array([0.299, 0.587, 0.114], np.float32)
    bright = crop[lum >= np.percentile(lum, 70)]
    paper = np.median(bright, axis=0) if len(bright) else np.array([0.94, 0.89, 0.77], np.float32)
    out = crop * (1 - hal[..., None]) + paper * hal[..., None]
    out = out * (1 - g[..., None]) + INK * g[..., None]
    canvas.paste(Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8)), box[:2])
    return box


def main(argv):
    tiles, geo, out = argv[1], argv[2], argv[3]
    preview = argv[argv.index("--preview") + 1] if "--preview" in argv else ""
    canvas = Image.new("RGB", (GRID * TILE, GRID * TILE), (0, 0, 0))
    for y in range(GRID):
        for x in range(GRID):
            p = os.path.join(tiles, str(LEVEL), "%d_%d.jpg" % (x, y))
            if os.path.exists(p):
                canvas.paste(Image.open(p).convert("RGB"), (x * TILE, y * TILE))
    labels = []
    for f in json.load(open(geo, encoding="utf-8"))["features"]:
        p = f["properties"]
        if p.get("layer") == "etiket":
            x, y = f["geometry"]["coordinates"]
            labels.append({"text": p["text"], "font_px": p["font_px"], "x": x, "y": y})
    if preview:
        os.makedirs(preview, exist_ok=True)
    changed = set()
    for lab in labels:
        show = preview and lab["text"] in ("Vastrevar", "Rivecande", "Dravoss", "Orbeyan Caravanserai")
        area = (int(lab["x"]) - 520, int(lab["y"]) - 200, int(lab["x"]) + 520, int(lab["y"]) + 90)
        before = canvas.crop(area) if show else None
        box = patch(canvas, lab)
        if box is None:
            continue
        for ty in range(box[1] // TILE, (box[3] - 1) // TILE + 1):
            for tx in range(box[0] // TILE, (box[2] - 1) // TILE + 1):
                changed.add((tx, ty))
        if before is not None:
            after = canvas.crop(area)
            pair = Image.new("RGB", (before.size[0], before.size[1] * 2 + 8), (40, 40, 40))
            pair.paste(before, (0, 0))
            pair.paste(after, (0, before.size[1] + 8))
            pair.save(os.path.join(preview, "etiket_%s.jpg" % lab["text"].split()[0]), quality=90)
    # 4. seviye: yalnızca değişen karolar
    os.makedirs(os.path.join(out, str(LEVEL)), exist_ok=True)
    for tx, ty in sorted(changed):
        canvas.crop((tx * TILE, ty * TILE, (tx + 1) * TILE, (ty + 1) * TILE)).save(
            os.path.join(out, str(LEVEL), "%d_%d.jpg" % (tx, ty)), quality=80, optimize=True, progressive=True)
    # alt seviyeler: hepsi (make_tiles.py ile aynı)
    cur = canvas
    level = LEVEL
    while level > 0:
        cur = cur.resize((cur.size[0] // 2,) * 2, Image.LANCZOS)
        level -= 1
        n = cur.size[0] // TILE
        d = os.path.join(out, str(level))
        os.makedirs(d, exist_ok=True)
        for y in range(n):
            for x in range(n):
                cur.crop((x * TILE, y * TILE, (x + 1) * TILE, (y + 1) * TILE)).save(
                    os.path.join(d, "%d_%d.jpg" % (x, y)), quality=80, optimize=True, progressive=True)
    print("etiket:", len(labels), "değişen 4. seviye karo:", len(changed))


if __name__ == "__main__":
    main(sys.argv)
