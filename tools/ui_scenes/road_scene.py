"""Yol ekranının paralaks katmanları, biyom başına, şehirlerle aynı hattan.

    python3 tools/ui_scenes/road_scene.py --biome forest [--samples 32] [--layers far,mid,ground,fore]

Her katman **yatayda dikişsiz döşenen** bir şerit: sahnedeki her şey x'te
L periyotlu (yükseklik alanı tam sayı frekanslı sinüslerin toplamı, her nesne
x-L ve x+L'de de var) ve ortografik kamera tam L genişliğinde bakıyor - yani
şeridin sağ kenarı sol kenarının devamı. Oyun şeridi kaydırıp yan yana
dizerek sonsuz bir yol çiziyor (TravelBand), "manzara listeden değil dünya
koordinatından üretilir" kuralının resimli hâli: aynı şerit tekrar etse de
dört katman dört ayrı periyotta döndüğü için tekrar okunmuyor.

Katmanlar (uzaktan yakına):
  far     sırtlar ve dağlar, yandan
  mid     ağaçlar, kayalar; zemin gölge yakalayıcı (yalnızca gölge)
  ground  zemin ve yol, eğik bakış; yolun merkezi bilinen bir satırda
  fore    yolun önündeki çalı, taş, ot; gölge yakalayıcı

Gün saati burada yok: katmanlar nötr gün ışığında render ediliyor, oyun
onları evrenin ışığıyla çarpıyor (TravelBand.get_light) - şafak, gece ve
yağmur sistemin kendisi olarak kalıyor.

Çıktı: build/ui_scenes/road_<biome>/<layer>.png ve layout.json; son işleme
road_post.py.
"""
import json
import math
import os
import random
import sys
import zlib

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_scene as T  # noqa: E402  (aynı yükleyici, aynı dokular)

OUT = os.path.join(T.ROOT, "build/ui_scenes")
TEX_W = 2048

# Katman: dünya periyodu L (metre), kamera eğimi, kare yüksekliği (piksel),
# bağlantı noktası (y derinliği, z) ve onun karedeki yeri (alttan pay).
LAYERS = {
    # Alçak kamera (Oregon Trail düzeni): yol ekranın ortasında bir bant,
    # arkasında yol kenarı otu ve ağaçlar, önünde kameraya yakın bir ot
    # tarlası. Eğimler bu yüzden küçük - zemin yukarıdan değil, diz
    # hizasından görülüyor.
    "far": {"L": 360.0, "tilt": 2.0, "h": 512, "anchor_y": 0.0, "anchor_v": 0.12},
    "mid": {"L": 120.0, "tilt": 4.0, "h": 640, "anchor_y": 0.0, "anchor_v": 0.12},
    "ground": {"L": 40.0, "tilt": 12.0, "h": 384, "anchor_y": 5.5, "anchor_v": 0.45},
    "fore": {"L": 16.0, "tilt": 8.0, "h": 512, "anchor_y": 0.0, "anchor_v": 0.85},
}

# Zeminin uzak kenarı (dünya y'si): yolun arkasındaki ot bandı burada biter,
# ötesi orta katmanın ağaçları.
GROUND_FAR_Y = 18.0

