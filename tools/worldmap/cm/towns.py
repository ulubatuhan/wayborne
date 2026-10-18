"""Kültüre göre yerleşim simgeleri. Her kültür siluet, renk ve bir ayırt
edici eşyayla ayrılır; düzen (sur halkası, tepeye tırmanan evler, ortada
bir simge yapı) bütün kentlerde ortak, böylece harita tek elden çıkmış okur.
"""
import math

import numpy as np

import build as B
from build import C
from hand import ellipse_pts, ink, shape, darker

STYLE = {
    "vadi": dict(stone=(0.90, 0.81, 0.64), cap="cone", cap_color=C["red"], palisade=False,
                 walls=[C["ochre"], C["white"], (0.93, 0.78, 0.58)], roofs=[C["red"], C["red"], (0.72, 0.40, 0.25)],
                 kind=("eave", 0.75), pitch=(0.55, 0.8), tall=(5.5, 7.5), flag=C["banner_vadi"], tree="cypress",
                 timber=0.0, flat=0.0),
    "ahit": dict(stone=(0.91, 0.89, 0.83), cap="spire", cap_color=C["slate"], palisade=False,
                 walls=[C["white"], C["pale"], (0.95, 0.93, 0.86)], roofs=[C["slate"], (0.36, 0.42, 0.52)],
                 kind=("gable", 0.8), pitch=(1.1, 1.5), tall=(7.0, 10.0), flag=C["banner_ahit"], tree="leaf",
                 timber=0.0, flat=0.0, narrow=True),
    "sinir": dict(stone=C["timber"], cap="cone", cap_color=C["shingle"], palisade=True,
                  walls=[C["white"], (0.93, 0.90, 0.80)], roofs=[C["shingle"], C["straw"], (0.52, 0.38, 0.26)],
                  kind=("gable", 0.65), pitch=(0.9, 1.2), tall=(5.0, 6.5), flag=C["banner_sinir"], tree="leaf",
                  timber=0.7, flat=0.0),
    "imparatorluk": dict(stone=C["grey"], cap="crenel", cap_color=None, palisade=False,
                         walls=[(0.78, 0.77, 0.74), (0.86, 0.85, 0.82)], roofs=[(0.28, 0.30, 0.36), (0.36, 0.38, 0.44)],
                         kind=("gable", 0.5), pitch=(1.3, 1.7), tall=(6.5, 8.5), flag=C["banner_imp"], tree="conifer",
                         timber=0.0, flat=0.0, square=True),
    "guney": dict(stone=(0.95, 0.92, 0.84), cap="crenel", cap_color=None, palisade=False,
                  walls=[C["white"], (0.97, 0.90, 0.78), (0.92, 0.84, 0.72)], roofs=[(0.86, 0.78, 0.62)],
                  kind=("eave", 1.0), pitch=(0.4, 0.5), tall=(5.0, 8.0), flag=(0.20, 0.42, 0.62), tree="cypress",
                  timber=0.0, flat=0.85),
    "dag": dict(stone=(0.58, 0.56, 0.52), cap="cone", cap_color=C["sod"], palisade=True,
                walls=[(0.52, 0.38, 0.26), (0.48, 0.34, 0.22)], roofs=[C["sod"], (0.50, 0.58, 0.34)],
                kind=("eave", 0.8), pitch=(0.6, 0.8), tall=(4.0, 5.0), flag=(0.55, 0.30, 0.18), tree="conifer",
                timber=0.0, flat=0.0),
}
STYLE["dag_maden"] = STYLE["dag"]


