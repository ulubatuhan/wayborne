#!/usr/bin/env python3
"""Yol göstergelerinin resimleri (moral, stres, takat, tehlike) ve arkalarındaki kart.

Kaynak: art_source/gauges/<gösterge>_<yuksek|orta|dusuk>.png (Gemini, saydam zemin,
gravür üslubu; istemler proje_takibi/referans/gemini_gosterge_promptlari.md).
Çıktı: data/assets/ui/gauges/<id>_<high|mid|low>.png ve medallion.png.

- Bir göstergenin üç hâli aynı kutudan kesilir (üçünün birleşik sınırı), yoksa
  değer değişince nesne kartın içinde zıplar. Teslimatın tuval boyları farklı
  (687x1024, 848x1264, 1696x2528) ama oranları aynı; önce ortak boya ölçeklenir.
- Madalyon üretiliyor, boyanmıyor: eskimiş bronz bir sikke - aşınmış açık orta,
  koyu pas kenar, bir sıra kabartma diş, kalkık dış kenar (kullanıcı kararı
  2026-10-22: dikdörtgen kart değil, daire; örneği bir stok fotoğraftı, kendisi
  filigranlı ve lisanssız olduğu için kullanılmadı, aynı karakter burada üretildi). Mürekkep kuzgun ve diken koyu taşın üstünde kayboluyordu (zemin
  ~#121010, kuzgun ~#1A1818); madalyon onlara açık bir zemin veriyor.

Çıktı PNG'leri elle düzeltilmez: bu aracı değiştirip yeniden koş.
    python3 -I tools/gauge_icons.py
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art_source", "gauges")
OUT = os.path.join(ROOT, "data", "assets", "ui", "gauges")

GAUGES = {"moral": "morale", "stres": "stress", "takat": "stamina", "tehlike": "danger"}
STATES = {"yuksek": "high", "orta": "mid", "dusuk": "low"}

# Ortak tuval (en büyük teslimatın boyu).
CANVAS = (1696, 2528)
# Resmin en uzak opak pikseli madalyonun iç halkasının bu payında durur.
FIT_SHARE = 0.93
ALPHA_SOLID = 24

# Madalyon: eskimiş bronz bir sikke (kullanıcının gösterdiği örnekteki gibi):
# ortası aşınmış açık, kenara doğru koyu pas, bir sıra kabartma diş, kalkık
# dış kenar. Oyunda ~88 px çapında çiziliyor, mipmap'li üç kat küsur.
MEDALLION = 300
RIM_IN = 0.90            # dış kenarın başladığı yarıçap payı
DENTICLE_R = 0.835       # diş sırasının yarıçap payı
DENTICLE_LEN = 0.05     # bir dişin boyu (yarıçap payı)
DENTICLE_W = 0.019       # bir dişin yarı eni (yarıçap payı)
DENTICLE_COUNT = 52
ICON_RADIUS = 0.78       # resmin sığdığı iç dairenin yarıçap payı
WORN = np.array([0.80, 0.72, 0.57])       # aşınmış orta
BRONZE = np.array([0.55, 0.42, 0.26])
TARNISH = np.array([0.22, 0.15, 0.08])
HIGHLIGHT = np.array([0.88, 0.80, 0.62])
EDGE_DARK = np.array([0.08, 0.06, 0.04])
SEED = 7


def load_normalised(path):
    im = Image.open(path).convert("RGBA")
    if im.size != CANVAS:
        im = im.resize(CANVAS, Image.LANCZOS)
    return im


def inner_radius():
    return (MEDALLION * 0.5 - 1.0) * ICON_RADIUS


def export_icons():
    """Her resim madalyonla aynı boyda kare bir tuvale oturur: oyun ikisini üst
    üste aynı dikdörtgene çizer. Ölçek üç hâlin birleşik maskesinden: en uzak
    opak piksel iç halkanın `FIT_SHARE` payına düşer, kutuya sığdırmak dar bir
    meşaleyi ve geniş bir atı gereğinden çok küçültüyordu (ölçüldü)."""
    for src_id, out_id in GAUGES.items():
        images = {s: load_normalised(os.path.join(SRC, f"{src_id}_{s}.png")) for s in STATES}
        mask = np.zeros((CANVAS[1], CANVAS[0]), bool)
        for im in images.values():
            mask |= np.asarray(im.getchannel("A")) > ALPHA_SOLID
        ys, xs = np.nonzero(mask)
        cx = (xs.min() + xs.max()) * 0.5
        cy = (ys.min() + ys.max()) * 0.5
        reach = float(np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2).max())
        scale = FIT_SHARE * inner_radius() / reach
        size = (max(1, round(CANVAS[0] * scale)), max(1, round(CANVAS[1] * scale)))
        offset = (round(MEDALLION * 0.5 - cx * scale), round(MEDALLION * 0.5 - cy * scale))
        for s, im in images.items():
            canvas = Image.new("RGBA", (MEDALLION, MEDALLION), (0, 0, 0, 0))
            canvas.alpha_composite(im.resize(size, Image.LANCZOS), offset) if offset[0] >= 0 and offset[1] >= 0 \
                else canvas.paste(im.resize(size, Image.LANCZOS), offset, im.resize(size, Image.LANCZOS))
            canvas.save(os.path.join(OUT, f"{out_id}_{STATES[s]}.png"), optimize=True)
        print(f"{out_id}: ölçek {scale:.3f}, merkez ({cx:.0f}, {cy:.0f})")


def smooth_noise(rng, shape, cell):
    small = rng.random((shape[0] // cell + 2, shape[1] // cell + 2)).astype(np.float32)
    im = Image.fromarray((small * 255).astype(np.uint8)).resize((shape[1], shape[0]), Image.BICUBIC)
    return np.asarray(im, dtype=np.float32) / 255.0


def make_medallion():
    n = MEDALLION
    rng = np.random.default_rng(SEED)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    c = (n - 1) * 0.5
    dx, dy = xx - c, yy - c
    d = np.sqrt(dx * dx + dy * dy)
    R = n * 0.5 - 1.0
    u = d / R                                                   # 0 merkez, 1 kenar
    ang = np.arctan2(dy, dx)
    lit = (-(dx + dy) / np.maximum(d, 1.0)) * 0.5 + 0.5          # 1 = sol üst

    # Yüzey: aşınmış açık orta, kenara doğru koyu pas; pas lekeli, yüzey çukurlu.
    patches = 0.6 * smooth_noise(rng, (n, n), 36) + 0.4 * smooth_noise(rng, (n, n), 12)
    # Düz bir aşınma: orta parlak bir benek değil, diş sırasına kadar eşit.
    # Merkezde parlak bir benek, halka biçimli resimlerin (stres) içini
    # dolu bir daire gibi gösteriyordu (kullanıcı raporu 2026-10-22).
    wear = np.clip(1.0 - np.clip((u - 0.62) / 0.2, 0.0, 1.0) ** 1.5, 0.0, 1.0) * 0.62
    wear = np.clip(wear + 0.35 * (patches - 0.5) - 0.12 * (dy / R), 0.0, 1.0)
    face = TARNISH + (BRONZE - TARNISH) * np.clip(wear * 1.6, 0, 1)[..., None]
    face = face + (WORN - face) * np.clip(wear * 1.4 - 0.35, 0, 1)[..., None]
    pits = smooth_noise(rng, (n, n), 2)
    face *= (0.90 + 0.18 * pits)[..., None]
    rust = np.clip((smooth_noise(rng, (n, n), 9) - 0.55) * 2.5, 0, 0.6) * np.clip(u * 1.3 - 0.3, 0, 1)
    face = face * (1.0 - rust[..., None]) + TARNISH * rust[..., None]
    rgb = face

    # Kabartma diş sırası: her diş radyal bir kapsül, sol üstten ışık alıyor.
    step = 2.0 * np.pi / DENTICLE_COUNT
    a_local = (np.mod(ang + step * 0.5, step) - step * 0.5) * d / R      # dişe teğet uzaklık (yarıçap payı)
    r_local = u - DENTICLE_R
    tooth = (np.abs(r_local) < DENTICLE_LEN * 0.5) & (np.abs(a_local) < DENTICLE_W)
    soft = np.clip(1.0 - (np.abs(a_local) / DENTICLE_W) ** 2, 0, 1)
    tooth_col = TARNISH + (HIGHLIGHT - TARNISH) * (0.25 + 0.45 * lit * soft)[..., None]
    # dişler de aşınmış: pas lekesi onları da koyultur
    tooth_col = tooth_col * (1.0 - 0.6 * rust[..., None]) + TARNISH * (0.6 * rust[..., None])
    # dişin gölgesi (sağ alt yana düşüyor)
    shade = (np.abs(r_local) < DENTICLE_LEN * 0.55) & (np.abs(a_local - DENTICLE_W * 0.9) < DENTICLE_W * 0.7) & ~tooth
    rgb = np.where(shade[..., None], rgb * 0.55, rgb)
    rgb = np.where(tooth[..., None], tooth_col * (0.85 + 0.15 * pits)[..., None], rgb)
    # diş sırasının altındaki koyu oluk
    groove = np.exp(-((u - (DENTICLE_R - DENTICLE_LEN * 0.9)) / 0.012) ** 2) * 0.45
    rgb *= (1.0 - groove)[..., None]

    # Dış kenar: kalkık bant, iç kenarı gölgede, dış kenarı ışıkta.
    t = np.clip((u - RIM_IN) / (1.0 - RIM_IN), 0, 1)
    rim_light = np.where(t < 0.5, 1.0 - lit, lit)
    rim = BRONZE * 0.6 + TARNISH * 0.4 + (HIGHLIGHT - BRONZE) * (0.15 + 0.55 * rim_light * np.sin(t * np.pi))[..., None]
    rim *= (0.85 + 0.25 * smooth_noise(rng, (n, n), 4))[..., None]
    rgb = np.where((u >= RIM_IN)[..., None], rim, rgb)
    inner_edge = np.exp(-((u - RIM_IN) / 0.01) ** 2) * 0.8
    rgb = rgb * (1.0 - inner_edge[..., None]) + EDGE_DARK * inner_edge[..., None]
    outer_edge = np.clip(1.0 - (R - d) / 2.0, 0, 1)
    rgb = rgb * (1.0 - outer_edge[..., None] * 0.8) + EDGE_DARK * (outer_edge[..., None] * 0.8)

    alpha = np.clip(R + 0.5 - d, 0.0, 1.0)
    out = np.dstack([np.clip(rgb, 0, 1), alpha])
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "medallion.png"), optimize=True)
    print("medallion.png", n)


def main():
    os.makedirs(OUT, exist_ok=True)
    export_icons()
    make_medallion()
    stale = os.path.join(OUT, "card.png")
    if os.path.exists(stale):
        os.remove(stale)
    return 0


if __name__ == "__main__":
    sys.exit(main())
