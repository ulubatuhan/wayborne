"""Tam harita, mürekkep ve parşömen (Orta Dünya haritasının dili, bizim kentlerimizle).

    python3 -I cm_full.py prep  <fields.npz> <places.json> <layout_v3.json> <out_dir>
    python3 -I cm_full.py tile  <out_dir> <tx> <ty>
    python3 -I cm_full.py stitch <out_dir>

Hazırlık bütün nesneleri tek sefer, sabit tohumlarla hesaplar; karolar aynı
listeden kendi alanına düşenleri çizer, böylece karo sınırında dikiş olmaz.
Kâğıt, ton ve köşe karartması birleşik resme bir kez uygulanır.
"""
import math
import os
import pickle
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import cairo  # noqa: E402
import cv2  # noqa: E402
import numpy as np  # noqa: E402
from PIL import Image  # noqa: E402
from scipy import ndimage as ndi  # noqa: E402

P = 2                 # piksel / harita birimi
NMAP = 4096
N = NMAP * P          # 8192
TILE = 2048
MARGIN = 260
SS = 2
INK = (0.17, 0.12, 0.09)
PAPER = (0.94, 0.89, 0.77)


# ------------------------------------------------------------------ alanlar

class Fields:
    def __init__(self, fp):
        F = np.load(fp)
        self.f = {k: F[k].astype(np.float32) for k in ("water", "forest", "mount", "roads", "height")}

    def crop(self, name, x0, y0, w, h):
        """Piksel uzayında [x0,x0+w)×[y0,y0+h) kesiti (harita dışı kenardan uzatılır)."""
        a = self.f[name]
        mx0, my0 = int(math.floor(x0 / P)) - 2, int(math.floor(y0 / P)) - 2
        mx1, my1 = int(math.ceil((x0 + w) / P)) + 2, int(math.ceil((y0 + h) / P)) + 2
        pad = max(0, -mx0, -my0, mx1 - NMAP, my1 - NMAP)
        if pad:
            a = np.pad(a, pad, mode="edge")
        sub = a[my0 + pad:my1 + pad, mx0 + pad:mx1 + pad]
        big = cv2.resize(sub, ((mx1 - mx0) * P, (my1 - my0) * P), interpolation=cv2.INTER_LINEAR)
        ox, oy = x0 - mx0 * P, y0 - my0 * P
        return big[oy:oy + h, ox:ox + w]


def local_terrain(F, x0, y0, W):
    import shaped as SH
    return SH.Terrain(F.crop("water", x0, y0, W, W) > 0.5, F.crop("height", x0, y0, W, W),
                      F.crop("roads", x0, y0, W, W) > 0.5, F.crop("mount", x0, y0, W, W))


# ------------------------------------------------------------------ hazırlık

CITY_R = {"ic_city": 125, "ic_portcity": 125, "ic_freecity": 100, "it_town": 62, "it_markettown": 62,
          "it_rivertown": 62}
SMALL = {
    "it_swamptown": ("swamp", 2.1), "ih_mezra": ("village", 2.0), "iv_farm": ("farm", 2.0),
    "iv_fishvillage": ("fish", 2.0), "il_lumber": ("lumber", 2.0), "ia_abbey": ("abbey", 2.1),
    "iw_tower": ("tower", 1.8), "ig_gallows": ("gallows", 1.7), "is_stones": ("stones", 1.8),
    "ib_battle": ("battle", 1.7), "in_yurtcamp": ("camp", 2.0), "it_minetown": ("mine", 2.0),
    "ip_lighthouse": ("lighthouse", 1.7), "ie_deepmine": ("deepmine", 1.6), "ie_saltmine": ("deepmine", 1.5),
    "ix_mountaintribe": ("hillfort", 2.0), "ir_ruins": ("ruins", 1.7), "ig_graveyard": ("graveyard", 1.6),
    "ix_wreck": ("wreck", 1.6),
}
LABEL = {"swamp": 21, "village": 19, "farm": 18, "lumber": 17, "abbey": 19, "tower": 17, "gallows": 16,
         "stones": 16, "battle": 16, "camp": 19, "fish": 19, "mine": 20, "lighthouse": 17, "deepmine": 17,
         "hillfort": 20, "ruins": 17, "graveyard": 16, "wreck": 16, "serai": 22}

SERAI_NAMES = ["Tarvessa Caravanserai", "Ombrakal Caravanserai", "Kesimer Caravanserai", "Haldrun Caravanserai",
               "Seyvan Caravanserai"]


def lattice(mask, step, jitter, rng):
    h, w = mask.shape
    ys = np.arange(step / 2, h, step * 0.87)
    pts = []
    for r, y in enumerate(ys):
        xs = np.arange(step / 2 + (r % 2) * step / 2, w, step)
        X = xs + rng.uniform(-jitter, jitter, len(xs))
        Y = y + rng.uniform(-jitter, jitter, len(xs))
        ok = (X >= 0) & (X < w) & (Y >= 0) & (Y < h)
        X, Y = X[ok], Y[ok]
        keep = mask[Y.astype(int), X.astype(int)]
        pts.append(np.stack([X[keep], Y[keep]], 1))
    return np.vstack(pts) if pts else np.zeros((0, 2))


