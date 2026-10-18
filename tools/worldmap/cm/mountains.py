"""Üç farklı dağ dili, aynı yükseklik verisinden.

cluster: Carta Marina'nın asıl dağları - yan yana yığılmış, kenarı kırık kaya
         kümeleri, gri-toprak tonu, gölgeli yüzü taramalı.
ridge:   gravür sırtları - gerçek doruklarda sivri tepeler, aralarını bağlayan
         sırt çizgisi, doruktan aşağı akan mahmuz çizgileri.
relief:  elle boyanmış kabartma - simge yok; yamaç gölgesi sulu boya, eğimin
         yönünde kısa tarama çizgileri (hachure).
"""
import math

import numpy as np
from scipy import ndimage as ndi

from hand import INK, darker, ink, shape


def _jagged_peak(x, by, W, H, rng, bumps=None):
    """Kenarı kırık kaya: birkaç omuz, keskin tepe."""
    n = bumps or int(rng.integers(2, 5))
    px = x + W * (rng.random() - 0.5) * 0.3
    pts = [(x - W / 2, by)]
    for i in range(1, 7):
        t = i / 7
        xx = x - W / 2 + (px - x + W / 2) * t
        yy = by - H * t ** 0.9 + rng.normal(0, H * 0.05)
        if rng.random() < 0.3:
            yy -= H * 0.08
        pts.append((xx, yy))
    pts.append((px, by - H))
    for i in range(1, 7):
        t = i / 7
        xx = px + (x + W / 2 - px) * t
        yy = by - H * (1 - t) ** 1.1 + rng.normal(0, H * 0.05)
        pts.append((xx, yy))
    pts.append((x + W / 2, by))
    return pts, px


def cluster_group(ctx, rng, x, by, size, color=(0.74, 0.69, 0.58)):
    n = int(rng.integers(2, 5))
    peaks = []
    for i in range(n):
        W = size * (0.55 + 0.6 * rng.random())
        H = W * (0.75 + 0.4 * rng.random())
        dx = (rng.random() - 0.5) * size * 0.9
        dy = rng.random() * size * 0.18
        peaks.append((by - dy, x + dx, W, H))
    for b, xx, W, H in sorted(peaks):
        pts, px = _jagged_peak(xx, b, W, H, rng)
        shade = [(px, b - H - 3), (xx + W / 2 + 3, b - H - 3), (xx + W / 2 + 3, b + 2), (px, b + 2)]
        shape(ctx, pts, color, rng, hatch_angle=1.2, hatch_sp=1.4, hatch_region=shade, hatch_alpha=0.75, w=1.0)
        # kaya çatlakları ve basamaklar
        for k in range(int(rng.integers(2, 5))):
            t = rng.random()
            sx = px + (rng.random() - 0.5) * W * 0.5
            sy = b - H * (0.3 + 0.5 * rng.random())
            ink(ctx, [(sx, sy), (sx + W * 0.08, sy + H * 0.12), (sx + W * 0.02, sy + H * 0.25)], rng, 0.55,
                closed=False, amp=0.2, alpha=0.75)
        ink(ctx, [(xx - W * 0.35, b - 1.5), (xx + W * 0.4, b - 1)], rng, 0.4, closed=False, amp=0.3, alpha=0.4)


def ridge_peaks(height, mount, N, rng, spacing=38):
    hs = ndi.gaussian_filter(height, 4)
    mx = ndi.maximum_filter(hs, size=spacing)
    ys, xs = np.nonzero((hs == mx) & (mount > 0.45))
    out = [(float(x), float(y), float(hs[y, x])) for x, y in zip(xs, ys)]
    return out, hs


def ridge_draw(ctx, rng, peaks, hs, keep, color=(0.82, 0.74, 0.60)):
    gy, gx = np.gradient(hs)
    hmax = max(p[2] for p in peaks) if peaks else 1
    N = hs.shape[0]
    objs = []
    for x, y, h in peaks:
        if keep[int(y), int(x)]:
            continue
        H = 18 + 46 * (h / hmax) * (0.8 + 0.4 * rng.random())
        W = H * (1.0 + 0.4 * rng.random())
        objs.append((y, x, W, H))
    for y, x, W, H in sorted(objs):
        ridge_one(ctx, rng, x, y, W, H, color)


