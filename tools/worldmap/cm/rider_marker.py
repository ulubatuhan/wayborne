"""Harita işareti: at ve binicisi, 8 yönden, haritanın mürekkep dilinde.

usage: python rider_marker.py <Horse.gltf> <out_dir> [preview.jpg]

- At: depodaki Quaternius Horse.gltf (CC0). Binici: aynı sahnede basit 3D parçalardan
  (gövde, baş, başlık, pelerin, bacaklar, dizgin tutan kollar) kurulur.
- Kamera: haritadaki dağlarla aynı yukarıdan-yandan bakış (eğim 35°), ortografik.
- Yönler, ekranda gidiş yönü: K (yukarı), KD, D (sağa), GD, G (aşağı, bize doğru), GB, B, KB.
- Mürekkep dili: kâğıt dolgu, dış hat ve kıvrım çizgileri, gölge tarafında dağlardaki gibi
  çapraz tarama, binicinin pelerini tek renk vurgu (koyu kırmızı).
Çıktı: atli_<yön>_<px>.png (64/96/128/256), atli_sayfa.png (8 yön yan yana), atli_yonler.json
(bağlama noktası: tırnakların ortası, görüntü içi oran).
"""
import json
import math
import os
import sys

import numpy as np
import trimesh
from PIL import Image
from scipy import ndimage as ndi

INK = np.array([0.14, 0.10, 0.07])
PAPER = np.array([0.93, 0.88, 0.76])
CLOAK = np.array([0.09, 0.08, 0.075])          # siyah pelerin
EL = math.radians(35)
RES = 720
DIRS = [("K", 270), ("KD", 315), ("D", 0), ("GD", 45), ("G", 90), ("GB", 135), ("B", 180), ("KB", 225)]


def load_horse(p):
    s = trimesh.load(p, force="scene")
    m = s.to_geometry() if hasattr(s, "to_geometry") else s.dump(concatenate=True)
    v = np.asarray(m.vertices, float)
    f = np.asarray(m.faces, int)
    # baş tarafı +z mi -z mi: en yüksek noktanın z işareti
    head_z = v[np.argmax(v[:, 1]), 2]
    if head_z < 0:
        v[:, 2] *= -1
        f = f[:, ::-1]
    v[:, 1] -= v[:, 1].min()
    return v, f


def drape(top_y, bot_y, r_top, r_bot, back, open_deg, zc, nu=40, nv=16):
    """Önü açık pelerin yüzeyi: üstte omuz çevresi, altta geniş etek; arkaya doğru kayar.
    Açı 0 = arka (-z). Önde open_deg genişliğinde açıklık (kollar ve göğüs görünsün)."""
    half = math.radians(180 - open_deg / 2)
    us = np.linspace(-half, half, nu)
    vs = np.linspace(0, 1, nv)
    V = []
    for v_ in vs:
        y = top_y + (bot_y - top_y) * v_
        r = r_top + (r_bot - r_top) * (v_ ** 0.8)
        zoff = -back * v_ ** 1.3                      # etek arkaya, sağrıya dökülür
        for u in us:
            V.append([r * math.sin(u), y, zc + zoff - r * math.cos(u)])
    F = []
    for j in range(nv - 1):
        for i in range(nu - 1):
            a0, a1 = j * nu + i, j * nu + i + 1
            b0, b1 = a0 + nu, a1 + nu
            F += [[a0, b0, a1], [a1, b0, b1]]
    return trimesh.Trimesh(np.array(V), np.array(F), process=False)


LANTERN = np.zeros(3)                            # fenerin model koordinatı (rider() doldurur)


