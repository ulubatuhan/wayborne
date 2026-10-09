"""Kiyafetler render edilmeden ONCE: ust uste giyilince birbirine giriyorlar mi?

    python3 -I tools/figure_pipeline/qa/outfit_check.py --variant male_average \
        [--combos peasant_pants,peasant_shoes,peasant_shirt;...] [--clips walk,idle] [--frames 0,6,12,18]

Iki olcu, ikisi de butun kalemler cizim sirasiyla giydirildikten sonra
(render_outfits.setup - render'in kendisiyle ayni sahne):

1. 3B tasma (`poke`): pozlanmis her karede, bir alt giysinin her noktasi icin
   bedenin altindaki yuzey normali boyunca ust giysi araniyor; ust giysi o
   noktayi ortuyorsa, alt giysi ondan disarida olmamali. Sayi: ortulen alt
   giysi noktalarinin disari tasan payi. Bu, kalemler birbirinden habersiz
   bedene sarildiginda pantolon belinin gomlegin icinden cikmasini olcer.
2. 2B bindirme (`composite`): oyunun cizdigi sira (her katmanda beden, sonra
   giysiler cizim sirasiyla) ile ayni karenin tek parca, gercek gorunurluklu
   render'i karsilastiriliyor - her piksel hangi nesneye ait (duz renkli,
   isiksiz kimlik render'i). Yanlis nesne gosteren giysi pikseli = hata.

Cikti: build/figures/outfit_qa/<varyant>/table.json, fark resimleri.
Cikis kodu 1: esiklerden biri asildi.
"""
import json
import os
import sys

import bpy
import numpy as np
from mathutils import Vector
from PIL import Image

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "blender"))
sys.path.insert(0, os.path.join(PIPE, "beasts"))
import fig_shading  # noqa: E402
import fig_weights  # noqa: E402
import fit_garment  # noqa: E402
import render_clip as rc  # noqa: E402
import render_frames as rf  # noqa: E402
import render_outfits as ro  # noqa: E402

OUT = os.path.join(ROOT, "build", "figures", "outfit_qa")
# 3B: ortulen alt giysi noktalarinin en fazla bu payi disari tasabilir (yuzde).
MAX_POKE_PCT = 0.5
TOL = 0.001  # m; yuzeyler arasi bu kadarlik yakinlik tasma sayilmaz
# 2B: giysi piksellerinin en fazla bu payi yanlis nesneyi gosterebilir (kenar
# yumusatmasi tek piksellik serit birakiyor).
MAX_COMPOSITE_PCT = 2.0
# Giysi yerinde giysi, iki yon (3B'de icinden gecme dahil): eski, birbirinden
# habersiz giydirmede %8.8; katmanli giydirmede en kotu %1.6 - hep ayni kare,
# saldirinin 3. karesi: kol tam havada, yelegin omzu 3B'de kukuletanin
# pelerininden cikiyor (oyunda pelerin ustte ciziliyor). Sizma - oyunun alttakini ustte cizmesi -
# ayri ve siki: en kotu %0.27 olculdu (iri erkek, kol tam havada: gomlegin
# gogsu on kol katmanina giriyor, yelegin oradaki parcasi giremiyor).
MAX_SWAP_PCT = 2.0
MAX_BLEED_PCT = 0.3
BODY_ID = (0.5, 0.5, 0.5)
PALETTE = [(1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 0), (0, 1, 1), (1, 0, 1), (1, 0.5, 0), (0.5, 0, 1)]
DEFAULT_COMBOS = [
    "peasant_pants,peasant_shoes,peasant_shirt",
    "ranger_pants,ranger_boots,peasant_shirt,ranger_jacket,ranger_hood",
    "peasant_pants,ranger_boots,ranger_jacket",
]


_FLAT = {}


def flat(cfg, mode, color, name):
    """Isiksiz duz renk; `mode` fig_shading'in id/id:<katman> maskesini tasir."""
    key = (mode, tuple(color), name)
    if key in _FLAT:
        return _FLAT[key]
    mat = fig_shading.body_material(cfg, mode, name_suffix="_qa_" + name)
    nt = mat.node_tree
    em = next(n for n in nt.nodes if n.type == "EMISSION" and n.inputs["Color"].is_linked
              and n.inputs["Color"].links[0].from_node.type == "COMBINE_COLOR")
    nt.links.remove(em.inputs["Color"].links[0])
    em.inputs["Color"].default_value = (color[0], color[1], color[2], 1.0)
    _FLAT[key] = mat
    return mat


