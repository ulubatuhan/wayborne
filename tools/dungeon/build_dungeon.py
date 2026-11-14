# -*- coding: utf-8 -*-
"""Galeri ağızlarının bölge arka planları (Y-A07; SIDERIA §11.7), Blender Cycles.

Her ağız üç bölgeden geçer ve her bölgenin kendi resmi var:

- **agiz**: insanın açtığı ya da doğanın yardığı giriş (kuyu, yarık, merdiven).
- **gecis**: kaba kayanın kadim işçiliğe dönmeye başladığı yer ("kazmayla açılmamış").
- **galeri**: kadim şehrin kendi galerisi; düz kesilmiş, işlenmiş, aşınmış taş.

Görünüş yandan, savaşın diliyle: arka duvar kameraya paralel, figürler önündeki
zemine basar (ayak çizgisi resmin ~%59'unda, duvar dibi ~%46'sında). Işık tek
sıcak kaynaktan: kadronun meşalesi (Art Rules, tek sıcak kaynak); geri kalan her
şey soğuk ve soluk, dokular solgunlaştırılıyor. Gün ışığı (kuyu ağzı, merdiven
başı) soğuk.

    python3 -I tools/dungeon/fetch_assets.py            # bir kez: dokular, modeller
    /root/bpyenv/bin/python tools/dungeon/build_dungeon.py --scene eski_agiz_agiz [--preview]
    /root/bpyenv/bin/python tools/dungeon/build_dungeon.py --all

Çıktı `data/assets/backgrounds/dungeon/<ağız>_<bölge>.jpg` (1920x1080).
Kaynaklar: Poly Haven (CC0), `art_source/models/props/LICENSES.md`.
"""
import argparse
import math
import os
import random
import sys

import bpy
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "build", "dungeon_src")
OUT = os.path.join(ROOT, "data", "assets", "backgrounds", "dungeon")
PREVIEW = os.path.join(ROOT, "build", "dungeon_preview")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fresco  # noqa: E402

WALL_Y = 3.0            # arka duvarın düzlemi
CORRIDOR = 20.0         # x boyunca sahnenin eni (kameranın gördüğünden geniş)
TORCH = (1.0, 0.56, 0.26)
COLD = (0.62, 0.72, 0.86)


# ---------------------------------------------------------------- sahne

def reset(preview: bool) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24 if preview else 56
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.adaptive_threshold = 0.02
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 6
    scene.cycles.volume_bounces = 1
    scene.cycles.caustics_reflective = False
    scene.cycles.caustics_refractive = False
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 4
    scene.render.resolution_x = 960 if preview else 1920
    scene.render.resolution_y = 540 if preview else 1080
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = 0.0
    world = bpy.data.worlds.new("dunya")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.010, 0.012, 0.016, 1.0)
    bg.inputs[1].default_value = 1.0
    scene.world = world


