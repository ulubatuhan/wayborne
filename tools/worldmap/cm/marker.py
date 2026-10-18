"""Haritada oyuncunun konumunu gösteren kervan işareti (mürekkep-parşömen dilinde).

usage: python3 -I marker.py <out_dir>
Çıktı: kervan_isareti.svg, kervan_isareti_{48,64,96,128,256}.png ve _vurgulu (koyu kırmızı halkalı) varyantı.
Bağlantı noktası (konumun tam üstüne oturan nokta): alttaki sivri ucun ucu = (0.5 * W, 1.0 * H).
"""
import math
import os
import sys

import cairo

INK = (0.14, 0.10, 0.07)
PAPER = (0.93, 0.88, 0.76)
ACCENT = (0.55, 0.16, 0.12)          # koyu kırmızı (mühür)
W, H = 100.0, 128.0                  # tasarım birimi


def draw(ctx, accent):
    cx, cy, R = 50.0, 50.0, 40.0
    # gölge
    ctx.save()
    ctx.translate(2.2, 2.6)
    _pin_path(ctx, cx, cy, R)
    ctx.set_source_rgba(0, 0, 0, 0.28)
    ctx.fill()
    ctx.restore()
    # madalyon + sivri uç
    _pin_path(ctx, cx, cy, R)
    ctx.set_source_rgb(*PAPER)
    ctx.fill_preserve()
    ctx.set_source_rgb(*(ACCENT if accent else INK))
    ctx.set_line_width(4.2)
    ctx.stroke()
    # iç halka
    ctx.arc(cx, cy, R - 7.5, 0, 2 * math.pi)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(1.4)
    ctx.stroke()
    # kervan arabası: örtülü vagon
    ctx.save()
    ctx.translate(cx, cy + 4)
    ctx.set_line_join(cairo.LINE_JOIN_ROUND)
    # örtü (yay biçimli bez)
    ctx.move_to(-21, 2)
    ctx.curve_to(-22, -20, -6, -24, 0, -24)
    ctx.curve_to(6, -24, 22, -20, 21, 2)
    ctx.close_path()
    ctx.set_source_rgb(*PAPER)
    ctx.fill_preserve()
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(2.2)
    ctx.stroke()
    # örtü kaburgaları (tarama dili)
    ctx.set_line_width(1.1)
    for x in (-11, 0, 11):
        ctx.move_to(x, -22 + abs(x) * 0.25)
        ctx.line_to(x * 1.05, 2)
    ctx.stroke()
    # gövde
    ctx.rectangle(-24, 2, 48, 8)
    ctx.set_source_rgb(*INK)
    ctx.fill()
    # tekerlekler
    for x in (-14, 14):
        ctx.arc(x, 13, 6.2, 0, 2 * math.pi)
        ctx.set_source_rgb(*PAPER)
        ctx.fill_preserve()
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(2.0)
        ctx.stroke()
        for k in range(4):
            a = k * math.pi / 4
            ctx.move_to(x - 6 * math.cos(a), 13 - 6 * math.sin(a))
            ctx.line_to(x + 6 * math.cos(a), 13 + 6 * math.sin(a))
        ctx.set_line_width(0.9)
        ctx.stroke()
    # ok (çeki demiri)
    ctx.move_to(24, 6)
    ctx.line_to(31, 3)
    ctx.set_line_width(2.0)
    ctx.stroke()
    ctx.restore()
    # flama: madalyonun üstünde küçük sancak
    ctx.move_to(cx + 22, cy - 26)
    ctx.line_to(cx + 22, cy - 46)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(1.8)
    ctx.stroke()
    ctx.move_to(cx + 22, cy - 46)
    ctx.line_to(cx + 36, cy - 42)
    ctx.line_to(cx + 22, cy - 38)
    ctx.close_path()
    ctx.set_source_rgb(*(ACCENT if accent else INK))
    ctx.fill()


def _pin_path(ctx, cx, cy, R):
    a = math.radians(28)
    ctx.new_path()
    ctx.arc(cx, cy, R, math.pi / 2 + a, math.pi / 2 - a + 2 * math.pi)
    ctx.line_to(cx, H - 2)
    ctx.close_path()


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for accent, suf in ((False, ""), (True, "_vurgulu")):
        s = cairo.SVGSurface(os.path.join(out, "kervan_isareti%s.svg" % suf), W, H)
        draw(cairo.Context(s), accent)
        s.finish()
        for px in (48, 64, 96, 128, 256):
            h = int(round(px * H / W))
            surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, px, h)
            c = cairo.Context(surf)
            c.scale(px / W, h / H)
            draw(c, accent)
            surf.write_to_png(os.path.join(out, "kervan_isareti%s_%d.png" % (suf, px)))
    print("tamam")


if __name__ == "__main__":
    main()
