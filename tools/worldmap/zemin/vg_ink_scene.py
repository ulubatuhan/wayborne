"""referans oyun denemesi 2 (oyunun dili): aynı sahne, dört ayrı geçiş.

  shade.png   beyaz malzemeyle yalnız ışık (alçak akşam güneşi + gölge) -
              son işlemde düz tonlara bölünecek (oyunun "dört ton" kuralı);
  albedo.png  ışıksız düz renk (emisyon);
  ids.png     sınıf rengi: arazi, su, ağaç, yapı, sur (mürekkep kenarları);
  height.png  dünya z'si (16 bit) - dağ ve kıyı konturu.

    python3 -I vg_ink_scene.py <vg klasörü> <layout.json> [samples] [res]
"""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vg_scene as V  # noqa: E402  (aynı argümanlar)

CLASS = {
    "terrain": (0.0, 0.0, 0.0), "water": (0.0, 0.0, 1.0),
    "conifer": (0.0, 1.0, 0.0), "leaf": (0.0, 1.0, 0.0), "bush": (0.0, 0.6, 0.0),
    "stone": (1.0, 0.0, 0.0), "stone_dark": (1.0, 0.0, 0.0), "wood": (1.0, 0.0, 0.0),
    "plaster": (1.0, 1.0, 0.0), "roof_a": (1.0, 1.0, 0.0), "roof_b": (1.0, 1.0, 0.0),
    "thatch": (1.0, 1.0, 0.0), "felt": (1.0, 0.0, 1.0), "felt_dark": (1.0, 0.0, 1.0),
    "crown": (1.0, 0.0, 0.6), "mud": (0.0, 0.0, 0.0), "horse": (1.0, 0.0, 0.3),
    "plaster_grey": (1.0, 1.0, 0.0), "plaster_warm": (1.0, 1.0, 0.0), "plaster_pale": (1.0, 1.0, 0.0),
    "slate": (1.0, 1.0, 0.0), "tile_red": (1.0, 1.0, 0.0), "flat_roof": (1.0, 1.0, 0.0),
    "timber_dark": (1.0, 1.0, 0.0), "sod": (1.0, 1.0, 0.0), "stone_pale": (1.0, 0.0, 0.0),
    "hull": (0.6, 0.0, 1.0), "sail": (0.6, 0.6, 1.0), "wake": (0.0, 0.0, 1.0),
}


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    V.terrain()
    acc = V.Acc()
    V.trees(acc)
    V.settlements(acc)
    acc.build()
    me = bpy.data.meshes.new("water")
    h = V.HALF
    me.from_pydata([(-h, -h, 0.0), (h, -h, 0.0), (h, h, 0.0), (-h, h, 0.0)], [], [(0, 1, 2, 3)])
    wm = bpy.data.materials.new("water")
    b = wm.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.02, 0.03, 0.04, 1)
    b.inputs["Roughness"].default_value = 0.9
    me.materials.append(wm)
    ob = bpy.data.objects.new("water", me)
    sc.collection.objects.link(ob)
    for o in sc.objects:
        if o.type == "MESH":
            o.color = CLASS.get(o.name, (0, 0, 0)) + (1.0,)

    # alçak akşam güneşi, batı-kuzeybatıdan; turuncu
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 3.0
    sun.angle = math.radians(0.6)
    so = bpy.data.objects.new("sun", sun)
    elev, az = math.radians(20), math.radians(160)
    d = Vector((math.cos(elev) * math.cos(az), math.cos(elev) * math.sin(az), math.sin(elev)))
    so.rotation_mode = "QUATERNION"
    so.rotation_quaternion = d.to_track_quat("Z", "Y")
    sc.collection.objects.link(so)
    w = bpy.data.worlds.new("w")
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (1, 1, 1, 1)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.12
    sc.world = w

    cam = bpy.data.cameras.new("cam")
    cam.type = "ORTHO"
    cam.ortho_scale = float(os.environ.get("VG_CAM_SCALE", V.S))
    cam.clip_end = 2000
    co = bpy.data.objects.new("cam", cam)
    co.location = (float(os.environ.get("VG_CAM_X", 0)), float(os.environ.get("VG_CAM_Y", 0)), 800)
    sc.collection.objects.link(co)
    sc.camera = co
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.render.resolution_x = sc.render.resolution_y = V.RES
    sc.render.image_settings.file_format = "PNG"
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    return sc


def override(sc, kind):
    m = bpy.data.materials.new("ovr_" + kind)
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    if kind == "shade":
        d = nt.nodes.new("ShaderNodeBsdfDiffuse")
        d.inputs["Color"].default_value = (0.8, 0.8, 0.8, 1)
        nt.links.new(d.outputs["BSDF"], out.inputs["Surface"])
    elif kind == "ids":
        info = nt.nodes.new("ShaderNodeObjectInfo")
        em = nt.nodes.new("ShaderNodeEmission")
        nt.links.new(info.outputs["Color"], em.inputs["Color"])
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    elif kind == "height":
        geo = nt.nodes.new("ShaderNodeNewGeometry")
        sep = nt.nodes.new("ShaderNodeSeparateXYZ")
        rng = nt.nodes.new("ShaderNodeMapRange")
        rng.inputs["From Min"].default_value = -10.0
        rng.inputs["From Max"].default_value = 110.0
        em = nt.nodes.new("ShaderNodeEmission")
        nt.links.new(geo.outputs["Position"], sep.inputs["Vector"])
        nt.links.new(sep.outputs["Z"], rng.inputs["Value"])
        nt.links.new(rng.outputs["Result"], em.inputs["Color"])
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    sc.view_layers[0].material_override = m


def albedo_mode():
    """Her malzemenin çıkışını kendi renginin emisyonuna bağla."""
    for m in bpy.data.materials:
        nt = m.node_tree
        if nt is None or "Principled BSDF" not in nt.nodes:
            continue
        b = nt.nodes["Principled BSDF"]
        out = nt.nodes["Material Output"]
        em = nt.nodes.new("ShaderNodeEmission")
        if b.inputs["Base Color"].is_linked:
            nt.links.new(b.inputs["Base Color"].links[0].from_socket, em.inputs["Color"])
        else:
            em.inputs["Color"].default_value = b.inputs["Base Color"].default_value
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])


def shot(sc, name, samples, depth="8", mode="RGB", flat=False):
    sc.cycles.samples = samples
    sc.cycles.use_denoising = not flat
    sc.cycles.filter_width = 0.01 if flat else 1.5
    sc.render.image_settings.color_mode = mode
    sc.render.image_settings.color_depth = depth
    sc.render.filepath = os.path.join(V.VG, name)
    bpy.ops.render.render(write_still=True)


def main():
    sc = build()
    override(sc, "shade")
    shot(sc, "shade.png", V.SAMPLES, depth="16")
    sun = bpy.data.objects["sun"]
    sun.hide_render = True
    sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
    override(sc, "ids")
    shot(sc, "ids.png", 1, flat=True)
    sc.view_layers[0].material_override = None
    albedo_mode()
    shot(sc, "albedo_r.png", 4)
    print("GEÇİŞLER TAMAM")


if __name__ == "__main__":
    main()
