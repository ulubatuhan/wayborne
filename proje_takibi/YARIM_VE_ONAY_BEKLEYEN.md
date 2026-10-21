# Yarım kalan ve onay bekleyenler

Benim payım bitmiş ama kullanıcı onayı (taslak, tasarım notu, plan), indirme izni, lore ya da dış test bekleyen görevler; bir de kısmen yapılmış olanlar. Her birinde ne yapıldığı ve ne kaldığı yazıyor.


### İndirme durumu (2026-10-19)

Kullanıcı izniyle (yalnız CC0) indirilenler: Kenney UI Pack RPG Expansion, Fantasy UI Borders, Graveyard Kit, Impact Sounds, Castle Kit ve Poly Haven Lantern 01 (`araclar/indirilenler/`, kopyaları `wayborne/art_source`). İndirilmeyenler: MPFB2 (GPL, CC0 değil: Y-G04, Y-G12) ve Freesound sesleri (giriş gerekli). Hepsi CC0 ya da OFL; boyutlar yaklaşık, indirmeden önce lisans sayfası ve gerçek boyut kontrol edilir.

| Kaynak | Ne için | Görev | Lisans | Yaklaşık boyut |
|---|---|---|---|---|
| Kenney UI Pack RPG Expansion | panel çerçevesi, başlık şeridi, düğme durumları (mürekkep diline boyanır) | 9.1 | CC0 | ~1 MB |
| Kenney Fantasy UI Borders | 140 çerçeve, seçim köşebentleri | 9.1 | CC0 | ~2 MB |
| Kenney Graveyard Kit | mezar taşı, çit, kripta (dini sembol çıkarılır) | 9.12 | CC0 | ~5 MB |
| Poly Haven `Lantern_01` | fener amblemi ve menü feneri | Y-G08 | CC0 | ~20 MB (2K doku) |
| MPFB2 (Blender eklentisi) + temel varlık paketi | büst portre render'ı (figür hattıyla) | Y-G04 | GPL eklenti, CC0 varlık | ~60 MB |
| Kenney Impact Sounds | vuruş sesi katmanları | Y-H05 | CC0 | ~2 MB |
| Freesound CC0: `sword clash`, `arrow impact`, `campfire`, `large wooden door`, `chain rattle`, `winch` | vuruş, menü ateşi, şehir kapısı sesi | Y-H05, Y-G16, 12.2a | CC0 | ~10 MB; Freesound giriş istiyor, sen indirmelisin |
| Kenney Castle Kit (tam) | kapı sahnesinde alternatif sur ve kule | 12.2a (isteğe bağlı) | CC0 | ~10 MB |
| Y-H02 İlk 10 dakikanın çizelgesi | Hedefler 3/10/30 dk ve ilk on dakikanın akışı. Soru: ilk seferde ilk tehdidi yönetmen öne çeksin mi? | test sonrası | ☐ |
| Y-G13 Kimliği tanımlayan beş ana görsel (taslak) | 1 gece haritası ve fenerli atlı, 2 kamp ateşi, 3 tam ekran olay kartı, 4 defter ve kırık mühür, 5 kapıya varış. Soru: beşinin sırası mağazada bu mu (ilk ikisi yol ve olay kartı istenmişti)? | test sonrası | ☐ |
| Y-J04 Demo ve Next Fest planı | Fest boyunca demo (Şubat 2027), EA festten 4-10 hafta sonra; demo iki bölge 2-3 sefer. Kullanıcının festte EA fikri kurala takılıyor. Soru: kabul mü? | test sonrası | ☐ |

### Karar soruları (CK ve CI, ayrıntısı KALAN_ISLER.md)

Bu işleri toplu çalışmada yapmadım: ya senin kararın (CK) ya da lore ve içerik kararın (CI) gerekiyor. Her biri için
tek soru; cevabın gelince sırayla yapılır.

| Görev | Soru |
|---|---|
| 6.1 LFS ve `.gitattributes` | Büyük ikili dosyalar (atlas sayfaları, kasaba resimleri) Git LFS'e taşınsın mı? GitHub LFS kotası ücretli olabilir. |
| 2.1 Dışa aktarımdan test ve araçlar | `tests/` ve `tools/` dışa aktarımdan çıkarılsın mı (Web/PC derlemesi küçülür)? |
| Y-K03 Oyun ölçümü | Oyuncu testinde anonim süre verisi (Y-H02 dosyası) sana gönderilsin mi, yoksa yalnız yerelde mi kalsın? |
| 3.6, 3.4, 2.3 Ölü araç ve varlıklar | Kalan eski araç ve varlıklar arşive mi (`docs/history`), silinsin mi? |
| 4.4 Olay anahtarları | `event_catalog.gd`'de `"%s_TITLE"` ile kurulan anahtarlar kasıtlı bir istisna mı, yoksa açık yazılsın mı? |
| 2.5 Yıpranma efekti | Stres kenarı kaldırıldı, açlık kenarı kaldı (senin kararın). Açlık kenarı da kalksın mı? |
| 5.2, 5.4 Mipmap ve atlas paketleme | Doku ayarlarını içe aktarma tarafına almak ve atlasları sıkı paketlemek resimleri yeniden üretmek demek; şimdi mi, demo öncesi mi? |
| 8.7 Boğazın adı | Haritada geçici "Kesgrav Boğazı" yazıyor. Ne ad olsun? |
| Y-G03 Saç ve başlıklar | Saç modülleri (MPFB) indirme izni ve hangi saç stilleri? |
| Y-C12 Bölgesel itibar ve hizipler | Kaç hizip, hangileri (lore)? Bölge başına itibar mı, hizip başına mı? |
| Y-C13 Adı olan kişiler | Her şehirde 2-3 kişi: lonca ustası, tefeci, han sahibi. Adları ve kişilikleri sen mi yazarsın, ben taslak mı çıkarayım? |
| Y-B08 Günün satırı | Her akşam günün olayı deftere tek cümle. Oyuncu satırı düzeltebilsin mi (metin girişi)? |
| R3 Merak ve töre | Kervan töresi, anlatıcı ("yolun ruhu"), belirsiz işaretler, yol notları, tepeye çıkma: hangileri? |
| R5 Büyük sahneler | Kervan mahkemesi, sancak, yol şarkısı, çatallar: hangileri, hangi sırayla? |
| Y-C06 Ekipman 35+ parça | Yeni parçaların adları ve kültür dağılımı (lore) senden mi? |
| Y-C09 Bölgesel düşman kimlikleri | Bölge başına hangi düşmanlar (lore)? |
| Y-D04 Varis devralma sahnesi ve video | Sahnenin kurgusu: kısa sinematik mi, defter sayfası mı? |
| Y-E04 Yavaş açılan dünya sırrı | Sır ne (lore)? |
| Y-E08 Takvim | Şehirlerin bayram ve fuarları (lore); hac dönemi dinî sembolsüz nasıl anlatılsın? |
| Y-C18 Kampanya bölümleri | Bölüm metinleri sen mi yazarsın, taslak mı? |
| Y-I01, Y-I02, Y-I03 Ses, müzik, kâtip sesi | AI ses kullanılacak (Y-I03 cevabın). Hangi araç ve bütçe? Müzik dili için örnek parça? |
| Y-J03, Y-J12 Fragman ve basın kiti | Aralık'ta (senin notun); kliplenebilir anlar listesi hazır (Y-J09). |
| N32 Nemesis benzeri NPC hafızası | Sistem mi (adlı düşmanlar terfi eder, geri döner), hikâye kurgusu mu, ikisi mi? Uzun zincir altyapısı (Y-E02) buna zemin. |



