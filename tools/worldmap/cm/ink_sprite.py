"""Render'ı mürekkep/parşömen figürüne çevirir: 3 ton + kontur, saydam zemin."""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

def ink(src, out):
    im = np.asarray(Image.open(src).convert("RGBA"), np.float32) / 255
    a = im[..., 3]
    L = im[..., :3] @ np.array([0.3, 0.59, 0.11], np.float32)
    snow = (im[..., 0] - im[..., 2]) > 0.12          # kar işareti (kırmızı kanal)
    lines = (L < 0.12) & (a > 0.5)
    # Freestyle'ın taban kenarı çizgileri (eteğin kesik kenarı) silinir; üst silüeti biz çiziyoruz
    inner = ndi.binary_erosion(a > 0.5, iterations=2)
    lines &= inner
    Ls = ndi.median_filter(L, 3)
    # 3 ton: ışık (kâğıt), orta (açık mürekkep), gölge (koyu mürekkep)
    tone = np.where(Ls > 0.62, 0.0, np.where(Ls > 0.40, 0.30, 0.58))
    tone = np.where(snow, np.where(Ls > 0.42, -0.30, 0.16), tone)      # kar: ışıkta kâğıttan açık, gölgede açık ton
    tone = ndi.gaussian_filter(tone, 0.6)
    # silüet: saydam olmayanın üst ve yan kenarı mürekkep, etek yumuşar
    solid = a > 0.5
    edge = solid & ~ndi.binary_erosion(solid, iterations=2)
    below = np.zeros_like(solid); below[:-6] = solid[6:]          # altında dağ varsa etek değil
    above = np.zeros_like(solid); above[6:] = solid[:-6]
    top_edge = edge & ~above
    dist = ndi.distance_transform_edt(solid)
    yy = np.arange(a.shape[0])[:, None]
    bottom = solid & ~below
    soft = np.clip(dist / 10.0, 0, 1)
    a = np.where(top_edge, a, a * np.clip(soft + (~ndi.binary_dilation(bottom, iterations=10)), 0, 1))
    tone = np.maximum(tone, np.maximum(lines, ndi.binary_dilation(top_edge) & solid) * 0.92)
    paper = np.array([0.94, 0.89, 0.77]); inkc = np.array([0.17, 0.12, 0.09]); white = np.array([0.99, 0.97, 0.92])
    tp = np.clip(tone, 0, 1)[..., None]; tw = np.clip(-tone, 0, 1)[..., None] * 4
    rgb = paper * (1 - tp) + inkc * tp
    rgb = rgb * (1 - np.clip(tw, 0, 1)) + white * np.clip(tw, 0, 1)
    o = np.dstack([rgb, a])
    Image.fromarray((np.clip(o, 0, 1) * 255).astype(np.uint8)).save(out)

if __name__ == "__main__":
    if sys.argv[1] == "lib":
        import glob, os
        for p in sorted(glob.glob(os.path.join(sys.argv[2], "*_raw.png"))):
            ink(p, p.replace("_raw.png", ".png"))
    else:
        ink(sys.argv[1], sys.argv[2])
