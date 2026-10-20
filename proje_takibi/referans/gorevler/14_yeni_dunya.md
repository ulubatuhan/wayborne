# §14. Yeni dünya: yerleşimler, mesafeler, menüler ve yol kontrol paneli

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

**Kaynak:** Kullanıcı kararları, 2026-10-18. Eski beş yer tutucu şehir (Karakonak, Kurtboğazı, İpekevi, Demirkapı, Yeşilova) **unutulacak**; oyun gerçek haritadaki yerleşimlerle oynanır. Y-C01 (kimlik eşlemesi, dünyanın tamamı hemen) bu bölümün çatısı: 8.3, 8.4 ve Y-C01 bu görevlerle birlikte yapılır.

## Kullanıcı kararları (aynen özet)

**Oynanabilir yerler.** Her şehir, kasaba ve kervansaray oynanabilir (harita v3'te 12 şehir, 12 kasaba, 3 kervansaray = **27 yer**; Tarvessa ve Ombrakal kervansarayları v3'te kaldırılmıştı). Diğer yerleşimler (köy, mezra, kamp, balıkçı köyü, maden kabilesi…) yol durağı olarak kalır.

| | Şehir | Kasaba | Kervansaray |
|---|---|---|---|
| Aksiyonlar | **hepsi** (pazar, lonca, taverna, kilise, kervan avlusu, terzi, işe alma…) | pazar, taverna ve benzeri; **lonca yok, kervan avlusu yok** | **kervan avlusu var, lonca yok**; han ve pazar |
| Ticaret | tam | **payı düşük**; temel ürünler **daha ucuz**; **her ürün bulunmaz** | **değişik ürünler**; alırken **pahalı**, satarken **ucuz** |
| Kontrat varışı | evet | evet | **hayır** |

Kontrat destinasyonu yalnızca şehir ve kasaba olabilir.

**Ölçek.** Büyük bir kıta. Westeros'un en güneyinden en kuzeyine gitmek x gün sürüyorsa, bizim kıtanın kuzey ucundan güney ucuna gitmek **3x/4 gün** sürsün. Aradaki iki yerleşim arası yol kolay bitmesin, keyifli bir süre tutsun; süreler yerleşimlerin harita konumundan çıksın.

**Menüler.** Şehir menüleri her şehre ve kasabaya göre yenilenecek; **her yerleşime özel tasarım**.

**Yol kontrol paneli.** Yol ekranında altta yalnızca çimen görünmesin; referans oyunlardaki ve Kenshi'deki gibi bir kontrol paneli: parti, moral ve öteki statlar, durumlar; birkaç sekmeli.

## İkinci tur kararlar (2026-10-18, aynen özet)

1. **Westeros'ta güneyden kuzeye 81 gün** → bizim kıtanın kuzey ucundan güney ucuna **61 gün** (3×81/4 = 60,75).
2. **Başlangıç:** Yeni oyun, karakter oluşturmada seçilen kültürün bölgesindeki ya da o bölgeye yakın bir bölgedeki **rastgele bir şehirde (ya da kasabada)** başlar, her zaman.
3. **Yol paneli:** Kullanıcı güveniyor; referans oyunun ve Kenshi'nin panelleri mekanik olarak referans alınabilir. Onay beklemeden yapılır, ekran görüntüsü gösterilir.
4. **Stil cümlesi onaylı:** "Wayborne, bir kervan kâtibinin defterine ve haritasına mürekkeple çizilmiş bir dünyadır." Rehber yazılabilir.
5. **Menüler:** Kullanıcı güveniyor; stile, coğrafyaya ve kültüre bağlı kalınsın. Parti parti onay beklenmez, ekran görüntüsü gösterilir.
6. **Kültür benzetmeleri** (kullanıcının harita renkleri, `../belgeler/HARITA_GECMISI.md` 16 Ekim): Vadi → Tyrell benzeri; göçebe boyları → Türk boyları; kuzeyin eski imparatorluğu → Nilfgaard benzeri, askeri açıdan güçlü; güney kentleri → Essos benzeri, ticaret odaklı ve hoşgörülü; sınır halkları → arada kalmış karışık kültürler; dağ kabileleri ve madenler; Eski Ahit kutsal kenti. **Coğrafya gerçekleri önce gelir** (kıyı, dağ, bozkır, iklim).
7. **Mal tablosu:** Claude yapar.
8. **Harita oyuna dahil:** Karolar oyuna girer (yeni büyük dosyalar Git LFS ile; geçmişi yeniden yazan `lfs migrate` değil). Yolda haritayı açan bir **tuş ve ekranda düğme**: açılır pencere harita.

## Paketler

**Sıra (en az maliyet; her adım bir sonrakinin yeniden işini önler):**

