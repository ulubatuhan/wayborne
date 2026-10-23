"""Yakın plan kümeleri (görev Y-G12): duruş karesinin 3 kat çözünürlüklü hâli.

    WAYBORNE_HD=3 blender -b --python tools/figure_pipeline/blender/render_frames.py -- --variant V --clip idle
    WAYBORNE_HD=3 blender -b --python tools/figure_pipeline/blender/render_outfits.py -- --variant V --clips idle
    python -X utf8 tools/figure_pipeline/mesh/pack_hd.py [--variants male_average,...] [--scale 3]
        [--items hair_short01,...] [--outfits-only]

--outfits-only: beden kümesi yeniden paketlenmez (kaynağı yine gerekir, kalemler
bedenin eklemlerine oturur); yeni kalem eklenince oyundaki beden kümesi değişmesin.

Girdi : build/figures/out_hd/<varyant>/idle, build/figures/outfits_hd/<varyant>/<kalem>/idle
Cikti : data/assets/characters/frames/body_<varyant>_hd, outfit_<kalem>_<varyant>_hd

Yoldaki figur render'in ~5'te biri boyunda cizildigi icin normal kume yetiyor;
karakter ekrani, gardirop ve konusma portresi figuru render boyundan buyuk
gosteriyordu ve kareler bulaniklasiyordu (kullanici notu: "yolda daha az
pikselle kaliteli bir manken gosterebiliyorken ayni mankeni gardiropta...").
Yalniz `idle` klibi, tek kare; oyun bu kumeyi duran figur icin kullanir
(WalkFigure.hd). Paketleme pack_frames / pack_outfits'in kendi kodu: kaynak
klasorleri, capa ve olcek degisir, kucultme yok (texel_scale 1).
"""
import json
import os
import shutil
import sys
import tempfile

ROOT = os.environ.get("WAYBORNE_ROOT") or os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
sys.path.insert(0, os.path.join(PIPE, "mesh"))
import pack_frames as P  # noqa: E402
import pack_outfits as PO  # noqa: E402

FRAMES = os.path.join(ROOT, "data", "assets", "characters", "frames")


def _move(tmp, ident, final):
    """Gecici paketi yerine tasir ve sayfa yollarini yeni kimlige cevirir."""
    src = os.path.join(tmp, ident)
    dest = os.path.join(FRAMES, final)
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    shutil.move(src, dest)
    tres = os.path.join(dest, "frames.tres")
    text = open(tres, encoding="utf-8").read()
    text = text.replace("/frames/%s/" % ident, "/frames/%s/" % final)
    open(tres, "w", encoding="utf-8", newline="\n").write(text)


def main():
    build = json.load(open(os.path.join(PIPE, "config", "build.json")))
    layers = json.load(open(os.path.join(PIPE, "config", "layers.json")))["layers"]
    post = json.load(open(os.path.join(PIPE, "config", "camera.json")))["posterize"]
    scale = float(sys.argv[sys.argv.index("--scale") + 1]) if "--scale" in sys.argv else 3.0
    variants = build["variants"]
    if "--variants" in sys.argv:
        variants = sys.argv[sys.argv.index("--variants") + 1].split(",")
    idle = dict(build["clips"]["idle"])
    idle["anchor_px"] = [v * scale for v in idle["anchor_px"]]
    hd_build = {"clips": {"idle": idle}}
    items = list(json.load(open(os.path.join(PIPE, "config", "outfits.json")))["items"])
    if "--items" in sys.argv:
        items = sys.argv[sys.argv.index("--items") + 1].split(",")
    outfits_only = "--outfits-only" in sys.argv
    tmp = tempfile.mkdtemp(prefix="hd_pack_")
    P.OUT = os.path.join(ROOT, "build", "figures", "out_hd")
    P.DEST = tmp
    PO.SRC = os.path.join(ROOT, "build", "figures", "outfits_hd")
    PO.BODY = P.OUT
    PO.DOWNSCALE = 1.0
    PO.CANVAS_W = PO.CANVAS_W * scale
    try:
        for v in variants:
            if not os.path.isdir(os.path.join(P.OUT, v, "idle")):
                print("yok:", v)
                continue
            if not outfits_only:
                P.pack_variant(v, hd_build, layers, post)
                _move(tmp, "body_" + v, "body_%s_hd" % v)
            for item in items:
                if not os.path.isdir(os.path.join(PO.SRC, v, item, "idle")):
                    continue
                PO.pack(v, item, hd_build, layers, post)
                ident = "outfit_%s_%s" % (item, v)
                if os.path.isdir(os.path.join(tmp, ident)):
                    _move(tmp, ident, ident + "_hd")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
