# -*- coding: utf-8 -*-
"""Dış oyuncu testinin ilk dakikaları (görev Y-H02).

Oyun, bir oyuncunun dört ilkini (ilk karar, ilk tehdit, ilk kayıp tehlikesi,
ilk kârlı varış) gerçek oyun süresiyle user://playtest_times.json'a yazar.
Bu betik o dosyayı okuyup hedeflerle karşılaştırır.

Görev N31a: oyun ayrıca her karar ve bilgi anını (kart, seçim, yol işareti,
kamp, savaş, ekran değişimi) playtest_beats.jsonl'a yazar; betik buradan boş
dakikaları (iki an arasında hedefi aşan süre), en uzun sessizliği, savaşın ve
kampın sürelerini ve ekran başına geçen zamanı çıkarır.

    python -X utf8 tools/playtest_report.py [dosya] [beat_dosyası]

Varsayılan dosya Windows'ta %APPDATA%/Godot/app_userdata/Wayborne/playtest_times.json.
"""
import json
import os
import sys

NAMES = {"first_decision": "ilk karar", "first_threat": "ilk tehdit",
         "first_loss_risk": "ilk kayıp tehlikesi", "first_profit": "ilk kârlı varış"}


BEAT_TARGET = 90.0  # saniye: 1x'te en geç bu kadarda bir karar ya da bilgi anı (Y-B09)


def beat_report(rows):
    """Bir kervanın beat satırlarından özet: boş dakika, en uzun ara, savaş,
    kamp ve ekran süreleri. Saf fonksiyon (test: tests'te değil, burada
    `--self-test`)."""
    rows = sorted(rows, key=lambda r: float(r["t"]))
    moments = [float(r["t"]) for r in rows if r["kind"] in ("decision", "info")]
    gaps = [b - a for a, b in zip(moments, moments[1:])]
    idle = sum(max(0.0, g - BEAT_TARGET) for g in gaps)
    spans = {}
    for start, end, name in (("combat_start", "combat_end", "savaş"), ("camp_start", "camp_end", "kamp")):
        opened = None
        for r in rows:
            if r["kind"] == start:
                opened = float(r["t"])
            elif r["kind"] == end and opened is not None:
                spans.setdefault(name, []).append(float(r["t"]) - opened)
                opened = None
    screens = {}
    marks = [r for r in rows if r["kind"] == "screen"]
    for a, b in zip(marks, marks[1:] + [None]):
        until = float(b["t"]) if b else float(rows[-1]["t"])
        screens[a["detail"]] = screens.get(a["detail"], 0.0) + max(0.0, until - float(a["t"]))
    return {"moments": len(moments), "idle_minutes": idle / 60.0, "longest_gap": max(gaps) if gaps else 0.0,
            "mean_gap": sum(gaps) / len(gaps) if gaps else 0.0, "spans": spans, "screens": screens}


def print_beats(path):
    if not os.path.exists(path):
        print("beat dosyası yok:", path)
        return
    by_caravan = {}
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line:
            r = json.loads(line)
            by_caravan.setdefault(r.get("caravan", "?"), []).append(r)
    for caravan, rows in by_caravan.items():
        rep = beat_report(rows)
        print(f"── {caravan}: an ve boşluk")
        print(f"   karar/bilgi anı {rep['moments']}, ortalama ara {rep['mean_gap']:.0f} sn, "
              f"en uzun ara {rep['longest_gap']:.0f} sn")
        print(f"   boş dakika (hedef {BEAT_TARGET:.0f} sn'yi aşan): {rep['idle_minutes']:.1f} dk")
        for name, values in rep["spans"].items():
            print(f"   {name}: {len(values)} kez, ortalama {sum(values) / len(values):.0f} sn, en uzun {max(values):.0f} sn")
        for screen, seconds in sorted(rep["screens"].items(), key=lambda kv: -kv[1])[:8]:
            print(f"   ekran {screen:22s} {seconds / 60:5.1f} dk")


def self_test():
    rows = [{"t": 0, "kind": "screen", "detail": "city_map"}, {"t": 10, "kind": "decision", "detail": ""},
            {"t": 40, "kind": "screen", "detail": "road_journey"}, {"t": 50, "kind": "info", "detail": ""},
            {"t": 200, "kind": "decision", "detail": ""}, {"t": 210, "kind": "combat_start", "detail": ""},
            {"t": 260, "kind": "combat_end", "detail": ""}, {"t": 300, "kind": "info", "detail": ""}]
    rep = beat_report(rows)
    assert rep["moments"] == 4, rep
    assert abs(rep["idle_minutes"] - 70.0 / 60.0) < 1e-6, rep  # 150 ve 100 sn aralar -> 60 + 10 sn boş
    assert rep["longest_gap"] == 150.0, rep
    assert rep["spans"]["savaş"] == [50.0], rep
    assert abs(rep["screens"]["city_map"] - 40.0) < 1e-6 and abs(rep["screens"]["road_journey"] - 260.0) < 1e-6, rep
    print("öz sınama tamam")


def main(argv):
    if argv and argv[0] == "--self-test":
        self_test()
        return 0
    beats = argv[1] if len(argv) > 1 else os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata",
                                                         "Wayborne", "playtest_beats.jsonl")
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
    print_beats(beats)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
