#!/usr/bin/env python3
"""Gömülü (base64) tek tamponlu .gltf dosyalarını .glb'ye çevirir (görev 5.5).

    python3 tools/gltf_to_glb.py art_source/models/animals/quaternius_gltf/glTF/*.gltf

Kayıpsız: JSON aynen kalır (yalnızca tamponun `uri` alanı düşer), ikili veri
birebir GLB'nin BIN parçasına girer. Base64 %33 şişirdiği için dosya küçülür.
Yanına `<ad>.glb` yazar; kaynak .gltf'yi silmek çağıranın işi.
"""
import base64
import json
import struct
import sys

MAGIC = 0x46546C67  # 'glTF'
JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942


def convert(path):
    doc = json.load(open(path, encoding="utf-8"))
    buffers = doc.get("buffers", [])
    if len(buffers) != 1 or not buffers[0].get("uri", "").startswith("data:"):
        raise SystemExit("%s: tek gömülü tampon bekleniyordu" % path)
    if any("uri" in image for image in doc.get("images", [])):
        raise SystemExit("%s: dış ya da gömülü görüntü var, desteklenmiyor" % path)
    blob = base64.b64decode(buffers[0]["uri"].split(",", 1)[1])
    if len(blob) != buffers[0]["byteLength"]:
        raise SystemExit("%s: tampon uzunluğu tutmuyor" % path)
    del buffers[0]["uri"]
    text = json.dumps(doc, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    text += b" " * (-len(text) % 4)
    blob += b"\0" * (-len(blob) % 4)
    total = 12 + 8 + len(text) + 8 + len(blob)
    out = path[: -len(".gltf")] + ".glb"
    with open(out, "wb") as f:
        f.write(struct.pack("<III", MAGIC, 2, total))
        f.write(struct.pack("<II", len(text), JSON_CHUNK) + text)
        f.write(struct.pack("<II", len(blob), BIN_CHUNK) + blob)
    return out


if __name__ == "__main__":
    for source in sys.argv[1:]:
        print(convert(source))