def camera(height: float = 1.5, dist: float = 6.6, tilt: float = 0.0, lens: float = 23.0, shift: float = -0.09) -> None:
    cam_data = bpy.data.cameras.new("kamera")
    cam_data.lens = lens
    cam_data.clip_end = 200.0
    cam = bpy.data.objects.new("kamera", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = (0.0, -dist, height)
    cam.rotation_euler = (math.radians(90.0 - tilt), 0.0, 0.0)
    # Eğmek yerine kaydırma: duvarlar dik kalır, duvar dibi kadrajın ~%46'sına iner.
    cam_data.shift_y = shift
    bpy.context.scene.camera = cam


# ---------------------------------------------------------------- malzeme

def _tex(nodes, path: str, color: bool, proj_box: bool = True):
    node = nodes.new("ShaderNodeTexImage")
    node.image = bpy.data.images.load(path, check_existing=True)
    if not color:
        node.image.colorspace_settings.name = "Non-Color"
    if proj_box:
        node.projection = "BOX"
        node.projection_blend = 0.25
    return node


def pbr(name: str, asset: str, scale: float = 1.0, sat: float = 0.35, value: float = 0.8,
        rough: float = 1.0, bump: float = 0.6, tint=(1.0, 1.0, 1.0), wet: float = 0.0,
        fresco_img: str = "", vary: float = 0.0) -> bpy.types.Material:
    """Poly Haven dokusu, nesne koordinatında kutu izdüşümüyle (UV gerekmez).
    `sat` doygunluk: sahne dokusu soğuk ve soluk kalır (tek sıcak kaynak)."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = nodes["Principled BSDF"]
    folder = os.path.join(SRC, "tex", asset)
    coord = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (1.0 / scale, 1.0 / scale, 1.0 / scale)
    links.new(coord.outputs["Object"], mapping.inputs["Vector"])
    diff = _tex(nodes, os.path.join(folder, "diff.jpg"), True)
    links.new(mapping.outputs[0], diff.inputs[0])
    hsv = nodes.new("ShaderNodeHueSaturation")
    hsv.inputs["Saturation"].default_value = sat
    hsv.inputs["Value"].default_value = value
    links.new(diff.outputs[0], hsv.inputs["Color"])
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    links.new(hsv.outputs[0], mix.inputs[6])
    mix.inputs[7].default_value = (*tint, 1.0)
    color_out = mix.outputs[2]
    if vary > 0.0:
        # Her blok kendi taşından: nesne başına rastgele ton (kesme taş tek renk olmaz).
        info = nodes.new("ShaderNodeObjectInfo")
        ramp = nodes.new("ShaderNodeMapRange")
        ramp.inputs["To Min"].default_value = 1.0 - vary
        ramp.inputs["To Max"].default_value = 1.0 + vary * 0.6
        links.new(info.outputs["Random"], ramp.inputs["Value"])
        vmix = nodes.new("ShaderNodeVectorMath")
        vmix.operation = "SCALE"
        links.new(color_out, vmix.inputs[0])
        links.new(ramp.outputs[0], vmix.inputs["Scale"])
        color_out = vmix.outputs[0]
    if fresco_img:
        color_out = fresco.mix_into(nt, color_out, fresco_img)
    links.new(color_out, bsdf.inputs["Base Color"])
    rough_tex = _tex(nodes, os.path.join(folder, "rough.jpg"), False)
    links.new(mapping.outputs[0], rough_tex.inputs[0])
    rmath = nodes.new("ShaderNodeMath")
    rmath.operation = "MULTIPLY"
    rmath.inputs[1].default_value = rough * (1.0 - 0.75 * wet)
    links.new(rough_tex.outputs[0], rmath.inputs[0])
    links.new(rmath.outputs[0], bsdf.inputs["Roughness"])
    nor_tex = _tex(nodes, os.path.join(folder, "nor.jpg"), False)
    links.new(mapping.outputs[0], nor_tex.inputs[0])
    nmap = nodes.new("ShaderNodeNormalMap")
    nmap.inputs["Strength"].default_value = 1.0
    links.new(nor_tex.outputs[0], nmap.inputs["Color"])
    disp_tex = _tex(nodes, os.path.join(folder, "disp.jpg"), False)
    links.new(mapping.outputs[0], disp_tex.inputs[0])
    bmp = nodes.new("ShaderNodeBump")
    bmp.inputs["Strength"].default_value = bump
    bmp.inputs["Distance"].default_value = 0.05 * scale
    links.new(disp_tex.outputs[0], bmp.inputs["Height"])
    links.new(nmap.outputs[0], bmp.inputs["Normal"])
    links.new(bmp.outputs[0], bsdf.inputs["Normal"])
    if wet > 0.0:
        # Islaklık hafif bir parıltı; kaplama (coat) kıvılcım gibi parlıyordu (önizlemede görüldü).
        bsdf.inputs["Specular IOR Level"].default_value = 0.5 + 0.2 * wet
    return mat


def flat(name: str, color, rough: float = 0.9, emission=None, strength: float = 0.0) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return mat


def water(name: str = "su", puddle: bool = False) -> bpy.types.Material:
    """Durgun su. `puddle`: kenarı gürültüyle kesilen birikinti (dikdörtgen değil)."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.05, 0.055, 0.06, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.05
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 3.0
    noise.inputs["Detail"].default_value = 4.0
    bmp = nt.nodes.new("ShaderNodeBump")
    bmp.inputs["Strength"].default_value = 0.08
    nt.links.new(noise.outputs[0], bmp.inputs["Height"])
    nt.links.new(bmp.outputs[0], bsdf.inputs["Normal"])
    if puddle:
        mat.blend_method = "HASHED"
        coord = nt.nodes.new("ShaderNodeTexCoord")
        shape = nt.nodes.new("ShaderNodeTexNoise")
        shape.inputs["Scale"].default_value = 0.9
        shape.inputs["Detail"].default_value = 6.0
        nt.links.new(coord.outputs["Object"], shape.inputs["Vector"])
        cut = nt.nodes.new("ShaderNodeMapRange")
        cut.inputs["From Min"].default_value = 0.44
        cut.inputs["From Max"].default_value = 0.47
        nt.links.new(shape.outputs[0], cut.inputs["Value"])
        clear = nt.nodes.new("ShaderNodeBsdfTransparent")
        mix = nt.nodes.new("ShaderNodeMixShader")
        out = nt.nodes["Material Output"]
        nt.links.new(cut.outputs[0], mix.inputs[0])
        nt.links.new(clear.outputs[0], mix.inputs[1])
        nt.links.new(bsdf.outputs[0], mix.inputs[2])
        nt.links.new(mix.outputs[0], out.inputs["Surface"])
    return mat


def haze(density: float, color=(0.6, 0.65, 0.7), size=(24.0, 18.0, 8.0), loc=(0.0, 0.0, 3.0)) -> None:
    """Havadaki toz ya da buhar: ışık huzmesini ve meşalenin halesini görünür kılar."""
    bpy.ops.mesh.primitive_cube_add(location=loc)
    cube = bpy.context.active_object
    cube.name = "pus"
    cube.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    mat = bpy.data.materials.new("pus")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Density"].default_value = density
    vol.inputs["Color"].default_value = (*color, 1.0)
    vol.inputs["Anisotropy"].default_value = 0.35
    nt.links.new(vol.outputs[0], nt.nodes["Material Output"].inputs["Volume"])
    cube.data.materials.append(mat)


# ---------------------------------------------------------------- geometri

def _obj_from_active(name: str, mat) -> bpy.types.Object:
    obj = bpy.context.active_object
    obj.name = name
    if mat is not None:
        obj.data.materials.append(mat)
    return obj


def grid(name: str, size_x: float, size_y: float, loc, rot, mat, res: int = 6) -> bpy.types.Object:
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=max(2, int(size_x * res)),
                                    y_subdivisions=max(2, int(size_y * res)),
                                    size=1.0, location=loc, rotation=rot)
    obj = _obj_from_active(name, mat)
    obj.scale = (size_x, size_y, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    return obj


def rough_up(obj, strength: float, scale: float, kind: str = "VORONOI", seed: int = 0, axis: str = "NORMAL",
             detail: float = 0.0) -> None:
    """Kaba kaya: gürültüyle ötelenmiş yüzey (makro biçim; mikro dokudan)."""
    tex = bpy.data.textures.new("%s_%d" % (obj.name, seed), type=kind)
    if kind == "VORONOI":
        tex.noise_scale = scale
        tex.distance_metric = "DISTANCE"
        tex.noise_intensity = 1.0
    else:
        tex.noise_scale = scale
        tex.noise_depth = 4
    mod = obj.modifiers.new("kaba_%d" % seed, "DISPLACE")
    mod.texture = tex
    mod.strength = strength
    mod.mid_level = 0.5
    mod.direction = axis
    mod.texture_coords = "GLOBAL"
    if detail > 0.0:
        t2 = bpy.data.textures.new("%s_d%d" % (obj.name, seed), type="CLOUDS")
        t2.noise_scale = detail
        t2.noise_depth = 5
        m2 = obj.modifiers.new("ince_%d" % seed, "DISPLACE")
        m2.texture = t2
        m2.strength = strength * 0.25
        m2.direction = axis
        m2.texture_coords = "GLOBAL"


def box(name: str, size, loc, mat, bevel: float = 0.02, rot=(0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    obj = _obj_from_active(name, mat)
    obj.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    if bevel > 0:
        mod = obj.modifiers.new("pah", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    return obj


def cylinder(name: str, radius: float, depth: float, loc, rot, mat, verts: int = 16) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=loc, rotation=rot, vertices=verts)
    return _obj_from_active(name, mat)


def model(asset: str, loc, scale: float = 1.0, rot_z: float = 0.0, rot=None, tint_sat: float = 0.4) -> list:
    folder = os.path.join(SRC, "models", asset)
    path = [f for f in os.listdir(folder) if f.endswith(".gltf")][0]
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(folder, path))
    new = [o for o in bpy.data.objects if o not in before]
    roots = [o for o in new if o.parent is None]
    for root in roots:
        root.location = loc
        root.scale = (scale, scale, scale)
        root.rotation_euler = rot if rot is not None else (0.0, 0.0, rot_z)
    for obj in new:
        if obj.type != "MESH":
            continue
        for slot in obj.material_slots:
            _desaturate(slot.material, tint_sat)
    return new


def _desaturate(mat, sat: float) -> None:
    if mat is None or not mat.use_nodes or mat.get("_soluk"):
        return
    mat["_soluk"] = True
    nt = mat.node_tree
    bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf is None or not bsdf.inputs["Base Color"].is_linked:
        return
    src = bsdf.inputs["Base Color"].links[0].from_socket
    hsv = nt.nodes.new("ShaderNodeHueSaturation")
    hsv.inputs["Saturation"].default_value = sat
    hsv.inputs["Value"].default_value = 0.85
    nt.links.new(src, hsv.inputs["Color"])
    nt.links.new(hsv.outputs[0], bsdf.inputs["Base Color"])


def scatter(assets, count: int, x_range, y_range, scale_range, seed: int, z: float = 0.0) -> None:
    rng = random.Random(seed)
    for _ in range(count):
        model(rng.choice(assets), (rng.uniform(*x_range), rng.uniform(*y_range), z),
              rng.uniform(*scale_range), rng.uniform(0, math.tau))


# ---------------------------------------------------------------- ışık

def _link(obj) -> None:
    bpy.context.scene.collection.objects.link(obj)


def torch(x: float = 0.0, power: float = 420.0, y: float = 0.9, z: float = 1.9) -> None:
    """Kadronun meşalesi: sahnenin tek sıcak kaynağı. Görünmez (figürler taşır);
    duvara yakın, çünkü kadro duvarın önünde durur."""
    data = bpy.data.lights.new("mesale", "POINT")
    data.energy = power
    data.color = TORCH
    data.shadow_soft_size = 0.35
    obj = bpy.data.objects.new("mesale", data)
    obj.location = (x, y, z)
    # Pus meşaleyi bir ampul gibi göstermesin: ışık zemine ve duvara düşer, havada hale yok.
    obj.visible_volume_scatter = False
    _link(obj)


def fill(power: float = 420.0, color=COLD, z: float = 2.6) -> None:
    """Soğuk dolgu, kameranın arkasından duvara: karanlığın içi okunsun diye."""
    data = bpy.data.lights.new("dolgu", "AREA")
    data.energy = power
    data.color = color
    data.shape = "RECTANGLE"
    data.size = 16.0
    data.size_y = 4.0
    obj = bpy.data.objects.new("dolgu", data)
    obj.location = (0.0, -7.5, z)
    obj.rotation_euler = (math.radians(84), 0.0, 0.0)
    obj.visible_volume_scatter = False
    _link(obj)


def shaft(loc, power: float, angle: float = 22.0, rot=(0.0, 0.0, 0.0), color=COLD) -> None:
    """Yukarıdan inen soğuk gün ışığı (kuyu ağzı, merdiven başı)."""
    data = bpy.data.lights.new("gunisigi", "SPOT")
    data.energy = power
    data.color = color
    data.spot_size = math.radians(angle)
    data.spot_blend = 0.5
    data.shadow_soft_size = 0.2
    obj = bpy.data.objects.new("gunisigi", data)
    obj.location = loc
    obj.rotation_euler = rot
    _link(obj)


# ---------------------------------------------------------------- yapı taşları

def punch(obj, cx: float, cy: float, radius: float) -> None:
    """Izgaradan daire biçiminde yüz siler (açık yüzeyde Boolean tutmuyor)."""
    import bmesh
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    local = Vector((cx, cy, 0.0)) - obj.location
    gone = [f for f in bm.faces if (f.calc_center_median().xy - local.xy).length < radius]
    bmesh.ops.delete(bm, geom=gone, context="FACES")
    bm.to_mesh(mesh)
    bm.free()


def natural_room(wall_mat, floor_mat, ceil_mat=None, height: float = 3.8, seed: int = 1,
                 wall_rough: float = 0.55, floor_rough: float = 0.10, hole=None) -> None:
    """Doğal mağara: ötelenmiş arka duvar, engebeli zemin, alçak kaba tavan."""
    ceil_mat = ceil_mat or wall_mat
    floor = grid("zemin", CORRIDOR, 12.0, (0.0, -2.5, 0.0), (0.0, 0.0, 0.0), floor_mat, res=10)
    rough_up(floor, floor_rough, 0.9, "CLOUDS", seed, "Z", detail=0.25)
    wall = grid("duvar", CORRIDOR, height + 1.5, (0.0, WALL_Y, height / 2 - 0.2), (math.radians(90), 0, 0),
                wall_mat, res=14)
    rough_up(wall, wall_rough, 1.3, "VORONOI", seed + 1, detail=0.35)
    roof = grid("tavan", CORRIDOR, 12.0, (0.0, -2.5, height), (0.0, 0.0, 0.0), ceil_mat, res=10)
    if hole is not None:
        punch(roof, *hole)
    rough_up(roof, 0.7, 1.6, "VORONOI", seed + 2, "Z", detail=0.4)


def side_rocks(mat, seed: int, count: int = 2, y: float = 0.6) -> None:
    """Kadrajın iki kenarında karanlık kaya kütleleri: çerçeve ve derinlik."""
    rng = random.Random(seed)
    for side in (-1, 1):
        for i in range(count):
            x = side * (6.6 + rng.uniform(-0.3, 0.6) + i * 1.1)
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=5, radius=rng.uniform(1.2, 1.9),
                                                  location=(x, y + rng.uniform(-0.6, 1.6), rng.uniform(0.6, 3.0)))
            rock = _obj_from_active("yan_kaya", mat)
            rock.scale = (rng.uniform(0.7, 1.0), rng.uniform(0.8, 1.2), rng.uniform(1.2, 1.9))
            rough_up(rock, 0.55, 0.8, "VORONOI", seed + i * 7 + side, detail=0.3)


def ashlar_wall(mat, y: float = WALL_Y, height: float = 4.0, x0: float = -10.0, x1: float = 10.0,
                block_w: float = 1.6, block_h: float = 0.8, seed: int = 3, jitter: float = 0.006,
                gap: float = 0.008, missing=(), depth: float = 0.5, bevel=(0.004, 0.02)) -> None:
    """Kadim işçilik: harçsız, sık oturtulmuş iri bloklar. Her blok ayrı: derz
    dokudan değil gerçek geometriden okunur."""
    rng = random.Random(seed)
    row = 0
    z = 0.0
    while z < height - 0.01:
        h = min(block_h * (1.0 if row % 3 else 0.72), height - z)
        x = x0 - (block_w * 0.5 if row % 2 else 0.0)
        col = 0
        while x < x1:
            w = block_w * rng.uniform(0.8, 1.25)
            if (row, col) not in missing:
                box("blok", (w - gap, depth, h - gap),
                    (x + w / 2, y + depth / 2 + rng.uniform(-jitter, jitter), z + h / 2),
                    mat, bevel=rng.uniform(*bevel))
            x += w
            col += 1
        z += h
        row += 1


def timber_set(x: float, mat, height: float = 2.9, y: float = WALL_Y - 0.35, lean: float = 0.0) -> None:
    """Madenci dikmesi: iki direk ve başlık. Kaba yuvarlak ağaç."""
    for side in (-1, 1):
        cylinder("direk", 0.13, height, (x + side * 1.25, y, height / 2), (0.0, math.radians(side * 3 + lean), 0.0), mat, 12)
    cylinder("baslik", 0.15, 3.1, (x, y, height + 0.05), (0.0, math.radians(90), 0.0), mat, 12)


def rubble(seed: int, x: float, width: float, y: float = WALL_Y - 0.6, count: int = 14, big: float = 1.0) -> None:
    rng = random.Random(seed)
    stones = ["namaqualand_boulder_02", "namaqualand_boulder_03", "namaqualand_boulder_05", "rock_07", "rock_09",
              "stone_01"]
    for i in range(count):
        size = big * rng.uniform(0.25, 0.9) * (1.0 - i / (count * 1.4))
        model(rng.choice(stones), (x + rng.uniform(-width / 2, width / 2), y + rng.uniform(-0.8, 0.4), 0.0),
              size, rng.uniform(0, math.tau))


def slab_floor(mat, seed: int, x0: float = -10.0, x1: float = 10.0, y0: float = -8.0, y1: float = WALL_Y,
               w: float = 1.4, d: float = 1.0) -> None:
    """Kadim döşeme: iri, hafif oynamış levhalar (asırlık yürüyüşle aşınmış)."""
    rng = random.Random(seed)
    y = y0
    while y < y1:
        x = x0 - rng.uniform(0, w)
        while x < x1:
            ww = w * rng.uniform(0.8, 1.3)
            box("levha", (ww - 0.012, d - 0.012, 0.2), (x + ww / 2, y + d / 2, -0.1 + rng.uniform(-0.012, 0.01)),
                mat, bevel=rng.uniform(0.01, 0.03), rot=(rng.uniform(-0.006, 0.006), rng.uniform(-0.006, 0.006), 0.0))
            x += ww
        y += d


# ---------------------------------------------------------------- sahneler
#
# Doku seçimi: doğal kaya `rock_face_03`/`dark_rock`; madenci kazması
# `quarry_wall_02`; kadim kesik yüz `concrete_wall_006` (desensiz, koyu, düz) ve
# `rock_surface` (ince taneli kesme taş); kadim döşeme `monastery_stone_floor`/
# `rock_tile_floor` yerine geometrik levha; sıva `worn_plaster_wall`. Dokuların
# kendi blok deseni olanları (rock_wall_16, japanese_stone_wall) iri bloğun
# üstünde küçük tuğla gibi okunduğu için kadim duvardan çıkarıldı (önizlemede görüldü).

def eski_agiz_agiz(seed: int = 11) -> None:
    """Vorgat'ın ilk kuyusunun dibi: kaba kaya; tavandaki kuyu ağzından, kırık
    taş örtünün arasından süzülen soğuk ışık; sarkan halat ve kova; ağızdan
    dökülen moloz ve örtünün yere düşmüş parçaları."""
    rock = pbr("kaya", "rock_face_03", 2.4, sat=0.22, value=0.75)
    ground = pbr("zemin", "rocks_ground_02", 1.6, sat=0.22, value=0.6)
    hole = (-2.6, 1.7, 1.15)
    natural_room(rock, ground, height=3.6, seed=seed, wall_rough=0.7, hole=hole)
    side_rocks(pbr("yan", "dark_rock_02", 2.0, sat=0.2, value=0.5), seed)
    slab = pbr("ortu", "rock_surface", 1.2, sat=0.12, value=0.6)
    # Kuyu ağzının çevresinde örgü bilezik, üstünde kırık örtü.
    for k in range(10):
        a = k / 10 * math.tau
        box("bilezik", (0.6, 0.35, 0.4), (hole[0] + math.cos(a) * 1.3, hole[1] + math.sin(a) * 1.3, 3.75), slab,
            rot=(0.0, 0.0, a), bevel=0.03)
    box("ortu", (1.3, 0.7, 0.22), (hole[0] + 0.7, hole[1] - 0.2, 4.1), slab, rot=(0.25, 0.1, 0.3))
    box("ortu_dusmus", (1.1, 0.8, 0.22), (hole[0] - 0.4, hole[1] - 0.6, 0.18), slab, rot=(0.35, 0.2, 0.7))
    box("ortu_dusmus2", (0.9, 0.6, 0.2), (hole[0] + 1.0, hole[1] - 0.2, 0.12), slab, rot=(-0.2, 0.15, -0.4))
    shaft((hole[0], hole[1], 14.0), 70000.0, 9.0)
    rope = flat("halat", (0.20, 0.18, 0.16), 0.95)
    cylinder("halat", 0.02, 3.7, (hole[0] + 0.2, hole[1], 1.85), (0.0, 0.0, 0.0), rope, 8)
    model("wooden_bucket_01", (hole[0] + 0.45, hole[1] - 0.7, 0.0), 1.0, 0.6)
    rubble(seed, hole[0], 2.2, y=hole[1] + 0.3, count=14, big=0.4)
    rubble(seed + 5, 4.8, 2.4, count=7, big=0.35)
    wood = pbr("dikme", "bark_willow_02", 0.8, sat=0.2, value=0.55)
    cylinder("eski_dikme", 0.12, 3.2, (4.2, WALL_Y - 0.5, 1.5), (0.0, math.radians(12), 0.0), wood, 12)
    torch(0.8, 304.0)
    fill(988.0)
    haze(0.035, color=(0.6, 0.65, 0.72))


def eski_agiz_gecis(seed: int = 21) -> None:
    """Madenci tüneli: kazma izli duvar, kaba dikmeler. Sağda kaya birden biter;
    arkasından düz, derzleri kıl kadar, kazmayla açılmamış koyu bir yüz çıkar."""
    hewn = pbr("kazma", "quarry_wall_02", 2.4, sat=0.2, value=0.72)
    ground = pbr("zemin", "rocky_trail", 1.8, sat=0.2, value=0.58)
    natural_room(hewn, ground, height=3.4, seed=seed, wall_rough=0.35)
    ancient = pbr("kadim", "rock_surface", 2.0, sat=0.06, value=0.42, bump=0.5, vary=0.18)
    ashlar_wall(ancient, y=WALL_Y - 0.75, height=3.3, x0=2.5, x1=11.0, block_w=2.6, block_h=1.1, seed=seed,
                gap=0.006, jitter=0.0, bevel=(0.002, 0.006))
    edge = pbr("kirik", "dark_rock_02", 1.6, sat=0.2, value=0.5)
    for k, z in enumerate((0.5, 1.5, 2.6)):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=5, radius=0.8, location=(2.35, WALL_Y - 0.55, z))
        lip = _obj_from_active("kaya_kenari", edge)
        lip.scale = (0.55, 0.7, 0.9)
        rough_up(lip, 0.45, 0.6, "VORONOI", seed + k, detail=0.3)
    wood = pbr("dikme", "bark_willow_02", 0.8, sat=0.2, value=0.55)
    for x in (-6.0, -2.6):
        timber_set(x, wood)
    planks = pbr("tahta", "brown_planks_03", 1.0, sat=0.15, value=0.5)
    box("tahta_yigini", (1.6, 0.5, 0.18), (-4.4, WALL_Y - 1.0, 0.09), planks, rot=(0, 0, 0.15))
    model("picke_dirty_01", (1.6, WALL_Y - 1.2, 0.0), 1.0, rot=(math.radians(-14), 0, math.radians(80)))
    model("wooden_crate_01", (-5.0, WALL_Y - 1.3, 0.0), 0.9, 0.3)
    rubble(seed, 1.4, 1.2, count=6, big=0.35)
    side_rocks(pbr("yan", "dark_rock_02", 2.0, sat=0.2, value=0.5), seed)
    torch(0.4, 320.0)
    fill(1040.0)
    haze(0.012)


