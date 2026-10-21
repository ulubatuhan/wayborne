"""Brandali kervan vagonu ve tek aksli yarim vagon, bpy ile sifirdan.

Paketlerde hazir bir brandali vagon yok (bkz. art_source/models/props/LICENSES.md):
MegaKit'in arabasi tek aksli ve gevsek parcalardan olusuyor, tekerlegi ayri bir
nesne olarak cikmiyor. Oyunun vagonu da zaten `ArtDraw.wagon()`'un oranlarina
bagli (tekerlek yaricapi 0.34h, tekerlekler +-0.30w, kasa tabani 1.35r, branda
tepesi ~1.24h) - kolon dizilimi, okun boyu ve arabacinin oturagi bu sayilari
okuyor. Bu yuzden model o oranlarla, metre cinsinden kuruluyor; sprite oyunda
ayni kutuya dusuyor ve RoadCaravan'in hicbir mesafesi degismiyor.

Eksenler kameranin: on taraf -Y (ekranin sagi), yukari +Z, yer z=0.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix

H = 1.6                  # ArtDraw'daki h, metre
W = H * 0.21 / 0.17      # WAGON_WIDTH_RATIO / WAGON_HEIGHT_RATIO
R = H * 0.34             # WAGON_WHEEL_RATIO: arka tekerlek
R_FRONT = R * 0.80       # on tekerlek kucuk: gercek vagon onu altindan donsun diye
BED_Z = R * 1.35         # kasa tabani
BED_TOP = BED_Z + H * 0.16
CANOPY_TOP = BED_TOP + H * 0.62

# sRGB -> lineer: ArtPalette degerleri ekran rengi, emisyon lineer okur
def _lin(c):
    return tuple(((v / 12.92) if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4) for v in c)


PALETTE = {
    "wood": _lin((0.40, 0.28, 0.18)),
    "wood_dark": _lin((0.27, 0.19, 0.13)),
    "wood_light": _lin((0.50, 0.36, 0.23)),
    "canvas": _lin((0.80, 0.75, 0.63)),
    "canvas_dark": _lin((0.66, 0.61, 0.50)),
    "wheel": _lin((0.30, 0.22, 0.15)),
    "iron": _lin((0.20, 0.20, 0.22)),
    "rope": _lin((0.58, 0.49, 0.33)),
}


def material(name):
    m = bpy.data.materials.get("wb_" + name)
    if m is None:
        m = bpy.data.materials.new("wb_" + name)
        m.use_nodes = True
        bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        c = PALETTE[name]
        bsdf.inputs["Base Color"].default_value = (c[0], c[1], c[2], 1.0)
    return m


def _obj(name, bm, mat):
    me = bpy.data.meshes.new(name)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    me.materials.append(material(mat))
    return ob


def box(name, lo, hi, mat):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x = lo[0] + (v.co.x + 0.5) * (hi[0] - lo[0])
        v.co.y = lo[1] + (v.co.y + 0.5) * (hi[1] - lo[1])
        v.co.z = lo[2] + (v.co.z + 0.5) * (hi[2] - lo[2])
    return _obj(name, bm, mat)


def cylinder_x(name, centre, radius, length, mat, segs=16):
    """X eksenli silindir (aks, gobek)."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=radius, radius2=radius, depth=length)
    for v in bm.verts:
        x, y, z = v.co.x, v.co.y, v.co.z
        v.co.x, v.co.y, v.co.z = centre[0] + z, centre[1] + x, centre[2] + y
    return _obj(name, bm, mat)


def cylinder_z(name, centre, radius, length, mat, segs=16):
    """Dik silindir (fici, cuval)."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=radius, radius2=radius, depth=length)
    for v in bm.verts:
        v.co.x += centre[0]
        v.co.y += centre[1]
        v.co.z += centre[2]
    return _obj(name, bm, mat)


def cylinder_y(name, centre, radius, length, mat, segs=16):
    """Y eksenli (yatik, kameraya yandan gorunen) silindir."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=radius, radius2=radius, depth=length)
    for v in bm.verts:
        x, y, z = v.co.x, v.co.y, v.co.z
        v.co.x, v.co.y, v.co.z = centre[0] + x, centre[1] + z, centre[2] + y
    return _obj(name, bm, mat)


