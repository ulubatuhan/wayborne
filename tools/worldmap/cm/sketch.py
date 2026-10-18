"""El çizimi coğrafya: dağ ve ağaç.

Kalemin baskısı çizginin içinde değişir (başta kalın, sonda incelir), şekillerin
altı kapanmaz, tarama tek tek fırça darbesidir ve yamacın yönünü izler, hiçbir
iki dağ ya da ağaç aynı kalıptan çıkmaz.
"""
import math

import cv2
import numpy as np
from scipy import ndimage as ndi

from hand import INK, PAPER, path, wob


def stroke(ctx, pts, rng, w=1.2, taper=(0.35, 1.0, 0.15), color=INK, alpha=0.95, amp=0.35):
    """Baskılı kalem darbesi: genişlik başta/ortada/sonda (taper) oranlarıyla değişir."""
    p = wob(pts, rng, amp, step=1.8, closed=False, freq=0.15)
    n = len(p)
    if n < 2:
        return
    t = np.linspace(0, 1, n)
    a, b, c = taper
    ww = np.where(t < 0.5, a + (b - a) * (t / 0.5), b + (c - b) * ((t - 0.5) / 0.5)) * w
    d = np.gradient(p, axis=0)
    d /= np.maximum(np.linalg.norm(d, axis=1, keepdims=True), 1e-6)
    nrm = np.stack([-d[:, 1], d[:, 0]], 1)
    left = p + nrm * (ww[:, None] / 2)
    right = p - nrm * (ww[:, None] / 2)
    path(ctx, np.vstack([left, right[::-1]]), True)
    ctx.set_source_rgba(*color, alpha)
    ctx.fill()


def _fill(ctx, pts, color, alpha):
    path(ctx, pts, True)
    ctx.set_source_rgb(*PAPER)
    ctx.fill()
    if color is not None:
        path(ctx, pts, True)
        ctx.set_source_rgba(*color, alpha)
        ctx.fill()


# ------------------------------------------------------------------ dağ

def mountain(ctx, rng, x, by, W, H, color=(0.78, 0.70, 0.56), wash=0.45):
    """Altı açık, omuzlu bir dağ; sağ yamaç sırttan aşağı akan darbelerle gölgeli."""
    pk = np.array([x + W * rng.uniform(-0.15, 0.15), by - H])
    # sol yamaç: bir iki omuz, kırık
    L = [np.array([x - W / 2, by])]
    k = int(rng.integers(2, 4))
    for i in range(1, k + 1):
        t = i / (k + 1)
        q = L[0] + (pk - L[0]) * t
        q = q + np.array([rng.normal(0, W * 0.04), -abs(rng.normal(0, H * 0.10))])
        L.append(q)
    L.append(pk)
    R = [pk]
    k = int(rng.integers(2, 4))
    end = np.array([x + W / 2, by])
    for i in range(1, k + 1):
        t = i / (k + 1)
        q = pk + (end - pk) * t
        q = q + np.array([rng.normal(0, W * 0.04), -abs(rng.normal(0, H * 0.08))])
        R.append(q)
    R.append(end)
    outline = np.array(L + R[1:])
    _fill(ctx, np.vstack([outline, [[x, by + 1.5]]]), color, wash)
    # gölge yamacı: sırttan aşağı, eğimi izleyen darbeler
    ridge = np.array(R)
    seg = np.cumsum(np.r_[0, np.linalg.norm(np.diff(ridge, axis=0), axis=1)])
    total = seg[-1]
    s = 0.0
    while s < total * 0.92:
        i = min(int(np.searchsorted(seg, s)), len(ridge) - 1)
        i = max(i, 1)
        f = (s - seg[i - 1]) / max(seg[i] - seg[i - 1], 1e-6)
        q = ridge[i - 1] + (ridge[i] - ridge[i - 1]) * f
        depth = (by - q[1]) / H
        Ls = H * (0.25 + 0.55 * depth) * rng.uniform(0.6, 1.1)
        ang = math.radians(rng.uniform(100, 118))
        q2 = q + np.array([math.cos(ang) * Ls * -0.35, math.sin(ang) * Ls])
        mid = (q + q2) / 2 + np.array([-1.2, 0])
        stroke(ctx, [q + [-0.6, 0.6], mid, q2], rng, w=0.75 + 0.5 * depth, taper=(1.0, 0.7, 0.05), alpha=0.85)
        s += rng.uniform(2.0, 3.4)
    # aydınlık yamaçta yalnızca birkaç kısa kırık çizgi
    for _ in range(int(rng.integers(1, 4))):
        t = rng.uniform(0.25, 0.75)
        q = outline[0] + (pk - outline[0]) * t + np.array([W * 0.06, H * 0.05])
        stroke(ctx, [q, q + [W * 0.05, H * 0.10], q + [W * 0.02, H * 0.2]], rng, w=0.6, taper=(0.8, 0.6, 0.1),
               alpha=0.7)
    # siluet: iki darbe, tepede biraz üst üste
    stroke(ctx, L, rng, w=1.5, taper=(0.4, 1.0, 0.75), amp=0.4)
    stroke(ctx, R, rng, w=1.5, taper=(0.9, 1.0, 0.25), amp=0.4)
    # etekte zemine oturtan kısa çizgiler
    for sx in (-0.5, 0.5):
        gx = x + W * sx
        stroke(ctx, [(gx - 4, by + 0.5), (gx + 4, by + 0.8)], rng, w=0.6, taper=(0.2, 0.8, 0.1), alpha=0.6)


