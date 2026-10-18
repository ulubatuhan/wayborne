"""Savaş efektlerinin sprite'ları ve iki durum ikonu, tek hattan.

    python3 -I tools/fx_assets.py

Kaynak: art_source/fx/kenney_particle_pack/ (Kenney Particle Pack, CC0) -
paketin siyah zeminli sürümü, 512 px. Parlaklık saydamlığa çevriliyor,
renk beyaz: paketin "saydam" sürümünde renk kanalı koyu gri ve bir renkle
çarpılınca koyu zeminde kayboluyordu (ölçüldü). Oyuna 128 px'e küçültülüp
data/assets/fx/'e yazılıyor; renk çizimde `modulate` ile veriliyor, o yüzden
dosyalar renksiz kalıyor (aynı alev hem ateş oku hem yanma için).

İkonlar (k4g_burn, k4h_chill) K4 ailesinin boyunda, aynı parçacıklardan:
renklendirilmiş şekil + koyu mürekkep kenarı. Çıktı PNG'leri elle
düzenlenmez - bu dosyayı değiştirip yeniden çalıştır.
"""
import os
import sys

from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art_source", "fx", "kenney_particle_pack")
OUT = os.path.join(ROOT, "data", "assets", "fx")
ICONS = os.path.join(ROOT, "data", "assets", "ui", "waybook")
SIZE = 128
ICON_SIZE = (93, 96)
INK = (38, 28, 22)

# Oyunun kodda gerçekten çizdiği sprite'lar (status_fx.gd, combat_fx_layer.gd;
# flame_01-06 ve smoke_04-08 dinamik adlandırılıyor). Aile adıyla süzmek
# kullanılmayan numaraları da geri getiriyordu; geri kalan pakette dursun,
# oyuna girmesin. Yeni bir sprite kullanılacaksa buraya eklenir.
SPRITES = (
    "circle_02", "circle_05", "dirt_01", "fire_01", "fire_02", "flame_01",
    "flame_02", "flame_03", "flame_04", "flame_05", "flame_06", "light_01",
    "light_02", "light_03", "magic_03", "magic_04", "slash_02", "smoke_02",
    "smoke_03", "smoke_04", "smoke_05", "smoke_06", "smoke_07", "smoke_08",
    "spark_05", "spark_06", "star_04", "star_06", "trace_03", "twirl_01",
    "twirl_02",
)


def sprites() -> int:
    os.makedirs(OUT, exist_ok=True)
    count = 0
    for name in sorted(os.listdir(SRC)):
        stem, ext = os.path.splitext(name)
        if ext != ".png" or stem not in SPRITES:
            continue
        lum = Image.open(os.path.join(SRC, name)).convert("L")
        im = Image.new("RGBA", lum.size, (255, 255, 255, 0))
        im.putalpha(lum)
        # Parçacık 512 px tuvalin ortasında küçük bir şekil; içeriğine
        # kırpılıp kare tuvale ortalanıyor ki çizimdeki boy görünen boy olsun.
        box = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
        if box:
            im = im.crop(box)
        side = max(im.width, im.height)
        square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        square.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
        im = square.resize((SIZE, SIZE), Image.LANCZOS)
        im.save(os.path.join(OUT, name), optimize=True)
        count += 1
    return count


def icon(src_name: str, color: tuple, out_name: str) -> None:
    lum = Image.open(os.path.join(SRC, src_name)).convert("L")
    im = Image.new("RGBA", lum.size, (255, 255, 255, 0))
    im.putalpha(lum)
    im = im.crop(im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox())
    w, h = ICON_SIZE
    scale = min((w - 10) / im.width, (h - 10) / im.height)
    im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.LANCZOS)
    alpha = im.getchannel("A").point(lambda a: 255 if a > 60 else int(a * 4))
    shape = Image.new("RGBA", im.size, color + (255,))
    shape.putalpha(alpha)
    canvas = Image.new("RGBA", ICON_SIZE, (0, 0, 0, 0))
    pos = ((w - im.width) // 2, (h - im.height) // 2)
    edge = Image.new("L", ICON_SIZE, 0)
    edge.paste(alpha, pos)
    edge = edge.filter(ImageFilter.MaxFilter(5))
    ink = Image.new("RGBA", ICON_SIZE, INK + (255,))
    ink.putalpha(edge)
    canvas.alpha_composite(ink)
    canvas.alpha_composite(shape, pos)
    canvas.save(os.path.join(ICONS, out_name), optimize=True)


if __name__ == "__main__":
    n = sprites()
    icon("fire_01.png", (226, 118, 38), "k4g_burn.png")
    icon("star_06.png", (168, 214, 242), "k4h_chill.png")
    print("fx sprite: %d, ikon: 2" % n)
    sys.exit(0)
