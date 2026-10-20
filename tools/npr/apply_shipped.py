"""Hafif mürekkep geçişini (ink_pass.light_pass) oyundaki hazır resimlere bir
kez uygular (görev Y-G02). Ara render'lar her makinede yok; paketleyiciler
(pack_props.py, road_post.py) geçişi artık kendileri uyguluyor, bu araç
yalnız bugünkü dosyalar için. İki kez uygulanmasın diye uygulanan dosyalar
data/assets/npr_applied.json'da tutulur.

    python -X utf8 tools/npr/apply_shipped.py
"""
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
from ink_pass import light_pass  # noqa: E402
from PIL import Image  # noqa: E402

LOG = os.path.join(ROOT, "data", "assets", "npr_applied.json")


def targets():
    out = sorted(glob.glob(os.path.join(ROOT, "data", "assets", "props", "*", "*.png")))
    for layer in ("mid", "ground"):
        out += sorted(glob.glob(os.path.join(ROOT, "data", "assets", "ui", "road", "*", layer + ".png")))
    return out


def main():
    done = set(json.load(open(LOG))) if os.path.exists(LOG) else set()
    n = 0
    for path in targets():
        rel = os.path.relpath(path, ROOT).replace("\\", "/")
        if rel in done:
            continue
        light_pass(Image.open(path)).save(path, optimize=True)
        done.add(rel)
        n += 1
    json.dump(sorted(done), open(LOG, "w"), indent=1)
    print("uygulandı:", n, "toplam:", len(done))


if __name__ == "__main__":
    main()


def tame_colours(path):
    """Stil kuralı (doygun mavi, mor, yeşil yok): eşya resminde doygun mavi ve
    yeşil pikseller soluk arduvaz ve zeytine çekilir, parlaklık korunur. Köy
    evlerinin turkuaz çatıları ve izometrik binaların yeşilleri (2026-10-20)."""
    import numpy as np
    img = Image.open(path).convert("RGBA")
    a = np.asarray(img).astype(np.float32) / 255.0
    rgb, al = a[..., :3], a[..., 3]
    mx, mn = rgb.max(-1), rgb.min(-1)
    sat = (mx - mn) / np.maximum(mx, 1e-3)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    blue = (b > r + 0.05) & (sat > 0.30)
    green = (g > r + 0.06) & (g > b + 0.02) & (sat > 0.30)
    lum = (rgb * np.array([0.299, 0.587, 0.114], np.float32)).sum(-1, keepdims=True)
    slate = lum * np.array([0.92, 0.97, 1.06], np.float32)
    olive = lum * np.array([1.02, 1.03, 0.86], np.float32)
    out = rgb.copy()
    out[blue] = (rgb * 0.3 + slate * 0.7)[blue]
    out[green] = (rgb * 0.3 + olive * 0.7)[green]
    res = np.dstack([np.clip(out, 0, 1), al])
    Image.fromarray((res * 255).astype(np.uint8), "RGBA").save(path, optimize=True)


TAMED = ["house_1", "house_2", "iso_bell_tower", "iso_house_1", "iso_house_2", "iso_stable"]

if __name__ == "__main__" and "--tame" in sys.argv:
    for pid in TAMED:
        for path in glob.glob(os.path.join(ROOT, "data", "assets", "props", pid, "*.png")):
            tame_colours(path)
    print("renkler yumuşatıldı:", ", ".join(TAMED))
