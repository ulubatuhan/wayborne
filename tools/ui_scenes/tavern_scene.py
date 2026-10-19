"""Taverna iç mekânı (görev 9.4, kullanıcı isteği 2026-10-19: hareketli taverna).

Odanın arka planı bir kez render edilir; içindeki insanlar, alev, mum ve
fenerin titremesi oyunda canlı çizilir. Bu betik iki şey yazar:
  build/ui_scenes/town_tavern/beauty.png  - boş oda (insansız), mürekkep çizgili
  build/ui_scenes/town_tavern/anchors.json - oyunun figürleri ve ışıkları koyacağı
      yerler: ekran payı (0-1) ve o noktadaki boy (ekran yüksekliği payı)

    WAYBORNE_ROOT=<depo> blender -b --python tools/ui_scenes/tavern_scene.py -- [--samples 48] [--scale 100]

Model kaynakları CC0: Quaternius (fıçı, sandık), Kenney Graveyard Kit (fener,
mum); gerisi kutu ve silindirle kurulan masa, tezgâh, şömine (ambientCG
taş ve tahta dokuları). Odada dinî sembol yok.
"""
import json
import math
import os
import sys

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_scene as ts  # noqa: E402

OUT = os.path.join(ts.ROOT, "build/ui_scenes/town_tavern")
GY = os.path.join(ts.ROOT, "art_source/models/props/kenney_graveyard")
PLANKS = os.path.join(ts.TEX, "Planks037A/Planks037A_1K-JPG_Color.jpg")

# Oda: x -14..14 (genişlik), y 0..14.5 (derinlik), z 0..6.4 (yükseklik).
CAMERA = {"at": [0.0, -7.0, 2.0], "look": [0.0, 10.0, 1.9], "lens": 28}

_wood = {}


def wood(name="wood", value=0.55, tint=(1.0, 0.82, 0.62)):
    key = (name, value)
    if key in _wood:
        return _wood[key]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.5, 0.5, 0.5)
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    t = ts._tex_node(nt, PLANKS, mp)
    mul = nt.nodes.new("ShaderNodeMix")
    mul.data_type = "RGBA"
    mul.blend_type = "MULTIPLY"
    mul.inputs["Factor"].default_value = 1.0
    nt.links.new(t.outputs["Color"], mul.inputs["A"])
    mul.inputs["B"].default_value = [c * value for c in tint] + [1.0]
    nt.links.new(mul.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    _wood[key] = m
    return m


def box(x, y, z0, w, d, h, mat):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, y, z0 + h / 2.0))
    o = bpy.context.object
    o.scale = (w, d, h)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat)
    return o


def cyl(x, y, z0, r, h, mat, verts=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=(x, y, z0 + h / 2.0))
    o = bpy.context.object
    o.data.materials.append(mat)
    return o


def stone(value=0.4):
    return ts._stone_material("tavern_stone_%d" % int(value * 100), value)


def table(x, y, w=3.0, d=1.3):
    top = wood("table", 0.62)
    box(x, y, 0.95, w, d, 0.14, top)
    for dx in (-w / 2 + 0.2, w / 2 - 0.2):
        for dy in (-d / 2 + 0.2, d / 2 - 0.2):
            box(x + dx, y + dy, 0.0, 0.16, 0.16, 0.95, wood("leg", 0.45))
    # Tezgâh üstü: mum
    ts.place(os.path.join(GY, "candle.glb"), (x, y, 1.09), 0.0, 1.5)


def stool(x, y):
    cyl(x, y, 0.0, 0.3, 0.62, wood("stool", 0.5), 10)
    cyl(x, y, 0.62, 0.36, 0.08, wood("stool_top", 0.58), 10)


def bench(x, y, w=2.8):
    box(x, y, 0.5, w, 0.45, 0.1, wood("bench", 0.55))
    box(x - w / 2 + 0.2, y, 0.0, 0.14, 0.4, 0.5, wood("bleg", 0.45))
    box(x + w / 2 - 0.2, y, 0.0, 0.14, 0.4, 0.5, wood("bleg", 0.45))


