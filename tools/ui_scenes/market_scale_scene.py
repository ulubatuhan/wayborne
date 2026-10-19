"""Pazarın terazisi (görev Y-G11T, kullanıcı kararı 2026-10-19: "terazi tamamen
referans görseldeki gibi"): işlemeli, eskimiş pirinç bir kefeli terazi.

Oyun teraziyi oynatır (kol eğilir, kefeler dik asılı kalır, mal kefede
birikir), o yüzden her parça ayrı ve saydam render edilir, önden ortografik
kamerayla (2B'de birleşsinler diye):
  column.png - taban, sütun, tepe süsü (sabit)
  beam.png   - kol, ortadaki mil ve ibre (milin çevresinde döner)
  pan.png    - kefe, üç zincir ve askı halkası (kolun ucuna asılır)
  coin.png   - tek sikke, hafif yukarıdan (altın kefesine dizilir)
ve scripts/ui/market_scale_art.gd'ye pikselde ölçülmüş bağlantı noktaları.

    blender -b --python tools/ui_scenes/market_scale_scene.py -- [--samples 64]

Model elle kurulur (silindir, torus, döndürülmüş profil); dış kaynak yok.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

ROOT = os.environ.get("WAYBORNE_ROOT") or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "assets", "ui", "market_scale")
GD = os.path.join(ROOT, "scripts", "ui", "market_scale_art.gd")
PPU = 400  # birim başına piksel (render çözünürlüğü bundan)

PIVOT_Z = 1.62       # kolun mili
BEAM_HALF = 0.92     # milden kefe askısına
CHAIN = 0.62         # askıdan kefe kenarına
PAN_R = 0.36         # kefe yarıçapı
PAN_DEPTH = 0.10


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "Medium High Contrast"


def metal(name, color, rough=0.38, patina=0.45):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = rough
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 18.0
    noise.inputs["Detail"].default_value = 8.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.35
    ramp.color_ramp.elements[0].color = [c * (1.0 - patina) for c in color] + [1.0]
    ramp.color_ramp.elements[1].position = 0.7
    ramp.color_ramp.elements[1].color = list(color) + [1.0]
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    return m


def lathe(name, profile, mat, z0=0.0, segments=64):
    """Profil (r, z) noktalarını z ekseni çevresinde döndürür."""
    verts, faces = [], []
    n = len(profile)
    for s in range(segments):
        a = 2.0 * math.pi * s / segments
        for r, z in profile:
            verts.append((r * math.cos(a), r * math.sin(a), z0 + z))
    for s in range(segments):
        for i in range(n - 1):
            a = s * n + i
            b = ((s + 1) % segments) * n + i
            faces.append((a, b, b + 1, a + 1))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    o.data.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = True
    return o


def torus(loc, major, minor, mat, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(location=loc, major_radius=major, minor_radius=minor,
                                     major_segments=32, minor_segments=12, rotation=rot)
    o = bpy.context.object
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return o


def cyl(loc, r, depth, mat, rot=(0, 0, 0), verts=32):
    bpy.ops.mesh.primitive_cylinder_add(location=loc, radius=r, depth=depth, vertices=verts, rotation=rot)
    o = bpy.context.object
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return o


def sphere(loc, r, mat, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(location=loc, radius=r, segments=32, ring_count=16)
    o = bpy.context.object
    o.scale = scale
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return o


def collect(name, objs):
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    for o in objs:
        for c in o.users_collection:
            c.objects.unlink(o)
        col.objects.link(o)
    return col


def build_column(brass, dark):
    objs = []
    # Taban: basamaklı, kenarı kabartmalı
    objs.append(lathe("base", [(0.0, 0.0), (0.52, 0.0), (0.54, 0.03), (0.50, 0.07), (0.40, 0.09),
                               (0.36, 0.14), (0.24, 0.17), (0.20, 0.24), (0.12, 0.30), (0.0, 0.31)], brass))
    objs.append(torus((0, 0, 0.065), 0.47, 0.022, dark))
    objs.append(torus((0, 0, 0.16), 0.27, 0.018, dark))
    # Sütun: ince gövde, üç düğüm
    objs.append(cyl((0, 0, 0.30 + (PIVOT_Z - 0.40) / 2.0), 0.045, PIVOT_Z - 0.40, brass))
    for z in (0.55, 0.95, 1.30):
        objs.append(lathe("knot", [(0.0, -0.05), (0.06, -0.05), (0.085, -0.02), (0.085, 0.02), (0.06, 0.05), (0.0, 0.05)], dark, z))
    # Milin yatağı: çatal
    objs.append(lathe("crown", [(0.0, 0.0), (0.09, 0.0), (0.13, 0.08), (0.10, 0.14), (0.0, 0.14)], brass, PIVOT_Z - 0.20))
    # Tepe süsü yok: milin üstünde kolun ibresi durur (iki sivri uç üst üste biniyordu).
    return collect("column", objs)


def build_beam(brass, dark):
    objs = []
    # Kol: ortada kalın, uçlara incelen; kare kesitli değil, yassı oval
    for side in (-1, 1):
        for k in range(10):
            u = (k + 0.5) / 10.0
            r = 0.042 - 0.018 * u
            o = cyl((side * BEAM_HALF * u, 0, PIVOT_Z), r, BEAM_HALF / 10.0 + 0.01, brass, rot=(0, math.pi / 2, 0))
            o.scale = (1.0, 0.7, 1.0)
            objs.append(o)
        # Uç süsü: kıvrık halka ve askı kancası
        objs.append(torus((side * (BEAM_HALF + 0.02), 0, PIVOT_Z + 0.03), 0.045, 0.013, dark, rot=(math.pi / 2, 0, 0)))
        objs.append(sphere((side * (BEAM_HALF - 0.12), 0, PIVOT_Z), 0.03, dark))
        objs.append(torus((side * BEAM_HALF, 0, PIVOT_Z - 0.04), 0.022, 0.008, dark, rot=(math.pi / 2, 0, 0)))
    # Mil göbeği ve ibre
    objs.append(cyl((0, 0, PIVOT_Z), 0.075, 0.12, dark, rot=(math.pi / 2, 0, 0)))
    objs.append(cyl((0, 0, PIVOT_Z), 0.04, 0.16, brass, rot=(math.pi / 2, 0, 0)))
    objs.append(lathe("needle", [(0.0, 0.0), (0.016, 0.0), (0.0, 0.30)], brass, PIVOT_Z + 0.04))
    return collect("beam", objs)


def chain(top, bottom, mat, links=16):
    """Halka halka zincir: her halkanın düzlemi zincir doğrultusunu içerir,
    bir sonraki 90 derece döner (gerçek zincir gibi)."""
    from mathutils import Quaternion
    objs = []
    d = (bottom - top).normalized()
    base = d.to_track_quat("Y", "Z")
    for i in range(links):
        u = (i + 0.5) / links
        o = torus(tuple(top.lerp(bottom, u)), 0.017, 0.005, mat)
        q = base @ Quaternion((0.0, 1.0, 0.0), math.pi / 2 if i % 2 else 0.0)
        o.rotation_mode = "QUATERNION"
        o.rotation_quaternion = q
        o.scale = (0.75, 1.45, 1.0)
        objs.append(o)
    return objs


def build_pan(brass, dark):
    """Askı halkası z=0'da; kefe CHAIN kadar aşağıda."""
    objs = []
    rim_z = -CHAIN
    objs.append(torus((0, 0, 0.0), 0.04, 0.012, dark, rot=(math.pi / 2, 0, 0)))
    for k in range(3):
        a = 2.0 * math.pi * k / 3.0 + math.pi / 2
        bottom = Vector((PAN_R * 0.95 * math.cos(a), PAN_R * 0.95 * math.sin(a), rim_z + 0.01))
        objs += chain(Vector((0, 0, -0.03)), bottom, dark)
    # Kefe: sığ çanak, dışında kabartma halka
    objs.append(lathe("pan", [(0.0, rim_z - PAN_DEPTH), (PAN_R * 0.55, rim_z - PAN_DEPTH), (PAN_R * 0.85, rim_z - PAN_DEPTH * 0.6),
                              (PAN_R, rim_z), (PAN_R * 1.03, rim_z + 0.012), (PAN_R * 0.97, rim_z + 0.012),
                              (PAN_R * 0.83, rim_z - PAN_DEPTH * 0.5), (0.0, rim_z - PAN_DEPTH * 0.8)], brass))
    objs.append(torus((0, 0, rim_z + 0.006), PAN_R * 1.0, 0.011, dark))
    objs.append(torus((0, 0, rim_z - PAN_DEPTH * 0.55), PAN_R * 0.78, 0.008, dark))
    return collect("pan", objs)


