# -*- coding: utf-8 -*-
"""P12 arayüz taslakları (9.4, 9.5, 9.6, 9.7, 9.8 + Y-G05, 9.9, 9.11).

Hepsi oyunun kendi resimleri, gövde ve hayvan kareleri, yazı yüzleri ve
paletiyle; her biri onay için tek bir karedir, oyun kodu değil.

    python -X utf8 arayuz_taslaklari.py [hepsi|94|95|96|97|98|99|911]
"""
import os
import sys

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

import sehir_halk_taslak as people

ROOT = r"D:\Users\u90238\Desktop\xx\wayborne"
WB = os.path.join(ROOT, "data", "assets", "ui", "waybook")
ROAD = os.path.join(ROOT, "data", "assets", "ui", "road")
FONTS = os.path.join(ROOT, "data", "assets", "fonts")
HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 1920, 1080

INK = (14, 13, 15)
BONE = (224, 217, 199)
BONE_DIM = (158, 150, 138)
GOLD = (219, 179, 87)
GOLD_DIM = (150, 120, 60)
BLOOD = (168, 48, 43)
MOSS = (110, 140, 90)
PANEL = (22, 19, 17, 235)
CELL = (34, 30, 27, 255)


def body(size):
    return ImageFont.truetype(os.path.join(FONTS, "EBGaramond.ttf"), size)


def head(size):
    return ImageFont.truetype(os.path.join(FONTS, "IMFellEnglishSC.ttf"), size)


def icon(name, size):
    im = Image.open(os.path.join(WB, name)).convert("RGBA")
    im.thumbnail((size, size), Image.LANCZOS)
    return im


def backdrop(name, dim=0.62, blur=3):
    bg = Image.open(os.path.join(WB, name)).convert("RGB").resize((W, H), Image.LANCZOS)
    if blur:
        bg = bg.filter(ImageFilter.GaussianBlur(blur))
    return Image.blend(bg, Image.new("RGB", (W, H), INK), dim).convert("RGBA")


def panel(base, box, title=None, outline=GOLD, alpha=120):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(box, 6, fill=PANEL, outline=(*outline, alpha), width=1)
    base.alpha_composite(layer)
    if title:
        d = ImageDraw.Draw(base)
        d.text((box[0] + 24, box[1] + 14), title, font=head(30), fill=GOLD)
        d.line((box[0] + 24, box[1] + 58, box[2] - 24, box[1] + 58), fill=GOLD_DIM, width=1)


def bar(d, x, y, w, share, col, h=8, notches=0):
    d.rectangle((x, y, x + w, y + h), fill=CELL)
    d.rectangle((x, y, x + int(w * share), y + h), fill=col)
    for k in range(1, notches):
        nx = x + w * k / notches
        d.line((nx, y - 3, nx, y + h + 3), fill=INK, width=2)


def figure(gender="male", garments=None, clip="idle", frame=0, scale=1.0, skin=(205, 160, 120)):
    garments = garments or (["peasant_pants", "short_boots", "laced_shirt", "leather_vest"] if gender == "male"
                            else ["long_skirt", "peasant_shoes", "peasant_blouse"])
    fig = people.figure("body_%s_average" % gender, clip, frame, skin, garments)
    bbox = fig.getbbox()
    fig = fig.crop(bbox)
    return fig.resize((int(fig.width * scale), int(fig.height * scale)), Image.LANCZOS)


def beast(name, clip="idle", frame=0, scale=1.0):
    fr = people.frames(name)
    canvas = Image.new("RGBA", (400, 330), (0, 0, 0, 0))
    for layer in range(5):
        people.put(canvas, fr, clip, frame, layer, 0)
    canvas = canvas.crop(canvas.getbbox())
    return canvas.resize((int(canvas.width * scale), int(canvas.height * scale)), Image.LANCZOS)


def stamp(base, text):
    ImageDraw.Draw(base).text((W - 420, 40), text, font=body(20), fill=BONE_DIM)


def save(base, name):
    out = os.path.join(HERE, name)
    base.convert("RGB").save(out, quality=90)
    print("yazıldı:", out)