def eski_agiz_galeri(seed: int = 31) -> None:
    """Kadim tünel: dimdik, düz, kıl derzli iri bloklar; uzun levhalardan düz
    tavan; sağda üç kademeli çerçeveyle örtülmüş bir kapı; solda tavandan inmiş
    göçük (aşağısı göçükle kapalı)."""
    ancient = pbr("kadim", "rock_surface", 2.0, sat=0.06, value=0.42, bump=0.5, vary=0.18)
    worn = pbr("asinmis", "rock_surface", 1.6, sat=0.06, value=0.5)
    slab_floor(pbr("doseme", "rock_surface", 1.6, sat=0.05, value=0.36, bump=0.5, vary=0.15), seed, w=2.2, d=1.3)
    ashlar_wall(ancient, height=3.6, block_w=2.6, block_h=1.2, seed=seed, gap=0.006, jitter=0.004,
                bevel=(0.004, 0.03))
    # Kuşak: kadimlerin tek süsü, düz bir oluk sırası.
    for k in range(26):
        box("oluk", (0.06, 0.06, 0.32), (-9.6 + k * 0.76, WALL_Y - 0.02, 2.9), worn, bevel=0.01)
    for k in range(9):
        box("tavan_levha", (2.4, 12.0, 0.45), (-10.0 + k * 2.42 + 1.2, -2.5, 3.85), ancient, bevel=0.004)
    # Kapı: üç kademeli oyuk çerçeve, içinde düz levha.
    door_x = 3.4
    for step, (w, h, d) in enumerate(((2.9, 3.0, 0.12), (2.5, 2.75, 0.24), (2.1, 2.5, 0.36))):
        for side in (-1, 1):
            box("cerceve", (0.2, d, h), (door_x + side * (w / 2 - 0.1), WALL_Y - d / 2 + 0.01, h / 2), worn, bevel=0.004)
        box("cerceve_ust", (w, d, 0.2), (door_x, WALL_Y - d / 2 + 0.01, h - 0.1), worn, bevel=0.004)
    box("levha", (1.7, 0.2, 2.3), (door_x, WALL_Y - 0.25, 1.15), worn, bevel=0.004)
    # Göçük: tavan levhaları kırılıp inmiş.
    fallen = [(-3.6, 0.3, 0.3, 0.4), (-2.7, 0.25, -0.4, 0.2), (-3.2, 0.85, 0.7, -0.3), (-4.4, 0.35, 0.1, 0.9)]
    for i, (x, z, r, t) in enumerate(fallen):
        box("dusmus", (1.5, 0.9, 0.62), (x, WALL_Y - 0.8 - i * 0.2, z), ancient, rot=(t, r, 0.15 * i), bevel=0.03)
    for k in (2, 3):
        o = [ob for ob in bpy.data.objects if ob.name.startswith("tavan_levha")][k]
        o.location.z -= 0.25
        o.rotation_euler = (0.12, -0.08, 0.0)
    rubble(seed, -3.5, 2.6, count=12, big=0.45)
    torch(0.2, 304.0)
    fill(936.0)
    haze(0.02, color=(0.6, 0.62, 0.66))