LAYER_KW = {}


def mask(cfg, layer):
    """Paketin katman alfasi golge render'indan geliyor (pack_frames/
    pack_outfits) - test de ayni malzemenin alfasini okumali."""
    key = ("layer", layer)
    if key not in _FLAT:
        _FLAT[key] = fig_shading.body_material(cfg, "layer:" + layer, name_suffix="_qa", **LAYER_KW)
    return _FLAT[key]


def set_mat(obj, mat):
    for k in range(len(obj.material_slots)):
        obj.material_slots[k].material = mat


POKE_REACH = 0.03  # m; bu kadar disarida bir dis giysi yuzu "ustunde" sayilir


def poke(body, inner, outer):
    """Pozlanmis aglarda alt giysinin dis giysiden disari tasan noktalari.
    Bir alt giysi noktasindan bedene dogru (bedenin en yakin normalinin tersi)
    gidilince bedenden ONCE dis giysiye carpiliyorsa nokta dis giysinin
    disinda. Ilk surum tersinden olcuyordu (bedenden disari, dis giysi nerede)
    ve govdeye yakin sallanan koldaki gomlek kolunu yelegin govdesinin
    disinda sayiyordu: kol yelegin degil kolun ustunde. Doner: (tasan, ortulen)."""
    # Giydirmenin olctugu beden: MPFB'nin yardimci aglari (tayt, etek) gizli.
    prev = fit_garment._masks(body, True)
    btree, bm = fit_garment.body_bvh(body)
    for m, v in prev:
        m.show_viewport = v
    bpy.context.view_layer.update()
    otree = fit_garment.mesh_bvh(outer)
    covered = out = 0
    for co in rc.evaluated_coords(inner):
        loc, nrm, _f, _d = btree.find_nearest(co)
        if loc is None:
            continue
        down = -nrm
        start = co + nrm * 1e-4
        bhit, _n, _i, bd = btree.ray_cast(start, down, 1.0)
        ohit, _n2, _i2, od = otree.ray_cast(start, down, POKE_REACH)
        if ohit is not None and (bhit is None or od < bd - TOL):
            out += 1
        # ortulme: disari dogru dis giysi var mi (yuzde paydasi)
        if otree.ray_cast(co - nrm * 1e-4, nrm, POKE_REACH)[0] is not None or ohit is not None:
            covered += 1
    bm.free()
    return out, covered


# Giydirilmis giysinin boyu / kaynaktaki boyu (beden boy oraninda). Bir kemik
# gerilirse ilk boyda gorunur. Yan (x) ve on-arka (y) olculmuyor: kaynak T-poz,
# bizimki A-poz (kollar), katmanlama da giysiyi bilerek kalinlastiriyor.
HEIGHT_RANGE = (0.85, 1.15)
# Hicbir giysi kafanin tepesinden bundan fazla yukari cikmaz (m). Kukuleta
# 10 cm cikiyordu ve boy oranina gore "normal"di: kaynak da buyuk kafaliydi.
MAX_HEADROOM = 0.06


def proportions(fitted, rig, body):
    """Dinlenme pozunda her kalemin boy orani ve kafanin ustundeki payi."""
    rc.reset_pose(rig, rig)
    top = max(c.z for c in rc.evaluated_coords(body))
    out, bad = {}, []
    for name, obj in fitted.items():
        zs = [c.z for c in rc.evaluated_coords(obj)]
        r = (max(zs) - min(zs)) / max(1e-6, obj["native_max"][2] - obj["native_min"][2])
        room = max(zs) - top
        snug = bool(obj.get("snugged", False))
        out[name] = {"height_ratio": round(r, 2), "above_head_m": round(room, 3), "snugged": snug}
        # Kafaya gore kucultulen kalem (fit_garment.snug_head) kaynagindan
        # bilerek farkli: onun olcusu tepedeki pay.
        if (not snug and not (HEIGHT_RANGE[0] <= r <= HEIGHT_RANGE[1])) or room > MAX_HEADROOM:
            bad.append(name)
    return out, bad


