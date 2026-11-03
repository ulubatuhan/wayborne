#!/usr/bin/env python3
"""Efekt sprite sheet'lerini basar.

    python3 tools/efekt/uret.py                 # hepsi
    python3 tools/efekt/uret.py rain_medium ... # yalnızca adı verilenler
    python3 tools/efekt/uret.py --tabaka        # ayrıca önizleme tabakası

Çıktı: `data/assets/fx/sheets/<id>.png` (saydam ızgara) ve yanında
`fx.json` (oyunun okuduğu manifesto). Üretim tohumlu ve yinelenebilir:
aynı katalogdan aynı resim çıkar, yani bir efektin rengini değiştirip
yeniden basmak diffte yalnızca o efekti gösterir.

Kareler ızgaraya soldan sağa, sonra alt satıra diziliyor; `sutun` manifesto
alanı. Godot tarafı `FxCatalog` bunu okuyor.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

SRC = Path(__file__).resolve().parent
sys.path.insert(0, str(SRC))

from cekirdekler import CEKIRDEKLER  # noqa: E402
from katalog import KATALOG  # noqa: E402

KOK = SRC.parent.parent
CIKTI = KOK / "data" / "assets" / "fx" / "sheets"
MANIFESTO = CIKTI / "fx.json"
# Godot dokuyu tek parça yüklüyor; ızgara bundan geniş olmasın.
EN_COK_EN = 2048
# Kare başına çevre boşluğu (piksel). Bkz. `_izgara`.
BOSLUK = 2


def _sutun(kare: int, en: int) -> int:
    """Kareleri kabaca kare bir ızgaraya dizen sütun sayısı."""
    s = max(1, int(math.ceil(math.sqrt(kare))))
    return max(1, min(s, EN_COK_EN // max(1, en + 2 * BOSLUK)))


def _izgara(kareler: list[np.ndarray], sutun: int, dosenir: bool) -> Image.Image:
    """Kareleri ızgaraya dizer; her karenin çevresine `BOSLUK` piksel bırakır.

    Boşluk şart: doku doğrusal süzgeçle örnekleniyor, bitişik iki kare
    arasında boşluk olmazsa bir karenin kenarı öbürünün pikselini içine
    çekiyor ve yağmur karesinin tepesinde bir önceki karenin damlası
    beliriyor.

    Döşenen efektlerde (perde, sis) boşluk **saydam bırakılmıyor, karenin
    öbür kenarıyla dolduruluyor**: ekranı döşerken komşu döşemenin gerçek
    pikseli orası. Saydam bırakılsaydı her döşeme sınırında soluk bir
    dikiş çizgisi kalırdı - `RoadStrips`'in zemininde de aynı kural var.
    """
    h, w = kareler[0].shape[:2]
    b = BOSLUK
    satir = int(math.ceil(len(kareler) / sutun))
    tuval = np.zeros((satir * (h + 2 * b), sutun * (w + 2 * b), 4), dtype=np.uint8)
    for i, k in enumerate(kareler):
        if dosenir:
            # Sarmalı taşma: ortada kare, çevresinde karenin karşı kenarı.
            genis = np.pad(k, ((b, b), (b, b), (0, 0)), mode="wrap")
        else:
            genis = np.pad(k, ((b, b), (b, b), (0, 0)), mode="constant")
        y, x = divmod(i, sutun)
        oy, ox = y * (h + 2 * b), x * (w + 2 * b)
        tuval[oy:oy + h + 2 * b, ox:ox + w + 2 * b] = genis
    return Image.fromarray(tuval, mode="RGBA")


## Kırpmada bırakılan yumuşak kenar payı (piksel).
KIRPMA_PAYI = 2


def _kirp(kareler: list[np.ndarray], mil: list) -> tuple[list[np.ndarray], list]:
    """Kareleri **içeriğin kutusuna** kırpar ve mili yeniden hesaplar.

    Neden: `m` alanı efektin dünyadaki eni demek, ama parçacıklar karenin
    ortasında duruyor ve kenarlarda boş pay kalıyordu. Ölçüldü: gerçek
    sahnede 114 piksellik bir sıçrama karesinde görünen sıçrama ~45
    pikseldi, yani ekranda efekt iki buçuk kat küçük duruyordu. Boşluk
    kesilince `m` içeriğin kendi eni oluyor ve oyunda yazdığı boyda
    görünüyor.

    Mil kırpmayla birlikte kayıyor: ayak basma noktası karenin alt-ortası
    değil, **aynı dünya noktası** kalmalı. Yeni mil eski milin kırpılmış
    kutudaki oranı.
    """
    birlesik = np.zeros(kareler[0].shape[:2], dtype=np.uint8)
    for k in kareler:
        birlesik = np.maximum(birlesik, k[..., 3])
    dolu = birlesik > 3
    if not dolu.any():
        return kareler, mil
    ys, xs = np.where(dolu)
    h, w = birlesik.shape
    p = KIRPMA_PAYI
    x0, x1 = max(0, int(xs.min()) - p), min(w, int(xs.max()) + 1 + p)
    y0, y1 = max(0, int(ys.min()) - p), min(h, int(ys.max()) + 1 + p)
    if x1 - x0 < 4 or y1 - y0 < 4:
        return kareler, mil
    mil_px = (float(mil[0]) * w, float(mil[1]) * h)
    yeni_mil = [(mil_px[0] - x0) / float(x1 - x0), (mil_px[1] - y0) / float(y1 - y0)]
    return [k[y0:y1, x0:x1] for k in kareler], yeni_mil


def bas(spec: dict) -> dict:
    cekirdek = CEKIRDEKLER[spec["cekirdek"]]
    kareler = cekirdek(spec)
    dosenir = spec["cekirdek"] in ("perde", "sis")
    mil = list(spec["mil"])
    if not dosenir:
        # Döşenen perde kırpılmaz: kenarı komşu döşemeye dikişsiz bağlanmak
        # zorunda, yani boş görünen kenar da karenin bir parçası.
        kareler, mil = _kirp(kareler, mil)
    spec = dict(spec)
    spec["en"], spec["boy"] = kareler[0].shape[1], kareler[0].shape[0]
    spec["mil"] = mil
    sutun = _sutun(len(kareler), spec["en"])
    CIKTI.mkdir(parents=True, exist_ok=True)
    _izgara(kareler, sutun, dosenir).save(CIKTI / f"{spec['id']}.png", optimize=True)
    return {
        "kare": len(kareler),
        "sutun": sutun,
        "bosluk": BOSLUK,
        "dosenir": dosenir,
        "en": spec["en"],
        "boy": spec["boy"],
        "fps": spec["fps"],
        "dongu": bool(spec.get("dongu", False)),
        "m": float(spec["m"]),
        "mil": [float(spec["mil"][0]), float(spec["mil"][1])],
        "oklama": spec.get("oklama", "yok"),
        "aile": spec["cekirdek"],
    }


def main(argv: list[str]) -> int:
    istenen = [a for a in argv if not a.startswith("-")]
    tabaka = "--tabaka" in argv
    secili = [s for s in KATALOG if not istenen or s["id"] in istenen]
    if not secili:
        print("eşleşen efekt yok:", ", ".join(istenen))
        return 1

    eski: dict = {}
    if MANIFESTO.exists():
        eski = json.loads(MANIFESTO.read_text(encoding="utf-8")).get("efektler", {})

    manifesto = dict(eski)
    for spec in secili:
        manifesto[spec["id"]] = bas(spec)
        print(f"  {spec['id']:<20} {manifesto[spec['id']]['kare']:>2} kare")

    # Katalogdan kalkan bir efektin manifestoda kalması, oyunun var olmayan
    # bir dokuyu istemesi demek: üretim tam koşuyorsa manifesto da tam.
    if not istenen:
        manifesto = {s["id"]: manifesto[s["id"]] for s in KATALOG}

    CIKTI.mkdir(parents=True, exist_ok=True)
    MANIFESTO.write_text(
        json.dumps({"surum": 1, "efektler": manifesto}, ensure_ascii=False,
                   indent=1, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"{len(secili)} efekt -> {CIKTI.relative_to(KOK)}")

    if tabaka:
        _onizleme(secili, manifesto)
    return 0


def _onizleme(secili: list[dict], manifesto: dict | None = None) -> None:
    """Her efektin orta karesini tek bir kontrol sayfasına dizer.

    Oyunda görmeden önce elde bakılacak tek resim; koyu zemin, çünkü
    efektlerin hepsi saydam ve açık renk.
    """
    hucre = 168
    sutun = 7
    satir = int(math.ceil(len(secili) / sutun))
    sayfa = Image.new("RGBA", (sutun * hucre, satir * hucre), (26, 24, 27, 255))
    yazi = ImageDraw.Draw(sayfa)
    for i, spec in enumerate(secili):
        yol = CIKTI / f"{spec['id']}.png"
        if not yol.exists():
            continue
        sheet = Image.open(yol)
        # Ölçüler **manifestodan**: kareler içeriğe kırpıldığı için
        # katalogdaki en/boy artık üretilmiş dosyanınki değil.
        kayit = (manifesto or {}).get(spec["id"], spec)
        w, h = int(kayit["en"]), int(kayit["boy"])
        adim_x, adim_y = w + 2 * BOSLUK, h + 2 * BOSLUK
        kolon = max(1, sheet.width // adim_x)
        n = max(1, kolon * (sheet.height // adim_y))
        # Döngülü efekt her karede dolu; tek seferlik olan **tepe
        # noktasında** bakılır, sönerken değil - sönmüş kareye bakıp
        # "efekt zayıf" demek ölçüm hatası olurdu.
        secik = n // 2 if spec.get("dongu") else min(n - 1, max(1, int(n * 0.22)))
        _ = kayit
        cx, cy = secik % kolon, secik // kolon
        px, py = cx * adim_x + BOSLUK, cy * adim_y + BOSLUK
        kare = sheet.crop((px, py, px + w, py + h))
        k = min((hucre - 28) / w, (hucre - 28) / h, 2.4)
        kare = kare.resize((max(1, int(w * k)), max(1, int(h * k))), Image.LANCZOS)
        gx, gy = (i % sutun) * hucre, (i // sutun) * hucre
        yazi.rectangle([gx + 1, gy + 1, gx + hucre - 2, gy + hucre - 2],
                       outline=(54, 50, 54, 255))
        sayfa.alpha_composite(kare, (gx + (hucre - kare.width) // 2,
                                     gy + 14 + (hucre - 20 - kare.height) // 2))
        yazi.text((gx + 6, gy + 4), spec["id"], fill=(190, 184, 172, 255))
    hedef = KOK / "docs" / "ui" / "efekt_tabakasi.png"
    hedef.parent.mkdir(parents=True, exist_ok=True)
    sayfa.save(hedef)
    print(f"önizleme -> {hedef.relative_to(KOK)}")


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
