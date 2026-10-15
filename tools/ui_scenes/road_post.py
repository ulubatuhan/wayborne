"""Yol katmanlarını kasabalarla aynı mürekkepli görünüşe çeker.

Girdi: road_scene.py'nin build/ui_scenes/road_<biyom>/<katman>.png'leri.
Çıktı: data/assets/ui/road/<biyom>/<katman>.png ve layout.json.

Kasaba son işlemesinin (town_post.py) yol için olan yarısı: ton, pus,
mürekkep, gren. Farklar:
  * gökyüzü, kenar kararması ve kâğıt yok - onlar yolun kendi işi
    (TravelBand saat ve havaya göre çiziyor), katman yalnızca manzara;
  * Sobel **sarmalı** (np.roll): şerit yatayda döşeniyor, sağ kenarın
    komşusu sol kenar - düz bir türev dikişte çizgi bırakırdı;
  * renk nötr gün ışığında kalıyor, oyun katmanı evrenin ışığıyla
    çarpıyor (gece, şafak, yağmur sistemin kendisi);
  * üstteki tamamen saydam satırlar kırpılıyor, bağlantı noktaları
    alttan piksel olarak yazılıyor (alt kenar sabit kaldığı için kırpma
    onları bozmuyor).

    python3 tools/ui_scenes/road_post.py forest steppe ...
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from town_post import grade, smoothstep  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BUILD = os.path.join(ROOT, "build", "ui_scenes")
OUT = os.path.join(ROOT, "data", "assets", "ui", "road")

# Katman başına: pusa ne kadar (uzak katman soluk), mürekkep kalınlığı.
LAYER_POST = {
    # Uzak: mürekkepsiz, puslu, yumuşak - Oregon Trail'in derinliği hava
    # perspektifinden ve alan derinliğinden geliyor, çizgiden değil.
    "far": {"haze": 0.50, "ink": 0.0, "width": 1, "lum": 0.0, "blur": 2.2},
    "mid": {"haze": 0.10, "ink": 0.45, "width": 1, "lum": 1.6, "blur": 0.9},
    # Kervanın düzlemi: keskin, mürekkepli - göz burada.
    "ground": {"haze": 0.0, "ink": 0.6, "width": 3, "lum": 0.9, "blur": 0.0},
    # Kameraya en yakın tarla: koyu ve bulanık, sahneyi alttan çerçeveliyor.
    "fore": {"haze": 0.0, "ink": 0.25, "width": 1, "lum": 1.0, "blur": 2.6, "dark": 0.62},
}
HAZE = np.array([0.60, 0.64, 0.68], np.float32)
GRADE = {"shadow": [30, 26, 34], "exposure": 1.05}
SATURATION = 1.45


def wsobel(a):
    gx = np.roll(a, -1, 1) - np.roll(a, 1, 1)
    gy = np.zeros_like(a)
    gy[1:-1, :] = a[2:, :] - a[:-2, :]
    return np.hypot(gx, gy)


def wrap_filter(img, filt, pad):
    """Bir PIL süzgecini yatayda sarmalı uygular: iki yana komşu dilimi
    ekle, süz, kes."""
    w, h = img.size
    big = Image.new(img.mode, (w + 2 * pad, h))
    big.paste(img.crop((w - pad, 0, w, h)), (0, 0))
    big.paste(img, (pad, 0))
    big.paste(img.crop((0, 0, pad, h)), (w + pad, 0))
    return big.filter(filt).crop((pad, 0, pad + w, h))


def process_layer(src, layer, seed):
    p = LAYER_POST[layer]
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    b = np.asarray(im, np.float32) / 255.0
    rgb, alpha = b[..., :3], b[..., 3].copy()
    # Gölge yakalayıcının uzak kenarı ve gürültü: neredeyse saydam pikseller
    # kırpmayı bozup karenin tepesine dek bir sis bırakıyordu.
    alpha[alpha < 0.04] = 0.0
    img = grade(rgb, GRADE)
    # Kasabanın tonu gece içindi ve rengin çoğunu siliyordu; gündüz yolda
    # zeytin, pas ve kemik tonları okunabilsin diye bir kısmı geri.
    glum = (img * np.array([0.299, 0.587, 0.114], np.float32)).sum(-1, keepdims=True)
    img = np.clip(glum + (img - glum) * SATURATION, 0, 1)
    img = img * (1 - p["haze"]) + HAZE * p["haze"]
    lum = (img * np.array([0.299, 0.587, 0.114], np.float32)).sum(-1)
    soft = wrap_filter(Image.fromarray((np.clip(lum * alpha, 0, 1) * 255).astype(np.uint8)),
                       ImageFilter.GaussianBlur(1.4), 8)
    soft = np.asarray(soft, np.float32) / 255.0
    e = wsobel(soft) * p["lum"] + wsobel(alpha) * 2.4
    e = smoothstep(0.2, 0.6, e) * p["ink"]
    line = Image.fromarray((np.clip(e, 0, 1) * 255).astype(np.uint8))
    if p["width"] > 1 and p["ink"] > 0.0:
        line = wrap_filter(line, ImageFilter.MaxFilter(p["width"]), 8)
    line = wrap_filter(line, ImageFilter.GaussianBlur(0.6), 8)
    lines = np.asarray(line, np.float32) / 255.0
    inkc = np.array([0.04, 0.03, 0.04], np.float32)
    img = img * (1 - lines[..., None] * 0.85) + inkc * lines[..., None] * 0.85
    # Siluet çizgisi kenarın dışına da taşıyor: o pikseller saydamdı.
    out_a = np.maximum(alpha, lines * 0.9 * smoothstep(0.0, 0.05, wrap_max(alpha, 3)))
    rng = np.random.default_rng(seed)
    img = img + (rng.random((h, w, 1)).astype(np.float32) - 0.5) * 0.03
    img = img * p.get("dark", 1.0)
    if p.get("blur", 0.0) > 0.0:
        img, out_a = wrap_blur(img, out_a, p["blur"])
    rgba = np.dstack([np.clip(img, 0, 1), np.clip(out_a, 0, 1)])
    rows = np.where((rgba[..., 3] > 0.2).sum(1) > 2)[0]
    top = max(0, int(rows.min()) - 2) if rows.size else 0
    return Image.fromarray((rgba[top:] * 255).astype(np.uint8)), h - top


def wrap_blur(rgb, alpha, radius):
    """Alan derinliği: önçarpılmış renkle bulanıklık, yatayda sarmalı (dikiş
    açılmasın), dikeyde kenar uzatmalı. Önçarpılmazsa saydam kenarın siyahı
    ota sızar."""
    from scipy.ndimage import gaussian_filter
    pre = np.dstack([rgb * alpha[..., None], alpha]).astype(np.float32)
    out = np.empty_like(pre)
    for c in range(4):
        out[..., c] = gaussian_filter(pre[..., c], radius, mode=("nearest", "wrap"))
    a = out[..., 3]
    return np.clip(out[..., :3] / np.maximum(a, 1e-4)[..., None], 0, 1), a


def wrap_max(a, size):
    img = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))
    return np.asarray(wrap_filter(img, ImageFilter.MaxFilter(size), 4), np.float32) / 255.0


def process(biome):
    src = os.path.join(BUILD, "road_" + biome)
    layout = json.load(open(os.path.join(src, "layout.json")))
    dst = os.path.join(OUT, biome)
    os.makedirs(dst, exist_ok=True)
    out = {}
    for i, layer in enumerate(("far", "mid", "ground", "fore")):
        path = os.path.join(src, layer + ".png")
        if not os.path.exists(path):
            continue
        orig_h = Image.open(path).size[1]
        img, h = process_layer(path, layer, 11 + i)
        img.save(os.path.join(dst, layer + ".png"), optimize=True)
        spec = layout[layer]
        entry = {"L": spec["L"], "width": img.size[0], "height": h,
                 "anchor_px": round(spec["anchor_v"] * orig_h, 1)}
        for k in ("road_v", "road_top_v", "road_bottom_v"):
            if k in spec:
                entry[k.replace("_v", "_px")] = round(spec[k] * orig_h, 1)
        out[layer] = entry
    json.dump(out, open(os.path.join(dst, "layout.json"), "w"), indent=1)
    print("YAZILDI", dst)


if __name__ == "__main__":
    for b in sys.argv[1:]:
        process(b)
