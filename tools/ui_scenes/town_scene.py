"""Şehir merkezi arka planı: önden bakılan bir
kasaba meydanı, şehir başına bir tane.

    python3 -I tools/ui_scenes/town_scene.py --city karakonak [--samples 64] [--scale 100]

Çıktı: build/ui_scenes/town_<city>/beauty.png (ham render), ids.png (mekân
maskeleri: her mekân kendi düz rengiyle, gerisi siyah), meta.json.
Ardından town_post.py resmi oyunun diline çevirir (mürekkep, ton, kir).

Modeller: Quaternius Medieval Village (CC0) binaları, Kenney Fantasy Town
Kit (CC0) parçalarından kurulan gotik kuleler, ambientCG (CC0) dokuları.
Referans görüntülerin hiçbir pikseli kullanılmıyor.
"""
import json
import math
import os
import random
import sys

import bpy
from mathutils import Euler, Matrix, Vector

ROOT = os.environ.get("WAYBORNE_ROOT", "/home/user/wayborne-ui")
QV = os.path.join(ROOT, "art_source/models/props/quaternius_medieval_village")
QM = os.path.join(ROOT, "art_source/models/props/quaternius_modular_medieval")
FTK = os.path.join(ROOT, "art_source/models/ui_scenes/kenney_fantasy_town/GLB format")
TEX = os.path.join(ROOT, "art_source/textures/ambientcg")
OUT = os.path.join(ROOT, "build/ui_scenes")
CFG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "towns.json")

# Mekân -> maske rengi (ids.png). Sıra CityFront.VENUES ile aynı.
VENUE_IDS = {
    "yard": (1.0, 0.0, 0.0), "market": (0.0, 1.0, 0.0), "guild": (0.0, 0.0, 1.0),
    "tavern": (1.0, 1.0, 0.0), "church": (1.0, 0.0, 1.0), "tailor": (0.0, 1.0, 1.0),
    "gate": (1.0, 0.5, 0.0),
}

_cache = {}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _cache.clear()


def _import(path):
    before = set(bpy.data.objects)
    if path.endswith(".blend"):
        with bpy.data.libraries.load(path, link=False) as (src, dst):
            dst.objects = list(src.objects)
        for o in dst.objects:
            if o is not None:
                bpy.context.scene.collection.objects.link(o)
    else:
        bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.type in ("CAMERA", "LIGHT"):
            bpy.data.objects.remove(o, do_unlink=True)
    return [o for o in bpy.data.objects if o not in before]


def _template(path):
    """Bir modeli bir kez yükler, gizli bir şablon olarak tutar."""
    if path in _cache:
        return _cache[path]
    objs = _import(path)
    roots = [o for o in objs if o.parent is None]
    for o in objs:
        o.hide_render = True
        o.hide_viewport = True
    _cache[path] = (objs, roots)
    return _cache[path]


def place(path, loc, rot_z=0.0, scale=1.0, tag="", mats=None):
    """Şablonun bağlantılı bir kopyasını sahneye koyar."""
    objs, roots = _template(path)
    mapping = {}
    out = []
    for o in objs:
        c = o.copy()
        bpy.context.scene.collection.objects.link(c)
        c.hide_render = False
        c.hide_viewport = False
        mapping[o] = c
        out.append(c)
    for o, c in mapping.items():
        if o.parent in mapping:
            c.parent = mapping[o.parent]
    for r in roots:
        c = mapping[r]
        turn = Matrix.Rotation(math.radians(rot_z), 3, "Z")
        rot = turn @ r.matrix_basis.to_3x3().normalized()
        c.rotation_mode = "XYZ"
        c.rotation_euler = rot.to_euler("XYZ")
        c.location = turn @ (Vector(r.location) * scale) + Vector(loc)
        c.scale = Vector(r.scale) * scale
    for c in out:
        c["venue"] = tag
        if mats is not None and c.type == "MESH":
            for slot in c.material_slots:
                slot.link = "OBJECT"
                slot.material = mats
    return out


def qv(name):
    return os.path.join(QV, name + ".blend")


def ftk(name):
    return os.path.join(FTK, name + ".glb")


# ---------------------------------------------------------------- yapılar

