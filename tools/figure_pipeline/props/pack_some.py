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


def pack_one(pid):
    meta = json.load(open(os.path.join(pack_props.SRC, pid, "meta.json")))
    ax, ay = meta["anchor"]
    os.makedirs(os.path.join(pack_props.DST, pid), exist_ok=True)
    layers = {}
    for name in meta["layers"]:
        img = pack_props.compose(os.path.join(pack_props.SRC, pid, name + "__shade.png"),
                                 os.path.join(pack_props.SRC, pid, name + "__albedo.png"))
        bb = img.getchannel("A").point(lambda a: 255 if a > 4 else 0).getbbox()
        if bb is None:
            continue
        img = pack_props.ink_pass.light_pass(img.crop(bb))
        img.save(os.path.join(pack_props.DST, pid, name + ".png"), optimize=True)
        layers[name] = [bb[0] - ax, bb[1] - ay]
    return {
        "ppm": meta["ppm"], "view": meta["view"], "layers": layers,
        "pivots": {k: [x - ax, y - ay] for k, (x, y) in meta["pivots"].items()},
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
