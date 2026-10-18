"""Tam harita, oyunun diliyle: alanlar ve renk bütün harita için bir kez
(gürültü tek, karolar arasında dikiş yok), render 4x4 karo (her karo komşu
bölgenin gölge düşüren arazisini de taşır), son işlem birleşik resme bir kez.

    python3 -I vg_full.py <çıktı klasörü> [samples]

Çıktı: <klasör>/map_5120.png (1.25 px / harita birimi) ve map_4096.png.
"""
import json
import os
import subprocess
import sys
import time

import cv2
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import vg_albedo  # noqa: E402
import vg_height  # noqa: E402

N_MAP = 4096
PX = 1.25            # piksel / harita birimi
N_OUT = int(N_MAP * PX)
T = 1024             # karo (harita birimi)
M = 320              # karo çevresindeki gölge payı
RS = T + 2 * M
TP = int(T * PX)


def log(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


def run(cmd, env=None):
    e = dict(os.environ)
    e.update(env or {})
    r = subprocess.run(cmd, env=e, capture_output=True, text=True)
    if r.returncode != 0 or "Traceback" in r.stderr:
        print(r.stdout[-3000:], r.stderr[-3000:])
        raise SystemExit("başarısız: " + " ".join(cmd))
    return r.stdout


def main():
    out = sys.argv[1]
    samples = sys.argv[2] if len(sys.argv) > 2 else "32"
    os.makedirs(out, exist_ok=True)
    fp = os.path.join(out, "fields.npz")
    if not os.path.exists(fp):
        log("alanlar (4096)")
        run([sys.executable, "-I", os.path.join(HERE, "vg_fields.py"), ".", "0", "0", str(N_MAP), fp])
        log("yükseklik")
        f = dict(np.load(fp))
        f["height"] = vg_height.height(f)
        np.savez_compressed(fp, **f)
    f = dict(np.load(fp))
    alb_p = os.path.join(out, "albedo_full.png")
    trees_p = os.path.join(out, "trees_full.json")
    if not os.path.exists(alb_p):
        log("albedo (%d)" % N_OUT)
        col, forest, steppe, mount, wb = vg_albedo.build(f, N_OUT)
        Image.fromarray((col * 255).astype(np.uint8)).save(alb_p)
        from scipy import ndimage as ndi
        foot = ndi.zoom(f["foot"], N_OUT / N_MAP, order=0)
        roads = ndi.zoom(f["roads"], N_OUT / N_MAP, order=1)
        pts = vg_albedo.tree_points(forest, steppe, mount, wb, foot, roads, N_MAP)
        json.dump(pts, open(trees_p, "w"))
        del col, forest, steppe, mount, wb
        log("ağaç", len(pts))
    albedo = np.asarray(Image.open(alb_p).convert("RGB"))
    trees = np.array(json.load(open(trees_p)), np.float32)
    Hp = np.pad(f["height"], M, mode="edge")
    Wp = np.pad(f["water"], M, mode="edge")
    mp = int(M * PX)
    Ap = np.pad(albedo, ((mp, mp), (mp, mp), (0, 0)), mode="edge")

    shade = np.zeros((N_OUT, N_OUT), np.uint16)
    ids = np.zeros((N_OUT, N_OUT, 3), np.uint8)
    alb_r = np.zeros((N_OUT, N_OUT, 3), np.uint8)
    n = N_MAP // T
    for ty in range(n):
        for tx in range(n):
            td = os.path.join(out, "tile_%d_%d" % (tx, ty))
            done = os.path.join(td, "albedo_r.png")
            if not os.path.exists(done):
                os.makedirs(td, exist_ok=True)
                rx0, ry0 = tx * T - M, ty * T - M
                np.savez_compressed(os.path.join(td, "fields.npz"), x0=rx0, y0=ry0, size=RS,
                                    height=Hp[ry0 + M:ry0 + M + RS, rx0 + M:rx0 + M + RS],
                                    water=Wp[ry0 + M:ry0 + M + RS, rx0 + M:rx0 + M + RS])
                ap = int(RS * PX)
                ax, ay = int((rx0 + M) * PX), int((ry0 + M) * PX)
                Image.fromarray(Ap[ay:ay + ap, ax:ax + ap]).save(os.path.join(td, "albedo.png"))
                sel = (trees[:, 0] >= rx0) & (trees[:, 0] < rx0 + RS) & (trees[:, 1] >= ry0) & (trees[:, 1] < ry0 + RS)
                tt = trees[sel].copy()
                tt[:, 0] -= rx0
                tt[:, 1] -= ry0
                json.dump([[round(float(a), 1), round(float(b), 1), int(c)] for a, b, c in tt],
                          open(os.path.join(td, "trees.json"), "w"))
                log("karo", tx, ty, "ağaç", int(sel.sum()))
                run([sys.executable, "-I", os.path.join(HERE, "vg_ink_scene.py"), td, os.environ.get("VG_LAYOUT", "out/layout.json"),
                     samples, str(TP)], env={"VG_CAM_SCALE": str(T)})
            y0, x0 = ty * TP, tx * TP
            sh = cv2.imread(os.path.join(td, "shade.png"), cv2.IMREAD_UNCHANGED)
            if sh.ndim == 3:
                sh = sh[..., :3].mean(-1)
            shade[y0:y0 + TP, x0:x0 + TP] = sh.astype(np.uint16)
            ids[y0:y0 + TP, x0:x0 + TP] = np.asarray(Image.open(os.path.join(td, "ids.png")).convert("RGB"))
            alb_r[y0:y0 + TP, x0:x0 + TP] = np.asarray(Image.open(done).convert("RGB"))
    cv2.imwrite(os.path.join(out, "shade.png"), shade)
    Image.fromarray(ids).save(os.path.join(out, "ids.png"))
    Image.fromarray(alb_r).save(os.path.join(out, "albedo_r.png"))
    log("son işlem")
    run([sys.executable, "-I", os.path.join(HERE, "vg_ink_post.py"), out, os.environ.get("VG_LAYOUT", "out/layout.json"),
         os.path.join(out, "map_5120.png")], env={"VG_VIG0": "0.55", "VG_VIG": "0.45"})
    Image.open(os.path.join(out, "map_5120.png")).resize((N_MAP, N_MAP), Image.LANCZOS).save(
        os.path.join(out, "map_4096.png"))
    log("TAMAM")


if __name__ == "__main__":
    main()
