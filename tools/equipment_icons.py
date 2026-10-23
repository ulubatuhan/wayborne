#!/usr/bin/env python3
"""Görev Y-C06'nın 24 yeni ekipmanının ikonları, mevcut boyalı aileden türetilmiş.

İlk teslimatın 12 ekipman ikonu (`eq_*.png`) boyanmış; yeni parçalar için yeni bir
boyama turu yerine aynı resimlerden türetiliyor ki aile tek el gibi dursun:

- metal ve taş yeniden renkleniyor (ışık ve doku korunur, yalnız ton değişir:
  parlaklık × hedef renk);
- yüzüğün boncuğu konumundan bulunup başka bir taşa çevriliyor (icon_discs.blue_bead
  ile aynı yol: bakır tel boncukla aynı renk açısında, ayıran yeri);
- lanetli parçaya mürekkep bir çatlak ve hafif bir kararma (lanet görünür olsun);
- mızrak ve balta oyunun kendi render edilmiş silah eşyasından (data/assets/props),
  çapraz çevrilip mürekkep konturla.

Bu bir yer tutucu değil ama boyanmış değil: AI beyanı gerektirmeyen elle çizim hedefi
(docs/design_notes/ai_referansli_sprite.md) bunları da kapsar.

Çıktı PNG'leri elle düzeltilmez: bu aracı değiştirip yeniden koş.
    python3 -I tools/equipment_icons.py
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WAYBOOK = os.path.join(ROOT, "data", "assets", "ui", "waybook")
PROPS = os.path.join(ROOT, "data", "assets", "props")
SIZE = 96
INK = (24, 19, 13)

# metal tonları (parlaklık 0.5'teki renk)
IRON = (0.46, 0.46, 0.48)
SILVER = (0.70, 0.70, 0.72)
BLACK = (0.20, 0.19, 0.20)
GOLD = (0.74, 0.58, 0.30)
ROSE = (0.72, 0.48, 0.40)
COPPER = (0.70, 0.40, 0.22)
VERDIGRIS = (0.36, 0.52, 0.46)
BRONZE = (0.58, 0.44, 0.26)
LINEN = (0.74, 0.66, 0.50)
DARK_STEEL = (0.36, 0.38, 0.42)
BONE = (0.86, 0.82, 0.70)
STONE = (0.56, 0.55, 0.52)
LEATHER = (0.48, 0.30, 0.16)
RED = (0.66, 0.12, 0.10)
WHITE = (0.88, 0.86, 0.80)
TEAL = (0.18, 0.46, 0.46)
SOOT = (0.16, 0.14, 0.14)


def load(name):
    return np.asarray(Image.open(os.path.join(WAYBOOK, "eq_%s.png" % name)).convert("RGBA")).astype(np.float32) / 255.0


def luma(im):
    return im[..., :3] @ np.array([0.299, 0.587, 0.114], dtype=np.float32)


def sat(im):
    mx, mn = im[..., :3].max(-1), im[..., :3].min(-1)
    return np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)


def tint(im, color, mask=None, gain=1.0):
    """Maskedeki pikselleri parlaklık × renk yapar (mürekkep koyu kalır)."""
    out = im.copy()
    l = luma(im)[..., None]
    col = np.clip(np.array(color, dtype=np.float32) * (l / 0.5) * gain, 0, 1)
    m = np.ones(l.shape[:2], bool) if mask is None else mask
    out[..., :3] = np.where(m[..., None], col, im[..., :3])
    return out


def region(im, cx, cy, r):
    h, w = im.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    return np.hypot((xx - w * cx) / w, (yy - h * cy) / h) < r


def bead(im, color):
    """ring_charmed'in boncuğu (tepede, renkli) başka bir taşa."""
    m = region(im, 0.5, 0.125, 0.12) & (sat(im) > 0.3) & (im[..., 3] > 0.2)
    return tint(im, color, m, 1.1)


