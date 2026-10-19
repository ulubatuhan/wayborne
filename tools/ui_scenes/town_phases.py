# -*- coding: utf-8 -*-
"""Yerleşim resimlerinin gün evresi varyantları (görevler 9.3, N33; kullanıcı
kararı 2026-10-19: "sabah, gündüz, akşam, gece ve her şehir için kültürüne
göre ayrı"). Taban resim (towns.json) gece; bu araç her yerleşim için sabah,
gündüz ve akşam sahne tanımlarını yazar (`towns_phases.json`, anahtar
"<yer>@<evre>"), kamera ve yapılar aynı kalır, böylece mask.png piksel hizalı.

Değişen yalnızca ışık ve gök: güneşin açısı ve rengi, gökyüzünün renkleri,
pencerelerin ve fenerlerin yanıp yanmadığı, sis, pozlama. Her yerleşimin
kendi rengi korunur: ufuk rengi tabanınkiyle evrenin rengi arasında karışır
(kültürün paleti - kuzeyin soğuğu, güneyin sıcağı - her evrede okunur).

    python -X utf8 tools/ui_scenes/town_phases.py
    WAYBORNE_TOWN_CFG=tools/ui_scenes/towns_phases.json blender -b --python tools/ui_scenes/town_scene.py -- --city vastrevar@day
    WAYBORNE_TOWN_CFG=tools/ui_scenes/towns_phases.json python -X utf8 tools/ui_scenes/town_post.py vastrevar@day
"""
import copy
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
TOWNS = os.path.join(HERE, "towns.json")
OUT = os.path.join(HERE, "towns_phases.json")
SKIP = {"camp", "tavern", "graveyard_calm", "graveyard_vigil", "karakonak", "ipekevi", "demirkapi",
        "kurtbogazi", "yesilova"}

# Evre -> (render: gök, güneş, pencere, fener; post: gök renkleri, disk, sis, pozlama)
PHASES = {
    "morning": {
        "sky": {"horizon": [0.80, 0.58, 0.48], "zenith": [0.24, 0.30, 0.44], "height": 0.25, "strength": 2.2},
        "moon": 2.6, "moon_color": [1.0, 0.86, 0.72], "moon_rot": [76, 115],
        "backlight": 0.35, "backlight_color": [1.0, 0.75, 0.55], "window_strength": 1.2, "lamp_scale": 0.12,
        "post": {"zenith": [70, 86, 118], "horizon": [226, 186, 160], "cloud": [212, 194, 188],
                 "fog": [188, 178, 184], "fog_amount": 0.42, "exposure": 1.05, "glow": 0.15,
                 "shadow": [58, 50, 62], "moon": [0.16, 0.56], "disc_r": 0.045,
                 "disc_color": [0.48, 0.40, 0.32], "disc_soft": 0.55, "halo": 0.5, "halo_r": 0.3},
        "mix": 0.25,
    },
    "day": {
        "sky": {"horizon": [0.78, 0.76, 0.70], "zenith": [0.36, 0.44, 0.56], "height": 0.3, "strength": 3.0},
        "moon": 4.2, "moon_color": [1.0, 0.96, 0.88], "moon_rot": [38, 160],
        "backlight": 0.0, "window_strength": 0.0, "lamp_scale": 0.0,
        "post": {"zenith": [92, 112, 140], "horizon": [212, 206, 192], "cloud": [232, 228, 220],
                 "fog": [198, 198, 194], "fog_amount": 0.32, "exposure": 0.98, "glow": 0.0,
                 "shadow": [68, 64, 70], "moon": None},
        "mix": 0.12,
    },
    "evening": {
        "sky": {"horizon": [0.82, 0.42, 0.22], "zenith": [0.10, 0.09, 0.18], "height": 0.22, "strength": 1.6},
        "moon": 1.9, "moon_color": [1.0, 0.56, 0.30], "moon_rot": [81, 250],
        "backlight": 1.4, "backlight_color": [1.0, 0.5, 0.28], "window_strength": 6.0, "lamp_scale": 1.0,
        # Akşam göğü mor değil (stil kuralı: doygun mor yok): tepe nötr koyu
        # taş, bulut ve pus sıcak kahve; renk ufuktaki turuncu banttan gelir.
        "post": {"zenith": [36, 33, 38], "horizon": [212, 116, 62], "cloud": [104, 80, 70],
                 "fog": [122, 94, 84], "fog_amount": 0.44, "exposure": 1.22, "glow": 0.8,
                 "shadow": [40, 31, 32], "moon": [0.82, 0.58], "disc_r": 0.055,
                 "disc_color": [0.78, 0.48, 0.24], "disc_soft": 0.7, "halo": 0.55, "halo_r": 0.28},
        "mix": 0.3,
    },
}


def mix(a, b, t):
    return [round(x * (1 - t) + y * t, 3) for x, y in zip(a, b)]


def phase_cfg(base, phase):
    spec = PHASES[phase]
    cfg = copy.deepcopy(base)
    for key in ("moon", "moon_color", "moon_rot", "backlight", "backlight_color", "window_strength", "lamp_scale"):
        if key in spec:
            cfg[key] = spec[key]
    sky = dict(spec["sky"])
    # Kültürün rengi: tabanın ufku evrenin ufkuna biraz karışır.
    sky["horizon"] = mix(sky["horizon"], base["sky"]["horizon"], spec["mix"])
    cfg["sky"] = sky
    post = dict(base["post"])
    post.update(spec["post"])
    post["horizon"] = [int(round(v)) for v in mix(spec["post"]["horizon"], base["post"]["horizon"], spec["mix"])]
    cfg["post"] = post
    return cfg


def main():
    towns = json.load(open(TOWNS, encoding="utf-8"))
    out = {}
    for city, cfg in towns.items():
        if city in SKIP or "post" not in cfg:
            continue
        for phase in PHASES:
            out["%s@%s" % (city, phase)] = phase_cfg(cfg, phase)
    json.dump(out, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("yazıldı:", OUT, len(out), "sahne")


if __name__ == "__main__":
    main()