Toplam: **28** görev. Belgeler `referans/belge_uret.py` ile `referans/gorevler.json`'dan üretilir.

## Paket P01

### 6.1 · LFS ve `.gitattributes` ekle

- **Durum:** kısmen · **Öncelik:** P2 · **Paket:** P01 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/06_depo_hijyeni.md](referans/gorevler/06_depo_hijyeni.md)
- **Son not:** .gitattributes eklendi (metin dosyaları LF, ikililer binary). Bu makinedeki core.autocrlf=true yüzünden CRLF'ye dönen iki spec JSON'u iki testi kırıyordu; artık geçiyor. LFS taşıması (`git lfs migrate`, geçmişi yeniden yazar) kullanıcı onayı bekliyor, yapılmadı. git-lfs 3.7.1 kurulu. | 2026-10-20 kullanıcı kararı: LFS taşıması (git lfs migrate, geçmiş yeniden yazılır) ONAYLANDI. | 2026-10-20 güncelleme: push yok, geçmiş yeniden yazılmayacak; kullanıcı dosyaları yeni bir dala kendisi alacak. Yalnızca .gitattributes LFS kuralları. | 2026-10-20: .gitattributes LFS kuralları (png, jpg, ogg, wav, mp3, glb, blend, npz, pdf, ttf, otf). Geçmiş yeniden yazılmadı (kullanıcı kararı). Yeni dalda: git lfs install && git add --renormalize . | 2026-10-20 (son): geniş LFS kuralları denendi ve GERİ ALINDI: geçmiş düz blob, klonda pointer uyarısı; taşınırsa ~500 MB LFS ve CI her koşuda indirir (ücretsiz aylık 1 GB kota). En büyük dosya 2,2 MB, 100 MB sınırı sorun değil. Yalnız harita karoları LFS. Karar kullanıcıda.

<details><summary>Görev metni</summary>

- [ ] **6.1 LFS ve `.gitattributes` ekle** (§5 H-1, H-9)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `32f9ac4`): .gitattributes eklendi (metin dosyaları LF, ikililer binary). Bu makinedeki core.autocrlf=true yüzünden CRLF'ye dönen iki spec JSON'u iki testi kırıyordu; artık geçiyor. LFS taşıması (`git lfs migrate`, geçmişi yeniden yazar) kullanıcı onayı bekliyor, yapılmadı. git-lfs 3.7.1 kurulu.
  - İkili dosyalar LFS'e gitsin.
  - Metin dosyaları için `eol=lf` tanımla (Windows'tan yapılacak commitler için gerekli).
  - Geçmişi yeniden yazmak (`git lfs migrate`) **kullanıcı onayı** ister (§7 madde 11).

</details>

## Paket P02

### 2.3 · Ölü `CityView` sınıfını ve bağlı varlıklarını kaldır

- **Durum:** kısmen · **Öncelik:** P1 · **Paket:** P02 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/02_yuksek_etkili.md](referans/gorevler/02_yuksek_etkili.md)
- **Bağımlı:** 7
- **Son not:** city_view.gd (983 satır) ve screenshot_city.gd silindi; yorum başvuruları CityFront/TravelBand'e çevrildi. Kanıt: şehir CityFront'a geçti (REDESIGN §7.2), kullanıcı önden görünüm istiyor, izometrik dönüş planı yok. DENETİM YANILMIŞ: iso_* eşyaları ölü değil, tools/ui_scenes/ui_kit.py şehir madalyonlarını iso_stable, iso_market_stand_1, iso_house_2, iso_inn, iso_bell_tower'dan üretiyor; 10 iso_* eşyası ve test_props.gd beklentileri tutuldu. Kullanıcı onayı hâlâ açık: istenmezse commit geri alınabilir. CLAUDE.md Art Rules'taki CityView maddeleri 4.2'de.

<details><summary>Görev metni</summary>

