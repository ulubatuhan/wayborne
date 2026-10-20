# -*- coding: utf-8 -*-
"""9.3 taslağı: CityFront durum varyantları (alacakaranlık, gece, gri, kriz).

Kaynak şehrin gösterilen resmi (data/assets/ui/towns/<yer>/background.jpg).
Varyantlar resmin piksellerini yerinden oynatmadan renk ve ışıkla türetilir, bu
yüzden mask.png ile piksel hizalı kalır (tıklama eşlemesi değişmez):
  - alacakaranlık: üstten bakır, gölgeler mora;
  - gece: çivit, karanlık; resimdeki sıcak ışıklar (pencere, fener) korunur ve
    çevresine taşar;
  - gri: kapalı hava, doygunluk düşük, siyahlar kalkık;
  - kriz (savaş/veba/kıtlık): doygunluk düşük, ufukta kızıl, duman lekeleri.

    python -X utf8 sehir_varyant_taslak.py [yer]
"""
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = r"D:\Users\u90238\Desktop\xx\wayborne"
FONT = os.path.join(ROOT, "data", "assets", "fonts", "EBGaramond.ttf")
HERE = os.path.dirname(os.path.abspath(__file__))


def load(town):
    return np.asarray(Image.open(os.path.join(ROOT, "data", "assets", "ui", "towns", town, "background.jpg")).convert("RGB"),
                      dtype=np.float32) / 255.0


def luma(a):
    return (a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114)[..., None]


def warm_lights(a):
    """Sıcak, parlak pikseller: pencere ve fener ışığı (0..1 maske)."""
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    warm = np.clip((r - b) * 3.0, 0, 1) * np.clip((luma(a)[..., 0] - 0.35) * 3.0, 0, 1)
    return warm[..., None]


def vertical(h, w, top, bottom):
    t = np.linspace(0, 1, h, dtype=np.float32)[:, None, None]
    return np.broadcast_to(np.array(top, np.float32) * (1 - t) + np.array(bottom, np.float32) * t, (h, w, 3))


def dusk(a):
    h, w, _ = a.shape
    grade = vertical(h, w, (1.10, 0.78, 0.62), (0.92, 0.80, 0.86))
    out = a * grade * 0.92
    return out + warm_lights(a) * 0.15


def night(a):
    h, w, _ = a.shape
    lights = warm_lights(a)
    base = a * np.array([0.46, 0.50, 0.68], np.float32) * vertical(h, w, (0.8, 0.8, 1.0), (1.0, 1.0, 1.0))
    bloom = np.asarray(Image.fromarray((lights[..., 0] * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(18)),
                       np.float32)[..., None] / 255.0
    glow = np.array([1.0, 0.66, 0.30], np.float32)
    return base * (1 - lights) + a * lights * 1.05 + bloom * glow * 0.9


def grey(a):
    l = luma(a)
    out = a * 0.35 + l * 0.65
    out = 0.10 + out * 0.82
    return out * np.array([0.95, 0.98, 1.03], np.float32)


def crisis(a, seed=3):
    h, w, _ = a.shape
    l = luma(a)
    out = (a * 0.25 + l * 0.75) * 0.78
    sky = vertical(h, w, (0.55, 0.16, 0.10), (0.0, 0.0, 0.0))
    band = np.exp(-((np.linspace(0, 1, h, dtype=np.float32) - 0.42) / 0.12) ** 2)[:, None, None]
    out = out + sky * band * 0.55
    smoke = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(smoke)
    rnd = random.Random(seed)
    for _ in range(3):
        x = rnd.uniform(w * 0.15, w * 0.85)
        y = h * 0.42
        for k in range(14):
            r = 30 + k * 9
            d.ellipse((x - r + k * 6, y - k * 34 - r, x + r + k * 6, y - k * 34 + r), fill=150 - k * 8)
    smoke = np.asarray(smoke.filter(ImageFilter.GaussianBlur(22)), np.float32)[..., None] / 255.0
    return out * (1 - smoke * 0.6) + np.array([0.40, 0.36, 0.34], np.float32) * smoke * 0.6


def main(town):
    a = load(town)
    variants = [("bugünkü", a), ("alacakaranlık", dusk(a)), ("gece", night(a)), ("gri", grey(a)), ("kriz", crisis(a))]
    tw, th = 640, 360
    pad, label = 10, 34
    sheet = Image.new("RGB", (3 * (tw + pad) + pad, 2 * (th + pad + label) + pad), (14, 13, 15))
    d = ImageDraw.Draw(sheet)
    f = ImageFont.truetype(FONT, 22)
    for i, (name, img) in enumerate(variants):
        im = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).resize((tw, th), Image.LANCZOS)
        x = pad + (i % 3) * (tw + pad)
        y = pad + (i // 3) * (th + pad + label)
        d.text((x, y), name, font=f, fill=(219, 179, 87))
        sheet.paste(im, (x, y + label))
    d.text((pad + 2 * (tw + pad), pad + th + pad + label + label + 20),
           f"{town}: piksel hizalı (mask.png değişmez)", font=f, fill=(158, 150, 138))
    out = os.path.join(HERE, f"y_93_sehir_varyant_{town}.png")
    sheet.save(out, quality=92)
    print("yazıldı:", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "vastrevar")
