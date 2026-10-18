"""Yapı simgeleri: eğik (yandan-üstten) bakışta, elle çizilmiş, masalsı.

Her fonksiyon (ctx, ...) alır ve ön-alt noktasına göre çizer. Derinlik
vektörü D sağa-yukarı: yan duvar ve çatı sırtı oraya kaçar.
"""
import math

import numpy as np

from hand import INK, PAPER, darker, ellipse_pts, hatch, ink, path, shape, wash, blob

DX, DY = 0.55, -0.42

# kültür paletleri
C = dict(
    ochre=(0.95, 0.83, 0.60), red=(0.80, 0.34, 0.22), white=(0.97, 0.95, 0.89),
    pale=(0.90, 0.88, 0.81), slate=(0.43, 0.50, 0.60), grey=(0.67, 0.66, 0.63),
    shingle=(0.60, 0.42, 0.27), timber=(0.42, 0.28, 0.16), sod=(0.55, 0.62, 0.36),
    gold=(0.86, 0.66, 0.24), green=(0.45, 0.60, 0.32), dkgreen=(0.27, 0.43, 0.30),
    banner_vadi=(0.24, 0.48, 0.30), banner_ahit=(0.92, 0.90, 0.80), banner_sinir=(0.62, 0.22, 0.18),
    banner_imp=(0.20, 0.18, 0.20), straw=(0.86, 0.74, 0.44),
)


def windows(ctx, rng, x0, x1, ytop, ybot, rows=1, kind="square"):
    w = x1 - x0
    n = max(1, int(w / 4.5))
    for r in range(rows):
        yy = ytop + (ybot - ytop) * (r + 0.5) / rows
        for i in range(n):
            if rng.random() < 0.25:
                continue
            x = x0 + w * (i + 0.5) / n
            if kind == "arch":
                pts = [(x - 0.8, yy + 1.2), (x - 0.8, yy - 0.6), (x, yy - 1.4), (x + 0.8, yy - 0.6), (x + 0.8, yy + 1.2)]
            else:
                pts = [(x - 0.8, yy - 0.9), (x + 0.8, yy - 0.9), (x + 0.8, yy + 0.9), (x - 0.8, yy + 0.9)]
            path(ctx, pts)
            ctx.set_source_rgba(*INK, 0.85)
            ctx.fill()


def door(ctx, cx, by, h=3.2, w=2.0):
    pts = [(cx - w / 2, by), (cx - w / 2, by - h * 0.7), (cx, by - h), (cx + w / 2, by - h * 0.7), (cx + w / 2, by)]
    path(ctx, pts)
    ctx.set_source_rgba(*INK, 0.9)
    ctx.fill()


def banner(ctx, rng, x, y, h, color):
    ink(ctx, [(x, y), (x, y - h)], rng, 0.8, closed=False, amp=0.15)
    t = y - h
    wv = rng.random() * 6
    top = [(x + i * 1.2, t + 0.6 * math.sin(i * 0.9 + wv)) for i in range(7)]
    bot = [(x + i * 1.2, t + 3.2 + 0.6 * math.sin(i * 0.9 + wv) - i * 0.15) for i in range(7)][::-1]
    pts = top + [(x + 9.6, t + 1.6)] + bot
    shape(ctx, pts, color, rng, w=0.6)


