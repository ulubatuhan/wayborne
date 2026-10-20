# -*- coding: utf-8 -*-
"""9.2 + Y-G16 taslağı: ana menü gece kampı, ateş başında üç yorgun yolcu.

Arka plan menünün kendi kamp resmi (data/assets/ui/towns/camp/background.jpg).
Figürler oyunun gövde ve giysi kareleri, `sit_box` klibinin oturuşu (MPFB'den
render edilmiş gerçek oturuş: kalça diz hizasında, uyluk yatay, eller dizde).
Kullanıcı notu (2026-10-19): "sağdaki iki figür hiç oturuyor gibi değil; bağdaş
kurmuş ya da bir kutu, sandık üzerinde otursunlar"; ikinci tur: "bu sandık üstünde
oturmak mı sence?" (`ride` karesi at üstü oturuşuydu, bacaklar sarkıyordu) - her
yolcu bir sandığın üstünde, kalçası sandığın kapağında, ayakları yerde. İkisi ateşe yan dönük, biri ateşin ardında. Işık
yalnızca ateşten: ateşe bakan yan sıcak, öteki yan karanlık. Duman ayrı katman.
Gök mor-lacivert (resmin kendi gecesi); arayüze sağda karanlık, sade alan kalır.

    python -X utf8 menu_kamp_taslak.py
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

import sehir_halk_taslak as people

ROOT = r"D:\Users\u90238\Desktop\xx\wayborne"
HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(ROOT, "data", "assets", "fonts", "IMFellEnglishSC.ttf")
BODY = os.path.join(ROOT, "data", "assets", "fonts", "EBGaramond.ttf")
FIRE = (565, 800)


def seated(body, garments, skin, scale, facing_right):
    fig = people.figure(body, "sit_box", 0, skin, garments)
    fig = fig.crop(fig.getbbox())
    fig = fig.resize((int(fig.width * scale), int(fig.height * scale)), Image.LANCZOS)
    if not facing_right:
        fig = fig.transpose(Image.FLIP_LEFT_RIGHT)
    return fig


CRATE = os.path.join(ROOT, "data", "assets", "props", "crate", "body.png")
## sit_box karesinde oturağın yeri: kalçanın alt yüzü karenin üstünden bu payda,
## kalça karenin ortasından arkaya genişliğin bu payı kadar (ayaklar önde).
SEAT_SHARE = 0.66
HIP_BACK = 0.24


def crate_under(fig, foot, facing_right, light):
    """Sandık: üst yüzü kalçanın altında, altı yerde; ön kenarı dizlerin gerisinde."""
    seat_y = foot[1] - fig.height + int(fig.height * SEAT_SHARE)
    height = max(20, foot[1] - seat_y)
    box = Image.open(CRATE).convert("RGBA")
    width = int(height * box.width / box.height * 0.95)
    box = box.resize((width, height), Image.LANCZOS)
    box = firelit(box, foot, light * 0.8)
    back = -1 if facing_right else 1
    cx = foot[0] + back * int(fig.width * HIP_BACK)
    return box, (int(cx - width / 2), int(foot[1] - height + 4))


def firelit(fig, pos, strength):
    """Ateşe bakan yan sıcak, öteki yan karanlık: yatay gradyan × kehribar."""
    a = np.asarray(fig, np.float32) / 255.0
    h, w, _ = a.shape
    xs = np.linspace(0, 1, w, dtype=np.float32)[None, :, None]
    toward = xs if pos[0] < FIRE[0] else 1.0 - xs
    light = 0.18 + toward * 0.55 * strength
    warm = np.array([1.0, 0.62, 0.34], np.float32)
    rgb = a[..., :3] * light * (0.55 + 0.45 * warm)
    out = np.concatenate([np.clip(rgb, 0, 1), a[..., 3:]], axis=-1)
    return Image.fromarray((out * 255).astype(np.uint8))


def smoke(size):
    layer = Image.new("L", size, 0)
    d = ImageDraw.Draw(layer)
    x, y = FIRE[0], FIRE[1] - 70
    for k in range(18):
        r = 14 + k * 5
        d.ellipse((x - r + k * 9, y - k * 30 - r, x + r + k * 9, y - k * 30 + r), fill=max(0, 70 - k * 4))
    return layer.filter(ImageFilter.GaussianBlur(18))


def main():
    bg = Image.open(os.path.join(ROOT, "data", "assets", "ui", "towns", "camp", "background.jpg")).convert("RGBA")
    sm = smoke(bg.size)
    grey = Image.new("RGBA", bg.size, (120, 112, 120, 255))
    bg = Image.composite(Image.blend(bg, grey, 0.5), bg, sm)
    scale = 1.45
    crew = [
        # (gövde, giysi, ten, ayak noktası, ateşe dönük mü sağa, ölçek çarpanı, ışık)
        ("body_male_heavy", ["wool_pants", "short_boots", "linen_tunic", "wool_coat", "felt_hat"], (205, 160, 120),
         (395, 850), True, 1.0, 1.0),
        ("body_female_lean", ["long_skirt", "felt_shoes", "peasant_blouse", "head_veil"], (236, 200, 170),
         (745, 860), False, 1.0, 1.0),
        ("body_male_lean", ["peasant_pants", "peasant_shoes", "peasant_shirt"], (160, 112, 78),
         (655, 808), False, 0.8, 0.55),
    ]
    crew.sort(key=lambda c: c[3][1])
    for body, garments, skin, (fx, fy), right, k, light in crew:
        fig = seated(body, garments, skin, scale * k, right)
        fig = firelit(fig, (fx, fy), light)
        box, at = crate_under(fig, (fx, fy), right, light)
        bg.alpha_composite(box, at)
        # Oturuş: kalça kütük hizasında, ayaklar yerde - karenin altı ayak noktasına.
        bg.alpha_composite(fig, (int(fx - fig.width / 2), int(fy - fig.height)))
    # Ateşin ışığı figürlerin üstüne tekrar taşar (sıcak hale).
    glow = Image.new("RGB", bg.size, (0, 0, 0))
    ImageDraw.Draw(glow).ellipse((FIRE[0] - 260, FIRE[1] - 200, FIRE[0] + 260, FIRE[1] + 120), fill=(70, 38, 14))
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    rgb = np.clip(np.asarray(bg.convert("RGB"), np.int32) + np.asarray(glow, np.int32), 0, 255).astype(np.uint8)
    out = Image.fromarray(rgb).convert("RGBA")
    d = ImageDraw.Draw(out)
    d.text((1180, 300), "WAYBORNE", font=ImageFont.truetype(FONT, 92), fill=(219, 179, 87))
    for i, item in enumerate(["Devam Et", "Yeni Kervan", "Kayıtlar", "Ayarlar", "Çık"]):
        d.text((1190, 460 + i * 62), item, font=ImageFont.truetype(BODY, 38), fill=(224, 217, 199) if i else (219, 179, 87))
    d.text((1190, 800), "Kara Yol Kervanı · 2. kuşak · 143. gün", font=ImageFont.truetype(BODY, 24), fill=(158, 150, 138))
    path = os.path.join(HERE, "y_g16_menu_kamp.png")
    out.convert("RGB").save(path, quality=90)
    print("yazıldı:", path)


if __name__ == "__main__":
    main()
