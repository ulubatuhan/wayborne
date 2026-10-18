"""16384 px haritayı yakınlaştırılabilir görüntüleyici için 1024 px karolara böler.
Seviye L'de görüntü 1024*2^L px; seviye 4 tam çözünürlük."""
import os
import sys

from PIL import Image

Image.MAX_IMAGE_PIXELS = None
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGB")
size = im.size[0]
level = 4
cur = im
while level >= 0:
    n = cur.size[0] // 1024
    d = os.path.join(out, "t", str(level))
    os.makedirs(d, exist_ok=True)
    for y in range(n):
        for x in range(n):
            cur.crop((x * 1024, y * 1024, (x + 1) * 1024, (y + 1) * 1024)).save(
                os.path.join(d, "%d_%d.jpg" % (x, y)), quality=80, optimize=True, progressive=True)
    print("seviye", level, n * n, flush=True)
    if level:
        cur = cur.resize((cur.size[0] // 2,) * 2, Image.LANCZOS)
    level -= 1
