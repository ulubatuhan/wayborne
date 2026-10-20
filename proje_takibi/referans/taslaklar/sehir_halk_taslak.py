# -*- coding: utf-8 -*-
"""Y-G10T taslağı: şehir ekranında halk görünsün (kervan şehre girmez).

Figürler oyunun kendi gövde kareleri (data/assets/characters/frames/body_*):
beş derinlik katmanı, gövde gri × ten rengi, temel takım (üst/alt) giysi
rengiyle - WalkFigure'ın çarpma kuralı. Meydana derinliğe göre ölçeklenmiş
bir kalabalık dizilir; sahnenin ışığına göre karartılır. Kervan yok.

    python -X utf8 sehir_halk_taslak.py [yer]
"""
import os
import random
import re
import sys

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = r"D:\Users\u90238\Desktop\xx\wayborne"
FRAMES = os.path.join(ROOT, "data", "assets", "characters", "frames")
FONT = os.path.join(ROOT, "data", "assets", "fonts", "EBGaramond.ttf")
HERE = os.path.dirname(os.path.abspath(__file__))
LAYERS, KINDS = 5, 4

SKINS = [(236, 200, 170), (205, 160, 120), (160, 112, 78), (110, 74, 52)]
CLOTH = [(92, 70, 52), (120, 52, 44), (60, 72, 58), (138, 122, 96), (52, 56, 74), (150, 132, 104)]


def parse(name):
    text = open(os.path.join(FRAMES, name, "frames.tres"), encoding="utf-8").read()

    def arr(key):
        m = re.search(key + r" = Packed\w+\(([^)]*)\)", text)
        return [x.strip().strip('"') for x in m.group(1).split(",")] if m else []

    m = re.search(r"texel_scale = ([0-9.]+)", text)
    pages = [p.replace("res://", "").replace("/", os.sep) for p in arr("pages")]
    base, acc = {}, 0
    for n, c in zip(arr("clip_names"), [int(x) for x in arr("clip_frames")]):
        base[n] = acc
        acc += c
    return {"base": base, "rects": [int(x) for x in arr("rects")], "offs": [float(x) for x in arr("offsets")],
            "pages": [Image.open(os.path.join(ROOT, p)).convert("RGBA") for p in pages],
            "scale": float(m.group(1)) if m else 1.0}


_cache = {}


def frames(name):
    if name not in _cache:
        _cache[name] = parse(name) if os.path.isdir(os.path.join(FRAMES, name)) else None
    return _cache[name]


def put(canvas, fr, clip, frame, layer, kind, tone=None):
    i = ((fr["base"][clip] + frame) * LAYERS + layer) * KINDS + kind
    r = i * 5
    if r + 4 >= len(fr["rects"]) or fr["rects"][r + 3] <= 0:
        return
    page, x, y, w, h = fr["rects"][r:r + 5]
    part = fr["pages"][page].crop((x, y, x + w, y + h))
    if fr["scale"] != 1.0:
        part = part.resize((int(w * fr["scale"]), int(h * fr["scale"])), Image.LANCZOS)
    if tone is not None:
        rgb = ImageChops.multiply(part.convert("RGB"), Image.new("RGB", part.size, tone))
        part = Image.merge("RGBA", (*rgb.split(), part.split()[3]))
    ox, oy = fr["offs"][i * 2], fr["offs"][i * 2 + 1]
    canvas.alpha_composite(part, (int(200 + ox), int(300 + oy)))


def figure(body, clip, frame, skin, garments):
    """Gövde ve giysiler katman katman: her katmanda önce gövde, sonra giysiler sırayla."""
    canvas = Image.new("RGBA", (400, 330), (0, 0, 0, 0))
    variant = body.replace("body_", "")
    sets = [frames("outfit_%s_%s" % (g, variant)) for g in garments]
    fr = frames(body)
    for layer in range(LAYERS):
        put(canvas, fr, clip, frame, layer, 0, skin)
        for gs in sets:
            if gs is not None:
                put(canvas, gs, clip, frame, layer, 0)
    return canvas


MEN = [["peasant_pants", "peasant_shoes", "peasant_shirt"],
       ["wool_pants", "short_boots", "linen_tunic", "felt_hat"],
       ["cloth_trousers", "leather_boots", "laced_shirt", "wool_coat"]]
WOMEN = [["long_skirt", "peasant_shoes", "peasant_blouse"],
         ["tiered_skirt", "womens_ankle_boots", "peasant_blouse", "head_veil"],
         ["pinafore_dress", "felt_shoes"]]


import numpy as np

CRATE = os.path.join(ROOT, "data", "assets", "props", "crate", "body.png")

# Kullanıcı notu (2026-10-19): "insanların ışığı ortamdan aykırı; gece bu kadar
# insan olur mu, akşam bile daha az olmalı; hepsi yürüyor, sahne kurgulanmalı."
# Sahne artık elle kurulu küçük anlar: kapıda feneriyle bir bekçi, kapı önünde
# konuşan iki kişi, eve dönen bir yolcu (gece); akşam bunlara tezgâhını toplayan
# satıcı, sandıkta oturan yaşlı, konuşan bir çift daha ve bir yolcu eklenir.
# Her figür durduğu yerin ışığını alır (arka planın o bölgesinin ortalaması),
# fenerin yanındakiler sıcak bir yan ışık.
# (yer x, yer y, cinsiyet, klip, kare, sağa bakıyor mu, rol)
NIGHT = [
    (0.470, 0.865, "m", "idle", 0, True, "watch"),
    (0.215, 0.950, "m", "idle", 0, True, ""),
    (0.250, 0.950, "f", "idle", 0, False, ""),
    (0.705, 0.975, "m", "walk", 6, False, ""),
]
EVENING = NIGHT + [
    (0.830, 0.940, "f", "idle", 0, False, "vendor"),
    (0.120, 0.985, "m", "ride", 0, True, "seated"),
    (0.520, 0.870, "f", "idle", 0, True, ""),
    (0.548, 0.870, "m", "idle", 0, False, ""),
    (0.365, 0.995, "f", "walk", 14, True, ""),
]


