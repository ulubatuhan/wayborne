# Hata ve şüphe listesi

Bu turda oyun kodu değişmedi. Oynamayı durduran bir hata çıkmadı: 15 koşunun hepsi 4 saati tamamladı, günlüklerde
`SCRIPT ERROR` yok. Aşağıdakiler düzeltilmedi, yalnız listelendi.

| no | ne | kanıt | sınıf | iş |
|---|---|---|---|---|
| ~~H-01~~ | **Kapandı (IP-002).** Meşale 2 GG'ye **27 yerleşimin hepsinde** tezgâhta (`Location.sells`, `LIGHT_SUPPLIES`). Sürücü ışık malzemesini hiç almıyordu; düzeltildi, 60 saatte 86 meşale alımı. Oyunda sorun yok. | `tests/playtest/olc_mesale.gd` **[Ölçüm]** | kapandı | — |
| H-15 | Meşale tarifi ekonomik olarak anlamsız: 12 GG'lik bir bez 4 GG'lik iki meşale veriyor. Yolda üretmek dışında bir sebebi yok. | `olc_mesale.gd` **[Ölçüm]** | sayı (kullanıcı kararı) | — |
| H-16 | **İşe alım karşılanamıyor:** 60 saatte 0 alım; 102 kez "kese yetmiyor", 99 kez "vagonlarında yer yok". Kadro hiç 2'yi geçmedi. (Sürücü düzeltildikten sonra da sürüyor.) | `engeller_ilk10` **[Ölçüm]** | denge | K-03 ile birlikte |
| H-02 | Hatırlayan kişilerin işi hiç tamamlanmadı. | "4 tane eksik" 41-184 / profil; tamamlanan 0. **[Ölçüm]** | erişim | IP-009 |
| H-03 | Planlayıcı eksik erzağı birimle söylüyor, günle değil. | `UI_PLANNER_PROVISIONS_SHORT`; P1'in 23 açlık ölümü. **[Ölçüm + Gözlem]** | okunabilirlik | IP-001 |
| H-04 | İsyan kartı aynı aç yürüyüşte üst üste çıkıyor. | P1'de 21 kez / 12 saat. **[Ölçüm]** | tekrar | IP-005 |
| H-05 | Kısa seferde garantili dövüş hep pusu. | P2: 19 pusu / 20 sefer. **[Ölçüm]** | tekrar | IP-003 |
| H-06 | 1006 borçla moral 100, stres 2. | P3b, 4:00 kontrol noktası. **[Ölçüm]** | hissizlik | IP-013 (karar K-05) |
| H-07 | Kervan avlusunda "sıradaki adım" görünmüyor; 150 GG'ye kimse ulaşamadı. | "kese yetmiyor (150 GG)" 22-53 / profil. **[Ölçüm]** | okunabilirlik | IP-006 |
| H-08 | Sürücü geri dönüşü neredeyse hiç kullanmıyor. | 60 saatte 1. Sürücü sınırı olabilir. **[Tahmin]** | ölçüm aracı | IP-008 |
| H-09 | Sürücü yol sahnesini açmıyor; dikkat işaretleri ve yürüyüş ölçülmedi. | `ALTYAPI.md` | ölçüm aracı | IP-008 |
| H-10 | `playtest_driver.gd` 2270 satır, tek dosya. | — | bakım | şimdilik dokunma |
| ~~H-11~~ | **Kapandı (IP-015).** Vagon satışı artık yalnız icra baskısı ya da sürülemeyen vagon için. Büyüme 26→27, satış 31→33 ama hepsi gerçek baskı; 15 koşunun 13'ü vagon 2'yi gördü. | `olaylar.jsonl` **[Ölçüm]** | kapandı | — |
| ~~H-12~~ | **Kapandı (IP-015).** Aday seçimi profilden geliyor (`sehir.aday_secimi`, varsayılan "ucuz"), yedek 60→20. Alım yine 0 çıktı: sebep sürücü değil, fiyat — bkz. H-16. | `playtest_driver.gd` **[Ölçüm]** | kapandı | — |
| ~~H-13~~ | **Kapandı (IP-015).** Mal payı artık bir sonraki büyüme basamağının parasını ayırıyor (`sehir.buyume_hedefi`). Kese dibi −956'dan −35'e çıktı. | `_mal_al` **[Ölçüm]** | kapandı | — |
| H-14 | `ilkler_oturum.first_decision` yalnız olay kartını sayıyor; planlayıcıdaki "eksik erzakla çık" kararı sayılmıyor. "İlk karar 7-11. dakika" bu tanımla okunmalı. | `ALTYAPI.md` **[Gözlem]** | tanım | IP-015 |

Ölçülmedi: ses, kumanda, 1280x800, uzun oturum bellek kullanımı, kayıt/yükleme döngüsü (sürücü kaydetmiyor).
