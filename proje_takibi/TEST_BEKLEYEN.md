# Test bekleyenler

Kodu yazılmış, commit edilmiş ama Godot açılmadığı için henüz test edilmemiş görevler. Akşam koşusu bu belgenin başındaki adımlarla yapılır; her görevin altında neyin görülmesi gerektiği yazıyor.

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



Toplam: **11** görev. Belgeler `referans/belge_uret.py` ile `referans/gorevler.json`'dan üretilir.

## Paket P03

### Y-E03 · Her kartta cazip ama riskli bir seçenek

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P03 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 59 kart incelendi, 7 karta zarlı seçenek eklendi.

<details><summary>Görev metni</summary>

- [ ] **Y-E03 Her kartta cazip ama riskli bir seçenek**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `6630a09`): 59 kart incelendi, 7 karta zarlı seçenek eklendi.
  - **Öncelik:** P2 · **Dalga:** 5
  - **Ne:** Yazım kuralı: kartların olabildiğince çoğunda anlatısal olarak çekici ama mekanik olarak riskli bir seçenek bulunur. Kural CLAUDE.md olay yazım kurallarına eklenir.
  - **Kullanıcı notu:** “Evet, "olabildiğince" olması gereken bir özellik.”
  - **Kabul:** Kural belgede; mevcut kartlar gözden geçirildi.
  - **Literatür:** R25, R16

</details>

## Paket P06

### 8.7 · Boğaza ad ver

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P06 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Son not:** Ad Drazvor Boğazı; GeoJSON ve geo_export güncel. Haritadaki yazı karolara basılı: patch_labels.py ile karolara yeniden basılmadı, oyunda eski ad görünüyor. | 2026-10-20 düzeltme: "oyunda eski ad görünüyor" notu yanlıştı - boğazın adı karolara hiç basılmamış; haritada hiçbir su adı (deniz, koy) yazılı değil. Ad verisi (GeoJSON) Drazvor Boğazı. Tek başına bir su etiketi basılmadı (tutarsız olurdu ve hale kâğıt rengine göre çiziliyor).

<details><summary>Görev metni</summary>

- [ ] **8.7 Boğaza ad ver.** GeoJSON'da geçici olarak "Kesgrav Boğazı" yazıyor. İsim kuralına uygun bir ad kullanıcıya sorulsun.

</details>

## Paket P07

### Y-C25 · Veba bir dünya hâli: kart açılmadan görünür

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C21
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: İlk parça: WorldEvents.natural_plague bölge ve 18 günlük dönem; has_plague kriz, bulaşma, işe alma ve şehir özetinde. Kart görseli bölgeyle soluyor (Y-G20). | 2026-10-31 onay turu: Kullanıcı (onay turu): Düzenle - veba kendiliğinden gelip gitmez; arka planda nüfus, bulaşma ve şehirler arası ilişki sistemi kurulacak; nerede veba olduğu yolda ya da şehirde haber olarak öğrenilir. | 2026-10-31: PlagueWorld (nüfus, bulaşma, yollarla yayılma, kervanın taşıması, bağışıklığın sönmesi) ve plague_news (görülür/duyulur); ölçüm kurallar-ekonomi Plague Rules. | 2026-11-01: veba yolda da duyulur.

<details><summary>Görev metni</summary>

- [ ] **Y-C25 Veba bir dünya hâli: kart açılmadan görünür**
  - **Onay turu (2026-10-31):** kısmen. Kullanıcı (onay turu): Düzenle - veba kendiliğinden gelip gitmez; arka planda nüfus, bulaşma ve şehirler arası ilişki sistemi kurulacak; nerede veba olduğu yolda ya da şehirde haber olarak öğrenilir.
  - **Durum (2026-10-31):** kısmen. İlk parça: WorldEvents.natural_plague bölge ve 18 günlük dönem; has_plague kriz, bulaşma, işe alma ve şehir özetinde. Kart görseli bölgeyle soluyor (Y-G20).
  - **Öncelik:** P1 · **Dalga:** 2 · **Bağımlı:** Y-C21 · **Kim:** C
  - **Ne:** Veba genel bir durum. Etkileri kart açılmadan görülür: şehrin görünüşü ve kapısı, yol, pazar, işe alınacak insanlar, kervanın sağlığı. Bölgeye göre farklılık var. İlgili olaylar ayrıca olabilir.
  - **Kullanıcı notu:** "Veba genel bir durum olmalı, bununla ilgili olaylar olabilir ama event card çıkmadan da etkilerini görmeliyiz. Bölgeye göre farklılık olmalı."
  - **Kabul:** Veba altındaki bir şehir ve yolun, kart açılmadan farkı gösterilen görüntüsü; etkiler test edilir.

</details>

## Paket P12

### Y-G07 · Yol sahnesi: haritaya bağlı biyomlar ve varyantlar

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G01, Y-G02, Y-C01, 12.2d
- **Son not:** Biyomlar haritadan (N28), vadiye çayır (N29, 5ae38c4). | 2026-10-21 iklim ve ufukta dağ varyantları (K14), test bekliyor.

