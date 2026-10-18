"""referans harita tarzı yerleşim katmanı: zemine pişmez, şeffaf 4096 PNG.

referans harita dünya haritasında bir yer bir ikon değil, küçük bir yapı kümesidir:
yandan-üstten görülen evler (krem duvar, kırmızı/kahve/saman çatı, mürekkep
kontur), şehirlerin çevresinde kuleli taş sur ve kapı, kasabalarda çit,
köylerde yola dizilmiş birkaç ev. Konumlar world.json'dan, değişmez.

    python3 -I zemin_settlements.py <kök> <çıktı.png> [tohum]
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

SS = 3  # süper örnekleme
INK = (38, 28, 18, 255)
WALL = [(226, 214, 184), (214, 200, 168), (232, 222, 196)]
ROOF = [(150, 62, 44), (128, 52, 38), (112, 76, 48), (156, 128, 86), (98, 80, 66)]
STONE = (176, 168, 150)
STONE_DK = (130, 122, 108)

# tür: (sur yarıçapı, ev sayısı, saçılma yarıçapı, kule?, kilise?, çit?)
KINDS = {
    "ic_city":       (120, 70, 150, True, True, False),
    "ic_freecity":   (115, 64, 145, True, True, False),
    "ic_portcity":   (110, 60, 140, True, True, False),
    "it_town":       (0, 26, 75, False, True, True),
    "it_markettown": (0, 30, 80, False, True, True),
    "it_rivertown":  (0, 26, 75, False, True, True),
    "it_minetown":   (0, 18, 60, False, False, True),
    "it_swamptown":  (0, 16, 60, False, False, True),
    "ih_mezra":     (0, 6, 34, False, False, False),
    "iv_farm":       (0, 3, 22, False, False, True),
    "iv_fishvillage": (0, 7, 34, False, False, False),
    "il_lumber":     (0, 3, 22, False, False, False),
    "ia_abbey":      (0, 0, 0, False, False, False),
    "iw_tower":      (0, 0, 0, False, False, False),
    "ix_mountaintribe": (0, 5, 30, False, False, False),
}


def house(dr, x, y, w, h, roof, wall, ang_flip):
    """Yandan-üstten ev: ön duvar + üçgen alınlı çatı. (x, y) taban ortası."""
    s = SS
    w, h = w * s, h * s
    x, y = x * s, y * s
    wall_h = h * 0.45
    roof_h = h * 0.75
    # duvar
    dr.polygon([(x - w / 2, y), (x + w / 2, y), (x + w / 2, y - wall_h), (x - w / 2, y - wall_h)],
               fill=wall, outline=INK)
    # çatı: sırt yatay (ev uzun), yan alın üçgeni bir uçta
    ov = w * 0.08
    ridge_y = y - wall_h - roof_h * 0.55
    dr.polygon([(x - w / 2 - ov, y - wall_h + ov), (x + w / 2 + ov, y - wall_h + ov),
                (x + w / 2 - w * 0.12, ridge_y), (x - w / 2 + w * 0.12, ridge_y)],
               fill=roof, outline=INK)
    # çatı gölge yarısı ve sırt çizgisi
    dk = tuple(int(c * 0.78) for c in roof)
    mid = y - wall_h + (ridge_y - (y - wall_h)) * 0.5
    side = 1 if ang_flip else -1
    dr.polygon([(x + side * (w / 2 + ov), y - wall_h + ov), (x + side * (w / 2 - w * 0.12), ridge_y),
                (x + side * (w / 2 - w * 0.12) - side * w * 0.28, mid)], fill=dk)
    dr.line([(x - w / 2 + w * 0.12, ridge_y), (x + w / 2 - w * 0.12, ridge_y)], fill=INK, width=max(1, s))
    # kapı
    dr.rectangle([x - w * 0.06, y - wall_h * 0.6, x + w * 0.06, y], fill=INK)


def tower(dr, x, y, r, h, roof=(98, 80, 66)):
    s = SS
    x, y, r, h = x * s, y * s, r * s, h * s
    dr.rectangle([x - r, y - h, x + r, y], fill=STONE, outline=INK)
    dr.polygon([(x - r * 1.25, y - h), (x + r * 1.25, y - h), (x, y - h - r * 2.2)], fill=roof, outline=INK)
    dr.rectangle([x - r * 0.25, y - h * 0.7, x + r * 0.25, y - h * 0.5], fill=INK)


def church(dr, x, y, scale=1.0):
    house(dr, x, y, 22 * scale, 15 * scale, (110, 108, 104), WALL[2], True)
    tower(dr, x - 12 * scale, y + 1, 3.6 * scale, 18 * scale, (90, 88, 86))


def wall_ring(dr, cx, cy, R, rng, towers=True):
    s = SS
    n = 26
    a = np.linspace(0, 2 * np.pi, n, endpoint=False) + rng.random() * 0.3
    rr = R * (0.88 + 0.18 * rng.random(n))
    rr = (rr + np.roll(rr, 1) + np.roll(rr, -1)) / 3
    pts = [(cx + np.cos(t) * r, cy + np.sin(t) * r * 0.78) for t, r in zip(a, rr)]
    P = [(p[0] * s, p[1] * s) for p in pts] + [(pts[0][0] * s, pts[0][1] * s)]
    dr.line(P, fill=INK, width=int(7 * s))
    dr.line(P, fill=STONE, width=int(4.5 * s))
    dr.line(P, fill=STONE_DK, width=int(1 * s))
    return pts


def draw_place(kind, x, y, rng):
    """Bir yerin yapılarını, ortası (x, y) olan bir yamaya çizer."""
    R, count, spread, walled, has_church, fence = KINDS[kind]
    half = int(max(spread, R) * 1.35 + 40)
    W = half * 2
    im = Image.new("RGBA", (W * SS, W * SS), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    c = half
    items = []  # (y, çizici)
    if kind == "ia_abbey":
        # avlu: dört kanat + kilise
        for dx, dy in ((-14, -10), (14, -10), (-14, 10), (14, 10)):
            items.append((c + dy, lambda dx=dx, dy=dy: house(dr, c + dx, c + dy, 20, 12, ROOF[0], WALL[0], dx > 0)))
        items.append((c + 1, lambda: church(dr, c, c + 1, 1.15)))
    elif kind == "iw_tower":
        items.append((c, lambda: tower(dr, c, c + 8, 5, 26)))
    else:
        ang = rng.random() * np.pi
        u = np.array([np.cos(ang), np.sin(ang) * 0.75])
        v = np.array([-np.sin(ang), np.cos(ang)]) * 0.75
        placed = []
        tries = 0
        while len(placed) < count and tries < count * 40:
            tries += 1
            if walled:
                rad = R * 0.85 * np.sqrt(rng.random())
                th = rng.random() * 2 * np.pi
                p = np.array([np.cos(th) * rad, np.sin(th) * rad * 0.78])
            else:
                # köy: bir yol boyunca, iki yana dizili
                t = (rng.random() - 0.5) * 2 * spread
                side = (rng.random() - 0.5) * 2 * spread * 0.35
                p = u * t + v * side
            if any(np.hypot(*(p - q)) < 16 for q in placed):
                continue
            placed.append(p)
        for p in placed:
            hw = 13 + rng.random() * 8
            hh = 10 + rng.random() * 5
            roof = ROOF[rng.integers(len(ROOF))] if not walled else ROOF[rng.integers(3)]
            wall = WALL[rng.integers(len(WALL))]
            flip = rng.random() < 0.5
            px, py = c + p[0], c + p[1]
            items.append((py, lambda px=px, py=py, hw=hw, hh=hh, roof=roof, wall=wall, flip=flip:
                          house(dr, px, py, hw, hh, roof, wall, flip)))
        if has_church:
            items.append((c, lambda: church(dr, c, c, 1.25 if walled else 1.0)))
        if walled:
            # kale/burç: merkezin biraz kuzeyinde
            items.append((c - R * 0.35, lambda: tower(dr, c + R * 0.25, c - R * 0.35, 6, 30)))
        # suburbs outside walls
        if walled:
            for _ in range(count // 4):
                th = rng.random() * 2 * np.pi
                rad = R * (1.1 + 0.35 * rng.random())
                px, py = c + np.cos(th) * rad, c + np.sin(th) * rad * 0.78
                roof = ROOF[rng.integers(len(ROOF))]
                items.append((py, lambda px=px, py=py, roof=roof: house(dr, px, py, 12, 9, roof, WALL[0], rng.random() < 0.5)))
    # sur önce (arkada), sonra y sırasıyla yapılar; ön sur yarısı en son
    if walled:
        wall_ring(dr, c, c, R, rng)
        for th in np.linspace(0, 2 * np.pi, 9, endpoint=False):
            items.append((c + np.sin(th) * R * 0.78 + 0.1,
                          lambda th=th: tower(dr, c + np.cos(th) * R * 0.97, c + np.sin(th) * R * 0.76 + 6, 5, 14)))
    if False and fence and count:  # tam çit halkası yapay okundu (denendi)
        rr = spread * 0.95
        pts = [((c + np.cos(t) * rr) * SS, (c + np.sin(t) * rr * 0.7) * SS) for t in np.linspace(0, 2 * np.pi, 40)]
        dr.line(pts, fill=(90, 66, 40), width=int(1.4 * SS))
    for _, f in sorted(items, key=lambda it: it[0]):
        f()
    im = im.resize((W, W), Image.LANCZOS)
    return im, half


def paste(dst, src, x, y):
    """alpha_composite, kenardan taşan yamayı kırparak."""
    l, t = max(0, -x), max(0, -y)
    r = min(src.width, dst.width - x)
    b = min(src.height, dst.height - y)
    if r <= l or b <= t:
        return
    dst.alpha_composite(src.crop((l, t, r, b)), (x + l, y + t))


def render(root, seed=0, n=4096):
    rng = np.random.default_rng(seed)
    world = json.load(open(os.path.join(root, "data", "world.json")))
    out = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    syms = [s for s in world["syms"] if s[0] in KINDS]
    for kind, x, y in sorted(syms, key=lambda s: s[2]):
        patch, half = draw_place(kind, x, y, rng)
        # gölge: yamanın alfa'sı sağ alta, yumuşak
        a = np.asarray(patch, np.float32)[..., 3]
        sh = Image.fromarray((a * 0.35).astype(np.uint8)).filter(__import__("PIL.ImageFilter", fromlist=["x"]).GaussianBlur(2))
        shadow = Image.new("RGBA", patch.size, (20, 14, 8, 0))
        shadow.putalpha(sh)
        paste(out, shadow, int(x - half + 3), int(y - half + 3))
        paste(out, patch, int(x - half), int(y - half))
    return out


def main():
    root, dst = sys.argv[1], sys.argv[2]
    seed = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    render(root, seed).save(dst)
    print("YAZILDI", dst)


if __name__ == "__main__":
    main()
