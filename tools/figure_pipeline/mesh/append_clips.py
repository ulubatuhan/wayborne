"""Yeni klipleri var olan kare kumelerine EKLER (eski klipleri yeniden render
etmeden).

    python -I tools/figure_pipeline/mesh/append_clips.py --clips sit_box [--variants male_average] [--items peasant_shirt]

Neden: pack_frames.py / pack_outfits.py her kumeyi build/figures/out'taki
butun kliplerden bastan kurar. Eski render'lar bu makinede yok (Codespace'te
uretildi); yeni bir durusu (sit_box, 2026-10-20) eklemek icin butun klipleri
yeniden render etmek saatler surerdi. Bu arac kumenin frames.tres'ini okur,
istenen klibi (varsa once cikarip) sona ekler, yeni parcalari yeni
page_N.png'lere yazar. Eski indisler degismez: girdi indisi
((klip_tabani + kare) * 5 + katman) * 4 + tur, yeni klip sona eklendigi icin
eski kliplerin tabani ayni kalir (BodyFrames).

Govde: build/figures/out/<varyant>/<klip>/fNN (render_frames.py).
Giysi: build/figures/outfits/<varyant>/<kalem>/<klip>/fNN (render_outfits.py).
Bir giysinin o klip icin render'i yoksa kume degismez ve bu soylenir: bos
girdili bir klip "var" sayilip giysiyi gorunmez yapardi (WalkFigure.shared_clips).
"""
import json
import os
import re
import sys

import numpy as np
from PIL import Image

ROOT = os.environ.get("WAYBORNE_ROOT") or os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "mesh"))
sys.path.insert(0, os.path.join(PIPE, "beasts"))
import pack_frames as P  # noqa: E402
import pack_beasts  # noqa: E402
import pack_outfits as PO  # noqa: E402

LAYERS_N = 5
KINDS_N = 4
JOINTS_N = len(P.JOINTS)


def read_tres(path):
    text = open(path, encoding="utf-8").read()
    data = {}
    for key, kind, body in re.findall(r"^(\w+) = (Packed\w+)\((.*)\)$", text, re.M):
        if kind == "PackedStringArray":
            data[key] = re.findall(r'"([^"]*)"', body)
        elif kind == "PackedInt32Array":
            data[key] = [int(x) for x in body.split(",") if x.strip()]
        else:
            data[key] = [float(x) for x in body.split(",") if x.strip()]
    for key in ("shoulder_px", "texel_scale"):
        m = re.search(r"^%s = ([-0-9.]+)$" % key, text, re.M)
        if m:
            data[key] = float(m.group(1))
    return data


def write_tres(path, d, body):
    lines = [
        '[gd_resource type="Resource" script_class="BodyFrames" load_steps=2 format=3]', "",
        '[ext_resource type="Script" path="res://scripts/character/body_frames.gd" id="1_bf"]', "",
        "[resource]",
        'script = ExtResource("1_bf")',
        "pages = " + P.packed("PackedStringArray", d["pages"], '"%s"'),
        "clip_names = " + P.packed("PackedStringArray", d["clip_names"], '"%s"'),
        "clip_frames = " + P.packed("PackedInt32Array", d["clip_frames"], "%d"),
        "shoulder_px = %.3f" % d["shoulder_px"],
    ]
    if "texel_scale" in d:
        lines.append("texel_scale = %.4f" % d["texel_scale"])
    lines += [
        "rects = " + P.packed("PackedInt32Array", d["rects"], "%d"),
        "offsets = " + P.packed("PackedVector2Array", d["offsets"], "%.2f"),
    ]
    if body:
        lines += [
            "joint_names = " + P.packed("PackedStringArray", d["joint_names"], '"%s"'),
            "joints = " + P.packed("PackedVector2Array", d["joints"], "%.2f"),
            "weapon_angles = " + P.packed("PackedFloat32Array", d["weapon_angles"], "%.4f"),
            "draws = " + P.packed("PackedFloat32Array", d["draws"], "%.3f"),
        ]
    lines.append("")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines))


def remove_clip(d, clip, body):
    """Klip zaten varsa girdilerini cikarir (yeniden eklenmeden once)."""
    if clip not in d["clip_names"]:
        return
    k = d["clip_names"].index(clip)
    base = sum(d["clip_frames"][:k])
    n = d["clip_frames"][k]
    e0, e1 = base * LAYERS_N * KINDS_N, (base + n) * LAYERS_N * KINDS_N
    d["rects"] = d["rects"][:e0 * 5] + d["rects"][e1 * 5:]
    d["offsets"] = d["offsets"][:e0 * 2] + d["offsets"][e1 * 2:]
    if body:
        d["joints"] = d["joints"][:base * JOINTS_N * 2] + d["joints"][(base + n) * JOINTS_N * 2:]
        d["weapon_angles"] = d["weapon_angles"][:base] + d["weapon_angles"][base + n:]
        d["draws"] = d["draws"][:base] + d["draws"][base + n:]
    del d["clip_names"][k]
    del d["clip_frames"][k]


def trim_pages(d, dest):
    """Artik hicbir girdinin kullanmadigi sondaki sayfalari siler."""
    used = max((d["rects"][i] for i in range(0, len(d["rects"]), 5) if d["rects"][i + 3] > 0), default=0)
    while len(d["pages"]) > used + 1:
        p = d["pages"].pop()
        f = os.path.join(dest, os.path.basename(p))
        for path in (f, f + ".import"):
            if os.path.exists(path):
                os.remove(path)


