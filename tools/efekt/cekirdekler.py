"""Beş çekirdek: her efekt bunlardan biriyle ve bir parametre takımıyla
tanımlanıyor. Efektin kendisi resim değil kod olduğu için rengi, yoğunluğu
ve hızı değiştirip yeniden basmak bir satır.

- `perde`  : ekranı döşeyen, zamanda döngülü yağış/sis (yağmur, kar, sis)
- `patlama`: bir noktadan fışkıran, yerçekimiyle düşen parçacıklar
             (sıçrama, toz, savrulma)
- `halka`  : suya düşen damlanın genişleyen dalgası
- `bulut`  : yükselen, büyüyen, sönen yumuşak kütleler (duman, buhar)
- `iz`     : yerde kalan ve sönen leke (ayak izi, tekerlek izi)

**Döngü kuralı (perde).** Son kare ilk kareye dikişsiz bağlanmalı, yoksa
yağmur her döngüde zıplar. Bir parçacık `kare` kare sonunda tam olarak
(cx x genişlik, cy x yükseklik) kadar yol almalı; bu yüzden eğim serbest
bir ondalık değil, `cx/cy` oranı. Kanat çırpması da döngünün tam katı
sayıda sinüsle yapılıyor.
"""

from __future__ import annotations

import zlib

import numpy as np

from tuval import Doseli, Tuval


def _rng(tohum: str) -> np.random.Generator:
    # `hash()` değil: Python'un dizge karması her süreçte farklı tohumlanıyor
    # (PYTHONHASHSEED), yani aynı efekt her çalıştırmada başka çıkardı.
    return np.random.default_rng(zlib.crc32(tohum.encode("utf-8")))


def _aralik(rng, a, kac):
    """Sayı ya da (alt, ust) ikilisi: ikisi de parametre olarak yazılabilsin."""
    if isinstance(a, (tuple, list)):
        return rng.uniform(a[0], a[1], kac)
    return np.full(kac, float(a))


# ---------------------------------------------------------------------------


def perde(p: dict) -> list[np.ndarray]:
    """Döşenebilir, zamanda döngülü yağış perdesi."""
    w, h, kare = p["en"], p["boy"], p["kare"]
    rng = _rng(p["id"])
    n = p["adet"]
    cx, cy = p.get("cx", 1), p.get("cy", 2)
    egim = (w * cx) / (h * cy)  # eğim döngüden türüyor, serbest değil
    hiz_y = h * cy / kare

    x0 = rng.uniform(0.0, w, n)
    y0 = rng.uniform(0.0, h, n)
    derinlik = rng.uniform(0.0, 1.0, n)  # 0 uzak/soluk/küçük, 1 yakın
    boy_p = _aralik(rng, p.get("uzunluk", (6.0, 14.0)), n) * (0.45 + 0.85 * derinlik)
    kalin = _aralik(rng, p.get("kalinlik", (0.5, 1.1)), n) * (0.55 + 0.75 * derinlik)
    alfa = _aralik(rng, p.get("alfa", (0.25, 0.65)), n) * (0.40 + 0.80 * derinlik)
    # Hız derinlikle değişiyor ama döngü bozulmasın diye tam katlarla:
    # yakın damla iki tur atarken uzak bir tur atıyor.
    tur = np.where(derinlik > 0.62, 2.0, 1.0) if p.get("derinlik_hizi", True) else np.ones(n)
    carp = _aralik(rng, p.get("carpik", 0.0), n)
    kanat_k = rng.integers(1, 4, n).astype(np.float32)  # tam kat: döngü korunur
    kanat_g = _aralik(rng, p.get("kanat", 0.0), n)
    faz = rng.uniform(0.0, 2.0 * np.pi, n)

    renk = p["renk"]
    renk2 = p.get("renk2", renk)
    sec = rng.uniform(0.0, 1.0, n)[:, None]
    renkler = np.asarray(renk)[None, :] * (1.0 - sec) + np.asarray(renk2)[None, :] * sec

    kareler = []
    for f in range(kare):
        t = f / kare
        tv = Doseli(w, h)
        yy = (y0 + hiz_y * tur * kare * t) % h
        xx = (x0 + egim * hiz_y * tur * kare * t
              + kanat_g * np.sin(2.0 * np.pi * kanat_k * t + faz)) % w
        sira = np.argsort(derinlik)  # uzak önce: yakın olan üstte kalsın
        for i in sira:
            if p.get("tanecik", False):
                tv.nokta(xx[i], yy[i], kalin[i] * 1.6, renkler[i], alfa[i],
                         yumusak=0.85)
            else:
                ux = -egim * boy_p[i] + carp[i]
                tv.cizgi(xx[i] + ux, yy[i] - boy_p[i], xx[i], yy[i],
                         kalin[i], renkler[i], alfa[i], yumusak=0.9)
        kareler.append(tv.rgba())
    return kareler