def build():
    ts.reset()
    dark = wood("dark", 0.32, (0.9, 0.7, 0.55))
    # Zemin ve duvarlar
    box(0, 2.0, -0.1, 30, 30, 0.1, wood("floor", 0.6))
    box(0, 14.7, 0.0, 30, 0.7, 6.6, stone(0.34))
    box(-14.4, 7.0, 0.0, 0.7, 16, 6.6, stone(0.3))
    box(14.4, 7.0, 0.0, 0.7, 16, 6.6, stone(0.3))
    box(0, 7.0, 6.4, 30, 16, 0.3, dark)
    # Tavan kirişleri
    for x in range(-12, 13, 4):
        box(x, 7.0, 5.7, 0.4, 16, 0.5, dark)
    for y in (4.0, 9.0, 13.6):
        box(0, y, 5.6, 29, 0.35, 0.45, dark)
    # Şömine: iki taş ayak, ocak, saçak, baca
    fx = 0.0
    box(fx - 2.1, 13.9, 0.0, 1.0, 1.4, 3.3, stone(0.45))
    box(fx + 2.1, 13.9, 0.0, 1.0, 1.4, 3.3, stone(0.45))
    box(fx, 14.0, 0.0, 3.2, 1.0, 0.25, stone(0.35))          # ocak tabanı
    box(fx, 14.15, 0.3, 3.2, 0.6, 3.0, dark)                  # ocağın içi: kapkara
    box(fx, 13.9, 3.3, 5.6, 1.5, 0.45, stone(0.5))           # saçak
    box(fx, 14.1, 3.75, 3.8, 1.1, 2.7, stone(0.42))          # baca
    # Tezgâh ve arkasındaki raflar (sol)
    bx = -9.0
    box(bx, 8.0, 0.0, 6.4, 1.5, 1.1, wood("counter", 0.5))
    box(bx, 8.0, 1.1, 6.6, 1.7, 0.14, wood("counter_top", 0.66))
    for z in (1.9, 2.8, 3.7):
        box(bx - 0.4, 14.2, z, 5.4, 0.5, 0.1, dark)
        for k in range(7):
            cyl(bx - 2.6 + k * 0.8, 14.2, z + 0.1, 0.12, 0.38, wood("bottle", 0.28, (0.5, 0.8, 0.5)), 8)
    box(bx - 5.4, 13.4, 0.0, 0.1, 0.1, 0.1, dark)
    for k, (bx2, by2) in enumerate(((-12.4, 12.8), (-11.0, 13.4), (-12.4, 11.4))):
        ts.place(ts.qv("Barrel"), (bx2, by2, 0.0), k * 40.0, 1.6)
    ts.place(ts.qv("Barrel"), (bx - 3.6, 7.4, 0.0), 0.0, 1.3)
    # Masalar ve oturaklar
    table(-2.6, 5.0)
    bench(-2.6, 3.9)
    bench(-2.6, 6.1)
    table(4.2, 4.4)
    bench(4.2, 3.3)
    bench(4.2, 5.5)
    table(8.6, 9.4, 2.6, 1.2)
    stool(7.4, 8.3)
    stool(9.8, 8.3)
    stool(bx + 3.5, 6.2)
    stool(bx + 1.5, 6.2)
    ts.place(ts.qv("Crate"), (12.0, 12.6, 0.0), 12.0, 1.5)
    ts.place(ts.qv("Barrel"), (12.5, 8.2, 0.0), 0.0, 1.4)
    # Hasır ve fenerler
    for x in (-5.4, 5.4):
        box(x, 7.0, 4.4, 0.04, 0.04, 1.2, dark)
        ts.place(os.path.join(GY, "lantern-glass.glb"), (x, 7.0, 4.2), 0.0, 2.2)
    for x, y in ((-12.8, 12.0), (12.8, 11.0)):
        ts.place(os.path.join(GY, "lantern-candle.glb"), (x, y, 2.6), 0.0, 2.0)


