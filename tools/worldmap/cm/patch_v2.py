"""cm_full.py'ye d.docx düzenlemeleri (2026-10-17). Her değişiklik birebir eşleşme ister."""
p = "cm_full.py"
s = open(p, encoding="utf-8").read()


def rep(a, b):
    global s
    assert s.count(a) == 1, ("eşleşme yok/çok", a[:80])
    s = s.replace(a, b)


# 1) göçebe bölgesinde kervansaray yok
rep('''    for i, q in enumerate(serais):
        # yolun hemen kenarına''', '''    cult = np.array([[p["x"] * P, p["y"] * P] for p in places])
    keep_i = [i for i, q in enumerate(serais)
              if places[int(np.argmin(np.hypot(*(cult - np.asarray(q)).T)))]["c"] != "gocebe"]
    print("kervansaray (göçebe bölgesi dışında)", [SERAI_NAMES[i] for i in keep_i])
    serais = [serais[i] for i in keep_i]
    for i, q in zip(keep_i, serais):
        # yolun hemen kenarına''')

# 2) pusula yok
rep('''    _furniture(ctx, sc, hit)
    buf''', '''    _arch(ctx, hit)
    buf''')

# 3) yollar: ana yol hafif kalın, patika aynı
rep('''    core = np.clip(ndi.gaussian_filter(line.astype(np.float32), 0.75) * 2.6, 0, 1)
    bed = np.clip(ndi.gaussian_filter(line.astype(np.float32), 2.0) * 6, 0, 1) * 0.9''',
    '''    if ROAD_MAIN is not None:
        main = np.zeros((H, W), bool)
        main[ya - oy:yb - oy, xa - ox:xb - ox] = ROAD_MAIN[ya:yb, xa:xb]
        line = line | ndi.binary_dilation(main & line, iterations=1)
    core = np.clip(ndi.gaussian_filter(line.astype(np.float32), 0.75) * 2.6, 0, 1)
    bed = np.clip(ndi.gaussian_filter(line.astype(np.float32), 2.0) * 6, 0, 1) * 0.9''')
rep('''ROAD_LINE = None


def road_line_global''', '''ROAD_LINE = None
ROAD_MAIN = None


def road_line_global''')
rep('''    global ROAD_LINE
    sc = pickle.load(open(os.path.join(out, "scene_final.pkl"), "rb"))
    F = Fields(os.environ["CM_FIELDS"])
    ROAD_LINE = np.unpackbits(np.load(os.path.join(out, "roads_clean.npy")))[:N * N].reshape(N, N).astype(bool)''',
    '''    global ROAD_LINE, ROAD_MAIN
    sc = pickle.load(open(os.path.join(out, "scene_final.pkl"), "rb"))
    F = Fields(os.environ["CM_FIELDS"])
    ROAD_LINE = np.unpackbits(np.load(os.path.join(out, "roads_clean.npy")))[:N * N].reshape(N, N).astype(bool)
    mp = os.path.join(out, "roads_main.npy")
    if os.path.exists(mp):
        ROAD_MAIN = np.unpackbits(np.load(mp))[:N * N].reshape(N, N).astype(bool)''')

