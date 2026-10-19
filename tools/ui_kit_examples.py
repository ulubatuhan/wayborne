# -*- coding: utf-8 -*-
"""UI kiti v2 (görev 9.1) örnekleri: kit parçaları oyunun gerçek ekran
görüntülerine uygulanır - nerede, nasıl kullanılacağı görünsün (kullanıcı
notu 2026-10-19: "örnek görmem lazım, ilgili sahnelerde göster").

Girdi: tests/screenshot_screens.gd ve screenshot_journey_screen.gd'nin son
çıktıları (pazar, taverna, olay kartı) ve build/ui_kit (tools/ui_kit_ink.py).
Çıktı: TODO/referans/taslaklar/y_91_ui_kit_ornekler.png. Oyuna girmez.

Kullanım kuralı (örneklerde görünen):
  - panel_border: yan sütunların ve kartın kenarı (dolgu oyunun kendi koyu bandı);
  - title_strip: sütun başlığının altındaki çizgi;
  - button_primary: kararın ana eylemi (Al, Sat, Yola çık) - ekranda bir tane;
    ikincil eylemler oyunun düz düğmesinde kalır (Pazarlık, Vazgeç);
  - select_corner: seçili satır ya da kişi (dört köşe, ortası açık);
  - tooltip_plate: fiyat nedeni gibi ipuçları.

    python -X utf8 tools/ui_kit_examples.py
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(ROOT, "build", "ui_kit")
SHOTS = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata", "Wayborne")
OUT = os.path.join(os.path.dirname(ROOT), "TODO", "referans", "taslaklar", "y_91_ui_kit_ornekler.png")
FONT = os.path.join(ROOT, "data", "assets", "fonts", "EBGaramond.ttf")
HEAD = os.path.join(ROOT, "data", "assets", "fonts", "IMFellEnglishSC.ttf")
PARCHMENT = (224, 214, 190)
GOLD = (219, 179, 87)


def kit(name, k=1.0):
    img = Image.open(os.path.join(KIT, name + ".png")).convert("RGBA")
    if k != 1.0:
        img = img.resize((max(1, int(img.width * k)), max(1, int(img.height * k))), Image.LANCZOS)
    return img


def nine(img, size, margin):
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


def frame(img, box, margin=15):
    """Kenar ince kalır: kit parçası 0.4'e küçültülür (kalın, bulanık bir
    çerçeve başlıkları örtüyordu)."""
    x0, y0, x1, y1 = box
    img.alpha_composite(nine(kit("panel_border", 0.4), (x1 - x0 + 8, y1 - y0 + 8), margin), (x0 - 4, y0 - 4))


def strip(img, x, y, w):
    img.alpha_composite(kit("title_strip").resize((w, 18), Image.LANCZOS), (x, y))


def button(img, box, label, key="button_primary", size=24):
    x0, y0, x1, y1 = box
    ImageDraw.Draw(img).rectangle(box, fill=(14, 12, 11, 255))
    img.alpha_composite(nine(kit(key), (x1 - x0, y1 - y0), 22), (x0, y0))
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(FONT, size)
    tw = d.textlength(label, font=f)
    d.text(((x0 + x1 - tw) / 2, (y0 + y1) / 2 - size * 0.62), label, font=f,
           fill=PARCHMENT if key != "button_primary_disabled" else (150, 140, 128))


def corners(img, box):
    x0, y0, x1, y1 = box
    img.alpha_composite(nine(kit("select_corner", 0.35), (x1 - x0 + 8, y1 - y0 + 8), 22), (x0 - 4, y0 - 4))


def tip(img, box, title, line):
    x0, y0, x1, y1 = box
    img.alpha_composite(nine(kit("tooltip_plate"), (x1 - x0, y1 - y0), 40), (x0, y0))
    d = ImageDraw.Draw(img)
    d.text((x0 + 22, y0 + 14), title, font=ImageFont.truetype(HEAD, 24), fill=(40, 30, 26))
    d.text((x0 + 22, y0 + 50), line, font=ImageFont.truetype(FONT, 21), fill=(40, 30, 26))


def caption(img, text):
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, img.width, 54), fill=(10, 9, 8, 235))
    d.text((24, 10), text, font=ImageFont.truetype(HEAD, 30), fill=GOLD)


def market():
    img = Image.open(os.path.join(SHOTS, "screen_shots", "market_1920x1080.png")).convert("RGBA")
    frame(img, (28, 73, 497, 1005))
    frame(img, (1422, 73, 1891, 1005))
    strip(img, 42, 128, 440)
    strip(img, 1436, 128, 440)
    corners(img, (42, 331, 483, 384))
    button(img, (716, 948, 875, 1000), "Al")
    tip(img, (90, 392, 560, 486), "Fiyatın nedeni", "Pahalılık · Mevsim: kış, tezgâh az")
    caption(img, "Pazar: kenar, başlık çizgisi, seçili satır, ana eylem (Al), ipucu plakası")
    return img


def tavern():
    img = Image.open(os.path.join(SHOTS, "screen_shots", "tavern_1920x1080.png")).convert("RGBA")
    button(img, (1414, 1027, 1548, 1077), "Sohbete başla", size=22)
    corners(img, (1195, 315, 1275, 545))
    caption(img, "Taverna: ana eylem (Sohbete başla), seçili kişi köşebentle")
    return img


def event_card():
    img = Image.open(os.path.join(SHOTS, "journey_shots", "02b_olay_karti_zar.png")).convert("RGBA")
    frame(img, (619, 312, 1301, 767))
    strip(img, 646, 372, 300)
    button(img, (646, 646, 1274, 690), "Enkazın kenarından sıyrılıp geç — Kervanbaşı · Güç · %50", size=22)
    caption(img, "Olay kartı: kartın kenarı, başlık çizgisi; ilk seçenek ana eylem")
    return img


def main():
    shots = [market(), tavern(), event_card()]
    w = 960
    rows = [s.resize((w, int(s.height * w / s.width)), Image.LANCZOS) for s in shots]
    sheet = Image.new("RGB", (w * 2 + 30, rows[0].height * 2 + 30), (14, 12, 11))
    for i, r in enumerate(rows):
        sheet.paste(r.convert("RGB"), (10 + (i % 2) * (w + 10), 10 + (i // 2) * (r.height + 10)))
    sheet.save(OUT, quality=92)
    print("yazıldı:", OUT)


if __name__ == "__main__":
    main()
