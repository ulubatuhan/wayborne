"""Faz 2+ hakemleri: build/figures/out altindaki BUTUN varyant x klip x karede.

    python3 -I tools/figure_pipeline/qa/run_build.py [--variants a,b] [--clips walk,idle]

Faz 1'in dort testi (godot haric: o kare kumesinin kendi oynaticisinda,
test_body_frames.gd) + iki yeni:
  grounded: yurume/duruste en alt bacak pikseli capanin (zemin) +-GROUND_PX'i
            icinde (binicide kalca capa, test yok).
  garment_inside: id (atlet/bra/sort) kapsamasi her katmanda bedenin
            alfasini asmiyor (giysi bedenin disina tasmiyor) - 1/255 tolerans.
Cikti: build/figures/qa/{results.json, results.md}
"""
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import faz1_tests as T  # noqa: E402

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
OUT = os.path.join(ROOT, "build", "figures", "out")
REP = os.path.join(ROOT, "build", "figures", "qa")
GROUND_PX = 3.0
LEGS = ("back_leg", "front_leg")


def arg(name):
    return sys.argv[sys.argv.index(name) + 1].split(",") if name in sys.argv else None


def frame_tests(d, layers, clip_cfg, anatomy):
    r = {}
    layers = clip_cfg.get("layers", layers)
    if not os.path.exists(os.path.join(d, "full.png")):
        # Katman alt kumesi (walk_boots): tek parca yok, yalniz katman testleri.
        worst = 0.0
        for n in layers:
            a = T.load_rgba(os.path.join(d, n + ".png"))[..., 3]
            idimg = T.load_rgba(os.path.join(d, "id_" + n + ".png"))
            worst = max(worst, float((idimg[..., :3].max(axis=2) * idimg[..., 3] - a).max()))
        r["garment_inside"] = {"worst_excess_x255": worst * 255.0, "pass": worst <= 1.0 / 255.0 + 1e-9}
        ay = clip_cfg["anchor_px"][1]
        lowest = max(int(np.nonzero(T.load_rgba(os.path.join(d, n + ".png"))[..., 3].any(axis=1))[0].max())
                     for n in LEGS)
        r["grounded"] = {"lowest_minus_ground": lowest + 1 - ay, "pass": abs(lowest + 1 - ay) <= GROUND_PX}
        return r
    r["composite_equals_full"] = T.composite_equals_full(
        [os.path.join(d, n + ".png") for n in layers], os.path.join(d, "full.png"))
    if os.path.exists(os.path.join(d, "magenta.png")):
        # Gecme Faz 1'deki gibi: tek parca ve BIRLESIK magenta 0. Katman basina
        # sayi bilgi icin: bir uzuv katmani kok kesiginden icini gosterir ve
        # o delik birlesimde govde katmaninin altinda kalir (QUESTIONS #10).
        per = {n: T.magenta_pixels(os.path.join(d, "magenta_" + n + ".png"))[0] for n in layers}
        full = T.magenta_pixels(os.path.join(d, "magenta.png"))[0]
        comp = T.over([T.load_rgba(os.path.join(d, "magenta_" + n + ".png")) for n in layers])
        al = np.clip(comp[..., 3:4], 1e-6, 1)
        comp_n = np.concatenate([np.where(comp[..., 3:4] > 0, comp[..., :3] / al, 0), comp[..., 3:4]], 2)
        r_, g_, b_, a_ = (comp_n[..., k] for k in range(4))
        composite = int(((a_ > 0.1) & (r_ > 0.6) & (b_ > 0.6) & (g_ < 0.35)).sum())
        r["no_backfaces"] = {"full": full, "composite": composite, "layers_info": per,
                             "pass": full == 0 and composite == 0}
    if not clip_cfg.get("seated"):
        p = T.proportions(os.path.join(d, "full.png"), os.path.join(d, "joints.json"), anatomy,
                          {"front_arm": os.path.join(d, "front_arm.png")})
        r["proportions"] = {"pass": p["pass"], **{k: v.get("value", v.get("outside"))
                                                    for k, v in p["checks"].items()}}
        ay = clip_cfg["anchor_px"][1]
        lowest = max(int(np.nonzero(T.load_rgba(os.path.join(d, n + ".png"))[..., 3].any(axis=1))[0].max())
                     for n in LEGS)
        r["grounded"] = {"lowest_minus_ground": lowest + 1 - ay, "pass": abs(lowest + 1 - ay) <= GROUND_PX}
    full_a = T.load_rgba(os.path.join(d, "full.png"))[..., 3]
    edge = max(full_a[0].max(), full_a[-1].max(), full_a[:, 0].max(), full_a[:, -1].max())
    # Tuvalden tasan kare kirpilir: yatan pozda bas bir kez kesik cikti.
    r["inside_canvas"] = {"edge_alpha": float(edge), "pass": float(edge) <= 1.0 / 255.0}
    worst = 0.0
    for n in layers:
        a = T.load_rgba(os.path.join(d, n + ".png"))[..., 3]
        idimg = T.load_rgba(os.path.join(d, "id_" + n + ".png"))
        cov = idimg[..., :3].max(axis=2) * idimg[..., 3]
        worst = max(worst, float((cov - a).max()))
    r["garment_inside"] = {"worst_excess_x255": worst * 255.0, "pass": worst <= 1.0 / 255.0 + 1e-9}
    return r


def main():
    build = json.load(open(os.path.join(PIPE, "config", "build.json")))
    layers = json.load(open(os.path.join(PIPE, "config", "layers.json")))["layers"]
    anatomy = os.path.join(PIPE, "config", "anatomy.json")
    variants = arg("--variants") or build["variants"]
    clips = arg("--clips") or list(build["clips"])
    os.makedirs(REP, exist_ok=True)
    res = {}
    for v in variants:
        for c in clips:
            n = int(build["clips"][c]["frames"])
            rows = {}
            for i in range(n):
                d = os.path.join(OUT, v, c, "f%02d" % i)
                if os.path.exists(os.path.join(d, "joints.json")):
                    rows["f%02d" % i] = frame_tests(d, layers, build["clips"][c], anatomy)
            res["%s/%s" % (v, c)] = rows
    json.dump(res, open(os.path.join(REP, "results.json"), "w"), indent=1, default=float)
    tests = ("composite_equals_full", "no_backfaces", "proportions", "grounded", "garment_inside", "inside_canvas")
    lines = ["| varyant/klip | kare | " + " | ".join(tests) + " |", "|---|---|" + "---|" * len(tests)]
    for key, rows in res.items():
        cells = []
        for t in tests:
            vals = [r[t]["pass"] for r in rows.values() if t in r]
            cells.append("%d/%d" % (sum(vals), len(vals)) if vals else "-")
        lines.append("| %s | %d | %s |" % (key, len(rows), " | ".join(cells)))
    open(os.path.join(REP, "results.md"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
