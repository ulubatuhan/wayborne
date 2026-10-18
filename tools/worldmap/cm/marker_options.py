"""Kervan işareti için alternatif öneriler (mürekkep dili). Haritadan bir kesitin üstünde gösterir.
usage: python marker_options.py <map_16384.png> <out.jpg>
"""
import math
import sys

import cairo
import numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = None
INK = (0.14, 0.10, 0.07)
PAPER = (0.93, 0.88, 0.76)
RED = (0.55, 0.16, 0.12)


def wheel(c, x, y, s):          # A: tekerlek mührü
    R = 22 * s
    c.arc(x, y, R + 5 * s, 0, 2 * math.pi); c.set_source_rgb(*RED); c.fill()
    c.arc(x, y, R, 0, 2 * math.pi); c.set_source_rgb(*PAPER); c.fill_preserve()
    c.set_source_rgb(*INK); c.set_line_width(2.4 * s); c.stroke()
    c.arc(x, y, R * 0.72, 0, 2 * math.pi); c.set_line_width(2.0 * s); c.stroke()
    for k in range(8):
        a = k * math.pi / 4
        c.move_to(x + 4 * s * math.cos(a), y + 4 * s * math.sin(a))
        c.line_to(x + R * 0.72 * math.cos(a), y + R * 0.72 * math.sin(a))
    c.set_line_width(1.8 * s); c.stroke()
    c.arc(x, y, 4 * s, 0, 2 * math.pi); c.fill()


def lantern(c, x, y, s):        # B: fener + ışık halesi
    g = cairo.RadialGradient(x, y, 2, x, y, 46 * s)
    g.add_color_stop_rgba(0, 1.0, 0.85, 0.45, 0.85)
    g.add_color_stop_rgba(1, 1.0, 0.85, 0.45, 0.0)
    c.set_source(g); c.arc(x, y, 46 * s, 0, 2 * math.pi); c.fill()
    c.set_source_rgb(*INK); c.set_line_width(2.0 * s)
    c.arc(x, y - 22 * s, 6 * s, math.pi, 2 * math.pi); c.stroke()            # tutamak
    c.move_to(x - 11 * s, y - 16 * s); c.line_to(x + 11 * s, y - 16 * s)
    c.line_to(x + 8 * s, y - 12 * s); c.line_to(x - 8 * s, y - 12 * s); c.close_path(); c.fill()
    c.rectangle(x - 8 * s, y - 12 * s, 16 * s, 22 * s)
    c.set_source_rgb(1.0, 0.86, 0.5); c.fill_preserve(); c.set_source_rgb(*INK); c.stroke()
    for dx in (-3, 3):
        c.move_to(x + dx * s, y - 12 * s); c.line_to(x + dx * s, y + 10 * s)
    c.set_line_width(1.2 * s); c.stroke()
    c.move_to(x - 11 * s, y + 10 * s); c.line_to(x + 11 * s, y + 10 * s)
    c.line_to(x + 8 * s, y + 15 * s); c.line_to(x - 8 * s, y + 15 * s); c.close_path(); c.fill()


def banner(c, x, y, s):         # C: sancak
    c.set_source_rgba(0, 0, 0, 0.25); c.save(); c.translate(x, y); c.scale(1, 0.35)
    c.arc(0, 0, 9 * s, 0, 2 * math.pi); c.restore(); c.fill()
    c.set_source_rgb(*INK); c.set_line_width(2.6 * s)
    c.move_to(x, y); c.line_to(x, y - 52 * s); c.stroke()
    c.move_to(x, y - 52 * s); c.curve_to(x + 14 * s, y - 56 * s, x + 22 * s, y - 46 * s, x + 34 * s, y - 50 * s)
    c.line_to(x + 28 * s, y - 40 * s); c.line_to(x + 34 * s, y - 30 * s)
    c.curve_to(x + 22 * s, y - 26 * s, x + 14 * s, y - 36 * s, x, y - 32 * s); c.close_path()
    c.set_source_rgb(*RED); c.fill_preserve(); c.set_source_rgb(*INK); c.set_line_width(1.6 * s); c.stroke()
    c.arc(x + 14 * s, y - 42 * s, 4 * s, 0, 2 * math.pi); c.set_source_rgb(*PAPER); c.fill()


