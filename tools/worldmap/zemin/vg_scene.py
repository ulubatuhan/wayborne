"""referans oyun denemesi, adım 4: Blender'da tepeden, alçak güneşli render.

Arazi = yükseklik ağı + albedo dokusu; ağaçlar, evler, surlar, kuleler, yurtlar
birleştirilmiş tek ağlar (malzeme başına). Ortografik kamera tam tepeden; güneş
kuzeybatıdan alçak - dağı ve şehri okutan gölge buradan.

    python3 -I vg_scene.py <vg klasörü> <layout.json> [samples] [res]
"""
import json
import math
import os
import sys

import bpy
import numpy as np
from scipy import ndimage as ndi

VG = sys.argv[1]
LAYOUT = sys.argv[2]
SAMPLES = int(sys.argv[3]) if len(sys.argv) > 3 else 24
RES = int(sys.argv[4]) if len(sys.argv) > 4 else 2048

F = np.load(os.path.join(VG, "fields.npz"))
X0, Y0, S = int(F["x0"]), int(F["y0"]), int(F["size"])
H = F["height"]
WET = F["water"] > 0.5 if "water" in F.files else None
HALF = S / 2
GRID = int(min(1500, S / 1.3))

MATS = {
    "terrain": None,
    "conifer": (0.10, 0.12, 0.08),
    "leaf": (0.15, 0.15, 0.09),
    "bush": (0.13, 0.13, 0.09),
    "plaster": (0.30, 0.28, 0.24),
    "roof_a": (0.24, 0.13, 0.09),
    "roof_b": (0.20, 0.17, 0.14),
    "thatch": (0.38, 0.31, 0.20),
    "stone": (0.33, 0.31, 0.28),
    "stone_dark": (0.12, 0.115, 0.11),
    "wood": (0.20, 0.13, 0.08),
    "felt": (0.46, 0.42, 0.35),
    "felt_dark": (0.36, 0.27, 0.18),
    "crown": (0.10, 0.08, 0.06),
    "mud": (0.20, 0.16, 0.11),
    "horse": (0.16, 0.11, 0.07),
    "field_a": (0.22, 0.20, 0.12),
    "field_b": (0.15, 0.15, 0.09),
    "field_c": (0.19, 0.16, 0.10),
    # kültür üslupları: yalnızca renk, çatı biçimi, kule biçimi
    "plaster_grey": (0.27, 0.27, 0.27),
    "slate": (0.10, 0.11, 0.13),
    "plaster_warm": (0.36, 0.30, 0.22),
    "tile_red": (0.30, 0.11, 0.07),
    "plaster_pale": (0.44, 0.41, 0.35),
    "flat_roof": (0.35, 0.31, 0.25),
    "timber_dark": (0.13, 0.09, 0.06),
    "sod": (0.15, 0.17, 0.09),
    "stone_pale": (0.45, 0.43, 0.39),
    "hull": (0.16, 0.10, 0.06),
    "sail": (0.66, 0.61, 0.50),
    "wake": (0.075, 0.085, 0.09),
}

# kültür: duvar, çatı malzemeleri, çatı biçimi, eğim (genişliğe oran), kule biçimi
STYLE = {
    "imparatorluk": dict(wall="plaster_grey", roofs=("slate",), roof="gable", pitch=0.70, tower="square",
                         stone="stone_dark"),
    "vadi": dict(wall="plaster_warm", roofs=("tile_red", "tile_red", "roof_a"), roof="hip", pitch=0.32,
                 tower="round"),
    "guney": dict(wall="plaster_pale", roofs=("flat_roof",), roof="flat", pitch=0.0, tower="round"),
    "dag": dict(wall="timber_dark", roofs=("sod",), roof="gable", pitch=0.62, tower="square"),
    "dag_maden": dict(wall="timber_dark", roofs=("sod", "roof_b"), roof="gable", pitch=0.62, tower="square"),
    "ahit": dict(wall="stone_pale", roofs=("roof_b", "stone"), roof="gable", pitch=0.55, tower="round",
                 stone="stone_pale"),
}


