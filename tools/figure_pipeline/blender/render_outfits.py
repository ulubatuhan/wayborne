"""Giyilip cikarilabilen kiyafetlerin kareleri: bedenin (render_frames.py)
AYNI pozunda ve AYNI kokunde, her kalem kendi basina, katman katman.

    python3 -I tools/figure_pipeline/blender/render_outfits.py --variant male_average \\
        [--items peasant_shirt,...] [--clips walk,idle] [--frames 0,6]

Her kalem config/outfits.json'dan; parcalar fit_garment ile bedene giydirilip
tek aga birlestirilir. Beden kameraya gorunmez ama golge dusurur (giysi
bedenin golgesini tasir, beden giysininkini tasimaz: giysi cikarilabilir).
Diger kalemler sahnede yok sayilir (hide_render) - hangisinin giyilecegi
oyunda belli olur.

Hayvanlar gibi iki gecis (render_beast.py): golge (insanla ayni gri malzeme,
paketlemede dort tona indirilir) ve albedo (kumasin kendi rengi, isiksiz).
Paketleyici ikisini carpar (mesh/pack_outfits.py). Kalemin uyesi olmadigi
katman hic render edilmez - bir ayakkabi kolda bos resim uretmesin.

Cikti: build/figures/outfits/<varyant>/<kalem>/<klip>/fNN/{shade,albedo}_<katman>.png
"""
import json
import os
import sys
import time

import bpy

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "blender"))
sys.path.insert(0, os.path.join(PIPE, "beasts"))
sys.path.insert(0, os.path.join(PIPE, "qa"))
import fig_shading  # noqa: E402
import fig_weights  # noqa: E402
import fit_garment  # noqa: E402
import render_clip as rc  # noqa: E402
import render_frames as rf  # noqa: E402
import render_beast  # noqa: E402

CLOTHES = os.path.join(ROOT, "art_source", "models", "clothes", "quaternius_fantasy")
OUT = os.path.join(ROOT, "build", "figures", "outfits")


def fit_item(spec, gender, body, rig, inner=()):
    meshes = []
    lo, hi = [1e9] * 3, [-1e9] * 3
    snugged = False
    for piece in spec["pieces"][gender]:
        obj, pushed = fit_garment.fit(os.path.join(CLOTHES, piece + ".gltf"), body, rig,
                                      float(spec["eps"]), inner, float(spec.get("gap", 0.003)))
        print("giydirildi", piece, "itilen", pushed, flush=True)
        lo = [min(a, b) for a, b in zip(lo, obj["native_min"])]
        hi = [max(a, b) for a, b in zip(hi, obj["native_max"])]
        snugged = snugged or bool(obj["snugged"])
        meshes.append(obj)
    if len(meshes) > 1:
        bpy.ops.object.select_all(action="DESELECT")
        for m in meshes:
            m.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()
    meshes[0]["native_min"], meshes[0]["native_max"] = lo, hi
    meshes[0]["snugged"] = snugged
    return meshes[0]


def fit_all(ocfg, gender, body, rig):
    """Butun kalemleri cizim sirasiyla giydirir; her kalem, altina giyilebilecek
    her kalemin (daha kucuk sira, baska yuva - butun varyantlariyla) ustune
    oturtulur. Hep hepsi giydirilir: yalniz bir kismi render edilse bile bir
    kalemin sekli, altinda ne olabilecegine bagli ve her render'da ayni olmali.
    Doner: ad -> nesne, cizim sirasiyla."""
    fitted = {}
    order = sorted(ocfg["items"], key=lambda k: ocfg["items"][k]["draw_order"])
    for name in order:
        spec = ocfg["items"][name]
        inner = [fitted[o] for o in fitted
                 if ocfg["items"][o]["draw_order"] < spec["draw_order"] and ocfg["items"][o]["slot"] != spec["slot"]]
        rc.reset_pose(rig, rig)
        fitted[name] = fit_item(spec, gender, body, rig, inner)
    return fitted


LAYER_REACH = 0.04  # m; fit_garment.INHERIT_REACH ile ayni (0.06-0.08 olculdu: kotulesti)


