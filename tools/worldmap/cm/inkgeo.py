"""Mürekkep coğrafyası (Orta Dünya haritasının dili).

Dağ: sivri, altı açık; gölge yamacı sırttan aşağı inen sık darbelerle neredeyse
dolu, ışıklı yamaçta yalnızca bir iki çizgi. Kuzeyde doruklar karlı: kar çizgisinin
üstü boş kâğıt kalır, kenarı tırtıklı bir çizgiyle biter.
Tepe: tek bir kavis ve altında birkaç gölge çizgisi.
Deniz: boyanmaz; kıyıyı izleyen çizgiler ve kısa dalga işaretleri.
"""
import math

import numpy as np

import build as B
from hand import INK, PAPER, ellipse_pts, path
from sketch import _fill, stroke

SNOW = PAPER          # kar renk değil: taramanın durduğu kâğıt


def peak(ctx, rng, x, by, W, H, snow=0.0):
    px = x + W * rng.uniform(-0.12, 0.12)
    top = np.array([px, by - H])
    left = [np.array([x - W / 2, by])]
    for t in (0.35, 0.68):
        q = left[0] + (top - left[0]) * t
        left.append(q + [rng.normal(0, W * 0.05), -abs(rng.normal(0, H * 0.07))])
    left.append(top)
    right = [top]
    end = np.array([x + W / 2, by])
    for t in (0.3, 0.65):
        q = top + (end - top) * t
        right.append(q + [rng.normal(0, W * 0.05), -abs(rng.normal(0, H * 0.06))])
    right.append(end)
    outline = np.array(left + right[1:])
    _fill(ctx, np.vstack([outline, [[x, by + 1]]]), None, 0)
    # sırt omurgası: tepeden ortaya doğru inen ayrım çizgisi
    spine_end = np.array([px + W * rng.uniform(0.02, 0.14), by])
    snow_y = by - H * (1 - snow) if snow > 0 else by - H - 1
    if snow > 0:
        # kar örtüsü: kar çizgisine kadar tüm üst kısım beyaz
        snow_poly = [p for p in outline if p[1] <= snow_y + 1]
        if len(snow_poly) >= 3:
            path(ctx, snow_poly, True)
            ctx.set_source_rgba(*SNOW, 1)
            ctx.fill()
    # gölge yamacı: omurgadan sağ yamaca, eğik ve sık darbeler
    n = int(H / 1.15)
    for i in range(1, n):
        t = i / n
        a = top + (spine_end - top) * t
        # sağ yamaçta aynı yükseklikteki nokta
        yy = a[1]
        rr = np.array(right)
        j = int(np.clip(np.searchsorted(rr[:, 1], yy), 1, len(rr) - 1))
        f = (yy - rr[j - 1, 1]) / max(rr[j, 1] - rr[j - 1, 1], 1e-6)
        b = rr[j - 1] + (rr[j] - rr[j - 1]) * np.clip(f, 0, 1)
        if yy < snow_y:
            continue
        L = b[0] - a[0]
        if L < 0.8:
            continue
        a2 = a + [0.2, 0]
        b2 = b + [-0.4, L * 0.35]
        stroke(ctx, [a2, (a2 + b2) / 2 + [0, 0.4], b2], rng, w=0.85, taper=(1.0, 0.85, 0.15), alpha=0.9, amp=0.12)
    # kar kenarı: tırtıklı çizgi ve gölge tarafta kısa koyu çentikler
    if snow > 0:
        xs = np.linspace(x - W * 0.42 * snow - W * 0.05, px + (end[0] - px) * snow * 0.9, 7)
        zz = [(xx, snow_y + rng.uniform(-1.5, 2.5)) for xx in xs]
        stroke(ctx, zz, rng, w=0.7, taper=(0.4, 0.9, 0.3), alpha=0.85, amp=0.2)
        for k in range(int(rng.integers(2, 4))):
            q = top + (spine_end - top) * rng.uniform(0.1, 0.9) * (1 - snow)
            stroke(ctx, [q, q + [W * 0.12, H * 0.1]], rng, w=0.5, taper=(0.8, 0.6, 0.1), alpha=0.6, amp=0.1)
    # ışıklı yamaçta bir iki kısa çizgi
    for _ in range(int(rng.integers(0, 3))):
        t = rng.uniform(0.35, 0.8)
        q = left[0] + (top - left[0]) * t + [W * 0.08, H * 0.04]
        if q[1] < snow_y:
            continue
        stroke(ctx, [q, q + [W * 0.06, H * 0.14]], rng, w=0.5, taper=(0.8, 0.6, 0.1), alpha=0.7, amp=0.1)
    stroke(ctx, left, rng, w=1.25, taper=(0.3, 1.0, 0.8), amp=0.25)
    stroke(ctx, right, rng, w=1.25, taper=(0.9, 1.0, 0.3), amp=0.25)


