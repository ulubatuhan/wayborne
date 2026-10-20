### Akşam koşusu · 0. Hazırlık (bir kez)

```powershell
cd D:\Users\u90238\Desktop\xx\wayborne
$g = "D:\Users\u90238\Desktop\xx\araclar\godot\Godot_v4.2.2-stable_win64_console.exe"
git status                      # temiz olmalı
git log --oneline -40           # bu belgenin kapsadığı commit'ler
```

1. **İçe aktarma** (yeni resimler, şeritler, çeviriler): `cmd /c "$g --headless --import > import.log 2>&1"`.
   Temiz klonda ilk koşu 1 ile biter, bir kez daha koştur. Pencere açmaz.
2. **project.godot:** `git diff project.godot`. İçe aktarma `windows_native_title` satırını düşürüyorsa
   `git checkout -- project.godot`.
3. **Betik hatası taraması:** her günlükte `SCRIPT ERROR|Parse Error|Compile Error|Failed to load script|Failed to create an autoload`.
   Godot bunları basıp 0 ile çıkabilir (CLAUDE.md). Yerel betik: (yerel kontrol betiği yok; komutlar aşağıda) (import + test + tarama).

### Akşam koşusu · 1. Birim testleri (pencere açmaz)

```powershell
cmd /c "$g --headless --script res://tests/run_tests.gd > tests.log 2>&1"
```

- Beklenen: `N geçti, 0 kaldı`, çıkış kodu 0. Günlük cp1254 kodlamalı.
- Kalan varsa: görev kimliği aşağıdaki tabloda; önce testin kendisini, sonra kodu şüphelen (CLAUDE.md'nin ölçüm hataları
  dersi).

### Akşam koşusu · 2. Ekran görüntüleri (pencere açar)

Pencere ekran dışına alınabilir: `--position 20000,20000`. Pencere görünmezken kare tamamen siyah (0,0,0) gelebiliyor;
siyah gelirse o aracı yeniden koştur. Çıktılar `%APPDATA%\Godot\app_userdata\Wayborne\<ad>_shots\`.

```powershell
function Shot($script, $rest) {
  $a = @('--path','.','--resolution','1920x1080','--position','20000,20000','--script',"res://tests/$script") + $rest
  $p = Start-Process -FilePath $g -ArgumentList $a -PassThru -NoNewWindow
  if (-not $p.WaitForExit(400000)) { $p.Kill() }
}
```

### Akşam koşusu · 3. Simülatörler (pencere açmaz, denge)

```powershell
cmd /c "$g --headless --script res://tests/simulate_journeys.gd > sim_journeys.log 2>&1"
cmd /c "$g --headless --script res://tests/simulate_career.gd > sim_career.log 2>&1"
```

Karşılaştırma tabanı: `docs/design_notes/denge_yeni_dunya.md` (N8 ölçümü).

Ek simülatörler ve raporlar (pencere açmaz):

```powershell
cmd /c "$g --headless --script res://tests/simulate_attention.gd > sim_attention.log 2>&1"
cmd /c "$g --headless --script res://tests/simulate_road_beats.gd > sim_beats.log 2>&1"
cmd /c "$g --headless --script res://tests/report_event_quality.gd > event_quality.log 2>&1"   # Y-E01
```

- `simulate_career`: tehdit kartı evre sayımı (Y-C15) ve **finale kadar tekrar oranı** satırı (Y-E01).
- `report_event_quality`: listeden geçmeyen kartlar ve çekilebilir kart / 120.

### Akşam koşusu · 3b. Bu turun araçları (pencere açmaz, uzun)

1. **Codex olay sayfaları (Y-E07):**
   ```powershell
   cmd /c "$g --headless --script res://tests/export_codex_events.gd > codex_export.log 2>&1"
   python -X utf8 docs/codex/codex_main.py
   ```
   Beklenen: `docs/codex/events_export.json` 71 olay; PDF'in olay bölümünde 29 elle + 42 otomatik sayfa.
2. **Kasaba resimleri, geniş kadraj (12.1)**, bilgisayar boştayken (~1,5-2 saat, Blender -b, pencere açmaz):
   ```powershell
   python -X utf8 tools/ui_scenes/render_all_towns.py
   ```
   Sonra `test_grim_ui` (CityFront eşleme) ve şehir ekranı görüntüleri.
3. **Kapı sahnesi tam boy (12.2a, onaylanırsa):**
   ```powershell
   $env:WAYBORNE_TOWN_CFG="tools/ui_scenes/gates.json"; $env:WAYBORNE_TOWN_OUT="build/gates"
   python -X utf8 tools/ui_scenes/settlement_gates.py
   ```
   ve her yer için `town_scene.py -- --city gate_<id>` + `town_post.py gate_<id>`.
4. **Oyuncu testi ilk dakikaları (Y-H02):** dış oyuncu oynadıktan sonra `python -X utf8 tools/playtest_report.py`.


### Akşam koşusu · bu turun ekleri

- `python -X utf8 tools/worldmap/cm/patch_labels.py <karo_klasörü> referans/harita_final/wayborne_harita.geojson <çıktı>`:
  Drazvor Boğazı etiketi karolara basılır (8.7).
- İçe aktarma yeni sesleri (`data/assets/audio/combat/*.ogg`) ve fener amblemini alır; savaşta vuruş sesi duyulmalı.
- Defter (L tuşu): sayfa düz, cetvelsiz okunur (DFT1).

<!-- ONAY -->
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

