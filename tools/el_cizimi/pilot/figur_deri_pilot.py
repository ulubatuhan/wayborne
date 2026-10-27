"""Pilot: tek bir rölanti çizimi oyunun kemikleriyle bütün pozlara bükülebilir mi?

Elle çizilmiş bir figür henüz yok. Yerine bir *yedek çizim* kullanılıyor:
bedenin ve giysilerin HD rölanti render'ı, mürekkep hattı ve dört düz tonla
elle çizilmiş bir resme benzetiliyor (`stand_in`). Gerçek çizim aynı beş
katmanda, aynı eklemlerle geleceği için bükülme davranışı aynı.

Yöntem (oyuna girecek HumanSkin'in Python ön örneği):
  1. Çizimin dinlenme iskeleti: HD rölanti karesinin kendi eklemleri; karede
     olmayanlar (arka diz, arka bilek, ayak uçları) FigureRig'in rölanti
     pozundan ölçeklenip taşınıyor.
  2. Her katman kendi kemiklerine bağlı (arka_kol: üst kol, önkol, el...).
     Her piksel kemik parçalarına uzaklığıyla ağırlıklanıyor; dirsekte ve
     dizde iki kemik yumuşakça karışıyor.
  3. Hedef kare: FigureActions'ın o karedeki kemik açıları
     (build/figures/clips/*.json, export_clips.gd). Her kemik dinlenme
     açısından o açıya döndürülüp ileri kinematikle yerine konuyor.
  4. Katman bir üçgen ızgarasıyla çiziliyor (doğrusal karışımlı deri,
     BeastSkin'in insan sürümü).
Karşılaştırma: aynı kare için oyunun bugünkü 3B render karesi.

    python3 -I tools/el_cizimi/pilot/figur_deri_pilot.py <klipler klasörü> <çıktı klasörü>
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from ortak import Frames, font  # noqa: E402

LAYERS = Frames.LAYERS
LAYER_BONES = {
    "back_arm": ["upper_arm_back", "forearm_back", "hand_back"],
    "back_leg": ["thigh_back", "shin_back", "foot_back"],
    "torso_head": ["torso", "head"],
    "front_leg": ["thigh_front", "shin_front", "foot_front"],
    "front_arm": ["upper_arm_front", "forearm_front", "hand_front"],
}
BONES = {
    "torso": ("shoulder", "hip"), "head": ("shoulder", "head"),
    "upper_arm_back": ("shoulder", "elbow_back"), "forearm_back": ("elbow_back", "hand_back"),
    "hand_back": ("hand_back", "fingers_back"),
    "thigh_back": ("hip", "knee_back"), "shin_back": ("knee_back", "ankle_back"), "foot_back": ("ankle_back", "toe_back"),
    "thigh_front": ("hip", "knee_front"), "shin_front": ("knee_front", "ankle_front"),
    "foot_front": ("ankle_front", "toe_front"),
    "upper_arm_front": ("shoulder", "elbow_front"), "forearm_front": ("elbow_front", "hand_front"),
    "hand_front": ("hand_front", "fingers_front"),
}
# Uzaklık için kemiğin görünen parçası (baş kemiği omuzdan döner ama kafatası boyundan yukarı).
DIST_SEG = {"head": ("neck", "head_top")}
FK_ORDER = ["torso", "head", "upper_arm_back", "forearm_back", "hand_back", "upper_arm_front", "forearm_front",
            "hand_front", "thigh_back", "shin_back", "foot_back", "thigh_front", "shin_front", "foot_front"]
GRID = 5
FALLOFF = 4.0
HD_PER_RENDER = 3.0  # HD kare kümesi, normal kümenin 3 katı (shoulder_px 484.7 / 161.6)


# --- yedek çizim ----------------------------------------------------------

def stand_in(img: Image.Image, grey: bool) -> Image.Image:
    """Render'ı elle çizim gibi yap: dört düz ton + mürekkep hattı + iç kıvrım çizgileri."""
    a = np.array(img).astype(np.float32)
    alpha = a[..., 3]
    rgb = a[..., :3]
    lum = rgb.mean(axis=2, keepdims=True)
    band = np.floor(lum / 255.0 * 4).clip(0, 3) / 3.0
    if grey:
        flat = np.repeat(70 + band * 150, 3, axis=2)
    else:
        mean = (rgb * (alpha[..., None] > 0)).reshape(-1, 3).sum(0) / max(1, (alpha > 0).sum())
        hue = rgb / np.maximum(lum, 1) * mean.mean()
        flat = (0.55 * hue + 0.45 * mean) * (0.55 + 0.6 * band)
    mask = (alpha > 128).astype(np.uint8)
    ink = mask - cv2.erode(mask, np.ones((5, 5), np.uint8))
    edges = cv2.Canny((lum[..., 0]).astype(np.uint8), 40, 110) > 0
    edges &= cv2.erode(mask, np.ones((7, 7), np.uint8)) > 0
    out = np.concatenate([flat.clip(0, 255), alpha[..., None]], axis=2)
    out[ink > 0, :3] = (34, 26, 22)
    out[edges, :3] = out[edges, :3] * 0.45
    return Image.fromarray(out.astype(np.uint8), "RGBA")