def spire_tower(x, y, z0, floors, size, tag="", wood=False, roof="roof-high-point", mats=None):
    """Kenney duvarlarından kare gövdeli, sivri çatılı bir kule."""
    wall_kinds = ["wall-wood-window-shutters", "wall-wood", "wall-wood-window-small"] if wood else \
        ["wall-window-stone", "wall", "wall-window-small"]
    rng = random.Random(int(x * 31 + y * 17))
    for f in range(floors):
        for k in range(4):
            kind = wall_kinds[0 if f == floors - 1 else rng.randrange(len(wall_kinds))]
            place(ftk(kind), (x, y, z0 + f * size), k * 90.0, size, tag, mats)
    place(ftk(roof), (x, y, z0 + floors * size), 0.0, size * 1.05, tag)


def terrace(x, y, w, d, h, tag=""):
    """Bir binayı yükselten taş set: dokulu tek bir blok (istinat
    duvarları gibi)."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, y, h / 2.0))
    b = bpy.context.object
    b.scale = (w, d, h)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    b["venue"] = tag
    b.data.materials.append(_stone_material())


def _stone_material(name="terrace_stone", value=0.55):
    m = bpy.data.materials.get(name)
    if m is not None:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True  # Blender 4.2: varsayılan kapalı
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.35, 0.35, 0.35)
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    t = _tex_node(nt, os.path.join(TEX, "Bricks097/Bricks097_1K-JPG_Color.jpg"), mp)
    hsv = nt.nodes.new("ShaderNodeHueSaturation")
    hsv.inputs["Saturation"].default_value = 0.25
    hsv.inputs["Value"].default_value = value
    nt.links.new(t.outputs["Color"], hsv.inputs["Color"])
    nt.links.new(hsv.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.95
    return m


def _built(name, loc, rot_z, scale, tag):
    """Eşya hattının kurucusundan (brandalı vagon) bir model: oyunun yolda
    çizdiği vagonun aynısı, bir boşluk nesnesine bağlanıp yerleştirilir."""
    sys.path.insert(0, os.path.join(ROOT, "tools/figure_pipeline/props"))
    import wagon_builder
    before = set(bpy.data.objects)
    wagon_builder.BUILDERS[name]()
    new = [o for o in bpy.data.objects if o not in before]
    pivot = bpy.data.objects.new(name + "_pivot", None)
    bpy.context.scene.collection.objects.link(pivot)
    for o in new:
        if o.name not in bpy.context.scene.collection.objects and not o.users_collection:
            bpy.context.scene.collection.objects.link(o)
        if o.parent is None:
            o.parent = pivot
        o["venue"] = tag
    pivot.location = loc
    pivot.rotation_euler = (0.0, 0.0, math.radians(rot_z))
    pivot.scale = (scale, scale, scale)


def building(spec):
    if spec["kind"] == "wallrow":
        wall_row(spec)
        return
    tag = spec.get("venue", "")
    x, y = spec["at"]
    z = spec.get("z", 0.0)
    if spec.get("terrace"):
        tw, td, th = spec["terrace"]
        terrace(x, y, tw, td, th, "")
        z = th
    kind = spec["kind"]
    if kind == "spire":
        spire_tower(x, y, z, spec.get("floors", 3), spec.get("size", 1.2), tag, spec.get("wood", False),
            mats=_stone_material("wall_dark", 0.3) if spec.get("dark") else None)
    elif kind.startswith("builder:"):
        _built(kind[8:], (x, y, z), spec.get("rot", 0.0), spec.get("scale", 1.0), tag)
    elif kind.startswith("file:"):
        place(os.path.join(ROOT, kind[5:]), (x, y, z), spec.get("rot", 0.0), spec.get("scale", 1.0), tag)
    elif kind.startswith("ftk:"):
        place(ftk(kind[4:]), (x, y, z), spec.get("rot", 0.0), spec.get("scale", 1.0), tag)
    else:
        place(qv(kind), (x, y, z), spec.get("rot", 0.0), spec.get("scale", 1.0), tag)
    for extra in spec.get("spires", []):
        ex, ey, ez = extra["at"]
        spire_tower(x + ex, y + ey, z + ez, extra.get("floors", 2), extra.get("size", 1.0), tag, extra.get("wood", False))


# ---------------------------------------------------------------- malzemeler

def _tex_node(nt, path, mapping):
    t = nt.nodes.new("ShaderNodeTexImage")
    t.image = bpy.data.images.load(path, check_existing=True)
    t.projection = "BOX"
    t.projection_blend = 0.3
    nt.links.new(mapping.outputs["Vector"], t.inputs["Vector"])
    return t


def texture_materials(window_glow):
    """Düz renkli Quaternius malzemelerine doku ve pencerelere ışık."""
    detail = {
        "Stone": "Rock064", "Stone_Dark": "Rock064", "Stone_Light": "Rock064",
        "Plaster": "Plaster001", "Beige": "Plaster001",
        "Wood": "Planks037A", "Wood_Light": "Planks037A", "Wood_Side": "Planks037A",
    }
    for m in bpy.data.materials:
        if not m.use_nodes:
            continue
        nt = m.node_tree
        bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            continue
        base = m.name.split(".")[0]
        if base == "Windows":
            bsdf.inputs["Emission Color"].default_value = window_glow
            bsdf.inputs["Emission Strength"].default_value = 6.0
            continue
        if base in detail:
            tc = nt.nodes.new("ShaderNodeTexCoord")
            mp = nt.nodes.new("ShaderNodeMapping")
            mp.inputs["Scale"].default_value = (0.6, 0.6, 0.6)
            nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
            tex = _tex_node(nt, os.path.join(TEX, detail[base], detail[base] + "_1K-JPG_Color.jpg"), mp)
            mix = nt.nodes.new("ShaderNodeMix")
            mix.data_type = "RGBA"
            mix.blend_type = "MULTIPLY"
            mix.inputs["Factor"].default_value = 0.75
            col = bsdf.inputs["Base Color"].default_value[:]
            mix.inputs["A"].default_value = col
            gray = nt.nodes.new("ShaderNodeRGBToBW")
            nt.links.new(tex.outputs["Color"], gray.inputs["Color"])
            bright = nt.nodes.new("ShaderNodeMath")
            bright.operation = "MULTIPLY"
            bright.inputs[1].default_value = 1.8
            nt.links.new(gray.outputs["Val"], bright.inputs[0])
            nt.links.new(bright.outputs["Value"], mix.inputs["B"])
            nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.9


def ground(cfg):
    """Meydan (kaldırım taşı) ve çevresi (toprak), arkada tepe."""
    bpy.ops.mesh.primitive_plane_add(size=120, location=(0, 25, 0))
    g = bpy.context.object
    g.name = "ground"
    m = bpy.data.materials.new("ground_mat")
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.25, 0.25, 0.25)
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    cob = _tex_node(nt, os.path.join(TEX, "PavingStones119/PavingStones119_1K-JPG_Color.jpg"), mp)
    dirt = _tex_node(nt, os.path.join(TEX, "Ground106/Ground106_1K-JPG_Color.jpg"), mp)
    # Meydan dairesi: merkezden uzaklık maskesi.
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Object"], sep.inputs["Vector"])
    plaza = cfg.get("plaza", [0.0, 6.0, 9.0])
    dx = nt.nodes.new("ShaderNodeMath"); dx.operation = "SUBTRACT"; dx.inputs[1].default_value = plaza[0] - 0.0
    nt.links.new(sep.outputs["X"], dx.inputs[0])
    dy = nt.nodes.new("ShaderNodeMath"); dy.operation = "SUBTRACT"; dy.inputs[1].default_value = plaza[1] - 25.0
    nt.links.new(sep.outputs["Y"], dy.inputs[0])
    cmb = nt.nodes.new("ShaderNodeCombineXYZ")
    nt.links.new(dx.outputs[0], cmb.inputs["X"]); nt.links.new(dy.outputs[0], cmb.inputs["Y"])
    ln = nt.nodes.new("ShaderNodeVectorMath"); ln.operation = "LENGTH"
    nt.links.new(cmb.outputs[0], ln.inputs[0])
    ramp = nt.nodes.new("ShaderNodeMapRange")
    ramp.inputs["From Min"].default_value = plaza[2] * 0.85
    ramp.inputs["From Max"].default_value = plaza[2] * 1.15
    nt.links.new(ln.outputs["Value"], ramp.inputs["Value"])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"
    nt.links.new(ramp.outputs["Result"], mix.inputs["Factor"])
    nt.links.new(cob.outputs["Color"], mix.inputs["A"])
    nt.links.new(dirt.outputs["Color"], mix.inputs["B"])
    out = _tint_and_snow(nt, mix.outputs["Result"], tc, cfg.get("ground_tint"), cfg.get("snow", 0.0), 0.15)
    nt.links.new(out, bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.95
    g.data.materials.append(m)
    # Arka tepe: kasabanın arkasında yükselen, kalenin oturduğu sırt.
    hill = cfg.get("hill")
    if hill:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=hill["at"])
        h = bpy.context.object
        h.scale = hill["scale"]
        # Pürüzsüz kubbe yapay okunuyor: alçak frekanslı gürültüyle sırt
        # kırılır, tepe sivrilir - kayalık bir sırt gibi.
        bpy.ops.object.modifier_add(type="SUBSURF")
        h.modifiers[-1].levels = 2
        h.modifiers[-1].render_levels = 3
        tx = bpy.data.textures.new("hill_noise", "CLOUDS")
        tx.noise_scale = hill.get("rough_scale", 0.35)
        tx.noise_depth = 3
        bpy.ops.object.modifier_add(type="DISPLACE")
        h.modifiers[-1].texture = tx
        h.modifiers[-1].strength = hill.get("rough", 0.35)
        rm = bpy.data.materials.new("hill_mat")
        rn = rm.node_tree
        rb = rn.nodes["Principled BSDF"]
        tc2 = rn.nodes.new("ShaderNodeTexCoord"); mp2 = rn.nodes.new("ShaderNodeMapping")
        mp2.inputs["Scale"].default_value = (0.08, 0.08, 0.08)
        rn.links.new(tc2.outputs["Object"], mp2.inputs["Vector"])
        rt = _tex_node(rn, os.path.join(TEX, "Rock064/Rock064_1K-JPG_Color.jpg"), mp2)
        rout = _tint_and_snow(rn, rt.outputs["Color"], tc2, hill.get("tint"), hill.get("snow", 0.0), 0.08, True)
        rn.links.new(rout, rb.inputs["Base Color"])
        h.data.materials.append(rm)


def _tint_and_snow(nt, colour, tc, tint, snow, scale, cap=False):
    """Bir doku rengini şehrin tonuna çarpar; `snow` > 0 ise gürültüyle
    (tepede yüksekliğe göre de) beyaza çeker - Kurtboğazı'nın karı."""
    out = colour
    if tint:
        mul = nt.nodes.new("ShaderNodeMix"); mul.data_type = "RGBA"; mul.blend_type = "MULTIPLY"
        mul.inputs["Factor"].default_value = 1.0
        nt.links.new(out, mul.inputs["A"])
        mul.inputs["B"].default_value = list(tint) + [1.0]
        out = mul.outputs["Result"]
    if snow > 0.0:
        noise = nt.nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 1.0 / max(scale, 1e-3) * 0.08
        nt.links.new(tc.outputs["Object"], noise.inputs["Vector"])
        fac = nt.nodes.new("ShaderNodeMapRange")
        fac.inputs["From Min"].default_value = 0.55 - snow * 0.35
        fac.inputs["From Max"].default_value = 0.62 - snow * 0.25
        nt.links.new(noise.outputs["Fac"], fac.inputs["Value"])
        last = fac.outputs["Result"]
        if cap:
            sep = nt.nodes.new("ShaderNodeSeparateXYZ")
            nt.links.new(tc.outputs["Object"], sep.inputs["Vector"])
            hz = nt.nodes.new("ShaderNodeMapRange")
            hz.inputs["From Min"].default_value = 0.1
            hz.inputs["From Max"].default_value = 0.45
            nt.links.new(sep.outputs["Z"], hz.inputs["Value"])
            mx = nt.nodes.new("ShaderNodeMath"); mx.operation = "MAXIMUM"
            nt.links.new(last, mx.inputs[0]); nt.links.new(hz.outputs["Result"], mx.inputs[1])
            last = mx.outputs[0]
        soft = nt.nodes.new("ShaderNodeMath"); soft.operation = "MULTIPLY"
        soft.inputs[1].default_value = 0.8
        nt.links.new(last, soft.inputs[0])
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"
        nt.links.new(soft.outputs[0], mix.inputs["Factor"])
        nt.links.new(out, mix.inputs["A"])
        mix.inputs["B"].default_value = (0.72, 0.75, 0.8, 1.0)
        out = mix.outputs["Result"]
    return out