def hs(px, py):
    """Harita pikselinde yükseklik (bilinear)."""
    x, y = px - X0, py - Y0
    return float(ndi.map_coordinates(H, [[np.clip(y, 0, S - 1)], [np.clip(x, 0, S - 1)]], order=1)[0])


def wet(px, py):
    """Bu harita noktası suda mı (bölge maskesi)."""
    if WET is None:
        return False
    x, y = int(round(px - X0)), int(round(py - Y0))
    if not (0 <= x < S and 0 <= y < S):
        return False
    return bool(WET[y, x])


def seg_wet(a, b, steps=8):
    return any(wet(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t) for t in np.linspace(0, 1, steps))


def bx(px):
    return px - X0 - HALF


def by(py):
    return HALF - (py - Y0)


class Acc:
    """Malzeme başına birleştirilmiş ağ biriktirici."""

    def __init__(self):
        self.v, self.f = {}, {}

    def add(self, mat, verts, faces):
        vs = self.v.setdefault(mat, [])
        fs = self.f.setdefault(mat, [])
        off = sum(len(a) for a in vs)
        vs.append(np.asarray(verts, np.float64))
        fs.extend([[i + off for i in face] for face in faces])

    def build(self):
        for mat, vs in self.v.items():
            verts = np.concatenate(vs)
            me = bpy.data.meshes.new(mat)
            me.from_pydata(verts.tolist(), [], self.f[mat])
            me.update()
            ob = bpy.data.objects.new(mat, me)
            ob.data.materials.append(material(mat))
            bpy.context.collection.objects.link(ob)


_mat_cache = {}