def hill(ctx, rng, x, by, W):
    H = W * rng.uniform(0.28, 0.42)
    pts = [(x - W / 2 + W * t, by - H * math.sin(math.pi * t) ** 0.9) for t in np.linspace(0, 1, 10)]
    _fill(ctx, pts + [(x, by + 1)], None, 0)
    stroke(ctx, pts, rng, w=1.0, taper=(0.2, 1.0, 0.25), amp=0.2)
    for k in range(int(rng.integers(3, 6))):
        t = 0.52 + 0.08 * k
        if t > 0.95:
            break
        q = (x - W / 2 + W * t, by - H * math.sin(math.pi * t) ** 0.9 + 0.6)
        stroke(ctx, [q, (q[0] - 0.8, q[1] + H * 0.55)], rng, w=0.55, taper=(0.9, 0.5, 0.05), alpha=0.75, amp=0.05)


def wave(ctx, rng, x, y, s=1.0):
    pts = [(x + i * 1.7 * s, y + 1.1 * s * math.sin(i * 1.25)) for i in range(7)]
    stroke(ctx, pts, rng, w=0.75 * s, taper=(0.2, 1.0, 0.2), alpha=0.75, amp=0.1)


# ------------------------------------------------------------------ yapılar

def caravanserai(ctx, rng, cx, cy, s=1.0):
    """Kervansaray: kare avlulu, kalın duvarlı, köşeleri kuleli, önünde yüksek
    taçkapı. Avluda kuyu, arka duvarın iç yüzünde kemer dizisi. Kubbe yok."""
    W, D, h = 44 * s, 30 * s, 8 * s
    stone = (0.86, 0.82, 0.72)
    x0, x1 = cx - W / 2, cx + W / 2
    yb, yf = cy - D * 0.45, cy + D * 0.45      # arka ve ön duvarın tabanı
    # avlu zemini
    path(ctx, [(x0, yb), (x1, yb), (x1, yf), (x0, yf)])
    ctx.set_source_rgb(*PAPER)
    ctx.fill()
    # arka duvar ve iç yüzündeki kemerler
    B.shape(ctx, [(x0, yb), (x1, yb), (x1, yb - h), (x0, yb - h)], stone, rng, hatch_angle=1.5, hatch_sp=2.0,
            hatch_alpha=0.3, w=0.9)
    for i in range(7):
        ax = x0 + W * (i + 0.5) / 7
        B.door(ctx, ax, yb, h * 0.7, W / 7 * 0.6)
    # yan duvarlar (üstten görünen kalınlık)
    for xs in (x0, x1):
        B.shape(ctx, [(xs - 1.5, yb - h), (xs + 1.5, yb - h), (xs + 1.5, yf - h), (xs - 1.5, yf - h)], stone, rng, w=0.8)
    # avluda kuyu ve iki deve/katır
    B.shape(ctx, list(ellipse_pts(cx, cy, 3.2 * s, 1.4 * s, 0, 2 * math.pi, 12)), (0.70, 0.70, 0.66), rng, w=0.7)
    for (dx, dy) in ((-12, -2), (10, 1)):
        _beast(ctx, rng, cx + dx * s, cy + dy * s, s)
    # köşe kuleleri ve ön duvar
    for (xx, yy) in ((x0, yb), (x1, yb)):
        B.square_tower(ctx, rng, xx, yy, 7 * s, h * 1.5, stone)
    B.shape(ctx, [(x0, yf), (x1, yf), (x1, yf - h), (x0, yf - h)], stone, rng, w=1.0)
    for i in range(1, int(W / 3.2)):
        xx = x0 + i * 3.2
        B.shape(ctx, [(xx - 0.8, yf - h), (xx + 0.8, yf - h), (xx + 0.8, yf - h - 1.8), (xx - 0.8, yf - h - 1.8)],
                stone, rng, w=0.5)
    for (xx, yy) in ((x0, yf), (x1, yf)):
        B.square_tower(ctx, rng, xx, yy, 7 * s, h * 1.5, stone)
    # taçkapı: duvardan yüksek dikdörtgen çerçeve, içinde sivri kemer
    pw, ph = 13 * s, h * 2.3
    B.shape(ctx, [(cx - pw / 2, yf), (cx + pw / 2, yf), (cx + pw / 2, yf - ph), (cx - pw / 2, yf - ph)], stone, rng,
            w=1.1)
    B.shape(ctx, [(cx - pw / 2 + 1.2, yf - ph + 1.2), (cx + pw / 2 - 1.2, yf - ph + 1.2),
                  (cx + pw / 2 - 1.2, yf - ph + 3), (cx - pw / 2 + 1.2, yf - ph + 3)], (0.70, 0.66, 0.58), rng, w=0.5)
    B.door(ctx, cx, yf, ph * 0.72, pw * 0.5)
    # kapı önünde bekleyen küçük kervan
    for k in range(3):
        _beast(ctx, rng, cx + pw * 0.6 + k * 7 * s, yf + 6 * s + k * 1.5, s * 0.9)


