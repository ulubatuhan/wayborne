# -*- coding: utf-8 -*-
"""Yerleşim türüne özel parçalar, Blender'da kurulur (kullanıcı, 2026-10-22:
"yurtlara, maden ya da balık kasabalarına özel şehir ekranı ve şehre giriş
tasarımı"). Paketlerde yurt, tuğ, maden arabası, ray, kuyu iskelesi, balık
sergisi, sazlık yoktu; burada düz renkli, kalın hatlı alçak poligon olarak
kuruluyorlar: town_post'un mürekkebi ve dört tonu paket modelleriyle aynı dile
çeviriyor.

Her kurucu orijinde, tabanı z=0'da, önü -y'ye (kasaba kamerasına) bakan bir
nesne listesi döndürür; yerleştirmeyi town_scene yapar (`"kind":
"builder:<ad>[:<arg>]"`). Ölçüler metre.
"""
import math

import bpy
from mathutils import Vector

# Malzemeler: ad -> renk. Adlar town_scene.weather_materials'ın atladığı
# listede değil, yani yıpranan bir kültürde bunlar da yıpranır.
COLORS = {
    "felt": (0.64, 0.58, 0.47), "felt_roof": (0.54, 0.48, 0.38), "felt_band": (0.40, 0.12, 0.07),
    "door_paint": (0.56, 0.20, 0.07), "timber": (0.34, 0.22, 0.12), "timber_dark": (0.20, 0.13, 0.08),
    "iron": (0.16, 0.16, 0.17), "ore": (0.22, 0.20, 0.19), "horsehair": (0.06, 0.05, 0.045),
    "net": (0.30, 0.27, 0.20), "fish": (0.62, 0.64, 0.62), "reed": (0.42, 0.40, 0.22),
    "rope": (0.48, 0.40, 0.28), "brass": (0.62, 0.48, 0.20),
}


def material(name):
    m = bpy.data.materials.get("sp_" + name)
    if m is not None:
        return m
    m = bpy.data.materials.new("sp_" + name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = COLORS[name] + (1.0,)
    bsdf.inputs["Roughness"].default_value = 0.85 if name not in ("iron", "brass", "fish") else 0.45
    return m


def _finish(obj, mat):
    obj.data.materials.append(material(mat))
    for p in obj.data.polygons:
        p.use_smooth = False
    return obj


def cylinder(r, depth, at, mat, verts=20, r2=None, rot=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=at)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=depth, location=at)
    o = bpy.context.object
    if rot is not None:
        o.rotation_euler = rot
    return _finish(o, mat)


def box(size, at, mat, rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=at)
    o = bpy.context.object
    o.scale = size
    if rot is not None:
        o.rotation_euler = rot
    return _finish(o, mat)


def beam(a, b, thick, mat):
    """İki nokta arasında kare kesitli bir kiriş."""
    a, b = Vector(a), Vector(b)
    d = b - a
    o = box((thick, thick, d.length), (a + b) / 2, mat)
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    return o


def torus(r, minor, z, mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=minor, location=(0, 0, z),
                                     major_segments=28, minor_segments=6)
    return _finish(bpy.context.object, mat)


# ------------------------------------------------------------------ göçebe

