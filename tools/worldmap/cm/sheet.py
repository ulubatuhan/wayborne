"""Deneme sayfası: her kültürün kenti ve küçük yerleşimler yan yana."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import cairo
import numpy as np
from PIL import Image

import towns as T
from hand import PAPER
from paper import finish

SS = 3
OUT_SCALE = float(os.environ.get("OUT_SCALE", 1))
W, H = 1500, 760
surf = cairo.ImageSurface(cairo.FORMAT_RGB24, W * SS, H * SS)
ctx = cairo.Context(surf)
ctx.scale(SS, SS)
ctx.set_source_rgb(*PAPER)
ctx.paint()
cults = ["vadi", "ahit", "sinir", "imparatorluk", "guney", "dag"]
for i, c in enumerate(cults):
    x = 140 + (i % 3) * 460
    y = 200 + (i // 3) * 300
    T.city(ctx, np.random.default_rng(i + 1), x, y, c, 105)
    ctx.select_font_face("IM FELL English SC")
    ctx.set_font_size(18)
    ctx.set_source_rgb(0.17, 0.12, 0.09)
    ctx.move_to(x - 40, y + 75)
    ctx.show_text(c.upper())
small = [(T.village, "vadi"), (T.farm, "vadi"), (T.lumber, "sinir"), (T.swamp_town, "sinir"), (T.abbey, "ahit"),
         (T.camp, "gocebe")]
for i, (fn, c) in enumerate(small):
    x, y = 340 + (i % 3) * 460, 250 + (i // 3) * 300
    fn(ctx, np.random.default_rng(50 + i), x, y, c)
T.tower_post(ctx, np.random.default_rng(9), 420, 120, "imparatorluk")
T.stones(ctx, np.random.default_rng(9), 880, 120)
T.gallows(ctx, np.random.default_rng(9), 1340, 120)
T.battle(ctx, np.random.default_rng(9), 1400, 680)
buf = np.frombuffer(surf.get_data(), np.uint8).reshape(H * SS, W * SS, 4)[..., [2, 1, 0]]
img = finish(buf.astype(np.float32) / 255, SS)
Image.fromarray(img).resize((int(W * OUT_SCALE), int(H * OUT_SCALE)), Image.LANCZOS).save(sys.argv[1])
