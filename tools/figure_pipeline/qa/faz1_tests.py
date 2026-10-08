"""Faz 1 hakemleri. Icerik uretilmeden ONCE yazildi; her biri bilinen hatali bir
ornekte basarisiz olmali (bkz. qa/validate_tests_on_old.py).

Esik (prompt): ortalama mutlak fark < 1/255 VE 8/255'ten buyuk fark olan piksel 0.
Karsilastirma 8 bit, onceden carpilmis (premultiplied) RGBA uzerinde, kanal basina.
"""
import json
import os

import numpy as np
from PIL import Image

MEAN_LIMIT = 1.0 / 255.0
PIXEL_LIMIT = 8.0 / 255.0


def load_rgba(path):
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float64) / 255.0
    return a


def premul(img):
    out = img.copy()
    out[..., :3] *= out[..., 3:4]
    return out


def over(layers):
    """Ressam sirasiyla (ilk = en arka) premultiplied alpha-over."""
    acc = np.zeros_like(layers[0])
    for lay in layers:
        p = premul(lay)
        acc = p + acc * (1.0 - p[..., 3:4])
    return acc  # premultiplied


def image_diff(a_premul, b_premul, diff_path=None):
    d = np.abs(a_premul - b_premul)
    mean = float(d.mean())
    per_px = d.max(axis=2)
    n_over = int((per_px > PIXEL_LIMIT + 1e-9).sum())
    if diff_path:
        heat = np.clip(per_px * 8.0, 0, 1)  # 1/8 fark tam kirmizi
        rgb = np.zeros(per_px.shape + (3,), np.uint8)
        rgb[..., 0] = (heat * 255).astype(np.uint8)
        rgb[..., 1] = ((per_px > PIXEL_LIMIT) * 255).astype(np.uint8)  # esik ustu = sari
        base = (np.clip(b_premul[..., 3], 0, 1) * 60).astype(np.uint8)
        rgb[..., 2] = base
        Image.fromarray(rgb).save(diff_path)
    return {"mean_abs": mean, "mean_abs_x255": mean * 255.0, "pixels_over_8": n_over,
            "max_x255": float(per_px.max() * 255.0),
            "pass": mean < MEAN_LIMIT and n_over == 0}


def composite_equals_full(layer_paths, full_path, diff_path=None):
    layers = [load_rgba(p) for p in layer_paths]
    comp = over(layers)
    full = premul(load_rgba(full_path))
    return image_diff(comp, full, diff_path)


def godot_equals_blender(godot_path, blender_layer_paths, diff_path=None):
    comp = over([load_rgba(p) for p in blender_layer_paths])
    g = premul(load_rgba(godot_path))
    if g.shape != comp.shape:
        return {"pass": False, "error": "boyut farkli %s vs %s" % (g.shape, comp.shape)}
    return image_diff(g, comp, diff_path)


# --- no_backfaces -----------------------------------------------------------
def magenta_pixels(path):
    """Ic yuzler duz magenta (1,0,1) emisyonla boyanmis render'da gorunen magenta
    piksel sayisi. AA kenarlari icin magentanin baskin oldugu her piksel sayilir."""
    img = load_rgba(path)
    a = img[..., 3]
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    mask = (a > 0.1) & (r > 0.6) & (b > 0.6) & (g < 0.35)
    return int(mask.sum()), mask


def no_backfaces(magenta_path, mark_path=None):
    n, mask = magenta_pixels(magenta_path)
    if mark_path:
        Image.fromarray((mask * 255).astype(np.uint8)).save(mark_path)
    return {"magenta_pixels": n, "pass": n == 0}


# --- proportions -------------------------------------------------------------
def _dist(p, q):
    return float(np.hypot(p[0] - q[0], p[1] - q[1]))


def _alpha(img):
    return img[..., 3] > 0.5


def hand_length_px(hand_mask, wrist, elbow):
    """Bilek isaretinden, onkol dogrultusunda en uzak el pikseline uzaklik.
    Yalniz el kemerinin ileri yari-duzlemindeki pikseller (bilekten one)."""
    ys, xs = np.nonzero(hand_mask)
    if len(xs) == 0:
        return 0.0, None
    d = np.array([wrist[0] - elbow[0], wrist[1] - elbow[1]], float)
    d /= max(np.hypot(*d), 1e-9)
    rel = np.stack([xs - wrist[0], ys - wrist[1]], 1)
    along = rel @ d
    i = int(np.argmax(along))
    return float(along[i]), (float(xs[i]), float(ys[i]))


def head_height_px(full_alpha, head_top_hint, chin_hint):
    """Tepe: bas bolgesindeki en ust silhouette pikseli. Cene: isaret ipucu yoksa
    profilden (on kontur x(y) en hizli geri cekildigi satir, agiz altinda)."""
    ys, xs = np.nonzero(full_alpha)
    x0, x1 = head_top_hint[0] - 40, head_top_hint[0] + 40
    sel = (xs >= x0) & (xs <= x1)
    top_y = int(ys[sel].min())
    return top_y