def _house_args(st, rng, scale=1.0):
    narrow = st.get("narrow")
    w = (7.0 + 4.0 * rng.random()) * (0.8 if narrow else 1.0) * scale
    h = (st["tall"][0] + (st["tall"][1] - st["tall"][0]) * rng.random()) * scale
    rh = w * (st["pitch"][0] + (st["pitch"][1] - st["pitch"][0]) * rng.random())
    kind = "eave" if (rng.random() < st["kind"][1]) == (st["kind"][0] == "eave") else "gable"
    return dict(w=w, d=w * (0.7 + 0.3 * rng.random()), h=h, rh=rh, kind=kind,
                wall=st["walls"][rng.integers(len(st["walls"]))], roof=st["roofs"][rng.integers(len(st["roofs"]))],
                timber=rng.random() < st["timber"], flat=rng.random() < st["flat"],
                chimney=(0.55, 0.36, 0.26) if rng.random() < 0.35 else None)


def _place(rng, cx, cy, rx, ry, n, hole=(0, 0), sep=(11.0, 5.5), tries=4000):
    pts = []
    for _ in range(tries):
        a = rng.random() * 2 * math.pi
        r = math.sqrt(rng.random())
        x, y = cx + rx * r * math.cos(a), cy + ry * r * math.sin(a)
        if hole[0] and ((x - cx) / hole[0]) ** 2 + ((y - cy) / hole[1]) ** 2 < 1:
            continue
        if all(((x - a2) / sep[0]) ** 2 + ((y - b2) / sep[1]) ** 2 > 1 for a2, b2 in pts):
            pts.append((x, y))
        if len(pts) >= n:
            break
    return pts


def landmark(ctx, rng, culture, x, y, s):
    st = STYLE[culture]
    if culture == "vadi":
        # saray: geniş salon, iki yuvarlak kule, kırmızı külahlar, sancak
        B.round_tower(ctx, rng, x - 13 * s, y - 2, 4.2 * s, 22 * s, st["walls"][0], "cone", C["red"])
        B.house(ctx, rng, x, y, 22 * s, 12 * s, 11 * s, 9 * s, C["ochre"], C["red"], "eave")
        B.round_tower(ctx, rng, x + 13 * s, y + 1, 4.6 * s, 26 * s, st["walls"][0], "cone", C["red"],
                      flag=st["flag"])
    elif culture == "ahit":
        # büyük ibadethane: uzun nef, önünde göğe uzanan tek iğne kule
        B.house(ctx, rng, x + 4 * s, y - 3, 26 * s, 12 * s, 13 * s, 10 * s, C["white"], C["slate"], "eave")
        B.round_tower(ctx, rng, x + 18 * s, y - 1, 2.6 * s, 18 * s, C["white"], "spire", C["slate"], cap_h=14 * s)
        B.square_tower(ctx, rng, x - 10 * s, y + 2, 9 * s, 34 * s, C["white"], roof=C["slate"], roof_h=34 * s)
    elif culture == "sinir":
        # ahşap kale: yüksek kule, uzun salon, kazık iskele
        B.house(ctx, rng, x + 6 * s, y, 20 * s, 10 * s, 9 * s, 11 * s, C["white"], C["shingle"], "eave", timber=True)
        B.square_tower(ctx, rng, x - 10 * s, y + 3, 8 * s, 28 * s, C["timber"], roof=C["shingle"], roof_h=10 * s,
                       flag=st["flag"])
    elif culture == "imparatorluk":
        B.square_tower(ctx, rng, x - 9 * s, y, 11 * s, 30 * s, C["grey"], flag=st["flag"])
        B.house(ctx, rng, x + 8 * s, y + 2, 16 * s, 10 * s, 12 * s, 14 * s, (0.80, 0.79, 0.76), (0.28, 0.30, 0.36),
                "gable")
    elif culture == "guney":
        B.house(ctx, rng, x, y, 24 * s, 12 * s, 12 * s, 4, C["white"], (0.86, 0.78, 0.62), flat=True)
        B.round_tower(ctx, rng, x + 14 * s, y + 2, 3.6 * s, 26 * s, C["white"], "crenel", flag=st["flag"])
    else:
        B.house(ctx, rng, x, y, 16 * s, 9 * s, 6 * s, 9 * s, st["walls"][0], st["roofs"][0], "eave")