def lights():
    sc = bpy.context.scene
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.02, 0.018, 0.02, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.2
    sc.world = world

    def lamp(x, y, z, energy, color=(1.0, 0.6, 0.28), size=0.35):
        L = bpy.data.lights.new("lamp", "POINT")
        L.energy = energy
        L.color = color
        L.shadow_soft_size = size
        o = bpy.data.objects.new("lamp", L)
        o.location = (x, y, z)
        sc.collection.objects.link(o)

    lamp(0.0, 13.0, 0.9, 1100, (1.0, 0.5, 0.2), 0.9)     # şömine ateşi
    lamp(-5.4, 7.0, 4.0, 700)
    lamp(5.4, 7.0, 4.0, 700)
    lamp(-2.6, 5.0, 1.6, 120)
    lamp(4.2, 4.4, 1.6, 120)
    lamp(8.6, 9.4, 1.6, 90)
    lamp(0.0, 3.0, 4.5, 520, (1.0, 0.8, 0.6), 1.5)
    lamp(-9.0, 6.0, 2.6, 300)     # dolgu: yüzler görünsün


def anchors():
    sc = bpy.context.scene
    cam = sc.camera
    names = {
        # İnsanlar: ayak noktası
        "bartender": (-9.0, 9.1, 0.0), "waitress_left": (-4.5, 10.2, 0.0), "waitress_right": (7.5, 11.2, 0.0),
        "bard": (0.6, 12.0, 0.0),
        "seat_a1": (-3.7, 5.0, 0.0), "seat_a2": (-1.5, 5.0, 0.0),
        "seat_b1": (3.1, 4.4, 0.0), "seat_b2": (5.3, 4.4, 0.0),
        "seat_c1": (7.7, 9.4, 0.0), "seat_c2": (9.5, 9.4, 0.0),
        "table_a": (-2.6, 5.0, 1.1), "table_b": (4.2, 4.4, 1.1), "table_c": (8.6, 9.4, 1.1),
        "counter_top": (-9.0, 8.0, 1.25),
        # Işıklar ve ateş
        "fire": (0.0, 13.6, 0.7), "lantern_l": (-5.4, 7.0, 4.2), "lantern_r": (5.4, 7.0, 4.2),
        "candle_a": (-2.6, 5.0, 1.2), "candle_b": (4.2, 4.4, 1.2), "candle_c": (8.6, 9.4, 1.2),
    }
    out = {}
    for key, (x, y, z) in names.items():
        p = world_to_camera_view(sc, cam, Vector((x, y, z)))
        head = world_to_camera_view(sc, cam, Vector((x, y, z + 1.75)))
        out[key] = {"x": round(p.x, 4), "y": round(1.0 - p.y, 4), "person_h": round(abs(head.y - p.y), 4)}
    return out


def main(argv):
    samples = int(argv[argv.index("--samples") + 1]) if "--samples" in argv else 48
    pct = int(argv[argv.index("--scale") + 1]) if "--scale" in argv else 100
    os.makedirs(OUT, exist_ok=True)
    build()
    ts.camera({"camera": CAMERA})
    lights()
    bpy.context.view_layer.update()
    found = anchors()
    json.dump(found, open(os.path.join(OUT, "anchors.json"), "w"), indent=1)
    # Oyun kodu olarak da yazılır: Web dışa aktarımı .json taşımıyor (CLAUDE.md).
    lines = ["class_name TavernLayout", "extends RefCounted", "",
             "## tools/ui_scenes/tavern_scene.py yazar, elle değiştirme. Ekran payı (0-1) ve boy payı.", "",
             "const ANCHORS: Dictionary = {"]
    for key, v in found.items():
        lines.append('	"%s": {"x": %s, "y": %s, "person_h": %s},' % (key, v["x"], v["y"], v["person_h"]))
    lines += ["}", ""]
    with open(os.path.join(ts.ROOT, "scripts/ui/tavern_layout.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    ts.render_beauty(os.path.join(OUT, "beauty.png"), samples, pct)
    ts.render_ids(os.path.join(OUT, "ids.png"), pct)
    ts.render_depth(os.path.join(OUT, "depth.png"), pct, 40.0)
    print("BITTI", OUT)


if __name__ == "__main__":
    main(sys.argv)