def ridge_one(ctx, rng, x, y, W, H, color=(0.82, 0.74, 0.60)):
    if True:
        pts, px = _jagged_peak(x, y, W, H, rng, bumps=2)
        shade = [(px, y - H - 3), (x + W / 2 + 3, y - H - 3), (x + W / 2 + 3, y + 2), (px, y + 2)]
        shape(ctx, pts, color, rng, hatch_angle=1.3, hatch_sp=1.2, hatch_region=shade, hatch_alpha=0.85, w=1.1)
        # doruktan aşağı akan mahmuzlar
        for k in range(int(rng.integers(3, 7))):
            sx = px + (rng.random() - 0.5) * W * 0.6
            sy = y - H * (0.55 + 0.35 * rng.random())
            line = [(sx, sy)]
            ang = math.pi / 2 + (sx - px) / W * 1.6
            for j in range(5):
                ang += rng.normal(0, 0.15)
                line.append((line[-1][0] + math.cos(ang) * H * 0.09, line[-1][1] + math.sin(ang) * H * 0.09))
            ink(ctx, line, rng, 0.5, closed=False, amp=0.15, alpha=0.7)
        # eteğe yayılan kısa tepeler
        for k in range(int(rng.integers(0, 3))):
            fx = x + (rng.random() - 0.5) * W * 1.6
            fW = W * 0.35
            p2, px2 = _jagged_peak(fx, y + 4 + rng.random() * 6, fW, fW * 0.6, rng, 2)
            shape(ctx, p2, color, rng, hatch_angle=1.3, hatch_sp=1.4,
                  hatch_region=[(px2, y - fW), (fx + fW, y - fW), (fx + fW, y + 20), (px2, y + 20)],
                  hatch_alpha=0.7, w=0.8)


def relief_wash(height, mount, water):
    """Yamaç gölgesi: kuzeybatıdan ışık; yalnızca dağlık ve tepelik yerde."""
    hs = ndi.gaussian_filter(height, 3)
    gy, gx = np.gradient(hs)
    lx, ly = -0.7, -0.7
    shade = (gx * lx + gy * ly)
    shade = np.clip(shade / (np.percentile(np.abs(shade), 98) + 1e-6), -1, 1)
    wgt = np.clip(ndi.gaussian_filter(mount, 6) * 1.6, 0, 1) * (~water)
    return shade, wgt, gx, gy


def relief_hachures(ctx, rng, gx, gy, wgt, keep, water, N, density=5.0):
    slope = np.hypot(gx, gy)
    sm = slope / (np.percentile(slope[wgt > 0.2], 95) + 1e-6) if (wgt > 0.2).any() else slope
    ys, xs = np.nonzero((wgt > 0.15) & (sm > 0.18) & ~water)
    if not len(xs):
        return
    order = rng.permutation(len(xs))
    grid = {}
    for i in order:
        x, y = xs[i], ys[i]
        g = (int(x // density), int(y // density))
        if g in grid:
            continue
        if keep[y, x]:
            continue
        grid[g] = 1
        s = min(1.0, sm[y, x])
        L = 3 + 7 * s
        ux, uy = gx[y, x], gy[y, x]
        n = math.hypot(ux, uy) + 1e-6
        ux, uy = ux / n, uy / n
        shadow = (ux * -0.7 + uy * -0.7) < 0
        if not shadow and rng.random() < 0.6:
            continue
        w = 0.4 + 0.7 * s * (1.2 if shadow else 0.6)
        ink(ctx, [(x - ux * L / 2, y - uy * L / 2), (x + ux * L / 2, y + uy * L / 2)], rng, w, closed=False, amp=0.1,
            alpha=0.5 + 0.4 * s)
