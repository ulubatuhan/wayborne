"""Faz 1.4: her katmanin karelerini alfa kutusuna kirpar ve katman basina bir atlas
PNG'si + JSON (kare -> atlas dikdortgeni + capaya gore ofset) yazar.

    python3 -I tools/figure_pipeline/mesh/build_atlas.py [--src frames|flat]

Capa = config/camera.json ground_px (kalca altindaki zemin noktasi). Oynatici bir
kareyi, Sprite2D'yi capa + ofset konumuna koyarak birebir yeniden kurar.
"""
import json
import os

import numpy as np
from PIL import Image

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
FAZ1 = os.path.join(ROOT, "build", "figures", "faz1")


def main():
    import sys
    src = sys.argv[sys.argv.index("--src") + 1] if "--src" in sys.argv else "frames"
    FRAMES = os.path.join(FAZ1, src)
    OUT = os.path.join(FAZ1, "atlas" if src == "frames" else "atlas_" + src)
    layers = json.load(open(os.path.join(PIPE, "config", "layers.json")))["layers"]
    cam = json.load(open(os.path.join(PIPE, "config", "camera.json")))
    gx, gy = cam["ground_px"]
    frames = sorted(d for d in os.listdir(FRAMES) if d.startswith("f"))
    os.makedirs(OUT, exist_ok=True)
    meta = {"anchor_px": [gx, gy], "canvas": cam["canvas"], "layers": layers,
            "frames": [int(f[1:]) for f in frames], "atlas": {}}
    for layer in layers:
        crops = []
        for f in frames:
            im = Image.open(os.path.join(FRAMES, f, layer + ".png")).convert("RGBA")
            a = np.asarray(im)[..., 3]
            ys, xs = np.nonzero(a)
            if len(xs) == 0:
                crops.append((f, None, (0, 0)))
                continue
            box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
            crops.append((f, im.crop(box), (box[0] - gx, box[1] - gy)))
        # tek satir paketleme, kareler arasi 2 px bosluk (filtrede tasma olmasin)
        w = sum(c[1].width + 2 for c in crops if c[1]) + 2
        h = max(c[1].height for c in crops if c[1]) + 4
        atlas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        x = 2
        entries = {}
        for f, img, off in crops:
            if img is None:
                entries[f] = None
                continue
            atlas.paste(img, (x, 2))
            entries[f] = {"rect": [x, 2, img.width, img.height], "offset": list(off)}
            x += img.width + 2
        path = os.path.join(OUT, layer + ".png")
        atlas.save(path)
        meta["atlas"][layer] = {"png": layer + ".png", "frames": entries}
        print(layer, atlas.size)
    json.dump(meta, open(os.path.join(OUT, "atlas.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