def city(ctx, rng, cx, cy, culture, rx, walled=True, lift=8.0, n_houses=None, gate_flag=True):
    st = STYLE[culture]
    ry = rx * 0.42
    wh = 7.0 if not st["palisade"] else 6.0
    if walled:
        B.wall_ring(ctx, rng, cx, cy, rx, ry, wh, st["stone"], "back", towers=max(6, int(rx / 11)),
                    cap=st["cap"], cap_color=st["cap_color"], palisade=st["palisade"])
    n = n_houses or int(rx * 0.55)
    s = rx / 100.0 + 0.45
    pts = _place(rng, cx, cy, rx * 0.84, ry * 0.8, n, hole=(rx * 0.30, ry * 0.42))
    items = [(y, "h", x) for x, y in pts]
    items.append((cy + 2, "L", cx))
    for y, k, x in sorted(items):
        d2 = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
        up = lift * max(0.0, 1 - d2)
        if k == "L":
            landmark(ctx, rng, culture, x, y - lift, s)
            continue
        if rng.random() < 0.08:
            _tree(ctx, rng, st, x, y - up, 0.75)
            continue
        a = _house_args(st, rng, 0.95 + 0.25 * (1 - d2))
        B.house(ctx, rng, x, y - up, a["w"], a["d"], a["h"], a["rh"], a["wall"], a["roof"], a["kind"],
                timber=a["timber"], chimney=a["chimney"], flat=a["flat"])
    if walled:
        B.wall_ring(ctx, rng, cx, cy, rx, ry, wh, st["stone"], "front", towers=max(6, int(rx / 11)),
                    cap=st["cap"], cap_color=st["cap_color"], palisade=st["palisade"],
                    flag=st["flag"] if gate_flag else None)
    return ry


def _tree(ctx, rng, st, x, y, s):
    if st["tree"] == "cypress":
        B.cypress(ctx, rng, x, y, s)
    elif st["tree"] == "conifer":
        B.tree(ctx, rng, x, y, s, "conifer")
    else:
        B.tree(ctx, rng, x, y, s)


def village(ctx, rng, cx, cy, culture, n=4, spread=22):
    st = STYLE[culture]
    pts = _place(rng, cx, cy, spread, spread * 0.45, n, sep=(10, 5))
    for x, y in sorted(pts, key=lambda p: p[1]):
        if rng.random() < 0.2:
            _tree(ctx, rng, st, x, y, 0.8)
            continue
        a = _house_args(st, rng, 0.85)
        B.house(ctx, rng, x, y, a["w"], a["d"], a["h"], a["rh"], a["wall"], a["roof"], a["kind"],
                timber=a["timber"], chimney=a["chimney"], flat=a["flat"])


def abbey(ctx, rng, cx, cy, culture):
    st = STYLE.get(culture, STYLE["ahit"])
    rx, ry = 22, 9
    B.wall_ring(ctx, rng, cx, cy, rx, ry, 4, st["stone"], "back", towers=0, cap=None)
    B.house(ctx, rng, cx + 6, cy - 2, 14, 7, 7, 6, C["white"], C["slate"], "eave")
    B.square_tower(ctx, rng, cx - 8, cy, 5.5, 18, C["white"], roof=C["slate"], roof_h=16)
    for i in range(4):
        ink(ctx, [(cx - 14 + i * 5, cy + 6), (cx - 11 + i * 5, cy + 6)], rng, 1.2, closed=False, amp=0.1,
            color=C["green"])
    B.wall_ring(ctx, rng, cx, cy, rx, ry, 4, st["stone"], "front", towers=0, cap=None)