def material(name):
    if name in _mat_cache:
        return _mat_cache[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.95
    if name == "terrain":
        tex = m.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(os.path.join(VG, "albedo.png"))
        tex.interpolation = "Cubic"
        m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        c = MATS[name]
        bsdf.inputs["Base Color"].default_value = (*c, 1)
    _mat_cache[name] = m
    return m


def rot(u, x, y):
    """Yerel (x boyuna, y enine) -> blender düzlemi; u harita uzayında birim yön."""
    ux, uy = u[0], -u[1]
    return x * ux - y * uy, x * uy + y * ux


def box(cx, cy, z, L, W, h, u=(1, 0)):
    pts = []
    for zz in (z, z + h):
        for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            dx, dy = rot(u, sx * L / 2, sy * W / 2)
            pts.append((cx + dx, cy + dy, zz))
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return pts, faces


def gable(cx, cy, z, L, W, h, u=(1, 0)):
    """Beşik çatı: sırt u boyunca."""
    pts = []
    for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        dx, dy = rot(u, sx * L / 2, sy * W / 2)
        pts.append((cx + dx, cy + dy, z))
    for sx in (-1, 1):
        dx, dy = rot(u, sx * L / 2, 0)
        pts.append((cx + dx, cy + dy, z + h))
    faces = [(0, 1, 5, 4), (2, 3, 4, 5), (0, 4, 3), (1, 2, 5), (0, 3, 2, 1)]
    return pts, faces


def hip(cx, cy, z, L, W, h, u=(1, 0)):
    """Kırma çatı: sırt kısa, dört yüz eğik."""
    pts = []
    for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        dx, dy = rot(u, sx * L / 2, sy * W / 2)
        pts.append((cx + dx, cy + dy, z))
    r = max(0.0, L / 2 - W / 2)
    for sx in (-1, 1):
        dx, dy = rot(u, sx * r, 0)
        pts.append((cx + dx, cy + dy, z + h))
    faces = [(0, 1, 5, 4), (2, 3, 4, 5), (0, 4, 3), (1, 2, 5), (0, 3, 2, 1)]
    return pts, faces


def hull(cx, cy, z, L, W, h, u=(1, 0)):
    """Gövde: sivri pruva, kesik kıç, tabana doğru daralan."""
    prof = [(-0.5, -0.38), (0.22, -0.5), (0.5, 0.0), (0.22, 0.5), (-0.5, 0.38)]
    pts = []
    for zz, k in ((z, 0.62), (z + h, 1.0)):
        for px, py in prof:
            dx, dy = rot(u, px * L * (1.0 if zz > z else 0.86), py * W * k)
            pts.append((cx + dx, cy + dy, zz))
    n = len(prof)
    faces = [tuple(range(n))[::-1], tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    return pts, faces


def ship(acc, s):
    """Büyük gemi: gövde, iki direk, rüzgârla şişen kare yelkenler.
    Küçük tekne: gövde ve tek üçgen yelken."""
    c, u = s["c"], s["u"]
    if not wet(*c):
        return  # bu karonun dışında ya da karada
    x, y = bx(c[0]), by(c[1])
    if s["size"] == "big":
        L, W = 40.0, 10.0
        wx, wy = rot(u, -L * 0.9, 0)
        acc.add("wake", *hull(x + wx, y + wy, -0.9, L * 1.3, W * 0.9, 0.95, u))
        acc.add("hull", *hull(x, y, -0.6, L, W, 2.8, u))
        acc.add("wood", *box(x - rot(u, L * 0.30, 0)[0], y - rot(u, L * 0.30, 0)[1], 2.0, 6.0, W * 0.8, 1.6, u))
        for off, sw in ((0.16, 1.0), (-0.12, 0.85)):
            mx, my = rot(u, L * off, 0)
            acc.add("wood", *box(x + mx, y + my, 2.0, 0.7, 0.7, 20))
            # yelken: direğe dik, rüzgâra hafif kıvrık (iki levha)
            for k, zz in ((0.0, 7.0), (0.6, 13.5)):
                sx, sy = rot(u, L * off + 0.8 + k, 0)
                acc.add("sail", *box(x + sx, y + sy, zz, 3.4, W * 1.5 * sw * (1 - 0.15 * k), 5.5, u))
    else:
        L, W = 11.0, 3.6
        wx, wy = rot(u, -L * 0.8, 0)
        acc.add("wake", *hull(x + wx, y + wy, -0.9, L * 1.1, W * 0.8, 0.95, u))
        acc.add("hull", *hull(x, y, -0.4, L, W, 1.4, u))
        mx, my = rot(u, L * 0.1, 0)
        acc.add("wood", *box(x + mx, y + my, 0.9, 0.4, 0.4, 7))
        sx, sy = rot(u, L * 0.1 - 1.4, 0.6)
        acc.add("sail", *box(x + sx, y + sy, 1.6, 4.0, 1.6, 4.6, u))


def cyl(cx, cy, z, r, h, n=12, cap_h=0.0):
    pts = []
    for zz in (z, z + h):
        for i in range(n):
            a = 2 * math.pi * i / n
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a), zz))
    faces = [tuple(range(n))[::-1]]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    if cap_h > 0:
        pts.append((cx, cy, z + h + cap_h))
        top = len(pts) - 1
        for i in range(n):
            faces.append((n + i, n + (i + 1) % n, top))
    else:
        faces.append(tuple(range(n, 2 * n)))
    return pts, faces


def cone(cx, cy, z, r, h, n=7):
    pts = [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n), z) for i in range(n)]
    pts.append((cx, cy, z + h))
    faces = [tuple(range(n))[::-1]] + [(i, (i + 1) % n, n) for i in range(n)]
    return pts, faces


def blob(cx, cy, z, r, hz, rng):
    """Kaba yaprak tacı: düzensiz sekizyüzlü-kubbe."""
    n = 7
    pts = []
    for ring, (rr, zz) in enumerate(((1.0, 0.25), (0.75, 0.75))):
        for i in range(n):
            a = 2 * math.pi * (i + 0.5 * ring) / n
            k = rr * (0.8 + 0.4 * rng.random())
            pts.append((cx + r * k * math.cos(a), cy + r * k * math.sin(a), z + hz * zz))
    pts.append((cx, cy, z + hz))
    pts.append((cx, cy, z))
    top, bot = 2 * n, 2 * n + 1
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces.append((bot, j, i))
        faces.append((i, j, n + i))
        faces.append((j, n + j, n + i))
        faces.append((n + i, n + j, top))
    return pts, faces


