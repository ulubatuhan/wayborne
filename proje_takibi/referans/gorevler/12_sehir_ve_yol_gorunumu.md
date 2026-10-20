# §12. Şehir ekranı ve yol görünümü (kullanıcı, 2026-10-17)

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

Her madde sonrası ekran görüntüsü alınıp kullanıcıya gösterilmeli.

- [ ] **12.1 Şehir menülerinde kamera şehre çok yakın, bir tık geriden bakılmalı.**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b620a9b`): Lens 24->20 (kadraj ~%20 geniş); deneme render: vastrevar kenarlarda boşluk yok.
  - **Yer:** `scripts/ui/grim/city_front.gd:64-67`. Arka plan `TextureRect`, `STRETCH_KEEP_ASPECT_COVERED` ile ekranı kaplıyor; bu yüzden kenarlardan kırpılıyor ve yakın görünüyor. Tıklama eşlemesi `cover_to_image()` (`:120`) aynı kaplama hesabını kullanıyor.
  - **Seçenekler:**
    - **(a, önerilen)** Kasaba render'larını daha geniş kadrajla yeniden al: `tools/ui_scenes/town_scene.py` içindeki kamera uzaklığı ya da odak uzaklığı yaklaşık %15–20. `mask.png` aynı kameradan yeniden üretilmeli.
    - **(b)** Mevcut görseli yaklaşık %85 ölçekle göster; kenarda kalan boşluğu gökyüzü ya da zemin uzantısıyla doldur. Bu durumda `cover_to_image()` ve tıklama alanları yeni ölçeğe göre güncellenmeli.
  - **Kabul:** 6 şehrin hepsinde şehrin silueti ve çevresi biraz daha görünür; mekân levhaları, kadro kartları ve alt şerit hâlâ yerinde; maske tıklamaları doğru (`tests/test_grim_ui.gd` CityFront eşleme testleri).

- [ ] **12.2 Yol görünümü: büyük revizyon (overhaul).** Kullanıcı: "yol görünümü üzerine büyük bir overhaul çalışması yapacağız." Aşağıdaki üç sorun ilk somut maddeler. Kapsam §9.9–9.10 (yol HUD'u ve biyom arka planları, art referansları) ve §10b ile birlikte planlanmalı. Önce kısa bir tasarım notu yazılıp kullanıcıya onaylatılsın, sonra uygulansın.
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `2dd895a`): 12.2a, 12.2e, 9.9, 9.10 bu notta sıralı.
  - [ ] **12.2a Şehir kapısı görünümü çok kötü ("rezalet"), baştan tasarlanmalı.**
    - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `5bfcc7d`): settlement_gates.py her yerleşimin kapısını kasabasından türetir (gök, ışık, kar, mimari değer); render WAYBORNE_TOWN_CFG/OUT ile build/gates altına. Yuvarlak Tower minareye benzediği için kullanılmadı.
    - Varış ve ayrılışta yolun sonundaki şehir kapısı ve sur sahnesi.
    - **Yer:** `scripts/ui/travel_band.gd` (kapı ve varış çizimi; `:203` ve `:1045` civarındaki notlar), şehir kapısı sesi ve varış akışı `road_journey.gd`.
    - **Yön:** Render edilmiş, katmanlı bir kapı sahnesi:
      - sur, kapı kemeri ve kuleler,
      - şehrin kendi mimari ve kültür dili (CityFront kasaba render'larıyla aynı set),
      - kervanın kapıya yaklaşırken ölçeklenmesi ve kapıdan geçişi.
    - Referanslar §9.3 (A-25…A-29, T-01).
    - **Kaynaklar (CC0, 2026-10-17):** sur, kule ve kapı modülleri Kenney Castle Kit ve Fantasy Town Kit (CC0), Quaternius Medieval Village MegaKit (elde varsa CC0; yeni indirme QAL). Render + mürekkep geçişi (Y-G02). Kapı sesi için hazır CC0 kayıt yok: Freesound CC0 `large wooden door`, `chain rattle`, `winch` katmanlanarak tasarlanır. Kullanıcı kararı: kervan şehre girmez; kapı sahnesi varışta kervanı kapı önünde bırakır (Y-G10T).
  - [ ] **12.2b Yol üstündeki kule (durak), kamp kurulduktan sonra kadrajdan bir anda kaçıyor.**
    - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `0b5e4b6`): Kod ve test önceki turda; gözle doğrulanacak.
    - **Gözlem (kullanıcı):** Yolda giderken karşıya bir kule çıkıyor; kamp kuruluyor; ardından kule bir anda kadrajdan kayboluyor.
    - **Yer:** Durak çizimi `travel_band.gd:951-1006` (`STOP_SPRITES`, karakol kulesi `:993-1006`).
    - **Olası sebep:** Kamp kurulunca `_layout()` ya da bant kayması yeniden hesaplanıyor (kamp yerleşimi, `road_caravan.gd` `_refresh_gather_targets()` notu), ya da duraklar yolun "önündeki boş alana" göre yerleştirildiği için kamp konumu değişince durak çapası kayıyor.
    - **Çözüm:** Durağın dünya konumu, yol mesafesi cinsinden sabit olsun; kamp ve yeniden düzenleme onu kaydırmasın.
    - **Test:** Kampa girmeden önce ve sonra durağın ekran x'i aynı (ya da yalnızca kamera hareketi kadar farklı).
  - [ ] **12.2c Kamp: karakterler ateşe çok yavaş yürüyor (3x'te bile); ateşe varana kadar sabah oluyor; ateş ilk varan kişiyle yansın.**
    - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `968111f`): Ateş sesi (tutuşma + çıtırtı döngüsü, prosedürel) eklendi; ekranda ve kulakla doğrulanacak.
    - **Kullanıcı:** "Buradaki temel sorun karakterlerin çok çok yavaş yürümesi. 3x'te dahi yavaşlar." "Ateş, ilk kişi ateşin başına vardığında yansın." Gidip dönme yaklaşık 10 oyun saati sürüyor.
    - **Kodda görülen** (`scripts/ui/road_caravan.gd`):
      - `gather_seconds()` (`:1198-1209`): süre = `max(1.3, 1.5 × en_uzak_mesafe / en_yavaş_figürün_tempolu_hızı)`.
        - En yavaş figürün hızı ve 1,5 çarpanı tüm grubu yavaşlatıyor.
        - En uzaktaki vagon da süreyi uzatıyor.
      - Süre gerçek saniye üzerinden; oyun hızı çarpanı (2x, 3x) büyük ihtimalle yürüyüşe uygulanmıyor. Bu yüzden 3x'te de aynı yavaşlık var. **Doğrula.**
      - Kamp süresi `road_journey.gd:2279` `_camp_ends_at_hours = _clock.total_hours + CAMP_HOURS` (8 saat). Saat yürüyüş sırasında kampın hızlı akışıyla ilerliyor, sayaç yürüyüş bitmeden başlıyor. Bu yüzden ateşe varmak saatler yiyor ve sabah oluyor.
    - **Yapılacak:**
      1. **Yürüyüş hızı:**
         - Toplanma ve dağılma yürüyüşü tempolu bir hızla olsun; en yavaşa göre ve 1,5 çarpanıyla uzatılmasın. Herkes kendi tempolu hızıyla yürüsün.
         - Toplam yürüyüşe bir üst sınır: gerçek zamanda en fazla yaklaşık 2–3 sn (1x'te).
         - Oyun hızı çarpanı yürüyüş animasyonuna da uygulansın: 3x'te üç kat hızlı.
      2. **Ateş:** Kamp ateşi ilk figür ateş başına vardığında yansın. Kısa bir tutuşma animasyonu (kıvılcım, alevin büyümesi) ve ateş sesi; varmadan önce yalnızca odun yığını görünsün.
         - **Ses kaynağı (CC0):** Freesound CC0 `campfire` (114 sonuç; ör. kyles “fire small campfire crackling”) taban döngü, ayrı rastgele çıtırtı sesleri; tutuşma için `torch ignite`, `fire whoosh`. Ayrıntı: `../ICERIK_IHTIYACLARI.md` S-3.
      - **Not (kullanıcı kararı, Y-B09):** Yol yeterince dolunca 1.5x ve 3x hızları kalkacak; o zaman aşağıdaki (b) testi kaldırılır.
      3. **Saat:**
         - Toplanma ve dağılma sırasında oyun saati durmasın ama normal yürüyüş hızıyla aksın; kampın hızlı akışı uygulanmasın.
         - `CAMP_HOURS` sayacı herkes ateşe vardığında başlasın.
         - Toplanma ve dağılmanın toplamı en fazla yaklaşık 0,5 oyun saati.
      4. Kampın kurulduğu ve kalkıldığı saat günlüğe yazılsın.
    - **Test** (`tests/test_camp_gathering.gd` ve yeni ekler):
      - (a) 1x'te toplanma ≤ 3 sn gerçek zaman.
      - (b) 3x'te süre üçte birine iniyor.
      - (c) İlk varan figürle ateş yanıyor; ondan önce yanmıyor.
      - (d) Kamp kurma ve kalkma arası tam `CAMP_HOURS` ± 0,1; yürüyüşler toplam ≤ 0,5 oyun saati.
      - (e) Mevcut üst üste binme ve oturma testleri geçiyor.
  - [x] **12.2d Kervanın altında, yerde ağaç kütüğü gibi çubuklar görünüyor; anlamsız duruyor.**
    - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `2eaec93`): Kullanıcı 12.2d şeritlerinin kalmasını onayladı.
    - **Gözlem (kullanıcı):** Yolda giderken kervanın alt kısmında, yerde kütük ya da çubuk benzeri dikey parçalar var.
    - **Olası kaynaklar** (önce ekran görüntüsüyle ve katmanları tek tek kapatarak doğrula):
      1. **Yol kenarı nesneleri:** `scripts/ui/travel_band.gd:1094` `_draw_ground_props()`.
         - Koddaki not (`:1107-1113`): yakın kenardaki nesneler yolun bankında bitiyor ve yol en son çiziliyor.
         - Çalı ya da ağaçların alt kısmı bankta kalıp üstü yolun altında kaybolunca geriye yalnızca gövde (çubuk) görünüyor olabilir.
         - Yolun yakın kenarındaki (kameraya yakın) ağaçlar, kervanın hemen altında kesik gövdeler olarak okunuyor.
      2. **Render edilmiş zemin şeridi:** `RoadStrips.GROUND` (`travel_band.gd:490`, `:539`). Şerit görselinin kendi içindeki çit kazığı, kütük ya da dal desenleri kervanın tam altına denk geliyor olabilir.
      3. **Duraklar:** `travel_band.gd:951-1006` `STOP_SPRITES`. Çit ya da kazık parçaları zemin hizasında kalıyor olabilir.
    - **Çözüm:**
      - Kervanın yürüdüğü şeridin (yol ve hemen önü) içine dikey ve ince hiçbir nesne konmasın: kervan şeridi için bir "boş bant" maskesi.
      - Yakın kenar nesneleri ya tamamen görünür olsun (tepesi dahil) ya da hiç çizilmesin; yarım kesik gövde kalmasın.
      - Zemin şeridinde kervan bandına denk gelen bölge düz zemin olsun.
    - **Test:** Yol ekranının ekran görüntüsü testine (`tests/screenshot_journey_screen.gd`) bir kontrol: kervan bandının dikdörtgeni içinde dikey ince koyu çizgi kümesi yok (basit kenar yoğunluğu ölçümü) ya da elle onay.

  - [ ] **12.2e Yol sahnesi estetik olarak güzel değil; her detayı yeniden tasarla: çimen, yol, arka plan, güneş.**
    - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `2dd895a`): Gerçek şeritlerle; değişen yalnızca gök, güneş-ışık, renk derecelendirmesi, sis şeridi, gece feneri.
    - **Kullanıcı:** "çimenler, yol, arka plan, hele ki güneş estetik olarak güzel bir sahne değil, buradaki her detayı yeniden tasarlamak lazım."
    - **Bugünkü yapı:** `scripts/ui/travel_band.gd` katmanları, uzaktan yakına:
      | Katman | Kod |
      |---|---|
      | Gökyüzü | `_draw_sky()` `:589` |
      | Güneş ve ay yayı | `:613-` civarı, "Güneş/ay ufuk boyunca bir yay çiziyor" |
      | Uzak sırtlar | `_draw_far_ridges()` `:683`, ya da render şeridi `RoadStrips.FAR` |
      | Orta sırtlar | `_draw_mid_ridges()` `:696` / `RoadStrips.MID` |
      | Zemin dolgusu | `_draw_ground_fill()` `:795` / `RoadStrips.GROUND` |
      | Yol | `_draw_road()` `:841` |
      | Yol kenarı nesneleri | `_draw_ground_props()` `:1094` |
      | Hava | `_draw_weather()` |
      - Prosedürel çizim ile render şeritleri (`scripts/ui/road_strips.gd`) karışık kullanılıyor; biyom geçişi `RoadStrips.draw_blend`.
    - **Yeniden tasarım adımları** (her biri için önce bir mockup ya da tek kare render çıkarılıp kullanıcıya onaylatılsın):
      1. **Görsel dil kararı:** Yol sahnesi, haritanın ve UI'ın "mürekkep ve parşömen + karanlık arayüz" diliyle nasıl konuşacak? §9.10'daki referanslar (A-03, A-05, A-07, A-09, A-10, A-12, A-20, A-24): soğuk uzak katman, sıcak ön plan, sis şeridi, sınırlı palet, güçlü siluet. Karar tek sayfalık bir stil rehberine yazılsın.
      2. **Gökyüzü ve güneş:**
         - Güneş bugün düz bir disk ve yay; çiğ duruyor.
         - Öneri: güneşi ve ayı doğrudan göstermek yerine ışığın kendisini göster:
           - ufukta sıcak ışık bandı,
           - bulut kenarlarında ışık,
           - gece ay ışığı,
           - gerekirse çok yumuşak, haleli küçük bir disk.
         - Gün evreleri (şafak, gündüz, akşam, gece) için 4 palet anahtarı. Hava durumu (kapalı, yağmur, sis) bu paletleri griye çeker ama evreyi silmez (koddaki mevcut kural korunur).
      3. **Uzak ve orta katmanlar:**
         - Biyom başına render edilmiş, döşenebilir ve paralakslı katmanlar.
         - Uzak katman soğuk ve düşük kontrastlı, orta katman siluetli.
         - Sis şeridi ayrı bir katman.
         - Prosedürel sırtlar kaldırılsın ya da yalnızca yedek olarak kalsın.
      4. **Zemin ve çimen:**
         - Tekdüze çimen dolgusu yerine katmanlı zemin: uzakta tonal düzlük, yakında seçici detay (tutam, taş, iz).
         - Yakın plan detayı az ama nitelikli olsun.
         - Kervan bandı sade kalsın (12.2d).
      5. **Yol:**
         - Tekerlek izi ve çamur; biyoma göre toprak, taş ya da kar.
         - Kenarlar yumuşak ve doğal; bugünkü koyu bank çizgisi yerine çimen ile yol arasında organik geçiş.
         - Okunurluk korunmalı: yol zeminden ayrılmalı (koddaki %42 ayrım dersi).
      6. **Yol kenarı nesneleri:**
         - Biyomun ağaç, çalı ve kaya seti; derinliğe göre ölçek ve pus.
         - Yarım kesik nesne yok (12.2d).
         - Yoğunluk biyoma göre.
      7. **Işık ve atmosfer:**
         - Günün saatine göre tüm katmanlara tek bir renk derecelendirmesi.
         - Gece fener ve kamp ateşi ışığı. Kervanın feneri haritadaki atlı işaretle aynı dili paylaşsın: `../belgeler/ATLI_ISARET.md`, §8.10–8.11.
      8. **Performans:** Hedef PC'de 60 FPS (orta sınıf ekran kartı). Web yalnız test için, ölçüt değil. Katmanlar önbellekli dokular; kare başına yeniden çizim en az. §5 ve §2.2 kuralları geçerli.
    - **Kabul:** Dört gün evresinde ve en az üç biyomda (ova, orman, dağ) ekran görüntüleri kullanıcı tarafından onaylanmış. Kervan, yol ve HUD okunurluğu korunmuş. Mevcut yol testleri (`tests/test_road_layers.gd` ve diğerleri) güncellenmiş ve geçiyor.
    - **Kullanıcı kararı (2026-10-17, Y-G07):** Tek biyom değil, bütün biyomlar için birer örnek kare; sonra varyantlar. Biyom haritadan seçilir, arka plan haritadaki konuma göre kurulur (dağlık yerde arkada dağ). Kaynaklar Y-G07'de.
    - **Bağlantılı maddeler:** 12.2a (şehir kapısı), 12.2b (durak ve kule), 12.2c (kamp), 12.2d (yerdeki çubuklar), §9.9–9.10 (yol HUD'u ve biyom arka planları), §10 (binici, arabacı, koşum), §10b.
