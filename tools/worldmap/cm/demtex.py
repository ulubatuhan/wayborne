"""Dağ dokusu: gerçek dünya yükseklik verisinden (SRTM/3DEP, kamuya açık) harmanlanmış rölyef.

Her dağ alanına, sırt doğrultusu o kuşağın uzandığı yöne çevrilmiş gerçek bir
sıradağ parçası oturur; parçalar yumuşak kenarlı pencerelerle üst üste
harmanlanır. Sonuç harita pikselinde bir rölyef alanı (R): ortalaması sıfır,
standart sapması ~1. Gölgelemeyi karo çizimi yapar.

    python3 -I demtex.py <fields.npz> <dem_dir> <out.npy>
"""
import glob
import math
import os
import sys

import cv2
import numpy as np
from scipy import ndimage as ndi

N = 8192
NMAP = 4096
P = 2
BLOCK = 704
STEP = 480
SCALE = 1.15            # harita pikseli / yükseklik pikseli (tepe aralığı ~30-50 px)
SKIP = ("alaska",)


def _orient(a, sig):
    gy, gx = np.gradient(a)
    jxx = ndi.gaussian_filter(gx * gx, sig)
    jxy = ndi.gaussian_filter(gx * gy, sig)
    jyy = ndi.gaussian_filter(gy * gy, sig)
    return 0.5 * np.arctan2(2 * jxy, jxx - jyy)        # gradyan doğrultusu (sırta dik)


def load_sources(dem_dir):
    src = []
    for f in sorted(glob.glob(os.path.join(dem_dir, "*.npy"))):
        if any(s in f for s in SKIP):
            continue
        h = np.load(f).astype(np.float32)
        h = cv2.resize(h, None, fx=SCALE, fy=SCALE, interpolation=cv2.INTER_CUBIC)
        d = h - ndi.gaussian_filter(h, 60)
        d /= d.std() + 1e-6
        th = _orient(ndi.gaussian_filter(h, 18), 120)
        src.append((os.path.basename(f)[:-4], d, th))
    return src


def build(fields_p, dem_dir, out_p, seed=5):
    F = np.load(fields_p)
    mount = F["mount"].astype(np.float32)
    rng = np.random.default_rng(seed)
    src = load_sources(dem_dir)
    # kuşak doğrultusu (alan pikselinde)
    mz = ndi.gaussian_filter(np.clip((mount - 0.25) / 0.3, 0, 1), 3)
    th_belt = _orient(ndi.gaussian_filter(mz, 6), 40)
    acc = np.zeros((N, N), np.float32)
    wsum = np.zeros((N, N), np.float32)
    win1 = np.sin(np.linspace(0, np.pi, BLOCK)) ** 2
    win = np.outer(win1, win1).astype(np.float32)
    mz_map = cv2.resize(mz, (N, N), interpolation=cv2.INTER_LINEAR)
    n = 0
    for by in range(-BLOCK // 2, N, STEP):
        for bx in range(-BLOCK // 2, N, STEP):
            ya, yb, xa, xb = max(0, by), min(N, by + BLOCK), max(0, bx), min(N, bx + BLOCK)
            if ya >= yb or xa >= xb or mz_map[ya:yb, xa:xb].max() < 0.05:
                continue
            cy, cx = (ya + yb) // 2 // P, (xa + xb) // 2 // P
            name, d, th = src[int(rng.integers(len(src)))]
            H, W = d.shape
            R = int(BLOCK * 0.75) + 4
            sx, sy = int(rng.integers(R, W - R)), int(rng.integers(R, H - R))
            # parçanın sırt doğrultusunu kuşağınkine çevir (+ rastgele 180° ve küçük sapma)
            ang = math.degrees(th_belt[min(cy, NMAP - 1), min(cx, NMAP - 1)] - th[sy, sx])
            ang += 180 * int(rng.integers(2)) + rng.normal(0, 10)
            M = cv2.getRotationMatrix2D((float(sx), float(sy)), ang, 1.0)
            M[0, 2] += BLOCK / 2 - sx
            M[1, 2] += BLOCK / 2 - sy
            patch = cv2.warpAffine(d, M, (BLOCK, BLOCK), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT)
            if rng.random() < 0.5:
                patch = patch[:, ::-1]
            pa, pb = ya - by, xa - bx
            acc[ya:yb, xa:xb] += patch[pa:pa + yb - ya, pb:pb + xb - xa] * win[pa:pa + yb - ya, pb:pb + xb - xa]
            wsum[ya:yb, xa:xb] += win[pa:pa + yb - ya, pb:pb + xb - xa]
            n += 1
    R = acc / np.maximum(wsum, 1e-3)
    # harmanlamanın düzleştirdiği yerlerde genliği geri getir
    amp = np.sqrt(ndi.gaussian_filter(R * R, 40)) + 1e-3
    R = R / amp
    R[wsum < 1e-3] = 0
    np.save(out_p, R.astype(np.float16))
    print("parça", n, "kaynak", [s[0] for s in src])


if __name__ == "__main__":
    build(*sys.argv[1:4])