def ring_x(name, centre, r_in, r_out, thick, mat, segs=28):
    """X eksenli kalin halka (jant, demir cember)."""
    bm = bmesh.new()
    rows = []
    for x in (-thick / 2, thick / 2):
        for r in (r_in, r_out):
            rows.append([bm.verts.new((centre[0] + x, centre[1] + r * math.cos(2 * math.pi * k / segs),
                                       centre[2] + r * math.sin(2 * math.pi * k / segs))) for k in range(segs)])
    a_in, a_out, b_in, b_out = rows
    for k in range(segs):
        n = (k + 1) % segs
        for p, q in ((a_out, b_out), (b_in, a_in), (b_out, b_in), (a_in, a_out)):
            bm.faces.new((p[k], p[n], q[n], q[k]))
    return _obj(name, bm, mat)


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = name
    return objs[0]


def wheel(name, centre, radius=R, spokes=12):
    """Tahta jant, demir cember, gobek ve parmaklar - tek nesne, merkezi `centre`."""
    parts = [
        ring_x(name + "_tire", centre, radius - 0.022, radius, 0.075, "iron"),
        ring_x(name + "_felloe", centre, radius * 0.82, radius - 0.022, 0.07, "wheel"),
        cylinder_x(name + "_hub", centre, radius * 0.17, 0.22, "wood_dark"),
    ]
    for k in range(spokes):
        a = 2 * math.pi * (k + 0.5) / spokes
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        L = radius * 0.70
        for v in bm.verts:
            # parmagi once +Y boyunca uzat, sonra a acisiyla dondur
            lx, ly, lz = v.co.x * 0.045, (v.co.y + 0.5) * L + radius * 0.14, v.co.z * 0.032
            v.co.x = centre[0] + lx
            v.co.y = centre[1] + ly * math.cos(a) - lz * math.sin(a)
            v.co.z = centre[2] + ly * math.sin(a) + lz * math.cos(a)
        parts.append(_obj(name + "_spoke%d" % k, bm, "wheel"))
    return join(parts, name)


def _canopy_section(t, half_w, rise):
    """Kemer kesiti: t 0..pi, kenarlar dikce yukselir, tepe yuvarlak."""
    c, s = math.cos(t), math.sin(t)
    x = half_w * math.copysign(abs(c) ** 0.75, c)
    z = rise * (abs(s) ** 0.55)
    return x, z


def canopy(name, y_front, y_back, hoops=5, half_w=0.64, rise=None, flare=0.16, seg=24):
    """Brandayi kemerler arasinda hafif sarkan bir kabuk olarak orer. Uclar
    acik; kalinlik solidify ile (backface culling icin kapali hacim)."""
    rise = rise if rise is not None else CANOPY_TOP - BED_TOP
    hoop_y = [y_front + (y_back - y_front) * k / (hoops - 1) for k in range(hoops)]
    sub = 6
    ys = []
    for k in range(hoops - 1):
        for j in range(sub):
            ys.append((hoop_y[k] + (hoop_y[k + 1] - hoop_y[k]) * j / sub, j / sub))
    ys.append((hoop_y[-1], 0.0))
    bm = bmesh.new()
    rings = []
    for idx, (y, frac) in enumerate(ys):
        sag = 1.0 - 0.045 * math.sin(math.pi * frac) ** 2
        ring = []
        end = idx == 0 or idx == len(ys) - 1
        for i in range(seg + 1):
            t = math.pi * i / seg
            x, z = _canopy_section(t, half_w, rise)
            x *= sag
            z *= sag
            yy = y
            if end:
                # uc kemerler disa acilir: tepe kasanin disina tasar
                yy += (-1 if idx == 0 else 1) * flare * (z / rise)
            ring.append(bm.verts.new((x, yy, BED_TOP - 0.02 + z)))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for i in range(seg):
            bm.faces.new((a[i], a[i + 1], b[i + 1], b[i]))
    ob = _obj(name, bm, "canvas")
    mod = ob.modifiers.new("thick", "SOLIDIFY")
    mod.thickness = 0.025
    mod.offset = 1.0
    # kemer kuşaklari: brandanin ustunde ince tahta seritler
    ribs = []
    for k, y in enumerate(hoop_y):
        rb = bmesh.new()
        prev = None
        for i in range(seg + 1):
            t = math.pi * i / seg
            x, z = _canopy_section(t, half_w + 0.012, rise + 0.012)
            yy = y
            if k == 0 or k == hoops - 1:
                yy += (-1 if k == 0 else 1) * flare * (z / rise)
            cur = [rb.verts.new((x, yy + dy, BED_TOP - 0.02 + z)) for dy in (-0.028, 0.028)]
            if prev is not None:
                rb.faces.new((prev[0], prev[1], cur[1], cur[0]))
            prev = cur
        r_ob = _obj(name + "_rib%d" % k, rb, "canvas_dark")
        m2 = r_ob.modifiers.new("thick", "SOLIDIFY")
        m2.thickness = 0.012
        ribs.append(r_ob)
    return ob, ribs


