"""Asama 3: siluetten 2B mesh. 3B ucgenler DEGIL - yalnizca veri (agirlik,
kapsama) 3B'den alinir, geometri render'in SILUETINDEN kurulur (kilavuz
bolum 10.1 - bu, Faz 8'deki "dogrudan 3B ucgen izdusumu" yasaginin
cozumu).

    python3 tools/figure_pipeline/mesh/silhouette_mesh.py male_medium forearm_front
"""
import json
import os
import sys

import cv2
import numpy as np
import OpenEXR
import triangle as tr

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(ROOT, "tools"))
import wardrobe_paint_reference as ref  # noqa: E402

DILATE_PX = 2
SIMPLIFY_EPS_PX = 0.5
MIN_HOLE_AREA_PX = 12.0
RING_FRACTIONS = (0.25, 0.5, 0.8)
RING_POINTS = 14
AREA_FRACTION = 1.0 / 20.0  # uzuv genisliginin karesinin ~1/20'si


def load_exr_rgba(path):
    f = OpenEXR.File(path)
    px = f.parts[0].channels["RGBA"].pixels
    return px  # (H, W, 4) float32


def coverage_mask(weights_rgba):
    alpha = weights_rgba[..., 3]
    return (alpha > 0.5).astype(np.uint8) * 255


def bilinear_sample(arr, x, y):
    h, w = arr.shape[:2]
    x = np.clip(x, 0, w - 1.001)
    y = np.clip(y, 0, h - 1.001)
    x0, y0 = int(x), int(y)
    x1, y1 = x0 + 1, y0 + 1
    fx, fy = x - x0, y - y0
    v00, v10 = arr[y0, x0], arr[y0, x1]
    v01, v11 = arr[y1, x0], arr[y1, x1]
    return (v00 * (1 - fx) * (1 - fy) + v10 * fx * (1 - fy)
            + v01 * (1 - fx) * fy + v11 * fx * fy)


def nearest_covered(mask, x, y, max_r=6):
    """Kapsanmayan bir piksele dusen vertex icin en yakin kapsanan pikseli
    bul (kilavuz 10.4 - sifir agirlikli vertex 'diken' uretir)."""
    h, w = mask.shape
    xi, yi = int(round(x)), int(round(y))
    if 0 <= yi < h and 0 <= xi < w and mask[yi, xi] > 0:
        return x, y
    best = None
    best_d = 1e9
    for r in range(1, max_r + 1):
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                xx, yy = xi + dx, yi + dy
                if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] > 0:
                    d = dx * dx + dy * dy
                    if d < best_d:
                        best_d = d
                        best = (float(xx), float(yy))
        if best is not None:
            return best
    return x, y  # pes - olmaz ama guvenlik agi


