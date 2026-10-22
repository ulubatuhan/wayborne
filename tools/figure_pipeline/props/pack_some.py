"""pack_props.py'nin seçici hâli: yalnız verilen eşyaları paketler, props.tres'teki
ötekilere dokunmaz. build/props her eşyanın son render'ını tutmuyor (bazıları
başka makinede render edildi), yani tam paketleme oyundaki eşyaları eskisiyle
ezebilir.

    python3 -I tools/figure_pipeline/props/pack_some.py gate_akavan gate_belvanor ...
    python3 -I tools/figure_pipeline/props/pack_some.py --prefix gate_
"""
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pack_props  # noqa: E402

TRES_HEAD = "props = "


def read_sheet(path):
    text = open(path).read()
    return json.loads(text[text.index(TRES_HEAD) + len(TRES_HEAD):].strip())


# Kapının geçidi (yerleşim kapısı kesitleri): oyun geçidin içini karartıyor,
# kanadı ya da parmaklığı orada çiziyor, gece meşaleleri iki yanına koyuyor.
# Render'ın kendisinden ölçülüyor: çapanın sütununda yerden yukarı ilk dolu
# piksel geçidin tepesi, yarı yükseklikte iki yana ilk dolu piksel söveler.
DOOR_ALPHA = 40
DOOR_MAX_H_M = 4.6
DOOR_MAX_W_M = 6.0


def door_pivots(img, ax, ay, ppm):
    a = img.getchannel("A").load()
    w, h = img.size
    ax, ay = int(round(ax)), int(round(ay))
    if not (0 <= ax < w and 0 < ay <= h):
        return {}
    y = ay - 3
    limit = ay - int(DOOR_MAX_H_M * ppm)
    while y > max(limit, 0) and a[ax, y] < DOOR_ALPHA:
        y -= 1
    if y >= ay - 3 - int(0.8 * ppm):
        return {}  # geçit yok (dolu duvar)
    top = y
    mid = ay - int(min(1.2 * ppm, (ay - top) * 0.5))
    reach = int(DOOR_MAX_W_M * 0.5 * ppm)
    lx = ax
    while lx > ax - reach and lx > 0 and a[lx, mid] < DOOR_ALPHA:
        lx -= 1
    rx = ax
    while rx < ax + reach and rx < w - 1 and a[rx, mid] < DOOR_ALPHA:
        rx += 1
    return {"door_l": [lx - ax, mid - ay], "door_r": [rx - ax, mid - ay], "door_top": [0, top - ay]}


def pack_one(pid):
    meta = json.load(open(os.path.join(pack_props.SRC, pid, "meta.json")))
    ax, ay = meta["anchor"]
    os.makedirs(os.path.join(pack_props.DST, pid), exist_ok=True)
    layers = {}
    extra = {}
    for name in meta["layers"]:
        img = pack_props.compose(os.path.join(pack_props.SRC, pid, name + "__shade.png"),
                                 os.path.join(pack_props.SRC, pid, name + "__albedo.png"))
        if name == "body" and pid.startswith("gate_"):
            extra = door_pivots(img, ax, ay, meta["ppm"])
        bb = img.getchannel("A").point(lambda a: 255 if a > 4 else 0).getbbox()
        if bb is None:
            continue
        img = pack_props.ink_pass.light_pass(img.crop(bb))
        img.save(os.path.join(pack_props.DST, pid, name + ".png"), optimize=True)
        layers[name] = [bb[0] - ax, bb[1] - ay]
    return {
        "ppm": meta["ppm"], "view": meta["view"], "layers": layers,
        "pivots": dict({k: [x - ax, y - ay] for k, (x, y) in meta["pivots"].items()}, **extra),
        "size_m": meta["size_m"],
    }


def main(argv):
    if argv[:1] == ["--prefix"]:
        ids = sorted(p for p in os.listdir(pack_props.SRC)
                     if p.startswith(argv[1]) and os.path.exists(os.path.join(pack_props.SRC, p, "meta.json")))
    else:
        ids = argv
    path = os.path.join(pack_props.DST, "props.tres")
    sheet = read_sheet(path)
    for pid in ids:
        sheet[pid] = pack_one(pid)
        print("paketlendi", pid)
    tres = ('[gd_resource type="Resource" script_class="PropSheet" load_steps=2 format=3]\n\n'
            '[ext_resource type="Script" path="res://scripts/ui/prop_sheet.gd" id="1"]\n\n'
            '[resource]\nscript = ExtResource("1")\nprops = %s\n' % pack_props._gd(sheet))
    open(path, "w").write(tres)


if __name__ == "__main__":
    main(sys.argv[1:])