def wall_row(spec):
    """Sur: `from`-`to` arasında Kenney taş duvar parçaları, aralıklı
    burçlar; `gate` payındaki parça kemer olur (Demirkapı'nın kapısı)."""
    (x0, y0), (x1, y1) = spec["from"], spec["to"]
    size = spec.get("size", 2.0)
    z = spec.get("z", 0.0)
    tag = spec.get("venue", "")
    length = math.hypot(x1 - x0, y1 - y0)
    n = max(1, int(length / size))
    ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
    gate = spec.get("gate", -1.0)
    for i in range(n):
        t = (i + 0.5) / n
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        kind = "wall-arch" if gate >= 0 and abs(t - gate) < 0.5 / n else spec.get("piece", "wall")
        for f in range(spec.get("floors", 2)):
            k = kind if f == 0 else "wall-block"
            dark = _stone_material("wall_dark", spec.get("value", 0.3))
            place(ftk(k), (x, y, z + f * size), ang + spec.get("rot", 0.0), size, tag if kind == "wall-arch" else spec.get("wall_tag", ""), dark)
        if spec.get("towers") and i % spec["towers"] == 0:
            spire_tower(x, y + 0.2, z, spec.get("floors", 2) + 2, size * 0.9, spec.get("wall_tag", ""),
                mats=_stone_material("wall_dark", spec.get("value", 0.3)))