# ------------------------------------------------------------------ 9.4
def venue():
    base = backdrop("b3_tavern.jpg", 0.55)
    d = ImageDraw.Draw(base)
    d.text((60, 40), "Taverna · Vastrevar", font=head(46), fill=GOLD)
    stamp(base, "taslak 9.4 - mekân iskeleti")
    # Sol: büyük sahip portresi (taslakta figürün yakın planı).
    panel(base, (60, 130, 560, 980), "Hanci Oswin")
    owner = figure("male", ["wool_pants", "leather_boots", "linen_tunic", "leather_vest"], scale=3.2)
    owner = ImageEnhance.Brightness(owner).enhance(0.9)
    base.alpha_composite(owner.crop((0, 0, owner.width, min(owner.height, 600))), (310 - owner.width // 2, 220))
    d.text((84, 860), "\"Yollardan ne haber? Söylentinin de fiyatı var.\"", font=body(22), fill=BONE)
    d.text((84, 900), "Huyu: kurnaz · Seninle: tanışık (2 ziyaret)", font=body(19), fill=BONE_DIM)
    # Orta: mimariden türeyen yuvalar - tavernada fıçılar.
    slots = [("Söylenti", "item_wine.png", "18 altın"), ("Ziyafet", "item_honey.png", "kişi başı 6"),
             ("Yolcu tut", "item_cloth.png", "2 aday"), ("Arınma", "item_potion.png", "taze huy")]
    for i, (label, ic, sub) in enumerate(slots):
        cx, cy = 820 + (i % 2) * 320, 340 + (i // 2) * 330
        d.ellipse((cx - 120, cy - 120, cx + 120, cy + 120), fill=(46, 34, 24), outline=GOLD_DIM, width=3)
        for k in (-60, 0, 60):
            d.arc((cx - 120, cy - 120 + k * 0.2, cx + 120, cy + 120 + k * 0.2), 200, 340, fill=(70, 52, 36), width=2)
        base.alpha_composite(icon(ic, 96), (cx - 48, cy - 70))
        tw = d.textlength(label, font=head(30))
        d.text((cx - tw / 2, cy + 36), label, font=head(30), fill=BONE)
        sw = d.textlength(sub, font=body(20))
        d.text((cx - sw / 2, cy + 74), sub, font=body(20), fill=BONE_DIM)
    # Sağ: kervanın durumu, kararı kolaylaştıran sayılar.
    panel(base, (1380, 130, 1860, 980), "Kervan")
    rows = [("Kese", "312 altın"), ("Stres (ortalama)", "41"), ("En yorgun", "Selin, 63"), ("Erzak", "26 gün"),
            ("Borç", "240, 34 gün"), ("İtibar", "12")]
    for i, (k, v) in enumerate(rows):
        d.text((1404, 210 + i * 56), k, font=body(22), fill=BONE_DIM)
        d.text((1700, 210 + i * 56), v, font=body(22), fill=BONE)
    d.rounded_rectangle((1404, 900, 1836, 954), 5, fill=CELL, outline=BONE_DIM)
    d.text((1560, 910), "Geri: Şehir", font=body(24), fill=BONE)
    save(base, "y_94_mekan.png")


# ------------------------------------------------------------------ 9.5
def market_b():
    base = backdrop("b2_market.jpg", 0.6)
    d = ImageDraw.Draw(base)
    d.text((60, 40), "Pazar · Belvanor", font=head(46), fill=GOLD)
    stamp(base, "taslak 9.5 - üstte mal, altta kervan")
    goods = [("item_grain.png", "Tahıl", 8, "bol"), ("item_cloth.png", "Kumaş", 22, ""), ("item_fish.png", "Balık", 9, "taze"),
             ("item_wine.png", "Şarap", 31, "şok"), ("item_furs.png", "Kürk", 40, "aranan"), ("item_spice.png", "Baharat", 64, ""),
             ("item_silk.png", "İpek", 95, "nadir"), ("item_provisions.png", "Erzak", 3, "")]
    for i, (ic, name, price, mark) in enumerate(goods):
        x, y = 60 + i * 227, 140
        sel = i == 3
        d.rounded_rectangle((x, y, x + 212, y + 300), 6, fill=(26, 22, 19), outline=GOLD if sel else GOLD_DIM, width=2 if sel else 1)
        base.alpha_composite(icon(ic, 110), (x + 51, y + 26))
        d.text((x + 18, y + 150), name, font=head(28), fill=BONE)
        d.text((x + 18, y + 192), f"{price} altın", font=body(26), fill=GOLD)
        if mark:
            d.text((x + 18, y + 232), mark, font=body(19), fill=BLOOD if mark == "şok" else MOSS if mark in ("bol", "taze") else GOLD)
    panel(base, (60, 480, 1860, 1000), "Kervanın yükü")
    for w in range(3):
        x0 = 84 + w * 594
        d.text((x0, 556), ["1. vagon · Ali", "2. vagon · Selin", "3. vagon · kontrat"][w], font=body(22), fill=BONE)
        bar(d, x0, 590, 540, [0.8, 0.45, 1.0][w], BLOOD if w == 2 else GOLD)
        for k in range(10):
            cx, cy = x0 + (k % 5) * 110, 616 + (k // 5) * 110
            d.rounded_rectangle((cx, cy, cx + 100, cy + 100), 4, fill=CELL, outline=BONE_DIM)
            if (w, k) in {(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4)}:
                ic = ["item_grain.png", "item_furs.png", "item_spice.png"][w]
                base.alpha_composite(icon(ic, 70), (cx + 15, cy + 15))
    d.text((84, 940), "Şarap ×6 seçili · 186 altın · Liraven'de 41 (savaş şoku +%18) · sürükle: hangi vagona", font=body(22), fill=BONE_DIM)
    save(base, "y_95_pazar_ust_alt.png")


# ------------------------------------------------------------------ 9.6
def character():
    base = backdrop("b9_tent.jpg", 0.66)
    d = ImageDraw.Draw(base)
    d.text((60, 40), "Selin Kaya", font=head(46), fill=GOLD)
    d.text((60, 98), "Sekban · 4. seviye · vadi loncaları", font=body(24), fill=BONE_DIM)
    stamp(base, "taslak 9.6 - üç sütun")
    panel(base, (60, 150, 620, 1000), "Kimlik")
    fig = figure("female", ["ranger_pants", "ranger_boots", "ranger_jacket", "ranger_hood"], scale=2.8,
                 skin=(236, 200, 170))
    base.alpha_composite(fig, (340 - fig.width // 2, 230))
    for i, line in enumerate(["171 cm · ince", "Geçmişi: borçlu bir dokumacının kızı", "Amacı: babasının tezgâhını geri almak",
                              "Seninle: dost (yakınlık 3)"]):
        d.text((84, 800 + i * 40), line, font=body(21), fill=BONE if i == 0 else BONE_DIM)
    panel(base, (660, 150, 1260, 1000), "Huylar ve statlar")
    stats = [("p3_strength.png", "Güç", 5), ("p3_agility.png", "Çeviklik", 9), ("p3_endurance.png", "Dayanıklılık", 6),
             ("p3_intellect.png", "Zeka", 6), ("p3_perception.png", "Sezgi", 11), ("p3_charisma.png", "Karizma", 4),
             ("p3_wisdom.png", "Bilgelik", 5), ("p3_faith.png", "İnanç", 3)]
    for i, (ic, name, v) in enumerate(stats):
        y = 236 + i * 62
        base.alpha_composite(icon(ic, 44), (690, y))
        d.text((748, y + 6), name, font=body(24), fill=BONE)
        bar(d, 930, y + 18, 240, v / 15, GOLD, notches=3)
        d.text((1190, y + 6), str(v), font=body(24), fill=BONE)
    d.text((690, 760), "Huylar", font=head(26), fill=GOLD)
    for i, (ic, name) in enumerate([("p2_virtue.png", "Keskin göz"), ("p2_affliction.png", "Kuşkucu")]):
        base.alpha_composite(icon(ic, 44), (690, 806 + i * 60))
        d.text((748, 812 + i * 60), name, font=body(24), fill=BONE)
    panel(base, (1300, 150, 1860, 1000), "Beceriler ve dirençler")
    skills = [("Nişan", 60), ("Geri adım", 35), ("Ayak bağı", 20)]
    for i, (name, prof) in enumerate(skills):
        y = 236 + i * 70
        d.text((1330, y), name, font=body(24), fill=BONE)
        bar(d, 1560, y + 14, 260, prof / 100, MOSS)
    for i, (ic, name, v) in enumerate([("k4a_bleed.png", "Kanama", 40), ("k4b_blight.png", "Zehir", 35),
                                       ("k4c_stun.png", "Sersemleme", 30), ("k4g_burn.png", "Yanma", 40)]):
        y = 500 + i * 66
        base.alpha_composite(icon(ic, 40), (1330, y))
        d.text((1384, y + 4), name, font=body(23), fill=BONE)
        d.text((1760, y + 4), f"%{v}", font=body(23), fill=BONE)
    d.text((1330, 800), "Can 34/38 · Stres 63 · Yorgun", font=body(22), fill=BLOOD)
    save(base, "y_96_karakter.png")


# ------------------------------------------------------------------ 9.7
def roster():
    base = backdrop("b8_recruit.jpg", 0.7)
    d = ImageDraw.Draw(base)
    d.text((60, 40), "Kadro kartı ve seviye rozeti", font=head(46), fill=GOLD)
    stamp(base, "taslak 9.7 - durumlar")
    states = [("Kerem", "lider", "normal", 1.0, (205, 160, 120), "male"),
              ("Selin", "seçili", "selected", 0.9, (236, 200, 170), "female"),
              ("Ali", "yaralı", "wounded", 0.35, (160, 112, 78), "male"),
              ("Derya", "ölümün kıyısı", "door", 0.0, (110, 74, 52), "female")]
    for i, (name, label, state, hp, skin, g) in enumerate(states):
        x, y = 120 + i * 440, 200
        outline = GOLD if state == "selected" else BLOOD if state == "door" else GOLD_DIM
        d.rounded_rectangle((x, y, x + 380, y + 640), 8, fill=(24, 20, 18), outline=outline, width=3 if state == "selected" else 2)
        fig = figure(g, scale=1.9, skin=skin)
        if state in ("wounded", "door"):
            fig = ImageEnhance.Brightness(fig).enhance(0.7 if state == "wounded" else 0.45)
        base.alpha_composite(fig, (x + 190 - fig.width // 2, y + 40))
        # Seviye rozeti: mühür halkası, rakam ortada.
        d.ellipse((x + 300, y + 20, x + 360, y + 80), fill=(40, 30, 20), outline=GOLD, width=3)
        d.text((x + 322, y + 30), str([5, 4, 3, 2][i]), font=head(32), fill=GOLD)
        d.text((x + 24, y + 470), name, font=head(34), fill=BONE)
        d.text((x + 24, y + 516), label, font=body(22), fill=BLOOD if state in ("wounded", "door") else BONE_DIM)
        bar(d, x + 24, y + 560, 330, hp, BLOOD if hp < 0.4 else MOSS, h=10)
        bar(d, x + 24, y + 590, 330, [0.2, 0.63, 0.5, 0.8][i], GOLD_DIM, h=6)
        if state == "door":
            d.line((x + 20, y + 494, x + 200, y + 494), fill=BLOOD, width=3)
    d.text((120, 900), "Yeşil can, kehribar stres. Seçili kart altın kenar; ölümün kıyısında kenar kan rengi ve ad üstü çizgi.",
           font=body(24), fill=BONE_DIM)
    save(base, "y_97_kadro_karti.png")


# ------------------------------------------------------------------ 9.8 + Y-G05
def combat():
    # Biyom plakası: yolun kendi şeritleri (orman), koyu.
    base = Image.new("RGBA", (W, H), (30, 30, 36, 255))
    for name, top, ratio in (("far", 240, 1.5), ("mid", 300, 3.4), ("ground", 420, 2.17)):
        tex = Image.open(os.path.join(ROAD, "forest", name + ".png")).convert("RGBA")
        k = H * ratio / tex.width * 0.9
        tile = tex.resize((int(tex.width * k), int(tex.height * k)), Image.LANCZOS)
        tile = Image.merge("RGBA", (*ImageEnhance.Brightness(tile.convert("RGB")).enhance(0.55).split(), tile.split()[3]))
        x = 0
        while x < W:
            base.alpha_composite(tile, (x, top))
            x += tile.width
    d = ImageDraw.Draw(base)
    stamp(base, "taslak 9.8 + Y-G05 - savaş ekranı")
    # Figürler ekran yüksekliğinin ~%32'si.
    target_h = int(H * 0.32)
    party = [("male", ["peasant_pants", "leather_boots", "quilted_tunic"], "stance_melee"),
             ("female", ["ranger_pants", "ranger_boots", "ranger_jacket", "ranger_hood"], "stance_bow"),
             ("male", ["wool_pants", "short_boots", "laced_shirt", "leather_vest"], "idle")]
    for i, (g, gar, clip) in enumerate(party):
        fig = figure(g, gar, clip=clip)
        fig = fig.resize((int(fig.width * target_h / fig.height), target_h), Image.LANCZOS)
        base.alpha_composite(fig, (720 - i * 230 - fig.width // 2, 720 - target_h))
    for i in range(3):
        wolf = beast("beast_wolf", "idle").transpose(Image.FLIP_LEFT_RIGHT)
        wolf = wolf.resize((int(wolf.width * target_h * 0.45 / wolf.height), int(target_h * 0.45)), Image.LANCZOS)
        base.alpha_composite(wolf, (1150 + i * 290 - wolf.width // 2, 720 - wolf.height + i * 6))
    # Kritik mührü hedefin üstünde.
    seal = icon("g9_seal.png", 150)
    seal = Image.merge("RGBA", (*Image.blend(seal.convert("RGB"), Image.new("RGB", seal.size, BLOOD), 0.5).split(), seal.split()[3]))
    base.alpha_composite(seal, (1060, 330))
    d.text((1090, 490), "KRİTİK", font=head(34), fill=BLOOD)
    # Tur madalyonu.
    d.ellipse((900, 40, 1020, 160), fill=(30, 24, 18), outline=GOLD, width=4)
    d.text((928, 62), "III", font=head(54), fill=GOLD)
    d.text((918, 166), "3. tur", font=body(22), fill=BONE_DIM)
    # Alt panel: solda aktif üye, sağda hedef kartı.
    panel(base, (40, 780, 940, 1050), "Selin · Sekban")
    for i, (sk, ok) in enumerate([("Nişan", True), ("Geri adım", True), ("Ayak bağı", False), ("Bandaj ×2", True)]):
        x = 64 + i * 214
        d.rounded_rectangle((x, 850, x + 200, 960), 5, fill=CELL if ok else (24, 22, 20), outline=GOLD if i == 0 else BONE_DIM)
        d.text((x + 16, 870), sk, font=body(24), fill=BONE if ok else BONE_DIM)
        d.text((x + 16, 910), "isabet %78" if ok else "sıra 3-4'ten", font=body(18), fill=BONE_DIM)
    panel(base, (980, 780, 1880, 1050), "Hedef: Kurt (sıra 1)")
    bar(d, 1004, 860, 600, 0.3, BLOOD, h=12)
    d.text((1004, 890), "Can 7/24 · koruma 0 · kanıyor (2 tur)", font=body(22), fill=BONE)
    d.text((1004, 930), "Davranış: en zayıf canı kovalar", font=body(20), fill=BONE_DIM)
    save(base, "y_98_savas.png")


# ------------------------------------------------------------------ 9.9
def hud():
    base = Image.open(os.path.join(HERE, "y_122e_yol_isik.png")).convert("RGB")
    base = base.crop((504, 52, 984, 322)).resize((W, H), Image.LANCZOS).convert("RGBA")
    d = ImageDraw.Draw(base)
    stamp(base, "taslak 9.9 - ince göstergeler")
    gauges = [("r4a_morale.png", "Moral", 0.72, MOSS), ("r4b_stress.png", "Stres", 0.41, GOLD),
              ("r4_vial.png", "Takat", 0.58, (120, 150, 190)), ("r7c_smoke.png", "Tehlike", 0.38, BLOOD)]
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle((1440, 30, 1890, 270), 6, fill=(14, 12, 12, 200), outline=(*GOLD_DIM, 160))
    base.alpha_composite(layer)
    for i, (ic, name, v, col) in enumerate(gauges):
        y = 52 + i * 54
        base.alpha_composite(icon(ic, 36), (1460, y))
        d.text((1506, y + 2), name, font=body(22), fill=BONE)
        bar(d, 1620, y + 14, 200, v, col, h=6, notches=4)
        d.text((1832, y + 2), str(int(v * 100)), font=body(22), fill=BONE)
    d.text((1460, 268 - 24), "çentik = olay eşiği", font=body(16), fill=BONE_DIM)
    save(base, "y_99_yol_hud.png")


# ------------------------------------------------------------------ 9.11
def fallen():
    book = Image.open(os.path.join(WB, "l1_ledger.jpg")).convert("RGB")
    book = book.resize((W, int(book.height * W / book.width)), Image.LANCZOS)
    base = Image.new("RGBA", (W, H), (*INK, 255))
    base.alpha_composite(book.convert("RGBA"), (0, (H - book.height) // 2))
    d = ImageDraw.Draw(base)
    ink = (40, 30, 26)
    ox, oy = int(W * 0.13), (H - book.height) // 2 + int(book.height * 0.14)
    d.text((ox, oy), "Düşenler", font=head(46), fill=ink)
    fallen = [("Kurucu Hasan", "kurucu", "babadan kalan ad", 3), ("Ayşe", "lider, 1. kuşak", "açlıktan, Kesgrav yolunda (gün 43)", 2),
              ("Murat", "sekban", "kurtlara, Kurt Geçidi'nde (gün 71)", 1), ("Elif", "tayfa", "vagonla birlikte, sel (gün 90)", 0)]
    for i, (name, rank, cause, deco) in enumerate(fallen):
        y = oy + 90 + i * 120
        # Mezar işareti: rütbe arttıkça süs artar (taş, taş+çizgi, taş+çizgi+halka).
        cx = ox + 30
        d.rectangle((cx - 14, y + 10, cx + 14, y + 60), outline=ink, width=3)
        d.arc((cx - 14, y - 4, cx + 14, y + 24), 180, 360, fill=ink, width=3)
        if deco >= 1:
            d.line((cx - 8, y + 34, cx + 8, y + 34), fill=ink, width=2)
        if deco >= 2:
            d.ellipse((cx - 22, y - 10, cx + 22, y + 70), outline=ink, width=1)
        if deco >= 3:
            d.line((cx - 26, y + 66, cx + 26, y + 66), fill=ink, width=3)
        d.text((ox + 80, y), name, font=head(34), fill=ink)
        tw = d.textlength(name, font=head(34))
        d.line((ox + 80, y + 22, ox + 80 + tw, y + 22), fill=(90, 30, 26), width=2)
        d.text((ox + 80, y + 44), f"{rank} · {cause}", font=body(22), fill=ink)
    d.text((int(W * 0.645), oy), "Hikâye satırları", font=head(36), fill=ink)
    for i, line in enumerate(["Gün 12: Selin borçlu dokumacının", "kızı olduğunu anlattı.", "",
                              "Gün 40: Murat ateş başında", "kardeşinden söz etti.", "", "Gün 71: Kurt Geçidi."]):
        d.text((int(W * 0.645), oy + 70 + i * 36), line, font=body(23), fill=ink)
    stamp(base, "taslak 9.11 - düşenler sayfası")
    save(base, "y_911_dusenler.png")


JOBS = {"94": venue, "95": market_b, "96": character, "97": roster, "98": combat, "99": hud, "911": fallen}

if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "hepsi"
    for key, job in JOBS.items():
        if which in ("hepsi", key):
            job()
