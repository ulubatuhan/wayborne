#!/usr/bin/env python3
"""İki klasördeki ekran görüntülerini (PNG) piksel piksel karşılaştırır.

Kullanım:
    python3 tools/ci/screenshot_diff.py ESKI_KLASOR YENI_KLASOR \
        [--tolerance 12] [--max-percent 1.0] [--report rapor.md] \
        [--diff-dir fark_klasoru] [--fail]

Dosyalar klasörlere göre göreli yola göre eşleşir. Her çift için, herhangi bir
kanalı `--tolerance`'tan fazla değişen piksellerin yüzdesi hesaplanır; bu yüzde
`--max-percent`'i aşarsa dosya FARKLI sayılır. Eski klasörde olup yenide
olmayan görüntü KAYIP, yenide olup eskide olmayan YENİ'dir.

Çıkış kodu: `--fail` verilmediyse her zaman 0 (yalnızca rapor). `--fail` ile
FARKLI, KAYIP ya da BOYUT varsa 1. YENİ tek başına başarısızlık değildir.

Neden bir tolerans var: yazılım rasterleyicisi aynı kareyi bayt bayt aynı
çizse de ana menüdeki yıldızlar gibi zamanla oynayan şeyler iki koşuda birkaç
pikseli farklı bırakır. Eşikler gerçek ölçümden seçilmeli, tahminden değil.
"""

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

DURUM_AYNI = "AYNI"
DURUM_FARKLI = "FARKLI"
DURUM_BOYUT = "BOYUT"
DURUM_KAYIP = "KAYIP"
DURUM_YENI = "YENİ"

BASARISIZ_DURUMLAR = {DURUM_FARKLI, DURUM_BOYUT, DURUM_KAYIP}


def png_listesi(klasor: Path) -> dict:
    """Klasördeki bütün PNG'ler: göreli yol (/ ile) -> mutlak yol."""
    return {
        p.relative_to(klasor).as_posix(): p
        for p in sorted(klasor.rglob("*.png"))
        if p.is_file()
    }


def yukle(yol: Path) -> np.ndarray:
    # Alfa kanalı karşılaştırmaya girmesin: ekran görüntüleri opak, ama bir
    # araç ileride saydam PNG basarsa fark yanlış okunmasın.
    with Image.open(yol) as im:
        return np.asarray(im.convert("RGB"), dtype=np.int16)


def karsilastir(eski: Path, yeni: Path, tolerans: int, diff_yolu: Path = None):
    """(yüzde, boyut_uyuşuyor) döndürür; fark görüntüsünü isteğe bağlı yazar."""
    a = yukle(eski)
    b = yukle(yeni)
    if a.shape != b.shape:
        return 100.0, False
    fark = np.abs(a - b).max(axis=2)
    degisen = fark > tolerans
    yuzde = 100.0 * float(degisen.sum()) / degisen.size
    if diff_yolu is not None and degisen.any():
        # Yeni görüntüyü soluk çiz, değişen pikselleri kırmızıyla işaretle.
        cikti = (b * 0.35).astype(np.uint8)
        cikti[degisen] = (255, 0, 0)
        diff_yolu.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(cikti).save(diff_yolu)
    return yuzde, True


def calistir(eski_klasor, yeni_klasor, tolerans, max_yuzde, diff_klasoru=None):
    eski = png_listesi(eski_klasor)
    yeni = png_listesi(yeni_klasor)
    satirlar = []
    for ad in sorted(set(eski) | set(yeni)):
        if ad not in yeni:
            satirlar.append((ad, DURUM_KAYIP, None))
        elif ad not in eski:
            satirlar.append((ad, DURUM_YENI, None))
        else:
            diff_yolu = (diff_klasoru / ad) if diff_klasoru else None
            yuzde, boyut_ok = karsilastir(eski[ad], yeni[ad], tolerans, diff_yolu)
            if not boyut_ok:
                satirlar.append((ad, DURUM_BOYUT, None))
            elif yuzde > max_yuzde:
                satirlar.append((ad, DURUM_FARKLI, yuzde))
            else:
                satirlar.append((ad, DURUM_AYNI, yuzde))
    return satirlar


def rapor_metni(satirlar, tolerans, max_yuzde) -> str:
    if not satirlar:
        return "Karşılaştırılacak ekran görüntüsü bulunamadı.\n"
    ozet = {}
    for _, durum, _ in satirlar:
        ozet[durum] = ozet.get(durum, 0) + 1
    baslik = ", ".join("%d %s" % (n, d) for d, n in sorted(ozet.items()))
    cikti = [
        "### Ekran görüntüsü karşılaştırması: %s" % baslik,
        "",
        "Tolerans: kanal başına %d, eşik: piksellerin %%%s'i." % (tolerans, max_yuzde),
        "",
        "| Dosya | Durum | Değişen piksel |",
        "|---|---|---|",
    ]
    for ad, durum, yuzde in satirlar:
        deger = "-" if yuzde is None else "%%%.3f" % yuzde
        cikti.append("| %s | %s | %s |" % (ad, durum, deger))
    return "\n".join(cikti) + "\n"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("eski", type=Path)
    ap.add_argument("yeni", type=Path)
    ap.add_argument("--tolerance", type=int, default=12)
    ap.add_argument("--max-percent", type=float, default=1.0)
    ap.add_argument("--report", type=Path)
    ap.add_argument("--diff-dir", type=Path)
    ap.add_argument("--fail", action="store_true")
    args = ap.parse_args(argv)

    for klasor in (args.eski, args.yeni):
        if not klasor.is_dir():
            print("Klasör yok: %s" % klasor, file=sys.stderr)
            return 2

    satirlar = calistir(args.eski, args.yeni, args.tolerance, args.max_percent, args.diff_dir)
    metin = rapor_metni(satirlar, args.tolerance, args.max_percent)
    print(metin)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(metin, encoding="utf-8")

    if args.fail and any(d in BASARISIZ_DURUMLAR for _, d, _ in satirlar):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
