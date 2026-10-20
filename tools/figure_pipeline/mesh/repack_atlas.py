"""Kare kumesinin atlas sayfalarini sikica yeniden paketler (gorev 5.4).

    python3 -I tools/figure_pipeline/mesh/repack_atlas.py [--sets body_male_average,...] [--dry]

Paketleyiciler (pack_frames, pack_outfits, pack_beasts, append_clips, pack_hd)
parcalari geldikleri sirayla bir rafa diziyordu: boylari karisik oldugu icin
her satirin altinda bosluk kaliyordu ve ayni parca (walk_boots'un yurume
klibinden aldigi katmanlar, bos kiyafet katmanlarinin ayni kirpintisi) her
seferinde yeniden yaziliyordu. Olculen: 1139 sayfa, 473 Mpx, opak doluluk
%15,5; parcalarin sinir kutulari 196 Mpx, tekilleri 138 Mpx.

Burada her kume kendi frames.tres'inden okunur, ayni bayttaki parcalar tek
yere konur (girdiler ayni dikdortgeni gosterir), tekiller boya gore azalan
sirada rafa dizilir ve yalniz `pages` ile `rects` satirlari yeniden yazilir;
ofsetler, eklem ve klip tablolari degismez. Her paketleyici kendi isinin
sonunda bunu cagirir, boylece sayfalar hep sikidir.

Sayfa adi icerigin ozetini tasir (`page_<k>_<ozet>.png`): ayni adla yeniden
yazilan sayfa Godot'nun ice aktarma onbellegindeki eski resmi okutuyordu
(CLAUDE.md, "Repacked atlas pages keep their names"). Ad degisince eski
onbellek kullanilmaz.
"""
import hashlib
import os
import re
import sys

import numpy as np
from PIL import Image

ROOT = os.environ.get("WAYBORNE_ROOT") or os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
FRAMES = os.path.join(ROOT, "data", "assets", "characters", "frames")
PAGE = 2048
PAD = 2
HEIGHT_STEP = 64
RES_PREFIX = "res://data/assets/characters/frames/%s/%s"

_PAGES_RE = re.compile(r"^pages = PackedStringArray\((.*)\)$", re.M)
_RECTS_RE = re.compile(r"^rects = PackedInt32Array\((.*)\)$", re.M)


def _ints(text):
    return [int(v) for v in text.split(",") if v.strip()]


def _strings(text):
    return [s.strip().strip('"') for s in text.split(",") if s.strip()]


def skyline_pack(sizes):
    """Ufuk cizgisi (skyline, alt-sol) paketi; boya gore azalan sirada.
    Raf paketinde her satir en uzun parcasi kadar yer tutuyor, kisa parcalarin
    ustu bos kaliyordu; ufuk cizgisi her parcayi o anki en alcak yere oturtur.
    sizes: [(w, h)] -> [(sayfa, x, y)], sayfa basina kullanilan yukseklik."""
    order = sorted(range(len(sizes)), key=lambda i: (-sizes[i][1], -sizes[i][0]))
    spots = [None] * len(sizes)
    sky = [[(0, PAGE, 0)]]  # sayfa basina [(x, genislik, y)] - dolu tavan
    heights = [0]
    for i in order:
        w, h = sizes[i][0] + PAD, sizes[i][1] + PAD
        if w > PAGE or h > PAGE:
            raise ValueError("parca sayfaya sigmiyor: %dx%d" % sizes[i])
        placed = False
        for pg, line in enumerate(sky):
            best = None
            for k in range(len(line)):
                x0 = line[k][0]
                if x0 + w > PAGE:
                    break
                top, span, j = 0, 0, k
                while span < w:
                    top = max(top, line[j][2])
                    span = line[j][0] + line[j][1] - x0
                    j += 1
                if top + h > PAGE:
                    continue
                if best is None or top < best[1] or (top == best[1] and x0 < best[0]):
                    best = (x0, top, k)
            if best is None:
                continue
            x0, top, k = best
            new_seg = (x0, w, top + h)
            rest = []
            for seg in line[k:]:
                sx, sw, sy = seg
                if sx + sw <= x0 + w:
                    continue
                if sx < x0 + w:
                    rest.append((x0 + w, sx + sw - (x0 + w), sy))
                else:
                    rest.append(seg)
            line[k:] = [new_seg] + rest
            merged = []
            for seg in line:
                if merged and merged[-1][2] == seg[2]:
                    merged[-1] = (merged[-1][0], merged[-1][1] + seg[1], seg[2])
                else:
                    merged.append(seg)
            line[:] = merged
            spots[i] = (pg, x0 + PAD, top + PAD)
            heights[pg] = max(heights[pg], top + h)
            placed = True
            break
        if not placed:
            sky.append([(0, PAGE, 0)])
            heights.append(0)
            pg = len(sky) - 1
            sky[pg][:] = [(0, w, h), (w, PAGE - w, 0)]
            spots[i] = (pg, PAD, PAD)
            heights[pg] = h
    return spots, heights