def rider(v):
    """Atın eğerine oturan binici (atın yerel ekseninde: ileri +z, yukarı +y)."""
    H = v[:, 1].max()
    s = H / 4.8
    # sırt profili: z dilimlerinde en yüksek nokta; eğer = gövde ortasındaki en alçak sırt noktası
    z0, z1 = np.percentile(v[:, 2], [8, 70])
    zs = np.linspace(z0, z1, 40)
    prof = []
    for z in zs:
        m = np.abs(v[:, 2] - z) < 0.25 * s
        prof.append(v[m, 1].max() if m.sum() >= 8 else np.nan)
    prof = np.array(prof)
    body = (zs > z0 + (z1 - z0) * 0.25) & (zs < z0 + (z1 - z0) * 0.75)
    k = int(np.nanargmin(np.where(body, prof, np.nan)))
    zc, back = float(zs[k]), float(prof[k])
    near = (np.abs(v[:, 2] - zc) < 0.3 * s) & (v[:, 1] > back - 0.9 * s)
    w = float(np.abs(v[near, 0]).max()) if near.any() else 0.45 * s
    parts = []

    def add(mesh, kind, *Ts):
        T = np.eye(4)
        for t_ in Ts:
            T = T @ t_
        mesh.apply_transform(T)
        parts.append((mesh, kind))

    def tr(x, y, z):
        return trimesh.transformations.translation_matrix([x, y, z])

    def rx(a):
        return trimesh.transformations.rotation_matrix(a, [1, 0, 0])

    def rz(a):
        return trimesh.transformations.rotation_matrix(a, [0, 0, 1])

    UP = rx(-math.pi / 2)                      # +z ekseni -> +y (dikey)
    s = s * 1.3                                # binici/at oranı (yetişkin binici)
    seat = back + 0.02 * s
    # bacaklar: böğrün iki yanında, dizden hafif öne
    for sd in (-1, 1):
        add(trimesh.creation.capsule(height=0.95 * s, radius=0.12 * s, count=[10, 10]), "rider",
            tr(sd * (w + 0.06 * s), seat - 0.42 * s, zc + 0.10 * s), rx(0.22), rz(sd * 0.10), UP)
    # gövde: dik, hafif öne eğik
    add(trimesh.creation.capsule(height=0.62 * s, radius=0.24 * s, count=[12, 12]), "rider",
        tr(0, seat + 0.52 * s, zc - 0.02 * s), rx(0.12), UP)
    # kollar: omuzdan dizgine, öne ve aşağı
    add(trimesh.creation.capsule(height=0.58 * s, radius=0.08 * s, count=[8, 8]), "rider",
        tr(-0.24 * s, seat + 0.62 * s, zc + 0.28 * s), rx(0.75))                 # sol kol: dizgin
    sh = np.array([0.26 * s, seat + 0.86 * s, zc + 0.02 * s])                     # sağ omuz
    d = np.array([0.62, 0.86, 0.30]); d /= np.linalg.norm(d)                      # yukarı, öne, hafif yana
    L = 0.70 * s
    arm = trimesh.creation.capsule(height=L, radius=0.08 * s, count=[8, 8])
    ax = np.cross([0, 0, 1], d); ang = math.acos(np.clip(d[2], -1, 1))
    Rm = trimesh.transformations.rotation_matrix(ang, ax) if np.linalg.norm(ax) > 1e-6 else np.eye(4)
    add(arm, "rider", tr(*(sh + d * L / 2)), Rm)
    hand = sh + d * L
    # fener: elden kısa sapla sarkan gövde + şapka
    lc = hand + np.array([0.04 * s, -0.36 * s, 0])
    add(trimesh.creation.cylinder(radius=0.012 * s, height=0.18 * s, sections=6), "rider",
        tr(hand[0], hand[1] - 0.10 * s, hand[2]), UP)
    add(trimesh.creation.box(extents=[0.28 * s, 0.36 * s, 0.28 * s]), "lantern", tr(*lc))
    add(trimesh.creation.cone(radius=0.21 * s, height=0.16 * s, sections=8), "rider",
        tr(lc[0], lc[1] + 0.18 * s, lc[2]), UP)
    LANTERN[:] = lc
    # baş
    add(trimesh.creation.icosphere(subdivisions=2, radius=0.17 * s), "rider", tr(0, seat + 1.12 * s, zc + 0.05 * s))
    # kukuleta: başın arkasını ve üstünü saran yuvarlak örtü (önden yüz açık)
    add(trimesh.creation.icosphere(subdivisions=2, radius=0.205 * s), "cloak", tr(0, seat + 1.15 * s, zc - 0.03 * s))
    # pelerin: omuzlardan sırtı sarıp eğerin üstünden sağrıya ve böğre açılan örtü, önü açık
    add(drape(top_y=seat + 0.98 * s, bot_y=seat - 0.30 * s, r_top=0.27 * s, r_bot=0.62 * s,
              back=0.30 * s, open_deg=110, zc=zc - 0.06 * s), "cloak")
    return parts