# --- iskelet ---------------------------------------------------------------

def rest_skeleton(hd: Frames, rig_idle: dict) -> tuple[dict, float, np.ndarray]:
    """Çizimin dinlenme eklemleri (HD piksel) ve rig -> HD ölçeği."""
    hdj = {k: np.array(v) for k, v in hd.frame_joints("idle", 0).items()}
    common = ["shoulder", "hip", "elbow_front", "hand_front", "knee_front", "ankle_front"]
    R = np.array([rig_idle[k] for k in common])
    H = np.array([hdj[k] for k in common])
    rc, hc = R.mean(0), H.mean(0)
    s = float(np.sum((R - rc) * (H - hc)) / np.sum((R - rc) ** 2))
    t = hc - s * rc
    joints = {k: s * np.array(v) + t for k, v in rig_idle.items()}
    for k in ("shoulder", "hip", "elbow_front", "hand_front", "fingers_front", "elbow_back", "hand_back", "neck",
              "head_top", "knee_front", "ankle_front"):
        joints[k] = hdj[k]
    # Rölantide arka bacak ön bacağın tam arkasında.
    joints["knee_back"] = joints["knee_front"].copy()
    joints["ankle_back"] = joints["ankle_front"].copy()
    joints["toe_back"] = joints["toe_front"].copy()
    return joints, s, t


def angle(v) -> float:
    return math.atan2(v[1], v[0])


def rot(theta: float) -> np.ndarray:
    c, s = math.cos(theta), math.sin(theta)
    return np.array([[c, -s], [s, c]])


def pose_bones(rest: dict, rig_rest: dict, rig_t: dict, scale: float) -> dict:
    """Kemik adı -> (R, a_dinlenme, a_hedef): v' = R (v - a_r) + a_t."""
    out = {}
    tj = {"hip": rest["hip"] + (np.array(rig_t["hip"]) - np.array(rig_rest["hip"])) * scale}
    for bone in FK_ORDER:
        a, b = BONES[bone]
        d = angle(np.subtract(rig_t[b], rig_t[a])) - angle(np.subtract(rig_rest[b], rig_rest[a]))
        R = rot(d)
        if bone == "torso":
            tj["shoulder"] = tj["hip"] - R @ (rest["hip"] - rest["shoulder"])
        else:
            tj[b] = tj[a] + R @ (rest[b] - rest[a])
        out[bone] = (R, rest[a], tj[a])
    fwd = "thigh_front" if rig_t["knee_front"][0] >= rig_t["knee_back"][0] else "thigh_back"
    out["thigh_fwd"] = out[fwd]
    out["thigh_rear"] = out["thigh_back" if fwd == "thigh_front" else "thigh_front"]
    return out


# --- ağırlıklar ve deri ------------------------------------------------------

def seg_dist(p: np.ndarray, a: np.ndarray, b: np.ndarray) -> np.ndarray:
    ab = b - a
    t = np.clip(((p - a) @ ab) / max(1e-6, ab @ ab), 0, 1)
    return np.linalg.norm(p - (a + t[:, None] * ab), axis=1)