def covered_wagon():
    """Katmanlar: govde (kasa, alt takim, oturak), branda, yuk, tekerlek.
    Dondurulecek tek sey on/arka tekerlek; sallanacak tek sey branda."""
    body = []
    half_bed = 0.58
    body.append(box("bed", (-half_bed, -W / 2, BED_Z), (half_bed, W / 2, BED_TOP), "wood"))
    # yan tahtalar: ust kenarda acik renkli bir pervaz, altta koyu kiris
    for side in (-1, 1):
        body.append(box("rail%d" % side, (side * half_bed - 0.025, -W / 2 - 0.02, BED_TOP - 0.05),
                        (side * half_bed + 0.025, W / 2 + 0.02, BED_TOP + 0.01), "wood_light"))
        body.append(box("sill%d" % side, (side * half_bed - 0.03, -W / 2, BED_Z - 0.03),
                        (side * half_bed + 0.03, W / 2, BED_Z + 0.04), "wood_dark"))
        for k in range(5):
            y = -W / 2 + 0.12 + k * (W - 0.24) / 4
            body.append(box("stake%d_%d" % (side, k), (side * half_bed - 0.035, y - 0.03, BED_Z),
                            (side * half_bed + 0.035, y + 0.03, BED_TOP), "wood_dark"))
    wy = W * 0.30
    for y, r in ((-wy, R_FRONT), (wy, R)):
        body.append(cylinder_x("axle%+.1f" % y, (0, y, r), 0.045, 1.52, "wood_dark"))
        body.append(box("bolster%+.1f" % y, (-0.5, y - 0.07, r), (0.5, y + 0.07, BED_Z), "wood_dark"))
    body.append(box("reach", (-0.06, -wy, R_FRONT - 0.05), (0.06, wy, R + 0.05), "wood_dark"))
    # on: oturak, sirtlik ve ayak tahtasi. Arabaci ArtDraw.wagon_driver_seat'te
    # (on +0.34w, kasa ustu +0.04h) oturuyor; oturak onun altinda.
    seat_y = -W * 0.34
    body.append(box("seat", (-0.5, seat_y - 0.13, BED_TOP + 0.02), (0.5, seat_y + 0.13, BED_TOP + 0.08), "wood_light"))
    for side in (-1, 1):
        body.append(box("seatpost%d" % side, (side * 0.42 - 0.03, seat_y - 0.03, BED_TOP),
                        (side * 0.42 + 0.03, seat_y + 0.03, BED_TOP + 0.03), "wood_dark"))
    body.append(box("footboard", (-0.5, -W / 2 - 0.16, BED_Z + 0.02), (0.5, -W / 2 + 0.02, BED_Z + 0.06), "wood_dark"))
    body.append(box("tailgate", (-half_bed, W / 2 - 0.02, BED_Z), (half_bed, W / 2 + 0.03, BED_TOP + 0.04), "wood_dark"))
    # arka raf: yuk katmani bunun ustune biniyor
    body.append(box("rearshelf", (-0.45, W / 2, BED_Z - 0.02), (0.45, W / 2 + 0.26, BED_Z + 0.03), "wood_dark"))
    # su fici yanda: kervanin "yolda yasayan" bir sey oldugunu soyluyor
    body.append(cylinder_z("waterbarrel", (-half_bed - 0.12, W * 0.10, BED_Z + 0.10), 0.12, 0.30, "wood_light"))
    for dz in (-0.10, 0.10):
        body.append(cylinder_z("barrelhoop%+.1f" % dz, (-half_bed - 0.12, W * 0.10, BED_Z + 0.10 + dz), 0.126, 0.03, "iron"))
    body_obj = join(body, "body")

    can, ribs = canopy("canopy", -W * 0.24, W * 0.44, flare=0.10, rise=CANOPY_TOP - BED_TOP - 0.06)
    can_obj = join([can] + ribs, "canopy")

    load = [
        box("crate", (-0.32, W / 2 + 0.02, BED_Z + 0.03), (0.06, W / 2 + 0.25, BED_Z + 0.33), "wood_light"),
        box("crate_band", (-0.325, W / 2 + 0.015, BED_Z + 0.16), (0.065, W / 2 + 0.255, BED_Z + 0.19), "iron"),
        cylinder_z("sack", (0.22, W / 2 + 0.13, BED_Z + 0.17), 0.12, 0.28, "canvas_dark", segs=12),
        box("rope", (-0.36, W / 2 + 0.10, BED_Z + 0.03), (0.40, W / 2 + 0.14, BED_Z + 0.36), "rope"),
    ]
    load_obj = join(load, "load")

    wheels = {(s, e): wheel("wheel_%s_%s" % (s, e), (sx * 0.70, y, r), radius=r)
              for s, sx in (("near", -1), ("far", 1)) for e, y, r in (("front", -wy, R_FRONT), ("back", wy, R))}
    return {
        "body": [body_obj, wheels[("far", "front")], wheels[("far", "back")]],
        "canopy": [can_obj],
        "load": [load_obj],
        "wheel": [wheels[("near", "back")]],
        "wheel_front": [wheels[("near", "front")]],
    }, {
        "wheel_front": (-0.70, -wy, R_FRONT), "wheel_back": (-0.70, wy, R),
        "seat": (0.0, seat_y, BED_TOP + 0.064), "front": (0.0, -W / 2 - 0.16, BED_Z + 0.04),
        "canopy_base": (0.0, 0.0, BED_TOP),
    }