def layer_weights_all(fitted, ocfg, rig, layers):
    """Her kalemin katman agirliklari, dis giysi altindakinin uzuv katmanini
    devralarak (kanal kanal en buyugu). Oyun her katmanda bedeni sonra
    giysileri ciziyor; yelegin omzu on kol katmaninda, kukuletanin eteginin
    ucu govde katmanindaysa on kol katmani sonra cizildigi icin yelek
    kukuletanin ustune cikiyordu (qa/outfit_check.py, giysi karismasi).
    Ustteki giysi alttakinin katmanina da girerse ayni katmanda cizim sirasi
    onu ustte tutar. Dinlenme pozunda olculur; nitelikleri ("lw", "gw")
    yazar. Doner: ad -> agirliklar."""
    from mathutils.kdtree import KDTree
    rc.reset_pose(rig, rig)
    lws, coords = {}, {}
    for name, obj in fitted.items():  # fit_all cizim sirasiyla dondurur
        lw = [list(w) for w in fig_weights.layer_weights(obj, rig, layers)]
        coords[name] = rc.evaluated_coords(obj)
        spec = ocfg["items"][name]
        inner = [o for o in lws if ocfg["items"][o]["draw_order"] < spec["draw_order"]
                 and ocfg["items"][o]["slot"] != spec["slot"]]
        src = [(co, lws[o][k]) for o in inner for k, co in enumerate(coords[o])]
        if src:
            kd = KDTree(len(src))
            for k, (co, _w) in enumerate(src):
                kd.insert(co, k)
            kd.balance()
            for k, co in enumerate(coords[name]):
                _c, j, dist = kd.find(co)
                if dist is not None and dist <= LAYER_REACH:
                    lw[k] = [max(a, b) for a, b in zip(lw[k], src[j][1])]
        lws[name] = lw
        fig_weights.write_attr(obj, lw)
        fig_weights.write_color(obj, [(0.0, 0.0, 1.0, 1.0)] * len(obj.data.vertices), "gw")
    return lws


def member_layers(lw, layers_cfg):
    """Kalemin en az bir noktasinin uyesi oldugu katmanlar (fig_shading'in
    gorunurluk kurali: govde = hicbir uzvun cekirdegi degil, uzuv = kok esigi
    ustu)."""
    core, root = layers_cfg["core_threshold"], layers_cfg["root_threshold"]
    out = []
    for n in layers_cfg["layers"]:
        if n == "torso_head":
            hit = any(max(w) < core for w in lw)
        else:
            hit = any(w[fig_shading.LIMB_CHANNEL[n]] > root - 1e-6 for w in lw)
        if hit:
            out.append(n)
    return out


def _copy_upstream(src_nt, sock, dst_nt, memo):
    """Kaynak dugum agacindaki bir girisin yukarisini hedef agaca kopyalar ve
    hedefteki karsilik gelen cikis soketini doner. Quaternius'ta Base Color
    duz bir doku degil: doku x renk ozniteligi (MIX/MULTIPLY) - render_beast
    yalniz dogrudan dokuyu taniyor, digerinde beyaz kaliyordu."""
    link = sock.links[0]
    node = link.from_node
    if node.name not in memo:
        new = dst_nt.nodes.new(node.bl_idname)
        for attr in ("image", "interpolation", "extension", "uv_map", "layer_name", "data_type",
                     "blend_type", "clamp_result", "clamp_factor", "factor_mode", "operation"):
            if hasattr(node, attr):
                try:
                    setattr(new, attr, getattr(node, attr))
                except (AttributeError, TypeError):
                    pass
        memo[node.name] = new
        for k, inp in enumerate(node.inputs):
            if not inp.enabled:
                continue
            if inp.is_linked:
                out = _copy_upstream(src_nt, inp, dst_nt, memo)
                dst_nt.links.new(out, new.inputs[k])
            elif hasattr(inp, "default_value"):
                try:
                    new.inputs[k].default_value = inp.default_value
                except (AttributeError, TypeError):
                    pass
    new = memo[node.name]
    idx = list(node.outputs).index(link.from_socket)
    return new.outputs[idx]


