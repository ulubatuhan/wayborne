"""Ortak mürekkep geçişi (görev Y-G02): render sonrası tek geçiş.

    python -I tools/npr/ink_pass.py <girdi.png> <çıktı.png> [--strength 1.0]
    python -I tools/npr/ink_pass.py --compare <çıktı.jpg> <girdi1.png> [girdi2.png ...]

Karakter, hayvan, vagon, kasaba ve yol render'ları bugün ayrı ayrı mürekkepleniyor
(town_post.py, road_post.py, figür paketleyicileri); her hattın kendi eşiği var. Bu
geçiş hepsine aynı dili verir (STIL_REHBERI.md):

1. **Üç ton:** parlaklık gölge / orta / ışık diye üç kademeye yuvarlanır; renk
   (ton) korunur, yalnızca değer basamaklanır. Geçişler yumuşak kenarlı (keskin
   bant posterleşme gibi okunuyor).
2. **Tarama:** gölge kademesinde 45°, en koyu yerde 45° + 135° çapraz ince çizgi.
   Çizgi aralığı görüntü boyuna göre, ince resimde kaybolmasın diye en az 3 px.
3. **Kontur:** alfa kenarı (siluet) her zaman, iç kenar parlaklık Sobel'inden;
   siluet kalın, iç çizgi ince. Mürekkep rengi `INK` (#0E0D0F).
4. **Kâğıt:** ambientCG Paper005 dokusu çarpılır (yalnızca opak piksellerde,
   saydamlık korunur).

Saf numpy + Pillow; tohum yok (geçiş deterministik). Onaydan sonra hatların
post adımlarına bu modül bağlanır; o güne kadar oyun varlıklarına uygulanmaz.
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PAPER = os.path.join(ROOT, "art_source", "textures", "ambientcg", "Paper005", "Paper005_1K-JPG_Color.jpg")
INK = np.array([0x0E, 0x0D, 0x0F], np.float32) / 255.0
LUMA = np.array([0.299, 0.587, 0.114], np.float32)


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def sobel(a):
    p = np.pad(a, 1, mode="edge")
    gx = (p[:-2, 2:] + 2 * p[1:-1, 2:] + p[2:, 2:]) - (p[:-2, :-2] + 2 * p[1:-1, :-2] + p[2:, :-2])
    gy = (p[2:, :-2] + 2 * p[2:, 1:-1] + p[2:, 2:]) - (p[:-2, :-2] + 2 * p[:-2, 1:-1] + p[:-2, 2:])
    return np.hypot(gx, gy)


def three_tone(rgb):
    lum = (rgb * LUMA).sum(-1)
    # kademe hedefleri: gölge 0.22, orta 0.50, ışık 0.80; yumuşak eşikler
    lo = smoothstep(0.24, 0.32, lum)
    hi = smoothstep(0.58, 0.66, lum)
    target = 0.22 + lo * 0.28 + hi * 0.30
    scale = target / np.maximum(lum, 1e-3)
    out = np.clip(rgb * scale[..., None], 0.0, 1.0)
    # aşırı doygunluğu kır: ölçek büyüdüğünde ton griye çekilsin
    grey = (out * LUMA).sum(-1, keepdims=True)
    return out * 0.85 + grey * 0.15, lum


def hatch(lum, h, w):
    step = max(3, int(round(min(h, w) / 110)))
    yy, xx = np.mgrid[0:h, 0:w]
    d1 = ((xx + yy) % step) == 0
    d2 = ((xx - yy) % step) == 0
    shadow = smoothstep(0.30, 0.20, lum)
    deep = smoothstep(0.16, 0.08, lum)
    return np.clip(d1 * shadow * 0.55 + d2 * deep * 0.55, 0.0, 1.0)


def contour(lum, alpha):
    h, w = lum.shape
    width = max(1, int(round(min(h, w) / 260)))
    sil = sobel(alpha)
    inner = sobel(lum) * (alpha > 0.5)
    sil = np.clip(sil * 1.5, 0, 1)
    inner = smoothstep(0.35, 0.9, inner) * 0.7
    lines = np.maximum(sil, inner)
    if width > 1:
        # kalınlaştırma: komşu maksimumu
        p = np.pad(lines, width, mode="edge")
        acc = lines.copy()
        for dy in range(-width, width + 1):
            for dx in range(-width, width + 1):
                acc = np.maximum(acc, p[width + dy:width + dy + h, width + dx:width + dx + w])
        lines = acc
    return lines


def paper(h, w):
    if not os.path.exists(PAPER):
        return np.ones((h, w), np.float32)
    pa = np.asarray(Image.open(PAPER).convert("L").resize((w, h), Image.BICUBIC), np.float32) / 255.0
    return 0.88 + 0.12 * (pa / max(pa.mean(), 1e-3))


def ink_pass(img, strength=1.0):
    a = np.asarray(img.convert("RGBA"), np.float32) / 255.0
    rgb, alpha = a[..., :3], a[..., 3]
    h, w = alpha.shape
    toned, lum = three_tone(rgb)
    out = rgb * (1 - strength) + toned * strength
    hat = hatch(lum, h, w) * strength
    out = out * (1 - hat[..., None]) + INK * hat[..., None]
    lines = contour(lum, alpha) * strength
    out = out * (1 - lines[..., None] * 0.9) + INK * lines[..., None] * 0.9
    out = out * paper(h, w)[..., None]
    res = np.dstack([np.clip(out, 0, 1), alpha])
    return Image.fromarray((res * 255).astype(np.uint8), "RGBA")


def compare(out_path, inputs, cell=520):
    rows = []
    for p in inputs:
        src = Image.open(p).convert("RGBA")
        k = cell / max(src.size)
        src = src.resize((max(1, int(src.size[0] * k)), max(1, int(src.size[1] * k))), Image.LANCZOS)
        after = ink_pass(src)
        bg = (196, 186, 166, 255)
        pair = Image.new("RGBA", (cell * 2 + 30, src.size[1] + 20), bg)
        pair.alpha_composite(src, (10, 10))
        pair.alpha_composite(after, (cell + 20, 10))
        rows.append(pair)
    h = sum(r.size[1] for r in rows)
    sheet = Image.new("RGBA", (cell * 2 + 30, h), (196, 186, 166, 255))
    y = 0
    for r in rows:
        sheet.alpha_composite(r, (0, y))
        y += r.size[1]
    sheet.convert("RGB").save(out_path, quality=88)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "--compare":
        compare(args[1], args[2:])
    else:
        strength = float(args[args.index("--strength") + 1]) if "--strength" in args else 1.0
        ink_pass(Image.open(args[0]), strength).save(args[1])
    print("tamam")
