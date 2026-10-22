"""Bir yerleşimin kapısını yandan, saydam arka planla eşya (prop) olarak kurar:
yolun sonunda ve hub'da kervanın vardığı kapı (kullanıcı, 2026-10-21: "yolun
sonuna geldiğimizde o şehir kapısına gelelim; yapıştırılmış bir resim değil,
yolun sonunun bir parçası olsun").

Kaynak kapı sahnesinin kendisi (gates.json, settlement_gates.py): aynı sur, aynı
kuleler, aynı bayraklar, aynı kütük ya da taş, arkasında aynı kasabanın çatıları.
Ağaçlar, zemin, tepe, meydan ve ufaktefek alınmaz; sur iki yana `HALF_SPAN`
metreyle kesilir (yol ekranı bir duvarın tamamını göstermez).

render_props.py'nin `builder` yolu çağırır (`"builder": "settlement_gate:<id>"`);
ışık, dört ton ve mürekkep öteki eşyalarla aynı hattan geçer.
"""
import json
import math
import os
import random
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
GATES = os.path.join(HERE, "gates.json")
# Kapı sahnesinde geçit (0, WALL_Y)'de, sur x ekseninde.
WALL_Y = 16.0
WALL_BAND = (13.4, 18.6)
# Surun arkası ayrı bir katman ("town"): oyun onu pusla, biraz yukarıda ve
# küçük çiziyor - yandan dik bir kamerada sur arkasındaki her şeyi örterdi,
# şehir yalnızca bir duvar olurdu (ölçüldü: 15 taş yerleşimin kesiti aynıydı).
BEHIND_MAX_Y = 78.0
HALF_SPAN = 21.0
TOWN_HALF_SPAN = 30.0
CLUTTER = ("Bags", "Hay", "Barrel", "Crate", "Cart", "Well", "Bench")


def _layer(spec):
    """"body", "town" ya da None."""
    kind = str(spec.get("kind", ""))
    if kind in ("palisade", "wallrow"):
        return "body"
    if kind in CLUTTER or kind in ("water", "quay"):
        return None
    at = spec.get("at")
    if at is None:
        return None
    x, y = at[0], at[1]
    if WALL_BAND[0] <= y <= WALL_BAND[1]:
        # Surun kendisi ve önündeki tuğ, çit, at: ağaç değil.
        if abs(x) > HALF_SPAN + 2.0 or kind.startswith("ftk:tree"):
            return None
        return "body"
    if kind.startswith("ftk:") and not kind.startswith(("ftk:windmill", "ftk:watermill")):
        return None  # ağaç, kaya, sancak: yolun kendi ağaç hattı var
    if WALL_BAND[1] < y <= BEHIND_MAX_Y and abs(x) <= TOWN_HALF_SPAN:
        return "town"
    return None


def _clipped(spec):
    if spec.get("kind") == "palisade":
        out = dict(spec)
        (x0, y0), (x1, y1) = spec["from"], spec["to"]
        gate_x = x0 + (x1 - x0) * spec.get("gate", 0.5)
        out["from"] = [gate_x - HALF_SPAN, y0]
        out["to"] = [gate_x + HALF_SPAN, y1]
        out["gate"] = 0.5
        return out
    return spec


def _built(before):
    return [o for o in bpy.context.scene.objects if o not in before and o.type == "MESH" and not o.hide_render]


def settlement_gate(city):
    os.environ["WAYBORNE_TOWN_CFG"] = GATES
    if HERE not in sys.path:
        sys.path.insert(0, HERE)
    import town_scene
    town_scene.CFG = GATES
    town_scene._cache.clear()  # render_props her eşyada sahneyi sıfırlıyor: eski şablonlar yok
    cfg = json.load(open(GATES))["gate_" + city]
    random.seed(cfg.get("seed", 1))
    layers = {"body": [], "town": []}
    for spec in cfg.get("props", []) + cfg.get("buildings", []):
        layer = _layer(spec)
        if layer is None:
            continue
        before = set(bpy.context.scene.objects)
        town_scene.building(_clipped(spec))
        layers[layer].extend(_built(before))
    town_scene.texture_materials(tuple(cfg.get("window", [1.0, 0.55, 0.22])) + (1.0,), 0.0)
    town_scene.weather_materials(cfg.get("weathered", 0.0))
    meshes = layers["body"] + layers["town"]
    # Yandan bakan kamera +x'e bakıyor ve ekranın sağı -y: sahneyi -90° çevir,
    # geçidi orijine, tabanı z=0'a al (render_props.normalize'ın ölçeksiz hâli).
    root = bpy.data.objects.new("gate_root", None)
    bpy.context.scene.collection.objects.link(root)
    bpy.context.view_layer.update()
    for o in [o for o in bpy.context.scene.objects if o.parent is None and o is not root]:
        mw = o.matrix_world.copy()
        o.parent = root
        o.matrix_world = mw
    root.rotation_euler = (0.0, 0.0, math.radians(-90.0))
    bpy.context.view_layer.update()
    gate = root.matrix_world @ Vector((0.0, WALL_Y, 0.0))
    lo_z = min((o.matrix_world @ Vector(c)).z for o in layers["body"] for c in o.bound_box)
    root.location = (-gate.x, -gate.y, -lo_z)
    bpy.context.view_layer.update()
    return {k: v for k, v in layers.items() if v}, {}
