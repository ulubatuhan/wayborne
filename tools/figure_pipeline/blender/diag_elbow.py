"""Teshis (icerik degil): on dirsegi 90 derece bukup mesh'in nereden buküldugunu ve
dirsek isaretinin o bukume oturup oturmadigini gosterir. Onkol/ust kol = 1.06
olcumunun (iskelet isaretleri) goruntuyle celisip celismedigini ayirir (kural 4).
"""
import json, math, os, sys
import bpy
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render_clip as rc
import fig_shading, fig_weights, make_variant as mv

OUT = "/home/user/wayborne/build/figures/faz1/diag_elbow"
os.makedirs(OUT, exist_ok=True)
layers, camcfg = rc.cfg("layers.json"), rc.cfg("camera.json")
clip = json.load(open(os.path.join(rc.OUT, "clip_walk.json")))
bpy.ops.wm.open_mainfile(filepath="/home/user/wayborne/build/figures/variants/male_medium/male_medium.blend")
mv.ensure_mpfb()
rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
body = next(o for o in bpy.data.objects if o.type == "MESH")
for m in body.modifiers:
    if m.type == "MASK":
        m.show_viewport = False
rc.reset_pose(rig, rig)
rest_foot = {n: rig.pose.bones[n].matrix.to_quaternion() for n in ("foot_l", "foot_r")}
body_idx = rc.body_vertex_set(body)
fig_shading.setup_render(camcfg)
fig_shading.setup_camera(camcfg, 0.0, 0.0)
mat = fig_shading.body_material(camcfg, "full")
body.data.materials.clear(); body.data.materials.append(mat)
fr = json.loads(json.dumps(clip["frames"][0]))
for name, up, fo in (("bent90", math.pi / 2, 0.0), ("straight", math.pi / 2, math.pi / 2)):
    fr["bones"]["upper_arm_front"] = up      # dik asagi
    fr["bones"]["forearm_front"] = fo         # 0 = ileri yatay (90 derece bukuk)
    rc.reset_pose(rig, rig)
    rc.apply_frame(rig, fr, layers, rest_foot)
    coords = rc.evaluated_coords(body)
    minz = min(coords[k].z for k in body_idx)
    pel_y = (rig.matrix_world @ rig.pose.bones["pelvis"].head).y
    rig.location = (0.0, -pel_y, -minz); rc.update()
    rc.render(os.path.join(OUT, name + ".png"))
    j = rc.joints_px(rig, camcfg, layers, rc.evaluated_coords(body), 0, 0.0)
    json.dump(j, open(os.path.join(OUT, name + ".json"), "w"), indent=1)
print("TAMAM")
