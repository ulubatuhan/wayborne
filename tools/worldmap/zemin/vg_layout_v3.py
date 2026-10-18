"""Yerleşim planı v3: her yerleşime kültür, denize gemiler.

  * kültür: kullanıcının çizdiği bölgelerden (atlas/names/regions.py);
  * boğaz gemileri: ana kıta ile güneydoğu karası arasında, eski yolun
    geçtiği hatta üç gemi;
  * liman gemileri: liman kentlerinin açık denize bakan yanında iki gemi;
  * balıkçı tekneleri: balıkçı kasabalarının kıyı açığında iki-üç küçük tekne.

    python3 -I vg_layout_v3.py <layout_v2.json> <fields.npz> <regions.py klasörü> <çıktı.json>
"""
import json
import math
import sys

import numpy as np
from scipy import ndimage as ndi

src, fields, regdir, dst = sys.argv[1:5]
sys.path.insert(0, regdir)
from regions import CULT, region_of  # noqa: E402

L = json.load(open(src))
F = np.load(fields)
water = F["water"] > 0.5
sea = ndi.distance_transform_edt(water)      # sudan karaya uzaklık (su içinde)
rng = np.random.default_rng(23)


def wat(x, y):
    xi, yi = int(round(x)), int(round(y))
    return 0 <= xi < 4096 and 0 <= yi < 4096 and water[yi, xi]


def depth(x, y):
    xi, yi = int(round(x)), int(round(y))
    return float(sea[np.clip(yi, 0, 4095), np.clip(xi, 0, 4095)])


def pick(cx, cy, rmin, rmax, dmin, dmax, n, sep, prefer_open):
    cands = []
    for _ in range(4000):
        a = rng.random() * 2 * math.pi
        r = rmin + rng.random() * (rmax - rmin)
        x, y = cx + r * math.cos(a), cy + r * math.sin(a)
        if not wat(x, y):
            continue
        d = depth(x, y)
        if dmin <= d <= dmax:
            cands.append((d if prefer_open else -abs(d - (dmin + dmax) / 2), x, y))
    cands.sort(reverse=True)
    out = []
    for _, x, y in cands:
        if all(math.hypot(x - a, y - b) > sep for a, b in out):
            out.append((x, y))
        if len(out) == n:
            break
    return out


def heading(x, y, cx, cy, along):
    a = math.atan2(y - cy, x - cx) + (math.pi / 2 if along else 0) + rng.normal(0, 0.35)
    return [math.cos(a), math.sin(a)]


for e in L:
    r, _ = region_of(*e["center"])
    e["culture"] = CULT[r]

ships = []
# boğaz: ana kıta ile güneydoğu karası arasındaki geniş su, açık ortası
for (x, y), sg in (((3560, 3500), 1), ((3600, 3650), -1), ((3440, 3720), 1)):
    assert wat(x, y), (x, y)
    d = np.array([0.5, 0.87]) * sg
    ships.append({"c": [x, y], "u": (d / np.linalg.norm(d)).tolist(), "size": "big"})
# liman kentleri
for e in L:
    if e["kind"] == "ic_portcity" or (e["kind"] in ("ic_city", "ic_freecity") and e.get("piers")):
        cx, cy = e["center"]
        for x, y in pick(cx, cy, 110, 300, 40, 400, 2, 120, True):
            ships.append({"c": [x, y], "u": heading(x, y, cx, cy, True), "size": "big"})
# balıkçı tekneleri
for e in L:
    if e["kind"] == "iv_fishvillage":
        cx, cy = e["center"]
        for x, y in pick(cx, cy, 35, 110, 10, 60, 3, 22, False):
            ships.append({"c": [x, y], "u": heading(x, y, cx, cy, False), "size": "small"})
L.append({"kind": "x_ships", "anchor": [2048, 2048], "center": [2048, 2048], "ships": ships, "houses": [],
          "culture": "none"})
json.dump(L, open(dst, "w"))
print("gemi", sum(s["size"] == "big" for s in ships), "tekne", sum(s["size"] == "small" for s in ships))
