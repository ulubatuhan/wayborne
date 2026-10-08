"""Faz 3-4: giysi modulleri. Ciplak beden render'inin (render_frames.py) AYNI
pozunda, her giysiyi ayri bir katmanli resim kumesi olarak render eder; oyun
bunlari bedenin her katmaninin ustune, sirayla bindirecek.

    python3 -I tools/figure_pipeline/blender/render_garments.py --variant male_average \
        --clip walk --garments shoes03,male_casualsuit01 [--frames 0,6] [--magenta]

Her kare (build/figures/out/<varyant>/<klip>/fNN/garments/):
  <gid>_<katman>.png   - o giysinin o katmandaki golgeli resmi; beden kameraya
                         GORUNMEZ ama golge dusurur (holdout yok), diger
                         giysiler de kameraya gorunmez.
  truth.png            - beden + butun giysiler birlikte (giysinin altindaki
                         beden MPFB'nin silme grubuyla gizli): gercek gorunum.
  truth_id.png         - ayni sahne, B kanali = giysi (ten tasmasi testi).
  [magenta_<gid>.png]  - --magenta: giysinin ic yuzleri (no_backfaces).

Giysinin katman uyeligi bedeninkiyle ayni formulden: kendi kemik
agirliklarindan (MPFB giysiyi bedenin agirliklarini enterpole ederek
rig'ler), layer_weights() ile.
"""
import json
import os
import sys
import time

import bpy

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "blender"))
sys.path.insert(0, os.path.join(PIPE, "qa"))
import fig_shading  # noqa: E402
import fig_weights  # noqa: E402
import render_clip as rc  # noqa: E402
import render_frames as rf  # noqa: E402

MPFB_DATA = rf.MPFB_DATA


def add_garment(basemesh, gid):
    from bl_ext.user_default.mpfb.services.humanservice import HumanService
    path = os.path.join(MPFB_DATA, "clothes", gid, gid + ".mhclo")
    return HumanService.add_mhclo_asset(path, basemesh, asset_type="Clothes", subdiv_levels=0)


def set_material(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    variant = rf.arg(argv, "--variant")
    clip_name = rf.arg(argv, "--clip")
    gids = rf.arg(argv, "--garments").split(",")
    only = [int(x) for x in rf.arg(argv, "--frames").split(",")] if "--frames" in argv else None
    do_magenta = "--magenta" in argv
    build = rf.cfg("build.json")
    clip_cfg = build["clips"][clip_name]
    out_root = os.path.join(ROOT, "build", "figures", "out", variant, clip_name)
    layers, retarget, garments = rf.cfg("layers.json"), rf.cfg("retarget.json"), rf.cfg("garments.json")
    camcfg = dict(rf.cfg("camera.json"))
    camcfg["ground_px"] = list(clip_cfg["anchor_px"])
    clip = json.load(open(os.path.join(ROOT, "build", "figures", "clips", clip_name + ".json")))

    bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "build/figures/variants", variant, variant + ".blend"))
    rf.enable_mpfb()
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    body = bpy.data.objects["Human"]
    rf.thicken(body, rf.variant_thickness(variant))
    clothes = [add_garment(body, gid) for gid in gids]
    for obj in [body] + clothes:
        for m in obj.modifiers:
            if m.type == "MASK":
                m.show_viewport = False  # poz/koordinat olcumu ciplak bedenle ayni kalsin
                m.show_render = True

    rc.reset_pose(rig, rig)
    rest_foot_rot = {n: rig.pose.bones[n].matrix.to_quaternion() for n in ("foot_l", "foot_r")}
    lw = fig_weights.layer_weights(body, rig, layers)
    fig_weights.write_attr(body, lw)
    rest = rc.evaluated_coords(body)
    g = garments["by_gender"][rf.gender_of(variant)]
    fig_weights.write_color(body, fig_weights.garment_weights(body, rig, lw, rest, garments, g["top"]), "gw")
    for obj in clothes:
        fig_weights.write_attr(obj, fig_weights.layer_weights(obj, rig, layers))
        fig_weights.write_color(obj, [(0.0, 0.0, 1.0, 1.0)] * len(obj.data.vertices), "gw")
    body_idx = rc.body_vertex_set(body)

    fig_shading.setup_render(camcfg)
    bpy.context.scene.render.use_persistent_data = "--no-persist" not in argv
    fig_shading.setup_camera(camcfg, 0.0, 0.0)
    kw = dict(core=layers["core_threshold"], root=layers["root_threshold"])
    mat = {m: fig_shading.body_material(camcfg, m, **kw)
           for m in ["full", "id"] + ["layer:" + n for n in layers["layers"]] + ["magenta"]}
    curl = retarget.get("finger_curl_deg", [0, 0, 0])
    timings = {}

    for fr in clip["frames"]:
        i = fr["index"]
        if only is not None and i not in only:
            continue
        rc.reset_pose(rig, rig)
        rc.apply_frame(rig, fr, layers, rest_foot_rot, retarget)
        for side in ("l", "r"):
            rf.curl_fingers(rig, side, curl)
        # Bir kez: liste kavramasinin icinde her kose icin tum mesh yeniden
        # degerlendiriliyordu (olculdu: kare basina ~170 sn).
        posed = rc.evaluated_coords(body)
        rf.place_root(rig, [posed[k] for k in body_idx], clip_cfg["root"])
        d = os.path.join(out_root, "f%02d" % i, "garments")
        os.makedirs(d, exist_ok=True)

        def shot(name, kind):
            t0 = time.time()
            rc.render(os.path.join(d, name + ".png"))
            timings.setdefault(kind, []).append(time.time() - t0)

        # gercek gorunum: herkes kameraya gorunur
        for obj in [body] + clothes:
            obj.visible_camera = True
        for key, name in (("full", "truth"), ("id", "truth_id")):
            for obj in [body] + clothes:
                set_material(obj, mat[key])
            shot(name, key)
        # moduller: yalniz o giysi kameraya gorunur, beden ve digerleri golge dusurur.
        # Gorunmeyenler de "full" malzemeyi tasimali: Cycles emisyonlu yuzeyi
        # isik kaynagi sayiyor ve truth_id'den kalan mavi emisyon pacanin
        # altindaki corabi mora boyuyordu (olculdu: 175,175,255).
        for obj in [body] + clothes:
            set_material(obj, mat["full"])
        body.visible_camera = False
        for gid, obj in zip(gids, clothes):
            for other in clothes:
                other.visible_camera = other is obj
            for n in layers["layers"]:
                set_material(obj, mat["layer:" + n])
                shot("%s_%s" % (gid, n), "layer")
            if do_magenta:
                set_material(obj, mat["magenta"])
                shot("magenta_" + gid, "magenta")
            set_material(obj, mat["full"])
        for obj in [body] + clothes:
            obj.visible_camera = True
        json.dump({"garments": gids}, open(os.path.join(d, "garments.json"), "w"))
        print("kare", variant, clip_name, i, "giysi tamam",
              {k: round(sum(v) / len(v), 1) for k, v in timings.items()}, flush=True)


if __name__ == "__main__":
    main()