def caravan_route(F, start, end):
    """Kuzeyden güneye kervan yolu: mevcut yollara yapışık en ucuz yol."""
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import dijkstra
    g = 4
    n = NMAP // g
    roads = F.f["roads"].reshape(n, g, n, g).max(axis=(1, 3))
    water = F.f["water"].reshape(n, g, n, g).mean(axis=(1, 3)) > 0.5
    mount = F.f["mount"].reshape(n, g, n, g).mean(axis=(1, 3))
    cost = np.where(roads > 0.3, 1.0, 7.0) + mount * 30.0
    cost[water] = 1e5
    idx = np.arange(n * n).reshape(n, n)
    rows, cols, vals = [], [], []
    for dy, dx, f in ((0, 1, 1.0), (1, 0, 1.0), (1, 1, 1.414), (1, -1, 1.414)):
        a = idx[max(0, -dy):n - max(0, dy), max(0, -dx):n - max(0, dx)]
        b = idx[max(0, -dy) + dy:n - max(0, dy) + dy, max(0, -dx) + dx:n - max(0, dx) + dx]
        ca = cost.ravel()[a.ravel()]
        cb = cost.ravel()[b.ravel()]
        v = (ca + cb) / 2 * f
        rows += [a.ravel(), b.ravel()]
        cols += [b.ravel(), a.ravel()]
        vals += [v, v]
    G = coo_matrix((np.concatenate(vals), (np.concatenate(rows), np.concatenate(cols))), shape=(n * n, n * n)).tocsr()
    s = int(start[1] // g) * n + int(start[0] // g)
    e = int(end[1] // g) * n + int(end[0] // g)
    dist, pred = dijkstra(G, indices=s, return_predecessors=True)
    pathi = [e]
    while pathi[-1] != s and pathi[-1] >= 0:
        pathi.append(pred[pathi[-1]])
    pathi = pathi[::-1]
    pts = np.array([[(i % n + 0.5) * g, (i // n + 0.5) * g] for i in pathi], float)
    # yumuşat
    for _ in range(3):
        pts[1:-1] = (pts[:-2] + 2 * pts[1:-1] + pts[2:]) / 4
    return pts


def prep(fields_p, places_p, layout_p, out):
    import shaped as SH
    import json
    os.makedirs(out, exist_ok=True)
    F = Fields(fields_p)
    rng = np.random.default_rng(7)
    places = json.load(open(places_p))
    big = {k: cv2.resize(F.f[k], (N, N), interpolation=cv2.INTER_LINEAR) for k in ("water", "forest", "mount", "roads")}
    water = big["water"] > 0.5
    keep = np.zeros((N, N), bool)
    objs = []          # (sırala_y, tür, veri, bbox)
    labels = []

    def keep_ellipse(cx, cy, rx, ry, up):
        x0, x1 = int(max(0, cx - rx)), int(min(N, cx + rx))
        y0, y1 = int(max(0, cy - ry - up)), int(min(N, cy + ry))
        if x1 <= x0 or y1 <= y0:
            return
        yy, xx = np.mgrid[y0:y1, x0:x1]
        dy = np.where(yy < cy, (yy - cy) / (ry + up), (yy - cy) / ry)
        keep[y0:y1, x0:x1] |= ((xx - cx) / rx) ** 2 + dy ** 2 < 1

    def add_label(text, cx, y, fs, kind="place"):
        w = len(text) * fs * 0.62
        labels.append(dict(text=text, x=cx, y=y, fs=fs, kind=kind))
        keep[max(0, int(y - fs)):max(0, int(y + 6)), max(0, int(cx - w / 2 - 4)):max(0, int(cx + w / 2 + 4))] = True

    # --- kentler ve yerleşimler
    for p in places:
        cx, cy = p["x"] * P, p["y"] * P
        cul = p["c"] if p["c"] in ("vadi", "ahit", "sinir", "imparatorluk", "guney", "dag", "dag_maden") else "sinir"
        if p["k"] in CITY_R:
            R = CITY_R[p["k"]] * (1.1 if cul == "ahit" else 1.0)
            port = p["k"] == "ic_portcity"
            Wn = int(R * 3.4) * 2
            wx0, wy0 = int(cx) - Wn // 2, int(cy) - Wn // 2
            terr = local_terrain(F, wx0, wy0, Wn)
            fp = SH.footprint(terr, cx - wx0, cy - wy0, R, np.random.default_rng(p["id"]), port)
            if fp is None:
                continue
            m = fp[0]
            ys, xs = np.nonzero(m)
            grow = ndi.binary_dilation(m, iterations=int(R * 0.45) + 6)
            for up in range(0, 64, 6):
                gx0, gy0 = wx0, wy0 - up
                sub = grow
                ya, yb = max(0, gy0), min(N, gy0 + Wn)
                xa, xb = max(0, gx0), min(N, gx0 + Wn)
                if ya < yb and xa < xb:
                    keep[ya:yb, xa:xb] |= sub[ya - gy0:yb - gy0, xa - gx0:xb - gx0]
            bottom = wy0 + float(ys.max())
            d = dict(p=p, cul=cul, R=R, port=port, fp=fp, win=(wx0, wy0, Wn), seed=p["id"] + 100)
            objs.append((bottom, "city", d, (wx0, wy0 - 80, wx0 + Wn, wy0 + Wn)))
            fs = 38 if R >= 120 else 31 if R >= 90 else 24
            ly = bottom + fs * 1.05
            yi, xi = int(np.clip(ly - fs * 0.4, 0, N - 1)), int(np.clip(cx, 0, N - 1))
            if port and water[yi, xi]:
                ly = wy0 + float(ys.min()) - 48
            add_label(p["en"], cx, ly, fs)
        elif p["k"] in SMALL:
            kind, k = SMALL[p["k"]]
            keep_ellipse(cx, cy - 8 * k, 34 * k, 26 * k, 0)
            d = dict(p=p, cul=cul, kind=kind, k=k, cx=cx, cy=cy, seed=p["id"] + 100)
            objs.append((cy + 8, "small", d, (cx - 45 * k, cy - 50 * k, cx + 45 * k, cy + 20 * k)))
            add_label(p["en"], cx, cy + 14 * k + LABEL[kind] * 1.05, LABEL[kind])

    # --- kervan yolu: kuzey krallığının başkentinden en güneydeki kente
    imp = [p for p in places if p["c"] == "imparatorluk" and p["k"] == "ic_city"]
    start = min(imp, key=lambda p: p["y"])
    end = max([p for p in places if p["k"].startswith("ic_")], key=lambda p: p["y"])
    route = caravan_route(F, (start["x"], start["y"]), (end["x"], end["y"])) * P
    seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(route, axis=0), axis=1))]
    towns = np.array([[p["x"] * P, p["y"] * P] for p in places if p["k"].startswith(("ic_", "it_", "ih_", "iv_"))])
    serais = []
    for i in range(5):
        best, bd = None, -1
        for f in np.linspace((i + 0.2) / 5, (i + 0.8) / 5, 40):
            s = f * seg[-1]
            j = min(max(int(np.searchsorted(seg, s)), 1), len(route) - 1)
            q = route[j - 1] + (route[j] - route[j - 1]) * ((s - seg[j - 1]) / max(seg[j] - seg[j - 1], 1e-6))
            if water[int(q[1]), int(q[0])]:
                continue
            dmin = float(np.min(np.hypot(*(towns - q).T)))
            if serais:
                dmin = min(dmin, float(np.min(np.hypot(*(np.array(serais) - q).T))) * 0.5)
            if dmin > bd:
                best, bd = q, dmin
        serais.append(best)
    cult = np.array([[p["x"] * P, p["y"] * P] for p in places])
    keep_i = [i for i, q in enumerate(serais)
              if places[int(np.argmin(np.hypot(*(cult - np.asarray(q)).T)))]["c"] != "gocebe"]
    print("kervansaray (göçebe bölgesi dışında)", [SERAI_NAMES[i] for i in keep_i])
    serais = [serais[i] for i in keep_i]
    for i, q in zip(keep_i, serais):
        # yolun hemen kenarına
        cx, cy = float(q[0]) + 30, float(q[1]) - 10
        keep_ellipse(cx, cy - 10, 55, 30, 20)
        objs.append((cy + 14, "serai", dict(cx=cx, cy=cy, seed=900 + i), (cx - 70, cy - 70, cx + 70, cy + 40)))
        add_label(SERAI_NAMES[i], cx, cy + 40, LABEL["serai"], "serai")
    route_mask = np.zeros((N, N), np.uint8)
    cv2.polylines(route_mask, [route.astype(np.int32)], False, 1, 12)

    # --- gemiler (önceki düzenden: boğaz, liman açıkları, balıkçı tekneleri)
    L = json.load(open(layout_p))
    ships = [e for e in L if e["kind"] == "x_ships"]
    for i, s in enumerate(ships[0]["ships"] if ships else []):
        x, y = s["c"][0] * P, s["c"][1] * P
        if not water[int(y), int(x)]:
            continue
        face = 1 if s["u"][0] >= 0 else -1
        kind = "ship" if s["size"] == "big" else "boat"
        objs.append((y, kind, dict(x=x, y=y, face=face, seed=700 + i), (x - 40, y - 70, x + 40, y + 10)))

    # --- dağlar ve tepeler
    mount, forest = big["mount"], big["forest"]
    del big
    hpx = cv2.resize(F.f["height"], (N, N), interpolation=cv2.INTER_LINEAR)
    pk = lattice((mount > 0.47) & ~water, 29, 9, rng)
    for i, (x, y) in enumerate(pk):
        m = mount[int(y), int(x)]
        if rng.random() > 0.5 + 0.5 * m:
            continue
        H = 22 + 46 * m * rng.uniform(0.6, 1.2) + hpx[int(y), int(x)] * 0.15
        W = H * rng.uniform(0.75, 1.05)
        if keep[int(max(0, y - H)), int(x)] or keep[int(y), int(x)]:
            continue
        north = np.clip((1500 - y / P) / 500, 0, 1)
        snow = 0.0
        if north > 0 and H > 34:
            snow = float(np.clip(0.22 + 0.25 * north + (H - 34) / 80, 0, 0.55)) * (1 if rng.random() < 0.9 else 0)
        objs.append((y, "peak", dict(x=x, y=y, W=W, H=H, snow=snow, seed=10_000 + i), (x - W, y - H - 4, x + W, y + 4)))
    hl = lattice((mount > 0.24) & (mount <= 0.47) & ~water, 44, 12, rng)
    for i, (x, y) in enumerate(hl):
        if rng.random() < 0.45 or keep[int(y), int(x)]:
            continue
        W = rng.uniform(18, 32)
        objs.append((y, "hill", dict(x=x, y=y, W=W, seed=200_000 + i), (x - W, y - W * 0.5, x + W, y + 4)))

    # --- ağaçlar
    con_mask = (mount > 0.18) | (hpx > 30) | (np.arange(N)[:, None] < 1300 * P)
    del hpx
    roads_px = cv2.resize(F.f["roads"], (N, N), interpolation=cv2.INTER_LINEAR) > 0.5
    tr = lattice((forest > 0.5) & ~water & (mount < 0.47), 9.5, 3.0, rng)
    for i, (x, y) in enumerate(tr):
        xi, yi = int(x), int(y)
        if keep[yi, xi] or roads_px[yi, xi] or route_mask[yi, xi]:
            continue
        con = bool(con_mask[yi, xi]) if rng.random() < 0.85 else bool(rng.random() < 0.2)
        s = rng.uniform(0.75, 1.05)
        objs.append((y, "tree", dict(x=x, y=y, kind="conifer" if con else "leaf", s=s, seed=400_000 + i),
                     (x - 8, y - 18, x + 8, y + 2)))
    lone = lattice((forest < 0.3) & (mount < 0.3) & ~water, 64, 18, rng)
    for i, (x, y) in enumerate(lone):
        if rng.random() < 0.55 or keep[int(y), int(x)] or roads_px[int(y), int(x)]:
            continue
        for k in range(int(rng.integers(1, 4))):
            xx, yy = x + k * 7 - 7, y + k * 3
            objs.append((yy, "tree", dict(x=xx, y=yy, kind="leaf", s=rng.uniform(0.8, 1.0), seed=900_000 + i * 4 + k),
                         (xx - 8, yy - 18, xx + 8, yy + 2)))
    del forest, mount

    # --- kıyı çizgileri ve dalgalar
    wm = water.astype(np.uint8)
    dist_in = ndi.distance_transform_edt(wm).astype(np.float32)
    coasts = []
    for lvl, w, al in ((0.5, 1.6, 1.0), (5, 0.6, 0.75), (10, 0.5, 0.55), (17, 0.45, 0.35)):
        cs, _ = cv2.findContours((dist_in > lvl).astype(np.uint8), cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
        for c in cs:
            if len(c) < 24:
                continue
            pts = c[::3, 0, :].astype(np.float32)
            coasts.append(dict(pts=pts, w=w, al=al, bbox=(pts[:, 0].min(), pts[:, 1].min(), pts[:, 0].max(), pts[:, 1].max())))
    wv = lattice((dist_in > 26) & (dist_in < 220) & ~keep, 46, 16, rng)
    waves = [dict(x=float(x), y=float(y), s=float(rng.uniform(0.8, 1.3))) for x, y in wv if rng.random() < 0.55]
    del dist_in

    # --- yollar: ince kesik çizgi; kervan yolu kalın ve sürekli kesik
    ys, xs = np.nonzero(roads_px & ~ndi.binary_dilation(route_mask > 0, iterations=4))
    dashes = []
    order = rng.permutation(len(xs))
    grid = {}
    for i in order:
        x, y = float(xs[i]), float(ys[i])
        g = (int(x // 7), int(y // 7))
        if any(grid.get((g[0] + a, g[1] + b)) for a in (-1, 0, 1) for b in (-1, 0, 1)):
            continue
        if keep[int(y), int(x)] and not water[int(y), int(x)]:
            pass
        grid[g] = True
        win = roads_px[max(0, int(y) - 4):int(y) + 5, max(0, int(x) - 4):int(x) + 5]
        py, px = np.nonzero(win)
        if len(px) < 3:
            continue
        ev, evec = np.linalg.eigh(np.cov(np.stack([px, py])))
        d = evec[:, 1]
        dashes.append((x, y, float(d[0]), float(d[1])))

    objs.sort(key=lambda o: o[0])
    with open(os.path.join(out, "scene.pkl"), "wb") as f:
        pickle.dump(dict(objs=objs, labels=labels, coasts=coasts, waves=waves, dashes=dashes, route=route,
                         serais=serais), f)
    print("nesne", len(objs), "kıyı", len(coasts), "dalga", len(waves), "yol", len(dashes), "kervansaray", serais)


# ------------------------------------------------------------------ karo

OUT = int(os.environ.get("CM_OUT", "1"))      # çıktı piksel / harita pikseli


def tile(out, tx, ty):
    global ROAD_LINE, ROAD_MAIN
    sc = pickle.load(open(os.path.join(out, "scene_final.pkl"), "rb"))
    F = Fields(os.environ["CM_FIELDS"])
    ROAD_LINE = np.unpackbits(np.load(os.path.join(out, "roads_clean.npy")))[:N * N].reshape(N, N).astype(bool)
    mp = os.path.join(out, "roads_main.npy")
    if os.path.exists(mp):
        ROAD_MAIN = np.unpackbits(np.load(mp))[:N * N].reshape(N, N).astype(bool)
    ox, oy = tx * TILE - MARGIN, ty * TILE - MARGIN
    S = TILE + 2 * MARGIN
    img = render(sc, F, ox, oy, S, S, OUT)
    m, t = MARGIN * OUT, TILE * OUT
    img.crop((m, m, m + t, m + t)).save(os.path.join(out, "tile_%d_%d.png" % (tx, ty)))
    print("karo", tx, ty)


ROCK_DRAW = {  # tür: (renk, uç incelmesi, dalga)
    "hatch": ((0.6, 1.0, 0.25), 0.05),
    "edge": ((0.5, 1.0, 0.5), 0.25),
    "crease": ((0.3, 1.0, 0.25), 0.2),
    "ridge": ((0.3, 1.0, 0.3), 0.15),
    "spine": ((0.6, 1.0, 0.6), 0.25),
    "spur": ((0.9, 0.7, 0.2), 0.2),
    "sub": ((0.9, 0.7, 0.1), 0.15),
    "hach": ((0.4, 1.0, 0.3), 0.1),
}
SNOW = (0.985, 0.975, 0.95)


def _rock_wash(ctx, F, ox, oy, W, H):
    """Kaya alanı: referans haritanın kaya rengi yerine çok hafif bir mürekkep tonu."""
    m = F.crop("mount", ox, oy, W, H)
    w = F.crop("water", ox, oy, W, H) > 0.5
    a = np.clip((ndi.gaussian_filter(m, 6) - 0.44) / 0.10, 0, 1) * 0.09
    a[ndi.binary_dilation(w, iterations=3)] = 0
    rgba = np.zeros((H, W, 4), np.uint8)
    al = (a * 255).astype(np.uint8)
    for c, v in enumerate((INK[2], INK[1], INK[0])):
        rgba[..., c] = (al * v).astype(np.uint8)
    rgba[..., 3] = al
    s = cairo.ImageSurface.create_for_data(memoryview(np.ascontiguousarray(rgba)), cairo.FORMAT_ARGB32, W, H)
    ctx.save()
    ctx.set_source_surface(s, ox, oy)
    ctx.paint()
    ctx.restore()


def _paint_rgba(ctx, rgb, alpha, ox, oy):
    H, W = alpha.shape
    al = (np.clip(alpha, 0, 1) * 255).astype(np.uint8)
    rgba = np.zeros((H, W, 4), np.uint8)
    for c, v in enumerate((rgb[2], rgb[1], rgb[0])):
        rgba[..., c] = (al * v).astype(np.uint8)
    rgba[..., 3] = al
    s = cairo.ImageSurface.create_for_data(memoryview(np.ascontiguousarray(rgba)), cairo.FORMAT_ARGB32, W, H)
    ctx.save()
    ctx.set_source_surface(s, ox, oy)
    ctx.paint()
    ctx.restore()


ROAD_LINE = None
ROAD_MAIN = None


def road_line_global(F, path=None):
    """Bütün haritanın yol orta çizgisi (harita pikseli), paralel kopyalar ayıklanmış.

    Kaynak veride bazı yollar yan yana iki iz olarak geliyor; en uzun izden
    başlayarak, başka bir yola uzun süre 30 px'ten yakın koşan parça silinir.
    Kavşaklardaki kısa yakınlık (bir yolun ötekine bağlandığı yer) kalır."""
    import rock as RK
    if path and os.path.exists(path):
        return np.unpackbits(np.load(path))[:N * N].reshape(N, N).astype(bool)
    r = cv2.resize(F.f["roads"], (N, N), interpolation=cv2.INTER_LINEAR)
    s = ndi.gaussian_filter(r, 5.0) / 0.5
    _, nx, ny = RK._hessian(-s, 3.0)
    line = RK._nms(s, nx, ny) & (s > 0.22)
    del nx, ny, r
    thick = ndi.binary_opening(line, structure=np.ones((2, 2)))
    line &= ~ndi.binary_dilation(thick, iterations=2)
    lab, n = ndi.label(line, structure=np.ones((3, 3)))
    sz = ndi.sum(line, lab, np.arange(1, n + 1))
    keep = np.zeros(N * N, bool).reshape(N, N)
    objs = ndi.find_objects(lab)
    near_r = 30
    for i in np.argsort(-sz):
        if sz[i] < 14:
            break
        sl = objs[i]
        y0, y1 = max(0, sl[0].start - near_r), min(N, sl[0].stop + near_r)
        x0, x1 = max(0, sl[1].start - near_r), min(N, sl[1].stop + near_r)
        comp = lab[y0:y1, x0:x1] == i + 1
        acc = keep[y0:y1, x0:x1]
        if acc.any():
            dist = ndi.distance_transform_edt(~acc)
            near = comp & (dist < near_r)
            nl, nn = ndi.label(ndi.binary_dilation(near, iterations=2), structure=np.ones((3, 3)))
            if nn:
                nsz = ndi.sum(near, nl, np.arange(1, nn + 1))
                drop = np.isin(nl, np.nonzero(nsz > 45)[0] + 1)
                comp &= ~drop
            cl, cn = ndi.label(comp, structure=np.ones((3, 3)))     # kopan küçük artıklar
            if cn:
                csz = ndi.sum(comp, cl, np.arange(1, cn + 1))
                comp = np.isin(cl, np.nonzero(csz >= 14)[0] + 1)
        keep[y0:y1, x0:x1] |= comp
    if path:
        np.save(path, np.packbits(keep.ravel()))
    return keep


def clean_roads(line, route, near_r=55, bridge=320, min_len=160):
    """Tek bir yol ağı: kervan yolu da öteki yollar gibi tek düz çizgi olarak
    katılır, ona (ya da birbirine) paralel koşan kopyalar silinir, aynı doğrultuda
    kopuk kalan parçalar birleştirilir, hiçbir yere bağlanmayan kırıntılar atılır."""
    from scipy.spatial import cKDTree
    line = line.copy()
    rmask = np.zeros((N, N), np.uint8)
    cv2.polylines(rmask, [route.astype(np.int32)], False, 1, 1)
    near = ndi.distance_transform_edt(rmask == 0) < near_r
    line &= ~near
    line |= rmask.astype(bool)
    for _ in range(3):
        nb = ndi.convolve(line.astype(np.uint8), np.ones((3, 3), np.uint8), mode="constant") - line
        ends = np.argwhere(line & (nb == 1))
        lab, _n = ndi.label(line, structure=np.ones((3, 3)))
        dirs = []
        for y, x in ends:
            ya, yb, xa, xb = max(0, y - 14), y + 15, max(0, x - 14), x + 15
            ys, xs = np.nonzero(lab[ya:yb, xa:xb] == lab[y, x])
            v = np.array([x - (xs.mean() + xa), y - (ys.mean() + ya)], np.float32)
            dirs.append(v / (np.linalg.norm(v) + 1e-6))
        if len(ends) < 2:
            break
        tree = cKDTree(ends[:, ::-1].astype(np.float32))
        used = set()
        added = 0
        for i, j in sorted(tree.query_pairs(bridge), key=lambda q: np.linalg.norm(ends[q[0]] - ends[q[1]])):
            if i in used or j in used:
                continue
            a, b = ends[i][::-1].astype(np.float32), ends[j][::-1].astype(np.float32)
            v = b - a
            d = np.linalg.norm(v)
            if d < 1:
                continue
            v /= d
            same = lab[tuple(ends[i])] == lab[tuple(ends[j])]
            if same and d < 60:
                continue
            if dirs[i] @ v > (0.82 if d < 170 else 0.9) and dirs[j] @ -v > (0.82 if d < 170 else 0.9):
                img = line.astype(np.uint8)
                cv2.line(img, tuple(int(c) for c in a), tuple(int(c) for c in b), 1, 1)
                line = img.astype(bool)
                used |= {i, j}
                added += 1
        print("köprü", added, flush=True)
        if not added:
            break
    # T kavşakları: ucu, önündeki başka bir yola bağla
    nb = ndi.convolve(line.astype(np.uint8), np.ones((3, 3), np.uint8), mode="constant") - line
    ends = np.argwhere(line & (nb == 1))
    lab, _n = ndi.label(line, structure=np.ones((3, 3)))
    img = line.astype(np.uint8)
    joined = 0
    R = 110
    for y, x in ends:
        ya, yb, xa, xb = max(0, y - 14), y + 15, max(0, x - 14), x + 15
        ys, xs = np.nonzero(lab[ya:yb, xa:xb] == lab[y, x])
        dv = np.array([x - (xs.mean() + xa), y - (ys.mean() + ya)], np.float32)
        dv /= np.linalg.norm(dv) + 1e-6
        ya, yb, xa, xb = max(0, y - R), min(N, y + R + 1), max(0, x - R), min(N, x + R + 1)
        win = lab[ya:yb, xa:xb]
        cy, cx = np.nonzero((win > 0) & (win != lab[y, x]))
        if not len(cy):
            continue
        vx, vy = cx + xa - x, cy + ya - y
        dist = np.hypot(vx, vy)
        ok = (vx * dv[0] + vy * dv[1]) > 0.6 * dist
        if not ok.any():
            continue
        k = np.argmin(np.where(ok, dist, 1e9))
        cv2.line(img, (int(x), int(y)), (int(cx[k] + xa), int(cy[k] + ya)), 1, 1)
        joined += 1
    line = img.astype(bool)
    print("kavşak", joined, flush=True)
    lab, n = ndi.label(line, structure=np.ones((3, 3)))
    sz = ndi.sum(line, lab, np.arange(1, n + 1))
    line = np.isin(lab, np.nonzero(sz >= min_len)[0] + 1)
    return line


def _road_raster(ctx, F, ox, oy, W, H):
    if ROAD_LINE is None:
        return
    line = np.zeros((H, W), bool)
    ya, yb, xa, xb = max(0, oy), min(N, oy + H), max(0, ox), min(N, ox + W)
    if ya >= yb or xa >= xb:
        return
    line[ya - oy:yb - oy, xa - ox:xb - ox] = ROAD_LINE[ya:yb, xa:xb]
    if not line.any():
        return
    if ROAD_MAIN is not None:
        main = np.zeros((H, W), bool)
        main[ya - oy:yb - oy, xa - ox:xb - ox] = ROAD_MAIN[ya:yb, xa:xb]
        line = line | ndi.binary_dilation(main & line, iterations=1)
    core = np.clip(ndi.gaussian_filter(line.astype(np.float32), 0.75) * 2.6, 0, 1)
    bed = np.clip(ndi.gaussian_filter(line.astype(np.float32), 2.0) * 6, 0, 1) * 0.9
    _paint_rgba(ctx, PAPER, bed, ox, oy)
    _paint_rgba(ctx, INK, core * 0.92, ox, oy)


def render(sc, F, ox, oy, W, H, O=1):
    import build as B
    import inkgeo as IG
    import shaped as SH
    import sketch as SK
    import towns as T
    from hand import ink
    bx0, by0, bx1, by1 = ox, oy, ox + W, oy + H

    def hit(bb):
        return not (bb[2] < bx0 or bb[0] > bx1 or bb[3] < by0 or bb[1] > by1)

    surf = cairo.ImageSurface(cairo.FORMAT_RGB24, W * SS * O, H * SS * O)
    ctx = cairo.Context(surf)
    ctx.scale(SS * O, SS * O)
    ctx.translate(-ox, -oy)
    ctx.set_source_rgb(*PAPER)
    ctx.paint()
    evolve = bool(os.environ.get("CM_EVOLVE"))
    if evolve:
        # zemin: orijinal haritanın kendisi (dağ, orman, kıyı, nehir onun), tona sonra çevrilir
        import relief as RL
        Bc = getattr(RL, "_BASE_RGB", None)
        if Bc is None:
            from PIL import Image as _I
            RL._BASE_RGB = Bc = np.asarray(_I.open(os.environ["CM_BASEMAP"]).convert("RGB"), np.float32) / 255
        s = Bc.shape[0] / N
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        lum = Bc @ np.array([0.3, 0.59, 0.11], np.float32)
        L = ndi.map_coordinates(lum, [oy * s + yy * s, ox * s + xx * s], order=3, mode="nearest")
        bl = ndi.gaussian_filter(L, 3.0)
        L = np.clip(L + (L - bl) * 0.8, 0, 1)                       # hafif keskinleştirme
        L = np.clip((L - 0.18) / 0.70, 0, 1) * 0.92 + 0.04
        g = (L * 255).astype(np.uint8)
        rgba = np.dstack([g, g, g, np.full_like(g, 255)])
        srf = cairo.ImageSurface.create_for_data(memoryview(np.ascontiguousarray(rgba)), cairo.FORMAT_ARGB32, W, H)
        ctx.save(); ctx.set_source_surface(srf, ox, oy); ctx.paint(); ctx.restore()
    for i, c in enumerate([] if evolve else sc["coasts"]):
        if hit(c["bbox"]):
            ink(ctx, c["pts"], np.random.default_rng(i), c["w"], closed=True, amp=0.6, alpha=c["al"])
    for i, w in enumerate([] if evolve else sc["waves"]):
        if hit((w["x"] - 15, w["y"] - 5, w["x"] + 15, w["y"] + 5)):
            IG.wave(ctx, np.random.default_rng(50_000 + i), w["x"], w["y"], w["s"])
    # dağlar: boyanmış ışık-gölge (gerçekçi), üstünde kar
    if os.environ.get("CM_DEM") and not evolve:
        import relief as RL
        m = 96
        kp = scene_keep(sc, (ox - m, oy - m, W + 2 * m, H + 2 * m))
        dk, lt, sn, el = RL.dem_shade(F.crop("mount", ox - m, oy - m, W + 2 * m, H + 2 * m),
                                  F.crop("water", ox - m, oy - m, W + 2 * m, H + 2 * m) > 0.5,
                                  ox - m, oy - m, W + 2 * m, H + 2 * m, kp)
        base = np.clip(el / 6.0, 0, 1)                          # dağ gövdesi (kâğıt rengiyle örter)
        (dk, lt, sn, base), edge = RL.oblique([dk, lt, sn, base], el)
        sl = (slice(m, -m), slice(m, -m))
        _paint_rgba(ctx, PAPER, base[sl] * 0.92, ox, oy)
        _paint_rgba(ctx, INK, dk[sl] * 0.82 * (1 - 0.6 * sn[sl]), ox, oy)
        _paint_rgba(ctx, INK, ndi.gaussian_filter(edge, 0.6)[sl] * base[sl] * 0.9, ox, oy)
        _paint_rgba(ctx, (0.99, 0.97, 0.91), np.clip(lt[sl] * 0.55 + sn[sl] * 0.75, 0, 1), ox, oy)
        sc = dict(sc, rock=[])
    elif os.environ.get("CM_RELIEF", "1") == "1" and not evolve and not SPRITE_DIR and not os.environ.get("CM_PEAKS"):
        import relief as RL
        m = 8
        if os.environ.get("CM_VEC"):
            dk, md, lt, ed, mzk = RL.vector_tones(F.crop("height", ox - m, oy - m, W + 2 * m, H + 2 * m),
                                                  F.crop("mount", ox - m, oy - m, W + 2 * m, H + 2 * m),
                                                  F.crop("water", ox - m, oy - m, W + 2 * m, H + 2 * m) > 0.5,
                                                  ox - m, oy - m, scene_keep(sc, (ox - m, oy - m, W + 2 * m, H + 2 * m)))
            sl = (slice(m, -m), slice(m, -m))
            _paint_rgba(ctx, INK, md[sl] * 0.22, ox, oy)
            _paint_rgba(ctx, INK, dk[sl] * 0.55, ox, oy)
            _paint_rgba(ctx, (0.99, 0.97, 0.90), lt[sl] * 0.6, ox, oy)
            _paint_rgba(ctx, INK, ed[sl] * 0.8, ox, oy)
            dk = None
        else:
          dk, lt, mzk = (RL.painted if os.environ.get('CM_BASEMAP') else RL.shade)(F.crop("height", ox - m, oy - m, W + 2 * m, H + 2 * m),
                               F.crop("mount", ox - m, oy - m, W + 2 * m, H + 2 * m),
                               F.crop("water", ox - m, oy - m, W + 2 * m, H + 2 * m) > 0.5, ox - m, oy - m,
                               scene_keep(sc, (ox - m, oy - m, W + 2 * m, H + 2 * m)))
        if dk is not None:
            sl = (slice(m, -m), slice(m, -m))
            _paint_rgba(ctx, (0.93, 0.88, 0.76), mzk[sl] * 0.55, ox, oy)       # kaya zemini, kâğıttan biraz açık
            _paint_rgba(ctx, INK, dk[sl] * 0.85, ox, oy)
            _paint_rgba(ctx, (0.99, 0.97, 0.90), lt[sl] * 0.55, ox, oy)
        sc = dict(sc, rock=[r for r in sc.get("rock", []) if r[3] in ("snowfill", "snowedge")])
    # dağlar: tarama, kar, sonra çatlak ve sırt çizgileri
    rock = [] if evolve else [r for r in sc.get("rock", []) if hit(r[4])]
    from hand import path as hpath
    for kinds in (("tone",), ("hach", "hatch"), ("snowfill",), ("spine", "spur", "sub", "crease", "ridge", "snowedge")):
        for i, (pts, w, al, kind, bb) in enumerate(rock):
            if kind not in kinds:
                continue
            g = np.random.default_rng(int(bb[0] * 7 + bb[1] * 13) % 2**31)
            if kind == "tone":
                hpath(ctx, pts, True)
                ctx.set_source_rgba(*INK, al)
                ctx.fill()
            elif kind == "snowfill":
                hpath(ctx, pts, True)
                ctx.set_source_rgba(*SNOW, al)
                ctx.fill()
            elif kind == "snowedge":
                SK.stroke(ctx, pts, g, w=w, taper=(1, 1, 1), alpha=al, amp=0.3)
            else:
                tp, amp = ROCK_DRAW[kind]
                SK.stroke(ctx, pts, g, w=w, taper=tp, alpha=al, amp=amp)
    # yollar: kâğıt renginde bir yatak (taramayı keser), ortasında sürekli mürekkep çizgisi
    _road_raster(ctx, F, ox, oy, W, H)
    for o in sc["objs"]:
        y, kind, d, bb = o
        if not hit(bb):
            continue
        g = np.random.default_rng(d["seed"])
        if kind == "peak":
            IG.peak(ctx, g, d["x"], d["y"], d["W"], d["H"], d["snow"])
        elif kind == "hill":
            IG.hill(ctx, g, d["x"], d["y"], d["W"])
        elif kind == "tree" and evolve:
            continue
        elif kind == "msprite":
            s, (sw, sh), _ = _sprite(d["name"], d["flip"])
            k = d["w"] / sw
            ctx.save()
            ctx.translate(d["x"] - d["w"] / 2, d["y"] - sh * k)
            ctx.scale(k, k)
            ctx.set_source_surface(s, 0, 0)
            ctx.get_source().set_filter(cairo.FILTER_GOOD)
            ctx.paint()
            ctx.restore()
        elif kind == "tree":
            SK.tree(ctx, g, d["x"], d["y"], d["s"], d["kind"])
        elif kind == "ship":
            B.ship(ctx, g, d["x"], d["y"], 0.95, d["face"])
        elif kind == "boat":
            B.boat(ctx, g, d["x"], d["y"], 1.1, d["face"])
        elif kind == "serai":
            IG.caravanserai(ctx, g, d["cx"], d["cy"], 1.15)
        elif kind == "city":
            wx0, wy0, Wn = d["win"]
            terr = local_terrain(F, wx0, wy0, Wn)
            ctx.save()
            ctx.translate(wx0, wy0)
            SH.city(ctx, g, terr, d["fp"], d["cul"], d["R"], d["port"])
            ctx.restore()
        elif kind == "small":
            ctx.save()
            ctx.translate(d["cx"], d["cy"])
            ctx.scale(d["k"], d["k"])
            ctx.translate(-d["cx"], -d["cy"])
            fn = dict(swamp=T.swamp_town, village=T.village, farm=T.farm, lumber=T.lumber, abbey=T.abbey,
                      tower=T.tower_post, camp=T.camp, fish=T.fish_village, mine=T.mine_town,
                      lighthouse=T.lighthouse, deepmine=T.deep_mine, hillfort=T.hill_fort).get(d["kind"])
            if fn:
                fn(ctx, g, d["cx"], d["cy"], d["cul"])
            elif d["kind"] in ("ruins", "graveyard", "wreck"):
                getattr(IG, d["kind"])(ctx, g, d["cx"], d["cy"])
            else:
                getattr(T, d["kind"])(ctx, g, d["cx"], d["cy"])
            ctx.restore()
    # yazılar
    for lb in sc["labels"]:
        if not hit((lb["x"] - 300, lb["y"] - 60, lb["x"] + 300, lb["y"] + 20)):
            continue
        _text(ctx, lb["text"], lb["x"], lb["y"], lb["fs"], italic=lb["kind"] == "serai")
    _arch(ctx, hit)
    buf = np.frombuffer(surf.get_data(), np.uint8).reshape(H * SS * O, W * SS * O, 4)[..., [2, 1, 0]]
    img = Image.fromarray(buf.copy())
    del buf, surf
    return img.resize((W * O, H * O), Image.LANCZOS)


def _text(ctx, text, cx, y, fs, italic=False, face="IM FELL English SC", track=0.12):
    ctx.select_font_face(face)
    ctx.set_font_size(fs)
    tr = fs * track
    tw = sum(ctx.text_extents(ch).x_advance + tr for ch in text) - tr
    x = cx - tw / 2
    ctx.save()
    for ch in text:
        ctx.move_to(x, y)
        ctx.text_path(ch)
        x += ctx.text_extents(ch).x_advance + tr
    ctx.set_source_rgba(*PAPER, 0.85)
    ctx.set_line_width(fs * 0.22)
    ctx.set_line_join(cairo.LINE_JOIN_ROUND)
    ctx.stroke_preserve()
    ctx.set_source_rgb(*INK)
    ctx.fill()
    ctx.restore()


def _furniture(ctx, sc, hit):
    """Kartuş (sol alt denizde), pusula gülü (sağ üst denizde), çerçeve."""
    import sketch as SK
    rng = np.random.default_rng(5)
    # pusula gülü
    px, py, R = N - 700, 650, 260
    if hit((px - R - 60, py - R - 60, px + R + 60, py + R + 60)):
        for k in range(16):
            a = k * math.pi / 8 - math.pi / 2
            L = R if k % 4 == 0 else R * 0.62 if k % 2 == 0 else R * 0.38
            wdt = 26 if k % 4 == 0 else 16 if k % 2 == 0 else 9
            tip = (px + L * math.cos(a), py + L * math.sin(a))
            l = (px + wdt * math.cos(a - math.pi / 2), py + wdt * math.sin(a - math.pi / 2))
            r_ = (px + wdt * math.cos(a + math.pi / 2), py + wdt * math.sin(a + math.pi / 2))
            ctx.move_to(*l)
            ctx.line_to(*tip)
            ctx.line_to(px, py)
            ctx.close_path()
            ctx.set_source_rgb(*INK)
            ctx.fill()
            ctx.move_to(*r_)
            ctx.line_to(*tip)
            ctx.line_to(px, py)
            ctx.close_path()
            ctx.set_source_rgb(*PAPER)
            ctx.fill_preserve()
            ctx.set_source_rgb(*INK)
            ctx.set_line_width(1.6)
            ctx.stroke()
        for rr_, lw in ((R * 0.72, 2.0), (R * 0.78, 1.0)):
            ctx.arc(px, py, rr_, 0, 2 * math.pi)
            ctx.set_line_width(lw)
            ctx.stroke()
        for t, (dx, dy) in zip("NESW", ((0, -1), (1, 0), (0, 1), (-1, 0))):
            _text(ctx, t, px + dx * (R + 45), py + dy * (R + 45) + 22, 64)


ARCH = None


def _arch_load():
    global ARCH
    if ARCH is None:
        import json
        ap = os.environ.get("CM_ARCH", "")
        ARCH = json.load(open(ap)) if ap and os.path.exists(ap) else {}
    return ARCH


def arch_outline(n=28):
    """Köprünün kaya gövdesi (harita pikseli): boğaza dik, kenarları düzensiz."""
    A = _arch_load()
    if not A:
        return None
    rng = np.random.default_rng(31)
    x, y, dx, dy, w = A["x"], A["y"], A["dx"], A["dy"], A["w"]
    nx, ny = -dy, dx
    L = w * 0.70
    t = np.linspace(-1, 1, n)
    waist = 13 + 5 * np.abs(t) ** 2                       # ortası ince, uçları kalın
    j1 = rng.normal(0, 1.6, n)
    j2 = rng.normal(0, 1.6, n)
    up = [(x + nx * L * u - dx * (h + e), y + ny * L * u - dy * (h + e)) for u, h, e in zip(t, waist, j1)]
    dn = [(x + nx * L * u + dx * (h + e), y + ny * L * u + dy * (h + e)) for u, h, e in zip(t[::-1], waist[::-1], j2)]
    return np.array(up + dn, np.float32)


def _arch(ctx, hit):
    """Boğazın ortasındaki doğal kaya köprüsü: yarlı, dar kaya kemer."""
    A = _arch_load()
    if not A:
        return
    x, y, dx, dy, w = A["x"], A["y"], A["dx"], A["dy"], A["w"]
    if not hit((x - w, y - w, x + w, y + w)):
        return
    poly = arch_outline()
    n = len(poly) // 2
    # akıntı yönünde kemerin gölgesi (suyun üstünde koyu yay)
    ctx.save()
    nx, ny = -dy, dx
    L = w * 0.70
    ctx.move_to(x - nx * L * 0.55 + dx * 20, y - ny * L * 0.55 + dy * 20)
    ctx.curve_to(x - nx * L * 0.2 + dx * 34, y - ny * L * 0.2 + dy * 34,
                 x + nx * L * 0.2 + dx * 34, y + ny * L * 0.2 + dy * 34,
                 x + nx * L * 0.55 + dx * 20, y + ny * L * 0.55 + dy * 20)
    ctx.set_source_rgba(*INK, 0.55)
    ctx.set_line_width(5.0)
    ctx.stroke()
    # gövde
    ctx.move_to(*poly[0])
    for q in poly[1:]:
        ctx.line_to(*q)
    ctx.close_path()
    ctx.set_source_rgb(*PAPER)
    ctx.fill_preserve()
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(1.8)
    ctx.stroke()
    # iki uzun kenarda yar taraması (içe doğru kısa çizgiler)
    ctx.set_line_width(0.9)
    for side, sgn in ((poly[n:], -1),):          # yalnız gölge (akıntı) tarafı
        for k in range(2, n - 2, 2):
            px, py = side[k]
            ln = 3 + 2 * ((k * 7) % 3)
            ctx.move_to(px, py)
            ctx.line_to(px + dx * sgn * ln, py + dy * sgn * ln)
    ctx.stroke()
    # üstte iki çatlak
    for u in (-0.3, 0.25):
        cx, cy = x + nx * L * u, y + ny * L * u
        ctx.move_to(cx - dx * 4, cy - dy * 4)
        ctx.line_to(cx + nx * 6 + dx * 3, cy + ny * 6 + dy * 3)
    ctx.stroke()
    ctx.restore()


def vector_roads(out, world_p, F, route):
    """Yollar kaynak vektörden: sudan geçen parçalar kesilir, yan yana koşan kopyalar
    tek orta çizgiye birleşir, bir yerleşime varmayan çıkmaz uçlar budanır.
    roads_clean.npy (hepsi) ve roads_main.npy (ana yollar) yazar."""
    import json
    from skimage.morphology import skeletonize
    sc = pickle.load(open(os.path.join(out, "scene_final.pkl"), "rb"))
    water = cv2.resize(F.f["water"], (N, N), interpolation=cv2.INTER_LINEAR) > 0.5
    roads = json.load(open(world_p))["roads"]
    MERGE = 13                                   # bu yarıçaptaki paralel izler tek yola iner

    def draw(mask, pts):
        pts = np.asarray(pts, np.float32)
        if len(pts) < 2:
            return
        cv2.polylines(mask, [np.round(pts).astype(np.int32)], False, 1, 2 * MERGE, cv2.LINE_8)

    def runs(pts, wet):
        """Suda olmayan ardışık parçalar."""
        cur = []
        for (x, y), w_ in zip(pts, wet):
            xi, yi = int(min(N - 1, max(0, x))), int(min(N - 1, max(0, y)))
            if w_ or water[yi, xi]:
                if len(cur) > 1:
                    yield cur
                cur = []
            else:
                cur.append((x, y))
        if len(cur) > 1:
            yield cur

    allm = np.zeros((N, N), np.uint8)
    mainm = np.zeros((N, N), np.uint8)
    for r in roads:
        pts = np.asarray(r["p"], np.float32) * P
        for seg in runs(pts, r["wet"]):
            draw(allm, seg)
            if r["c"] == "road":
                draw(mainm, seg)
    for seg in runs(np.asarray(route, np.float32), [False] * len(route)):
        draw(allm, seg)
        draw(mainm, seg)
    allm[water] = 0
    # iki iz arasında kalan küçük kapalı boşluklar iskelette göz/halka kavşak üretir: doldur
    from skimage.morphology import remove_small_holes
    allm = remove_small_holes(allm.astype(bool), area_threshold=30000)
    line = skeletonize(allm)
    # yerleşimler: yol uçları bunlara varmalı
    places = []
    for y_, kind, d, bb in sc["objs"]:
        if kind in ("city", "small", "serai"):
            places.append(((bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2, max(bb[2] - bb[0], bb[3] - bb[1]) / 2 + 40))
    places = np.array(places, np.float32)

    def near_place(x, y):
        return bool(len(places)) and bool(np.any(np.hypot(places[:, 0] - x, places[:, 1] - y) < places[:, 2]))

    K = np.ones((3, 3), np.uint8)
    pruned = 0
    for it in range(60):
        nb = ndi.convolve(line.astype(np.uint8), K, mode="constant") - line
        ends = np.argwhere(line & (nb == 1))
        bad = [(y, x) for y, x in ends if not near_place(x, y)]
        if not bad:
            break
        # her kötü uçtan kavşağa (komşu>2) kadar yürü ve sil; kısa iskelet çıkıntıları da bu yolla gider
        for y, x in bad:
            path = [(y, x)]
            cy, cx = y, x
            while True:
                ya, yb, xa, xb = max(0, cy - 1), min(N, cy + 2), max(0, cx - 1), min(N, cx + 2)
                nbr = [(a, b) for a in range(ya, yb) for b in range(xa, xb)
                       if (a, b) != (cy, cx) and line[a, b] and (a, b) not in path]
                if len(nbr) != 1 or len(path) > 4000:
                    break
                cy, cx = nbr[0]
                cnt = int(line[max(0, cy - 1):cy + 2, max(0, cx - 1):cx + 2].sum()) - 1
                if cnt > 2:
                    break
                path.append((cy, cx))
            for a, b in path:
                line[a, b] = False
            pruned += 1
    lab, n = ndi.label(line, structure=np.ones((3, 3)))
    sz = ndi.sum(line, lab, np.arange(1, n + 1))
    line = np.isin(lab, np.nonzero(sz >= 60)[0] + 1)
    main = line & ndi.binary_dilation(mainm.astype(bool), iterations=2)
    np.save(os.path.join(out, "roads_clean.npy"), np.packbits(line.ravel()))
    np.save(os.path.join(out, "roads_main.npy"), np.packbits(main.ravel()))
    print("vektör yollar: budanan uç", pruned, "piksel", int(line.sum()), "ana", int(main.sum()))


# ------------------------------------------------------------------ birleştir

# ------------------------------------------------------------------ dağ ve yol çizgileri

def scene_keep(sc, rect=None):
    """Kent, yerleşim, kervansaray ve yazı alanları: dağ çizgisi buraya girmez."""
    if rect is not None:
        rx, ry, rw, rh = rect
        full = scene_keep(dict(objs=[o for o in sc["objs"] if o[1] in ("city", "small", "serai")
                                     and not (o[3][2] < rx or o[3][0] > rx + rw or o[3][3] < ry or o[3][1] > ry + rh)],
                               labels=[l for l in sc["labels"] if rx - 400 < l["x"] < rx + rw + 400
                                       and ry - 80 < l["y"] < ry + rh + 80]))
        out = np.zeros((rh, rw), bool)
        ya, yb, xa, xb = max(0, ry), min(N, ry + rh), max(0, rx), min(N, rx + rw)
        out[ya - ry:yb - ry, xa - rx:xb - rx] = full[ya:yb, xa:xb]
        return out
    keep = np.zeros((N, N), bool)
    for y, kind, d, bb in sc["objs"]:
        if kind == "city":
            wx0, wy0, Wn = d["win"]
            m = ndi.binary_dilation(d["fp"][0], iterations=int(d["R"] * 0.35) + 6)
            for up in range(0, 64, 8):
                gx0, gy0 = wx0, wy0 - up
                ya, yb = max(0, gy0), min(N, gy0 + Wn)
                xa, xb = max(0, gx0), min(N, gx0 + Wn)
                if ya < yb and xa < xb:
                    keep[ya:yb, xa:xb] |= m[ya - gy0:yb - gy0, xa - gx0:xb - gx0]
        elif kind in ("small", "serai"):
            x0, y0, x1, y1 = [int(v) for v in bb]
            keep[max(0, y0 - 6):max(0, y1 + 6), max(0, x0 - 6):max(0, x1 + 6)] = True
    for lb in sc["labels"]:
        w = len(lb["text"]) * lb["fs"] * 0.62
        y, cx, fs = lb["y"], lb["x"], lb["fs"]
        keep[max(0, int(y - fs - 4)):max(0, int(y + 8)), max(0, int(cx - w / 2 - 8)):max(0, int(cx + w / 2 + 8))] = True
    return keep


def lines(F, sc, rect=None, block=1024, margin=64):
    import rock as RK
    import rock as RK
    keep = scene_keep(sc)
    x0, y0, x1, y1 = rect or (0, 0, N, N)
    rockl, roadl = [], []
    # eşikler bütün harita için bir kez (blok blok değişmesin); alan pikselinde
    # ölçülür, harita pikselinde ikinci türev P² kat küçülür
    hf = ndi.gaussian_filter(F.f["height"], 0.6)
    mf = F.f["mount"] > 0.6
    lam, _, _ = RK._hessian(hf, 3.0 / P)
    qc = float(np.quantile(lam[mf], 0.80)) / P ** 2
    lam, _, _ = RK._hessian(-hf, 3.4 / P)
    qr = float(np.quantile(lam[mf], 0.85)) / P ** 2
    gy, gx = np.gradient(ndi.gaussian_filter(F.f["height"], 1.5))
    gq = float(np.quantile(np.hypot(gx, gy)[mf], 0.85)) / P
    del gx, gy
    del lam
    # kar: kuzeyde mutlak yükseklikten, alan pikselinde tek parça
    hs = ndi.gaussian_filter(F.f["height"], 1.0)
    north = np.clip((1500 - np.arange(NMAP)[:, None]) / 350.0, 0, 1)
    thr = 54 - 16 * north
    wd = ndi.distance_transform_edt(F.f["water"] < 0.5)
    kd = cv2.resize(keep.astype(np.uint8), (NMAP, NMAP), interpolation=cv2.INTER_AREA) > 0
    cap = (hs > thr) & (north > 0.02) & (F.f["mount"] > 0.58) & (wd > 4) & ~kd
    cap = ndi.binary_opening(cap, iterations=1)
    cap = ndi.binary_closing(cap, iterations=2) & ~kd
    cs, _ = cv2.findContours(cap.astype(np.uint8), cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
    for cnt in cs:
        if cv2.contourArea(cnt) < 110:
            continue
        pts = cv2.approxPolyDP(cnt.astype(np.float32), 0.7, True)[:, 0, :].astype(np.float32) * P + P / 2
        if len(pts) < 4:
            continue
        bb = (pts[:, 0].min() - 2, pts[:, 1].min() - 2, pts[:, 0].max() + 2, pts[:, 1].max() + 2)
        if bb[2] < x0 or bb[0] > x1 or bb[3] < y0 or bb[1] > y1:
            continue
        rockl.append((pts, 0.0, 0.93, "snowfill", bb))
        rockl.append((np.vstack([pts, pts[:1]]), 0.55, 0.6, "snowedge", bb))
    del hs, wd, cap
    for by in range(y0, y1, block):
        for bx in range(x0, x1, block):
            ox, oy = bx - margin, by - margin
            S = block + 2 * margin
            g = lambda k: F.crop(k, ox, oy, S, S)
            water = g("water") > 0.5
            kp = np.zeros((S, S), bool)
            ya, yb, xa, xb = max(0, oy), min(N, oy + S), max(0, ox), min(N, ox + S)
            kp[ya - oy:yb - oy, xa - ox:xb - ox] = keep[ya:yb, xa:xb]
            roads = g("roads") > 0.5
            rng = np.random.default_rng(bx * 31 + by)
            import herring as HB
            for pts, w, al, kind in HB.build(g("height"), g("mount"), water, kp, roads, rng):
                p0 = pts[0]
                if not (margin <= p0[0] < margin + block and margin <= p0[1] < margin + block):
                    continue
                pts = pts + (ox, oy)
                bb = (pts[:, 0].min() - w, pts[:, 1].min() - w, pts[:, 0].max() + w, pts[:, 1].max() + w)
                rockl.append((pts, w, al, kind, bb))
            print("blok", bx, by, len(rockl), len(roadl), flush=True)
    return rockl, roadl


def fix_scene(sc, F):
    """Önceki hazırlıktan kalanlar: kervansaray adları, dağdaki ağaçlar, tepe simgeleri."""
    old = {"Kesimer Caravanserai": "Orbeyan Caravanserai", "Haldrun Caravanserai": "Duvenmor Caravanserai"}
    for lb in sc["labels"]:
        lb["text"] = old.get(lb["text"], lb["text"])
    m = F.f["mount"]
    import shaped as SH
    objs = []
    for o in sc["objs"]:
        y, kind, d, bb = o
        if kind == "city":                      # şekil yeniden: araziden
            wx0, wy0, Wn = d["win"]
            p = d["p"]
            terr = local_terrain(F, wx0, wy0, Wn)
            fp = SH.footprint(terr, p["x"] * P - wx0, p["y"] * P - wy0, d["R"], np.random.default_rng(p["id"]), d["port"])
            if fp is not None:
                d = dict(d, fp=fp)
                ys = np.nonzero(fp[0])[0]
                o = (wy0 + float(ys.max()), kind, d, bb)
        if kind in ("peak", "hill"):
            continue
        if kind == "tree" and m[int(min(NMAP - 1, d["y"] / P)), int(min(NMAP - 1, d["x"] / P))] > 0.40:
            continue
        objs.append(o)
    sc["objs"] = objs
    return sc


def finish(img_u8, rng_seed=4, full=True):
    """Mürekkep-parşömen ikili tonu (+ kar için kâğıttan açık bir ton)."""
    from paper import noise
    H, W = img_u8.shape[:2]
    a = img_u8.astype(np.float32) / 255
    lum = a @ np.array([0.3, 0.59, 0.11], np.float32)
    del a
    t = np.clip((lum - 0.12) / (0.90 - 0.12), 0, 1) ** 0.95
    hl = np.clip((lum - 0.925) / 0.04, 0, 1)
    ink_c = np.array([0.14, 0.10, 0.07], np.float32)
    paper_c = np.array([0.86, 0.78, 0.62], np.float32)
    snow_c = np.array([0.94, 0.905, 0.81], np.float32)
    rng = np.random.default_rng(rng_seed)
    blot = cv2.resize(noise((max(8, H // 16), max(8, W // 16)), 5, rng), (W, H), interpolation=cv2.INTER_CUBIC)
    mid = cv2.resize(noise((max(8, H // 4), max(8, W // 4)), 2.5, rng), (W, H), interpolation=cv2.INTER_CUBIC)
    if full:
        yy, xx = np.ogrid[0:H, 0:W]
        r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
        vign = np.clip(r - 0.62, 0, 1) ** 1.4
    else:
        vign = 0
    tone = (1 - 0.03 * blot - 0.015 * mid - 0.55 * vign).astype(np.float32)
    out = np.empty((H, W, 3), np.uint8)
    for c in range(3):
        ch = (ink_c[c] + (paper_c[c] - ink_c[c]) * t) * (1 - hl) + snow_c[c] * hl
        out[..., c] = (np.clip(ch * tone, 0, 1) * 255).astype(np.uint8)
    return out


def sample(out, x0, y0, w, h, dst):
    sc = pickle.load(open(os.path.join(out, "scene.pkl"), "rb"))
    F = Fields(os.environ["CM_FIELDS"])
    sc = fix_scene(sc, F)
    global ROAD_LINE
    ROAD_LINE = road_line_global(F, os.path.join(out, "roads_line.npy"))
    if os.environ.get("CM_PEAKS"):
        sc["rock"] = []
        sc["objs"] = sorted(sc["objs"] + place_peaks(sc, F, (x0 - 200, y0 - 100, x0 + w + 200, y0 + h + 300)),
                            key=lambda o: o[0])
    elif SPRITE_DIR:
        sc["rock"] = []
        sc["objs"] = sorted(sc["objs"] + place_mountains(sc, F, (x0 - 200, y0 - 100, x0 + w + 200, y0 + h + 300)),
                            key=lambda o: o[0])
    else:
        rk, rd = lines(F, sc, (x0 - 256, y0 - 256, x0 + w + 256, y0 + h + 256), block=512)
        sc["rock"] = rk
    img = render(sc, F, x0, y0, w, h)
    Image.fromarray(finish(np.asarray(img), full=False)).save(dst, quality=93)
    print("örnek", dst)


# ------------------------------------------------------------------ dağ figürleri

SPRITE_DIR = os.environ.get("CM_SPRITES", "")
_SPR = {}


def sprite_list():
    import json
    meta = json.load(open(os.path.join(SPRITE_DIR, "meta.json")))
    return [m for m in meta if os.path.exists(os.path.join(SPRITE_DIR, m["name"] + ".png"))]


def _sprite(name, flip):
    k = (name, flip)
    if k not in _SPR:
        im = Image.open(os.path.join(SPRITE_DIR, name + ".png")).convert("RGBA")
        bb = im.getchannel("A").point(lambda v: 255 if v > 20 else 0).getbbox()
        im = im.crop(bb)
        if flip:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        a = np.asarray(im, np.float32) / 255
        pm = a.copy()
        pm[..., :3] *= pm[..., 3:4]                                   # cairo: önceden çarpılmış alfa
        bgra = (pm[..., [2, 1, 0, 3]] * 255).astype(np.uint8)
        s = cairo.ImageSurface.create_for_data(memoryview(np.ascontiguousarray(bgra)), cairo.FORMAT_ARGB32,
                                               im.size[0], im.size[1])
        _SPR[k] = (s, im.size, bgra)
    return _SPR[k]


def place_mountains(sc, F, rect=None, seed=17):
    """Dağ alanına figürleri diz: çekirdekte büyük, etekte küçük; arkadan öne."""
    rng = np.random.default_rng(seed)
    meta = sprite_list()
    plain = [m for m in meta if not m["snow"]]
    snowy = [m for m in meta if m["snow"]]
    x0, y0, x1, y1 = rect or (0, 0, N, N)
    W, H = x1 - x0, y1 - y0
    mz = ndi.gaussian_filter(F.crop("mount", x0, y0, W, H), 4)
    water = F.crop("water", x0, y0, W, H) > 0.5
    wd = ndi.distance_transform_edt(~water)
    keep = scene_keep(sc, (x0, y0, W, H))
    occ = np.zeros((H, W), bool)
    objs = []
    for big, step, lo in ((True, 58, 0.47), (False, 44, 0.32)):
        pts = lattice(mz > lo, step, step * 0.35, rng)
        order = rng.permutation(len(pts))
        for i in order:
            x, y = pts[i]
            xi, yi = int(x), int(y)
            m = mz[yi, xi]
            Wd = (62 + 70 * min(1, (m - 0.45) / 0.35)) * rng.uniform(0.85, 1.15) if big else rng.uniform(30, 46)
            fx0, fx1 = int(max(0, x - Wd * 0.45)), int(min(W - 1, x + Wd * 0.45))
            fy0, fy1 = int(max(0, y - Wd * 0.22)), int(min(H - 1, y + 2))
            if fx1 <= fx0 or fy1 <= fy0:
                continue
            fp = (slice(fy0, fy1), slice(fx0, fx1))
            if (wd[fp] < 5).any() or keep[fp].any() or (mz[fp] > lo - 0.08).mean() < 0.8:
                continue
            if occ[int(y), int(x)]:
                continue
            north = float(np.clip((3000 - (y + y0)) / 900.0, 0, 1))
            pool = snowy if (big and rng.random() < north) else plain
            mm = pool[int(rng.integers(len(pool)))]
            flip = bool(rng.random() < 0.5)
            ry, rx = int(Wd * 0.20), int(Wd * 0.40)
            occ[max(0, yi - ry):yi + ry, max(0, xi - rx):xi + rx] = True
            gx, gy = float(x + x0), float(y + y0)
            objs.append((gy, "msprite", dict(x=gx, y=gy, w=float(Wd), name=mm["name"], flip=flip, seed=0),
                         (gx - Wd / 2, gy - Wd * 0.9, gx + Wd / 2, gy + 2)))
    return objs


def place_peaks(sc, F, rect=None, seed=23):
    """Orta Dünya düzeni: tepeler sıradağın sırt çizgileri boyunca zincir halinde,
    birbirine binerek; kuşağın ortasında büyük, kenarında küçük; eteklerde tepecikler."""
    import herring as HB
    rng = np.random.default_rng(seed)
    x0, y0, x1, y1 = rect or (0, 0, N, N)
    W, H = x1 - x0, y1 - y0
    mz = ndi.gaussian_filter(F.crop("mount", x0, y0, W, H), 4)
    water = F.crop("water", x0, y0, W, H) > 0.5
    wd = ndi.distance_transform_edt(~water)
    keep = scene_keep(sc, (x0, y0, W, H))
    M = ndi.binary_opening((mz > 0.44) & (wd > 6), iterations=2)
    objs = []
    if M.sum() < 100:
        return objs
    tx, ty, D = HB._orient(M, 16.0)
    occ = np.zeros((H, W), np.uint8)
    ys, xs = np.nonzero(M & (D > 3))
    seeds = {}
    for i in rng.permutation(len(xs)):
        g = (xs[i] // 34, ys[i] // 34)
        if g not in seeds:
            seeds[g] = (xs[i], ys[i])
    seeds = sorted(seeds.values(), key=lambda p: -D[p[1], p[0]])
    sep = 42
    taken = []

    def ok(x, y, w, h):
        xa, xb = int(max(0, x - w / 2)), int(min(W - 1, x + w / 2))
        ya, yb = int(max(0, y - h)), int(min(H - 1, y + 3))
        if xb <= xa or yb <= ya:
            return False
        return (wd[ya:yb, xa:xb] > 3).all() and not keep[ya:yb, xa:xb].any()

    def north_of(x, y):
        # yalnız kuzeybatı dağları karlı
        gx, gy = (x + x0) / N, (y + y0) / N
        return float(np.clip((0.40 - gy) / 0.10, 0, 1) * np.clip((0.55 - gx) / 0.10, 0, 1))
    for sx, sy in seeds:
        if occ[sy, sx]:
            continue
        line = HB._stream(np.array([sx, sy], float), tx, ty, M, occ, rng.uniform(80, 260))
        if line is None or len(line) < 6:
            continue
        line = HB._smooth_line(line, 3)
        cv2.polylines(occ, [np.round(line).astype(np.int32)], False, 1, sep)
        seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(line, axis=0), axis=1))]
        s = rng.uniform(0, 6)
        while s < seg[-1]:
            x = float(np.interp(s, seg, line[:, 0])); y = float(np.interp(s, seg, line[:, 1]))
            dlt = D[int(y), int(x)]
            Wp = (30 + min(dlt, 50) * 1.0) * rng.uniform(0.75, 1.25)
            Hp = Wp * rng.uniform(0.52, 0.72)
            yb = y + rng.normal(0, 3)
            if ok(x, yb, Wp, Hp):
                nf = north_of(x, yb)
                snow = 0.0
                if nf > 0 and Hp > 18:
                    snow = float(np.clip(0.30 + 0.20 * nf + (Hp - 18) / 80, 0, 0.55)) if rng.random() < 0.95 * nf else 0.0
                taken.append((x, yb, Wp, Hp, snow))
            s += Wp * rng.uniform(0.55, 0.8)
    # eteklerde ve kenarda tepecikler
    for x, y in lattice((mz > 0.28) & (mz < 0.5) & (wd > 6), 40, 12, rng):
        if rng.random() < 0.5:
            continue
        Wh = rng.uniform(16, 28)
        if ok(x, y, Wh, Wh * 0.5) and not occ[int(y), int(x)]:
            objs.append((y + y0, "hill", dict(x=x + x0, y=y + y0, W=Wh, seed=int(rng.integers(1 << 30))),
                         (x + x0 - Wh, y + y0 - Wh, x + x0 + Wh, y + y0 + 4)))
    for x, y, Wp, Hp, snow in taken:
        gx, gy = x + x0, y + y0
        objs.append((gy, "peak", dict(x=gx, y=gy, W=Wp, H=Hp, snow=snow, seed=int(rng.integers(1 << 30))),
                     (gx - Wp, gy - Hp - 4, gx + Wp, gy + 4)))
    return objs


def _up(small, y0, y1, W, H):
    """Küçük ızgarayı (H,W) tam boyutun [y0,y1) satırlarına çift doğrusal büyüt."""
    sh, sw = small.shape
    ys = (np.arange(y0, y1, dtype=np.float32) + 0.5) * sh / H - 0.5
    xs = (np.arange(W, dtype=np.float32) + 0.5) * sw / W - 0.5
    yy = np.repeat(ys[:, None], W, 1)
    xx = np.repeat(xs[None, :], y1 - y0, 0)
    return ndi.map_coordinates(small, [yy, xx], order=1, mode="nearest").astype(np.float32)


def stitch(out):
    from paper import noise as _noise

    def noise(shape, sc, rng):              # 0..1'e normalize: genlikler gerçekten oran olsun
        a = _noise(shape, sc, rng).astype(np.float32)
        return (a - a.min()) / (a.max() - a.min() + 1e-6)
    n = N // TILE
    T = TILE * OUT
    NN = N * OUT
    img = np.zeros((NN, NN, 3), np.uint8)
    for ty in range(n):
        for tx in range(n):
            img[ty * T:(ty + 1) * T, tx * T:(tx + 1) * T] = np.asarray(
                Image.open(os.path.join(out, "tile_%d_%d.png" % (tx, ty))).convert("RGB"))
    rng = np.random.default_rng(4)
    # küçük ölçekli alanlar (bir kez), şerit şerit büyütülür
    G = 2048
    blot = noise((N // 16, N // 16), 5, rng).astype(np.float32)
    midn = noise((N // 4, N // 4), 2.5, rng).astype(np.float32)
    F = Fields(os.environ["CM_FIELDS"])
    w = cv2.resize(F.f["water"], (G, G), interpolation=cv2.INTER_AREA)
    wd = ndi.distance_transform_edt(w > 0.5).astype(np.float32) * (NMAP / G)
    wa_s = np.clip(cv2.GaussianBlur((w > 0.5).astype(np.float32), (0, 0), 0.7), 0, 1) * (0.62 + 0.22 * np.clip(wd / 120.0, 0, 1))
    ap = arch_outline()
    if ap is not None:                      # köprü kayası su tonunu almaz
        am = np.zeros((G, G), np.uint8)
        cv2.fillPoly(am, [np.round(ap * G / N).astype(np.int32)], 1)
        wa_s = wa_s * (1 - cv2.dilate(am, np.ones((3, 3), np.uint8)).astype(np.float32))
    wn = noise((N // 32, N // 32), 3, rng).astype(np.float32)
    S = G
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    inset = np.array([0.020, 0.032, 0.026, 0.017]) * S       # sol, üst, sağ, alt (asimetrik)
    d = np.minimum.reduce([xx - inset[0], yy - inset[1], (S - 1 - xx) - inset[2], (S - 1 - yy) - inset[3]])
    for (cx, cy), r in zip(((0, 0), (S, 0), (S, S), (0, S)), (0.10, 0.06, 0.13, 0.08)):
        d = np.minimum(d, np.hypot(xx - cx, yy - cy) - r * S * 0.9)
    big = cv2.resize(noise((24, 24), 2, rng), (S, S), interpolation=cv2.INTER_CUBIC)
    mid = cv2.resize(noise((96, 96), 2, rng), (S, S), interpolation=cv2.INTER_CUBIC)
    fine = cv2.resize(noise((400, 400), 2, rng), (S, S), interpolation=cv2.INTER_CUBIC)
    d = (d + (big - 0.5) * S * 0.030 + (mid - 0.5) * S * 0.010 + (fine - 0.5) * S * 0.004).astype(np.float32)
    ink_c = np.array([0.14, 0.10, 0.07], np.float32)
    paper_c = np.array([0.86, 0.78, 0.62], np.float32)
    snow_c = np.array([0.94, 0.905, 0.81], np.float32)
    wcol = np.array([0.40, 0.46, 0.50], np.float32)
    desk = np.array([24, 19, 15], np.float32) / 255
    px_per_d = NN / S
    STRIP = 1024
    for y0 in range(0, NN, STRIP):
        y1 = min(NN, y0 + STRIP)
        a = img[y0:y1].astype(np.float32) / 255
        lum = a @ np.array([0.3, 0.59, 0.11], np.float32)
        del a
        t = np.clip((lum - 0.12) / (0.90 - 0.12), 0, 1) ** 0.95
        hl = np.clip((lum - 0.925) / 0.04, 0, 1)
        tone = 1 - 0.03 * _up(blot, y0, y1, NN, NN) - 0.015 * _up(midn, y0, y1, NN, NN)
        wa = np.clip(_up(wa_s, y0, y1, NN, NN) * (0.96 + 0.04 * _up(wn, y0, y1, NN, NN)), 0, 1)
        paper = 1.0
        burn = 0.0
        for c_ in range(3):
            ch = (ink_c[c_] + (paper_c[c_] - ink_c[c_]) * t) * (1 - hl) + snow_c[c_] * hl
            ch = ch * tone
            ch = ch * (1 - wa) + ch * wcol[c_] * 1.25 * wa
            ch = ch * (1 - 0.55 * burn)
            ch = ch * paper + desk[c_] * (1 - paper)
            img[y0:y1, :, c_] = (np.clip(ch, 0, 1) * 255).astype(np.uint8)
        print("şerit", y0, flush=True)
    # kenar bandı (üretilmiş görünen dış şerit) kırpılır: sol, üst, sağ, alt pay
    cl, ct, cr, cb = (int(NN * f_) for f_ in (0.0114, 0.0101, 0.0114, 0.0126))
    full = Image.fromarray(img[ct:NN - cb, cl:NN - cr])
    del img
    full.save(os.path.join(out, "map_%d.png" % NN), compress_level=3)
    full.save(os.path.join(out, "map_%d.jpg" % NN), quality=90)
    small = full.resize((4096, int(4096 * full.size[1] / full.size[0])), Image.LANCZOS)
    small.save(os.path.join(out, "map_4096.jpg"), quality=92)
    print("TAMAM")


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "prep":
        prep(*sys.argv[2:6])
    elif cmd == "tile":
        tile(sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))
    elif cmd == "finalize":
        sc = pickle.load(open(os.path.join(sys.argv[2], "scene.pkl"), "rb"))
        F = Fields(os.environ["CM_FIELDS"])
        sc = fix_scene(sc, F)
        sc["rock"] = []
        objs = []
        B = 2048
        for by in range(0, N, B):            # bloklar halinde (bellek), kenar payıyla; tepe tabanı blok içindeyse alınır
            for bx in range(0, N, B):
                for o in place_peaks(sc, F, (bx - 160, by - 160, bx + B + 160, by + B + 160), seed=bx * 7 + by):
                    if bx <= o[2]["x"] < bx + B and by <= o[2]["y"] < by + B:
                        objs.append(o)
                print("blok", bx, by, len(objs), flush=True)
        sc["objs"] = sorted(sc["objs"] + objs, key=lambda o: o[0])
        road_line_global(F, os.path.join(sys.argv[2], "roads_line.npy"))
        pickle.dump(sc, open(os.path.join(sys.argv[2], "scene_final.pkl"), "wb"))
        print("TAMAM", len(objs))
    elif cmd == "vroads":
        F = Fields(os.environ["CM_FIELDS"])
        sc = pickle.load(open(os.path.join(sys.argv[2], "scene_final.pkl"), "rb"))
        vector_roads(sys.argv[2], sys.argv[3], F, sc["route"])
    elif cmd == "roads":
        sc = pickle.load(open(os.path.join(sys.argv[2], "scene_final.pkl"), "rb"))
        F = Fields(os.environ["CM_FIELDS"])
        line = road_line_global(F, os.path.join(sys.argv[2], "roads_line.npy"))
        clean = clean_roads(line, sc["route"])
        np.save(os.path.join(sys.argv[2], "roads_clean.npy"), np.packbits(clean.ravel()))
        print("TAMAM", int(line.sum()), int(clean.sum()))
    elif cmd == "sample":
        sample(sys.argv[2], *[int(v) for v in sys.argv[3:7]], sys.argv[7])
    else:
        stitch(sys.argv[2])