def yurt(arg=""):
    """Keçe yurt: kafes duvar, iki halat kuşak, basık kubbe, tepe halkası,
    boyalı ahşap kapı (kameraya bakar)."""
    r = float(arg or 2.6)
    wall_h = r * 0.6
    out = [cylinder(r, wall_h, (0, 0, wall_h / 2), "felt", verts=28)]
    for z in (wall_h * 0.25, wall_h * 0.8):
        out.append(torus(r * 1.005, 0.03, z, "felt_band"))
    roof_h = r * 0.48
    out.append(cylinder(r * 1.06, roof_h, (0, 0, wall_h + roof_h / 2), "felt_roof", verts=28, r2=r * 0.18))
    out.append(cylinder(r * 0.2, 0.18, (0, 0, wall_h + roof_h + 0.06), "timber", verts=16))
    out.append(torus(r * 0.8, 0.04, wall_h + roof_h * 0.32, "felt_band"))
    # Soba borusu tepe halkasının yanında.
    out.append(cylinder(0.07, 0.6, (r * 0.12, r * 0.06, wall_h + roof_h + 0.28), "iron", verts=8))
    door_w, door_h = 0.9, min(1.25, wall_h * 0.85)
    out.append(box((door_w + 0.16, 0.12, door_h + 0.12), (0, -r - 0.02, (door_h + 0.12) / 2), "timber_dark"))
    out.append(box((door_w, 0.14, door_h), (0, -r - 0.05, door_h / 2), "door_paint"))
    # Kapının üstünde sarılı keçe perde.
    out.append(cylinder(0.12, door_w + 0.2, (0, -r - 0.08, door_h + 0.2), "felt", verts=10,
                        rot=(0.0, math.radians(90), 0.0)))
    return out


def tug(arg=""):
    """Tuğ: uzun sırık, tepede pirinç uç ve halka, altında at kılı püskül."""
    h = float(arg or 4.4)
    out = [cylinder(0.055, h, (0, 0, h / 2), "timber", verts=8)]
    out.append(cylinder(0.05, 0.42, (0, 0, h + 0.21), "brass", verts=8, r2=0.0))
    out.append(torus(0.2, 0.025, h - 0.1, "brass"))
    out[-1].location.z = h - 0.1
    out.append(cylinder(0.26, 1.1, (0, 0, h - 0.75), "horsehair", verts=12, r2=0.05))
    out.append(cylinder(0.05, 0.25, (0, 0, h - 0.18), "felt_band", verts=8))
    return out


def horse_line(arg=""):
    """At bağlama direği: iki kazık arasında gergin halat."""
    w = float(arg or 5.0)
    out = []
    for x in (-w / 2, w / 2):
        out.append(cylinder(0.07, 1.4, (x, 0, 0.7), "timber", verts=8))
    out.append(cylinder(0.025, w, (0, 0, 1.25), "rope", verts=6, rot=(0.0, math.radians(90), 0.0)))
    return out


# ------------------------------------------------------------------ maden

def minecart(arg=""):
    """Maden arabası: tahta tekne, demir kuşak, dört teker, içinde cevher."""
    out = [box((0.9, 1.3, 0.5), (0, 0, 0.55), "timber")]
    for y in (-0.5, 0.5):
        out.append(box((0.94, 0.06, 0.52), (0, y, 0.55), "iron"))
    for x in (-0.46, 0.46):
        for y in (-0.42, 0.42):
            out.append(cylinder(0.2, 0.08, (x, y, 0.2), "iron", verts=14, rot=(0.0, math.radians(90), 0.0)))
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.55, location=(0, 0, 0.82))
    ore = bpy.context.object
    ore.scale = (0.78, 1.05, 0.45)
    out.append(_finish(ore, "ore"))
    return out


def rails(arg=""):
    """Ray: iki demir hat ve traversler, +y boyunca `arg` metre."""
    length = float(arg or 10.0)
    out = []
    for x in (-0.36, 0.36):
        out.append(box((0.07, length, 0.09), (x, length / 2, 0.13), "iron"))
    n = int(length / 0.65)
    for i in range(n):
        out.append(box((1.05, 0.18, 0.08), (0, 0.3 + i * 0.65, 0.04), "timber_dark"))
    return out


