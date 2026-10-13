"""Esya (prop) render hatti: statik modeller ve kurulu vagonlar, figurlerle ayni
isik ve ayni dort ton.

    python3 -I tools/figure_pipeline/props/render_props.py [--only id,id] [--force]

Girdi : tools/figure_pipeline/props/props.json
Cikti : build/props/<id>/<katman>__shade.png, __albedo.png, meta.json

Katman: oyunda ayri cizilen ya da ayri hareket eden parca (vagonun tekerlegi
doner, brandasi salinir, degirmenin kanadi doner). Her katman kendi render'i;
diger katmanlar kameraya gorunmez ama golge dusurur, yani bir parcanin
golgesi ayri cizildiginde de dogru yerde kalir (kiyafet hattinin kurali).
Hepsi ayni kare cercevesini paylasir; pack_props.py her katmani kendi
sinirina kirpip yeri cipa noktasina gore kaydeder.

Olcek gercek boy: her model `size` ile metreye oturtulur ve tek bir ppm ile
cekilir, yani bir han ile bir ev ayni olcude durur. Pivot noktalari (tekerlek
gobegi, kanat mili) dunya koordinatindan piksel konumuna izdusurulur.
"""
import json
import math
import os
import re
import sys

import bpy
from mathutils import Matrix, Vector

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
for sub in ("blender", "beasts", "props"):
    sys.path.insert(0, os.path.join(PIPE, sub))
import fig_shading  # noqa: E402
import render_outfits  # noqa: E402
import wagon_builder  # noqa: E402

CAM = json.load(open(os.path.join(PIPE, "config", "camera.json")))
SPEC = os.path.join(PIPE, "props", "props.json")
OUT = os.path.join(ROOT, "build", "props")
VIEWS = {"side": (90.0, 0.0, -90.0), "iso": (60.0, 0.0, -45.0)}
PAD = 12


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_file(path, only=None, drop=None):
    before = set(bpy.data.objects)
    ext = os.path.splitext(path)[1].lower()
    if ext == ".blend":
        with bpy.data.libraries.load(path, link=False) as (src, dst):
            dst.objects = list(src.objects)
        for o in dst.objects:
            if o is not None:
                bpy.context.scene.collection.objects.link(o)
    elif ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=path)
    elif ext == ".obj":
        bpy.ops.wm.obj_import(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    rx_only = re.compile(only) if only else None
    rx_drop = re.compile(drop) if drop else None
    keep = []
    for o in new:
        bad = o.type in ("CAMERA", "LIGHT")
        if o.type == "MESH" and ((rx_only and not rx_only.search(o.name)) or (rx_drop and rx_drop.search(o.name))):
            bad = True
        if bad:
            bpy.data.objects.remove(o, do_unlink=True)
        elif o.type == "MESH" and not o.hide_render:
            keep.append(o)
    bpy.context.view_layer.update()
    return keep


def world_bbox(meshes):
    dg = bpy.context.evaluated_depsgraph_get()
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in meshes:
        ev = o.evaluated_get(dg)
        for c in ev.bound_box:
            w = ev.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


def normalize(meshes, yaw, size, measure, scale=None):
    """Yaw ile dondur, `size` metreye olcekle, tabani z=0'a, ortayi orijine."""
    root = bpy.data.objects.new("prop_root", None)
    bpy.context.scene.collection.objects.link(root)
    bpy.context.view_layer.update()
    tops = {o for o in bpy.data.objects if o.parent is None and o is not root and o.type in ("MESH", "EMPTY")}
    for o in tops:
        mw = o.matrix_world.copy()
        o.parent = root
        o.matrix_world = mw
    root.rotation_euler = (0.0, 0.0, math.radians(yaw))
    bpy.context.view_layer.update()
    lo, hi = world_bbox(meshes)
    ext = {"z": hi.z - lo.z, "x": hi.x - lo.x, "y": hi.y - lo.y,
           "long": max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)}[measure]
    s = scale if scale else (size / max(ext, 1e-6) if size else 1.0)
    root.scale = (s, s, s)
    bpy.context.view_layer.update()
    lo, hi = world_bbox(meshes)
    root.location = (-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z)
    bpy.context.view_layer.update()
    return root, s