def terrain():
    g = GRID
    Hs = ndi.zoom(H, g / S, order=1)
    xs = np.linspace(-HALF, HALF, g)
    ys = np.linspace(HALF, -HALF, g)
    X, Y = np.meshgrid(xs, ys)
    verts = np.stack([X.ravel(), Y.ravel(), Hs.ravel()], 1)
    idx = np.arange(g * g).reshape(g, g)
    a, b, c, d = idx[:-1, :-1], idx[:-1, 1:], idx[1:, 1:], idx[1:, :-1]
    faces = np.stack([a.ravel(), d.ravel(), c.ravel(), b.ravel()], 1)
    me = bpy.data.meshes.new("terrain")
    me.vertices.add(len(verts))
    me.vertices.foreach_set("co", verts.ravel())
    me.loops.add(faces.size)
    me.loops.foreach_set("vertex_index", faces.ravel())
    me.polygons.add(len(faces))
    me.polygons.foreach_set("loop_start", np.arange(0, faces.size, 4))
    me.polygons.foreach_set("loop_total", np.full(len(faces), 4))
    uv = me.uv_layers.new()
    vi = faces.ravel()
    uvs = np.stack([(verts[vi, 0] + HALF) / S, (verts[vi, 1] + HALF) / S], 1)
    uv.data.foreach_set("uv", uvs.ravel())
    me.update()
    me.polygons.foreach_set("use_smooth", np.ones(len(faces), bool))
    ob = bpy.data.objects.new("terrain", me)
    ob.data.materials.append(material("terrain"))
    bpy.context.collection.objects.link(ob)


def trees(acc):
    rng = np.random.default_rng(3)
    for x, y, kind in json.load(open(os.path.join(VG, "trees.json"))):
        px, py = x + X0, y + Y0
        z = hs(px, py) - 0.3
        cx, cy = x - HALF, HALF - y
        s = 0.75 + 0.5 * rng.random()
        if kind == 1:
            acc.add("conifer", *cone(cx, cy, z, 3.4 * s, 11.0 * s))
        elif kind == 0:
            acc.add("leaf", *blob(cx, cy, z + 1.0, 4.4 * s, 6.5 * s, rng))
        else:
            acc.add("bush", *blob(cx, cy, z, 1.7 * s, 1.6 * s, rng))


def yurt(acc, c, r, rng, mat="felt", pole=False):
    """Yurt: alçak duvar, sığ konik keçe çatı, tepede koyu halka (tünük),
    güneye bakan küçük kapı. Tepeden bakınca halka ve kapı onu çadırdan,
    çatısının konisi de tepecikten ayırıyor."""
    x, y = bx(c[0]), by(c[1])
    z = hs(*c) - 0.2
    wall = r * 0.42
    acc.add(mat, *cyl(x, y, z, r, wall, 16, cap_h=r * 0.38))
    acc.add("crown", *cyl(x, y, z + wall + r * 0.30, r * 0.20, 0.15, 10))
    acc.add("wood", *box(x, y - r * 0.98, z, r * 0.36, 0.9, wall * 0.9))
    if pole:
        acc.add("wood", *box(x + r * 1.25, y + r * 0.2, z, 0.8, 0.8, 16))
        acc.add("roof_a", *box(x + r * 1.25 + 2.2, y + r * 0.2, z + 12.5, 4.0, 0.3, 3.0))


def pen_draw(acc, pen, rng):
    """Ağıl: çiğnenmiş toprak, kazık sırası (sürekli halka değil) ve içinde atlar."""
    c, r = pen["c"], pen["r"] * 0.85
    x, y = bx(c[0]), by(c[1])
    z = hs(*c)
    acc.add("mud", *cyl(x, y, z - 0.25, r, 0.35, 18))
    n = max(10, int(2 * math.pi * r / 3.2))
    for i in range(n):
        if i == 0:
            continue  # giriş
        a = 2 * math.pi * i / n
        acc.add("wood", *box(x + r * math.cos(a), y + r * math.sin(a), z - 0.2, 0.9, 0.9, 1.8))
    for _ in range(int(pen.get("horses", 2))):
        a = rng.random() * 2 * math.pi
        d = r * 0.45 * rng.random()
        hx, hy = x + d * math.cos(a), y + d * math.sin(a)
        ang = rng.random() * 2 * math.pi
        u = (math.cos(ang), -math.sin(ang))
        acc.add("horse", *box(hx, hy, z + 0.1, 3.6, 1.3, 1.6, u))


