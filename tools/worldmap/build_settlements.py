#!/usr/bin/env python3
"""Oynanabilir yerleşimleri ve aralarındaki yolları harita v3'ün GeoJSON'undan
kurar (görevler N1, N2, N3; §14 yeni dünya).

    python3 tools/worldmap/build_settlements.py <wayborne_harita.geojson> [çıktı.json] [rapor.md]

Varsayılan çıktı `data/config/settlements.json`.

- **Yerleşimler:** şehir (`ic_*`), kasaba (`it_*`) ve kervansaray. Kimlik özel
  addan, küçük harf ASCII (`vastrevar`); kervansaray `serai_<ad>`.
- **Yollar:** haritanın yol ağı (`yol`, `yol_düğümü`) ve kervan yolu. İki
  oynanabilir yer arasındaki komşuluk, yol ağında birinden ötekine **başka bir
  oynanabilir yerden geçmeden** varılan en kısa güzergâh. Güzergâhtaki köy, mezra,
  kule gibi oynanamayan yerler `via` listesine (yol durağı olarak).
- **Süre:** ölçek, en kuzeydeki oynanabilir yerden en güneydekine en kısa yol
  `NORTH_SOUTH_DAYS` gün edecek biçimde (kullanıcı kararı: Westeros 81 gün,
  bizimki 3/4'ü = 61). Kenar günü bu ölçekle, yuvarlanarak.
- **Tehlike:** yol sınıfı (kervan yolu < ana yol < patika), güzergâhın orman ve
  dağ payı ve bölge (sınır halkları daha tekin değil). Formül aşağıda; sayılar
  denge ölçümünde (N8) yeniden ayarlanır.
- **Arazi:** yol ekranının biyomları güzergâhın kendisinden: her nokta dağ
  (dağlık alan içinde), bataklık (bataklık kasabasının yakını), göl (göl ya da
  deniz kıyısı), orman (orman içinde ya da kıyısında) ya da bozkır (açık
  arazi). Etiketler yumuşatılıp en az `TERRAIN_MIN_SEG_DAYS` günlük parçalara
  birleşir. Parça sınırında durak: dağa girişte geçit, suda köprü, yakında
  bir harita noktası (kule, manastır, maden, mezra...) varsa onun karşılığı.
  Oyun bunu `RouteTerrain.build` ile okur; yol `terrain_from` şehrinden
  okunacak sırada yazılır, ters yönde oyun diziyi çevirir.

Koordinatlar teslim edilen harita görüntüsünün pikseli (16012x16013, x sağa,
y aşağı) - MapTileView ile aynı.
"""
import heapq
import json
import math
import os
import sys
from collections import defaultdict

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
DEFAULT_OUT = os.path.join(ROOT, "data", "config", "settlements.json")

NORTH_SOUTH_DAYS = 61
## Komşu iki yer arası en az bu kadar gün: bir günlük yol "hemen biten" yol (kullanıcı).
MIN_DAYS = 2
## Başlangıç yerinin en az bir komşusu bu kadar gün içinde olmalı.
START_MAX_FIRST_LEG = 10
## Kervan yolunun bir köşesi, bu kadar yakın bir yol düğümüne bağlanır (kervan
## yolu mevcut yolları izliyor; aynı kavşakta buluşuyorlar).
ROUTE_SNAP_PX = 48.0
## Bir yerleşim ya da kervansaray kervan yoluna bu kadar yakınsa yoldadır.
STATION_SNAP_PX = 140.0
## Yol ağına adıyla bağlanmamış bir yer, bu yakınlıktaki düğüme bağlanır.
ATTACH_PX = 1200.0
## Bu yakınlıktaki yol düğümleri aynı kavşak sayılır.
MERGE_PX = 24.0
## Yerleşimin kapladığı alan: bu yarıçaptaki kavşaklar onundur.
## Bir yol, yerin alanının bu payı kadar yakınından geçiyorsa yerin içinden geçer.
PASS_SHARE = 0.75
OWN_RADIUS = {"city": 420.0, "town": 300.0, "caravanserai": 220.0}
## Yol sınıfının temel tehlikesi.
CLASS_DANGER = {"kervan yolu": 0.15, "ana yol": 0.28, "patika": 0.42}
FOREST_DANGER = 0.18
MOUNTAIN_DANGER = 0.22
REGION_DANGER = {"sinir": 0.10, "gocebe": 0.06, "dag": 0.06, "dag_maden": 0.04,
                 "imparatorluk": -0.04, "vadi": -0.03, "guney": 0.0, "ahit": 0.0}
