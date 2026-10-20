# -*- coding: utf-8 -*-
"""Y-G13 taslağı: kimliği tanımlayan beş ana görsel.

1. Gece haritası ve fenerli atlı  - haritanın kendi karoları, gece tonu (NIGHT_TINT),
   yerleşim ışıkları, atlı işaret ve fener halesi.
2. Kamp ateşi panoraması          - y_g16_menu_kamp.png (menü yazısız sürüm).
3. Tam ekran olay kartı           - olay resmi (e6c_bandits) ve mühürlü kart.
4. Defter ve kırık mühür          - l1_ledger + g9b_seal_cracked, çizili ad.
5. Şehir kapısına varış           - kapı render taslağı (12.2a) ve kapı önündeki vagon.

    python -X utf8 bes_gorsel_taslak.py
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = r"D:\Users\u90238\Desktop\xx\wayborne"
HERE = os.path.dirname(os.path.abspath(__file__))
WB = os.path.join(ROOT, "data", "assets", "ui", "waybook")
MAP = os.path.join(ROOT, "data", "assets", "map")
PROPS = os.path.join(ROOT, "data", "assets", "props")
F_HEAD = os.path.join(ROOT, "data", "assets", "fonts", "IMFellEnglishSC.ttf")
F_BODY = os.path.join(ROOT, "data", "assets", "fonts", "EBGaramond.ttf")
W, H = 1920, 1080
GOLD = (219, 179, 87)
BONE = (224, 217, 199)
INK = (40, 30, 26)


def glow(img, x, y, radius, colour, strength):
    a = np.asarray(img.convert("RGB"), np.float32)
    yy, xx = np.mgrid[0:img.height, 0:img.width].astype(np.float32)
    k = strength * np.exp(-(((xx - x) ** 2 + (yy - y) ** 2) / (radius ** 2)))
    a = np.clip(a + k[..., None] * np.array(colour, np.float32), 0, 255)
    return Image.fromarray(a.astype(np.uint8))


def night_map():
    level, scale = 3, 0.5
    cx, cy = 6433.2 * scale, 3556.2 * scale  # Vastrevar
    x0, y0 = int(cx - W / 2), int(cy - H / 2)
    canvas = Image.new("RGB", (W, H))
    for tx in range(x0 // 1024, (x0 + W) // 1024 + 1):
        for ty in range(y0 // 1024, (y0 + H) // 1024 + 1):
            path = os.path.join(MAP, "tiles", str(level), f"{tx}_{ty}.jpg")
            if os.path.exists(path):
                canvas.paste(Image.open(path).convert("RGB"), (tx * 1024 - x0, ty * 1024 - y0))
    a = np.asarray(canvas, np.float32) * np.array([0.60, 0.64, 0.75], np.float32) * 0.72
    img = Image.fromarray(a.astype(np.uint8))
    data = json.load(open(os.path.join(ROOT, "data", "config", "settlements.json"), encoding="utf-8"))
    rows = data["settlements"] if isinstance(data, dict) and "settlements" in data else data
    for s in rows:
        px, py = s["pos"][0] * scale - x0, s["pos"][1] * scale - y0
        if 0 <= px < W and 0 <= py < H:
            img = glow(img, px, py, 14, (255, 170, 80), 0.9)
    rider = Image.open(os.path.join(MAP, "rider", "atli_B.png")).convert("RGBA")
    rider.thumbnail((90, 90), Image.LANCZOS)
    rx, ry = W // 2 + 180, H // 2 + 120
    img = glow(img, rx + 30, ry + 20, 70, (255, 190, 110), 0.55)
    img = img.convert("RGBA")
    img.alpha_composite(rider, (rx - rider.width // 2, ry - rider.height // 2))
    return img


def camp():
    return Image.open(os.path.join(HERE, "y_g16_menu_kamp.png")).convert("RGBA")


GAME_CARD = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata", "Wayborne", "journey_shots", "02b_olay_karti_zar.png")


def event_card():
    """Kullanıcı notu (2026-10-19): olay kartının kendi arka planı olmaz, kart
    sahnenin içinde durur, olayın görseli kartın içindedir (EU4). Oyun artık
    böyle; görsel oyunun kendi ekran görüntüsü (tests/screenshot_journey_screen)."""
    if os.path.exists(GAME_CARD):
        return Image.open(GAME_CARD).convert("RGBA").resize((W, H), Image.LANCZOS)
    art = Image.open(os.path.join(WB, "e6c_bandits.jpg")).convert("RGB").resize((W, H), Image.LANCZOS)
    art = Image.blend(art, Image.new("RGB", (W, H), (10, 8, 8)), 0.35).convert("RGBA")
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    box = (W // 2 - 520, 160, W // 2 + 520, 940)
    d.rounded_rectangle(box, 8, fill=(20, 16, 14, 225), outline=(*GOLD, 220), width=2)
    art.alpha_composite(layer)
    d = ImageDraw.Draw(art)
    d.text((box[0] + 50, box[1] + 40), "Haydut Pususu", font=ImageFont.truetype(F_HEAD, 56), fill=GOLD)
    d.text((box[0] + 50, box[1] + 130), "Yolun daraldığı yerde önünüzü kestiler.\nSayıları belli değil, niyetleri belli.",
           font=ImageFont.truetype(F_BODY, 32), fill=BONE, spacing=10)
    for i, (label, combat) in enumerate([("Fidyeyi öde (120 altın)", False), ("Direnç göster  ·  tehlike %58", True),
                                         ("Pazarlığa otur  ·  Karizma", False)]):
        y = box[1] + 330 + i * 110
        d.rounded_rectangle((box[0] + 50, y, box[2] - 50, y + 84), 6, fill=(34, 30, 27), outline=(150, 120, 60))
        if combat:
            d.rectangle((box[0] + 58, y + 10, box[0] + 64, y + 74), fill=(168, 48, 43))
        d.text((box[0] + 84, y + 22), label, font=ImageFont.truetype(F_BODY, 32), fill=BONE)
    seal = Image.open(os.path.join(WB, "g9_seal.png")).convert("RGBA")
    seal.thumbnail((150, 150), Image.LANCZOS)
    art.alpha_composite(seal, (box[2] - 120, box[1] - 50))
    return art


def ledger():
    book = Image.open(os.path.join(WB, "l1_ledger.jpg")).convert("RGB").resize((W, H), Image.LANCZOS).convert("RGBA")
    d = ImageDraw.Draw(book)
    x, y = int(W * 0.14), int(H * 0.22)
    head = ImageFont.truetype(F_HEAD, 46)
    body = ImageFont.truetype(F_BODY, 30)
    d.text((x, y), "Kara Yol Kervanı", font=head, fill=INK)
    lines = [("Kurucu Hasan, babadan kalan ad", True), ("Ayşe, açlıktan, Kesgrav yolunda (gün 43)", True),
             ("Kerem adı devraldı, 2. kuşak", False), ("Murat, kurtlara, Kurt Geçidi'nde (gün 71)", True)]
    for i, (line, struck) in enumerate(lines):
        ly = y + 90 + i * 64
        d.text((x, ly), line, font=body, fill=INK)
        if struck:
            w = d.textlength(line, font=body)
            d.line((x, ly + 20, x + w, ly + 20), fill=(110, 28, 22), width=3)
    seal = Image.open(os.path.join(WB, "g9b_seal_cracked.png")).convert("RGBA")
    seal.thumbnail((300, 300), Image.LANCZOS)
    book.alpha_composite(seal, (int(W * 0.68), int(H * 0.36)))
    return book


def gate():
    g = Image.open(os.path.join(HERE, "y_122a_kapi_vastrevar.jpg")).convert("RGB").resize((W, H), Image.LANCZOS).convert("RGBA")
    sheet = json.loads(open(os.path.join(PROPS, "props.tres"), encoding="utf-8").read().split("props = ", 1)[1].rsplit("}", 1)[0] + "}")
    wagon = sheet["covered_wagon"]
    k = 0.85
    base = (int(W * 0.40), int(H * 0.93))
    # Yere basan gölge: vagon yerde dursun, havada değil.
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).ellipse((base[0] - 40, base[1] - 22, base[0] + 300, base[1] + 18), fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    g = Image.composite(Image.new("RGBA", (W, H), (8, 6, 6, 255)), g, shadow)
    for layer in ("wheel", "body", "load", "canopy", "wheel_front"):
        path = os.path.join(PROPS, "covered_wagon", layer + ".png")
        if not os.path.exists(path):
            continue
        im = Image.open(path).convert("RGBA")
        im = im.resize((int(im.width * k), int(im.height * k)), Image.LANCZOS)
        ox, oy = wagon["layers"][layer]
        at = (int(base[0] + ox * k), int(base[1] + oy * k))
        g.alpha_composite(scene_lit(im, at, g), at)
    return g


def scene_lit(im, at, scene):
    """Kullanıcı notu: kapıdaki vagonun ışığı ortama uymuyordu. Vagon artık
    sahnenin kendi ışığını alır: ortam rengi vagonun durduğu yerin ortalaması,
    kapı tarafından (resmin ortası) sıcak bir meşale kenarı, öbür yan gölgede."""
    a = np.asarray(im, np.float32) / 255.0
    h, w, _ = a.shape
    box = scene.convert("RGB").crop((max(0, at[0] - 80), max(0, at[1] - 60), at[0] + w + 80, at[1] + h + 40))
    ambient = np.asarray(box, np.float32).reshape(-1, 3).mean(axis=0) / 255.0
    ambient = np.clip(ambient / max(1e-3, ambient.max()) * min(1.0, ambient.max() * 2.2), 0.08, 1.0)
    xs = np.linspace(0, 1, w, dtype=np.float32)[None, :, None]
    toward = xs if at[0] + w / 2 < W / 2 else 1.0 - xs
    torch = np.array([1.0, 0.62, 0.30], np.float32) * (0.03 + 0.16 * toward)
    rgb = a[..., :3] * (ambient * 0.55 + torch)
    out = np.concatenate([np.clip(rgb, 0, 1), a[..., 3:]], axis=-1)
    return Image.fromarray((out * 255).astype(np.uint8))


def main():
    frames = [("1 · gece haritası, fenerli atlı", night_map()), ("2 · kamp ateşi", camp()), ("3 · olay kartı", event_card()),
              ("4 · defter ve kırık mühür", ledger()), ("5 · kapıya varış", gate())]
    tw, th, pad, label = 640, 360, 12, 34
    sheet = Image.new("RGB", (3 * (tw + pad) + pad, 2 * (th + pad + label) + pad), (14, 13, 15))
    d = ImageDraw.Draw(sheet)
    for i, (name, im) in enumerate(frames):
        x = pad + (i % 3) * (tw + pad)
        y = pad + (i // 3) * (th + pad + label)
        d.text((x, y), name, font=ImageFont.truetype(F_BODY, 22), fill=GOLD)
        sheet.paste(im.convert("RGB").resize((tw, th), Image.LANCZOS), (x, y + label))
        im.convert("RGB").save(os.path.join(HERE, f"y_g13_{i + 1}.jpg"), quality=90)
    out = os.path.join(HERE, "y_g13_bes_gorsel.png")
    sheet.save(out, quality=92)
    print("yazıldı:", out)


if __name__ == "__main__":
    main()