def headframe(arg=""):
    """Kuyu iskelesi: iki A çatkı, tepede makara, aşağıda kuyu ağzı."""
    h = float(arg or 7.0)
    out = []
    for x in (-1.1, 1.1):
        out.append(beam((x, -1.4, 0), (x * 0.4, 0, h), 0.22, "timber"))
        out.append(beam((x, 1.4, 0), (x * 0.4, 0, h), 0.22, "timber"))
        out.append(beam((x, -0.9, h * 0.35), (x, 0.9, h * 0.35), 0.16, "timber"))
    out.append(beam((-0.9, 0, h), (0.9, 0, h), 0.2, "timber_dark"))
    wheel = torus(0.75, 0.07, 0, "iron")
    wheel.rotation_euler = (0.0, math.radians(90), 0.0)
    wheel.location = (0, 0, h + 0.15)
    out.append(wheel)
    out.append(cylinder(0.02, h - 0.6, (0, -0.75, (h - 0.6) / 2 + 0.6), "rope", verts=6))
    out.append(box((2.0, 2.0, 0.6), (0, 0, 0.3), "timber_dark"))
    return out


def ore_heap(arg=""):
    s = float(arg or 1.6)
    bpy.ops.mesh.primitive_cone_add(vertices=9, radius1=s, radius2=s * 0.15, depth=s * 0.8, location=(0, 0, s * 0.4))
    return [_finish(bpy.context.object, "ore")]


# ------------------------------------------------------------------ su

def net_rack(arg=""):
    """Balık ve ağ sergisi: iki çatal direk, sırıklarda asılı ağ ve balıklar."""
    w = float(arg or 3.2)
    out = []
    for x in (-w / 2, w / 2):
        out.append(beam((x, -0.4, 0), (x, 0, 2.1), 0.1, "timber"))
        out.append(beam((x, 0.4, 0), (x, 0, 2.1), 0.1, "timber"))
    out.append(cylinder(0.05, w + 0.3, (0, 0, 2.05), "timber", verts=8, rot=(0.0, math.radians(90), 0.0)))
    out.append(box((w * 0.55, 0.02, 1.2), (-w * 0.18, 0, 1.4), "net"))
    for i in range(5):
        x = w * 0.12 + i * 0.22
        f = cylinder(0.07, 0.42, (x, 0, 1.75), "fish", verts=8, r2=0.02)
        out.append(f)
    return out


def stilts(arg=""):
    """Kazık ayaklar ve tahta döşeme: bataklık evinin altı (`arg` = yükseklik)."""
    h = float(arg or 1.4)
    out = [box((5.2, 4.6, 0.2), (0, 0, h - 0.1), "timber")]
    for x in (-2.3, 0.0, 2.3):
        for y in (-2.0, 2.0):
            out.append(cylinder(0.13, h + 0.4, (x, y, (h - 0.4) / 2), "timber_dark", verts=8))
    out.append(beam((-2.6, -2.6, 0.0), (-2.0, -2.3, h), 0.18, "timber_dark"))
    for i in range(4):
        out.append(box((0.9, 0.28, 0.06), (-2.3, -2.4 - i * 0.3, h - 0.25 - i * 0.32), "timber"))
    return out


def reeds(arg=""):
    """Sazlık: ince eğik koniler, tohumla değil düzenli dağılmış."""
    w = float(arg or 3.0)
    out = []
    for i in range(26):
        a = i * 2.399
        rr = w * 0.5 * math.sqrt((i + 0.5) / 26)
        x, y = math.cos(a) * rr, math.sin(a) * rr * 0.6
        h = 1.1 + 0.6 * ((i * 37) % 10) / 10.0
        c = cylinder(0.035, h, (x, y, h / 2), "reed", verts=5, r2=0.005)
        c.rotation_euler = (0.12 * math.sin(i), 0.12 * math.cos(i * 1.7), 0.0)
        out.append(c)
    return out


BUILDERS = {
    "yurt": yurt, "tug": tug, "horse_line": horse_line,
    "minecart": minecart, "rails": rails, "headframe": headframe, "ore_heap": ore_heap,
    "net_rack": net_rack, "stilts": stilts, "reeds": reeds,
}


def build(name, arg=""):
    before = set(bpy.data.objects)
    BUILDERS[name](arg)
    return [o for o in bpy.data.objects if o not in before]
