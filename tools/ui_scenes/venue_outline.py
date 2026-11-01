"""Mekân maskesinden (mask.png) vurgunun dış hattını üretir: outline.png.

Kanallar: R = mekânın deliksiz şekli (id), G = şeklin dışındaki hat (id), B = hattın gücü.
Neden: tezgâh ve iskele gibi açık yapıların maskesi delik delik; vurgu her deliğin
kenarına kontur çiziyordu (kullanıcı, 2026-11-01: "iç dış her tarafından glow gelmemeli,
sadece dış hatlarında"). Şekil kapatılıp (genişlet + daralt) delikleri doldurulur, hat
yalnızca dışına çizilir. Tıklama eşlemesi mask.png'de kalır.

    python3 -I tools/ui_scenes/venue_outline.py [şehir ...]
"""
import glob
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage  # pip install scipy

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
TOWNS = os.path.join(ROOT, "data", "assets", "ui", "towns")
CLOSE = 15          # kapatma çekirdeği (maske pikseli, yarım çözünürlük)
RINGS = ((3, 255), (5, 150), (7, 70))


def _filled(binary):
    closed = ndimage.binary_closing(np.pad(binary, CLOSE), structure=np.ones((CLOSE, CLOSE), bool))
    return ndimage.binary_fill_holes(closed)[CLOSE:-CLOSE, CLOSE:-CLOSE]


def write_outline(town_dir):
    mask = np.array(Image.open(os.path.join(town_dir, "mask.png")))
    if mask.ndim == 3:
        mask = mask[..., 0]
    out = np.zeros(mask.shape + (3,), np.uint8)
    for vid in [int(v) for v in np.unique(mask) if v]:
        shape = _filled(mask == vid)
        out[..., 0][shape] = vid
        for size, power in reversed(RINGS):
            ring = ndimage.binary_dilation(shape, structure=np.ones((size, size), bool)) & ~shape
            out[..., 1][ring] = vid
            out[..., 2][ring] = power
    Image.fromarray(out).save(os.path.join(town_dir, "outline.png"))


if __name__ == "__main__":
    names = sys.argv[1:] or [os.path.basename(os.path.dirname(p)) for p in glob.glob(os.path.join(TOWNS, "*", "mask.png"))]
    for name in sorted(names):
        write_outline(os.path.join(TOWNS, name))
    print(len(names), "outline.png")