def build():
    hv, hf = load_horse(sys.argv[1])
    horse = trimesh.Trimesh(hv, hf, process=False)
    meshes = [(horse, "horse")] + rider(hv)
    V, F, K = [], [], []
    off = 0
    kid = {"horse": 0, "rider": 1, "cloak": 2, "lantern": 3}
    for m, k in meshes:
        V.append(np.asarray(m.vertices, float))
        F.append(np.asarray(m.faces, int) + off)
        K.append(np.full(len(m.faces), kid[k]))
        off += len(m.vertices)
    return np.vstack(V), np.vstack(F), np.concatenate(K)


def render(V, F, K, heading_deg):
    # model ileri (+z) -> dünya yönü; dünya: x doğu, z güney (ekranda aşağı), y yukarı
    a = math.radians(heading_deg)
    fwd = np.array([math.cos(a), 0, math.sin(a)])
    side = np.array([-math.sin(a), 0, math.cos(a)])
    R = np.stack([side * -1, [0, 1, 0], fwd], 1)       # model (x,y,z) -> dünya
    W = V @ R.T
    up = np.array([0, math.cos(EL), -math.sin(EL)])
    toward = np.array([0, math.sin(EL), math.cos(EL)])
    sx = W[:, 0]
    sy = -(W @ up)
    dz = W @ toward
    pts = np.stack([sx, sy], 1)
    lo, hi = pts.min(0), pts.max(0)
    span = (hi - lo).max() * 1.12
    c = (lo + hi) / 2
    P = (pts - c) / span * RES + RES / 2
    zb = np.full((RES, RES), -1e9)
    nrm = np.zeros((RES, RES, 3))
    kid = np.full((RES, RES), -1)
    fid = np.full((RES, RES), -1)
    tri = W[F]
    n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-9
    face_toward = n @ toward
    for i, (a_, b_, c_) in enumerate(F):
        p0, p1, p2 = P[a_], P[b_], P[c_]
        x0, x1 = int(max(0, min(p0[0], p1[0], p2[0]))), int(min(RES - 1, max(p0[0], p1[0], p2[0]) + 1))
        y0, y1 = int(max(0, min(p0[1], p1[1], p2[1]))), int(min(RES - 1, max(p0[1], p1[1], p2[1]) + 1))
        if x1 < x0 or y1 < y0:
            continue
        den = (p1[1] - p2[1]) * (p0[0] - p2[0]) + (p2[0] - p1[0]) * (p0[1] - p2[1])
        if abs(den) < 1e-9:
            continue
        gy, gx = np.mgrid[y0:y1 + 1, x0:x1 + 1] + 0.5
        w0 = ((p1[1] - p2[1]) * (gx - p2[0]) + (p2[0] - p1[0]) * (gy - p2[1])) / den
        w1 = ((p2[1] - p0[1]) * (gx - p2[0]) + (p0[0] - p2[0]) * (gy - p2[1])) / den
        w2 = 1 - w0 - w1
        ins = (w0 >= -1e-4) & (w1 >= -1e-4) & (w2 >= -1e-4)
        if not ins.any():
            continue
        z = w0 * dz[a_] + w1 * dz[b_] + w2 * dz[c_]
        sub = zb[y0:y1 + 1, x0:x1 + 1]
        upd = ins & (z > sub)
        sub[upd] = z[upd]
        nn = n[i] if face_toward[i] >= 0 else -n[i]
        nrm[y0:y1 + 1, x0:x1 + 1][upd] = nn
        kid[y0:y1 + 1, x0:x1 + 1][upd] = K[i]
        fid[y0:y1 + 1, x0:x1 + 1][upd] = i
    # tırnak (yer) noktası: atın en alt noktalarının ortası
    lw = LANTERN @ R.T
    lp = (np.array([lw[0], -(lw @ up)]) - c) / span * RES + RES / 2
    # Dört toynağın ekrandaki kutusu: eğik bakışta arka toynaklar öndekilerden
    # yukarıda görünür. Gölge ve bağlantı noktası bu kutunun ortasında; ilk
    # sürüm en alttaki (en yakın) toynağı aldı, arka ayaklar havada kaldı.
    feet = P[np.asarray(W[:, 1] < W[:, 1].min() + 0.08)]
    box = (float(feet[:, 0].min()), float(feet[:, 1].min()), float(feet[:, 0].max()), float(feet[:, 1].max()))
    anchor = ((box[0] + box[2]) / 2.0, (box[1] + box[3]) / 2.0)
    return zb, nrm, kid, fid, (anchor, (float(lp[0]), float(lp[1])), float(lw @ toward), box)


