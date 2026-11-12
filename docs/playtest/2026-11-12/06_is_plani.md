# İş planı: satışa hazır Wayborne

Kapsam kesilmez. Takvim üç senaryoyla verilir; seçim kullanıcınındır. Saatler tahmindir; ölçülmüş olanlar
işaretlidir. Kim: **K** kullanıcı · **C** Claude (uygulayıcı Opus) · **İ** ikisi birlikte (Claude yapar, kullanıcı
onaylar ya da içerik verir).

## 1. "Satışa hazır" ne demek

Her satır ölçülür; hepsi tutmadan 1.0 çıkmaz.

| no | ölçüt | nasıl ölçülür | bugün |
|---|---|---|---|
| S-01 | İlk karar ≤ 240 sn, ilk tehdit ≤ 900 sn (dört profil ortancası) | `playtest_driver` | 404-677 / 499-6032 |
| S-02 | 4 saatte en az bir büyüme basamağı (eşek, yarım vagon ya da vagon) gören profil ≥ 3 / 4 | huni | 0 / 4 |
| S-03 | 4 saatte doğan iz ≥ 12, dönen ≥ 4, bedel ödeyen ≥ 4, hâl geçişi ≥ 3 (okuyan profiller) | `ozet.json` | 0-10 / 0-4 / 0-2 / 0-1 |
| S-04 | En çok görülen kartın payı ≤ %10; 4 saatte farklı kart ≥ 35 | `kart_gorulme` | %12-20; 17-33 |
| S-05 | Çekilebilir kart ≥ 120, hepsi kalite listesinden geçer | `report_event_quality` | 101 |
| S-06 | "İyi şey" arası en uzun ≤ 18 gün (dört profil) | `iyi_sey_arasi` | 12-32 |
| S-07 | Açlık ölümünde son 5 günde en az 2 karar | `olaylar.jsonl` | 0 |
| S-08 | Oyunda AI üretimi görsel 0; `AI_DISCLOSURE.md` yeniden yazılmış | `envanter.py` | 181 |
| S-09 | Müzik, ortam ve efekt gerçek kayıt; sentez yer tutucu 0 | `AudioManager` listesi | hepsi sentez |
| S-10 | Kumandayla baştan sona oynanır; 1280x800'de taşma yok | `kumanda_denetimi.md` listesi | eksik |
| S-11 | TR ve EN tam; tanımsız anahtar 0; EN bir kez baştan okunmuş | çeviri testi + okuma | EN okunmadı |
| S-12 | 10 saatlik sürücü koşusunda çökme 0, `SCRIPT ERROR` 0; kayıt/yükleme 50 tur hatasız | CI | 4 saat temiz |
| S-13 | Mağaza sayfası: 5 ekran görüntüsü, 1 fragman, kısa ve uzun metin, etiketler | elle | yok |
| S-14 | Demo 60-90 dk, kendi başına biter, tam sürüme kayıt taşır ya da taşımadığını söyler | elle + sürücü | yok |
| S-15 | Windows derlemesi temiz makinede açılır; 60 FPS (1080p, orta donanım) | elle | ölçülmedi |

## 2. Kilometre taşları

| taş | çıkış ölçütü | içerik |
|---|---|---|
| **Dikey dilim** | S-01, S-02, S-07 tutar; ilk saat gerçek sahnelerle baştan sona görüntülenmiş | Dalga 1 (IP-001…IP-013) |
| **Alfa** | S-03, S-04, S-06 tutar; sistemlerin hepsi oyuncuya ulaşır | Y-R01, Y-R02, Y-C21, açlık kartları, kart 120 |
| **Demo** | S-14, S-10, S-12 (demo kapsamı) | Demo kesiti, kumanda, mağaza sayfası |
| **Beta** | S-05, S-09, S-11, S-12 tutar; görsellerin öncelik 1'i el çizimi | Ses, çeviri okuması, 181 görsel |
| **Aday** | S-08, S-13, S-15 tutar; açık P0/P1 hata 0 | Kalan görseller, fragman, denge son tur |
| **1.0** | 15 ölçütün hepsi | — |

