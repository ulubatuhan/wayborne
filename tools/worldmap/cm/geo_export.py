"""Haritadaki tüm varlıkları GeoJSON olarak dışa aktarır (haritaya bakmadan okunabilsin).

usage: python3 -I geo_export.py <full_dir> <fields.npz> <places.json> <names_dir> <out.geojson>

Koordinat sistemi: teslim edilen harita görüntüsünün pikseli (x sağa, y aşağı).
  görüntü = 16384 px'lik tam render'dan kenar bandı kırpılmış hâli.
  img_x = 4 * u - CROP_L ,  img_y = 4 * v - CROP_T   (u, v: 4096'lık dünya ızgarası)
  img_x = 2 * x - CROP_L ,  img_y = 2 * y - CROP_T   (x, y: 8192'lik render ızgarası)
"""
import json
import math
import os
import pickle
import sys

import cv2
import numpy as np
from scipy import ndimage as ndi

full, fields_p, places_p, names_dir, out_p = sys.argv[1:6]
N, NMAP, NN = 8192, 4096, 16384
CL, CT, CR, CB = (int(NN * f) for f in (0.0114, 0.0101, 0.0114, 0.0126))
IMG_W, IMG_H = NN - CL - CR, NN - CT - CB


def img8(x, y):            # 8192 ızgarası -> görüntü pikseli
    return [round(2 * float(x) - CL, 1), round(2 * float(y) - CT, 1)]


def img4(u, v):            # 4096 ızgarası -> görüntü pikseli
    return [round(4 * float(u) - CL, 1), round(4 * float(v) - CT, 1)]


feats = []


def add(geom, **props):
    feats.append({"type": "Feature", "geometry": geom, "properties": props})


sc = pickle.load(open(os.path.join(full, "scene_final.pkl"), "rb"))
places = json.load(open(places_p, encoding="utf-8"))
i18n = json.load(open(os.path.join(names_dir, "names_i18n.json"), encoding="utf-8"))
sys.path.insert(0, names_dir)
from regions import REG, CULT, K  # noqa: E402

KIND = {"ic_": "kent", "it_": "kasaba", "ih_": "köy", "iv_": "köy", "in_": "göçebe kampı", "il_": "işletme",
        "ix_": "yapı/işaret"}
CULT_TR = {"gocebe": "Göçebe boyları", "dag": "Dağ kabileleri", "dag_maden": "Dağ kabileleri (maden)",
           "imparatorluk": "Kuzey, eski imparatorluk", "sinir": "Sınır halkları", "vadi": "Vadi",
           "ahit": "Eski Ahit", "guney": "Güney kentleri"}

# --- yerleşimler ve adlandırılmış yapılar (yalnız haritada çizilenler)
drawn_ids = {d["p"]["id"] for _, k, d, _ in sc["objs"] if k in ("city", "small")}
for p in places:
    if p["id"] not in drawn_ids:
        continue
    nm = i18n.get(str(p["id"]), {})
    cls = next((v for k, v in KIND.items() if p["k"].startswith(k)), "diğer")
    add({"type": "Point", "coordinates": img4(p["x"], p["y"])},
        id="place_%d" % p["id"], layer="yerleşim", class_=cls, kind=p["k"], type_tr=p.get("t"),
        name_tr=nm.get("tr", p.get("d")), name_en=nm.get("en", p.get("en")), name_zh=nm.get("zh", p.get("zh")),
        proper=nm.get("proper"), culture=p.get("c"), culture_tr=CULT_TR.get(p.get("c")),
        world_4096=[round(p["x"], 1), round(p["y"], 1)])

# --- kervansaraylar
for lb in sc["labels"]:
    if lb["kind"] == "serai":
        sx, sy = lb["x"], lb["y"] - 40
        add({"type": "Point", "coordinates": img8(sx, sy)}, id="serai_" + lb["text"].split()[0].lower(),
            layer="kervansaray", class_="kervansaray", name_en=lb["text"],
            name_tr=lb["text"].replace(" Caravanserai", " Kervansarayı"))

