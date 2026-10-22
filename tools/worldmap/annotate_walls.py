# -*- coding: utf-8 -*-
"""Her yerleşimin surunun malzemesini settlements.json'a yazar (`wall`: "wood",
"stone" ya da göçebe obasında "felt"). Kaynak kasaba sahnesinin kendisi (tools/ui_scenes/towns.json'daki
`wallrow`'un `wood` bayrağı): hub'daki kapı, kapı sahnesi ve kasaba görüntüsü
aynı kararı okusun diye oyun da bu alanı okuyor (Location.wall).

    python3 -X utf8 tools/worldmap/annotate_walls.py

Yalnızca `wall` alanını ekler; haritanın geri kalanını yeniden üretmez.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TOWNS = os.path.join(ROOT, "tools", "ui_scenes", "towns.json")
OUT = os.path.join(ROOT, "data", "config", "settlements.json")


def wall_of(town):
    specs = town.get("props", []) + town.get("buildings", [])
    if any(str(p.get("kind", "")).startswith("builder:yurt") for p in specs):
        return "felt"  # göçebe obası: sur yok, hasır çit ve tuğlar
    wood = any(p.get("kind") == "wallrow" and p.get("wood") for p in specs)
    return "wood" if wood else "stone"


def main():
    towns = json.load(open(TOWNS, encoding="utf-8"))
    doc = json.load(open(OUT, encoding="utf-8"))
    for s in doc["settlements"]:
        s["wall"] = wall_of(towns[s["id"]])
    with open(OUT, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(doc, fh, ensure_ascii=False, indent=1)
    print({w: sum(1 for s in doc["settlements"] if s["wall"] == w) for w in ("wood", "stone", "felt")})


if __name__ == "__main__":
    main()
