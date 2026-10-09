"""Hayvan karelerini oyunun kare kumesine (BodyFrames) paketler.

    python3 -I tools/figure_pipeline/beasts/pack_beasts.py [--species horse,wolf] [--src DIR]

Katman = albedo x golge: golge insanla ayni sabit sinirlarla dort tona
indiriliyor (mesh/posterize.py, config/camera.json "posterize"), sonra
malzemenin kendi rengiyle carpiliyor. Alfa golge render'inin alfasi (albedo
ayni geometri, ayni maske). Hayvanin tek turu var (KIND_BODY); oyun onu beyaz
tonla ciziyor, renk zaten resimde.

Cikti: data/assets/characters/frames/beast_<tur>/{page_N.png, frames.tres}.
`shoulder_px` hayvanda cidagonun capadan yuksekligi, `ref_share` turun
`back` orani: BodyFrames.scale_for(h) ikisinden olcegi buluyor.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "mesh"))
import pack_frames as P  # noqa: E402
import posterize  # noqa: E402

SRC = os.path.join(ROOT, "build", "beasts", "out")
LAYERS = ["back_arm", "back_leg", "torso_head", "front_leg", "front_arm"]
JOINTS = ["saddle", "head"]


def compose(fdir, layer, post):
    shade = posterize.flatten_array(P.load(os.path.join(fdir, "shade_%s.png" % layer)), post["tones"],
                                    post["display_lo"], post["display_hi"]).astype(np.float32) / 255.0
    alb = P.load(os.path.join(fdir, "albedo_%s.png" % layer)).astype(np.float32) / 255.0
    out = np.empty_like(shade)
    out[..., :3] = shade[..., :3] * alb[..., :3]
    out[..., 3] = shade[..., 3]
    return np.round(np.clip(out, 0, 1) * 255.0).astype(np.uint8)


def withers_px(sdir, meta):
    """Cidagonun capadan yuksekligi. meta'da 'trunk' olcusu varsa o; yoksa
    (bas dahil olculmus eski render) eyer isaretinin dinlenme karesindeki
    yuksekligi - sirtin ortasindaki ust nokta, cidagodan birkac yuzde alcak."""
    if meta.get("withers_from") == "trunk":
        return meta["withers_px"]
    j = json.load(open(os.path.join(sdir, "idle", "f00", "joints.json")))
    return meta["anchor_px"][1] - j["saddle"][1]


def pack_species(species, cfg, post, src):
    sdir = os.path.join(src, species)
    meta = json.load(open(os.path.join(sdir, "meta.json")))
    ax, ay = meta["anchor_px"]
    dest = os.path.join(P.DEST, "beast_" + species)
    os.makedirs(dest, exist_ok=True)
    shelf = P.Shelf()
    rects, offsets, joints, names, counts = [], [], [], [], []
    for clip, ccfg in cfg["clips"].items():
        n = int(ccfg["frames"])
        names.append(clip)
        counts.append(n)
        for i in range(n):
            fdir = os.path.join(sdir, clip, "f%02d" % i)
            j = json.load(open(os.path.join(fdir, "joints.json")))
            for k in JOINTS:
                joints.append((j[k][0] - ax, j[k][1] - ay))
            for layer in LAYERS:
                for kind in range(4):
                    piece, (x0, y0) = P.crop(compose(fdir, layer, post)) if kind == 0 else (None, (0, 0))
                    if piece is None:
                        rects.append((0, 0, 0, 0, 0))
                        offsets.append((0.0, 0.0))
                        continue
                    rects.append(shelf.put(piece))
                    offsets.append((x0 - ax, y0 - ay))
    pages = []
    for k, page in enumerate(shelf.pages):
        used = np.nonzero(page[..., 3].any(axis=1))[0]
        hgt = 1 << ((int(used.max()) + 1 + P.PAD if len(used) else P.PAD) - 1).bit_length()
        name = "page_%d.png" % k
        Image.fromarray(page[:hgt]).save(os.path.join(dest, name), optimize=True)
        pages.append("res://data/assets/characters/frames/beast_%s/%s" % (species, name))
    lines = [
        '[gd_resource type="Resource" script_class="BodyFrames" load_steps=2 format=3]', "",
        '[ext_resource type="Script" path="res://scripts/character/body_frames.gd" id="1_bf"]', "",
        "[resource]",
        'script = ExtResource("1_bf")',
        "pages = " + P.packed("PackedStringArray", pages, '"%s"'),
        "clip_names = " + P.packed("PackedStringArray", names, '"%s"'),
        "clip_frames = " + P.packed("PackedInt32Array", counts, "%d"),
        "shoulder_px = %.3f" % withers_px(sdir, meta),
        "ref_share = %.4f" % meta["back"],
        "rects = " + P.packed("PackedInt32Array", [v for r in rects for v in r], "%d"),
        "offsets = " + P.packed("PackedVector2Array", [v for o in offsets for v in o], "%.2f"),
        "joint_names = " + P.packed("PackedStringArray", JOINTS, '"%s"'),
        "joints = " + P.packed("PackedVector2Array", [v for p in joints for v in p], "%.2f"),
        "",
    ]
    open(os.path.join(dest, "frames.tres"), "w").write("\n".join(lines))
    size = sum(os.path.getsize(os.path.join(dest, f)) for f in os.listdir(dest))
    print("beast_%s: %d sayfa, %d kayit, %.1f MB" % (species, len(pages), len(rects), size / 1e6))


def main():
    cfg = json.load(open(os.path.join(PIPE, "beasts", "beasts.json")))
    post = json.load(open(os.path.join(PIPE, "config", "camera.json")))["posterize"]
    species = list(cfg["species"])
    if "--species" in sys.argv:
        species = sys.argv[sys.argv.index("--species") + 1].split(",")
    src = sys.argv[sys.argv.index("--src") + 1] if "--src" in sys.argv else SRC
    for s in species:
        pack_species(s, cfg, post, src)


if __name__ == "__main__":
    main()
