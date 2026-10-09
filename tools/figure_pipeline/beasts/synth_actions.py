"""Animasyonu olmayan modellere (ayi, domuz) kemik donusleriyle klip uretir.

Quaternius paketindeki hayvanlarin yurume/saldiri/darbe/olum animasyonlari
modelle birlikte geliyor; ayi ve domuzun iskeleti ise tools/beast_prep_blend.py
ile sonradan oturtuldu ve hic aksiyonu yok. Burada ayni adlarla
(synth_walk, synth_idle, synth_attack, synth_hit, synth_dead, synth_downed)
anahtar karelenmis aksiyonlar kuruluyor.

Butun donusler sagital duzlemde - dunya X ekseni etrafinda - cunku kamera
yandan bakiyor ve bacak/govde yalniz o duzlemde okunuyor. X etrafinda donus
ayni eksende oldugu icin zincirde (ust bacak, alt bacak) birbirinin uzerine
dogrudan toplanir. Hayvan -Y'ye bakiyor: negatif aci bacagi one atar.
Olu ve yerdeki pozlar render'da zemine indiriliyor (en alcak nokta zeminde).
"""
import math

import bpy
from mathutils import Matrix, Quaternion, Vector

FRAMES = 24

# Tur basina yurume genligi (derece) ve saldiri bicimi.
STYLE = {
    "bear": {"stride": 22.0, "attack": "rear", "dead": ((-80, 15), (80, -15), 0, 30)},
    "boar": {"stride": 26.0, "attack": "charge", "dead": ((-70, 20), (-70, 120), 4, 34)},
}


def _bones(rig, *prefixes):
    return [b for b in rig.pose.bones if b.name.startswith(prefixes)]


def _side(name):
    return name[-2:] if name[-2:] in (".L", ".R") else ""


def _key_x(pb, deg, frame):
    """Kemigi dunya X ekseni etrafinda `deg` derece dondurup karele."""
    rest = pb.bone.matrix_local.to_3x3()
    # Dunya X'i iskelet uzayina: domuzun iskeleti dunyaya gore Z'de 180 derece
    # donuk geliyor, aci orada ters isliyordu (olu domuzun basi yukari kalkti).
    axis = pb.id_data.matrix_world.to_3x3().inverted() @ Vector((1.0, 0.0, 0.0))
    q_arm = Quaternion(axis.normalized(), math.radians(deg))
    q = (rest.inverted() @ q_arm.to_matrix() @ rest).to_quaternion()
    pb.rotation_mode = "QUATERNION"
    pb.rotation_quaternion = q
    pb.keyframe_insert("rotation_quaternion", frame=frame)


def _key_loc(pb, world_offset, frame):
    rest = pb.bone.matrix_local.to_3x3()
    pb.location = rest.inverted() @ (pb.id_data.matrix_world.to_3x3().inverted() @ world_offset)
    pb.keyframe_insert("location", frame=frame)


def _new_action(rig, name):
    act = bpy.data.actions.new(name)
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = act
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
    rig.rotation_euler = (0, 0, 0)
    rig.location = (0, 0, 0)
    return act


def _neutral_keys(rig, frame):
    for pb in rig.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        pb.location = (0, 0, 0)
        pb.keyframe_insert("location", frame=frame)


def _legs(rig):
    """{(on/arka, taraf): (ust, alt)} - ayak kemikleri ayri donmuyor."""
    pb = rig.pose.bones
    out = {}
    for s in (".L", ".R"):
        out[("fore", s)] = (pb.get("FrontUpperLeg" + s), pb.get("FrontLowerLeg" + s))
        out[("hind", s)] = (pb.get("BackLeg" + s) or pb.get("BackUpperLeg" + s), pb.get("BackLowerLeg" + s))
    return out


def _root(rig):
    for n in ("Body", "Root"):
        if n in rig.pose.bones:
            return rig.pose.bones[n]
    return rig.pose.bones[0]


def _walk(rig, stride):
    act = _new_action(rig, "synth_walk")
    legs = _legs(rig)
    # Capraz cift ayni fazda (yakin on + uzak arka): dort ayaklinin yurumesi.
    phase = {("fore", ".L"): 0.0, ("hind", ".R"): 0.0, ("fore", ".R"): math.pi, ("hind", ".L"): math.pi}
    for f in range(FRAMES + 1):
        a = 2.0 * math.pi * f / FRAMES
        for key, (up, lo) in legs.items():
            p = a + phase.get(key, 0.0)
            swing = -stride * math.sin(p)
            if up is not None:
                _key_x(up, swing, f)
            if lo is not None:
                # Adimda (one gelirken) diz/bilek kirilir, basarken duz.
                bend = max(0.0, math.cos(p)) * stride * 1.4
                _key_x(lo, bend if key[0] == "fore" else -bend, f)
        _key_loc(_root(rig), _vec(0, 0, 0.02 * abs(math.sin(a))), f)
    return act