def settlements(acc):
    rng = np.random.default_rng(9)
    for e in json.load(open(LAYOUT)):
        if e["kind"] == "x_ships":
            for s_ in e["ships"]:
                ship(acc, s_)
            continue
        cx, cy = e["center"]
        if not (X0 - 80 < cx < X0 + S + 80 and Y0 - 80 < cy < Y0 + S + 80):
            continue
        st = STYLE.get(e.get("culture"))
        for hsx in e.get("houses", []):
            c, u = hsx["c"], hsx["u"]
            if wet(*c):
                continue
            z = hs(*c) - 0.5
            wall_h = 4.0 + rng.random() * 1.5
            X, Y, L, W = bx(c[0]), by(c[1]), hsx["L"], hsx["W"]
            if st is None:
                acc.add("plaster", *box(X, Y, z, L, W, wall_h + 0.5, u))
                roof = ("roof_a", "roof_b", "thatch")[hsx.get("roof", 0) % 3] if e["kind"].startswith("ic") else "thatch"
                acc.add(roof, *gable(X, Y, z + wall_h + 0.5, L + 1.2, W + 1.2, W * 0.45, u))
                continue
            roof = st["roofs"][hsx.get("roof", 0) % len(st["roofs"])]
            if st["roof"] == "flat":
                acc.add(st["wall"], *box(X, Y, z, L, W, wall_h + 0.5, u))
                acc.add(roof, *box(X, Y, z + wall_h + 0.5, L + 0.6, W + 0.6, 0.6, u))
                if hsx.get("roof", 0) % 3 == 0:  # çatı köşkü
                    ox, oy = rot(u, L * 0.25, 0)
                    acc.add(st["wall"], *box(X + ox, Y + oy, z + wall_h + 1.1, L * 0.35, W * 0.6, 2.4, u))
                continue
            acc.add(st["wall"], *box(X, Y, z, L, W, wall_h + 0.5, u))
            fn = hip if st["roof"] == "hip" else gable
            acc.add(roof, *fn(X, Y, z + wall_h + 0.5, L + 1.2, W + 1.2, W * st["pitch"], u))
        mat = {"dark": "stone_dark", "stone": "stone", "wood": "wood"}[e.get("material", "wood")]
        wh = {"stone_dark": 9.0, "stone": 8.0, "wood": 6.0}[mat]
        if st and st.get("stone") and mat != "wood":
            mat = st["stone"]
        tower_kind = st["tower"] if st else ("square" if mat == "wood" else "round")
        walls = e.get("walls") or []
        for i in range(len(walls)):
            a, b = walls[i], walls[(i + 1) % len(walls)]
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            if L < 0.1:
                continue
            if seg_wet(a, b):
                continue  # sur suya girmez: kıyıda biter, şehir göle açılır
            u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
            m = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
            acc.add(mat, *box(bx(m[0]), by(m[1]), hs(*m) - 1, L + 2.5, 3.2, wh + 1, u))
        for t in e.get("towers") or []:
            c = t["c"]
            if wet(*c):
                continue
            if mat == "wood":
                acc.add("wood", *box(bx(c[0]), by(c[1]), hs(*c) - 1, 7, 7, wh + 4))
            elif tower_kind == "square":
                s_ = (t["r"] + 1.2) * 1.8
                acc.add(mat, *box(bx(c[0]), by(c[1]), hs(*c) - 1, s_, s_, t["h"]))
                acc.add("slate" if st else mat, *hip(bx(c[0]), by(c[1]), hs(*c) - 1 + t["h"], s_ + 1, s_ + 1, s_ * 0.8))
            else:
                acc.add(mat, *cyl(bx(c[0]), by(c[1]), hs(*c) - 1, t["r"] + 1.2, t["h"], 12, cap_h=3.5))
        if e.get("keep"):
            c, r = e["keep"]["c"], e["keep"]["r"]
            acc.add(mat if mat != "wood" else "stone", *box(bx(c[0]), by(c[1]), hs(*c) - 1, r * 2.6, r * 2.6, e["keep"]["h"]))
        if e.get("church"):
            ch = e["church"]
            c = ch["c"]
            z = hs(*c) - 0.5
            cs = st["stone"] if st and st.get("stone") else "stone"
            k = 1.5 if e.get("culture") == "ahit" else 1.0
            CL, CW = ch["L"] * k, ch["W"] * k
            acc.add(cs, *box(bx(c[0]), by(c[1]), z, CL, CW, 8 * k, ch["u"]))
            acc.add("slate", *gable(bx(c[0]), by(c[1]), z + 8 * k, CL + 1, CW + 1, CW * 0.5, ch["u"]))
            tx, ty = rot(ch["u"], -CL / 2, 0)
            th = 30 if e.get("culture") == "ahit" else 18
            acc.add(cs, *box(bx(c[0]) + tx, by(c[1]) + ty, z, 6, 6, th))
            if e.get("culture") == "ahit":  # sivri kule başı, kubbe değil
                acc.add("slate", *cone(bx(c[0]) + tx, by(c[1]) + ty, z + th, 4.6, 14, 4))
        for y_ in e.get("yurts") or []:
            c, r = y_["c"], y_["r"]
            if not wet(*c):
                yurt(acc, c, r * 0.62, rng)
        if e.get("khan"):
            c = e["khan"]["c"]
            yurt(acc, c, 15.0, rng, mat="felt_dark", pole=True)
        for pen in e.get("pens") or []:
            if not wet(*pen["c"]):
                pen_draw(acc, pen, rng)
        for pr in e.get("piers") or []:
            a, b = pr["a"], pr["b"]
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
            m = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
            acc.add("wood", *box(bx(m[0]), by(m[1]), 0.2, L, 4, 0.8, u))
        for bt in e.get("boats") or []:
            ship(acc, {"c": bt["c"], "u": bt["u"], "size": "small"})


def scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    terrain()
    acc = Acc()
    trees(acc)
    settlements(acc)
    acc.build()
    # su yüzeyi: hafif parlak düz düzlem
    me = bpy.data.meshes.new("water")
    me.from_pydata([(-HALF, -HALF, 0.0), (HALF, -HALF, 0.0), (HALF, HALF, 0.0), (-HALF, HALF, 0.0)], [], [(0, 1, 2, 3)])
    wm = bpy.data.materials.new("water")
    wm.use_nodes = True
    b = wm.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.03, 0.04, 0.05, 1)
    b.inputs["Roughness"].default_value = 0.35
    b.inputs["Alpha"].default_value = 0.55
    me.materials.append(wm)
    ob = bpy.data.objects.new("water", me)
    sc.collection.objects.link(ob)

    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 2.6
    sun.angle = math.radians(1.2)
    sun.color = (1.0, 0.93, 0.82)
    so = bpy.data.objects.new("sun", sun)
    # kuzeybatıdan (sol üst), alçak: yükseliş 30°
    elev, az = math.radians(38), math.radians(135)
    d = (math.cos(elev) * math.cos(az), math.cos(elev) * math.sin(az), math.sin(elev))
    so.rotation_euler = (0, 0, 0)
    so.rotation_mode = "QUATERNION"
    from mathutils import Vector
    so.rotation_quaternion = Vector(d).to_track_quat("Z", "Y")
    sc.collection.objects.link(so)
    w = bpy.data.worlds.new("w")
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.32, 0.36, 0.42, 1)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.55
    sc.world = w

    cam = bpy.data.cameras.new("cam")
    cam.type = "ORTHO"
    cam.ortho_scale = S
    cam.clip_end = 2000
    co = bpy.data.objects.new("cam", cam)
    co.location = (0, 0, 800)
    sc.collection.objects.link(co)
    sc.camera = co

    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = SAMPLES
    sc.cycles.use_denoising = True
    sc.render.resolution_x = sc.render.resolution_y = RES
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_depth = "16"
    sc.view_settings.view_transform = "AgX"
    sc.render.filepath = os.path.join(VG, "render.png")
    bpy.ops.render.render(write_still=True)
    print("RENDER", sc.render.filepath)


if __name__ == "__main__":
    scene()