<details><summary>Görev metni</summary>

- [x] **Y-G07 Yol sahnesi: haritaya bağlı biyomlar ve varyantlar**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `2c8be40`): Biyomlar haritadan (N28), vadiye çayır (N29, 5ae38c4).
  - **Öncelik:** P1 · **Dalga:** 6 · **Bağımlı:** Y-G01, Y-G02, Y-C01, 12.2d · **İlgili:** 12.2, 12.2e, 9.10
  - **Ne:** Kullanıcı notu: tek biyom değil, bütün biyomlar için birer örnek kare; sonra her biyomun varyantları türetilir ve birbirine bağlanır. Biyom haritadan seçilir; yol arka planı haritadaki konuma göre kurulur (dağlık yerden geçerken arkada dağ). Halkalı güneş ve ay, lolipop ağaç, koni çam ve prosedürel sırtlar kalkar.
  - **Kullanıcı notu:** “sadece bir biyom değil, tüm biyomlar için birer örnek olmalı ve daha sonra bu biyomlara ait varyantlar türetilmeli, birbirine bağlanmalı fakat unutma elimizde harita var artık, bu yüzden biyomları haritada seçmeli, bu haritadaki konumlara göre varyant oluşturmalıyız. mesela dağlık bir yerden geçiyorsak dağ görmeliyiz arkaplanda.”
  - **Kabul:** Her biyomun onaylı örnek karesi; yol arka planı haritadaki konumdan üretiliyor; biyom geçişleri dikişsiz.
  - **Kaynaklar ve teknik (CC0 araştırması):** Arazi dokuları Poly Haven ve ambientCG (CC0): dirt, path, mud, rocky, snow, grass. Ağaç, kaya, harabe ve kamp nesneleri: Kenney Survival Kit, Quaternius Ultimate Modular Ruins; render ve mürekkep geçişi (Y-G02). Yeni Quaternius indirmeleri QAL lisansıyla (tarih ve lisans sayfasının ekran görüntüsü kaydedilir). Ses katmanı Y-I01'deki biyom × gün saati ambiyansıyla eşleşir. `../ICERIK_IHTIYACLARI.md` G-2, G-4.

</details>

### 9.10 · Yol arka planları, biyom başına

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Y-G07 biyom şeritleri hazır; sis şeridi ve gece varyantı taslakta, enkaz (Broken Cart) 12.2 sırasının 5. adımı. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş). | 2026-10-21 sis şeridi ve gece varyantı oyunda (K5). Haritadaki konuma göre biyom varyantları (Y-G07) Blender işi, yapılmadı. | 2026-10-21 haritaya göre görünüşler oyunda (K14): kuzey soğuk, güney sıcak, dağa yakın parçada ufukta dağ; 24 görünüş.

<details><summary>Görev metni</summary>

- [ ] **9.10 Yol arka planları, biyom başına** (A-03, A-05, A-07, A-09, A-10, A-12, A-20, A-24 …)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `2dd895a`): Y-G07 biyom şeritleri hazır; sis şeridi ve gece varyantı taslakta, enkaz (Broken Cart) 12.2 sırasının 5. adımı.
  - Katmanlar: soğuk uzak katman, sıcak ön plan, döşenebilir orta katman, sis şeridi.
  - Kervan enkazı eşyası.
  - Gece varyantı.
  - **Kullanıcı kararı ve kaynaklar:** Bu iş **Y-G07** ile birlikte yapılır (bütün biyomlar, haritadaki konuma göre varyantlar). Dokular Poly Haven ve ambientCG (CC0), nesneler Kenney Survival Kit ve Quaternius (yeni indirmeler QAL), enkaz Quaternius `Broken Cart`. Ayrıntı: `../ICERIK_IHTIYACLARI.md` G-2, G-4.

</details>

### 12.1 · Şehir menülerinde kamera şehre çok yakın, bir tık geriden bakılmalı

- **Durum:** kamera ayarlandı, render akşam · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** Lens 24->20 (kadraj ~%20 geniş); deneme render: vastrevar kenarlarda boşluk yok.

<details><summary>Görev metni</summary>

