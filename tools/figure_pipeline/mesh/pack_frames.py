"""Render edilmis kareleri oyunun okudugu BodyFrames kumesine paketler.

    python3 -I tools/figure_pipeline/mesh/pack_frames.py [--variants male_average,...]

Girdi : build/figures/out/<varyant>/<klip>/fNN/{<katman>.png, id_<katman>.png, joints.json}
Cikti : data/assets/characters/frames/body_<varyant>/{page_N.png, frames.tres}

Katman basina dort tur resim (scripts/character/body_frames.gd KIND_*):
  body   = golge, oyun tonlarina indirilmis (mesh/posterize.py ile ayni sabit sinirlar)
  top    = ayni golge, alfa = id R kanali x kapsama (atlet/bra)
  bottom = ayni golge, alfa = id G kanali x kapsama (sort)
  module = id B (sac vb.; saf mankende bos - karakter yaratiminda eklenecek)
Giysi resminin alfasi bedeninkini asamaz (kenetlenir): giysi bedenin disina tasmaz.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "mesh"))
import posterize  # noqa: E402

OUT = os.path.join(ROOT, "build", "figures", "out")
DEST = os.path.join(ROOT, "data", "assets", "characters", "frames")
PAGE = 2048
PAD = 2
KINDS = ("body", "top", "bottom", "module")
JOINTS = {  # oyun adi <- render isareti
    "shoulder": "front_shoulder", "elbow_front": "front_elbow", "hand_front": "front_wrist",
    "fingers_front": "front_fingertip", "elbow_back": "back_elbow", "hand_back": "back_wrist",
    "hip": "pelvis", "neck": "neck", "head_top": "head_top_hint", "chin": "chin",
    "knee_front": "front_knee", "ankle_front": "front_ankle",
}


def load(p):
    return np.asarray(Image.open(p).convert("RGBA"))


def images_for(fdir, layer, post):
    shade = posterize.flatten_array(load(os.path.join(fdir, layer + ".png")), post["tones"],
                                    post["display_lo"], post["display_hi"])
    ident = load(os.path.join(fdir, "id_" + layer + ".png")).astype(np.float32) / 255.0
    a = shade[..., 3].astype(np.float32) / 255.0
    out = [shade]
    for ch in range(3):
        cov = np.minimum(ident[..., ch] * ident[..., 3], a)
        img = shade.copy()
        img[..., 3] = np.round(cov * 255.0).astype(np.uint8)
        out.append(img)
    return out


def crop(img):
    ys, xs = np.nonzero(img[..., 3] > 0)
    if len(xs) == 0:
        return None, (0, 0)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    return img[y0:y1, x0:x1], (int(x0), int(y0))


class Shelf:
    def __init__(self):
        self.pages = [np.zeros((PAGE, PAGE, 4), np.uint8)]
        self.x = self.y = self.row = PAD

    def put(self, img):
        h, w = img.shape[:2]
        if self.x + w + PAD > PAGE:
            self.x, self.y, self.row = PAD, self.y + self.row + PAD, 0
        if self.y + h + PAD > PAGE:
            self.pages.append(np.zeros((PAGE, PAGE, 4), np.uint8))
            self.x = self.y = PAD
            self.row = 0
        page = len(self.pages) - 1
        self.pages[page][self.y:self.y + h, self.x:self.x + w] = img
        rect = (page, self.x, self.y, w, h)
        self.x += w + PAD
        self.row = max(self.row, h)
        return rect


def packed(kind, values, fmt):
    return "%s(%s)" % (kind, ", ".join(fmt % v for v in values))


def pack_variant(variant, build, layers, post):
    body_id = "body_" + variant
    dest = os.path.join(DEST, body_id)
    os.makedirs(dest, exist_ok=True)
    shelf = Shelf()
    rects, offsets, joints, clip_names, clip_frames = [], [], [], [], []
    shoulder_px = None
    for clip, ccfg in build["clips"].items():
        cdir = os.path.join(OUT, variant, clip)
        n = int(ccfg["frames"])
        ax, ay = ccfg["anchor_px"]
        clip_names.append(clip)
        clip_frames.append(n)
        for i in range(n):
            fdir = os.path.join(cdir, "f%02d" % i)
            j = json.load(open(os.path.join(fdir, "joints.json")))
            for name, src in JOINTS.items():
                joints.append((j[src][0] - ax, j[src][1] - ay))
            if clip == "idle":
                shoulder_px = ay - j["front_shoulder"][1]
            for layer in layers:
                for img in images_for(fdir, layer, post):
                    piece, (x0, y0) = crop(img)
                    if piece is None:
                        rects.append((0, 0, 0, 0, 0))
                        offsets.append((0.0, 0.0))
                        continue
                    rects.append(shelf.put(piece))
                    offsets.append((x0 - ax, y0 - ay))
    page_paths = []
    for k, page in enumerate(shelf.pages):
        used = np.nonzero(page[..., 3].any(axis=1))[0]
        hgt = int(used.max()) + 1 + PAD if len(used) else PAD
        hgt = 1 << (hgt - 1).bit_length()  # 2'nin kuvveti: mipmap/GPU sikistirma dostu
        name = "page_%d.png" % k
        Image.fromarray(page[:hgt]).save(os.path.join(dest, name), optimize=True)
        page_paths.append("res://data/assets/characters/frames/%s/%s" % (body_id, name))
    lines = [
        '[gd_resource type="Resource" script_class="BodyFrames" load_steps=2 format=3]', "",
        '[ext_resource type="Script" path="res://scripts/character/body_frames.gd" id="1_bf"]', "",
        "[resource]",
        'script = ExtResource("1_bf")',
        "pages = " + packed("PackedStringArray", page_paths, '"%s"'),
        "clip_names = " + packed("PackedStringArray", clip_names, '"%s"'),
        "clip_frames = " + packed("PackedInt32Array", clip_frames, "%d"),
        "shoulder_px = %.3f" % shoulder_px,
        "rects = " + packed("PackedInt32Array", [v for r in rects for v in r], "%d"),
        "offsets = " + packed("PackedVector2Array", [v for o in offsets for v in o], "%.2f"),
        "joint_names = " + packed("PackedStringArray", list(JOINTS), '"%s"'),
        "joints = " + packed("PackedVector2Array", [v for p in joints for v in p], "%.2f"),
        "",
    ]
    open(os.path.join(dest, "frames.tres"), "w").write("\n".join(lines))
    size = sum(os.path.getsize(os.path.join(dest, f)) for f in os.listdir(dest))
    print("%s: %d sayfa, %d kayit, %.1f MB" % (body_id, len(page_paths), len(rects), size / 1e6))


def main():
    build = json.load(open(os.path.join(PIPE, "config", "build.json")))
    layers = json.load(open(os.path.join(PIPE, "config", "layers.json")))["layers"]
    post = json.load(open(os.path.join(PIPE, "config", "camera.json")))["posterize"]
    variants = build["variants"]
    if "--variants" in sys.argv:
        variants = sys.argv[sys.argv.index("--variants") + 1].split(",")
    for v in variants:
        pack_variant(v, build, layers, post)


if __name__ == "__main__":
    main()
