"""Şehir ekranının boyalı parçaları, CC0 dokulardan (ambientCG) ve oyunun
kendi eşya render'larından üretilir. Elle düzenlenmiş çıktı yok: bir şey
değişecekse burası değişir ve yeniden koşulur.

Çıktı: data/assets/ui/grim/kit/
  strip_wood.png    alt şerit: koyu tahta, üst ve altta perçinli pas demir
  plate.png         mekân düğmesi levhası: koyu taş, demir kenar (dokuz dilim)
  plate_hover.png   aynı levha, kehribar ışıklı kenar
  banner.png        yırtık kızıl sancak (şehir adı, uyarılar)
  crest.png         kervan arması: demir halkalı kalkan
  card.png          kadro kartı zemini: kömür, ince pas kenar, yıpranma
  icon_<ad>.png     madalyon ikonları (mekânlar ve gezinme)

Doku kararı (oyuncunun isteği: "oyun geliştirme estetik kurallarına göre"):
doku malzemenin *ne olduğunu* söylediği yerde kullanılır - bir şerit
tahtadır, bir levha taştır, bir sancak kumaştır. Okunacak metin hep düz,
koyu bir zemin üstünde kalır (dokunun üstüne yazı yazılmaz; bkz. Waybook UI
Rules'un perçinlerin harfleri kestiği ölçüm).
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TEX = os.path.join(ROOT, "art_source", "textures", "ambientcg")
PROPS = os.path.join(ROOT, "data", "assets", "props")
WAYBOOK = os.path.join(ROOT, "data", "assets", "ui", "waybook")
OUT = os.path.join(ROOT, "data", "assets", "ui", "grim", "kit")

AMBER = np.array([237, 168, 82], np.float32) / 255.0
RUST = np.array([115, 64, 36], np.float32) / 255.0
CRIMSON = np.array([153, 41, 23], np.float32) / 255.0
INK = np.array([10, 8, 9], np.float32) / 255.0

# ikon adı -> (kaynak, ölçek payı). Eşya render'ı ya da Waybook resmi.
ICONS = {
    "yard": ("props/iso_stable", 0.92),
    "market": ("props/iso_market_stand_1", 0.9),
    "guild": ("props/iso_house_2", 0.9),
    "tavern": ("props/iso_inn", 0.92),
    "church": ("props/iso_bell_tower", 0.95),
    "tailor": ("props/saddlebag", 0.82),
    "gate": ("props/city_gate", 0.95),
    "party": ("props/weapon_shield_heater", 0.86),
    "ledger": ("waybook/m3_closed", 0.86),
    "map": ("props/signpost", 0.9),
    "caravan": ("props/market_cart", 0.92),
    "camp": ("props/bonfire", 0.86),
    "wardrobe": ("props/backpack", 0.8),
}


def tex(name, size):
    path = os.path.join(TEX, name, name + "_1K-JPG_Color.jpg")
    img = Image.open(path).convert("RGB")
    tw, th = img.size
    out = Image.new("RGB", size)
    for x in range(0, size[0], tw):
        for y in range(0, size[1], th):
            out.paste(img, (x, y))
    return np.asarray(out, np.float32) / 255.0


def grade(a, value=0.35, sat=0.4, tint=None):
    lum = a.mean(-1, keepdims=True)
    a = lum + (a - lum) * sat
    a = a * value / max(float(lum.mean()), 1e-3) * 0.5
    if tint is not None:
        a = a * (0.6 + 0.8 * tint)
    return np.clip(a, 0, 1)


def save(a, name):
    os.makedirs(OUT, exist_ok=True)
    if a.shape[-1] == 3:
        a = np.concatenate([a, np.ones(a.shape[:2] + (1,), np.float32)], -1)
    Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name))


def iron_band(w, h, seed, rivets=True):
    m = grade(tex("Metal041B", (w, h)), 0.55, 0.85, RUST)
    y = np.linspace(-1, 1, h)[:, None]
    m = m * (1.15 - 0.45 * y * y)[..., None]  # yuvarlak çubuk: ortası parlak
    m[0, :] *= 0.4
    m[-1, :] *= 0.3
    if rivets:
        img = Image.fromarray((m * 255).astype(np.uint8))
        d = ImageDraw.Draw(img)
        r = max(2, h // 4)
        for x in range(28, w, 96):
            d.ellipse((x - r, h / 2 - r, x + r, h / 2 + r), fill=(40, 26, 20))
            d.ellipse((x - r + 1, h / 2 - r + 1, x + r - 2, h / 2 + r - 2), fill=(120, 82, 58))
        m = np.asarray(img, np.float32) / 255.0
    return m


def strip_wood():
    w, h = 1920, 104
    wood = grade(tex("Planks037A", (w, 1024))[300:300 + h], 0.24, 0.55)
    band = 10
    wood[:band] = iron_band(w, band, 1)
    wood[-band:] = iron_band(w, band, 2)
    # şeridin içi bir gölge: metnin üstüne gelen orta kısım daha koyu ve düz
    y = np.linspace(0, 1, h)[:, None]
    wood *= (0.8 + 0.2 * np.abs(y - 0.5) * 2)[..., None]
    save(wood, "strip_wood.png")


def plate(hover):
    w, h = 360, 76
    stone = grade(tex("Rock064", (w, h)), 0.2, 0.3)
    a = np.ones((h, w, 1), np.float32)
    rim = AMBER if hover else RUST
    img = np.concatenate([stone, a], -1)
    for i in range(3):
        c = rim * (1.0 - 0.28 * i) if hover else rim * (0.9 - 0.25 * i)
        img[i, :, :3] = c
        img[-1 - i, :, :3] = c
        img[:, i, :3] = c
        img[:, -1 - i, :3] = c
    if hover:
        yy, xx = np.mgrid[0:h, 0:w]
        edge = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy)).astype(np.float32)
        glow = np.exp(-edge / 9.0)[..., None] * 0.32
        img[..., :3] = img[..., :3] + AMBER * glow
    # köşe perçinleri
    pil = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(pil)
    for cx, cy in ((9, 9), (w - 10, 9), (9, h - 10), (w - 10, h - 10)):
        d.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(36, 22, 16, 255))
        d.ellipse((cx - 2, cy - 2, cx + 1, cy + 1), fill=(150, 104, 70, 255))
    pil.save(os.path.join(OUT, "plate_hover.png" if hover else "plate.png"))


def banner():
    w, h = 620, 120
    rng = np.random.default_rng(5)
    cloth = tex("Fabric085", (w, h))
    lum = cloth.mean(-1, keepdims=True)
    cloth = CRIMSON * (0.55 + 0.9 * lum) * 0.75
    # kıvrımlar: yatay sinüs gölgesi
    x = np.linspace(0, 1, w)[None, :]
    folds = 0.82 + 0.18 * np.sin(x * 23.0 + np.sin(x * 7.0) * 2.0)
    cloth = cloth * folds[..., None]
    y = np.linspace(0, 1, h)[:, None]
    cloth *= (0.75 + 0.35 * np.sin(y * np.pi))[..., None]
    alpha = np.ones((h, w), np.float32)
    # sağ uç: kırlangıç kuyruğu + yırtık püskül
    notch = (h / 2) * (1 - np.abs(y[:, 0] - 0.5) * 2)
    for row in range(h):
        cut = w - 1 - int(notch[row] * 0.55)
        tatter = int(rng.integers(0, 14))
        alpha[row, cut - tatter:] = 0.0
    # alt kenar yıpranmış
    for col in range(w):
        alpha[h - int(rng.integers(0, 5)) - 1:, col] = 0.0
    al = Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))
    alpha = np.asarray(al, np.float32)[..., None] / 255.0
    # sol uç: sancak direği (demir)
    pole = iron_band(h, 14, 3, False).transpose(1, 0, 2)
    cloth[:, :14] = pole
    alpha[:, :14] = 1.0
    save(np.concatenate([cloth, alpha], -1), "banner.png")


def card():
    w, h = 300, 132
    base = grade(tex("Rock064", (w, h)), 0.14, 0.2)
    img = np.concatenate([base, np.ones((h, w, 1), np.float32)], -1)
    img[:2, :, :3] = RUST
    img[-2:, :, :3] = RUST * 0.7
    img[:, :2, :3] = RUST * 0.8
    img[:, -2:, :3] = RUST * 0.8
    save(img, "card.png")


def crest():
    s = 160
    yy, xx = np.mgrid[0:s, 0:s].astype(np.float32)
    cx = (xx - s / 2) / (s / 2)
    cy = (yy - s / 2) / (s / 2)
    # kalkan: üstü düz, altı sivri
    inside = (np.abs(cx) < 0.78) & (cy > -0.82) & (cy < 0.9 - np.abs(cx) * 0.9)
    field = tex("Fabric085", (s, s)).mean(-1, keepdims=True)
    col = CRIMSON * (0.5 + field) * 0.8
    img = np.zeros((s, s, 4), np.float32)
    img[..., :3] = col
    img[..., 3] = inside
    rim = inside & ~((np.abs(cx) < 0.7) & (cy > -0.74) & (cy < 0.8 - np.abs(cx) * 0.9))
    metal = grade(tex("Metal063", (s, s)), 0.6, 0.7, RUST)
    img[rim, :3] = metal[rim]
    # tek amblem: tekerlek (kervan)
    pil = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(pil)
    c, r = s / 2, s * 0.22
    d.ellipse((c - r, c - r - 6, c + r, c + r - 6), outline=(214, 186, 140, 255), width=6)
    for k in range(6):
        ang = k * np.pi / 3
        d.line((c, c - 6, c + np.cos(ang) * r, c - 6 + np.sin(ang) * r), fill=(214, 186, 140, 255), width=4)
    d.ellipse((c - 7, c - 13, c + 7, c + 1), fill=(214, 186, 140, 255))
    pil.save(os.path.join(OUT, "crest.png"))


def _load_source(src):
    kind, name = src.split("/", 1)
    if kind == "props":
        path = os.path.join(PROPS, name, "body.png")
        img = Image.open(path).convert("RGBA")
        extra = os.path.join(PROPS, name, "canopy.png")
        if os.path.exists(extra):  # brandalı vagon: gövde + branda tek resim
            img = img.copy()
            canopy = Image.open(extra).convert("RGBA")
            img.alpha_composite(canopy.resize(img.size))
        return img
    return Image.open(os.path.join(WAYBOOK, name + ".png")).convert("RGBA")


def icon(name, src, share):
    s = 112
    img = _load_source(src)
    img = img.crop(img.getbbox())
    k = (s * share) / max(img.size)
    img = img.resize((max(1, int(img.size[0] * k)), max(1, int(img.size[1] * k))), Image.LANCZOS)
    a = np.asarray(img, np.float32) / 255.0
    rgb, al = a[..., :3], a[..., 3:]
    lum = rgb.mean(-1, keepdims=True)
    rgb = lum + (rgb - lum) * 0.35  # ikonlar: neredeyse tek renk, ışık sıcak
    rgb = np.clip(rgb * (0.55 + 0.6 * AMBER), 0, 1)
    fig = Image.fromarray((np.concatenate([rgb, al], -1) * 255).astype(np.uint8), "RGBA")
    # mürekkep: alfayı genişlet, siyaha boya, altına koy
    ink = fig.split()[3].filter(ImageFilter.MaxFilter(5))
    canvas = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    off = ((s - fig.size[0]) // 2, (s - fig.size[1]) // 2)
    inkimg = Image.new("RGBA", fig.size, (8, 6, 7, 255))
    inkimg.putalpha(ink)
    canvas.alpha_composite(inkimg, off)
    canvas.alpha_composite(fig, off)
    canvas.save(os.path.join(OUT, "icon_%s.png" % name))


def main():
    os.makedirs(OUT, exist_ok=True)
    strip_wood()
    plate(False)
    plate(True)
    banner()
    card()
    crest()
    for name, (src, share) in ICONS.items():
        icon(name, src, share)
    print("YAZILDI", OUT)


if __name__ == "__main__":
    main()
