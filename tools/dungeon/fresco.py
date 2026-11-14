# -*- coding: utf-8 -*-
"""Kör Kazmalar'ın resimli duvarı (SIDERIA §11.7: "gündelik hayat resimleri").

Kadimlerin resminde savaş, tanrı ya da kral yok: tarla, su taşıyan, sürü,
dokuma, sofra. Figürler yalın, toprak boyasıyla; yüzyıllar boyası dökülmüş,
solmuş. Pigment soluk (Art Rules, tek sıcak kaynak: sıcaklığı meşale verir).

`paint()` duvarın tamamı için bir RGBA resim yazar (x: duvar boyu 20 m,
y: yükseklik 4 m); `mix_into()` onu sıvanın rengine boya olarak karıştırır.
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 5000, 1000              # 20 m x 4 m: 250 px/m
PX = W / 20.0
PAINT_Z = (0.62, 3.1)          # boyalı kuşak, yerden metre
PANELS = [(-10.0, -7.8), (-7.2, -2.8), (-2.2, 2.2), (2.8, 7.2), (7.8, 10.0)]

RED = (150, 92, 74)            # soluk aşı boyası
SOOT = (62, 58, 54)
LIME = (214, 208, 196)
OCHRE = (150, 128, 88)


def _x(m: float) -> float:
    return (m + 10.0) * PX


def _y(z: float) -> float:
    return H - z * PX


def _person(d: ImageDraw.ImageDraw, x: float, ground: float, s: float, color, pose: str, rng) -> None:
    """Yalın insan: baş, gövde, dört uzuv. Pozu işinden."""
    head_r = 0.09 * s
    hip = (x, ground - 0.55 * s)
    neck = (x + (0.08 * s if pose in ("bend", "carry_low") else 0.0), ground - 1.1 * s)
    if pose == "bend":
        neck = (x + 0.35 * s, ground - 0.85 * s)
    width = max(3, int(0.07 * s))
    d.line([hip, neck], fill=color, width=width + 3)
    hx, hy = neck[0] + (0.06 * s if pose == "bend" else 0.0), neck[1] - head_r * 1.2
    d.ellipse([hx - head_r, hy - head_r, hx + head_r, hy + head_r], fill=color)
    stride = 0.18 * s * rng.uniform(0.7, 1.2)
    d.line([hip, (hip[0] - stride, ground)], fill=color, width=width)
    d.line([hip, (hip[0] + stride, ground)], fill=color, width=width)
    sh = (neck[0] * 0.8 + hip[0] * 0.2, neck[1] * 0.8 + hip[1] * 0.2)
    if pose == "carry":       # başında testi
        d.line([sh, (hx - 0.12 * s, hy - 0.05 * s)], fill=color, width=width)
        d.line([sh, (hx + 0.12 * s, hy - 0.05 * s)], fill=color, width=width)
        d.ellipse([hx - 0.13 * s, hy - 0.42 * s, hx + 0.13 * s, hy - 0.12 * s], fill=color)
    elif pose == "bend":      # orak, eğik
        d.line([sh, (sh[0] + 0.35 * s, ground - 0.25 * s)], fill=color, width=width)
        d.arc([sh[0] + 0.2 * s, ground - 0.45 * s, sh[0] + 0.5 * s, ground - 0.15 * s], 200, 340, fill=color, width=width)
    elif pose == "staff":     # çoban değneği
        d.line([sh, (sh[0] + 0.28 * s, sh[1] + 0.2 * s)], fill=color, width=width)
        d.line([(sh[0] + 0.28 * s, ground), (sh[0] + 0.28 * s, ground - 1.3 * s)], fill=color, width=max(2, width - 1))
    elif pose == "raise":     # sofrada, kollar yukarı
        d.line([sh, (sh[0] - 0.25 * s, sh[1] - 0.3 * s)], fill=color, width=width)
        d.line([sh, (sh[0] + 0.25 * s, sh[1] - 0.3 * s)], fill=color, width=width)
    else:
        d.line([sh, (sh[0] - 0.2 * s, hip[1])], fill=color, width=width)
        d.line([sh, (sh[0] + 0.2 * s, hip[1])], fill=color, width=width)


def _animal(d: ImageDraw.ImageDraw, x: float, ground: float, s: float, color, horns: bool, rng) -> None:
    body = [x - 0.4 * s, ground - 0.62 * s, x + 0.4 * s, ground - 0.32 * s]
    d.ellipse(body, fill=color)
    w = max(3, int(0.06 * s))
    for lx in (x - 0.3 * s, x - 0.18 * s, x + 0.2 * s, x + 0.32 * s):
        d.line([(lx, ground - 0.4 * s), (lx + rng.uniform(-0.04, 0.04) * s, ground)], fill=color, width=w)
    head = (x + 0.52 * s, ground - 0.72 * s)
    d.line([(x + 0.32 * s, ground - 0.55 * s), head], fill=color, width=w + 3)
    d.ellipse([head[0] - 0.08 * s, head[1] - 0.07 * s, head[0] + 0.12 * s, head[1] + 0.07 * s], fill=color)
    if horns:
        d.arc([head[0] - 0.2 * s, head[1] - 0.3 * s, head[0] + 0.1 * s, head[1]], 180, 300, fill=color, width=w)
    d.line([(x - 0.4 * s, ground - 0.55 * s), (x - 0.5 * s, ground - 0.3 * s)], fill=color, width=w)


def _panel_field(d, x0, x1, ground, s, rng):
    x = x0 + 0.4
    while x < x1 - 0.3:
        for k in range(3):
            gx = _x(x + k * 0.12)
            d.line([(gx, ground), (gx + rng.uniform(-4, 4), ground - 0.5 * s)], fill=OCHRE, width=4)
            d.ellipse([gx - 6, ground - 0.62 * s, gx + 6, ground - 0.48 * s], fill=OCHRE)
        x += 0.55
    for i in range(3):
        _person(d, _x(x0 + 0.8 + i * (x1 - x0 - 1.4) / 2.5), ground, s, RED, "bend", rng)


def _panel_water(d, x0, x1, ground, s, rng):
    wx = _x(x1 - 0.7)
    d.rectangle([wx - 0.3 * s, ground - 0.45 * s, wx + 0.3 * s, ground], outline=SOOT, width=8)
    d.line([(wx - 0.4 * s, ground - 1.1 * s), (wx + 0.4 * s, ground - 1.1 * s)], fill=SOOT, width=8)
    for i in range(4):
        _person(d, _x(x0 + 0.5 + i * 0.95), ground, s * rng.uniform(0.9, 1.0), RED if i % 2 else SOOT, "carry", rng)


def _panel_herd(d, x0, x1, ground, s, rng):
    pts = [(_x(x0), ground - 1.55 * s)]
    for i in range(1, 9):
        pts.append((_x(x0 + (x1 - x0) * i / 8), ground - (1.35 + 0.35 * math.sin(i * 1.7)) * s))
    d.line(pts, fill=SOOT, width=6)
    for i in range(6):
        _animal(d, _x(x0 + 0.6 + i * 0.68), ground - rng.uniform(0, 0.15) * s, s * 0.55, SOOT if i % 3 else RED, i % 2 == 0, rng)
    _person(d, _x(x1 - 0.5), ground, s, RED, "staff", rng)


def _panel_loom(d, x0, x1, ground, s, rng):
    lx = _x(x0 + 1.1)
    d.rectangle([lx - 0.45 * s, ground - 1.3 * s, lx + 0.45 * s, ground], outline=SOOT, width=8)
    for k in range(9):
        xx = lx - 0.4 * s + k * 0.1 * s
        d.line([(xx, ground - 1.25 * s), (xx, ground - 0.1 * s)], fill=RED, width=3)
    _person(d, lx + 0.75 * s, ground, s, SOOT, "", rng)
    for i in range(3):
        _person(d, _x(x0 + 2.4 + i * 0.6), ground, s * 0.6, RED, "", rng)


def _panel_feast(d, x0, x1, ground, s, rng):
    cx = _x((x0 + x1) / 2)
    d.ellipse([cx - 0.5 * s, ground - 0.25 * s, cx + 0.5 * s, ground - 0.05 * s], fill=OCHRE)
    for i in range(int((x1 - x0) / 0.55)):
        px = _x(x0 + 0.3 + i * 0.55)
        if abs(px - cx) < 0.6 * s:
            continue
        _person(d, px, ground, s * 0.85, RED if i % 2 else SOOT, "raise", rng)


PAINTERS = [_panel_field, _panel_water, _panel_herd, _panel_loom, _panel_feast]


def _flake_mask(rng_seed: int) -> np.ndarray:
    """Dökülmüş boya: büyük lekeler boyayı tamamen almış, ince damar çatlaklar."""
    rs = np.random.RandomState(rng_seed)
    acc = np.zeros((H // 10, W // 10), dtype=np.float32)
    for octave, amp in ((1, 1.0), (2, 0.5), (4, 0.25), (8, 0.12)):
        small = rs.rand(max(2, H // (100 // octave)), max(2, W // (100 // octave))).astype(np.float32)
        img = Image.fromarray((small * 255).astype(np.uint8)).resize((W // 10, H // 10), Image.BICUBIC)
        acc += amp * np.asarray(img, dtype=np.float32) / 255.0
    acc /= acc.max()
    full = np.asarray(Image.fromarray((acc * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC), dtype=np.float32) / 255.0
    keep = np.clip((0.74 - full) * 6.0, 0.0, 1.0)
    grain = rs.rand(H, W).astype(np.float32)
    keep *= np.where(grain < 0.08, 0.3, 1.0)
    return keep


def paint(path: str, seed: int) -> str:
    if os.path.exists(path):
        return path
    rng = random.Random(seed)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ground = _y(PAINT_Z[0] + 0.25)
    s = 1.55 * PX * 0.62
    for (x0, x1), painter in zip(PANELS, PAINTERS):
        # Panonun kuşakları: üstte ve altta iki aşı boyası şerit.
        for z in (PAINT_Z[0] + 0.08, PAINT_Z[1] - 0.1):
            d.rectangle([_x(x0 + 0.1), _y(z) - 7, _x(x1 - 0.1), _y(z) + 7], fill=RED)
        painter(d, x0 + 0.1, x1 - 0.1, ground, s, rng)
    img = img.filter(ImageFilter.GaussianBlur(2.4))
    arr = np.asarray(img, dtype=np.float32)
    alpha = arr[..., 3] / 255.0 * _flake_mask(seed) * 0.8
    arr[..., 3] = alpha * 255.0
    os.makedirs(os.path.dirname(path), exist_ok=True)
    Image.fromarray(arr.astype(np.uint8), "RGBA").save(path)
    return path


def mix_into(nt, color_socket, img_path: str):
    """Sıvanın rengine boyayı karıştırır; resim duvarın üretilmiş koordinatına
    (0..1 x 0..1) oturur, yani yalnız `pano` ızgarasında kullanılır."""
    nodes, links = nt.nodes, nt.links
    coord = nodes.new("ShaderNodeTexCoord")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = __import__("bpy").data.images.load(img_path, check_existing=True)
    tex.extension = "CLIP"
    # Izgaranın kendi UV'si (0..1): üretilmiş koordinat düz ızgarada eksenleri karıştırıyordu.
    uv = nodes.new("ShaderNodeUVMap")
    links.new(uv.outputs["UV"], tex.inputs[0])
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MIX"
    links.new(tex.outputs["Alpha"], mix.inputs["Factor"])
    links.new(color_socket, mix.inputs[6])
    hsv = nodes.new("ShaderNodeHueSaturation")
    hsv.inputs["Saturation"].default_value = 0.8
    hsv.inputs["Value"].default_value = 0.6
    links.new(tex.outputs["Color"], hsv.inputs["Color"])
    links.new(hsv.outputs[0], mix.inputs[7])
    return mix.outputs[2]