def half_cart():
    """Tek aksli, iki tekerli, oku olan yuk arabasi - esek ceker. Brandasi
    alcak: yarim vagon tam vagonun yarisi kadar yuk alir (GameSession)."""
    h = H * 0.62
    r = h * 0.40
    bed_z = r * 1.15
    half_len = 0.62
    body = [box("bed", (-0.42, -half_len, bed_z), (0.42, half_len, bed_z + 0.20), "wood")]
    for side in (-1, 1):
        body.append(box("rail%d" % side, (side * 0.42 - 0.02, -half_len, bed_z + 0.16),
                        (side * 0.42 + 0.02, half_len, bed_z + 0.22), "wood_light"))
        # cekme kollari (oklar) one dogru, esegin iki yanina
        body.append(box("shaft%d" % side, (side * 0.30 - 0.025, -half_len - 1.05, bed_z + 0.02),
                        (side * 0.30 + 0.025, -half_len + 0.2, bed_z + 0.07), "wood_dark"))
    body.append(cylinder_x("axle", (0, 0.05, r), 0.04, 1.06, "wood_dark"))
    body_obj = join(body, "body")
    can, ribs = canopy("canopy", -half_len + 0.08, half_len - 0.04, hoops=3, half_w=0.46, rise=0.62, flare=0.08)
    # canopy() kasa ustunu tam vagona gore koyuyor; yarim vagona indir
    for o in [can] + ribs:
        o.location.z -= BED_TOP - (bed_z + 0.20)
    can_obj = join([can] + ribs, "canopy")
    load = [
        cylinder_y("sack1", (0.0, half_len + 0.10, bed_z + 0.13), 0.11, 0.22, "canvas_dark", segs=12),
        box("rope", (-0.28, half_len + 0.06, bed_z + 0.02), (0.28, half_len + 0.10, bed_z + 0.25), "rope"),
    ]
    load_obj = join(load, "load")
    w_near = wheel("wheel_near", (-0.52, 0.05, r), radius=r, spokes=10)
    w_far = wheel("wheel_far", (0.52, 0.05, r), radius=r, spokes=10)
    return {
        "body": [body_obj, w_far],
        "canopy": [can_obj],
        "load": [load_obj],
        "wheel": [w_near],
    }, {
        "wheel_front": (-0.52, 0.05, r), "front": (0.0, -half_len - 1.05, bed_z + 0.04),
        "canopy_base": (0.0, 0.0, bed_z + 0.20),
    }


GATE_HALF = 9.85         # kapı sahnesi city_gate ile aynı genişlikte (19,7 m)
GATE_OPENING = 3.6
LOG_STEP = 0.40
LOG_R = 0.20


def _log(bm, y, x, h, r, segs=8):
    """Dikili kütük: sekizgen gövde, sivri uç (town_scene.palisade ile aynı)."""
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r, radius2=r, depth=h,
                          matrix=Matrix.Translation((x, y, h / 2.0)))
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=True, segments=segs, radius1=r, radius2=0.0, depth=r * 2.4,
                          matrix=Matrix.Translation((x, y, h + r * 1.2)))