def camera(view, lo, hi, ppm):
    sc = bpy.context.scene
    cd = bpy.data.cameras.new("prop_cam")
    cd.type = "ORTHO"
    cam = bpy.data.objects.new("prop_cam", cd)
    sc.collection.objects.link(cam)
    cam.rotation_euler = tuple(math.radians(a) for a in VIEWS[view])
    bpy.context.view_layer.update()
    m = cam.matrix_world.to_3x3()
    right, up, fwd = m.col[0], m.col[1], -m.col[2]
    corners = [Vector((x, y, z)) for x in (lo.x, hi.x) for y in (lo.y, hi.y) for z in (lo.z, hi.z)]
    us = [c.dot(right) for c in corners]
    vs = [c.dot(up) for c in corners]
    W = int(math.ceil((max(us) - min(us)) * ppm)) + 2 * PAD
    H = int(math.ceil((max(vs) - min(vs)) * ppm)) + 2 * PAD
    cd.ortho_scale = max(W, H) / ppm
    cu, cv = (max(us) + min(us)) / 2, (max(vs) + min(vs)) / 2
    cam.location = right * cu + up * cv - fwd * 60.0
    cd.clip_end = 300.0
    sc.render.resolution_x, sc.render.resolution_y = W, H
    sc.camera = cam

    def project(p):
        p = Vector(p)
        return [W / 2 + (p.dot(right) - cu) * ppm, H / 2 - (p.dot(up) - cv) * ppm]
    return W, H, project


def tint_for(spec, obj, slot_mat):
    for rule in spec.get("tints", []):
        name = slot_mat.name if slot_mat else ""
        if re.search(rule["match"], obj.name + "|" + name):
            return rule["color"]
    return None


def set_materials(meshes, mode, originals, spec):
    cache = {}
    for o in meshes:
        if not o.material_slots:
            o.data.materials.append(None)
        for i, sl in enumerate(o.material_slots):
            src = originals.get((o.name, i))
            if mode == "shade":
                key = ("shade",)
            else:
                tint = tint_for(spec, o, src)
                key = ("alb", src.name if src else None, tuple(tint) if tint else None)
            if key not in cache:
                if mode == "shade":
                    cache[key] = fig_shading.body_material(CAM, "full", name_suffix="_prop")
                elif key[2] is not None:
                    lin = [((v / 12.92) if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4) for v in key[2]]
                    cache[key] = render_outfits.tint_material(CAM, "", src, lin, 0.5, 0.02)
                elif src is not None and not src.use_nodes:
                    # dugumsuz eski malzeme (modular paket): rengi diffuse_color'da, lineer
                    cache[key] = render_outfits.tint_material(CAM, "", None, list(src.diffuse_color[:3]), 0.5, 0.02)
                else:
                    cache[key] = render_outfits.albedo_material(CAM, "", src, 0.5, 0.02)
            sl.link = "OBJECT"
            sl.material = cache[key]


def build(spec):
    """Sahneyi kurar; (katman -> nesneler, pivotlar(dunya), golge-yalniz nesneler)."""
    reset()
    if "builder" in spec:
        layers, pivots = wagon_builder.BUILDERS[spec["builder"]]()
        shadow_only = layers.pop("_shadow_only", [])
        return layers, {k: Vector(v) for k, v in pivots.items()}, shadow_only
    layers = {}
    parts = spec.get("parts") or [{"file": spec["file"], "only": spec.get("only"), "drop": spec.get("drop"),
                                   "layer": "body"}]
    for part in parts:
        objs = import_file(os.path.join(ROOT, part["file"]), part.get("only"), part.get("drop"))
        off = part.get("offset")
        if off or part.get("part_yaw") or part.get("part_scale"):
            # parca (or. kapi kanadi) diger parcalarin cercevesine elle yerlestirilir
            mat = (Matrix.Translation(Vector(off or (0, 0, 0)))
                   @ Matrix.Rotation(math.radians(part.get("part_yaw", 0.0)), 4, "Z")
                   @ Matrix.Scale(part.get("part_scale", 1.0), 4))
            for o in objs:
                if o.parent is None or o.parent not in objs:
                    o.matrix_world = mat @ o.matrix_world
            bpy.context.view_layer.update()
        if part.get("split"):
            rx = re.compile(part["split"])
            for o in objs:
                layers.setdefault(part["split_layer"] if rx.search(o.name) else part.get("layer", "body"), []).append(o)
        else:
            layers.setdefault(part.get("layer", "body"), []).extend(objs)
    return layers, {}, []


