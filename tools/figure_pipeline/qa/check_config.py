"""Yapisal kararlari makinece dogrular (RULES.md kural 7). Her hat calistirmasinin
basinda cagrilir; bir ihlalde SystemExit ile durur.

    python3 -I tools/figure_pipeline/qa/check_config.py [rig_bones.json]
"""
import json
import os
import sys

PIPE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CFG = os.path.join(PIPE, "config")

CHECK_GROUPS = 17  # yukaridaki if-bloklarinin sayisi; yeni kontrol eklerken guncelle
LAYERS_EXPECTED = ["back_arm", "back_leg", "torso_head", "front_leg", "front_arm"]


def load(name):
    with open(os.path.join(CFG, name)) as f:
        return json.load(f)


def check(rig_bones_path=None):
    errors = []

    layers = load("layers.json")
    camera = load("camera.json")
    anatomy = load("anatomy.json")
    clip = load("clip.json")
    retarget = load("retarget.json")

    if layers["layers"] != LAYERS_EXPECTED:
        errors.append("katman listesi/sirasi tam olarak %s olmali, bulundu %s" % (LAYERS_EXPECTED, layers["layers"]))
    if layers["core_threshold"] != 0.5 or layers["root_threshold"] != 0.02:
        errors.append("esikler 0.5 / 0.02 olmali")
    if set(layers["limb_bones"]) != {"back_arm", "back_leg", "front_leg", "front_arm"}:
        errors.append("limb_bones tam dort uzuv katmani icermeli")
    if {layers["front_side"], layers["back_side"]} != {"l", "r"}:
        errors.append("front_side/back_side l ve r olmali")
    # Kamera -X'te ve model -Y'ye bakiyorsa yakin taraf karakterin sagi (_r).
    # Bu kural render'la dogrulandi (config/evidence/side_check_camera_minusX.png).
    near = "r" if camera["camera_axis"] == "-X" and camera["model_faces_world"] == "-Y" else None
    if near is None:
        errors.append("kamera ekseni/model yonu degisti: yakin tarafi yeniden render'la dogrula")
    elif layers["front_side"] != near:
        errors.append("front_side=%s ama kamera geometrisi yakin tarafi %s veriyor" % (layers["front_side"], near))
    for layer, bones in layers["limb_bones"].items():
        side = layers["front_side"] if layer.startswith("front") else layers["back_side"]
        wrong = [b for b in bones if not b.endswith("_" + side)]
        if wrong:
            errors.append("%s yanlis taraf kemikleri: %s" % (layer, wrong))
    every = [b for bones in layers["limb_bones"].values() for b in bones] + layers["torso_head_bones"]
    dup = sorted({b for b in every if every.count(b) > 1})
    if dup:
        errors.append("birden fazla katmana atanmis kemik: %s" % dup)
    if rig_bones_path and os.path.exists(rig_bones_path):
        rig = set(json.load(open(rig_bones_path))["deform_bones"])
        if rig != set(every):
            errors.append("rig kemikleri ile katman atamasi uyusmuyor: eksik=%s fazla=%s"
                          % (sorted(rig - set(every)), sorted(set(every) - rig)))

    if camera["backface_culling"] is not True:
        errors.append("backface_culling acik olmali (kural 9)")
    if camera["holdout"] is not False:
        errors.append("holdout kullanilmaz (Faz 1 prompt)")
    if camera["type"] != "ORTHO":
        errors.append("kamera ortografik olmali")
    if retarget["bone_scale_allowed"] is not False or retarget["rotation_only"] is not True:
        errors.append("kemik olcegi asla degismez, yalnizca donus")
    for name in ("hand_over_head", "forearm_over_upper_arm", "shank_over_thigh"):
        r = anatomy["ratios"].get(name)
        if not r or not (r["min"] < r["nominal"] < r["max"]):
            errors.append("anatomy.json %s araligi eksik/tutarsiz" % name)
    if "Winter" not in anatomy["_comment"]:
        errors.append("anatomy.json kaynak gostermeli")
    if clip["clip"] != "walk" or clip["variant"] != "male_medium":
        errors.append("Faz 1 kapsami: male_medium + walk")
    if not isinstance(clip["frames_per_cycle"], int) or clip["frames_per_cycle"] < 12:
        errors.append("frames_per_cycle >= 12 tamsayi olmali")

    if errors:
        for e in errors:
            print("CONFIG HATA:", e)
        raise SystemExit(1)
    print("check_config: tum kontroller gecti (%d kural grubu)" % CHECK_GROUPS)


if __name__ == "__main__":
    check(sys.argv[1] if len(sys.argv) > 1 else None)