| Adım | İş | Neden bu sırada |
|---|---|---|
| 1 | N1 katalog, N2 yol grafiği, N3 süreler | Yalnızca veri; her şeyin tabanı, kodu kırmaz |
| 2 | N5 mal tablosu, N4 kural verisi, N9 başlangıç kuralı (veri) | Aynı veri dosyasına yazılır; kod henüz değişmez |
| 3 | Karoları LFS ile oyuna al, N7 harita ekranı, N24 yolda açılır harita | Hazır bileşen (`MapTileView`) ve 1. adımın verisiyle; eski şehirlerden bağımsız |
| 4 | N6 eski beş şehri sök + N4 ve N9 kodu + kayıt göçü | En büyük kod işi, tek seferde: yeni veri hazır olduğu için bir kez yapılır |
| 5 | N8 denge ölçümü | Yeni dünya oturduktan sonra bir kez ölçülür |
| 6 | P18 yol paneli (N16–N23) | Dünya verisine bağımlı değil ama Harita sekmesi 3. adımı, Durum sekmesi yeni süreleri kullanır |
| 7 | P17 yerleşim menüleri (N10–N15) | En pahalı iş (27 tasarım); tesis kodu (4. adım) ve stil rehberi hazır olunca |

Kullanıcının 2. tur cevaplarıyla "senden bekleyenler" listesindeki maddeler plana görev olarak girdi (N3, N5, N9, N11, N24 ve karolar).

### P16 · Yeni dünya verisi

- [x] **N1 Yerleşim kataloğu** (`C`, Y-C01'in parçası)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `c3527b0`): 27 yerleşim (12 şehir, 12 kasaba, 3 kervansaray), settlements.json.
  - `wayborne_harita.geojson` ve `atlas/places_v3.json`'dan 29 oynanabilir yer: kimlik (kararlı, ASCII), tür (şehir, kasaba, kervansaray), kültür, boyut, harita konumu, adlar (tr, en, zh).
  - Çıktı: `data/config/settlements.json`; `world_places.json` bununla eşitlenir (8.4).
  - **Kabul:** Test: 12 + 12 + 5 yer, kimlikler tekil, kültür ve tür dolu.
- [x] **N2 Yol grafiği** (`C`, 8.3 ile birlikte)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `c3527b0`): 41 yol, tek bağlı graf, her yer en az iki komşulu.
  - Haritanın yollarından (kervan yolu ve ara yollar) yerleşimleri bağlayan graf; her kenarın uzunluğu harita pikselinde, güzergâh üzerinden (kuş uçuşu değil).
  - Her yerleşimin en az iki komşusu olsun; hiçbir yer ayrık kalmasın (`RouteConditions`'ın "şehir mühürlenemez" kuralı yeni grafta da geçerli).
- [x] **N3 Mesafe ölçeği ve süreler** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `c3527b0`): Kuzey-güney 61 gün; yollar 2-38 gün, ortanca 8. Rapor docs/design_notes/yerlesimler_rapor.md.
  - **Karar:** x = 81 → kuzey ucu ile güney ucu arası **61 gün**.
  - Ölçek, haritanın en kuzeydeki oynanabilir yeri ile en güneydeki arasındaki en kısa yol 61 gün etsin diye bulunur; tüm kenarların günü bundan türer, yuvarlanır.
  - Gün, **kervanın gerçek yürüyüş hızından** (1 gün = 45 sn gerçek zaman, 1x) ölçülür; komşu iki yerleşim arası hedef **5–12 gün** (yaklaşık 4–9 dakika), uçtan uca ~3x/4 gün.
  - Tehlike: bölge, biyom ve yerleşim türünden türer (kervan yolu güvenli, ıssız geçit tehlikeli); tehlikenin dökümü gösterilir (Y-F10).
  - **Kabul:** Tablo (yerleşim çifti, gün, tehlike) sana sunulur; onayla kilitlenir.
- [x] **N4 Yerleşim kuralları** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `887fa0c`): SettlementRules: tesisler, ticaret payı, kasaba temel mal indirimi, kervansaray alış/satış çarpanı; kontrat hedefi yalnız şehir/kasaba.
  - Yukarıdaki tablo koda: `settlements.json` her yerleşimin `facilities` listesini, `trade_share` (ticaret payı), `price_bias` (temel ürün çarpanı), `goods_available` (bulunan mallar) ve `buy_markup`/`sell_markdown` alanlarını taşır.
  - Kontrat panosu ve kontrat varışı yalnızca şehir ve kasabaya bağlanır; kervansaray hiçbir kontratın hedefi olamaz (test).
  - Kasabada lonca ve kervan avlusu düğmesi çıkmaz; kervansarayda lonca çıkmaz, avlu çıkar (test, her tür için ekran düğmeleri).