def weights(points: np.ndarray, layer: str, rest: dict, skirt: bool) -> tuple[list, np.ndarray]:
    bones = list(LAYER_BONES[layer])
    d = []
    for bone in bones:
        a, b = DIST_SEG.get(bone, BONES[bone])
        d.append(seg_dist(points, rest[a], rest[b]))
    w = 1.0 / (np.stack(d, axis=1) + 4.0) ** FALLOFF
    w /= w.sum(axis=1, keepdims=True)
    if skirt and layer == "torso_head":
        # Etek ve cüppe: kalçanın altı iki uyluğun ortalamasını izler, kalçadan uzaklaştıkça daha çok.
        below = np.clip((points[:, 1] - rest["hip"][1]) / max(1.0, rest["knee_front"][1] - rest["hip"][1]), 0, 1)
        share = 0.9 * below
        # Önü öndeki uyluğu, arkası arkadaki uyluğu izler (hangisinin önde olduğu kareye göre değişir):
        # adım açılınca etek de açılır, ortadan yarılmaz.
        side = np.clip((points[:, 0] - rest["hip"][0]) / 60.0, -1, 1)
        fwd = share * (0.5 + 0.5 * side)
        bones = bones + ["thigh_fwd", "thigh_rear"]
        w = np.concatenate([w * (1 - share)[:, None], np.stack([fwd, share - fwd], axis=1)], axis=1)
    return bones, w


class LayerSkin:
    def __init__(self, img: Image.Image, pos: tuple[float, float], layer: str, rest: dict, skirt: bool):
        self.img = np.array(img)
        self.pos = np.array(pos)
        h, w = self.img.shape[:2]
        xs = np.arange(0, w + GRID, GRID).clip(0, w)
        ys = np.arange(0, h + GRID, GRID).clip(0, h)
        gx, gy = np.meshgrid(xs, ys)
        self.uv = np.stack([gx.ravel(), gy.ravel()], axis=1).astype(np.float32)
        self.nx = len(xs)
        pts = self.uv + self.pos
        self.bones, self.w = weights(pts, layer, rest, skirt)
        alpha = self.img[..., 3]
        self.cells = []
        for j in range(len(ys) - 1):
            for i in range(len(xs) - 1):
                if alpha[ys[j]:ys[j + 1] + 1, xs[i]:xs[i + 1] + 1].max() > 0:
                    self.cells.append((j, i))

    def deform(self, posed: dict) -> np.ndarray:
        pts = self.uv + self.pos
        out = np.zeros_like(pts)
        for k, bone in enumerate(self.bones):
            R, ar, at = posed[bone]
            out += self.w[:, k:k + 1] * ((pts - ar) @ R.T + at)
        return out

    def draw(self, canvas: np.ndarray, origin: np.ndarray, posed: dict) -> None:
        dst = self.deform(posed) + origin
        nx = self.nx
        for j, i in self.cells:
            q = [j * nx + i, j * nx + i + 1, (j + 1) * nx + i + 1, (j + 1) * nx + i]
            for tri in ((q[0], q[1], q[2]), (q[0], q[2], q[3])):
                _warp_tri(self.img, canvas, self.uv[list(tri)], dst[list(tri)])


def _warp_tri(src: np.ndarray, dst: np.ndarray, s: np.ndarray, d: np.ndarray) -> None:
    x0, y0 = np.floor(d.min(0)).astype(int) - 1
    x1, y1 = np.ceil(d.max(0)).astype(int) + 2
    x0, y0 = max(x0, 0), max(y0, 0)
    x1, y1 = min(x1, dst.shape[1]), min(y1, dst.shape[0])
    if x1 <= x0 or y1 <= y0:
        return
    M = cv2.getAffineTransform(s.astype(np.float32), (d - [x0, y0]).astype(np.float32))
    patch = cv2.warpAffine(src, M, (x1 - x0, y1 - y0), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT)
    m = np.zeros((y1 - y0, x1 - x0), np.uint8)
    cv2.fillConvexPoly(m, np.round((d - [x0, y0]) * 4).astype(np.int32), 1, shift=2)
    cv2.dilate(m, np.ones((2, 2), np.uint8), dst=m)
    region = dst[y0:y1, x0:x1]
    a = (patch[..., 3:4].astype(np.float32) / 255.0) * m[..., None]
    region[..., :3] = (patch[..., :3] * a + region[..., :3] * (1 - a)).astype(np.uint8)
    region[..., 3] = np.maximum(region[..., 3], (a[..., 0] * 255).astype(np.uint8))


