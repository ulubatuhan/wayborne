# -*- coding: utf-8 -*-
"""Dış oyuncu testinin ilk dakikaları (görev Y-H02).

Oyun, bir oyuncunun dört ilkini (ilk karar, ilk tehdit, ilk kayıp tehlikesi,
ilk kârlı varış) gerçek oyun süresiyle user://playtest_times.json'a yazar.
Bu betik o dosyayı okuyup hedeflerle karşılaştırır.

    python -X utf8 tools/playtest_report.py [dosya]

Varsayılan dosya Windows'ta %APPDATA%/Godot/app_userdata/Wayborne/playtest_times.json.
"""
import json
import os
import sys

NAMES = {"first_decision": "ilk karar", "first_threat": "ilk tehdit",
         "first_loss_risk": "ilk kayıp tehlikesi", "first_profit": "ilk kârlı varış"}


def main(argv):
    path = argv[0] if argv else os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata", "Wayborne",
                                             "playtest_times.json")
    if not os.path.exists(path):
        print("dosya yok:", path)
        return 1
    rows = json.load(open(path, encoding="utf-8"))
    by_caravan = {}
    for r in rows:
        by_caravan.setdefault(r.get("caravan", "?"), {})[r["mark"]] = r
    for caravan, marks in by_caravan.items():
        print(f"── {caravan}")
        for mark, name in NAMES.items():
            r = marks.get(mark)
            if r is None:
                print(f"   {name:22s} yaşanmadı")
                continue
            s, target = float(r["seconds"]), float(r["target"])
            verdict = "tamam" if s <= target else "GEÇ"
            print(f"   {name:22s} {s / 60:5.1f} dk  (hedef {target / 60:.0f} dk)  {verdict}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