# Kasvetli palet: doygunluk düşük, yeşiller zeytin ve kurşuna, çiçekler
# pas ve soluk kemik rengi. Işık oyundan geliyor (saat, hava).
BIOMES = {
    "steppe": {
        "far": {"amp": 16.0, "base": 4.0, "freqs": [2, 3, 5], "tint": [0.56, 0.52, 0.44], "trees": 0},
        "ground_tex": "Ground106", "ground_tint": [0.70, 0.62, 0.46], "grass": [0.52, 0.48, 0.30],
        "trees": [("leafy", 0.45), ("dead", 0.55)], "tree_count": 9, "tree_h": (6.0, 9.0),
        "rocks": 0.5, "tufts": 14, "water": False, "snow": 0.0,
        "flowers": [(0.62, 0.34, 0.18), (0.70, 0.64, 0.52)],
    },
    "forest": {
        "far": {"amp": 24.0, "base": 8.0, "freqs": [2, 3, 7], "tint": [0.34, 0.38, 0.34], "trees": 90},
        "ground_tex": "Ground106", "ground_tint": [0.46, 0.50, 0.38], "grass": [0.30, 0.36, 0.22],
        "trees": [("leafy", 0.5), ("conifer", 0.4), ("dead", 0.1)], "tree_count": 26, "tree_h": (8.0, 14.0),
        "rocks": 0.4, "tufts": 18, "water": False, "snow": 0.0,
        "flowers": [(0.58, 0.30, 0.18), (0.56, 0.54, 0.60)],
    },
    "mountain": {
        "far": {"amp": 70.0, "base": 18.0, "freqs": [2, 3, 5, 9], "tint": [0.52, 0.53, 0.56], "snow": 0.7},
        "ground_tex": "Ground106", "ground_tint": [0.62, 0.60, 0.56], "rock_tint": [0.55, 0.55, 0.57],
        "grass": [0.38, 0.40, 0.32],
        "trees": [("conifer", 0.8), ("dead", 0.2)], "tree_count": 14, "tree_h": (8.0, 13.0),
        "rocks": 1.4, "tufts": 10, "water": False, "snow": 0.0,
        "flowers": [(0.66, 0.66, 0.66)],
    },
    "lake": {
        "far": {"amp": 14.0, "base": 4.0, "freqs": [2, 5], "tint": [0.44, 0.50, 0.52], "water": True, "trees": 40},
        "ground_tex": "Ground106", "ground_tint": [0.54, 0.58, 0.48], "grass": [0.34, 0.42, 0.32],
        "trees": [("leafy", 0.7), ("dead", 0.3)], "tree_count": 12, "tree_h": (7.0, 11.0),
        "rocks": 0.5, "tufts": 16, "water": False, "snow": 0.0,
        "flowers": [(0.54, 0.50, 0.62), (0.64, 0.36, 0.22)],
    },
    "marsh": {
        "far": {"amp": 9.0, "base": 2.0, "freqs": [3, 4], "tint": [0.38, 0.40, 0.34], "water": True, "trees": 25},
        "ground_tex": "Ground106", "ground_tint": [0.42, 0.42, 0.32], "grass": [0.34, 0.36, 0.22],
        "trees": [("dead", 0.7), ("leafy", 0.3)], "tree_count": 12, "tree_h": (5.0, 9.0),
        "rocks": 0.2, "tufts": 26, "water": True, "snow": 0.0,
        "flowers": [(0.60, 0.58, 0.50)],
    },
}


# ---------------------------------------------------------------- yardımcılar

def wrapped(x, L):
    """Bir nesnenin x'i ve iki komşu kopyası - kenardan taşan yarısı karşı
    kenarda görünsün diye."""
    return [x - L, x, x + L]


def place_wrapped(path, x, y, z, rot, scale, L, mats=None):
    for xx in wrapped(x, L):
        T.place(path, (xx, y, z), rot, scale, mats=mats)


def rock_material(b):
    """Kayalar paketin açık gri düz renginde beyaz diş gibi duruyordu;
    biyomun taşıyla dokulu ve koyu."""
    m = bpy.data.materials.get("road_rock")
    if m is None:
        tint = b.get("rock_tint", [0.42, 0.40, 0.38])
        m = material("road_rock", tint, tex="Rock064", scale=0.6, tint=tint)
        m.name = "road_rock"
    return m


