#!/usr/bin/env python3
"""Harita karo piramidini oyunun varlık klasörüne kopyalar (görev 8.1).

    python3 tools/worldmap/install_tiles.py xx/TODO/harita_final/goruntuleyici/t

Hedef `data/assets/map/tiles/<seviye>/<x>_<y>.jpg` (MapTileView bunu okur).
Karolar 49 MB; git'e girmiyor (.gitignore) - LFS kararı (görev 6.1) verilince
değişecek.
"""
import os
import shutil
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
DEST = os.path.join(ROOT, "data", "assets", "map", "tiles")


def main(source):
    if not os.path.isdir(source):
        raise SystemExit("karo klasörü yok: %s" % source)
    count = 0
    for level in sorted(os.listdir(source)):
        src_dir = os.path.join(source, level)
        if not os.path.isdir(src_dir) or not level.isdigit():
            continue
        os.makedirs(os.path.join(DEST, level), exist_ok=True)
        for name in os.listdir(src_dir):
            if name.endswith(".jpg"):
                shutil.copy2(os.path.join(src_dir, name), os.path.join(DEST, level, name))
                count += 1
    print("%d karo kopyalandı -> %s" % (count, DEST))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "")
