# -*- coding: utf-8 -*-
"""12.2e taslağı: yol sahnesinin gökyüzü ve ışığı, dört gün evresi × üç biyom.

Katmanlar oyunun kendi render şeritleri (data/assets/ui/road/<biyom>/), yerleri
TravelBand'in oranlarıyla: ufuk 0.58, yol 0.72, uzak/orta düşüş 0.02/0.035,
ön plan 0.075. Değişen yalnızca önerilen gökyüzü ve ışık:
  - güneş disk değil ışık: ufukta sıcak bant, bulut kenarında ışık, haleli küçük
    bir çekirdek; gece ay ışığı;
  - evre başına tek renk derecelendirmesi bütün katmanlara (uzak soğuk ve
    puslu, ön sıcak ve koyu);
  - uzak ile orta arasında ayrı bir sis şeridi.

    python -X utf8 yol_isik_taslak.py
"""
import math
import os
import random
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = r"D:\Users\u90238\Desktop\xx\wayborne"
ROAD = os.path.join(ROOT, "data", "assets", "ui", "road")
FONT = os.path.join(ROOT, "data", "assets", "fonts", "EBGaramond.ttf")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "y_122e_yol_isik.png")

W, H = 960, 540
HORIZON, ROAD_Y = 0.58, 0.72
SPEC = {"far": (61.4, 1.5), "mid": (76.8, 3.4), "ground": (172.8, 2.17), "fore": (435.2, 1.3)}

# Evre: gök üst/alt, ufuk bandı, ışık çarpanı, uzak katman pusu, güneş (x payı, y payı) ya da None.
PHASES = {
    "şafak": dict(top=(46, 52, 78), low=(196, 150, 128), band=(240, 170, 110), light=(1.0, 0.86, 0.78),
                  haze=(170, 150, 150), sun=(0.18, 0.55), sun_col=(255, 214, 160)),
    "gündüz": dict(top=(92, 120, 150), low=(196, 204, 200), band=(236, 226, 200), light=(1.0, 0.98, 0.93),
                   haze=(190, 196, 196), sun=(0.62, 0.16), sun_col=(255, 248, 228)),
    "akşam": dict(top=(58, 46, 70), low=(214, 126, 82), band=(250, 150, 70), light=(1.0, 0.74, 0.55),
                  haze=(180, 120, 110), sun=(0.82, 0.53), sun_col=(255, 180, 110)),
    "gece": dict(top=(10, 12, 24), low=(34, 40, 62), band=(70, 84, 120), light=(0.42, 0.48, 0.66),
                 haze=(50, 58, 82), sun=(0.30, 0.20), sun_col=(210, 222, 255)),
}
BIOMES = ["meadow", "forest", "mountain"]
BIOME_TR = {"meadow": "çayır", "forest": "orman", "mountain": "dağ"}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def sky(p):
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    hz = int(H * HORIZON)
    for y in range(H):
        t = min(1.0, y / hz)
        col = lerp(p["top"], p["low"], t ** 1.6)
        # Ufukta sıcak ışık bandı: güneşin kendisinden önce ışığı.
        band = math.exp(-((y - hz) / (H * 0.07)) ** 2)
        col = lerp(col, p["band"], band * 0.55)
        d.line((0, y, W, y), fill=col)
    return img


def glow(img, p):
    """Haleli küçük çekirdek: disk değil ışık. Gece ay. Işınsal düşüş, keskin kenar yok."""
    import numpy as np
    sx, sy = W * p["sun"][0], H * p["sun"][1]
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    d = np.sqrt((xx - sx) ** 2 + (yy - sy) ** 2)
    k = 0.10 * np.exp(-(d / 260.0) ** 2) + 0.28 * np.exp(-(d / 70.0) ** 2) + 1.2 * np.exp(-(d / 9.0) ** 2)
    col = np.array(p["sun_col"], dtype=np.float32)
    add = np.clip(k[..., None] * col[None, None, :], 0, 255)
    base = np.asarray(img, dtype=np.float32)
    return Image.fromarray(np.clip(base + add, 0, 255).astype(np.uint8))


def clouds(img, p, seed):
    """Bulut şeritleri; güneşe bakan kenarları ışık alır."""
    rnd = random.Random(seed)
    sx = W * p["sun"][0]
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    body = lerp(p["top"], p["low"], 0.45)
    for _ in range(7):
        cx, cy = rnd.uniform(0, W), rnd.uniform(H * 0.12, H * 0.42)
        w, h = rnd.uniform(120, 260), rnd.uniform(10, 22)
        d.ellipse((cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), fill=(*body, 150))
        side = 1 if sx > cx else -1
        d.ellipse((cx - w / 2 + side * 8, cy - h / 2 - 3, cx + w / 2 + side * 8, cy - h / 2 + 5),
                  fill=(*p["band"], 120))
    layer = layer.filter(ImageFilter.GaussianBlur(5))
    img.paste(layer, (0, 0), layer)
    return img