def kemrug_agiz(seed: int = 41) -> None:
    """Ocağın tabanındaki yarık: ıslak kara kaya, tavanda yukarı uzanan çatlak,
    zeminde birikintiler ve duvar dibinden sızan ince bir su; yarıktan yükselen
    ılık buhar. Solda bir taş rafta bez üstünde ekmek sepeti: Kemruglular'ın
    bıraktığı, ne için olduğu söylenmez."""
    wet = pbr("islak", "dark_rock", 2.2, sat=0.16, value=1.0, rough=0.75, bump=0.35)
    ground = pbr("zemin", "dark_rock_02", 1.6, sat=0.14, value=0.6, rough=0.6)
    natural_room(wet, ground, height=4.6, seed=seed, wall_rough=0.75)
    # Tavanın ortası yukarı yarılır: iki eğik kaya kütlesi arasında karanlık bir yarık.
    for side in (-1, 1):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=5, radius=3.0, location=(side * 2.6, 1.2, 4.6))
        lip = _obj_from_active("tavan_kutle", wet)
        lip.scale = (1.4, 1.3, 0.55)
        lip.rotation_euler = (0.0, side * 0.35, 0.0)
        rough_up(lip, 0.6, 0.9, "VORONOI", seed + side, detail=0.3)
    side_rocks(wet, seed, count=3)
    pool = water(puddle=True)
    for x, w, y in ((-2.2, 3.2, 1.4), (2.2, 2.6, 2.0), (4.6, 2.6, 1.0)):
        grid("birikinti", w, 1.6, (x, y, 0.045), (0, 0, 0), pool, res=2)
    grid("sizinti", CORRIDOR, 0.5, (0.0, WALL_Y - 0.5, 0.05), (0, 0, 0), water(puddle=True), res=2)
    shelf = pbr("raf", "dark_rock_02", 1.2, sat=0.18, value=0.6)
    box("raf", (1.3, 0.7, 0.85), (-4.6, WALL_Y - 0.75, 0.42), shelf, bevel=0.08)
    cloth = flat("bez", (0.30, 0.29, 0.27), 0.95)
    box("bez", (0.85, 0.55, 0.02), (-4.6, WALL_Y - 0.78, 0.86), cloth, bevel=0.0)
    model("wicker_basket_01", (-4.7, WALL_Y - 0.78, 0.87), 0.7, 0.4)
    model("wooden_bowl_01", (-4.2, WALL_Y - 0.85, 0.87), 0.9, 0.0)
    torch(0.3, 288.0)
    fill(1040.0)
    haze(0.05, color=(0.72, 0.74, 0.77), size=(24.0, 8.0, 5.0), loc=(0.0, 1.5, 2.5))


