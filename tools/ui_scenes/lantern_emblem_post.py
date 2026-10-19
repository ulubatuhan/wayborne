# -*- coding: utf-8 -*-
"""Fener amblemi mürekkep geçişi (görev Y-G08).

Girdi: build/ui_scenes/lantern/beauty.png (lantern_emblem.py).
Çıktı: data/assets/ui/grim/lantern_emblem.png (256 px, saydam): pirinç
koyulaştırılır, cam kehribar yanar (ışığın tek kaynağı), siluet ve iç kenarlar
mürekkeple çizilir.

    python -X utf8 tools/ui_scenes/lantern_emblem_post.py
"""
import os

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "build", "ui_scenes", "lantern", "beauty.png")
OUT = os.path.join(ROOT, "data", "assets", "ui", "grim", "lantern_emblem.png")
AMBER = np.array([1.0, 0.68, 0.30], np.float32)   # ArtPalette.UI_ACCENT ailesi
INK = np.array([0.04, 0.03, 0.03], np.float32)
SIZE = 256


def main() -> None:
    a = np.asarray(Image.open(SRC).convert("RGBA"), np.float32) / 255.0
    rgb, alpha = a[..., :3], a[..., 3]
    rgb = np.clip(rgb * 2.4, 0, 1) ** 0.8
    lum = (rgb * [0.299, 0.587, 0.114]).sum(-1)
    h, w = lum.shape
    # Cam: siluetin ortasında, koyu ve doygunluğu düşük bölge -> kehribar ışık.
    yy, xx = np.mgrid[0:h, 0:w]
    centre = np.exp(-(((xx - w * 0.5) / (w * 0.10)) ** 2 + ((yy - h * 0.64) / (h * 0.10)) ** 2))
    glass = (lum < 0.25) * (alpha > 0.5) * centre
    glow = ndimage.gaussian_filter(glass.astype(np.float32), 6.0)
    rgb = rgb * (1 - glow[..., None]) + AMBER * glow[..., None] * 1.1
    # Mürekkep: siluet kenarı + iç parlaklık kenarı.
    edge_a = np.hypot(ndimage.sobel(alpha, 0), ndimage.sobel(alpha, 1))
    edge_l = np.hypot(ndimage.sobel(lum, 0), ndimage.sobel(lum, 1)) * alpha
    ink = np.clip(edge_a * 1.2 + np.clip(edge_l - 0.25, 0, 1) * 1.5, 0, 1)
    rgb = rgb * (1 - ink[..., None]) + INK * ink[..., None]
    out = np.concatenate([np.clip(rgb, 0, 1), alpha[..., None]], -1)
    img = Image.fromarray((out * 255).astype(np.uint8), "RGBA")
    img = img.crop(img.getbbox())
    img.thumbnail((SIZE, SIZE), Image.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2))
    canvas.save(OUT)
    print("yazıldı:", OUT)


if __name__ == "__main__":
    main()