def foothill(ctx, rng, x, by, W):
    """Etek tümseği: tek bir kavisli darbe ve altına iki gölge çizgisi."""
    H = W * rng.uniform(0.25, 0.4)
    pts = [(x - W / 2 + W * t, by - H * math.sin(math.pi * t) * (1 + 0.1 * rng.normal())) for t in np.linspace(0, 1, 9)]
    _fill(ctx, pts + [(x, by + 1)], (0.80, 0.73, 0.58), 0.35)
    stroke(ctx, pts, rng, w=1.1, taper=(0.3, 1.0, 0.2))
    for k in range(int(rng.integers(2, 5))):
        t = 0.55 + 0.1 * k
        q = (x - W / 2 + W * t, by - H * math.sin(math.pi * t))
        stroke(ctx, [q, (q[0] - 1.5, q[1] + H * 0.6)], rng, w=0.6, taper=(0.9, 0.5, 0.05), alpha=0.7)


# ------------------------------------------------------------------ ağaç

def tree(ctx, rng, x, by, s=1.0, kind="leaf", color=(0.55, 0.66, 0.38)):
    if kind == "conifer":
        h = 13 * s * rng.uniform(0.85, 1.15)
        w = 5.5 * s
        pts = [(x - w / 2, by - h * 0.18)]
        for i in range(3):
            y = by - h * (0.18 + 0.27 * i)
            pts += [(x - w * (0.5 - 0.12 * i) + 1.5 * s, y - h * 0.08), (x - w * (0.42 - 0.12 * i), y - h * 0.2)]
        pts.append((x, by - h))
        rpts = [(2 * x - a, b) for a, b in pts[::-1]]
        poly = pts + rpts[1:]
        _fill(ctx, poly, (0.36, 0.50, 0.36), 0.40)
        stroke(ctx, [(x, by + 1), (x, by - h * 0.5)], rng, w=1.0 * s, taper=(1, 0.7, 0.2), amp=0.1)
        stroke(ctx, poly[:len(pts)], rng, w=0.9 * s, taper=(0.4, 1, 0.6), amp=0.25)
        stroke(ctx, poly[len(pts) - 1:], rng, w=1.0 * s, taper=(0.8, 1, 0.3), amp=0.25)
        for k in range(3):
            y = by - h * (0.25 + 0.22 * k)
            stroke(ctx, [(x + 0.6, y), (x + w * 0.35, y + 1.6)], rng, w=0.55, taper=(0.9, 0.5, 0.1), alpha=0.75)
        return
    r = 4.3 * s * rng.uniform(0.85, 1.15)
    cy = by - r * 1.55
    # taç: kapanmayan, tümsekli bir çember; sağ altta açıklık bırakır
    a0 = rng.uniform(0.2, 0.6)
    angs = np.linspace(a0, a0 + 2 * math.pi - 0.7, 22)
    bump = 1 + 0.12 * np.abs(np.sin(angs * 3.5 + rng.random() * 6))
    crown = np.stack([x + r * bump * np.cos(angs), cy + r * 0.92 * bump * np.sin(angs)], 1)
    _fill(ctx, np.vstack([crown, [[x + r * 0.9, cy + r * 0.4]]]), color, 0.30)
    stroke(ctx, [(x, by + 0.5), (x + 0.3, by - r * 0.9)], rng, w=1.4 * s, taper=(1, 0.8, 0.3), amp=0.1)
    stroke(ctx, crown, rng, w=1.0 * s, taper=(0.5, 1.0, 0.2), amp=0.3)
    for k in range(int(rng.integers(3, 6))):
        a = rng.uniform(-0.2, 1.3)
        q = (x + r * 0.55 * math.cos(a), cy + r * 0.55 * math.sin(a))
        stroke(ctx, [q, (q[0] + 1.6, q[1] + 1.8)], rng, w=0.6, taper=(0.9, 0.6, 0.1), alpha=0.7)


