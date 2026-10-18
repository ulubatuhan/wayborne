#!/usr/bin/env python3
"""Karanlık arayüz taslağının dokuları ve ses imleri - tamamen özgün, koddan.

Referans görüntüler (Frostpunk, This War of Mine, Banner
Saga, KCD, Wartales) yalnızca palet ve yerleşim için okundu; hiçbir pikseli
kesilip buraya taşınmadı. Her şey tohumlu gürültüden üretiliyor, yani aynı
komut her seferinde bayt bayt aynı dosyaları yazar.

    python3 -I tools/grim_ui_assets.py

Çıktı: data/assets/ui/grim/*.png, data/assets/audio/ui_*.wav
"""
import math
import os
import struct
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_TEX = os.path.join(ROOT, "data", "assets", "ui", "grim")
OUT_SND = os.path.join(ROOT, "data", "assets", "audio")
SEED = 1729

# ArtPalette.GRIM_* ile aynı sayılar (renk otoritesi orada; burada yalnızca
# dokunun kendi tonu için).
PARCHMENT = (196, 176, 142)
PARCHMENT_DARK = (120, 98, 70)
INK = (14, 12, 14)
FROST = (205, 225, 238)


def rng(salt):
    return np.random.default_rng(SEED + salt)


def value_noise(w, h, cell, salt, tile=True):
    """Yumuşak değer gürültüsü 0..1; `tile` ise kenarlar birbirine bağlanır."""
    r = rng(salt)
    gw, gh = max(1, w // cell), max(1, h // cell)
    grid = r.random((gh + 1, gw + 1))
    if tile:
        grid[-1, :] = grid[0, :]
        grid[:, -1] = grid[:, 0]
    ys = np.linspace(0, gh, h, endpoint=False)
    xs = np.linspace(0, gw, w, endpoint=False)
    y0 = np.floor(ys).astype(int)
    x0 = np.floor(xs).astype(int)
    fy = (ys - y0)[:, None]
    fx = (xs - x0)[None, :]
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a = grid[y0][:, x0]
    b = grid[y0][:, x0 + 1]
    c = grid[y0 + 1][:, x0]
    d = grid[y0 + 1][:, x0 + 1]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(w, h, cell, salt, octaves=4, tile=True):
    out = np.zeros((h, w))
    amp, total = 1.0, 0.0
    for o in range(octaves):
        c = max(2, cell >> o)
        out += value_noise(w, h, c, salt + o * 31, tile) * amp
        total += amp
        amp *= 0.5
    return out / total


def save_rgba(name, rgb, alpha):
    rgb = np.clip(rgb, 0, 255).astype(np.uint8)
    a = np.clip(alpha * 255.0, 0, 255).astype(np.uint8)
    img = np.dstack([rgb, a]) if rgb.ndim == 3 else np.dstack([rgb, rgb, rgb, a])
    Image.fromarray(img, "RGBA").save(os.path.join(OUT_TEX, name), optimize=True)
    print("doku:", name, img.shape[1], "x", img.shape[0])


def solid(h, w, colour):
    return np.ones((h, w, 3)) * np.array(colour, dtype=float)


# ---------------------------------------------------------------- dokular

def ash_flake():
    """Düşen kül: düzensiz, yumuşak kenarlı gri bir pul."""
    s = 32
    yy, xx = np.mgrid[0:s, 0:s] / (s - 1) * 2 - 1
    ang = np.arctan2(yy, xx)
    radius = 0.62 + 0.22 * np.sin(ang * 3 + 0.7) + 0.10 * np.sin(ang * 7)
    d = np.sqrt(xx * xx + yy * yy) / radius
    a = np.clip(1.0 - d, 0, 1) ** 0.8
    a *= 0.55 + 0.45 * fbm(s, s, 8, 3, 2, False)
    save_rgba("ash_flake.png", solid(s, s, (170, 166, 160)), a)


def vignette():
    """Kenardan içeri yanmış, lekeli karanlık; ekranın tamamına gerilir."""
    s = 512
    yy, xx = np.mgrid[0:s, 0:s] / (s - 1) * 2 - 1
    d = np.sqrt((xx * 0.92) ** 2 + (yy * 1.05) ** 2)
    n = fbm(s, s, 64, 11, 5, False)
    a = np.clip((d - 0.55 + (n - 0.5) * 0.35) / 0.65, 0, 1) ** 1.6
    save_rgba("vignette.png", solid(s, s, INK), a * 0.92)


def grime_overlay():
    """Kir ve is: döşenebilir, kahverengi-siyah benekler."""
    s = 256
    n = fbm(s, s, 32, 21, 5)
    speck = rng(22).random((s, s))
    a = np.clip((n - 0.52) * 3.2, 0, 1) * 0.55 + (speck > 0.985) * 0.5
    rgb = solid(s, s, (42, 30, 20)) * (0.7 + 0.6 * n[..., None])
    save_rgba("grime_overlay.png", rgb, np.clip(a, 0, 0.85))


def frost_overlay():
    """Kenardan büyüyen kırağı: ortası boş, köşeleri kristal dolu."""
    s = 256
    img = Image.new("L", (s, s), 0)
    draw = ImageDraw.Draw(img)
    r = rng(31)
    for _ in range(140):
        side = r.integers(4)
        t = r.random() * s
        x, y = [(t, 0), (s - 1, t), (t, s - 1), (0, t)][side]
        ang = [math.pi / 2, math.pi, -math.pi / 2, 0][side] + (r.random() - 0.5) * 1.6
        length = 10 + r.random() * 46
        for depth in range(3):
            nx = x + math.cos(ang) * length
            ny = y + math.sin(ang) * length
            draw.line([(x, y), (nx, ny)], fill=int(150 + r.random() * 100), width=1)
            for side_ang in (-0.9, 0.9):
                bx = x + (nx - x) * 0.5
                by = y + (ny - y) * 0.5
                draw.line([(bx, by), (bx + math.cos(ang + side_ang) * length * 0.35,
                                       by + math.sin(ang + side_ang) * length * 0.35)],
                          fill=120, width=1)
            x, y, length = nx, ny, length * 0.55
            ang += (r.random() - 0.5) * 0.8
    lines = np.asarray(img.filter(ImageFilter.GaussianBlur(0.6)), dtype=float) / 255.0
    yy, xx = np.mgrid[0:s, 0:s] / (s - 1) * 2 - 1
    edge = np.clip((np.maximum(abs(xx), abs(yy)) - 0.45) / 0.55, 0, 1)
    haze = edge ** 2 * (0.25 + 0.4 * fbm(s, s, 32, 33, 4, False))
    save_rgba("frost_overlay.png", solid(s, s, FROST), np.clip(lines * 0.9 + haze, 0, 1))


def tatter_mask():
    """Yıpranma maskesi: beyaz = sağlam, siyah = yırtık. Gölgelendirici
    eşiği yıpranmaya göre kaydırır, yani tek doku her derecede işe yarar."""
    s = 256
    n = fbm(s, s, 48, 41, 5, False)
    yy, xx = np.mgrid[0:s, 0:s] / (s - 1) * 2 - 1
    edge = np.maximum(abs(xx), abs(yy))
    # Kenar önce yıpranır: kenara yakın piksel daha düşük değer alır.
    v = n * 0.65 + (1.0 - edge) * 0.55
    v = (v - v.min()) / (v.max() - v.min())
    save_rgba("tatter_mask.png", solid(s, s, (255, 255, 255)) * v[..., None], np.ones((s, s)))


def torn_edge_alpha(w, h, salt, depth):
    """Kenarları yırtık bir kâğıdın alfası."""
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    dist = np.minimum.reduce([xx, w - 1 - xx, yy, h - 1 - yy])
    n = fbm(w, h, 12, salt, 4, False)
    return np.clip((dist - depth * n) / 3.0, 0, 1)


def notice_card():
    """Haber kartı: yıpranmış parşömen, lekeler, yırtık kenar. Dokuz
    dilimle gerilir (kenar payı 28 px)."""
    w, h = 512, 320
    n = fbm(w, h, 64, 61, 5, False)
    stain = fbm(w, h, 128, 62, 3, False)
    base = np.array(PARCHMENT, dtype=float)
    dark = np.array(PARCHMENT_DARK, dtype=float)
    t = np.clip(n * 0.6 + (stain - 0.55) * 1.4, 0, 1)[..., None]
    rgb = base * (1 - t) + dark * t
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    dist = np.minimum.reduce([xx, w - 1 - xx, yy, h - 1 - yy])
    burn = np.clip(1 - dist / 30.0, 0, 1)[..., None] ** 1.5
    rgb = rgb * (1 - burn * 0.55)
    save_rgba("notice_card.png", rgb, torn_edge_alpha(w, h, 63, 16))


def ink_blot():
    """Menü fırça darbesi: soldan sağa incelen, saçaklı mürekkep."""
    w, h = 768, 192
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    u = xx / (w - 1)
    centre = h * 0.5 + (fbm(w, 1, 96, 71, 3, False)[0] - 0.5) * h * 0.25
    half = h * (0.40 - 0.18 * u[0]) * (0.85 + 0.3 * fbm(w, 1, 48, 72, 3, False)[0])
    d = np.abs(yy - centre[None, :]) / half[None, :]
    bristle = fbm(w, h, 6, 73, 2, False)
    a = np.clip((1.0 - d) * 3.0 - (bristle - 0.5) * 1.8, 0, 1)
    head = np.clip(u / 0.04, 0, 1)
    tail = np.clip((1.0 - u) / 0.22, 0, 1) ** 0.7
    a *= head * tail
    a *= 0.85 + 0.15 * fbm(w, h, 24, 74, 3, False)
    save_rgba("ink_blot.png", solid(h, w, INK), a)


def lantern_glow():
    """Fener ışığı: sıcak, merkezden düşen, hafif lekeli bir hale."""
    s = 256
    yy, xx = np.mgrid[0:s, 0:s] / (s - 1) * 2 - 1
    d = np.sqrt(xx * xx + yy * yy)
    a = np.clip(1 - d, 0, 1) ** 2.2 * (0.85 + 0.15 * fbm(s, s, 32, 81, 3, False))
    save_rgba("lantern_glow.png", solid(s, s, (255, 196, 120)), a)


# ---------------------------------------------------------------- sesler

RATE = 22050


def write_wav(name, samples):
    samples = np.clip(samples, -1, 1)
    data = (samples * 32000).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT_SND, name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data)
    print("ses:", name, "%.2f sn" % (len(samples) / RATE))


