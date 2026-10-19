# -*- coding: utf-8 -*-
"""Bütün yerleşimlerin kasaba resmini yeniden üretir (görev 12.1: geniş kadraj).

Her yer için Blender'ı arka planda (-b, pencere açmaz) town_scene.py ile
çalıştırır, ardından town_post.py ile mürekkep geçişini yapar. Resim ve
maske aynı kameradan geldiği için CityFront tıklama eşlemesi hizalı kalır.

    python -X utf8 tools/ui_scenes/render_all_towns.py [kimlik ...] [--samples 64]

Blender yolu WAYBORNE_BLENDER ortam değişkeninden, yoksa araclar/ altındaki
4.2 kurulumundan okunur. Tam set uzun sürer (yer başına birkaç dakika);
bilgisayar boştayken çalıştırılır.
"""
import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
CFG = os.path.join(HERE, "towns.json")
DEFAULT_BLENDER = os.path.join(os.path.dirname(ROOT), "araclar", "blender", "blender-4.2.23-windows-x64", "blender.exe")
# Eski dünyanın şehirleri ve menünün kampı bu turun dışında (kamp kendi kadrajında).
SKIP = {"karakonak", "ipekevi", "demirkapi", "kurtbogazi", "yesilova", "camp"}


def main(argv):
    samples = argv[argv.index("--samples") + 1] if "--samples" in argv else "64"
    names = [a for a in argv if not a.startswith("--") and a != samples]
    towns = json.load(open(CFG, encoding="utf-8"))
    ids = names or [k for k in towns if k not in SKIP]
    blender = os.environ.get("WAYBORNE_BLENDER", DEFAULT_BLENDER)
    env = dict(os.environ, WAYBORNE_ROOT=ROOT)
    failed = []
    for i, city in enumerate(ids, 1):
        start = time.time()
        r = subprocess.run([blender, "-b", "--python", os.path.join(HERE, "town_scene.py"), "--",
                            "--city", city, "--samples", samples], env=env,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if r.returncode == 0:
            r = subprocess.run([sys.executable, "-X", "utf8", os.path.join(HERE, "town_post.py"), city])
        status = "tamam" if r.returncode == 0 else "HATA"
        if r.returncode != 0:
            failed.append(city)
        print(f"[{i}/{len(ids)}] {city}: {status} ({time.time() - start:.0f} sn)", flush=True)
    print("bitti; hatalı:", failed or "yok")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
