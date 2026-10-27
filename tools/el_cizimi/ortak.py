"""Şablon üretici, alım aracı ve pilotun paylaştığı okuyucular.

Oyunun kendi kaynak dosyalarını (BodyFrames .tres, BeastSkin .tres,
props.tres) Godot'suz okur. Yazmaz: oyuna giren dosyaları `al.py` yazar.
"""
from __future__ import annotations

import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
A = ROOT / "data" / "assets"
FONT = A / "fonts" / "EBGaramond.ttf"

# Katman renkleri: katman haritasında her derinlik katmanı kendi renginde.
LAYER_COLORS = [(70, 110, 220), (40, 170, 190), (90, 170, 70), (230, 150, 40), (210, 60, 60),
                (150, 80, 200), (200, 120, 160), (120, 120, 120)]
GUIDE = (0, 150, 200)


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT), size)


def _packed(text: str, name: str, kind: str) -> list:
    m = re.search(r"%s = %s\(([^)]*)\)" % (name, kind), text)
    if not m or not m.group(1).strip():
        return []
    body = m.group(1)
    if kind == "PackedStringArray":
        return re.findall(r'"([^"]*)"', body)
    return [float(x) for x in body.split(",")]


def res_path(p: str) -> Path:
    return ROOT / p.removeprefix("res://")


class Frames:
    """BodyFrames: kareler, beş derinlik katmanı, dört tür (beden/üst/alt/saç)."""

    LAYERS = ["back_arm", "back_leg", "torso_head", "front_leg", "front_arm"]
    KINDS = 4

    def __init__(self, set_id: str):
        self.dir = A / "characters" / "frames" / set_id
        text = (self.dir / "frames.tres").read_text(encoding="utf-8")
        self.pages = [Image.open(res_path(p)).convert("RGBA") for p in _packed(text, "pages", "PackedStringArray")]
        self.clip_names = _packed(text, "clip_names", "PackedStringArray")
        self.clip_frames = [int(x) for x in _packed(text, "clip_frames", "PackedInt32Array")]
        self.rects = [int(x) for x in _packed(text, "rects", "PackedInt32Array")]
        off = _packed(text, "offsets", "PackedVector2Array")
        self.offsets = [(off[i], off[i + 1]) for i in range(0, len(off), 2)]
        self.joint_names = _packed(text, "joint_names", "PackedStringArray")
        jp = _packed(text, "joints", "PackedVector2Array")
        self.joints = [(jp[i], jp[i + 1]) for i in range(0, len(jp), 2)]
        m = re.search(r"texel_scale = ([0-9.]+)", text)
        self.texel_scale = float(m.group(1)) if m else 1.0
        self.base = {}
        acc = 0
        for name, n in zip(self.clip_names, self.clip_frames):
            self.base[name] = acc
            acc += n

    def piece(self, clip: str, frame: int, layer: int, kind: int = 0):
        """(RGBA resim, (x, y) ayak noktasına göre sol üst, texel ölçeği) ya da None."""
        i = ((self.base[clip] + frame) * len(self.LAYERS) + layer) * self.KINDS + kind
        page, x, y, w, h = self.rects[i * 5:i * 5 + 5]
        if w <= 0 or h <= 0:
            return None
        img = self.pages[page].crop((x, y, x + w, y + h))
        return img, self.offsets[i]

    def frame_joints(self, clip: str, frame: int) -> dict:
        n = len(self.joint_names)
        b = (self.base[clip] + frame) * n
        return {name: self.joints[b + k] for k, name in enumerate(self.joint_names)}

    def compose(self, clip: str, frame: int, kinds=(0,), layers=None, scale: float = 1.0):
        """Katmanları ayak noktası (0,0) olan bir tuvale dizer. Dönüş: {katman: (resim, sol_üst)}."""
        out = {}
        for li in (layers if layers is not None else range(len(self.LAYERS))):
            for kind in kinds:
                p = self.piece(clip, frame, li, kind)
                if p is None:
                    continue
                img, (ox, oy) = p
                k = self.texel_scale * scale
                if k != 1.0:
                    img = img.resize((max(1, round(img.width * k)), max(1, round(img.height * k))), Image.LANCZOS)
                out.setdefault(li, []).append((img, (ox * scale, oy * scale)))
        return out


def bbox_of(placed: dict) -> tuple[float, float, float, float]:
    xs, ys, xe, ye = [], [], [], []
    for items in placed.values():
        for img, (x, y) in items:
            xs.append(x); ys.append(y); xe.append(x + img.width); ye.append(y + img.height)
    return min(xs), min(ys), max(xe), max(ye)


def paste_placed(canvas: Image.Image, placed: dict, origin: tuple[float, float], scale: float,
                 tint=None, alpha: float = 1.0, layers=None) -> None:
    for li in sorted(placed):
        if layers is not None and li not in layers:
            continue
        for img, (x, y) in placed[li]:
            im = img
            if scale != 1.0:
                im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
            if tint is not None:
                c = tint(li) if callable(tint) else tint
                a = np.array(im)
                lum = a[..., :3].mean(axis=2, keepdims=True) / 255.0
                rgb = (np.array(c, dtype=np.float32) * (0.45 + 0.55 * lum)).clip(0, 255)
                a = np.concatenate([rgb.astype(np.uint8), a[..., 3:]], axis=2)
                im = Image.fromarray(a, "RGBA")
            if alpha < 1.0:
                a = np.array(im)
                a[..., 3] = (a[..., 3] * alpha).astype(np.uint8)
                im = Image.fromarray(a, "RGBA")
            canvas.alpha_composite(im, (round(origin[0] + x * scale), round(origin[1] + y * scale)))


class Skin:
    """BeastSkin: üç katman (uzak bacaklar, kuyruk, gövde) ve her katmanın
    doku pikselinden poz uzayına eşlemesi (uv -> köşe)."""

    def __init__(self, species: str):
        self.dir = A / "characters" / "beasts" / species
        text = (self.dir / "skin.tres").read_text(encoding="utf-8")
        self.textures = _packed(text, "layer_textures", "PackedStringArray")
        vo = [int(x) for x in _packed(text, "layer_vertex_offsets", "PackedInt32Array")]
        v = _packed(text, "vertices", "PackedVector2Array")
        uv = _packed(text, "uvs", "PackedVector2Array")
        V = np.array(v).reshape(-1, 2)
        U = np.array(uv).reshape(-1, 2)
        self.layers = []
        for li, name in enumerate(self.textures):
            img = Image.open(self.dir / name).convert("RGBA")
            vv, uu = V[vo[li]:vo[li + 1]], U[vo[li]:vo[li + 1]]
            # poz = a * uv + b, eksen başına: doku dikdörtgeni poz uzayında nerede.
            ax = np.polyfit(uu[:, 0], vv[:, 0], 1)
            ay = np.polyfit(uu[:, 1], vv[:, 1], 1)
            x0, y0 = ax[1], ay[1]
            sx, sy = ax[0] / img.width, ay[0] / img.height
            self.layers.append({"name": name, "img": img, "origin": (x0, y0), "px": (sx, sy)})


def props_sheet() -> dict:
    import json
    text = (A / "props" / "props.tres").read_text(encoding="utf-8")
    m = re.search(r"props = (\{.*\})\s*$", text, re.S | re.M)
    return json.loads(m.group(1))


def label(draw: ImageDraw.ImageDraw, xy, text: str, size: int, fill=(30, 30, 30)) -> None:
    draw.text(xy, text, font=font(size), fill=fill)
