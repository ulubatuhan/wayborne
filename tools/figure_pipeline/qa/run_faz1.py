"""Faz 1 hakemlerini TUM karelerde calistirir, tablo + fark goruntuleri yazar.

    python3 -I tools/figure_pipeline/qa/run_faz1.py

Cikti: build/figures/faz1/report/{results.json, results.md, diffs/...}
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check_config  # noqa: E402
import faz1_tests as T  # noqa: E402

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
F = os.path.join(ROOT, "build", "figures", "faz1")
REP = os.path.join(F, "report")
BG = np.array([58, 54, 50], float) / 255.0


def over_bg(premul_img):
    return premul_img[..., :3] + BG * (1.0 - premul_img[..., 3:4])


def opaque_rgba(rgb):
    return np.concatenate([rgb, np.ones(rgb.shape[:2] + (1,))], 2)


def save_premul(arr, path):
    a = arr.copy()
    al = np.clip(a[..., 3:4], 1e-6, 1)
    rgb = np.where(a[..., 3:4] > 0, a[..., :3] / al, 0)
    Image.fromarray((np.clip(np.concatenate([rgb, a[..., 3:4]], 2), 0, 1) * 255 + .5).astype(np.uint8)).save(path)


def main():
    src = sys.argv[sys.argv.index("--src") + 1] if "--src" in sys.argv else "frames"
    frames_root = os.path.join(F, src)
    rep = REP if src == "frames" else os.path.join(F, "report_" + src)
    godot_dir = os.path.join(F, "godot" if src == "frames" else "godot_" + src)
    check_config.check(os.path.join(F, "rig_bones.json"))
    layers = json.load(open(os.path.join(PIPE, "config", "layers.json")))["layers"]
    anatomy = os.path.join(PIPE, "config", "anatomy.json")
    frames = sorted(d for d in os.listdir(frames_root) if d.startswith("f"))
    os.makedirs(os.path.join(rep, "diffs"), exist_ok=True)
    res = {}
    ankles = []
    for f in frames:
        d = os.path.join(frames_root, f)
        r = {}
        r["composite_equals_full"] = T.composite_equals_full(
            [os.path.join(d, n + ".png") for n in layers], os.path.join(d, "full.png"),
            os.path.join(rep, "diffs", f + "_composite.png"))
        if os.path.exists(os.path.join(d, "magenta.png")):
            comp = T.over([T.load_rgba(os.path.join(d, "magenta_" + n + ".png")) for n in layers])
            mp = os.path.join(rep, "diffs", f + "_magenta_composite.png")
            save_premul(comp, mp)
            r["no_backfaces"] = {"composite": T.no_backfaces(mp)["magenta_pixels"],
                                 "full": T.no_backfaces(os.path.join(d, "magenta.png"))["magenta_pixels"]}
            r["no_backfaces"]["pass"] = r["no_backfaces"]["composite"] == 0 and r["no_backfaces"]["full"] == 0
        p = T.proportions(os.path.join(d, "full.png"), os.path.join(d, "joints.json"), anatomy,
                          {"front_arm": os.path.join(d, "front_arm.png")},
                          os.path.join(rep, "diffs", f + "_proportions.png"))
        r["proportions"] = {"pass": p["pass"], **{k: v.get("value", v.get("outside")) for k, v in p["checks"].items()}}
        g = os.path.join(godot_dir, f + ".png")
        if os.path.exists(g):
            comp = T.over([T.load_rgba(os.path.join(d, n + ".png")) for n in layers])
            blender = opaque_rgba(over_bg(comp))
            god = T.load_rgba(g)
            r["godot_equals_blender"] = T.image_diff(god, blender, os.path.join(rep, "diffs", f + "_godot.png"))
        j = json.load(open(os.path.join(d, "joints.json")))
        ankles.append((j["front_ankle"], j["back_ankle"]))
        res[f] = r

    # Ayak kaymasi (bilgi): yere basan (en alttaki) ayak bileginin kare arasi yatay
    # hareketi. Oyun figuru FigureRig'in adim boyuyla ilerletir; burada olculen,
    # kalcaya gore ayak geri gidisi. Ideal: basan ayak her karede ayni hizda gerilemeli.
    stance = []
    for i in range(len(ankles)):
        fa, ba = ankles[i]
        foot = fa if fa[1] >= ba[1] else ba
        stance.append(foot)
    summary = {}
    for test in ("composite_equals_full", "no_backfaces", "proportions", "godot_equals_blender"):
        vals = [res[f][test]["pass"] for f in res if test in res[f]]
        summary[test] = {"passed": sum(vals), "of": len(vals)}
    out = {"summary": summary, "frames": res, "stance_ankle_px": stance}
    json.dump(out, open(os.path.join(rep, "results.json"), "w"), indent=1, default=float)

    lines = ["| kare | birlesik=tek (px>8 / ort) | ic yuz (birlesik/tek) | el/bas | onkol/ust kol | baldir/uyluk | godot=blender (px>8) |",
             "|---|---|---|---|---|---|---|"]
    for f in frames:
        r = res[f]
        c = r["composite_equals_full"]
        nb = r.get("no_backfaces", {})
        pr = r["proportions"]
        gb = r.get("godot_equals_blender")
        lines.append("| %s | %s %d / %.2f | %s | %.3f | %.3f | %.3f | %s |" % (
            f, "GECTI" if c["pass"] else "KALDI", c["pixels_over_8"], c["mean_abs_x255"],
            "%d/%d" % (nb.get("composite", -1), nb.get("full", -1)) if nb else "-",
            pr["hand_over_head"], pr["forearm_over_upper_arm"], pr["shank_over_thigh"],
            ("GECTI" if gb["pass"] else "KALDI") + " %d" % gb["pixels_over_8"] if gb else "-"))
    lines.append("")
    for k, v in summary.items():
        lines.append("- **%s**: %d/%d kare gecti" % (k, v["passed"], v["of"]))
    open(os.path.join(rep, "results.md"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
