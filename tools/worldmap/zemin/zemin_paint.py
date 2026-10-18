"""Wayborne zeminini referans oyunun haritasının diline yeniden boyar.

Ücretsiz yol (üretici model yok): coğrafya doğrudan mevcut zeminden ve
maskelerden okunuyor, bu yüzden kıyı, göl, dağ ve orman yerinden oynamıyor.

  1. Sınıf haritası (4096): su = zeminin mavi-gri pikselleri ∪ maske, dağ ve
     orman = maskeler + zeminin kendi koyu yeşili; sınırlar yumuşatılıyor.
  2. Ayrıntı katmanı: zeminin parlaklığı / yerel ortalaması - tarama, ağaç
     işaretleri, sırt çizgileri. Yavaş değişimler (yanık kenar, kâğıt
     lekesi) bu oranda yok oluyor.
  3. referans harita paleti: zeytin çayır ile saman tarlası arasında iki ölçekli yama,
     dağda sıcak gri-kahve, ormanda koyu yeşil, suda kurşuni mavi (kıyıya
     doğru açılıyor); kıyıda mürekkep çizgisi ve kıyıya paralel dalga
     çizgileri; nehir dolguları maviye.
  4. Pusula sökülüyor (zemine pişmişti), kâğıt dokusu hafifçe; yazı, ikon,
     çerçeve yok.

    python3 zemin_paint.py <kök> <varyant> <çıktı.png>
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

VARIANTS = {
    # ad: (ayrıntı gücü, mürekkep, yama kontrastı, doygunluk)
    "a": (0.85, 0.75, 0.55, 1.00),
    "b": (1.25, 1.00, 0.70, 0.90),
    "c": (0.80, 0.70, 0.40, 1.10),
}

MEADOW = np.array([0.50, 0.54, 0.31])
STRAW = np.array([0.70, 0.64, 0.40])
MOUNTAIN = np.array([0.60, 0.55, 0.44])
FOREST = np.array([0.27, 0.33, 0.19])
WATER_DEEP = np.array([0.40, 0.50, 0.53])
WATER_SHORE = np.array([0.62, 0.70, 0.69])
RIVER = np.array([0.46, 0.58, 0.62])
INK = np.array([0.16, 0.13, 0.09])

# Pusula: zeminin sol altı (4096 uzayı), suyun üstüne pişmiş.
COMPASS = (520, 3520, 470)


def load(root, name, size):
    im = Image.open(os.path.join(root, "images", name)).convert("L").resize((size, size), Image.BILINEAR)
    return np.asarray(im, np.float32) / 255.0


def fbm(n, seed, base, octaves=4):
    rng = np.random.default_rng(seed)
    out = np.zeros((n, n), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        cells = base * 2 ** o
        g = rng.random((cells + 1, cells + 1)).astype(np.float32)
        out += amp * np.asarray(Image.fromarray((g * 255).astype(np.uint8)).resize((n, n), Image.BICUBIC), np.float32) / 255
        tot += amp
        amp *= 0.5
    return out / tot


def smooth(a, s):
    return ndi.gaussian_filter(a, s)


def paint(root, variant):
    det_k, ink_k, patch_k, sat_k = VARIANTS[variant]
    base = np.asarray(Image.open(os.path.join(root, "images", "base_map_4096.jpg")).convert("RGB"), np.float32) / 255
    n = base.shape[0]
    r, g, b = base[..., 0], base[..., 1], base[..., 2]
    lum = 0.299 * r + 0.587 * g + 0.114 * b

    # --- sınıflar
    m_water = load(root, "mask_water.png", n)
    m_mount = load(root, "mask_mountain.png", n)
    m_forest = load(root, "mask_forest.png", n)
    # Su: zeminde su b-r ≈ -0.11, kara ≈ -0.27 (ölçüldü). Maske kaba bir
    # öncül; kıyının kendisi rengin sınıflamasından, maskenin ±kenarında.
    # Eşik kıyının açık su halkasını da içeriyor: zeminde mürekkep çizgisinin
    # içindeki açık mavi şerit suyun parçası.
    wc = np.clip((smooth(b - r, 1.2) + 0.215) / 0.07, 0, 1)
    prior = smooth(m_water, 25)
    # Kenarda zeminin yanık çerçevesi renk sınıflamasını yanıltıyor: orada
    # maskeye güven (deniz karenin kenarına kadar gidiyor).
    yy, xx = np.mgrid[0:n, 0:n]
    border = np.minimum(np.minimum(xx, yy), np.minimum(n - 1 - xx, n - 1 - yy))
    water = np.where(prior > 0.85, 1.0, np.where(prior < 0.04, 0.0, wc))
    water = np.where(border < 70, (prior > 0.4).astype(np.float32), water)
    water = ndi.binary_opening(water > 0.5, iterations=1)
    # Karadaki küçük açık lekeler (ormanın içinde boşluk) su değil: maskeye
    # değmeyen ve küçük olan bileşenler atılıyor.
    lab, nlab = ndi.label(water)
    if nlab:
        size = ndi.sum(water, lab, index=np.arange(1, nlab + 1))
        touch = ndi.maximum(prior > 0.5, lab, index=np.arange(1, nlab + 1))
        keep = np.concatenate([[False], (size > 2500) | touch.astype(bool)])
        water = keep[lab]
    water = smooth(water.astype(np.float32), 1.0)
    river_src = wc * (prior < 0.04)
    cy, cx, cr = COMPASS[1], COMPASS[0], COMPASS[2]
    compass = np.clip((cr - np.hypot(xx - cx, yy - cy)) / 40.0, 0, 1)
    water = np.maximum(water, compass)
    green = smooth(g - (r + b) * 0.5, 4)
    # Orman maskesi elle çizilmiş elipsler: yalnızca kapı. Ormanın kendisi
    # zeminin koyu yeşili - elips tek başına yumuşak yeşil bir leke bırakıyordu.
    gate = smooth(m_forest, 40) > 0.08
    forest = np.clip((green + 0.005) / 0.04, 0, 1) * np.clip((0.62 - lum) / 0.15, 0, 1) * gate
    forest = smooth(forest, 3) * (1 - water)
    mount = smooth(m_mount, 12) * (1 - water)

    # --- ayrıntı: parlaklığın yerel ortalamaya oranı
    local = smooth(lum, 18) + 1e-3
    detail = np.clip(lum / local, 0.3, 1.6)
    detail = 1 + (detail - 1) * det_k
    ink = np.clip((local - lum) / local * 2.0 - 0.10, 0, 1) ** 1.5 * ink_k
    edge = np.clip((border - 12) / 40.0, 0, 1)
    detail = 1 + (detail - 1) * edge * (1 - compass)
    ink = ink * edge * (1 - compass)

    # --- renk
    patches = fbm(n, 3, 6)
    fields = fbm(n, 7, 24, 2)
    t = np.clip((patches - 0.5) * 2.4 * patch_k + 0.5 + (fields - 0.5) * 0.6 * patch_k, 0, 1)[..., None]
    land = MEADOW * (1 - t) + STRAW * t
    land = land * (1 - mount[..., None] * 0.85) + MOUNTAIN * mount[..., None] * 0.85
    land = land * (1 - forest[..., None]) + FOREST * forest[..., None]
    col = land * detail[..., None]

    dist = ndi.distance_transform_edt(water > 0.5)
    shore = np.exp(-dist / 70.0)[..., None]
    wcol = WATER_DEEP * (1 - shore) + WATER_SHORE * shore
    wnoise = fbm(n, 11, 10, 3)[..., None]
    wcol = wcol * (0.94 + 0.12 * wnoise)
    # kıyıya paralel dalga çizgileri (oyma haritaların dili)
    for d0, k in ((18.0, 0.14), (40.0, 0.08)):
        ring = np.exp(-((dist - d0) / 1.8) ** 2) * (dist > 4)
        wcol = wcol * (1 - ring[..., None] * k)
    col = col * (1 - water[..., None]) + wcol * water[..., None]

    # nehirler: karadaki ince, açık, mavimsi dolgular
    river = smooth(river_src, 1.0) * (lum > 0.5) * (1 - water)
    river = smooth(river, 1.2)
    col = col * (1 - river[..., None] * 0.8) + RIVER * river[..., None] * 0.8

    # mürekkep: zeminin koyu çizgileri + kıyı çizgisi
    coast = np.clip(1 - np.abs(smooth(water, 1.4) - 0.5) * 4, 0, 1)
    ink = np.maximum(ink * (1 - water), coast * 0.9)
    col = col * (1 - ink[..., None]) + INK * ink[..., None]

    # doygunluk ve kâğıt
    gl = col.mean(-1, keepdims=True)
    col = gl + (col - gl) * sat_k
    paper_path = "/home/user/wayborne/art_source/textures/ambientcg/Paper005/Paper005_1K-JPG_Color.jpg"
    if os.path.exists(paper_path):
        p = np.asarray(Image.open(paper_path).convert("L"), np.float32) / 255
        p = np.tile(p, (n // p.shape[0] + 1, n // p.shape[1] + 1))[:n, :n]
        col = col * (0.9 + 0.1 * p / p.mean())[..., None]
    grain = np.random.default_rng(5).random((n, n)).astype(np.float32)
    col = col + (grain[..., None] - 0.5) * 0.025
    return np.clip(col, 0, 1), water


def main():
    root, variant, out = sys.argv[1], sys.argv[2], sys.argv[3]
    col, water = paint(root, variant)
    Image.fromarray((col * 255).astype(np.uint8)).save(out)
    np.save(out + ".water.npy", (water > 0.5))
    print("YAZILDI", out)


if __name__ == "__main__":
    main()
