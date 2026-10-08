"""Faz 3-4 hakemleri: giysi modulleri ciplak bedenin ustune bindirildiginde.

skin_bleed: oyun sirasiyla (her katmanda once beden, sonra giysiler listedeki
  sirayla) bindirilmis resimde EN USTTE beden pikseli kalan, ama gercek render'da
  (truth_id) ten OLMAYAN (giysi ya da bos) piksel sayisi. Ten giysinin icinden
  ya da kenarindan gorunuyor demek.
  Gecme: 0. Ters yon (gercekte ten gorunurken giysi ciziliyor) ayrica sayilir
  ama esige girmez - bir sonraki karar (QUESTIONS).
composite_equals_truth: ayni bindirme vs truth.png, Faz 1'in esigiyle.
no_backfaces: giysinin magenta render'inda magenta piksel 0.

Bilinen hatali ornek: ayni karede bindirme sirasi TERS (giysi bedenden once).
skin_bleed onu yakalamali (validate_garment_tests).
"""
import os

import numpy as np
from PIL import Image

import faz1_tests as f1

ALPHA_ON = 0.5


def layer_stack(fdir, gids, layers, garments_first=False):
    """[(kaynak, rgba)] ressam sirasiyla. kaynak: 'body' ya da giysi id'si."""
    out = []
    gdir = os.path.join(fdir, "garments")
    for n in layers:
        body = ("body", f1.load_rgba(os.path.join(fdir, n + ".png")))
        gs = [(g, f1.load_rgba(os.path.join(gdir, "%s_%s.png" % (g, n)))) for g in gids]
        out += (gs + [body]) if garments_first else ([body] + gs)
    return out


def top_source(stack):
    """Her piksel icin en son alfasi ALPHA_ON'u gecen kaynagin indeksi (-1 bos)."""
    names = []
    top = None
    for src, img in stack:
        if src not in names:
            names.append(src)
        k = names.index(src)
        if top is None:
            top = np.full(img.shape[:2], -1, np.int16)
        top[img[..., 3] > ALPHA_ON] = k
    return top, names


def skin_bleed(fdir, gids, layers, garments_first=False, diff_path=None):
    stack = layer_stack(fdir, gids, layers, garments_first)
    top, names = top_source(stack)
    tid = f1.load_rgba(os.path.join(fdir, "garments", "truth_id.png"))
    truth_g = (tid[..., 3] > ALPHA_ON) & (tid[..., 2] > 0.5)
    truth_skin = (tid[..., 3] > ALPHA_ON) & (tid[..., 2] <= 0.5)
    body_k = names.index("body")
    is_g = (top >= 0) & (top != body_k)
    # gercekte ten GORUNMEYEN her yerde (giysi ya da bos) en ustte beden: ten
    # giysinin icinden ya da kenarindan tasiyor (ornek: ayakkabinin onunden
    # cikan ciplak parmak - gercekte o ayak MPFB'nin silme grubuyla gizli).
    bleed = ~truth_skin & (top == body_k)
    spill = truth_skin & is_g
    if diff_path:
        rgb = np.zeros(top.shape + (3,), np.uint8)
        rgb[..., 2] = (truth_g * 70).astype(np.uint8)
        rgb[bleed] = (255, 0, 0)
        rgb[spill] = (255, 200, 0)
        Image.fromarray(rgb).save(diff_path)
    return {"bleed": int(bleed.sum()), "spill": int(spill.sum()),
            "garment_px": int(truth_g.sum()), "pass": int(bleed.sum()) == 0}


def composite_equals_truth(fdir, gids, layers, diff_path=None):
    comp = f1.over([img for _s, img in layer_stack(fdir, gids, layers)])
    truth = f1.premul(f1.load_rgba(os.path.join(fdir, "garments", "truth.png")))
    return f1.image_diff(comp, truth, diff_path)


def no_backfaces(fdir, gid):
    n, _m = f1.magenta_pixels(os.path.join(fdir, "garments", "magenta_%s.png" % gid))
    return {"magenta_px": n, "pass": n == 0}