def house(ctx, rng, cx, by, w, d, h, rh, wall, roof, kind="eave", timber=False, chimney=None, win=True,
          stilts=0.0, flat=False):
    """Tek ev. kind: 'eave' (saçak öne) ya da 'gable' (alın öne)."""
    if stilts > 0:
        for sx in (cx - w * 0.4, cx + w * 0.4, cx + w * 0.5 + d * DX * 0.9):
            ink(ctx, [(sx, by), (sx, by - stilts)], rng, 0.7, closed=False, amp=0.1)
        by -= stilts
    x0, x1 = cx - w / 2, cx + w / 2
    Dx, Dy = d * DX, d * DY
    side = [(x1, by), (x1 + Dx, by + Dy), (x1 + Dx, by + Dy - h), (x1, by - h)]
    shape(ctx, side, darker(wall, 0.86), rng, hatch_angle=1.45, hatch_sp=1.8, hatch_alpha=0.55, w=0.85)
    if flat:
        front = [(x0, by), (x1, by), (x1, by - h), (x0, by - h)]
        top = [(x0 - 0.6, by - h), (x1 + 0.6, by - h), (x1 + Dx + 0.6, by + Dy - h), (x0 + Dx - 0.6, by + Dy - h)]
        shape(ctx, front, wall, rng, w=0.85)
        shape(ctx, top, roof, rng, w=0.8)
        # parapet
        ink(ctx, [(x0 - 0.6, by - h - 0.9), (x1 + 0.6, by - h - 0.9)], rng, 0.6, closed=False, amp=0.1)
    elif kind == "gable":
        ridge = (cx, by - h - rh)
        sroof = [ridge, (cx + Dx, by - h - rh + Dy), (x1 + Dx + 0.8, by - h + Dy + 0.5), (x1 + 0.8, by - h + 0.5)]
        shape(ctx, sroof, roof, rng, hatch_angle=math.atan2(Dy, Dx) + 1.57 * 0.9, hatch_sp=1.9, hatch_alpha=0.5,
              w=0.85)
        front = [(x0, by), (x1, by), (x1, by - h), ridge, (x0, by - h)]
        shape(ctx, front, wall, rng, w=0.9)
        if timber:
            _timber(ctx, rng, x0, x1, by, h)
        if win:
            windows(ctx, rng, x0 + 1, x1 - 1, by - h + 1.2, by - h * 0.45)
            ink(ctx, [(cx - 0.6, by - h - rh * 0.45), (cx + 0.6, by - h - rh * 0.45)], rng, 1.2, closed=False, amp=0.05)
        door(ctx, cx + w * 0.15 * (rng.random() - 0.5), by, min(3.4, h * 0.55))
    else:
        o = 0.9
        rl = (x0 + Dx / 2, by - h + Dy / 2 - rh)
        rr = (x1 + Dx / 2, by - h + Dy / 2 - rh)
        gable = [(x1, by - h), (x1 + Dx, by - h + Dy), rr]
        shape(ctx, gable, darker(wall, 0.9), rng, w=0.8)
        front = [(x0, by), (x1, by), (x1, by - h), (x0, by - h)]
        shape(ctx, front, wall, rng, w=0.9)
        if timber:
            _timber(ctx, rng, x0, x1, by, h)
        froof = [(x0 - o, by - h + 0.6), (x1 + o, by - h + 0.6), (rr[0] + o * 0.3, rr[1]), (rl[0] - o * 0.6, rl[1])]
        shape(ctx, froof, roof, rng, hatch_angle=-1.30, hatch_sp=1.7, hatch_alpha=0.45, w=0.9)
        if win:
            windows(ctx, rng, x0 + 1, x1 - 1, by - h + 1.5, by - 2.5, rows=1 if h < 9 else 2)
        door(ctx, x0 + w * (0.25 + 0.5 * rng.random()), by, min(3.4, h * 0.5))
        if chimney:
            t = 0.3 + 0.4 * rng.random()
            px = rl[0] + (rr[0] - rl[0]) * t
            py = rl[1] + (rr[1] - rl[1]) * t + rh * 0.35
            shape(ctx, [(px - 0.9, py), (px + 0.9, py), (px + 0.9, py - 3.2), (px - 0.9, py - 3.2)], chimney, rng, w=0.6)


def _timber(ctx, rng, x0, x1, by, h):
    for x in np.linspace(x0, x1, max(2, int((x1 - x0) / 4)) + 1)[1:-1]:
        ink(ctx, [(x, by), (x, by - h)], rng, 0.6, closed=False, amp=0.1, alpha=0.8)
    ink(ctx, [(x0, by - h * 0.5), (x1, by - h * 0.5)], rng, 0.6, closed=False, amp=0.1, alpha=0.8)
    mx = (x0 + x1) / 2
    ink(ctx, [(x0, by - h * 0.5), (mx, by - h)], rng, 0.5, closed=False, amp=0.1, alpha=0.7)
    ink(ctx, [(x1, by - h * 0.5), (mx, by - h)], rng, 0.5, closed=False, amp=0.1, alpha=0.7)


