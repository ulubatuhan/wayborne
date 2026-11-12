#!/usr/bin/env python3
"""Oyun testi koşularını (build/playtest/<profil>/<tohum>/ozet.json) tek tabloda toplar.

Kullanım: python3 tools/playtest_toplam.py [kök=build/playtest] > build/playtest/toplam.txt
"""
import glob
import json
import statistics
import sys

kok = sys.argv[1] if len(sys.argv) > 1 else "build/playtest"
kosular = {}
for yol in sorted(glob.glob(f"{kok}/*/*/ozet.json")):
    kosular.setdefault(yol.split("/")[-3], []).append(json.load(open(yol, encoding="utf-8")))


def ortanca(degerler):
    dolu = [d for d in degerler if d is not None]
    return round(statistics.median(dolu), 1) if dolu else None


print("profil tohum | kervan sefer kart farkli tekrar savas kazanilan olu ac_gece bos_tur yol_gunu karli "
      "iyi_ort iyi_max iz_dogan iz_donen yanki bedel")
for profil, liste in kosular.items():
    for o in liste:
        s, i, z = o["sayaclar"], o["iyi_sey_arasi"], o["iz"]
        print(profil, o["tohum"], "|", o["kervan_sayisi"], s["sefer"], s["kart"], o["farkli_kart"],
              o["tekrar_orani"], s["savas"], s["savas_kazanilan"], s["olu"], s["ac_gece"], s["bos_tur"],
              s["yol_gunu"], s["karli_varis"], i["ortalama_gun"], i["en_uzun_gun"], z["dogan"], z["donen"],
              o["yanki"], o["bedel_odeyen"])

print("\nilkler (sn, ortanca; eksik = hiç olmadı)")
for profil, liste in kosular.items():
    adlar = sorted({k for o in liste for k in o["ilkler_oturum"]})
    print(profil, {k: ortanca([o["ilkler_oturum"].get(k) for o in liste]) for k in adlar},
          "eksik:", {k: sum(1 for o in liste if k not in o["ilkler_oturum"]) for k in adlar
                     if any(k not in o["ilkler_oturum"] for o in liste)})

print("\nhuni (ortanca): an kese erzak kadro vagon moral kart sefer olu ac_gece bos_tur borc")
for profil, liste in kosular.items():
    for j in range(len(liste[0]["huni"])):
        dilim = [o["huni"][j] for o in liste if j < len(o["huni"])]
        print(profil, dilim[0]["ad"], *[ortanca([h.get(k) for h in dilim]) for k in
              ["kese", "erzak", "kadro", "vagon", "moral", "kart", "sefer", "olu", "ac_gece", "bos_tur", "borc"]])

print("\nölüm sebepleri ve ilk ölüm anı (sn)")
for profil, liste in kosular.items():
    sayim, ilk = {}, []
    for o in liste:
        for d in o["olumler"]:
            sayim[d["sebep"]] = sayim.get(d["sebep"], 0) + 1
        if o["olumler"]:
            ilk.append(o["olumler"][0]["t_sn"])
    print(profil, sayim, ilk)

print("\nen çok görülen kartlar")
for profil, liste in kosular.items():
    sayim = {}
    for o in liste:
        for k, v in o["kart_gorulme"].items():
            sayim[k] = sayim.get(k, 0) + v
    print(profil, sorted(sayim.items(), key=lambda x: -x[1])[:6])