def tint(layer, mult, haze=None, haze_amt=0.0):
    r, g, b, a = layer.split()
    rgb = Image.merge("RGB", (r, g, b))
    rgb = ImageChops.multiply(rgb, Image.new("RGB", rgb.size, tuple(int(255 * m) for m in mult)))
    if haze is not None:
        rgb = Image.blend(rgb, Image.new("RGB", rgb.size, haze), haze_amt)
    return Image.merge("RGBA", (*rgb.split(), a))


def strip(canvas, biome, name, anchor_y, mult, haze=None, haze_amt=0.0, scroll=0):
    tex = Image.open(os.path.join(ROAD, biome, name + ".png")).convert("RGBA")
    anchor_px, ratio = SPEC[name]
    k = H * ratio / tex.width
    tile = tex.resize((int(tex.width * k), int(tex.height * k)), Image.LANCZOS)
    tile = tint(tile, mult, haze, haze_amt)
    top = int(anchor_y - (tex.height - anchor_px) * k)
    x = -(scroll % tile.width)
    while x < W:
        canvas.alpha_composite(tile, (int(x), top))
        x += tile.width


def fog_band(canvas, p, y, height, alpha):
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i in range(height):
        a = int(alpha * math.sin(math.pi * i / height))
        d.line((0, y + i, W, y + i), fill=(*p["haze"], a))
    canvas.alpha_composite(layer)


def frame(biome, phase, seed):
    p = PHASES[phase]
    img = clouds(glow(sky(p), p), p, seed).convert("RGBA")
    hz = H * HORIZON
    light = p["light"]
    cool = tuple(min(1.0, v * c) for v, c in zip(light, (0.86, 0.92, 1.05)))
    warm = tuple(min(1.0, v * c) for v, c in zip(light, (1.04, 0.97, 0.88)))
    strip(img, biome, "far", hz + H * 0.02, cool, p["haze"], 0.45, scroll=seed * 37)
    fog_band(img, p, int(hz - H * 0.02), int(H * 0.07), 110)
    strip(img, biome, "mid", hz + H * 0.035, cool, p["haze"], 0.18, scroll=seed * 91)
    strip(img, biome, "ground", H * ROAD_Y, light, scroll=seed * 173)
    fore = tuple(v * 0.62 for v in warm)
    strip(img, biome, "fore", H * ROAD_Y + H * 0.075, fore, scroll=seed * 241)
    # Gece: kervanın fenerinin sıcak dairesi yol çizgisinde.
    if phase == "gece":
        lamp = Image.new("RGB", (W, H), (0, 0, 0))
        ImageDraw.Draw(lamp).ellipse((W * 0.42, H * 0.62, W * 0.58, H * 0.80), fill=(120, 84, 40))
        lamp = lamp.filter(ImageFilter.GaussianBlur(40))
        img = Image.merge("RGBA", (*ImageChops.add(img.convert("RGB"), lamp).split(), img.split()[3]))
    return img.convert("RGB")


def main():
    pad, label_h = 12, 40
    cols, rows = list(PHASES), BIOMES
    sheet = Image.new("RGB", (len(cols) * (W // 2 + pad) + pad, len(rows) * (H // 2 + pad) + pad + label_h), (14, 13, 15))
    d = ImageDraw.Draw(sheet)
    f = ImageFont.truetype(FONT, 24)
    for ci, phase in enumerate(cols):
        d.text((pad + ci * (W // 2 + pad) + 8, 8), phase, font=f, fill=(219, 179, 87))
    for ri, biome in enumerate(rows):
        for ci, phase in enumerate(cols):
            im = frame(biome, phase, ri * 7 + ci + 1).resize((W // 2, H // 2), Image.LANCZOS)
            x = pad + ci * (W // 2 + pad)
            y = label_h + pad + ri * (H // 2 + pad)
            sheet.paste(im, (x, y))
            d.text((x + 8, y + 6), BIOME_TR[biome], font=ImageFont.truetype(FONT, 18), fill=(224, 217, 199))
    sheet.save(OUT, quality=92)
    print("yazıldı:", OUT)


if __name__ == "__main__":
    main()
