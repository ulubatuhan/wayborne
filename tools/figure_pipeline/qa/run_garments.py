"""Giysi modullerinin hakem tablosu.

    python3 -I tools/figure_pipeline/qa/run_garments.py --variant male_average --clip walk \
        --garments shoes03,male_casualsuit01 [--frames 0,6] [--validate]

--validate: ayni karelerde bindirme sirasi TERS (giysi bedenden once) - skin_bleed
bunu yakalamazsa hakem gecersizdir (RULES 1).
Cikti: build/figures/garments_qa/<varyant>_<klip>/{table.json, fNN_*.png}
"""
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import faz1_tests as f1  # noqa: E402
import garment_tests as gt  # noqa: E402

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")


def arg(name, default=None):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default


def sheet(fdir, gids, layers, path):
    comp = f1.over([img for _s, img in gt.layer_stack(fdir, gids, layers)])
    truth = f1.premul(f1.load_rgba(os.path.join(fdir, "garments", "truth.png")))
    nude = f1.over([f1.load_rgba(os.path.join(fdir, n + ".png")) for n in layers])
    bg = np.ones(comp.shape[:2] + (3,)) * 0.85
    tiles = [np.clip(c[..., :3] + bg * (1 - c[..., 3:4]), 0, 1) for c in (nude, comp, truth)]
    Image.fromarray((np.concatenate(tiles, axis=1) * 255).astype(np.uint8)).save(path)


def main():
    variant, clip = arg("--variant"), arg("--clip")
    gids = arg("--garments").split(",")
    layers = json.load(open(os.path.join(PIPE, "config", "layers.json")))["layers"]
    base = os.path.join(ROOT, "build", "figures", "out", variant, clip)
    frames = [int(x) for x in arg("--frames").split(",")] if "--frames" in sys.argv else sorted(
        int(d[1:]) for d in os.listdir(base) if d.startswith("f") and
        os.path.exists(os.path.join(base, d, "garments", "garments.json")))
    out = os.path.join(ROOT, "build", "figures", "garments_qa", "%s_%s" % (variant, clip))
    os.makedirs(out, exist_ok=True)
    rows = []
    for i in frames:
        fdir = os.path.join(base, "f%02d" % i)
        row = {"frame": i,
               "skin_bleed": gt.skin_bleed(fdir, gids, layers, diff_path=os.path.join(out, "f%02d_bleed.png" % i)),
               "composite_equals_truth": gt.composite_equals_truth(
                   fdir, gids, layers, os.path.join(out, "f%02d_diff.png" % i)),
               "no_backfaces": {g: gt.no_backfaces(fdir, g) for g in gids
                                if os.path.exists(os.path.join(fdir, "garments", "magenta_%s.png" % g))}}
        if "--validate" in sys.argv:
            row["validate_reversed_order"] = gt.skin_bleed(
                fdir, gids, layers, garments_first=True, diff_path=os.path.join(out, "f%02d_bleed_reversed.png" % i))
        sheet(fdir, gids, layers, os.path.join(out, "f%02d_sheet.png" % i))
        rows.append(row)
        print(json.dumps(row))
    json.dump(rows, open(os.path.join(out, "table.json"), "w"), indent=1)
    n = len(rows)
    print("skin_bleed %d/%d, composite %d/%d, no_backfaces %d/%d" % (
        sum(r["skin_bleed"]["pass"] for r in rows), n,
        sum(r["composite_equals_truth"]["pass"] for r in rows), n,
        sum(all(v["pass"] for v in r["no_backfaces"].values()) for r in rows), n))


if __name__ == "__main__":
    main()
