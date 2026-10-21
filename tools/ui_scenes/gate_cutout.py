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
WALL_BAND = (14.0, 18.6)
BEHIND_MAX_Y = 45.0
HALF_SPAN = 21.0
CLUTTER = ("Bags", "Hay", "Barrel", "Crate", "Cart", "Well", "Bench")


def _keep(spec):
    kind = str(spec.get("kind", ""))
    if kind in ("palisade", "wallrow"):
        return True
    if kind.startswith("ftk:") or kind in CLUTTER:
        return False
    if spec.get("terrace"):
        # Setli yukarı şehir (çan kulesi, setli ev) yandan surun iki katı yükseliyor;
        # yol ekranı kapıyı ona göre küçültüp suru çimenin arkasına gömüyordu.
        return False
    at = spec.get("at")
    if at is None:
        return False
    x, y = at[0], at[1]
    if abs(x) > HALF_SPAN + 2.0:
        return False
    if WALL_BAND[0] <= y <= WALL_BAND[1]:
        return True
    return WALL_BAND[1] < y <= BEHIND_MAX_Y and not spec.get("dark")


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


def settlement_gate(city):
    os.environ["WAYBORNE_TOWN_CFG"] = GATES
    if HERE not in sys.path:
        sys.path.insert(0, HERE)
    import town_scene
    town_scene.CFG = GATES
    town_scene._cache.clear()  # render_props her eşyada sahneyi sıfırlıyor: eski şablonlar yok
    cfg = json.load(open(GATES))["gate_" + city]
    random.seed(cfg.get("seed", 1))
    for spec in cfg.get("props", []) + cfg.get("buildings", []):
        if _keep(spec):
            town_scene.building(_clipped(spec))
    town_scene.texture_materials(tuple(cfg.get("window", [1.0, 0.55, 0.22])) + (1.0,), 0.0)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.hide_render]
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
    lo_z = min((o.matrix_world @ Vector(c)).z for o in meshes for c in o.bound_box)
    root.location = (-gate.x, -gate.y, -lo_z)
    bpy.context.view_layer.update()
    return {"body": meshes}, {}