- [x] **N5 Mal tablosu** (`C`, kullanıcı Claude'a bıraktı)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f8c9df2`): tools/worldmap/economy.json.
  - Her yerleşimin ürettiği ve aradığı mallar: haritadaki kültür, boyut ve coğrafyadan (kıyı: balık, dağ: demir ve kürk, vadi: tahıl ve şarap). Tablo `goods_by_place.md` olarak bilgi için sunulur.
  - Kasaba: temel mallar (tahıl, balık, kürk, kumaş) ucuz, çeşit az. Kervansaray: nadir ve değişik mallar, alış pahalı, satış ucuz.
  - Çıktı özet tablo `goods_by_place.md`; onaydan sonra `settlements.json`.
- [x] **N6 Eski beş şehri sök** (`C`, büyük)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `887fa0c`): Eski beş şehir söküldü; SAVE_VERSION 4, kayıt göçü testli.
  - `test_loc_a…e`, `world_map_data.gd`'deki beş şehir ve yedi kenar, ona bağlı olaylar (`near_*` bayrakları, Kurtboğazı ve Demirkapı bölge kadroları, `region_id`), kampanya bölümleri, kontrat teklifleri, lonca vagon görevleri, testler ve ekran yazıları.
  - **Kayıt göçü:** eski kayıttaki `test_loc_*` kimlikleri yeni bir yerleşime eşlenir (`SAVE_VERSION` artar, `_migrate_save`); göç testi.
  - Kampanya bölümlerinin şehir bağımlılıkları yeni yerleşimlere yeniden yazılır.
- [x] **N7 Harita ekranı** (`C`, 8.1 ve 8.2 ile birlikte)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b4a41c2`): WorldMapView: karo, işaretler, yollar, 8 yönlü atlı. Atlının gölgesi 19555b5'te düzeltildi.
  - Yeni harita (`MapTileView`, hazır) + yerleşim işaretleri (tür simgesi) + atlı kervan (8 yön) + "Kervana git" düğmesi; yol durumu çizgiye vurur.
  - Karolar (49 MB) oyuna girer: yeni dosyalar Git LFS ile izlenir (geçmiş yeniden yazılmaz).
- [x] **N24 Yolda açılır harita** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b4a41c2`): M tuşu ve Harita düğmesi; zaman durur.
  - Yol ekranında bir tuş (öneri M) ve ekranda düğme: haritayı açılır pencerede gösterir, kervan ortada, hedef ve rota işaretli; zaman bu sırada durur (karar paneli gibi). Esc ve düğme kapatır.
  - Aynı bileşen yol panelinin Harita sekmesinde küçük hâliyle (N21).
- [x] **N8 Denge yeniden ölçümü** (`C`, N6 sonrası)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `bf9f5ff`): Kontrat günlük ücreti 14; 8 kervandan 1'i finale ulaşmıyor (politika batışı). docs/design_notes/denge_yeni_dunya.md.
  - Yollar uzayınca erzak vaadi ("doğru stoklayan aç kalmaz"), kontrat süreleri, kampanya temposu ve yolda olay sayısı yeniden ölçülür (`simulate_journeys`, `simulate_career`); ölçüm tabloları CLAUDE.md'ye.
  - Uzun yol, günlük olay sıklığının ve kamp ihtiyacının yeniden ayarını isteyebilir (Y-B02 yol yönetmeni).
- [x] **N9 Başlangıç yeri** (`C`, karar verildi)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `887fa0c`): Kültüre göre başlangıç adayları; ilk yolu 10 günü geçmeyen şehir/kasaba.
  - Karakter oluşturmada seçilen kültürün bölgesindeki ya da en yakın bölgedeki rastgele bir şehir veya kasaba; kervansaray değil.
  - Oyunun bugünkü 5 kültürü (göçebe, vadi, dağ, liman, balıkçı) harita bölgelerine eşlenir: göçebe → göçebe boyları (bölgede şehir yok, en yakın şehir/kasaba), vadi → Vadi, dağ → dağ kabileleri ve madenler, liman → güney kentleri, balıkçı → balıkçı köylerine en yakın kıyı şehir ve kasabaları. Tohum yeni oyunun tohumundan (yeniden yükleme değiştirmez).
  - **Açık soru (engellemez):** Haritada 8 kültür var, oyunda 5. Eski imparatorluk ve sınır halkları oynanabilir kültür olsun mu? Sonra sorulacak.

### P17 · Yerleşim menüleri

Her yerleşim kendi tasarımına sahip; ortak iskelet + yerel görsel. Menü, yerleşimin `facilities` listesinden kurulur (N4), sabit beş buton değil.