# 4) vektör yollar + doğal köprü + kırpma
rep('''# ------------------------------------------------------------------ birleştir''',
    '''ARCH = None


def _arch(ctx, hit):
    """Boğazın ortasındaki doğal kaya köprüsü: suyun üstünden geçen dar kaya kemer."""
    global ARCH
    if ARCH is None:
        import json
        ap = os.environ.get("CM_ARCH", "")
        ARCH = json.load(open(ap)) if ap and os.path.exists(ap) else {}
    if not ARCH:
        return
    x, y, dx, dy, w = ARCH["x"], ARCH["y"], ARCH["dx"], ARCH["dy"], ARCH["w"]
    if not hit((x - w, y - w, x + w, y + w)):
        return
    nx, ny = -dy, dx                       # köprü boğaza dik uzanır
    L, B = w * 0.62, 11.0                  # yarı uzunluk, yarı genişlik
    ctx.save()
    ctx.translate(x, y)
    ctx.transform(cairo.Matrix(nx, ny, dx, dy, 0, 0))
    # gövde: kâğıt, iki uzun kenar hafif kavisli
    ctx.move_to(-L, -B)
    ctx.curve_to(-L * 0.3, -B - 5, L * 0.3, -B - 5, L, -B)
    ctx.line_to(L, B)
    ctx.curve_to(L * 0.3, B + 5, -L * 0.3, B + 5, -L, B)
    ctx.close_path()
    ctx.set_source_rgb(*PAPER)
    ctx.fill_preserve()
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(1.6)
    ctx.stroke()
    # kemerin altı: akış yönünde gölge yayı ve kısa taramalar
    ctx.set_line_width(1.0)
    ctx.move_to(-L * 0.55, B + 3)
    ctx.curve_to(-L * 0.2, B + 12, L * 0.2, B + 12, L * 0.55, B + 3)
    ctx.stroke()
    for k in np.linspace(-L * 0.45, L * 0.45, 9):
        ctx.move_to(k, B + 4)
        ctx.line_to(k - 2, B + 9)
    ctx.stroke()
    # kaya dokusu: üstte birkaç çatlak
    for k in (-0.5, -0.1, 0.35):
        ctx.move_to(L * k, -B + 2)
        ctx.line_to(L * k + 4, -B + 7)
    ctx.stroke()
    ctx.restore()


def vector_roads(out, world_p, F, route):
    """Yollar kaynak vektörden: sudan geçen parçalar kesilir, yan yana koşan kopyalar
    tek orta çizgiye birleşir, bir yerleşime varmayan çıkmaz uçlar budanır.
    roads_clean.npy (hepsi) ve roads_main.npy (ana yollar) yazar."""
    import json
    from skimage.morphology import skeletonize
    sc = pickle.load(open(os.path.join(out, "scene_final.pkl"), "rb"))
    water = cv2.resize(F.f["water"], (N, N), interpolation=cv2.INTER_LINEAR) > 0.5
    roads = json.load(open(world_p))["roads"]
    MERGE = 13                                   # bu yarıçaptaki paralel izler tek yola iner

    def draw(mask, pts):
        pts = np.asarray(pts, np.float32)
        if len(pts) < 2:
            return
        cv2.polylines(mask, [np.round(pts).astype(np.int32)], False, 1, 2 * MERGE, cv2.LINE_8)

    def runs(pts, wet):
        """Suda olmayan ardışık parçalar."""
        cur = []
        for (x, y), w_ in zip(pts, wet):
            xi, yi = int(min(N - 1, max(0, x))), int(min(N - 1, max(0, y)))
            if w_ or water[yi, xi]:
                if len(cur) > 1:
                    yield cur
                cur = []
            else:
                cur.append((x, y))
        if len(cur) > 1:
            yield cur

    allm = np.zeros((N, N), np.uint8)
    mainm = np.zeros((N, N), np.uint8)
    for r in roads:
        pts = np.asarray(r["p"], np.float32) * P
        for seg in runs(pts, r["wet"]):
            draw(allm, seg)
            if r["c"] == "road":
                draw(mainm, seg)
    for seg in runs(np.asarray(route, np.float32), [False] * len(route)):
        draw(allm, seg)
        draw(mainm, seg)
    allm[water] = 0
    line = skeletonize(allm.astype(bool))
    # yerleşimler: yol uçları bunlara varmalı
    places = []
    for y_, kind, d, bb in sc["objs"]:
        if kind in ("city", "small", "serai"):
            places.append(((bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2, max(bb[2] - bb[0], bb[3] - bb[1]) / 2 + 40))
    places = np.array(places, np.float32)

    def near_place(x, y):
        return bool(len(places)) and bool(np.any(np.hypot(places[:, 0] - x, places[:, 1] - y) < places[:, 2]))

    K = np.ones((3, 3), np.uint8)
    pruned = 0
    for it in range(60):
        nb = ndi.convolve(line.astype(np.uint8), K, mode="constant") - line
        ends = np.argwhere(line & (nb == 1))
        bad = [(y, x) for y, x in ends if not near_place(x, y)]
        if not bad:
            break
        # her kötü uçtan kavşağa (komşu>2) kadar yürü ve sil; kısa iskelet çıkıntıları da bu yolla gider
        for y, x in bad:
            path = [(y, x)]
            cy, cx = y, x
            while True:
                ya, yb, xa, xb = max(0, cy - 1), min(N, cy + 2), max(0, cx - 1), min(N, cx + 2)
                nbr = [(a, b) for a in range(ya, yb) for b in range(xa, xb)
                       if (a, b) != (cy, cx) and line[a, b] and (a, b) not in path]
                if len(nbr) != 1 or len(path) > 4000:
                    break
                cy, cx = nbr[0]
                cnt = int(line[max(0, cy - 1):cy + 2, max(0, cx - 1):cx + 2].sum()) - 1
                if cnt > 2:
                    break
                path.append((cy, cx))
            for a, b in path:
                line[a, b] = False
            pruned += 1
    lab, n = ndi.label(line, structure=np.ones((3, 3)))
    sz = ndi.sum(line, lab, np.arange(1, n + 1))
    line = np.isin(lab, np.nonzero(sz >= 60)[0] + 1)
    main = line & ndi.binary_dilation(mainm.astype(bool), iterations=2)
    np.save(os.path.join(out, "roads_clean.npy"), np.packbits(line.ravel()))
    np.save(os.path.join(out, "roads_main.npy"), np.packbits(main.ravel()))
    print("vektör yollar: budanan uç", pruned, "piksel", int(line.sum()), "ana", int(main.sum()))


# ------------------------------------------------------------------ birleştir''')

rep('''    full = Image.fromarray(img)
    del img''', '''    # kenar bandı (üretilmiş görünen dış şerit) kırpılır: sol, üst, sağ, alt pay
    cl, ct, cr, cb = (int(NN * f_) for f_ in (0.0114, 0.0101, 0.0114, 0.0126))
    full = Image.fromarray(img[ct:NN - cb, cl:NN - cr])
    del img''')
rep('''    elif cmd == "roads":''', '''    elif cmd == "vroads":
        F = Fields(os.environ["CM_FIELDS"])
        sc = pickle.load(open(os.path.join(sys.argv[2], "scene_final.pkl"), "rb"))
        vector_roads(sys.argv[2], sys.argv[3], F, sc["route"])
    elif cmd == "roads":''')
rep('''    small = full.resize((4096, 4096), Image.LANCZOS)''',
    '''    small = full.resize((4096, int(4096 * full.size[1] / full.size[0])), Image.LANCZOS)''')
open(p, "w", encoding="utf-8", newline="\n").write(s)
print("yama tamam")
