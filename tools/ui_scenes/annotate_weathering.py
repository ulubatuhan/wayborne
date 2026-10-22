# -*- coding: utf-8 -*-
"""Yıpranmış kültürlerin yerleşimlerine `weathered` yazar (towns.json,
towns_phases.json, gates.json). town_scene.weather_materials bunu okuyup yapı
malzemelerine kir, akıntı izi, dipte toprak ve yosun ekliyor; kapı kesiti
(gate_cutout.py) aynı sahneden geldiği için yolun ucundaki kapı da yıpranıyor.

    python3 -X utf8 tools/ui_scenes/annotate_weathering.py

Sahneleri yeniden üretmez (settlement_towns.py bir yolun güzergâhını da
oynatabiliyordu); yalnızca bu alanı ekler ya da siler. Kaynak:
settlement_towns.CULTURES[kültür]["weathered"].
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SETTLEMENTS = os.path.join(ROOT, "data", "config", "settlements.json")
FILES = ("towns.json", "towns_phases.json", "gates.json")


def main():
    sys.path.insert(0, HERE)
    from settlement_towns import CULTURES
    amount = {s["id"]: CULTURES.get(s.get("culture"), {}).get("weathered", 0.0)
              for s in json.load(open(SETTLEMENTS, encoding="utf-8"))["settlements"]}
    for name in FILES:
        path = os.path.join(HERE, name)
        doc = json.load(open(path, encoding="utf-8"))
        marked = 0
        for key, cfg in doc.items():
            place = key.split("@")[0].removeprefix("gate_")
            value = amount.get(place, 0.0)
            if value > 0.0:
                cfg["weathered"] = value
                marked += 1
            else:
                cfg.pop("weathered", None)
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(doc, fh, ensure_ascii=False, indent=1)
        print(name, marked)


if __name__ == "__main__":
    main()