def kemrug_gecis(seed: int = 51) -> None:
    """Yarık genişler: duvarın alt boyu düz kesilmiş iri bloklara döner, üstü hâlâ
    yarığın ıslak kayası; zeminde dümdüz oyulmuş, içinde ılık su akan bir kanal."""
    wet = pbr("islak", "dark_rock", 2.2, sat=0.16, value=1.0, rough=0.75, bump=0.35)
    ground = pbr("zemin", "dark_rock_02", 1.6, sat=0.14, value=0.6, rough=0.6)
    natural_room(wet, ground, height=4.4, seed=seed, wall_rough=0.55)
    cut = pbr("kesik", "rock_surface", 1.4, sat=0.08, value=0.6, vary=0.15)
    ashlar_wall(cut, y=WALL_Y - 0.7, height=2.0, block_w=2.0, block_h=1.0, seed=seed,
                missing={(1, 0), (1, 1), (1, 9)}, bevel=(0.005, 0.02))
    edge = pbr("kanal", "rock_surface", 1.0, sat=0.06, value=0.55, wet=0.4)
    # Kanal duvarın dibinde: kesik bloklarla aynı elden.
    box("kanal_arka", (CORRIDOR, 0.25, 0.32), (0.0, WALL_Y - 0.85, 0.16), edge, bevel=0.01)
    box("kanal_on", (CORRIDOR, 0.25, 0.32), (0.0, WALL_Y - 1.65, 0.16), edge, bevel=0.01)
    box("kanal_dibi", (CORRIDOR, 0.6, 0.06), (0.0, WALL_Y - 1.25, 0.03), edge, bevel=0.0)
    grid("kanal_su", CORRIDOR, 0.56, (0.0, WALL_Y - 1.25, 0.22), (0, 0, 0), water(), res=2)
    side_rocks(wet, seed, count=2)
    torch(0.3, 304.0)
    fill(1040.0)
    haze(0.045, color=(0.72, 0.74, 0.77), size=(24.0, 8.0, 5.0), loc=(0.0, 1.5, 2.5))