- [ ] **2.3 Ölü `CityView` sınıfını ve bağlı varlıklarını kaldır** (§1A, §1E)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `b756a52`): city_view.gd (983 satır) ve screenshot_city.gd silindi; yorum başvuruları CityFront/TravelBand'e çevrildi. Kanıt: şehir CityFront'a geçti (REDESIGN §7.2), kullanıcı önden görünüm istiyor, izometrik dönüş planı yok. DENETİM YANILMIŞ: iso_* eşyaları ölü değil, tools/ui_scenes/ui_kit.py şehir madalyonlarını iso_stable, iso_market_stand_1, iso_house_2, iso_inn, iso_bell_tower'dan üretiyor; 10 iso_* eşyası ve test_props.gd beklentileri tutuldu. Kullanıcı onayı hâlâ açık: istenmezse commit geri alınabilir. CLAUDE.md Art Rules'taki CityView maddeleri 4.2'de.
  - Dosyalar: `scripts/ui/city_view.gd`, `tests/screenshot_city.gd`, 10 adet `iso_*` eşya, `b10_city.jpg`.
  - İlişkili listeler: `tests/test_props.gd:18-20`, `props.json` girdileri, `tools/waybook_assets.py` ve `waybook_ingest_v2.py`.
  - Bayat yorumlar: §3A'daki 4 CityView yorumu.
  - CLAUDE.md Art Rules'taki CityView maddeleri.
  - **Önce doğrula** (§7 madde 6): izometrik şehre dönüş planı yok mu?

</details>

## Paket P10

### Y-D05 · Hafif meta ilerleme: güç değil çeşitlilik

- **Durum:** beklemede · **Öncelik:** P2 · **Paket:** P10 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-D03
- **Son not:** Açılımlar user://lineage_archive.json içinde. | 2026-10-19 karar: beklet: üstüne düşünülecek.

<details><summary>Görev metni</summary>

- [ ] **Y-D05 Hafif meta ilerleme: güç değil çeşitlilik**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `0428df4`): Açılımlar user://lineage_archive.json içinde.
  - **Öncelik:** P2 · **Dalga:** 4 · **Bağımlı:** Y-D03
  - **Ne:** Soy defterinde kuşak başarıları; yeni başlangıç kökenleri, kurucu huyları ve hikâye başlangıçları açılır. Güç veren açılım yok.
  - **Kabul:** En az 5 açılabilir başlangıç; açılımlar meta kayıtta.
  - **Literatür:** R9, R54

</details>

## Paket P11

### Y-E01 · Olay havuzunu 46'dan 120'nin üstüne çıkar

- **Durum:** sistem yapıldı, içerik lore bekliyor · **Öncelik:** P1 · **Paket:** P11 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06, Y-C01
- **Son not:** Kart yazımı lore sonrası 10luk partilerle; düzen docs/design_notes/olay_uretim_duzeni.md.

<details><summary>Görev metni</summary>

- [ ] **Y-E01 Olay havuzunu 46'dan 120'nin üstüne çıkar**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `cbe2b02`): Kart yazımı lore sonrası 10luk partilerle; düzen docs/design_notes/olay_uretim_duzeni.md.
  - **Öncelik:** P1 · **Dalga:** 5 · **Bağımlı:** Y-E06, Y-C01
  - **Ne:** Bölge başına 6–10 kart, yoldaş kartları, zincirler. Her kart oyuncunun kararını değiştirecek kadar farklı olmalı. Üretim düzeni için “Kullanıcının sorularına cevaplar” bölümüne bak.
  - **Kullanıcı notu:** “Sayıyı arttır demek kolay ama arttırabilecek misin?”
  - **Kabul:** En az 120 çekilebilir kart; her kart kalite listesinden geçti; simülatörde finale kadar tekrar oranı ölçüldü.
  - **Literatür:** R15, R48

</details>

### Y-E02 · Uzun zincirler: karşılık başka şehirde ya da sonraki kuşakta

- **Durum:** sistem yapıldı, içerik lore bekliyor · **Öncelik:** P1 · **Paket:** P11 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06
- **Son not:** 10 zincirin içeriği Y-E06 (lore) kapanınca yazılacak.

<details><summary>Görev metni</summary>

- [ ] **Y-E02 Uzun zincirler: karşılık başka şehirde ya da sonraki kuşakta**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `3069762`): 10 zincirin içeriği Y-E06 (lore) kapanınca yazılacak.
  - **Öncelik:** P1 · **Dalga:** 5 · **Bağımlı:** Y-E06
  - **Ne:** En az 10 çok seferli zincir; sonucu başka bir şehirde ya da varisin döneminde gelir.
  - **Kabul:** 10 zincir; kayıtta zincir durumu; testler.
  - **Literatür:** R24, R48

</details>

### Y-A07 · Zindanlar: tam sürüm

- **Durum:** lore bekliyor · **Öncelik:** P2 · **Paket:** P11 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06, Y-C01
- **Son not:** docs/design_notes/zindanlar.md; uygulama onay ve lore sonrası. | 2026-10-19 karar: beklet: lore beklenecek.

<details><summary>Görev metni</summary>

