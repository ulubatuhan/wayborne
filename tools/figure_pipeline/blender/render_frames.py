"""Faz 2+: bir varyant x klip icin her kareyi render eder.

    python3 -I tools/figure_pipeline/blender/render_frames.py --variant male_average --clip walk
        [--frames 0,6] [--magenta] [--out DIR]

Her kare (build/figures/out/<varyant>/<klip>/fNN/):
  full.png, <katman>.png            - golgeli beden (gri; oyun tenle carpar)
  id_full.png, id_<katman>.png      - kusam kimligi: R=ust (atlet/bra), G=sort,
                                      B=modul (sac vb.; saf mankende bos)
  [magenta*.png]                    - --magenta ile ic yuz testi
  joints.json                       - eklem isaretleri (piksel)

Faz 1'in render_clip.py'si degismeden duruyor (kapinin kaniti); bu dosya onun
apply_frame/joints_px'ini kullaniyor, uzerine: klip basina capa (binici kalcadan
asilir), sac proxy'si, temel kusam bolgeleri ve gevsek el.
"""
import json
import math
import os
import time
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "blender"))
sys.path.insert(0, os.path.join(PIPE, "qa"))
import fig_shading  # noqa: E402
import fig_weights  # noqa: E402
import make_variant as mv  # noqa: E402
import check_config  # noqa: E402
import render_clip as rc  # noqa: E402

CFG = os.path.join(PIPE, "config")
MPFB_DATA = "/root/.config/blender/5.0/extensions/.user/user_default/mpfb/data"
FINGERS = ("index", "middle", "ring", "pinky")


def cfg(name):
    return json.load(open(os.path.join(CFG, name)))


def arg(argv, name, default=None):
    return argv[argv.index(name) + 1] if name in argv else default


def enable_mpfb():
    """MPFB zaten kurulu; her surecin yeniden KURMASI eklenti deposunu kilitliyor
    ve paralel render'lar 'lock exists' ile dusuyordu. Yalniz etkinlestir."""
    import addon_utils
    try:
        addon_utils.enable("bl_ext.user_default.mpfb", default_set=True)
        import bl_ext.user_default.mpfb  # noqa: F401
    except Exception:
        mv.ensure_mpfb()


def gender_of(variant):
    return "female" if variant.startswith("female") else "male"


def add_hair(basemesh, hair_id):
    from bl_ext.user_default.mpfb.services.humanservice import HumanService
    path = os.path.join(MPFB_DATA, "hair", hair_id, hair_id + ".mhclo")
    hair = HumanService.add_mhclo_asset(path, basemesh, asset_type="Hair", subdiv_levels=0)
    tex = os.path.join(MPFB_DATA, "hair", hair_id, hair_id + "_diffuse.png")
    return hair, bpy.data.images.load(tex)


def curl_fingers(rig, side, curl_deg):
    """Gevsek el: her parmak eklemi avuca dogru bukulur. Eksen dunyada
    hesaplanir (parmak yonu x avuc normali), kemigin basi etrafinda - yerel
    eksenlerin adi rig'e gore degistigi icin tahmin edilmiyor (olculdu:
    yerel X ve Z ikisi de avuca dogru bilesen veriyordu)."""
    hand = rig.pose.bones["hand_" + side]
    rest_normal = Vector((1.0 if side == "r" else -1.0, 0.0, 0.0))  # A-pozda avuc govdeye bakar
    delta = hand.matrix.to_3x3() @ hand.bone.matrix_local.to_3x3().inverted()
    normal = (delta @ rest_normal).normalized()
    for f in FINGERS:
        for k, deg in enumerate(curl_deg):
            pb = rig.pose.bones["%s_%02d_%s" % (f, k + 1, side)]
            d = (pb.tail - pb.head).normalized()
            axis = d.cross(normal).normalized()
            q = Quaternion(axis, math.radians(deg))
            # isaret: uc avuca (normal yonune) gitmeli
            if (q @ d).dot(normal) < d.dot(normal):
                q = Quaternion(axis, -math.radians(deg))
            head = pb.head.copy()
            pb.matrix = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head) @ pb.matrix
            bpy.context.view_layer.update()


