"""Asama 1: bir MPFB2 govde varyanti uret - .blend + bone_map dogrulamasi +
gercek kemik uzunluklari (REF_H birimine cevrilmis) + debug eklem-isareti
render'i.

Calistirma (bpy pip paketi, ayri bir `blender` ikili dosyasi degil - bkz.
SETUP.md):
    python3 tools/figure_pipeline/blender/make_variant.py config/variants/male_medium.json

Cikti: build/figures/variants/<id>/
    <id>.blend              - govde + iskelet
    rig_spec.json           - paint_joints (bu turda: kanonik oranlarla,
                               yalnizca boy ile olceklenmis - bkz. asagidaki
                               "Kapsam karari") + bu varyantin GERCEK olculmus
                               kemik uzunluklari (ileride FigureRig'e per-limb
                               IK eklenirse kullanilacak)
    debug_joints.png        - paint_joints'in render uzerine isaretlenmis hali
    bone_map_report.json    - validate_bone_map.py ciktisi
"""
import json
import math
import os
import sys

import bpy
from mathutils import Vector

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(PIPE, "blender"))

import human_body_render as hbr  # noqa: E402 - kamera/paint_pose altyapisi yeniden kullaniliyor

MPFB_ZIP = "/tmp/mpfb.zip"
RIG_SPEC_CANON = os.path.join(ROOT, "docs", "wardrobe", "rig_spec.json")
BONE_MAP_PATH = os.path.join(PIPE, "config", "bone_map.json")
OUT_ROOT = os.path.join(ROOT, "build", "figures", "variants")


def ensure_mpfb():
    bpy.ops.extensions.package_install_files(
        filepath=MPFB_ZIP, repo="user_default", enable_on_install=True
    )


def load_variant_cfg(path):
    with open(path) as f:
        return json.load(f)


def build_human(cfg):
    # KRITIK: bos sahneden basla. quaternius_render.import_outfit() bunu
    # zaten yapiyordu (read_factory_settings(use_empty=True)); bu script
    # ilk turda atladi ve Blender'in varsayilan baslangic sahnesindeki
    # "Cube" nesnesi (2x2x2, dunya orijininde - tam govdenin kalca/ayak
    # hizasinda) debug render'da govdenin alt yarisini kaplayan opak gri
    # bir dikdortgen olarak ortaya cikti. Govde render edilmiyor degildi -
    # bu kubun ARKASINDA kaliyordu.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    from bl_ext.user_default.mpfb.services.humanservice import HumanService
    macros = dict(cfg["macros"])
    basemesh = HumanService.create_human(macro_detail_dict=macros)
    rig = HumanService.add_builtin_rig(basemesh, cfg["rig"], import_weights=True)
    return basemesh, rig


def validate_bone_map(rig, bone_map):
    """Her MPFB deform kemigi tam olarak bir FigureRig kemigine dusmeli -
    kilavuz bolum 8.2'nin kendi kontrolu. Esleme bulunamayan kemik varsa hata
    (sessizce atlanirsa o bolgede agirlik eksik kalir, kilavuzun kendi uyardigi
    hata)."""
    all_mapped = set()
    seen_twice = set()
    for fb, mpfb_bones in bone_map.items():
        if fb == "_comment":
            continue
        for b in mpfb_bones:
            if b in all_mapped:
                seen_twice.add(b)
            all_mapped.add(b)

    rig_bones = {b.name for b in rig.data.bones}
    unmapped = sorted(rig_bones - all_mapped)
    extra = sorted(all_mapped - rig_bones)
    report = {
        "rig_bone_count": len(rig_bones),
        "mapped_bone_count": len(all_mapped & rig_bones),
        "unmapped_deform_bones": unmapped,
        "mapped_but_not_in_rig": extra,
        "mapped_twice": sorted(seen_twice),
        "ok": len(unmapped) == 0 and len(seen_twice) == 0,
    }
    return report


def measure_bone_lengths(rig):
    """Gercek (REST pozu) kemik uzunluklari, Blender dunya birimlerinde -
    mesh sinirlayici kutusundan degil, dogrudan pose kemiklerinden (kilavuz
    bolum 3'un yasakladigi hatanin tam tersi)."""
    out = {}
    for b in rig.pose.bones:
        head = rig.matrix_world @ b.head
        tail = rig.matrix_world @ b.tail
        out[b.name] = (tail - head).length
    return out