# --- figür ------------------------------------------------------------------

class Figure:
    def __init__(self, gender: str, outfit: list[str], rig_idle: dict, skirt_items: set):
        self.body = Frames("body_%s_average_hd" % gender)
        self.rest, self.scale, _ = rest_skeleton(self.body, rig_idle)
        self.rig_idle = rig_idle
        self.sets = [(self.body, (0, 1, 2), True, False)]
        for item in outfit:
            self.sets.append((Frames("outfit_%s_%s_average_hd" % (item, gender)),
                              (0,), item.startswith("hair_"), item in skirt_items))
        # Katman 3.5: etek ve cüppe tek parça, iki bacağın da önünde (çizer bunu "etek" katmanına çizer).
        self.skins: dict[float, list[LayerSkin]] = {li: [] for li in (0, 1, 2, 3, 3.5, 4)}
        for frames, kinds, grey, skirt in self.sets:
            placed = frames.compose("idle", 0, kinds=kinds)
            if skirt:
                merged = [(img, pos) for li in (1, 2, 3) for img, pos in placed.pop(li, [])]
                if merged:
                    img, pos = _merge(merged)
                    self.skins[3.5].append(LayerSkin(stand_in(img, grey), pos, "torso_head", self.rest, True))
            for li, items in placed.items():
                for img, pos in items:
                    self.skins[li].append(LayerSkin(stand_in(img, grey), pos, LAYERS[li], self.rest, False))

    def draw(self, rig_t: dict, size=(900, 760), origin=(400, 700)) -> Image.Image:
        canvas = np.zeros((size[1], size[0], 4), np.uint8)
        posed = pose_bones(self.rest, self.rig_idle, rig_t, self.scale)
        for li in sorted(self.skins):
            for skin in self.skins[li]:
                skin.draw(canvas, np.array(origin, np.float32), posed)
        return Image.fromarray(canvas, "RGBA")


def _merge(items):
    x0 = min(p[0] for _, p in items); y0 = min(p[1] for _, p in items)
    x1 = max(p[0] + im.width for im, p in items); y1 = max(p[1] + im.height for im, p in items)
    canvas = Image.new("RGBA", (int(x1 - x0) + 1, int(y1 - y0) + 1), (0, 0, 0, 0))
    for im, (x, y) in items:
        canvas.alpha_composite(im, (int(x - x0), int(y - y0)))
    return canvas, (x0, y0)


def render_frame(gender: str, outfit: list[str], clip: str, frame: int, size=(900, 760), origin=(400, 700)) -> Image.Image:
    """Bugünkü 3B render karesi (normal küme, HD ölçeğine büyütülmüş)."""
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    sets = [(Frames("body_%s_average" % gender), (0, 1, 2))]
    for item in outfit:
        sets.append((Frames("outfit_%s_%s_average" % (item, gender)), (0,)))
    body_clip = clip
    for li in range(5):
        for frames, kinds in sets:
            c = body_clip if body_clip in frames.base else "idle"
            for kind in kinds:
                p = frames.piece(c, min(frame, frames.clip_frames[frames.clip_names.index(c)] - 1), li, kind)
                if p is None:
                    continue
                img, (ox, oy) = p
                k = HD_PER_RENDER * frames.texel_scale
                img = img.resize((round(img.width * k), round(img.height * k)), Image.LANCZOS)
                canvas.alpha_composite(img, (round(origin[0] + ox * HD_PER_RENDER), round(origin[1] + oy * HD_PER_RENDER)))
    return canvas


def load_clips(folder: Path) -> dict:
    return {p.stem: json.loads(p.read_text()) for p in folder.glob("*.json")}


def joints_of(clips: dict, clip: str, frame: int) -> dict:
    return clips[clip]["frames"][frame]["joints"]


