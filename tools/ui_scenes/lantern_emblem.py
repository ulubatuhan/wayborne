"""Fener amblemi (görev Y-G08): Poly Haven Lantern 01 (CC0) yandan, saydam
arka planla render edilir; mürekkep geçişi `lantern_emblem_post.py`'de.

    blender -b --python tools/ui_scenes/lantern_emblem.py

Çıktı: build/ui_scenes/lantern/beauty.png (1024x1024, saydam).
"""
import math
import os

import bpy
from mathutils import Vector

ROOT = os.environ.get("WAYBORNE_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
SRC = os.path.join(ROOT, "art_source/models/props/polyhaven_lantern_01/Lantern_01_1k.gltf")
OUT = os.path.join(ROOT, "build/ui_scenes/lantern")


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=SRC)
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    centre = (lo + hi) / 2.0
    size = max(hi - lo)
    # Işık: yanan bir fener - içeride sıcak nokta ışık, dışarıdan soğuk dolgu.
    warm = bpy.data.lights.new("warm", "POINT")
    warm.energy = 40.0
    warm.color = (1.0, 0.62, 0.30)
    lw = bpy.data.objects.new("warm", warm)
    lw.location = centre
    bpy.context.scene.collection.objects.link(lw)
    fill = bpy.data.lights.new("fill", "SUN")
    fill.energy = 1.2
    fill.color = (0.72, 0.78, 0.95)
    lf = bpy.data.objects.new("fill", fill)
    lf.rotation_euler = (math.radians(55), 0.0, math.radians(35))
    bpy.context.scene.collection.objects.link(lf)
    cam = bpy.data.cameras.new("cam")
    cam.type = "ORTHO"
    cam.ortho_scale = size * 1.25
    co = bpy.data.objects.new("cam", cam)
    co.location = centre + Vector((0.0, -size * 4.0, 0.0))
    co.rotation_euler = (math.radians(90), 0.0, 0.0)
    bpy.context.scene.collection.objects.link(co)
    sc = bpy.context.scene
    sc.camera = co
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 64
    sc.render.film_transparent = True
    sc.render.resolution_x = 1024
    sc.render.resolution_y = 1024
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.02, 0.02, 0.03, 1.0)
    sc.world = world
    os.makedirs(OUT, exist_ok=True)
    sc.render.filepath = os.path.join(OUT, "beauty.png")
    bpy.ops.render.render(write_still=True)
    print("BITTI", sc.render.filepath)


main()