def sis_perdesi(p: dict) -> list[np.ndarray]:
    """Döşenebilir sis/buğu: yanlara kayan, şişip sönen yumuşak kütleler."""
    w, h, kare = p["en"], p["boy"], p["kare"]
    rng = _rng(p["id"])
    n = p["adet"]
    cx = p.get("cx", 1)
    hiz_x = w * cx / kare

    x0 = rng.uniform(0.0, w, n)
    y0 = rng.uniform(0.0, h, n)
    r = _aralik(rng, p.get("yaricap", (18.0, 48.0)), n)
    alfa = _aralik(rng, p.get("alfa", (0.06, 0.16)), n)
    nefes_k = rng.integers(1, 3, n).astype(np.float32)
    faz = rng.uniform(0.0, 2.0 * np.pi, n)
    en_oran = p.get("en_oran", 2.2)

    kareler = []
    for f in range(kare):
        t = f / kare
        tv = Doseli(w, h)
        xx = (x0 + hiz_x * kare * t) % w
        nefes = 1.0 + 0.22 * np.sin(2.0 * np.pi * nefes_k * t + faz)
        for i in range(n):
            tv.nokta(xx[i], y0[i], r[i] * nefes[i], p["renk"],
                     alfa[i] * nefes[i], yumusak=1.0, en_oran=en_oran)
        kareler.append(tv.rgba())
    return kareler


# ---------------------------------------------------------------------------


def patlama(p: dict) -> list[np.ndarray]:
    """Bir noktadan fışkıran parçacıklar: sıçrama, toz, savrulma.

    Kaynak sprite'ın alt-ortası (ayak, toynak, tekerlek teması). Parçacık
    yerçekimiyle düşüyor, sürtünmeyle yavaşlıyor, ömrü dolunca sönüyor;
    yere değen parçacık orada yassı bir leke bırakıyor (`yere_yapisir`).
    """
    w, h, kare = p["en"], p["boy"], p["kare"]
    rng = _rng(p["id"])
    n = p["adet"]
    ox = w * p.get("kaynak_x", 0.5)
    oy = h * p.get("kaynak_y", 1.0)

    aci = rng.uniform(np.radians(p["aci"][0]), np.radians(p["aci"][1]), n)
    hiz = _aralik(rng, p["hiz"], n)
    vx = np.cos(aci) * hiz
    vy = -np.sin(aci) * hiz  # ekranda yukarı negatif
    if p.get("yon", 1) < 0:
        vx = -vx
    g = p.get("yercekimi", 150.0)
    surtunme = p.get("surtunme", 1.6)
    omur = _aralik(rng, p.get("omur", (0.55, 1.0)), n)
    r0 = _aralik(rng, p.get("yaricap", (1.0, 2.6)), n)
    alfa0 = _aralik(rng, p.get("alfa", (0.5, 0.9)), n)
    gecikme = _aralik(rng, p.get("gecikme", 0.0), n)

    renk = np.asarray(p["renk"], dtype=np.float32)
    renk2 = np.asarray(p.get("renk2", p["renk"]), dtype=np.float32)
    sec = rng.uniform(0.0, 1.0, n)[:, None]
    renkler = renk[None, :] * (1.0 - sec) + renk2[None, :] * sec

    uzar = p.get("uzar", 0.0)  # hıza göre uzayan damla (su savrulması)
    yere = p.get("yere_yapisir", False)
    # Kaynağın altı **zemin mi**? Ayak ve tekerlek için evet: oradan aşağı
    # düşen parçacık yere gömülür. Tavandan damlayan su (`canopy_drip`) ve
    # havada asılı kırağı (`frost_glint`) için hayır - ilk sürümde bu ayrım
    # yoktu ve ikisi de tamamen boş çıkıyordu, çünkü her parçacık daha ilk
    # karede "yere değdi" sayılıp eleniyordu.
    zemin = p.get("zemin", p.get("kaynak_y", 1.0) >= 0.9)
    leke = p.get("leke", None)  # {"r":.., "alfa":.., "renk":..} yerdeki ıslaklık

    kareler = []
    for f in range(kare):
        t = f / (kare - 1) if kare > 1 else 0.0
        tv = Tuval(w, h)
        if leke is not None:
            u = min(1.0, t / 0.45)
            sol = max(0.0, 1.0 - max(0.0, (t - 0.55) / 0.45))
            tv.nokta(ox, oy - 0.5, leke["r"] * (0.3 + 0.7 * u), leke["renk"],
                     leke["alfa"] * sol, yumusak=0.9, en_oran=leke.get("en_oran", 3.0))
        for i in range(n):
            tt = (t - gecikme[i]) / max(1e-3, omur[i])
            if tt < 0.0 or tt > 1.0:
                continue
            # Sürtünmeli hareket: hız üstel sönüyor, yerçekimi ekleniyor.
            s = (1.0 - np.exp(-surtunme * tt * omur[i])) / surtunme
            px = ox + vx[i] * s
            py = oy + vy[i] * s + 0.5 * g * (tt * omur[i]) ** 2
            yerde = zemin and py >= oy
            if yerde and not yere:
                continue
            if yerde:
                py = oy
            sol = 1.0 - tt
            a = alfa0[i] * (sol ** 0.7)
            r = r0[i] * (0.55 + 0.45 * sol)
            if yerde:
                tv.nokta(px, py, r * 1.3, renkler[i], a * 0.8, yumusak=0.9, en_oran=2.4)
            elif uzar > 0.0:
                hx = vx[i] * np.exp(-surtunme * tt * omur[i])
                hy = vy[i] * np.exp(-surtunme * tt * omur[i]) + g * tt * omur[i]
                n_ = max(1e-3, np.hypot(hx, hy))
                uz = min(uzar, uzar * n_ / 120.0)
                tv.cizgi(px - hx / n_ * uz, py - hy / n_ * uz, px, py,
                         r, renkler[i], a, yumusak=0.85)
            else:
                tv.nokta(px, py, r, renkler[i], a, yumusak=p.get("yumusak", 0.7))
        kareler.append(tv.rgba())
    return kareler