- [x] **N10 Veriden kurulan menü** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `887fa0c`): Levhalar tesis listesinden; olmayan mekân yok.
  - `city_map.gd` ve `CityFront` düğme listesini yerleşimin tesislerinden kursun; tesis yoksa düğme yok (disabled-with-reason kuralı yalnızca olan ama kilitli işler için).
- [x] **N11 Stil rehberi** (`C`, Y-G01)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): docs/ui/STIL_REHBERI.md.
  - Stil cümlesi onaylı (yukarıda). Bir sayfalık rehber: kâğıt ve mürekkep renk kodları, 3 ton kuralı, kontur, tarama, tek sıcak ışık, kırmızı yalnızca kan/kayıp/ana eylem, kehribar yalnızca ışık. `docs/` altına.
- [x] **N12 İskelet ve ilk örnek** (`C`, ekran görüntüsü gösterilir)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): Ortak iskelet + tools/ui_scenes/settlement_towns.py.
  - Ortak iskelet (mekân levhaları, kadro kartları, alt şerit) ve **tek** yerleşimde (öneri: Vastrevar) tam tasarım; ekran görüntüsü onayı.
- [x] **N13 Şehir menüleri, 12 yer** (`C`, ekran görüntüsü gösterilir)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): 12 şehir render edildi. Kullanıcı gözüyle onay bekliyor (TODO/KONTROL_BELGESI.md).
  - 3'erli dört parti, her parti senin onayınla. Her şehir kültürünün mimarisinden (göçebe, vadi, dağ, liman, eski imparatorluk, sınır halkı…) türer; lore gerekir (Y-E06).
- [x] **N14 Kasaba menüleri, 12 yer** (`C`, ekran görüntüsü gösterilir)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): 12 kasaba render edildi; kasabalar seyrek, ev sayısı artırılabilir.
  - Küçük şablon (daha az mekân), yerel arka plan ve yapılar; dört parti.
- [x] **N15 Kervansaray menüleri, 3 yer** (`C`, ekran görüntüsü gösterilir)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): 3 kervansaray render edildi.
  - Han avlusu iskeleti, yerel manzara; tek parti.
- **Üretim yolu:** Mevcut hat (`tools/ui_scenes/town_scene.py`, `towns.json`, Blender 4.2 yerelde kurulu) yerleşim başına bir JSON girdisiyle kurulur; elle boyama yok.

### Kullanıcı bildirimi (2026-10-19): yol ve harita düzeltmeleri

- [x] **N25 Dağ zirvelerindeki düz kesik** (`C`)
  - Dağ biyomunun uzak katmanı 768 karede yeniden render edildi; road_scene.py biyom başına kare boyu.
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `19555b5`).
- [x] **N26 Haritadaki atlının gölgesi toynaklara otursun** (`C`)
  - Gölge ve bağlantı noktası dört toynağın ortasında; 8 yön yeniden üretildi.
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `19555b5`).
- [x] **N27 Vagon sürücüsü yeni gövdeyle** (`C`)
  - Koltukta düz silüet yerine gerçek figür (climb_down ilk karesi).
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `19555b5`).

- [x] **N28 Yol biyomları haritanın gerçek arazisinden** (`C`)
  - Dağ, bataklık, göl, orman, bozkır güzergâhtan ölçülür; duraklar geçit, köprü ve yoldaki harita noktaları. Ters yönde dizi ters okunur.
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `2c8be40`).

- [ ] **N29 Vadiye özgü yeşil çayır biyomu** (`CO`)
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5ae38c4`): Kod, veri ve dört katman hazır; testler ve ekran görüntüsü TEST_PLANI.md'de, onay ONAY_PAKETI.md'de.
  - Bugün vadinin açık tarım arazisi "bozkır" şeridiyle çiziliyor (kuru, sarı ot). Vadi (Tyrell benzetmesi) bereketli: yeşil çayır, ekin tarlası, çit ve ağaç sırası, uzakta yumuşak tepeler.
  - Yeni biyom `meadow`: `ArtPalette` dört rolü (gökyüzü/uzak/yakın/flora), `tools/ui_scenes/road_scene.py` `BIOMES` girdisi ve dört katmanın (far, mid, ground, fore) Blender render'ı, `road_post.py`; `RouteTerrain.BIOME_CHAIN`, isim anahtarı (`TERRAIN_MEADOW`, tr/en), hava eğilimi (`RouteWeather`), ağaç çizimi.
  - Üreteç (`build_settlements.py`): vadi bölgesindeki açık arazi bozkır değil çayır; bozkır göçebe ve güney kuru topraklarında kalır.
  - **Kabul:** Belvanor-İlsande yolu çayır; ekran görüntüsü senin onayına; `test_grim_ui` şerit kenar testleri ve `test_route_terrain` geçer.
- [ ] **N30 Bozkırda yol durakları arasını aç** (`C`)
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5ae38c4`): Bozkırda durak aralığı 6 gün; test TEST_PLANI.md'de.
  - Göçebe bozkırında (ör. Selvicar-Orbeyan, 35 gün) yol beş yurtta durur; harita noktası durakları arasındaki en az aralık 3 gün.
  - Bozkır parçalarında aralık daha geniş (öneri 6 gün) ya da yol başına harita noktası durağı sınırı; dağ/su geçidi durakları etkilenmez.
  - **Kabul:** Selvicar-Orbeyan'da yurt durağı en çok 3; `test_route_terrain` geçer.