def round_tower(ctx, rng, cx, by, r, h, wall, cap="cone", cap_color=None, cap_h=None, flag=None, slit=True):
    ry = r * 0.36
    body = list(ellipse_pts(cx, by, r, ry, 0, math.pi, 14)) + [(cx - r, by - h), (cx + r, by - h)][::-1]
    body = [(cx + r, by - h)] + list(ellipse_pts(cx, by, r, ry, 0, math.pi, 14)) + [(cx - r, by - h)]
    shade = [(cx + r * 0.25, by + 5), (cx + r + 3, by + 5), (cx + r + 3, by - h - 5), (cx + r * 0.25, by - h - 5)]
    shape(ctx, body, wall, rng, hatch_angle=1.52, hatch_sp=1.6, hatch_region=shade, hatch_alpha=0.6, w=0.9)
    top = by - h
    if slit:
        for k in range(int(h / 9)):
            yy = by - 4 - k * 8
            path(ctx, [(cx - 0.5, yy), (cx + 0.5, yy), (cx + 0.5, yy - 2.6), (cx - 0.5, yy - 2.6)])
            ctx.set_source_rgba(*INK, 0.85)
            ctx.fill()
    if cap in ("cone", "spire"):
        ch = cap_h or (r * 2.4 if cap == "cone" else r * 5.0)
        ov = 1.2
        base = list(ellipse_pts(cx, top, r + ov, ry + 0.5, 0, math.pi, 12))
        cone = [(cx, top - ch)] + base[::-1][::-1]
        cone = [(cx + r + ov, top)] + base + [(cx - r - ov, top), (cx, top - ch)]
        cshade = [(cx, top + 4), (cx + r + 4, top + 4), (cx + r + 4, top - ch), (cx, top - ch)]
        shape(ctx, cone, cap_color, rng, hatch_angle=1.35, hatch_sp=1.6, hatch_region=cshade, hatch_alpha=0.55, w=0.9)
        if flag:
            banner(ctx, rng, cx, top - ch, 7, flag)
        else:
            shape(ctx, blob(cx, top - ch - 0.8, 1.0, rng, 4, 0.1), C["gold"], rng, w=0.5)
    elif cap == "crenel":
        rim = list(ellipse_pts(cx, top, r + 0.8, ry + 0.4, 0, 2 * math.pi, 20))
        shape(ctx, rim, darker(wall, 0.85), rng, w=0.8)
        for a in np.linspace(0.15, math.pi - 0.15, 5):
            x = cx + (r + 0.4) * math.cos(a)
            y = top + (ry + 0.2) * math.sin(a)
            shape(ctx, [(x - 1, y), (x + 1, y), (x + 1, y - 2.2), (x - 1, y - 2.2)], wall, rng, w=0.6)
        if flag:
            banner(ctx, rng, cx, top, 9, flag)


def square_tower(ctx, rng, cx, by, w, h, wall, roof=None, roof_h=None, flag=None, crenel=True):
    d = w * 0.8
    Dx, Dy = d * DX, d * DY
    x0, x1 = cx - w / 2, cx + w / 2
    shape(ctx, [(x1, by), (x1 + Dx, by + Dy), (x1 + Dx, by + Dy - h), (x1, by - h)], darker(wall, 0.85), rng,
          hatch_angle=1.5, hatch_sp=1.6, hatch_alpha=0.6, w=0.85)
    shape(ctx, [(x0, by), (x1, by), (x1, by - h), (x0, by - h)], wall, rng, w=0.9)
    for k in range(int(h / 9)):
        yy = by - 5 - k * 8
        path(ctx, [(cx - 0.5, yy), (cx + 0.5, yy), (cx + 0.5, yy - 2.6), (cx - 0.5, yy - 2.6)])
        ctx.set_source_rgba(*INK, 0.85)
        ctx.fill()
    top = by - h
    if roof:
        rh = roof_h or w * 1.6
        ap = (cx + Dx / 2, top + Dy / 2 - rh)
        shape(ctx, [(x1 + 0.8, top + 0.5), (x1 + Dx + 0.8, top + Dy), ap], darker(roof, 0.8), rng, w=0.8)
        shape(ctx, [(x0 - 0.8, top + 0.5), (x1 + 0.8, top + 0.5), ap], roof, rng, hatch_angle=-1.2, hatch_sp=1.8,
              hatch_alpha=0.4, w=0.85)
        if flag:
            banner(ctx, rng, ap[0], ap[1], 7, flag)
    elif crenel:
        shape(ctx, [(x0, top), (x1, top), (x1 + Dx, top + Dy), (x0 + Dx, top + Dy)], darker(wall, 0.7), rng, w=0.7)
        n = max(2, int(w / 2.6))
        for i in range(n):
            xx = x0 + (i + 0.5) * w / n
            shape(ctx, [(xx - 0.8, top), (xx + 0.8, top), (xx + 0.8, top - 2.2), (xx - 0.8, top - 2.2)], wall, rng,
                  w=0.6)
        if flag:
            banner(ctx, rng, cx + Dx / 2, top + Dy / 2, 10, flag)


