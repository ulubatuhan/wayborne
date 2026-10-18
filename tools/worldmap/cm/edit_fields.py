"""Kullanıcı düzenlemeleri (2026-10-17, d.docx) - arazi ve yer verisi.

usage: python3 -I edit_fields.py <fields.npz> <places.json> <out_fields.npz> <out_places.json> <out_dir>

1. Doğu kıyısındaki ince şerit adalar (Vorgat'ın doğusu) kaldırılır.
2. Kesgrav'ın doğusundaki koy, doğudaki denize bir boğazla açılır; boğazın ortası
   doğal kaya köprüsü olarak işaretlenir (arch.json, harita pikseli N=8192).
3. Suya taşan kıyı yerleşimleri (ör. Reskel) karaya, kıyıdan kısa bir mesafeye alınır.
Girdi dosyalarının üstüne yazılmaz.
"""
import json
import os
import sys

import numpy as np
from scipy import ndimage as ndi

src_f, src_p, dst_f, dst_p, outdir = sys.argv[1:6]
f = dict(np.load(src_f))
n = f["water"].shape[0]                 # 4096
P = 8192 / n
water = f["water"] > 0.5

# 1) doğudaki ince adalar: kutu içinde tamamen kalan kara parçaları
x0, y0, x1, y1 = 3960, 1880, n, 2360
land_lab, _ = ndi.label(~water)
box = np.zeros_like(water)
box[y0:y1, x0:x1] = True
gone = 0
for lab in np.unique(land_lab[box & ~water]):
    comp = land_lab == lab
    if not (comp & ~box).any():
        water |= comp
        gone += 1
print("ada kaldırıldı", gone)

# 2) boğaz: koy (3300,1125) ile doğu denizi (3750,1150) arasındaki en dar kara şeridi
wl, _ = ndi.label(water)
inlet = wl == wl[1125, 3300]
sea = wl == wl[1150, 3750]
assert wl[1125, 3300] != wl[1150, 3750], "koy zaten denize açık"
din, idx = ndi.distance_transform_edt(~inlet, return_indices=True)
ys, xs = np.nonzero(sea & (np.arange(n)[:, None] > 1000) & (np.arange(n)[:, None] < 1320))
k = int(np.argmin(din[ys, xs]))
b = np.array([xs[k], ys[k]], float)
a = np.array([idx[1][ys[k], xs[k]], idx[0][ys[k], xs[k]]], float)
print("boğaz", a, "->", b, "genişlik", round(float(din[ys[k], xs[k]]), 1))
v = (b - a) / np.linalg.norm(b - a)
a2, b2 = a - v * 12, b + v * 12
yy, xx = np.mgrid[0:n, 0:n]
t = np.clip(((xx - a2[0]) * v[0] + (yy - a2[1]) * v[1]) / np.linalg.norm(b2 - a2), 0, 1)
px, py = a2[0] + t * (b2 - a2)[0], a2[1] + t * (b2 - a2)[1]
dist = np.hypot(xx - px, yy - py)
half = 16 + 3 * np.sin(t * 9.0)          # biraz düzensiz kıyı
chan = dist < half
water |= chan
for key in ("mount", "forest", "steppe", "core", "mz", "mforest", "crease", "roads", "foot"):
    if key in f:
        f[key] = np.where(chan, 0, f[key]).astype(f[key].dtype)
if "height" in f:
    f["height"] = np.where(chan, np.minimum(f["height"], 0), f["height"]).astype(f["height"].dtype)
mid = (a + b) / 2
json.dump(dict(x=float(mid[0] * P), y=float(mid[1] * P), dx=float(v[0]), dy=float(v[1]),
               w=float(2 * 19 * P)), open(os.path.join(outdir, "arch.json"), "w"))

f["water"] = water.astype(np.float32)

# 4) kuzeybatı ormanı (Dornak-Zurek-Taragun): kaynak veride kusursuz bir elips ve düz bir
#    geçiş bloğu. Kenarlar bükülür, iç açıklıklar ve kenarda dağınık kümeler oluşur.
#    Yalnız bu bölgede uygulanır, çevreye yumuşak geçer.
rng = np.random.default_rng(57)


def smooth_noise(sigma):
    a = ndi.gaussian_filter(rng.standard_normal((n, n)).astype(np.float32), sigma)
    return (a - a.mean()) / (a.std() + 1e-6)


R0, R1 = 1050, 1350                                 # bölge (4096 ızgarası): tam etki / geçiş sonu
region = np.clip((R1 - np.maximum(xx, yy * 1.0)) / (R1 - R0), 0, 1).astype(np.float32)
if region.any():
    wx, wy = smooth_noise(90) * 70, smooth_noise(90) * 70   # alan bükülmesi (px)
    fo = ndi.map_coordinates(f["forest"].astype(np.float32), [np.clip(yy + wy, 0, n - 1), np.clip(xx + wx, 0, n - 1)],
                             order=1, mode="nearest")
    fs = ndi.gaussian_filter(fo, 18)
    v = fs * 1.05 + 0.22 * smooth_noise(60) + 0.16 * smooth_noise(22) + 0.08 * smooth_noise(7)
    new = np.clip((v - 0.48) / 0.14, 0, 1)
    new *= ~water
    f["forest"] = (region * new + (1 - region) * f["forest"]).astype(f["forest"].dtype)
    print("kuzeybatı ormanı doğallaştırıldı")
np.savez_compressed(dst_f, **f)

# 3) suya taşan kıyı yerleşimleri karaya
places = json.load(open(src_p))
dl = ndi.distance_transform_edt(~water)          # karadan suya uzaklık
SMALL_R = 20                                       # küçük yerleşim yarıçapı (4096 px)
moved = []
for p in places:
    if p["k"].startswith("ic_"):
        continue                                   # kentler kendi şeklini araziden alıyor
    x, y = int(round(p["x"])), int(round(p["y"]))
    if dl[min(y, n - 1), min(x, n - 1)] >= SMALL_R:
        continue
    r = 70
    ya, yb, xa, xb = max(0, y - r), min(n, y + r), max(0, x - r), min(n, x + r)
    win = dl[ya:yb, xa:xb]
    gy, gx = np.mgrid[ya:yb, xa:xb]
    ok = (win >= SMALL_R + 2) & (win <= SMALL_R + 10)
    if not ok.any():
        continue
    d = np.where(ok, np.hypot(gx - p["x"], gy - p["y"]), 1e9)
    j = np.unravel_index(np.argmin(d), d.shape)
    moved.append((p["en"], (p["x"], p["y"]), (float(gx[j]), float(gy[j]))))
    p["x"], p["y"] = float(gx[j]), float(gy[j])
json.dump(places, open(dst_p, "w"), ensure_ascii=False, separators=(",", ":"))
print("taşınan", len(moved))
for m in moved:
    print("  ", m)
