"""referans harita haritasının dağ dili, mürekkeple: yukarıdan bakılmış kaya alanı.

referans haritada dağ, kaya renginde bir alan, içinde koyu, kırık vadi çizgileri ve
gölge yamaçta düz bir koyu ton. Burada aynı veriden (yükseklik alanının
Hessian'ı) üç mürekkep katmanı çıkar:
  * vadi çizgileri: sırt arasındaki çatlaklar, uçları incelen kalem izi;
  * gölge yamaç: kuzeybatıdan ışık, güneydoğuya bakan yamaçta sık, kısa,
    eğime paralel taramalar (düz bir ton gibi okunur, kabartma değil);
  * kaya sınırı: dağ alanının eteği, kesik kesik ince kontur.
Hiçbir çizgi suya, kıyıya 5 px'ten yakına ya da kent/yazı alanına girmez.
"""
import math

import numpy as np
from scipy import ndimage as ndi


def _hessian(h, s):
    hxx = ndi.gaussian_filter(h, s, order=(0, 2))
    hyy = ndi.gaussian_filter(h, s, order=(2, 0))
    hxy = ndi.gaussian_filter(h, s, order=(1, 1))
    tr = (hxx + hyy) / 2
    dt = np.sqrt(((hxx - hyy) / 2) ** 2 + hxy ** 2)
    lam1 = tr + dt                       # vadi (içbükey) > 0
    # lam1'in özvektörü: çizginin normali
    nx = hxy
    ny = lam1 - hxx
    bad = (np.abs(nx) + np.abs(ny)) < 1e-9
    nx = np.where(bad, 1.0, nx)
    ny = np.where(bad, 0.0, ny)
    n = np.hypot(nx, ny)
    return lam1, nx / n, ny / n


def _nms(c, nx, ny):
    """Çizgiye dik yönde yerel tepe olmayanı sil: tek piksellik çizgi kalır."""
    H, W = c.shape
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    a = ndi.map_coordinates(c, [yy + ny, xx + nx], order=1, mode="nearest")
    b = ndi.map_coordinates(c, [yy - ny, xx - nx], order=1, mode="nearest")
    return (c >= a) & (c >= b)


def _trace(strength, thin, nx, ny, allow, minlen, rng, max_lines=10**6):
    H, W = strength.shape
    used = np.zeros_like(thin)
    ys, xs = np.nonzero(thin & allow)
    order = np.argsort(-strength[ys, xs])
    lines = []
    for i in order:
        y0, x0 = ys[i], xs[i]
        if used[y0, x0]:
            continue
        pts = []
        for sgn in (1, -1):
            x, y = float(x0), float(y0)
            tx, ty = -ny[y0, x0] * sgn, nx[y0, x0] * sgn
            seg = []
            for _ in range(400):
                xi, yi = int(round(x)), int(round(y))
                if not (0 <= xi < W and 0 <= yi < H):
                    break
                # yakındaki ince çizgi pikseline otur
                best = None
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        X, Y = xi + dx, yi + dy
                        if 0 <= X < W and 0 <= Y < H and thin[Y, X] and allow[Y, X] and not (used[Y, X] and seg):
                            s = strength[Y, X]
                            if best is None or s > best[0]:
                                best = (s, X, Y)
                if best is None:
                    break
                _, X, Y = best
                used[max(0, Y - 1):Y + 2, max(0, X - 1):X + 2] = True
                seg.append((X + 0.5, Y + 0.5, strength[Y, X]))
                ntx, nty = -ny[Y, X], nx[Y, X]
                if ntx * tx + nty * ty < 0:
                    ntx, nty = -ntx, -nty
                tx, ty = 0.6 * tx + 0.4 * ntx, 0.6 * ty + 0.4 * nty
                m = math.hypot(tx, ty) + 1e-9
                tx, ty = tx / m, ty / m
                x, y = X + 0.5 + tx * 1.6, Y + 0.5 + ty * 1.6
            if sgn == 1:
                pts = seg[::-1]
            else:
                pts = pts + seg[1:]
        if len(pts) >= minlen:
            lines.append(np.array(pts, np.float32))
        if len(lines) >= max_lines:
            break
    return lines