MASK_SCALE = 8  # tehlike maskeleri 1/8 çözünürlükte
PATH_POINT_SPACING = 48.0
# Arazi (yol ekranı biyomları)
WATER_NEAR_PX = 260.0     # göl/deniz kıyısı sayılan uzaklık
FOREST_NEAR_PX = 80.0     # yol ormanın kıyısından geçiyorsa da orman
# Haritanın yolları dağ çokgenlerinin içinden değil vadilerden geçiyor: dağın
# yakını ve dağ halklarının bölgesi de dağ yolu (ilk sürümde Brazdun-Kesgrav
# bozkır çıktı).
MOUNTAIN_NEAR_PX = 40.0  # dağ çokgenleri haritanın %22si; geniş bir kıyı her yeri dağ yapıyordu
MOUNTAIN_REGIONS = ("dag", "dag_maden")
STOP_MIN_GAP_DAYS = 3.0   # iki harita noktası durağı arası en az
MARSH_RADIUS_PX = 1100.0  # bataklık kasabasının çevresi
TERRAIN_SMOOTH = 7        # çoğunluk süzgeci (nokta)
TERRAIN_MIN_SEG_DAYS = 1.2
TERRAIN_MAX_SEGMENTS = 8
STOP_POI_PX = 650.0       # durağa dönüşecek harita noktasının yola uzaklığı
POI_STOPS = {
    "iw_tower": "outpost", "ir_ruins": "outpost", "ib_battle": "outpost", "ig_gallows": "outpost",
    "ip_lighthouse": "outpost", "ia_abbey": "shrine", "is_stones": "shrine", "ig_graveyard": "shrine",
    "ie_deepmine": "mine", "ie_saltmine": "mine", "ih_hamlet": "mezra", "iv_farm": "mezra",
    "iv_fishvillage": "mezra", "in_yurtcamp": "mezra", "ix_mountaintribe": "mezra", "il_lumber": "mezra",
}
TYPE_BY_PREFIX = {"ic_": "city", "it_": "town"}


def ascii_id(text):
    table = str.maketrans("çğıöşüâîûÇĞİÖŞÜ", "cgiosuaiuCGIOSU")
    out = text.translate(table).lower()
    return "".join(ch if ch.isalnum() else "_" for ch in out).strip("_")