def wall_ring(ctx, rng, cx, cy, rx, ry, h, stone, part, towers=8, tower_r=3.6, tower_h=None, cap="cone",
              cap_color=None, palisade=False, flag=None):
    """part='back' (arka yarı) ya da 'front' (ön yarı, kapı dahil)."""
    a0, a1 = (math.pi, 2 * math.pi) if part == "back" else (0, math.pi)
    n = 40
    t = np.linspace(a0, a1, n)
    xs, ys = cx + rx * np.cos(t), cy + ry * np.sin(t)
    if palisade:
        idx = np.argsort(ys) if part == "back" else np.argsort(ys)
        tt = np.linspace(a0, a1, int(rx * 1.2))
        stakes = sorted([(cy + ry * math.sin(a), cx + rx * math.cos(a)) for a in tt])
        for y, x in stakes:
            if part == "front" and abs(x - cx) < rx * 0.08 and y > cy:
                continue
            hh = h * (0.9 + 0.2 * rng.random())
            shape(ctx, [(x - 1.0, y), (x + 1.0, y), (x + 1.0, y - hh), (x, y - hh - 1.8), (x - 1.0, y - hh)],
                  C["timber"], rng, w=0.55, alpha=0.8)
    else:
        top = list(zip(xs, ys - h))
        bot = list(zip(xs, ys))
        band = top + bot[::-1]
        shp = darker(stone, 0.93 if part == "front" else 0.8)
        shape(ctx, band, shp, rng, hatch_angle=1.5 if part == "back" else None, hatch_sp=2.4, hatch_alpha=0.35, w=0.95)
        # taş sıraları
        for k in (0.4, 0.75):
            ink(ctx, list(zip(xs, ys - h * k)), rng, 0.4, closed=False, amp=0.2, alpha=0.5)
        # mazgallar
        for i in range(1, n - 1, 2):
            x, y = xs[i], ys[i] - h
            shape(ctx, [(x - 0.9, y), (x + 0.9, y), (x + 0.9, y - 1.8), (x - 0.9, y - 1.8)], stone, rng, w=0.5)
    th = tower_h or h * 2.0
    angs = np.linspace(0, 2 * math.pi, towers, endpoint=False) + math.pi / max(towers, 1)
    pts = [(cy + ry * math.sin(a), cx + rx * math.cos(a), a) for a in angs if a0 <= a % (2 * math.pi) <= a1]
    for y, x, a in sorted(pts):
        if part == "front" and abs(x - cx) < rx * 0.2 and y > cy:
            continue
        if palisade:
            square_tower(ctx, rng, x, y, tower_r * 1.6, th * 1.1, C["timber"], roof=C["shingle"], roof_h=5)
        else:
            round_tower(ctx, rng, x, y, tower_r, th, stone, cap=cap, cap_color=cap_color)
    if part == "front":
        gx, gy = cx, cy + ry
        if palisade:
            square_tower(ctx, rng, gx - 6, gy, 5, th * 1.2, C["timber"], roof=C["shingle"], roof_h=5)
            square_tower(ctx, rng, gx + 6, gy, 5, th * 1.2, C["timber"], roof=C["shingle"], roof_h=5, flag=flag)
        else:
            round_tower(ctx, rng, gx - 7, gy, tower_r + 0.8, th * 1.15, stone, cap=cap, cap_color=cap_color)
            shape(ctx, [(gx - 5, gy), (gx + 5, gy), (gx + 5, gy - h - 4), (gx - 5, gy - h - 4)], stone, rng, w=0.9)
            door(ctx, gx, gy, h + 1, 5)
            round_tower(ctx, rng, gx + 7, gy, tower_r + 0.8, th * 1.15, stone, cap=cap, cap_color=cap_color,
                        flag=flag)