def build_coin(gold):
    objs = [cyl((0, 0, 0), 0.06, 0.012, gold, verts=48)]
    objs.append(torus((0, 0, 0.006), 0.052, 0.003, gold))
    return collect("coin", objs)


def lights():
    sc = bpy.context.scene
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.06, 0.05, 0.04, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    sc.world = world

    def area(loc, energy, color, size, look=(0, 0, 1.0)):
        L = bpy.data.lights.new("a", "AREA")
        L.energy = energy
        L.color = color
        L.size = size
        o = bpy.data.objects.new("a", L)
        o.location = loc
        d = Vector(look) - Vector(loc)
        o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.collection.objects.link(o)

    area((-2.5, -3.0, 3.2), 900, (1.0, 0.78, 0.52), 2.0)    # sıcak ana ışık (fener)
    area((2.8, -1.5, 2.0), 300, (0.75, 0.80, 1.0), 1.5)      # soğuk kenar
    area((0.0, 2.5, 2.5), 400, (1.0, 0.7, 0.4), 2.0)         # arkadan sırt
    area((0.0, -3.0, -0.5), 120, (1.0, 0.85, 0.7), 3.0)      # alttan dolgu


def camera_for(center, width, height, elevation=0.0):
    sc = bpy.context.scene
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = max(width, height)
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    e = math.radians(elevation)
    cam.location = (center[0], center[1] - 6.0 * math.cos(e), center[2] + 6.0 * math.sin(e))
    cam.rotation_euler = (math.pi / 2 - e, 0.0, 0.0)
    sc.camera = cam
    sc.render.resolution_x = int(round(width * PPU))
    sc.render.resolution_y = int(round(height * PPU))
    return cam