def material(name, rgb, rough=0.95, tex=None, scale=0.25, tint=None, snow=0.0, L=None, cap=False,
             cap_range=(0.1, 0.45), noise_scale=None):
    """Dokulu malzeme. `L` verilirse doku x'te L periyotlu döşeniyor: resim
    dokusunun tekrarı L'ye tam sayı kez sığacak şekilde ölçek yuvarlanıyor,
    kar gürültüsü de x'i bir çembere sarıp okuyor - yoksa şeridin iki kenarı
    birbirini tutmaz ve oyunda her döşemede bir dikiş görünür."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True  # Blender 4.2: varsayılan kapalı
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rough
    if tex:
        if L:
            scale = max(1, round(L * scale)) / L
        tc = nt.nodes.new("ShaderNodeTexCoord")
        mp = nt.nodes.new("ShaderNodeMapping")
        mp.inputs["Scale"].default_value = (scale, scale, scale)
        nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
        t = T._tex_node(nt, os.path.join(T.TEX, tex, tex + "_1K-JPG_Color.jpg"), mp)
        out = T._tint_and_snow(nt, t.outputs["Color"], tc, tint, 0.0 if L else snow, scale, cap=cap)
        if L and snow > 0.0:
            out = _periodic_snow(nt, out, tc, L, snow, scale, cap, cap_range, noise_scale)
        nt.links.new(out, bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = list(rgb) + [1.0]
    return m


def _math(nt, op, a, b=None):
    n = nt.nodes.new("ShaderNodeMath")
    n.operation = op
    for i, v in enumerate((a, b)):
        if v is None:
            continue
        if isinstance(v, (int, float)):
            n.inputs[i].default_value = v
        else:
            nt.links.new(v, n.inputs[i])
    return n.outputs[0]


def _periodic_snow(nt, colour, tc, L, snow, scale, cap, cap_range=(0.1, 0.45), noise_scale=None):
    """town_scene._tint_and_snow'un karı, ama gürültü (R cos θ, R sin θ, y)
    noktasında okunuyor (θ = 2πx/L, R = L/2π): x'te tam L periyotlu ve aynı
    ölçekte."""
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Object"], sep.inputs["Vector"])
    theta = _math(nt, "MULTIPLY", sep.outputs["X"], 2.0 * math.pi / L)
    r = L / (2.0 * math.pi)
    comb = nt.nodes.new("ShaderNodeCombineXYZ")
    nt.links.new(_math(nt, "MULTIPLY", _math(nt, "COSINE", theta), r), comb.inputs["X"])
    nt.links.new(_math(nt, "MULTIPLY", _math(nt, "SINE", theta), r), comb.inputs["Y"])
    # Yükseklik de giriyor: dağın yüzü neredeyse dik, yalnızca y okunursa
    # gürültü dikey çizgilere uzuyordu.
    nt.links.new(_math(nt, "ADD", sep.outputs["Y"], sep.outputs["Z"]), comb.inputs["Z"])
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = noise_scale if noise_scale else 1.0 / max(scale, 1e-3) * 0.08
    nt.links.new(comb.outputs["Vector"], noise.inputs["Vector"])
    fac = nt.nodes.new("ShaderNodeMapRange")
    fac.inputs["From Min"].default_value = 0.55 - snow * 0.35
    fac.inputs["From Max"].default_value = 0.62 - snow * 0.25
    nt.links.new(noise.outputs["Fac"], fac.inputs["Value"])
    last = fac.outputs["Result"]
    if cap:
        # Dağda kar yalnızca tepede: kar çizgisi gürültüyle kırılıyor, ama
        # alçaktaki yamaçta gürültü tek başına kar açmıyor (benekli oluyordu).
        span = cap_range[1] - cap_range[0]
        wob = _math(nt, "MULTIPLY", _math(nt, "SUBTRACT", noise.outputs["Fac"], 0.5), span * 1.4)
        hz = nt.nodes.new("ShaderNodeMapRange")
        hz.inputs["From Min"].default_value = cap_range[0]
        hz.inputs["From Max"].default_value = cap_range[1]
        nt.links.new(_math(nt, "ADD", sep.outputs["Z"], wob), hz.inputs["Value"])
        last = hz.outputs["Result"]
    soft = _math(nt, "MULTIPLY", last, 0.8)
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    nt.links.new(soft, mix.inputs["Factor"])
    nt.links.new(colour, mix.inputs["A"])
    mix.inputs["B"].default_value = (0.72, 0.75, 0.8, 1.0)
    return mix.outputs["Result"]


def heightfield(name, L, y0, y1, nx, ny, fn, mat, warp=None):
    """x'te [-L, 2L), y'de [y0, y1] bir ızgara; z = fn(x, y). fn x'te L
    periyotlu olmalı. `warp(x, t)` satırın y'sine eklenir (t: 0 yakın kenar,
    1 uzak kenar) - cetvelle çizilmiş düz bir kenar yerine dalgalı bir kenar."""
    verts, faces = [], []
    for j in range(ny + 1):
        t = j / ny
        for i in range(nx + 1):
            x = -L + 3.0 * L * i / nx
            y = y0 + (y1 - y0) * t + (warp(x, t) if warp else 0.0)
            verts.append((x, y, fn(x, y)))
    for j in range(ny):
        for i in range(nx):
            a = j * (nx + 1) + i
            faces.append((a, a + 1, a + nx + 2, a + nx + 1))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    for p in me.polygons:
        p.use_smooth = True
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    o.data.materials.append(mat)
    return o


def periodic(L, freqs, seed):
    rng = random.Random(seed)
    terms = [(k, rng.random() * math.tau, 1.0 / (1 + i)) for i, k in enumerate(freqs)]
    norm = sum(a for _, _, a in terms)

    def f(x):
        return sum(a * math.sin(k * math.tau * x / L + p) for k, p, a in terms) / norm
    return f


def tuft(name, x, y, height, colour, mat_cache, rng):
    """Bir ot öbeği: ince, eğik üçgen yapraklar."""
    key = tuple(round(c, 2) for c in colour)
    if key not in mat_cache:
        mat_cache[key] = material("tuft_%d" % len(mat_cache), colour, 0.9)
    verts, faces = [], []
    for b in range(7):
        a = rng.uniform(-0.7, 0.7)
        w = height * 0.06
        bx = rng.uniform(-0.25, 0.25) * height
        by = rng.uniform(-0.15, 0.15) * height
        h = height * rng.uniform(0.6, 1.0)
        base = len(verts)
        verts += [(x + bx - w, y + by, 0.0), (x + bx + w, y + by, 0.0),
                  (x + bx + math.sin(a) * h * 0.6, y + by + 0.02, h)]
        faces.append((base, base + 1, base + 2))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    o.data.materials.append(mat_cache[key])
    return o


def shadow_catcher(L, y0, y1):
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(L / 2.0, (y0 + y1) / 2.0, 0.0))
    p = bpy.context.object
    p.scale = (L * 3.0, (y1 - y0), 1.0)
    p.is_shadow_catcher = True


def light_rig():
    w = bpy.data.worlds.new("road_sky")
    w.use_nodes = True  # Blender 4.2: varsayılan kapalı
    bpy.context.scene.world = w
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.58, 0.64, 1.0)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.55
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 1.9
    sun.color = (1.0, 0.95, 0.86)
    sun.angle = math.radians(3)
    so = bpy.data.objects.new("sun", sun)
    so.rotation_euler = (math.radians(52), math.radians(-18), math.radians(-28))
    bpy.context.scene.collection.objects.link(so)


def camera(spec, res_y):
    """Ortografik, tam L genişliğinde. Bağlantı noktası (x=L/2, anchor_y, 0)
    karede alttan anchor_v payına düşecek şekilde yerleştiriliyor."""
    L = spec["L"]
    tilt = math.radians(spec["tilt"])
    cam = bpy.data.cameras.new("cam")
    cam.type = "ORTHO"
    cam.ortho_scale = L
    co = bpy.data.objects.new("cam", cam)
    bpy.context.scene.collection.objects.link(co)
    co.rotation_euler = (math.radians(90) - tilt, 0.0, 0.0)
    forward = Vector((0.0, math.cos(tilt), -math.sin(tilt)))
    up = Vector((0.0, math.sin(tilt), math.cos(tilt)))
    height_m = L * res_y / TEX_W
    anchor = Vector((L / 2.0, spec["anchor_y"], 0.0))
    co.location = anchor - forward * 300.0 - up * (spec["anchor_v"] - 0.5) * height_m
    cam.clip_end = 2000.0
    bpy.context.scene.camera = co
    return height_m


def v_of(spec, res_y, y, z=0.0):
    """Dünyadaki (y, z) noktasının karede alttan payı - oyun bunu okuyor."""
    tilt = math.radians(spec["tilt"])
    up = Vector((0.0, math.sin(tilt), math.cos(tilt)))
    height_m = spec["L"] * res_y / TEX_W
    d = (Vector((0.0, y, z)) - Vector((0.0, spec["anchor_y"], 0.0))).dot(up)
    return spec["anchor_v"] + d / height_m


# ---------------------------------------------------------------- katmanlar

def build_far(b, spec, rng):
    L = spec["L"]
    cfg = b["far"]
    f1 = periodic(L, cfg["freqs"], rng.randrange(10 ** 6))
    f2 = periodic(L, [k + 1 for k in cfg["freqs"]], rng.randrange(10 ** 6))
    amp, base = cfg["amp"], cfg["base"]
    rock = material("far_rock", cfg["tint"], tex="Rock064", scale=0.05, tint=cfg["tint"],
                    snow=cfg.get("snow", 0.0) * 0.15, L=L, noise_scale=0.06, cap=cfg.get("snow", 0.0) > 0.0,
                    cap_range=(cfg["base"] + cfg["amp"] * 0.7, cfg["base"] + cfg["amp"] * 1.05))
    # Öndeki alçak tepeler biyomun kendi toprağı: uzak sırtın renginde
    # ufukta kurşuni bir şerit gibi okunuyordu.
    near_mat = material("far_hill", b["ground_tint"], tex="Ground106", scale=0.08,
                        tint=[c * 0.85 for c in b["ground_tint"]], L=L)
    # İki sıra: arkada yüksek sırt, önünde alçak tepeler. Sırtın üstünde
    # çapraz yarıklar (x'te periyotlu, y ile kayan): düz bir kubbe hamur
    # gibi okunuyordu.
    gully = periodic(L, [13, 19, 29, 41], rng.randrange(10 ** 6))

    def back(x, y):
        t = math.sin(math.pi * (y - 40.0) / 30.0)
        return base + amp * (0.6 + 0.6 * f1(x)) * t + amp * 0.10 * gully(x + 3.0 * y) * t
    heightfield("far_back", L, 40.0, 70.0, 720, 30, back, rock)
    heightfield("far_front", L, 8.0, 30.0, 360, 6,
                lambda x, y: base * 0.35 + amp * 0.25 * (0.6 + 0.6 * f2(x)) * math.sin(math.pi * (y - 8.0) / 22.0),
                near_mat)
    if cfg.get("water"):
        bpy.ops.mesh.primitive_plane_add(size=1.0, location=(L / 2.0, 5.0, 0.4))
        w = bpy.context.object
        w.scale = (L * 3.0, 10.0, 1.0)
        w.data.materials.append(material("water", (0.46, 0.56, 0.62), 0.35))
    for _ in range(cfg.get("trees", 0)):
        x = rng.uniform(0, L)
        y = rng.uniform(10.0, 26.0)
        z = base * 0.35 + amp * 0.25 * (0.6 + 0.6 * f2(x)) * math.sin(math.pi * (y - 8.0) / 22.0)
        place_wrapped(T.ftk("tree-high"), x, y, z - 0.5, rng.uniform(0, 360), rng.uniform(5.0, 8.0), L)


def _mesh_object(name, me, mat):
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    me.materials.append(mat)
    return o


def _blob(name, centre, radius, squash, mat, seed):
    """Taç kümesi: yer değiştirmiş bir ikosfer - pürüzsüz top değil, yapraklı
    kenarı olan bir yığın."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=radius, location=centre)
    o = bpy.context.object
    o.name = name
    o.scale = (1.0, 1.0, squash)
    tex = bpy.data.textures.new(name + "_n", "CLOUDS")
    tex.noise_scale = radius * 0.28
    tex.noise_depth = 2
    d = o.modifiers.new("disp", "DISPLACE")
    d.texture = tex
    d.strength = radius * 0.7
    # Yerel koordinat: ağacın x ± L kopyaları aynı şekli taşısın (dikiş).
    d.texture_coords = "LOCAL"
    o.rotation_euler = (seed * 3.1, seed * 5.7, seed * 6.28)
    o.data.materials.append(mat)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def _limb(name, a, b, r0, r1, mat):
    """Gövde/dal: iki ucu arasında konik bir silindir."""
    a, b = Vector(a), Vector(b)
    d = b - a
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=r0, radius2=r1, depth=d.length,
                                    location=(a + b) / 2.0)
    o = bpy.context.object
    o.name = name
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = d.to_track_quat("Z", "Y")
    o.data.materials.append(mat)
    return o


