"""Karo dikişlerini yumuşat: her 1280 px sınırında 8 px'lik bantta yerel ortalama.

    python3 -I vg_seam.py <map_5120.png> <çıktı_5120.png> <çıktı_4096.jpg>
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

src, dst, small = sys.argv[1:4]
im = np.asarray(Image.open(src).convert("RGB"), np.float32)
n = im.shape[0]
blur = np.stack([ndi.uniform_filter(im[..., c], 9) for c in range(3)], -1)
w = np.zeros((n, n), np.float32)
band = 8
for s in range(1280, n, 1280):
    for d in range(-band, band + 1):
        a = 1 - abs(d) / (band + 1)
        w[:, s + d] = np.maximum(w[:, s + d], a)
        w[s + d, :] = np.maximum(w[s + d, :], a)
out = im * (1 - w[..., None]) + blur * w[..., None]
o = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))
o.save(dst)
o.resize((4096, 4096), Image.LANCZOS).save(small, quality=90)
print("ok")