def env(n, attack, decay):
    t = np.arange(n) / RATE
    return np.minimum(t / max(attack, 1e-4), 1.0) * np.exp(-t / decay)


def noise(n, salt):
    return rng(salt).random(n) * 2 - 1


def lowpass(x, k):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def sounds():
    t = lambda sec: np.arange(int(RATE * sec)) / RATE
    # Üstüne gelme: kumaş fısıltısı, çok kısa.
    n = int(RATE * 0.09)
    write_wav("ui_hover.wav", lowpass(noise(n, 1), 0.18) * env(n, 0.01, 0.03) * 0.5)
    # Basma: demir mandal - kısa metal tık + gövdesiz çınlama.
    s = t(0.22)
    click = noise(len(s), 2) * env(len(s), 0.001, 0.008)
    ring = (np.sin(2 * math.pi * 1180 * s) + 0.5 * np.sin(2 * math.pi * 1730 * s)) * env(len(s), 0.001, 0.06)
    write_wav("ui_press.wav", (click * 0.7 + ring * 0.25))
    # Sayfa hışırtısı: süpürülen, bant geçirgen gürültü.
    n = int(RATE * 0.38)
    x = noise(n, 3)
    x = x - lowpass(x, 0.05)
    sweep = np.sin(np.linspace(0, math.pi, n)) ** 1.5
    write_wav("ui_page.wav", lowpass(x, 0.5) * sweep * 0.55)
    # Sikke: iki yakın kısmi ses, uzun kuyruk.
    s = t(0.6)
    coin = (np.sin(2 * math.pi * 2350 * s) + 0.7 * np.sin(2 * math.pi * 3120 * s + 1)) * env(len(s), 0.001, 0.16)
    write_wav("ui_coin.wav", (coin * 0.35 + noise(len(s), 4) * env(len(s), 0.001, 0.004) * 0.4))
    # Mühür: ağır, boğuk darbe.
    s = t(0.35)
    thump = np.sin(2 * math.pi * (70 + 60 * np.exp(-s * 30)) * s) * env(len(s), 0.002, 0.08)
    write_wav("ui_stamp.wav", thump * 0.9 + lowpass(noise(len(s), 5), 0.1) * env(len(s), 0.001, 0.03) * 0.5)
    # Uyarı: alçak, iki vuruşlu, kalp atışı gibi.
    s = t(0.9)
    beat = np.zeros(len(s))
    for start in (0.0, 0.28):
        k = s - start
        on = k >= 0
        beat[on] += np.sin(2 * math.pi * 55 * k[on]) * np.exp(-k[on] / 0.09)
    write_wav("ui_alert.wav", beat * 0.85)


def main():
    os.makedirs(OUT_TEX, exist_ok=True)
    os.makedirs(OUT_SND, exist_ok=True)
    for fn in (ash_flake, vignette, grime_overlay, frost_overlay, tatter_mask,
               notice_card, ink_blot, lantern_glow):
        fn()
    sounds()


if __name__ == "__main__":
    main()
