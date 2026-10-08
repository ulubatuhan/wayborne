"""Faz 1 ortak gölgelendirme (Blender/Cycles). Tek malzeme, uc mod:

- "full":       tum govde, backface culling acik.
- "layer:<ad>": yalniz o katman KAMERAYA gorunur; geri kalan yuzeyler kamera
                isinlarinda saydam ama golge/isik isinlarinda opak (holdout yok,
                "diger katmanlar kameraya gorunmez ama golge ve isiga katilir").
- "magenta":    backface culling yerine ic yuzler duz magenta (no_backfaces testi);
                katman secimi "magenta:<ad>" ile ayni kurallarla.

Backface culling: Cycles malzeme ayarini (use_backface_culling) yalniz viewport'ta
okur; render'da kullanilmaz. Bu yuzden kamera isini arka yuze carptiginda yuzey
Transparent BSDF olur (isin devam eder) - golge isinlari etkilenmez.

Katman uyeligi NOKTA basina: "lw" renk ozniteligi (vertex basina RGBA =
w_back_arm, w_back_leg, w_front_leg, w_front_arm) yuzey uzerinde enterpole edilir
ve esik orada uygulanir (config/layers.json: uzuv w>=0.02; torso_head: tum uzuv
w<0.5). Mask modifier yuz bazinda keser ve testere kenar uretir (POSTMORTEM).

Isik deterministik: gunes (aci 0, keskin golge) + emisyon olarak ortam terimi,
dolayli sekme yok. Ayni piksel ayni yuzeye carparsa her render'da ayni deger.
"""
import math

import bpy

LIMB_CHANNEL = {"back_arm": 0, "back_leg": 1, "front_leg": 2, "front_arm": 3}