def render_only(col_name, path, center, width, height, samples, elevation=0.0):
    sc = bpy.context.scene
    for col in bpy.data.collections:
        hide = col.name != col_name
        col.hide_render = hide
    for o in list(sc.collection.objects):
        if o.type == "CAMERA":
            bpy.data.objects.remove(o)
    camera_for(center, width, height, elevation)
    sc.cycles.samples = samples
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main(argv):
    samples = int(argv[argv.index("--samples") + 1]) if "--samples" in argv else 64
    os.makedirs(OUT, exist_ok=True)
    reset()
    brass = metal("brass", (0.50, 0.42, 0.30), 0.34, 0.6)
    dark = metal("dark_brass", (0.30, 0.25, 0.18), 0.40, 0.65)
    gold = metal("gold", (0.95, 0.72, 0.30), 0.28, 0.25)
    build_column(brass, dark)
    build_beam(brass, dark)
    build_pan(brass, dark)
    build_coin(gold)
    lights()
    # Çerçeveler (birim): her resim kendi parçasını boşlukla sarar.
    col_w, col_h = 1.2, PIVOT_Z + 0.42
    beam_w, beam_h = 2.0 * BEAM_HALF + 0.24, 0.62
    pan_w, pan_h = 2.0 * PAN_R + 0.14, CHAIN + PAN_DEPTH + 0.16
    render_only("column", os.path.join(OUT, "column.png"), (0, 0, col_h / 2.0 - 0.02), col_w, col_h, samples)
    render_only("beam", os.path.join(OUT, "beam.png"), (0, 0, PIVOT_Z + 0.07), beam_w, beam_h, samples)
    render_only("pan", os.path.join(OUT, "pan.png"), (0, 0, -(CHAIN + PAN_DEPTH) / 2.0 + 0.02), pan_w, pan_h, samples)
    render_only("coin", os.path.join(OUT, "coin.png"), (0, 0, 0), 0.16, 0.16, samples, 30.0)
    # Bağlantı noktaları (resim pikseli, sol üstten): oyun parçaları bunlarla birleştirir.
    def px(width, height, center_z, x, z):
        return (round((x + width / 2.0) * PPU, 1), round((center_z + height / 2.0 - z) * PPU, 1))
    col_pivot = px(col_w, col_h, col_h / 2.0 - 0.02, 0.0, PIVOT_Z)
    col_foot = px(col_w, col_h, col_h / 2.0 - 0.02, 0.0, 0.0)
    beam_c = PIVOT_Z + 0.07
    beam_pivot = px(beam_w, beam_h, beam_c, 0.0, PIVOT_Z)
    beam_left = px(beam_w, beam_h, beam_c, -BEAM_HALF, PIVOT_Z - 0.04)
    pan_c = -(CHAIN + PAN_DEPTH) / 2.0 + 0.02
    pan_hook = px(pan_w, pan_h, pan_c, 0.0, 0.0)
    pan_floor = px(pan_w, pan_h, pan_c, 0.0, -CHAIN - PAN_DEPTH * 0.55)
    lines = [
        "class_name MarketScaleArt",
        "extends RefCounted",
        "",
        "## tools/ui_scenes/market_scale_scene.py yazar, elle değiştirme. Resim pikseli, sol üstten.",
        "",
        "const DIR: String = \"res://data/assets/ui/market_scale/\"",
        "const PPU: float = %d.0" % PPU,
        "const COLUMN_PIVOT: Vector2 = Vector2(%s, %s)" % col_pivot,
        "const COLUMN_FOOT: Vector2 = Vector2(%s, %s)" % col_foot,
        "const BEAM_PIVOT: Vector2 = Vector2(%s, %s)" % beam_pivot,
        "## Sol askı; sağ askı mile göre aynası.",
        "const BEAM_LEFT_HOOK: Vector2 = Vector2(%s, %s)" % beam_left,
        "const PAN_HOOK: Vector2 = Vector2(%s, %s)" % pan_hook,
        "## Kefenin içinde malın oturduğu yer (orta) ve yarıçapı (piksel).",
        "const PAN_FLOOR: Vector2 = Vector2(%s, %s)" % pan_floor,
        "const PAN_RADIUS: float = %s" % round(PAN_R * 0.82 * PPU, 1),
        "",
    ]
    with open(GD, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("BITTI", OUT)


if __name__ == "__main__":
    main(sys.argv)
