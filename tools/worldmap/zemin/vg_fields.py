"""referans oyun denemesi, adım 1: arazi alanları (4096 uzayında hesapla, parçayı kırp).

Coğrafya zemin_render.py ile aynı kurallardan geliyor (kıyı coast.py, orman/bozkır/
dağ aynı maskelerden) - yalnızca çizim dili değişiyor. Çıktı tek .npz:
water, forest, steppe, mount, core, height, roads, foot (hepsi kırpılmış, 0..1;
height metre).

    python3 -I vg_fields.py <kök> <x0> <y0> <boy> <çıktı.npz>
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import coast as coastline  # noqa: E402
import zemin_paint  # noqa: E402
from zemin_render import NOMAD_KINDS, FOREST_SHARE, warp_sample  # noqa: E402

SEED = 7
MOUNT_H = 70.0     # sırt yüksekliği (birim = harita pikseli)
HILL_H = 7.0
WATER_D = -6.0


def fields(root):
    n, scale, seed = 4096, 1.0, SEED
    base = np.asarray(Image.open(os.path.join(root, "images", "base_map_4096.jpg")).convert("RGB"), np.float32) / 255
    lum = base @ np.array([0.299, 0.587, 0.114], np.float32)
    water = coastline.water_mask(root, n).astype(np.float32)
    wb = water > 0.5
    land = 1 - zemin_paint.smooth(water, 1.0)
    m_mount = zemin_paint.load(root, "mask_mountain.png", n)
    m_forest = zemin_paint.load(root, "mask_forest.png", n)
    world = json.load(open(os.path.join(root, "data", "world.json")))
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)

    foot = np.zeros((n, n), np.float32)
    fp = os.path.join(root, "out", "layout.json.foot.npy")
    if os.path.exists(fp):
        foot = np.unpackbits(np.load(fp))[:n * n].reshape(n, n).astype(np.float32)
    footS = zemin_paint.smooth(foot, 3)
    rim = Image.new("L", (n, n), 0)
    rdr = ImageDraw.Draw(rim)
    for rd in json.load(open(os.path.join(root, "out", "world_zemin.json")))["roads"]:
        rdr.line([tuple(p) for p in rd["p"]], fill=255, width=(26 if rd["c"] == "road" else 18))
    roadm = zemin_paint.smooth(np.asarray(rim, np.float32) / 255, 3)
    rim2 = Image.new("L", (n, n), 0)
    rdr2 = ImageDraw.Draw(rim2)
    for rd in json.load(open(os.path.join(root, "out", "world_zemin.json")))["roads"]:
        pts = [tuple(p) for p, w in zip(rd["p"], rd["wet"]) if not w]
        if len(pts) > 1:
            rdr2.line(pts, fill=255 if rd["c"] == "road" else 170, width=(5 if rd["c"] == "road" else 3))
    track = np.asarray(rim2, np.float32) / 255

    steppe = np.zeros((n, n), np.float32)
    for s_, x_, y_ in world["syms"]:
        if s_ in NOMAD_KINDS:
            R_ = 560
            x0, x1 = int(max(0, x_ - R_)), int(min(n, x_ + R_))
            y0, y1 = int(max(0, y_ - R_)), int(min(n, y_ + R_))
            d_ = np.hypot(xx[y0:y1, x0:x1] - x_, yy[y0:y1, x0:x1] - y_) / R_
            steppe[y0:y1, x0:x1] = np.maximum(steppe[y0:y1, x0:x1], np.clip(1.2 - d_, 0, 1))
    steppe = warp_sample(zemin_paint.smooth(steppe, 220), n, seed + 91, 160)
    steppe = np.clip(steppe * 1.8, 0, 1) ** 1.3 * land

    # orman: zemin_render ile aynı karar (yerleşim açıklığı hariç - ev zaten ayak izi)
    edge_px = np.minimum(np.minimum(xx, yy), np.minimum(n - 1 - xx, n - 1 - yy))
    efade = np.clip((edge_px - 30) / 170, 0, 1)
    g = base[..., 1] - (base[..., 0] + base[..., 2]) / 2
    greenish = efade * zemin_paint.smooth(np.clip((g + 0.005) / 0.04, 0, 1) * np.clip((0.62 - lum) / 0.15, 0, 1), 3)
    ell = warp_sample(zemin_paint.smooth(m_forest, 10), n, seed + 40, 90)
    relief = coastline.relief(root, n)
    mnt = np.maximum(zemin_paint.smooth(m_mount, 18), zemin_paint.smooth(relief, 10))
    patch = zemin_paint.fbm(n, seed + 21, 5, 4)
    woods = np.clip((patch - 0.50) * 5, 0, 1)
    forest_f = np.maximum.reduce([ell * 1.4, greenish * 1.2, mnt * 1.6 * np.clip((patch - 0.30) * 4, 0, 1), woods * 0.9])
    forest_f = forest_f + (zemin_paint.fbm(n, seed + 77, 14, 3) - 0.5) * 0.5
    core = zemin_paint.smooth(np.clip((zemin_paint.smooth(np.maximum(m_mount, relief), 5) - 0.55) * 3, 0, 1), 3)
    core = core * np.clip((zemin_paint.fbm(n, seed + 88, 18, 2) - 0.25) * 3, 0, 1)
    # Bu harita referans haritadan çok daha az ağaçlı: payı yarıya indir
    forest_f = zemin_paint.smooth(forest_f, 4) - core * 1.4 - footS * 3.0 - roadm * 2.0
    landmask = land > 0.5
    thr = np.quantile(forest_f[landmask], 1 - FOREST_SHARE * 0.62)
    forest = np.clip((forest_f - thr) * 8 + 0.5, 0, 1) * np.clip(land * 1.2 - 0.2, 0, 1)
    shore_gap = np.clip(ndi.distance_transform_edt(~wb) / 14 - 0.5, 0, 1)
    strict = warp_sample(zemin_paint.smooth(m_forest, 6), n, seed + 41, 30)
    strict = np.clip((strict - 0.45) * 6, 0, 1) * (1 - np.clip(footS * 3 + roadm * 2, 0, 1))
    forest = forest * (1 - steppe) + strict * steppe * 0.7
    forest = forest * shore_gap
    mount = np.clip(mnt * 1.4, 0, 1) * land

    # yükseklik: geniş dağ kütlesi + sırt gürültüsü + kaynak haritanın vadi
    # çizgileri (Hessian) oyuk olarak - dağlar orijinaldeki yerinde kalır
    ls = zemin_paint.smooth(lum, 3.0)
    hxx = ndi.gaussian_filter(lum, 7.0, order=(0, 2))
    hyy = ndi.gaussian_filter(lum, 7.0, order=(2, 0))
    hxy = ndi.gaussian_filter(lum, 7.0, order=(1, 1))
    lam = (hxx + hyy) / 2 + np.sqrt(((hxx - hyy) / 2) ** 2 + hxy ** 2)
    mz = np.clip(mount * 1.6 + core, 0, 1)
    q = np.quantile(lam[mz > 0.5], 0.80)
    crease = np.clip((lam / (q + 1e-9) - 1.0) * 1.5, 0, 1)
    # sırt ağı: bükülmüş, çok ölçekli "ridged" gürültü (keskin tepe hatları)
    ridged = np.zeros((n, n), np.float32)
    amp = 1.0
    for o, cells in enumerate((14, 30, 64)):
        r_ = 1 - np.abs(zemin_paint.fbm(n, seed + 300 + o, cells, 3) - 0.5) * 2
        ridged += amp * r_ ** 3
        amp *= 0.5
    ridged = warp_sample(ridged / 1.75, n, seed + 320, 40)
    mass = zemin_paint.smooth(mz * (1 - zemin_paint.smooth(m_forest, 12) * 0.95), 24) ** 1.2
    H = MOUNT_H * (mass * (0.35 + 0.9 * ridged) - 0.30 * zemin_paint.smooth(crease, 2.0) * mass)
    H = H * np.clip(1 - footS * 0.0, 0, 1)
    H += HILL_H * (zemin_paint.fbm(n, seed + 310, 10, 4) - 0.5) * 2 * (1 - 0.6 * steppe)
    H += 2.0 * (zemin_paint.fbm(n, seed + 311, 60, 3) - 0.5)
    dist_w = ndi.distance_transform_edt(~wb)
    shore = np.clip(dist_w / 30, 0, 1)
    H = H * shore + 0.5 * (1 - shore)
    depth = np.clip(ndi.distance_transform_edt(wb) / 40, 0, 1)
    H = np.where(wb, WATER_D * depth - 0.3, H)
    # yerleşim zemini düzlenir (binalar yamaçta asılı kalmasın)
    flat = zemin_paint.smooth(foot, 14)
    flat = np.clip(flat * 4, 0, 1)
    H = H * (1 - flat) + zemin_paint.smooth(H, 20) * flat
    return dict(water=water, forest=forest, steppe=steppe, mount=mount, core=core,
                height=H.astype(np.float32), roads=track, foot=foot, crease=crease * mz,
                mz=mz, mforest=m_forest, lum=lum)


def main():
    root, x0, y0, s, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
    f = fields(root)
    np.savez_compressed(out, x0=x0, y0=y0, size=s,
                        **{k: v[y0:y0 + s, x0:x0 + s].astype(np.float32) for k, v in f.items()})
    print("YAZILDI", out)


if __name__ == "__main__":
    main()
