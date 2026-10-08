"""Kural 1: her hakem, bilinen hatali ornekte BASARISIZ olmali; ayrica dogru ornekte
(ozdes cift) GECMELI - her seyi reddeden test de gecersizdir.

Eski cikti: build/figures/variants/male_medium (onceki deneme, ayni kamera/malzeme/poz:
layers/*/texture.png = 14 kemik katmani, debug_render_raw.png = tek parca render,
debug_marks.json = ayni karede projekte edilen eklem isaretleri).
"""
import json, os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import faz1_tests as T

ROOT = "/home/user/wayborne"
OLD = os.path.join(ROOT, "build/figures/variants/male_medium")
OUT = os.path.join(ROOT, "build/figures/faz1/validation")
os.makedirs(OUT, exist_ok=True)
OLD_ORDER = ["upper_arm_back", "forearm_back", "hand_back", "thigh_back", "shin_back", "foot_back",
             "thigh_front", "shin_front", "foot_front", "torso", "head",
             "upper_arm_front", "forearm_front", "hand_front"]
results = {}

# 1) composite_equals_full - eski 14 katman vs eski tek parca
paths = [os.path.join(OLD, "layers", n, "texture.png") for n in OLD_ORDER]
r = T.composite_equals_full(paths, os.path.join(OLD, "debug_render_raw.png"), os.path.join(OUT, "old_composite_diff.png"))
results["composite_equals_full[old]"] = r
# ozdes cift: ayni goruntu kendisiyle -> gecmeli
full = os.path.join(OLD, "debug_render_raw.png")
results["composite_equals_full[identity]"] = T.composite_equals_full([full], full)

# 2) proportions - eski render + eski isaretler
m = json.load(open(os.path.join(OLD, "debug_marks.json")))
j = {"front_shoulder": m["shoulder"], "front_elbow": m["elbow_front"], "front_wrist": m["hand_front"],
     "front_hip": m["hip"], "front_knee": m["knee_front"], "front_ankle": m["ankle_front"],
     "neck": m["shoulder"], "head_top_hint": m["head"], "facing": 1}
jp = os.path.join(OUT, "old_joints.json"); json.dump(j, open(jp, "w"))
results["proportions[old]"] = T.proportions(full, jp, os.path.join(ROOT, "tools/figure_pipeline/config/anatomy.json"),
    {"front_arm": os.path.join(OLD, "layers/hand_front/texture.png")}, os.path.join(OUT, "old_proportions_marks.png"))

# 3) godot_equals_blender - mutasyonlar (eski denemede Blender'in kare kare birlesik
# karesi yoktu; bu test icin bilinen hatali ornek, testin yakalamasi gereken hata
# siniflarinin kendisi: ofset, sira, pivot/olcek). Ozdes cift gecmeli.
comp = T.over([T.load_rgba(p) for p in paths])
def save_premul(arr, path):
    a = arr.copy(); al = np.clip(a[..., 3:4], 1e-6, 1)
    rgb = np.where(a[..., 3:4] > 0, a[..., :3] / al, 0)
    Image.fromarray((np.clip(np.concatenate([rgb, a[..., 3:4]], 2), 0, 1) * 255 + 0.5).astype(np.uint8)).save(path)
ref = os.path.join(OUT, "old_comp.png"); save_premul(comp, ref)
# referansi katman olarak ver (tek katman = birlesik)
results["godot_equals_blender[identity]"] = T.godot_equals_blender(ref, [ref])
sh = np.roll(np.asarray(Image.open(ref)), 1, axis=1); p1 = os.path.join(OUT, "mut_offset1px.png"); Image.fromarray(sh).save(p1)
results["godot_equals_blender[offset_1px]"] = T.godot_equals_blender(p1, [ref], os.path.join(OUT, "mut_offset_diff.png"))
rev = T.over([T.load_rgba(p) for p in reversed(paths)]); p2 = os.path.join(OUT, "mut_order.png"); save_premul(rev, p2)
results["godot_equals_blender[wrong_order]"] = T.godot_equals_blender(p2, [ref], os.path.join(OUT, "mut_order_diff.png"))
im = Image.open(ref); W, H = im.size
sc = im.resize((round(W * 1.01), round(H * 1.01)), Image.BILINEAR).crop((0, 0, W, H)); p3 = os.path.join(OUT, "mut_scale.png"); sc.save(p3)
results["godot_equals_blender[scale_1pct_pivot_topleft]"] = T.godot_equals_blender(p3, [ref], os.path.join(OUT, "mut_scale_diff.png"))

json.dump(results, open(os.path.join(OUT, "validation.json"), "w"), indent=1, default=str)
for k, v in results.items():
    brief = {kk: vv for kk, vv in v.items() if kk in ("pass", "mean_abs_x255", "pixels_over_8", "max_x255")}
    if "checks" in v:
        brief = {"pass": v["pass"], **{kk: (vv.get("value"), vv["pass"]) if "value" in vv else (vv.get("outside"), vv["pass"]) for kk, vv in v["checks"].items()}}
    print("%-48s %s" % (k, brief))
