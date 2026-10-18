"""Gerçekçi boyanmış dağlar: sırtlı ayrıntı gürültüsü + ışık-gölge.

Orijinal haritanın ve referans harita sürümünün dağları gibi: çok sayıda küçük, keskin
sırtlı tepe, kuzeybatıdan ışık, gölge yüzleri koyu, sırtlar açık. Gürültü
dünya koordinatından üretilir, karo sınırında dikiş olmaz.
"""
import numpy as np
from scipy import ndimage as ndi

N = 8192
_GRIDS = {}


def _grid(cell, seed):
    k = (cell, seed)
    if k not in _GRIDS:
        n = N // cell + 3
        _GRIDS[k] = np.random.default_rng(seed).random((n, n)).astype(np.float32)
    return _GRIDS[k]


def _value(ox, oy, W, H, cell, seed):
    g = _grid(cell, seed)
    yy, xx = np.mgrid[oy:oy + H, ox:ox + W].astype(np.float32)
    gx, gy = np.clip(xx / cell, 0, g.shape[1] - 2), np.clip(yy / cell, 0, g.shape[0] - 2)
    return ndi.map_coordinates(g, [gy, gx], order=3, mode="nearest")


def ridged(ox, oy, W, H, seed=11):
    """Sırtlı (keskin tepeli) çok oktavlı gürültü, 0..1."""
    out = np.zeros((H, W), np.float32)
    amp, tot = 1.0, 0.0
    weight = np.ones((H, W), np.float32)
    for i, cell in enumerate((64, 32, 16, 8, 4)):
        v = _value(ox, oy, W, H, cell, seed + i)
        r = 1.0 - np.abs(v * 2 - 1)
        r = r ** 3
        r *= weight
        weight = np.clip(r * 2.2, 0, 1)
        out += r * amp
        tot += amp
        amp *= 0.5
    return out / tot


def shade(height, mount, water, ox, oy, keep=None):
    """Döner (karanlık, aydınlık) alfaları; dağ dışı sıfır."""
    H, W = height.shape
    mz = ndi.gaussian_filter(np.clip((mount - 0.28) / 0.30, 0, 1), 3)
    r = ridged(ox, oy, W, H)
    # ana kütle + sırtlı ayrıntı; ayrıntı dağ içinde güçlü, etekte zayıf
    z = ndi.gaussian_filter(height, 3) * 0.8 + mz * 70 * r
    z = ndi.gaussian_filter(z, 0.5)
    gy, gx = np.gradient(z)
    # kuzeybatıdan ışık, 40° yükseklik
    lx, ly, lz = -0.62, -0.62, 0.48
    nz = 1.0 / np.sqrt(gx * gx + gy * gy + 1.0)
    lit = (-gx * nz * lx - gy * nz * ly + nz * lz)
    lit = (lit - lz) / (1 - lz)                       # düz zemin 0
    dark = np.clip(-lit * 2.2, 0, 1) ** 0.7
    light = np.clip(lit * 1.6, 0, 1)
    # kıyıya ve suya taşmaz
    wd = ndi.distance_transform_edt(~water)
    edge = np.clip((wd - 3) / 6, 0, 1)
    if keep is not None:
        edge = edge * np.clip(ndi.distance_transform_edt(~keep) / 8.0, 0, 1)
    k = mz * edge
    return dark * k, light * k, mz * edge


_BASE = None


def _base_lum():
    global _BASE
    if _BASE is None:
        import os
        from PIL import Image
        p = os.environ.get("CM_BASEMAP")
        im = np.asarray(Image.open(p).convert("L"), np.float32) / 255
        _BASE = im
    return _BASE


def painted(height, mount, water, ox, oy, keep=None, P=2):
    """Dağların ışık-gölgesi haritanın kendi boyalı dağlarından (base_map), üstüne
    ince sırtlı ayrıntı; dönüş (karanlık, aydınlık, zemin) alfaları."""
    import cv2
    H, W = height.shape
    B = _base_lum()
    n = B.shape[0]
    s = n / (N)                       # harita pikseli -> base pikseli
    x0, y0 = ox * s, oy * s
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    lum = ndi.map_coordinates(B, [y0 + yy * s, x0 + xx * s], order=3, mode="nearest")
    rel = lum / (ndi.gaussian_filter(lum, 36) + 1e-3)
    # ince ayrıntı: aynı ışıkla gölgelenmiş sırtlı gürültü
    r = ridged(ox, oy, W, H, 23)
    gy, gx = np.gradient(r * 14)
    det = (-gx * -0.62 - gy * -0.62)
    det = np.clip(det, -1, 1)
    t = (rel - 1.0) * 3.2 + det * 0.35
    mz = ndi.gaussian_filter(np.clip((mount - 0.28) / 0.30, 0, 1), 3)
    wd = ndi.distance_transform_edt(~water)
    edge = np.clip((wd - 3) / 6, 0, 1)
    if keep is not None:
        edge = edge * np.clip(ndi.distance_transform_edt(~keep) / 10.0, 0, 1)
    k = mz * edge
    dark = np.clip(-t, 0, 1) ** 0.9
    light = np.clip(t, 0, 1)
    return dark * k, light * k, k


