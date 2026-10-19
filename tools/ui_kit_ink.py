# -*- coding: utf-8 -*-
"""Ortak UI kiti v2 (görev 9.1): Kenney UI Pack RPG Expansion ve Fantasy UI
Borders (CC0) parçaları kâğıt ve mürekkep diline boyanır.

Yalnızca biçim alınır, renk alınmaz: parçanın saydamlığı ve tonu okunur,
renk `ArtPalette`'in grim tonlarından verilir (kömür dolgu, pas çizgi, kan
rengi ana eylem). Piksel sanatı 4 kat büyütülüp hafif yumuşatılır: kenarı
basamaklı değil, mürekkep gibi. Deri, çizik ve süslü nine-slice dili
kullanılmaz (kullanıcı kararları); kenar ince ve sade kalır.

Çıktı onaydan önce oyuna girmez ("Nothing painted ships unread"):
build/ui_kit/*.png ve önizleme TODO/taslaklar/y_91_ui_kit.png.

    python -X utf8 tools/ui_kit_ink.py
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(ROOT, "art_source", "ui_kits")
OUT = os.path.join(ROOT, "build", "ui_kit")
PREVIEW = os.path.join(os.path.dirname(ROOT), "TODO", "taslaklar", "y_91_ui_kit.png")
FONT = os.path.join(ROOT, "data", "assets", "fonts", "EBGaramond.ttf")
HEAD = os.path.join(ROOT, "data", "assets", "fonts", "IMFellEnglishSC.ttf")

# ArtPalette grim tonları (0-255).
CHARCOAL = (24, 21, 20)
RUST = (122, 74, 46)
PARCHMENT = (224, 214, 190)
PARCH_DIM = (160, 150, 132)
BLOOD = (150, 42, 36)
BLOOD_HOVER = (176, 56, 46)
BLOOD_PRESSED = (110, 30, 26)
GOLD = (219, 179, 87)
SCALE = 4


def load(rel):
    return Image.open(os.path.join(KIT, rel)).convert("RGBA")


def inked(img, line, fill=None, soften=1.2):
    """Tonu iki renge çevirir: koyu pikseller çizgi, açıklar dolgu; büyütüp yumuşatır."""
    a = np.asarray(img, np.float32) / 255.0
    lum = (a[..., :3] * [0.299, 0.587, 0.114]).sum(-1)
    alpha = a[..., 3]
    t = np.clip((lum - 0.25) / 0.5, 0, 1)[..., None]
    fill_c = np.array(fill if fill else line, np.float32) / 255.0
    line_c = np.array(line, np.float32) / 255.0
    rgb = line_c * (1 - t) + fill_c * t
    out = Image.fromarray((np.concatenate([rgb, alpha[..., None]], -1) * 255).astype(np.uint8), "RGBA")
    out = out.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST).filter(ImageFilter.GaussianBlur(soften))
    return out


def nine(img, size, margin):
    """Basit nine-slice: köşeler sabit, kenarlar ve orta gerilir (önizleme için)."""
    w, h = img.size
    m = margin
    W, H = size
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    boxes = [(0, 0, m, m, 0, 0, m, m), (m, 0, w - m, m, m, 0, W - m, m), (w - m, 0, w, m, W - m, 0, W, m),
             (0, m, m, h - m, 0, m, m, H - m), (m, m, w - m, h - m, m, m, W - m, H - m), (w - m, m, w, h - m, W - m, m, W, H - m),
             (0, h - m, m, h, 0, H - m, m, H), (m, h - m, w - m, h, m, H - m, W - m, H), (w - m, h - m, w, h, W - m, H - m, W, H)]
    for sx0, sy0, sx1, sy1, dx0, dy0, dx1, dy1 in boxes:
        if sx1 > sx0 and sy1 > sy0 and dx1 > dx0 and dy1 > dy0:
            out.alpha_composite(img.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.LANCZOS), (dx0, dy0))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    pieces = {
        "panel": inked(load("kenney_fantasy_ui_borders/Panel/panel-003.png"), RUST, CHARCOAL),
        "panel_border": inked(load("kenney_fantasy_ui_borders/Border/panel-border-003.png"), RUST),
        "title_strip": inked(load("kenney_fantasy_ui_borders/Divider/divider-000.png"), RUST),
        "button_primary": inked(load("kenney_ui_rpg_expansion/buttonLong_brown.png"), (40, 14, 12), BLOOD),
        "button_primary_hover": inked(load("kenney_ui_rpg_expansion/buttonLong_brown.png"), (40, 14, 12), BLOOD_HOVER),
        "button_primary_pressed": inked(load("kenney_ui_rpg_expansion/buttonLong_brown_pressed.png"), (30, 10, 8), BLOOD_PRESSED),
        "button_primary_disabled": inked(load("kenney_ui_rpg_expansion/buttonLong_grey.png"), (50, 46, 44), (88, 80, 76)),
        "tooltip_plate": inked(load("kenney_ui_rpg_expansion/panelInset_beigeLight.png"), (90, 70, 50), PARCHMENT),
        "select_corner": inked(load("kenney_fantasy_ui_borders/Transparent center/panel-transparent-center-003.png"), GOLD),
    }
    for name, img in pieces.items():
        img.save(os.path.join(OUT, name + ".png"))
    # Önizleme
    sheet = Image.new("RGBA", (1600, 900), (16, 14, 13, 255))
    d = ImageDraw.Draw(sheet)
    head = ImageFont.truetype(HEAD, 34)
    body = ImageFont.truetype(FONT, 24)
    d.text((40, 24), "UI kiti v2 (taslak 9.1): Kenney CC0 biçimleri, Wayborne renkleri", font=head, fill=GOLD)
    panel = nine(pieces["panel"], (640, 420), 16 * SCALE // 4 * 3)
    sheet.alpha_composite(panel, (40, 100))
    strip = pieces["title_strip"].resize((560, 22), Image.LANCZOS)
    sheet.alpha_composite(strip, (80, 180))
    d.text((90, 140), "Panel ve başlık şeridi", font=body, fill=PARCHMENT)
    d.text((90, 250), "Kömür dolgu, pas çizgi; ince ve sade kenar.", font=body, fill=PARCH_DIM)
    y = 120
    for i, (key, label) in enumerate([("button_primary", "Yola çık"), ("button_primary_hover", "üstüne gelince"),
                                      ("button_primary_pressed", "basılı"), ("button_primary_disabled", "kilitli")]):
        b = nine(pieces[key], (360, 76), 12)
        sheet.alpha_composite(b, (760, y))
        tw = d.textlength(label, font=body)
        d.text((760 + 180 - tw / 2, y + 22), label, font=body, fill=PARCHMENT if i < 3 else PARCH_DIM)
        y += 100
    tip = nine(pieces["tooltip_plate"], (420, 120), 14)
    sheet.alpha_composite(tip, (1160, 120))
    d.text((1180, 140), "İpucu plakası", font=head, fill=(40, 30, 26))
    d.text((1180, 186), "Moral düşük: 2 gündür aç", font=body, fill=(40, 30, 26))
    sel = nine(pieces["select_corner"], (300, 200), 16)
    d.rounded_rectangle((1200, 320, 1500, 520), 4, fill=(30, 26, 24))
    sheet.alpha_composite(sel, (1200, 320))
    d.text((1230, 540), "Seçim köşebentleri", font=body, fill=PARCHMENT)
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    sheet.convert("RGB").save(PREVIEW, quality=92)
    print("yazıldı:", OUT, PREVIEW)


if __name__ == "__main__":
    main()