def halka(p: dict) -> list[np.ndarray]:
    """Suya düşen damlanın dalgası: yassı elips halkalar, art arda."""
    w, h, kare = p["en"], p["boy"], p["kare"]
    cxp, cyp = w * 0.5, h * 0.5
    sayi = p.get("halka", 2)
    r_son = p.get("r_son", w * 0.42)
    en_oran = p.get("en_oran", 2.6)
    kareler = []
    for f in range(kare):
        t = f / (kare - 1) if kare > 1 else 0.0
        tv = Tuval(w, h)
        if p.get("damla", True) and t < 0.22:
            # Düşen damlanın kendisi: ilk karelerde hâlâ havada.
            u = t / 0.22
            tv.nokta(cxp, cyp - h * 0.34 * (1.0 - u), 1.5, p["renk"], 0.8 * (1.0 - u * 0.4))
        for k in range(sayi):
            tt = t - k * p.get("araluk", 0.22)
            if tt <= 0.0 or tt > 1.0:
                continue
            r = r_son * (tt ** 0.62) * (1.0 - 0.25 * k)
            a = p.get("alfa", 0.55) * (1.0 - tt) ** 1.3 * (1.0 - 0.3 * k)
            tv.halka(cxp, cyp, r, p.get("kalinlik", 1.1), p["renk"], a, en_oran)
        kareler.append(tv.rgba())
    return kareler


def bulut(p: dict) -> list[np.ndarray]:
    """Yükselen, büyüyen, sönen yumuşak kütleler: duman, buhar, nefes."""
    w, h, kare = p["en"], p["boy"], p["kare"]
    rng = _rng(p["id"])
    n = p["adet"]
    ox = w * p.get("kaynak_x", 0.5)
    oy = h * p.get("kaynak_y", 1.0)
    yon = p.get("yon", 1)

    vx = _aralik(rng, p.get("hiz_x", (-6.0, 6.0)), n) * yon
    vy = _aralik(rng, p.get("hiz_y", (-26.0, -14.0)), n)
    r0 = _aralik(rng, p.get("yaricap", (3.0, 7.0)), n)
    buyume = _aralik(rng, p.get("buyume", (6.0, 14.0)), n)
    omur = _aralik(rng, p.get("omur", (0.6, 1.0)), n)
    gecikme = _aralik(rng, p.get("gecikme", (0.0, 0.35)), n)
    alfa0 = _aralik(rng, p.get("alfa", (0.22, 0.45)), n)
    savrul = p.get("savrul", 10.0)
    savrul_k = rng.integers(1, 3, n).astype(np.float32)
    faz = rng.uniform(0.0, 2.0 * np.pi, n)

    # Döngülü duman (ocak, meşale) ile tek seferlik buhar (ateşe düşen
    # yağmur) aynı çekirdekten çıkıyor, tek fark zamanın sarması: döngüde
    # her parçacık kendi evresinden başlayıp baştan doğuyor, yani son kare
    # ilk kareye dikişsiz bağlanıyor. Tek seferlikte gecikme gecikmedir.
    dongu = p.get("dongu", False)
    evre = rng.uniform(0.0, 1.0, n) if dongu else gecikme

    kareler = []
    for f in range(kare):
        t = f / kare if dongu else (f / (kare - 1) if kare > 1 else 0.0)
        tv = Tuval(w, h)
        for i in range(n):
            if dongu:
                tt = (t + evre[i]) % 1.0
            else:
                tt = (t - evre[i]) / max(1e-3, omur[i])
            if tt < 0.0 or tt > 1.0:
                continue
            px = ox + vx[i] * tt * omur[i] + savrul * np.sin(savrul_k[i] * tt * 3.0 + faz[i]) * tt
            py = oy + vy[i] * tt * omur[i]
            r = r0[i] + buyume[i] * tt
            # Önce şişer, sonra söner: hemen sönen duman tüy gibi duruyor.
            a = alfa0[i] * np.clip(tt / 0.25, 0.0, 1.0) * (1.0 - tt) ** 1.1
            tv.nokta(px, py, r, p["renk"], a, yumusak=1.0)
        kareler.append(tv.rgba())
    return kareler