def merge_nodes(nodes, radius):
    """Birbirine `radius` pikselden yakın düğümleri birleştirir (union-find)."""
    parent = {n: n for n in nodes}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    cells = defaultdict(list)
    for n, (x, y) in nodes.items():
        cells[(int(x // radius), int(y // radius))].append(n)
    for (cx, cy), members in cells.items():
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for m in cells.get((cx + dx, cy + dy), []):
                    for n in members:
                        if n < m and math.dist(nodes[n], nodes[m]) <= radius:
                            parent[find(n)] = find(m)
    return {n: find(n) for n in nodes}


def load(path):
    data = json.load(open(path, encoding="utf-8"))
    return data["features"], data["wayborne_crs"]["image_size"]


def raster(features, layer, size, value_of=None):
    """Bir katmanın çokgenlerini 1/MASK_SCALE ölçekli bir maskeye çizer."""
    w, h = size[0] // MASK_SCALE + 1, size[1] // MASK_SCALE + 1
    img = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(img)
    for f in features:
        if f["properties"].get("layer") != layer:
            continue
        geom = f["geometry"]
        polys = geom["coordinates"] if geom["type"] == "MultiPolygon" else [geom["coordinates"]]
        value = 255 if value_of is None else value_of(f["properties"])
        for poly in polys:
            ring = [(x / MASK_SCALE, y / MASK_SCALE) for x, y in poly[0]]
            if len(ring) >= 3:
                draw.polygon(ring, fill=value)
    return np.asarray(img)


def sample(mask, pts):
    h, w = mask.shape
    vals = []
    for x, y in pts:
        xi = min(max(int(x / MASK_SCALE), 0), w - 1)
        yi = min(max(int(y / MASK_SCALE), 0), h - 1)
        vals.append(mask[yi, xi])
    return vals


def polyline_length(pts):
    return sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))


def resample(pts, spacing):
    if not pts:
        return []
    out = [pts[0]]
    acc = 0.0
    for i in range(1, len(pts)):
        acc += math.dist(pts[i - 1], pts[i])
        if acc >= spacing:
            out.append(pts[i])
            acc = 0.0
    if out[-1] != pts[-1]:
        out.append(pts[-1])
    return out


def build(geojson_path):
    features, size = load(geojson_path)
    places = {}
    for f in features:
        p = f["properties"]
        if p.get("layer") == "yerleşim":
            places[p["id"]] = dict(p, pos=tuple(f["geometry"]["coordinates"]))
        elif p.get("layer") == "kervansaray":
            places[p["id"]] = dict(p, pos=tuple(f["geometry"]["coordinates"]), kind="ik_caravanserai",
                                   proper=p["name_en"].replace(" Caravanserai", ""))

    playable = {}
    for pid, p in places.items():
        kind = p.get("kind", "")
        stype = "caravanserai" if kind == "ik_caravanserai" else TYPE_BY_PREFIX.get(kind[:3])
        if stype is None:
            continue
        sid = "serai_" + ascii_id(p["proper"]) if stype == "caravanserai" else ascii_id(p["proper"])
        playable[pid] = {"id": sid, "type": stype, "map_kind": kind, "map_place_id": pid}

    # --- yol ağı
    nodes = {}
    node_place = {}
    adj = defaultdict(list)  # node -> [(node, length, class, coords)]
    raw_place = {}
    for f in features:
        p = f["properties"]
        if p.get("layer") == "yol_düğümü":
            nodes[p["id"]] = tuple(f["geometry"]["coordinates"])
            if p.get("at_id"):
                raw_place[p["id"]] = p["at_id"]
    # Harita dışa aktarımında kavşaklar her yol parçası için ayrı düğüm olarak
    # yazılmış (153 kopuk parça). Birkaç piksel içindeki düğümler aynı kavşaktır.
    canon = merge_nodes(nodes, MERGE_PX)
    nodes = {canon[n]: xy for n, xy in nodes.items() if canon[n] == n}
    for n, pid in raw_place.items():
        node_place.setdefault(canon[n], pid)
    for f in features:
        p = f["properties"]
        if p.get("layer") != "yol":
            continue
        coords = [tuple(c) for c in f["geometry"]["coordinates"]]
        a, b = canon[p["from_node"]], canon[p["to_node"]]
        if a == b:
            continue
        # Yolun uçlarındaki yer adı düğümde yazmayabiliyor; yolun kendisinde var.
        if p.get("from_id"):
            node_place.setdefault(a, p["from_id"])
        if p.get("to_id"):
            node_place.setdefault(b, p["to_id"])
        # Yol bir şehrin içinden geçip düğümü başka yerde olabilir: şehre en
        # yakın köşede yol bölünür ve o köşe şehrin kapısı olur.
        cuts = []
        for pid, s in playable.items():
            pos = places[pid]["pos"]
            best, best_d = None, math.inf
            for i, c in enumerate(coords[1:-1], 1):
                dd_ = math.dist(c, pos)
                if dd_ < best_d:
                    best, best_d = i, dd_
            if best is not None and best_d <= OWN_RADIUS[s["type"]] * PASS_SHARE:
                cuts.append((best, pid))
        cuts.sort()
        chain = [a]
        pieces = []
        start = 0
        for idx, pid in cuts:
            gate = "pass_%s_%s" % (pid, p["id"])
            nodes[gate] = coords[idx]
            node_place[gate] = pid
            pieces.append((chain[-1], gate, coords[start:idx + 1]))
            chain.append(gate)
            start = idx
        pieces.append((chain[-1], b, coords[start:]))
        for u, v, seg in pieces:
            length = polyline_length(seg)
            adj[u].append((v, length, p["class"], seg))
            adj[v].append((u, length, p["class"], list(reversed(seg))))

    # --- kervan yolu: köşeleri düğüm, yakın kavşaklara ve istasyonlara bağlı
    route = next(f for f in features if f["properties"].get("layer") == "kervan_yolu")
    rpts = [tuple(c) for c in route["geometry"]["coordinates"]]
    for i, pt in enumerate(rpts):
        nid = "cr_%d" % i
        nodes[nid] = pt
        if i > 0:
            prev = "cr_%d" % (i - 1)
            seg = [rpts[i - 1], pt]
            length = math.dist(rpts[i - 1], pt)
            adj[prev].append((nid, length, "kervan yolu", seg))
            adj[nid].append((prev, length, "kervan yolu", list(reversed(seg))))
    road_nodes = [(n, xy) for n, xy in nodes.items() if not n.startswith("cr_")]
    rn_xy = np.array([xy for _, xy in road_nodes])
    for i, pt in enumerate(rpts):
        d = np.hypot(rn_xy[:, 0] - pt[0], rn_xy[:, 1] - pt[1])
        j = int(np.argmin(d))
        if d[j] <= ROUTE_SNAP_PX:
            nid, rid = "cr_%d" % i, road_nodes[j][0]
            seg = [pt, road_nodes[j][1]]
            adj[nid].append((rid, float(d[j]), "kervan yolu", seg))
            adj[rid].append((nid, float(d[j]), "kervan yolu", list(reversed(seg))))
    r_xy = np.array(rpts)
    for pid, p in places.items():
        d = np.hypot(r_xy[:, 0] - p["pos"][0], r_xy[:, 1] - p["pos"][1])
        j = int(np.argmin(d))
        already = any(v == pid for v in node_place.values())
        limit = OWN_RADIUS[playable[pid]["type"]] * PASS_SHARE if pid in playable else STATION_SNAP_PX
        if d[j] <= limit and (pid in playable or not already):
            node_place["cr_%d" % j] = pid

    # Bir şehir bir nokta değil bir alan: çevresindeki kavşaklar onun kapısıdır.
    # Yoksa en kısa yol şehrin dibinden geçip onu "atlıyor" ve iki uzak yer
    # komşu görünüyordu.
    for n, xy in nodes.items():
        if node_place.get(n) in playable:
            continue
        best, best_d = None, math.inf
        for pid, s in playable.items():
            d = math.dist(xy, places[pid]["pos"])
            if d <= OWN_RADIUS[s["type"]] and d < best_d:
                best, best_d = pid, d
        if best is not None:
            node_place[n] = best
    place_nodes = defaultdict(list)
    for n, pid in node_place.items():
        place_nodes[pid].append(n)
    # Yol ağına adıyla bağlanmamış oynanabilir yer en yakın yol düğümüne bağlanır.
    for pid in playable:
        if place_nodes.get(pid):
            continue
        pos = places[pid]["pos"]
        d = np.hypot(rn_xy[:, 0] - pos[0], rn_xy[:, 1] - pos[1])
        j = int(np.argmin(d))
        if d[j] <= ATTACH_PX:
            n = road_nodes[j][0]
            if n not in node_place:
                node_place[n] = pid
                place_nodes[pid].append(n)
            else:
                ghost = "at_" + pid
                nodes[ghost] = pos
                seg = [pos, road_nodes[j][1]]
                adj[ghost].append((n, float(d[j]), "patika", seg))
                adj[n].append((ghost, float(d[j]), "patika", list(reversed(seg))))
                node_place[ghost] = pid
                place_nodes[pid].append(ghost)

    # --- iki oynanabilir yer arasındaki en kısa güzergâh, başka oynanabilirden geçmeden
    edges = {}
    for pid in playable:
        starts = place_nodes.get(pid, [])
        dist = {n: 0.0 for n in starts}
        prev = {}
        heap = [(0.0, n) for n in starts]
        heapq.heapify(heap)
        while heap:
            dcur, n = heapq.heappop(heap)
            if dcur > dist.get(n, math.inf):
                continue
            here = node_place.get(n)
            if here in playable and here != pid:
                key = tuple(sorted((pid, here)))
                if key not in edges or edges[key]["length_px"] > dcur:
                    path, classes, via = [], [], []
                    m = n
                    while m in prev:
                        pm, cls, coords = prev[m]
                        path = coords + path[1:] if path else coords
                        classes.append((cls, polyline_length(coords)))
                        stop = node_place.get(pm)
                        if stop and stop not in playable and stop not in via:
                            via.append(stop)
                        m = pm
                    if key[0] != pid:
                        path = list(reversed(path))
                        via = list(reversed(via))
                    edges[key] = {"length_px": dcur, "path": path, "classes": classes, "via": via}
                continue  # oynanabilir yerin içinden geçilmez
            for m, length, cls, coords in adj[n]:
                nd = dcur + length
                if nd < dist.get(m, math.inf):
                    dist[m] = nd
                    prev[m] = (n, cls, coords)
                    heapq.heappush(heap, (nd, m))
    build.debug = {"nodes": nodes, "node_place": node_place, "adj": adj, "place_nodes": place_nodes}
    return features, size, places, playable, edges


def shortest(graph, a, b):
    dist = {a: 0.0}
    heap = [(0.0, a)]
    while heap:
        d, n = heapq.heappop(heap)
        if n == b:
            return d
        if d > dist.get(n, math.inf):
            continue
        for m, w in graph[n]:
            if d + w < dist.get(m, math.inf):
                dist[m] = d + w
                heapq.heappush(heap, (d + w, m))
    return math.inf


def near_mask(mask, px):
    """Maskenin `px` piksel yakınındaki her yer (uzaklık dönüşümüyle)."""
    from scipy import ndimage
    dist = ndimage.distance_transform_edt(mask == 0) * MASK_SCALE
    return (dist <= px).astype(np.uint8) * 255


def classify_terrain(pts, forest, mountain, water, swamp_towns, region_codes, mountain_codes):
    """Her güzergâh noktasının biyomu. Öncelik: dağ, bataklık, göl, orman, bozkır."""
    out = []
    m, f, w = sample(mountain, pts), sample(forest, pts), sample(water, pts)
    r = sample(region_codes, pts)
    for i, pt in enumerate(pts):
        if m[i] or r[i] in mountain_codes:
            out.append("mountain")
        elif any(math.dist(pt, t) <= MARSH_RADIUS_PX for t in swamp_towns):
            out.append("marsh")
        elif w[i]:
            out.append("lake")
        elif f[i]:
            out.append("forest")
        else:
            out.append("steppe")
    # Çoğunluk süzgeci: tek tük noktalar (bir orman kıyısı) parça açmasın.
    half = TERRAIN_SMOOTH // 2
    smooth = []
    for i in range(len(out)):
        win = out[max(0, i - half):i + half + 1]
        smooth.append(max(sorted(set(win)), key=lambda b: (win.count(b), b == out[i])))
    return smooth


def _merge_short(runs, min_pts):
    """En kısa parçayı uzun komşusuna katar; her parça en az `min_pts` olana dek."""
    while len(runs) > 1:
        k = min(range(len(runs)), key=lambda j: runs[j][2] - runs[j][1])
        if runs[k][2] - runs[k][1] >= min_pts:
            return
        left = runs[k - 1] if k > 0 else None
        right = runs[k + 1] if k + 1 < len(runs) else None
        if right is None or (left is not None and left[2] - left[1] >= right[2] - right[1]):
            left[2] = runs[k][2]
        else:
            right[1] = runs[k][1]
        del runs[k]
        j = 1
        while j < len(runs):
            if runs[j][0] == runs[j - 1][0]:
                runs[j - 1][2] = runs[j][2]
                del runs[j]
            else:
                j += 1


def terrain_segments(labels, pts, days, pois):
    """Etiket dizisini parçalara böler: [{"biome", "to", "stop"}], `to` yolun payı (0-1)."""
    n = len(labels)
    if n == 0:
        return [{"biome": "steppe", "to": 1.0, "stop": ""}]
    runs = []  # [biyom, başlangıç, bitiş (hariç)]
    for i, b in enumerate(labels):
        if runs and runs[-1][0] == b:
            runs[-1][2] = i + 1
        else:
            runs.append([b, i, i + 1])
    min_pts = max(1, int(math.ceil(TERRAIN_MIN_SEG_DAYS / max(days, 1) * n)))
    gap_pts = max(min_pts, int(math.ceil(STOP_MIN_GAP_DAYS / max(days, 1) * n)))
    _merge_short(runs, min_pts)
    grow = min_pts
    while len(runs) > TERRAIN_MAX_SEGMENTS:
        grow += 1
        _merge_short(runs, grow)

    # Uzun, tek biyomlu parçalar yolun yanındaki harita noktalarında bölünür:
    # durak bir sınırda durur (RouteTerrain), aynı biyom iki yanında da sürer.
    used = set()
    split = []
    for b, lo, hi in runs:
        cuts = []
        for kind, pos, pid in pois:
            best_i, best_d = None, None
            for i in range(lo + min_pts, hi - min_pts):
                d = math.dist(pts[i], pos)
                if d <= STOP_POI_PX and (best_d is None or d < best_d):
                    best_i, best_d = i, d
            if best_i is not None:
                cuts.append((best_i, POI_STOPS[kind], pid))
        cuts.sort()
        start = lo
        for i, stop, pid in cuts:
            if pid in used or i - start < gap_pts or hi - i < gap_pts:
                continue
            split.append([b, start, i, stop])
            used.add(pid)
            start = i
        split.append([b, start, hi, ""])
    while len(split) > TERRAIN_MAX_SEGMENTS:
        cands = [j for j in range(len(split) - 1) if split[j][0] == split[j + 1][0]]
        if not cands:
            break
        j = min(cands, key=lambda j: split[j][2] - split[j][1])
        split[j + 1][1] = split[j][1]
        del split[j]

    segs = []
    for j, (b, lo, hi, stop) in enumerate(split):
        last = j == len(split) - 1
        if not last and not stop:
            other = split[j + 1][0]
            # Geçit dağa girişte, köprü suya girişte: çıkışa da koymak her
            # göl parçasını iki köprüyle çevreliyordu.
            if b != other and other == "mountain":
                stop = "pass"
            elif b != other and other in ("lake", "marsh"):
                stop = "bridge"
            else:
                pt = pts[min(hi, n - 1)]
                near = sorted((math.dist(pt, pos), POI_STOPS[kind], pid) for kind, pos, pid in pois
                              if pid not in used and math.dist(pt, pos) <= STOP_POI_PX)
                if near:
                    stop = near[0][1]
                    used.add(near[0][2])
        segs.append({"biome": b, "to": 1.0 if last else round(hi / n, 3), "stop": "" if last else stop})
    return segs


def main(argv):
    geojson = argv[1]
    out_path = argv[2] if len(argv) > 2 else DEFAULT_OUT
    report_path = argv[3] if len(argv) > 3 else None
    features, size, places, playable, edges = build(geojson)

    forest = raster(features, "orman", size)
    mountain = raster(features, "dağ", size)
    water = np.maximum(raster(features, "göl", size), raster(features, "deniz", size))
    water_near = near_mask(water, WATER_NEAR_PX)
    forest_near = near_mask(forest, FOREST_NEAR_PX)
    mountain_near = near_mask(mountain, MOUNTAIN_NEAR_PX)
    swamp_towns = [p["pos"] for p in places.values() if p.get("kind") == "it_swamptown"]
    pois = [(p["kind"], p["pos"], pid) for pid, p in places.items() if p.get("kind") in POI_STOPS]
    culture_codes = sorted({f["properties"].get("culture") for f in features
                            if f["properties"].get("layer") == "bölge"})
    region = raster(features, "bölge", size, lambda p: 1 + culture_codes.index(p.get("culture")))

    graph = defaultdict(list)
    for (a, b), e in edges.items():
        graph[a].append((b, e["length_px"]))
        graph[b].append((a, e["length_px"]))
    north = min(playable, key=lambda pid: places[pid]["pos"][1])
    south = max(playable, key=lambda pid: places[pid]["pos"][1])
    ns_px = shortest(graph, north, south)
    if not math.isfinite(ns_px):
        raise SystemExit("kuzey ile güney arasında yol yok")
    days_per_px = NORTH_SOUTH_DAYS / ns_px

    settlements = []
    for pid, s in sorted(playable.items(), key=lambda kv: kv[1]["id"]):
        p = places[pid]
        code = sample(region, [p["pos"]])[0]
        reg = culture_codes[code - 1] if code else p.get("culture")
        settlements.append({
            "id": s["id"], "type": s["type"], "map_kind": s["map_kind"], "map_place_id": pid,
            "culture": p.get("culture") or reg, "region": reg,
            "name": {"tr": p["name_tr"], "en": p["name_en"], "zh_CN": p.get("name_zh", p["name_en"])},
            "proper_name": p["proper"], "pos": [round(p["pos"][0], 1), round(p["pos"][1], 1)],
            "neighbours": sorted(playable[o]["id"] for o, _ in graph[pid]),
        })

    routes = []
    for (a, b), e in sorted(edges.items(), key=lambda kv: (playable[kv[0][0]]["id"], playable[kv[0][1]]["id"])):
        pts = resample(e["path"], PATH_POINT_SPACING)
        f_share = float(np.mean([v > 0 for v in sample(forest, pts)])) if pts else 0.0
        m_share = float(np.mean([v > 0 for v in sample(mountain, pts)])) if pts else 0.0
        total = sum(l for _, l in e["classes"]) or 1.0
        base = sum(CLASS_DANGER.get(c, 0.35) * l for c, l in e["classes"]) / total
        regs = [culture_codes[v - 1] for v in sample(region, pts) if v]
        reg_bonus = float(np.mean([REGION_DANGER.get(r, 0.0) for r in regs])) if regs else 0.0
        danger = base + FOREST_DANGER * f_share + MOUNTAIN_DANGER * m_share + reg_bonus
        caravan_share = sum(l for c, l in e["classes"] if c == "kervan yolu") / total
        days = max(MIN_DAYS, int(round(e["length_px"] * days_per_px)))
        labels = classify_terrain(pts, forest_near, mountain_near, water_near, swamp_towns, region,
                                  {1 + culture_codes.index(c) for c in MOUNTAIN_REGIONS if c in culture_codes})
        terrain = terrain_segments(labels, pts, days, pois)
        routes.append({
            "a": playable[a]["id"], "b": playable[b]["id"],
            "length_px": round(e["length_px"], 1),
            "days": days,
            "danger": round(min(0.85, max(0.08, danger)), 2),
            "forest_share": round(f_share, 2), "mountain_share": round(m_share, 2),
            "caravan_road_share": round(caravan_share, 2),
            "via": [places[v]["name_en"] for v in e["via"] if v in places],
            "terrain_from": playable[a]["id"],
            "terrain": terrain,
            "path": [[round(x), round(y)] for x, y in pts],
        })

    comps, seen = [], set()
    for pid in playable:
        if pid in seen:
            continue
        stack, comp = [pid], []
        seen.add(pid)
        while stack:
            n = stack.pop()
            comp.append(playable[n]["id"])
            for m, _ in graph[n]:
                if m not in seen:
                    seen.add(m)
                    stack.append(m)
        comps.append(sorted(comp))

    economy = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "economy.json"), encoding="utf-8"))
    for s in settlements:
        g = economy["goods"].get(s["id"])
        if g is None:
            raise SystemExit("economy.json'da mal yok: %s" % s["id"])
        s["produces"] = g["produces"]
        s["demands"] = g["demands"]
        if s["type"] != "city":
            s["available"] = sorted(set(g.get("available", [])) | set(g["produces"]))
    by_id = {s["id"]: s for s in settlements}
    starts = {}
    fish_villages = [p["pos"] for p in places.values() if p.get("kind") == "iv_fishvillage"]
    for culture, regions in economy["start_cultures"].items():
        if culture.startswith("_"):
            continue
        homes = [s for s in settlements if s["type"] != "caravanserai"]
        if regions == ["@fishvillage"]:
            # Balıkçı kültürü: her balıkçı köyüne en yakın şehir ya da kasaba.
            picked = set()
            for fv in fish_villages:
                picked.add(min(homes, key=lambda h: math.dist(h["pos"], fv))["id"])
            starts[culture] = sorted(picked)
            continue
        inside = [h["id"] for h in homes if h["region"] in regions]
        if not inside:
            # Bölgede şehir/kasaba yok (göçebe boyları): bölgedeki yerlerin
            # ortasına en yakın üç şehir ya da kasaba.
            pts = [p["pos"] for p in places.values() if p.get("culture") in regions]
            cx = sum(x for x, _ in pts) / len(pts)
            cy = sum(y for _, y in pts) / len(pts)
            inside = [h["id"] for h in sorted(homes, key=lambda h: math.dist(h["pos"], (cx, cy)))[:3]]
        # İlk sefer 15-38 günlük bir yol olmasın: yeni kervanın 250 altını ve
        # erzağı ancak kısa bir ilk yola yeter (görev N8 ölçümü: Vorgat'ta
        # başlayan kervan hiç kontrat teslim edemeden battı). Yakın komşusu
        # olan aday varsa yalnızca onlar.
        near = [i for i in inside if any(r["days"] <= START_MAX_FIRST_LEG and i in (r["a"], r["b"]) for r in routes)]
        starts[culture] = sorted(near or inside)

    doc = {
        "_doc": "Oynanabilir yerleşimler ve aralarındaki yollar (tools/worldmap/build_settlements.py ile harita v3 GeoJSON'undan; elle düzenleme yok). Koordinat: harita görüntüsü pikseli (16012x16013).",
        "map_size": size,
        "scale": {"north": playable[north]["id"], "south": playable[south]["id"], "north_south_px": round(ns_px, 1),
                  "north_south_days": NORTH_SOUTH_DAYS, "days_per_1000px": round(days_per_px * 1000, 3)},
        "settlements": settlements,
        "routes": routes,
        "start_candidates": starts,
    }
    with open(out_path, "w", encoding="utf-8", newline=chr(10)) as fh:
        json.dump(doc, fh, ensure_ascii=False, indent=1)

    days = sorted(r["days"] for r in routes)
    lines = [
        "# Yerleşimler ve yollar: üretim raporu", "",
        "Oynanabilir yer: %d (şehir %d, kasaba %d, kervansaray %d). Yol (komşuluk): %d." % (
            len(settlements), sum(s["type"] == "city" for s in settlements),
            sum(s["type"] == "town" for s in settlements), sum(s["type"] == "caravanserai" for s in settlements), len(routes)),
        "Ölçek: %s → %s en kısa yol %.0f px = %d gün (1000 px = %.2f gün)." % (
            playable[north]["id"], playable[south]["id"], ns_px, NORTH_SOUTH_DAYS, days_per_px * 1000),
        "Kenar günleri: en az %d, ortanca %d, en çok %d." % (days[0], days[len(days) // 2], days[-1]),
        "Bağlı bileşen: %d %s" % (len(comps), "" if len(comps) == 1 else "- AYRIK: " + "; ".join(", ".join(c) for c in comps if len(c) < len(settlements))),
        "", "| Yer | Tür | Kültür | Üretir | Arar | Komşular |", "|---|---|---|---|---|---|",
    ]
    for s in settlements:
        lines.append("| %s | %s | %s | %s | %s | %s |" % (s["name"]["tr"], s["type"], s["culture"], ", ".join(s["produces"]),
                     ", ".join(s["demands"]), ", ".join(s["neighbours"]) or "**yok**"))
    lines += ["", "Başlangıç adayları (kültür → yer): " + "; ".join("%s: %s" % (k, ", ".join(v)) for k, v in starts.items())]
    lines += ["", "| Yol | Gün | Tehlike | Orman | Dağ | Kervan yolu | Duraklar |", "|---|---|---|---|---|---|---|"]
    for r in routes:
        lines.append("| %s – %s | %d | %.2f | %.0f%% | %.0f%% | %.0f%% | %s |" % (
            r["a"], r["b"], r["days"], r["danger"], r["forest_share"] * 100, r["mountain_share"] * 100,
            r["caravan_road_share"] * 100, ", ".join(r["via"])))
    text = "\n".join(lines) + "\n"
    if report_path:
        open(report_path, "w", encoding="utf-8", newline=chr(10)).write(text)
    print(text)


if __name__ == "__main__":
    main(sys.argv)
