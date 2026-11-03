"""Efekt tuvali: alfa-üstüne birleştiren, kenar yumuşatmalı damga seti.

Neden kendi tuvalimiz var: efektler *kod*, resim değil. Bir sprite sheet
üretildiği anda donuyor ama onu üreten parametreler elimizde kaldığı için
rengi, yoğunluğu, hızı değiştirip yeniden basmak bir satır. Pillow'un
kendi çizimi kenar yumuşatma yapmıyor; bu yüzden her damga bir uzaklık
alanı olarak hesaplanıp 2x örneklenmiş tuvale yazılıyor, sonra
küçültülüyor.

Renk ön-çarpımlı tutuluyor (`_rgb` alfa ile çarpılmış): alfa-üstüne
birleştirme ancak böyle doğru. Sonda bölerek geri açılıyor.
"""

from __future__ import annotations

import numpy as np

SS = 2  # süper örnekleme: 2x çizip küçültmek kenarı yumuşatıyor


class Tuval:
    """Tek bir kare. Koordinatlar nihai (küçültülmüş) piksel biriminde."""

    def __init__(self, w: int, h: int) -> None:
        self.w = w
        self.h = h
        self._rgb = np.zeros((h * SS, w * SS, 3), dtype=np.float32)
        self._a = np.zeros((h * SS, w * SS), dtype=np.float32)

    # -- iç birleştirme ----------------------------------------------------

    def _blend(self, y0: int, y1: int, x0: int, x1: int, mask: np.ndarray, color) -> None:
        """Alfa-üstüne. `mask` 0..1 alfa, `color` 0..1 RGB."""
        if mask.size == 0:
            return
        a = np.clip(mask, 0.0, 1.0)[..., None]
        c = np.asarray(color, dtype=np.float32)[None, None, :]
        dst_rgb = self._rgb[y0:y1, x0:x1]
        dst_a = self._a[y0:y1, x0:x1]
        self._rgb[y0:y1, x0:x1] = c * a + dst_rgb * (1.0 - a)
        self._a[y0:y1, x0:x1] = a[..., 0] + dst_a * (1.0 - a[..., 0])

    def _grid(self, cx: float, cy: float, reach: float):
        """Damganın kutusu ve o kutudaki piksel merkezleri (süper ölçekte)."""
        sx, sy, r = cx * SS, cy * SS, reach * SS
        x0 = max(0, int(np.floor(sx - r)) - 1)
        x1 = min(self.w * SS, int(np.ceil(sx + r)) + 1)
        y0 = max(0, int(np.floor(sy - r)) - 1)
        y1 = min(self.h * SS, int(np.ceil(sy + r)) + 1)
        if x0 >= x1 or y0 >= y1:
            return None
        ys = np.arange(y0, y1, dtype=np.float32) + 0.5
        xs = np.arange(x0, x1, dtype=np.float32) + 0.5
        gy, gx = np.meshgrid(ys, xs, indexing="ij")
        return x0, x1, y0, y1, gx - sx, gy - sy

    # -- damgalar ----------------------------------------------------------

    def nokta(self, cx: float, cy: float, r: float, color, alpha: float = 1.0,
              yumusak: float = 0.55, en_oran: float = 1.0) -> None:
        """Yumuşak kenarlı disk. `yumusak` 0 keskin, 1 tamamen dağılmış.

        `en_oran` 1'den büyükse yatay elips (su birikintisi, gölge).
        """
        if r <= 0.0 or alpha <= 0.0:
            return
        g = self._grid(cx, cy, r * max(1.0, en_oran) + 1.0)
        if g is None:
            return
        x0, x1, y0, y1, dx, dy = g
        d = np.sqrt((dx / max(1e-3, en_oran)) ** 2 + dy ** 2) / (r * SS)
        inner = max(0.0, 1.0 - yumusak)
        m = np.clip((1.0 - d) / max(1e-3, 1.0 - inner), 0.0, 1.0)
        self._blend(y0, y1, x0, x1, m * alpha, color)

    def cizgi(self, x0p: float, y0p: float, x1p: float, y1p: float, w: float,
              color, alpha: float = 1.0, yumusak: float = 0.8) -> None:
        """Yuvarlak uçlu çizgi (kapsül). Yağmur damlası ve hareket bulanıklığı."""
        if alpha <= 0.0 or w <= 0.0:
            return
        cx, cy = (x0p + x1p) * 0.5, (y0p + y1p) * 0.5
        reach = np.hypot(x1p - x0p, y1p - y0p) * 0.5 + w + 1.0
        g = self._grid(cx, cy, reach)
        if g is None:
            return
        gx0, gx1, gy0, gy1, dx, dy = g
        # Nokta-doğru parçası uzaklığı, kutunun merkezine göre.
        ax, ay = (x0p - cx) * SS, (y0p - cy) * SS
        bx, by = (x1p - cx) * SS, (y1p - cy) * SS
        vx, vy = bx - ax, by - ay
        ll = vx * vx + vy * vy
        if ll < 1e-6:
            t = np.zeros_like(dx)
        else:
            t = np.clip(((dx - ax) * vx + (dy - ay) * vy) / ll, 0.0, 1.0)
        d = np.sqrt((dx - (ax + t * vx)) ** 2 + (dy - (ay + t * vy)) ** 2) / (w * SS)
        inner = max(0.0, 1.0 - yumusak)
        m = np.clip((1.0 - d) / max(1e-3, 1.0 - inner), 0.0, 1.0)
        self._blend(gy0, gy1, gx0, gx1, m * alpha, color)

    def halka(self, cx: float, cy: float, r: float, kalinlik: float, color,
              alpha: float = 1.0, en_oran: float = 2.6) -> None:
        """Yassı elips halka: suya düşen damlanın dalgası."""
        if r <= 0.0 or alpha <= 0.0:
            return
        g = self._grid(cx, cy, r * en_oran + kalinlik + 2.0)
        if g is None:
            return
        x0, x1, y0, y1, dx, dy = g
        d = np.sqrt((dx / en_oran) ** 2 + dy ** 2)
        m = np.clip(1.0 - np.abs(d - r * SS) / max(1e-3, kalinlik * SS), 0.0, 1.0)
        self._blend(y0, y1, x0, x1, m * alpha, color)

    def yay(self, cx: float, cy: float, r: float, kalinlik: float, color,
            bas: float, bit: float, alpha: float = 1.0, en_oran: float = 1.0) -> None:
        """Halkanın bir dilimi: taç sıçramanın kavsi, toynak izinin hilali."""
        if r <= 0.0 or alpha <= 0.0:
            return
        g = self._grid(cx, cy, r * max(1.0, en_oran) + kalinlik + 2.0)
        if g is None:
            return
        x0, x1, y0, y1, dx, dy = g
        d = np.sqrt((dx / max(1e-3, en_oran)) ** 2 + dy ** 2)
        ring = np.clip(1.0 - np.abs(d - r * SS) / max(1e-3, kalinlik * SS), 0.0, 1.0)
        ang = np.arctan2(dy, dx)
        span = (ang - bas) % (2.0 * np.pi)
        width = (bit - bas) % (2.0 * np.pi)
        inside = span <= width
        # Uçlarda yumuşat: keskin kesilen yay bıçak gibi duruyor.
        fade = np.clip(np.minimum(span, width - span) / max(1e-3, width * 0.22), 0.0, 1.0)
        self._blend(y0, y1, x0, x1, ring * inside * fade * alpha, color)

    # -- çıktı -------------------------------------------------------------

    def rgba(self) -> np.ndarray:
        """Küçültülmüş, ön-çarpımı açılmış 8 bit RGBA."""
        rgb = self._rgb.reshape(self.h, SS, self.w, SS, 3).mean(axis=(1, 3))
        a = self._a.reshape(self.h, SS, self.w, SS).mean(axis=(1, 3))
        safe = np.maximum(a, 1e-4)[..., None]
        out = np.zeros((self.h, self.w, 4), dtype=np.uint8)
        out[..., :3] = np.clip(rgb / safe * 255.0 + 0.5, 0, 255).astype(np.uint8)
        out[..., 3] = np.clip(a * 255.0 + 0.5, 0, 255).astype(np.uint8)
        return out