def repack_set(dest, dry=False):
    """dest: kumenin klasoru (frames.tres ve sayfalari). (once, sonra) piksel sayisi doner."""
    tres = os.path.join(dest, "frames.tres")
    text = open(tres, encoding="utf-8").read()
    ident = os.path.basename(os.path.normpath(dest))
    old_pages = _strings(_PAGES_RE.search(text).group(1))
    rects = _ints(_RECTS_RE.search(text).group(1))
    # Sayfalar res:// yolundan degil klasorden okunur: pack_hd kumeyi gecici
    # bir klasorde paketleyip sonra tasiyor.
    files = [os.path.join(dest, os.path.basename(p)) for p in old_pages]
    imgs = [np.asarray(Image.open(f).convert("RGBA")) for f in files]
    before = sum(im.shape[0] * im.shape[1] for im in imgs)
    unique, index_of, entry_unique = [], {}, []
    for e in range(0, len(rects), 5):
        pg, x, y, w, h = rects[e:e + 5]
        if w <= 0 or h <= 0:
            entry_unique.append(-1)
            continue
        piece = imgs[pg][y:y + h, x:x + w]
        key = (w, h, hashlib.md5(piece.tobytes()).digest())
        if key not in index_of:
            index_of[key] = len(unique)
            unique.append(piece)
        entry_unique.append(index_of[key])
    spots, heights = skyline_pack([(p.shape[1], p.shape[0]) for p in unique])
    # Yukseklik 2'nin kuvvetine degil HEIGHT_STEP'in katina yuvarlaniyor: Godot 4
    # her boyda mipmap uretir, GPU sikistirmasi yalniz 4'un katini ister; 2'nin
    # kuvveti son sayfayi cogu zaman iki katina sisiriyordu.
    pages = [np.zeros((-(-max(hh, PAD) // HEIGHT_STEP) * HEIGHT_STEP, PAGE, 4), np.uint8) for hh in heights]
    for u, piece in enumerate(unique):
        pg, x, y = spots[u]
        h, w = piece.shape[:2]
        pages[pg][y:y + h, x:x + w] = piece
    new_rects = []
    for n, u in enumerate(entry_unique):
        if u < 0:
            new_rects += rects[n * 5:n * 5 + 5]
            continue
        pg, x, y = spots[u]
        h, w = unique[u].shape[:2]
        new_rects += [pg, x, y, w, h]
    after = sum(p.shape[0] * p.shape[1] for p in pages)
    if dry:
        area = sum(p.shape[0] * p.shape[1] for p in unique)
        print("  tekil parca alani %.1f Mpx, verim %%%.0f" % (area / 1e6, 100.0 * area / max(after, 1)))
        return before, after
    names = []
    for k, page in enumerate(pages):
        digest = hashlib.md5(page.tobytes()).hexdigest()[:8]
        names.append("page_%d_%s.png" % (k, digest))
    for f in set(files) - {os.path.join(dest, n) for n in names}:
        for path in (f, f + ".import"):
            if os.path.exists(path):
                os.remove(path)
    for name, page in zip(names, pages):
        path = os.path.join(dest, name)
        if not os.path.exists(path):
            Image.fromarray(page).save(path, optimize=True)
    page_line = "pages = PackedStringArray(%s)" % ", ".join('"%s"' % (RES_PREFIX % (ident, n)) for n in names)
    rect_line = "rects = PackedInt32Array(%s)" % ", ".join("%d" % v for v in new_rects)
    text = _PAGES_RE.sub(lambda _m: page_line, text, count=1)
    text = _RECTS_RE.sub(lambda _m: rect_line, text, count=1)
    open(tres, "w", encoding="utf-8", newline="\n").write(text)
    return before, after


def main():
    sets = sorted(d for d in os.listdir(FRAMES) if os.path.exists(os.path.join(FRAMES, d, "frames.tres")))
    if "--sets" in sys.argv:
        sets = sys.argv[sys.argv.index("--sets") + 1].split(",")
    dry = "--dry" in sys.argv
    tb = ta = 0
    for s in sets:
        b, a = repack_set(os.path.join(FRAMES, s), dry)
        tb, ta = tb + b, ta + a
        print("%s: %.1f -> %.1f Mpx" % (s, b / 1e6, a / 1e6), flush=True)
    print("toplam: %.0f -> %.0f Mpx (%.1fx)" % (tb / 1e6, ta / 1e6, tb / max(ta, 1)))


if __name__ == "__main__":
    main()