def setup_render(cfg):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = int(cfg["samples"])
    sc.cycles.seed = int(cfg["seed"])
    sc.cycles.use_denoising = False
    sc.cycles.use_adaptive_sampling = False
    sc.cycles.max_bounces = int(cfg["max_bounces"])
    sc.cycles.diffuse_bounces = 0
    sc.cycles.glossy_bounces = 0
    sc.cycles.transmission_bounces = 0
    sc.cycles.volume_bounces = 0
    sc.cycles.transparent_max_bounces = int(cfg["transparent_max_bounces"])
    sc.cycles.pixel_filter_type = cfg["pixel_filter"]
    sc.cycles.filter_width = float(cfg["filter_width"])
    sc.render.film_transparent = bool(cfg["film_transparent"])
    sc.render.resolution_x, sc.render.resolution_y = cfg["canvas"]
    sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.image_settings.color_depth = "8"
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    world = bpy.data.worlds.new("fig_world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.0
    sc.world = world

    lt = cfg["lighting"]
    sun_data = bpy.data.lights.new("fig_sun", "SUN")
    sun_data.energy = float(lt["sun_energy"])
    sun_data.angle = math.radians(float(lt["sun_angle_deg"]))
    sun = bpy.data.objects.new("fig_sun", sun_data)
    sc.collection.objects.link(sun)
    sun.rotation_euler = tuple(math.radians(a) for a in lt["sun_rotation_euler_deg"])
    return sc


def setup_camera(cfg, ground_world_y=0.0, ground_world_z=0.0):
    """Ortografik yan kamera. Dunya (y=ground_world_y, z=ground_world_z) noktasi
    cfg['ground_px'] pikseline duser; olcek cfg['px_per_meter']."""
    sc = bpy.context.scene
    w, h = cfg["canvas"]
    ppm = float(cfg["px_per_meter"])
    cd = bpy.data.cameras.new("fig_cam")
    cd.type = "ORTHO"
    cd.ortho_scale = max(w, h) / ppm  # Blender ortho_scale'i BUYUK eksene uygular
    cd.sensor_fit = "AUTO"
    cam = bpy.data.objects.new("fig_cam", cd)
    sc.collection.objects.link(cam)
    gx, gy = cfg["ground_px"]
    # Ekran sagi = dunya -Y, ekran yukari = dunya +Z (config/camera.json).
    # Kamera merkezi (w/2, h/2) pikseline bakar.
    cy_world = ground_world_y - (w / 2.0 - gx) / ppm
    cz_world = ground_world_z + (gy - h / 2.0) / ppm
    cam.location = (float(cfg["camera_location_x"]), cy_world, cz_world)
    cam.rotation_euler = tuple(math.radians(a) for a in cfg["rotation_euler_deg"])
    sc.camera = cam
    return cam


def world_to_px(cfg, y, z, ground_world_y=0.0, ground_world_z=0.0):
    ppm = float(cfg["px_per_meter"])
    gx, gy = cfg["ground_px"]
    return gx + (-(y - ground_world_y)) * ppm, gy - (z - ground_world_z) * ppm


def body_material(cfg, mode, layer_attr="lw", core=0.5, root=0.02, garment_attr="gw",
                  alpha_image=None, alpha_cutoff=0.5, name_suffix=""):
    """mode: "full" | "layer:<ad>" | "magenta[:<ad>]" | "id[:<ad>]".
    "id": isiksiz emisyon, renk = garment_attr'in kanallari keskin esikle (>0.5)
    - (atlet/bra, sort, sac). Kapsama ayni ornek desenini kullanir, yani
    oyundaki giysi katmaninin alfasi = bu render'in kanali x alfa.
    alpha_image: sac kartlari icin doku alfasi; esigin altinda kalan yuzey
    TUM isinlara saydam (golge de dusurmez)."""
    lt = cfg["lighting"]
    alb = float(lt["albedo"])
    mat = bpy.data.materials.new("fig_body_" + mode.replace(":", "_") + name_suffix)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    N = nt.nodes.new
    L = nt.links.new
    out = N("ShaderNodeOutputMaterial")
    diff = N("ShaderNodeBsdfDiffuse")
    diff.inputs["Color"].default_value = (alb, alb, alb, 1.0)
    emit = N("ShaderNodeEmission")
    emit.inputs["Color"].default_value = (alb, alb, alb, 1.0)
    emit.inputs["Strength"].default_value = float(lt["ambient_as_emission"])
    lit = N("ShaderNodeAddShader")
    L(diff.outputs[0], lit.inputs[0])
    L(emit.outputs[0], lit.inputs[1])

    geo = N("ShaderNodeNewGeometry")
    lp = N("ShaderNodeLightPath")
    transp = N("ShaderNodeBsdfTransparent")

    # back = arka yuz VE kamera isini
    back = N("ShaderNodeMath"); back.operation = "MULTIPLY"
    L(geo.outputs["Backfacing"], back.inputs[0])
    L(lp.outputs["Is Camera Ray"], back.inputs[1])

    kind, _, layer = mode.partition(":")
    if kind == "id":
        gattr = N("ShaderNodeAttribute"); gattr.attribute_name = garment_attr
        gsep = N("ShaderNodeSeparateColor")
        L(gattr.outputs["Color"], gsep.inputs[0])
        gcomb = N("ShaderNodeCombineColor")
        for k in range(3):
            th = N("ShaderNodeMath"); th.operation = "GREATER_THAN"
            L(gsep.outputs[k], th.inputs[0]); th.inputs[1].default_value = 0.5
            L(th.outputs[0], gcomb.inputs[k])
        idem = N("ShaderNodeEmission")
        idem.inputs["Strength"].default_value = 1.0
        L(gcomb.outputs[0], idem.inputs["Color"])
        lit = idem
    # 1) arka yuz: kamera isininda saydam (culling) ya da magenta (test modu)
    mix_b = N("ShaderNodeMixShader")
    L(back.outputs[0], mix_b.inputs[0])
    L(lit.outputs[0], mix_b.inputs[1])
    if kind == "magenta":
        mag = N("ShaderNodeEmission")
        mag.inputs["Color"].default_value = (1.0, 0.0, 1.0, 1.0)
        mag.inputs["Strength"].default_value = 1.0
        L(mag.outputs[0], mix_b.inputs[2])
    else:
        L(transp.outputs[0], mix_b.inputs[2])
    surface = mix_b.outputs[0]

    # 2) katman disi her nokta (on ya da arka yuz) kamera isininda saydam
    if layer:
        attr = N("ShaderNodeAttribute"); attr.attribute_name = layer_attr
        sep = N("ShaderNodeSeparateColor")
        L(attr.outputs["Color"], sep.inputs[0])
        chans = [sep.outputs[0], sep.outputs[1], sep.outputs[2], attr.outputs["Alpha"]]
        if layer == "torso_head":
            mx = chans[0]
            for c in chans[1:]:
                m = N("ShaderNodeMath"); m.operation = "MAXIMUM"
                L(mx, m.inputs[0]); L(c, m.inputs[1]); mx = m.outputs[0]
            vis = N("ShaderNodeMath"); vis.operation = "LESS_THAN"
            L(mx, vis.inputs[0]); vis.inputs[1].default_value = core
        else:
            vis = N("ShaderNodeMath"); vis.operation = "GREATER_THAN"
            L(chans[LIMB_CHANNEL[layer]], vis.inputs[0]); vis.inputs[1].default_value = root - 1e-6
        hide = N("ShaderNodeMath"); hide.operation = "SUBTRACT"
        hide.inputs[0].default_value = 1.0
        L(vis.outputs[0], hide.inputs[1])
        hide_cam = N("ShaderNodeMath"); hide_cam.operation = "MULTIPLY"
        L(hide.outputs[0], hide_cam.inputs[0]); L(lp.outputs["Is Camera Ray"], hide_cam.inputs[1])
        mix_l = N("ShaderNodeMixShader")
        L(hide_cam.outputs[0], mix_l.inputs[0])
        L(surface, mix_l.inputs[1]); L(transp.outputs[0], mix_l.inputs[2])
        surface = mix_l.outputs[0]

    if alpha_image is not None:
        tex = N("ShaderNodeTexImage"); tex.image = alpha_image
        cut = N("ShaderNodeMath"); cut.operation = "LESS_THAN"
        L(tex.outputs["Alpha"], cut.inputs[0]); cut.inputs[1].default_value = alpha_cutoff
        mix_a = N("ShaderNodeMixShader")
        L(cut.outputs[0], mix_a.inputs[0])
        L(surface, mix_a.inputs[1]); L(transp.outputs[0], mix_a.inputs[2])
        surface = mix_a.outputs[0]

    L(surface, out.inputs["Surface"])
    return mat
