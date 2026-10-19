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

# Oda: x -8.3..8.3 (genişlik), y 0..9.5 (derinlik), z 0..4.6 (yükseklik).
# Kamera yakın (9.4 ikinci tur, kullanıcı: "referans ekran gibi"): masadaki kişi
# odanın yüksekliğinin dörtte biri; geniş açı odanın iki duvarını da tutar.
CAMERA = {"at": [0.0, -2.4, 1.75], "look": [0.0, 9.0, 1.5], "lens": 24}

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


_lantern_mat = None


def lantern_material():
    """Kenney fenerinin yeşil boyası stile aykırı (kullanıcı notu): renk
    atlasının parlaklığı okunur, koyu kısım dövme demir, açık kısım (cam) sıcak
    ve hafif ışıyan kehribar olur."""
    global _lantern_mat
    if _lantern_mat is not None:
        return _lantern_mat
    m = bpy.data.materials.new("lantern_iron")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(GY, "Textures", "colormap.png"))
    tex.interpolation = "Closest"
    bw = nt.nodes.new("ShaderNodeRGBToBW")
    nt.links.new(tex.outputs["Color"], bw.inputs["Color"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.42
    ramp.color_ramp.elements[0].color = (0.055, 0.048, 0.042, 1.0)
    ramp.color_ramp.elements[1].position = 0.55
    ramp.color_ramp.elements[1].color = (1.0, 0.60, 0.24, 1.0)
    nt.links.new(bw.outputs["Val"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Emission Color"])
    glow = nt.nodes.new("ShaderNodeMath")
    glow.operation = "GREATER_THAN"
    glow.inputs[1].default_value = 0.5
    nt.links.new(bw.outputs["Val"], glow.inputs[0])
    strength = nt.nodes.new("ShaderNodeMath")
    strength.operation = "MULTIPLY"
    strength.inputs[1].default_value = 1.1
    nt.links.new(glow.outputs["Value"], strength.inputs[0])
    nt.links.new(strength.outputs["Value"], bsdf.inputs["Emission Strength"])
    bsdf.inputs["Metallic"].default_value = 0.6
    bsdf.inputs["Roughness"].default_value = 0.55
    _lantern_mat = m
    return m


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
    """Küçük, dolu bir taverna (9.4 ikinci tur): ilk oda 28 m genişliğinde bir
    salondu ve insanlar içinde kayboluyordu. Şimdi 16 m x 9.5 m, tavan 4.6 m;
    solda tezgâh ve fıçılar, ortada şömine, önde iki masa, sağ arkada küçük masa."""
    ts.reset()
    dark = wood("dark", 0.32, (0.9, 0.7, 0.55))
    # Zemin, duvarlar, tavan
    box(0, 4.0, -0.1, 18, 16, 0.1, wood("floor", 0.6))
    box(0, 9.85, 0.0, 17.4, 0.7, 4.9, stone(0.34))
    box(-8.65, 4.0, 0.0, 0.7, 12, 4.9, stone(0.3))
    box(8.65, 4.0, 0.0, 0.7, 12, 4.9, stone(0.3))
    box(0, 4.0, 4.6, 18, 12, 0.3, dark)
    # Tavan kirişleri ve dikmeler
    for x in (-6.0, -3.0, 0.0, 3.0, 6.0):
        box(x, 4.0, 4.15, 0.32, 12, 0.42, dark)
    for y in (2.0, 5.5, 9.2):
        box(0, y, 4.05, 17, 0.3, 0.4, dark)
    for x in (-8.1, 8.1):
        for y in (2.0, 5.5, 9.2):
            box(x, y, 0.0, 0.3, 0.3, 4.6, dark)
    # Şömine: iki taş ayak, ocak, saçak, baca
    box(-1.55, 9.2, 0.0, 0.8, 1.0, 2.3, stone(0.45))
    box(1.55, 9.2, 0.0, 0.8, 1.0, 2.3, stone(0.45))
    box(0.0, 9.25, 0.0, 2.4, 0.8, 0.22, stone(0.35))          # ocak tabanı
    box(0.0, 9.45, 0.25, 2.4, 0.4, 2.05, dark)                 # ocağın içi: kapkara
    box(0.0, 9.15, 2.3, 4.0, 1.1, 0.35, stone(0.5))            # saçak
    box(0.0, 9.35, 2.65, 2.8, 0.8, 2.0, stone(0.42))           # baca
    # Tezgâh (sol), arkasında raflar ve fıçılar
    box(-6.0, 5.8, 0.0, 3.6, 0.8, 1.1, wood("counter", 0.5))
    box(-6.0, 5.8, 1.1, 3.8, 1.0, 0.12, wood("counter_top", 0.66))
    for z in (1.6, 2.3, 3.0):
        box(-5.4, 9.45, z, 3.8, 0.4, 0.08, dark)
        for k in range(8):
            cyl(-7.0 + k * 0.45, 9.45, z + 0.08, 0.09, 0.3, wood("bottle", 0.28, (0.5, 0.8, 0.5)), 8)
    for k, (bx2, by2) in enumerate(((-7.9, 7.4), (-7.9, 8.4), (-6.9, 8.9))):
        ts.place(ts.qv("Barrel"), (bx2, by2, 0.0), k * 40.0, 1.3)
    ts.place(ts.qv("Barrel"), (-7.6, 7.9, 1.25), 90.0, 1.0)
    # Masalar: önde iki uzun masa, sağ arkada küçük masa
    table(-1.9, 3.8, 2.4, 1.0)
    bench(-1.9, 3.05, 2.3)
    bench(-1.9, 4.55, 2.3)
    table(3.0, 3.4, 2.4, 1.0)
    bench(3.0, 2.65, 2.3)
    bench(3.0, 4.15, 2.3)
    table(5.6, 6.8, 1.8, 0.9)
    stool(5.1, 7.45)
    stool(6.1, 7.45)
    stool(-6.6, 5.0)
    stool(-5.2, 5.0)
    ts.place(ts.qv("Crate"), (7.5, 8.7, 0.0), 12.0, 1.2)
    ts.place(ts.qv("Barrel"), (7.6, 4.6, 0.0), 0.0, 1.2)
    ts.place(ts.qv("Barrel"), (7.0, 9.0, 0.0), 30.0, 1.2)
    # Asılı fenerler, duvar mumları
    for x in (-3.5, 3.5):
        box(x, 4.5, 3.6, 0.04, 0.04, 1.0, dark)
        ts.place(os.path.join(GY, "lantern-glass.glb"), (x, 4.5, 3.3), 0.0, 1.8, mats=lantern_material())
    for x, y in ((-8.2, 3.0), (8.2, 7.0), (-3.4, 9.4), (3.4, 9.4)):
        ts.place(os.path.join(GY, "lantern-candle.glb"), (x, y, 2.2), 0.0, 1.6, mats=lantern_material())


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

    lamp(0.0, 8.7, 0.7, 650, (1.0, 0.5, 0.2), 0.8)      # şömine ateşi
    lamp(-3.5, 4.5, 3.1, 320)
    lamp(3.5, 4.5, 3.1, 320)
    lamp(-1.9, 3.8, 1.5, 70)
    lamp(3.0, 3.4, 1.5, 70)
    lamp(5.6, 6.8, 1.4, 55)
    lamp(-6.0, 6.4, 2.4, 160)                            # tezgâh
    lamp(-3.4, 9.0, 2.3, 60)
    lamp(3.4, 9.0, 2.3, 60)
    lamp(0.0, 0.0, 3.4, 260, (1.0, 0.8, 0.6), 1.5)      # dolgu: yüzler görünsün


def anchors():
    sc = bpy.context.scene
    cam = sc.camera
    names = {
        # İnsanlar: ayak noktası. Oturanlar masanın arka tarafındaki bankta,
        # masa alt yarılarını örter (oyun figürü masa üstünde keser).
        "bartender": (-6.3, 6.7, 0.0), "bar_pour": (-4.8, 6.7, 0.0),
        "waitress_left": (-3.5, 6.6, 0.0), "waitress_right": (4.5, 6.0, 0.0),
        "pickup": (-3.6, 6.1, 0.0), "serve_a": (-1.9, 5.3, 0.0), "serve_b": (3.0, 4.95, 0.0),
        "bard": (-2.3, 8.1, 0.0), "bard_right": (2.3, 8.1, 0.0),
        "seat_a1": (-2.5, 4.55, 0.0), "seat_a2": (-1.3, 4.55, 0.0),
        "seat_b1": (2.4, 4.15, 0.0), "seat_b2": (3.6, 4.15, 0.0),
        "seat_c1": (5.1, 7.45, 0.0), "seat_c2": (6.1, 7.45, 0.0),
        "aisle_a1": (-2.5, 5.6, 0.0), "aisle_a2": (-1.3, 5.6, 0.0),
        "aisle_b1": (2.4, 5.3, 0.0), "aisle_b2": (3.6, 5.3, 0.0), "door": (9.4, 5.6, 0.0),
        # Kesim noktaları: masanın ve tezgâhın arka kenarının üstü
        "table_a": (-1.9, 4.3, 1.09), "table_b": (3.0, 3.9, 1.09), "table_c": (5.6, 7.25, 1.09),
        "counter_top": (-6.0, 6.3, 1.22),
        # Işıklar ve ateş
        "fire": (0.0, 9.1, 0.45), "lantern_l": (-3.5, 4.5, 3.3), "lantern_r": (3.5, 4.5, 3.3),
        "candle_a": (-1.9, 3.8, 1.2), "candle_b": (3.0, 3.4, 1.2), "candle_c": (5.6, 6.8, 1.2),
    }
    out = {}
    for key, (x, y, z) in names.items():
        p = world_to_camera_view(sc, cam, Vector((x, y, z)))
        head = world_to_camera_view(sc, cam, Vector((x, y, z + 1.75)))
        out[key] = {"x": round(p.x, 4), "y": round(1.0 - p.y, 4), "person_h": round(abs(head.y - p.y), 4)}
    return out


def depth_fit():
    """Zemindeki bir kişinin boyu, ayağının ekran yüksekliğine göre doğrusal
    (düz zemin, iğne delikli kamera): oyun yürüyen figürü bu doğruyla büyütür."""
    sc = bpy.context.scene
    cam = sc.camera
    ys, hs = [], []
    for wy in [2.0 + 0.4 * i for i in range(19)]:
        p = world_to_camera_view(sc, cam, Vector((0.0, wy, 0.0)))
        head = world_to_camera_view(sc, cam, Vector((0.0, wy, 1.75)))
        ys.append(1.0 - p.y)
        hs.append(abs(head.y - p.y))
    n = len(ys)
    my, mh = sum(ys) / n, sum(hs) / n
    slope = sum((y - my) * (h - mh) for y, h in zip(ys, hs)) / sum((y - my) ** 2 for y in ys)
    return {"y0": round(my, 4), "h0": round(mh, 4), "slope": round(slope, 4)}


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
    fit = depth_fit()
    lines += ["}", "",
              "## Zemindeki kişinin boyu: h0 + (ayak_y - y0) * slope (ekran payı).",
              "const DEPTH: Dictionary = {\"y0\": %s, \"h0\": %s, \"slope\": %s}" % (fit["y0"], fit["h0"], fit["slope"]), ""]
    with open(os.path.join(ts.ROOT, "scripts/ui/tavern_layout.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    ts.render_beauty(os.path.join(OUT, "beauty.png"), samples, pct)
    ts.render_ids(os.path.join(OUT, "ids.png"), pct)
    ts.render_depth(os.path.join(OUT, "depth.png"), pct, 40.0)
    print("BITTI", OUT)


if __name__ == "__main__":
    main(sys.argv)