def build_tree(kind, base, h, rng, mats, tag):
    """Prosedürel ağaç: paketlerdeki ağaçlar oyuncak gibi katmanlıydı.
    Yapraklı (eğik gövde, dal, 5-8 taç kümesi), iğne yapraklı (üst üste
    pürüzlü koniler) ya da kurumuş (yalnızca gövde ve çatallanan dallar -
    kasvetli yolun imzası)."""
    x, y, z = base
    parts = []
    lean = rng.uniform(-0.12, 0.12) * h
    top = (x + lean, y, z + h * (0.55 if kind == "leafy" else 0.9))
    parts.append(_limb(tag + "_t", (x, y, z - 0.3), top, h * 0.035, h * 0.018, mats["bark"]))
    if kind == "leafy":
        for i in range(rng.randint(5, 8)):
            c = (top[0] + rng.uniform(-0.28, 0.28) * h, y + rng.uniform(-0.15, 0.15) * h,
                 top[2] + rng.uniform(-0.05, 0.32) * h)
            parts.append(_blob("%s_b%d" % (tag, i), c, h * rng.uniform(0.14, 0.22), 0.8,
                               mats["leaf"], rng.random()))
    elif kind == "conifer":
        tiers = rng.randint(4, 6)
        for i in range(tiers):
            t = i / tiers
            r = h * (0.26 * (1.0 - t) + 0.05)
            zc = z + h * (0.18 + 0.78 * t)
            bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=r, radius2=0.0, depth=h * 0.30,
                                            location=(x + lean * (0.5 + t * 0.5), y, zc))
            o = bpy.context.object
            o.name = "%s_c%d" % (tag, i)
            o.data.materials.append(mats["needle"])
            o.rotation_euler = (0, 0, rng.uniform(0, 6.28))
            parts.append(o)
    else:
        def branch(a, d, length, radius, depth):
            b = Vector(a) + d.normalized() * length
            parts.append(_limb("%s_d%d_%d" % (tag, depth, len(parts)), a, b, radius, radius * 0.6, mats["bark"]))
            if depth == 0:
                return
            for _ in range(2 if depth > 1 else rng.randint(1, 3)):
                nd = d.normalized() + Vector((rng.uniform(-0.9, 0.9), rng.uniform(-0.3, 0.3),
                                              rng.uniform(0.0, 0.7)))
                branch(b, nd, length * rng.uniform(0.55, 0.75), radius * 0.6, depth - 1)
        branch(top, Vector((rng.uniform(-0.4, 0.4), 0, 1)), h * 0.22, h * 0.02, 3)
    return parts