def _beast(ctx, rng, x, y, s):
    """Yük hayvanı: gövde, boyun, iki heybe, dört ince bacak."""
    body = list(ellipse_pts(x, y - 4 * s, 3.4 * s, 1.8 * s, 0, 2 * math.pi, 12))
    for k in (-2.2, -0.8, 0.9, 2.3):
        stroke(ctx, [(x + k * s, y - 3 * s), (x + k * s, y)], rng, w=0.6, taper=(1, 0.8, 0.5), amp=0.05)
    B.shape(ctx, body, (0.60, 0.50, 0.40), rng, w=0.6)
    stroke(ctx, [(x + 3 * s, y - 5 * s), (x + 4.5 * s, y - 7.5 * s)], rng, w=1.1 * s, taper=(1, 0.9, 0.7), amp=0.05)
    B.shape(ctx, [(x - 1.5 * s, y - 6 * s), (x + 1.2 * s, y - 6 * s), (x + 1.2 * s, y - 3.4 * s), (x - 1.5 * s, y - 3.4 * s)],
            (0.82, 0.74, 0.58), rng, w=0.5)


def ruins(ctx, rng, cx, cy):
    """Yıkıntı: kırık duvar parçaları, devrik sütun, taş yığını."""
    for i in range(4):
        x = cx - 15 + i * 9 + rng.normal(0, 1.5)
        hh = rng.uniform(4, 13)
        top = [(x - 3, cy - hh), (x - 1, cy - hh - 2.5), (x + 0.5, cy - hh + 0.5), (x + 3, cy - hh * 0.6)]
        B.shape(ctx, [(x - 3, cy), (x + 3, cy)] + top[::-1], (0.80, 0.77, 0.70), rng, hatch_angle=1.5, hatch_sp=1.6,
                hatch_alpha=0.4, w=0.8)
    B.shape(ctx, [(cx - 6, cy + 5), (cx + 9, cy + 3), (cx + 9.5, cy + 5.5), (cx - 5.5, cy + 7.5)], (0.80, 0.77, 0.70),
            rng, w=0.6)
    for k in range(6):
        x, y = cx + rng.uniform(-18, 18), cy + rng.uniform(2, 8)
        B.shape(ctx, list(ellipse_pts(x, y, 1.6, 1.0, 0, 2 * math.pi, 8)), (0.78, 0.76, 0.72), rng, w=0.4)


def graveyard(ctx, rng, cx, cy):
    """Mezarlık: alçak taş duvar içinde dikili mezar taşları (dinî simge yok)."""
    B.shape(ctx, [(cx - 18, cy - 7), (cx + 18, cy - 7), (cx + 18, cy - 9), (cx - 18, cy - 9)], (0.80, 0.77, 0.70), rng,
            w=0.6)
    for r in range(3):
        for i in range(5):
            x = cx - 13 + i * 6.5 + (r % 2) * 2
            y = cy - 3 + r * 5
            B.shape(ctx, [(x - 1.4, y), (x + 1.4, y), (x + 1.4, y - 3.2), (x, y - 4.2), (x - 1.4, y - 3.2)],
                    (0.85, 0.83, 0.78), rng, w=0.5)
    B.tree(ctx, rng, cx + 20, cy + 4, 0.7, "conifer")


def wreck(ctx, rng, cx, cy):
    """Batık: sudan çıkan kırık direk ve gövde kaburgaları."""
    for i in range(5):
        x = cx - 8 + i * 4
        stroke(ctx, [(x, cy), (x - 1.2, cy - 5 - (2 - abs(i - 2)) * 1.5)], rng, w=0.9, taper=(1, 0.8, 0.3), amp=0.1)
    stroke(ctx, [(cx + 2, cy), (cx + 6, cy - 18)], rng, w=1.2, taper=(1, 0.9, 0.4), amp=0.15)
    stroke(ctx, [(cx + 2, cy - 12), (cx + 10, cy - 13)], rng, w=0.7, taper=(1, 0.8, 0.4), amp=0.1)
    for k in range(3):
        stroke(ctx, [(cx - 14 + k * 9 + i * 1.6, cy + 2 + 0.8 * math.sin(i)) for i in range(5)], rng, w=0.5,
               taper=(0.3, 1, 0.3), alpha=0.7, amp=0.1)