def curse(im, seed):
    """Mürekkep bir çatlak ve hafif kararma: lanetli parça."""
    out = im.copy()
    out[..., :3] *= 0.82
    h, w = im.shape[:2]
    rng = np.random.default_rng(seed)
    pil = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")
    layer = Image.new("RGBA", pil.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    alpha = im[..., 3] > 0.5
    ys, xs = np.nonzero(alpha)
    # Koyu metalde mürekkep çatlak görünmüyor: orada kül rengi bir yarık.
    line = INK if float(luma(im)[alpha].mean()) > 0.33 else (206, 196, 176)
    if len(xs):
        x, y = float(xs.mean()), float(ys.min() + (ys.max() - ys.min()) * 0.25)
        pts = [(x, y)]
        for _ in range(6):
            x += rng.uniform(-6, 6)
            y += rng.uniform(4, 9)
            pts.append((x, y))
        d.line(pts, fill=line + (235,), width=2)
        mid = pts[3]
        d.line([mid, (mid[0] + rng.uniform(5, 9), mid[1] + rng.uniform(2, 6))], fill=line + (220,), width=1)
    pil.alpha_composite(layer)
    res = np.asarray(pil).astype(np.float32) / 255.0
    res[..., 3] = im[..., 3]  # çatlak yalnız parçanın üstünde
    return res


def mark_eye(im):
    """Kadim göz: diskin ortasına mürekkeple bir göz (tapınak duvarındaki gibi)."""
    pil = Image.fromarray((np.clip(im, 0, 1) * 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(pil)
    a = im[..., 3] > 0.5
    ys, xs = np.nonzero(a)
    cx, cy = (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2 + 4
    rw, rh = (xs.max() - xs.min()) * 0.26, (ys.max() - ys.min()) * 0.12
    d.chord([cx - rw, cy - rh * 1.8, cx + rw, cy + rh * 1.8], 200, 340, outline=INK, width=2)
    d.chord([cx - rw, cy - rh * 1.8, cx + rw, cy + rh * 1.8], 20, 160, outline=INK, width=2)
    d.ellipse([cx - rh * 0.7, cy - rh * 0.7, cx + rh * 0.7, cy + rh * 0.7], fill=INK)
    return np.asarray(pil).astype(np.float32) / 255.0


def hole(im, frac=0.13):
    """Diskin ortasına bir delik (delik para, yolcu taşı)."""
    a = im[..., 3] > 0.5
    ys, xs = np.nonzero(a)
    cx, cy = (xs.min() + xs.max()) / 2, ys.min() + (ys.max() - ys.min()) * 0.56
    r = (xs.max() - xs.min()) * frac
    h, w = im.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    dist = np.hypot(xx - cx, yy - cy)
    out = im.copy()
    out[..., 3] = np.where(dist < r, 0.0, out[..., 3])
    rim = (dist >= r) & (dist < r + 1.6)
    out[..., :3] = np.where(rim[..., None], np.array(INK) / 255.0, out[..., :3])
    return out


def shrink(im, scale):
    pil = Image.fromarray((np.clip(im, 0, 1) * 255).astype(np.uint8), "RGBA")
    w, h = pil.size
    small = pil.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.LANCZOS)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.alpha_composite(small, ((w - small.width) // 2, (h - small.height) // 2))
    return np.asarray(canvas).astype(np.float32) / 255.0


def prop_icon(prop, angle, color=None):
    """Oyunun render edilmiş silahı: çapraz, ikon kutusuna, mürekkep konturla."""
    im = Image.open(os.path.join(PROPS, prop, "body.png")).convert("RGBA")
    im = im.rotate(angle, expand=True, resample=Image.BICUBIC)
    im = im.crop(im.getbbox())
    im.thumbnail((SIZE - 8, SIZE - 8), Image.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    a = im.getchannel("A")
    ink = Image.new("RGBA", im.size, INK + (255,))
    ink.putalpha(a.filter(ImageFilter.MaxFilter(3)))
    off = ((SIZE - im.width) // 2, (SIZE - im.height) // 2)
    canvas.alpha_composite(ink, off)
    canvas.alpha_composite(im, off)
    arr = np.asarray(canvas).astype(np.float32) / 255.0
    return tint(arr, color, (arr[..., 3] > 0) & (luma(arr) > 0.12)) if color else arr


def recipes():
    m, c = load("ring_marksman"), load("ring_charmed")
    fang, disc, ward = load("amulet_wolf_fang"), load("amulet_courage"), load("amulet_ward")
    a1, a3, w3 = load("armor_tier_1"), load("armor_tier_3"), load("weapon_tier_3")
    metal_c = (sat(c) < 0.45) | ~region(c, 0.5, 0.125, 0.12)
    return {
        "weapon_spear": prop_icon("weapon_spear", -45),
        "weapon_axe": prop_icon("weapon_axe_small", -30),
        "weapon_old_blade": curse(tint(w3, DARK_STEEL), 3),
        "armor_gambeson": tint(a1, LINEN),
        "armor_scale": tint(a3, DARK_STEEL),
        "armor_lamellar": tint(a3, BRONZE),
        "ring_iron_band": tint(m, IRON),
        "ring_hawk": tint(m, GOLD),
        "ring_steady_hand": tint(m, SILVER),
        "ring_bloodstone": bead(c, RED),
        "ring_debtor": curse(tint(m, BLACK, gain=1.4), 5),
        "ring_silent": tint(m, BLACK, gain=1.2),
        "ring_salt_seal": bead(tint(c, SILVER, metal_c), WHITE),
        "ring_widow": tint(m, ROSE),
        "ring_drowned": curse(bead(tint(c, VERDIGRIS, metal_c), TEAL), 7),
        "amulet_bear_claw": tint(fang, LEATHER, (luma(fang) > 0.35) & (fang[..., 3] > 0.3)),
        "amulet_wayfarer_stone": hole(tint(disc, STONE), 0.16),
        "amulet_raven_feather": tint(fang, SOOT, (luma(fang) > 0.35) & (fang[..., 3] > 0.3), 1.6),
        "amulet_ash_locket": tint(shrink(disc, 0.8), IRON),
        "amulet_ancient_eye": curse(mark_eye(tint(disc, BRONZE)), 11),
        "amulet_salt_charm": tint(ward, WHITE, (ward[..., 3] > 0.3) & (sat(ward) > 0.25)),
        "amulet_horse_hair": tint(ward, LEATHER, (ward[..., 3] > 0.3) & (sat(ward) > 0.25)),
        "amulet_wolf_skull": curse(tint(fang, BONE, (luma(fang) > 0.35) & (fang[..., 3] > 0.3)), 13),
        "amulet_copper_coin": hole(tint(shrink(disc, 0.72), COPPER), 0.14),
    }


def main() -> int:
    for name, arr in recipes().items():
        Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(
            os.path.join(WAYBOOK, "eq_%s.png" % name), optimize=True)
        print("eq_%s.png" % name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