def lumber(ctx, rng, cx, cy, culture):
    B.tree(ctx, rng, cx - 16, cy - 5, 0.9, "conifer")
    B.house(ctx, rng, cx - 4, cy - 2, 10, 7, 5, 6, (0.55, 0.40, 0.26), C["shingle"], "gable")
    B.house(ctx, rng, cx + 9, cy + 1, 8, 6, 4.5, 5, (0.55, 0.40, 0.26), C["shingle"], "eave")
    for i, (dx, dy) in enumerate([(0, 0), (3, 0), (6, 0), (1.5, -2.6), (4.5, -2.6), (3, -5.2)]):
        ctx_x, ctx_y = cx + 14 + dx, cy + 9 + dy
        shape(ctx, list(ellipse_pts(ctx_x, ctx_y, 1.6, 1.6, 0, 2 * math.pi, 10)), (0.78, 0.62, 0.42), rng, w=0.6)
    for k in range(3):
        x = cx - 10 + k * 7 + rng.random() * 3
        shape(ctx, [(x - 1.5, cy + 10), (x + 1.5, cy + 10), (x + 1.5, cy + 8), (x - 1.5, cy + 8)], (0.70, 0.55, 0.38),
              rng, w=0.6)


def swamp_town(ctx, rng, cx, cy, culture):
    st = STYLE[culture]
    for i in range(5):
        x = cx - 26 + i * 13 + rng.random() * 4
        y = cy - 4 + (i % 2) * 7
        shape(ctx, list(ellipse_pts(x, y + 1, 7, 2.2, 0, 2 * math.pi, 16)), (0.55, 0.68, 0.66), rng, w=0.6, alpha=0.7)
    pts = _place(rng, cx, cy, 26, 10, 6, sep=(11, 5))
    for x, y in sorted(pts, key=lambda p: p[1]):
        a = _house_args(st, rng, 0.85)
        B.house(ctx, rng, x, y, a["w"], a["d"], a["h"], a["rh"], a["wall"], C["straw"], a["kind"], timber=a["timber"],
                stilts=3.5)
    for i in range(10):
        x, y = cx - 30 + rng.random() * 60, cy + 6 + rng.random() * 8
        for k in range(3):
            ink(ctx, [(x + k, y), (x + k * 1.6 - 1.5, y - 4 - rng.random() * 2)], rng, 0.5, closed=False, amp=0.1)


def farm(ctx, rng, cx, cy, culture):
    st = STYLE[culture]
    for r in range(4):
        y = cy + 8 + r * 3.2
        for i in range(9):
            x = cx - 26 + i * 3.4 + (r % 2) * 1.5
            ink(ctx, [(x, y), (x, y - 2.2)], rng, 0.6, closed=False, amp=0.05)
            shape(ctx, B.blob(x, y - 2.6, 1.1, rng, 4, 0.2), C["green"], rng, w=0.4)
    B.house(ctx, rng, cx - 8, cy, 11, 7, 6, 6, st["walls"][0], st["roofs"][0], "eave", chimney=(0.55, 0.36, 0.26))
    B.windmill(ctx, rng, cx + 14, cy - 2, 0.85)


def tower_post(ctx, rng, cx, cy, culture):
    st = STYLE.get(culture, STYLE["imparatorluk"])
    B.square_tower(ctx, rng, cx, cy, 8, 24, st["stone"] if not st["palisade"] else C["timber"], flag=st["flag"])


def stones(ctx, rng, cx, cy):
    for a in sorted(np.linspace(0, 2 * math.pi, 7, endpoint=False), key=lambda a: math.sin(a)):
        B.standing_stone(ctx, rng, cx + 13 * math.cos(a), cy + 5 * math.sin(a), 0.9)