def thicken(obj, k):
    """Kilo: dinlenme pozunda on-arka (Y) kalinlik, her yukseklik diliminde
    govdenin kendi Y merkezine gore (tools/human_body_render.py'nin ayni
    islemi; yalniz Y, cunku kamera X'ten bakiyor ve X'i olceklemek durusu
    acardi). Sekil anahtarlari varsa hepsine ayni donusum: degerlendirilen
    mesh Basis'ten degil anahtarlardan geliyor."""
    if abs(k - 1.0) < 1e-6:
        return
    import numpy as np
    co = np.array([p.co[:] for p in obj.data.vertices])
    z = co[:, 2]
    lo, hi = z.min(), z.max()
    bins = np.clip(((z - lo) / max(hi - lo, 1e-9) * 48).astype(int), 0, 47)
    centre = np.zeros(48)
    for b in range(48):
        m = co[bins == b]
        centre[b] = 0.5 * (m[:, 1].min() + m[:, 1].max()) if len(m) else 0.0
    smooth = np.convolve(np.pad(centre, 2, mode="edge"), np.ones(5) / 5.0, mode="valid")
    targets = [obj.data.vertices]
    if obj.data.shape_keys:
        targets += [kb.data for kb in obj.data.shape_keys.key_blocks]
    for data in targets:
        for i, p in enumerate(data):
            c = smooth[bins[i]]
            p.co[1] = c + (p.co[1] - c) * k
    obj.data.update()


def variant_thickness(variant):
    p = os.path.join(CFG, "variants", variant + ".json")
    return float(json.load(open(p)).get("thickness", 1.0)) if os.path.exists(p) else 1.0


def place_root(rig, body_idx_coords, mode, shift_m=0.0):
    """Kok otelemesi (olcek degil). ground: kalca y=-shift_m, en alcak govde
    noktasi z=0. pelvis: kalca (pelvis basi) dunya (0,0)'da - binici eyerden
    asilir. shift_m: klibin kalca ilerlemesi (saldiri hamlesinde kalca one
    gider, ayaklar yerinde kalir); ekran sagi dunya -Y. Doner: konum."""
    pel = rig.matrix_world @ rig.pose.bones["pelvis"].head
    if mode == "pelvis":
        rig.location = (0.0, -pel.y, -pel.z)
    else:
        minz = min(c.z for c in body_idx_coords)
        rig.location = (0.0, -pel.y - shift_m, -minz)
    bpy.context.view_layer.update()
    return tuple(rig.location)


def set_foot(rig, name, rest_rot, angle):
    """Ayagin dunya yonelimi: dinlenme yonelimi, ekran acisi kadar X etrafinda
    dondurulmus. Ekran acisi ayak bileginden parmaga (x saga, y asagi); dinlenmede
    ayak duz (aci 0). (0,-1,0) X etrafinda a kadar donunce (0,-cos a,-sin a) olur,
    ki screen_to_world(a)'nin ta kendisi - isaret donusumu yok."""
    rc.keep_world_rotation(rig, name, Quaternion((1.0, 0.0, 0.0), angle) @ rest_rot)


def pose_frame(rig, fr, layers, rest_foot_rot, retarget, curl):
    rc.reset_pose(rig, rig)
    rc.apply_frame(rig, fr, layers, rest_foot_rot, retarget)
    for side, s in (("front", layers["front_side"]), ("back", layers["back_side"])):
        if "foot_" + side in fr:
            set_foot(rig, "foot_" + s, rest_foot_rot["foot_" + s], float(fr["foot_" + side]))
    for side in ("l", "r"):
        curl_fingers(rig, side, curl)


