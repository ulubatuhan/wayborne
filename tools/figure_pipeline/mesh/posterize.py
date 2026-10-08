"""Oyun dili: render'i birkac duz tona indirir (tools/human_body_render.flatten ile
ayni ton seti). Fark: sinirlar resim basina yuzdelik DEGIL, config/camera.json'daki
isik modelinden turetilmis SABIT degerler - boylece bir katman ve tek parca render ayni
pikselde ayni tonu alir (yuzdelik, katmanin kendi dagilimina gore kayardi).

    python3 -I tools/figure_pipeline/mesh/posterize.py

Girdi : build/figures/faz1/frames/fNN/{full, <katmanlar>}.png
Cikti : build/figures/faz1/flat/fNN/ ayni adlarla. Alfa DEGISMEZ; yalniz duz (straight)
renk tona cekilir, yani kenar pikselleri de ayni tonu tasir.
"""
import json
import os

import numpy as np
from PIL import Image

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
SRC = os.path.join(ROOT, "build", "figures", "faz1", "frames")
DST = os.path.join(ROOT, "build", "figures", "faz1", "flat")


def flatten_array(rgba, tones, lo, hi):
    img = rgba.astype(np.float32) / 255.0
    lum = img[..., 0]
    level = np.clip((lum - lo) / max(hi - lo, 1e-4), 0.0, 1.0)
    index = np.clip((level * len(tones)).astype(int), 0, len(tones) - 1)
    tone = np.asarray(tones, np.float32)[index]
    out = img.copy()
    has = img[..., 3] > 0
    out[..., :3] = np.where(has[..., None], tone[..., None], img[..., :3])
    return (np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)


def main():
    cam = json.load(open(os.path.join(PIPE, "config", "camera.json")))["posterize"]
    layers = json.load(open(os.path.join(PIPE, "config", "layers.json")))["layers"]
    for f in sorted(d for d in os.listdir(SRC) if d.startswith("f")):
        os.makedirs(os.path.join(DST, f), exist_ok=True)
        for n in ["full"] + layers:
            a = np.asarray(Image.open(os.path.join(SRC, f, n + ".png")).convert("RGBA"))
            Image.fromarray(flatten_array(a, cam["tones"], cam["display_lo"], cam["display_hi"])).save(
                os.path.join(DST, f, n + ".png"))
        # eklem isaretleri ayni kareye ait; kopyala
        j = open(os.path.join(SRC, f, "joints.json")).read()
        open(os.path.join(DST, f, "joints.json"), "w").write(j)
    print("tamam", DST)


if __name__ == "__main__":
    main()