def gallows(ctx, rng, cx, cy):
    ink(ctx, [(cx - 5, cy), (cx - 5, cy - 18), (cx + 6, cy - 18)], rng, 1.4, closed=False, amp=0.2)
    ink(ctx, [(cx - 5, cy - 13), (cx, cy - 18)], rng, 0.9, closed=False, amp=0.1)
    ink(ctx, [(cx + 4, cy - 18), (cx + 4, cy - 12)], rng, 0.6, closed=False, amp=0.1)
    shape(ctx, list(ellipse_pts(cx + 4, cy - 11, 1.3, 1.6, 0, 2 * math.pi, 10)), (0.6, 0.5, 0.4), rng, w=0.5)
    shape(ctx, list(ellipse_pts(cx, cy + 1, 8, 2.5, 0, 2 * math.pi, 14)), (0.62, 0.55, 0.42), rng, w=0.5, alpha=0.6)


def battle(ctx, rng, cx, cy):
    for k in range(3):
        x = cx - 9 + k * 9
        shape(ctx, list(ellipse_pts(x, cy + 2, 4, 1.5, math.pi, 2 * math.pi, 10)) + [(x + 4, cy + 2)],
              (0.62, 0.56, 0.42), rng, w=0.5)
    ink(ctx, [(cx - 8, cy + 2), (cx + 6, cy - 16)], rng, 0.9, closed=False, amp=0.1)
    ink(ctx, [(cx + 8, cy + 2), (cx - 6, cy - 16)], rng, 0.9, closed=False, amp=0.1)
    for (x, y, ux, uy) in [(cx + 6, cy - 16, 0.6, -0.8), (cx - 6, cy - 16, -0.6, -0.8)]:
        shape(ctx, [(x - uy * 1.2, y + ux * 1.2), (x + ux * 4, y + uy * 4), (x + uy * 1.2, y - ux * 1.2)],
              (0.75, 0.75, 0.78), rng, w=0.5)


def camp(ctx, rng, cx, cy, culture="gocebe", n=6):
    pts = _place(rng, cx, cy, 26, 11, n, sep=(13, 6))
    for x, y in sorted(pts, key=lambda p: p[1]):
        B.yurt(ctx, rng, x, y, 5.5 + rng.random() * 1.5)
    B.banner(ctx, rng, cx + 18, cy - 4, 16, (0.62, 0.22, 0.18))


def fish_village(ctx, rng, cx, cy, culture, terr=None, scale=1.0):
    st = STYLE.get(culture, STYLE["sinir"])
    for i in range(2):
        x = cx - 22 + i * 8
        ink(ctx, [(x, cy + 2), (x, cy - 7), (x + 6, cy - 7), (x + 6, cy + 2)], rng, 0.6, closed=False, amp=0.1)
        for k in range(4):
            ink(ctx, [(x + 0.5 + k * 1.5, cy - 7), (x + 1 + k * 1.5, cy - 1)], rng, 0.35, closed=False, amp=0.15,
                alpha=0.7)
    village(ctx, rng, cx + 6, cy - 4, culture, n=5, spread=20)


def mine_town(ctx, rng, cx, cy, culture):
    B.mine_mouth(ctx, rng, cx + 20, cy - 10, 1.0)
    village(ctx, rng, cx - 6, cy + 2, culture, n=6, spread=20)


def lighthouse(ctx, rng, cx, cy, culture):
    B.lighthouse(ctx, rng, cx, cy, 1.0)


def deep_mine(ctx, rng, cx, cy, culture):
    B.mine_mouth(ctx, rng, cx, cy, 1.0)


def hill_fort(ctx, rng, cx, cy, culture):
    st = STYLE.get(culture, STYLE["dag"])
    B.mountain(ctx, rng, cx, cy + 6, 70, 22, color=(0.80, 0.66, 0.52))
    village(ctx, rng, cx - 4, cy - 2, culture, n=6, spread=18)
    if st.get("square"):
        B.square_tower(ctx, rng, cx + 14, cy - 4, 8, 22, st["stone"], flag=st["flag"])
    else:
        B.round_tower(ctx, rng, cx + 14, cy - 4, 4, 20, st["stone"], cap=st["cap"], cap_color=st["cap_color"],
                      flag=st["flag"])
