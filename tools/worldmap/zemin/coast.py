"""Kıyı: doğrudan haritanın renginden (mavi/kırmızı oranı, iki tepeli -
kara ~0.58, su ~0.85; eşik 0.70). Kenardaki kâğıt payı (ne deniz ne kara)
en yakın iç sınıfla devam ettirilir; pusula suya sayılır."""
import os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

THRESH = 0.70
MARGIN = 60           # 4096 ölçeğinde koyu çerçeve çizgisi (doldurulur)
BURN = 220            # yanık kenar bandı
COMPASS = (520, 3520, 470)
MIN_LAKE = 900
RIVER_R = 9          # 4096 px; bundan dar su kolu nehirdir (ayrı çizilir)        # 4096² px; daha küçük mavi lekeler boyalı nehir/yol


def water_mask(root, n=4096):
    base = Image.open(os.path.join(root, "images", "base_map_4096.jpg")).convert("RGB")
    if n != 4096:
        base = base.resize((n, n), Image.LANCZOS)
    b = np.asarray(base, np.float32) / 255
    k = n / 4096
    q = ndi.gaussian_filter(b[..., 2] / (b[..., 0] + 1e-3), 3 * k)
    yy, xx = np.mgrid[0:n, 0:n]
    ed = np.minimum(np.minimum(xx, yy), np.minimum(n - 1 - xx, n - 1 - yy))
    # Yanık kenar oranı kenara yaklaştıkça bastırıyor (ölçüldü: kenardan
    # ~200 px içeride deniz 0.85 -> 0.60, kara ~0.45'te kalıyor): eşik de
    # aynı bantta 0.70'ten 0.55'e iniyor.
    thr = THRESH - 0.20 * np.clip((BURN - ed / k) / (BURN - MARGIN), 0, 1)
    w = q > thr
    cx, cy, cr = (c * k for c in COMPASS)
    w |= np.hypot(xx - cx, yy - cy) < cr
    w = ndi.binary_closing(w, iterations=max(1, int(3 * k)))
    # ince boyalı nehirler su kütlesi değil: dar kollar açılmayla düşer
    disk = np.hypot(*np.mgrid[-RIVER_R:RIVER_R + 1, -RIVER_R:RIVER_R + 1]) <= RIVER_R
    rk = max(1, int(round(RIVER_R * k)))
    disk = np.hypot(*np.mgrid[-rk:rk + 1, -rk:rk + 1]) <= rk
    w = ndi.binary_opening(w, structure=disk)
    lab, nl = ndi.label(w)
    if nl:
        size = ndi.sum(w, lab, index=np.arange(1, nl + 1))
        keep = np.concatenate([[False], size > MIN_LAKE * k * k])
        w = keep[lab]
    # adacık: küçük kara lekeleri (suyun içinde) koru - yalnızca gürültüyü sil
    land = ~w
    lab, nl = ndi.label(land)
    if nl:
        size = ndi.sum(land, lab, index=np.arange(1, nl + 1))
        keep = np.concatenate([[False], size > 60 * k * k])
        w = ~keep[lab]
    # kenar payı: iç sınıfı dışarı uzat
    B = int(MARGIN * k)
    # geniş ölçekte yumuşatılmış iç sınıf: kenara değen küçük ada/koy
    # payın içine çubuk olarak uzamasın
    # pay, iç bölgeden normalize bulanıklıkla doldurulur (çubuk bırakmaz)
    edge = ed < B
    inside = (~edge).astype(np.float32)
    num = ndi.gaussian_filter(w.astype(np.float32) * inside, B * 0.7)
    den = ndi.gaussian_filter(inside, B * 0.7)
    fill = num / np.maximum(den, 1e-4) > 0.5
    w = np.where(edge, fill, w)
    return w


def relief(root, n=4096):
    """Haritanın çizili dağ kuşakları: tarama dokusunun yerel kontrastı.
    Dağ maskesi kaba elipsler; bu, kaynak haritadaki gerçek sıradağları izler.
    0..1, suda 0. Orman elipslerinin ağaç dokusu orman maskesiyle düşülür."""
    g = Image.open(os.path.join(root, "images", "base_map_4096.jpg")).convert("L").resize((1024, 1024), Image.LANCZOS)
    b = np.asarray(g, np.float32) / 255
    e = ndi.gaussian_filter(np.abs(b - ndi.gaussian_filter(b, 1.5)), 6)
    w = water_mask(root, 1024)
    e[w] = 0
    lo, hi = np.quantile(e[~w], [0.5, 0.9])
    r = np.clip((e - lo) / (hi - lo), 0, 1)
    f = np.asarray(Image.open(os.path.join(root, "images", "mask_forest.png")).convert("L").resize((1024, 1024)), np.float32) / 255
    r = r * (1 - ndi.gaussian_filter(f, 4))
    r = np.asarray(Image.fromarray(r).resize((n, n), Image.BILINEAR), np.float32)
    return r
