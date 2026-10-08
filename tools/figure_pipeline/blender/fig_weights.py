"""Katman agirligi: vertex basina w_K (K = uzuv katmaninin MPFB kemikleri), tum
deform kemiklerine gore normalize. "lw" renk ozniteligine RGBA olarak yazilir:
(w_back_arm, w_back_leg, w_front_leg, w_front_arm). config/layers.json okunur.
"""
ORDER = ["back_arm", "back_leg", "front_leg", "front_arm"]


def layer_weights(mesh_obj, rig_obj, layers_cfg):
    deform = {b.name for b in rig_obj.data.bones if b.use_deform}
    names = {g.index: g.name for g in mesh_obj.vertex_groups}
    sets = {k: set(layers_cfg["limb_bones"][k]) for k in ORDER}
    out = []
    for v in mesh_obj.data.vertices:
        tot = 0.0
        acc = [0.0, 0.0, 0.0, 0.0]
        for g in v.groups:
            n = names.get(g.group)
            if n not in deform:
                continue
            tot += g.weight
            for i, k in enumerate(ORDER):
                if n in sets[k]:
                    acc[i] += g.weight
        out.append([a / tot if tot > 1e-9 else 0.0 for a in acc])
    return out


def bone_share(mesh_obj, rig_obj, bone_names):
    """Vertex basina verilen kemiklerin deform agirligi payi (0..1)."""
    deform = {b.name for b in rig_obj.data.bones if b.use_deform}
    names = {g.index: g.name for g in mesh_obj.vertex_groups}
    want = set(bone_names)
    out = []
    for v in mesh_obj.data.vertices:
        tot = acc = 0.0
        for g in v.groups:
            n = names.get(g.group)
            if n not in deform:
                continue
            tot += g.weight
            if n in want:
                acc += g.weight
        out.append(acc / tot if tot > 1e-9 else 0.0)
    return out


def garment_weights(body_obj, rig_obj, lw, rest_coords, gcfg, top_kind):
    """Bedenin yuzeyine boyanan temel kusam: (top, bottom, 0) vertex basina 0/1.
    Bolgeler dinlenme pozundaki kemik yuksekliklerinden (config/garments.json).
    Kollar (uzuv agirligi >= 0.5) ve bas/boyun hicbir zaman giysi degil:
    kol oyugu boylece kendiliginden aciliyor."""
    r = gcfg["regions"]
    W = rig_obj.matrix_world
    head = lambda n: W @ rig_obj.data.bones[n].head_local
    pel = head("pelvis").z
    T = head("neck_01").z - pel
    hip = head("thigh_r").z
    knee = head("calf_r").z
    shoulder_x = abs(head("upperarm_r").x)
    shoulder_z = head("upperarm_r").z
    waist = pel + r["waist_t"] * T
    overlap = r["overlap_t"] * T
    hem = knee + r["hem_knee_share"] * (hip - knee)
    if top_kind == "tank":
        top_lo, top_hi = waist - overlap, pel + r["tank_top_t"] * T
    else:
        top_lo, top_hi = pel + r["bra_bottom_t"] * T, pel + r["bra_top_t"] * T
    strap_x = r["strap_x_share"] * shoulder_x
    strap_w = r["strap_half_width_m"]
    headneck = bone_share(body_obj, rig_obj, ["head", "neck_01"])
    # Sinir ISARETLI MESAFEDEN: deger = 0.5 + mesafe/(2*RAMP), [0,1]'e kenetli.
    # Golgelendirici > 0.5'te keser; dogrusal bir alan yuzey uzerinde dogrusal
    # enterpole edildigi icin sinir her yuzde gercek bir duzlem kesiti olur.
    # Ilk surum 0/1 yaziyordu: sinir agin kenarlarini izleyip testere gibi
    # tirtikli cikti (sort pacasi, proto1.png).
    RAMP = 0.08

    def band(z, lo, hi):
        return min(z - lo, hi - z)

    def sv(dist):
        return max(0.0, min(1.0, 0.5 + dist / (2.0 * RAMP)))

    out = []
    for i, c in enumerate(rest_coords):
        arm = max(lw[i][0], lw[i][3])
        leg = max(lw[i][1], lw[i][2])
        # agirlik mesafesi: 0.5 sinirinda sifir; RAMP olcegine tasiniyor
        not_arm = (0.5 - arm) * RAMP * 2.0
        not_head = (0.5 - headneck[i]) * RAMP * 2.0
        not_leg = (0.5 - leg) * RAMP * 2.0
        bottom = sv(min(band(c.z, hem, waist), not_arm))
        body_band = band(c.z, top_lo, top_hi)
        strap = min(band(c.z, top_hi - 0.02, shoulder_z + 0.04), strap_w - abs(abs(c.x) - strap_x))
        top = sv(min(max(body_band, strap), not_arm, not_head, not_leg))
        out.append((top, bottom, 0.0, 1.0))
    return out


def write_color(mesh_obj, values, name):
    me = mesh_obj.data
    if name in me.color_attributes:
        me.color_attributes.remove(me.color_attributes[name])
    attr = me.color_attributes.new(name, "FLOAT_COLOR", "POINT")
    for i, v in enumerate(values):
        attr.data[i].color = v
    return attr


def write_attr(mesh_obj, weights, name="lw"):
    me = mesh_obj.data
    if name in me.color_attributes:
        me.color_attributes.remove(me.color_attributes[name])
    attr = me.color_attributes.new(name, "FLOAT_COLOR", "POINT")
    for i, w in enumerate(weights):
        attr.data[i].color = (w[0], w[1], w[2], w[3])
    return attr
