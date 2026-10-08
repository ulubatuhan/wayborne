"""Asama 2: bir (varyant, katman) icin doku render'i + agirlik haritasi
(EXR) render'i. Bu ilk tur yalnizca TEK bir katmani (forearm_front) kanitlar
- mekanizma dogrulaninca diger katmanlara/govdeye/giysiye genellenir.

    python3 tools/figure_pipeline/blender/render_passes.py male_medium forearm_front
"""
import json
import os
import sys

import bpy
from mathutils import Vector

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(PIPE, "blender"))

import human_body_render as hbr  # noqa: E402
import make_variant as mv  # noqa: E402
import render_variant_debug as rvd  # noqa: E402

OUT_ROOT = os.path.join(ROOT, "build", "figures", "variants")
BONE_MAP_PATH = os.path.join(PIPE, "config", "bone_map.json")

CORE_THRESHOLD = 0.5
ROOT_THRESHOLD = 0.02
# "bones" dizisi - EXR'in R/G/B kanallarina bu sirayla yazilacak 3 FigureRig
# kemigi. Katmanin KENDI kemigi her zaman R'de (kilavuz 9.4: "bir render'da
# 3 kemik tasinir").
LAYER_BONES = {
    # [kendi kemigi (R), ebeveyn (G), cocuk (B)] - forearm_front'un kurdugu
    # desenin tum govdeye genellenmesi. Uc noktalarda (el/ayak/bas) cocuk
    # yok, ebeveyn G ve B'ye tekrar yazilir (zararsiz - silhouette_mesh
    # ihtiyac duyulan eklemlerin KUMESINI aliyor, tekrar kayit sorun
    # yaratmiyor). Govde (torso) kok oldugu icin ebeveyni yok - DRAW_ORDER
    # geregi govde arka uzuvlarin ustune cizildigi icin (onlari ortmesi
    # gerekiyor) B/G'ye iki arka-uzuv komsusu (govdeye en yakin ucu
    # paylasan upper_arm_back/thigh_back) yazildi.
    "forearm_front": ["forearm_front", "upper_arm_front", "hand_front"],
    "forearm_back": ["forearm_back", "upper_arm_back", "hand_back"],
    "upper_arm_front": ["upper_arm_front", "torso", "forearm_front"],
    "upper_arm_back": ["upper_arm_back", "torso", "forearm_back"],
    "hand_front": ["hand_front", "forearm_front", "forearm_front"],
    "hand_back": ["hand_back", "forearm_back", "forearm_back"],
    "thigh_front": ["thigh_front", "torso", "shin_front"],
    "thigh_back": ["thigh_back", "torso", "shin_back"],
    "shin_front": ["shin_front", "thigh_front", "foot_front"],
    "shin_back": ["shin_back", "thigh_back", "foot_back"],
    "foot_front": ["foot_front", "shin_front", "shin_front"],
    "foot_back": ["foot_back", "shin_back", "shin_back"],
    "torso": ["torso", "upper_arm_back", "thigh_back"],
    "head": ["head", "torso", "torso"],
}


def vertex_bucket_weights(basemesh, bone_map):
    """vertex index -> {figure_bone: normalize edilmemis agirlik toplami} -
    build_real_body_skin.py'nin GROUP_TO_BONE mantiginin govde-genel hali,
    ama burada DOGRUDAN bone_map.json'dan (kilavuzun istedigi tek kaynak)."""
    group_to_bone = {}
    for fb, mpfb_bones in bone_map.items():
        if fb == "_comment":
            continue
        for b in mpfb_bones:
            group_to_bone[b] = fb
    idx_to_name = {g.index: g.name for g in basemesh.vertex_groups}
    out = []
    for v in basemesh.data.vertices:
        acc = {}
        for ge in v.groups:
            fb = group_to_bone.get(idx_to_name.get(ge.group))
            if fb:
                acc[fb] = acc.get(fb, 0.0) + ge.weight
        out.append(acc)
    return out