- [ ] **Y-A07 Zindanlar: tam sürüm**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b76bb93`): docs/design_notes/zindanlar.md; uygulama onay ve lore sonrası.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-E06, Y-C01
  - **Ne:** Rota dışı zindan, hazine ve mistik yaratık (Temmuz pitch'inin çekirdeği) tam sürüm olarak tasarlanır ve uygulanır; küçük ara sürüm yok. Önce tasarım notu: giriş (haritada yer, söylenti, olay), yapı (oda ya da aşama dizisi), savaş, ganimet, kayıp ve stres kuralları, kervanın zindan dışında beklemesi. Tasarım notu kullanıcı onayından sonra uygulanır.
  - **Neden:** Zindanlar konuşmalarda hiç ele alınmadı; keşif ve ganimet açığını kapatır.
  - **Kullanıcı notu:** “Sıra zindanlara gelecek fakat bende küçük sürüm diye bir şey yok, tam gaz devam. Solo indie olduğum için istediğim gibi ilerleyebiliyorum ve claude, gemini, google ai sayesinde fazlasıyla da hızlı ilerliyor çalışmalar.”
  - **Kabul:** Onaylı tasarım notu; haritadaki en az bir bölgede oynanabilir zindan; kayıt ve yükleme testi.
  - **Kaynaklar ve teknik (CC0 araştırması):** Yapılar: Quaternius Ultimate Modular Ruins ve Modular Dungeon (yeni indirme QAL), Kenney Castle Kit (CC0). Ses: OpenGameArt “Loopable Dungeon Ambience”, “Dripping water loop” (indirmeden önce lisans sayfası kontrol edilir).
  - **Literatür:** R9

</details>

## Paket P12

### 9.1 · Ortak UI kiti v2

- **Durum:** onaylandı, uygulanacak · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Kenney UI Pack RPG Expansion + Fantasy UI Borders (CC0) indirildi; tools/ui_kit_ink.py ile mürekkep ve palet renklerine boyandı (build/ui_kit); önizleme referans/taslaklar/y_91_ui_kit.png. Seçim köşebendinin ortası dolu çıktı. Onaydan sonra temaya bağlanır. | 2026-10-19 karar: beklet: kit, önceki düzeltmelerle birlikte ilgili sahnelerde örnekle gösterilecek. | 2026-10-20 kullanıcı kararı: köşebentler kaldırıldı (select_corner kitten ve örneklerden çıktı). | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş).

<details><summary>Görev metni</summary>

- [ ] **9.1 Ortak UI kiti v2** (K-01, K-03, T-02…T-12)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kenney UI Pack RPG Expansion + Fantasy UI Borders (CC0) indirilince kâğıt-mürekkep diline boyanır; Y-G11T ve 9.4-9.9 taslaklarındaki ince çerçeve ve kehribar vurgu bu kitin hedefi.
  - 9-slice panel çerçevesi, başlık şeridi, kırmızı ana eylem düğmesi (tüm durumlarıyla), tooltip plakası, seçim köşebentleri.
  - **Kaynak (CC0, 2026-10-17):** Kenney UI Pack RPG Expansion (85 dosya) ve Kenney Fantasy UI Borders (140 çerçeve), ikisi de CC0. Çerçeveler kâğıt ve mürekkep diline yeniden boyanır (stil rehberi Y-G01); kullanıcının reddettiği çizik, deri ve nine-slice süs dili kullanılmaz (25–27 Eylül kararları). Süsleme ve vinyet için Old Book Illustrations “Ornaments” görselleri (görseller serbest, açıklama metinleri NC, kopyalanmaz). Ayrıntı: `../ICERIK_IHTIYACLARI.md` G-7.

</details>

### Y-G11T · Masa ekranı şablonunu görsel taslakla göster

- **Durum:** onaylandı, uygulanacak · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Oyunun kendi resim, yazı yüzü ve paletiyle; uygulama kararı taslaktan sonra 9.1e işlenir. | 2026-10-19: terazi oyunda (9.5 notuna bakın); masa şablonu onayı sürüyor. | 2026-10-19 karar: terazi tamamen referans görseldeki gibi (Gemini içeriği; kırpılabilir ya da başka yöntem). Terazi durumları (denge/mal ağır/altın ağır) onaylandı. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş).

<details><summary>Görev metni</summary>

- [ ] **Y-G11T Masa ekranı şablonunu görsel taslakla göster**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Oyunun kendi resim, yazı yüzü ve paletiyle; uygulama kararı taslaktan sonra 9.1e işlenir.
  - **Öncelik:** P2 · **Dalga:** 6 · **İlgili:** 9.1, 9.5
  - **Köken:** onaylanmayan **G11** önerisinin altındaki kullanıcı notu.
  - **Ne:** Kullanıcı notundan türetildi: “bunu görmem lazım, yazıyla anlaşılmıyor.” Sol liste, ortada metafor nesnesi, sağda kervan düzeni pazar ekranı üzerinde görsel taslak olarak hazırlanıp sunulur. Uygulama kararı taslaktan sonra.
  - **Kullanıcı notu:** “bunu görmem lazım, yazıyla anlaşılmıyor.”
  - **Kabul:** Taslak kare kullanıcıya sunuldu; karar 9.1'e işlendi.

</details>

### 12.2 · Yol görünümü: büyük revizyon (overhaul)

- **Durum:** onaylandı, uygulanacak · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** 12.2a, 12.2e, 9.9, 9.10 bu notta sıralı. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş).

<details><summary>Görev metni</summary>

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

</details>

### 9.10 · Yol arka planları, biyom başına

- **Durum:** onaylandı, uygulanacak · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Y-G07 biyom şeritleri hazır; sis şeridi ve gece varyantı taslakta, enkaz (Broken Cart) 12.2 sırasının 5. adımı. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş).

<details><summary>Görev metni</summary>

- [ ] **9.10 Yol arka planları, biyom başına** (A-03, A-05, A-07, A-09, A-10, A-12, A-20, A-24 …)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `2dd895a`): Y-G07 biyom şeritleri hazır; sis şeridi ve gece varyantı taslakta, enkaz (Broken Cart) 12.2 sırasının 5. adımı.
  - Katmanlar: soğuk uzak katman, sıcak ön plan, döşenebilir orta katman, sis şeridi.
  - Kervan enkazı eşyası.
  - Gece varyantı.
  - **Kullanıcı kararı ve kaynaklar:** Bu iş **Y-G07** ile birlikte yapılır (bütün biyomlar, haritadaki konuma göre varyantlar). Dokular Poly Haven ve ambientCG (CC0), nesneler Kenney Survival Kit ve Quaternius (yeni indirmeler QAL), enkaz Quaternius `Broken Cart`. Ayrıntı: `../ICERIK_IHTIYACLARI.md` G-2, G-4.

</details>

### Y-G10T · Şehir ekranı: insanlar ve şehir görünsün

- **Durum:** değişiklik istendi · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Oyunun gövde ve giysi kareleriyle meydanda halk; kervan yok. Uygulamada kalabalık ayrı katman: town_scene içinde sahne ışığı ve örtmeyle render, saatle yoğunluk (gece az, pazar günü çok), krizde (9.3) azalır ve yüzler değişir. | 2026-10-19 karar: insanların ışığı ortama aykırı; gece/akşam çok daha az insan; herkes yürüyor, sahne kurgulanmalı (duran, konuşan, satan).

<details><summary>Görev metni</summary>

- [ ] **Y-G10T Şehir ekranı: insanlar ve şehir görünsün**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Oyunun gövde ve giysi kareleriyle meydanda halk; kervan yok. Uygulamada kalabalık ayrı katman: town_scene içinde sahne ışığı ve örtmeyle render, saatle yoğunluk (gece az, pazar günü çok), krizde (9.3) azalır ve yüzler değişir.
  - **Öncelik:** P1 · **Dalga:** 6 · **İlgili:** 12.1, 12.2a, 9.3
  - **Köken:** onaylanmayan **G10** önerisinin altındaki kullanıcı notu.
  - **Ne:** Kullanıcı notundan türetildi (kervan merkezli şehir önerisi reddedildi): şehir menüsü iyileştirilir, insanlar ve şehir görünür. Savaşın ve kıtlığın içinde bu işi yapmanın motivasyonu halkların kendisidir; ekran bunu hissettirmeli. Kervan şehre girmez. 12.1 ve 12.2a ile birlikte; önce taslak kare onaya.
  - **Kullanıcı notu:** “Şehir menüsü iyileştirilebilir, evet başka oyuna çok benziyor fakat insanlar ve şehir gözükmeli. Bizim yolda olmamız büyük bir tehlike ve bu işin özünde şu durumda, savaşın ve kıtlığın içinde bu işi yapmamızın bir motivasyonu olmalı, o motivasyon ise halkların kendisi. ayrıca şehre kervan girmez.”
  - **Kabul:** Onaylı taslak; şehirde insanlar görünüyor; kervan şehir içinde gösterilmiyor.

</details>

### 9.5 · Pazar, erzak ve envanter

- **Durum:** değişiklik istendi · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19: oyunda uygulandı - pazar terazisi (MarketScale: mühür içinde mal ve sikke, sepet büyüdükçe parça sayısı artar, kol dengeye göre yaylı eğilir, düşen parça yerine oturur); ekran görüntüsüyle kontrol edildi, onay bekliyor. | 2026-10-19 karar: terazili tek ekran gereksiz; pazar Y-G11T masa ekranı olacak, terazi referans görseldeki gibi.

<details><summary>Görev metni</summary>

- [ ] **9.5 Pazar, erzak ve envanter** (T-12, T-08)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Üstte fiyatlı mal kartları, altta kervan envanteri.

</details>

### 9.8 · Savaş ekranı

- **Durum:** değişiklik istendi · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19 karar: savaş arka planı savaşın olduğu yere göre; karakterlerin altında stilize can barı, can sağ panelden izlenmemeli.

<details><summary>Görev metni</summary>

- [ ] **9.8 Savaş ekranı** (K-03…K-05)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Alt panel: solda aktif üye, sağda hedef kartı.
  - Tur madalyonu.
  - Kritik vuruşta renk değişimi ve yakınlaşma.
  - `g9_seal` ile uyumlu bir öldürücü darbe mührü.

</details>

### Y-G05 · Savaş ekranını yeniden kur

- **Durum:** onaylandı, uygulanacak · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Biyom plakası yolun kendi şeritlerinden; figürler ekranın %32si. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş).

<details><summary>Görev metni</summary>

- [ ] **Y-G05 Savaş ekranını yeniden kur**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Biyom plakası yolun kendi şeritlerinden; figürler ekranın %32si.
  - **Öncelik:** P1 · **Dalga:** 6 · **İlgili:** 9.8
  - **Ne:** Biyom başına mekân plakası, figürler ekran yüksekliğinin %30–35'i, kritikte kırmızı mühür. Kullanıcı notu: referans oyunun sahne ve menüleri bugün belgelendi; `belgeler/ART_IKINCI_TUR_REFERANSLARI.md` esas alınır.
  - **Kullanıcı notu:** “evet, bu yüzden referans oyun sahne ve menülerini dokümante ettik bugün seninle.”
  - **Kabul:** Yeni savaş ekranı ekran görüntüsüyle onaylandı.
  - **Kaynaklar ve teknik (CC0 araştırması):** Mekân plakaları Y-G07 katmanlarından. Hayvan düşmanlar: Quaternius Ultimate Animated Animal Pack (elde), OpenGameArt yaban domuzu (Teh_Bucket), kurt (NewDLC), geyik (crownjoshua), hepsi CC0. Yan profilden 8–12 karelik döngüler; siluette 2 px kontur. Vuruş sesi üç katman (Y-H05). `../ICERIK_IHTIYACLARI.md` G-3.
  - **Literatür:** R20, R21

</details>

### Y-G06 · Gravür efektleri; parlak efektleri kaldır

- **Durum:** beklemede · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G01
- **Son not:** Kaba bir yön taslağı: tarama ve mürekkep dili, parlak mor/mavi yok. Gerçek dokular onaydan sonra Krita + David Revoy 2023 CC0 fırçalarıyla; eski efekt onaylı karşılığı gelince kalkar. | 2026-10-19 karar: "hiç olmamış": baştan yapılacak. | 2026-10-20 kullanıcı kararı: gravür efektleri beğenilmedi, kaldırıldı; efektler şimdilik eksik kalsın. Taslak (gravur_efekt_taslak.py, y_g06_gravur_efektler.png) silindi; oyuna hiç girmemişti.

<details><summary>Görev metni</summary>

- [ ] **Y-G06 Gravür efektleri; parlak efektleri kaldır**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kaba bir yön taslağı: tarama ve mürekkep dili, parlak mor/mavi yok. Gerçek dokular onaydan sonra Krita + David Revoy 2023 CC0 fırçalarıyla; eski efekt onaylı karşılığı gelince kalkar.
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-G01
  - **Ne:** Kullanıcı notu: yerine ne konacağı çok önemli. Önce her efekt için (kan, duman, sis, kritik, büyü, yanma, donma, zehir) gravür karşılığının örnek karesi hazırlanır, onaydan sonra eskisi kaldırılır. 14 Ekim kararları korunur: yanan adam gerçekçi yanar, donma bölgesel buzlanma, zehir yeşil sis.
  - **Kullanıcı notu:** “yerine ne koyacağımız çok önemli ama”
  - **Kabul:** Her efektin onaylı örneği ve oyundaki karşılığı; parlak mor ve mavi efekt kalmadı.
  - **Kaynaklar ve teknik (CC0 araştırması):** Hazır CC0 mürekkep sıçrama dokusu yok: Krita'da David Revoy 2023 fırça kitiyle (CC0; 2025 kitinin lisansı çelişkili, kullanılmaz) kendimiz üretiriz. Kritik mührü özgün tasarım. Godot'ta `CPUParticles2D` + mürekkep dokuları. `../ICERIK_IHTIYACLARI.md` G-6.
  - **Literatür:** R20

</details>

### 9.9 · Yol HUD'u

- **Durum:** değişiklik istendi · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Alt panel (P18) zaten sekmeli: harita ve envanter orada. | 2026-10-19 karar: harita ve envanterle birlikte gösterilecek; sağ üstteki moral/stres/takat paneli kalkar, alt panele iner.

<details><summary>Görev metni</summary>

- [ ] **9.9 Yol HUD'u** (K-02; çatlak efekti kaldırılacak, bkz. §2.5)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Alt panel (P18) zaten sekmeli: harita ve envanter orada.
  - `SurvivalGauge` ince çubuk, amblem ve çentiklerle çizilecek.
  - Harita ve envanter sekmeli alt panel.
  - Bu iş §8 ile bağlantılı.

</details>

### 9.2 · Ana menü gece kampı, katmanlı

- **Durum:** onaylandı, uygulanacak · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Bağımlı:** 9.1
- **Son not:** Mor-lacivert gök ve tek ateş ışığı resmin kendisinden; duman ayrı katman; sağda arayüz için karanlık sade alan. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş).

<details><summary>Görev metni</summary>

- [ ] **9.2 Ana menü gece kampı, katmanlı** (A-25, A-19, A-10, A-17)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Mor-lacivert gök ve tek ateş ışığı resmin kendisinden; duman ayrı katman; sağda arayüz için karanlık sade alan.
  - Mor-lacivert gök ve tek ateş ışığı.
  - Duman ayrı katmanda.
  - Arayüze karanlık, sade bir alan bırakılacak.

</details>

### Y-G16 · Ana menü: kamp ateşi ve üç yorgun yolcu

- **Durum:** onaylandı, uygulanacak · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Figürler oyunun karelerinden, ride karesinin oturuşuyla; gerçek sürümde FigureActions a sit_tired (kambur, elleri ateşe) klibi yazılıp MPFB hattıyla render edilir. Menüde müzik yok, ateş ve gece ambiyansı. | 2026-10-19 karar: sağdaki iki figür oturuyor gibi değil: bağdaş kurmuş ya da sandık/kutu üstünde otursunlar. | 2026-10-20: taslak MPFB oturuş klibi (sit_box) ile yeniden: üç yolcu sandığın üstünde gerçekten oturuyor (kalça kapakta, uyluk yatay, ayaklar yerde), ateşe dönük. y_g16_menu_kamp.png. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş).

<details><summary>Görev metni</summary>

- [ ] **Y-G16 Ana menü: kamp ateşi ve üç yorgun yolcu**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Figürler oyunun karelerinden, ride karesinin oturuşuyla; gerçek sürümde FigureActions a sit_tired (kambur, elleri ateşe) klibi yazılıp MPFB hattıyla render edilir. Menüde müzik yok, ateş ve gece ambiyansı.
  - **Öncelik:** P2 · **Dalga:** 6 · **İlgili:** 9.2
  - **Ne:** Ana menü kamp ateşi panoramasından bir kare; fener ışığı kısılır. Kullanıcı notu: ateş başında oturan, yorgunluktan bitmiş ve ısınmaya çalışan üç kişilik kervan ekibi. Ana menüde şarkı yok (Y-I02).
  - **Kullanıcı notu:** “ana menüye kervan ekibi de katılmalı, ateş başında oturan, yorgunluktan ölmüş ve ısınmaya çalışan 3 kişi.”
  - **Kabul:** Yeni ana menü onaylı; üç figür ateş başında.
  - **Kaynaklar ve teknik (CC0 araştırması):** Ana menüde müzik yok: gece ormanı ve ateş çıtırtısı ambiyansı (Freesound CC0 `campfire`, `forest night`), yaklaşık −22 LUFS. `../ICERIK_IHTIYACLARI.md` S-1.

</details>

### Y-G08 · Fener, oyunun görsel motifi

- **Durum:** kısmen · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Emblem oyunda (ana menü başlığı). Menünün ışık kaynağı yalnızca taslakta (Y-G16), oyunda değil: beş yerin dördü.

<details><summary>Görev metni</summary>

- [ ] **Y-G08 Fener, oyunun görsel motifi**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `3784072`): Beş yerden üçü var, biri taslakta (menü), logo amblemi Poly Haven Lantern_01 indirmesine bağlı.
  - **Öncelik:** P1 · **Dalga:** 6 · **İlgili:** 8.11, Y-C20
  - **Ne:** Atlı işaretin feneri, yoldaki kervan feneri, menünün ışık kaynağı, arayüzün kehribar vurgusu, logo yanında küçük amblem.
  - **Kabul:** Motif stil rehberinde; beş yerde uygulanmış.
  - **Kaynaklar ve teknik (CC0 araştırması):** Fener modeli: Poly Haven `Lantern_01` (CC0), render ve mürekkep geçişi.
  - **Literatür:** R58

</details>

## Paket P14

### Y-H01 · Onboarding'i ilk seferin içine yay

- **Durum:** kısmen · **Öncelik:** P1 · **Paket:** P14 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C14
- **Son not:** Babadan devir sahnesi (Y-C14) yeni oyunun ilk anı olarak kalıyor; dört konuluk panel yardım düğmesinde. | 2026-10-20 KULLANICI KARARI: çivili ipucu fişleri (FirstTimeHint) metinleriyle kaldırıldı ("iğrenç duruyor"); öğretici notları kullanıcı sonra yazacak. Dört konuluk panel yardım düğmesinde. | 2026-10-20 (son): çivili kâğıt fiş (G8) ipucu baloncuklarından ve pazar fişinden de kalktı, düz panel (46dd8c1).

<details><summary>Görev metni</summary>

- [ ] **Y-H01 Onboarding'i ilk seferin içine yay**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `2001285`): Babadan devir sahnesi (Y-C14) yeni oyunun ilk anı olarak kalıyor; dört konuluk panel yardım düğmesinde.
  - **Öncelik:** P1 · **Dalga:** 6 · **Bağımlı:** Y-C14
  - **Ne:** Dört konuluk panel kalkar. İlk sefer rehberli: ticaret, kontrat, planlayıcı, dikkat, sofra, savaş; her biri ilk karşılaşıldığı anda tek cümleyle. Babadan devir başlangıcıyla (Y-C14) birleşir.
  - **Kabul:** Yeni oyuncu testinde altı konu ilk seferde öğreniliyor.
  - **Literatür:** R78

</details>

### Y-H02 · İlk 10 dakikanın çizelgesi

- **Durum:** ölçüm hazır, dış oyuncu testi bekliyor · **Öncelik:** P1 · **Paket:** P14 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** docs/design_notes/ilk_on_dakika.md; dört ilk gerçek oyunda user://playtest_times.json a yazılır.

<details><summary>Görev metni</summary>

- [ ] **Y-H02 İlk 10 dakikanın çizelgesi**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `46fa60b`): docs/design_notes/ilk_on_dakika.md; dört ilk gerçek oyunda user://playtest_times.json a yazılır.
  - **Öncelik:** P1 · **Dalga:** 6
  - **Ne:** İlk 3 dakikada ilk anlamlı karar; 10 dakikaya kadar ilk tehdit; 30 dakikaya kadar ilk kayıp tehlikesi ve ilk kârlı varış.
  - **Kabul:** Dış oyuncu testlerinde süreler ölçüldü.
  - **Literatür:** R78, R59

</details>

### Y-H06 · Kumanda, Steam Deck ve Xbox

- **Durum:** denetim yazıldı, uygulama sonra (P3) · **Öncelik:** P3 · **Paket:** P14 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Sanal imleç bugün her ekranı kumandayla çalıştırıyor; eksikler (odak gezinmesi, tuş simgeleri, savaş ve pazar kısayolları, 1280x800 taraması) sıralı.

<details><summary>Görev metni</summary>

- [ ] **Y-H06 Kumanda, Steam Deck ve Xbox**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f3e22fb`): Sanal imleç bugün her ekranı kumandayla çalıştırıyor; eksikler (odak gezinmesi, tuş simgeleri, savaş ve pazar kısayolları, 1280x800 taraması) sıralı.
  - **Öncelik:** P3 · **Dalga:** 7
  - **Ne:** Kullanıcı notu: sonra eklenecek ama listede dursun. Tam kumanda desteği, Steam Deck uyumluluk denetimi, Xbox.
  - **Kullanıcı notu:** “bu daha sonra eklememiz gereken bir şey değil mi? listeye ekleyebiliriz yine de. steam deck, xbox.”
  - **Kabul:** Bütün ekranlar kumandayla oynanıyor.

