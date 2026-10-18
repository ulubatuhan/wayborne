"""referans harita haritası: renderer_zemin.html + yeniden yönlendirilmiş yollar + yerleşim
katmanı + bulut çerçevesi + sis sprite'ları -> tek dosyalık HTML.
Girdi build_html.py ile aynı; orijinal şablon/veri ezilmez.

    python3 build_html_zemin.py <zemin.png> <world_zemin.json> <yerleşim.png> <bulut_kenar.png> <bulut_klasörü> <çıktı.html>
"""
import base64
import glob
import io
import json
import os
import sys

from PIL import Image


def b64(im, fmt, size=None, **kw):
    if size:
        im = im.resize(size, Image.LANCZOS)
    b = io.BytesIO()
    im.save(b, fmt, **kw)
    return base64.b64encode(b.getvalue()).decode()


ground, world, settle, clouds, cdir, out = sys.argv[1:7]
here = os.path.dirname(os.path.abspath(__file__))
t = open(os.path.join(here, "renderer_zemin.html"), encoding="utf8").read()
g = Image.open(ground).convert("RGB")
t = t.replace("/*DATA*/", open(world, encoding="utf8").read())
t = t.replace("/*IMG*/", b64(g, "JPEG", (3072, 3072), quality=86, optimize=True, progressive=True))
t = t.replace("/*SETTLE*/", b64(Image.open(settle), "PNG", optimize=True))
t = t.replace("/*CLOUDS*/", b64(Image.open(clouds), "PNG", (2048, 2048), optimize=True))
fog = ["data:image/png;base64," + b64(Image.open(p).convert("RGBA"), "PNG",
       (300, int(300 * Image.open(p).height / Image.open(p).width)), optimize=True)
       for p in sorted(glob.glob(os.path.join(cdir, "cloud_*.png")))]
t = t.replace("/*FOG*/", json.dumps(fog))
open(out, "w", encoding="utf8").write(t)
print(out, round(len(t) / 1e6, 1), "MB")