def vector_tones(height, mount, water, ox, oy, keep=None):
    """Orijinal haritanın dağları, yerinde, 3 ton katmanına ayrılıp eğri sınırlarla
    büyütülmüş (vektörleştirme ile aynı sonuç: kenarlar her ölçekte keskin)."""
    import cv2
    H, W = height.shape
    B = _base_lum()
    n = B.shape[0]
    # kaynağın gerçek ayrıntısı ~1176 px: önce o ölçekte gürültüsünü al
    src = cv2.bilateralFilter((B * 255).astype(np.uint8), 7, 30, 5).astype(np.float32) / 255
    s = n / N
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    lum = ndi.map_coordinates(src, [oy * s + yy * s, ox * s + xx * s], order=3, mode="nearest")
    lum = ndi.gaussian_filter(lum, 2.2)          # yumuşak alan -> eşikte pürüzsüz eğri
    rel = lum / (ndi.gaussian_filter(lum, 40) + 1e-3)
    mz = ndi.gaussian_filter(np.clip((mount - 0.28) / 0.30, 0, 1), 3)
    wd = ndi.distance_transform_edt(~water)
    k = mz * np.clip((wd - 3) / 6, 0, 1)
    if keep is not None:
        k = k * np.clip(ndi.distance_transform_edt(~keep) / 10.0, 0, 1)
    aa = lambda v, t: np.clip((v - t) / 0.012 + 0.5, 0, 1)      # kenar yumuşatma (1-2 px)
    dark = aa(-rel, -0.90)            # rel < 0.90
    mid = aa(-rel, -0.97) * (1 - dark)
    light = aa(rel, 1.06)
    # gölge şekillerinin kenarı: ince mürekkep
    e = np.abs(np.gradient(dark)[0]) + np.abs(np.gradient(dark)[1])
    edge = np.clip(e * 1.4, 0, 1)
    return dark * k, mid * k, light * k, edge * k, k


_DEM = None


def _dem():
    global _DEM
    if _DEM is None:
        import os
        _DEM = np.load(os.environ["CM_DEM"], mmap_mode="r")
    return _DEM


def dem_shade(mount, water, ox, oy, W, H, keep=None):
    """Gerçek yükseklik dokusunun ışık-gölgesi: (gölge, ışık, kar) alfaları."""
    D = _dem()
    R = np.zeros((H, W), np.float32)
    ya, yb, xa, xb = max(0, oy), min(N, oy + H), max(0, ox), min(N, ox + W)
    if ya < yb and xa < xb:
        R[ya - oy:yb - oy, xa - ox:xb - ox] = D[ya:yb, xa:xb]
    mz = ndi.gaussian_filter(np.clip((mount - 0.26) / 0.30, 0, 1), 4)
    wd = ndi.distance_transform_edt(~water)
    k = mz * np.clip((wd - 2) / 14, 0, 1)
    if keep is not None:
        kf = ndi.gaussian_filter(keep.astype(np.float32), 10)          # yuvarlak, yumuşak kesik
        k = k * np.clip(1 - kf * 2.2, 0, 1)
    k = k * k * (3 - 2 * k)
    near = np.clip((wd - 4) / 45, 0, 1)                                 # kıyıya yakın dağ alçalır
    z = (R * 9.0 + 14.0) * k * (0.35 + 0.65 * near)
    gy, gx = np.gradient(z)
    lx, ly, lz = -0.62, -0.62, 0.48
    nz = 1.0 / np.sqrt(gx * gx + gy * gy + 1.0)
    lit = (-gx * nz * lx - gy * nz * ly + nz * lz)
    lit = (lit - lz) / (1 - lz)
    dark = np.clip(-lit * 1.35 - 0.06, 0, 1) ** 0.85
    light = np.clip(lit * 1.3, 0, 1)
    # kar: kuzeyde sırtların yüksek kısmı
    yy = np.arange(oy, oy + H, dtype=np.float32)[:, None]
    north = np.clip((3000 - yy) / 900.0, 0, 1)
    snow = np.clip((R - (1.6 - 1.0 * north)) / 0.5, 0, 1) * north * k
    elev = np.clip(z, 0, None) * 0.55
    return dark * k, light * k, snow, elev


def oblique(layers, elev):
    """Eğik (hafif yandan, hafif yukarıdan) izdüşüm: her nokta yüksekliği kadar
    yukarı kalkar, öndeki (güneydeki) sırt arkadakini örter. layers: aynı boyutlu
    alfa dizileri; dönüş: izdüşmüş katmanlar + silüet çizgisi."""
    H, W = elev.shape
    out = [np.zeros((H, W), np.float32) for _ in layers]
    src_row = np.full((H, W), -1.0, np.float32)
    horizon = np.full(W, H, np.float32)             # bu sütunda şimdiye kadar boyanan en üst ekran satırı
    cols = np.arange(W)
    for y in range(H - 1, -1, -1):                  # önden arkaya
        top = y - elev[y]
        lo = np.clip(np.ceil(top), 0, H).astype(np.int32)
        hi = np.minimum(horizon, H).astype(np.int32)
        m = lo < hi
        if not m.any():
            continue
        # [lo, hi) aralığını bu satırın değeriyle doldur (en çok birkaç piksel)
        span = int((hi - lo)[m].max())
        for k in range(span):
            rr = lo + k
            mm = m & (rr < hi)
            if not mm.any():
                break
            r, c = rr[mm], cols[mm]
            for o, L in zip(out, layers):
                o[r, c] = L[y, c]
            src_row[r, c] = y
        horizon = np.where(m, lo, horizon).astype(np.float32)
    # silüet: ekranda bir sonraki pikselin kaynağı çok daha arkadan geliyorsa (sırt kenarı)
    d = np.zeros((H, W), np.float32)
    d[:-1] = src_row[1:] - src_row[:-1]
    edge = np.clip((d - 3) / 6, 0, 1)
    return out, edge
