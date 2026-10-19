# -*- coding: utf-8 -*-
"""Defter sayfasının cetvel çizgilerini siler (kullanıcı bildirimi: "defter
okunaklı değil, sayfanın tabanındaki çizgiler okunmayı engelliyor").

Kaynak: art_source/waybook/l1_ledger_ruled.jpg (ikinci sanat turunun teslim ettiği
çizgili defter; v2 teslim klasörü depoda yok, bu yüzden kaynak olarak saklandı).
Çıktı:  data/assets/ui/waybook/l1_ledger.jpg

Yöntem: sayfanın açık kâğıt bölgesinde, kâğıdın kendi tonundan (büyük medyan)
belirgin koyu olan ve uzun yatay ya da dikey bir çizgiye ait pikseller cetvel
sayılır; bunlar çevrelerinin medyanıyla doldurulur. Lekeler, yırtıklar, kitabın
kenarı ve ip çizgi değil (kısa ya da düz değil), dokunulmaz.

    python -X utf8 tools/ledger_unrule.py
"""
import os

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art_source", "waybook", "l1_ledger_ruled.jpg")
OUT = os.path.join(ROOT, "data", "assets", "ui", "waybook", "l1_ledger.jpg")

PAPER_MIN = 85.0       # bu tonun altındaki bölgeler kâğıt değil (kapak, gölge)
LINE_DARKER = 9.0      # kâğıttan en az bu kadar koyu
LINE_LENGTH = 31       # çizgi sayılması için en kısa düz uzunluk (px)


GRAIN = os.path.join(ROOT, "art_source", "textures", "ambientcg", "Paper005", "Paper005_1K-JPG_Color.jpg")
TONE_SIGMA = 4.0       # kâğıt tonunun ölçeği: lekeler kalır, cetvel aralığı (~10 px) silinir


def line_mask(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    grey = rgb.astype(np.float32) @ np.array([0.299, 0.587, 0.114], np.float32)
    paper = ndimage.median_filter(grey, size=25)
    dark = (paper - grey) > LINE_DARKER
    on_paper = ndimage.binary_erosion(paper > PAPER_MIN, iterations=2)
    dark &= on_paper
    horizontal = ndimage.binary_opening(dark, structure=np.ones((1, LINE_LENGTH), bool))
    vertical = ndimage.binary_opening(dark, structure=np.ones((LINE_LENGTH, 1), bool))
    lines = ndimage.binary_dilation(horizontal | vertical, iterations=1)
    return lines, on_paper


def unrule(rgb: np.ndarray) -> np.ndarray:
    lines, on_paper = line_mask(rgb)
    keep = (~lines).astype(np.float32)
    src = rgb.astype(np.float32)
    # Normalize evrişim: yalnızca çizgi olmayan piksellerden kâğıt tonu.
    weight = ndimage.gaussian_filter(keep, TONE_SIGMA)
    tone = np.stack([ndimage.gaussian_filter(src[..., c] * keep, TONE_SIGMA) for c in range(3)], -1)
    tone /= np.maximum(weight, 1e-3)[..., None]
    if os.path.exists(GRAIN):
        g = Image.open(GRAIN).convert("L")
        tile = np.asarray(g, np.float32) / 255.0
        h, w = rgb.shape[:2]
        reps = (h // tile.shape[0] + 1, w // tile.shape[1] + 1)
        grain = np.tile(tile, reps)[:h, :w]
        grain = 1.0 + (grain - grain.mean()) * 0.35
        tone *= grain[..., None]
    # Kâğıt bölgesi yeniden kurulur; sınırda yumuşak geçiş, kâğıt dışı olduğu gibi.
    page = ndimage.gaussian_filter(on_paper.astype(np.float32), 3.0)[..., None]
    out = tone * page + src * (1.0 - page)
    return np.clip(out, 0, 255).astype(np.uint8)


def main() -> None:
    rgb = np.asarray(Image.open(SRC).convert("RGB"))
    Image.fromarray(unrule(rgb)).save(OUT, quality=92)
    print("yazıldı:", OUT)


if __name__ == "__main__":
    main()
