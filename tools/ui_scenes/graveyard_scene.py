# -*- coding: utf-8 -*-
"""Kilise ve mezarlık arka planı (görev 9.12): Kenney Graveyard Kit (CC0) ile
iki varyant - sakin (yalnız ay) ve nöbet (fenerler, ateş sepeti, mumlar).
Haç ve haçlı taşlar paketten hiç alınmadı (Art Rules: dinî sembol yok).

    python -X utf8 tools/ui_scenes/graveyard_scene.py          # graveyards.json yazar
    WAYBORNE_TOWN_CFG=tools/ui_scenes/graveyards.json blender -b --python tools/ui_scenes/town_scene.py -- --city graveyard_calm
    WAYBORNE_TOWN_CFG=... WAYBORNE_TOWN_OUT=build/graveyard python -X utf8 tools/ui_scenes/town_post.py graveyard_calm

Gök, ay ve ışık kasabaların diliyle (kuzeyin soğuk ışığı: Kesgrav'ın tanımından).
"""
import copy
import json
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
TOWNS = os.path.join(HERE, "towns.json")
OUT = os.path.join(HERE, "graveyards.json")
GY = "file:art_source/models/props/kenney_graveyard/"
STONES = ["gravestone-round", "gravestone-wide", "gravestone-bevel", "gravestone-broken",
          "gravestone-decorative", "gravestone-roof", "gravestone-debris"]
STONE_SCALE = 1.8


def base(look_from="kesgrav"):
    town = json.load(open(TOWNS, encoding="utf-8"))[look_from]
    cfg = copy.deepcopy(town)
    cfg["buildings"] = []
    # Mezarlıkta kaldırım yok, uzak tepe gökyüzünü kaplıyordu: toprak zemin, tepe yok.
    cfg["plaza"] = [0.0, -200.0, 0.1]
    cfg.pop("hill", None)
    cfg["camera"] = {"at": [0.0, -6.0, 1.7], "look": [0.0, 14.0, 2.6], "lens": 28}
    cfg["far"] = 70.0
    rng = random.Random(912)
    props = []
    for y in (6.0, 9.0, 12.0, 15.0):
        x = -9.0 + rng.uniform(-0.4, 0.4)
        while x < 9.5:
            kind = rng.choice(STONES)
            props.append({"kind": GY + kind + ".glb", "at": [round(x, 2), y + rng.uniform(-0.3, 0.3)],
                          "rot": rng.randint(-8, 8), "scale": STONE_SCALE})
            if rng.random() < 0.55:
                props.append({"kind": GY + "grave.glb", "at": [round(x, 2), y - 1.3], "rot": rng.randint(-4, 4),
                              "scale": STONE_SCALE})
            x += rng.uniform(2.0, 2.8)
    for x in range(-14, 15, 2):
        props.append({"kind": GY + "stone-wall.glb", "at": [float(x), 21.0], "scale": 2.2})
    props.append({"kind": GY + "crypt-large.glb", "at": [6.5, 18.0], "rot": 180, "scale": 2.4})
    props.append({"kind": GY + "crypt-large-roof.glb", "at": [6.5, 18.0], "rot": 180, "scale": 2.4})
    props.append({"kind": GY + "pillar-obelisk.glb", "at": [-5.5, 17.5], "scale": 2.2})
    for x, y, s in ((-12.0, 24.0, 3.2), (11.5, 26.0, 3.0), (-3.5, 28.0, 3.4), (16.0, 12.0, 2.8), (-16.0, 10.0, 2.6)):
        props.append({"kind": GY + rng.choice(["pine.glb", "pine-crooked.glb"]), "at": [x, y], "scale": s})
    for x in (-13.0, -11.0, 11.0, 13.0):
        props.append({"kind": GY + "iron-fence.glb", "at": [x, 3.0], "scale": 2.0})
    cfg["props"] = props
    cfg["lamps"] = []
    return cfg


def vigil(cfg):
    """Nöbet: aynı mezarlık, fenerler ve ateş sepeti yanık, birkaç mezarda mum."""
    out = copy.deepcopy(cfg)
    for x, y in ((-4.0, 8.0), (5.0, 10.5)):
        out["props"].append({"kind": GY + "lightpost-single.glb", "at": [x, y], "scale": 1.8})
        out["lamps"].append([x, y - 0.3, 2.2, 160])
    out["props"].append({"kind": GY + "fire-basket.glb", "at": [0.5, 11.0], "scale": 2.0})
    out["lamps"].append([0.5, 11.0, 0.6, 260])
    for x, y in ((-6.8, 6.2), (2.6, 9.2), (7.4, 12.1)):
        out["props"].append({"kind": GY + "lantern-candle.glb", "at": [x, y - 0.6], "scale": 1.6})
        out["lamps"].append([x, y - 0.6, 0.5, 40])
    out["moon"] = cfg.get("moon", 1.0) * 0.7
    return out


def main():
    calm = base()
    data = {"graveyard_calm": calm, "graveyard_vigil": vigil(calm)}
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("yazıldı:", OUT)


if __name__ == "__main__":
    main()