def save_pages(shelf, dest, ident, first_index):
    paths = []
    for k, page in enumerate(shelf.pages):
        used = np.nonzero(page[..., 3].any(axis=1))[0]
        if len(used) == 0:
            continue
        hgt = 1 << ((int(used.max()) + 1 + P.PAD) - 1).bit_length()
        name = "page_%d.png" % (first_index + len(paths))
        Image.fromarray(page[:hgt]).save(os.path.join(dest, name), optimize=True)
        paths.append("res://data/assets/characters/frames/%s/%s" % (ident, name))
    return paths


def append_body(variant, clips, build, layers, post):
    ident = "body_" + variant
    dest = os.path.join(P.DEST, ident)
    path = os.path.join(dest, "frames.tres")
    d = read_tres(path)
    for clip in clips:
        remove_clip(d, clip, True)
    trim_pages(d, dest)
    shelf = P.Shelf()
    first = len(d["pages"])
    for clip in clips:
        ccfg = build["clips"][clip]
        n = int(ccfg["frames"])
        ax, ay = ccfg["anchor_px"]
        for i in range(n):
            fdir = os.path.join(P.OUT, variant, clip, "f%02d" % i)
            j = json.load(open(os.path.join(fdir, "joints.json")))
            for name, src in P.JOINTS.items():
                d["joints"] += [j[src][0] - ax, j[src][1] - ay]
            d["weapon_angles"].append(float(j.get("weapon", 0.0)))
            d["draws"].append(float(j.get("draw", 0.0)))
            for layer in layers:
                for img in P.images_for(fdir, layer, post):
                    piece, (x0, y0) = P.crop(img)
                    if piece is None:
                        d["rects"] += [0, 0, 0, 0, 0]
                        d["offsets"] += [0.0, 0.0]
                        continue
                    page, x, y, w, h = shelf.put(piece)
                    d["rects"] += [first + page, x, y, w, h]
                    d["offsets"] += [x0 - ax, y0 - ay]
        d["clip_names"].append(clip)
        d["clip_frames"].append(n)
    d["pages"] += save_pages(shelf, dest, ident, first)
    write_tres(path, d, True)
    print("%s: +%s, %d sayfa" % (ident, ",".join(clips), len(d["pages"])))


def append_outfit(variant, item, clips, build, layers, post):
    ident = "outfit_%s_%s" % (item, variant)
    dest = os.path.join(P.DEST, ident)
    path = os.path.join(dest, "frames.tres")
    if not os.path.exists(path):
        return
    missing = [c for c in clips if not os.path.isdir(os.path.join(PO.SRC, variant, item, c))]
    if missing:
        print("RENDER YOK, eklenmedi:", ident, missing)
        return
    d = read_tres(path)
    for clip in clips:
        remove_clip(d, clip, False)
    trim_pages(d, dest)
    shelf = P.Shelf()
    first = len(d["pages"])
    for clip in clips:
        ccfg = build["clips"][clip]
        n = int(ccfg["frames"])
        ax, ay = ccfg["anchor_px"]
        for i in range(n):
            fdir = os.path.join(PO.SRC, variant, item, clip, "f%02d" % i)
            for layer in layers:
                have = os.path.exists(os.path.join(fdir, "shade_%s.png" % layer))
                for kind in range(KINDS_N):
                    full = pack_beasts.compose(fdir, layer, post) if kind == 0 and have else None
                    piece, (x0, y0) = P.crop(full) if full is not None else (None, (0, 0))
                    if piece is None:
                        d["rects"] += [0, 0, 0, 0, 0]
                        d["offsets"] += [0.0, 0.0]
                        continue
                    piece, (x0, y0) = PO.shrink(piece, x0, y0, full.shape[1] / float(PO.CANVAS_W))
                    page, x, y, w, h = shelf.put(piece)
                    d["rects"] += [first + page, x, y, w, h]
                    d["offsets"] += [x0 - ax, y0 - ay]
        d["clip_names"].append(clip)
        d["clip_frames"].append(n)
    d["pages"] += save_pages(shelf, dest, ident, first)
    write_tres(path, d, False)
    print("%s: +%s" % (ident, ",".join(clips)), flush=True)


def main():
    build = json.load(open(os.path.join(PIPE, "config", "build.json")))
    layers = json.load(open(os.path.join(PIPE, "config", "layers.json")))["layers"]
    post = json.load(open(os.path.join(PIPE, "config", "camera.json")))["posterize"]
    clips = sys.argv[sys.argv.index("--clips") + 1].split(",")
    variants = build["variants"]
    if "--variants" in sys.argv:
        variants = sys.argv[sys.argv.index("--variants") + 1].split(",")
    items = list(json.load(open(os.path.join(PIPE, "config", "outfits.json")))["items"])
    if "--items" in sys.argv:
        items = sys.argv[sys.argv.index("--items") + 1].split(",")
    for v in variants:
        append_body(v, clips, build, layers, post)
        if "--body-only" in sys.argv:
            continue
        for it in items:
            append_outfit(v, it, clips, build, layers, post)


if __name__ == "__main__":
    main()