def tree(ctx, rng, x, by, s=1.0, kind="leaf", color=None):
    if kind == "conifer":
        hh, ww = 15 * s, 7 * s
        pts = [(x, by - hh)]
        for i in range(1, 4):
            y = by - hh + hh * 0.85 * i / 3
            pts += [(x + ww * 0.5 * i / 3 + 1.2 * s, y), (x + ww * 0.25 * i / 3, y - 1.2 * s)]
        pts += [(x + ww / 2, by - hh * 0.12), (x - ww / 2, by - hh * 0.12)]
        for i in range(3, 0, -1):
            y = by - hh + hh * 0.85 * i / 3
            pts += [(x - ww * 0.25 * i / 3, y - 1.2 * s), (x - ww * 0.5 * i / 3 - 1.2 * s, y)]
        ink(ctx, [(x, by), (x, by - hh * 0.15)], rng, 0.9 * s, closed=False, amp=0.05)
        shp = [(x, by + 3), (x + 9 * s, by + 3), (x + 9 * s, by - hh - 2), (x + 1 * s, by - hh - 2)]
        shape(ctx, pts, color or C["dkgreen"], rng, hatch_angle=1.25, hatch_sp=1.5 * max(s, 0.8), hatch_region=shp,
              hatch_alpha=0.6, w=0.75)
    else:
        r = 4.4 * s
        ink(ctx, [(x, by), (x, by - r * 1.0)], rng, 1.1 * s, closed=False, amp=0.05)
        crown = blob(x, by - r * 1.65, r, rng, 6, 0.22)
        shp = [(x + r * 0.15, by + 2), (x + r + 3, by + 2), (x + r + 3, by - r * 3), (x + r * 0.15, by - r * 3)]
        shape(ctx, crown, color or C["green"], rng, hatch_angle=0.8, hatch_sp=1.4 * max(s, 0.8), hatch_region=shp,
              hatch_alpha=0.55, w=0.75)


def cypress(ctx, rng, x, by, s=1.0):
    hh, r = 14 * s, 2.3 * s
    pts = list(ellipse_pts(x, by - hh / 2 - 1, r, hh / 2, 0, 2 * math.pi, 18))
    ink(ctx, [(x, by), (x, by - 1.5)], rng, 0.8, closed=False, amp=0.05)
    shape(ctx, pts, C["dkgreen"], rng, hatch_angle=1.5, hatch_sp=1.3,
          hatch_region=[(x, by + 2), (x + 5, by + 2), (x + 5, by - hh - 3), (x, by - hh - 3)], w=0.7)


def yurt(ctx, rng, cx, by, r, felt=(0.93, 0.89, 0.80), band=(0.70, 0.30, 0.20)):
    ry = r * 0.35
    h = r * 0.75
    body = [(cx + r, by - h)] + list(ellipse_pts(cx, by, r, ry, 0, math.pi, 14)) + [(cx - r, by - h)]
    shade = [(cx + r * 0.2, by + 5), (cx + r + 3, by + 5), (cx + r + 3, by - h - r), (cx + r * 0.2, by - h - r)]
    shape(ctx, body, felt, rng, hatch_angle=1.5, hatch_sp=1.7, hatch_region=shade, hatch_alpha=0.5, w=0.85)
    ink(ctx, list(ellipse_pts(cx, by - h * 0.55, r, ry, 0, math.pi, 12)), rng, 1.6, closed=False, amp=0.1,
        color=band, alpha=0.9)
    dome = [(cx + r, by - h)] + [(cx + r * math.cos(a), by - h - r * 0.7 * math.sin(a)) for a in
                                 np.linspace(0.05, math.pi - 0.05, 14)] + [(cx - r, by - h)]
    shape(ctx, dome, felt, rng, hatch_angle=1.2, hatch_sp=1.7, hatch_region=shade, hatch_alpha=0.45, w=0.85)
    shape(ctx, list(ellipse_pts(cx, by - h - r * 0.68, r * 0.25, r * 0.1, 0, 2 * math.pi, 10)), C["timber"], rng,
          w=0.6)
    door(ctx, cx - r * 0.2, by + ry * 0.6, h * 0.8, r * 0.45)