</details>

## Paket P15

### Y-G13 · Kimliği tanımlayan beş ana görsel

- **Durum:** onaylandı, uygulanacak · **Öncelik:** P1 · **Paket:** P15 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G02, Y-G07
- **Son not:** Hepsi oyunun kendi resimleri ve bugünkü taslaklardan; olay kartı gerçek kart düzeniyle (savaş şeridi, mühür). | 2026-10-19 karar: kapıda vagonun ışığı ortama uymuyor; olay kartının kendi arka planı olmayacak, kart mevcut sahnenin (yol, taverna, şehir) içinde, olay görseli kartın içinde (EU4 gibi). Diğerleri güzel. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş).

<details><summary>Görev metni</summary>

- [ ] **Y-G13 Kimliği tanımlayan beş ana görsel**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Hepsi oyunun kendi resimleri ve bugünkü taslaklardan; olay kartı gerçek kart düzeniyle (savaş şeridi, mühür).
  - **Öncelik:** P1 · **Dalga:** 7 · **Bağımlı:** Y-G02, Y-G07 · **İlgili:** 8.10, 12.2a, 12.2c
  - **Ne:** Gece haritası ve fenerli atlı; kamp ateşi panoraması; tam ekran olay kartı; defter ve kırık mühür; şehir kapısına varış. Mağaza görüntüleri ve fragman bunlardan çıkar.
  - **Kabul:** Beş görsel onaylı.
  - **Literatür:** R58, R59