class Doseli(Tuval):
    """Yatayda ve dikeyde döşenebilen tuval: her damga dokuz kaydırmayla
    basılıyor, yani kenardan çıkan damla öbür kenardan giriyor.

    Perde efektleri (yağmur, kar, sis) ekranı döşeyerek kaplıyor; dikiş
    görünmesin diye tuvalin kendisi dikişsiz olmak zorunda. Aynı kural
    `RoadStrips`'in zemininde de var (bkz. kurallar-sanat, Rendered Road).
    """

    def _wrap(self, fn, cx: float, cy: float, *args, **kwargs) -> None:
        for ox in (-self.w, 0, self.w):
            for oy in (-self.h, 0, self.h):
                fn(cx + ox, cy + oy, *args, **kwargs)

    def nokta(self, cx, cy, *a, **k) -> None:
        self._wrap(super().nokta, cx, cy, *a, **k)

    def halka(self, cx, cy, *a, **k) -> None:
        self._wrap(super().halka, cx, cy, *a, **k)

    def yay(self, cx, cy, *a, **k) -> None:
        self._wrap(super().yay, cx, cy, *a, **k)

    def cizgi(self, x0p, y0p, x1p, y1p, *a, **k) -> None:
        for ox in (-self.w, 0, self.w):
            for oy in (-self.h, 0, self.h):
                Tuval.cizgi(self, x0p + ox, y0p + oy, x1p + ox, y1p + oy, *a, **k)