## 3. İş paketleri

| no | paket | sütun | saat | kim | bağlı | kabul | risk |
|---|---|---|---|---|---|---|---|
| WP-01 | Dalga 1: ilk saat ve açlık (IP-001…IP-009) | İnsanlar aşınır · Yol yaşar | 40 | C | K-03, K-04 | S-01, S-02, S-07 | Düşük |
| WP-02 | İz ve bedel hacmi (IP-010, IP-011, Y-R01 kalan 30 satır) | Defter unutmaz | 60 | C | — | S-03 | Orta: iz tavanı |
| WP-03 | Yankı varyantları (Y-R02) | Defter unutmaz | 30 | C | WP-02 | 22 → 60 kart | Düşük |
| WP-04 | Kart hacmi 101 → 120+ (Y-E01, Y-E04, Y-E09…E13) | Yol yaşar | 80 | İ | lore kararı | S-04, S-05 | Orta: metin onayı |
| WP-05 | Kıtlık omurgası (Y-C21…C24 kalanı, Y-C25, Y-C26) | dördü | 90 | İ | K-06 | S-06 | Yüksek: kapsam |
| WP-06 | Borcun yüzü (IP-013) | İnsanlar aşınır | 10 | C | K-05 | H-06 kapanır | Düşük |
| WP-07 | Ölçüm: sürücü CI'da, sahne turu (IP-008) | — | 20 | C | — | S-12 | Düşük |
| WP-08 | Kumanda ve 1280x800 (Y-J*) | — | 50 | C | — | S-10 | Orta |
| WP-09 | Ses: müzik, ortam, efekt, nidalar | Yol yaşar | 120 | K + İ | K-07 | S-09 | **Yüksek: kaynak** |
| WP-10 | El çizimi öncelik 1 (183 görsel) | — | 292 | K | — | S-08 (kısmi) | **Kritik yol** |
| WP-11 | El çizimi kalan (532 kalem) | — | 1766 | K | WP-10 | S-08 | **Kritik yol** |
| WP-12 | Çizimi oyuna alma, `HumanSkin`, ekran doğrulama | — | 90 | C | WP-10 | her teslim ekranda | Orta |
| WP-13 | Çeviri: EN baştan okuma, yazım, glif | — | 40 | İ | WP-04 | S-11 | Düşük |
| WP-14 | Demo kesiti (Y-I*, `demo_next_fest.md`) | — | 40 | C | WP-01 | S-14 | Orta |
| WP-15 | Mağaza sayfası, fragman, basın paketi | — | 60 | K + İ | WP-10 kısmi | S-13 | Orta |
| WP-16 | Denge son turu (`simulate_career`, sürücü) | Ticaret bilgi oyunudur | 40 | C | WP-05 | S-02, S-06 | Orta |
| WP-17 | Sürüm: derleme, kayıt uyumu, çökme, başarımlar | — | 40 | C | hepsi | S-12, S-15 | Düşük |
| WP-18 | Codex ve tasarım notları (72 kart notu) | — | 30 | C | lore | codex tam | Düşük |
| WP-19 | Hikâye ve kampanya diyalogları | Defter unutmaz | ? | K | lore | kullanıcı | **Belirsiz** |

Toplam: kullanıcı 2058 saat çizim + ses ve mağaza için ~100 saat; Claude ~570 saat eşdeğeri iş (takvimi belirlemez,
çizimle koşut yürür). WP-19'un saati kullanıcı kapsamı söyleyince yazılır.

## 4. Kritik yol

Çizim (WP-10, WP-11) → oyuna alma (WP-12) → AI beyanı (S-08) → aday. Kod işlerinin hepsi bunun gölgesinde biter.
Çizimi kısaltan tek kaldıraç haftalık saattir; kapsam kesilmez.