def tree_materials():
    return {
        "bark": material("bark", (0.16, 0.13, 0.11), tex="Planks037A", scale=1.5, tint=[0.34, 0.30, 0.27]),
        "leaf": material("leaf", (0.13, 0.15, 0.10), 0.95),
        "needle": material("needle", (0.09, 0.12, 0.09), 0.95),
    }


def place_tree_wrapped(kind, x, y, h, rng, mats, L, tag):
    """Ağaç bir kez kurulur, iki kopyası x ± L'ye taşınır (dikişsiz döşeme)."""
    parts = build_tree(kind, (x, y, 0.0), h, rng, mats, tag)
    for dx in (-L, L):
        for o in parts:
            c = o.copy()
            c.data = o.data
            c.location = o.location + Vector((dx, 0.0, 0.0))
            bpy.context.scene.collection.objects.link(c)


def pick(pool, rng):
    r = rng.random()
    acc = 0.0
    for kind, share in pool:
        acc += share
        if r <= acc:
            return kind
    return pool[-1][0]


def build_mid(b, spec, rng):
    L = spec["L"]
    shadow_catcher(L, -6.0, 40.0)
    mats = tree_materials()
    count = b["tree_count"]
    lo, hi = b["tree_h"]
    for i in range(count):
        x = (i + rng.uniform(0.0, 1.0)) * L / count
        y = rng.uniform(0.0, 24.0)
        # Uzaktaki küçük: aynı katmanda derinlik boyla okunuyor.
        h = rng.uniform(lo, hi) * (1.0 - y / 60.0)
        place_tree_wrapped(pick(b["trees"], rng), x, y, h, rng, mats, L, "t%d" % i)
    for _ in range(int(4 * b["rocks"] * L / 72.0)):
        kind = rng.choice(["rock-large", "rock-wide", "rock-wide"])
        place_wrapped(T.ftk(kind), rng.uniform(0, L), rng.uniform(0.0, 10.0), 0.0,
                      rng.uniform(0, 360), rng.uniform(1.2, 2.6), L, mats=rock_material(b))


