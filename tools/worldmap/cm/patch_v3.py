"""Doğal köprü: kaya kemer görünümü + birleştirmede su tonundan muaf (2026-10-17)."""
p = "cm_full.py"
s = open(p, encoding="utf-8").read()


def rep(a, b):
    global s
    assert s.count(a) == 1, ("eşleşme yok/çok", a[:80])
    s = s.replace(a, b)


a = s.index("def _arch(ctx, hit):")
b = s.index("def vector_roads(")
s = s[:a] + '''def _arch_load():
    global ARCH
    if ARCH is None:
        import json
        ap = os.environ.get("CM_ARCH", "")
        ARCH = json.load(open(ap)) if ap and os.path.exists(ap) else {}
    return ARCH


def arch_outline(n=28):
    """Köprünün kaya gövdesi (harita pikseli): boğaza dik, kenarları düzensiz."""
    A = _arch_load()
    if not A:
        return None
    rng = np.random.default_rng(31)
    x, y, dx, dy, w = A["x"], A["y"], A["dx"], A["dy"], A["w"]
    nx, ny = -dy, dx
    L = w * 0.70
    t = np.linspace(-1, 1, n)
    waist = 13 + 5 * np.abs(t) ** 2                       # ortası ince, uçları kalın
    j1 = rng.normal(0, 1.6, n)
    j2 = rng.normal(0, 1.6, n)
    up = [(x + nx * L * u - dx * (h + e), y + ny * L * u - dy * (h + e)) for u, h, e in zip(t, waist, j1)]
    dn = [(x + nx * L * u + dx * (h + e), y + ny * L * u + dy * (h + e)) for u, h, e in zip(t[::-1], waist[::-1], j2)]
    return np.array(up + dn, np.float32)


def _arch(ctx, hit):
    """Boğazın ortasındaki doğal kaya köprüsü: yarlı, dar kaya kemer."""
    A = _arch_load()
    if not A:
        return
    x, y, dx, dy, w = A["x"], A["y"], A["dx"], A["dy"], A["w"]
    if not hit((x - w, y - w, x + w, y + w)):
        return
    poly = arch_outline()
    n = len(poly) // 2
    # akıntı yönünde kemerin gölgesi (suyun üstünde koyu yay)
    ctx.save()
    nx, ny = -dy, dx
    L = w * 0.70
    ctx.move_to(x - nx * L * 0.55 + dx * 20, y - ny * L * 0.55 + dy * 20)
    ctx.curve_to(x - nx * L * 0.2 + dx * 34, y - ny * L * 0.2 + dy * 34,
                 x + nx * L * 0.2 + dx * 34, y + ny * L * 0.2 + dy * 34,
                 x + nx * L * 0.55 + dx * 20, y + ny * L * 0.55 + dy * 20)
    ctx.set_source_rgba(*INK, 0.55)
    ctx.set_line_width(5.0)
    ctx.stroke()
    # gövde
    ctx.move_to(*poly[0])
    for q in poly[1:]:
        ctx.line_to(*q)
    ctx.close_path()
    ctx.set_source_rgb(*PAPER)
    ctx.fill_preserve()
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(1.8)
    ctx.stroke()
    # iki uzun kenarda yar taraması (içe doğru kısa çizgiler)
    ctx.set_line_width(0.9)
    for side, sgn in ((poly[:n], 1), (poly[n:], -1)):
        for k in range(2, n - 2):
            px, py = side[k]
            ln = 5 + 3 * ((k * 7) % 3)
            ctx.move_to(px, py)
            ctx.line_to(px + dx * sgn * ln, py + dy * sgn * ln)
    ctx.stroke()
    # üstte iki çatlak
    for u in (-0.3, 0.25):
        cx, cy = x + nx * L * u, y + ny * L * u
        ctx.move_to(cx - dx * 4, cy - dy * 4)
        ctx.line_to(cx + nx * 6 + dx * 3, cy + ny * 6 + dy * 3)
    ctx.stroke()
    ctx.restore()


''' + s[b:]

rep('''    wn = noise((N // 32, N // 32), 3, rng).astype(np.float32)''',
    '''    ap = arch_outline()
    if ap is not None:                      # köprü kayası su tonunu almaz
        am = np.zeros((G, G), np.uint8)
        cv2.fillPoly(am, [np.round(ap * G / N).astype(np.int32)], 1)
        wa_s = wa_s * (1 - cv2.dilate(am, np.ones((3, 3), np.uint8)).astype(np.float32))
    wn = noise((N // 32, N // 32), 3, rng).astype(np.float32)''')
open(p, "w", encoding="utf-8", newline="\n").write(s)
print("yama v3 tamam")
