# §9. İkinci art çalışması: menüler ve arka planlar

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

**Ana belge:** `../belgeler/ART_IKINCI_TUR_REFERANSLARI.md`

**Kaynak:** Kullanıcının üç referans belgesi, `../referanslar/art_ikinci_tur/kaynak_belgeler/` içinde. Bu belgelerden 46 görsel çıkarıldı; görsel kodları belgede kullanılan kodlarla aynı.

| Kaynak belge | Görsel | Klasör |
|---|---|---|
| arka planlar | A-01 … A-29 (29) | `../referanslar/art_ikinci_tur/gorseller/arkaplanlar/` |
| karakter, stat ve savaş ekranları | K-01 … K-05 (5) | `../referanslar/art_ikinci_tur/gorseller/karakter_ve_savas/` |
| kasaba ekranları | T-01 … T-12 (12) | `../referanslar/art_ikinci_tur/gorseller/kasaba/` |

**Belgenin içeriği:**
- Her görsel için yerleşim, palet, ışık, tipografi ve bileşen analizi.
- Kullanıcının görsellerin yanına yazdığı notlar, aynen.
- Her görsel için "Wayborne'a uyarlanacak olan" maddeleri.
- Bölüm 4: ortak görsel dil.

**Kurallar:**
- Referanslar ilke olarak uyarlanacak, birebir kopyalanmayacak.
- Yeni dosya, sınıf ve asset adlarında "referans oyun", "referans oyun", "referans oyun" ya da "mezra" geçmeyecek. "grim" serbest.
- Belgede kaynak oyundan yalnızca "referans oyun" diye söz ediliyor.

İş listesi aşağıda. Her maddenin önerilen asset adları ve kabul kriterleri belgenin 5. bölümünde, aynı numarayla.

- [ ] **9.1 Ortak UI kiti v2** (K-01, K-03, T-02…T-12)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kenney UI Pack RPG Expansion + Fantasy UI Borders (CC0) indirilince kâğıt-mürekkep diline boyanır; Y-G11T ve 9.4-9.9 taslaklarındaki ince çerçeve ve kehribar vurgu bu kitin hedefi.
  - 9-slice panel çerçevesi, başlık şeridi, kırmızı ana eylem düğmesi (tüm durumlarıyla), tooltip plakası, seçim köşebentleri.
  - **Kaynak (CC0, 2026-10-17):** Kenney UI Pack RPG Expansion (85 dosya) ve Kenney Fantasy UI Borders (140 çerçeve), ikisi de CC0. Çerçeveler kâğıt ve mürekkep diline yeniden boyanır (stil rehberi Y-G01); kullanıcının reddettiği çizik, deri ve nine-slice süs dili kullanılmaz (25–27 Eylül kararları). Süsleme ve vinyet için Old Book Illustrations “Ornaments” görselleri (görseller serbest, açıklama metinleri NC, kopyalanmaz). Ayrıntı: `../ICERIK_IHTIYACLARI.md` G-7.
- [ ] **9.2 Ana menü gece kampı, katmanlı** (A-25, A-19, A-10, A-17)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Mor-lacivert gök ve tek ateş ışığı resmin kendisinden; duman ayrı katman; sağda arayüz için karanlık sade alan.
  - Mor-lacivert gök ve tek ateş ışığı.
  - Duman ayrı katmanda.
  - Arayüze karanlık, sade bir alan bırakılacak.
- [ ] **9.3 CityFront durum varyantları** (A-25…A-29, T-01)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Piksel hizalı renk ve ışık türetimi; gerçek uygulamada gök town_post adım 1de varyanta göre değişecek (taslakta ay her varyantta kalıyor). Kalabalık ve hasar katmanları Y-G10T ile.
  - Varyantlar: alacakaranlık, gece, gri, kriz.
  - Katmanlar: pencere ışığı, ışık huzmesi, hasar ve kalabalık.
  - Hepsi mevcut `mask.png` ile piksel hizalı olacak.
- [ ] **9.4 Mekân ekranları** (T-02…T-09)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Ortak bir iskelet.
  - Büyük sahip portresi.
  - Mekânın mimarisinden türeyen yuvalar: kilise nişi, taverna fıçısı, şifacı kapısı.
