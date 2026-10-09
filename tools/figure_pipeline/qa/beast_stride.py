"""Yürüyüş karelerinde bir çevrimde gövdenin katettiği yol (figür boyu cinsinden).

Yere basan ayağın/toynağın alt bandı (bacak katmanı, zemine en yakın %7) iki
ardışık karede yatay ilintiyle karşılaştırılıyor; alt-piksel tepe, ortanca
kayma, çevrim başına yol. Sonuç `BodyFrames.BEAST_WALK_CYCLE`'ın kaynağı.
Doğrulama: insan karesinde 0.607 okur, rig'in kendi değeri 0.633.

    python3 -I tools/figure_pipeline/qa/beast_stride.py <repo> beast_ox beast_horse ...
"""
import re, sys, numpy as np
from PIL import Image
ROOT = sys.argv[1]
LAYERS = 5; KINDS = 4
def arr(txt, name, typ):
    m = re.search(name + r' = Packed\w+Array\(([^)]*)\)', txt)
    s = m.group(1).strip()
    if not s: return []
    return [typ(v) for v in s.replace(' ', '').split(',')]
def measure(sid, legs):
    d = f"{ROOT}/data/assets/characters/frames/{sid}"
    txt = open(d + "/frames.tres").read()
    pages = re.search(r'pages = PackedStringArray\(([^)]*)\)', txt).group(1).replace('"','').split(', ')
    imgs = [np.asarray(Image.open(ROOT + "/" + p.replace("res://","")).convert("RGBA"))[..., 3].astype(float)/255 for p in pages]
    names = re.search(r'clip_names = PackedStringArray\(([^)]*)\)', txt).group(1).replace('"','').split(', ')
    counts = arr(txt, 'clip_frames', int)
    rects = arr(txt, 'rects', int)
    offs = arr(txt, 'offsets', float)
    sh = float(re.search(r'shoulder_px = ([\d.]+)', txt).group(1))
    ms = re.search(r'ref_share = ([\d.]+)', txt)
    share = float(ms.group(1)) if ms else 0.72
    base = sum(counts[:names.index('walk')]); n = counts[names.index('walk')]
    band = 0.07 * sh
    W = int(sh * 4)
    res = {}
    for layer in legs:
        profs = []; lows = []
        for f in range(n):
            i = ((base + f) * LAYERS + layer) * KINDS
            r = rects[i*5:i*5+5]; ox, oy = offs[i*2], offs[i*2+1]
            a = imgs[r[0]][r[2]:r[2]+r[4], r[1]:r[1]+r[3]]
            ys, xs = np.nonzero(a > 0.5)
            low = oy + ys.max() + 1
            lows.append(low)
            prof = np.zeros(W)
            for y in range(a.shape[0]):
                gy = oy + y + 1
                if gy < low - band: continue
                gx0 = int(round(ox + W/2))
                prof[gx0:gx0 + a.shape[1]] += a[y]
            profs.append(prof)
        tol = 0.02 * sh
        shifts = []
        for f in range(n):
            g = (f + 1) % n
            if abs(lows[f]) < tol and abs(lows[g]) < tol:
                p, q = profs[f], profs[g]
                if abs(p.sum() - q.sum()) > 0.25 * max(p.sum(), q.sum()): continue
                c = np.correlate(q - q.mean(), p - p.mean(), mode='full')
                k = int(np.argmax(c)); 
                if 0 < k < len(c)-1:
                    y0, y1, y2 = c[k-1], c[k], c[k+1]
                    dk = 0.5*(y0 - y2)/(y0 - 2*y1 + y2) if (y0 - 2*y1 + y2) != 0 else 0
                else: dk = 0
                shifts.append(k - (W - 1) + dk)
        if shifts:
            v = float(np.median(shifts))
            res[layer] = (round(-v * n * share / sh, 3), len(shifts), sum(1 for s in shifts if s > 0.3))
    return res
for sid in sys.argv[2:]:
    legs = [1, 3] if sid.startswith('body') else [0, 1, 3, 4]
    r = measure(sid, legs)
    vals = [v[0] for v in r.values()]
    print(sid, r, 'mean', round(float(np.mean(vals)), 3) if vals else None)
