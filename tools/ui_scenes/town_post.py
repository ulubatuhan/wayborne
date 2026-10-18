"""Kasaba render'ını elle mürekkeplenmiş bir görünüşe çeker.

Girdi: town_scene.py'nin beauty.png (gökyüzü saydam), ids.png, depth.png.
Çıktı: data/assets/ui/towns/<şehir>/background.jpg ve mask.png.

Adımlar, sırasıyla:
  1. gökyüzü: boyalı degrade + fbm bulut + soluk ay (render'da gök saydam,
     çünkü Cycles'ın düz rengi resim gibi değil, ekran gibi okunuyordu);
  2. sis: derinlikle artan, gökyüzü renginde - uzaktaki kale siluete döner;
  3. renk: doygunluğu kır, gölgeleri mor-kömüre it, S eğrisi; sıcak ışık
     (pencereler, fenerler) doygun kalır - rengin tek kaynağı ışıktır;
  4. mürekkep: parlaklık + derinlik + maske kenarlarından Sobel, yakında
     kalın uzakta ince;
  5. kâğıt dokusu (ambientCG Paper005, çarp), kir ve kenar kararması.

Hepsi tohumlu; aynı girdi aynı resmi verir.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BUILD = os.path.join(ROOT, "build", "ui_scenes")
CFG = os.path.join(ROOT, "tools", "ui_scenes", "towns.json")
OUT = os.path.join(ROOT, "data", "assets", "ui", "towns")
PAPER = os.path.join(ROOT, "art_source", "textures", "ambientcg", "Paper005", "Paper005_1K-JPG_Color.jpg")
GRIME = os.path.join(ROOT, "data", "assets", "ui", "grim", "grime_overlay.png")

VENUE_IDS = {
    "yard": (1, 0, 0), "market": (0, 1, 0), "guild": (0, 0, 1), "tavern": (1, 1, 0),
    "church": (1, 0, 1), "tailor": (0, 1, 1), "gate": (1, 0.5, 0),
}


def fbm(h, w, seed, octaves=5, base=4):
    rng = np.random.default_rng(seed)
    out = np.zeros((h, w), np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        cells = base * (2 ** o)
        grid = rng.random((cells + 1, int(cells * w / h) + 2)).astype(np.float32)
        img = Image.fromarray((grid * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        out += amp * np.asarray(img, np.float32) / 255.0
        total += amp
        amp *= 0.5
    return out / total


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def sky(h, w, p, seed):
    y = np.linspace(0.0, 1.0, h)[:, None]
    zen = np.array(p["zenith"], np.float32) / 255.0
    hor = np.array(p["horizon"], np.float32) / 255.0
    t = smoothstep(0.05, p.get("horizon_y", 0.62), y) ** 1.6
    col = zen[None, None, :] * (1 - t[..., None]) + hor[None, None, :] * t[..., None]
    col = np.broadcast_to(col, (h, w, 3)).copy()
    clouds = fbm(h, w, seed, 6, 3)
    streak = fbm(h, w * 3, seed + 1, 4, 2)[:, ::3]  # yatay uzamış bulut
    c = smoothstep(0.45, 0.75, 0.6 * clouds + 0.4 * streak) * (0.35 + 0.65 * (1 - t))
    cl = np.array(p["cloud"], np.float32) / 255.0
    col = col * (1 - c[..., None] * 0.85) + cl * c[..., None] * 0.85
    # ay: soluk disk + hale, bulutun arkasında kalır
    mx, my = p.get("moon", [0.78, 0.16])
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.hypot(xx - mx * w, (yy - my * h)) / h
    r = 0.038
    disc = smoothstep(r, r * 0.92, d) * (1 - c * 0.7)
    halo = np.exp(-(d / 0.16) ** 2) * 0.22 * (1 - c * 0.5)
    moon = np.array([0.86, 0.82, 0.70], np.float32)
    col = col + moon * (disc[..., None] * 0.75 + halo[..., None])
    return np.clip(col, 0, 1)


def sobel(a):
    gx = np.zeros_like(a)
    gy = np.zeros_like(a)
    gx[:, 1:-1] = a[:, 2:] - a[:, :-2]
    gy[1:-1, :] = a[2:, :] - a[:-2, :]
    return np.hypot(gx, gy)


def grade(rgb, p):
    lum = (rgb * np.array([0.299, 0.587, 0.114], np.float32)).sum(-1, keepdims=True)
    mx = rgb.max(-1, keepdims=True)
    mn = rgb.min(-1, keepdims=True)
    sat = (mx - mn) / (mx + 1e-4)
    warm = np.clip((rgb[..., :1] - rgb[..., 2:3]) * 2.2, 0, 1) * smoothstep(0.25, 0.6, lum)
    keep = 0.38 + 0.62 * warm  # sıcak ışık doygun kalır, gerisi solar
    rgb = lum + (rgb - lum) * keep
    # gölgeler mor-kömüre, S eğrisi
    shadow = np.array(p.get("shadow", [26, 20, 30]), np.float32) / 255.0
    s = smoothstep(0.0, 0.35, lum)
    rgb = rgb * s + (shadow * 0.5 + rgb * 0.85) * (1 - s)
    rgb = np.clip(rgb, 0, 1)
    rgb = rgb * rgb * (3 - 2 * rgb) * 0.55 + rgb * 0.45
    del sat
    return np.clip(rgb * p.get("exposure", 1.12), 0, 1)


def ink(lum, depth, ids, alpha):
    near = 1.0 - smoothstep(0.15, 0.9, depth)
    e = sobel(lum) * 3.2 + sobel(depth) * 9.0 + sobel(alpha) * 2.0
    for c in range(3):
        e += sobel(ids[..., c]) * 1.5
    e = smoothstep(0.18, 0.55, e) * (0.45 + 0.55 * near)
    img = Image.fromarray((np.clip(e, 0, 1) * 255).astype(np.uint8))
    img = img.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    return np.asarray(img, np.float32) / 255.0


def mask_from_ids(ids):
    """İsabetli kimlik: her pikseli en yakın mekân rengine, eşikle."""
    out = np.zeros(ids.shape[:2], np.uint8)
    for i, (name, col) in enumerate(VENUE_IDS.items(), start=1):
        d = np.abs(ids - np.array(col, np.float32)).sum(-1)
        out[d < 0.35] = i
    return out


def process(city):
    cfg = json.load(open(CFG))[city]
    p = cfg["post"]
    src = os.path.join(BUILD, "town_" + city)
    beauty = Image.open(os.path.join(src, "beauty.png")).convert("RGBA")
    w, h = beauty.size
    b = np.asarray(beauty, np.float32) / 255.0
    rgb, alpha = b[..., :3], b[..., 3]
    ids = np.asarray(Image.open(os.path.join(src, "ids.png")).convert("RGB").resize((w, h), Image.NEAREST), np.float32) / 255.0
    depth = np.asarray(Image.open(os.path.join(src, "depth.png")).convert("I;16").resize((w, h)), np.float32)
    depth = (depth / 65535.0) ** 2.2
    depth = np.where(alpha > 0.5, depth, 1.0)

    town = grade(rgb, p)
    skyc = sky(h, w, p, cfg.get("seed", 1))
    fogc = np.array(p["fog"], np.float32) / 255.0
    fog = smoothstep(0.35, 0.95, depth) * p.get("fog_amount", 0.5)
    # yere yakın sis bandı: alt kenardan yükselen değil, ufka yaslanan
    yy = np.linspace(0, 1, h)[:, None]
    band = np.exp(-((yy - p.get("horizon_y", 0.62)) / 0.12) ** 2) * 0.25
    fog = np.clip(fog + band * smoothstep(0.2, 0.6, depth), 0, 0.9)
    town = town * (1 - fog[..., None]) + fogc * fog[..., None]
    a = alpha[..., None]
    img = town * a + skyc * (1 - a)
    # ışık taşması: sıcak, parlak pikseller (pencere, fener) etrafa sızar
    lumt = (rgb * np.array([0.299, 0.587, 0.114], np.float32)).sum(-1)
    hot = smoothstep(0.45, 0.9, lumt) * np.clip((rgb[..., 0] - rgb[..., 2]) * 2.0, 0, 1)
    glow = Image.fromarray((hot * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(w / 90))
    g = np.asarray(glow, np.float32)[..., None] / 255.0
    img = img + g * np.array([1.0, 0.55, 0.22], np.float32) * p.get("glow", 0.9)

    lum = (img * np.array([0.299, 0.587, 0.114], np.float32)).sum(-1)
    lines = ink(lum, depth, ids, alpha)
    inkc = np.array([0.03, 0.02, 0.03], np.float32)
    img = img * (1 - lines[..., None] * 0.85) + inkc * lines[..., None] * 0.85

    if os.path.exists(PAPER):
        paper = Image.open(PAPER).convert("L").resize((w, h), Image.BICUBIC)
        pa = np.asarray(paper, np.float32) / 255.0
        img = img * (0.86 + 0.14 * (pa / max(pa.mean(), 1e-3)))[..., None]
    if os.path.exists(GRIME):
        g = Image.open(GRIME).convert("RGBA").resize((w, h), Image.BICUBIC)
        ga = np.asarray(g, np.float32)[..., 3] / 255.0
        img = img * (1 - ga[..., None] * 0.35)
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.hypot((xx / w - 0.5) * 1.15, (yy / h - 0.48))
    img = img * (1 - smoothstep(0.42, 0.85, r)[..., None] * 0.6)
    rng = np.random.default_rng(cfg.get("seed", 1) + 7)
    img = img + (rng.random((h, w, 1)).astype(np.float32) - 0.5) * 0.035

    dst = os.path.join(OUT, city)
    os.makedirs(dst, exist_ok=True)
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(os.path.join(dst, "background.jpg"), quality=88)
    Image.fromarray(mask_from_ids(ids)).save(os.path.join(dst, "mask.png"))
    json.dump({"venues": list(VENUE_IDS)}, open(os.path.join(dst, "mask.json"), "w"))
    print("YAZILDI", dst)


if __name__ == "__main__":
    for c in sys.argv[1:]:
        process(c)
