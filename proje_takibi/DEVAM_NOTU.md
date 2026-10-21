# Devam notu (oturum köprüsü)

Bu dosya, oturum limiti dolup çalışma durduğunda bir sonraki oturumun kaldığı yerden devam etmesi içindir.
Her adım bitince güncellenir ve commit edilir. Kural: imza/oturum bağlantısı yok, `main` ve `Wayborne`'a ileri sarma push.

## Çalışma düzeni

- Oturum kullanım yüzdesi araçlardan **okunamıyor**; bu yüzden çalışma küçük adımlara bölündü, her adım commit + bu not.
  Limit dolarsa saatlik zamanlanmış görev ("Wayborne: kaldığın yerden devam") oturumu bu nottan sürdürür.
- Her işte tasarımcı gözü: oyuncuya görünen şey ekranda doğrulanmadan "bitti" denmez (CLAUDE.md, görev Y-K01).
- Bu ortamda ekran görüntüsü aracının sınırı: yazılım rasterleyici çok sayıda atlas dokusunu bozuk çiziyor
  (figürler beyaz blok). Figür içeren ekranların görsel doğrulaması bu ortamda **güvenilmez**; bunlar kullanıcının
  PC'sinde test turuna kalır. Figürsüz ekranlar (menü, şehir önü, defter, harita) ekran görüntüsüyle doğrulanabilir.

## Adımlar

| # | İş | Durum |
|---|---|---|
| F1 | Test turu dokümanı: `proje_takibi/TEST_TURU.md` + `.html` (85 madde, 8 bölüm; üretici `referans/test_turu_uret.py`). Yayınlanan sayfa linki kullanıcıya verildi mi: aşağıya yaz | md/html bitti, yayın sırada |
| A1 | 2.1: web yolu kapandı, PC export şablonu gerekmiyor → kaydı kapat | sırada |
| A2 | Y-J05: ses künyesi (`KUNYE.tsv` BEKLENİYOR satırları) kaynak/lisans tara, kapatılabilenleri kapat | sırada |
| A3 | N31d: figür bakınma pozu (stick-figure ile doğrula, render Blender gerektirir) | sırada |
| A4 | Y-H07: erişilebilirlik kapsamını genişlet (öneri, kapsam kararı gerektirmeyen kısım) | sırada |
| B1 | 9.2 + Y-G16 ana menü: katmanlı gece kampı, ateş, üç yorgun yolcu | sırada |
| B2 | 9.1 ortak UI kiti v2 | sırada |
| B3 | Y-G05 savaş ekranı | sırada |
| B4 | 12.2 yol görünümü büyük revizyon, 9.10 biyom arka planları | sırada |
| B5 | Y-G11T masa şablonu taslağı, Y-G13 beş ana görsel | sırada |

Kullanıcıdan karar bekleyenler (bunlara dokunma, sorma): 2.3 (CityView silme onayı), 6.1 (LFS), Y-G08, Y-H01, N31f.
Lore'a bağlı olanlar (Y-E01/E02/E06, Y-A07) yazılmaz.