def kemrug_galeri(seed: int = 61) -> None:
    """Ilık kaynak salonu: kadim kare ayaklar, düz kesilmiş duvar, duvar dibinde
    basamaklı taş havuzlar; havuzlardan buhar; aşınmış iri döşeme."""
    stone = pbr("tas", "rock_surface", 1.6, sat=0.07, value=0.6, vary=0.15)
    slab_floor(pbr("doseme", "rock_surface", 1.2, sat=0.06, value=0.5, wet=0.35), seed, w=1.6, d=1.2)
    ashlar_wall(stone, height=4.4, block_w=2.2, block_h=1.1, seed=seed, bevel=(0.005, 0.015))
    for k in range(9):
        box("tavan_levha", (2.4, 12.0, 0.45), (-10.0 + k * 2.42 + 1.2, -2.5, 4.62), stone, bevel=0.004)
    for x in (-6.2, -2.1, 2.1, 6.2):
        box("ayak", (0.75, 0.75, 4.4), (x, WALL_Y - 1.05, 2.2), stone, bevel=0.02)
        box("ayak_basi", (1.05, 1.05, 0.3), (x, WALL_Y - 1.05, 4.25), stone, bevel=0.015)
        box("ayak_kaidesi", (1.0, 1.0, 0.25), (x, WALL_Y - 1.05, 0.12), stone, bevel=0.015)
    for x in (-4.15, 0.0, 4.15):
        box("havuz_arka", (3.2, 0.25, 0.55), (x, WALL_Y - 0.15, 0.27), stone, bevel=0.01)
        box("havuz_on", (3.2, 0.25, 0.55), (x, WALL_Y - 1.35, 0.27), stone, bevel=0.01)
        grid("havuz_su", 3.0, 1.0, (x, WALL_Y - 0.75, 0.42), (0, 0, 0), water(), res=2)
        box("basamak", (3.2, 0.45, 0.22), (x, WALL_Y - 1.7, 0.11), stone, bevel=0.01)
    torch(0.2, 288.0)
    fill(1040.0)
    haze(0.07, color=(0.74, 0.76, 0.78), size=(24.0, 5.0, 3.5), loc=(0.0, WALL_Y - 1.0, 1.8))


