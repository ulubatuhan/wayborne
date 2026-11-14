# -*- coding: utf-8 -*-
"""Galeri ağızlarının (Y-A07) render kaynakları: Poly Haven'dan CC0 doku ve
model indirir, `build/dungeon_src/`'ye (depoda değil; her oturum yeniden
indirir, lisans listesi `art_source/models/props/LICENSES.md`'de).

    python3 -I tools/dungeon/fetch_assets.py

Dokular 2K jpg (renk, OpenGL normal, pürüzlülük, yükseklik); modeller 1K glTF.
Seçim gerekçesi `build_dungeon.py`'nin başında.
"""
import json
import os
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "build", "dungeon_src")
API = "https://api.polyhaven.com/files/"

TEXTURES = [
    "dark_rock", "dark_rock_02", "rock_face_03", "quarry_wall_02", "rocks_ground_02", "rocky_trail",
    "rock_wall_16", "japanese_stone_wall", "monastery_stone_floor", "rock_tile_floor",
    "plastered_stone_wall", "bark_willow_02", "brown_planks_03", "rock_surface", "concrete_wall_006",
    "worn_plaster_wall", "grey_plaster_02",
]
MAPS = {"diff": "Diffuse", "nor": "nor_gl", "rough": "Rough", "disp": "Displacement"}
MODELS = [
    "namaqualand_boulder_02", "namaqualand_boulder_03", "namaqualand_boulder_05", "rock_07", "rock_09",
    "stone_01", "namaqualand_stones_01", "wooden_bucket_01", "wooden_crate_01", "picke_dirty_01",
    "wicker_basket_01", "wooden_bowl_01",
]


def _get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read()


def _save(url: str, path: str) -> None:
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = _get(url)
    with open(path, "wb") as fh:
        fh.write(data)


def fetch_texture(asset: str) -> None:
    files = json.loads(_get(API + asset))
    for short, key in MAPS.items():
        entry = files[key]["2k"]
        fmt = "jpg" if "jpg" in entry else "png"
        _save(entry[fmt]["url"], os.path.join(OUT, "tex", asset, "%s.%s" % (short, fmt)))


def fetch_model(asset: str) -> None:
    files = json.loads(_get(API + asset))
    gltf = files["gltf"]["1k"]["gltf"]
    folder = os.path.join(OUT, "models", asset)
    _save(gltf["url"], os.path.join(folder, os.path.basename(gltf["url"])))
    for rel, info in gltf.get("include", {}).items():
        _save(info["url"], os.path.join(folder, rel))


def main() -> int:
    for asset in TEXTURES:
        fetch_texture(asset)
        print("doku", asset)
    for asset in MODELS:
        fetch_model(asset)
        print("model", asset)
    return 0


if __name__ == "__main__":
    sys.exit(main())
