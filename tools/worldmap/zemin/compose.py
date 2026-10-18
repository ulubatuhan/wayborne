"""Önizleme: zemin + referans harita tarzı yollar + yerleşim katmanı (yalnız sunum için;
oyunda yollar HTML katmanında çizilir)."""
import json
import sys

import numpy as np
from PIL import Image, ImageDraw


def smooth_path(p, k=4):
    p = np.array(p, np.float64)
    for _ in range(k):  # Chaikin
        q = [p[0]]
        for a, b in zip(p[:-1], p[1:]):
            q += [a * 0.75 + b * 0.25, a * 0.25 + b * 0.75]
        q.append(p[-1])
        p = np.array(q)
    return [tuple(x) for x in p]


def roads_layer(world, n=4096, ss=2):
    im = Image.new("RGBA", (n * ss, n * ss), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    # kara parçaları ve feribot (suda) parçaları ayrı: feribot kesik çizgi
    land, ferry = [], []
    for rd in world["roads"]:
        P = [(x * ss, y * ss) for x, y in rd["p"]]
        wet = rd.get("wet", [0] * len(P))
        cur, cw = [P[0]], bool(wet[0])
        for q, w in zip(P[1:], wet[1:]):
            if bool(w) != cw:
                (ferry if cw else land).append((rd["c"], cur + [q]))
                cur, cw = [q], bool(w)
            else:
                cur.append(q)
        (ferry if cw else land).append((rd["c"], cur))
    for c, p in land:  # koyu kenar
        if len(p) > 1:
            dr.line(p, fill=(92, 70, 40, 210), width=int((9 if c == "road" else 5.5) * ss), joint="curve")
    for c, p in land:  # krem toprak yol
        if len(p) > 1:
            dr.line(p, fill=(224, 208, 164, 255), width=int((6.5 if c == "road" else 3.2) * ss), joint="curve")
    for c, p in ferry:
        p = np.array(p)
        if len(p) < 2:
            continue
        seg = np.cumsum(np.r_[0, np.hypot(*np.diff(p, axis=0).T)])
        dash = 14 * ss
        for a in np.arange(0, seg[-1], dash * 2):
            q = [tuple(np.interp([t], seg, p[:, 0]).tolist() + np.interp([t], seg, p[:, 1]).tolist())
                 for t in np.linspace(a, min(a + dash, seg[-1]), 4)]
            dr.line(q, fill=(70, 56, 38, 230), width=int(3 * ss))
    return im.resize((n, n), Image.LANCZOS)


def main():
    ground, settle, world_p, out = sys.argv[1:5]
    g = Image.open(ground).convert("RGBA")
    g.alpha_composite(roads_layer(json.load(open(world_p))))
    g.alpha_composite(Image.open(settle))
    if len(sys.argv) > 5:
        g.alpha_composite(Image.open(sys.argv[5]))
    g.convert("RGB").save(out, quality=92)
    print("YAZILDI", out)


if __name__ == "__main__":
    main()