# --- kervan yolu
route = np.asarray(sc["route"], float)
route = route[::4] if len(route) > 400 else route
add({"type": "LineString", "coordinates": [img8(x, y) for x, y in route]}, id="caravan_route",
    layer="kervan_yolu", class_="kervan yolu", note="Kuzey başkentinden en güneydeki kente ana ticaret rotası")

# --- yol ağı: çizilen iskeletten grafik (düğüm = kavşak/uç, kenar = yol parçası)
line = np.unpackbits(np.load(os.path.join(full, "roads_clean.npy")))[:N * N].reshape(N, N).astype(bool)
main = np.unpackbits(np.load(os.path.join(full, "roads_main.npy")))[:N * N].reshape(N, N).astype(bool)
nb = ndi.convolve(line.astype(np.uint8), np.ones((3, 3), np.uint8), mode="constant") - line
node = line & (nb != 2)
ys, xs = np.nonzero(line)
pix = set(zip(ys.tolist(), xs.tolist()))
nodes = set(zip(*[a.tolist() for a in np.nonzero(node)]))
OFF = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
seen = set()
anchors = []                                    # adı olan noktalar: yerleşim + kervansaray
for f_ in feats:
    if f_["geometry"]["type"] == "Point":
        anchors.append((f_["geometry"]["coordinates"], f_["properties"].get("name_tr"), f_["properties"]["id"]))


def nearest_anchor(px, py, r=140):
    best, bd = None, r
    for (ax, ay), nm, aid in anchors:
        d = math.hypot(ax - px, ay - py)
        if d < bd:
            best, bd = (nm, aid), d
    return best


edges = 0
used_nodes = set()
starts = list(nodes) if nodes else []
for sy, sx in starts:
    for dy, dx in OFF:
        nxt = (sy + dy, sx + dx)
        if nxt not in pix or ((sy, sx), nxt) in seen:
            continue
        path = [(sy, sx), nxt]
        seen.add(((sy, sx), nxt))
        prev, cur = (sy, sx), nxt
        while cur not in nodes:
            nbrs = [(cur[0] + a, cur[1] + b) for a, b in OFF if (cur[0] + a, cur[1] + b) in pix
                    and (cur[0] + a, cur[1] + b) != prev]
            nbrs = [q for q in nbrs if q not in path[-3:]]
            if not nbrs:
                break
            prev, cur = cur, nbrs[0]
            path.append(cur)
        seen.add((cur, path[-2]))
        if len(path) < 4:
            continue
        arr = np.array([[x, y] for y, x in path], np.float32).reshape(-1, 1, 2)
        simp = cv2.approxPolyDP(arr, 1.5, False).reshape(-1, 2)
        is_main = float(np.mean([main[y, x] for y, x in path])) > 0.5
        coords = [img8(x, y) for x, y in simp]
        a_ = nearest_anchor(*coords[0])
        b_ = nearest_anchor(*coords[-1])
        length = float(np.sum(np.hypot(*np.diff(np.array(coords), axis=0).T)))
        edges += 1
        n0, n1 = "node_%d_%d" % (sx, sy), ("node_%d_%d" % (cur[1], cur[0]) if cur in nodes else None)
        used_nodes.update([(sy, sx)] + ([cur] if cur in nodes else []))
        add({"type": "LineString", "coordinates": coords}, id="road_%d" % edges, layer="yol", from_node=n0, to_node=n1,
            class_="ana yol" if is_main else "patika", length_px=round(length, 1),
            from_name=a_[0] if a_ else None, from_id=a_[1] if a_ else None,
            to_name=b_[0] if b_ else None, to_id=b_[1] if b_ else None)

for ny_, nx_ in sorted(used_nodes):
    deg = int(nb[ny_, nx_])
    c = img8(nx_, ny_)
    a_ = nearest_anchor(*c, r=90)
    add({"type": "Point", "coordinates": c}, id="node_%d_%d" % (nx_, ny_), layer="yol_düğümü",
        class_="kavşak" if deg > 2 else "yol ucu", degree=deg,
        at_name=a_[0] if a_ else None, at_id=a_[1] if a_ else None)

