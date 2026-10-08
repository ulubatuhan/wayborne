"""Kapi gorseli: yurume GIF'i, Godot oynaticisinin yakaladigi karelerden.

    python3 -I tools/figure_pipeline/qa/walk_gif.py

Render 2x olcekte (config/camera.json px_per_meter). "1x" = oyun olcegi (0.5,
en yakin komsu degil LANCZOS - oyundaki filtreyle ayni degil, yalniz izlemek icin);
"2x" = render olcegi birebir. Kare suresi clip.json fps'inden.
"""
import json
import os

from PIL import Image

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
F = os.path.join(ROOT, "build", "figures", "faz1")


def main():
    clip = json.load(open(os.path.join(PIPE, "config", "clip.json")))
    fps = float(clip.get("fps", 12))
    for src_dir, tag in ((os.path.join(F, "godot"), "smooth"), (os.path.join(F, "godot_flat"), "flat")):
        if not os.path.isdir(src_dir):
            continue
        names = sorted(n for n in os.listdir(src_dir) if n.startswith("f") and n.endswith(".png"))
        frames = [Image.open(os.path.join(src_dir, n)).convert("RGB") for n in names]
        out = os.path.join(F, "report")
        for scale, label in ((0.5, "1x"), (1.0, "2x")):
            seq = [im.resize((int(im.width * scale), int(im.height * scale)), Image.LANCZOS) for im in frames]
            p = os.path.join(out, "walk_%s_%s.gif" % (tag, label))
            seq[0].save(p, save_all=True, append_images=seq[1:], duration=int(1000 / fps), loop=0)
            print(p, len(seq))


if __name__ == "__main__":
    main()
