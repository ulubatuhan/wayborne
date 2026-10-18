"""Son işlem: eski kâğıt dokusu, boya tanesi, hafif mürekkep yayılması."""
import numpy as np
from scipy import ndimage as ndi


def noise(shape, sigma, rng):
    n = rng.random(shape).astype(np.float32)
    n = ndi.gaussian_filter(n, sigma)
    return (n - n.mean()) / (n.std() + 1e-6)


def finish(img, ss=1, seed=4):
    """img: HxWx3 float (0..1), süper örneklenmiş çizim."""
    rng = np.random.default_rng(seed)
    h, w = img.shape[:2]
    def up(a):
        return np.asarray(__import__("PIL.Image", fromlist=["Image"]).fromarray(a).resize((w, h), 2))

    # kâğıt: büyük lekeler, lif, kenarlara doğru sararma
    blot = up(noise((h // 8, w // 8), 6, rng))
    fib = noise((h, w), 0.8 * ss, rng)
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.hypot((xx - w / 2) / (w / 2), (yy - h / 2) / (h / 2))
    edge = np.clip(r - 0.75, 0, 1) ** 1.5
    tone = 1 - 0.022 * blot - 0.015 * fib - 0.25 * edge
    paper_tint = np.array([1.0, 0.97, 0.90], np.float32)
    # boya tanesi: renkli alanlarda (kâğıttan uzak) daha belirgin
    sat = img.max(-1) - img.min(-1)
    gran = noise((h, w), 1.0 * ss, rng)
    pool = up(noise((h // 4, w // 4), 3, rng))
    k = np.clip(sat * 3, 0, 1)
    img = img * (1 - k[..., None] * (0.05 * gran + 0.06 * pool)[..., None])
    img = img * tone[..., None] * paper_tint
    # mürekkep hafif yayılır
    img = ndi.gaussian_filter(img, (0.35 * ss, 0.35 * ss, 0))
    return (np.clip(img, 0, 1) * 255).astype(np.uint8)