# --- alanlar: su (deniz/göl), orman, dağlık alan
F = np.load(fields_p)


def polys(mask, eps, min_area, **props):
    m = (mask.astype(np.uint8)) * 255
    cs, hier = cv2.findContours(m, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_SIMPLE)
    if hier is None:
        return 0
    hier = hier[0]
    cnt = 0
    for i, c in enumerate(cs):
        if hier[i][3] != -1 or cv2.contourArea(c) < min_area:
            continue
        rings = [c]
        j = hier[i][2]
        while j != -1:
            if cv2.contourArea(cs[j]) >= min_area:
                rings.append(cs[j])
            j = hier[j][0]
        geo = []
        for r in rings:
            s = cv2.approxPolyDP(r, eps, True).reshape(-1, 2)
            if len(s) < 3:
                continue
            ring = [img4(u, v) for u, v in s]
            geo.append(ring + [ring[0]])
        if geo:
            cnt += 1
            add({"type": "Polygon", "coordinates": geo}, **dict(props, id="%s_%d" % (props["layer"], cnt),
                                                                  area_world=round(float(cv2.contourArea(c)), 1)))
    return cnt


water = F["water"] > 0.5
lab, n = ndi.label(water)
border = set(np.unique(np.r_[lab[0], lab[-1], lab[:, 0], lab[:, -1]]).tolist()) - {0}
sea = np.isin(lab, list(border))
polys(sea, 2.0, 60, layer="deniz", class_="deniz")
polys(water & ~sea, 1.5, 30, layer="göl", class_="göl")
polys(~water, 2.0, 200, layer="kara", class_="kara/ada")
polys(F["forest"] > 0.5, 3.0, 400, layer="orman", class_="orman")
polys(F["mount"] > 0.47, 3.0, 400, layer="dağ", class_="dağlık alan")

# boğaz (kullanıcı düzenlemesi)
ap = os.path.join(full, "arch.json")
if os.path.exists(ap):
    a = json.load(open(ap))
    add({"type": "Point", "coordinates": img8(a["x"], a["y"])}, id="strait_kesgrav", layer="boğaz",
        class_="boğaz", name_tr="Kesgrav Boğazı (adsız; geçici ad)",
        note="Koy ile doğu denizi arasındaki boğazın ortası")

# --- kültür bölgeleri
for key, poly in REG.items():
    ring = [img4(x * K, y * K) for x, y in poly]
    add({"type": "Polygon", "coordinates": [ring + [ring[0]]]}, id="region_" + key, layer="bölge",
        class_="kültür bölgesi", culture=CULT[key], culture_tr=CULT_TR.get(CULT[key]))

# --- etiketler (haritada yazılı her ad, yazının konumu)
for i, lb in enumerate(sc["labels"]):
    add({"type": "Point", "coordinates": img8(lb["x"], lb["y"])}, id="label_%d" % i, layer="etiket",
        text=lb["text"], label_kind=lb["kind"], font_px=round(lb["fs"] * 2, 1))

# --- gemiler
for y_, k, d, bb in sc["objs"]:
    if k in ("ship", "boat"):
        add({"type": "Point", "coordinates": img8(d["x"], d["y"])}, layer="gemi", class_=k)

# 'class_' -> 'class'
for f_ in feats:
    if "class_" in f_["properties"]:
        f_["properties"]["class"] = f_["properties"].pop("class_")

counts = {}
for f_ in feats:
    counts[f_["properties"]["layer"]] = counts.get(f_["properties"]["layer"], 0) + 1
doc = {"type": "FeatureCollection",
       "wayborne_crs": {"birim": "teslim edilen harita görüntüsünün pikseli", "eksen": "x sağa, y aşağı",
                        "image_size": [IMG_W, IMG_H],
                        "from_world_4096": "img = 4 * world - [%d, %d]" % (CL, CT),
                        "from_render_8192": "img = 2 * render - [%d, %d]" % (CL, CT)},
       "counts": counts, "features": feats}
json.dump(doc, open(out_p, "w", encoding="utf-8"), ensure_ascii=False)
print("özellik", len(feats), counts)