def sky(cfg):
    """Gökyüzü: tepede neredeyse siyah, ufukta boğuk bir ışık bandı."""
    w = bpy.data.worlds.new("sky")
    bpy.context.scene.world = w
    nt = w.node_tree
    bg = nt.nodes["Background"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Generated"], sep.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    cols = cfg["sky"]
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = cols["horizon"] + [1.0]
    ramp.color_ramp.elements[1].position = cols.get("height", 0.22)
    ramp.color_ramp.elements[1].color = cols["zenith"] + [1.0]
    nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = cols.get("strength", 1.0)


def lights(cfg):
    sc = bpy.context.scene
    moon = bpy.data.lights.new("moon", "SUN")
    moon.energy = cfg.get("moon", 0.6)
    moon.color = cfg.get("moon_color", (0.62, 0.66, 0.9))
    moon.angle = math.radians(4)
    mo = bpy.data.objects.new("moon", moon)
    mo.rotation_euler = Euler((math.radians(55), 0, math.radians(200)))
    sc.collection.objects.link(mo)
    # Arka ışık: tepenin arkasından, siluetleri ayıran boğuk kor.
    back = bpy.data.lights.new("back", "SUN")
    back.energy = cfg.get("backlight", 1.2)
    back.color = cfg.get("backlight_color", (1.0, 0.55, 0.3))
    bo = bpy.data.objects.new("back", back)
    bo.rotation_euler = Euler((math.radians(100), 0, math.radians(180)))
    sc.collection.objects.link(bo)
    for entry in cfg.get("lamps", []):
        lx, ly, lz, e = entry[:4]
        lamp = bpy.data.lights.new("lamp", "POINT")
        lamp.energy = e
        lamp.color = entry[4] if len(entry) > 4 else (1.0, 0.62, 0.3)
        lamp.shadow_soft_size = 0.3
        lo = bpy.data.objects.new("lamp", lamp)
        lo.location = (lx, ly, lz)
        sc.collection.objects.link(lo)


def camera(cfg):
    cam = bpy.data.cameras.new("cam")
    cam.lens = cfg["camera"].get("lens", 32)
    co = bpy.data.objects.new("cam", cam)
    co.location = cfg["camera"]["at"]
    target = Vector(cfg["camera"]["look"])
    d = target - Vector(co.location)
    co.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.collection.objects.link(co)
    bpy.context.scene.camera = co


# ---------------------------------------------------------------- render

def render_beauty(path, samples, pct):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x = 1920
    sc.render.resolution_y = 1080
    sc.render.resolution_percentage = pct
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Medium High Contrast"
    sc.render.use_freestyle = True
    sc.render.line_thickness_mode = "ABSOLUTE"
    sc.render.line_thickness = max(1.0, 2.4 * pct / 100.0)
    sc.render.film_transparent = True
    sc.render.image_settings.color_mode = "RGBA"
    fss = sc.view_layers[0].freestyle_settings
    fs = fss.linesets[0] if len(fss.linesets) else fss.linesets.new("ink")
    if fs.linestyle is None:
        fs.linestyle = bpy.data.linestyles.new("ink")
    ls = fs.linestyle
    ls.color = (0.02, 0.015, 0.02)
    ls.thickness = 1.6
    fs.select_by_visibility = True
    fs.select_silhouette = True
    fs.select_border = True
    fs.select_crease = True
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def render_ids(path, pct):
    """Mekân maskeleri: her mekânın nesneleri kendi düz rengiyle, kalan her
    şey siyah. Cycles, tek örnek, ışıksız emisyon, piksel süzgeci en dar -
    renk bir kimliktir, yumuşatılmamalı. (Workbench GPU istiyor, burada yok.)"""
    sc = bpy.context.scene
    sc.render.use_freestyle = False
    sc.render.film_transparent = False
    sc.render.image_settings.color_mode = "RGB"
    sc.cycles.samples = 1
    sc.cycles.use_denoising = False
    sc.cycles.filter_width = 0.01
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
    m = bpy.data.materials.new("id_mat")
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    info = nt.nodes.new("ShaderNodeObjectInfo")
    em = nt.nodes.new("ShaderNodeEmission")
    outn = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(info.outputs["Color"], em.inputs["Color"])
    nt.links.new(em.outputs["Emission"], outn.inputs["Surface"])
    sc.view_layers[0].material_override = m
    for o in sc.objects:
        if o.type == "LIGHT":
            o.hide_render = True
        if o.type != "MESH":
            continue
        tag = o.get("venue", "")
        o.color = VENUE_IDS.get(tag, (0.0, 0.0, 0.0)) + (1.0,)
    sc.render.resolution_percentage = pct
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def render_depth(path, pct, far):
    """Kamera uzaklığı griye: 0 yakın, 1 `far` ve ötesi. Sis ve kademeli
    mürekkep için. Kimlik geçişinin aynı yolu (emisyon, ışıksız)."""
    sc = bpy.context.scene
    m = bpy.data.materials.new("depth_mat")
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    cam = nt.nodes.new("ShaderNodeCameraData")
    rng = nt.nodes.new("ShaderNodeMapRange")
    rng.inputs["From Min"].default_value = 0.0
    rng.inputs["From Max"].default_value = far
    em = nt.nodes.new("ShaderNodeEmission")
    outn = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(cam.outputs["View Distance"], rng.inputs["Value"])
    nt.links.new(rng.outputs["Result"], em.inputs["Color"])
    nt.links.new(em.outputs["Emission"], outn.inputs["Surface"])
    sc.view_layers[0].material_override = m
    sc.render.film_transparent = False
    sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
    sc.render.image_settings.color_mode = "BW"
    sc.render.image_settings.color_depth = "16"
    sc.render.resolution_percentage = pct
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def build(city):
    cfg = json.load(open(CFG))[city]
    reset()
    random.seed(cfg.get("seed", 1))
    sky(cfg)
    ground(cfg)
    for spec in cfg["buildings"]:
        building(spec)
    for spec in cfg.get("props", []):
        building(spec)
    texture_materials(tuple(cfg.get("window", [1.0, 0.55, 0.22])) + (1.0,))
    lights(cfg)
    camera(cfg)
    return cfg


def main(argv):
    city = argv[argv.index("--city") + 1]
    samples = int(argv[argv.index("--samples") + 1]) if "--samples" in argv else 64
    pct = int(argv[argv.index("--scale") + 1]) if "--scale" in argv else 100
    out = os.path.join(OUT, "town_" + city)
    os.makedirs(out, exist_ok=True)
    cfg = build(city)
    render_beauty(os.path.join(out, "beauty.png"), samples, pct)
    render_ids(os.path.join(out, "ids.png"), pct)
    render_depth(os.path.join(out, "depth.png"), pct, cfg.get("far", 70.0))
    json.dump({"city": city, "venues": list(VENUE_IDS)}, open(os.path.join(out, "meta.json"), "w"))
    print("BITTI", out)


if __name__ == "__main__":
    main(sys.argv)
