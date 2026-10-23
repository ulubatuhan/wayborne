#!/usr/bin/env python3
"""Oyunun fare imleci: kullanıcının referansındaki "Shaped" ok ucu (2026-10-23).

Sol üstü gösteren, tabanı içe çentikli bir ok ucu; uçtan çentiğe inen bir sırt onu iki yüze
böler (sol yüz ışıkta, sağ yüz gölgede), koyu bir mürekkep çizgisi çevreler, altında küçük bir
gölge durur. İki ton, referanstaki iki varyant: `arrow.png` "Shaped (Dull)" (her yerde),
`pointer.png` "Shaped (Bright)" (tıklanabilir bir şeyin üstünde, CURSOR_POINTING_HAND).
Pirinç tonları gösterge madalyonunun pirinciyle aynı aileden.

Çıktı PNG'leri elle düzeltilmez: bu aracı değiştirip yeniden koş.
    python3 -I tools/cursor_art.py
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "assets", "ui", "cursor")
SIZE = 32
SS = 8                      # örnekleme çarpanı
ORIGIN = (3.0, 2.0)         # ok ucunun tuval üstündeki yeri = Godot'nun hotspot'u
# Ok ucu, ucuna göre piksel: uç, sol kanat, çentik, sağ kanat.
TIP = (0.0, 0.0)
LEFT = (3.0, 22.0)
NOTCH = (9.0, 16.0)
RIGHT = (18.0, 17.0)
OUTLINE = (24, 19, 13, 255)
OUTLINE_W = 2.6             # çizginin yarısı dışarıda kalır: ~1.3 px görünür
SHADOW = (0, 0, 0, 110)
TONES = {
    "arrow": ((184, 165, 112), (124, 108, 68), (214, 198, 150)),    # sol yüz, sağ yüz, sırt ışığı
    "pointer": ((232, 210, 146), (172, 148, 90), (250, 236, 190)),
}


def pts(*ps, dx=0.0, dy=0.0):
    return [((ORIGIN[0] + x + dx) * SS, (ORIGIN[1] + y + dy) * SS) for x, y in ps]


def draw(tones) -> Image.Image:
    left, right, ridge = tones
    n = SIZE * SS
    shadow = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).polygon(pts(TIP, LEFT, NOTCH, RIGHT, dx=1.4, dy=1.6), fill=SHADOW)
    img = shadow.filter(ImageFilter.GaussianBlur(1.1 * SS))
    d = ImageDraw.Draw(img)
    outline = pts(TIP, LEFT, NOTCH, RIGHT)
    d.polygon(outline, fill=OUTLINE)
    d.line(outline + outline[:1], fill=OUTLINE, width=round(OUTLINE_W * SS), joint="curve")
    d.polygon(pts(TIP, LEFT, NOTCH), fill=left + (255,))
    d.polygon(pts(TIP, NOTCH, RIGHT), fill=right + (255,))
    d.line(pts(TIP, NOTCH), fill=ridge + (255,), width=round(0.9 * SS))
    # Uca yakın sol kenarda ince bir parıltı: pirinç bir yüzeyin ışığı yakaladığı yer.
    d.line(pts((0.6, 2.5), (2.4, 15.0)), fill=ridge + (200,), width=round(0.7 * SS))
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    for name, tones in TONES.items():
        draw(tones).save(os.path.join(OUT, name + ".png"), optimize=True)
        print(name + ".png", "hotspot", ORIGIN)
    return 0


if __name__ == "__main__":
    sys.exit(main())
