"""referans oyun denemesi 2, son işlem: oyunun dili.

  * ışık dört düz tona bölünür (gölge × albedo, Prop Rules'un "dört ton"u);
  * sıcak akşam ışığı, gölgeler mor-kömür (town_post.grade ile aynı yön);
  * mürekkep: sınıf sınırları (kıyı, sur, ev, orman kenarı), ton sınırları ve
    yamaç kırıkları - siyah, kalınlığı yapının önemine göre;
  * yerleşim pencereleri ve yurt ateşleri: sıcak nokta + taşma ışığı;
  * kâğıt (Paper005) ve kir dokusu, kenarlar karanlığa gömülür.

    python3 -I vg_ink_post.py <vg klasörü> <layout.json> <çıktı.png>
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as ndi

ROOT = "/home/user/wayborne"
PAPER = os.path.join(ROOT, "art_source/textures/ambientcg/Paper005/Paper005_1K-JPG_Color.jpg")
GRIME = os.path.join(ROOT, "data/assets/ui/grim/grime_overlay.png")

LEVELS = [0.10, 0.34, 0.62, 1.0]
THRESH = [0.22, 0.45, 0.72]
WARM = np.array([1.00, 0.80, 0.58], np.float32)
AMBIENT = np.array([0.30, 0.30, 0.42], np.float32)
INK = np.array([0.035, 0.025, 0.03], np.float32)


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def sobel(a):
    gx = np.zeros_like(a)
    gy = np.zeros_like(a)
    gx[:, 1:-1] = a[:, 2:] - a[:, :-2]
    gy[1:-1, :] = a[2:, :] - a[:-2, :]
    return np.hypot(gx, gy)


def load(p, mode="RGB"):
    im = Image.open(p)
    if mode == "I16":
        a = np.asarray(im, np.float32)
        return a / (65535.0 if a.max() > 255 else 255.0)
    return np.asarray(im.convert(mode), np.float32) / 255.0


def posterize(s):
    t = np.full(s.shape, LEVELS[0], np.float32)
    for th, lo, hi in zip(THRESH, LEVELS[:-1], LEVELS[1:]):
        t += (hi - lo) * smoothstep(th - 0.025, th + 0.025, s)
    return t


def grade(rgb):
    lum = (rgb * np.array([0.299, 0.587, 0.114], np.float32)).sum(-1, keepdims=True)
    warm = np.clip((rgb[..., :1] - rgb[..., 2:3]) * 2.2, 0, 1) * smoothstep(0.30, 0.7, lum)
    keep = 0.55 + 0.45 * warm
    rgb = lum + (rgb - lum) * keep
    shadow = np.array([0.10, 0.08, 0.12], np.float32)
    s = smoothstep(0.0, 0.30, lum)
    rgb = rgb * s + (shadow * 0.6 + rgb * 0.7) * (1 - s)
    rgb = np.clip(rgb, 0, 1)
    return np.clip(rgb * rgb * (3 - 2 * rgb) * 0.5 + rgb * 0.5, 0, 1)


def lights(n, vg_fields, layout, rng):
    """Pencere noktaları (şehir/kasaba/köy evleri) ve yurt ateşleri."""
    x0, y0, S = int(vg_fields["x0"]), int(vg_fields["y0"]), int(vg_fields["size"])
    k = n / S
    pts = np.zeros((n, n), np.float32)
    fires = np.zeros((n, n), np.float32)
    for e in layout:
        cx, cy = e["center"]
        if not (x0 - 60 < cx < x0 + S + 60 and y0 - 60 < cy < y0 + S + 60):
            continue
        share = 0.55 if e["kind"].startswith("ic") else 0.4
        for h in e.get("houses", []):
            if rng.random() > share:
                continue
            u = np.array(h["u"])
            v = np.array([-u[1], u[0]])
            p = np.array(h["c"]) + u * (rng.random() - 0.5) * h["L"] * 0.7 + v * (rng.random() - 0.5) * h["W"] * 0.6
            ix, iy = int((p[0] - x0) * k), int((p[1] - y0) * k)
            if 1 <= ix < n - 1 and 1 <= iy < n - 1:
                pts[iy - 1:iy + 2, ix - 1:ix + 2] = 0.6 + 0.4 * rng.random()
        for y_ in e.get("yurts") or []:
            if rng.random() < 0.45:
                c = y_["c"]
                ix = int((c[0] + (rng.random() - 0.5) * 30 - x0) * k)
                iy = int((c[1] + (rng.random() - 0.5) * 30 - y0) * k)
                if 2 <= ix < n - 2 and 2 <= iy < n - 2:
                    fires[iy, ix] = 1.0
        if e.get("khan"):
            c = e["khan"]["c"]
            ix, iy = int((c[0] - x0) * k), int((c[1] - y0) * k + 30 * k)
            if 3 <= ix < n - 3 and 3 <= iy < n - 3:
                fires[iy, ix] = 1.6
    return pts, fires


def main():
    vg, layout_p, out = sys.argv[1], sys.argv[2], sys.argv[3]
    F = np.load(os.path.join(vg, "fields.npz"))
    shade = load(os.path.join(vg, "shade.png"), "I16")
    if shade.ndim == 3:
        shade = shade[..., :3].mean(-1)
    n = shade.shape[0]
    albedo = load(os.path.join(vg, "albedo_r.png"))
    ids = load(os.path.join(vg, "ids.png"))
    H = ndi.zoom(F["height"], n / F["height"].shape[0], order=1)
    W = ndi.zoom(F["water"], n / F["water"].shape[0], order=1) > 0.5
    M = np.clip(ndi.zoom(F["mount"], n / F["mount"].shape[0], order=1), 0, 1)
    R = np.clip(ndi.zoom(F["roads"], n / F["roads"].shape[0], order=1), 0, 1)
    k = n / 2048

    s = shade / np.quantile(shade, 0.995)
    tone = posterize(np.clip(s, 0, 1.2))
    tone = np.where(W, 0.55 + 0.15 * tone, tone)  # su düz kalır
    lit = albedo * (tone[..., None] * WARM + (1 - tone[..., None]) * AMBIENT * 0.55)
    img = grade(lit * 1.25)

    # yollar: akşamda soluk toz şeridi
    Rb = np.clip(ndi.gaussian_filter(R, 0.9 * k) * 1.4, 0, 1)
    edge = np.clip(ndi.gaussian_filter(R, 2.2 * k) * 1.8 - Rb, 0, 1)
    img = img * (1 - edge[..., None] * 0.35)
    img = img * (1 - Rb[..., None] * 0.6) + np.array([0.55, 0.46, 0.33]) * Rb[..., None] * 0.6

    rng = np.random.default_rng(12)
    pts, fires = lights(n, F, json.load(open(layout_p)), rng)
    win = np.array([1.0, 0.72, 0.34], np.float32)
    glow = ndi.gaussian_filter(pts, 5 * k) * 22 + ndi.gaussian_filter(fires, 12 * k) * 900

    # mürekkep
    lum_t = tone
    cls = ids
    e_cls = sum(sobel(cls[..., c]) for c in range(3))
    e_cls = smoothstep(0.25, 0.6, e_cls)
    struct = ((cls[..., 0] > 0.5)).astype(np.float32)  # yapı + yurt (kırmızı kanal)
    e_struct = smoothstep(0.2, 0.5, sobel(ndi.gaussian_filter(struct, 0.5)))
    e_tone = smoothstep(0.10, 0.25, sobel(ndi.gaussian_filter(lum_t, 0.8 * k))) * (0.35 + 0.65 * M)
    gy, gx = np.gradient(ndi.gaussian_filter(H, 1.2 * k))
    cliff = smoothstep(1.1, 2.4, np.hypot(gx, gy) / k) * M
    wb = W.astype(np.float32)
    coast = smoothstep(0.2, 0.5, sobel(ndi.gaussian_filter(wb, 1.0 * k)))
    lines = np.maximum.reduce([e_cls * 0.85, e_struct, e_tone * 0.7, cliff * 0.6, coast])
    li = Image.fromarray((np.clip(lines, 0, 1) * 255).astype(np.uint8))
    li = li.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.7 * k))
    lines = np.asarray(li, np.float32) / 255
    # orman içindeki ağaç ağaç kontur fazla gürültü: ormanın içini yumuşat
    trees = (cls[..., 1] > 0.3) & (cls[..., 0] < 0.5)
    dens = ndi.uniform_filter(trees.astype(np.float32), int(9 * k))
    lines = lines * (1 - 0.55 * smoothstep(0.35, 0.7, dens))
    img = img * (1 - lines[..., None] * 0.88) + INK * lines[..., None] * 0.88

    img = img + np.clip(glow, 0, 1)[..., None] * np.array([0.55, 0.30, 0.10]) * 0.7
    img = np.where((pts > 0)[..., None], img * 0.2 + win * pts[..., None], img)
    core = np.clip(ndi.gaussian_filter(fires, 1.3 * k) * 9, 0, 1)[..., None]
    img = img * (1 - core) + np.array([1.0, 0.66, 0.28]) * core
    # kâğıt, kir, karanlık kenar, tane
    if os.path.exists(PAPER):
        pa = np.asarray(Image.open(PAPER).convert("L").resize((n, n), Image.BICUBIC), np.float32) / 255
        img = img * (0.82 + 0.18 * (pa / pa.mean()))[..., None]
    if os.path.exists(GRIME):
        ga = np.asarray(Image.open(GRIME).convert("RGBA").resize((n, n), Image.BICUBIC), np.float32)[..., 3] / 255
        img = img * (1 - ga[..., None] * 0.4)
    yy, xx = np.mgrid[0:n, 0:n] / n
    r = np.hypot(xx - 0.5, yy - 0.5)
    blot = ndi.gaussian_filter(rng.random((n // 16, n // 16)).astype(np.float32), 1.5)
    blot = ndi.zoom(blot, n / blot.shape[0], order=1)[:n, :n]
    vig = smoothstep(float(os.environ.get('VG_VIG0', 0.30)), 0.72, r + (blot - 0.5) * 0.25)
    img = img * (1 - vig[..., None] * float(os.environ.get('VG_VIG', 0.88)))
    img = img + (rng.random((n, n, 1)).astype(np.float32) - 0.5) * 0.03
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(out)
    print("YAZILDI", out)


if __name__ == "__main__":
    main()