def ink(zb, nrm, kid, fid, info):
    anchor, lpos, ldepth = info[:3]
    mask = kid >= 0
    light = np.array([-0.75, 0.75, -0.25])
    light /= np.linalg.norm(light)
    lam = (nrm @ light)
    # kıvrım çizgileri: derinlik sıçraması, parça sınırı, keskin normal değişimi
    zf = np.where(mask, zb, np.nan)
    dzx = np.abs(np.diff(np.nan_to_num(zf, nan=-1e3), axis=1, prepend=np.nan_to_num(zf[:, :1], nan=-1e3)))
    dzy = np.abs(np.diff(np.nan_to_num(zf, nan=-1e3), axis=0, prepend=np.nan_to_num(zf[:1], nan=-1e3)))
    span = np.nanmax(zf) - np.nanmin(zf)
    crease = mask & ((dzx > span * 0.06) | (dzy > span * 0.06))
    kchg = (kid != np.roll(kid, 1, 0)) | (kid != np.roll(kid, 1, 1))
    crease |= mask & kchg
    nd = (nrm * np.roll(nrm, 1, 0)).sum(-1)
    nd2 = (nrm * np.roll(nrm, 1, 1)).sum(-1)
    crease |= mask & ((nd < 0.55) | (nd2 < 0.55)) & (np.roll(mask, 1, 0) & np.roll(mask, 1, 1))
    edge = mask & ~ndi.binary_erosion(mask, iterations=1)
    outline = ndi.binary_dilation(edge, iterations=2)
    crease = ndi.binary_dilation(crease, iterations=1) & mask
    # tarama: gölge tarafında 45° çizgiler, derin gölgede çapraz
    yy, xx = np.mgrid[0:RES, 0:RES]
    h1 = ((xx + yy) % 9) < 2
    h2 = ((xx - yy) % 9) < 2
    shade = mask & (lam < 0.22) & (kid == 0)
    deep = mask & (lam < -0.15) & (kid == 0)
    hatch = (shade & h1) | (deep & h2)
    rshade = mask & (lam < 0.15) & (kid == 1) & h1
    img = np.ones((RES, RES, 3)) * PAPER
    cm = mask & (kid == 2)
    img[cm] = CLOAK + np.array([0.20, 0.19, 0.18]) * np.clip(lam[cm][:, None], 0, 1) ** 1.5
    img[mask & (kid == 1)] = PAPER * 0.96
    lm = mask & (kid == 3)
    img[lm] = np.array([1.0, 0.86, 0.45])
    ink_m = outline | crease | hatch | rshade
    ink_m &= ~(lm & ~outline)                      # fener camı tarama almaz
    img[ink_m] = INK
    alpha = (mask | outline).astype(float)
    # ışıltı: fenerin çevresinde sıcak hale; nesnenin üstünde hafif aydınlatma, dışında saydam ışık
    lx, ly = lpos
    rr = np.hypot(xx - lx, yy - ly) / (RES * 0.26)
    glow = np.clip(1 - rr, 0, 1) ** 1.8
    warm = np.array([1.0, 0.80, 0.38])
    inside = alpha > 0
    img[inside] = img[inside] * (1 - 0.45 * glow[inside, None]) + warm * 0.45 * glow[inside, None]
    outg = ~inside & (glow > 0.01)
    img[outg] = warm
    alpha[outg] = 0.85 * glow[outg]
    # yer gölgesi: tırnakların altında yassı elips
    ax, ay = anchor
    box = info[3]
    rx = max(RES * 0.06, (box[2] - box[0]) / 2.0 + RES * 0.05)
    ry = max(RES * 0.025, (box[3] - box[1]) / 2.0 + RES * 0.02)
    ell = (((xx - ax) / rx) ** 2 + ((yy - ay) / ry) ** 2) < 1
    sh = ell & ~(mask | outline)
    img[sh] = img[sh] * 0 + INK
    alpha[sh] = 0.22
    return np.dstack([img, alpha])