- [ ] **N31 Oyun hissi incelemesi ve planı** (`C`)
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `ebd4e3a`): Altı alan incelendi; N31a-N31f alt görevleri 14_yeni_dunya.md ye eklendi (gorevler.json a bir sonraki durum.py taramasında).
  - **Sütun:** Yol yaşar · İnsanlar aşınır (oyunun keyfi ve okunurluğu)
  - **Ne:** Kullanıcının getirdiği altı alanlı listeye göre oyunun bugünkü hâli incelenir ve eklenebilecekler planlanır. Her alan için: bugün ne var (dosya ve sınıf), eksik ne, öneriler (sütuna ve kurallara uygun), maliyet, öncelik; sonuç ayrı görevler olarak listeye girer.
    1. **Ölçüm (Measurement):** oyun hissinin ölçülmesi; tepki süreleri, yol ekranında olay yoğunluğu, kamp ve savaş süresi, simülatör çıktıları, Y-K03 ile bağ.
    2. **Renk teorisi (bonus: ışık, sis, son işlem):** `STIL_REHBERI.md` ve `ArtPalette` üstünden; saat ve hava ışığı, uzaklık sisi, mürekkep/kâğıt son işlemi (Y-G02 NPR ile bağ).
    3. **Tepkili ses (Reactive Sound):** her oyuncu eylemine ve oyun olayına karşılık gelen ses (vuruş, para, ateş, kart, adım), çeşitleme (`AudioStreamRandomizer`), ses otobüsleri; mevcut `AudioManager`.
    4. **Tepkili animasyon (Reactive Animation):** düğme geri bildirimi (`ButtonFeedback`), savaş sarsıntısı ve düşüş (`CombatFx`), figür tepki klipleri, rüzgârda eğilme; eksikler (yol olaylarına figür tepkisi, kervanın duruşu).
    5. **Tepkili parçacıklar (Reactive Particles):** kıvılcım, toz, kül, durum efektleri (`StatusFx`); yol tozunun tempoya bağlanması, savaşta mürekkep sıçraması (Y-H05, Y-G06 ile bağ).
    6. **Müzik ve ortam (Music and Ambience):** kullanıcı kararları: ana menüde şarkı yok, müzik dili gerilimli; ortam katmanları (rüzgâr, ateş, yağmur, şehir uğultusu), duruma göre geçiş.
  - **Kabul:** `docs/design_notes/oyun_hissi_plani.md` (alan başına durum, eksik, öneri, maliyet, öncelik) ve listeye eklenen alt görevler.

- [ ] **N31a Ölçüm: beat kaydı ve boş dakika raporu** (`C`) - oyuncu testinde her karar ve bilgi anı gerçek saniyeyle; playtest_report boş dakikaları, savaş ve kamp sürelerini yazar. (M, P1) Ayrıntı: `docs/design_notes/oyun_hissi_plani.md` §1.
- [ ] **N31b Işık modeli ve sis şeridi koda** (`CO`) - 12.2e taslağı onaylanınca TravelBand gök, hale, evre derecelendirmesi, sis şeridi. (M, P1) §2.
- [ ] **N31c Ses otobüsleri, çeşitleme, ayar kaydırıcıları** (`C`) - müzik/ortam/efekt/arayüz otobüsleri, AudioStreamRandomizer, Ayarlar'da dört kaydırıcı. (M, P1) §3.
- [ ] **N31d Figür tepkileri: bakma ve yorgun bekleyiş** (`CO`) - look ve idle_tired klipleri, sinyalde en yakın figür bakar. (M, P2) §4.
- [ ] **N31e Tempoya bağlı toz, çamur ve kar** (`C`) - toz yoğunluğu yürüyüş hızıyla, yağmurda tekerlek çamuru. (S, P2) §5.
- [ ] **N31f Durum tablolu ortam sesi ve savaş müziği** (`CO`) - hava × saat × yer ortam tablosu, savaşta müzik kısılır. (M, P1) §6.