def kor_kazmalar_agiz(seed: int = 71) -> None:
    """Mezarlığın altına inen merdivenin dibi: arkada duvar boyunca yukarı çıkan
    oyulmuş basamaklar ve tepeden düşen soğuk gün ışığı; tavandan sarkan kökler;
    kaba örgü duvar, merdivenin yanında düzgün kesme taş."""
    rough_wall = pbr("orgu", "quarry_wall_02", 2.0, sat=0.15, value=0.62)
    ground = pbr("zemin", "rocky_trail", 1.6, sat=0.16, value=0.55)
    natural_room(rough_wall, ground, height=3.9, seed=seed, wall_rough=0.3, hole=(-5.6, 1.9, 1.3))
    steps = pbr("basamak", "rock_surface", 1.2, sat=0.08, value=0.58, vary=0.15)
    for i in range(10):
        box("basamak", (0.42, 1.5, 0.32 * (i + 1)), (-1.2 - i * 0.42, WALL_Y - 0.95, 0.16 * (i + 1)), steps,
            bevel=0.025)
    ashlar_wall(steps, y=WALL_Y - 0.25, height=3.9, x0=-6.0, x1=-0.9, block_w=1.1, block_h=0.55, seed=seed,
                bevel=(0.01, 0.03), jitter=0.02)
    shaft((-5.6, 1.9, 12.0), 50000.0, 10.0)
    root = flat("kok", (0.12, 0.11, 0.10), 0.9)
    rng = random.Random(seed)
    for i in range(18):
        x = rng.uniform(-7, 7)
        length = rng.uniform(0.3, 1.2)
        cylinder("kok", rng.uniform(0.008, 0.03), length, (x, rng.uniform(0.0, 2.6), 3.75 - length / 2),
                 (rng.uniform(-0.25, 0.25), rng.uniform(-0.25, 0.25), 0.0), root, 6)
    rubble(seed, 4.4, 2.4, count=7, big=0.35)
    side_rocks(pbr("yan", "dark_rock_02", 2.0, sat=0.2, value=0.48), seed)
    torch(0.8, 288.0)
    fill(988.0)
    haze(0.03)