</details>

### Y-J14 · Mağaza ekran görüntüsü seti

- **Durum:** Aralık (kullanıcı notu), Y-G13 taslakları hazır · **Öncelik:** P2 · **Paket:** P15 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G13, Y-G05
- **Son not:** Kullanıcı: pazarlama işleri Aralıkta. Beş ana görsel onaylanınca oyunun gerçek ekranlarından (screenshot araçları) beş kare alınır.

<details><summary>Görev metni</summary>

- [ ] **Y-J14 Mağaza ekran görüntüsü seti**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kullanıcı: pazarlama işleri Aralıkta. Beş ana görsel onaylanınca oyunun gerçek ekranlarından (screenshot araçları) beş kare alınır.
  - **Öncelik:** P2 · **Dalga:** 7 · **Bağımlı:** Y-G13, Y-G05
  - **Ne:** Beş ana görselden beş ekran görüntüsü; ilk ikisi yol ve olay kartı. Kullanıcı notu: pazarlama işleri Aralık'ta.
  - **Kullanıcı notu:** “tamam zaten bu pazarlama işlerini hemen yapmayacağız. Aralık gibi yapılacak.”
  - **Kabul:** Beş ekran görüntüsü onaylı.
  - **Literatür:** R58

</details>

### Y-J09 · Kliplenebilir anlar listesi