def make_layer_vertex_group(basemesh, name, weights, target_bone):
    vg = basemesh.vertex_groups.new(name=name)
    for i, acc in enumerate(weights):
        total = sum(acc.values())
        w = (acc.get(target_bone, 0.0) / total) if total > 1e-9 else 0.0
        if w > 1e-6:
            vg.add([i], w, "REPLACE")
    return vg


def setup_cycles_data_pass(basemesh, color_attr_name):
    """Kilavuz 9.4 Workbench/FLAT/AA-kapali istiyor, ama bu bpy 5.0.1
    paketinde yalnizca CYCLES motoru kayitli - Workbench/EEVEE gercek bir
    GL baglami (libEGL) ariyor ve bu kum havuzunda yok (denendi, SIGABRT
    ile cokuyor). Cycles'in kendi "AA kapali" dugmesi yok, ama bir Emission
    shader (vertex rengini DOGRUDAN, hicbir isik/golge/AO katkisi olmadan
    yayan) + minimal piksel filtre genisligi (kenar bulanikligini pratikte
    sifira indiren) ayni veri-dogrulugu hedefini karsiliyor. Bu, kilavuzun
    kendi "Workbench, hizli ve deterministik" gerekcesine denk bir
    *mekanizma* degisikligi - veri anlamı aynı kalıyor (renk = oznitelik
    degeri, golgelendirme yok), yalnizca motoru bu ortamda calisan tek
    motora uyarlaniyor."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 1
    scene.cycles.use_denoising = False
    scene.cycles.pixel_filter_type = "BOX"
    scene.cycles.filter_width = 0.01
    scene.cycles.max_bounces = 0
    scene.render.image_settings.file_format = "OPEN_EXR"
    scene.render.image_settings.color_depth = "32"
    scene.render.image_settings.exr_codec = "NONE"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"

    mat = bpy.data.materials.new("data_pass_%s" % color_attr_name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = color_attr_name
    nt.links.new(attr.outputs["Color"], emit.inputs["Color"])
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    basemesh.data.materials.clear()
    basemesh.data.materials.append(mat)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[-2:]
    variant_id, layer_name = args[0], args[1]
    out_dir = os.path.join(OUT_ROOT, variant_id, "layers", layer_name)
    os.makedirs(out_dir, exist_ok=True)

    blend_path = os.path.join(OUT_ROOT, variant_id, "%s.blend" % variant_id)
    bpy.ops.wm.open_mainfile(filepath=blend_path)
    mv.ensure_mpfb()
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    basemesh = next(o for o in bpy.data.objects if o.type == "MESH")

    spec = json.load(open(hbr.SPEC_PATH))
    m, ground, shoulder_z = mv.figure_scale(rig, spec)
    joints = {"height": m * hbr.figure_height(spec), "ground": ground}
    rvd.pose_mpfb(rig, spec, joints)

    bone_map = json.load(open(BONE_MAP_PATH))
    weights = vertex_bucket_weights(basemesh, bone_map)

    core_bone = layer_name
    w_core = []
    for acc in weights:
        total = sum(acc.values())
        w_core.append((acc.get(core_bone, 0.0) / total) if total > 1e-9 else 0.0)

    # Katman uyeligi: w_K >= ROOT_THRESHOLD (kok uzantisi dahil cekirdek).
    vg_mask = basemesh.vertex_groups.new(name="layer_%s_mask" % layer_name)
    for i, w in enumerate(w_core):
        if w >= ROOT_THRESHOLD:
            vg_mask.add([i], 1.0, "REPLACE")

    # Esik siniri uc-ucgen duzeyinde pürüzlü (dis-agirligin kendisi mesh
    # topolojisine gore degisken) - bu, Asama 3'un kontur sadelestirmesiyle
    # 150-600 vertex hedefi arasinda gercek bir gerilim yaratti (olculdu:
    # pürüzlü siniri 1px'e kadar takip etmek icin ~1000 vertex gerekti).
    # vertex_group_smooth, agirlik sinirini mesh'in kendi kenar komsuluguna
    # gore yumusatarak kontur sonra cok daha az noktayla dogru temsil
    # edilsin diye - bu sinir zaten "gizli, komsu katmanla ortusen" bolge
    # (kilavuz 9.2), piksel-tam olmasi gerekmiyor.
    bpy.context.view_layer.objects.active = basemesh
    basemesh.vertex_groups.active_index = vg_mask.index
    bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
    bpy.ops.object.vertex_group_smooth(group_select_mode="ACTIVE", factor=0.5, repeat=4)
    bpy.ops.object.mode_set(mode="OBJECT")

    # Govdenin "Hide helpers" maskesini (vertex_group='body') KORUYARAK
    # ikinci bir Mask modifier ekle - katman disindaki govde de gizlensin.
    mod = basemesh.modifiers.new("LayerMask_%s" % layer_name, "MASK")
    mod.vertex_group = vg_mask.name
    mod.show_in_editmode = True

    cam = hbr.setup_scene(joints, spec)

    # --- Doku render'i (sanatsal yer tutucu - noturo gri, Aşama 2'nin
    # mekanizma kanitini kirletmesin diye stil kararina girilmedi) ---
    mat = hbr.grey_material()
    basemesh.data.materials.clear()
    basemesh.data.materials.append(mat)
    tex_path = os.path.join(out_dir, "texture.png")
    hbr.render_to(tex_path)
    print("doku yazildi:", tex_path)

    # --- Agirlik haritasi render'lari (EXR, FLAT/AA kapali/32-bit) ---
    bones3 = LAYER_BONES[layer_name]
    per_bone_w = {}
    for b in bones3:
        wl = []
        for acc in weights:
            total = sum(acc.values())
            wl.append((acc.get(b, 0.0) / total) if total > 1e-9 else 0.0)
        per_bone_w[b] = wl

    if "wpass" in basemesh.data.color_attributes:
        basemesh.data.color_attributes.remove(basemesh.data.color_attributes["wpass"])
    attr = basemesh.data.color_attributes.new("wpass", "FLOAT_COLOR", "POINT")
    for i in range(len(basemesh.data.vertices)):
        attr.data[i].color = (
            per_bone_w[bones3[0]][i], per_bone_w[bones3[1]][i], per_bone_w[bones3[2]][i], 1.0
        )
    basemesh.data.color_attributes.active_color = attr
    basemesh.data.attributes.default_color_name = "wpass"
    setup_cycles_data_pass(basemesh, "wpass")

    weight_path = os.path.join(out_dir, "weights.exr")
    bpy.context.scene.render.filepath = weight_path
    bpy.ops.render.render(write_still=True)
    print("agirlik haritasi yazildi:", weight_path)

    # Kok maskesi (smoothstep) - ayri, tek kanalli bir EXR.
    if "rootmask" in basemesh.data.color_attributes:
        basemesh.data.color_attributes.remove(basemesh.data.color_attributes["rootmask"])
    rattr = basemesh.data.color_attributes.new("rootmask", "FLOAT_COLOR", "POINT")
    for i, w in enumerate(w_core):
        t = max(0.0, min(1.0, (w - ROOT_THRESHOLD) / (CORE_THRESHOLD - ROOT_THRESHOLD)))
        s = t * t * (3.0 - 2.0 * t)  # smoothstep
        rattr.data[i].color = (s, s, s, 1.0)
    basemesh.data.color_attributes.active_color = rattr
    basemesh.data.attributes.default_color_name = "rootmask"
    setup_cycles_data_pass(basemesh, "rootmask")
    root_path = os.path.join(out_dir, "root_mask.exr")
    bpy.context.scene.render.filepath = root_path
    bpy.ops.render.render(write_still=True)
    print("kok maskesi yazildi:", root_path)

    meta = {
        "variant": variant_id,
        "layer": layer_name,
        "bones3": bones3,
        "core_threshold": CORE_THRESHOLD,
        "root_threshold": ROOT_THRESHOLD,
        "ref_h": spec["ref_h"],
        "figure_scale_m": m,
        "ground": ground,
        "canvas": list(hbr.CANVAS),
    }
    with open(os.path.join(out_dir, "meta.json"), "w") as f:
        json.dump(meta, f, indent=1)
    print("TAMAM:", out_dir)


if __name__ == "__main__":
    main()