def build_ground(b, spec, rng):
    L = spec["L"]
    f = periodic(L, [3, 7, 11], rng.randrange(10 ** 6))
    far_edge = periodic(L, [9, 17, 31], rng.randrange(10 ** 6))
    grass = material("ground_grass", b["grass"], tex=b["ground_tex"], scale=0.35,
                     tint=b["ground_tint"], snow=b["snow"], L=L)
    heightfield("ground", L, -14.0, GROUND_FAR_Y, 240, 64,
                lambda x, y: 0.0 if 2.5 < y < 8.5 else 0.10 * f(x) * min(1.0, abs(y - 5.5) - 3.0),
                grass, warp=lambda x, t: (t ** 4) * 1.4 * far_edge(x))
    # Yol: geniş, açık toprak bir bant; kenarları dalgalı.
    road = material("road", (0.6, 0.52, 0.4), tex="Ground106", scale=0.5,
                    tint=b.get("road_tint", [1.05, 0.92, 0.76]), L=L)
    g = periodic(L, [4, 9, 13], rng.randrange(10 ** 6))
    h = periodic(L, [5, 8, 15], rng.randrange(10 ** 6))
    heightfield("road", L, 3.0, 8.0, 360, 10, lambda x, y: 0.02, road,
                warp=lambda x, t: (0.45 * g(x)) * (1.0 - t) + (0.45 * h(x)) * t)
    rut = material("rut", (0.16, 0.12, 0.09), 0.9, tex="Ground106", scale=0.9, tint=[0.48, 0.40, 0.32], L=L)
    for k, yy in enumerate((4.6, 6.4)):
        wob = periodic(L, [3, 6], rng.randrange(10 ** 6))
        heightfield("rut%d" % k, L, yy - 0.22, yy + 0.22, 360, 2, lambda x, y: 0.03, rut,
                    warp=lambda x, t, w=wob: 0.18 * w(x))
    if b["water"]:
        pud = material("puddle", (0.12, 0.15, 0.17), 0.9)
        for _ in range(4):
            x, y = rng.uniform(0, L), rng.uniform(3.4, 7.6)
            for xx in wrapped(x, L):
                bpy.ops.mesh.primitive_circle_add(vertices=24, radius=1.0, fill_type="NGON",
                                                  location=(xx, y, 0.04))
                o = bpy.context.object
                o.scale = (rng.uniform(0.8, 1.8), rng.uniform(0.3, 0.6), 1.0)
                o.data.materials.append(pud)
    cache = {}
    # Yolun arkası: diz boyu, sık bir ot bandı - ağaçların ayağı bunun
    # içinde kalıyor (referansta da öyle). Uzak kenara doğru uzuyor.
    n = 0
    for _ in range(b["tufts"] * 22):
        y = rng.uniform(8.6, GROUND_FAR_Y - 0.5)
        t = (y - 8.6) / (GROUND_FAR_Y - 8.6)
        x = rng.uniform(0, L)
        for xx in wrapped(x, L):
            tuft("gb%d" % n, xx, y, rng.uniform(0.35, 0.7) + t * 0.5,
                 [c * 0.7 for c in b["grass"]], cache, rng)
        n += 1
    # Yolun önü: seyrek; yakın tarla (ön katman) burayı zaten örtüyor.
    for _ in range(b["tufts"] * 4):
        x = rng.uniform(0, L)
        for xx in wrapped(x, L):
            tuft("gf%d" % n, xx, rng.uniform(-6.0, 2.8), rng.uniform(0.3, 0.6), b["grass"], cache, rng)
        n += 1
    # Zemin katmanında taş yok (görev 12.2d): Kenney kayaları dik ve yosunlu
    # çıkıyor, kervanın hemen altında ağaç kütüğü gibi okunuyordu. Taş
    # çeşitliliği orta katmanda (build_mid) kalıyor; yakın planda yalnızca ot.


