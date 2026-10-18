# Karanlık Arayüz Taslağı (ui-hud-redesign)

**Durum: onaylandı ve `main`'e birleşti (Faz 27); şehir ve ana menü bağlı, kalan ekranlar §7'de.**
Aşağıdaki "taslak" ifadeleri tarihtir. Taslak bileşenler `scripts/ui/grim/` altında,
taslak ekranlar `tests/screenshot_grim_ui.gd` ile çiziliyor
(`-- karakonak kurtbogazi ...` ile şehir seçilir).

## 0. İkinci turda neyin değiştiği (oyuncunun geri bildirimi)

| Geri bildirim | Cevap |
|---|---|
| Şehir yan görünüm olmasın, birebir [referans oyundaki] gibi, gidilen yere göre | Her şehir önden bakılan, boyalı bir kasaba resmi (`CityFront`). Beş şehir, beş ayrı sahne. Solda mekân levhaları, sağda kadro kartları, sol üstte arma + sancak, altta tahta şerit ve kızıl "Yola Çık". Binanın üstüne gelmek levhayı, levhanın üstüne gelmek binayı aydınlatıyor. |
| HUD düğmeleri alakasız | Düz kutular gitti. İkonu olan eylem madalyon düğme (oyunun kendi eşya render'larından), olmayan taş levha, geri alınamayan çıkış kızıl. Şeritler perçinli demir kenarlı koyu tahta. |
| Menüdeki fener çok parlak, arka plan hoş değil | Arka plan artık render edilmiş bir gece kampı: brandalı vagon, kamp ateşi, tepede uzak bir şehir. Tek ışık ateş; küçük, kısık, titrek. Menü sağda koyu bir şerit (Wartales). |
| Kitap animasyonu kötü | Kaldırıldı. Yerine soy satırı: "Demirtaş kervanı · 3. kuşak · 214. gün" - kitabın söylemek istediği tek şey buydu. |
| Doku kararı oyun geliştirme estetiğine göre | Doku, malzemenin ne olduğunu söylediği yerde: şerit tahta, levha taş, sancak kumaş, kenar pas demir. Okunacak metin hep düz koyu bir zeminde - dokunun üstüne yazı yazılmıyor. Kaynak ambientCG (CC0). |
| Gerekirse font değiştir, yerine göre farklı font | Üç yüz, üç görev: Grenze Gotisch (gotik vitrin; yalnızca oyunun adı ve şehrin sancağı), IM Fell English SC (başlık, levha, düğme), EB Garamond (gövde). Üçü de OFL, üçü de bütün Türkçe harfleri taşıyor (ölçüldü). |
| Eşya bozulması ve Celsius sıcaklık hedeflere | `main`'deki CLAUDE.md Ana Hedefler'e eklendi. Sıcaklık göstergesi taslakta derece okuyor ("−4 °C"; alev −25 °C'de sönmeye yakın, 30 °C'de tam). |
| Referanslar yeterince işlenmemiş | Aşağıda §1: her referanstan neyin alındığı tek tek. |
| Diğer ekranlar onaylı, iyileştirilebilirse iyileştir | Ticaret ve envanter yeni şeritleri, ikonlu düğmeleri ve sancak etiketlerini aldı; envanter boş siyah alan yerine loş avlu masasının üstünde, ızgaralar ortada. Kadro şeridine sınıf amblemi eklendi. |

## 1. Referans analizi - neyin alındığı

`UI-HUD.rar`'ın 45 görüntüsü ticari oyunlardan ekran görüntüsü. **Hiçbir
pikseli oyuna girmedi**; alınan şey düzen, oran, palet ve kural.

| Referans | Aldığımız | Nerede |
|---|---|---|
| Referans oyun - kasaba | Önden, mürekkepli, sıcak pencereli kasaba; arkada tepede kale; sol üstte arma ve sancak; binanın üstüne gelince kontur ve aydınlanma; altta koyu şerit, kaynaklar solda, kızıl gömme düğme sağda | `CityFront`, `town_scene.py` + `town_post.py` |
| Referans oyun - kadro | Sağda dikey kişi kartları: amblem, ad, sınıf/seviye, can çubuğu, on boncuklu stres | `CityFront._card` |
| Referans oyun - ikonlar | Alt şeritte kutusuz, resmin kendisi olan düğmeler | `GrimTheme.icon_button`, `ui_kit.py` madalyonları |
| Frostpunk | Sıcaklık bir derece; soğuk bir sistem soğuk renkte | `SurvivalGauge.set_celsius` |
| Wartales | Manzaranın üstünde sağda koyu bir menü şeridi | Başlık ekranı |
| Banner Saga | Yırtık kızıl sancak - haber ve uyarı bir kumaş parçası | `GrimTheme.banner_tag`, şehir sancağı |
| KCD | Parşömen yalnızca belge olan yerde | Haber kartı (`GrimNotice`) |
| This War of Mine | Karanlık zemin, kurşun kalem çizgi | Render'ın mürekkep geçişi |

Ölçülen ortak payda değişmedi: ekranın %60-80'i kömür, kırmızı yalnızca
kayıp ve tehlike, kehribar yalnızca ışık.

## 2. Kasaba resimleri nasıl üretiliyor

1. `tools/ui_scenes/town_scene.py --city <ad>`: Blender'da (bpy) şehir
   başına bir sahne, `towns.json`'dan. Quaternius Medieval Village (CC0)
   binaları, Kenney Fantasy Town Kit (CC0) duvarlarından kurulan gotik
   kuleler, surlar ve sancaklar, ambientCG (CC0) dokuları. Cycles + Freestyle
   mürekkep çizgisi. Üç geçiş: resim (gök saydam), mekân kimlikleri, derinlik.
2. `tools/ui_scenes/town_post.py <ad>`: boyalı gök (bulut, ay), derinliğe
   bağlı sis, ton (doygunluk kırılır, sıcak ışık doygun kalır, gölgeler
   mor-kömüre), ışık taşması, kalınlığı yakınlığa bağlı mürekkep, kâğıt
   dokusu, kir, kenar kararması. Çıktı `data/assets/ui/towns/<ad>/`:
   `background.jpg` ve `mask.png` (piksel başına mekân numarası).
3. `CityFront` resmi "kapla" kipinde çiziyor, maskeyi aynı dönüşümle okuyor;
   `venue_highlight.gdshader` seçilen mekânı aydınlatıp kehribar kontur
   çiziyor, kalanı karartıyor.

| Şehir | Kimliği |
|---|---|
| Karakonak | Kavşak: kızıl alacakaranlık, tepede kale, taş setler üstünde lonca ve kilise |
| Kurtboğazı | Dağ geçidi: soğuk mavi gece, karlı sarp kaya, kayanın tepesinde sur, köknarlar |
| İpekevi | İpek ve fuar şehri: altın-mor akşam, kalabalık pazar, sancaklar, sivri kuleli lonca |
| Demirkapı | Demir surlar: is ve ocak kızılı, arkada kemerli kapısıyla sur ve kuleler, önde demirci ateşi |
| Yeşilova | Ova: yeşilimsi gece, yel ve su değirmeni, çit, saman, yuvarlak ağaçlar |

Ana menü aynı hattan bir "kamp" sahnesi (`towns.json` → `camp`).

## 2b. Yol: render edilmiş paralaks katmanları (üçüncü tur)

Kasabaların onaylanan üslubu yola taşındı, düzen Oregon Trail'den (2021)
uyarlandı - kasvetli paletle. Alçak kamera: yol ekranın ortasında bir bant
(`RENDERED_ROAD_RATIO` 0.72), arkasında diz boyu ot ve ağaçlar, önünde
kameraya yakın, koyu ve bulanık bir ot tarlası. Derinlik çizgiden değil
pustan ve alan derinliğinden geliyor; mürekkep yalnızca kervanın
düzleminde.

| Katman | Ne | Son işleme | Paralaks | Döşeme |
|---|---|---|---|---|
| `far` | sırtlar, dağlar (kar yalnızca tepede), uzak orman | mürekkepsiz, pus %50, bulanık | 0.10 | 1.5 × şerit |
| `mid` | prosedürel ağaçlar: yapraklı, iğne yapraklı, kurumuş | ince mürekkep, hafif bulanık | 0.52 | 3.4 × şerit |
| `ground` | zemin, yol, tekerlek izi, yol kenarı ot bandı | keskin, mürekkepli | 1.0 | 2.17 × şerit (40 m) |
| `fore` | yakın tarla: uzun ot, pas ve kemik renkli çiçek, sazlık | koyu, çok bulanık | 1.45 | 1.3 × şerit |

Oyunda üstlerine: uzak sırta ve ağaç hattına gökyüzünün pusu, yolun üstünde
ışığın rengini alan ince bir toz perdesi (yağmurda yok), tarlanın dibine
doğru koyulaşan bir gölge.

- **Üretim:** `tools/ui_scenes/road_scene.py --biome <ad>` (Blender, CC0
  dokular, ağaçlar prosedürel - paket ağaçları oyuncak gibi katmanlıydı),
  `road_post.py` (ton, pus, mürekkep, alan derinliği). Çıktı
  `data/assets/ui/road/<biyom>/`.
- **Dikişsiz:** sahne x'te periyotlu, doku tekrarı şeride tam sayı kez
  sığıyor, kar gürültüsü x'i bir çembere sarıp okuyor, mürekkep ve
  bulanıklık yatayda sarmalı. Test zeminin iki kenarını karşılaştırıyor.
- **Saat ve hava sistemin kendisi:** katmanlar nötr gün ışığında; oyun
  onları evrenin ışığıyla çarpıyor. Gökyüzü, güneş/ay, uzak şehirler, yol
  durakları, yağmur prosedürel kalıyor.
- **Biyom geçişi:** `RouteTerrain.biome_blend_at()` - rengin karışımıyla aynı
  oran.
- **Geri dönüş:** dört katmanı olmayan biyom eski prosedürel çizime düşer.
- Referanslardan hiçbir piksel alınmadı; alınan düzen ve derinlik dili.

## 3. Palet ve tipografi

ArtPalette tek renk otoritesi (GRIM_*). Yazı yüzleri:

| Yüz | Lisans | Görev |
|---|---|---|
| Grenze Gotisch | OFL 1.1 | Vitrin: oyunun adı, şehrin sancağı. Ekranda en fazla bir kez; okunacak hiçbir şey. |
| IM Fell English SC | OFL 1.1 | Başlık, levha, düğme, büyük sayı |
| EB Garamond | OFL 1.1 | Gövde (oyunun mevcut kitap yüzü) |

CJK dillerinde ilk ikisi kitap yüzüne düşer (fallback zinciri).

## 4. Bileşenler (`scripts/ui/grim/`)

| Bileşen | Ne yapar |
|---|---|
| `CityFront` | Önden bakan, düzenli şehir ekranı; `venue_pressed(scene_path)` CityView ile aynı sinyal, `nav_pressed(key)` alt şerit |
| `venue_highlight.gdshader` | Maskeye göre mekân vurgusu |
| `GrimTheme` | Yazı yüzleri, şerit/levha/sancak kutuları, madalyon ve kızıl düğme |
| `SurvivalGauge` | Şişe, alev (Celsius), leke - sayı yanında |
| `GrimNotice`, `TradeScales`, `MarketMeter`, `WornCell` | İlk turda onaylandı |
| `AshFall`, `SmokeWisps`, `LanternGlow`, `InkMenu` | Atmosfer ve kutusuz menü |
| `GrimDrafts` | Taslak ekranları kurar; `from_session()` modeli doldurur |

Üreteçler: `tools/ui_scenes/town_scene.py`, `town_post.py`, `ui_kit.py`
(şerit, levha, sancak, arma, kart, madalyon ikonlar), `tools/grim_ui_assets.py`
(ilk turun dokuları ve sesleri). İlk turun yan görünüm sokağı silindi.

## 5. Etkileşim durumları

| Durum | Görsel | Ses imi |
|---|---|---|
| Hover (bina/levha) | Bina aydınlanır + kehribar kontur, öbürleri kararır; levha kehribar kenar | `ui_hover` |
| Hover (ikon) | İkon ısınır, ad kehribar | `ui_hover` |
| Basılı | Kan kenarı | `ui_press` |
| Kilitli | Soluk, sebebi yanında | - |
| Para | Terazi oturur | `ui_coin` |
| Kayıp / alamet kartı | Kart düşer, damga | `ui_stamp` / `ui_alert` |

## 6. Projenin kurallarıyla çatışmalar - onayınız gereken yerler

1. **Şehir B10 masa sahnesinden render edilmiş kasabaya geçiyor**, Ana
   Hedefler'deki "önden bakan şehir" maddesini karşılıyor; ikisi aynı anda
   yaşayamaz.
2. **Doku geri geliyor, ama deri değil.** Tahta şerit, taş levha, kumaş
   sancak, pas demir kenar - hepsi CC0 fotoğraf dokusundan, karartılmış.
   Waybook UI Rules'un "kontroller tek düz aile" kuralı bu tasarımla
   değişir; onaylanırsa kural yeniden yazılır.
3. **Üçüncü bir yazı yüzü** (Grenze Gotisch), yalnızca vitrin.
4. **Mekânlar sahne değiştirmeden mi açılsın?** Taslakta levhaya tıklamak
   doğrudan mekâna gidiyor (bugünkü davranış). Ana Hedefler'deki "mekânlar
   popup olarak" maddesi ayrı bir iş.

## 7. Onaydan sonra uygulama sırası

1. GrimTheme'in kalıcı parçaları WaybookTheme'e (yüzler, şerit/levha/sancak,
   GRIM paleti); `test_waybook_theme.gd` yeni kuralla güncellenir.
2. ✓ Şehir: `city_map.tscn`'de CityView yerine `CityFront`; CityBriefPanel
   satırları levhalara ve kartlara dağılır; `test_navigation.gd` grafiği.
3. ✓ Ana menü: kamp arka planı, soy satırı, sağ şerit; kitap (M1/M2) kalkar.
4. Yol HUD'u: ✓ PulseBar → SurvivalGauge (sağ üst levha); alt şerit ikonlu; defter olayları →
   GrimNotice.
5. Pazar ve envanter.
6. Sıcaklık ve bozulma mekanikleri (Ana Hedefler) bağlanınca gösterge ve
   hücre gerçek veriyle.

## Dosyalar

- `tools/ui_scenes/` - kasaba/kamp render'ı, son işleme, arayüz takımı, `towns.json`
- `data/assets/ui/towns/<şehir>/` - `background.jpg`, `mask.png`
- `data/assets/ui/grim/kit/` - şerit, levha, sancak, arma, kart, ikonlar
- `data/assets/fonts/GrenzeGotisch.ttf` + OFL
- `art_source/models/ui_scenes/kenney_fantasy_town/` (CC0),
  `art_source/textures/ambientcg/` (CC0, `LICENSES.md`)
- `scripts/ui/grim/*`, `tests/test_grim_ui.gd`, `tests/screenshot_grim_ui.gd`
