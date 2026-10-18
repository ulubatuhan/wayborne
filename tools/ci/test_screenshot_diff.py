"""screenshot_diff.py'nin testi. Çalıştırmak:

    python3 -m unittest discover -s tools/ci -p "test_*.py"

Sentetik görüntülerle kapıyı sınar: aynı görüntü AYNI, tolerans içi gürültü
AYNI, eşiği aşan değişiklik FARKLI, farklı boyut BOYUT, eksik/ekstra dosya
KAYIP/YENİ; --fail yalnızca gerçek bozulmada 1 döner.
"""

import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

import screenshot_diff as sd


def yaz(klasor: Path, ad: str, dizi: np.ndarray) -> None:
    yol = klasor / ad
    yol.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(dizi.astype(np.uint8)).save(yol)


def duz(boyut=(100, 200), deger=(40, 40, 40)) -> np.ndarray:
    a = np.zeros((boyut[0], boyut[1], 3), dtype=np.uint8)
    a[:] = deger
    return a


class EkranFarkiTesti(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.kok = Path(self._tmp.name)
        self.eski = self.kok / "eski"
        self.yeni = self.kok / "yeni"
        self.eski.mkdir()
        self.yeni.mkdir()

    def tearDown(self):
        self._tmp.cleanup()

    def durumlar(self, **kw):
        satirlar = sd.calistir(
            self.eski, self.yeni, kw.get("tolerans", 12), kw.get("max_yuzde", 1.0), kw.get("diff")
        )
        return {ad: durum for ad, durum, _ in satirlar}

    def test_ayni_goruntu_ayni(self):
        yaz(self.eski, "a.png", duz())
        yaz(self.yeni, "a.png", duz())
        self.assertEqual(self.durumlar(), {"a.png": sd.DURUM_AYNI})

    def test_tolerans_ici_gurultu_ayni(self):
        yaz(self.eski, "a.png", duz(deger=(40, 40, 40)))
        yaz(self.yeni, "a.png", duz(deger=(48, 40, 40)))  # kanal farkı 8 < 12
        self.assertEqual(self.durumlar(), {"a.png": sd.DURUM_AYNI})

    def test_esigi_asan_degisiklik_farkli(self):
        a = duz()
        b = duz()
        b[:20, :, :] = 200  # yüzde 20'si değişti
        yaz(self.eski, "a.png", a)
        yaz(self.yeni, "a.png", b)
        self.assertEqual(self.durumlar(), {"a.png": sd.DURUM_FARKLI})

    def test_kucuk_degisiklik_esigin_altinda_ayni(self):
        a = duz(boyut=(100, 200))
        b = duz(boyut=(100, 200))
        b[0, :50, :] = 255  # 50 piksel = yüzde 0.25
        yaz(self.eski, "a.png", a)
        yaz(self.yeni, "a.png", b)
        self.assertEqual(self.durumlar(max_yuzde=1.0), {"a.png": sd.DURUM_AYNI})
        self.assertEqual(self.durumlar(max_yuzde=0.1), {"a.png": sd.DURUM_FARKLI})

    def test_boyut_farki(self):
        yaz(self.eski, "a.png", duz(boyut=(100, 200)))
        yaz(self.yeni, "a.png", duz(boyut=(120, 200)))
        self.assertEqual(self.durumlar(), {"a.png": sd.DURUM_BOYUT})

    def test_kayip_ve_yeni(self):
        yaz(self.eski, "kayip.png", duz())
        yaz(self.yeni, "yeni.png", duz())
        self.assertEqual(
            self.durumlar(), {"kayip.png": sd.DURUM_KAYIP, "yeni.png": sd.DURUM_YENI}
        )

    def test_alt_klasor_yolu_eslesir(self):
        yaz(self.eski, "menu/01.png", duz())
        yaz(self.yeni, "menu/01.png", duz())
        self.assertEqual(self.durumlar(), {"menu/01.png": sd.DURUM_AYNI})

    def test_fark_goruntusu_yazilir(self):
        a = duz()
        b = duz()
        b[:30, :, :] = 255
        yaz(self.eski, "a.png", a)
        yaz(self.yeni, "a.png", b)
        diff = self.kok / "diff"
        self.durumlar(diff=diff)
        self.assertTrue((diff / "a.png").is_file())

    def test_fail_yalnizca_gercek_bozulmada(self):
        yaz(self.eski, "a.png", duz())
        yaz(self.yeni, "a.png", duz())
        yaz(self.yeni, "yeni.png", duz())  # YENİ başarısızlık sayılmaz
        self.assertEqual(sd.main([str(self.eski), str(self.yeni), "--fail"]), 0)
        yaz(self.yeni, "a.png", duz(deger=(255, 255, 255)))
        self.assertEqual(sd.main([str(self.eski), str(self.yeni), "--fail"]), 1)
        # --fail yoksa yalnızca rapor: bozulma olsa da 0.
        self.assertEqual(sd.main([str(self.eski), str(self.yeni)]), 0)

    def test_olmayan_klasor_2(self):
        self.assertEqual(sd.main([str(self.kok / "yok"), str(self.yeni)]), 2)


if __name__ == "__main__":
    unittest.main()