def kor_kazmalar_gecis(seed: int = 81) -> None:
    """Merdivenin dibindeki koridor: düz kesilmiş, aşınmış taş; duvarda boş
    nişler; sıvanın ilk parçaları yer yer duruyor."""
    worked = pbr("isli", "rock_surface", 1.5, sat=0.08, value=0.55, vary=0.15)
    slab_floor(pbr("doseme", "rock_surface", 1.2, sat=0.06, value=0.45), seed, w=1.3, d=0.9)
    niches = {(1, c) for c in (1, 3, 5, 7, 9)}
    ashlar_wall(worked, height=3.6, block_w=1.8, block_h=0.9, seed=seed, missing=niches,
                bevel=(0.008, 0.03), jitter=0.012)
    back = pbr("nis", "rock_surface", 1.0, sat=0.06, value=0.3)
    box("nis_dibi", (CORRIDOR, 0.2, 3.6), (0.0, WALL_Y + 0.6, 1.8), back, bevel=0.0)
    plaster = pbr("siva", "worn_plaster_wall", 1.2, sat=0.1, value=0.75)
    rng = random.Random(seed)
    for _ in range(4):
        box("siva", (rng.uniform(0.4, 1.1), 0.012, rng.uniform(0.3, 0.6)),
            (rng.uniform(-8, 8), WALL_Y - 0.004, rng.choice((0.45, 2.5, 3.0))), plaster, bevel=0.004)
    for k in range(9):
        box("tavan_levha", (2.4, 12.0, 0.45), (-10.0 + k * 2.42 + 1.2, -2.5, 3.82), worked, bevel=0.006)
    rubble(seed, -5.0, 1.8, count=5, big=0.3)
    torch(0.3, 304.0)
    fill(988.0)
    haze(0.015)


def kor_kazmalar_galeri(seed: int = 91) -> None:
    """Resimli duvarlar: sıvalı panolarda solmuş gündelik hayat (tarla, su
    taşıyanlar, sürü, dokuma, sofra); oyulmuş kuşaklar ve ayaklar."""
    plaster_img = fresco.paint(os.path.join(SRC, "fresco_kor_kazmalar.png"), seed)
    plaster = pbr("resimli", "grey_plaster_02", 1.6, sat=0.12, value=0.82, fresco_img=plaster_img)
    frame = pbr("kusak", "rock_surface", 1.3, sat=0.07, value=0.55, vary=0.1)
    slab_floor(pbr("doseme", "rock_surface", 1.2, sat=0.06, value=0.45), seed, w=1.5, d=1.0)
    wall = grid("pano", CORRIDOR, 4.0, (0.0, WALL_Y + 0.02, 2.0), (math.radians(90), 0, 0), plaster, res=24)
    rough_up(wall, 0.015, 1.0, "CLOUDS", seed, detail=0.2)
    box("alt_kusak", (CORRIDOR, 0.3, 0.55), (0.0, WALL_Y - 0.12, 0.27), frame, bevel=0.012)
    box("ust_kusak", (CORRIDOR, 0.35, 0.45), (0.0, WALL_Y - 0.15, 3.38), frame, bevel=0.012)
    for x in (-7.5, -2.5, 2.5, 7.5):
        box("ayak", (0.6, 0.4, 3.6), (x, WALL_Y - 0.17, 1.8), frame, bevel=0.015)
    for k in range(9):
        box("tavan_levha", (2.4, 12.0, 0.45), (-10.0 + k * 2.42 + 1.2, -2.5, 3.82), frame, bevel=0.006)
    rubble(seed, 6.0, 1.6, count=5, big=0.3)
    torch(0.2, 304.0)
    fill(936.0)
    haze(0.012)


SCENES = {
    "eski_agiz_agiz": eski_agiz_agiz,
    "eski_agiz_gecis": eski_agiz_gecis,
    "eski_agiz_galeri": eski_agiz_galeri,
    "kemrug_yarigi_agiz": kemrug_agiz,
    "kemrug_yarigi_gecis": kemrug_gecis,
    "kemrug_yarigi_galeri": kemrug_galeri,
    "kor_kazmalar_agiz": kor_kazmalar_agiz,
    "kor_kazmalar_gecis": kor_kazmalar_gecis,
    "kor_kazmalar_galeri": kor_kazmalar_galeri,
}


def render(name: str, preview: bool) -> str:
    reset(preview)
    camera()
    SCENES[name]()
    folder = PREVIEW if preview else OUT
    os.makedirs(folder, exist_ok=True)
    scene = bpy.context.scene
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 90
    path = os.path.join(folder, name + ".jpg")
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("yazildi", path)
    return path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scene", default="")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--preview", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:])
    names = list(SCENES) if args.all else [args.scene]
    for name in names:
        render(name, args.preview)
    return 0


if __name__ == "__main__":
    sys.exit(main())
