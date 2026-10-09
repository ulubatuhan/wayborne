"""Kiyafet karelerini oyunun kare kumesine (BodyFrames) paketler: kalem x
beden basina bir kume, bedenin kumesiyle ayni klip/kare/katman duzeninde.

    python3 -I tools/figure_pipeline/mesh/pack_outfits.py [--variants male_average] [--items peasant_shirt]

Girdi : build/figures/outfits/<varyant>/<kalem>/<klip>/fNN/{shade,albedo}_<katman>.png
        (render_outfits.py) ve bedenin kendi joints.json'u (base_dy_px icin).
Cikti : data/assets/characters/frames/outfit_<kalem>_<varyant>/{page_N.png, frames.tres}

Katman = albedo x dort tona indirilmis golge (pack_beasts.compose - hayvanla
ayni kural). Yalniz KIND_BODY dolu; oyun bedenin donusumuyle (ayni capa,
ayni olcek) bedenin katmaninin hemen ustune ciziyor (WalkFigure). Kalemin
uyesi olmadigi katman bos. Yalniz bacaklari render edilen klip (walk_boots)
kalan katmanlari temel klibin karesinden alir ve bedenin kaydirdigi kadar
(base_dy_px) kaydirir - beden de oyle paketleniyor (pack_frames.py).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "mesh"))
sys.path.insert(0, os.path.join(PIPE, "beasts"))
import pack_frames as P  # noqa: E402
import pack_beasts  # noqa: E402

SRC = os.path.join(ROOT, "build", "figures", "outfits")
BODY = os.path.join(ROOT, "build", "figures", "out")
# Resimler bu oranda kucultulup paketleniyor (BodyFrames.texel_scale = 1/oran):
# figur ekranda render'in ~5'te biri boyunda, yarim cozunurluk hala fazlasi.
# Tam cozunurlukte 42 kume ~55 MB tutuyordu, Web her birini indiriyor.
DOWNSCALE = 0.5


def shrink(piece, x0, y0):
    """Kirpilmis parcayi kucultur; kose (x0, y0) render pikselinde kalir,
    yarim piksellik hizayi kaybetmemek icin tabana yuvarlanmiyor."""
    h, w = piece.shape[:2]
    nw, nh = max(1, round(w * DOWNSCALE)), max(1, round(h * DOWNSCALE))
    img = Image.fromarray(piece).resize((nw, nh), Image.LANCZOS)
    return np.asarray(img), (x0, y0)


def pack(variant, item, build, layers, post):
    src = os.path.join(SRC, variant, item)
    if not os.path.isdir(src):
        print("yok:", variant, item)
        return
    ident = "outfit_%s_%s" % (item, variant)
    dest = os.path.join(P.DEST, ident)
    os.makedirs(dest, exist_ok=True)
    shelf = P.Shelf()
    rects, offsets, names, counts = [], [], [], []
    shoulder_px = None
    for clip, ccfg in build["clips"].items():
        n = int(ccfg["frames"])
        ax, ay = ccfg["anchor_px"]
        names.append(clip)
        counts.append(n)
        own = ccfg.get("layers", layers)
        for i in range(n):
            fdir = os.path.join(src, clip, "f%02d" % i)
            j = json.load(open(os.path.join(BODY, variant, clip, "f%02d" % i, "joints.json")))
            if clip == "idle":
                shoulder_px = ay - j["front_shoulder"][1]
            if ccfg.get("base"):
                nb = int(build["clips"][ccfg["base"]]["frames"])
                bdir = os.path.join(src, ccfg["base"], "f%02d" % (round(i * nb / n) % nb))
            else:
                bdir = fdir
            dy = float(j.get("base_dy_px", 0.0))
            for layer in layers:
                d = fdir if layer in own else bdir
                have = os.path.exists(os.path.join(d, "shade_%s.png" % layer))
                for kind in range(len(P.KINDS)):
                    piece, (x0, y0) = (P.crop(pack_beasts.compose(d, layer, post))
                                       if kind == 0 and have else (None, (0, 0)))
                    if piece is None:
                        rects.append((0, 0, 0, 0, 0))
                        offsets.append((0.0, 0.0))
                        continue
                    if layer not in own:
                        y0 += dy
                    piece, (x0, y0) = shrink(piece, x0, y0)
                    rects.append(shelf.put(piece))
                    offsets.append((x0 - ax, y0 - ay))
    pages = []
    for k, page in enumerate(shelf.pages):
        used = np.nonzero(page[..., 3].any(axis=1))[0]
        hgt = 1 << ((int(used.max()) + 1 + P.PAD if len(used) else P.PAD) - 1).bit_length()
        name = "page_%d.png" % k
        Image.fromarray(page[:hgt]).save(os.path.join(dest, name), optimize=True)
        pages.append("res://data/assets/characters/frames/%s/%s" % (ident, name))
    lines = [
        '[gd_resource type="Resource" script_class="BodyFrames" load_steps=2 format=3]', "",
        '[ext_resource type="Script" path="res://scripts/character/body_frames.gd" id="1_bf"]', "",
        "[resource]",
        'script = ExtResource("1_bf")',
        "pages = " + P.packed("PackedStringArray", pages, '"%s"'),
        "clip_names = " + P.packed("PackedStringArray", names, '"%s"'),
        "clip_frames = " + P.packed("PackedInt32Array", counts, "%d"),
        "shoulder_px = %.3f" % shoulder_px,
        "texel_scale = %.4f" % (1.0 / DOWNSCALE),
        "rects = " + P.packed("PackedInt32Array", [v for r in rects for v in r], "%d"),
        "offsets = " + P.packed("PackedVector2Array", [v for o in offsets for v in o], "%.2f"),
        "",
    ]
    open(os.path.join(dest, "frames.tres"), "w").write("\n".join(lines))
    size = sum(os.path.getsize(os.path.join(dest, f)) for f in os.listdir(dest))
    print("%s: %d sayfa, %.2f MB" % (ident, len(pages), size / 1e6), flush=True)


def main():
    build = json.load(open(os.path.join(PIPE, "config", "build.json")))
    layers = json.load(open(os.path.join(PIPE, "config", "layers.json")))["layers"]
    post = json.load(open(os.path.join(PIPE, "config", "camera.json")))["posterize"]
    items = list(json.load(open(os.path.join(PIPE, "config", "outfits.json")))["items"])
    variants = build["variants"]
    if "--variants" in sys.argv:
        variants = sys.argv[sys.argv.index("--variants") + 1].split(",")
    if "--items" in sys.argv:
        items = sys.argv[sys.argv.index("--items") + 1].split(",")
    for v in variants:
        for it in items:
            pack(v, it, build, layers, post)


if __name__ == "__main__":
    main()
