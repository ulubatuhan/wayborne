"""Wayborne zemini - referans oyunun dünya haritasının dilinde,
prosedürel (üretici model yok, ücretsiz).

referans harita haritasından okunan dil:
  * orman = sık, mürekkep konturlu, yuvarlak ağaç tacı damgaları; koyu zeytin,
    sol üstte açık, sağ altta gölge; taçlar y sırasıyla üst üste biniyor;
  * açık alan = sarı-zeytin çayır, üstünde kısa eğim taramaları, tek tük ağaç,
    yerleşimlerin çevresinde dar uzun tarla şeritleri (saman/yeşil);
  * su = kurşuni mavi, kıyıya paralel koyu dalga taramaları, mürekkep kıyı;
  * eski kâğıt: kenarlara doğru kararan, lekeli.
Bizim coğrafyamız referans haritadan dağlık: dağ kuşakları iğne yapraklı orman + açık
kaya sırtı (zeminin kendi sırt ayrıntısı korunuyor - hizalamayı da o taşıyor).

Coğrafya maskelerden ve zemin_paint.py'nin su sınıflamasından; yerleşim,
yazı, ikon, yol, çerçeve YOK (ikisi katman).

    python3 -I zemin_render.py <kök> <tohum> <çıktı.png> [boy]
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
import zemin_paint  # noqa: E402
import coast as coastline  # noqa: E402

STEPPE_LO = np.array([0.66, 0.62, 0.46])   # kuzeybatı: göçebe bozkırı, kuru ot
STEPPE_HI = np.array([0.76, 0.71, 0.55])
TUNDRA = np.array([0.60, 0.61, 0.50])      # gri-yeşil yosunlu yamalar
NOMAD_KINDS = ("in_yurtcamp", "in_khantent", "iny_0", "iny_2", "iny_3", "iny_4")
MEADOW_LO = np.array([0.56, 0.54, 0.32])
MEADOW_HI = np.array([0.70, 0.65, 0.40])
FIELD_A = np.array([0.82, 0.73, 0.48])
FIELD_B = np.array([0.62, 0.60, 0.35])
FIELD_C = np.array([0.76, 0.64, 0.42])
CROWN = np.array([0.44, 0.43, 0.23])
CONIFER = np.array([0.30, 0.33, 0.18])
ROCK = np.array([0.72, 0.63, 0.50])
FOREST_FLOOR = np.array([0.19, 0.18, 0.09])
WATER = np.array([0.42, 0.47, 0.54])
WATER_EDGE = np.array([0.52, 0.58, 0.62])
INK = np.array([0.14, 0.11, 0.07])
FOREST_SHARE = 0.48
EDGE_INSET = 110  # 4096 ölçeğinde  # referans harita: haritanın yarıdan fazlası orman


def crown_sprite(r, rng, kind):
    """referans harita ağacı: yandan-üstten görülen karnabahar taç (3-5 yuvarlak lob),
    kalın mürekkep kontur, üstte ışık, altta kısa gövde; RGBA (0..1)."""
    s = int(r * 2.6 + 8)
    yy, xx = np.mgrid[0:s, 0:s].astype(np.float32)
    cx, cy = s / 2, s / 2 - r * 0.15
    lobes = []
    if kind == "conifer":
        # sivri, üç katlı köknar silueti
        tip = (cx, cy - r * 1.05)
        dist = np.full((s, s), 1e9, np.float32)
        for k in range(3):
            wy = cy - r * 0.55 + k * r * 0.48
            half = r * (0.42 + 0.22 * k)
            yk = (yy - (wy - r * 0.45)) / (r * 0.9)
            inside_k = (yk >= 0) & (yk <= 1) & (np.abs(xx - cx) <= half * yk + 0.3)
            dist = np.where(inside_k, -1.0, dist)
        inside = (dist < 0).astype(np.float32)
        inside = ndi.gaussian_filter(inside, 0.6)
        inside = np.clip((inside - 0.3) * 3, 0, 1)
    else:
        n_l = rng.integers(3, 6)
        field = np.full((s, s), -1e9, np.float32)
        for k in range(n_l):
            a = -np.pi / 2 + (k - (n_l - 1) / 2) * 0.9 + (rng.random() - 0.5) * 0.4
            rr = r * (0.48 + 0.14 * rng.random())
            ox = cx + np.cos(a) * r * 0.42
            oy = cy + np.sin(a) * r * 0.30 + r * 0.12
            lobes.append((ox, oy, rr))
            field = np.maximum(field, rr - np.hypot(xx - ox, yy - oy))
        # gövdeyi dolduran merkez
        field = np.maximum(field, r * 0.62 - np.hypot(xx - cx, (yy - cy - r * 0.15) * 1.15))
        inside = np.clip(field + 0.5, 0, 1)
    outline = np.clip(ndi.maximum_filter(inside, size=3) - inside, 0, 1)
    outline = np.maximum(outline, np.clip(1 - np.abs(inside - 0.5) * 2, 0, 1))
    # iç lob çizgileri: lobların alt kenarları koyu kavis
    inner = np.zeros((s, s), np.float32)
    for (ox, oy, rr) in lobes[1:]:
        d = np.hypot(xx - ox, yy - oy)
        arc = np.clip(1 - np.abs(d - rr) / 0.9, 0, 1) * (yy > oy - rr * 0.1) * (inside > 0.5)
        inner = np.maximum(inner, arc * 0.7)
    lx = (xx - cx) / r
    ly = (yy - cy) / r
    light = np.clip(0.6 - 0.35 * lx - 0.75 * ly, 0, 1)
    base = CONIFER if kind == "conifer" else CROWN
    tint = 0.88 + 0.24 * rng.random()
    col = base * tint * (0.62 + 0.75 * light[..., None])
    tex = ndi.gaussian_filter(rng.random((s, s)).astype(np.float32), 0.9)
    col = col * (0.9 + 0.2 * (tex[..., None] - 0.5) * 2)
    ink = np.maximum(outline, inner)
    col = col * (1 - ink[..., None]) + INK * ink[..., None]
    a = np.maximum(inside, outline)
    # gövde: tacın altında kısa koyu çizgi
    trunk = (np.abs(xx - cx) < max(0.8, r * 0.07)) & (yy > cy + r * 0.55) & (yy < cy + r * 0.95) & (a < 0.5)
    col[trunk] = INK
    a = np.where(trunk, 1.0, a)
    # sağ alta düşen yumuşak gölge (yalnız saydam bölgede)
    sh = ndi.shift(inside, (r * 0.22, r * 0.28), order=1)
    sh = ndi.gaussian_filter(sh, r * 0.12) * 0.45
    col = np.where((a < 0.05)[..., None], INK * 0.6, col)
    a = np.maximum(a, sh * (a < 0.05))
    return np.dstack([np.clip(col, 0, 1), a]).astype(np.float32)

def sprite_bank(rng, rad, kind, n=24):
    return [crown_sprite(rad * (0.8 + 0.45 * rng.random()), rng, kind) for _ in range(n)]


def blit(dst, spr, x, y):
    h, w = spr.shape[:2]
    x0, y0 = int(x - w / 2), int(y - h / 2)
    H, W = dst.shape[:2]
    sx0, sy0 = max(0, -x0), max(0, -y0)
    x1, y1 = min(W, x0 + w), min(H, y0 + h)
    if x1 <= max(0, x0) or y1 <= max(0, y0):
        return
    sub = spr[sy0:sy0 + (y1 - max(0, y0)), sx0:sx0 + (x1 - max(0, x0))]
    reg = dst[max(0, y0):y1, max(0, x0):x1]
    a = sub[..., 3:4]
    reg[..., :3] = reg[..., :3] * (1 - a) + sub[..., :3] * a


def jitter_points(n, spacing, rng):
    g = np.arange(spacing / 2, n, spacing)
    xs, ys = np.meshgrid(g, g)
    xs = xs + (rng.random(xs.shape) - 0.5) * spacing * 0.9
    ys = ys + (rng.random(ys.shape) - 0.5) * spacing * 0.9
    # alternatif satırlar kaydırılmış: ızgara okunmasın
    xs[1::2] += spacing / 2
    return xs.ravel(), ys.ravel()


def stamp_canopy(img, mask, spacing, bank, rng, density):
    n = img.shape[0]
    xs, ys = jitter_points(n, spacing, rng)
    ok = (xs >= 0) & (ys >= 0) & (xs < n) & (ys < n)
    xs, ys = xs[ok], ys[ok]
    m = mask[ys.astype(int), xs.astype(int)]
    keep = rng.random(len(xs)) < m * density
    xs, ys = xs[keep], ys[keep]
    order = np.argsort(ys)
    for i in order:
        blit(img, bank[rng.integers(len(bank))], xs[i], ys[i])
    return len(order)


def strokes(n, rng, count, mask, angle_field, length, width, color, alpha):
    """Kısa mürekkep taramaları (eğim, çayır)."""
    im = Image.new("L", (n, n), 0)
    dr = ImageDraw.Draw(im)
    xs = rng.random(count) * n
    ys = rng.random(count) * n
    m = mask[ys.astype(int), xs.astype(int)]
    keep = rng.random(count) < m
    for x, y in zip(xs[keep], ys[keep]):
        a = angle_field[int(y), int(x)] + (rng.random() - 0.5) * 0.4
        L = length * (0.6 + 0.8 * rng.random())
        dx, dy = np.cos(a) * L / 2, np.sin(a) * L / 2
        # hafif kavisli: üç noktalı
        bx, by = -dy * 0.15, dx * 0.15
        dr.line([(x - dx, y - dy), (x + bx, y + by), (x + dx, y + dy)], fill=255, width=width)
    a = np.asarray(im, np.float32) / 255 * alpha
    return a


def field_patches(n, rng, sites, allowed, scale):
    """Yerleşim çevresinde şeritli tarla parçaları. Döner: renk, alfa, kontur."""
    col = np.zeros((n, n, 3), np.float32)
    alpha = Image.new("L", (n, n), 0)
    ink = Image.new("L", (n, n), 0)
    rgb = Image.new("RGB", (n, n), 0)
    da, di, dc = ImageDraw.Draw(alpha), ImageDraw.Draw(ink), ImageDraw.Draw(rgb)
    pal = [FIELD_A, FIELD_B, FIELD_C, MEADOW_HI]
    for (sx, sy, weight) in sites:
        count = int(2 + weight * 5)
        base_ang = rng.random() * np.pi
        for _ in range(count):
            r = (60 + rng.random() * 170 * (0.6 + weight)) * scale
            ang0 = rng.random() * 2 * np.pi
            cx, cy = sx + np.cos(ang0) * r, sy + np.sin(ang0) * r
            if not (0 <= cx < n and 0 <= cy < n) or allowed[int(cy), int(cx)] < 0.6:
                continue
            ang = base_ang + (rng.random() - 0.5) * 0.7
            L = (60 + rng.random() * 110) * scale
            strips = rng.integers(3, 8)
            sw = (9 + rng.random() * 9) * scale
            u = np.array([np.cos(ang), np.sin(ang)])
            v = np.array([-u[1], u[0]])
            for k in range(strips):
                off = (k - strips / 2) * sw
                c0 = np.array([cx, cy]) + v * off
                lk = L * (0.75 + 0.35 * rng.random())
                p = [c0 - u * lk / 2, c0 + u * lk / 2, c0 + u * lk / 2 + v * sw, c0 - u * lk / 2 + v * sw]
                pts = [tuple(q) for q in p]
                c = pal[rng.integers(len(pal))] * (0.92 + 0.16 * rng.random())
                dc.polygon(pts, fill=tuple(int(t * 255) for t in c))
                da.polygon(pts, fill=255)
                di.line(pts + [pts[0]], fill=255, width=max(1, int(1.6 * scale)))
                # sürüm çizgileri
                for j in range(1, 4):
                    q0 = c0 + v * sw * j / 4 - u * lk / 2
                    q1 = q0 + u * lk
                    di.line([tuple(q0), tuple(q1)], fill=90, width=1)
    col = np.asarray(rgb, np.float32) / 255
    a = np.asarray(alpha, np.float32) / 255
    i = np.asarray(ink, np.float32) / 255
    return col, a * allowed, i * allowed


def wave_hatch(n, rng, water, dist, scale):
    """referans harita suyu: kıyıya paralel kesik dalga çizgileri + yatay kısa dalgalar."""
    im = Image.new("L", (n, n), 0)
    dr = ImageDraw.Draw(im)
    count = int(n * n / (900 * scale * scale))
    xs = rng.random(count) * n
    ys = rng.random(count) * n
    w = water[ys.astype(int), xs.astype(int)] > 0.5
    for x, y in zip(xs[w], ys[w]):
        L = (10 + rng.random() * 18) * scale
        pts = [(x + t, y + np.sin(t / (3.5 * scale)) * 1.6 * scale) for t in np.linspace(-L / 2, L / 2, 6)]
        dr.line(pts, fill=255, width=1)
    a = np.asarray(im, np.float32) / 255
    rings = np.zeros_like(dist)
    for d0, k in ((10, 0.55), (22, 0.40), (38, 0.28), (60, 0.18)):
        d0 *= scale
        wob = np.sin(np.arange(n)[None, :] / (13 * scale)) * 1.5 * scale
        rings = np.maximum(rings, np.exp(-((dist - d0 + wob) / (1.0 * scale)) ** 2) * k)
    return np.maximum(a * 0.55, rings) * (water > 0.5)


def grass_ticks(n, rng, count, mask, scale):
    """referans harita çayırı: küçük yatay çim kavisleri (‿) ve tek tük kısa çizgi."""
    im = Image.new("L", (n, n), 0)
    dr = ImageDraw.Draw(im)
    xs = rng.random(count) * n
    ys = rng.random(count) * n
    keep = rng.random(count) < mask[ys.astype(int), xs.astype(int)]
    for x, y in zip(xs[keep], ys[keep]):
        w = (5 + rng.random() * 6) * scale
        dr.arc([x - w, y - w * 0.45, x + w, y + w * 0.45], 20, 160, fill=255, width=max(1, int(1.2 * scale)))
    return np.asarray(im, np.float32) / 255


def warp_sample(a, n, seed, amp):
    """Maskeyi gürültüyle bük: elle çizilmiş elipsler organik kenar kazansın."""
    fx = (zemin_paint.fbm(n, seed, 6, 4) - 0.5) * 2 * amp
    fy = (zemin_paint.fbm(n, seed + 1, 6, 4) - 0.5) * 2 * amp
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    return ndi.map_coordinates(a, [np.clip(yy + fy, 0, n - 1), np.clip(xx + fx, 0, n - 1)], order=1)


def mountain_hachure(n, rng, H, hs, mount, scale):
    """Kontur çizgileri + yokuş aşağı kısa taramalar; gölge yüzünde sık."""
    import cv2
    im = Image.new("L", (n, n), 0)
    dr = ImageDraw.Draw(im)
    gy, gx = np.gradient(H)
    w = max(1, int(1.3 * scale))
    for lev in (0.35, 0.55, 0.75, 0.95, 1.15):
        b = (H > lev).astype(np.uint8)
        cs, _ = cv2.findContours(b, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
        for c in cs:
            if len(c) < 40 * scale:
                continue
            pts = c[:, 0, :].astype(np.float32)
            step = max(1, int(5 * scale))
            pts = pts[::step]
            # kontur: kesik kesik (oyma), yarısı çizilir
            seg = rng.integers(3, 9)
            for i in range(0, len(pts) - 1, seg * 2):
                q = [tuple(p) for p in pts[i:i + seg + 1]]
                if len(q) > 1:
                    dr.line(q, fill=150, width=w)
            for p in pts[::2]:
                x, y = int(p[0]), int(p[1])
                if not (0 <= x < n and 0 <= y < n):
                    continue
                g = np.array([gx[y, x], gy[y, x]])
                gn = np.linalg.norm(g)
                if gn < 1e-6:
                    continue
                d = -g / gn  # yokuş aşağı
                shade_side = hs[y, x] < 0
                if not shade_side and rng.random() < 0.6:
                    continue
                L = (5 + rng.random() * 9) * scale * (1.3 if shade_side else 0.8)
                q = p + d * L
                dr.line([tuple(p), tuple(q)], fill=255 if shade_side else 170, width=w)
    a = np.asarray(im, np.float32) / 255
    return a * np.clip(mount * 2, 0, 1)


def render(root, seed, size=4096):
    rng = np.random.default_rng(seed)
    scale = size / 4096
    base = Image.open(os.path.join(root, "images", "base_map_4096.jpg")).convert("RGB")
    n = size
    if size != 4096:
        base = base.resize((n, n), Image.LANCZOS)
    # kıyı doğrudan haritanın renginden (coast.py) - kara sınırının tek kaynağı
    water = coastline.water_mask(root, n).astype(np.float32)
    base = np.asarray(base, np.float32) / 255
    lum = base @ np.array([0.299, 0.587, 0.114], np.float32)
    m_mount = zemin_paint.load(root, "mask_mountain.png", n)
    m_forest = zemin_paint.load(root, "mask_forest.png", n)
    water = np.clip(water, 0, 1)
    wb = water > 0.5
    land = 1 - zemin_paint.smooth(water, 1.0 * scale)

    world = json.load(open(os.path.join(root, "data", "world.json")))
    wt = {"ic_city": 1.0, "ic_freecity": 1.0, "ic_portcity": 0.9, "it_town": 0.7,
          "it_markettown": 0.8, "it_rivertown": 0.7, "it_minetown": 0.4, "it_swamptown": 0.3,
          "iv_farm": 0.5, "iv_fishvillage": 0.3, "ih_mezra": 0.35, "ia_abbey": 0.45, "il_lumber": 0.15}
    sites = [(x * scale, y * scale, wt.get(s, 0.12)) for s, x, y in world["syms"]]
    # yerleşim açıklığı: her yerin çevresinde, ağırlığıyla büyüyen bir çayır
    clear = np.zeros((n, n), np.float32)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    for (sx, sy, w) in sites:
        if w < 0.3:
            continue
        R = (50 + 190 * w) * scale
        x0, x1 = int(max(0, sx - R * 1.5)), int(min(n, sx + R * 1.5))
        y0, y1 = int(max(0, sy - R * 1.5)), int(min(n, sy + R * 1.5))
        d = np.hypot(xx[y0:y1, x0:x1] - sx, yy[y0:y1, x0:x1] - sy) / R
        clear[y0:y1, x0:x1] = np.maximum(clear[y0:y1, x0:x1], np.clip(1.3 - d, 0, 1))
    clear = warp_sample(clear, n, seed + 50, 140 * scale)
    clear = clear * np.clip(0.6 + (zemin_paint.fbm(n, seed + 51, 20, 3) - 0.5) * 2.5, 0, 1)
    # yerleşim planının ayak izi (zemin_settlements plan): ev, parsel, sur,
    # iskele - orman, tarla ve tek ağaç buradan çekilir
    foot = np.zeros((n, n), np.float32)
    fp = os.environ.get("ZEMIN_LAYOUT", os.path.join(root, "out", "layout.json")) + ".foot.npy"
    if os.path.exists(fp):
        f4 = np.unpackbits(np.load(fp))[:4096 * 4096].reshape(4096, 4096).astype(np.float32)
        foot = np.asarray(Image.fromarray(f4).resize((n, n), Image.BILINEAR), np.float32)
        foot = zemin_paint.smooth(foot, 3 * scale)
    # yollar (araziye göre yönlendirilmiş, zemin_roads): ormanda koridor açılır
    roadm = np.zeros((n, n), np.float32)
    wk = os.environ.get("ZEMIN_WORLD", os.path.join(root, "out", "world_zemin.json"))
    if os.path.exists(wk):
        rim = Image.new("L", (n, n), 0)
        rdr = ImageDraw.Draw(rim)
        for rd in json.load(open(wk))["roads"]:
            rdr.line([(x * scale, y * scale) for x, y in rd["p"]], fill=255,
                     width=max(2, int((26 if rd["c"] == "road" else 18) * scale)))
        roadm = zemin_paint.smooth(np.asarray(rim, np.float32) / 255, 3 * scale)
    # göçebe bozkırı: yurtların çevresi (kuzeybatı) - orman yalnız orijinal
    # haritanınki kadar, tarla yok, kuru ot ve yosun rengi
    steppe = np.zeros((n, n), np.float32)
    for s_, x_, y_ in world["syms"]:
        if s_ in NOMAD_KINDS:
            R_ = 560 * scale
            x0, x1 = int(max(0, x_ * scale - R_)), int(min(n, x_ * scale + R_))
            y0, y1 = int(max(0, y_ * scale - R_)), int(min(n, y_ * scale + R_))
            d_ = np.hypot(xx[y0:y1, x0:x1] - x_ * scale, yy[y0:y1, x0:x1] - y_ * scale) / R_
            steppe[y0:y1, x0:x1] = np.maximum(steppe[y0:y1, x0:x1], np.clip(1.2 - d_, 0, 1))
    steppe = warp_sample(zemin_paint.smooth(steppe, 220 * scale), n, seed + 91, 160 * scale)
    steppe = np.clip(steppe * 1.8, 0, 1) ** 1.3 * land
    edge_px = np.minimum(np.minimum(xx, yy), np.minimum(n - 1 - xx, n - 1 - yy))
    # zeminin yanık kenarı ayrıntı/orman sinyali sayılmasın
    efade = np.clip((edge_px - 30 * scale) / (170 * scale), 0, 1)

    # --- orman alanı (referans harita: haritanın çoğu orman)
    g = base[..., 1] - (base[..., 0] + base[..., 2]) / 2
    greenish = efade * zemin_paint.smooth(np.clip((g + 0.005) / 0.04, 0, 1) * np.clip((0.62 - lum) / 0.15, 0, 1), 3 * scale)
    ell = warp_sample(zemin_paint.smooth(m_forest, 10 * scale), n, seed + 40, 90 * scale)
    # dağ: kaba maske + haritanın kendi çizili sıradağları (rölyef)
    relief = coastline.relief(root, n)
    mnt = np.maximum(zemin_paint.smooth(m_mount, 18 * scale), zemin_paint.smooth(relief, 10 * scale))
    patch = zemin_paint.fbm(n, seed + 21, 5, 4)
    woods = np.clip((patch - 0.50) * 5, 0, 1)                  # ovada dağınık korular
    forest_f = np.maximum.reduce([ell * 1.4, greenish * 1.2, mnt * 1.6 * np.clip((patch - 0.30) * 4, 0, 1), woods * 0.9])
    forest_f = forest_f + (zemin_paint.fbm(n, seed + 77, 14, 3) - 0.5) * 0.5
    # dağın çekirdeği açık kaya sırtı kalır (kuşak okunsun), orman yamaçta
    core = zemin_paint.smooth(np.clip((zemin_paint.smooth(np.maximum(m_mount, relief), 5 * scale) - 0.55) * 3, 0, 1), 3 * scale)
    core = core * np.clip((zemin_paint.fbm(n, seed + 88, 18, 2) - 0.25) * 3, 0, 1)
    forest_f = zemin_paint.smooth(forest_f, 4 * scale) - clear * 1.2 - core * 1.4 - foot * 3.0 - roadm * 2.0
    landmask = land > 0.5
    thr = np.quantile(forest_f[landmask], 1 - FOREST_SHARE)
    forest = np.clip((forest_f - thr) * 8 + 0.5, 0, 1) * np.clip(land * 1.2 - 0.2, 0, 1)
    # kıyıdan biraz geri çekil: suyun kenarında çayır şeridi
    shore_gap = np.clip(ndi.distance_transform_edt(~wb) / (14 * scale) - 0.5, 0, 1)
    # bozkırda orman = orijinal haritanın orman lekeleri, o kadar
    strict = warp_sample(zemin_paint.smooth(m_forest, 6 * scale), n, seed + 41, 30 * scale)
    strict = np.clip((strict - 0.45) * 6, 0, 1) * (1 - np.clip(foot * 3 + roadm * 2, 0, 1))
    forest = forest * (1 - steppe) + strict * steppe
    forest = forest * shore_gap * np.clip((edge_px - 30 * scale) / (90 * scale), 0, 1)
    mount = np.clip(mnt * 1.4, 0, 1) * land

    # --- çayır: referans harita sarı-zeytini, iki ölçekli yamalar
    pf = zemin_paint.fbm(n, seed + 3, 5)
    pf2 = zemin_paint.fbm(n, seed + 9, 24, 2)
    t = np.clip((pf - 0.5) * 2.0 + 0.5 + (pf2 - 0.5) * 0.45, 0, 1)[..., None]
    col = MEADOW_LO * (1 - t) + MEADOW_HI * t
    tt = np.clip((zemin_paint.fbm(n, seed + 93, 9, 3) - 0.5) * 3 + 0.5, 0, 1)[..., None]
    st_col = STEPPE_LO * (1 - t) + STEPPE_HI * t
    st_col = st_col * (1 - tt * 0.45) + TUNDRA * tt * 0.45
    col = col * (1 - steppe[..., None]) + st_col * steppe[..., None]

    # Dağ: kaynak zeminin gölgesi 1176 px'ten büyütülmüş - doğrudan
    # kullanılınca bulanık leke bıraktı (denendi). Yerine iki şey:
    #  * gölge üç düz tona ayrılır (koyu yamaç / orta / açık sırt) - referans haritanın
    #    düz boya dili, keskin kenarlı;
    #  * gerçek sırt/vadi hatları Hessian ile bulunur, ince mürekkep olur.
    # İkisi de haritanın kendi dağlarını izler - hizalamayı da bu taşır.
    ls = zemin_paint.smooth(lum, 2.5 * scale)
    local = zemin_paint.smooth(lum, 26 * scale) + 1e-3
    rel = ls / local
    mz = np.clip(mount * 1.6 + core, 0, 1)
    dark = np.clip((0.90 - rel) * 14, 0, 1)
    light = np.clip((rel - 1.07) * 14, 0, 1)
    tone = 1 - 0.24 * dark + 0.10 * light
    rockw = np.clip(mount * 0.30 + core * 0.55, 0, 0.85)[..., None]
    col = col * (1 - rockw) + ROCK * rockw
    col = col * (1 + (tone - 1) * (0.25 + 0.75 * mz) * efade)[..., None]
    hxx = ndi.gaussian_filter(lum, 3.0 * scale, order=(0, 2))
    hyy = ndi.gaussian_filter(lum, 3.0 * scale, order=(2, 0))
    hxy = ndi.gaussian_filter(lum, 3.0 * scale, order=(1, 1))
    lam = (hxx + hyy) / 2 + np.sqrt(((hxx - hyy) / 2) ** 2 + hxy ** 2)  # vadi/gölge çizgisi > 0
    q = np.quantile(lam[mz > 0.5], 0.80) if (mz > 0.5).any() else 1.0
    crease = np.clip((lam / (q + 1e-9) - 1.25) * 2.5, 0, 1) * 0.8
    ridge_ink = crease * mz * efade
    # eğim taramaları (açık alanda)
    h = zemin_paint.smooth(m_mount * 1.0 + (1 - lum) * 0.6, 22 * scale)
    gy, gx = np.gradient(h)
    ang = np.arctan2(gy, gx) + np.pi / 2
    slope = np.clip(np.hypot(gx, gy) * 900 / scale, 0, 1)
    open_land = land * (1 - forest)
    hatch = strokes(n, rng, int(160000 * scale * scale), (0.05 + 0.8 * slope) * open_land * 0.6,
                    ang, 14 * scale, max(1, int(1.2 * scale)), 255, 0.5)
    ticks = grass_ticks(n, rng, int(80000 * scale * scale),
                        np.clip(open_land * (1 - mount * 0.7) * (0.6 + 0.5 * steppe), 0, 1), scale)

    # tarlalar
    allowed = land * (1 - np.clip(forest * 2, 0, 1)) * (1 - np.clip(mount * 1.6, 0, 1))
    allowed = zemin_paint.smooth((allowed > 0.7).astype(np.float32), 2 * scale) * (1 - np.clip(foot * 2, 0, 1))
    allowed = allowed * (1 - np.clip(steppe * 1.5 + roadm * 2, 0, 1))
    fsites = [s for s in sites if s[2] >= 0.45]
    fcol, fa, fink = field_patches(n, rng, fsites, allowed, scale)
    col = col * (1 - fa[..., None] * 0.9) + fcol * fa[..., None] * 0.9

    img = np.dstack([col, np.ones((n, n), np.float32)]).astype(np.float32)
    def ink_over(a, k):
        img[..., :3] = img[..., :3] * (1 - a[..., None] * k) + INK * a[..., None] * k
    ink_over(hatch * (1 - fa), 0.55)
    ink_over(ticks * (1 - fa), 0.45)
    ink_over(ridge_ink, 0.6)
    ink_over(fink, 0.55)

    # --- su
    dist = ndi.distance_transform_edt(wb)
    shore = np.exp(-dist / (50 * scale))[..., None]
    wcol = WATER * (1 - shore) + WATER_EDGE * shore
    wcol = wcol * (0.94 + 0.10 * zemin_paint.fbm(n, seed + 11, 8, 3)[..., None])
    wv = wave_hatch(n, rng, water, dist, scale)
    wcol = wcol * (1 - wv[..., None] * 0.40) + np.array([0.22, 0.26, 0.30]) * wv[..., None] * 0.40
    wa = zemin_paint.smooth(water, 1.0 * scale)[..., None]
    img[..., :3] = img[..., :3] * (1 - wa) + wcol * wa

    # nehirler
    wc = np.clip((zemin_paint.smooth(base[..., 2] - base[..., 0], 1.2 * scale) + 0.215) / 0.07, 0, 1)
    river = (wc * (zemin_paint.smooth(water, 25 * scale) < 0.04) * (lum > 0.5)) > 0.5
    # boyalı nehir kesik kesik: boşlukları kapat, kısa kırıntıları at, keskin kenar
    river = ndi.binary_closing(river, iterations=max(1, int(4 * scale)))
    lab, nl = ndi.label(river)
    if nl:
        sz = ndi.sum(river, lab, index=np.arange(1, nl + 1))
        river = np.concatenate([[False], sz > 120 * scale * scale])[lab]
    river = np.clip((zemin_paint.smooth(river.astype(np.float32), 0.8 * scale) - 0.3) * 4, 0, 1) * efade

    # --- orman: koyu taban + y sıralı taçlar
    # taban yalnızca taçların altında: kenarda bulanık koyu hale bırakmasın
    fl = zemin_paint.smooth((ndi.binary_erosion(forest > 0.5, iterations=max(1, int(6 * scale)))).astype(np.float32), 1.0 * scale)[..., None]
    img[..., :3] = img[..., :3] * (1 - fl * 0.9) + FOREST_FLOOR * fl * 0.9
    R = 13.0 * scale
    leafy = sprite_bank(rng, R, "leafy", 40)
    conif = sprite_bank(rng, R * 0.95, "conifer", 20)
    xs, ys = jitter_points(n, R * 1.05, rng)
    ok = (xs >= 0) & (ys >= 0) & (xs < n) & (ys < n)
    xs, ys = xs[ok], ys[ok]
    fm = forest[ys.astype(int), xs.astype(int)]
    keep = rng.random(len(xs)) < fm * 1.05
    xs, ys = xs[keep], ys[keep]
    conif_share = np.clip(mount[ys.astype(int), xs.astype(int)] * 0.55, 0, 0.6) + 0.04
    for i in np.argsort(ys):
        bank = conif if rng.random() < conif_share[i] else leafy
        blit(img, bank[rng.integers(len(bank))], xs[i], ys[i])
    # açık alanda çalı kümeleri ve tek ağaçlar (gölgeli)
    small = sprite_bank(rng, R * 0.55, "leafy", 20)
    lone = sprite_bank(rng, R * 0.8, "leafy", 16)
    cx_, cy_ = jitter_points(n, 70 * scale, rng)
    okc = (cx_ >= 0) & (cy_ >= 0) & (cx_ < n) & (cy_ < n)
    cx_, cy_ = cx_[okc], cy_[okc]
    om = (open_land * (1 - fa) * (1 - mount * 0.6) * (1 - water) * (1 - np.clip(foot * 2 + roadm * 2, 0, 1)) * (1 - 0.85 * steppe))[cy_.astype(int), cx_.astype(int)]
    pts = []
    for x, y, m in zip(cx_, cy_, om):
        if rng.random() > m * 0.28:
            continue
        k = rng.integers(1, 5)
        for _ in range(k):
            pts.append((x + rng.normal() * 9 * scale, y + rng.normal() * 4 * scale, k == 1))
    pts.sort(key=lambda p: p[1])
    for x, y, single in pts:
        b = lone if single else small
        blit(img, b[rng.integers(len(b))], x, y)

    # nehir ormanın üstünden de geçiyor: koyu kıyı + mavi dolgu
    rbank = np.clip(ndi.maximum_filter(river, size=max(3, int(3 * scale) | 1)) - river, 0, 1)
    ink_over(rbank, 0.75)
    img[..., :3] = img[..., :3] * (1 - river[..., None] * 0.92) + WATER_EDGE * 0.92 * river[..., None]

    coast = np.clip(1 - np.abs(zemin_paint.smooth(water, 1.3 * scale) - 0.5) * 3.5, 0, 1)
    ink_over(coast, 0.85)

    # kâğıt: kenara doğru kararma, lekeler, grain
    out = img[..., :3]
    u = yy / n
    v = xx / n
    vig = np.clip(1 - (np.maximum(np.abs(u - 0.5), np.abs(v - 0.5)) - 0.36) * 1.5, 0.80, 1)
    stain = zemin_paint.fbm(n, seed + 31, 4, 4)
    out = out * vig[..., None] * (0.90 + 0.14 * stain[..., None])
    paper_path = os.path.join(REPO_ROOT, "art_source/textures/ambientcg/Paper005/Paper005_1K-JPG_Color.jpg")
    if os.path.exists(paper_path):
        p = np.asarray(Image.open(paper_path).convert("L"), np.float32) / 255
        p = np.tile(p, (n // p.shape[0] + 1, n // p.shape[1] + 1))[:n, :n]
        out = out * (0.9 + 0.1 * p / p.mean())[..., None]
    out = out + (rng.random((n, n)).astype(np.float32)[..., None] - 0.5) * 0.03
    return np.clip(out, 0, 1), wb


def main():
    root, seed, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    size = int(sys.argv[4]) if len(sys.argv) > 4 else 4096
    img, wb = render(root, seed, size)
    Image.fromarray((img * 255).astype(np.uint8)).save(out)
    np.save(out + ".water.npy", wb)
    print("YAZILDI", out)


if __name__ == "__main__":
    main()
