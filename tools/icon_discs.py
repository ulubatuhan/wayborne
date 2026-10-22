#!/usr/bin/env python3
"""Stat ve görev ikonlarını tek aileye toplar: ikinci teslimatın parşömen diski.

İkinci teslimat (Faz 22) stat ve görev ikonlarının çoğunu parşömen yüzlü, ince altın
çizgili, koyu demir halkalı bir diske koydu; bir kısmı gelmedi ya da bozuk geldi ve
aile karıştı: çevikliğin tavşanı, zekânın terazisi ve tellalın çanı diskin dışında
kaldı, dayanıklılık işlenmemiş gri bir kare, sezgi kare bir karo (görsel denetim
C-01..C-05, 2026-10-22). Bu araç aynı diski üretir ve o ikonları en temiz kaynağından (ilk teslimatın
`P3*` jpg'leri ya da ikinci teslimatın çıplak ikonları, `*_src.png`) diskin içine oturtur. Disk
boyanmıyor, ölçülen tonlardan üretiliyor (p3_charisma: yüz 0.73, altın çizgi, halka
0.28), dolayısıyla diğer disklerle yan yana aynı nesne gibi durur.

Ayrıca: `eq_ring_charmed` istem "mavi boncuklu bakır tel yüzük" diyordu, boncuk kehribar
geldi. Kaynağı `art_source/waybook/eq_ring_charmed_src.png`; boncuk renk tonuyla bulunup
maviye çevrilir (yalnızca o bölge, parlaklık ve mürekkep korunur).

Çıktı PNG'leri elle düzeltilmez: bu aracı değiştirip yeniden koş.
    python3 -I tools/icon_discs.py
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import waybook_assets as wa  # noqa: E402

SRC = os.path.join(ROOT, "art_source", "waybook")
OUT = os.path.join(ROOT, "data", "assets", "ui", "waybook")

# Diske oturtulan ikonlar: kaynak -> çıktı.
# Saydam bir `_src.png` varsa (zaten anahtarlanmış, ikinci teslimatın temiz çıplak
# ikonu) o kullanılır; yoksa ilk teslimatın gri zeminli jpg'si anahtarlanır.
DISCED = {
    "p3_agility_src.png": "p3_agility.png",
    "P3c_stat_endurance.jpg": "p3_endurance.png",
    "p3_intellect_src.png": "p3_intellect.png",
    "P3e_stat_perception.jpg": "p3_perception.png",
    "p5_crier_src.png": "p5_crier.png",
}
OUT_SIZE = 96          # ailenin geri kalanı 96 px
WORK = 384             # disk bu boyda çizilip küçültülür
FACE_R = 0.80          # parşömen yüzün yarıçap payı
GOLD_R = 0.815         # ince altın çizgi
RING_IN = 0.84         # demir halka buradan başlar
ICON_FILL = 0.97       # ikonun en uzak opak pikseli yüzün bu payında

FACE_CENTRE = np.array([0.88, 0.85, 0.78])
FACE_EDGE = np.array([0.66, 0.62, 0.53])
GOLD = np.array([0.66, 0.55, 0.30])
IRON = np.array([0.22, 0.21, 0.18])
IRON_LIGHT = np.array([0.34, 0.32, 0.27])
IRON_DARK = np.array([0.12, 0.11, 0.09])
SEED = 11

# Boncuk: kehribar tonlar (renk açısı 15-55°, doygun) maviye döner.
BEAD_HUE = (15.0, 55.0)
BEAD_MIN_SAT = 0.45
BEAD_CENTRE = (0.5, 0.125)
BEAD_RADIUS = 0.12
BEAD_BLUE = np.array([0.26, 0.42, 0.62])


def noise(rng, n, cell):
    small = rng.random((n // cell + 2, n // cell + 2)).astype(np.float32)
    im = Image.fromarray((small * 255).astype(np.uint8)).resize((n, n), Image.BICUBIC)
    return np.asarray(im, dtype=np.float32) / 255.0


def make_disc() -> np.ndarray:
    n = WORK
    rng = np.random.default_rng(SEED)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    c = (n - 1) * 0.5
    dx, dy = xx - c, yy - c
    d = np.sqrt(dx * dx + dy * dy)
    R = n * 0.5 - 1.0
    u = d / R
    lit = (-(dx + dy) / np.maximum(d, 1.0)) * 0.5 + 0.5

    t = np.clip(u / FACE_R, 0, 1) ** 2
    face = FACE_CENTRE + (FACE_EDGE - FACE_CENTRE) * t[..., None]
    face *= (1.0 + 0.10 * (0.6 * noise(rng, n, 40) + 0.4 * noise(rng, n, 10) - 0.5))[..., None]
    rgb = face

    ring_t = np.clip((u - RING_IN) / (1.0 - RING_IN), 0, 1)
    bevel = np.where(ring_t < 0.5, 1.0 - lit, lit) * np.sin(ring_t * np.pi)
    iron = IRON + (IRON_LIGHT - IRON) * bevel[..., None]
    iron *= (0.9 + 0.2 * noise(rng, n, 5))[..., None]
    rgb = np.where((u >= RING_IN)[..., None], iron, rgb)
    gold = np.exp(-((u - GOLD_R) / 0.008) ** 2)
    rgb = rgb * (1 - gold[..., None]) + GOLD * gold[..., None]
    for edge, width in [(RING_IN, 0.006), (FACE_R, 0.006), (1.0 - 0.006, 0.006)]:
        line = np.exp(-((u - edge) / width) ** 2) * 0.85
        rgb = rgb * (1 - line[..., None]) + IRON_DARK * line[..., None]
    alpha = np.clip(R + 0.5 - d, 0, 1)
    return np.dstack([np.clip(rgb, 0, 1), alpha])


def keyed(src: str) -> np.ndarray:
    path = os.path.join(SRC, src)
    if src.endswith(".png"):
        return wa.crop_to_alpha(np.asarray(Image.open(path).convert("RGBA")))
    rgb = np.asarray(Image.open(path).convert("RGB"))
    return wa.crop_to_alpha(wa.key(rgb))


def place(disc: np.ndarray, icon_rgba: np.ndarray) -> Image.Image:
    n = disc.shape[0]
    a = icon_rgba[..., 3] > 24
    ys, xs = np.nonzero(a)
    cx, cy = (xs.min() + xs.max()) * 0.5, (ys.min() + ys.max()) * 0.5
    reach = float(np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2).max())
    scale = ICON_FILL * FACE_R * (n * 0.5 - 1.0) / reach
    icon = Image.fromarray(icon_rgba.astype(np.uint8), "RGBA")
    size = (max(1, round(icon.width * scale)), max(1, round(icon.height * scale)))
    icon = icon.resize(size, Image.LANCZOS)
    base = Image.fromarray((disc * 255).astype(np.uint8), "RGBA")
    base.alpha_composite(icon, (round(n * 0.5 - cx * scale), round(n * 0.5 - cy * scale)))
    return base.resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS)


def blue_bead() -> None:
    src = os.path.join(SRC, "eq_ring_charmed_src.png")
    im = np.asarray(Image.open(src).convert("RGBA")).astype(np.float32) / 255.0
    rgb = im[..., :3]
    mx, mn = rgb.max(-1), rgb.min(-1)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    hue = np.degrees(np.arctan2(np.sqrt(3) * (g - b), 2 * r - g - b)) % 360
    # Tel de bakır, aynı renk açısında; boncuğu yeri ayırıyor: halkanın tepesinde.
    # Ölçüldü (96 px kaynak): boncuk y 2-22, x 0.42-0.58 genişlik, merkez (0.5, 0.125).
    h, w = im.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    near = np.hypot((xx - w * BEAD_CENTRE[0]) / w, (yy - h * BEAD_CENTRE[1]) / h) < BEAD_RADIUS
    bead = (hue >= BEAD_HUE[0]) & (hue <= BEAD_HUE[1]) & (sat >= BEAD_MIN_SAT) & (im[..., 3] > 0.2) & near
    if not bead.any():
        raise SystemExit("eq_ring_charmed: boncuk bulunamadı")
    luma = (rgb @ np.array([0.299, 0.587, 0.114]))[..., None]
    blue = np.clip(BEAD_BLUE * (luma / 0.5), 0, 1)
    rgb = np.where(bead[..., None], blue, rgb)
    out = np.dstack([rgb, im[..., 3]])
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "eq_ring_charmed.png"), optimize=True)
    print("eq_ring_charmed: boncuk", int(bead.sum()), "px maviye")


def main() -> int:
    disc = make_disc()
    for src, out in DISCED.items():
        place(disc, keyed(src)).save(os.path.join(OUT, out), optimize=True)
        print(out)
    blue_bead()
    return 0


if __name__ == "__main__":
    sys.exit(main())
