"""referans harita tarzı yerleşimler: önce plan, sonra çizim.

referans harita dünya haritasında (Uzhitz, Rattay, Talmberg) bir kasaba:
  * evler YOLA dizilir; her evin arkasında çitle çevrili ince uzun bir parsel
    (bahçe/tarla şeridi) uzanır - kasabanın imzası budur;
  * ev yandan-üstten: çatı baskın (saman/kahve, kırmızı az), güney yüzde
    alçak bir duvar şeridi, sıcak kahve kontur - siyah değil;
  * şehir: yüksekliği görünen açık gri taş sur, mazgal, kırmızı külahlı
    yuvarlak kuleler, içeride sık evler, kilise ve burç.

Kurallar (oyuncunun):
  * ev/bina SUYUN, ORMANIN, TARLANIN üstüne düşmez - plan önce yapılır,
    zemin (zemin_render) planın ayak izinden ormanı ve tarlayı çeker;
  * liman yalnızca kıyıda: iskele suya uzanır, ev suya girmez.

    python3 -I zemin_settlements.py plan <kök> <layout.json> [tohum]
    python3 -I zemin_settlements.py draw <kök> <layout.json> <çıktı.png>
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import coast as coastline  # noqa: E402

N = 4096
SS = 3
INK = (66, 44, 24)
WALL_FACE = [(214, 196, 158), (202, 184, 146), (222, 206, 172)]
ROOF = [(178, 150, 102), (160, 128, 84), (142, 104, 66), (128, 92, 60), (162, 88, 60), (150, 74, 52)]
ROOF_W = [0.26, 0.22, 0.18, 0.12, 0.13, 0.09]
STONE_TOP = (216, 210, 196)
STONE_FACE = (176, 168, 152)
TOWER_ROOF = (160, 70, 50)
PLOT_FILL = [(204, 182, 120), (186, 176, 108), (172, 168, 100), (196, 170, 112)]
FENCE = (98, 66, 36)
PLANK = (122, 90, 56)

STONE_DARK_TOP = (150, 146, 140)
STONE_DARK_FACE = (112, 108, 104)
WOOD_FACE = (118, 84, 52)
WOOD_TOP = (150, 112, 72)
FELT = (230, 220, 198)
FELT_ROOF = (214, 202, 176)
SAIL = (232, 222, 196)

# Oyuncunun kararları (konumlar world.json'dan, değişmez):
SMALL_CITIES = {(2381.73, 2175.46), (2515.51, 2653.18)}   # ortadaki sık kuşak: küçük, ahşap surlu
DARK_STONE = {(1654.83, 930.27)}                          # kuzeyin en büyük şehri
CLUSTER_R = 260                                           # bu yarıçaptaki şehir sembolleri tek şehir
NOMAD = {"in_yurtcamp": (10, 55), "in_khantent": (12, 60), "iny_0": (2, 18), "iny_2": (3, 20),
         "iny_3": (3, 20), "iny_4": (4, 22)}             # (yurt sayısı, yayılım)

# tür: (sur yarıçapı, ev sayısı, yayılım, kilise, parsel, liman)
KINDS = {
    "ic_city":        (115, 90, 170, True, True, False),
    "ic_freecity":    (110, 84, 165, True, True, False),
    "ic_portcity":    (105, 80, 160, True, True, True),
    "it_town":        (52, 26, 95, True, True, False),
    "it_markettown":  (56, 30, 100, True, True, False),
    "it_rivertown":   (52, 26, 95, True, True, False),
    "it_minetown":    (0, 16, 70, False, True, False),
    "it_swamptown":   (0, 14, 70, False, True, False),
    "ih_mezra":      (0, 6, 45, False, True, False),
    "iv_farm":        (0, 3, 30, False, True, False),
    "iv_fishvillage": (0, 7, 45, False, False, True),
    "il_lumber":      (0, 3, 28, False, False, False),
    "ia_abbey":       (0, 0, 0, False, False, False),
    "iw_tower":       (0, 0, 0, False, False, False),
    "ix_mountaintribe": (0, 5, 35, False, False, False),
}


KINDS.update({k: (0, 0, 0, False, False, False) for k in NOMAD})


# ---------------------------------------------------------------- plan
class Occupancy:
    """1 px çözünürlükte dolu alan; aday çokgen dolu yere ya da suya değerse ret."""

    def __init__(self, water):
        self.water = ndi.binary_dilation(water, iterations=4)
        self.img = Image.new("L", (N, N), 0)
        self.dr = ImageDraw.Draw(self.img)

    def free(self, poly, pad=0):
        xs = [p[0] for p in poly]
        ys = [p[1] for p in poly]
        x0, y0 = int(min(xs)) - pad - 1, int(min(ys)) - pad - 1
        x1, y1 = int(max(xs)) + pad + 2, int(max(ys)) + pad + 2
        if x0 < 8 or y0 < 8 or x1 > N - 8 or y1 > N - 8:
            return False
        m = Image.new("L", (x1 - x0, y1 - y0), 0)
        ImageDraw.Draw(m).polygon([(p[0] - x0, p[1] - y0) for p in poly], fill=255)
        m = np.asarray(m) > 0
        if pad:
            m = ndi.binary_dilation(m, iterations=pad)
        if (self.water[y0:y1, x0:x1] & m).any():
            return False
        occ = np.asarray(self.img.crop((x0, y0, x1, y1))) > 0
        return not (occ & m).any()

    def take(self, poly):
        self.dr.polygon([tuple(p) for p in poly], fill=255)

    def mask(self):
        return np.asarray(self.img) > 0


def rect(c, u, L, W):
    u = np.asarray(u, np.float64)
    v = np.array([-u[1], u[0]])
    return [tuple(c + su * u * L / 2 + sv * v * W / 2) for su, sv in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def unit(a):
    a = np.asarray(a, np.float64)
    return a / (np.linalg.norm(a) + 1e-9)


def streets_near(roads, c, radius):
    """Yerin içinden geçen yol parçaları (world.json yolları), ince örneklenmiş."""
    out = []
    for rd in roads:
        p = np.array(rd["p"], np.float64)
        d = np.hypot(p[:, 0] - c[0], p[:, 1] - c[1])
        if d.min() > radius * 0.8:
            continue
        seg = []
        for a, b in zip(p[:-1], p[1:]):
            k = max(2, int(np.hypot(*(b - a)) / 6))
            for t in np.linspace(0, 1, k, endpoint=False):
                q = a + (b - a) * t
                if np.hypot(*(q - c)) < radius:
                    seg.append(q)
        if len(seg) > 4:
            out.append(np.array(seg))
    return out


def roof_pick(rng, city):
    w = np.array(ROOF_W)
    if city:
        w = w * np.array([0.6, 0.8, 1, 1, 1.8, 1.8])
    return int(rng.choice(len(ROOF), p=w / w.sum()))


def add_plot(occ, place, rng, hc, u, v, L, W, plen=(26, 66)):
    PL = plen[0] + rng.random() * (plen[1] - plen[0])
    pc = hc + v * (W / 2 + 2 + PL / 2)
    ppoly = rect(pc, v, PL, L + 2)
    if occ.free(ppoly, 1):
        occ.take(ppoly)
        place["plots"].append({"c": pc.tolist(), "u": v.tolist(), "L": PL, "W": L + 2,
                               "fill": int(rng.integers(len(PLOT_FILL))),
                               "orchard": bool(rng.random() < 0.25)})


def houses_along(occ, place, rng, lane, count, ok_at, city, plots):
    made = 0
    for side in (-1, 1):
        i = int(rng.integers(0, 3))
        while i < len(lane) - 1 and made < count:
            a, b = lane[i], lane[i + 1]
            u = unit(b - a)
            v = np.array([-u[1], u[0]]) * side
            L = 12 + rng.random() * 8
            W = 8 + rng.random() * 3
            hc = a + v * (W / 2 + 5)
            if not ok_at(hc):
                i += 2
                continue
            poly = rect(hc, u, L, W)
            if occ.free(poly, 2) and rng.random() < (0.95 if city else 0.8):
                occ.take(poly)
                made += 1
                place["houses"].append({"c": hc.tolist(), "u": u.tolist(), "L": L, "W": W,
                                        "roof": roof_pick(rng, city)})
                if plots:
                    add_plot(occ, place, rng, hc, u, v, L, W)
            i += max(1, int((L + 3 + rng.random() * 6) / 6))
    return made


def plan(root, seed=0):
    rng = np.random.default_rng(seed)
    world = json.load(open(os.path.join(root, "data", "world.json")))
    wk = os.environ.get("ZEMIN_WORLD", os.path.join(root, "out", "world_zemin.json"))
    if os.path.exists(wk):  # araziye göre yeniden yönlendirilmiş yollar
        world["roads"] = json.load(open(wk))["roads"]
    water = coastline.water_mask(root, N)
    dist_w = ndi.distance_transform_edt(~water)
    occ = Occupancy(water)
    _, (iy, ix) = ndi.distance_transform_edt(water, return_indices=True)
    places = []
    syms = [s for s in world["syms"] if s[0] in KINDS]
    syms.sort(key=lambda s: -KINDS[s[0]][1])  # büyükler önce yer seçsin
    # şehir kümeleri: yakın şehir sembolleri tek şehrin mahalleleri
    masters, absorbed = [], {}
    for kind, x, y in syms:
        if KINDS[kind][0] < 100:
            continue
        m = next((mm for mm in masters if np.hypot(mm[1] - x, mm[2] - y) < CLUSTER_R), None)
        if m is None:
            masters.append((kind, x, y))
        else:
            absorbed.setdefault((m[1], m[2]), []).append((kind, x, y))
            if kind == "ic_portcity" and m[0] != "ic_portcity":
                masters[masters.index(m)] = ("ic_portcity", m[1], m[2])
    skip = {(x, y) for v in absorbed.values() for _, x, y in v}
    syms = [s for s in syms if (s[1], s[2]) not in skip]
    syms = [next((m for m in masters if (m[1], m[2]) == (s[1], s[2])), s) for s in syms]
    for kind, x, y in syms:
        R, count, spread, has_church, plots, port = KINDS[kind]
        material = "stone" if R >= 100 else "wood"
        n_abs = len(absorbed.get((x, y), []))
        if n_abs:
            R, count, spread = R * 1.2, int(count * (1 + 0.25 * n_abs)), spread * 1.2
        if (round(x, 2), round(y, 2)) in SMALL_CITIES:
            R, count, spread, material = 62, 34, 110, "wood"
        if (round(x, 2), round(y, 2)) in DARK_STONE:
            material = "dark"
        c = np.array([x, y], np.float64)
        xi, yi = int(np.clip(x, 0, N - 1)), int(np.clip(y, 0, N - 1))
        moved = bool(water[yi, xi])
        if moved:
            # çapa suda: yapılar en yakın karaya kurulur, çapanın kendisi değişmez
            c = np.array([ix[yi, xi], iy[yi, xi]], np.float64)
        place = {"kind": kind, "anchor": [x, y], "center": c.tolist(), "moved": moved,
                 "houses": [], "plots": [], "walls": [], "towers": [], "church": None,
                 "keep": None, "piers": [], "material": material, "quay": [], "boats": [],
                 "absorbed": absorbed.get((x, y), [])}
        city = R > 0
        streets = streets_near(world["roads"], c, max(spread, R) * 1.1)
        if not streets:
            a = rng.random() * np.pi
            u = np.array([np.cos(a), np.sin(a)])
            ts = np.linspace(-spread, spread, 40)
            streets = [c + ts[:, None] * u]
        if kind in NOMAD:
            nyurt, spr = NOMAD[kind]
            place["yurts"], place["pens"] = [], []
            if kind == "in_khantent":
                if occ.free(rect(c, [1.0, 0], 30, 24), 2):
                    occ.take(rect(c, [1.0, 0], 30, 24))
                    place["khan"] = {"c": c.tolist()}
            tries = 0
            while len(place["yurts"]) < nyurt and tries < nyurt * 40:
                tries += 1
                q = c + rng.normal(0, spr * 0.5, 2) if (nyurt > 1 or tries > 1) else c
                r = 8.0 + rng.random() * 3.0
                if occ.free(rect(q, [1.0, 0], r * 2 + 2, r * 1.4 + 2), 2):
                    occ.take(rect(q, [1.0, 0], r * 2 + 2, r * 1.4 + 2))
                    place["yurts"].append({"c": q.tolist(), "r": r})
            if kind in ("in_yurtcamp", "in_khantent"):
                for _ in range(2 if kind == "in_khantent" else 1):
                    for _t in range(30):
                        q = c + rng.normal(0, spr * 0.6, 2)
                        r = 12 + rng.random() * 8
                        if occ.free(rect(q, [1.0, 0], r * 2, r * 1.3), 2):
                            occ.take(rect(q, [1.0, 0], r * 2, r * 1.3))
                            place["pens"].append({"c": q.tolist(), "r": r,
                                                  "horses": int(rng.integers(2, 6))})
                            break
            places.append(place)
            continue
        if kind == "ia_abbey":
            u = np.array([1.0, 0.0])
            if occ.free(rect(c, u, 36, 34), 2):
                occ.take(rect(c, u, 36, 34))
                place["church"] = {"c": c.tolist(), "u": u.tolist(), "L": 28, "W": 12}
                for dy in (-15, 15):
                    p = c + np.array([0, dy])
                    place["houses"].append({"c": p.tolist(), "u": u.tolist(), "L": 32, "W": 8, "roof": 2})
            places.append(place)
            continue
        if kind == "iw_tower":
            if occ.free(rect(c, [1.0, 0], 14, 14), 1):
                occ.take(rect(c, [1.0, 0], 14, 14))
                place["keep"] = {"c": c.tolist(), "r": 6, "h": 26, "solo": True}
            places.append(place)
            continue

        inside_arr = None
        pts = None
        if city:
            n = 22
            ang = np.linspace(0, 2 * np.pi, n, endpoint=False) + rng.random()
            shape = 0.86 + 0.22 * rng.random(n)
            shape = (shape + np.roll(shape, 1) + np.roll(shape, -1)) / 3
            # sur başka bir yerin yapısına değerse küçülür; yer yoksa sursuz kasaba
            for Rk in (R, R * 0.8, R * 0.65):
                cand = np.stack([c[0] + np.cos(ang) * Rk * shape, c[1] + np.sin(ang) * Rk * shape * 0.82], 1)
                for i in range(n):  # suya giren sur köşesi içeri çekilir
                    for _ in range(14):
                        px, py = int(np.clip(cand[i, 0], 0, N - 1)), int(np.clip(cand[i, 1], 0, N - 1))
                        if not occ.water[py, px]:
                            break
                        cand[i] = c + (cand[i] - c) * 0.9
                area = Image.new("L", (N, N), 0)
                ImageDraw.Draw(area).polygon([tuple(p) for p in cand], fill=255)
                x0, y0 = cand.min(0).astype(int) - 20
                x1, y1 = cand.max(0).astype(int) + 20
                x0, y0 = max(0, x0), max(0, y0)
                sub = np.asarray(area.crop((x0, y0, x1, y1))) > 0
                sub = ndi.binary_dilation(sub, iterations=16)
                if not (np.asarray(occ.img.crop((x0, y0, x1, y1))) > 0)[:sub.shape[0], :sub.shape[1]][sub].any():
                    pts, R = cand, Rk
                    break
            if pts is None:
                city = False
                spread = max(spread, R * 0.9)
                count = max(6, count // 3)
        if city:
            place["walls"] = pts.tolist()
            ring = Image.new("L", (N, N), 0)
            ImageDraw.Draw(ring).line([tuple(p) for p in pts] + [tuple(pts[0])], fill=255, width=14)
            occ.img.paste(255, mask=ring)
            for i in range(0, n, 3 if material != "wood" else 4):
                place["towers"].append({"c": pts[i].tolist(), "r": 4.8 if material != "wood" else 4.0,
                                        "h": 15 if material != "wood" else 11})
            inside = Image.new("L", (N, N), 0)
            ImageDraw.Draw(inside).polygon([tuple(p) for p in pts], fill=255)
            inside_arr = ndi.binary_erosion(np.asarray(inside) > 0, iterations=8)
            keep_c = c + np.array([R * 0.25, -R * 0.3])
            if material != "wood" and occ.free(rect(keep_c, [1.0, 0], 24, 22), 2):
                occ.take(rect(keep_c, [1.0, 0], 24, 22))
                place["keep"] = {"c": keep_c.tolist(), "r": 6, "h": 22}
        if has_church:
            for _ in range(40):
                cc = c + rng.normal(0, 10 if city else 18, 2)
                if occ.free(rect(cc, [1.0, 0], 34, 20), 2):
                    occ.take(rect(cc, [1.0, 0], 34, 20))
                    place["church"] = {"c": cc.tolist(), "u": [1.0, 0.0], "L": 26, "W": 12}
                    break

        if city and port:
            # liman kenti kıyı boyunca yayılır: sokaklar kıyıya paralel eş-uzaklık
            # hatları, sur yalnız kara tarafında (deniz cephesi rıhtım)
            import cv2
            RR = R * 1.9
            x0, y0 = int(max(0, c[0] - RR)), int(max(0, c[1] - RR))
            x1, y1 = int(min(N, c[0] + RR)), int(min(N, c[1] + RR))
            dsub = dist_w[y0:y1, x0:x1]
            yy_, xx_ = np.mgrid[y0:y1, x0:x1]
            near = np.hypot(xx_ - c[0], yy_ - c[1]) < RR
            port_lanes = []
            for dlt in (16, 38, 60, 82):
                m = ((dsub > dlt) & near).astype(np.uint8)
                cs, _ = cv2.findContours(m, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
                for cc in cs:
                    q = cc[:, 0, :].astype(np.float64) + [x0, y0]
                    q = q[(np.hypot(q[:, 0] - c[0], q[:, 1] - c[1]) < RR * 0.95)]
                    q = q[dist_w[q[:, 1].astype(int), q[:, 0].astype(int)] < dlt + 3]
                    if len(q) > 20:
                        port_lanes.append(q[::5])
            def ok_port(p):
                xi_, yi_ = int(np.clip(p[0], 0, N - 1)), int(np.clip(p[1], 0, N - 1))
                return dist_w[yi_, xi_] < 95 and np.hypot(*(p - c)) < RR
            made = 0
            for lane in sorted(port_lanes, key=len, reverse=True):
                made += houses_along(occ, place, rng, lane, int(count * 1.3) - made, ok_port, True, False)
            # sur: deniz cephesi hariç (suya 30 px'ten yakın sur parçası atılır)
            W_ = place["walls"]
            place["wall_open"] = [bool(dist_w[int(np.clip(W_[i][1], 0, N - 1)), int(np.clip(W_[i][0], 0, N - 1))] < 30
                                       or dist_w[int(np.clip(W_[(i + 1) % len(W_)][1], 0, N - 1)), int(np.clip(W_[(i + 1) % len(W_)][0], 0, N - 1))] < 30)
                                  for i in range(len(W_))]
            place["towers"] = [t for t in place["towers"]
                               if dist_w[int(np.clip(t["c"][1], 0, N - 1)), int(np.clip(t["c"][0], 0, N - 1))] >= 30]
            # rıhtım: kıyının liman bölümünde taş kenar
            m = ((dsub > 2) & near).astype(np.uint8)
            cs, _ = cv2.findContours(m, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
            for cc in cs:
                q = cc[:, 0, :].astype(np.float64) + [x0, y0]
                ok = (np.hypot(q[:, 0] - c[0], q[:, 1] - c[1]) < RR * 0.85) & (dist_w[q[:, 1].astype(int), q[:, 0].astype(int)] < 6)
                run = []
                for qq, kk in zip(q, ok):
                    if kk:
                        run.append(qq.tolist())
                    elif len(run) > 10:
                        place["quay"].append(run[::3]); run = []
                    else:
                        run = []
                if len(run) > 10:
                    place["quay"].append(run[::3])
        elif city:
            def ok_in(p):
                return inside_arr[int(np.clip(p[1], 0, N - 1)), int(np.clip(p[0], 0, N - 1))]
            main = streets[0]
            d = unit(main[-1] - main[0])
            v = np.array([-d[1], d[0]])
            lanes = list(streets)
            # iç sokak aralığı sur yarıçapıyla ölçeklenir (küçük surda boş halka kalmasın)
            for f in (-0.25, 0.25, -0.5, 0.5, -0.75, 0.75):
                off = f * R
                ts = np.linspace(-R * 1.2, R * 1.2, 70)
                lanes.append(c + v * off + ts[:, None] * d)
            for off in (-0.52 * R, -0.17 * R, 0.17 * R, 0.52 * R):
                ts = np.linspace(-R, R, 50)
                lanes.append(c + d * off + ts[:, None] * v)
            made = 0
            for lane in lanes:
                made += houses_along(occ, place, rng, lane, count - made, ok_in, True, False)
                if made >= count:
                    break
            # varoş: surun dışında ana yol boyunca evler ve parseller
            def ok_out(p):
                return R * 1.08 < np.hypot(*(p - c)) < R * 1.7
            for lane in streets:
                houses_along(occ, place, rng, lane, 10, ok_out, False, True)
        else:
            def ok_v(p):
                return np.hypot(*(p - c)) < spread
            made = 0
            for lane in streets:
                made += houses_along(occ, place, rng, lane, count - made, ok_v, False, plots)
                if made >= count:
                    break
        if port:
            r0 = int(max(spread, R) * 1.4)
            x0, y0 = int(max(0, c[0] - r0)), int(max(0, c[1] - r0))
            sub = water[y0:int(min(N, c[1] + r0)), x0:int(min(N, c[0] + r0))]
            if sub.any():
                edge = sub & ~ndi.binary_erosion(sub, iterations=2)
                ys, xs = np.nonzero(edge)
                if len(xs):
                    d = np.hypot(xs + x0 - c[0], ys + y0 - c[1])
                    order = np.argsort(d)
                    picked = []
                    for k in order:
                        p = np.array([xs[k] + x0, ys[k] + y0], np.float64)
                        if any(np.hypot(*(p - q)) < 22 for q in picked):
                            continue
                        picked.append(p)
                        # iskele kıyıya dik: su yönü = yerel su ağırlık merkezi
                        win = water[max(0, int(p[1]) - 12):int(p[1]) + 12, max(0, int(p[0]) - 12):int(p[0]) + 12]
                        wy, wx = np.nonzero(win)
                        out = unit(np.array([wx.mean() - 12, wy.mean() - 12]) if len(wx) else p - c)
                        place["piers"].append({"a": (p - out * 4).tolist(),
                                               "b": (p + out * (24 + rng.random() * 14)).tolist()})
                        if len(picked) >= (5 if city else 1):
                            break
                    for pr in place["piers"]:  # iskele ucunda tekne
                        a_, b_ = np.array(pr["a"]), np.array(pr["b"])
                        u_ = unit(b_ - a_)
                        side = np.array([-u_[1], u_[0]]) * (7 + rng.random() * 4) * (1 if rng.random() < 0.5 else -1)
                        bc = b_ - u_ * (6 + rng.random() * 8) + side
                        if water[int(np.clip(bc[1], 0, N - 1)), int(np.clip(bc[0], 0, N - 1))]:
                            place["boats"].append({"c": bc.tolist(), "u": u_.tolist(), "big": bool(city and rng.random() < 0.5)})
        places.append(place)
    foot = ndi.binary_dilation(occ.mask(), iterations=10)
    return places, foot


# ---------------------------------------------------------------- çizim
def shade(c, k):
    return tuple(int(max(0, min(255, v * k))) for v in c)


def draw_house(dr, h, o):
    s = SS
    c = (np.array(h["c"]) - o) * s
    u = unit(h["u"])
    if u[0] < 0:
        u = -u
    v = np.array([-u[1], u[0]])
    L, W = h["L"] * s, h["W"] * s
    ht = (3.2 + 0.08 * h["L"]) * s
    base = [c + su * u * L / 2 + sv * v * W / 2 for su, sv in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    up = np.array([0, -ht])
    top = [p + up for p in base]
    wall = WALL_FACE[int(abs(h["c"][0] * 7 + h["c"][1] * 3)) % 3]
    cen = sum(base) / 4
    for i in range(4):  # güneye bakan duvarlar görünür
        a, b = base[i], base[(i + 1) % 4]
        nrm = np.array([b[1] - a[1], -(b[0] - a[0])])
        if np.dot(nrm, (a + b) / 2 - cen) < 0:
            nrm = -nrm
        if nrm[1] > 0.05:
            lit = 0.82 + 0.18 * max(0, unit(nrm)[0])
            dr.polygon([tuple(a), tuple(b), tuple(b + up), tuple(a + up)], fill=shade(wall, lit), outline=INK)
            mid = (a + b) / 2
            dr.line([tuple(mid), tuple(mid + up * 0.55)], fill=INK, width=max(1, s))
    roof = ROOF[h["roof"]]
    ov = 1.0 * s
    r = [top[0] - u * ov - v * ov, top[1] + u * ov - v * ov, top[2] + u * ov + v * ov, top[3] - u * ov + v * ov]
    lift = np.array([0, -ht * 0.35])
    ridge_a = (r[0] + r[3]) / 2 + u * W * 0.18 + lift
    ridge_b = (r[1] + r[2]) / 2 - u * W * 0.18 + lift
    north = [r[0], r[1], ridge_b, ridge_a]
    south = [r[3], r[2], ridge_b, ridge_a]
    if np.mean([p[1] for p in north]) > np.mean([p[1] for p in south]):
        north, south = south, north
    # alın üçgenleri (kısa kenarlar)
    for end, rr2 in ((ridge_a, (r[0], r[3])), (ridge_b, (r[1], r[2]))):
        dr.polygon([tuple(rr2[0]), tuple(rr2[1]), tuple(end)], fill=shade(roof, 0.62), outline=INK)
    dr.polygon([tuple(p) for p in north], fill=shade(roof, 0.74), outline=INK)
    dr.polygon([tuple(p) for p in south], fill=roof, outline=INK)
    for t in np.linspace(0.15, 0.85, 4):  # saman/kiremit dokusu
        p0 = south[0] + (south[1] - south[0]) * t
        p1 = ridge_a + (ridge_b - ridge_a) * t
        dr.line([tuple(p0), tuple(p0 + (p1 - p0) * 0.75)], fill=shade(roof, 0.84), width=max(1, s // 2))
    dr.line([tuple(ridge_a), tuple(ridge_b)], fill=INK, width=max(1, s))


def draw_wood_tower(dr, t, o):
    """Ahşap gözetleme kulesi: kütük gövde, küçük tahta çatı."""
    s = SS
    cx, cy = (np.array(t["c"]) - o) * s
    r, h = t["r"] * s, t["h"] * s
    dr.rectangle([cx - r, cy - h, cx + r, cy], fill=WOOD_FACE, outline=INK)
    for k in range(1, 4):
        x = cx - r + 2 * r * k / 4
        dr.line([(x, cy - h), (x, cy)], fill=shade(WOOD_FACE, 0.75), width=max(1, s // 2))
    dr.rectangle([cx - r * 1.25, cy - h - r * 0.5, cx + r * 1.25, cy - h], fill=WOOD_TOP, outline=INK)
    dr.polygon([(cx - r * 1.35, cy - h - r * 0.5), (cx + r * 1.35, cy - h - r * 0.5), (cx, cy - h - r * 1.9)],
               fill=ROOF[2], outline=INK)


def draw_tower(dr, t, o, roof=TOWER_ROOF, face=STONE_FACE):
    s = SS
    cx, cy = (np.array(t["c"]) - o) * s
    r, h = t["r"] * s, t["h"] * s
    dr.ellipse([cx - r, cy - r * 0.45, cx + r, cy + r * 0.45], fill=face, outline=INK)
    dr.rectangle([cx - r, cy - h, cx + r, cy], fill=face)
    dr.line([(cx - r, cy - h), (cx - r, cy)], fill=INK, width=s)
    dr.line([(cx + r, cy - h), (cx + r, cy)], fill=INK, width=s)
    dr.rectangle([cx + r * 0.35, cy - h, cx + r - s, cy], fill=shade(face, 0.82))
    for t2 in (0.33, 0.66):
        dr.arc([cx - r, cy - h * t2 - r * 0.45, cx + r, cy - h * t2 + r * 0.45], 0, 180,
               fill=shade(face, 0.75), width=max(1, s // 2))
    dr.rectangle([cx - r * 0.18, cy - h * 0.62, cx + r * 0.18, cy - h * 0.48], fill=INK)
    dr.polygon([(cx - r * 1.25, cy - h), (cx + r * 1.25, cy - h), (cx, cy - h - r * 2.5)], fill=roof, outline=INK)
    dr.polygon([(cx, cy - h - r * 2.5), (cx + r * 1.25, cy - h), (cx + r * 0.25, cy - h)], fill=shade(roof, 0.75))


def draw_wall(dr, pts, o, front, material="stone", open_=None):
    """Sur: yüksekliği görünen bant. Taş: sur yolu + mazgal; koyu taş: aynısı,
    koyu ve yüksek; ahşap: sivri uçlu kütük palisat. front: güney yarısı."""
    s = SS
    P = (np.array(pts) - o) * s
    n = len(P)
    cen = P.mean(0)
    if material == "wood":
        hgt = 6 * s
        up = np.array([0, -hgt])
        for i in range(n):
            a, b = P[i], P[(i + 1) % n]
            if ((a[1] + b[1]) / 2 > cen[1]) != front or (open_ and open_[i]):
                continue
            dr.polygon([tuple(a), tuple(b), tuple(b + up), tuple(a + up)], fill=WOOD_FACE, outline=INK)
            k = max(2, int(np.hypot(*(b - a)) / (2.4 * s)))
            for j in range(k + 1):
                q = a + (b - a) * j / k
                dr.line([tuple(q), tuple(q + up)], fill=shade(WOOD_FACE, 0.7), width=max(1, s // 2))
                dr.polygon([tuple(q + up + [-1.1 * s, 0]), tuple(q + up + [1.1 * s, 0]), tuple(q + up * 1.3)],
                           fill=WOOD_TOP, outline=INK)
        return
    face, top = (STONE_DARK_FACE, STONE_DARK_TOP) if material == "dark" else (STONE_FACE, STONE_TOP)
    hgt = (10 if material == "dark" else 7) * s
    up = np.array([0, -hgt])
    for i in range(n):
        a, b = P[i], P[(i + 1) % n]
        if ((a[1] + b[1]) / 2 > cen[1]) != front or (open_ and open_[i]):
            continue
        dr.polygon([tuple(a), tuple(b), tuple(b + up), tuple(a + up)], fill=face, outline=INK)
        for t in (0.35, 0.68):
            dr.line([tuple(a + up * t), tuple(b + up * t)], fill=shade(face, 0.82), width=max(1, s // 2))
        dr.line([tuple(a + up), tuple(b + up)], fill=top, width=int(3.5 * s))
        k = max(2, int(np.hypot(*(b - a)) / (4 * s)))
        for j in range(k):
            q = a + up + (b - a) * (j + 0.5) / k
            dr.rectangle([q[0] - 0.9 * s, q[1] - 2.6 * s, q[0] + 0.9 * s, q[1]], fill=top, outline=INK)


def draw_plot(dr, p, o):
    s = SS
    c = (np.array(p["c"]) - o) * s
    u = unit(p["u"])
    v = np.array([-u[1], u[0]])
    L, W = p["L"] * s, p["W"] * s
    poly = [c + su * u * L / 2 + sv * v * W / 2 for su, sv in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    fill = PLOT_FILL[p["fill"]]
    dr.polygon([tuple(q) for q in poly], fill=fill)
    for t in np.linspace(-0.35, 0.35, 4):
        a = c + v * W * t - u * L * 0.45
        dr.line([tuple(a), tuple(a + u * L * 0.9)], fill=shade(fill, 0.85), width=max(1, s // 2))
    if p.get("orchard"):
        for t in np.linspace(-0.3, 0.3, 3):
            q = c + u * L * t
            r = 2.6 * s
            dr.ellipse([q[0] - r, q[1] - r * 1.6, q[0] + r, q[1] + r * 0.4], fill=(110, 112, 60), outline=INK)
    dr.line([tuple(q) for q in poly] + [tuple(poly[0])], fill=FENCE, width=int(1.4 * s))
    for i in range(4):
        a, b = poly[i], poly[(i + 1) % 4]
        k = max(1, int(np.hypot(*(b - a)) / (5 * s)))
        for j in range(k + 1):
            q = a + (b - a) * j / k
            dr.ellipse([q[0] - 0.8 * s, q[1] - 0.8 * s, q[0] + 0.8 * s, q[1] + 0.8 * s], fill=INK)


def draw_pier(dr, p, o):
    s = SS
    a = (np.array(p["a"]) - o) * s
    b = (np.array(p["b"]) - o) * s
    u = unit(b - a)
    v = np.array([-u[1], u[0]]) * 2.4 * s
    dr.polygon([tuple(a - v), tuple(b - v), tuple(b + v), tuple(a + v)], fill=PLANK, outline=INK)
    k = max(2, int(np.hypot(*(b - a)) / (3 * s)))
    for j in range(1, k):
        q = a + (b - a) * j / k
        dr.line([tuple(q - v), tuple(q + v)], fill=shade(PLANK, 0.75), width=max(1, s // 2))
    for q in (a - v * 1.2, a + v * 1.2, b - v * 1.2, b + v * 1.2):
        dr.ellipse([q[0] - s, q[1] - s, q[0] + s, q[1] + s], fill=INK)


def draw_quay(dr, run, o):
    s = SS
    P = [tuple((np.array(q) - o) * s) for q in run]
    dr.line(P, fill=INK, width=int(5 * s))
    dr.line(P, fill=STONE_FACE, width=int(3.4 * s))
    dr.line(P, fill=STONE_TOP, width=int(1.2 * s))


def draw_boat(dr, b, o):
    """Yukarıdan tekne: sivri gövde; büyükse direk ve yelken."""
    s = SS
    c = (np.array(b["c"]) - o) * s
    u = unit(b["u"])
    v = np.array([-u[1], u[0]])
    L = (16 if b["big"] else 10) * s
    W = (6 if b["big"] else 4) * s
    hull = [c + u * L / 2, c + u * L * 0.15 + v * W / 2, c - u * L / 2 + v * W * 0.4,
            c - u * L / 2 - v * W * 0.4, c + u * L * 0.15 - v * W / 2]
    dr.polygon([tuple(p) for p in hull], fill=PLANK, outline=INK)
    dr.polygon([tuple(c + (p - c) * 0.7) for p in hull], fill=shade(PLANK, 1.2))
    if b["big"]:
        m = c - np.array([0, 2 * s])
        dr.line([tuple(c), tuple(m - np.array([0, 12 * s]))], fill=INK, width=s)
        dr.polygon([tuple(m - np.array([5 * s, 11 * s])), tuple(m - np.array([-5 * s, 11 * s])),
                    tuple(m + np.array([4 * s, -3 * s])), tuple(m + np.array([-4 * s, -3 * s]))],
                   fill=SAIL, outline=INK)


def draw_yurt(dr, y, o, big=False):
    """Göçebe yurdu: keçe duvar bandı, alçak kubbe çatı, ışınlar, tepe deliği."""
    s = SS
    cx, cy = (np.array(y["c"]) - o) * s
    r = y["r"] * s * (1.7 if big else 1.0)
    wall_h = r * 0.55
    dr.ellipse([cx - r, cy - r * 0.45, cx + r, cy + r * 0.45], fill=shade(FELT, 0.8), outline=INK)
    dr.rectangle([cx - r, cy - wall_h, cx + r, cy], fill=FELT)
    dr.line([(cx - r, cy - wall_h), (cx - r, cy)], fill=INK, width=s)
    dr.line([(cx + r, cy - wall_h), (cx + r, cy)], fill=INK, width=s)
    band = (150, 60, 44) if big else (120, 88, 56)
    dr.rectangle([cx - r, cy - wall_h * 0.55, cx + r, cy - wall_h * 0.35], fill=band)
    top_c = cy - wall_h
    dr.ellipse([cx - r, top_c - r * 0.62, cx + r, top_c + r * 0.45], fill=FELT_ROOF, outline=INK)
    for a in np.linspace(0, np.pi * 2, 9, endpoint=False):
        dr.line([(cx, top_c - r * 0.12), (cx + np.cos(a) * r * 0.9, top_c - r * 0.08 + np.sin(a) * r * 0.42)],
                fill=shade(FELT_ROOF, 0.8), width=max(1, s // 2))
    dr.ellipse([cx - r * 0.22, top_c - r * 0.24, cx + r * 0.22, top_c - r * 0.02], fill=INK)
    dr.rectangle([cx - r * 0.18, cy - wall_h * 0.9, cx + r * 0.18, cy], fill=(110, 60, 40), outline=INK)
    if big:  # sancak
        dr.line([(cx + r * 0.9, cy - wall_h), (cx + r * 0.9, cy - wall_h - r * 2.0)], fill=INK, width=s)
        dr.polygon([(cx + r * 0.9, cy - wall_h - r * 2.0), (cx + r * 1.8, cy - wall_h - r * 1.75),
                    (cx + r * 0.9, cy - wall_h - r * 1.5)], fill=(160, 50, 40), outline=INK)


def draw_pen(dr, p, o, rng):
    """At ağılı: çit halkası, içinde birkaç at."""
    s = SS
    cx, cy = (np.array(p["c"]) - o) * s
    r = p["r"] * s
    pts = [(cx + np.cos(t) * r, cy + np.sin(t) * r * 0.6) for t in np.linspace(0, 2 * np.pi, 24)]
    dr.line(pts, fill=FENCE, width=int(1.3 * s))
    for q in pts[::2]:
        dr.ellipse([q[0] - 0.8 * s, q[1] - 0.8 * s, q[0] + 0.8 * s, q[1] + 0.8 * s], fill=INK)
    for _ in range(p["horses"]):
        a, rr = rng.random() * 2 * np.pi, rng.random() * 0.6 * r
        hx, hy = cx + np.cos(a) * rr, cy + np.sin(a) * rr * 0.6
        col = [(92, 62, 40), (130, 96, 64), (60, 46, 34), (200, 190, 170)][int(rng.integers(4))]
        dr.ellipse([hx - 2.6 * s, hy - 1.1 * s, hx + 2.6 * s, hy + 1.1 * s], fill=col, outline=INK)
        dr.ellipse([hx + 2.0 * s, hy - 1.6 * s, hx + 3.6 * s, hy - 0.2 * s], fill=col, outline=INK)


def draw_place(place):
    pts = [place["center"]]
    for h in place["houses"] + place["plots"]:
        pts.append(h["c"])
    pts += place["walls"]
    for pr in place["piers"]:
        pts += [pr["a"], pr["b"]]
    for k in ("yurts", "pens", "boats"):
        pts += [q["c"] for q in place.get(k, [])]
    for run in place.get("quay", []):
        pts += run
    P = np.array(pts, np.float64)
    o = P.min(0) - 70
    size = (P.max(0) + 70 - o).astype(int)
    im = Image.new("RGBA", (int(size[0] * SS), int(size[1] * SS)), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    rng = np.random.default_rng(int(place["center"][0] * 7 + place["center"][1]))
    for run in place.get("quay", []):
        draw_quay(dr, run, o)
    for pr in place["piers"]:
        draw_pier(dr, pr, o)
    for b in place.get("boats", []):
        draw_boat(dr, b, o)
    for pe in place.get("pens", []):
        draw_pen(dr, pe, o, rng)
    for p in place["plots"]:
        draw_plot(dr, p, o)
    wy = np.mean([w[1] for w in place["walls"]]) if place["walls"] else 0
    mat = place.get("material", "stone")
    opn = place.get("wall_open")
    face = STONE_DARK_FACE if mat == "dark" else STONE_FACE

    def tower(t):
        if mat == "wood":
            draw_wood_tower(dr, t, o)
        else:
            draw_tower(dr, t, o, face=face)
    if place["walls"]:
        draw_wall(dr, place["walls"], o, front=False, material=mat, open_=opn)
        for t in place["towers"]:
            if t["c"][1] <= wy:
                tower(t)
    items = [(h["c"][1], "h", h) for h in place["houses"]]
    items += [(y["c"][1], "y", y) for y in place.get("yurts", [])]
    if place.get("khan"):
        items.append((place["khan"]["c"][1], "K", place["khan"]))
    if place["church"]:
        items.append((place["church"]["c"][1], "c", place["church"]))
    if place["keep"]:
        items.append((place["keep"]["c"][1], "k", place["keep"]))
    for _, typ, it in sorted(items, key=lambda i: i[0]):
        if typ == "h":
            draw_house(dr, it, o)
        elif typ == "y":
            draw_yurt(dr, it, o)
        elif typ == "K":
            draw_yurt(dr, {"c": it["c"], "r": 7.5}, o, big=True)
        elif typ == "c":
            ch = dict(it, roof=4)
            # kilise: beyaz duvar, kırmızı çatı, batı ucunda çan kulesi
            draw_house(dr, ch, o)
            tc = np.array(it["c"]) - unit(it["u"]) * (it["L"] / 2 + 2) + np.array([0, it["W"] / 2])
            draw_tower(dr, {"c": tc.tolist(), "r": 3.6, "h": 19}, o, roof=(150, 72, 52))
        elif typ == "k":
            kc = np.array(it["c"])
            if it.get("solo"):
                draw_tower(dr, {"c": kc.tolist(), "r": it["r"], "h": it["h"]}, o, roof=(110, 84, 60))
            else:
                draw_house(dr, {"c": kc.tolist(), "u": [1, 0], "L": 20, "W": 16, "roof": 4}, o)
                draw_tower(dr, {"c": (kc + [9, 6]).tolist(), "r": 5, "h": it["h"]}, o)
    if place["walls"]:
        draw_wall(dr, place["walls"], o, front=True, material=mat, open_=opn)
        for t in place["towers"]:
            if t["c"][1] > wy:
                tower(t)
    im = im.resize((int(size[0]), int(size[1])), Image.LANCZOS)
    return im, o


def paste(dst, src, x, y):
    l, t = max(0, -x), max(0, -y)
    r = min(src.width, dst.width - x)
    b = min(src.height, dst.height - y)
    if r <= l or b <= t:
        return
    dst.alpha_composite(src.crop((l, t, r, b)), (x + l, y + t))


def draw(places):
    out = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    for place in sorted(places, key=lambda p: p["center"][1]):
        if not (place["houses"] or place["church"] or place["keep"] or place.get("yurts")):
            continue
        im, o = draw_place(place)
        a = np.asarray(im, np.float32)[..., 3]
        sh = Image.fromarray((a * 0.4).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.6))
        shadow = Image.new("RGBA", im.size, (24, 16, 8, 0))
        shadow.putalpha(sh)
        paste(out, shadow, int(o[0]) + 2, int(o[1]) + 2)
        paste(out, im, int(o[0]), int(o[1]))
    return out


def main():
    cmd, root = sys.argv[1], sys.argv[2]
    if cmd == "plan":
        dst = sys.argv[3]
        seed = int(sys.argv[4]) if len(sys.argv) > 4 else 0
        places, foot = plan(root, seed)
        json.dump(places, open(dst, "w"))
        np.save(dst + ".foot.npy", np.packbits(foot))
        moved = [(p["kind"], p["anchor"]) for p in places if p["moved"]]
        print("YER", len(places), "EV", sum(len(p["houses"]) for p in places),
              "PARSEL", sum(len(p["plots"]) for p in places),
              "İSKELE", sum(len(p["piers"]) for p in places), "ÇAPASI SUDA", moved)
    else:
        places = json.load(open(sys.argv[3]))
        draw(places).save(sys.argv[4])
        print("YAZILDI", sys.argv[4])


if __name__ == "__main__":
    main()
