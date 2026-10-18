"""Elle çizim fırçaları: titrek mürekkep, sulu boya dolgu, tarama.

Bütün ölçüler çıktı pikseli; cairo bağlamı süper örnekleme için ölçeklenmiş olabilir.
"""
import math

import cairo
import numpy as np

INK = (0.17, 0.12, 0.09)
PAPER = (0.94, 0.89, 0.77)


def darker(c, k=0.72):
    return tuple(v * k for v in c)


def resample(pts, step, closed):
    p = [np.asarray(q, float) for q in pts]
    if closed:
        p = p + [p[0]]
    out = [p[0]]
    for a, b in zip(p[:-1], p[1:]):
        L = float(np.hypot(*(b - a)))
        n = max(1, int(L / step))
        for i in range(1, n + 1):
            out.append(a + (b - a) * i / n)
    if closed:
        out = out[:-1]
    return np.array(out)


def wob(pts, rng, amp=0.5, step=2.5, closed=True, freq=0.09):
    """Çizgiyi, yay boyunca yumuşak bir gürültüyle normaline doğru oynat."""
    p = resample(pts, step, closed)
    if len(p) < 3:
        return p
    nxt = np.roll(p, -1, 0) if closed else np.vstack([p[1:], p[-1:] + (p[-1:] - p[-2:-1])])
    prv = np.roll(p, 1, 0) if closed else np.vstack([p[:1] - (p[1:2] - p[:1]), p[:-1]])
    t = nxt - prv
    n = np.stack([-t[:, 1], t[:, 0]], 1)
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-6)
    s = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(p, axis=0), axis=1))])
    off = np.zeros(len(p))
    for k in range(3):
        f = freq * (1.7 ** k) * (0.7 + 0.6 * rng.random())
        off += math.sin(0) + np.sin(s * f + rng.random() * 6.283) / (1.6 ** k)
    off *= amp / 1.6
    return p + n * off[:, None]


def path(ctx, p, closed=True):
    ctx.new_path()
    ctx.move_to(*p[0])
    for q in p[1:]:
        ctx.line_to(*q)
    if closed:
        ctx.close_path()


def ink(ctx, pts, rng, w=1.0, closed=True, amp=0.45, color=INK, alpha=1.0):
    p = wob(pts, rng, amp, closed=closed)
    path(ctx, p, closed)
    ctx.set_source_rgba(*color, alpha)
    ctx.set_line_width(w)
    ctx.set_line_join(cairo.LINE_JOIN_ROUND)
    ctx.set_line_cap(cairo.LINE_CAP_ROUND)
    ctx.stroke()
    # ikinci, ince ve hafif kayık geçiş: kalem baskısının düzensizliği
    p2 = wob(pts, rng, amp * 0.8, closed=closed)
    path(ctx, p2, closed)
    ctx.set_source_rgba(*color, 0.35 * alpha)
    ctx.set_line_width(w * 0.55)
    ctx.stroke()


def wash(ctx, pts, color, rng, alpha=0.88, shift=0.9, base=True):
    """Kâğıt rengi taban (arkadakini örter) + çizgiden taşan/eksik kalan boya."""
    if base:
        path(ctx, wob(pts, rng, 0.3), True)
        ctx.set_source_rgb(*PAPER)
        ctx.fill()
    d = rng.normal(0, shift, 2)
    p = wob(np.asarray(pts, float) + d, rng, 0.9, freq=0.12)
    path(ctx, p, True)
    ctx.set_source_rgba(*color, alpha)
    ctx.fill_preserve()
    # sulu boyanın kenarda toplanması
    ctx.set_source_rgba(*darker(color, 0.78), 0.32)
    ctx.set_line_width(1.3)
    ctx.stroke()


def hatch(ctx, pts, rng, angle=1.15, spacing=2.2, w=0.45, alpha=0.85, region=None, color=INK, jag=0.25):
    """Çokgen içine paralel tarama (isteğe bağlı ek kırpma bölgesi)."""
    p = np.asarray(pts, float)
    ctx.save()
    path(ctx, p, True)
    ctx.clip()
    if region is not None:
        path(ctx, np.asarray(region, float), True)
        ctx.clip()
    x0, y0 = p.min(0) - 4
    x1, y1 = p.max(0) + 4
    c, s = math.cos(angle), math.sin(angle)
    diag = math.hypot(x1 - x0, y1 - y0)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    ctx.set_source_rgba(*color, alpha)
    ctx.set_line_width(w)
    k = -diag / 2
    while k < diag / 2:
        ox, oy = cx + k * -s, cy + k * c
        a = (ox - c * diag / 2, oy - s * diag / 2)
        b = (ox + c * diag / 2, oy + s * diag / 2)
        q = wob([a, b], rng, jag, step=3, closed=False)
        path(ctx, q, False)
        ctx.stroke()
        k += spacing * (0.85 + 0.3 * rng.random())
    ctx.restore()


def shape(ctx, pts, color, rng, hatch_angle=None, hatch_sp=2.2, hatch_region=None, w=0.95, alpha=0.9,
          hatch_alpha=0.75):
    wash(ctx, pts, color, rng, alpha)
    if hatch_angle is not None:
        hatch(ctx, pts, rng, hatch_angle, hatch_sp, region=hatch_region, alpha=hatch_alpha)
    ink(ctx, pts, rng, w)


def ellipse_pts(cx, cy, rx, ry, a0=0, a1=2 * math.pi, n=48):
    t = np.linspace(a0, a1, n)
    return np.stack([cx + rx * np.cos(t), cy + ry * np.sin(t)], 1)


def blob(cx, cy, r, rng, bumps=7, rough=0.18, ry=1.0):
    """Ağaç tacı: kenarı tümsekli yuvarlak."""
    t = np.linspace(0, 2 * math.pi, bumps * 6, endpoint=False)
    ph = rng.random() * 6.28
    rr = r * (1 + rough * np.abs(np.sin(t * bumps / 2 + ph)) - rough * 0.5)
    return np.stack([cx + rr * np.cos(t), cy + ry * rr * np.sin(t)], 1)