def iz(p: dict) -> list[np.ndarray]:
    """Yerde kalan ve sönen leke: ayak izi, toynak, tekerlek şeridi.

    İlk kare en belirgin; sonrakiler aynı şeklin sönmüş hâli. Oyunda tek
    kare de çizilebilsin diye şeklin kendisi her karede aynı yerde.
    """
    w, h, kare = p["en"], p["boy"], p["kare"]
    rng = _rng(p["id"])
    kareler = []
    for f in range(kare):
        sol = 1.0 - f / max(1, kare - 1) * p.get("sonum", 0.85)
        tv = Tuval(w, h)
        for sekil in p["sekiller"]:
            tur = sekil[0]
            if tur == "elips":
                _, sx, sy, r, oran, a = sekil
                tv.nokta(w * sx, h * sy, r, p["renk"], a * sol,
                         yumusak=p.get("yumusak", 0.55), en_oran=oran)
            elif tur == "serit":
                _, x0s, x1s, sy, kal, a = sekil
                tv.cizgi(w * x0s, h * sy, w * x1s, h * sy, kal, p["renk"],
                         a * sol, yumusak=0.65)
            elif tur == "yiv":
                # Tekerlek izi düz bir çizgi değil: zemin eşit değil, yiv
                # yer yer derinleşip kayboluyor. Düz çizgiyle basılan ilk
                # sürüm cetvelle çizilmiş gibi duruyordu.
                # Dalganın evresi **ize özgü, yive değil**: bir arabanın iki
                # yivi aynı yoldan geçer, yani birlikte kıvrılır. Evre yiv
                # başına verildiğinde ikisi ters yöne gidip ortada
                # kesişiyordu - tekerlek izi değil, çarpı işareti.
                _, x0s, x1s, sy, kal, a, dalga = sekil
                adim = 14
                xs = np.linspace(w * x0s, w * x1s, adim + 1)
                evre = float(p.get("dalga_evresi", 0.6))
                for j in range(adim):
                    u = (j + 0.5) / adim
                    ofs = np.sin(u * 7.3 + evre) * dalga
                    ofs2 = np.sin((u + 1.0 / adim) * 7.3 + evre) * dalga
                    derin = 0.55 + 0.45 * (0.5 + 0.5 * np.sin(u * 13.0 + evre))
                    tv.cizgi(xs[j], h * sy + ofs, xs[j + 1], h * sy + ofs2,
                             kal * derin, p["renk"], a * sol * derin, yumusak=0.8)
            elif tur == "hilal":
                _, sx, sy, r, kal, bas, bit, a = sekil
                tv.yay(w * sx, h * sy, r, kal, p["renk"],
                       np.radians(bas), np.radians(bit), a * sol, en_oran=1.7)
        # Taze izin içindeki birikmiş su / kabarmış toprak.
        if p.get("parlak") is not None and f == 0:
            for sekil in p["sekiller"]:
                if sekil[0] == "elips":
                    _, sx, sy, r, oran, a = sekil
                    tv.nokta(w * sx, h * sy - 0.4, r * 0.45, p["parlak"], a * 0.5,
                             yumusak=0.9, en_oran=oran)
        _ = rng
        kareler.append(tv.rgba())
    return kareler


CEKIRDEKLER = {
    "perde": perde,
    "sis": sis_perdesi,
    "patlama": patlama,
    "halka": halka,
    "bulut": bulut,
    "iz": iz,
}