def lit(fig, scene, at, lantern):
    """Figür sahnenin ışığını alır: durduğu yerin ortalama rengi, fenerin yanında sıcak yan ışık."""
    a = np.asarray(fig, np.float32) / 255.0
    h, w, _ = a.shape
    box = scene.convert("RGB").crop((max(0, at[0] - 60), max(0, at[1] - 40), at[0] + w + 60, at[1] + h + 30))
    ambient = np.asarray(box, np.float32).reshape(-1, 3).mean(axis=0) / 255.0
    ambient = np.clip(ambient / max(1e-3, ambient.max()) * min(1.0, ambient.max() * 2.0), 0.06, 1.0)
    light = ambient * 0.7
    if lantern:
        xs = np.linspace(0, 1, w, dtype=np.float32)[None, :, None]
        light = light + np.array([1.0, 0.64, 0.32], np.float32) * (0.15 + 0.35 * xs)
    rgb = a[..., :3] * light
    return Image.fromarray((np.concatenate([np.clip(rgb, 0, 1), a[..., 3:]], axis=-1) * 255).astype(np.uint8))


def glow(img, x, y, radius, colour, strength):
    a = np.asarray(img.convert("RGB"), np.float32)
    yy, xx = np.mgrid[0:img.height, 0:img.width].astype(np.float32)
    k = strength * np.exp(-(((xx - x) ** 2 + (yy - y) ** 2) / (radius ** 2)))
    return Image.fromarray(np.clip(a + k[..., None] * np.array(colour, np.float32), 0, 255).astype(np.uint8)).convert("RGBA")


def stage(town, people, label, suffix):
    bg = Image.open(os.path.join(ROOT, "data", "assets", "ui", "towns", town, "background.jpg")).convert("RGBA")
    W, H = bg.size
    rnd = random.Random(7)
    for x, y, sex, clip, frame, right, role in sorted(people, key=lambda q: q[1]):
        x, y = x * W, y * H
        female = sex == "f"
        body = rnd.choice(["body_female_average", "body_female_lean"] if female else ["body_male_average", "body_male_heavy"])
        fig = figure(body, clip, frame, rnd.choice(SKINS), rnd.choice(WOMEN if female else MEN))
        fig = fig.crop(fig.getbbox())
        if not right:
            fig = fig.transpose(Image.FLIP_LEFT_RIGHT)
        depth = min(1.0, max(0.0, (y - H * 0.84) / (H * 0.18)))
        scale = (0.55 + depth * 0.65) * 1.0
        fig = fig.resize((max(1, int(fig.width * scale)), max(1, int(fig.height * scale))), Image.LANCZOS)
        ax, ay = int(x - fig.width / 2), int(y - fig.height)
        if role == "watch":
            bg = glow(bg, x + fig.width * 0.45, y - fig.height * 0.55, 60 * scale + 20, (255, 170, 80), 0.6)
        if role == "seated":
            box = Image.open(CRATE).convert("RGBA")
            ch = int(fig.height * 0.53)
            box = box.resize((int(ch * 1.1), ch), Image.LANCZOS)
            box = lit(box, bg, (int(x - box.width / 2), int(y - ch)), False)
            bg.alpha_composite(box, (int(x - fig.width * 0.10 - box.width / 2), int(y - ch + 4)))
        shadow = Image.new("RGBA", (fig.width, int(10 * scale) + 4), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).ellipse((fig.width * 0.25, 0, fig.width * 0.75, shadow.height), fill=(0, 0, 0, 140))
        bg.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(2)), (ax, int(y - shadow.height / 2)))
        bg.alpha_composite(lit(fig, bg, (ax, ay), role == "watch"), (ax, ay))
        if role == "watch":
            lamp = (int(x + fig.width * 0.42), int(y - fig.height * 0.52))
            ImageDraw.Draw(bg).ellipse((lamp[0] - 4, lamp[1] - 6, lamp[0] + 4, lamp[1] + 6), fill=(255, 196, 110, 255))
    d = ImageDraw.Draw(bg)
    d.text((40, 30), f"{town} · {label}", font=ImageFont.truetype(FONT, 34), fill=(219, 179, 87))
    out = os.path.join(HERE, f"y_g10t_sehir_halk_{town}{suffix}.png")
    bg.convert("RGB").save(out, quality=90)
    print("yazıldı:", out)


def main(town):
    stage(town, NIGHT, "gece: kapıda bekçi, iki kişi konuşuyor, biri eve dönüyor", "")
    stage(town, EVENING, "akşam: satıcı tezgâhını topluyor, yaşlı sandıkta, çiftler, iki yolcu", "_aksam")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "vastrevar")