def back_markers(body, rig, rest, body_idx):
    """Sirt cizgisinde iki nokta: kurek kemigi (spine_03 basi) ve bel (spine_01
    basi) hizasinda, orta hatta (|x|<4 mm) en arkadaki (dunya +Y; figur -Y'ye
    bakiyor) govde koseleri. Sirtta tasinan yay/kilic/heybe bu iki noktanin
    cizgisine oturur - havada asili bir yay degil, sirtin kendisine."""
    out = {}
    for key, bone in (("back_upper", "spine_03"), ("back_lower", "spine_01")):
        z = (rig.matrix_world @ rig.data.bones[bone].head_local).z
        cand = [k for k in body_idx if abs(rest[k].x) < 0.004 and abs(rest[k].z - z) < 0.015]
        out[key] = max(cand, key=lambda k: rest[k].y)
    return out


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    variant = arg(argv, "--variant")
    clip_name = arg(argv, "--clip")
    only = [int(x) for x in arg(argv, "--frames").split(",")] if "--frames" in argv else None
    build = cfg("build.json")
    clip_cfg = build["clips"][clip_name]
    do_magenta = "--magenta" in argv and clip_cfg.get("magenta", True)
    out_root = arg(argv, "--out", os.path.join(ROOT, "build", "figures", "out", variant, clip_name))
    layers, retarget, garments = cfg("layers.json"), cfg("retarget.json"), cfg("garments.json")
    camcfg = dict(cfg("camera.json"))
    camcfg["ground_px"] = list(clip_cfg["anchor_px"])
    clip = json.load(open(os.path.join(ROOT, "build", "figures", "clips", clip_name + ".json")))
    # Katman alt kumesi (walk_boots: yalniz bacaklar): kok, temel klibin ayni
    # karesinden alinir ki govde katmani (temelden) ile bacaklar ayni yere otursun.
    base = None
    if clip_cfg.get("base"):
        base = json.load(open(os.path.join(ROOT, "build", "figures", "clips", clip_cfg["base"] + ".json")))

    bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "build/figures/variants", variant, variant + ".blend"))
    enable_mpfb()
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    body = bpy.data.objects["Human"]
    thicken(body, variant_thickness(variant))
    g = garments["by_gender"][gender_of(variant)]
    # Saf manken: sac/kas/sakal YOK (kullanici karari) - bunlar karakter
    # yaratiminda modul olarak ust uste binecek. --hair yalniz modul denemesi icin.
    extras = []
    hair_id = arg(argv, "--hair")
    if hair_id:
        hair, hair_img = add_hair(body, hair_id)
        extras.append((hair, hair_img))
    os.makedirs(out_root, exist_ok=True)
    rb = os.path.join(out_root, "rig_bones.json")
    json.dump({"deform_bones": sorted(b.name for b in rig.data.bones if b.use_deform)}, open(rb, "w"))
    check_config.check(rb)

    for obj in [body] + [e[0] for e in extras]:
        for m in obj.modifiers:
            if m.type == "MASK":
                m.show_viewport = False
                m.show_render = True
    rc.reset_pose(rig, rig)
    rest_foot_rot = {n: rig.pose.bones[n].matrix.to_quaternion() for n in ("foot_l", "foot_r")}
    lw = fig_weights.layer_weights(body, rig, layers)
    fig_weights.write_attr(body, lw)
    for obj, _img in extras:
        fig_weights.write_attr(obj, fig_weights.layer_weights(obj, rig, layers))
    rest = rc.evaluated_coords(body)
    gw = fig_weights.garment_weights(body, rig, lw, rest, garments, g["top"])
    fig_weights.write_color(body, gw, "gw")
    for obj, _img in extras:
        fig_weights.write_color(obj, [(0.0, 0.0, 1.0, 1.0)] * len(obj.data.vertices), "gw")
    chin_idx = rc.chin_vertex(body, rig, rest)
    body_idx = rc.body_vertex_set(body)
    back_idx = back_markers(body, rig, rest, body_idx)
    # Zemine oturan beden: kollar haric. Yerde yatan/oturan bir pozda dayanan
    # el zemine degmeli, ama zemini belirleyen kalca ve bacaklar - kol en alcak
    # nokta sayilinca kalca havada kaldi (olculdu: downed'da 43 px).
    arm_k = [fig_weights.ORDER.index(n) for n in ("back_arm", "front_arm")]
    support_idx = [k for k in body_idx if max(lw[k][a] for a in arm_k) < layers["core_threshold"]]
    # FigureRig biriminden metreye: dinlenmede kalca yerden HIP_RATIO * h.
    m_per_h = (rig.matrix_world @ rig.data.bones["pelvis"].head_local).z / float(clip.get("hip_ratio", 0.46))

    fig_shading.setup_render(camcfg)
    # Ayni sahne 12 kez farkli malzemeyle render ediliyor; her seferinde BVH
    # yeniden kurulmasin (olculdu: 2 kare 5 dk 44 sn, CPU'nun ~1,3 cekirdegi).
    bpy.context.scene.render.use_persistent_data = True
    fig_shading.setup_camera(camcfg, 0.0, 0.0)
    rlayers = clip_cfg.get("layers", layers["layers"])
    whole = rlayers == layers["layers"]
    modes = (["full"] if whole else []) + ["layer:" + n for n in rlayers]
    modes += (["id"] if whole else []) + ["id:" + n for n in rlayers]
    if do_magenta:
        modes += (["magenta"] if whole else []) + ["magenta:" + n for n in rlayers]
    kw = dict(core=layers["core_threshold"], root=layers["root_threshold"])
    mats = {m: [fig_shading.body_material(camcfg, m, **kw)] +
            [fig_shading.body_material(camcfg, m, alpha_image=img, alpha_cutoff=garments["hair_alpha_cutoff"],
                                       name_suffix="_x%d" % k, **kw) for k, (_o, img) in enumerate(extras)]
            for m in modes}
    objs = [body] + [e[0] for e in extras]
    curl = retarget.get("finger_curl_deg", [0, 0, 0])
    timings = {}

    for fr in clip["frames"]:
        i = fr["index"]
        if only is not None and i not in only:
            continue
        shift = float(fr.get("root_x", 0.0)) * m_per_h
        if base is not None:
            # Temel klibin ayni fazdaki karesi (kare sayilari farkli olabilir).
            bi = round(i * len(base["frames"]) / len(clip["frames"])) % len(base["frames"])
            pose_frame(rig, base["frames"][bi], layers, rest_foot_rot, retarget, curl)
            # Bir kez: liste kavramasinin icinde her kose icin tum mesh yeniden
            # degerlendiriliyordu (olculdu: kare basina ~170 sn).
            posed = rc.evaluated_coords(body)
            loc = place_root(rig, [posed[k] for k in support_idx], clip_cfg["root"], shift)
            pose_frame(rig, fr, layers, rest_foot_rot, retarget, curl)
            rig.location = loc
            bpy.context.view_layer.update()
        else:
            pose_frame(rig, fr, layers, rest_foot_rot, retarget, curl)
            posed = rc.evaluated_coords(body)
            place_root(rig, [posed[k] for k in support_idx], clip_cfg["root"], shift)
        coords = rc.evaluated_coords(body)
        d = os.path.join(out_root, "f%02d" % i)
        os.makedirs(d, exist_ok=True)
        for m in modes:
            for obj, mat in zip(objs, mats[m]):
                obj.data.materials.clear()
                obj.data.materials.append(mat)
            t0 = time.time()
            rc.render(os.path.join(d, m.replace("layer:", "").replace(":", "_") + ".png"))
            timings.setdefault(m.split(":")[0], []).append(time.time() - t0)
        j = rc.joints_px(rig, camcfg, layers, coords, chin_idx, 0.0)
        j["anchor_px"] = list(clip_cfg["anchor_px"])
        for key, k in back_idx.items():
            j[key] = rc.project(camcfg, coords[k], 0.0)
        j["weapon"] = float(fr.get("weapon", 0.0))
        j["draw"] = float(fr.get("draw", 0.0))
        j["layers"] = rlayers
        json.dump(j, open(os.path.join(d, "joints.json"), "w"), indent=1)
        print("kare", variant, clip_name, i, "tamam",
              {k: round(sum(v) / len(v), 1) for k, v in timings.items()}, flush=True)


if __name__ == "__main__":
    main()
