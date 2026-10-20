# -*- coding: utf-8 -*-
"""Y-G11T v2 (kullanıcı geri bildirimi 2026-10-19):
- kefedeki mal ve altın bir mühür/daire içinde, havada durmuyor;
- terazi denge değiştikçe eğilir (altın artınca sağ iner, mal değeri artınca sol iner);
- vagonlarda yuva VE ağırlık sınırı; her malın ağırlığı tezgâh listesinde.

Ağırlıklar ItemCatalog'dan (şarap 1.8, ipek 0.6, kürk 2.0, tahıl 1.0, kumaş 1.5, baharat 0.4, balık 1.0),
vagon sınırı GameSession.CARGO_PER_WAGON = 50.

    python -X utf8 masa_taslak_v2.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

import masa_taslak as m

HERE = os.path.dirname(os.path.abspath(__file__))
font, icon, panel = m.font, m.icon, m.panel
BONE, BONE_DIM, GOLD, BLOOD, INK, CELL, MOSS = m.BONE, m.BONE_DIM, m.GOLD, m.BLOOD, m.INK, m.CELL, m.MOSS
W, H = m.W, m.H
GOLD_DIM = (150, 120, 60)

# (simge, ad, al, sat, işaret, birim ağırlık)
GOODS = [
    ("item_grain.png", "Tahıl", 8, 11, "bol", 1.0),
    ("item_cloth.png", "Kumaş", 22, 18, "", 1.5),
    ("item_fish.png", "Balık (6 gün)", 9, 7, "taze", 1.0),
    ("item_wine.png", "Şarap", 31, 26, "şok", 1.8),
    ("item_furs.png", "Kürk", 40, 52, "aranan", 2.0),
    ("item_spice.png", "Baharat", 64, 58, "", 0.4),
    ("item_silk.png", "İpek", 95, 88, "nadir", 0.6),
]
WAGONS = [  # ad, yuva dolu, yuva toplam, ağırlık, hücreler
    ("1. vagon · Ali'nin", 6, 8, 31.0, ["item_grain.png", "item_grain.png", "item_cloth.png", "item_provisions.png", "item_provisions.png", "item_bandage.png", None, None]),
    ("2. vagon · Selin'in", 3, 8, 17.0, ["item_furs.png", "item_furs.png", "item_fish.png", None, None, None, None, None]),
    ("3. vagon · kontrat", 8, 8, 49.6, ["item_spice.png"] * 6 + ["item_silk.png"] * 2),
]
LIMIT = 50.0


def seal_pan(base, cx, cy, r, content):
    """Kefe: mühür gibi yuvarlak bir levha; içindekiler dairenin içinde durur."""
    d = ImageDraw.Draw(base)
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse((cx - r, cy - r + 10, cx + r, cy + r + 10), fill=(0, 0, 0, 110))
    base.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(8)))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(44, 32, 24, 255), outline=GOLD_DIM, width=4)
    d.ellipse((cx - r + 12, cy - r + 12, cx + r - 12, cy + r - 12), outline=(*GOLD_DIM, 255), width=2)
    d.ellipse((cx - r + 22, cy - r + 22, cx + r - 22, cy + r - 22), fill=(30, 23, 18, 255))
    content(base, cx, cy, r)


def wine_content(base, cx, cy, r):
    ic = icon("item_wine.png", int(r * 1.15))
    base.alpha_composite(ic, (cx - ic.width // 2, cy - ic.height // 2 - 6))
    ImageDraw.Draw(base).text((cx - 28, cy + r - 52), "×6", font=font(26), fill=BONE)


def coin_content(base, cx, cy, r):
    d = ImageDraw.Draw(base)
    for k in range(7):
        a = k * 2.4
        x = cx + math.cos(a) * r * 0.32 * (k % 3) * 0.7
        y = cy + math.sin(a) * r * 0.22 * (k % 3) * 0.7 + 18 - k * 4
        d.ellipse((x - 26, y - 10, x + 26, y + 10), fill=GOLD, outline=INK, width=2)
    d.text((cx - 40, cy + r - 52), "186", font=font(26), fill=GOLD)


def scales(base, cx, top, goods_value, gold, label=True, small=False):
    """Terazi: sol kefe malın değeri, sağ kefe ödenen altın. Ağır olan taraf iner."""
    d = ImageDraw.Draw(base)
    k = 0.55 if small else 1.0
    ink = (*BONE, 255)
    diff = (goods_value - gold) / max(goods_value, gold, 1)  # + sol ağır
    tilt = max(-1.0, min(1.0, diff * 4.0)) * 34 * k
    arm = 230 * k
    r = int(86 * k)
    hang = 150 * k
    pivot = (cx, top + 40 * k)
    d.line((cx, pivot[1], cx, pivot[1] + 400 * k), fill=ink, width=max(3, int(6 * k)))
    d.polygon([(cx - 70 * k, pivot[1] + 420 * k), (cx + 70 * k, pivot[1] + 420 * k), (cx + 30 * k, pivot[1] + 390 * k), (cx - 30 * k, pivot[1] + 390 * k)], fill=ink)
    lx, ly = cx - arm, pivot[1] + tilt
    rx, ry = cx + arm, pivot[1] - tilt
    d.line((lx, ly, rx, ry), fill=ink, width=max(3, int(5 * k)))
    d.ellipse((cx - 12 * k, pivot[1] - 12 * k, cx + 12 * k, pivot[1] + 12 * k), fill=GOLD)
    for px, py, content in ((lx, ly, wine_content), (rx, ry, coin_content)):
        pcy = py + hang + r
        for a in (-0.9, 0.0, 0.9):  # üç zincir mührün üst kenarına
            ex = px + math.sin(a) * r * 0.95
            ey = pcy - math.cos(a) * r * 0.95
            d.line((px, py, ex, ey), fill=(*BONE_DIM, 255), width=max(1, int(2 * k)))
        d.ellipse((px - 5, py - 5, px + 5, py + 5), fill=GOLD)
        if small:
            seal_small(base, px, pcy, r)
        else:
            seal_pan(base, int(px), int(pcy), r, content)
    return tilt


def seal_small(base, cx, cy, r):
    d = ImageDraw.Draw(base)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(44, 32, 24, 255), outline=GOLD_DIM, width=3)
    d.ellipse((cx - r + 8, cy - r + 8, cx + r - 8, cy + r - 8), fill=(30, 23, 18, 255))


def stall(base):
    box = (60, 120, 640, 960)
    panel(base, box, "Tezgâh")
    d = ImageDraw.Draw(base)
    for x, t in ((box[0] + 330, "al"), (box[0] + 410, "sat"), (box[0] + 490, "ağ.")):
        d.text((x, box[1] + 72), t, font=font(18), fill=BONE_DIM)
    d.text((box[0] + 24, box[1] + 72), "mal", font=font(18), fill=BONE_DIM)
    y = box[1] + 104
    for i, (ic, name, buy, sell, mark, wt) in enumerate(GOODS):
        if i == 3:
            d.rounded_rectangle((box[0] + 12, y - 6, box[2] - 12, y + 66), 4, outline=GOLD, width=2)
        base.alpha_composite(icon(ic, 52), (box[0] + 24, y))
        d.text((box[0] + 90, y + 6), name, font=font(24), fill=BONE)
        if mark:
            col = BLOOD if mark == "şok" else MOSS if mark in ("bol", "taze") else GOLD
            d.text((box[0] + 90, y + 34), mark, font=font(16), fill=col)
        d.text((box[0] + 330, y + 10), f"{buy}", font=font(26), fill=BONE)
        d.text((box[0] + 410, y + 10), f"{sell}", font=font(26), fill=BONE_DIM)
        d.text((box[0] + 490, y + 10), f"{wt:g}", font=font(24), fill=BONE_DIM)
        y += 104
    d.text((box[0] + 24, box[3] - 44), "Kese: 312 altın · ağ.: birim ağırlık · fiyat nedeni: üstüne gel", font=font(17), fill=BONE_DIM)


def caravan(base):
    box = (1300, 120, 1880, 960)
    panel(base, box, "Kervan")
    d = ImageDraw.Draw(base)
    y = box[1] + 76
    for title, used, total, weight, cells in WAGONS:
        d.text((box[0] + 24, y), title, font=font(22), fill=BONE)
        full_slots, full_w = used >= total, weight / LIMIT >= 0.95
        d.text((box[0] + 330, y + 2), f"yuva {used}/{total}", font=font(19), fill=BLOOD if full_slots else BONE_DIM)
        d.text((box[0] + 440, y + 2), f"ağırlık {weight:g}/{LIMIT:g}", font=font(19), fill=BLOOD if full_w else BONE_DIM)
        d.rectangle((box[0] + 24, y + 36, box[2] - 24, y + 42), fill=CELL)
        d.rectangle((box[0] + 24, y + 36, box[0] + 24 + (box[2] - box[0] - 48) * min(1.0, weight / LIMIT), y + 42), fill=BLOOD if full_w else GOLD)
        for k, c in enumerate(cells):
            cx0 = box[0] + 24 + (k % 4) * 136
            cy0 = y + 54 + (k // 4) * 82
            d.rounded_rectangle((cx0, cy0, cx0 + 124, cy0 + 72), 4, fill=CELL, outline=(*BONE_DIM, 255), width=1)
            if c:
                base.alpha_composite(icon(c, 54), (cx0 + 35, cy0 + 8))
        y += 240
    d.text((box[0] + 24, box[3] - 40), "Hem yuva hem ağırlık sınırı var; hangisi önce dolarsa o bağlar", font=font(17), fill=BONE_DIM)


def main():
    bg = Image.open(os.path.join(m.WB, "b2_market.jpg")).convert("RGB").resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(3))
    base = Image.blend(bg, Image.new("RGB", (W, H), INK), 0.62).convert("RGBA")
    d = ImageDraw.Draw(base)
    d.text((60, 40), "Pazar · Belvanor", font=m.font(44, True), fill=GOLD)
    d.text((1420, 54), "taslak v2 - Y-G11T masa şablonu", font=font(20), fill=BONE_DIM)
    stall(base)
    scales(base, 970, 200, 246, 186)
    d.text((700, 760), "Şarap ×6  ·  ağırlık 10,8", font=font(30), fill=BONE)
    d.text((870, 806), "Mal değeri 246, ödenen 186: kefe şarapla ağır, kâr var.", font=font(20), fill=BONE_DIM)
    d.text((700, 836), "Vagon 3'te yer yok: 49,6/50; vagon 1'e 4 birim sığar.", font=font(20), fill=BLOOD)
    for i, (label, primary) in enumerate((("Al", True), ("Pazarlık", False), ("Vazgeç", False))):
        x0 = 700 + i * 180
        d.rounded_rectangle((x0, 880, x0 + 160, 940), 5, fill=BLOOD if primary else CELL, outline=GOLD if primary else BONE_DIM, width=2)
        tw = d.textlength(label, font=font(26))
        d.text((x0 + 80 - tw / 2, 892), label, font=font(26), fill=BONE)
    caravan(base)
    base.convert("RGB").save(os.path.join(HERE, "y_g11t_masa_pazar_v2.png"), quality=92)

    # Terazinin üç hâli
    sheet = Image.new("RGBA", (1500, 560), (16, 14, 13, 255))
    sd = ImageDraw.Draw(sheet)
    sd.text((30, 20), "Terazi altın ve mal değeriyle eğilir", font=m.font(36, True), fill=GOLD)
    for i, (title, gv, gold) in enumerate((("pazarlıkla altın düştü: mal ağır (kâr)", 246, 150), ("fiyat = değer: denge", 186, 186),
                                          ("altın arttı: altın ağır (zarar)", 150, 230))):
        cx = 260 + i * 490
        scales(sheet, cx, 90, gv, gold, small=True)
        sd.text((cx - 190, 500), title, font=font(22), fill=BONE)
    sheet.convert("RGB").save(os.path.join(HERE, "y_g11t_terazi_durumlari.png"), quality=92)
    print("yazıldı")


if __name__ == "__main__":
    main()
