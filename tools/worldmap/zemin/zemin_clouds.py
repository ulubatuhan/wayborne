"""referans harita tarzı oyma bulutlar: kenar çerçevesi ve keşfedilmemiş bölge sisi.

referans haritanın harita bulutu: üst üste binen yuvarlak loblar, her lobun koyu mürekkep
konturu, sol üstten ışık (açık krem-gri), alt-sağda koyu gri gölge ve o gölgenin
içinde ince paralel tarama, lobun içinde bir kıvrım (spiral). Renkler kâğıdın
gri-zeytin tonunda, doygun değil.

İki çıktı:
  * clouds/cloud_XX.png - tek bulut kümeleri (şeffaf). Oyun bunları
    keşfedilmemiş hücrelerin üstüne kendisi yerleştirir (renderer'daki
    `fog` katmanı aynı hücre kuralıyla gösteriyor);
  * overlay_clouds_border.png - haritanın dört kenarına dizili çerçeve.

    python3 -I zemin_clouds.py <çıktı klasörü>
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

INK = (34, 31, 26, 255)
LIGHT = (176, 170, 150, 255)
MID = (118, 114, 102, 255)
SHADOW = (82, 79, 70, 255)
HATCH = (52, 49, 43, 255)
SS = 4


def lobe_fill(dr, cx, cy, r, rng, tone, s=SS):
    """referans harita lobu: ana daire + üst kenarında küçük fistolar (karnabahar), düz
    gri dolgu, birleşik siluetin mürekkep konturu, alt-solda kenarı içeriden
    izleyen sık oyma yayları, ara sıra eş merkezli kıvrım."""
    cx, cy, r = cx * s, cy * s, r * s
    parts = [(cx, cy, r)]
    for a in np.linspace(200, 340, int(rng.integers(3, 6))) + rng.normal(0, 8, 1):
        rr = r * (0.34 + 0.14 * rng.random())
        d = r - rr * 0.55
        parts.append((cx + np.cos(np.radians(a)) * d, cy + np.sin(np.radians(a)) * d, rr))
    w = max(2, int(2.0 * s))
    for x, y, q in parts:
        dr.ellipse([x - q - w, y - q - w, x + q + w, y + q + w], fill=INK)
    for x, y, q in parts:
        dr.ellipse([x - q, y - q, x + q, y + q], fill=tuple(int(v) for v in tone) + (255,))
    # fistoların iç hatları: her tümseğin alt yayı ince çizgi
    for x, y, q in parts[1:]:
        dr.arc([x - q, y - q, x + q, y + q], 40 + rng.random() * 20, 120 + rng.random() * 20,
               fill=HATCH, width=max(1, int(1.0 * s)))
    mid = 120 + rng.random() * 40
    k = max(6, min(int(r / (4.2 * s)), 13))
    for i in range(k):
        f = i / (k - 1)
        rr = r * (0.94 - 0.40 * f)
        half = 66 * (1 - 0.8 * f) + rng.random() * 6
        dr.arc([cx - rr, cy - rr, cx + rr, cy + rr], mid - half, mid + half, fill=HATCH,
               width=max(1, int((1.15 - 0.45 * f) * s)))
    if rng.random() < 0.3:
        sx, sy = cx + r * 0.12, cy - r * 0.08
        for i in range(5):
            rr = r * (0.36 - 0.06 * i)
            a0 = 190 + i * 30
            dr.arc([sx - rr, sy - rr, sx + rr, sy + rr], a0, a0 + 250 - i * 35, fill=HATCH,
                   width=max(1, int(1.4 * s)))


def cloud(size, rng):
    """Bir bulut yığını: alt sırada büyük loblar, üstte küçükleri; loblar
    yarı yarıya biner, üst sıra önce çizilir. Tuval payı geniş: kesilmez."""
    W, H = size, int(size * 0.8)
    im = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    rows = [(0.40, 0.12, 2), (0.56, 0.135, 3), (0.72, 0.145, 4)]
    for yf, rf, cnt in rows:
        r0 = W * rf
        xs = np.linspace(W * 0.5 - r0 * 0.66 * (cnt - 1), W * 0.5 + r0 * 0.66 * (cnt - 1), cnt)
        for x in xs:
            r = r0 * (0.85 + 0.3 * rng.random())
            y = H * yf + rng.normal(0, H * 0.025)
            g = 128 + rng.random() * 34 + (yf - 0.40) * 60
            lobe_fill(dr, x + rng.normal(0, r0 * 0.1), y, r, rng, (g, g - 2, g - 12))
    arr = np.asarray(im, np.float32)
    nz = np.asarray(Image.fromarray((rng.random((H // 3 + 1, W // 3 + 1)) * 255).astype(np.uint8))
                    .resize(im.size, Image.BICUBIC).filter(ImageFilter.GaussianBlur(3)), np.float32) / 255
    arr[..., :3] *= (0.95 + 0.10 * nz)[..., None]
    out = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    out = out.resize((W, H), Image.LANCZOS)
    return out.crop(out.getbbox())


def border(n, sprites, rng, band=220, protect=None):
    """Dört kenara dizili bulut çerçevesi; iç kenar düzensiz. `protect`
    (n×n bool, yerleşim ayak izi) üstüne düşen bulut dışarı itilir."""
    out = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    placed = []
    step = 150
    for side in range(4):
        for k in np.arange(-100, n + 100, step):
            depth = rng.random() * band * 0.55
            sp = sprites[int(rng.integers(len(sprites)))]
            sc = 0.75 + rng.random() * 0.6
            w, h = int(sp.width * sc), int(sp.height * sc)
            if side == 0:    # üst
                x, y = k - w / 2 + rng.normal(0, 30), depth - h * 0.55
            elif side == 1:  # alt
                x, y = k - w / 2 + rng.normal(0, 30), n - depth - h * 0.45
            elif side == 2:  # sol
                x, y = depth - w * 0.55, k - h / 2 + rng.normal(0, 30)
            else:            # sağ
                x, y = n - depth - w * 0.45, k - h / 2 + rng.normal(0, 30)
            if protect is not None:
                for _ in range(8):  # yerleşime değiyorsa kenara doğru it
                    x0, y0 = int(max(0, x)), int(max(0, y))
                    x1, y1 = int(min(n, x + w)), int(min(n, y + h))
                    if x1 <= x0 or y1 <= y0 or not protect[y0:y1, x0:x1].any():
                        break
                    dx, dy = {0: (0, -40), 1: (0, 40), 2: (-40, 0), 3: (40, 0)}[side]
                    x, y = x + dx, y + dy
            placed.append((y + h, int(x), int(y), sp.resize((w, h), Image.LANCZOS)))
    # köşeler dolu
    for cx, cy in ((0, 0), (n, 0), (0, n), (n, n)):
        sp = sprites[int(rng.integers(len(sprites)))]
        w, h = int(sp.width * 1.5), int(sp.height * 1.5)
        placed.append((cy + h, int(cx - w / 2), int(cy - h / 2), sp.resize((w, h), Image.LANCZOS)))
    for _, x, y, sp in sorted(placed, key=lambda p: p[0]):
        pad = 30
        a = Image.new("L", (sp.width + 2 * pad, sp.height + 2 * pad), 0)
        a.paste(sp.getchannel("A").point(lambda v: int(v * 0.45)), (pad, pad))
        sh = Image.new("RGBA", a.size, (20, 18, 14, 0))
        sh.putalpha(a.filter(ImageFilter.GaussianBlur(10)))
        paste(out, sh, x + 10 - pad, y + 14 - pad)
        paste(out, sp, x, y)
    return out


def paste(dst, src, x, y):
    l, t = max(0, -x), max(0, -y)
    r = min(src.width, dst.width - x)
    b = min(src.height, dst.height - y)
    if r <= l or b <= t:
        return
    dst.alpha_composite(src.crop((l, t, r, b)), (x + l, y + t))


def main():
    out = sys.argv[1]
    os.makedirs(os.path.join(out, "clouds"), exist_ok=True)
    rng = np.random.default_rng(7)
    sprites = []
    for i in range(10):
        c = cloud(int(380 + rng.random() * 220), rng)
        c.save(os.path.join(out, "clouds", "cloud_%02d.png" % i))
        sprites.append(c)
    fp = os.path.join(out, "layout.json.foot.npy")
    protect = None
    if os.path.exists(fp):  # yerleşimlerin çekirdeği (ayak izi, biraz daraltılmış)
        protect = np.unpackbits(np.load(fp))[:4096 * 4096].reshape(4096, 4096).astype(bool)
    border(4096, sprites, np.random.default_rng(11), protect=protect).save(
        os.path.join(out, "overlay_clouds_border.png"))
    print("YAZILDI", out)


if __name__ == "__main__":
    main()
