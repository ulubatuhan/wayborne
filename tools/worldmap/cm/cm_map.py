"""Carta Marina tarzı harita parçası.

    python3 -I cm_map.py <fields.npz> <places.json> <x0> <y0> <size> <çıktı.png> [px/birim]

Coğrafya (su, dağ, orman, yol) ve yerleşim noktaları oyunun dünya
verisinden; çizimin kendisi tamamen bu klasördeki elle çizim fırçalarından.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import cairo  # noqa: E402
import cv2  # noqa: E402
import numpy as np  # noqa: E402
from PIL import Image  # noqa: E402
from scipy import ndimage as ndi  # noqa: E402

import build as B  # noqa: E402
import towns as T  # noqa: E402
from build import C  # noqa: E402
from hand import INK, PAPER, ink, path, shape, wob  # noqa: E402
from paper import finish, noise  # noqa: E402

fp, pp, X0, Y0, S, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), sys.argv[6]
P = float(sys.argv[7]) if len(sys.argv) > 7 else 2.0
SS = 2
N = int(S * P)
F = np.load(fp)
sl = {k: F[k][Y0:Y0 + S, X0:X0 + S].astype(np.float32) for k in ("water", "forest", "mount", "roads", "height")}
places = [p for p in json.load(open(pp)) if X0 + 10 < p["x"] < X0 + S - 10 and Y0 + 10 < p["y"] < Y0 + S - 10]
rng = np.random.default_rng(11)


def to_px(x, y):
    return (x - X0) * P, (y - Y0) * P


def field(name, n=N):
    return cv2.resize(sl[name], (n, n), interpolation=cv2.INTER_LINEAR)


# ---------------------------------------------------------------- yerleşimler
import shaped as SH  # noqa: E402

terr = SH.Terrain(field("water") > 0.5, field("height"), field("roads") > 0.5, field("mount"))
CITY_R = {"ic_city": 125, "ic_portcity": 125, "ic_freecity": 100, "it_town": 65, "ix_mountaintribe": 0}
SMALL = {
    "it_swamptown": ("swamp", 2.1), "ih_mezra": ("village", 2.0), "iv_farm": ("farm", 2.0),
    "iv_fishvillage": ("fish", 2.0), "il_lumber": ("lumber", 2.0), "ia_abbey": ("abbey", 2.1),
    "iw_tower": ("tower", 1.8), "ig_gallows": ("gallows", 1.7), "is_stones": ("stones", 1.8),
    "ib_battle": ("battle", 1.7), "in_yurtcamp": ("camp", 2.0), "it_minetown": ("mine", 2.0),
    "ip_lighthouse": ("lighthouse", 1.7), "ie_deepmine": ("deepmine", 1.6), "ix_mountaintribe": ("hillfort", 2.0),
}
keep = np.zeros((N, N), bool)
sets = []
for p in places:
    cx, cy = to_px(p["x"], p["y"])
    cul = p["c"] if p["c"] in T.STYLE else "sinir"
    if CITY_R.get(p["k"]):
        R = CITY_R[p["k"]] * (1.1 if cul == "ahit" else 1.0)
        port = p["k"] == "ic_portcity"
        fp = SH.footprint(terr, cx, cy, R, np.random.default_rng(p["id"]), port)
        if fp is None:
            continue
        m = fp[0]
        ys, xs = np.nonzero(m)
        s = dict(p=p, kind="city", cul=cul, R=R, port=port, fp=fp, cx=cx, cy=cy, bottom=float(ys.max()),
                 left=float(xs.min()), right=float(xs.max()))
        grow = ndi.binary_dilation(m, iterations=int(R * 0.45) + 6)
        for up in range(0, 60, 6):
            keep[:N - up] |= grow[up:]
        sets.append(s)
    elif p["k"] in SMALL:
        kind, k = SMALL[p["k"]]
        s = dict(p=p, kind=kind, k=k, cul=cul, cx=cx, cy=cy, bottom=cy + 14 * k)
        yy, xx = np.ogrid[:N, :N]
        keep |= ((xx - cx) / (34 * k)) ** 2 + ((yy - (cy - 8 * k)) / (26 * k)) ** 2 < 1
        sets.append(s)

LABEL = {"swamp": 21, "village": 19, "farm": 18, "lumber": 17, "abbey": 19, "tower": 17, "gallows": 16,
         "stones": 16, "battle": 16, "camp": 19, "fish": 19, "mine": 20, "lighthouse": 17, "deepmine": 17,
         "hillfort": 20}
label_boxes = []
for s in sets:
    if s["kind"] == "city":
        s["fs"] = 38 if s["R"] >= 120 else 31 if s["R"] >= 90 else 24
    else:
        s["fs"] = LABEL[s["kind"]]
    name = s["p"]["en"]
    w = len(name) * s["fs"] * 0.62
    ly = s["bottom"] + s["fs"] * 1.05
    if s["kind"] == "city" and s["port"]:
        xi, yi = int(np.clip(s["cx"], 0, N - 1)), int(np.clip(ly - s["fs"] * 0.4, 0, N - 1))
        if terr.water[yi, xi] or terr.wdist[yi, xi] < 8:
            ys_, xs_ = np.nonzero(s["fp"][0])
            ly = float(ys_.min()) - 48
    s["label"] = ly
    label_boxes.append((s["cx"] - w / 2 - 4, ly - s["fs"], s["cx"] + w / 2 + 4, ly + 6))
for (x0_, y0_, x1_, y1_) in label_boxes:
    keep[max(0, int(y0_)):max(0, int(y1_)), max(0, int(x0_)):max(0, int(x1_))] = True


def blocked(x, y, pad=0.0):
    xi, yi = int(x), int(y)
    r = int(max(0, pad))
    if not (0 <= xi < N and 0 <= yi < N):
        return True
    return bool(keep[max(0, yi - r):yi + r + 1, max(0, xi - r):xi + r + 1].any())


# ---------------------------------------------------------------- arazi boyası
water = field("water") > 0.5
forest = field("forest")
mount = field("mount")
height = field("height")
img = np.ones((N, N, 3), np.float32) * np.array(PAPER, np.float32)


def soft(mask, sig, warp=True):
    m = mask.astype(np.float32)
    if warp:
        nz = noise((N // 4, N // 4), 3, rng)
        nz = cv2.resize(nz, (N, N))
        m = np.clip(ndi.gaussian_filter(m, sig) + 0.18 * nz, 0, 1)
        m = (m > 0.5).astype(np.float32)
    return ndi.gaussian_filter(m, 1.2)


def lay(mask, color, alpha, edge=0.25):
    """Sulu boya katı: içi düz, kenarda toplanmış koyu bir şerit."""
    global img
    e = np.clip(mask - ndi.gaussian_filter(mask, 3.0), 0, 1) * 2.5
    a = mask * alpha
    col = np.array(color, np.float32)
    img = img * (1 - a[..., None]) + col * a[..., None]
    img = img * (1 - (e * edge)[..., None] * (1 - col * 0.6))


# çayırlar: kâğıdın üstünde çok hafif yeşil; ormanın altında koyulaşır; dağın altında toprak
lay(soft((forest > 0.18) & ~water, 6), (0.80, 0.83, 0.60), 0.35, 0.10)
lay(soft((forest > 0.45) & ~water, 4), (0.62, 0.72, 0.46), 0.30, 0.15)
import mountains as MT  # noqa: E402
MSTYLE = os.environ.get("MOUNT_STYLE", "cm")
if MSTYLE == "relief":
    shade_, wgt_, rgx, rgy = MT.relief_wash(height, mount, water)
    lay(soft((mount > 0.30) & ~water, 6), (0.88, 0.80, 0.64), 0.30, 0.06)
    dark = np.clip(shade_, 0, 1) * wgt_
    lite = np.clip(-shade_, 0, 1) * wgt_
    img = img * (1 - 0.65 * dark[..., None] * np.array([1.0, 1.06, 1.15], np.float32))
    img = img + (1 - img) * 0.25 * lite[..., None]
elif MSTYLE == "cluster":
    lay(soft((mount > 0.30) & ~water, 6), (0.82, 0.78, 0.66), 0.30, 0.08)
else:
    lay(soft((mount > 0.30) & ~water, 6), (0.86, 0.74, 0.58), 0.35, 0.10)
THEME = os.environ.get("MAP_THEME", "carta")
if THEME == "engraving":
    # gravür atlası: deniz boyanmaz, cetvelle çekilmiş yatay çizgilerle taranır
    wsoft = soft(water, 2, warp=False)
    rows = ((np.arange(N) // 1) % 5 < 1).astype(np.float32)[:, None] * np.ones((1, N), np.float32)
    dist_in = ndi.distance_transform_edt(water)
    fade = np.clip(dist_in / 40.0, 0, 1)
    lines = rows * wsoft * (1 - 0.6 * fade)
    img = img * (1 - 0.55 * lines[..., None])
    lay(wsoft, (0.80, 0.84, 0.82), 0.25, 0.3)
elif THEME == "painted":
    lay(soft(water, 2, warp=False), (0.36, 0.56, 0.62), 0.85, 0.7)
    lay(soft((forest > 0.10) & ~water, 10), (0.70, 0.78, 0.50), 0.30, 0.05)
elif THEME == "grim":
    lay(soft(water, 2, warp=False), (0.40, 0.48, 0.48), 0.85, 0.5)
else:
    lay(soft(water, 2, warp=False), (0.55, 0.70, 0.70), 0.85, 0.5)

# vadi tarlaları: verimli ova, kentin çevresinde şerit şerit ekin
fields_ctx = []
frng = np.random.default_rng(5)
for s in sets:
    if s["cul"] != "vadi" or s["kind"] not in ("city", "farm", "village"):
        continue
    R = 190 if s["kind"] == "city" else 110
    for _ in range(90 if s["kind"] == "city" else 35):
        a = frng.random() * 2 * math.pi
        r = R * (0.55 + 0.6 * frng.random())
        x, y = s["cx"] + r * math.cos(a), s["cy"] + r * 0.6 * math.sin(a)
        xi, yi = int(x), int(y)
        if not (0 < xi < N and 0 < yi < N) or water[yi, xi] or forest[yi, xi] > 0.25 or mount[yi, xi] > 0.25:
            continue
        fields_ctx.append((x, y, frng.random(), frng.random()))

# ---------------------------------------------------------------- cairo yüzeyi
surf = cairo.ImageSurface(cairo.FORMAT_RGB24, N * SS, N * SS)
ctx = cairo.Context(surf)
big = cv2.resize(img, (N * SS, N * SS), interpolation=cv2.INTER_CUBIC)
argb = np.zeros((N * SS, N * SS, 4), np.uint8)
argb[..., 2], argb[..., 1], argb[..., 0] = [(np.clip(big[..., i], 0, 1) * 255).astype(np.uint8) for i in range(3)]
stride = cairo.ImageSurface.format_stride_for_width(cairo.FORMAT_RGB24, N * SS)
src = cairo.ImageSurface.create_for_data(memoryview(argb), cairo.FORMAT_RGB24, N * SS, N * SS, stride)
ctx.set_source_surface(src, 0, 0)
ctx.paint()
ctx.scale(SS, SS)

# tarlalar
placed = []
for x, y, u, v in fields_ctx:
    if blocked(x, y, 6) or any(abs(x - a) < 22 and abs(y - b) < 11 for a, b in placed):
        continue
    placed.append((x, y))
    w, h = 26 + 12 * u, 10 + 5 * v
    sk = (v - 0.5) * 8
    q = [(x - w / 2 + sk, y - h / 2), (x + w / 2 + sk, y - h / 2), (x + w / 2 - sk, y + h / 2), (x - w / 2 - sk, y + h / 2)]
    col = [(0.88, 0.80, 0.52), (0.72, 0.78, 0.48), (0.84, 0.72, 0.50)][int(u * 3) % 3]
    shape(ctx, q, col, rng, hatch_angle=0.0 if v < 0.5 else 0.25, hatch_sp=2.6, hatch_alpha=0.3, w=0.5, alpha=0.65)

# göl kıyısı, kıyıyı izleyen ince çizgiler, dalgacıklar
wm = (cv2.resize(sl["water"], (N, N)) > 0.5).astype(np.uint8)
dist = ndi.distance_transform_edt(wm)
for lvl, wdt, al in ((0.5, 1.5, 1.0), (7, 0.55, 0.6), (15, 0.45, 0.4)):
    m = (dist > lvl).astype(np.uint8)
    cs, _ = cv2.findContours(m, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
    for c in cs:
        if len(c) < 20:
            continue
        pts = c[::3, 0, :].astype(float)
        ink(ctx, pts, rng, wdt, closed=True, amp=0.6, alpha=al)
ys, xs = np.nonzero(dist > 22)
for i in rng.choice(len(xs), min(len(xs), 160), replace=False) if len(xs) else []:
    x, y = xs[i], ys[i]
    pts = [(x + k * 1.6, y + 0.9 * math.sin(k * 1.4)) for k in range(6)]
    ink(ctx, pts, rng, 0.5, closed=False, amp=0.1, alpha=0.6)

# yollar: kesik mürekkep çizgisi
road = field("roads") > 0.5
ys, xs = np.nonzero(road)
order = rng.permutation(len(xs))
grid = {}
for i in order:
    x, y = float(xs[i]), float(ys[i])
    g = (int(x // 7), int(y // 7))
    if any(grid.get((g[0] + a, g[1] + b)) for a in (-1, 0, 1) for b in (-1, 0, 1)):
        continue
    if blocked(x, y, -6):
        continue
    grid[g] = True
    win = road[max(0, int(y) - 4):int(y) + 5, max(0, int(x) - 4):int(x) + 5]
    py, px = np.nonzero(win)
    if len(px) < 3:
        continue
    cov = np.cov(np.stack([px, py]))
    ev, evec = np.linalg.eigh(cov)
    d = evec[:, 1]
    ink(ctx, [(x - d[0] * 2, y - d[1] * 2), (x + d[0] * 2, y + d[1] * 2)], rng, 1.0, closed=False, amp=0.1,
        color=(0.45, 0.30, 0.20), alpha=0.85)

# ---------------------------------------------------------------- nesneler
objs = []


def poisson(mask, spacing, tries, key):
    ys, xs = np.nonzero(mask)
    if not len(xs):
        return []
    pts, grid = [], {}
    cell = spacing / math.sqrt(2)
    for i in rng.choice(len(xs), min(tries, len(xs)), replace=False):
        x, y = xs[i] + rng.random(), ys[i] + rng.random()
        g = (int(x // cell), int(y // cell))
        ok = True
        for a in range(-2, 3):
            for b in range(-2, 3):
                q = grid.get((g[0] + a, g[1] + b))
                if q and (q[0] - x) ** 2 + ((q[1] - y) * key) ** 2 < spacing ** 2:
                    ok = False
        if ok:
            grid[g] = (x, y)
            pts.append((x, y))
    return pts


# dağlar
if MSTYLE == "cluster":
    for x, y in poisson((mount > 0.50) & ~water.astype(bool), 40, 9000, 1.3):
        m = mount[int(y), int(x)]
        size = 26 + 40 * m * (0.6 + 0.6 * rng.random())
        if blocked(x, y, size * 0.4) or blocked(x, y - size * 0.6, 4):
            continue
        objs.append((y, "mc", x, size))
    for x, y in poisson((mount > 0.30) & (mount <= 0.50) & ~water.astype(bool), 55, 4000, 1.3):
        if blocked(x, y, 14) or rng.random() < 0.5:
            continue
        objs.append((y, "mc", x, 16 + 8 * rng.random()))
elif MSTYLE == "ridge":
    peaks, _hs = MT.ridge_peaks(height, mount, N, rng, 22)
    extra = [(x, y, float(_hs[int(y), int(x)])) for x, y in poisson((mount > 0.5) & ~water.astype(bool), 34, 6000, 1.3)]
    peaks = peaks + extra
    hmax = max([p[2] for p in peaks] or [1])
    for x, y, hh in peaks:
        H = 16 + 44 * (hh / hmax) * (0.7 + 0.5 * rng.random())
        if blocked(x, y, H * 0.5) or blocked(x, y - H * 0.7, 4):
            continue
        objs.append((y, "mr", x, H * (1.0 + 0.4 * rng.random()), H))
elif MSTYLE == "relief":
    MT.relief_hachures(ctx, rng, rgx, rgy, wgt_, keep, water, N, 6.5)
else:
    for x, y in poisson((mount > 0.55) & ~water.astype(bool), 64, 9000, 1.35):
        m = mount[int(y), int(x)]
        W = 60 + 80 * m * (0.5 + 0.8 * rng.random()) + height[int(y), int(x)] * 0.4
        H = W * (0.5 + 0.3 * rng.random())
        if blocked(x, y, W * 0.35) or blocked(x, y - H * 0.6, 4):
            continue
        objs.append((y, "m", x, W, H))
    for x, y in poisson((mount > 0.32) & (mount <= 0.55) & ~water.astype(bool), 60, 4000, 1.4):
        W = 28 + 22 * rng.random()
        if blocked(x, y, W * 0.4) or rng.random() < 0.55:
            continue
        objs.append((y, "m", x, W, W * 0.5))

# ağaçlar
for x, y in poisson((forest > 0.5) & ~water.astype(bool) & (mount < 0.45), 8.0, 60000, 1.25):
    if blocked(x, y, 3):
        continue
    hgt = height[int(y), int(x)]
    con = (mount[int(y), int(x)] > 0.2 or hgt > 22) and rng.random() < 0.8 or rng.random() < 0.12
    objs.append((y, "t", x, "conifer" if con else "leaf", 0.75 + 0.3 * rng.random()))
for x, y in poisson((forest < 0.3) & (mount < 0.3) & ~water.astype(bool), 70, 3000, 1.0):
    if blocked(x, y, 8) or rng.random() < 0.4:
        continue
    for k in range(rng.integers(1, 4)):
        objs.append((y + k * 3, "t", x + k * 7 - 7, "leaf", 0.8 + 0.2 * rng.random()))

for s in sets:
    objs.append((s["bottom"] if s["kind"] == "city" else s["cy"] + 8, "s", s))

# gemiler: liman kentlerinin açığında ve göl/denizde
srng = np.random.default_rng(21)
for s in sets:
    if s["kind"] == "city" and s["port"]:
        cand = np.argwhere((terr.wdist == 0) & (ndi.distance_transform_edt(terr.water) > 12))
        d = np.hypot(cand[:, 1] - s["cx"], cand[:, 0] - s["cy"])
        cand = cand[(d > s["R"] * 0.9) & (d < s["R"] * 2.2)]
        got = []
        for i in srng.permutation(len(cand)):
            y, x = cand[i]
            if all(math.hypot(x - a, y - b) > 70 for a, b in got) and not blocked(x, y, 4):
                got.append((x, y))
            if len(got) >= 3:
                break
        for x, y in got:
            objs.append((float(y), "ship", float(x), 0.95, 1 if srng.random() < 0.5 else -1))
    if s["kind"] == "fish":
        cand = np.argwhere((terr.wdist == 0) & (ndi.distance_transform_edt(terr.water) > 5))
        d = np.hypot(cand[:, 1] - s["cx"], cand[:, 0] - s["cy"])
        cand = cand[(d > 30) & (d < 110)]
        for i in srng.permutation(len(cand))[:3]:
            y, x = cand[i]
            objs.append((float(y), "boat", float(x), 1.1, 1 if srng.random() < 0.5 else -1))

objs.sort(key=lambda o: o[0])
DRAW = dict(swamp=T.swamp_town, village=T.village, farm=T.farm, lumber=T.lumber, abbey=T.abbey,
            tower=T.tower_post, camp=T.camp, fish=T.fish_village, mine=T.mine_town, lighthouse=T.lighthouse,
            deepmine=T.deep_mine, hillfort=T.hill_fort)
import build as B2  # noqa: E402
for o in objs:
    if o[1] == "m":
        _, _, x, W, H = o
        B.mountain(ctx, rng, x, o[0], W, H)
    elif o[1] == "mc":
        MT.cluster_group(ctx, rng, o[2], o[0], o[3])
    elif o[1] == "mr":
        MT.ridge_one(ctx, rng, o[2], o[0], o[3], o[4])
    elif o[1] == "t":
        _, _, x, kind, sc = o
        B.tree(ctx, rng, x, o[0], sc, kind)
    elif o[1] == "ship":
        B2.ship(ctx, rng, o[2], o[0], o[3], o[4])
    elif o[1] == "boat":
        B2.boat(ctx, rng, o[2], o[0], o[3], o[4])
    else:
        s = o[2]
        r2 = np.random.default_rng(s["p"]["id"] + 100)
        if s["kind"] == "city":
            SH.city(ctx, r2, terr, s["fp"], s["cul"], s["R"], s["port"])
            continue
        ctx.save()
        ctx.translate(s["cx"], s["cy"])
        ctx.scale(s["k"], s["k"])
        ctx.translate(-s["cx"], -s["cy"])
        if s["kind"] in DRAW:
            DRAW[s["kind"]](ctx, r2, s["cx"], s["cy"], s["cul"])
        else:
            getattr(T, s["kind"])(ctx, r2, s["cx"], s["cy"])
        ctx.restore()

# ---------------------------------------------------------------- yazılar
ctx.select_font_face("IM FELL English SC")
for s in sets:
    y, name = s["label"], s["p"]["en"]
    fs = s["fs"]
    ctx.set_font_size(fs)
    track = fs * 0.12
    tw = sum(ctx.text_extents(ch).x_advance + track for ch in name) - track
    x = s["cx"] - tw / 2
    # yazının altı kâğıda açılmış: çizgiler harflerin içinden geçmesin
    ctx.save()
    xx = x
    for ch in name:
        ctx.move_to(xx, y)
        ctx.text_path(ch)
        xx += ctx.text_extents(ch).x_advance + track
    ctx.set_source_rgba(*PAPER, 0.85)
    ctx.set_line_width(fs * 0.22)
    ctx.set_line_join(cairo.LINE_JOIN_ROUND)
    ctx.stroke_preserve()
    ctx.set_source_rgb(*INK)
    ctx.fill()
    ctx.restore()

# ---------------------------------------------------------------- çerçeve
m = 22
ctx.set_source_rgb(*INK)
for off, w in ((m, 2.2), (m + 9, 0.9)):
    ctx.rectangle(off, off, N - 2 * off, N - 2 * off)
    ctx.set_line_width(w)
    ctx.stroke()
step = 36
for i, t in enumerate(np.arange(m, N - m, step)):
    if i % 2 == 0:
        for (x, y, w, h) in ((t, m, min(step, N - m - t), 9), (t, N - m - 9, min(step, N - m - t), 9),
                             (m, t, 9, min(step, N - m - t)), (N - m - 9, t, 9, min(step, N - m - t))):
            ctx.rectangle(x, y, w, h)
            ctx.fill()
ctx.set_source_rgb(*PAPER)
ctx.rectangle(0, 0, N, m - 1)
ctx.rectangle(0, N - m + 1, N, m)
ctx.rectangle(0, 0, m - 1, N)
ctx.rectangle(N - m + 1, 0, m, N)
ctx.fill()

buf = np.frombuffer(surf.get_data(), np.uint8).reshape(N * SS, N * SS, 4)[..., [2, 1, 0]]
res = finish(buf.astype(np.float32) / 255, SS)
res = Image.fromarray(res).resize((N, N), Image.LANCZOS)
a = np.asarray(res, np.float32) / 255
lum = a @ np.array([0.3, 0.59, 0.11], np.float32)
if THEME == "engraving":
    # sepya baskı, üstüne çok hafif elle boyama payı
    sep = np.stack([lum * 1.0, lum * 0.92, lum * 0.78], -1)
    a = sep * 0.8 + a * 0.2
elif THEME == "grim":
    # oyunun karanlık diliyle: soluk renk, koyu deri-parşömen, ağır köşe karartması
    grey = lum[..., None]
    a = grey + (a - grey) * 0.45
    a = 0.06 + a ** 1.25 * np.array([0.78, 0.70, 0.60], np.float32)
    yy, xx = np.mgrid[0:N, 0:N] / N
    v = np.clip(np.hypot(xx - 0.5, yy - 0.5) * 1.6 - 0.2, 0, 1) ** 1.6
    a = a * (1 - 0.65 * v[..., None])
elif THEME == "storybook":
    grey = lum[..., None]
    a = np.clip(grey + (a - grey) * 1.55, 0, 1)
    a = np.clip((a - 0.5) * 1.12 + 0.53, 0, 1)
elif THEME == "painted":
    grey = lum[..., None]
    a = np.clip(grey + (a - grey) * 1.2, 0, 1)
Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).save(out)
print("yazıldı", out, "nesne", len(objs))
