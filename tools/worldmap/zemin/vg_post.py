"""referans oyun denemesi, adım 5: render'ı boyanmış haritaya çevir.

  * Kuwahara filtresi: ayrıntıyı düz renk lekelerine böler (yağlı boya fırçası);
  * çizgi-integral evrişimi (LIC): gürültü, yükseklik eğrileri boyunca sürülür -
    dağda yamaca paralel fırça izi, düzde rüzgâr yönünde uzun izler;
  * renk: doygunluk düşük, gölgeler sıcak isli kahve, ışıklar soluk kemik;
  * tuval dokusu ve ince tane.

    python3 -I vg_post.py <vg klasörü> <çıktı.png>
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from vg_height import noise  # noqa: E402


def kuwahara(img, r):
    """Klasik Kuwahara: dört çeyrek pencerenin en düşük varyanslısının ortalaması."""
    lum = img @ np.array([0.299, 0.587, 0.114], np.float32)
    k = r + 1
    mean_c = [ndi.uniform_filter(img[..., c], k) for c in range(3)]
    mean_l = ndi.uniform_filter(lum, k)
    var = ndi.uniform_filter(lum * lum, k) - mean_l ** 2
    offs = [(-r // 2, -r // 2), (-r // 2, r // 2), (r // 2, -r // 2), (r // 2, r // 2)]
    best = np.full(lum.shape, np.inf, np.float32)
    out = np.zeros_like(img)
    for dy, dx in offs:
        v = np.roll(var, (dy, dx), (0, 1))
        sel = v < best
        best = np.where(sel, v, best)
        for c in range(3):
            out[..., c] = np.where(sel, np.roll(mean_c[c], (dy, dx), (0, 1)), out[..., c])
    return out


def lic(tex, vx, vy, steps, h):
    n = tex.shape[0]
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    acc = tex.copy()
    wsum = 1.0
    for sgn in (1, -1):
        px, py = xx.copy(), yy.copy()
        for i in range(steps):
            ix = np.clip(px, 0, n - 1)
            iy = np.clip(py, 0, n - 1)
            ux = ndi.map_coordinates(vx, [iy, ix], order=1)
            uy = ndi.map_coordinates(vy, [iy, ix], order=1)
            px += sgn * ux * h
            py += sgn * uy * h
            w = 1 - i / steps
            acc += w * ndi.map_coordinates(tex, [np.clip(py, 0, n - 1), np.clip(px, 0, n - 1)], order=1)
            wsum += w
    return acc / wsum


def grade(c):
    lum = c @ np.array([0.299, 0.587, 0.114], np.float32)
    c = c * 0.72 + lum[..., None] * 0.28                  # soluk
    shadow = np.array([0.20, 0.15, 0.10])                 # isli kahve gölge
    light = np.array([0.88, 0.82, 0.70])                  # kemik ışık
    t = np.clip(lum, 0, 1)[..., None]
    tint = shadow * (1 - t) + light * t
    c = c * 0.75 + c * tint * 0.45
    c = np.clip((c - 0.03) * 1.12, 0, 1) ** 1.08          # kontrast, koyu
    return c


def main():
    vg, out = sys.argv[1], sys.argv[2]
    img = np.asarray(Image.open(os.path.join(vg, "render.png")).convert("RGB"), np.float32) / 255
    n = img.shape[0]
    F = np.load(os.path.join(vg, "fields.npz"))
    H = ndi.zoom(F["height"], n / F["height"].shape[0], order=1)
    W = ndi.zoom(F["water"], n / F["water"].shape[0], order=1)
    M = np.clip(ndi.zoom(F["mount"], n / F["mount"].shape[0], order=1), 0, 1)
    k = n / 2048

    p = kuwahara(img, max(2, int(round(3 * k))))

    # fırça izi yönü: eğimde yükseklik eğrisi boyunca, düzde rüzgâr (KD-GB)
    Hs = ndi.gaussian_filter(H, 14 * k)
    gy, gx = np.gradient(Hs)
    mag = np.hypot(gx, gy) + 1e-6
    cx, cy = -gy / mag, gx / mag
    wind = np.array([0.94, 0.34])
    wslope = np.clip(mag * 2.5 - 0.25, 0, 1) * M
    vx = cx * wslope + wind[0] * (1 - wslope)
    vy = cy * wslope + wind[1] * (1 - wslope)
    nm = np.hypot(vx, vy) + 1e-6
    vx, vy = vx / nm, vy / nm
    rng = np.random.default_rng(4)
    white = rng.random((n, n)).astype(np.float32)
    white = ndi.gaussian_filter(white, 0.8 * k)
    strokes = lic(white, vx, vy, int(9 * k) + 4, 1.0)
    strokes = (strokes - strokes.mean()) / (strokes.std() + 1e-6)
    amp = (0.035 + 0.035 * M) * (1 - W * 0.7)
    p = p * (1 + strokes[..., None] * amp[..., None])

    # büyük ölçekli boya lekesi (tonun düzensiz dağılımı)
    blot = noise(n, 41, 6, 4) - 0.5
    p = p * (1 + blot[..., None] * 0.18)
    p = grade(np.clip(p, 0, 1))

    # suda yatay, soluk parıltı fırçaları
    sheen = lic(rng.random((n, n)).astype(np.float32), np.ones((n, n), np.float32) * 0.98,
                np.ones((n, n), np.float32) * 0.2, int(18 * k) + 4, 1.0)
    sheen = np.clip((sheen - 0.53) * 9, 0, 1) * (noise(n, 43, 10, 2) > 0.55)
    p = p + (W * sheen * 0.05)[..., None] * np.array([0.7, 0.75, 0.8])

    R = ndi.zoom(F["roads"], n / F["roads"].shape[0], order=1)
    R = ndi.gaussian_filter(R, 0.9 * k)
    rimm = np.clip(ndi.gaussian_filter(R, 2.5 * k) * 1.6 - R, 0, 1)
    dust = np.array([0.62, 0.56, 0.44])
    p = p * (1 - rimm[..., None] * 0.25)
    p = p * (1 - R[..., None] * 0.55) + dust * R[..., None] * 0.55
    # tuval ve tane
    canvas = (noise(n, 44, 300, 1) - 0.5) * 0.06 + (rng.random((n, n)) - 0.5) * 0.035
    p = p * (1 + canvas[..., None])
    yy, xx = np.mgrid[0:n, 0:n] / n
    vig = 1 - 0.30 * np.clip(np.hypot(xx - 0.5, yy - 0.5) * 1.6 - 0.35, 0, 1) ** 1.5
    p = p * vig[..., None]
    Image.fromarray((np.clip(p, 0, 1) * 255).astype(np.uint8)).save(out)
    print("YAZILDI", out)


if __name__ == "__main__":
    main()
