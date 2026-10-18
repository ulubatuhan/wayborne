"""referans oyun denemesi, adım 3: arazi rengi (albedo) + ağaç noktaları.

referans oyun'un paleti: kül, toz okru, isli zeytin, kurşuni taş; su neredeyse siyah
lacivert. Doygunluk düşük, ışık render'dan gelecek - burada yalnızca
malzemenin kendi rengi var (gölge yok).

    python3 -I vg_albedo.py fields.npz <çıktı klasörü> [boy]
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from vg_height import noise, warp  # noqa: E402

STEPPE_A = np.array([0.50, 0.45, 0.34])
STEPPE_B = np.array([0.60, 0.55, 0.42])
TUNDRA = np.array([0.40, 0.41, 0.34])
MEADOW_A = np.array([0.33, 0.33, 0.22])
MEADOW_B = np.array([0.42, 0.40, 0.27])
FLOOR = np.array([0.15, 0.15, 0.10])
ROCK_A = np.array([0.22, 0.20, 0.18])
ROCK_B = np.array([0.40, 0.37, 0.33])
SCREE = np.array([0.45, 0.41, 0.35])
WATER = np.array([0.07, 0.09, 0.12])
WATER_SHALLOW = np.array([0.16, 0.20, 0.22])
SHORE = np.array([0.46, 0.43, 0.36])
DUST = np.array([0.62, 0.57, 0.46])
CRACK = np.array([0.30, 0.27, 0.21])


TEX_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "art_source", "textures", "ambientcg")
TEX_GROUND = os.path.join(TEX_DIR, "Ground106", "Ground106_1K-JPG_Color.jpg")
TEX_ROCK = os.path.join(TEX_DIR, "Rock064", "Rock064_1K-JPG_Color.jpg")


def texdetail(path, n, tile, strength):
    """Dokunun parlaklık ayrıntısı, döşenmiş, ortalaması 1; tekrar görünmesin
    diye iki ölçek ve döndürülmüş ikinci kat."""
    t = np.asarray(Image.open(path).convert("L"), np.float32) / 255
    t = t / t.mean()
    out = np.ones((n, n), np.float32)
    for sc_, flip in ((tile, False), (tile * 2.7, True)):
        ti = np.asarray(Image.fromarray(((t / 2).clip(0, 1) * 255).astype(np.uint8)).resize(
            (max(8, int(sc_)), max(8, int(sc_))), Image.LANCZOS), np.float32) / 255 * 2
        if flip:
            ti = ti.T[::-1]
        reps = n // ti.shape[0] + 2
        big = np.tile(ti, (reps, reps))[:n, :n]
        out *= big ** (strength * (0.6 if flip else 1.0))
    return out / out.mean()


def up(a, n):
    return ndi.zoom(a, n / a.shape[0], order=1)


def cracks(n, seed, cell, mask):
    """Kuru toprak çatlakları: bükülmüş Voronoi hücre kenarları."""
    rng = np.random.default_rng(seed)
    m = int(n / cell) + 2
    pts = (np.stack(np.meshgrid(np.arange(m), np.arange(m)), -1).reshape(-1, 2) + rng.random((m * m, 2))) * cell
    from scipy.spatial import cKDTree
    t = cKDTree(pts)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    q = np.stack([xx.ravel(), yy.ravel()], 1)
    d, _ = t.query(q, k=2)
    e = (d[:, 1] - d[:, 0]).reshape(n, n)
    line = np.clip(1 - e / 1.6, 0, 1)
    line = warp(line, seed + 5, cell * 0.25)
    gate = np.clip((noise(n, seed + 9, 5, 3) - 0.45) * 4, 0, 1)
    return line * gate * mask


def build(f, n):
    k = n / f["water"].shape[0]
    W = up(f["water"], n)
    wb = W > 0.5
    forest = np.clip(up(f["forest"], n), 0, 1)
    steppe = np.clip(up(f["steppe"], n), 0, 1)
    mount = np.clip(up(f["mount"], n), 0, 1)
    H = up(f["height"], n)
    roads = np.clip(up(f["roads"], n), 0, 1)
    gy, gx = np.gradient(H / k)
    slope = np.clip(np.hypot(gx, gy) / 1.2, 0, 1)

    t = noise(n, 11, 6, 4)[..., None]
    t2 = noise(n, 12, 60, 2)[..., None]
    mix = np.clip((t - 0.5) * 2.2 + 0.5 + (t2 - 0.5) * 0.5, 0, 1)
    meadow = MEADOW_A * (1 - mix) + MEADOW_B * mix
    st = STEPPE_A * (1 - mix) + STEPPE_B * mix
    tun = np.clip((noise(n, 13, 8, 3) - 0.5) * 3 + 0.5, 0, 1)[..., None]
    st = st * (1 - tun * 0.5) + TUNDRA * tun * 0.5
    col = meadow * (1 - steppe[..., None]) + st * steppe[..., None]
    # rüzgâr çizgileri: bozkırda uzun, yatık, açık-koyu fırça izleri
    streak = noise(n, 14, 3, 2)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    s = np.sin((xx * 0.55 + yy * 0.18) / (3.2 * k) + streak * 30) * (noise(n, 15, 30, 2) - 0.4)
    col *= (1 + 0.08 * s * steppe)[..., None]
    # çatlak toprak: bozkırın kuru yamalarında
    cr = cracks(n, 21, 34 * k, steppe * (1 - forest) * (1 - mount))
    col = col * (1 - 0.55 * cr[..., None]) + CRACK * 0.55 * cr[..., None]
    # dağ: kaya + yamaç molozu; dik yerde koyu kaya, sırtta açık
    rk = np.clip(mount * 1.6 * (0.5 + slope), 0, 1)[..., None]
    rmix = np.clip(noise(n, 16, 20, 3) * 1.2 - 0.1 + (H / (120 * 1)) * 0.6, 0, 1)[..., None]
    rock = ROCK_A * (1 - rmix) + ROCK_B * rmix
    col = col * (1 - rk) + rock * rk
    scree = np.clip(mount * (1 - slope) * 0.5, 0, 1)[..., None] * 0.5
    col = col * (1 - scree) + SCREE * scree
    # CC0 dokular (ambientCG): toprak her yerde, kaya dağda - yakından boyalı
    # zemin gibi okunsun diye yalnız parlaklık ayrıntısı (renk paletten)
    col = col * texdetail(TEX_GROUND, n, 170 * k, 0.55)[..., None] ** (1 - rk) \
        * texdetail(TEX_ROCK, n, 120 * k, 0.8)[..., None] ** rk
    # orman tabanı (ağaçlar üstüne gelecek)
    fl = ndi.gaussian_filter(forest, 2 * k)[..., None]
    col = col * (1 - fl * 0.85) + FLOOR * fl * 0.85
    # kıyı: ince açık kum/çakıl şeridi
    dw = ndi.distance_transform_edt(~wb) / k
    sh = np.clip(1 - dw / 6, 0, 1)[..., None] * (1 - wb[..., None])
    col = col * (1 - sh * 0.6) + SHORE * sh * 0.6
    # su: kıyıdan derine koyulaşan
    dlt = np.clip(ndi.distance_transform_edt(wb) / (35 * k), 0, 1)[..., None]
    wcol = WATER_SHALLOW * (1 - dlt) + WATER * dlt
    col = np.where(wb[..., None], wcol, col)
    # yollar: toz izi (sürülmüş toprak)
    col = col * (1 - roads[..., None] * 0.3) + DUST * roads[..., None] * 0.3
    # tarlalar (yerleşim parselleri) ve ince fırça gürültüsü
    grain = (noise(n, 17, 160, 2) - 0.5) * 0.10 + (noise(n, 18, 40, 2) - 0.5) * 0.10
    col *= (1 + grain)[..., None]
    return np.clip(col, 0, 1), forest, steppe, mount, wb


def tree_points(forest, steppe, mount, wb, foot, roads, n_units, seed=5):
    rng = np.random.default_rng(seed)
    n = forest.shape[0]
    k = n / n_units
    pts = []
    sp = 6.0
    g = np.arange(0, n_units, sp)
    X, Y = np.meshgrid(g, g)
    X = X + rng.random(X.shape) * sp
    Y = Y + rng.random(Y.shape) * sp
    ix = np.clip((X * k).astype(int), 0, n - 1)
    iy = np.clip((Y * k).astype(int), 0, n - 1)
    fo = forest[iy, ix]
    bad = wb[iy, ix] | (foot[iy, ix] > 0.2) | (roads[iy, ix] > 0.2)
    lone = 0.004 * (1 - steppe[iy, ix]) + 0.0015 * steppe[iy, ix]
    keep = (rng.random(X.shape) < np.clip(fo * 1.1, 0, 1) + lone) & ~bad
    conifer = rng.random(X.shape) < (0.35 + 0.5 * mount[iy, ix])
    for x, y, c in zip(X[keep], Y[keep], conifer[keep]):
        pts.append([round(float(x), 1), round(float(y), 1), int(c)])
    # bozkır çalısı: koyu, alçak
    sp2 = 9.0
    g2 = np.arange(0, n_units, sp2)
    X, Y = np.meshgrid(g2, g2)
    X = X + rng.random(X.shape) * sp2
    Y = Y + rng.random(Y.shape) * sp2
    ix = np.clip((X * k).astype(int), 0, n - 1)
    iy = np.clip((Y * k).astype(int), 0, n - 1)
    pr = 0.025 * steppe[iy, ix] * (1 - forest[iy, ix]) * (noise(n, 31, 7, 2)[iy, ix] > 0.5)
    keep = (rng.random(X.shape) < pr) & ~wb[iy, ix] & (foot[iy, ix] < 0.2) & (roads[iy, ix] < 0.2)
    for x, y in zip(X[keep], Y[keep]):
        pts.append([round(float(x), 1), round(float(y), 1), 2])
    return pts


def main():
    f = dict(np.load(sys.argv[1]))
    out = sys.argv[2]
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 2048
    col, forest, steppe, mount, wb = build(f, n)
    Image.fromarray((col * 255).astype(np.uint8)).save(os.path.join(out, "albedo.png"))
    foot = ndi.zoom(f["foot"], n / f["foot"].shape[0], order=0)
    roads = ndi.zoom(f["roads"], n / f["roads"].shape[0], order=1)
    pts = tree_points(forest, steppe, mount, wb, foot, roads, f["water"].shape[0])
    json.dump(pts, open(os.path.join(out, "trees.json"), "w"))
    print("albedo", col.shape, "ağaç", len(pts))


if __name__ == "__main__":
    main()