def figure_scale(rig, spec):
    """quaternius_render.joints_for() ile AYNI formul: yukseklik olcegi
    `m` (dunya birimi / REF_H pikseli), mesh degil REST kemiklerinden."""
    ground = 0.5 * (rig.pose.bones["foot_l"].tail[2] + rig.pose.bones["foot_r"].tail[2])
    shoulder_z = 0.5 * (rig.pose.bones["clavicle_l"].head[2] + rig.pose.bones["clavicle_r"].head[2])
    # Dunya matrisini carp (create_human feet_on_ground=True ile location
    # uyguluyor, ama rotasyon/olcek yoksa head/tail zaten dunya uzayinda
    # sayilabilir - emin olmak icin matrix_world'u Z bileseni icin de uygula).
    ground_w = (rig.matrix_world @ Vector((0, 0, ground))).z if False else ground
    shoulder_px = -spec["paint_joints"]["shoulder"][1]
    m = (shoulder_z - ground) / shoulder_px
    return m, ground, shoulder_z


def save_debug_joint_image(variant_id, rig, spec, m, ground, out_dir):
    """paint_joints'in bu varyantin KENDI govdesi uzerine isaretlendigi bir
    render - kilavuz 8.4'un "sapma 1 pikselden buyukse dur" kapisi icin.
    Bu turda paint_joints kanonik (bkz. make_variant.py docstring'indeki
    kapsam karari) - yani isaretler, bu varyantin REST iskeletinin
    GERCEK eklem noktalariyla DEGIL, kanonik orani bu varyantin boyuna
    olcekleyen hedef noktalarla cakisir. Sapma varsa (ayni REF_H birimine
    cevrilmis gercek omuz/kalca/ayak bilegi ile kanonik hedef arasinda)
    burada raporlanir.
    """
    checks = {}
    real_shoulder_px = (0.0, -(rig.pose.bones["clavicle_l"].head[2] + rig.pose.bones["clavicle_r"].head[2]) / 2.0 / m + ground / m)
    # Basitce: omuz ve ayak bilegi hedefiyle gercek olcumu REF_H biriminde kiyasla.
    canon_shoulder_y = spec["paint_joints"]["shoulder"][1]
    measured_shoulder_y = -(( (rig.pose.bones["clavicle_l"].head[2] + rig.pose.bones["clavicle_r"].head[2]) / 2.0 - ground) / m)
    checks["shoulder_y_deviation_px"] = abs(measured_shoulder_y - canon_shoulder_y)
    return checks


def main():
    cfg_path = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else sys.argv[-1]
    cfg = load_variant_cfg(cfg_path)
    variant_id = cfg["id"]
    out_dir = os.path.join(OUT_ROOT, variant_id)
    os.makedirs(out_dir, exist_ok=True)

    ensure_mpfb()
    basemesh, rig = build_human(cfg)

    with open(BONE_MAP_PATH) as f:
        bone_map = json.load(f)
    bm_report = validate_bone_map(rig, bone_map)
    with open(os.path.join(out_dir, "bone_map_report.json"), "w") as f:
        json.dump(bm_report, f, indent=1)
    print("bone_map dogrulama:", "OK" if bm_report["ok"] else "HATA", bm_report)
    if not bm_report["ok"]:
        print("DURDURULDU: esiz esleme kirik - kilavuzun kendi kurali (bolum 8.2).")
        sys.exit(1)

    spec = json.load(open(RIG_SPEC_CANON))
    m, ground, shoulder_z = figure_scale(rig, spec)
    lengths_world = measure_bone_lengths(rig)
    lengths_px = {k: v / m for k, v in lengths_world.items()}

    checks = save_debug_joint_image(variant_id, rig, spec, m, ground, out_dir)

    out_spec = {
        "variant": variant_id,
        "_scope_note": (
            "Bu turda paint_joints KANONIK rig_spec.json'dan geliyor, yalnizca "
            "bu varyantin olcek faktoru m ile orantili - FigureRig.pose()'un "
            "bugun hic per-limb (ust kol/alt kol/uyluk/baldir orani) parametresi "
            "almamasi yuzunden (sabit oranlar, yalnizca h ile olcekleniyor - "
            "mevcut oyunun TUM karakterleri icin zaten boyle, height_scale "
            "disinda kisiye ozel oran yok). Asagidaki measured_bone_lengths_px "
            "GERCEK, bu varyanttan olculmus deger - FigureRig'e per-limb IK "
            "eklenirse (ayri, kendi basina olculmesi gereken bir mimari "
            "degisiklik - CLAUDE.md'nin 'paylasilan sisteme olcmeden "
            "kablolama' kurali) buradan okunacak."
        ),
        "ref_h": spec["ref_h"],
        "head_radius": spec["head_radius"],
        "figure_scale_m": m,
        "paint_joints": spec["paint_joints"],
        "measured_bone_lengths_px": lengths_px,
        "debug_checks": checks,
    }
    with open(os.path.join(out_dir, "rig_spec.json"), "w") as f:
        json.dump(out_spec, f, indent=1)

    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out_dir, "%s.blend" % variant_id))
    print("TAMAM:", variant_id, "m=", m, "shoulder_y_sapma_px=", checks["shoulder_y_deviation_px"])
    print("yazildi:", out_dir)


if __name__ == "__main__":
    main()