- [ ] **12.1 Şehir menülerinde kamera şehre çok yakın, bir tık geriden bakılmalı.**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b620a9b`): Lens 24->20 (kadraj ~%20 geniş); deneme render: vastrevar kenarlarda boşluk yok.
  - **Yer:** `scripts/ui/grim/city_front.gd:64-67`. Arka plan `TextureRect`, `STRETCH_KEEP_ASPECT_COVERED` ile ekranı kaplıyor; bu yüzden kenarlardan kırpılıyor ve yakın görünüyor. Tıklama eşlemesi `cover_to_image()` (`:120`) aynı kaplama hesabını kullanıyor.
  - **Seçenekler:**
    - **(a, önerilen)** Kasaba render'larını daha geniş kadrajla yeniden al: `tools/ui_scenes/town_scene.py` içindeki kamera uzaklığı ya da odak uzaklığı yaklaşık %15–20. `mask.png` aynı kameradan yeniden üretilmeli.
    - **(b)** Mevcut görseli yaklaşık %85 ölçekle göster; kenarda kalan boşluğu gökyüzü ya da zemin uzantısıyla doldur. Bu durumda `cover_to_image()` ve tıklama alanları yeni ölçeğe göre güncellenmeli.
  - **Kabul:** 6 şehrin hepsinde şehrin silueti ve çevresi biraz daha görünür; mekân levhaları, kadro kartları ve alt şerit hâlâ yerinde; maske tıklamaları doğru (`tests/test_grim_ui.gd` CityFront eşleme testleri).

</details>

### Y-H05 · Savaşa vuruş hissi

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G06
- **Son not:** Kenney Impact Sounds (CC0) beşer çeşit (data/assets/audio/combat), rastgele seçim ve perde oynaması. Kalan: mürekkep sıçraması (Y-G06 onayına bağlı).

<details><summary>Görev metni</summary>

- [ ] **Y-H05 Savaşa vuruş hissi**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `972c733`): Sesler: hit/hit_crit/hit_kill.wav gelince otomatik çalar (Freesound CC0 üç katman, indirme izni gerekli). Mürekkep sıçraması Y-G06 onayından sonra.
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-G06
  - **Ne:** Kritikte kısa yakınlaşma, mürekkep sıçraması, anlatıcı satırı, ses; ölümde bir anlık duraklama.
  - **Kabul:** Savaş videosu onaylı.
  - **Kaynaklar ve teknik (CC0 araştırması):** Vuruş başına üç ses katmanı (metal çınlama + künt gövde + zırh ya da kumaş kuyruğu), her katmanda `AudioStreamRandomizer` (perde ±%5–8, tekrarsız rastgele). Kaynak: Freesound CC0 `sword clash`, `arrow impact`, Kenney Impact Sounds.
  - **Literatür:** R20, R21

</details>

### 9.11 · Waybook ve defter

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19 karar: onay. | 2026-10-20: defterde Düşenler açılımı: rütbeye göre mezar işareti (GraveMark: kurucu, lider, yoldaş, tayfa), rol · sebep, yer satırı, sağda hikâye satırları (15 kamp hikâyesine kısa özet). Kâğıt üstündeki çizgi ince ve kan kırmızısı. test_waybook_pages, screenshot_waybook 01b. Commit 4af6c2f.

<details><summary>Görev metni</summary>

- [ ] **9.11 Waybook ve defter** (T-10, T-11)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Hikâye satırları.
  - "Düşenler" sayfası: mezar işaretleri rütbeyle süslenir.

</details>

### DFT1 · Defter sayfası okunur olsun (cetvel çizgileri)

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/referans/gorevler/09_art_ikinci_tur.md](referans/referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Kullanıcı bildirimi (2026-10-19). tools/ledger_unrule.py: kaynak art_source/waybook/l1_ledger_ruled.jpg, çıktı data/assets/ui/waybook/l1_ledger.jpg; cetvel normalize evrişimle silindi, CC0 kâğıt dokusu eklendi. Lekelerin içinde küçük ızgara parçaları kaldı.

## Paket P18

### N33 · Yerleşim menülerinin gün evresi varyantları: sabah, gündüz, akşam, gece

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P18 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** 9.3, 12.1
- **Son not:** Kullanıcı isteği (2026-10-19), akşam düşünme ve geliştirme görevi. Taverna dedikodusu satın alınmaz, sohbetle edinilir. | 9.3 ile aynı iş: evre resimleri render ediliyor. | 9.3 ile aynı: commit 0b7eeeb.

<details><summary>Görev metni</summary>

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

</details>

## Paket P19

### T16-07 · Bölgesel itibar ve hizipler

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P19 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/16_oyun_testi_isleri.md](referans/gorevler/16_oyun_testi_isleri.md)
- **Son not:** 2026-11-02 kullanıcı listesi. Eski: Y-C12. | Yapıldı, kullanıcı onayına sunuldu: Standing (bölge başına itibar + lonca/kilise/kardeşlik), standing.json ilişki matrisi (LORE §12; komşu 0,1, uzak 0,03, düşman eksi), reputation artık bölgenin değeri (eski kapılar bölgeden okur), kredi ve pano lonca payıyla, kardeşlik yol tehlikesini ±%20 oynatır (dökümde satırı var), kilise bağışı ve hekim indirimi, EventEffect.FACTION (haraç/fidye +, direniş -), kayıt + eski kayıt geçişi, durum sekmesinde satırlar. Test: test_standing.

<details><summary>Görev metni</summary>

- [ ] **T16-07 Bölgesel itibar ve hizipler**
  - **Ne:** Bölgesel itibar ve hizipler (eski Y-C12). Kullanıcı onayına sunulur.
  - **Kim:** CO · **Eski:** Y-C12

</details>