SAMPLES_OVERRIDE = None
OUT_OVERRIDE = None


def render_prop(spec, force=False):
    outd = os.path.join(OUT_OVERRIDE or OUT, spec["id"])
    if not force and os.path.exists(os.path.join(outd, "meta.json")):
        print("var", spec["id"])
        return
    os.makedirs(outd, exist_ok=True)
    layers, pivots, shadow_only = build(spec)
    meshes = [o for objs in layers.values() for o in objs] + shadow_only
    if "builder" not in spec:
        root, s = normalize(meshes, float(spec.get("yaw", 0.0)), spec.get("size"), spec.get("measure", "z"),
                            spec.get("scale"))
    else:
        root, s = None, 1.0
    named = {}
    for name, p in spec.get("pivots", {}).items():
        # model pivotu: o nesnenin sinir kutusunun ortasi (or. kanat mili)
        objs = [o for o in meshes if re.search(p, o.name)]
        if objs:
            lo, hi = world_bbox(objs)
            named[name] = (lo + hi) / 2
    pivots.update(named)
    lo, hi = world_bbox(meshes)
    cfg = dict(CAM)
    cfg["samples"] = SAMPLES_OVERRIDE or int(spec.get("samples", 256))
    fig_shading.setup_render(cfg)
    ppm = float(spec.get("ppm", 120))
    W, H, project = camera(spec.get("view", "side"), lo, hi, ppm)
    originals = {(o.name, i): sl.material for o in meshes for i, sl in enumerate(o.material_slots)}
    for lname, objs in layers.items():
        for mode in ("shade", "albedo"):
            for o in meshes:
                o.hide_render = False
                o.visible_camera = o in objs
                # isiksiz albedo icin golge anlamsiz; obur katmanlar tamamen gizli
                if mode == "albedo" and o not in objs:
                    o.hide_render = True
            set_materials(meshes, mode, originals, spec)
            bpy.context.scene.render.filepath = os.path.join(outd, "%s__%s.png" % (lname, mode))
            bpy.ops.render.render(write_still=True)
    meta = {
        "id": spec["id"], "view": spec.get("view", "side"), "ppm": ppm, "canvas": [W, H],
        "anchor": project((0.0, 0.0, 0.0)),
        "pivots": {k: project(v) for k, v in pivots.items()},
        "size_m": [hi.x - lo.x, hi.y - lo.y, hi.z - lo.z],
        "layers": list(layers.keys()),
    }
    json.dump(meta, open(os.path.join(outd, "meta.json"), "w"), indent=1)
    print("OK", spec["id"], [round(v, 2) for v in meta["size_m"]], flush=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    only = None
    if "--only" in argv:
        only = set(argv[argv.index("--only") + 1].split(","))
    force = "--force" in argv
    global SAMPLES_OVERRIDE, OUT_OVERRIDE
    if "--samples" in argv:  # hizli deneme: dusuk ornek, ayri klasor
        SAMPLES_OVERRIDE = int(argv[argv.index("--samples") + 1])
    if "--out" in argv:
        OUT_OVERRIDE = argv[argv.index("--out") + 1]
    for spec in json.load(open(SPEC))["props"]:
        if only and spec["id"] not in only:
            continue
        try:
            render_prop(spec, force)
        except Exception as e:  # bir varlik digerlerini durdurmasin
            import traceback
            traceback.print_exc()
            print("HATA", spec["id"], repr(e), flush=True)


if __name__ == "__main__":
    main()