def flower(name, x, y, h, colour, mat_cache, stem_mat):
    """Sapında beş yapraklı küçük bir çiçek - yakın tarlanın tek sıcak notu."""
    key = ("fl",) + tuple(round(c, 2) for c in colour)
    if key not in mat_cache:
        mat_cache[key] = material("flower_%d" % len(mat_cache), colour, 0.8)
    verts, faces = [(x - 0.01, y, 0.0), (x + 0.01, y, 0.0), (x, y, h)], [(0, 1, 2)]
    centre = len(verts)
    verts.append((x, y - 0.01, h))
    r = 0.07
    for k in range(10):
        a = math.tau * k / 10.0
        rr = r if k % 2 == 0 else r * 0.4
        verts.append((x + math.cos(a) * rr, y - 0.01, h + math.sin(a) * rr))
    for k in range(10):
        faces.append((centre, centre + 1 + k, centre + 1 + (k + 1) % 10))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    o.data.materials.append(stem_mat)
    o.data.materials.append(mat_cache[key])
    for p in o.data.polygons:
        p.material_index = 0 if p.index == 0 else 1
    return o


def build_fore(b, spec, rng):
    """Kameraya en yakın ot tarlası: sık, uzun, arada çiçek. Arka kenarı
    (y = 0) yolun hemen altına oturuyor, ön kenarı karenin dibinden taşıyor.
    Ortografik kamerada yakın büyümediği için öndeki sıralar boyca uzun."""
    L = spec["L"]
    dirt = material("fore_ground", b["grass"], tex=b["ground_tex"], scale=0.5,
                    tint=[c * 0.5 for c in b["ground_tint"]], L=L)
    heightfield("fore_ground", L, -30.0, -0.3, 120, 20, lambda x, y: 0.0, dirt)
    cache = {}
    stem = material("stem", [c * 0.7 for c in b["grass"]], 0.9)
    n = 0
    rows = 34
    for r in range(rows):
        t = r / (rows - 1)  # 0 arka, 1 ön
        y = -0.2 - t * 26.0
        per_row = int(26 + 10 * t)
        for _ in range(per_row):
            x = rng.uniform(0, L)
            hgt = rng.uniform(0.5, 0.9) + t * rng.uniform(0.6, 1.4)
            shade = [c * rng.uniform(0.55, 0.95) for c in b["grass"]]
            for xx in wrapped(x, L):
                tuft("fg%d" % n, xx, y + rng.uniform(-0.3, 0.3), hgt, shade, cache, rng)
            n += 1
    for i in range(int(22 * len(b["flowers"]))):
        x = rng.uniform(0, L)
        t = rng.random()
        y = -0.4 - t * 20.0
        colour = rng.choice(b["flowers"])
        hgt = 0.5 + t * 1.1
        for xx in wrapped(x, L):
            flower("fl%d_%d" % (i, int(xx)), xx, y, hgt, colour, cache, stem)
    if b["water"]:
        reed = material("reed", [c * 0.45 for c in b["grass"]], 0.8)
        for i in range(30):
            x = rng.uniform(0, L)
            for xx in wrapped(x, L):
                t = tuft("rd%d" % i, xx, rng.uniform(-1.0, -8.0), rng.uniform(1.4, 2.4), b["grass"], cache, rng)
                t.data.materials[0] = reed


