# -*- coding: utf-8 -*-
"""Şehir kapısı sahneleri (görev 12.2a): her yerleşimin kasaba sahnesinden
türeyen, yoldan bakılan bir kapı sahnesi tanımı yazar (`gates.json`).

    python -X utf8 tools/ui_scenes/settlement_gates.py            # hepsi
    python -X utf8 tools/ui_scenes/settlement_gates.py vastrevar  # tek yer

Ardından (pencere açmaz):
    WAYBORNE_TOWN_CFG=tools/ui_scenes/gates.json blender -b --python tools/ui_scenes/town_scene.py -- --city gate_<id>
    WAYBORNE_TOWN_CFG=... WAYBORNE_TOWN_OUT=build/gates python -X utf8 tools/ui_scenes/town_post.py gate_<id>

Sahne kasabanınkiyle aynı dilde (gök, ay, ışık, kar, zemin, pencere rengi):
  - yola bakan sur (Quaternius Modular Medieval): ortada giriş, iki yanında
    kule, uçlarda gözcü kulesi;
  - kemerin iki yanında meşale ışığı;
  - kasabanın yüksek yapıları (kule, lonca, kilise, kale) surun arkasına kayar,
    meydanın tezgâhları ve sandıkları atılır - kapıdan şehrin yalnızca silueti
    görünür (kullanıcı kararı: kervan şehre girmez, kapı önünde durur);
  - kapının iki yanında birkaç ağaç, yol kameradan kemere uzanır.
"""
import copy
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOWNS = os.path.join(HERE, "towns.json")
OUT = os.path.join(HERE, "gates.json")
SKIP = {"karakonak", "ipekevi", "demirkapi", "kurtbogazi", "yesilova", "camp"}

WALL_Y = 16.0
SHIFT_Y = 10.0
WALL_SCALE = 2.5
TOWER_SCALE = 3.0
# Meydan eşyası: kapı sahnesine girmez.
PLAZA_KINDS = {"MarketStand_1", "MarketStand_2", "Cart", "Barrel", "Crate", "ftk:fountain-round",
               "ftk:lantern", "ftk:banner-red", "ftk:banner-green", "Well"}


def _y(spec):
    at = spec.get("at") or spec.get("from")
    return float(at[1]) if at else 0.0


## Kulenin genişliği kadar sur, kulenin hemen arkasında: duvar boyu surun
## kendisiyle aynı (WALL_SCALE), genişlik birden çok parçayla kapanır.
WALL_BEHIND_DEPTH = 0.45


def _wall_behind(qm, cx, width, value):
    unit = 1.52 * WALL_SCALE
    count = max(1, int(-(-width // unit)))
    span = count * unit
    out = []
    for k in range(count):
        x = cx - span / 2 + unit * (k + 0.5)
        out.append({"kind": qm + "TallWall.blend", "at": [x, WALL_Y + WALL_BEHIND_DEPTH], "scale": WALL_SCALE,
                    "stone": value})
    return out


def gate_config(town):
    cfg = copy.deepcopy(town)
    keep = []
    for spec in town["buildings"] + town.get("props", []):
        if spec.get("kind") in PLAZA_KINDS or spec.get("kind") == "wallrow":
            continue
        # Meydanın önündekiler (kameraya yakın evler) de kalkar; geridekiler surun arkasına.
        if _y(spec) < 9.0:
            continue
        moved = copy.deepcopy(spec)
        for key in ("at", "from", "to"):
            if key in moved:
                moved[key] = [moved[key][0], moved[key][1] + SHIFT_Y] + list(moved[key][2:])
        moved.pop("venue", None)
        keep.append(moved)
    value = next((p.get("value", 0.3) for p in town.get("props", []) if p.get("kind") == "wallrow"), 0.3)
    # Sur Quaternius Modular Medieval parçalarından (CC0): ortada giriş, iki
    # yanında kule, sonra duvar dizisi, uçlarda gözcü kulesi. Ölçüler paketin
    # biriminde ölçüldü (TallWall 1.52 geniş, Entrance 1.78, Tower 1.12).
    qm = "file:art_source/models/props/quaternius_modular_medieval/"
    # Yuvarlak, ince ve balkonlu Tower minare gibi okunuyor (Art Rules: ibadet
    # yeri silueti yok); kapıyı kare, çatılı gözcü kuleleri tutar.
    keep.append({"kind": qm + "TallWallEntrance.blend", "at": [0.0, WALL_Y], "scale": WALL_SCALE, "venue": "gate",
                 "stone": value})
    tower_x = 1.78 * WALL_SCALE / 2 + 1.5 * TOWER_SCALE / 2
    for side in (-1, 1):
        keep.append({"kind": qm + "WatchTowerWRoof.blend", "at": [side * tower_x, WALL_Y], "scale": TOWER_SCALE,
                     "stone": value})
        # Kullanıcı notu (karar A5, 2026-10-21): gözcü kulesi direkler üstünde
        # açık bir çatkı; altında duvar yoktu, sur kulenin altından kopuyordu.
        # Sur kulenin arkasından geçer: kule duvarın üstünde yükselir.
        keep.extend(_wall_behind(qm, side * tower_x, 1.5 * TOWER_SCALE, value))
        x = tower_x + 1.5 * TOWER_SCALE / 2 + 1.52 * WALL_SCALE / 2
        for i in range(6):
            keep.append({"kind": qm + "TallWall.blend", "at": [side * x, WALL_Y], "scale": WALL_SCALE, "stone": value})
            x += 1.52 * WALL_SCALE
            if i == 3:
                keep.append({"kind": qm + "WatchTowerWRoof.blend", "at": [side * (x + 0.6), WALL_Y],
                             "scale": TOWER_SCALE * 0.85, "stone": value})
                keep.extend(_wall_behind(qm, side * (x + 0.6), 1.5 * TOWER_SCALE * 0.85, value))
                x += 1.5 * TOWER_SCALE * 0.85 + 0.6
    for x, tree in ((-12.0, "ftk:tree-high"), (13.5, "ftk:tree-high-crooked"), (-17.5, "ftk:tree-high")):
        keep.append({"kind": tree, "at": [x, 7.0 + abs(x) * 0.2], "scale": 1.0})
    cfg["buildings"] = []
    cfg["props"] = keep
    cfg["lamps"] = [[-2.6, WALL_Y - 2.0, 2.8, 120], [2.6, WALL_Y - 2.0, 2.8, 120]]
    cfg["camera"] = {"at": [0.0, -11.0, 1.7], "look": [0.0, WALL_Y, 5.8], "lens": 30}
    cfg["far"] = 90.0
    return cfg


def main(argv):
    towns = json.load(open(TOWNS, encoding="utf-8"))
    ids = argv or [k for k in towns if k not in SKIP]
    gates = json.load(open(OUT, encoding="utf-8")) if os.path.exists(OUT) else {}
    sys.path.insert(0, HERE)
    import town_phases
    for city in ids:
        gate = gate_config(towns[city])
        gates["gate_" + city] = gate
        # Gündüz kapısı (12.2a): aynı sahne, town_phases'ın gündüz ışığıyla;
        # kamera ve yapılar aynı, piksel hizalı.
        if "post" in gate:
            gates["gate_%s@day" % city] = town_phases.phase_cfg(gate, "day")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(gates, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("yazıldı:", len(ids), "kapı ->", OUT)


if __name__ == "__main__":
    main(sys.argv[1:])