def build(height, mount, water, keep, roads, rng, P=2, snow_y=None, qc=None, qr=None, gq=1.0):
    """Alanlar harita pikselinde (P ile büyütülmüş). Döner: çizgi listesi
    [(noktalar Nx2, genişlik, alfa, tür)]."""
    h = ndi.gaussian_filter(height.astype(np.float32), 1.2)
    wdist = ndi.distance_transform_edt(~water)
    land_ok = (wdist > 6) & ~keep
    road_ok = ~ndi.binary_dilation(roads, iterations=3)
    mz = np.clip((mount - 0.30) / 0.30, 0, 1)
    mz = ndi.gaussian_filter(mz, 3)
    allow = land_ok & road_ok & (mz > 0.12)

    out = []
    # --- vadi çizgileri (referans haritanın koyu kırık hatları)
    import cv2

    def angular(ln, eps):
        p = ln[:, :2].reshape(-1, 1, 2).astype(np.float32)
        return cv2.approxPolyDP(p, eps, False)[:, 0, :].astype(np.float32)

    lam, nx, ny = _hessian(h, 3.0)
    q = 0.8 * qc if qc is not None else (np.quantile(lam[mz > 0.5], 0.80) if (mz > 0.5).any() else 1.0)
    c = np.clip((lam / (q + 1e-9) - 1.0) * 1.6, 0, 1) * mz
    thin = _nms(c, nx, ny) & (c > 0.24)
    for ln in _trace(c, thin, nx, ny, allow, 7, rng):
        s = float(np.mean(ln[:, 2]))
        pts = angular(ln, 1.4)
        if len(pts) < 2:
            continue
        out.append((pts, 0.8 + 1.6 * s, 0.6 + 0.35 * s, "crease"))

    # --- sırt çizgileri: ince omurga
    lam2, nx2, ny2 = _hessian(-h, 3.4)
    q2 = qr if qr is not None else (np.quantile(lam2[mz > 0.5], 0.85) if (mz > 0.5).any() else 1.0)
    c2 = np.clip((lam2 / (q2 + 1e-9) - 1.0) * 1.4, 0, 1) * mz
    thin2 = _nms(c2, nx2, ny2) & (c2 > 0.35)
    for ln in _trace(c2, thin2, nx2, ny2, allow, 10, rng):
        s = float(np.mean(ln[:, 2]))
        pts = angular(ln, 1.2)
        if len(pts) < 2:
            continue
        out.append((pts, 0.45 + 0.5 * s, 0.4 + 0.3 * s, "ridge"))

    # --- kar: kuzeyde yüksek yerler beyaz alan, alt kenarı tırtıklı ince çizgi
    if snow_y is not None and (mz > 0.5).any():
        Hh, Ww = h.shape
        north = np.clip((snow_y - np.arange(Hh)[:, None]) / 600.0, 0, 1) * np.ones((1, Ww))
        hs = ndi.gaussian_filter(h, 2.0)
        thr = np.quantile(hs[mz > 0.5], 0.80) - (np.quantile(hs[mz > 0.5], 0.80) - np.quantile(hs[mz > 0.5], 0.45)) * north
        cap = (hs > thr) & (north > 0.05) & (mz > 0.45) & allow
        cap = ndi.binary_opening(cap, iterations=2)
        cs, _ = cv2.findContours(cap.astype(np.uint8), cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
        for cnt in cs:
            if len(cnt) < 24:
                continue
            pts = cv2.approxPolyDP(cnt.astype(np.float32), 1.3, True)[:, 0, :].astype(np.float32)
            if len(pts) < 4:
                continue
            out.append((pts, 0.0, 0.92, "snowfill"))
            out.append((np.vstack([pts, pts[:1]]), 0.5, 0.55, "snowedge"))

    # --- gölge yamaç taraması: sırtın güneydoğu yanından yokuş aşağı
    gy, gx = np.gradient(ndi.gaussian_filter(h, 3.0))
    gn = np.hypot(gx, gy) + 1e-9
    face = (gx * 0.7 + gy * 0.7) / gn          # >0: aşağı yön kuzeybatıya → yamaç güneydoğuya bakar değil
    slope = np.clip(gn / gq, 0, 1)
    shade = (face < -0.15) & (slope > 0.25) & allow & (mz > 0.25)
    ys, xs = np.nonzero(shade)
    grid = {}
    for i in rng.permutation(len(xs)):
        x, y = xs[i], ys[i]
        g = (x // 3, y // 3)
        if g in grid:
            continue
        grid[g] = 1
        dx, dy = -gx[y, x] / gn[y, x], -gy[y, x] / gn[y, x]   # yokuş aşağı
        L = 3 + 6 * slope[y, x] * mz[y, x]
        p = np.array([[x, y], [x + dx * L, y + dy * L]], np.float32)
        out.append((p, 0.45 + 0.35 * slope[y, x], 0.35 + 0.35 * mz[y, x], "hatch"))

    return out


def road_lines(roads, water, rng):
    s = ndi.gaussian_filter(roads.astype(np.float32), 1.6)
    lam, nx, ny = _hessian(-s, 1.6)
    c = np.clip(s * 2.0, 0, 1)
    thin = _nms(c, nx, ny) & (c > 0.35)
    allow = ~ndi.binary_dilation(water, iterations=1)
    return [ln[::3, :2].copy() for ln in _trace(c, thin, nx, ny, allow, 6, rng)]