- [ ] **9.5 Pazar, erzak ve envanter** (T-12, T-08)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Üstte fiyatlı mal kartları, altta kervan envanteri.
- [ ] **9.6 Karakter ve stat ekranı** (K-01)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Üç sütun: kimlik ve figür / huylar ve statlar / beceriler ve dirençler.
- [ ] **9.7 Roster kartı ve seviye rozeti** (K-01, T-02, T-11)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Seçili ve yaralı durumlarıyla.
- [ ] **9.8 Savaş ekranı** (K-03…K-05)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Alt panel: solda aktif üye, sağda hedef kartı.
  - Tur madalyonu.
  - Kritik vuruşta renk değişimi ve yakınlaşma.
  - `g9_seal` ile uyumlu bir öldürücü darbe mührü.
- [ ] **9.9 Yol HUD'u** (K-02; çatlak efekti kaldırılacak, bkz. §2.5)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Alt panel (P18) zaten sekmeli: harita ve envanter orada.
  - `SurvivalGauge` ince çubuk, amblem ve çentiklerle çizilecek.
  - Harita ve envanter sekmeli alt panel.
  - Bu iş §8 ile bağlantılı.
- [ ] **9.10 Yol arka planları, biyom başına** (A-03, A-05, A-07, A-09, A-10, A-12, A-20, A-24 …)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `2dd895a`): Y-G07 biyom şeritleri hazır; sis şeridi ve gece varyantı taslakta, enkaz (Broken Cart) 12.2 sırasının 5. adımı.
  - Katmanlar: soğuk uzak katman, sıcak ön plan, döşenebilir orta katman, sis şeridi.
  - Kervan enkazı eşyası.
  - Gece varyantı.
  - **Kullanıcı kararı ve kaynaklar:** Bu iş **Y-G07** ile birlikte yapılır (bütün biyomlar, haritadaki konuma göre varyantlar). Dokular Poly Haven ve ambientCG (CC0), nesneler Kenney Survival Kit ve Quaternius (yeni indirmeler QAL), enkaz Quaternius `Broken Cart`. Ayrıntı: `../ICERIK_IHTIYACLARI.md` G-2, G-4.
- [ ] **9.11 Waybook ve defter** (T-10, T-11)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Hikâye satırları.
  - "Düşenler" sayfası: mezar işaretleri rütbeyle süslenir.
- [ ] **9.12 Kilise ve mezarlık arka planı** (A-01, A-06, A-14, T-03)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kenney Graveyard Kit (CC0) indirilince town_scene hattıyla sakin ve nöbet varyantları; dini sembol yok, lore (Y-E06) işaretleri bekleniyor.
  - Tek illüstrasyondan sakin ve nöbet varyantları.
  - **Kaynak:** Kenney Graveyard Kit (CC0; mezar taşı, çit, kripta). Kural: gerçek dinî yapı ve figür yok; haç ve benzeri semboller çıkarılır. Lore'daki inançlara (Y-E06) göre özgün işaretler.
- [x] **9.13 İsimlendirme temizliği, art tarafı**
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `0dc0f02`): e6j_mezra.jpg -> e6j_village.jpg, road_journey.gd başvurusu güncellendi (1.1 ile birlikte).
  - `data/assets/ui/waybook/e6j_mezra.jpg` dosyasını `e6j_village.jpg` olarak yeniden adlandır.
  - `scripts/ui/road_journey.gd` içindeki başvuruyu güncelle.
  - Bu iş §1.1 ile birlikte yapılmalı.

**Uygulama sırası önerisi:**
1. 9.1 ortak kit: diğer her şey onun kenar dilini kullanacak.
2. 9.2 ana menü ve 9.3 şehir: en çok görülen ekranlar.
3. 9.4–9.8 mekân, karakter ve savaş ekranları.
4. 9.9–9.12.

Her aşamada ekran görüntüsü alınıp kullanıcı onayına sunulmalı. CLAUDE.md'deki "Waybook UI Rules" ve "Art Rules" geçerli.