| senaryo | haftalık çizim | öncelik 1 (292 s) | tamamı (2058 s) | demo | 1.0 |
|---|---|---|---|---|---|
| A | 15 saat | 20 hafta → Nis 2027 | 137 hafta → Haz 2029 | Eki 2027 fuarı | 2029 3. çeyrek |
| B | 30 saat | 10 hafta → Oca 2027 sonu | 69 hafta → Mar 2028 | **Şub 2027 fuarı yetişir** | 2028 2. çeyrek |
| C | 45 saat | 7 hafta → Ara 2026 sonu | 46 hafta → Eki 2027 | Şub 2027 fuarı (payla) | 2027 4. çeyrek |

Öncelik 1'in 520 saati orantıyla çıkarıldı (181 / 714 × 2053) **[Tahmin]**; `el_cizimi_takip.xlsx` Özet sayfasındaki
gerçek saatle değiştirilmeli. Tarihler 2026-11-12'den sayıldı ve boş hafta içermez.

## 5. Kullanıcının kararları

Dalga 1 başlamadan cevaplanması gerekenler **K-03, K-04, K-05**; öbürleri takvimi belirler.

| no | karar | seçenekler | önerim |
|---|---|---|---|
| K-01 | Haftalık çizim saati | A 15 · B 30 · C 45 | B: öncelik 1 Ocak sonunda biter, Şubat 2027 fuarı yetişir |
| K-02 | Sıra | (a) demo → erken erişim → 1.0 · (b) demo → 1.0 · (c) erken erişim yok, kapalı beta | (a), ama erken erişim öncelik 1 görseller bittikten sonra |
| K-03 | Büyüme basamağı: yalnız görünür kılınsın mı, eşek/yarım vagon fiyatı da ölçülsün mü | yalnız görünürlük · görünürlük + fiyat ölçümü | Önce görünürlük, sonra yeniden ölç |
| K-04 | Garantili karşılaşmada tür dönüşümü (sıklık aynı) | evet · hayır | Evet |
| K-05 | Borcun yüzü: alacaklı kartının ağırlığı borçla artsın mı, lider stresi borca bağlansın mı | ikisi · yalnız kart · hiçbiri | Yalnız kart, sonra ölç |
| K-06 | Kıtlığın sebebi (lore) | büyülü · mevsim | Senin sözün; WP-05 buna bağlı |
| K-07 | Ses kaynağı | kendin kaydet · müzisyenle çalış · lisanslı kütüphane | AI beyanı hedefiyle uyumlu olan ilk ikisi |
| K-08 | Demo kayıtları tam sürüme taşınsın mı | evet · hayır | Hayır; demo kendi başına biter |
| K-09 | Fiyat ve bölgesel fiyat | — | Beta'da karar |
| K-10 | WP-19'un kapsamı (kampanya yok; ek görev diyalogları ne kadar) | — | Senin sözün |

## 6. Var olan görevlerle bağ

Yeni bölüm: `proje_takibi/referans/gorevler/20_oyun_testi_ve_satis_plani.md` (IP-001…IP-013, K-01…K-10). Var olanlar
yeniden açılmadı, pakete bağlandı: Y-R01, Y-R02 → WP-02, WP-03 · Y-E01, Y-E02, Y-E04, Y-E08, Y-E09…E13 → WP-04 ·
Y-C21…C26, Y-C29, Y-C31, Y-C33, Y-C34 → WP-05 · Y-J01T, Y-J02, Y-J03, Y-J06, Y-J10, Y-J12, Y-J14 → WP-08 ·
Y-I01…I03 → WP-14 · N31d, N31f → WP-09 · Y-G13, Y-G17, Y-G18 → WP-12 · Y-A06, Y-A07, Y-D04, Y-H02, Y-H06 → WP-16,
WP-17.
