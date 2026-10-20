# -*- coding: utf-8 -*-
"""Y-G11T: masa ekranı şablonu, pazar üzerinde görsel taslak.

Sol: tezgâh listesi. Orta: metafor nesnesi (terazi: alış ve satışın tartısı).
Sağ: kervan düzeni (vagon başına yük hücreleri). Yalnızca oyunun kendi
resimleri, yazı yüzü ve paleti kullanılır; çıktı onay için bir taslak karedir.

    python -X utf8 masa_taslak.py
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = r"D:\Users\u90238\Desktop\xx\wayborne"
WB = os.path.join(ROOT, "data", "assets", "ui", "waybook")
FONT = os.path.join(ROOT, "data", "assets", "fonts", "EBGaramond.ttf")
SHOW = os.path.join(ROOT, "data", "assets", "fonts", "GrenzeGotisch.ttf")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "y_g11t_masa_pazar.png")

W, H = 1920, 1080
INK = (14, 13, 15)
BONE = (224, 217, 199)
BONE_DIM = (158, 150, 138)
GOLD = (219, 179, 87)
BLOOD = (168, 48, 43)
PANEL = (22, 19, 17, 235)
CELL = (34, 30, 27, 255)
MOSS = (110, 140, 90)

GOODS = [
    ("item_grain.png", "Tahıl", 8, 11, "bol"),
    ("item_cloth.png", "Kumaş", 22, 18, ""),
    ("item_fish.png", "Balık (6 gün)", 9, 7, "taze"),
    ("item_wine.png", "Şarap", 31, 26, "şok"),
    ("item_furs.png", "Kürk", 40, 52, "aranan"),
    ("item_spice.png", "Baharat", 64, 58, ""),
    ("item_silk.png", "İpek", 95, 88, "nadir"),
]


def font(size, show=False):
    return ImageFont.truetype(SHOW if show else FONT, size)


def icon(name, size):
    im = Image.open(os.path.join(WB, name)).convert("RGBA")
    im.thumbnail((size, size), Image.LANCZOS)
    return im


def panel(base, box, title):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(box, 6, fill=PANEL, outline=(*GOLD[:3], 120), width=1)
    base.alpha_composite(layer)
    d = ImageDraw.Draw(base)
    d.text((box[0] + 24, box[1] + 16), title, font=font(30, True), fill=GOLD)
    d.line((box[0] + 24, box[1] + 60, box[2] - 24, box[1] + 60), fill=(*GOLD, 160), width=1)


def stall_list(base):
    box = (60, 120, 600, 960)
    panel(base, box, "Tezgâh")
    d = ImageDraw.Draw(base)
    d.text((box[0] + 24, box[1] + 72), "mal", font=font(18), fill=BONE_DIM)
    d.text((box[0] + 330, box[1] + 72), "al", font=font(18), fill=BONE_DIM)
    d.text((box[0] + 410, box[1] + 72), "sat", font=font(18), fill=BONE_DIM)
    y = box[1] + 104
    for i, (ic, name, buy, sell, mark) in enumerate(GOODS):
        if i == 3:
            d.rounded_rectangle((box[0] + 12, y - 6, box[2] - 12, y + 66), 4, outline=GOLD, width=2)
        base.alpha_composite(icon(ic, 52), (box[0] + 24, y))
        d.text((box[0] + 90, y + 6), name, font=font(24), fill=BONE)
        if mark:
            col = BLOOD if mark == "şok" else MOSS if mark in ("bol", "taze") else GOLD
            d.text((box[0] + 90, y + 34), mark, font=font(16), fill=col)
        d.text((box[0] + 330, y + 10), f"{buy}", font=font(26), fill=BONE)
        d.text((box[0] + 410, y + 10), f"{sell}", font=font(26), fill=BONE_DIM)
        y += 98
    d.text((box[0] + 24, box[3] - 44), "Kese: 312 altın   ·   fiyatların nedeni: üstüne gel", font=font(18), fill=BONE_DIM)


def scales(base):
    """Metafor nesnesi: terazi. Sol kefe alınacak mal, sağ kefe altın."""
    d = ImageDraw.Draw(base)
    cx, top = 960, 250
    ink = (*BONE, 255)
    d.line((cx, top, cx, top + 420), fill=ink, width=6)
    d.polygon([(cx - 70, top + 440), (cx + 70, top + 440), (cx + 30, top + 410), (cx - 30, top + 410)], fill=ink)
    tilt = 26
    lx, ly = cx - 220, top + 40 + tilt
    rx, ry = cx + 220, top + 40 - tilt
    d.line((lx, ly, rx, ry), fill=ink, width=5)
    d.ellipse((cx - 12, top + 28, cx + 12, top + 52), fill=GOLD)
    for px, py in ((lx, ly), (rx, ry)):
        d.line((px, py, px - 70, py + 170), fill=ink, width=2)
        d.line((px, py, px + 70, py + 170), fill=ink, width=2)
        d.chord((px - 95, py + 130, px + 95, py + 210), 0, 180, fill=(*BONE_DIM, 255), outline=ink, width=3)
    base.alpha_composite(icon("item_wine.png", 96), (lx - 48, ly + 70))
    for k in range(5):
        d.ellipse((rx - 40 + k * 14, ry + 150 - k * 6, rx - 10 + k * 14, ry + 168 - k * 6), fill=GOLD, outline=INK)
    d.text((cx - 250, top + 470), "Şarap ×6", font=font(30), fill=BONE)
    d.text((cx + 120, top + 470), "186 altın", font=font(30), fill=GOLD)
    d.text((cx - 300, top + 520), "Kefe şarapla ağır: Liraven'de 41, burada 31 (savaş şoku +%18).",
           font=font(20), fill=BONE_DIM)
    for i, (label, primary) in enumerate((("Al", True), ("Pazarlık", False), ("Vazgeç", False))):
        x0 = cx - 260 + i * 180
        d.rounded_rectangle((x0, top + 590, x0 + 160, top + 650), 5,
                            fill=BLOOD if primary else CELL, outline=GOLD if primary else BONE_DIM, width=2)
        tw = d.textlength(label, font=font(26))
        d.text((x0 + 80 - tw / 2, top + 602), label, font=font(26), fill=BONE)


def caravan(base):
    box = (1320, 120, 1860, 960)
    panel(base, box, "Kervan")
    d = ImageDraw.Draw(base)
    wagons = [
        ("1. vagon · Ali'nin", 0.82, ["item_grain.png", "item_grain.png", "item_cloth.png", "item_provisions.png",
                                      "item_provisions.png", "item_bandage.png", None, None]),
        ("2. vagon · Selin'in", 0.46, ["item_furs.png", "item_furs.png", "item_fish.png", None, None, None, None, None]),
        ("3. vagon · kontrat (Merigaud)", 1.0, ["item_spice.png"] * 6 + ["item_silk.png"] * 2),
    ]
    y = box[1] + 80
    for title, load, cells in wagons:
        d.text((box[0] + 24, y), title, font=font(22), fill=BONE)
        d.rectangle((box[0] + 24, y + 34, box[2] - 24, y + 42), fill=CELL)
        d.rectangle((box[0] + 24, y + 34, box[0] + 24 + (box[2] - box[0] - 48) * load, y + 42),
                    fill=BLOOD if load >= 0.95 else GOLD)
        for k, c in enumerate(cells):
            cx0 = box[0] + 24 + (k % 4) * 124
            cy0 = y + 54 + (k // 4) * 84
            d.rounded_rectangle((cx0, cy0, cx0 + 112, cy0 + 74), 4, fill=CELL, outline=(*BONE_DIM, 255), width=1)
            if c:
                base.alpha_composite(icon(c, 58), (cx0 + 27, cy0 + 8))
        y += 236
    d.text((box[0] + 24, box[3] - 44), "Mal hangi vagona girecek: sürükle ya da oklarla", font=font(18), fill=BONE_DIM)


def main():
    bg = Image.open(os.path.join(WB, "b2_market.jpg")).convert("RGB").resize((W, H), Image.LANCZOS)
    bg = bg.filter(ImageFilter.GaussianBlur(3))
    base = Image.blend(bg, Image.new("RGB", (W, H), INK), 0.62).convert("RGBA")
    d = ImageDraw.Draw(base)
    d.text((60, 40), "Pazar · Belvanor", font=font(44, True), fill=GOLD)
    d.text((1460, 54), "taslak - Y-G11T masa şablonu", font=font(20), fill=BONE_DIM)
    stall_list(base)
    scales(base)
    caravan(base)
    base.convert("RGB").save(OUT, quality=92)
    print("yazıldı:", OUT)


if __name__ == "__main__":
    main()