def albedo_material(cfg, layer, src_mat, core, root):
    """render_beast.albedo_material'in esi, ama Base Color'un butun yukari
    agacini tasiyor (kopya: _copy_upstream)."""
    bsdf = None
    if src_mat is not None and src_mat.use_nodes:
        bsdf = next((n for n in src_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf is None or not bsdf.inputs["Base Color"].is_linked:
        return render_beast.albedo_material(cfg, layer, src_mat, core, root)
    mat = fig_shading.body_material(cfg, "id:" + layer, core=core, root=root,
                                    name_suffix="_alb_%s" % src_mat.name)
    nt = mat.node_tree
    em = next(n for n in nt.nodes if n.type == "EMISSION" and n.inputs["Color"].is_linked
              and n.inputs["Color"].links[0].from_node.type == "COMBINE_COLOR")
    nt.links.remove(em.inputs["Color"].links[0])
    out = _copy_upstream(src_mat.node_tree, bsdf.inputs["Base Color"], nt, {})
    nt.links.new(out, em.inputs["Color"])
    return mat


def set_slots(obj, mats):
    """Malzeme yuvalari korunur (yuz indeksleri bozulmasin), icerik degisir."""
    for k in range(len(obj.material_slots)):
        obj.material_slots[k].material = mats[k] if isinstance(mats, list) else mats


def setup(variant):
    """Varyantin sahnesi, bedenin katman agirliklari ve butun kalemler
    giydirilmis halde (render ve qa/outfit_check.py ayni kurulumu kullanir)."""
    ocfg = json.load(open(os.path.join(PIPE, "config", "outfits.json")))
    layers, retarget = rf.cfg("layers.json"), rf.cfg("retarget.json")
    bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "build/figures/variants", variant, variant + ".blend"))
    rf.enable_mpfb()
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    body = bpy.data.objects["Human"]
    rf.thicken(body, rf.variant_thickness(variant))
    for m in body.modifiers:
        if m.type == "MASK":
            m.show_viewport = False
            m.show_render = True
    rc.reset_pose(rig, rig)
    rest_foot_rot = {n: rig.pose.bones[n].matrix.to_quaternion() for n in ("foot_l", "foot_r")}
    lw = fig_weights.layer_weights(body, rig, layers)
    fig_weights.write_attr(body, lw)
    body_idx = rc.body_vertex_set(body)
    arm_k = [fig_weights.ORDER.index(n) for n in ("back_arm", "front_arm")]
    support_idx = [k for k in body_idx if max(lw[k][a] for a in arm_k) < layers["core_threshold"]]
    fitted = fit_all(ocfg, rf.gender_of(variant), body, rig)
    return dict(ocfg=ocfg, layers=layers, retarget=retarget, rig=rig, body=body,
                rest_foot_rot=rest_foot_rot, support_idx=support_idx, fitted=fitted)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    variant = rf.arg(argv, "--variant")
    ocfg = json.load(open(os.path.join(PIPE, "config", "outfits.json")))
    items = rf.arg(argv, "--items").split(",") if "--items" in argv else list(ocfg["items"])
    build = rf.cfg("build.json")
    clips = rf.arg(argv, "--clips").split(",") if "--clips" in argv else list(build["clips"])
    only = [int(x) for x in rf.arg(argv, "--frames").split(",")] if "--frames" in argv else None

    sc = setup(variant)
    rig, body, layers, retarget = sc["rig"], sc["body"], sc["layers"], sc["retarget"]
    rest_foot_rot, support_idx = sc["rest_foot_rot"], sc["support_idx"]
    m_per_h = None

    objs = {}
    fitted = sc["fitted"]
    lws = layer_weights_all(fitted, sc["ocfg"], rig, layers)
    for name, obj in fitted.items():
        if name not in items:
            obj.hide_render = True
            continue
        olw = lws[name]
        objs[name] = (obj, member_layers(olw, layers), [s.material for s in obj.material_slots])
        print("kalem", name, "katmanlar", objs[name][1], flush=True)

    camcfg0 = dict(rf.cfg("camera.json"))
    fig_shading.setup_render(camcfg0)
    bpy.context.scene.render.use_persistent_data = True
    kw = dict(core=layers["core_threshold"], root=layers["root_threshold"])
    shade = {n: fig_shading.body_material(camcfg0, "layer:" + n, **kw) for n in layers["layers"]}
    body.data.materials.clear()
    body.data.materials.append(fig_shading.body_material(camcfg0, "full", **kw))
    body.visible_camera = False
    curl = retarget.get("finger_curl_deg", [0, 0, 0])

    for clip_name in clips:
        clip_cfg = build["clips"][clip_name]
        camcfg = dict(camcfg0)
        camcfg["ground_px"] = list(clip_cfg["anchor_px"])
        fig_shading.setup_camera(camcfg, 0.0, 0.0)
        clip = json.load(open(os.path.join(ROOT, "build", "figures", "clips", clip_name + ".json")))
        base = None
        if clip_cfg.get("base"):
            base = json.load(open(os.path.join(ROOT, "build", "figures", "clips", clip_cfg["base"] + ".json")))
        rc.reset_pose(rig, rig)
        m_per_h = (rig.matrix_world @ rig.data.bones["pelvis"].head_local).z / float(clip.get("hip_ratio", 0.46))
        own = clip_cfg.get("layers", layers["layers"])
        for name, (obj, mlayers, src) in objs.items():
            for other, o2 in fitted.items():
                o2.hide_render = other != name
            alb = {n: [albedo_material(camcfg, n, s, kw["core"], kw["root"]) for s in src]
                   for n in layers["layers"]}
            todo = [n for n in mlayers if n in own]
            for fr in clip["frames"]:
                i = fr["index"]
                if only is not None and i not in only:
                    continue
                t0 = time.time()
                rf.pose_clip_frame(rig, body, fr, base, clip, clip_cfg, layers, rest_foot_rot,
                                   retarget, curl, support_idx, m_per_h, camcfg)
                d = os.path.join(OUT, variant, name, clip_name, "f%02d" % i)
                os.makedirs(d, exist_ok=True)
                for n in todo:
                    bpy.context.scene.cycles.samples = int(ocfg["samples_shade"])
                    set_slots(obj, shade[n])
                    rc.render(os.path.join(d, "shade_%s.png" % n))
                    bpy.context.scene.cycles.samples = int(ocfg["samples_albedo"])
                    set_slots(obj, alb[n])
                    rc.render(os.path.join(d, "albedo_%s.png" % n))
                json.dump({"layers": todo}, open(os.path.join(d, "meta.json"), "w"))
                print("kare", variant, name, clip_name, i, "%.1f sn" % (time.time() - t0), flush=True)


if __name__ == "__main__":
    main()