- **Durum:** liste yazıldı, kayıtlar Aralıkta · **Öncelik:** P2 · **Paket:** P15 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Beş an: kırılma, varis devralma, alacaklı atlısı, kurt sürüsü, açlık gecesi; her biri için tetikleme ve kayıt hazırlığı.

<details><summary>Görev metni</summary>

- [ ] **Y-J09 Kliplenebilir anlar listesi**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f5e6c40`): Beş an: kırılma, varis devralma, alacaklı atlısı, kurt sürüsü, açlık gecesi; her biri için tetikleme ve kayıt hazırlığı.
  - **Öncelik:** P2 · **Dalga:** 7
  - **Ne:** Kırılma, varis devralma, alacaklı atlısı, kurt sürüsü, açlık gecesi; her biri net başlangıç ve sonu olan sahne.
  - **Kabul:** Liste ve her an için kayıt.
  - **Literatür:** R22, R11

</details>

## Paket P18

### N31d · Figür tepkileri: bakma ve yorgun bekleyiş

- **Durum:** kısmen · **Öncelik:** P2 · **Paket:** P18 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: look_ahead (alına siper) ve idle_tired klipleri tanımlı, yol bağlı (işarette en yakın yaya bakar, duran kervanda yorgun bekleyiş; yalnız duran kervanda, kayan ayak olmasın). Commit 8f7b27a. Render kuyrukta (figlogs/react_batch.sh); bitince append_clips ve yol görüntüsü. | 2026-10-20 10:5x: iki klip 276 kare setine eklendi. idle_tired açık (duran kervan). look_ahead 3B render'da el alnın önü yerine başın üstüne düşüyor, iki deneme (125/262, 118/238) tutmadı; RoadCaravan.LOOK_ENABLED=false. Çubuk figür ile 3B arasındaki farkı ölç (tests/screenshot_reactions.gd), sonra yeniden render. | 2026-10-20: look_ahead 92/206 ile yeniden render edildi ve eklendi ama poz hâlâ yanlış: el yüzün önünde/başın üstünde (journey_shots/tepkiler.png). LOOK_ENABLED kapalı. Öneri: ön kolu daha az bük (ör. arm_f [70, 165]) ve önce screenshot_poses çubuk figürüyle dene, sonra figlogs/look_batch.sh.

<details><summary>Görev metni</summary>

- [ ] **N31d Figür tepkileri: bakma ve yorgun bekleyiş** (`CO`) - look ve idle_tired klipleri, sinyalde en yakın figür bakar. (M, P2) §4.

</details>

### N31f · Durum tablolu ortam sesi ve savaş müziği

- **Durum:** kullanıcıda · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: ortam tablosu (ateş, rüzgâr) ve savaşta müzik kısma. Yağmur/orman/şehir kayıtları yok. | 2026-10-20 kullanıcı: ortam sesleri kullanıcıya bırakıldı.

<details><summary>Görev metni</summary>

- [ ] **N31f Durum tablolu ortam sesi ve savaş müziği** (`CO`) - hava × saat × yer ortam tablosu, savaşta müzik kısılır. (M, P1) §6.

</details>

### N34 · Konaklama, mini oyun ve sohbetle öğrenilen bilgi: yerleşimde kalmak

- **Durum:** kısmen · **Öncelik:** P2 · **Paket:** P18 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N33, Y-C13
- **Son not:** Kullanıcı isteği (2026-10-19), akşam düşünme ve geliştirme görevi. Taverna dedikodusu satın alınmaz, sohbetle edinilir. | 2026-10-20: söylenti satın alma kalktı; yol ve fiyat haberi sohbette (rol, içki, liman kültürü, tellal). Commit dee753b. Kalan: konaklama, mini oyunlar, adlı NPC hafızası (Y-C13/N32 lore'a bağlı).

<details><summary>Görev metni</summary>

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

</details>
