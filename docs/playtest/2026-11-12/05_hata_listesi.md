# Hata ve şüphe listesi

Bu turda oyun kodu değişmedi. Oynamayı durduran bir hata çıkmadı: 15 koşunun hepsi 4 saati tamamladı, günlüklerde
`SCRIPT ERROR` yok. Aşağıdakiler düzeltilmedi, yalnız listelendi.

| no | ne | kanıt | sınıf | iş |
|---|---|---|---|---|
| H-01 | Gece ışığı için meşale yalnız üretimle geliyor (tarif: 1 bez); hiçbir profil 4 saatte bir gece bile ışık yakamadı. | "İki meşale yok" 85-105 / koşu; "üretmek: yeterli malzeme yok" 20-61. **[Ölçüm]** | erişim | IP-002 |
| H-02 | Hatırlayan kişilerin işi hiç tamamlanmadı. | "4 tane eksik" 41-184 / profil; tamamlanan 0. **[Ölçüm]** | erişim | IP-009 |
| H-03 | Planlayıcı eksik erzağı birimle söylüyor, günle değil. | `UI_PLANNER_PROVISIONS_SHORT`; P1'in 23 açlık ölümü. **[Ölçüm + Gözlem]** | okunabilirlik | IP-001 |
| H-04 | İsyan kartı aynı aç yürüyüşte üst üste çıkıyor. | P1'de 21 kez / 12 saat. **[Ölçüm]** | tekrar | IP-005 |
| H-05 | Kısa seferde garantili dövüş hep pusu. | P2: 19 pusu / 20 sefer. **[Ölçüm]** | tekrar | IP-003 |
| H-06 | 1006 borçla moral 100, stres 2. | P3b, 4:00 kontrol noktası. **[Ölçüm]** | hissizlik | IP-013 (karar K-05) |
| H-07 | Kervan avlusunda "sıradaki adım" görünmüyor; 150 GG'ye kimse ulaşamadı. | "kese yetmiyor (150 GG)" 22-53 / profil. **[Ölçüm]** | okunabilirlik | IP-006 |
| H-08 | Sürücü geri dönüşü neredeyse hiç kullanmıyor. | 60 saatte 1. Sürücü sınırı olabilir. **[Tahmin]** | ölçüm aracı | IP-008 |
| H-09 | Sürücü yol sahnesini açmıyor; dikkat işaretleri ve yürüyüş ölçülmedi. | `ALTYAPI.md` | ölçüm aracı | IP-008 |
| H-10 | `playtest_driver.gd` 2270 satır, tek dosya. | — | bakım | şimdilik dokunma |

Ölçülmedi: ses, kumanda, 1280x800, uzun oturum bellek kullanımı, kayıt/yükleme döngüsü (sürücü kaydetmiyor).