def windmill(ctx, rng, cx, by, s=1.0):
    h, r0, r1 = 20 * s, 5.5 * s, 3.6 * s
    body = [(cx - r0, by), (cx + r0, by), (cx + r1, by - h), (cx - r1, by - h)]
    shape(ctx, body, C["white"], rng, hatch_angle=1.5, hatch_sp=1.6,
          hatch_region=[(cx + 1, by + 2), (cx + 9, by + 2), (cx + 9, by - h), (cx + 1, by - h)], w=0.9)
    shape(ctx, [(cx - r1 - 1, by - h), (cx + r1 + 1, by - h), (cx, by - h - 6 * s)], C["shingle"], rng, w=0.8)
    door(ctx, cx, by, 4 * s, 2.4 * s)
    hx, hy = cx - 1, by - h + 1
    ph = rng.random() * 1.5
    for k in range(4):
        a = ph + k * math.pi / 2
        ux, uy = math.cos(a), math.sin(a)
        L = 15 * s
        ink(ctx, [(hx, hy), (hx + ux * L, hy + uy * L)], rng, 0.8, closed=False, amp=0.1)
        px, py = -uy, ux
        sail = [(hx + ux * 4, hy + uy * 4), (hx + ux * L, hy + uy * L),
                (hx + ux * L + px * 3.4 * s, hy + uy * L + py * 3.4 * s), (hx + ux * 4 + px * 3.4 * s, hy + uy * 4 + py * 3.4 * s)]
        shape(ctx, sail, C["white"], rng, hatch_angle=a, hatch_sp=1.6, hatch_alpha=0.5, w=0.6)


def standing_stone(ctx, rng, x, by, s=1.0):
    h, w = 7 * s * (0.8 + 0.4 * rng.random()), 2.6 * s
    pts = [(x - w / 2, by), (x + w / 2, by), (x + w * 0.42, by - h), (x, by - h - 1), (x - w * 0.45, by - h * 0.95)]
    shape(ctx, pts, C["grey"], rng, hatch_angle=1.5, hatch_sp=1.3,
          hatch_region=[(x, by + 2), (x + 4, by + 2), (x + 4, by - h - 2), (x, by - h - 2)], w=0.7)


def mountain(ctx, rng, x, by, W, H, color=(0.80, 0.64, 0.50)):
    """Carta Marina dağı: yuvarlak omuzlu, tepesi biraz kayık bir tümsek;
    gölgeli yamaç taramalı, içinde bir iki sırt çizgisi."""
    px = x + W * (rng.random() - 0.5) * 0.25
    left = [(x - W / 2, by)]
    n = 10
    for i in range(1, n):
        t = i / n
        xx = x - W / 2 + (px - (x - W / 2)) * t
        yy = by - H * (math.sin(t * math.pi / 2) ** 1.4) - H * 0.06 * rng.random()
        left.append((xx, yy))
    top = [(px, by - H)]
    right = []
    for i in range(1, n):
        t = i / n
        xx = px + (x + W / 2 - px) * t
        yy = by - H * (math.cos(t * math.pi / 2) ** 1.2) - H * 0.06 * rng.random()
        right.append((xx, yy))
    right.append((x + W / 2, by))
    pts = left + top + right
    shade = [(px - 1, by - H - 3), (x + W / 2 + 3, by - H - 3), (x + W / 2 + 3, by + 2), (px + W * 0.05, by + 2)]
    shape(ctx, pts, color, rng, hatch_angle=1.05, hatch_sp=1.6, hatch_region=shade, hatch_alpha=0.7, w=1.0)
    for k in range(rng.integers(1, 3)):
        sx = px + (rng.random() - 0.6) * W * 0.25
        ridge = [(px, by - H + 1), (sx, by - H * 0.55), (sx + W * 0.08 * (rng.random() - 0.3), by - H * 0.2)]
        ink(ctx, ridge, rng, 0.6, closed=False, amp=0.3, alpha=0.7)