def interior(lab):
    """Etiketi dort komsusuyla ayni pikseller: iki nesnenin sinirindaki tek
    piksellik serit kenar yumusatmasi, hata degil (ilk olcumde butun
    siluet ve dikis cizgileri 'yanlis' cikiyordu)."""
    ok = np.ones(lab.shape, bool)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ok &= lab == np.roll(np.roll(lab, dy, 0), dx, 1)
    return ok


def label(img, colors):
    """RGBA kimlik resmi -> etiket haritasi (-1 bos), en yakin palet rengi."""
    a = img[..., 3] > 127
    rgb = img[..., :3].astype(np.float32) / 255.0
    pal = np.array(colors, np.float32)
    d = ((rgb[:, :, None, :] - pal[None, None]) ** 2).sum(-1)
    lab = d.argmin(-1)
    lab[~a] = -1
    return lab


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    variant = rf.arg(argv, "--variant")
    combos = (rf.arg(argv, "--combos").split(";") if "--combos" in argv else DEFAULT_COMBOS)
    combos = [c.split(",") for c in combos]
    clips = rf.arg(argv, "--clips").split(",") if "--clips" in argv else ["walk", "attack_swing"]
    frames = [int(x) for x in rf.arg(argv, "--frames").split(",")] if "--frames" in argv else [0, 4, 6, 12, 18]
    sc = ro.setup(variant)
    rig, body, layers, ocfg = sc["rig"], sc["body"], sc["layers"], sc["ocfg"]
    fitted = sc["fitted"]
    build = rf.cfg("build.json")
    LAYER_KW.update(core=layers["core_threshold"], root=layers["root_threshold"])
    ratios, misshapen = proportions(fitted, rig, body)
    print("ORAN", json.dumps(ratios), "bozuk:", misshapen, flush=True)
    ro.layer_weights_all(fitted, ocfg, rig, layers)
    camcfg0 = dict(rf.cfg("camera.json"))
    fig_shading.setup_render(camcfg0)
    scene = bpy.context.scene
    scene.cycles.samples = 4
    scene.render.filter_size = 0.01
    curl = sc["retarget"].get("finger_curl_deg", [0, 0, 0])
    out_dir = os.path.join(OUT, variant)
    os.makedirs(out_dir, exist_ok=True)
    rows, worst_poke, worst_comp, worst_swap, worst_bleed = [], 0.0, 0.0, 0.0, 0.0
    body_full = flat(camcfg0, "id", BODY_ID, "body")
    for clip_name in clips:
        clip_cfg = build["clips"][clip_name]
        camcfg = dict(camcfg0)
        camcfg["ground_px"] = list(clip_cfg["anchor_px"])
        fig_shading.setup_camera(camcfg, 0.0, 0.0)
        clip = json.load(open(os.path.join(ROOT, "build", "figures", "clips", clip_name + ".json")))
        rc.reset_pose(rig, rig)
        m_per_h = (rig.matrix_world @ rig.data.bones["pelvis"].head_local).z / float(clip.get("hip_ratio", 0.46))
        for fr in clip["frames"]:
            i = fr["index"]
            if i not in frames:
                continue
            rf.pose_clip_frame(rig, body, fr, None, clip, clip_cfg, layers, sc["rest_foot_rot"],
                               sc["retarget"], curl, sc["support_idx"], m_per_h, camcfg)
            for combo in combos:
                combo = sorted(combo, key=lambda k: ocfg["items"][k]["draw_order"])
                tag = "%s_f%02d_%s" % (clip_name, i, "+".join(combo))
                row = {"clip": clip_name, "frame": i, "combo": combo, "poke": {}}
                for a in range(len(combo)):
                    for b in range(a + 1, len(combo)):
                        o, c = poke(body, fitted[combo[a]], fitted[combo[b]])
                        pct = 100.0 * o / max(c, 1)
                        row["poke"]["%s<%s" % (combo[a], combo[b])] = [o, c, round(pct, 2)]
                        worst_poke = max(worst_poke, pct)
                colors = [BODY_ID] + PALETTE[:len(combo)]
                for name, obj in fitted.items():
                    obj.hide_render = name not in combo
                # gercek: herkes kameraya gorunur, gercek ortme
                body.visible_camera = True
                set_mat(body, body_full)
                for k, name in enumerate(combo):
                    set_mat(fitted[name], flat(camcfg0, "id", PALETTE[k], name))
                rc.render(os.path.join(out_dir, tag + "_truth.png"))
                truth = label(np.asarray(Image.open(os.path.join(out_dir, tag + "_truth.png")).convert("RGBA")),
                              colors)
                p = os.path.join(out_dir, "layer.png")
                # oyunun bindirmesi: katman katman, beden sonra giysiler
                comp = np.full(truth.shape, -1, int)
                body.visible_camera = False
                bdir = os.path.join(ROOT, "build", "figures", "out", variant, clip_name, "f%02d" % i)
                for layer in layers["layers"]:
                    # Beden: paketlenen resmin kendisi (build/figures/out).
                    m = np.asarray(Image.open(os.path.join(bdir, layer + ".png")).convert("RGBA"))[..., 3] > 127
                    comp[m] = 0
                    body.visible_camera = False
                    for k, name in enumerate(combo):
                        for other in combo:
                            fitted[other].hide_render = other != name
                        set_mat(fitted[name], mask(camcfg0, layer))
                        rc.render(p)
                        m = np.asarray(Image.open(p).convert("RGBA"))[..., 3] > 127
                        comp[m] = k + 1
                for name in combo:
                    fitted[name].hide_render = False
                body.visible_camera = True
                garment = (truth > 0) | (comp > 0)
                wrong = garment & (truth != comp) & interior(truth)
                pct = 100.0 * wrong.sum() / max(garment.sum(), 1)
                row["composite_wrong_pct"] = round(pct, 2)
                # Giysi yerine giysi. Iki yonu ayri: "sizma" = ust giysinin
                # gorunmesi gereken yerde oyun alttakini ciziyor (pantolon beli
                # gomlegin onunde - bildirilen hata); tersi, 3B'de alttakinin
                # ustten tasmasi (kalkan kolun omzu kukuleta pelerininden),
                # oyunda ust giysiyle ortuluyor ve bilgi icin raporlaniyor.
                # combo cizim sirasiyla, etiket = sira + 1: buyuk etiket ustte.
                swap = (truth > 0) & (comp > 0) & (truth != comp) & interior(truth)
                bleed = swap & (comp < truth)
                spct = 100.0 * bleed.sum() / max(garment.sum(), 1)
                row["garment_swap_pct"] = round(100.0 * swap.sum() / max(garment.sum(), 1), 2)
                row["bleed_pct"] = round(spct, 2)
                worst_bleed = max(worst_bleed, spct)
                spct = row["garment_swap_pct"]
                if swap.any():
                    pairs = {}
                    for tl, cl in zip(truth[swap], comp[swap]):
                        key = "%s>%s" % (combo[tl - 1], combo[cl - 1])  # gercekte > bindirmede
                        pairs[key] = pairs.get(key, 0) + 1
                    row["swaps"] = pairs
                worst_swap = max(worst_swap, spct)
                worst_comp = max(worst_comp, pct)
                if wrong.any():
                    pal = np.array([(0, 0, 0)] + [tuple(int(255 * x) for x in c) for c in colors], np.uint8)
                    Image.fromarray(pal[comp + 1]).save(os.path.join(out_dir, tag + "_composite.png"))
                    vis = np.zeros(truth.shape + (3,), np.uint8)
                    vis[truth >= 0] = 60
                    vis[wrong] = (255, 0, 0)
                    Image.fromarray(vis).save(os.path.join(out_dir, tag + "_wrong.png"))
                rows.append(row)
                print(json.dumps(row), flush=True)
    json.dump(rows, open(os.path.join(out_dir, "table.json"), "w"), indent=1)
    json.dump(ratios, open(os.path.join(out_dir, "proportions.json"), "w"), indent=1)
    ok = not misshapen and worst_comp <= MAX_COMPOSITE_PCT and worst_swap <= MAX_SWAP_PCT and worst_bleed <= MAX_BLEED_PCT
    print("SONUC %s: oran bozuk %s, bindirme %.2f%% (esik %.2f), giysi karismasi %.2f%% (esik %.2f), "
          "alttaki ustte %.2f%% (esik %.2f); 3B tasma %.2f%% (bilgi)" % (
              "GECTI" if ok else "KALDI", misshapen or "yok", worst_comp, MAX_COMPOSITE_PCT, worst_swap, MAX_SWAP_PCT,
              worst_bleed, MAX_BLEED_PCT, worst_poke), flush=True)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