def palisade_gate():
    """Ahşap surlu kasabanın hub kapısı: iki sıra sivri kütük, ortada kalın
    direkli geçit ve lento, iki yanda ahşap gözcü kulesi. `gate` katmanı geçidi
    kapatan tahta kanat - lider yaklaşınca kalkıyor (city_gate'in kafesi gibi).
    Taş kapıyla aynı genişlikte, yani oyun aynı ölçekle çiziyor."""
    logs = bmesh.new()
    clear = GATE_OPENING / 2 + 0.3
    n = int(GATE_HALF * 2 / LOG_STEP)
    for row, x in enumerate((0.0, 0.30)):
        for i in range(n + 1):
            y = -GATE_HALF + i * LOG_STEP + (LOG_STEP / 2 if row else 0.0)
            if abs(y) < clear or y > GATE_HALF:
                continue
            _log(logs, y, x, 4.1 + (((i * 37 + row * 11) % 11) / 11.0 - 0.5) * 0.6, LOG_R)
    body = [_obj("palisade_logs", logs, "wood")]
    posts = bmesh.new()
    for side in (-1, 1):
        _log(posts, side * (GATE_OPENING / 2 + 0.4), 0.1, 5.6, LOG_R * 2.0)
    body.append(_obj("gate_posts", posts, "wood_dark"))
    half = GATE_OPENING / 2 + 1.0
    body.append(box("lintel", (-0.3, -half, 4.2), (0.45, half, 4.65), "wood_dark"))
    for side in (-1, 1):
        yc = side * 5.4
        body.append(box("tower_body%d" % side, (-0.8, yc - 0.8, 0.0), (0.8, yc + 0.8, 4.6), "wood_light"))
        for cx in (-0.85, 0.85):
            for cy in (-0.85, 0.85):
                body.append(box("tower_post%d_%d_%d" % (side, cx > 0, cy > 0),
                                (cx - 0.11, yc + cy - 0.11, 0.0), (cx + 0.11, yc + cy + 0.11, 4.9), "wood_dark"))
        body.append(box("tower_deck%d" % side, (-1.15, yc - 1.15, 4.6), (1.15, yc + 1.15, 4.8), "wood_dark"))
        for cy in (-1.05, 1.05):
            body.append(box("parapet_y%d_%d" % (side, cy > 0), (-1.15, yc + cy - 0.06, 4.8),
                            (1.15, yc + cy + 0.06, 5.7), "wood"))
        for cx in (-1.05, 1.05):
            body.append(box("parapet_x%d_%d" % (side, cx > 0), (cx - 0.06, yc - 1.15, 4.8),
                            (cx + 0.06, yc + 1.15, 5.7), "wood"))
        roof = bmesh.new()
        bmesh.ops.create_cone(roof, cap_ends=True, cap_tris=True, segments=4, radius1=1.9, radius2=0.0, depth=1.9,
                              matrix=Matrix.Translation((0.0, yc, 6.65)) @ Matrix.Rotation(math.radians(45), 4, "Z"))
        body.append(_obj("tower_roof%d" % side, roof, "wood_dark"))
    body_obj = join(body, "body")

    leaf = []
    for k in range(9):
        y = -GATE_OPENING / 2 + 0.2 + k * 0.4
        leaf.append(box("plank%d" % k, (-0.12, y - 0.19, 0.0), (0.12, y + 0.19, 3.6), "wood" if k % 2 else "wood_light"))
    for z in (0.7, 2.6):
        leaf.append(box("strap%.1f" % z, (-0.15, -GATE_OPENING / 2, z), (0.15, GATE_OPENING / 2, z + 0.2), "iron"))
    return {"body": [body_obj], "gate": [join(leaf, "gate")]}, {}


def settlement_gate(city):
    """Bir yerleşimin kendi kapısı, kendi kapı sahnesinden (tools/ui_scenes/gate_cutout.py)."""
    ui = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "ui_scenes")
    if ui not in sys.path:
        sys.path.insert(0, ui)
    import gate_cutout
    return gate_cutout.settlement_gate(city)


BUILDERS = {"covered_wagon": covered_wagon, "half_cart": half_cart, "palisade_gate": palisade_gate,
            "settlement_gate": settlement_gate}