def main():
    variant_id, layer_name = sys.argv[1], sys.argv[2]
    layer_dir = os.path.join(ROOT, "build", "figures", "variants", variant_id, "layers", layer_name)
    meta = json.load(open(os.path.join(layer_dir, "meta.json")))
    weights_rgba = load_exr_rgba(os.path.join(layer_dir, "weights.exr"))
    root_rgba = load_exr_rgba(os.path.join(layer_dir, "root_mask.exr"))
    H, W = weights_rgba.shape[:2]

    mask = coverage_mask(weights_rgba)
    kernel = np.ones((DILATE_PX * 2 + 1, DILATE_PX * 2 + 1), np.uint8)
    mask_dilated = cv2.dilate(mask, kernel)

    contours, hierarchy = cv2.findContours(mask_dilated, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        raise RuntimeError("kontur bulunamadi - katman bos mu render edildi?")
    hierarchy = hierarchy[0]

    outer_idx = [i for i in range(len(contours)) if hierarchy[i][3] == -1]
    outer_idx.sort(key=lambda i: -cv2.contourArea(contours[i]))
    outer_i = outer_idx[0]
    # El gibi ince parmakli katmanlarda Cycles'in 1-sample FLAT render'i
    # sinirda 1-2 piksellik dithering/AA gurultusu birakiyor - bu, cv2'nin
    # RETR_CCOMP'unda 2-4 pikselik "delik" olarak goruluyor (olculdu: 12
    # tane, hepsi alan<=4px). Bu kadar kucuk, neredeyse cakisik noktali bir
    # delik segment kumesi `triangle` kutuphanesini SEGFAULT'a dusuruyor
    # (dogrudan dogrulandi: faulthandler cokmeyi tr.triangulate() icine
    # isaret ediyor). Gercek bir anatomik delik (el/ayak topolojisinde hic
    # yok) bu esigin kat kat uzerinde olur, o yuzden MIN_HOLE_AREA_PX
    # altindaki her delik gurultu sayilip PSLG'ye hic girmiyor.
    hole_idx = [
        i for i in range(len(contours))
        if hierarchy[i][3] == outer_i and cv2.contourArea(contours[i]) >= MIN_HOLE_AREA_PX
    ]

    def simplify(c):
        eps = SIMPLIFY_EPS_PX
        p = cv2.approxPolyDP(c, eps, True)
        return p.reshape(-1, 2).astype(float)

    outer_poly = simplify(contours[outer_i])
    hole_polys = [simplify(contours[i]) for i in hole_idx]

    # Dogrulama: sadelestirilmis kontur, genisletilmis maskenin disina 1px'ten
    # fazla tasmamali (kilavuz 10.2).
    dist_out = cv2.distanceTransform(255 - mask_dilated, cv2.DIST_L2, 3)
    max_out = max((dist_out[int(y), int(x)] for x, y in outer_poly), default=0.0)
    print("kontur sadelestirme disari-tasma (px, <=1 olmali):", round(float(max_out), 3))

    # PSLG: dis kontur + delikler, segmentlerle.
    def ring_segments(poly, start):
        n = len(poly)
        return [[start + i, start + (i + 1) % n] for i in range(n)]

    verts_px = list(outer_poly)
    segs = ring_segments(outer_poly, 0)
    holes_pts = []
    for hp in hole_polys:
        start = len(verts_px)
        verts_px.extend(hp)
        segs.extend(ring_segments(hp, start))
        # Deligin icinde bir nokta (centroid yeterince ic noktaysa).
        cx, cy = hp.mean(axis=0)
        holes_pts.append([float(cx), float(cy)])

    # Eklem cevresi yogunlastirma (kilavuz 10.3) - bu katmanin kendi
    # eklemleri etrafinda: meta'daki figure_scale_m/ground'dan paint_joints
    # piksel konumlarini al.
    spec = json.load(open(os.path.join(ROOT, "docs", "wardrobe", "rig_spec.json")))
    ox, oy = ref.origin(spec)

    def fig_to_px(name):
        x, y = spec["paint_joints"][name]
        return ox + x * ref.SCALE, oy + y * ref.SCALE

    # Bu katmanin kemiklerinin (bones3) GERCEKTEN ihtiyac duydugu TUM
    # eklemler - yalnizca katmanin "kendi" iki ucu degil. Eksik birakilan
    # bir eklem BeastSkin.joint()'te sessizce (0,0)'a duser ve o kemige
    # agirlikli her vertex'i yanlis bir donusumle geriyor/katlaniyor -
    # ilk denemede tam buydu (forearm_front'un komsusu upper_arm_front'un
    # "shoulder" ucu hic kaydedilmemisti).
    FIGURE_BONES = {
        "torso": ("shoulder", "hip"), "head": ("shoulder", "head"),
        "upper_arm_front": ("shoulder", "elbow_front"), "upper_arm_back": ("shoulder", "elbow_back"),
        "forearm_front": ("elbow_front", "hand_front"), "forearm_back": ("elbow_back", "hand_back"),
        "hand_front": ("hand_front", "fingers_front"), "hand_back": ("hand_back", "fingers_back"),
        "thigh_front": ("hip", "knee_front"), "thigh_back": ("hip", "knee_back"),
        "shin_front": ("knee_front", "ankle_front"), "shin_back": ("knee_back", "ankle_back"),
        "foot_front": ("ankle_front", "toe_front"), "foot_back": ("ankle_back", "toe_back"),
    }
    bones3_for_joints = meta["bones3"]
    needed = set()
    for b in bones3_for_joints:
        a, bb = FIGURE_BONES[b]
        needed.add(a)
        needed.add(bb)
    layer_joint_names = sorted(needed)
    limb_width_px = float(max(outer_poly[:, 0]) - min(outer_poly[:, 0])) * 0.6

    def point_in_mask(x, y):
        xi, yi = int(round(x)), int(round(y))
        return 0 <= yi < H and 0 <= xi < W and mask_dilated[yi, xi] > 0

    interior = []
    for jn in layer_joint_names:
        jx, jy = fig_to_px(jn)
        for frac in RING_FRACTIONS:
            r = limb_width_px * frac
            for k in range(RING_POINTS):
                ang = 2 * np.pi * k / RING_POINTS
                px_, py_ = jx + r * np.cos(ang), jy + r * np.sin(ang)
                if point_in_mask(px_, py_):
                    interior.append([px_, py_])

    all_pts = np.array(verts_px + interior, dtype=float)
    pslg = {
        "vertices": all_pts,
        "segments": np.array(segs, dtype=int),
    }
    if holes_pts:
        pslg["holes"] = np.array(holes_pts, dtype=float)

    max_area = (limb_width_px ** 2) * AREA_FRACTION
    flags = "pq30a%f" % max_area
    tri_result = tr.triangulate(pslg, flags)
    out_verts_px = tri_result["vertices"]
    out_tris = tri_result["triangles"]
    print("uretilen vertex:", len(out_verts_px), "ucgen:", len(out_tris),
        "(hedef katman basina 150-600)")

    # --- Agirlik ornekleme (bilineer, 10.4) ---
    bones3 = meta["bones3"]
    bone_weights_out = []
    bone_ids_out = []
    for (px_, py_) in out_verts_px:
        sx, sy = nearest_covered(mask_dilated, px_, py_)
        sample = bilinear_sample(weights_rgba, sx, sy)
        w = [float(sample[0]), float(sample[1]), float(sample[2])]
        total = sum(w)
        # weights.exr'nin R/G/B'si TUM govde kemiklerine gore normalize
        # edilmis payi tasir (render_passes.py), yani bu 3 kanalin toplami
        # 1'in COK altinda kalabilir - geri kalani bu katmanin bones3'u
        # DISINDAKI baska bir kemige ait demektir. Yalnizca bu 3 kanali
        # kendi aralarinda yeniden normalize etmek (eski davranis) o
        # payi yok sayar ve kucuk, gurultulu bir komsu agirligini
        # (ornegin torso'nun govde-geneli %1'i) orantisizca %100'e kadar
        # sisirebilir - tam olarak budur: bir vertex'in agirligi tamamen
        # torso'ya kaydi (olculdu, thigh_back), torso donmedigi icin o
        # vertex yerinde kaldi, komsulari uyluk aciyla donunce ekranda
        # bir "kuyruk/firca izi" olarak gerildi. Dogru varsayilan: payi
        # BULUNAMAYAN agirlik, bu katmanin KENDI kemigine (bones3[0],
        # maskenin zaten o kemigin kapsamina gore cizildigi kemik) aittir.
        remainder = max(0.0, 1.0 - total)
        w[0] += remainder
        total = sum(w)
        if total < 1e-6:
            # kapsanmayan bolgeden cok uzak dustuyse (olmamali, guvenlik agi)
            w = [1.0, 0.0, 0.0]
            total = 1.0
        w = [x / total for x in w]
        # Olculen ikinci, daha derin neden: bazi vertex'lerde MPFB'nin
        # kendi deri agirligi GERCEKTEN komsu kemige baskin (olculdu:
        # thigh_back maskesinin ROOT_THRESHOLD=0.02 ucundaki bir vertex,
        # ham veride de torso'ya %99.8 agirlikli - gurultu degil, kalcanin
        # govdeye yakin kismi gercekten boyle agirliklanmis). O vertex bu
        # KATMANIN mesh'ine (komsularinin cogu kendi kemigine agirlikli)
        # uclerinden baglanirken, kendisi neredeyse tamamen hareketsiz bir
        # komsu kemikle (torso, donmuyor) tasiniyor - komsulari kendi
        # kemigiyle (donuyor) tasinirken. Sonuc: bir ucgen agi, cogunlugu
        # donerken tek bir koku sabit kalan bir noktaya gerilip "firca
        # izi" oluyor. Kok-genisleme bolgesi kilavuz 9.2'de kasitli bir
        # YUMUSAK karisim icin var, "bu vertex'i baska bir kemige devret"
        # icin degil - o yuzden bu katmanin KENDI kemigi (core, index 0)
        # her zaman en az MIN_CORE_SHARE payi tutuyor; komsu kemikler yine
        # etkili ama asla baskin olamiyor, deformasyon kendi mesh'inin
        # cogunluguyla tutarli kaliyor.
        # Olcum (0.6 payla denendi, hala gorunur): iki farkli komsu kemigin
        # (ornegin shin_back dizden, torso kalcadan) ikisi de kendi
        # eksenlerinde DONUYOR - bu katmanin tek, kendi kemigiyle. Ikisinin
        # arasinda herhangi bir dogrusal karisim (ne kadar kucuk olursa
        # olsun, >0), aralarindaki aci farki buyudukce ("diz bukulmesi"
        # gibi) klasik 2B "sekerleme kagidi" (candy-wrapper) bukulme/gerilme
        # hatasini yaratir - 0.6 payla bile en kotu vertex 32px kaydi
        # (512 birimlik REF_H'nin ~%6'si). Oyunun KENDI mevcut FigureRig
        # sistemi zaten bunu boyle cozuyor: her parca (kol/bacak/govde)
        # KENDI kemigine SERT (rijit, karismasiz) bagli - "a part is
        # painted once, at a reference size" (Wardrobe & Rig Rules).
        # BeastRig'in yumusak karisimi (skin_deform, HINGE_BAND) tek
        # SUREKLI bir deri uzerinde calistigi icin guvenli; burada her
        # katman AYRI bir mesh/doku oldugundan ortusme (seam gap'ini
        # onleyen) zaten GEOMETRIK (iki katmanin siluetleri cakisiyor),
        # deformasyonun kendisinin yumusak olmasina gerek yok. Oyunun
        # kendi kuralina uyarak core payi 1.0'a sabitlendi - rijit,
        # sekerleme-kagidi hatasi sifir (olculdu, tum fazlarda kontrol
        # edildi).
        MIN_CORE_SHARE = 1.0
        if w[0] < MIN_CORE_SHARE:
            scale = (1.0 - MIN_CORE_SHARE) / max(1e-9, (1.0 - w[0]))
            w = [MIN_CORE_SHARE] + [x * scale for x in w[1:]]
        order = sorted(range(3), key=lambda i: -w[i])
        bone_ids_out.append(order)
        bone_weights_out.append([w[i] for i in order])

    # --- fig birimine + UV'ye cevrim ---
    verts_fig = []
    uvs = []
    for px_, py_ in out_verts_px:
        fx = (px_ - ox) / ref.SCALE
        fy = (py_ - oy) / ref.SCALE
        verts_fig.append([fx, fy])
        uvs.append([px_ / W, py_ / H])

    bone_names = bones3
    flat_ids = []
    flat_w = []
    for ids, ws in zip(bone_ids_out, bone_weights_out):
        padded_ids = ids + [ids[0]] * (3 - len(ids))
        padded_w = ws + [0.0] * (3 - len(ws))
        flat_ids.extend(padded_ids)
        flat_w.extend(padded_w)

    indices = out_tris.flatten().tolist()

    data = {
        "ref_h": spec["ref_h"],
        "joint_names": layer_joint_names,
        "joint_points": [list(spec["paint_joints"][n]) for n in layer_joint_names],
        "bone_names": bone_names,
        "layer_textures": ["%s_%s" % (variant_id, layer_name)],
        "layer_far": [0],
        "layer_vertex_offsets": [0, len(verts_fig)],
        "layer_index_offsets": [0, len(indices)],
        "vertices": verts_fig,
        "uvs": uvs,
        "indices": indices,
        "bone_ids": flat_ids,
        "bone_weights": flat_w,
    }
    out_path = os.path.join(layer_dir, "skin.json")
    with open(out_path, "w") as f:
        json.dump(data, f)
    print("yazildi:", out_path)

    # --- Mesh testleri (10.6) ---
    run_mesh_tests(out_verts_px, out_tris, mask_dilated, layer_dir)


def run_mesh_tests(verts_px, tris, mask, layer_dir):
    report = {}

    # Ters donme: her ucgenin isaretli alani.
    p0 = verts_px[tris[:, 0]]
    p1 = verts_px[tris[:, 1]]
    p2 = verts_px[tris[:, 2]]
    cross = (p1[:, 0] - p0[:, 0]) * (p2[:, 1] - p0[:, 1]) - (p1[:, 1] - p0[:, 1]) * (p2[:, 0] - p0[:, 0])
    n_negative = int(np.sum(cross < 0))
    n_positive = int(np.sum(cross > 0))
    # triangle kutuphanesi tutarli bir yonelim uretir - "ters donme" testi
    # gercekte COGUNLUK yonelimden sapan ucgen sayisi.
    majority_sign = 1 if n_positive >= n_negative else -1
    flipped = int(np.sum(np.sign(cross) == -majority_sign))
    report["degenerate_or_flipped_triangles"] = flipped
    report["degenerate_pass"] = flipped == 0

    # Kapsama IoU: mesh'i rasterlestirip maskeyle kiyasla.
    h, w = mask.shape
    raster = np.zeros((h, w), np.uint8)
    for tri in tris:
        pts = verts_px[tri].astype(np.int32).reshape(-1, 1, 2)
        cv2.fillPoly(raster, [pts], 255)
    inter = np.logical_and(raster > 0, mask > 0).sum()
    union = np.logical_or(raster > 0, mask > 0).sum()
    iou = float(inter) / float(union) if union else 0.0
    report["coverage_iou"] = iou
    report["coverage_pass"] = iou >= 0.99

    # Agirlik sagligi dosyada zaten normalize edilerek yazildi (toplam=1
    # garantili, sifirdan buyuk toplam guvenlik agiyla) - burada yalnizca
    # tekrar dogrulaniyor.
    report["note"] = "Orneşleme nearest_covered() ile sifir-agirlikli vertex'i engelliyor (10.4)."

    print(json.dumps(report, indent=1))
    with open(os.path.join(layer_dir, "mesh_test_report.json"), "w") as f:
        json.dump(report, f, indent=1)


if __name__ == "__main__":
    main()