def ship(ctx, rng, x, y, s=1.0, face=1, sail=(0.95, 0.92, 0.84), stripe=(0.70, 0.26, 0.20)):
    """Masal haritası gemisi: kavisli gövde, kıçta kasara, şişkin kare yelken."""
    f = face
    L, Hh = 26 * s, 6 * s
    hull = [(x - L / 2 * f, y - Hh * 0.9)]
    for t in np.linspace(0, 1, 9):
        hull.append((x + (-L / 2 + L * t) * f, y + Hh * 0.35 * math.sin(math.pi * t)))
    hull += [(x + (L / 2 + 3 * s) * f, y - Hh * 1.2), (x + L * 0.25 * f, y - Hh * 0.55), (x - L * 0.3 * f, y - Hh * 0.6)]
    # su çizgisi dalgaları
    for k in range(3):
        xx = x - L * 0.6 + k * L * 0.45
        ink(ctx, [(xx + i * 1.5, y + 3 * s + 0.8 * math.sin(i * 1.3)) for i in range(6)], rng, 0.5, closed=False,
            amp=0.1, alpha=0.7)
    # direk ve yelken (gövdenin arkasında başlar)
    mx = x + 1 * s * f
    ink(ctx, [(mx, y - Hh * 0.5), (mx, y - 30 * s)], rng, 1.0 * s, closed=False, amp=0.1)
    ink(ctx, [(mx - 9 * s, y - 26 * s), (mx + 9 * s, y - 26 * s)], rng, 0.8 * s, closed=False, amp=0.1)
    belly = 4.5 * s * f
    sl = [(mx - 9 * s, y - 26 * s), (mx + 9 * s, y - 26 * s)]
    sl += [(mx + 8 * s + belly * 0.6, y - 18 * s), (mx + 7 * s, y - 10 * s), (mx - 7 * s, y - 10 * s),
           (mx - 8 * s + belly * 0.6, y - 18 * s)]
    shape(ctx, sl, sail, rng, hatch_angle=1.5, hatch_sp=1.6,
          hatch_region=[(mx + 2 * s * f, y), (mx + 12 * s * f, y), (mx + 12 * s * f, y - 30 * s), (mx + 2 * s * f, y - 30 * s)],
          hatch_alpha=0.4, w=0.8)
    ink(ctx, [(mx - 7.5 * s + belly * 0.3, y - 21 * s), (mx + 7.5 * s + belly * 0.3, y - 21 * s)], rng, 2.0 * s,
        closed=False, amp=0.2, color=stripe, alpha=0.8)
    shape(ctx, hull, (0.50, 0.34, 0.22), rng, hatch_angle=0.15, hatch_sp=1.8, hatch_alpha=0.5, w=0.9)
    # kıç kasarası
    kx = x - L * 0.42 * f
    shape(ctx, [(kx - 3 * s, y - Hh * 0.85), (kx + 4 * s, y - Hh * 0.75), (kx + 4 * s, y - Hh * 1.7),
                (kx - 3 * s, y - Hh * 1.8)], (0.60, 0.42, 0.27), rng, w=0.7)
    # flama
    tx, ty = mx, y - 30 * s
    shape(ctx, [(tx, ty), (tx - 7 * s * f, ty + 1.2 * s), (tx, ty + 2.4 * s)], stripe, rng, w=0.5)


def boat(ctx, rng, x, y, s=1.0, face=1):
    L = 10 * s
    hull = [(x - L / 2, y - 1.6 * s)] + [(x - L / 2 + L * t, y + 1.4 * s * math.sin(math.pi * t)) for t in
                                         np.linspace(0, 1, 7)] + [(x + L / 2, y - 1.8 * s)]
    ink(ctx, [(x, y - 1), (x, y - 9 * s)], rng, 0.6, closed=False, amp=0.05)
    shape(ctx, [(x, y - 9 * s), (x + 4.5 * s * face, y - 2.5 * s), (x, y - 2.5 * s)], (0.93, 0.88, 0.76), rng, w=0.6)
    shape(ctx, hull, (0.52, 0.36, 0.24), rng, w=0.7)
    ink(ctx, [(x - 6 + i * 1.6, y + 2.5 + 0.7 * math.sin(i * 1.4)) for i in range(8)], rng, 0.45, closed=False,
        amp=0.1, alpha=0.7)


