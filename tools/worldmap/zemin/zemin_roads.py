"""Yolları araziye göre yeniden yönlendirir.

world.json'daki yollar düz çizgilerdi: denizin, dağın üstünden geçiyordu.
Bir harita yolunun mantığı:
  * su geçilmez - ancak etrafından dolanmak çok uzunsa feribot (kesik çizgi);
  * dağ pahalı: yol vadiden ve geçitten geçer;
  * orman geçilebilir (referans haritada yollar ormanı yarar), açık arazi kadar ucuz değil;
  * yollar birbirini izler: bir kez açılmış yol ucuzlar, yeni yol ona katılır.
Uç noktalar (yerleşimler) değişmez. Girdi world.json'a dokunulmaz; çıktı
`world_zemin.json` (aynı şema; her yolun `ferry` alanı: suda geçen parça
indeksleri).

    python3 -I zemin_roads.py <kök> <çıktı.json>
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import coast as coastline  # noqa: E402
import zemin_paint  # noqa: E402

N = 4096
G = 512           # yönlendirme ızgarası (8 px hücre)
CELL = N / G
COST_LAND = 1.0
COST_FOREST = 1.8
COST_MOUNT = 7.0
COST_CORE = 20.0
COST_WATER = 70.0  # feribot: ancak büyük dolambacı önlüyorsa
REUSE = 0.45       # açılmış yolun maliyet çarpanı


def cost_grid(root):
    water = coastline.water_mask(root, N)
    w = np.asarray(Image.fromarray(water.astype(np.uint8) * 255).resize((G, G), Image.BILINEAR)) > 127
    mount = zemin_paint.load(root, "mask_mountain.png", G)
    forest = zemin_paint.load(root, "mask_forest.png", G)
    rel = coastline.relief(root, G)
    m = np.maximum(ndi.gaussian_filter(mount, 1.0), rel)
    core = ndi.gaussian_filter((ndi.gaussian_filter(m, 2.0) > 0.7).astype(np.float32), 1.0)
    c = COST_LAND + (COST_FOREST - COST_LAND) * forest + (COST_MOUNT - COST_LAND) * m + COST_CORE * core
    # hafif gürültü: yol cetvel gibi değil, arazinin küçük engellerinden kıvrılarak
    c = c * (0.8 + 0.5 * zemin_paint.fbm(G, 17, 6, 3))
    c = np.where(w, COST_WATER, c)
    return c.astype(np.float64), w


def los_smooth(cells, c, water):
    """Görüş hattı düzleştirme: hücre yolunu, maliyeti belirgin artırmayan en uzun
    düz parçalarla kısaltır - ızgaranın 45 derecelik basamakları gider."""
    out = [0]
    i = 0
    n = len(cells)
    while i < n - 1:
        best = i + 1
        path_cost = 0.0
        j_lim = min(n - 1, i + 22)
        for j in range(i + 1, j_lim + 1):
            path_cost += c[cells[j][1], cells[j][0]]
            a, b = cells[i], cells[j]
            k = int(max(abs(b[0] - a[0]), abs(b[1] - a[1]))) + 1
            xs = np.round(np.linspace(a[0], b[0], k)).astype(int)
            ys = np.round(np.linspace(a[1], b[1], k)).astype(int)
            seg_cost = c[ys, xs].sum() * (np.hypot(b[0] - a[0], b[1] - a[1]) / max(1, k))
            wet_ok = water[ys, xs].sum() <= sum(water[cells[t][1], cells[t][0]] for t in range(i, j + 1))
            if seg_cost <= path_cost * 1.02 and wet_ok:
                best = j
        out.append(best)
        i = best
    return out


def build_graph(c):
    idx = np.arange(G * G).reshape(G, G)
    rows, cols, vals = [], [], []
    for dy, dx in ((0, 1), (1, 0), (1, 1), (1, -1)):
        a = idx[0:G - dy, max(0, -dx):G - max(0, dx)]
        b = idx[dy:G, max(0, dx):G + min(0, dx)]
        ca = c.ravel()[a.ravel()]
        cb = c.ravel()[b.ravel()]
        wgt = (ca + cb) / 2 * (1.4142 if dx and dy else 1.0)
        rows += [a.ravel(), b.ravel()]
        cols += [b.ravel(), a.ravel()]
        vals += [wgt, wgt]
    r = np.concatenate(rows)
    cc = np.concatenate(cols)
    v = np.concatenate(vals)
    return coo_matrix((v, (r, cc)), shape=(G * G, G * G)).tocsr()


def to_cell(p):
    return int(np.clip(p[1] / CELL, 0, G - 1)) * G + int(np.clip(p[0] / CELL, 0, G - 1))


def meander(p, seed):
    """Yola yanlamasına küçük kıvrım: uçlar sabit, ortası ±5 px."""
    if len(p) < 5:
        return p
    rng = np.random.default_rng(seed)
    t = np.linspace(0, 1, len(p))
    d = np.gradient(p, axis=0)
    nrm = np.stack([-d[:, 1], d[:, 0]], 1)
    nrm /= np.linalg.norm(nrm, axis=1, keepdims=True) + 1e-9
    s = np.cumsum(np.hypot(*d.T))
    off = 5 * np.sin(s / 55 + rng.random() * 6) * np.sin(np.pi * t) ** 0.5
    return p + nrm * off[:, None]


def chaikin(p, k=3):
    p = np.asarray(p, np.float64)
    for _ in range(k):
        q = [p[0]]
        for a, b in zip(p[:-1], p[1:]):
            q += [a * 0.75 + b * 0.25, a * 0.25 + b * 0.75]
        q.append(p[-1])
        p = np.array(q)
    return p


def route(root):
    world = json.load(open(os.path.join(root, "data", "world.json")))
    c, water = cost_grid(root)
    roads = sorted(world["roads"], key=lambda r: 0 if r["c"] == "road" else 1)  # ana yollar önce
    out = []
    stats = {"water_cells_before": 0, "water_cells_after": 0, "ferries": 0}
    for rd in roads:
        p = np.array(rd["p"], np.float64)
        # eski yolun suda geçen hücreleri (ölçüm için)
        for a, b in zip(p[:-1], p[1:]):
            for t in np.linspace(0, 1, 20):
                q = a + (b - a) * t
                stats["water_cells_before"] += int(water[int(np.clip(q[1] / CELL, 0, G - 1)), int(np.clip(q[0] / CELL, 0, G - 1))])
        g = build_graph(c)
        s, e = to_cell(p[0]), to_cell(p[-1])
        dist, pred = dijkstra(g, indices=s, return_predecessors=True)
        path = [e]
        while path[-1] != s and pred[path[-1]] >= 0:
            path.append(pred[path[-1]])
        path = path[::-1]
        cells = np.array([(i % G, i // G) for i in path])
        pts = (cells + 0.5) * CELL
        pts[0], pts[-1] = p[0], p[-1]
        keep = los_smooth(cells, c, water)
        sm = meander(chaikin(pts[keep], 4), len(out))
        wet = [int(water[int(np.clip(q[1] / CELL, 0, G - 1)), int(np.clip(q[0] / CELL, 0, G - 1))]) for q in sm]
        stats["water_cells_after"] += int(sum(water[y, x] for x, y in cells))
        if any(wet):
            stats["ferries"] += 1
        out.append({"c": rd["c"], "p": [[round(float(x), 1), round(float(y), 1)] for x, y in sm], "wet": wet})
        for x, y in cells:  # açılan yol ucuzlar
            c[y, x] = max(0.3, c[y, x] * REUSE) if not water[y, x] else c[y, x]
    world = dict(world)
    world["roads"] = out
    return world, stats


def main():
    root, dst = sys.argv[1], sys.argv[2]
    world, stats = route(root)
    json.dump(world, open(dst, "w"))
    print("YAZILDI", dst, stats)


if __name__ == "__main__":
    main()