POSES = [("idle", 0, "Rölanti (çizilen poz)"), ("walk", 3, "Yürüyüş 1"), ("walk", 9, "Yürüyüş 2"),
         ("stance_melee", 0, "Savaş duruşu"), ("attack_swing", 4, "Kılıç savurma"), ("attack_thrust", 3, "Mızrak dürtme"),
         ("aim_bow", 0, "Yay germe"), ("hit", 1, "Darbe alma"), ("defend", 2, "Savunma"), ("dodge", 2, "Kaçınma"),
         ("ride", 6, "Binicilik"), ("sit_box", 0, "Sandıkta oturma"), ("downed", 0, "Yere düşmüş"), ("dead", 0, "Ölü")]

OUTFITS = {
    "erkek_koylu": ("male", ["peasant_pants", "peasant_shirt", "leather_boots", "felt_hat"]),
    "erkek_korucu": ("male", ["ranger_pants", "laced_shirt", "ranger_jacket", "ranger_boots", "hair_short01"]),
    "kadin_etek": ("female", ["long_skirt", "peasant_blouse", "peasant_shoes", "hair_braid01"]),
    "erkek_cubbe": ("male", ["pilgrim_robe", "peasant_shoes", "pilgrim_hood"]),
}
SKIRTS = {"long_skirt", "pilgrim_robe", "scribe_robe", "mage_robe", "tiered_skirt", "shift_dress", "pinafore_dress"}


def sheet(name: str, clips: dict, out: Path, skirt_on: bool = True) -> Path:
    gender, outfit = OUTFITS[name]
    fig = Figure(gender, outfit, joints_of(clips, "idle", 0), SKIRTS if skirt_on else set())
    cell = (450, 380)
    cols = 4
    pairs = []
    for clip, frame, label in POSES:
        if clip not in clips:
            continue
        drawn = fig.draw(joints_of(clips, clip, frame))
        ref = render_frame(gender, outfit, clip, frame)
        pairs.append((label, ref, drawn))
    rows = math.ceil(len(pairs) / cols)
    W, H = cols * cell[0] * 2, rows * (cell[1] + 40) + 70
    img = Image.new("RGB", (W, H), (236, 231, 221))
    d = ImageDraw.Draw(img)
    d.text((16, 14), "Pilot: %s - her çiftte solda bugünkü 3B render, sağda tek rölanti çiziminin bükülmüş hâli"
           % name.replace("_", " "), font=font(30), fill=(40, 40, 40))
    for k, (label, ref, drawn) in enumerate(pairs):
        x, y = (k % cols) * cell[0] * 2, 70 + (k // cols) * (cell[1] + 40)
        for j, im in enumerate((ref, drawn)):
            t = im.resize(cell, Image.LANCZOS)
            bg = Image.new("RGBA", cell, (250, 247, 240, 255) if j else (225, 225, 230, 255))
            bg.alpha_composite(t)
            img.paste(bg.convert("RGB"), (x + j * cell[0], y + 32))
        d.text((x + 8, y + 4), label + "   (render | çizim)", font=font(22), fill=(60, 50, 40))
    path = out / ("pilot_%s.jpg" % name)
    img.save(path, quality=88)
    return path


def walk_gif(name: str, clips: dict, out: Path) -> Path:
    gender, outfit = OUTFITS[name]
    fig = Figure(gender, outfit, joints_of(clips, "idle", 0), SKIRTS)
    frames = []
    n = len(clips["walk"]["frames"])
    for i in range(n):
        drawn = fig.draw(joints_of(clips, "walk", i))
        ref = render_frame(gender, outfit, "walk", i)
        f = Image.new("RGBA", (900, 380), (245, 241, 233, 255))
        f.alpha_composite(ref.resize((450, 380), Image.LANCZOS), (0, 0))
        f.alpha_composite(drawn.resize((450, 380), Image.LANCZOS), (450, 0))
        frames.append(f.convert("P", palette=Image.ADAPTIVE))
    path = out / ("pilot_yuruyus_%s.gif" % name)
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=70, loop=0)
    return path


if __name__ == "__main__":
    clips_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    clips = load_clips(clips_dir)
    names = sys.argv[3:] or list(OUTFITS)
    for n in names:
        print(sheet(n, clips, out_dir))
    print(walk_gif(names[0], clips, out_dir))