def mini(c, x, y, s):           # D: minyatür kervan (araba + öküz)
    c.set_line_join(cairo.LINE_JOIN_ROUND)
    c.set_source_rgb(*INK); c.set_line_width(1.6 * s)
    # öküz
    c.save(); c.translate(x + 20 * s, y - 6 * s)
    c.move_to(-8 * s, 0); c.curve_to(-8 * s, -9 * s, 6 * s, -9 * s, 8 * s, -4 * s); c.line_to(13 * s, -5 * s)
    c.line_to(12 * s, 1 * s); c.line_to(7 * s, 1 * s); c.line_to(6 * s, 6 * s); c.move_to(-6 * s, 1 * s); c.line_to(-6 * s, 6 * s)
    c.restore(); c.stroke()
    c.move_to(x + 4 * s, y - 4 * s); c.line_to(x + 12 * s, y - 6 * s); c.stroke()
    # araba
    c.move_to(x - 16 * s, y - 6 * s); c.curve_to(x - 16 * s, y - 22 * s, x + 4 * s, y - 22 * s, x + 4 * s, y - 6 * s)
    c.close_path(); c.set_source_rgb(*PAPER); c.fill_preserve(); c.set_source_rgb(*INK); c.stroke()
    for k in (-10, -4, 2):
        c.move_to(x + k * s, y - 19 * s); c.line_to(x + k * s, y - 6 * s)
    c.set_line_width(0.9 * s); c.stroke()
    c.rectangle(x - 17 * s, y - 6 * s, 22 * s, 4 * s); c.fill()
    for wx in (-12, 0):
        c.arc(x + wx * s, y, 4 * s, 0, 2 * math.pi); c.set_source_rgb(*PAPER); c.fill_preserve()
        c.set_source_rgb(*INK); c.set_line_width(1.4 * s); c.stroke()
    # kırmızı nokta: konum
    c.arc(x - 4 * s, y + 10 * s, 3.5 * s, 0, 2 * math.pi); c.set_source_rgb(*RED); c.fill()


def star(c, x, y, s):           # E: pusula yıldızı + halka
    c.arc(x, y, 20 * s, 0, 2 * math.pi); c.set_source_rgb(*INK); c.set_line_width(1.6 * s); c.stroke()
    c.arc(x, y, 24 * s, 0, 2 * math.pi); c.set_line_width(0.9 * s); c.stroke()
    for k in range(4):
        a = k * math.pi / 2 - math.pi / 2
        for side, col in ((-1, INK), (1, PAPER)):
            c.move_to(x, y)
            c.line_to(x + 30 * s * math.cos(a), y + 30 * s * math.sin(a))
            c.line_to(x + 6 * s * math.cos(a + side * math.pi / 4), y + 6 * s * math.sin(a + side * math.pi / 4))
            c.close_path(); c.set_source_rgb(*col); c.fill_preserve(); c.set_source_rgb(*INK); c.set_line_width(1.2 * s); c.stroke()
    c.arc(x, y, 3.5 * s, 0, 2 * math.pi); c.set_source_rgb(*RED); c.fill()


OPTS = [("A  Tekerlek mührü", wheel), ("B  Fener", lantern), ("C  Sancak", banner),
        ("D  Minyatür kervan", mini), ("E  Pusula yıldızı", star)]

src, dst = sys.argv[1:3]
im = Image.open(src)
CW, CH = 360, 300
cx0, cy0 = 6433 - 520, 3556 + 260          # Vastrevar'ın güneyinde sakin bir kesit (görüntü pikseli)
crop = im.crop((cx0, cy0, cx0 + CW * 2, cy0 + CH * 2)).resize((CW, CH), Image.LANCZOS).convert("RGB")
cols = len(OPTS)
sheet = cairo.ImageSurface(cairo.FORMAT_RGB24, cols * (CW + 12) + 12, CH * 2 + 70)
c = cairo.Context(sheet)
c.set_source_rgb(0.11, 0.09, 0.07); c.paint()
arr = np.asarray(crop)
bgra = np.dstack([arr[..., 2], arr[..., 1], arr[..., 0], np.full(arr.shape[:2], 255, np.uint8)]).copy()
bg = cairo.ImageSurface.create_for_data(memoryview(bgra), cairo.FORMAT_RGB24, CW, CH, CW * 4)
for i, (name, fn) in enumerate(OPTS):
    ox = 12 + i * (CW + 12)
    # üst: harita üstünde gerçek boyut (oyunda görüleceği gibi)
    c.set_source_surface(bg, ox, 12); c.paint()
    c.new_path(); fn(c, ox + CW / 2, 12 + CH / 2 + 10, 1.0); c.new_path()
    # alt: büyük
    c.set_source_rgb(*PAPER); c.rectangle(ox, CH + 24, CW, CH - 24); c.fill()
    c.new_path(); fn(c, ox + CW / 2, CH + 24 + (CH - 24) / 2 + 20, 2.6); c.new_path()
    c.set_source_rgb(0.92, 0.87, 0.76); c.select_font_face("Georgia", 0, 1); c.set_font_size(16)
    c.move_to(ox + 4, CH * 2 + 56); c.show_text(name)
sheet.write_to_png(dst.replace(".jpg", ".png"))
Image.open(dst.replace(".jpg", ".png")).convert("RGB").save(dst, quality=90)
print("ok")
