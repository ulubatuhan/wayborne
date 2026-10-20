"""render_props.py ciktisini oyuna paketler: golge (dort tona indirilmis) x albedo,
katman basina sinirina kirpilmis PNG ve tek bir kaynak dosyasi.

    python3 -I tools/figure_pipeline/props/pack_props.py

Cikti : data/assets/props/<id>/<katman>.png
        data/assets/props/props.tres  (PropSheet: id -> {ppm, katmanlar, pivotlar})

Konumlar cipa noktasina (modelin yere bastigi orta nokta) gore piksel; oyun
`ppm` ile metreye, oradan kendi olcegine ceviriyor. Meta .tres, .json degil:
Web ihraci yalniz kaynaklari tasiyor (BeastSkin'in ayni sebebi).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.environ.get("WAYBORNE_ROOT") or os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "mesh"))
import posterize  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "tools", "npr"))
import ink_pass  # noqa: E402  ortak mürekkep geçişi (Y-G02)

SRC = os.path.join(ROOT, "build", "props")
DST = os.path.join(ROOT, "data", "assets", "props")
CAM = json.load(open(os.path.join(PIPE, "config", "camera.json")))["posterize"]


def compose(shade_path, albedo_path):
    s = posterize.flatten_array(np.asarray(Image.open(shade_path).convert("RGBA")),
                                CAM["tones"], CAM["display_lo"], CAM["display_hi"]).astype(np.float32) / 255
    a = np.asarray(Image.open(albedo_path).convert("RGBA")).astype(np.float32) / 255
    out = s.copy()
    out[..., :3] = s[..., :3] * a[..., :3]
    return Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8))


def _gd(v):
    if isinstance(v, dict):
        return "{" + ", ".join('"%s": %s' % (k, _gd(x)) for k, x in v.items()) + "}"
    if isinstance(v, (list, tuple)):
        return "[" + ", ".join(_gd(x) for x in v) + "]"
    if isinstance(v, str):
        return '"%s"' % v
    if isinstance(v, bool):
        return "true" if v else "false"
    return repr(round(float(v), 3))


def main():
    sheet = {}
    for pid in sorted(os.listdir(SRC)):
        meta_path = os.path.join(SRC, pid, "meta.json")
        if not os.path.exists(meta_path):
            continue
        meta = json.load(open(meta_path))
        ax, ay = meta["anchor"]
        os.makedirs(os.path.join(DST, pid), exist_ok=True)
        layers = {}
        for name in meta["layers"]:
            img = compose(os.path.join(SRC, pid, name + "__shade.png"), os.path.join(SRC, pid, name + "__albedo.png"))
            bb = img.getchannel("A").point(lambda a: 255 if a > 4 else 0).getbbox()
            if bb is None:
                continue
            img = ink_pass.light_pass(img.crop(bb))
            img.save(os.path.join(DST, pid, name + ".png"), optimize=True)
            # katmanin sol ust kosesi, cipaya gore
            layers[name] = [bb[0] - ax, bb[1] - ay]
        sheet[pid] = {
            "ppm": meta["ppm"], "view": meta["view"], "layers": layers,
            "pivots": {k: [x - ax, y - ay] for k, (x, y) in meta["pivots"].items()},
            "size_m": meta["size_m"],
        }
    tres = ('[gd_resource type="Resource" script_class="PropSheet" load_steps=2 format=3]\n\n'
            '[ext_resource type="Script" path="res://scripts/ui/prop_sheet.gd" id="1"]\n\n'
            '[resource]\nscript = ExtResource("1")\nprops = %s\n' % _gd(sheet))
    open(os.path.join(DST, "props.tres"), "w").write(tres)
    print("paketlendi", len(sheet), "esya")


if __name__ == "__main__":
    main()