- [ ] **N33 Yerleşim menülerinin gün evresi varyantları: sabah, gündüz, akşam, gece** (`CO`)
  - **Sütun:** Yol yaşar
  - **Kullanıcı isteği (2026-10-19):** Şehir, kasaba ve kervansaray menülerinin sabah, gündüz, akşam ve gece varyantları oluşturulsun. Akşama düşünme ve geliştirme görevi.
  - **Bugün:** Her yerleşimin tek bir (gece) resmi var (`data/assets/ui/towns/<yer>/background.jpg`, `mask.png`); 9.3 taslağı aynı resimden alacakaranlık, gece, gri ve kriz türetti (`referans/taslaklar/y_93_sehir_varyant_vastrevar.png`). Resim zaten gece olduğu için gündüz ve sabah türetilemiyor: gök ve ışık yeniden render edilmeli.
  - **Düşünülecek:**
    1. Dört evre için render mi (`town_scene.py` gök ve güneş/ay ışığı evreye göre, `settlement_towns.py`'ye `phase` alanı) yoksa türetme mi? Öneri: gök ve ışık render'da, kriz ve gri türetme.
    2. Üç yerleşim türü (şehir, kasaba, kervansaray) için farklı ışık dili: kervansarayda avlu ateşi, kasabada çit önü fener, şehirde pencere ışıkları. Pencere ışığı yalnız akşam ve gecede.
    3. Saat nereden okunur: `GameSession.last_clock_hour` (yol saati şehre taşınıyor, Motion Rules) ve `TravelBand.sky_for_hour`; şehirde bekleyince saat nasıl ilerler (konaklama, N34).
    4. Dosya boyutu: 27 yer × 4 evre × (resim + maske) ve LFS kararı (6.1). Maske evreler arası ortak kalır (aynı kamera).
    5. Kriz ve gri ile çarpışma (9.3, Y-G10T): evre × durum matrisi nasıl sadeleşir.
  - **Kabul:** Tasarım notu (render mi türetme mi, boyut hesabı) ve 3 yerleşim türünden birer örnek, dört evrede; kullanıcı onayından sonra 27 yer.
  - **Bağlı:** 9.3, 12.1 (geniş kadraj önce), Y-G10T, N34.
- [ ] **N34 Konaklama, mini oyun ve sohbetle öğrenilen bilgi: yerleşimde kalmak** (`CO`)
  - **Sütun:** İnsanlar aşınır · Defter unutmaz · Ticaret bilgi oyunudur
  - **Kullanıcı isteği (2026-10-19):** Şehirde, kasabada, kervansarayda konaklama ve mini oyun sunan, NPC sohbeti katan bir sistem için fikirler düşünülsün ve geliştirilsin. **Tavernadan doğrudan dedikodu satın alınmasın; bilgi konuşarak, sohbet ederek edinilsin.**
  - **Bugün:** Taverna söylentiyi parayla satıyor (`GameSession.buy_price_rumor`, Y-C10: komşu şehrin fiyatları, dörtte biri yalan); ziyafet (`throw_feast`, günde bir); `PurificationPanel`; yoldaş sohbeti yolda (`RoadChatter`, Y-B01) ve kamp hikâyeleri (`CampStory`, Y-C17); adlı kişiler Y-C13 ve hafıza N32 henüz yok.
  - **Düşünülecek fikirler:**
    1. **Sohbet bilgi kapısıdır, satın alma değil.** Taverna "Söylenti" düğmesi kalkar; yerine tezgâhta oturup sohbet: NPC'nin ilgisi (rapport, `CharacterData.rapport` mantığı) ve karşılıklı tercih (ona bir içki, bir haber, bir iyilik) bilgiyi açar. Bilgi parça parça gelir ve yalan olabilir (Y-C10'un yalan oranı korunur); doğrulamak için yolda bakmak gerekir.
    2. **Sohbet yapısı:** konu seçenekleri (yol, fiyat, kişi, borç, söylenti), NPC'nin huyu ve kültürü ne söyleyeceğini ve ne saklayacağını belirler; aynı NPC her ziyarette hatırlar (Y-C13 adlı kişiler, N32 hafıza). `EventEffect` sözlüğüyle konuşur; yeni sistem icat etmez.
    3. **Konaklama:** kalmak bir karar (zaman, kese, erzak): oda ya da avlu yeri, bir ya da birkaç gece; stres iner (`CAMP_STRESS_RELIEF`'ten büyük ama paralı), saat ilerler (N33 evreleri), geceleyin NPC'ler değişir (gündüz tüccar, gece yolcu ve kaçakçı). Kervansarayda avlu, kasabada han, şehirde pansiyon: üç tür farklı fiyat ve risk (hırsızlık, dedikodu). Kervanın kendisi şehir dışında kalır (Y-G10T kararı).
    4. **Mini oyun adayları** (hepsi mevcut kollara bağlı, zar gibi mekanik küçük): zar/kemik oyunu (kese riski, Karizma), kart/taş oyunu (Zeka, bilgi kazanma), içki yarışı (Dayanıklılık, bilgi karşılığı), el falı ya da hikâye yarışı (kültürel; dinî sembolsüz), arm wrestling (Güç, itibar). Her biri 30-60 sn, kaybı küçük ve bilgi/itibar/stres kazandırır; gerçek para kumarı değil.
    5. **Sabah-gün-akşam-gece ile bağ (N33):** sohbet ve mini oyun saate bağlı: gündüz pazar ve lonca, akşam han ve oyun, gece sır ve kaçakçılık.
    6. **Dedikodu nereden gelir:** NPC'nin bildiği = dünya durumu (`WorldEvents`, fiyat şokları, rota durumu, defter); ne kadarını söyleyeceği güven ve ilgiye bağlı. Böylece Y-C10 fiyat söylentisi ve yol haberi aynı kapıdan geçer.
  - **Riskler:** metin üretimi çok (NPC başına konu × güven kademesi): Y-E06 lore kapanmadan içerik yazılmaz; önce sistem iskeleti ve 2-3 örnek NPC. Mini oyunlar ekran ve test yükü getirir: önce ikisi (zar, taş oyunu).
  - **Kabul:** Tasarım notu (sohbet modeli, konaklama kuralları, mini oyun listesi ve bedelleri, taverna söylentisinin yeni biçimi) kullanıcı onayına; onaydan sonra iskelet: bir yerleşimde sohbetle bilgi alma, bir gece konaklama, bir mini oyun; kayıt ve yükleme testi.
  - **Bağlı:** Y-C10, Y-C13, Y-C17, Y-B01, N32, N33, Y-E06 (içerik).

- [ ] **N32 Nemesis benzeri NPC hafıza sistemi: tasarım** (`CK`)
  - **Sütun:** Defter unutmaz · Yol yaşar
  - **Ne:** Shadow of Mordor/War'un Nemesis sisteminden esinle, yolda karşılaşılan kişilerin (eşkıya reisi, muhafız çavuşu, tüccar, yoldaş adayı) oyuncuyu hatırlaması: kaçan ya da yenilen düşman adıyla, yarasıyla ve kinle geri döner; terfi eder, çetesi büyür; kurtarılan ya da kandırılan kişi sonra iyilikle ya da intikamla karşına çıkar. Sistem olarak mı, hikâye kurgusu olarak mı (ya da ikisi) yapılacağı kullanıcı kararı.
  - Mevcut zemin: `CaravanLedger` (dünyanın hafızası), `NpcDisposition` ve `ROLL_ENCOUNTER`, gecikmeli zincir olaylar (`evt_wanderer_revenge`), `EnemyCatalog` yöre reskin'leri, şikâyetler (grievances). Kural: yeni sistem icat etmez, olay sözlüğüyle (`EventEffect`) konuşur; adlı NPC'ler kayıtta tutulur, yeniden yüklemeyle değişmez.
  - **Kabul:** `docs/design_notes/nemesis_npc_plani.md` (seçenekler, lore'a bağımlılık, maliyet) ve kullanıcı kararından sonra alt görevler. Lore'a bağlı (Lore önce kuralı).

### P18 · Yol kontrol paneli

Yol ekranının altındaki çimen şeridi yerine **sekmeli kontrol paneli**.

**Yerleşim (kullanıcı kararı, işaretli ekran görüntüsüyle, 2026-10-18):** Sahnenin üstündeki boş gökyüzü şeridi (üst çubuğun hemen altındaki, yalnızca gökyüzü ve sağ üstte gösterge plakası olan bölge, ekran yüksekliğinin ~%19'u) **kaldırılır**. Yol sahnesi (dağlar, ağaçlar, kervan, yol) olduğu gibi kalır ama bu kadar **yukarı kayar**; böylece altta açılan alan (kaldırılan şerit + bugünkü alt çim şeridi, toplam ~%30) kontrol paneline gider. Sağ üstteki gösterge plakası (moral, stres, tehlike, takat) panele taşınır (Durum sekmesi); sahnede gökyüzü kırpıldığı için dağ ve güneş kesilmemeli (kırpma ufuk çizgisinin üstünde, güneş/ay yayı yeni üst kenara göre yeniden yerleşir).

Panel her zaman açık, kapatılmaz; yer açmak için sekme çubuğu küçültülebilir. Estetik: paneli çerçeveleyen ortak çerçeve ve arka plan, yol sahnesinin mürekkep ve karanlık arayüz diline uyar (stil rehberi N11); örnek ekran (N16) bunu da gösterir.

```
┌──────────────────────── yol (kervan, manzara) ────────────────────────┐
│                                                                       │
├───────────────────────────────────────────────────────────────────────┤
│ [Kadro] [Durum] [Yük] [Harita] [Defter]            tempo ▸ ▸▸ ▸▸▸  ⛺ │
├───────────────────────────────────────────────────────────────────────┤
│ sekme içeriği                                                         │
└───────────────────────────────────────────────────────────────────────┘
```

| Sekme | İçerik |
|---|---|
| **Kadro** | Portre kartları: ad, görev ikonu, can çubuğu, stres, açlık rozeti, durum rozetleri (yaralı, hasta, kırık). Tıkla → karakter ekranı. Lider işaretli. Kadro dışı tayfa tek satır. |
| **Durum** | Göstergeler (moral, stres, takat, tehlike) ve **sayılar**; erzak (kaç gün yeter), hava, arazi, tempo, kervan hızı (vagonların en yavaşı), borç, saat ve gün. Sorunlar kelimeyle ("iki kişi aç", "tekerlek gıcırdıyor"). |
| **Yük** | Vagon başına yük ve kapasite, erzak, taşınan kontratlar (hedef, kalan gün, ödül). |
| **Harita** | Küçük harita (karo katmanı), atlı kervan, hedef ve kalan gün, rota ve yol durumu. |
| **Defter** | Son olaylar günlüğü, açık yol işaretleri ve ihmal sayaçları, emirler (tempo, sofra politikası, akşam kampı). |

Kurallar: sayı gösterge yanında kalır (sayısal şeffaflık); stres ekran efektiyle değil davranış ve kelimeyle gösterilir (Y-D06); her kısayolun ekranda düğmesi vardır (dokunmatik denklik); sekme içeriği yalnızca okur, karar vermez, kararlar mevcut emir ve kart panelleridir.

- [x] **N16 Tasarım ve örnek ekran** (`C`, ekran görüntüsü gösterilir)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Gökyüzü şeridi kalktı, panel altta.
  - Sekmelerin yerleşimi, yazı boyutları ve renkler; önce **statik örnek ekran** (gerçek veriyle ekran görüntüsü), onay sonra kodlama.
- [x] **N17 Panel iskeleti** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): RoadControlPanel, beş sekme.
  - Üstteki boş gökyüzü şeridinin kaldırılması: `TravelBand` ve `TravelForeground` yüksekliği ve ufuk/zemin çizgisi bu kadar yukarı kayar, güneş/ay yayı ve ağaç hattı yeniden hesaplanır (oranlar `HORIZON_RATIO`, `BAND_HEIGHT`'a göre).
  - Altta alan açılır: sekme çubuğu ve sekme içeriği; bugünkü alt çim şeridi panelin arkasında kalır ya da kırpılır.
  - Farklı ekran boyutlarında (1280×720'den 2560×1440'a) sahne ve panel oranı bozulmaz; ekran görüntüleri onay için.
- [x] **N18 Kadro sekmesi** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Kişi kartları + kervanın nabzı (moral, takat, tehlike, erzak).
- [x] **N19 Durum sekmesi** (`C`, `SurvivalGauge` ince çubuk, 9.9 ile birlikte)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Göstergeler, sayılar, dertler kelimeyle.
- [x] **N20 Yük sekmesi** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Vagonlar, mallar, kontratlar.
- [x] **N21 Harita sekmesi** (`C`, N7'ye bağlı)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Küçük harita, Büyüt (M), Kervana git.
- [x] **N22 Defter ve emirler sekmesi** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Son olaylar ve kalıcı emirler.
  - Bugünkü sol-üst emir paneli ve Tab ile açılan `CaravanStatusPanel` buraya taşınır; ikisi tek kapıdan.
- [ ] **N23 Eski HUD parçalarını kaldır** (`C`)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `e967039`): Tab ile açılan CaravanStatusPanel kontrat listesini de gösterdiği için duruyor; panelin Yük sekmesine kontratlar taşınınca kalkar (karar senin).
  - Üst şerit ve yan göstergelerden panelde olanlar kalkar; yinelenen metin kalmaz; testler güncellenir.

## Bağlantılar

- 9.9 (yol HUD'u, K-02) → **N19, N22**; 12.2e (yol sahnesi) alt şerit boşluğuna bağlı.
- 8.1, 8.2 → **N7**; 8.3, 8.4 → **N2, N1**; Y-C01 → **N1–N5**; Y-G10T ve 12.2a → **N12–N13**.
- Y-G01 → **N11**; Y-E06 (lore) → **N13–N15**.
