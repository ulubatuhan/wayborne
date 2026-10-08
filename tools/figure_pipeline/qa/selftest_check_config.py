"""check_config'in eski denemenin kararlarini YAKALADIGINI gosterir (kural 1)."""
import copy, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_config as cc

real = cc.load
def run(mutate, label):
    def fake(name):
        d = copy.deepcopy(real(name))
        mutate(name, d)
        return d
    cc.load = fake
    try:
        cc.check()
        print("GECTI (beklenmiyordu):", label); return False
    except SystemExit:
        print("YAKALADI:", label); return True
    finally:
        cc.load = real

def old_14(name, d):
    if name == "layers.json":
        d["layers"] = ["upper_arm_back","forearm_back","hand_back","thigh_back","shin_back","foot_back","thigh_front","shin_front","foot_front","torso","head","upper_arm_front","forearm_front","hand_front"]
def old_side(name, d):
    if name == "layers.json":
        d["front_side"], d["back_side"] = "l", "r"
def rigid(name, d):
    if name == "layers.json":
        d["root_threshold"] = 0.5
def no_cull(name, d):
    if name == "camera.json":
        d["backface_culling"] = False
def scale(name, d):
    if name == "retarget.json":
        d["bone_scale_allowed"] = True
ok = all([run(old_14, "eski 14 parcali katman listesi"), run(old_side, "eski on=_l"),
          run(rigid, "kok uzantisi kaldirilmis (rijit)"), run(no_cull, "backface culling kapali"),
          run(scale, "kemik olcegi serbest (eski retarget)")])
print("selftest:", "5/5 yakalandi" if ok else "EKSIK")
sys.exit(0 if ok else 1)
