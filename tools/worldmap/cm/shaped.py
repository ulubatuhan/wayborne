"""Araziye göre biçimlenen kentler.

Kentin sınırı bir elips değil: yolların uzandığı yöne uzar, kıyıda suyun
kenarında biter (sur yerine rıhtım ve iskele), yokuşta yükselir, uçurumda
durur. Evler gerçek yüksekliğe göre basamaklanır; kale ya da kutsal kule
kentin en yüksek yerine çıkar.
"""
import math
import os

import cv2
import numpy as np
from scipy import ndimage as ndi

import build as B
import towns as T
from build import C
from hand import INK, darker, ink, path, shape

LIFT = 0.55        # piksel / yükseklik birimi
LIFT_MAX = 18.0


class Terrain:
    def __init__(self, water, height, roads, mount):
        self.water, self.height, self.roads, self.mount = water, height, roads, mount
        self.N = water.shape[0]
        self.wdist = ndi.distance_transform_edt(~water)


def _pca_dir(xs, ys):
    if len(xs) < 5:
        return None
    cov = np.cov(np.stack([xs - xs.mean(), ys - ys.mean()]))
    ev, evec = np.linalg.eigh(cov)
    return math.atan2(evec[1, 1], evec[0, 1])


def footprint(terr, cx, cy, R, rng, port=False):
    N = terr.N
    pad = int(R * 2.2)
    x0, y0 = max(0, int(cx) - pad), max(0, int(cy) - pad)
    x1, y1 = min(N, int(cx) + pad), min(N, int(cy) + pad)
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
    water = terr.water[y0:y1, x0:x1]
    th = None
    aniso = 1.0
    bx_, by_ = cx, cy
    if port:
        d = terr.wdist[int(cy), int(cx)]
        if d > R * 0.35:
            wy, wx = np.nonzero(terr.water[y0:y1, x0:x1])
            if len(wx):
                k = int(np.argmin((wx + x0 - cx) ** 2 + (wy + y0 - cy) ** 2))
                tx, ty = wx[k] + x0, wy[k] + y0
                L = math.hypot(tx - cx, ty - cy)
                f = (L - R * 0.35) / L
                bx_, by_ = cx + (tx - cx) * f, cy + (ty - cy) * f
        wd = terr.wdist[y0:y1, x0:x1]
        ys, xs = np.nonzero((wd > 0.5) & (wd < 2.5) & ((xx - cx) ** 2 + (yy - cy) ** 2 < (R * 1.6) ** 2))
        th = _pca_dir(xs.astype(float), ys.astype(float))
        aniso, R = 1.55, R * 1.05
    if th is None:
        rr = terr.roads[y0:y1, x0:x1]
        ys, xs = np.nonzero(rr & ((xx - cx) ** 2 + (yy - cy) ** 2 < (R * 1.2) ** 2))
        th = _pca_dir(xs.astype(float), ys.astype(float))
        aniso = 1.3
    if th is None:
        th, aniso = rng.random() * math.pi, 1.15
    c, s = math.cos(th), math.sin(th)
    dx, dy = xx - (bx_ + cx) / 2, yy - (by_ + cy) / 2
    u = (dx * c + dy * s) / aniso
    v = (-dx * s + dy * c) * aniso
    # eğik bakış: yukarı-aşağı biraz basık
    vy = u * s + v * c
    ux = u * c - v * s
    vy = vy / 0.72
    ang = np.arctan2(vy, ux)
    p = rng.random(3) * 6.28
    rad = R * (1 + 0.10 * np.sin(2 * ang + p[0]) + 0.07 * np.sin(3 * ang + p[1]) + 0.04 * np.sin(5 * ang + p[2]))
    h = terr.height[y0:y1, x0:x1]
    h0 = terr.height[int(cy), int(cx)]
    # doğa şekli belirler: yükseklik farkı ve dağlık zemin "uzaklık" sayılır, kent düzlükte
    # ve vadide uzar, yokuşa doğru kısa kalır
    mt = terr.mount[y0:y1, x0:x1] if hasattr(terr, "mount") and terr.mount is not None else 0
    dist = np.hypot(ux, vy) + np.abs(h - h0) * 2.2 + np.clip(mt - 0.30, 0, 1) * R * 1.2
    dist = ndi.gaussian_filter(dist, R * 0.06)
    m = dist < rad
    wet = ndi.binary_dilation(water, iterations=1 if port else 3)
    m &= ~wet & (h < h0 + 22)
    if port:
        # liman kenti kıyıya kadar iner: blob ile deniz arasındaki şerit de kentin
        wdl = terr.wdist[y0:y1, x0:x1]
        m |= ndi.binary_dilation(m, iterations=int(R * 0.5)) & ~wet & (wdl < R * 0.5) & (h < h0 + 22)
    lab, n = ndi.label(m)
    if n == 0:
        return None
    k = lab[int(cy) - y0, int(cx) - x0]
    if k == 0:
        d = ndi.distance_transform_edt(lab == 0, return_indices=True)[1]
        k = lab[d[0][int(cy) - y0, int(cx) - x0], d[1][int(cy) - y0, int(cx) - x0]]
    m = lab == k
    # sur hattı köşeli: birkaç uzun düz kenar, yamuk açılar
    cs, _ = cv2.findContours(m.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    cnt = max(cs, key=len)
    sm = cv2.GaussianBlur(m.astype(np.float32), (0, 0), R * 0.08) > 0.5   # yumuşak kenar, sivri uç yok
    cs2, _ = cv2.findContours(sm.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    if cs2:
        cnt = max(cs2, key=len)
    eps = R * (0.035 + 0.02 * rng.random())                    # çok sayıda kısa sur parçası
    ap = cv2.approxPolyDP(cnt, eps, True)
    m2 = np.zeros(m.shape, np.uint8)
    cv2.fillPoly(m2, [ap], 1)
    m = (m2 > 0) & ~wet & (h < h0 + 22)
    if port:
        wdl = terr.wdist[y0:y1, x0:x1]
        m |= ndi.binary_dilation(m, iterations=8) & ~wet & (wdl <= 6)
    lab, n = ndi.label(m)
    if n > 1:
        sizes = ndi.sum(m, lab, range(1, n + 1))
        m = lab == (1 + int(np.argmax(sizes)))
    full = np.zeros((N, N), bool)
    full[y0:y1, x0:x1] = m
    cs, _ = cv2.findContours(m.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    cnt = max(cs, key=len)
    poly = cv2.approxPolyDP(cnt, 2.0, True)[:, 0, :].astype(float) + [x0, y0]
    return full, poly


def lift_at(terr, x, y, hmin):
    xi, yi = int(np.clip(x, 0, terr.N - 1)), int(np.clip(y, 0, terr.N - 1))
    return min(LIFT_MAX, max(0.0, (terr.height[yi, xi] - hmin) * LIFT))


def _edges(poly, mask, terr):
    out = []
    n = len(poly)
    for i in range(n):
        a, b = poly[i], poly[(i + 1) % n]
        e = b - a
        L = float(np.hypot(*e))
        if L < 0.5:
            continue
        nrm = np.array([e[1], -e[0]]) / L
        mid = (a + b) / 2
        q = mid + nrm * 3
        if 0 <= int(q[1]) < terr.N and 0 <= int(q[0]) < terr.N and mask[int(q[1]), int(q[0])]:
            nrm = -nrm
        coast = False
        for k in (2, 4, 7):
            o = mid + nrm * k
            if terr.wdist[int(np.clip(o[1], 0, terr.N - 1)), int(np.clip(o[0], 0, terr.N - 1))] < 1.5:
                coast = True
        gate = bool(terr.roads[int(np.clip(mid[1], 0, terr.N - 1)), int(np.clip(mid[0], 0, terr.N - 1))])
        out.append(dict(a=a, b=b, n=nrm, mid=mid, L=L, coast=coast, gate=gate))
    return out


def _wall_seg(ctx, rng, a, b, la, lb, h, stone, back, palisade):
    a2, b2 = (a[0], a[1] - la), (b[0], b[1] - lb)
    if palisade:
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        for t in np.linspace(0, 1, max(2, int(L / 2.1))):
            x = a2[0] + (b2[0] - a2[0]) * t
            y = a2[1] + (b2[1] - a2[1]) * t
            hh = h * (0.9 + 0.2 * rng.random())
            shape(ctx, [(x - 1.0, y), (x + 1.0, y), (x + 1.0, y - hh), (x, y - hh - 1.8), (x - 1.0, y - hh)],
                  C["timber"], rng, w=0.55, alpha=0.8)
        return
    band = [a2, b2, (b2[0], b2[1] - h), (a2[0], a2[1] - h)]
    shape(ctx, band, darker(stone, 0.8 if back else 0.94), rng, hatch_angle=1.5 if back else None, hatch_sp=2.4,
          hatch_alpha=0.35, w=0.9)
    ink(ctx, [(a2[0], a2[1] - h * 0.45), (b2[0], b2[1] - h * 0.45)], rng, 0.4, closed=False, amp=0.2, alpha=0.5)
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    for t in np.arange(1.5 / max(L, 1), 1, 4.0 / max(L, 1)):
        x = a2[0] + (b2[0] - a2[0]) * t
        y = a2[1] + (b2[1] - a2[1]) * t - h
        shape(ctx, [(x - 0.9, y), (x + 0.9, y), (x + 0.9, y - 1.8), (x - 0.9, y - 1.8)], stone, rng, w=0.5)


def _quay(ctx, rng, a, b, la, lb, nrm, front):
    a2, b2 = (a[0], a[1] - la), (b[0], b[1] - lb)
    if front:
        band = [a2, b2, (b2[0], b2[1] + 3.0), (a2[0], a2[1] + 3.0)]
        shape(ctx, band, (0.80, 0.77, 0.70), rng, hatch_angle=1.5, hatch_sp=2.0, hatch_alpha=0.4, w=0.8)
    else:
        ink(ctx, [a2, b2], rng, 1.0, closed=False, amp=0.2)


def _pier(ctx, rng, mid, nrm, lift, L):
    p0 = (mid[0], mid[1] - lift + 1)
    p1 = (mid[0] + nrm[0] * L, mid[1] + nrm[1] * L * 0.8)
    t = np.array([-nrm[1], nrm[0]]) * 1.6
    shape(ctx, [(p0[0] + t[0], p0[1] + t[1]), (p1[0] + t[0], p1[1] + t[1]), (p1[0] - t[0], p1[1] - t[1]),
                (p0[0] - t[0], p0[1] - t[1])], (0.66, 0.50, 0.33), rng, w=0.7)
    for k in np.linspace(0.3, 1, 4):
        x, y = p0[0] + (p1[0] - p0[0]) * k, p0[1] + (p1[1] - p0[1]) * k
        ink(ctx, [(x, y + 1.5), (x, y + 4)], rng, 0.6, closed=False, amp=0.05)


def city(ctx, rng, terr, fp, culture, R, port=False):
    st = T.STYLE[culture]
    mask, poly = fp
    ys, xs = np.nonzero(mask)
    hs = terr.height[ys, xs]
    hmin = float(np.percentile(hs, 5))
    lift = lambda x, y: lift_at(terr, x, y, hmin)  # noqa: E731
    edges = _edges(poly, mask, terr)
    wh = 7.0 if not st["palisade"] else 6.0
    # simge yapı: kutsal kent ve imparatorluk en yüksek yere, ötekiler merkeze
    if culture in ("ahit", "imparatorluk", "dag", "dag_maden"):
        er = ndi.binary_erosion(mask, iterations=int(R * 0.25))
        cand = np.nonzero(er) if er.any() else (ys, xs)
        i = int(np.argmax(terr.height[cand[0], cand[1]]))
        lx, ly = float(cand[1][i]), float(cand[0][i])
    else:
        er = ndi.binary_erosion(mask, iterations=int(R * 0.25))
        cy2, cx2 = ndi.center_of_mass(er if er.any() else mask)
        lx, ly = float(cx2), float(cy2)
    s = R / 100.0 + 0.45
    citadel = culture in ("imparatorluk", "ahit") or R >= 120
    scattered = culture in ("sinir", "dag", "dag_maden") or rng.random() < 0.25
    inner = _citadel_mask(mask, lx, ly, R, rng) if citadel else None
    if port:
        harbor(ctx, rng, terr, edges, lift, front=False)
    sub_back, sub_front = _suburbs(terr, mask, R * (1.6 if scattered else 1.0), rng)
    for x, y in sub_back:
        _sub_house(ctx, rng, st, x, y - lift(x, y))
    # surun arkası
    back = sorted([e for e in edges if e["n"][1] <= 0.15], key=lambda e: e["mid"][1])
    front = sorted([e for e in edges if e["n"][1] > 0.15], key=lambda e: e["mid"][1])
    towers = _tower_spots(edges)
    for e in back:
        if e["coast"]:
            _quay(ctx, rng, e["a"], e["b"], lift(*e["a"]), lift(*e["b"]), e["n"], False)
        else:
            _wall_seg(ctx, rng, e["a"], e["b"], lift(*e["a"]), lift(*e["b"]), wh, st["stone"], True, st["palisade"])
    for (x, y, fr) in sorted(towers, key=lambda t: t[1]):
        if not fr:
            _tower(ctx, rng, st, x, y - lift(x, y), wh)
    # evler: kapıdan meydana caddeler, caddeden ara sokaklar, evler sokak kenarında
    eroded = ndi.binary_erosion(mask, iterations=6)
    pts, plaza = _street_layout(rng, terr, mask, eroded, inner, lx, ly, edges, port, R)
    if scattered:
        pts = [p for p in pts if rng.random() > 0.25]
    if inner is not None:
        items = [(y, "h", x) for x, y in pts] + [(float(np.nonzero(inner[0])[0].max()), "C", lx)]
    else:
        items = [(y, "h", x) for x, y in pts] + [(ly + 2, "L", lx)]
    if plaza is not None:
        items.append((plaza[1], "P", plaza[0]))
    coast_pts = [e["mid"] for e in edges if e["coast"]]
    if port:
        # kıyı boyunca açık bir rıhtım şeridi: evler suyun dibine yığılmasın
        qz = np.zeros_like(mask)
        for e in edges:
            if e["coast"]:
                cv2.line(qz.view(np.uint8), tuple(int(v) for v in e["a"]), tuple(int(v) for v in e["b"]), 1, 9)
        items = [it for it in items if it[1] == "L" or not qz[int(it[0]), int(it[2])]]
    for y, k, x in sorted(items):
        up = lift(x, y)
        if k == "L":
            T.landmark(ctx, rng, culture, x, y - up, s)
            continue
        if k == "P":
            _plaza(ctx, rng, x, y - up)
            continue
        if k == "C":
            _draw_citadel(ctx, rng, terr, inner, lift, st, culture, lx, ly, s, wh)
            continue
        if rng.random() < 0.07:
            T._tree(ctx, rng, st, x, y - up, 0.75)
            continue
        near_coast = port and any(math.hypot(x - a, y - b) < 16 for a, b in coast_pts)
        a = T._house_args(st, rng, 1.0 + (0.35 if near_coast else 0))
        if near_coast:     # ambarlar: rıhtım boyunca uzun, alçak
            a["w"] *= 1.5
            a["kind"] = "eave"
        B.house(ctx, rng, x, y - up, a["w"], a["d"], a["h"], a["rh"], a["wall"], a["roof"], a["kind"],
                timber=a["timber"], chimney=a["chimney"], flat=a["flat"])
    # surun önü, kapılar, iskeleler
    for e in front:
        la, lb = lift(*e["a"]), lift(*e["b"])
        if e["coast"]:
            _quay(ctx, rng, e["a"], e["b"], la, lb, e["n"], True)
        elif e["gate"] and e["L"] > 6:
            _wall_seg(ctx, rng, e["a"], e["b"], la, lb, wh, st["stone"], False, st["palisade"])
            m = e["mid"]
            _gate(ctx, rng, st, m[0], m[1] - lift(*m), wh)
        else:
            _wall_seg(ctx, rng, e["a"], e["b"], la, lb, wh, st["stone"], False, st["palisade"])
    for (x, y, fr) in sorted(towers, key=lambda t: t[1]):
        if fr:
            _tower(ctx, rng, st, x, y - lift(x, y), wh)
    for x, y in sub_front:
        _sub_house(ctx, rng, st, x, y - lift(x, y))
    if port:
        harbor(ctx, rng, terr, edges, lift, front=True)
    return dict(mask=mask, poly=poly, landmark=(lx, ly))


def _tower_spots(edges):
    out, acc = [], 0.0
    for i, e in enumerate(edges):
        nxt = edges[(i + 1) % len(edges)]
        acc += e["L"]
        turn = abs(math.atan2(e["n"][0] * nxt["n"][1] - e["n"][1] * nxt["n"][0], e["n"] @ nxt["n"]))
        if e["coast"] or nxt["coast"]:
            acc = 0
            continue
        if acc > 40 or (turn > 0.5 and acc > 14):
            acc = 0
            nn = e["n"] + nxt["n"]
            out.append((e["b"][0], e["b"][1], nn[1] > 0.1))
    return out


def _tower(ctx, rng, st, x, y, wh):
    if st["palisade"]:
        B.square_tower(ctx, rng, x, y, 5.5, wh * 2.2, C["timber"], roof=C["shingle"], roof_h=5)
    elif st.get("square"):
        B.square_tower(ctx, rng, x, y, 7, wh * 2.2, st["stone"])
    else:
        B.round_tower(ctx, rng, x, y, 3.6, wh * 2.0, st["stone"], cap=st["cap"], cap_color=st["cap_color"])


def _gate(ctx, rng, st, x, y, wh):
    if st["palisade"]:
        B.square_tower(ctx, rng, x - 5, y, 5, wh * 2.4, C["timber"], roof=C["shingle"], roof_h=5)
        B.square_tower(ctx, rng, x + 5, y, 5, wh * 2.4, C["timber"], roof=C["shingle"], roof_h=5, flag=st["flag"])
        return
    _tower(ctx, rng, st, x - 6.5, y, wh * 1.1)
    shape(ctx, [(x - 4.5, y), (x + 4.5, y), (x + 4.5, y - wh - 4), (x - 4.5, y - wh - 4)], st["stone"], rng, w=0.9)
    B.door(ctx, x, y, wh + 1, 4.5)
    if st.get("square"):
        B.square_tower(ctx, rng, x + 6.5, y, 7, wh * 2.4, st["stone"], flag=st["flag"])
    else:
        B.round_tower(ctx, rng, x + 6.5, y, 3.8, wh * 2.3, st["stone"], cap=st["cap"], cap_color=st["cap_color"],
                      flag=st["flag"])


def _suburbs(terr, mask, R, rng):
    """Surun dışında yol boyunca dizilen evler: kent kapısından taşan varoş."""
    ring = ndi.binary_dilation(mask, iterations=int(R * 0.45)) & ~ndi.binary_dilation(mask, iterations=7)
    road = ndi.binary_dilation(terr.roads, iterations=3) & ring & ~ndi.binary_dilation(terr.water, iterations=4)
    ys, xs = np.nonzero(road)
    pts = []
    for i in rng.permutation(len(xs)):
        x, y = float(xs[i]), float(ys[i])
        if all(((x - a) / 11) ** 2 + ((y - b) / 6) ** 2 > 1 for a, b in pts):
            pts.append((x, y))
        if len(pts) >= int(R * 0.18):
            break
    top = np.nonzero(mask)[0].mean()
    back = sorted([p for p in pts if p[1] < top], key=lambda p: p[1])
    front = sorted([p for p in pts if p[1] >= top], key=lambda p: p[1])
    return back, front


def _sub_house(ctx, rng, st, x, y):
    if rng.random() < 0.18:
        T._tree(ctx, rng, st, x, y, 0.8)
        return
    a = T._house_args(st, rng, 0.85)
    B.house(ctx, rng, x, y, a["w"], a["d"], a["h"], a["rh"], a["wall"], a["roof"], a["kind"], timber=a["timber"],
            chimney=a["chimney"], flat=a["flat"])


def harbor(ctx, rng, terr, edges, lift, front):
    """Kıyı: taş rıhtım, iskeleler ve yanlarına bağlı tekneler, bir vinç, ucunda
    fener kulesi olan kıvrık bir dalgakıran. front=False: denizi arkada kalan
    kıyı parçaları (evlerden önce çizilir), True: önde kalanlar."""
    coast = [e for e in edges if e["coast"] and ((e["n"][1] > 0.15) == front)]
    if not coast:
        return
    for e in sorted(coast, key=lambda e: e["mid"][1]):
        a, b = e["a"], e["b"]
        la, lb = lift(*a), lift(*b)
        a2, b2 = (a[0], a[1] - la), (b[0], b[1] - lb)
        out = e["n"] * 3.2
        band = [a2, b2, (b2[0] + out[0], b2[1] + out[1] + 2.5), (a2[0] + out[0], a2[1] + out[1] + 2.5)]
        shape(ctx, band, (0.82, 0.79, 0.72), rng, hatch_angle=1.5, hatch_sp=2.2, hatch_alpha=0.35, w=0.8)
        L = e["L"]
        for t in np.arange(2.5 / max(L, 1), 1, 5 / max(L, 1)):
            x = a2[0] + (b2[0] - a2[0]) * t + out[0]
            y = a2[1] + (b2[1] - a2[1]) * t + out[1]
            ink(ctx, [(x, y), (x, y + 2.5)], rng, 0.4, closed=False, amp=0.05, alpha=0.6)
    # iskeleler: kıyı boyunca eşit aralıkla
    acc, piers = 0.0, []
    for e in coast:
        acc += e["L"]
        if acc > 22:
            acc = 0
            piers.append(e)
    for e in sorted(piers, key=lambda e: e["mid"][1]):
        L = 18 + 12 * rng.random()
        p1 = e["mid"] + e["n"] * L
        if terr.wdist[int(np.clip(p1[1], 0, terr.N - 1)), int(np.clip(p1[0], 0, terr.N - 1))] > 0:
            continue
        _pier(ctx, rng, e["mid"], e["n"], lift(*e["mid"]), L)
        if rng.random() < 0.7:
            t = np.array([-e["n"][1], e["n"][0]])
            q = e["mid"] + e["n"] * L * 0.6 + t * 5.5
            B.boat(ctx, rng, q[0], q[1] + 2, 0.75, 1 if t[0] > 0 else -1)
    if front and coast:
        e = coast[len(coast) // 2]
        m = e["mid"]
        _crane(ctx, rng, m[0] - e["n"][1] * 8, m[1] - lift(*m) - 1)
    # dalgakıran: en açık suya bakan kıyı noktasından çıkar, kıyıya paralel kıvrılır
    if front or not coast:
        cand = coast if front else []
        best, bscore = None, -1
        allc = [e for e in edges if e["coast"]]
        for e in allc:
            sc = 0
            for k in range(4, 80, 4):
                p = e["mid"] + e["n"] * k
                if terr.wdist[int(np.clip(p[1], 0, terr.N - 1)), int(np.clip(p[0], 0, terr.N - 1))] > 0:
                    break
                sc = k
            if sc > bscore:
                best, bscore = e, sc
        if best is not None and bscore > 40 and (best["n"][1] > 0.15) == front:
            _mole(ctx, rng, terr, best, lift)


def _mole(ctx, rng, terr, e, lift):
    n = e["n"]
    t = np.array([-n[1], n[0]])
    if t[0] < 0:
        t = -t
    p = e["a"] if np.dot(e["a"] - e["b"], t) < 0 else e["b"]
    pts = [p.copy()]
    d = n.copy()
    for i in range(16):
        ang = 0.09 if i > 4 else 0.0
        c, s = math.cos(ang), math.sin(ang)
        d = np.array([d[0] * c - d[1] * s, d[0] * s + d[1] * c])
        q = pts[-1] + d * 4.5
        if terr.wdist[int(np.clip(q[1], 0, terr.N - 1)), int(np.clip(q[0], 0, terr.N - 1))] > 0 and i > 1:
            break
        pts.append(q)
    if len(pts) < 6:
        return
    pts = np.array(pts)
    pts[0, 1] -= lift(*pts[0])
    w = 3.0
    left, right = [], []
    for i in range(len(pts)):
        a = pts[max(0, i - 1)]
        b = pts[min(len(pts) - 1, i + 1)]
        dlt = b - a
        dlt /= max(np.linalg.norm(dlt), 1e-6)
        nn = np.array([-dlt[1], dlt[0]])
        left.append(pts[i] + nn * w)
        right.append(pts[i] - nn * w)
    poly = left + right[::-1]
    shape(ctx, poly, (0.80, 0.77, 0.70), rng, hatch_angle=1.5, hatch_sp=2.4, hatch_alpha=0.3, w=0.9)
    for i in range(1, len(pts) - 1, 2):
        ink(ctx, [left[i], right[i]], rng, 0.4, closed=False, amp=0.05, alpha=0.6)
    end = pts[-1]
    B.lighthouse(ctx, rng, end[0], end[1] + 2, 0.55)


def _crane(ctx, rng, x, y):
    """Rıhtım vinci: iki ayak, eğik kol, ucunda sarkan yük."""
    ink(ctx, [(x - 3, y), (x, y - 12), (x + 3, y)], rng, 0.9, closed=False, amp=0.1, color=C["timber"])
    ink(ctx, [(x, y - 12), (x + 11, y - 17)], rng, 0.9, closed=False, amp=0.1, color=C["timber"])
    ink(ctx, [(x + 11, y - 17), (x + 11, y - 8)], rng, 0.4, closed=False, amp=0.05)
    shape(ctx, [(x + 9.5, y - 8), (x + 12.5, y - 8), (x + 12.5, y - 5.5), (x + 9.5, y - 5.5)], (0.70, 0.55, 0.38),
          rng, w=0.5)


def _citadel_mask(mask, lx, ly, R, rng):
    """İç kale: simge yapının çevresinde küçük, köşeli bir avlu."""
    n = int(rng.integers(5, 8))
    rot = rng.random() * 6.28
    rr = R * 0.30
    pts = []
    for i in range(n):
        a = rot + 2 * math.pi * i / n + rng.normal(0, 0.15)
        k = rr * (0.8 + 0.4 * rng.random())
        pts.append((lx + k * math.cos(a), ly + 0.72 * k * math.sin(a)))
    m = np.zeros(mask.shape, np.uint8)
    cv2.fillPoly(m, [np.array(pts, np.int32)], 1)
    m = (m > 0) & ndi.binary_erosion(mask, iterations=8)
    if m.sum() < 200:
        return None
    lab, nlab = ndi.label(m)
    if nlab > 1:
        sizes = ndi.sum(m, lab, range(1, nlab + 1))
        m = lab == (1 + int(np.argmax(sizes)))
    cs, _ = cv2.findContours(m.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    poly = cv2.approxPolyDP(max(cs, key=len), 1.5, True)[:, 0, :].astype(float)
    return m, ndi.binary_dilation(m, iterations=6), poly


def _draw_citadel(ctx, rng, terr, inner, lift, st, culture, lx, ly, s, wh):
    """Yükseltilmiş iç kale: toprak sırt (motte) ya da taş platform, iç sur,
    kuleler, ortada simge yapı."""
    m, _, poly = inner
    raise_ = 16.0 if st["palisade"] else 11.0
    lin = lambda x, y: lift(x, y) + raise_  # noqa: E731
    edges = []
    n = len(poly)
    for i in range(n):
        a, b = poly[i], poly[(i + 1) % n]
        e = b - a
        L = float(np.hypot(*e))
        if L < 0.5:
            continue
        nrm = np.array([e[1], -e[0]]) / L
        mid = (a + b) / 2
        q = mid + nrm * 3
        if m[int(np.clip(q[1], 0, m.shape[0] - 1)), int(np.clip(q[0], 0, m.shape[1] - 1))]:
            nrm = -nrm
        edges.append(dict(a=a, b=b, n=nrm, mid=mid, L=L, coast=False, gate=False))
    # üst yüzey ve önden görünen yamaç
    top = [(p[0], p[1] - lin(*p)) for p in poly]
    earth = (0.80, 0.70, 0.52) if st["palisade"] else darker(st["stone"], 0.9)
    shape(ctx, top, (0.90, 0.86, 0.74), rng, w=0.8)
    for e in sorted([e for e in edges if e["n"][1] > 0.05], key=lambda e: e["mid"][1]):
        a, b = e["a"], e["b"]
        face = [(a[0], a[1] - lin(*a)), (b[0], b[1] - lin(*b)), (b[0], b[1] - lift(*b)), (a[0], a[1] - lift(*a))]
        shape(ctx, face, earth, rng, hatch_angle=1.35 if st["palisade"] else 1.5, hatch_sp=1.8, hatch_alpha=0.5, w=0.9)
    hw = wh * 1.15
    back = sorted([e for e in edges if e["n"][1] <= 0.15], key=lambda e: e["mid"][1])
    front = sorted([e for e in edges if e["n"][1] > 0.15], key=lambda e: e["mid"][1])
    towers = _tower_spots(edges)
    for e in back:
        _wall_seg(ctx, rng, e["a"], e["b"], lin(*e["a"]), lin(*e["b"]), hw, st["stone"], True, st["palisade"])
    for (x, y, fr) in sorted(towers, key=lambda t: t[1]):
        if not fr:
            _tower(ctx, rng, st, x, y - lin(x, y), hw * 1.1)
    T.landmark(ctx, rng, culture, lx, ly + 2 - lin(lx, ly), s)
    for e in front:
        _wall_seg(ctx, rng, e["a"], e["b"], lin(*e["a"]), lin(*e["b"]), hw, st["stone"], False, st["palisade"])
    for (x, y, fr) in sorted(towers, key=lambda t: t[1]):
        if fr:
            _tower(ctx, rng, st, x, y - lin(x, y), hw * 1.1)
    if front:
        e = max(front, key=lambda e: e["L"])
        g = e["mid"]
        _gate(ctx, rng, st, g[0], g[1] - lin(*g), hw)
        # kapıdan aşağı inen rampa
        ink(ctx, [(g[0] - 3, g[1] - lin(*g) + 1), (g[0] - 4, g[1] - lift(*g) + 3)], rng, 0.6, closed=False, amp=0.1)
        ink(ctx, [(g[0] + 3, g[1] - lin(*g) + 1), (g[0] + 4, g[1] - lift(*g) + 3)], rng, 0.6, closed=False, amp=0.1)


def _poly_walk(p0, p1, rng, bend=0.12):
    m = (p0 + p1) / 2
    d = p1 - p0
    m = m + np.array([-d[1], d[0]]) * rng.normal(0, bend)
    out = [p0 + (m - p0) * t for t in np.linspace(0, 1, 8)] + [m + (p1 - m) * t for t in np.linspace(0, 1, 8)[1:]]
    return np.array(out)


def _street_layout(rng, terr, mask, eroded, inner, lx, ly, edges, port, R):
    """Sokak ağı ve sokak kenarı ev noktaları."""
    blocked = inner[1] if inner is not None else np.zeros_like(mask)
    hub = np.array([lx, ly + (R * 0.3 if inner is not None else R * 0.18)])
    if not eroded[int(np.clip(hub[1], 0, mask.shape[0] - 1)), int(np.clip(hub[0], 0, mask.shape[1] - 1))]:
        hub = np.array([lx, ly])
    gates = [e["mid"] for e in edges if e["gate"] and not e["coast"]]
    land = [e for e in edges if not e["coast"]]
    land.sort(key=lambda e: -e["L"])
    while len(gates) < 3 and land:
        e = land.pop(0)
        if all(np.hypot(*(e["mid"] - g)) > R * 0.5 for g in gates):
            gates.append(e["mid"])
    streets = [_poly_walk(g, hub, rng) for g in gates]
    if port:
        # kıyı boyunca bitişik kıyı kenarlarından koşular: her biri bir rıhtım caddesi
        runs, cur = [], []
        for e in edges:
            if e["coast"]:
                cur.append(e)
            elif cur:
                runs.append(cur)
                cur = []
        if cur:
            if runs and edges[0]["coast"]:
                runs[0] = cur + runs[0]
            else:
                runs.append(cur)
        for run in runs:
            if sum(e["L"] for e in run) < 40:
                continue
            for off in (13, 33):
                row = [e["mid"] - e["n"] * off for e in run]
                row = [q for q in row if eroded[int(np.clip(q[1], 0, mask.shape[0] - 1)),
                                                int(np.clip(q[0], 0, mask.shape[1] - 1))]]
                if len(row) > 2:
                    streets.append(np.array(row))
            mid = run[len(run) // 2]["mid"] - run[len(run) // 2]["n"] * 13
            streets.append(_poly_walk(np.array(mid), hub, rng, 0.05))
    # ara sokaklar: caddeye dik, belli aralıkla
    side = []
    for st_ in streets:
        L = np.cumsum(np.r_[0, np.hypot(*np.diff(st_, axis=0).T)])
        for d0 in np.arange(R * 0.35, L[-1] - 10, R * 0.42):
            i = int(np.searchsorted(L, d0))
            i = min(max(i, 1), len(st_) - 1)
            t = st_[i] - st_[i - 1]
            t = t / max(np.linalg.norm(t), 1e-6)
            nrm = np.array([-t[1], t[0]])
            for sg in (-1, 1):
                if rng.random() < 0.45:
                    continue
                q = [st_[i]]
                for k in range(1, 22):
                    p = st_[i] + nrm * sg * k * 3.0 + t * rng.normal(0, 0.4) * k * 0.3
                    if not eroded[int(np.clip(p[1], 0, mask.shape[0] - 1)), int(np.clip(p[0], 0, mask.shape[1] - 1))]:
                        break
                    q.append(p)
                if len(q) > 5:
                    side.append(np.array(q))
    # surun iç yanında dolaşan sokak
    ring = ndi.binary_erosion(mask, iterations=16)
    if ring.sum() > 400:
        cs, _ = cv2.findContours(ring.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
        c = max(cs, key=len)[::4, 0, :].astype(float)
        if len(c) > 8:
            streets.append(np.vstack([c, c[:1]]))
    allst = streets + side
    # sokak maskesi: evler sokağın üstüne konmaz
    smask = np.zeros(mask.shape, np.uint8)
    for st_ in allst:
        cv2.polylines(smask, [st_.astype(np.int32)], False, 1, 4)
    cv2.circle(smask, tuple(int(v) for v in hub), int(R * 0.13), 1, -1)
    houses = []
    for st_ in allst:
        L = np.cumsum(np.r_[0, np.hypot(*np.diff(st_, axis=0).T)])
        d = 4.0
        while d < L[-1]:
            i = min(max(int(np.searchsorted(L, d)), 1), len(st_) - 1)
            t = st_[i] - st_[i - 1]
            t = t / max(np.linalg.norm(t), 1e-6)
            nrm = np.array([-t[1], t[0]])
            for sg in (-1, 1):
                p = st_[i] + nrm * sg * (8.5 + rng.random() * 1.5)
                xi, yi = int(p[0]), int(p[1])
                if not (0 <= xi < mask.shape[1] and 0 <= yi < mask.shape[0]):
                    continue
                if not eroded[yi, xi] or blocked[yi, xi] or smask[yi, xi]:
                    continue
                if rng.random() < 0.12:        # bahçe, avlu: her parsel dolu değil
                    continue
                if all(((p[0] - a) / 10.0) ** 2 + ((p[1] - b) / 6.5) ** 2 > 1 for a, b in houses):
                    houses.append((float(p[0]), float(p[1])))
            d += 10.5 + rng.random() * 2
    import os
    if os.environ.get("CM_DEBUG"):
        print("sokak", len(streets), len(side), "ev", len(houses), "kiyi", sum(e["coast"] for e in edges), "kenar", len(edges))
        dbg = np.dstack([mask * 80, eroded * 80, smask * 255]).astype(np.uint8)
        for a, b in houses:
            dbg[int(b), int(a)] = 255
        cv2.imwrite(os.path.join(os.environ.get("CM_DEBUG_DIR", "."), "dbg_%d.png" % int(lx)), dbg)
    return houses, (float(hub[0]), float(hub[1]))


def _plaza(ctx, rng, x, y):
    """Pazar meydanı: kuyu ve birkaç tenteli tezgâh."""
    shape(ctx, list(B.ellipse_pts(x, y, 3.2, 1.4, 0, 2 * math.pi, 12)), (0.55, 0.62, 0.62), rng, w=0.7)
    ink(ctx, [(x - 2.5, y), (x - 2.5, y - 5), (x + 2.5, y - 5), (x + 2.5, y)], rng, 0.6, closed=False, amp=0.05)
    for k, (dx, dy) in enumerate([(-11, 3), (10, 2), (-2, 8)]):
        col = [(0.80, 0.34, 0.22), (0.86, 0.78, 0.50), (0.45, 0.60, 0.32)][k]
        px, py = x + dx, y + dy
        ink(ctx, [(px - 3, py), (px - 3, py - 4)], rng, 0.5, closed=False, amp=0.05)
        ink(ctx, [(px + 3, py), (px + 3, py - 4)], rng, 0.5, closed=False, amp=0.05)
        shape(ctx, [(px - 4, py - 4), (px + 4, py - 4), (px + 3, py - 6.5), (px - 3, py - 6.5)], col, rng, w=0.5)