def front_profile_chin(full_alpha, top_y, neck_y, facing=1):
    """Yuz profili: her satirda en one (facing yonunde) silhouette pikseli. Cene =
    tepe ile boyun isareti arasinda, profilin en hizli geri cekildigi satir."""
    rows = list(range(top_y, int(neck_y) + 1))
    front = []
    for y in rows:
        xs = np.nonzero(full_alpha[y])[0]
        front.append(xs.max() if facing > 0 else -xs.min())
    front = np.array(front, float)
    span = len(rows)
    # Burun ucu: yuzun ust-orta bolgesinde en one cikan satir.
    a, b = int(span * 0.30), int(span * 0.80)
    nose = a + int(np.argmax(front[a:b]))
    # Cene alti neredeyse yatay: profil tek satirda buyuk bir geri cekilme yapar.
    # Burnun altindaki ILK buyuk geri cekilme = mentonun alt kenari. Kuresel en
    # buyuk dusus (ilk surum) eski goruntude omuz kenarina dustu (olculdu).
    slope = np.diff(front)
    jump = -max(2.0, 0.03 * span)
    for k in range(nose + 2, span - 1):
        if slope[k] <= jump:
            return rows[k]
    return rows[nose + 2 + int(np.argmin(slope[nose + 2:]))]


def proportions(full_path, joints_path, anatomy_path, layer_masks=None, mark_path=None):
    """joints: kare icin 2B piksel eklem isaretleri (ayni karede basilan).
    layer_masks: {katman: png} - isaret-anatomi uyumu icin."""
    img = load_rgba(full_path)
    alpha = _alpha(img)
    j = json.load(open(joints_path))
    anat = json.load(open(anatomy_path))["ratios"]
    side = j.get("front_side_tag", "front")
    res = {"checks": {}}

    hand_mask = alpha.copy()
    if layer_masks and "front_arm" in layer_masks:
        hand_mask = _alpha(load_rgba(layer_masks["front_arm"]))
    wrist, elbow, shoulder = j["front_wrist"], j["front_elbow"], j["front_shoulder"]
    hand_len, tip = hand_length_px(hand_mask, wrist, elbow)
    top_y = head_height_px(alpha, j["head_top_hint"], None)
    # Cene: yeni hatta ayni karede basilan mesh isareti (orta hattaki menton
    # noktasi); yoksa (eski cikti) profilden. Profil yontemi eski goruntude
    # basin omuzlara gomuk oldugu yerde ~20 px asagi kaydi (olculdu) - bu,
    # bas boyunu buyutup el/bas oranini KUCULTUR; yani eski ciktinin dusmesi
    # bu hatadan kaynaklanmiyor.
    if "chin" in j:
        chin_y = int(round(j["chin"][1]))
        res["chin_source"] = "mesh_marker"
    else:
        chin_y = front_profile_chin(alpha, top_y, j["neck"][1], j.get("facing", 1))
        res["chin_source"] = "profile_fallback"
    head_h = float(chin_y - top_y)
    up = _dist(shoulder, elbow)
    fore = _dist(elbow, wrist)
    thigh = _dist(j["front_hip"], j["front_knee"])
    shank = _dist(j["front_knee"], j["front_ankle"])
    measured = {
        "hand_over_head": hand_len / max(head_h, 1e-9),
        "forearm_over_upper_arm": fore / max(up, 1e-9),
        "shank_over_thigh": shank / max(thigh, 1e-9),
    }
    for k, v in measured.items():
        lo, hi = anat[k]["min"], anat[k]["max"]
        res["checks"][k] = {"value": round(v, 3), "range": [lo, hi], "pass": lo <= v <= hi}
    res["raw_px"] = {"hand": hand_len, "head": head_h, "upper_arm": up, "forearm": fore,
                     "thigh": thigh, "shank": shank, "chin_y": chin_y, "top_y": top_y,
                     "fingertip": tip}

    # Isaret-anatomi uyumu: her eklem isareti silhouette icinde olmali.
    outside = []
    for name in ("front_shoulder", "front_elbow", "front_wrist", "front_hip", "front_knee",
                 "front_ankle"):
        x, y = j[name]
        xi, yi = int(round(x)), int(round(y))
        inside = 0 <= yi < alpha.shape[0] and 0 <= xi < alpha.shape[1] and bool(alpha[yi, xi])
        if not inside:
            outside.append(name)
    res["checks"]["markers_inside_silhouette"] = {"outside": outside, "pass": not outside}
    res["pass"] = all(c["pass"] for c in res["checks"].values())

    if mark_path:
        vis = (img * 255).astype(np.uint8).copy()
        out = Image.fromarray(vis)
        from PIL import ImageDraw
        dr = ImageDraw.Draw(out)
        for name in ("front_shoulder", "front_elbow", "front_wrist", "front_hip", "front_knee",
                     "front_ankle", "neck"):
            x, y = j[name]
            dr.ellipse([x - 3, y - 3, x + 3, y + 3], outline=(255, 0, 0, 255))
        if tip:
            dr.ellipse([tip[0] - 3, tip[1] - 3, tip[0] + 3, tip[1] + 3], outline=(0, 160, 255, 255))
        w = img.shape[1]
        dr.line([0, top_y, w, top_y], fill=(0, 200, 0, 255))
        dr.line([0, chin_y, w, chin_y], fill=(0, 200, 0, 255))
        out.save(mark_path)
    return res