def lighthouse(ctx, rng, x, by, s=1.0):
    h, r0, r1 = 30 * s, 5 * s, 3.4 * s
    shape(ctx, [(x - 9 * s, by + 2), (x + 9 * s, by + 2), (x + 6 * s, by - 4 * s), (x - 7 * s, by - 3 * s)],
          C["grey"], rng, hatch_angle=1.1, hatch_sp=1.6, w=0.8)
    body = [(x - r0, by - 3 * s), (x + r0, by - 3 * s), (x + r1, by - h), (x - r1, by - h)]
    shape(ctx, body, C["white"], rng, hatch_angle=1.5, hatch_sp=1.5,
          hatch_region=[(x + 1, by), (x + 9, by), (x + 9, by - h), (x + 1, by - h)], w=0.9)
    for k in (0.35, 0.7):
        yy = by - 3 * s - (h - 3 * s) * k
        rr = r0 + (r1 - r0) * k
        shape(ctx, [(x - rr, yy), (x + rr, yy), (x + rr - 0.3, yy - 3 * s), (x - rr + 0.3, yy - 3 * s)], C["red"], rng,
              w=0.5)
    top = by - h
    shape(ctx, [(x - r1 - 1, top), (x + r1 + 1, top), (x + r1, top - 5 * s), (x - r1, top - 5 * s)], (0.98, 0.84, 0.40),
          rng, w=0.7)
    shape(ctx, [(x - r1 - 1, top - 5 * s), (x + r1 + 1, top - 5 * s), (x, top - 10 * s)], C["red"], rng, w=0.7)
    for a in np.linspace(-0.5, 0.5, 5):
        ink(ctx, [(x + math.cos(a) * 8 * s, top - 2.5 * s + math.sin(a) * 8 * s),
                  (x + math.cos(a) * 15 * s, top - 2.5 * s + math.sin(a) * 15 * s)], rng, 0.5, closed=False, amp=0.1,
            color=(0.85, 0.62, 0.20))


def mine_mouth(ctx, rng, x, by, s=1.0):
    """Kayaya açılmış ocak ağzı: dikme-kiriş çerçeve, dışarı uzanan ray, cüruf yığını."""
    mountain(ctx, rng, x - 4 * s, by, 34 * s, 20 * s, color=(0.70, 0.62, 0.55))
    ax, ay = x - 4 * s, by - 2 * s
    path(ctx, [(ax - 4 * s, ay), (ax - 4 * s, ay - 6 * s), (ax, ay - 9 * s), (ax + 4 * s, ay - 6 * s),
               (ax + 4 * s, ay)])
    ctx.set_source_rgba(*INK, 0.95)
    ctx.fill()
    ink(ctx, [(ax - 4.6 * s, ay), (ax - 4.6 * s, ay - 7 * s), (ax + 4.6 * s, ay - 7 * s), (ax + 4.6 * s, ay)], rng,
        1.2 * s, closed=False, amp=0.1, color=C["timber"])
    ink(ctx, [(ax - 1.5 * s, ay), (ax + 8 * s, ay + 7 * s)], rng, 0.6, closed=False, amp=0.1)
    ink(ctx, [(ax + 1.5 * s, ay), (ax + 11 * s, ay + 6 * s)], rng, 0.6, closed=False, amp=0.1)
    shape(ctx, [(ax + 7 * s, ay + 6 * s), (ax + 11 * s, ay + 4 * s), (ax + 12 * s, ay + 6.5 * s), (ax + 8 * s, ay + 8.5 * s)],
          C["timber"], rng, w=0.6)
    heap = [(x + 10 * s, by + 4)] + [(x + 10 * s + 9 * s * math.cos(a), by + 4 - 6 * s * math.sin(a)) for a in
                                    np.linspace(0, math.pi, 9)]
    shape(ctx, heap, (0.52, 0.48, 0.44), rng, hatch_angle=1.1, hatch_sp=1.4, w=0.7)