def forest_mass(ctx, rng, mask, conifer_mask, keep, color=(0.55, 0.66, 0.38), dark=(0.36, 0.50, 0.36)):
    """Orman tek bir kütle: tırtıllı kenar, içte sıra sıra yarım tepe darbeleri,
    ön kenarda gövdeleriyle birkaç ağaç."""
    m = (ndi.gaussian_filter(mask.astype(np.float32), 2.5) > 0.5) & ~keep
    lab, n = ndi.label(m)
    if n == 0:
        return []
    front = []
    for k in range(1, n + 1):
        comp = lab == k
        if comp.sum() < 120:
            continue
        cs, _ = cv2.findContours(comp.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
        for c in cs:
            pts = c[:, 0, :].astype(float)
            if len(pts) < 20:
                continue
            ys, xs = np.nonzero(comp)
            con = conifer_mask[ys, xs].mean() > 0.5
            fill_c = dark if con else color
            # dolgu
            path(ctx, pts, True)
            ctx.set_source_rgba(*fill_c, 0.55)
            ctx.fill()
            # içerideki yarım tepeler: kaydırmalı sıralar
            step_x, step_y = (7.0, 5.5) if not con else (6.0, 6.0)
            for yy in np.arange(ys.min() + 4, ys.max(), step_y):
                off = (int(yy / step_y) % 2) * step_x / 2
                for xx in np.arange(xs.min() + off, xs.max(), step_x):
                    xj, yj = xx + rng.normal(0, 1.2), yy + rng.normal(0, 1.0)
                    xi, yi = int(xj), int(yj)
                    if not (0 <= yi < comp.shape[0] and 0 <= xi < comp.shape[1]) or not comp[yi, xi]:
                        continue
                    if rng.random() < 0.18:
                        continue
                    r = step_x * 0.48 * rng.uniform(0.8, 1.15)
                    if con:
                        stroke(ctx, [(xj - r * 0.6, yj + r * 0.5), (xj, yj - r * 0.9), (xj + r * 0.6, yj + r * 0.5)],
                               rng, w=0.7, taper=(0.3, 1, 0.3), alpha=0.75, amp=0.15)
                    else:
                        arc = [(xj + r * math.cos(a), yj - r * 0.8 * math.sin(a)) for a in np.linspace(0.1, math.pi - 0.1, 7)]
                        stroke(ctx, arc[::-1], rng, w=0.75, taper=(0.3, 1, 0.4), alpha=0.75, amp=0.15)
                        stroke(ctx, [(xj + r * 0.4, yj - r * 0.2), (xj + r * 0.7, yj + r * 0.3)], rng, w=0.5,
                               taper=(0.8, 0.5, 0.1), alpha=0.55, amp=0.1)
            # kenar: dışa doğru tümsekler, her biri ayrı darbe
            res = pts[::6]
            cx_, cy_ = xs.mean(), ys.mean()
            for i in range(len(res)):
                a, b = res[i], res[(i + 1) % len(res)]
                mid = (a + b) / 2
                d = b - a
                L = np.linalg.norm(d) + 1e-6
                nrm = np.array([d[1], -d[0]]) / L
                if comp[int(np.clip(mid[1] + nrm[1] * 3, 0, comp.shape[0] - 1)),
                        int(np.clip(mid[0] + nrm[0] * 3, 0, comp.shape[1] - 1))]:
                    nrm = -nrm
                bulge = mid + nrm * L * 0.45
                if con:
                    arc = [a, bulge + nrm * 1.5, b]
                else:
                    arc = [a + (bulge - a) * t2 + nrm * math.sin(math.pi * t2) * L * 0.15 for t2 in np.linspace(0, 1, 4)]
                    arc += [bulge + (b - bulge) * t2 + nrm * math.sin(math.pi * t2) * L * 0.15 for t2 in np.linspace(0, 1, 4)[1:]]
                stroke(ctx, arc, rng, w=1.05, taper=(0.4, 1, 0.3), alpha=0.9, amp=0.2)
                if nrm[1] > 0.5 and rng.random() < 0.55:
                    front.append((float(mid[0]), float(mid[1] + 2), con))
    return front