def _vec(x, y, z):
    from mathutils import Vector
    return Vector((x, y, z))


def _pose_all(rig, frame, legs_deg, body_pitch=0.0, head_deg=0.0, body_shift=(0, 0, 0)):
    legs = _legs(rig)
    for key, (up, lo) in legs.items():
        u, l = legs_deg.get(key[0], (0.0, 0.0))
        if up is not None:
            _key_x(up, u, frame)
        if lo is not None:
            _key_x(lo, l, frame)
    root = _root(rig)
    _key_x(root, body_pitch, frame)
    _key_loc(root, _vec(*body_shift), frame)
    for pb in _bones(rig, "Neck1", "Head"):
        _key_x(pb, head_deg, frame)


def _attack(rig, style, length):
    act = _new_action(rig, "synth_attack")
    if style == "rear":
        # Ayi: arka ayaklar uzerinde yarim dogrulur, on pencelerle one savurur.
        # Bacak kemiginin basi omzun tepesinde: -60'in otesinde pence cenenin
        # altina katlaniyor (olculdu, -95'te on bacak gorunmez oldu).
        keys = [(0, {}, 0, 0, (0, 0, 0)),
                (8, {"fore": (-40, 15), "hind": (14, -8)}, -22, -8, (0, 0.03 * length, 0)),
                (13, {"fore": (-58, -5), "hind": (18, -12)}, -28, -12, (0, 0.03 * length, 0)),
                (18, {"fore": (-30, 25), "hind": (5, 0)}, -4, 18, (0, -0.10 * length, 0)),
                (24, {}, 0, 0, (0, 0, 0))]
    else:
        # Domuz: bas egik one hamle, azi disleriyle yukari savurma.
        keys = [(0, {}, 0, 0, (0, 0, 0)),
                (7, {"fore": (10, -10), "hind": (15, -20)}, 6, 18, (0, 0.06 * length, -0.02 * length)),
                (13, {"fore": (-30, 15), "hind": (-15, 10)}, -4, 22, (0, -0.16 * length, 0)),
                (17, {"fore": (-20, 10), "hind": (-10, 5)}, -10, -25, (0, -0.16 * length, 0)),
                (24, {}, 0, 0, (0, 0, 0))]
    for f, legs, pitch, head, shift in keys:
        _pose_all(rig, f, legs, pitch, head, shift)
    return act


def _hit(rig, length):
    act = _new_action(rig, "synth_hit")
    for f, pitch, head, dy in ((0, 0, 0, 0), (5, 9, -18, 0.06), (11, 4, -8, 0.04), (16, 0, 0, 0)):
        _pose_all(rig, f, {"fore": (-pitch, pitch * 0.5), "hind": (pitch, 0)}, pitch, head, (0, dy * length, 0))
    return act


def _dead(rig, style):
    """Yere yigilmis hayvan; poz ture gore (STYLE["dead"]: on, arka, govde, bas).
    Bu iki modelin animasyonu yok ve iskeletleri sonradan oturtuldu; denenip
    birakilanlar: yan yatirmak (Y'de 90 derece) yandan bakan kamerada hayvani
    ustten gosterdi - bir kutu; bacaklari tamamen katlamak sekilsiz bir yigin
    yapti. Ayida bacaklar acik serilmis, domuzda gogus ustu cokmus poz en iyi
    okunan oldu - ikisi de zayif, QUESTIONS #16. Zemine indirme render'da."""
    act = _new_action(rig, "synth_dead")
    fore, hind, pitch, head = style["dead"]
    for f in (0, FRAMES):
        _pose_all(rig, f, {"fore": fore, "hind": hind}, pitch, head, (0, 0, 0))
    return act


def _downed(rig, length):
    act = _new_action(rig, "synth_downed")
    for f in (0, FRAMES):
        # Gogus ustu cokmus: on bacaklar one uzanik, arka bacaklar altina katli.
        _pose_all(rig, f, {"fore": (-70, 20), "hind": (-70, 120)}, 2, -6, (0, 0, 0))
    return act


def build(rig, species):
    style = STYLE.get(species, STYLE["bear"])
    ys = [rig.matrix_world @ b.head_local for b in rig.data.bones]
    length = max(v.y for v in ys) - min(v.y for v in ys)
    _walk(rig, style["stride"])
    _new_action(rig, "synth_idle")
    _neutral_keys(rig, 0)
    _neutral_keys(rig, FRAMES)
    _attack(rig, style["attack"], length)
    _hit(rig, length)
    _dead(rig, style)
    _downed(rig, length)
    for a in bpy.data.actions:
        if a.name.startswith("synth_"):
            a.use_fake_user = True