BUILDERS = {"far": build_far, "mid": build_mid, "ground": build_ground, "fore": build_fore}


def render(path, samples, res_y, transparent=True):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x = TEX_W
    sc.render.resolution_y = res_y
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = transparent
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Base Contrast"
    sc.render.use_freestyle = True
    sc.render.line_thickness_mode = "ABSOLUTE"
    sc.render.line_thickness = 1.4
    fss = sc.view_layers[0].freestyle_settings
    fs = fss.linesets[0] if len(fss.linesets) else fss.linesets.new("ink")
    if fs.linestyle is None:
        fs.linestyle = bpy.data.linestyles.new("ink")
    fs.linestyle.color = (0.03, 0.02, 0.02)
    fs.select_by_visibility = True
    fs.select_silhouette = True
    fs.select_border = False
    fs.select_crease = False
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main(argv):
    biome = argv[argv.index("--biome") + 1]
    samples = int(argv[argv.index("--samples") + 1]) if "--samples" in argv else 32
    layers = argv[argv.index("--layers") + 1].split(",") if "--layers" in argv else list(LAYERS)
    out = os.path.join(OUT, "road_" + biome)
    os.makedirs(out, exist_ok=True)
    layout_path = os.path.join(out, "layout.json")
    layout = json.load(open(layout_path)) if os.path.exists(layout_path) else {}
    for name in layers:
        spec = LAYERS[name]
        T.reset()
        rng = random.Random(zlib.crc32(("%s|%s" % (biome, name)).encode()))
        BUILDERS[name](BIOMES[biome], spec, rng)
        T.texture_materials((1.0, 0.55, 0.22, 1.0))
        light_rig()
        camera(spec, spec["h"])
        render(os.path.join(out, name + ".png"), samples, spec["h"], transparent=True)
        entry = {"L": spec["L"], "anchor_v": spec["anchor_v"]}
        if name == "ground":
            entry["road_v"] = v_of(spec, spec["h"], 5.5)
            entry["road_top_v"] = v_of(spec, spec["h"], 8.5)
            entry["road_bottom_v"] = v_of(spec, spec["h"], 2.5)
        layout[name] = entry
        print("KATMAN", biome, name)
    json.dump(layout, open(layout_path, "w"), indent=1)
    print("BITTI", out)


if __name__ == "__main__":
    main(sys.argv)
