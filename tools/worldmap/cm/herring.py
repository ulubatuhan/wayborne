"""referans harita haritasının dağ dili: balıksırtı sıradağlar.

Her sıradağın bir omurgası (ana sırt) var; omurgadan iki yana, eşit aralıkla
ve aynı açıyla paralel kollar iner. Kolun gölge tarafı (güneydoğuya bakan yüz)
düz, tek bir açık mürekkep tonuyla dolar; ışık tarafı kâğıt kalır. Uzun
kolların ortasından yarı boyda ikincil kollar çıkar. Kabartma yok: ton yalnızca
iki kademe (dolu/boş), geçiş yok.
"""
import math

import numpy as np
from scipy import ndimage as ndi

from rock import _hessian, _nms, _trace

LIGHT = np.array([-0.70, -0.70])          # ışık kuzeybatıdan


def _smooth_line(p, k=2):
    for _ in range(k):
        p[1:-1] = (p[:-2] + 2 * p[1:-1] + p[2:]) / 4
    return p


def _resample(p, step):
    seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(p, axis=0), axis=1))]
    if seg[-1] < step:
        return p
    s = np.arange(0, seg[-1], step)
    return np.stack([np.interp(s, seg, p[:, 0]), np.interp(s, seg, p[:, 1])], 1)


def _walk(start, d, mz, ok, Lmax, occ=None, step=1.5):
    """Kolu yön boyunca dağ alanı bitene ya da başka bir kola çarpana kadar uzat."""
    H, W = mz.shape
    pts = [start]
    p = start.copy()
    L = 0.0
    while L < Lmax:
        q = p + d * step
        xi, yi = int(q[0]), int(q[1])
        if not (0 <= xi < W and 0 <= yi < H) or not ok[yi, xi] or mz[yi, xi] < 0.25:
            break
        if occ is not None and L > 4 and occ[yi, xi]:
            break
        p = q
        L += step
        pts.append(p.copy())
    return np.array(pts, np.float32), L


def _orient(M, sig=10.0):
    """Sıradağ yönü: kütlenin uzandığı doğrultu (yapı tensörü, işaretsiz)."""
    D = ndi.distance_transform_edt(M).astype(np.float32)
    D = ndi.gaussian_filter(D, 4)
    gy, gx = np.gradient(D)
    jxx = ndi.gaussian_filter(gx * gx, sig)
    jxy = ndi.gaussian_filter(gx * gy, sig)
    jyy = ndi.gaussian_filter(gy * gy, sig)
    th = 0.5 * np.arctan2(2 * jxy, jxx - jyy) + np.pi / 2      # gradyana dik
    return np.cos(th), np.sin(th), D


def _stream(seed, tx, ty, M, block, maxlen, step=2.0):
    H, W = M.shape
    halves = []
    for sgn in (1, -1):
        p = seed.astype(np.float64).copy()
        d = np.array([tx[int(p[1]), int(p[0])], ty[int(p[1]), int(p[0])]]) * sgn
        pts = []
        L = 0.0
        while L < maxlen / 2:
            xi, yi = int(p[0]), int(p[1])
            if not (0 <= xi < W and 0 <= yi < H) or not M[yi, xi] or (L > 0 and block[yi, xi]):
                break
            pts.append(p.copy())
            nd = np.array([tx[yi, xi], ty[yi, xi]])
            if nd @ d < 0:
                nd = -nd
            d = 0.7 * d + 0.3 * nd
            d /= np.linalg.norm(d) + 1e-9
            p = p + d * step
            L += step
        halves.append(pts)
    return np.array(halves[1][::-1] + halves[0][1:], np.float64) if len(halves[0]) + len(halves[1]) > 2 else None


def build(height, mount, water, keep, roads, rng, qs=None, sep=36.0, spacing=5.5):
    """Döner [(noktalar, genişlik, alfa, tür)]; tür: tone, spine, spur, sub, hach."""
    import cv2
    wdist = ndi.distance_transform_edt(~water)
    ok = (wdist > 6) & ~keep & ~ndi.binary_dilation(roads, iterations=3)
    mz = ndi.gaussian_filter(np.clip((mount - 0.30) / 0.28, 0, 1), 4)
    M = ndi.binary_opening((mz > 0.40) & ok, iterations=2)
    out = []
    if M.sum() < 200:
        return out
    tx, ty, D = _orient(M, 20.0)
    ridge_occ = np.zeros(M.shape, np.uint8)
    spur_occ = np.zeros(M.shape, np.uint8)
    # tohumlar: ızgara, kütlenin içinden dışına
    ys, xs = np.nonzero(M & (D > 4))
    if not len(xs):
        return out
    pick = {}
    for i in rng.permutation(len(xs)):
        g = (xs[i] // int(sep * 0.7), ys[i] // int(sep * 0.7))
        if g not in pick:
            pick[g] = (xs[i], ys[i])
    seeds = sorted(pick.values(), key=lambda p: -D[p[1], p[0]])
    lean = 0.55
    for sx, sy in seeds:
        if ridge_occ[sy, sx]:
            continue
        line = _stream(np.array([sx, sy], float), tx, ty, M, ridge_occ, rng.uniform(140, 300))
        if line is None or len(line) < 14:
            continue
        line = _smooth_line(line, 3)
        cv2.polylines(ridge_occ, [np.round(line).astype(np.int32)], False, 1, int(sep * 1.4))
        out.append((line.astype(np.float32), 1.5, 0.9, "spine"))
        pts = _resample(line, spacing)
        if len(pts) < 2:
            continue
        tan = np.gradient(pts, axis=0)
        tan /= np.linalg.norm(tan, axis=1, keepdims=True) + 1e-9
        nrm = np.stack([-tan[:, 1], tan[:, 0]], 1)
        n = len(pts)
        for side in (1, -1):
            shadow = side * float(np.dot(nrm.mean(0), -LIGHT)) > 0
            ends = []
            for i in range(n):
                taper = min(1.0, (min(i, n - 1 - i) + 1) / 3.0)        # uçlarda kısa kollar
                d = nrm[i] * side + tan[i] * lean
                d /= np.linalg.norm(d)
                Lmax = sep * 0.52 * taper * rng.uniform(0.75, 1.15)
                spur, L = _walk(pts[i], d, mz, M, Lmax, spur_occ)
                ends.append((spur, L, d))
            for i, (spur, L, d) in enumerate(ends):
                if L < 3:
                    continue
                cv2.polylines(spur_occ, [np.round(spur).astype(np.int32)], False, 1, 2)
                wob = spur.copy()
                bend = np.linspace(0, 1, len(wob)) ** 2 * rng.uniform(-1.2, 1.2)
                wob += np.stack([-d[1], d[0]]) * bend[:, None]
                if shadow and i + 1 < len(ends) and ends[i + 1][1] > 3:
                    nxt = ends[i + 1][0]
                    k = min(len(wob), len(nxt))
                    if k >= 2:
                        a = wob[:k]
                        b = a + (nxt[:k] - a) * rng.uniform(0.5, 0.65)
                        out.append((np.vstack([a, b[::-1]]).astype(np.float32), 0.0, 0.24, "tone"))
                out.append((wob.astype(np.float32), 1.05 if shadow else 0.75, 0.85 if shadow else 0.7, "spur"))
    return out