def save(rgba, path, px):
    # tam kareye kırp (içeriğe göre, biraz pay), sonra px yüksekliğe indir
    a = rgba[..., 3] > 0.01
    ys, xs = np.nonzero(a)
    pad = 8
    y0, y1, x0, x1 = max(0, ys.min() - pad), min(RES, ys.max() + pad), max(0, xs.min() - pad), min(RES, xs.max() + pad)
    s = max(y1 - y0, x1 - x0)
    cy, cx = (y0 + y1) // 2, (x0 + x1) // 2
    y0, x0 = max(0, cy - s // 2), max(0, cx - s // 2)
    crop = rgba[y0:y0 + s, x0:x0 + s]
    im = Image.fromarray((np.clip(crop, 0, 1) * 255).astype(np.uint8), "RGBA")
    big = im.resize((px, px), Image.LANCZOS)
    big.save(path)
    return (x0, y0, s)


def main():
    out = sys.argv[2]
    os.makedirs(out, exist_ok=True)
    V, F, K = build()
    meta = {}
    sheet = []
    for name, deg in DIRS:
        zb, nrm, kid, fid, info = render(V, F, K, deg)
        anchor = info[0]
        rgba = ink(zb, nrm, kid, fid, info)
        x0, y0, s = None, None, None
        for px in (64, 96, 128, 256):
            x0, y0, s = save(rgba, os.path.join(out, "atli_%s_%d.png" % (name, px)), px)
        meta[name] = {"heading_deg": deg, "anchor": [round((anchor[0] - x0) / s, 3), round((anchor[1] - y0) / s, 3)]}
        sheet.append(Image.open(os.path.join(out, "atli_%s_256.png" % name)))
        print(name, "tamam", flush=True)
    W = Image.new("RGBA", (256 * len(sheet), 256), (0, 0, 0, 0))
    for i, im in enumerate(sheet):
        W.alpha_composite(im, (256 * i, 0))
    W.save(os.path.join(out, "atli_sayfa.png"))
    json.dump({"yonler": meta, "not": "heading_deg: ekranda gidiş yönü (0 = sağa/doğu, 90 = aşağı/güney). anchor: "
                                       "görüntü içinde tırnakların ortası (0-1)."},
              open(os.path.join(out, "atli_yonler.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    if len(sys.argv) > 3:
        bg = Image.new("RGB", W.size, (220, 205, 170))
        bg.paste(W, (0, 0), W)
        bg.save(sys.argv[3], quality=90)


if __name__ == "__main__":
    main()
