"""referans oyun denemesi, adım 2: kırpılmış alanlardan yükseklik haritası.

Dağın yeri kaynak haritadan (mz: dağ maskesi + çizili sırtlar), şekli gürültüden:
geniş kütle × bükülmüş "ridged" gürültü = keskin sırt hatları ve aralarında
vadiler. Alçak, eğik güneş bunları gölgeyle okutacak.

    python3 -I vg_height.py fields.npz
"""
import sys

import numpy as np
from scipy import ndimage as ndi

MOUNT_H = 60.0
HILL_H = 6.0
WATER_D = -6.0


def noise(n, seed, cells, octaves=3):
    rng = np.random.default_rng(seed)
    out = np.zeros((n, n), np.float32)
    amp = tot = 0.0
    amp = 1.0
    for o in range(octaves):
        c = cells * 2 ** o
        g = rng.random((c + 3, c + 3)).astype(np.float32)
        z = ndi.zoom(g, n / c, order=3)[:n, :n]
        out += amp * z
        tot += amp
        amp *= 0.5
    return np.clip(out / tot, 0, 1)


def warp(a, seed, amp, cells=6):
    n = a.shape[0]
    fx = (noise(n, seed, cells, 3) - 0.5) * 2 * amp
    fy = (noise(n, seed + 1, cells, 3) - 0.5) * 2 * amp
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    return ndi.map_coordinates(a, [np.clip(yy + fy, 0, n - 1), np.clip(xx + fx, 0, n - 1)], order=1)


def height(f, seed=7):
    n = f["water"].shape[0]
    k = n / 1536.0  # gürültü hücreleri 1536'lık parçaya göre
    wb = f["water"] > 0.5
    steppe = f["steppe"]
    mf = ndi.gaussian_filter(ndi.maximum_filter(f["mforest"], int(40 * k)), 25 * k)
    mz = f["mz"] * np.clip(1 - mf * 1.5, 0, 1)
    mass = np.clip(ndi.gaussian_filter(mz, 22 * k) * 1.3, 0, 1) ** 1.4
    ridged = np.zeros((n, n), np.float32)
    amp, tot = 1.0, 0.0
    for o, cells in enumerate((5, 11, 24, 50)):
        r = 1 - np.abs(noise(n, seed + 300 + o, int(cells * k) or 1, 2) - 0.5) * 2
        ridged += amp * r ** 2.2
        tot += amp
        amp *= 0.5
    ridged = warp(ridged / tot, seed + 320, 30 * k)
    H = MOUNT_H * mass * (0.15 + ridged * 1.1) ** 1.5
    # ince kayalık: yüksek frekanslı keskin sırtlar, yalnız dağın gövdesinde
    fine = 1 - np.abs(noise(n, seed + 340, int(110 * k), 2) - 0.5) * 2
    H += 9.0 * mass ** 0.8 * fine ** 4
    H += HILL_H * (noise(n, seed + 310, 4, 4) - 0.5) * 2 * (1 - 0.5 * steppe)
    H += 1.2 * (noise(n, seed + 311, 40, 2) - 0.5)
    dist_w = ndi.distance_transform_edt(~wb)
    shore = np.clip(dist_w / (25 * k), 0, 1) ** 0.7
    H = np.maximum(H, 0.0) + 1.2
    H = H * shore + 1.0 * (1 - shore)
    depth = np.clip(ndi.distance_transform_edt(wb) / (40 * k), 0, 1)
    H = np.where(wb, WATER_D * depth, H)
    flat = np.clip(ndi.gaussian_filter(f["foot"], 14 * k) * 4, 0, 1)
    H = H * (1 - flat) + ndi.gaussian_filter(H, 20 * k) * flat
    return ndi.gaussian_filter(H, 0.8).astype(np.float32)


def main():
    p = sys.argv[1]
    f = dict(np.load(p))
    f["height"] = height(f)
    np.savez_compressed(p, **f)
    print("height", f["height"].min(), f["height"].max())


if __name__ == "__main__":
    main()
