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



Toplam: **98** görev. Belgeler `referans/belge_uret.py` ile `referans/gorevler.json`'dan üretilir.

## Paket P01

### Y-K02 · Otomatik ekran görüntüsü karşılaştırması

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P01 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Araç ve iş akışı hazır; GitHub Actions koşusu push sonrası (TEST_PLANI.md).

<details><summary>Görev metni</summary>

- [ ] **Y-K02 Otomatik ekran görüntüsü karşılaştırması**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `6868274`): Araç ve iş akışı hazır; GitHub Actions koşusu push sonrası (TEST_PLANI.md).
  - **Öncelik:** P1 · **Dalga:** 1
  - **Ne:** Kritik ekranlar her derlemede GitHub Actions'ta çekilip önceki sürümle karşılaştırılır; görsel bozulmalar yakalanır.
  - **Kabul:** CI'da görsel karşılaştırma adımı; fark raporu artefakt olarak.

</details>

## Paket P02

### 1.4 · Belgeleri temizle

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/01_isim_kurali.md](referans/gorevler/01_isim_kurali.md)
- **Son not:** Codex PDF Windows yazı tipleriyle yeniden üretildi; metinde yasaklı sözcük yok (pypdf ile tarandı).

<details><summary>Görev metni</summary>

- [ ] **1.4 Belgeleri temizle**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8b9db66`): Codex PDF Windows yazı tipleriyle yeniden üretildi; metinde yasaklı sözcük yok (pypdf ile tarandı).
  - `CLAUDE.md`, `README.md`, `docs/ui/REDESIGN.md`, `GELISIM_GECMISI.md` (§6 N-9).
  - `docs/codex/codex_body.py` ve `codex_events_data.py`: oyuncuya dönük PDF metni üretiyorlar, öncelikli.

</details>

### 1.5 · Doğrulama

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/01_isim_kurali.md](referans/gorevler/01_isim_kurali.md)
- **Son not:** git grep sıfır; kural tests/test_naming_rule.gd ile korunuyor.

<details><summary>Görev metni</summary>

- [ ] **1.5 Doğrulama:** `git grep` ile yasak kelime taraması (liste: CLAUDE_BASLANGIC.md) hiçbir sonuç vermemeli. Sonra testleri ve CI'ı çalıştır.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8b9db66`): git grep sıfır; kural tests/test_naming_rule.gd ile korunuyor.

</details>

### 4.4 · Olay anahtarlarını açık yaz

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P02 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/04_kod_kalitesi.md](referans/gorevler/04_kod_kalitesi.md)
- **Son not:** 2026-10-20: EventCatalog._event başlık ve metin anahtarını açık alıyor (71 çağrı); Düşenler sayfasının hikâye özeti de açık tablodan (CampStory.STORY_LINE_KEYS). Kullanıcıya sorulmadı: kural CLAUDE.md'de zaten açık.

<details><summary>Görev metni</summary>

- [ ] **4.4 Olay anahtarlarını açık yaz** (§3D)
  - `event_catalog.gd:2173` anahtarları `"%s_TITLE"` ile çalışma anında kuruyor; CLAUDE.md kuralı bunu yasaklıyor.
  - Kasıtlı bir istisna olup olmadığını kullanıcıya sor.

</details>

### 4.3 · Tekrarlanan yardımcıları birleştir

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/04_kod_kalitesi.md](referans/gorevler/04_kod_kalitesi.md)
- **Son not:** reduce_motion NodeUtil'de; autoload kopyaları bilerek kaldı; CI birleştirme GitHub'da doğrulanamadığı için yapılmadı.

<details><summary>Görev metni</summary>

- [ ] **4.3 Tekrarlanan yardımcıları birleştir** (§3C)
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `3e35324`): reduce_motion NodeUtil'de; autoload kopyaları bilerek kaldı; CI birleştirme GitHub'da doğrulanamadığı için yapılmadı.
  - `TextureLoader.load_any` (5 kopya), `_reduce_motion` (4), `_clear_children` (8), işe alma düğmesi (3), `tr` sarmalayıcıları (4), `_with_mipmaps` (2).
  - CI adımlarını tek bir reusable workflow'a topla.

</details>

## Paket P03

### Y-A01 · Oyun vaadini yaz ve belgelere işle

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Tasarım belgesi ve Steam metni taslağı yazıldı; vaat cümlesi onay bekliyor.

<details><summary>Görev metni</summary>

- [ ] **Y-A01 Oyun vaadini yaz ve belgelere işle**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `7083b90`): Tasarım belgesi ve Steam metni taslağı yazıldı; vaat cümlesi onay bekliyor.
  - **Öncelik:** P1 · **Dalga:** 1
  - **Ne:** Vaat cümlesi: “Bir kervanı kuşaklar boyu yolda tut. Her karar yola bir iz, her ölüm deftere bir satır olur.” Cümleyi `CLAUDE.md` başına, `docs/` altındaki tasarım belgesine ve Steam metni taslağına koy. Her yeni özellik bu cümleye karşı sınanır.
  - **Neden:** Vaadi olmayan oyun her öneriyi kabul eder ve dağılır; mağaza sayfasında his satılır.
  - **Kabul:** Vaat cümlesi CLAUDE.md'nin ilk bölümünde; kullanıcı son hâlini onayladı.
  - **Literatür:** R6, R60

</details>

### Y-A02 · Dört tasarım sütununu yazıya dök

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Görev şablonuna zorunlu 'Sütun' satırı eklendi.

<details><summary>Görev metni</summary>

- [ ] **Y-A02 Dört tasarım sütununu yazıya dök**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `7083b90`): Görev şablonuna zorunlu 'Sütun' satırı eklendi.
  - **Öncelik:** P1 · **Dalga:** 1 · **İlgili:** 6.3
  - **Ne:** Yol yaşar · İnsanlar aşınır · Defter unutmaz · Ticaret bilgi oyunudur. CLAUDE.md'nin başına “Sütunlar” bölümü olarak eklensin; her yeni sistem en az birine hizmet ettiğini belirtsin. Kullanıcının “derinleşme, asla sadeleştirme” ilkesi sütunların üstünde durur.
  - **Kabul:** Sütunlar CLAUDE.md'de; yeni görev şablonunda “hangi sütun” satırı var.
  - **Literatür:** R6, R10

</details>

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

### Y-F11 · CLAUDE.md'yi kayıpsız incelt

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 243 satır (CityView ve eski menü arka planı tarihçesi) arşive taşındı; dersler iki maddede kaldı.

<details><summary>Görev metni</summary>

- [ ] **Y-F11 CLAUDE.md'yi kayıpsız incelt**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `7083b90`): 243 satır (CityView ve eski menü arka planı tarihçesi) arşive taşındı; dersler iki maddede kaldı.
  - **Öncelik:** P2 · **Dalga:** 1 · **İlgili:** 6.3
  - **Ne:** Kullanıcı notu: mevcut olmayan ve eski ayrıntılar kaldırılabilir, mevcut sistem daha sade ve öz anlatılabilir, ama bilgi kaybı olmamalı. Çıkarılan her bölüm `docs/arsiv/` altına taşınır.
  - **Kullanıcı notu:** “mevcut olmayan, eski detaylar kaldırılabilir ya da mevcut sistem daha sade ve öz bir şekilde açıklanabilir ama kayıp yaşanmamalı burada.”
  - **Kabul:** CLAUDE.md kısaldı; çıkarılan metin arşivde; hiçbir geçerli kural kaybolmadı (fark listesi kullanıcıya sunuldu).

</details>

### Y-J13 · Yerelleştirme sırası ve terim sözlüğü

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Çeviri sırası ve 50 terimlik sözlük.

<details><summary>Görev metni</summary>

- [ ] **Y-J13 Yerelleştirme sırası ve terim sözlüğü**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `7083b90`): Çeviri sırası ve 50 terimlik sözlük.
  - **Öncelik:** P2 · **Dalga:** 5
  - **Ne:** Önce İngilizce ve Türkçe, sonra Basitleştirilmiş Çince, Almanca, Rusça. Metin hacmi büyümeden terim sözlüğü.
  - **Kabul:** Terim sözlüğü; çeviri sırası belgede.
  - **Literatür:** R39

</details>

## Paket P04

### 12.2c · Kamp: karakterler ateşe çok yavaş yürüyor (3x'te bile); ateşe varana kadar sabah oluyor; ateş ilk varan kişiyle yansın

- **Durum:** test bekliyor · **Öncelik:** P0 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** Ateş sesi (tutuşma + çıtırtı döngüsü, prosedürel) eklendi; ekranda ve kulakla doğrulanacak.

<details><summary>Görev metni</summary>

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

</details>

### 12.2b · Yol üstündeki kule (durak), kamp kurulduktan sonra kadrajdan bir anda kaçıyor

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** Kod ve test önceki turda; gözle doğrulanacak.

<details><summary>Görev metni</summary>

- [ ] **12.2b Yol üstündeki kule (durak), kamp kurulduktan sonra kadrajdan bir anda kaçıyor.**
    - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `0b5e4b6`): Kod ve test önceki turda; gözle doğrulanacak.
    - **Gözlem (kullanıcı):** Yolda giderken karşıya bir kule çıkıyor; kamp kuruluyor; ardından kule bir anda kadrajdan kayboluyor.
    - **Yer:** Durak çizimi `travel_band.gd:951-1006` (`STOP_SPRITES`, karakol kulesi `:993-1006`).
    - **Olası sebep:** Kamp kurulunca `_layout()` ya da bant kayması yeniden hesaplanıyor (kamp yerleşimi, `road_caravan.gd` `_refresh_gather_targets()` notu), ya da duraklar yolun "önündeki boş alana" göre yerleştirildiği için kamp konumu değişince durak çapası kayıyor.
    - **Çözüm:** Durağın dünya konumu, yol mesafesi cinsinden sabit olsun; kamp ve yeniden düzenleme onu kaydırmasın.
    - **Test:** Kampa girmeden önce ve sonra durağın ekran x'i aynı (ya da yalnızca kamera hareketi kadar farklı).

</details>

### 5.1 · `_process` döngülerinin gereksiz çalışmasını durdur

- **Durum:** test bekliyor · **Öncelik:** P3 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/05_performans.md](referans/gorevler/05_performans.md)
- **Son not:** Ortam animasyonları görünmezken çizilmiyor ve en çok 30 Hz; terazi dengede işlemeyi bırakıyor; kumanda ve geçiş elle denenecek.

<details><summary>Görev metni</summary>

- [ ] **5.1 `_process` döngülerinin gereksiz çalışmasını durdur**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `9d924e7`): Ortam animasyonları görünmezken çizilmiyor ve en çok 30 Hz; terazi dengede işlemeyi bırakıyor; kumanda ve geçiş elle denenecek.
  - `GamepadCursor` kumanda yokken çalışmasın (O-6).
  - `SceneInk` yalnız sahne geçişinde çalışsın (O-7).
  - `SurvivalGauge`, `AshFall`, `SmokeWisps`, `LanternGlow` ve `TradeScales` değer değişmezken yeniden çizmesin (O-8).

</details>

### Y-H04 · Hiçbir ekranda sıkışma kalmasın

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Paneller Esc'i ele alıyor; karar panelleri yutuyor; yapısal test eklendi.

<details><summary>Görev metni</summary>

- [ ] **Y-H04 Hiçbir ekranda sıkışma kalmasın**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `9c85ade`): Paneller Esc'i ele alıyor; karar panelleri yutuyor; yapısal test eklendi.
  - **Öncelik:** P1 · **Dalga:** 1
  - **Ne:** Her ekrandan Esc ile geri çıkış, sabit kısayollar, tutarlı geri düğmesi. Otomatik testle denetlenir.
  - **Kabul:** Her ekran için geri çıkış testi geçiyor.

</details>

## Paket P05

### 10.1 · Binici atın biraz fazla önünde oturuyor, çok az geriye alınmalı

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10_yol_figurleri.md](referans/gorevler/10_yol_figurleri.md)
- **Son not:** Binici at boyunun %5'i geride; iniş noktası aynı.

<details><summary>Görev metni</summary>

- [ ] **10.1 Binici atın biraz fazla önünde oturuyor, çok az geriye alınmalı.**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `ba76d99`): Binici at boyunun %5'i geride; iniş noktası aynı.
  - **Yer:** `scripts/ui/walk_figure.gd:460-470` (`KIND_MOUNTED`).
    - Atın sırt y'si `_draw_quadruped()` içinden geliyor.
    - Biniciyi çizen `_draw_person(height * MOUNT_RIDER_RATIO, back_y, true)` ise yatayda figürün ortasında (`origin.x = size.x * 0.5`, `:578`) duruyor.
  - **Çözüm:** Atın eğer noktasına (sırtın orta-arka kısmı) göre küçük bir geri kaydırma ekle, örneğin `MOUNT_SEAT_BACK_RATIO`.
    - Gidiş yönüne göre işareti değişmeli: sola giderken sağa, sağa giderken sola.
    - At dönüşte aynalanıyorsa binici de aynalanmalı.
  - **Test:** Eğer noktası ile kalça arasındaki mesafe için `tests/` altına bir kontrol.

</details>

### 10.2 · At üstündeki binici yürür gibi kol sallamaya devam ediyor

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10_yol_figurleri.md](referans/gorevler/10_yol_figurleri.md)
- **Son not:** Oturan figürde kol salınımı yok; ride klibi dinlenme karesinde.

<details><summary>Görev metni</summary>

- [ ] **10.2 At üstündeki binici yürür gibi kol sallamaya devam ediyor.**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `ba76d99`): Oturan figürde kol salınımı yok; ride klibi dinlenme karesinde.
  - **Yer:** `walk_figure.gd:256-276` (`pick_clip`). `seated` olduğunda yalnız `available.has("ride")` ise `ride` klibi seçiliyor; yoksa `walk` klibine düşüyor ve kollar sallanıyor.
  - **Olası sebep:** `shared_clips(frames, garments)` biniciyle birlikte giyilen kıyafetlerin kesişimini alıyor. Giyilen kıyafetlerden birinin frame setinde `ride` klibi yoksa ortak listeden düşüyor.
  - **Çözüm:**
    1. Hangi kıyafet ve beden setlerinde `ride` eksik, tara (`data/assets/characters/frames/*/frames.tres` içindeki `clip_names`).
    2. Eksik setleri `ride` ile yeniden render et (figür hattı: `tools/figure_pipeline/`).
    3. Kod tarafında `seated` iken asla `walk` seçilmesin; `ride` yoksa sabit bir oturma karesine düşülsün.
  - **Test:** `seated=true` için `pick_clip` hiçbir giysi kombinasyonunda `walk*` dönmemeli.

</details>

### 10.4 · Vagonu çeken hayvanlar vagona bağlı görünmüyor

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10_yol_figurleri.md](referans/gorevler/10_yol_figurleri.md)
- **Son not:** Ok öküzün boynuna uzanıyor, boyunduruk üst katmanda.

<details><summary>Görev metni</summary>

- [ ] **10.4 Vagonu çeken hayvanlar vagona bağlı görünmüyor.**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `ba76d99`): Ok öküzün boynuna uzanıyor, boyunduruk üst katmanda.
  - **Yer:**
    - `scripts/ui/road_caravan.gd:1352-1373`: `HITCH_GAP`, "Öküzle vagonun arasına hiçbir şey girmez, orası koşum yeri".
    - `:249-263`: öküz ölçüsü ve `CART_HITCH_M = WagonFigure.CART_HITCH_M`.
    - `scripts/ui/wagon_figure.gd`
  - **Çözüm:** Hayvanla vagon arasına görünür koşum çiz:
    - vagondan hayvanın göğsüne uzanan ok (dingil),
    - öküzde boyunduruk, atta ve eşekte göğüslük ile kayış.
  - **Hizalama:** Kayış uçları hayvanın omuz eklemine ve vagonun ön dingiline bağlanmalı, rig eklemlerinden okunarak (`BeastRig`, `shoulder_px`). Böylece yürüyüşte, dönüşte ve eğimde kopmaz.
  - **Not:** Dönüşte (`_wagon_turn`) hayvan ile vagonun ayrı aynalandığı yerler kontrol edilmeli.

</details>

### Y-G15 · Vagon ve kurt tek kaynaktan

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Savaş kurdu kartın rengine çekildi; vagon zaten tek kaynak.

<details><summary>Görev metni</summary>

- [ ] **Y-G15 Vagon ve kurt tek kaynaktan**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8b303d0`): Savaş kurdu kartın rengine çekildi; vagon zaten tek kaynak.
  - **Öncelik:** P2 · **Dalga:** 6
  - **Ne:** Menü, yol, kamp, kapı ve harita işaretinde aynı vagon render'ı; olay kartındaki kurtla savaş kurdu aynı renk ve konturda.
  - **Kabul:** Varlık kaynakları tekilleşti.

</details>

### 5.2 · Mipmap'leri içe aktarma ayarıyla üret

- **Durum:** test bekliyor · **Öncelik:** P3 · **Paket:** P05 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/05_performans.md](referans/gorevler/05_performans.md)
- **Son not:** 2026-10-20: project.godot [importer_defaults] texture mipmaps; içe aktarılmış dokuda çalışma anı kopyası yok; yerel 1537 .import çevrildi ve yeniden içe aktarıldı (596 -> 855 MB önbellek). Commit bd9e560.

<details><summary>Görev metni</summary>

- [ ] **5.2 Mipmap'leri içe aktarma ayarıyla üret** (O-4)
  - Çalışma anındaki `_with_mipmaps` kopyalamasını kaldır.
  - Ayar tüm projeye mi, belirli klasörlere mi uygulanacak, kullanıcıya sor (§7 madde 10).

</details>

### 5.3 · `BodyFrames` önbelleğine çıkarma politikası ekle

- **Durum:** test bekliyor · **Öncelik:** P3 · **Paket:** P05 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/05_performans.md](referans/gorevler/05_performans.md)
- **Son not:** LRU çıkarma (96 küme) ve ölçüm raporu.

<details><summary>Görev metni</summary>

- [ ] **5.3 `BodyFrames` önbelleğine çıkarma politikası ekle** (O-9). Önce bellek kullanımını ölç.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `9534722`): LRU çıkarma (96 küme) ve ölçüm raporu.

</details>

## Paket P06

### 8.7 · Boğaza ad ver

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P06 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Son not:** Ad Drazvor Boğazı; GeoJSON ve geo_export güncel. Haritadaki yazı karolara basılı: patch_labels.py ile karolara yeniden basılmadı, oyunda eski ad görünüyor. | 2026-10-20 düzeltme: "oyunda eski ad görünüyor" notu yanlıştı - boğazın adı karolara hiç basılmamış; haritada hiçbir su adı (deniz, koy) yazılı değil. Ad verisi (GeoJSON) Drazvor Boğazı. Tek başına bir su etiketi basılmadı (tutarsız olurdu ve hale kâğıt rengine göre çiziliyor).

<details><summary>Görev metni</summary>

- [ ] **8.7 Boğaza ad ver.** GeoJSON'da geçici olarak "Kesgrav Boğazı" yazıyor. İsim kuralına uygun bir ad kullanıcıya sorulsun.

</details>

### 8.5 · Yazı ile yolun çakışmasını gider

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Son not:** 126 etikete opak kâğıt halesi, yazı IM FELL; 161+85 karo yeniden yazıldı.

<details><summary>Görev metni</summary>

- [ ] **8.5 Yazı ile yolun çakışmasını gider.** Bazı kent adlarının altından yol geçiyor (örnek: Vastrevar). Yazının arkasına kâğıt renginde bir halo ya da maske ekle; `_text()` ve `_road_raster()` sırası.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `c59fb3a`): 126 etikete opak kâğıt halesi, yazı IM FELL; 161+85 karo yeniden yazıldı.

</details>

### Y-B13 · Aynı rotada farklı yol: mevsim ve kestirmeler

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C01
- **Son not:** İlkbahar su basar, yaz kurutur, kış dağı yavaşlatır; kestirme -%20 gün, orta üçte bir dağ/orman, tehlike +15 (boş pay); test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B13 Aynı rotada farklı yol: mevsim ve kestirmeler**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `824187d`): İlkbahar su basar, yaz kurutur, kış dağı yavaşlatır; kestirme -%20 gün, orta üçte bir dağ/orman, tehlike +15 (boş pay); test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** Y-C01
  - **Ne:** Rota tohumu mevsime ve dünya olayına göre değişir; riskli kestirmeler ve alternatif patikalar eklenir. Harita aktarımıyla (Y-C01) birlikte yapılır.
  - **Kabul:** Aynı rota iki farklı mevsimde farklı arazi veriyor; kestirme seçimi planlayıcıda.
  - **Literatür:** R15

</details>

### Y-F10 · Tehlikenin dökümünü göster

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Planlayıcıda taban, yol durumu, dünya olayı, zamanla büyüme; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-F10 Tehlikenin dökümünü göster**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `cefadb6`): Planlayıcıda taban, yol durumu, dünya olayı, zamanla büyüme; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 2
  - **Ne:** Planlayıcıda tehlike yüzdesinin kaynakları: taban, zamanla büyüme, rota durumu, hava, dünya olayı, duman.
  - **Kabul:** Döküm ekranda; değerler motorla birebir.
  - **Literatür:** R1, R4

</details>

### 8.10 · Harita saate göre kararıp aydınlansın (gündüz, akşam, gece)

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Son not:** Çarpan ton katmanı, kararma eğrisi yolun gökyüzüyle aynı; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **8.10 Harita saate göre kararıp aydınlansın (gündüz, akşam, gece).** Kullanıcı isteği, 2026-10-17.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4eca777`): Çarpan ton katmanı, kararma eğrisi yolun gökyüzüyle aynı; test TEST_PLANI.md'de.
  - **Kaynak:** Oyun saati `JourneyClock`'tan; şehirde de günün saati.
  - **Tonlar:** Harita dokusunun üstüne tek bir renk ve parlaklık katmanı:
    - Gündüz: doğal.
    - Akşam: sıcak, hafif koyu (≈ %85 parlaklık).
    - Gece: soğuk mavi-gri, koyu (≈ %60 parlaklık).
  - Geçişler yumuşak olacak, dakikalar içinde lerp.
  - **Kural: harita hiçbir zaman okunamayacak kadar kararmamalı.**
    - Gecede bile yazılar, yollar ve kıyılar okunur kalacak.
    - Kabul kriteri: en karanlık tonda mürekkep ile kâğıt arasındaki kontrast oranı ≥ 4.5:1. Yazılar için gerekirse ayrı ve daha az kararan bir katman.
  - **Görüntüleyici:** `../harita_final/goruntuleyici` aynı kuralı bir CSS ya da canvas katmanıyla deneyebilir.

</details>

### 8.11 · Şehirlerde ve yerleşimlerde küçük ışıklar; akşam ve gece hafifçe parıldasın

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Bağımlı:** 8.10
- **Son not:** 250 ışık, türe göre (şehir 6-12, kasaba 3-5, köy 1-2, harabe yok); test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **8.11 Şehirlerde ve yerleşimlerde küçük ışıklar; akşam ve gece hafifçe parıldasın.** Kullanıcı isteği, 2026-10-17.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4eca777`): 250 ışık, türe göre (şehir 6-12, kasaba 3-5, köy 1-2, harabe yok); test TEST_PLANI.md'de.
  - **Görünüm:** İşaretteki fenerin ışıltısıyla aynı dil (`../belgeler/ATLI_ISARET.md`): küçük sıcak sarı noktalar ve saydam hale.
  - **Konumlar:** `wayborne_harita.geojson` içindeki `yerleşim` noktaları. Işık sayısı ve dağılımı sınıfa göre:
    - kent: 6–12 ışık, kentin şekli içinde dağınık,
    - kasaba: 3–5,
    - köy ve kamp: 1–2,
    - harabe ve işaret: yok.
  - **Zamanlama:**
    - Gündüz görünmez.
    - Akşam yavaşça yanar.
    - Gece en parlak hâlinde; her ışık farklı fazda, düşük genlikli ve yavaş titreşir (mum gibi; hızlı yanıp sönme değil).
  - **Teknik:** Harita karolarına yakılmaz, ayrı bir katman olarak çizilir; zoom'da boyutları sabit ekran pikselinde kalır. Tek bir shader ya da çok noktalı bir `MultiMeshInstance2D` yeterli.
  - **Not:** Kervanın fener ışıltısı ile şehir ışıkları gece aynı ışık dilini paylaşmalı.

</details>

### Y-G09 · Haritada kervanın mürekkep izi

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P06 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** 8.1, 8.2
- **Son not:** GameSession.map_trail/journey_camps kayıtta; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-G09 Haritada kervanın mürekkep izi**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4eca777`): GameSession.map_trail/journey_camps kayıtta; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 6 · **Bağımlı:** 8.1, 8.2 · **İlgili:** 8.10, 8.11
  - **Ne:** Kervanın geçtiği yol haritaya mürekkeple çizilir ve kalır; kamp yerleri küçük ateş işareti. Renk yok.
  - **Kabul:** İz kayıtta; haritada görünüyor.
  - **Kaynaklar ve teknik (CC0 araştırması):** Harita süsleri için hat tekniği referansı: Carta Marina (Wikimedia, PD Mark): dalga taraması, gemi süsleri. Gerçek yer adları ve kıyılar alınmaz. David Rumsey koleksiyonu kullanılmaz (NC).
  - **Literatür:** R11

</details>

## Paket P07

### Y-C10 · Fiyat defteri: bilgi eskir, söylenti yanıltır

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Varışta görülen fiyat yazılır, 20 günden eski soluk; söylenti 2-6 gün eski ve yüzde 25 yanlış; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C10 Fiyat defteri: bilgi eskir, söylenti yanıltır**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `abc9d82`): Varışta görülen fiyat yazılır, 20 günden eski soluk; söylenti 2-6 gün eski ve yüzde 25 yanlış; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 2
  - **Ne:** Görülen fiyatlar tarihli olarak deftere yazılır ve eskir. Taverna dedikodusu başka şehrin fiyatını satar; bazen yanlıştır.
  - **Kabul:** Fiyat defteri ekranı; eskime ve yanlış söylenti testli.
  - **Literatür:** R9, R16

</details>

### Y-C11 · Gizli fiyat katmanlarını görünür kıl

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Satırda kısa etiketler, üstüne gelince katman başına bir cümle; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C11 Gizli fiyat katmanlarını görünür kıl**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `6014abe`): Satırda kısa etiketler, üstüne gelince katman başına bir cümle; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 2
  - **Ne:** Mal satırında mevsim, enflasyon, arz baskısı ve dünya olayı işaretleri; üzerine gelince açıklama (Y-H03'e uygun, edebi dil).
  - **Kabul:** Yedi katmanın her biri ekranda bir işaretle görünüyor.
  - **Literatür:** R1, R4

</details>

### Y-C19 · Mal çeşitliliği: bozulan, kaçak, nadir

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C01
- **Son not:** Al-sat sömürüsü (kendi alımının şişirdiği fiyata geri satış) %90 tavanla kapandı; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C19 Mal çeşitliliği: bozulan, kaçak, nadir**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `9b79738`): Al-sat sömürüsü (kendi alımının şişirdiği fiyata geri satış) %90 tavanla kapandı; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C01
  - **Ne:** Balık ve meyve bozulur; kaçak mal yüksek kâr ve muhafız riski; nadir mal yalnızca özel alıcıya; toplu alım indirimi.
  - **Kabul:** Yeni mal türleri ve kuralları; sömürü testleri geçiyor.
  - **Literatür:** R16

</details>

### Y-B07 · Sofrayı anlamlı karar yap: erzak türleri

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Erzak payı ve planlayıcı sözü değişmedi; çeşni yalnız sofra açıkken; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B07 Sofrayı anlamlı karar yap: erzak türleri**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `05ce4d8`): Erzak payı ve planlayıcı sözü değişmedi; çeşni yalnız sofra açıkken; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3 · **İlgili:** Y-C19
  - **Ne:** Ekmek, kuru et, tahıl ve şarap gibi erzak türleri farklı etkiler verir (takat, moral, bozulma). Bolluk varken de ara sıra ziyafet akşamı seçimi gelir. Kalıcı emir korunur; sofra yalnızca gerçek bir seçim varken sorulur.
  - **Kabul:** Erzak türleri ekonomi ve sofrada; kalıcı emirle günlük akış bozulmuyor.
  - **Literatür:** R16

</details>

### Y-B06 · Yolda erzak kaynağı: av, toplama, köy

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Av 10 erzak; köy 5 ve 4.7 altın/erzak (şehir 4); toplama +10 erzak, +1 gün; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B06 Yolda erzak kaynağı: av, toplama, köy**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `fa60be3`): Av 10 erzak; köy 5 ve 4.7 altın/erzak (şehir 4); toplama +10 erzak, +1 gün; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 3
  - **Ne:** Av savaşı erzak getirir; köy durağında erzak alınabilir; toplayıcılık zaman kaybettirir.
  - **Kabul:** Av zaferi erzak ekliyor; köy durağında erzak alımı var; testler var.
  - **Literatür:** R51, R17

</details>

### Y-C02 · Dinamik kontratlar ve yeni kontrat ekranı

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P07 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C01
- **Son not:** Lonca görevleri statik kaldı; teslimatta tüccar yolda yok (tüccar diyaloğu bu kontratlarda anlamsız, onay paketinde not); test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C02 Dinamik kontratlar ve yeni kontrat ekranı**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `2bc6802`): Lonca görevleri statik kaldı; teslimatta tüccar yolda yok (tüccar diyaloğu bu kontratlarda anlamsız, onay paketinde not); test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 2 · **Bağımlı:** Y-C01
  - **Ne:** Kontrat türleri: eşlik, süre baskılı kargo, yolcu taşıma, av ya da kurtarma, kaçak yük. Kullanıcı notları: (1) Kontrat menüsü değişir: ilan panosu ya da arka planda lonca masası ve kenarda kontrat listesi. (2) Tüccar kendi vagonuyla gelmeyebilir; yalnızca kendisi ve malıyla gelirse ücrete vagon kirası eklenir. (3) En sık tür: “malımı X yerine teslim et” (tüccar gelmez). Pano her varışta tohumdan yeniden üretilir.
  - **Kullanıcı notu:** “Kesinlikle çok dinmaik olmalı burası hatta kontrat menüsü de değişmeli. witcher^'daki gibi bir ilan panosu olabilir ya da bir masa arkasında lonca görevlerisi görebiliriz arkaplanda ve kenarda listelenir bu kontratlar. / Ayrıca her kontrat tipinde tüccar bizzat kendi vagonu ile gelmeyebilir, vagonsuz, malları ve kendisi gelmek isteyebilir ve bu durumda ücrete vagon kirası dahil olur. Bunun dışında benden sadece malını x lokasyonuna teslim etmemi de isteyebilir ki çoğunlukla durum bu olmalı bence.”
  - **Kabul:** En az 5 tür; teslimat türü en sık çıkıyor; vagon kirası hesabı testli; yeni ekran taslağı kullanıcı onayından geçti.
  - **Literatür:** R15, R16

</details>

### Y-F05 · Tüccar mizacını yola bağla

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C02
- **Son not:** Hırsız kaçar, çaresiz tehlikede döner, kinci kavga çıkarır, sadık erzak paylaşır; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-F05 Tüccar mizacını yola bağla**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `ee5ea65`): Hırsız kaçar, çaresiz tehlikede döner, kinci kavga çıkarır, sadık erzak paylaşır; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** Y-C02
  - **Ne:** Diyalogla öğrenilen mizaç yolda karşılık bulur: hırsız tüccar gece kaçar, korkak tüccar ilk tehlikede geri döner.
  - **Kabul:** Her mizacın en az bir yol olayı var.
  - **Literatür:** R16

</details>

## Paket P08

### R0 · Altyapı

- **Durum:** test bekliyor · **Öncelik:** Öneri · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/10b_yol_deneyimi_onerileri.md](referans/gorevler/10b_yol_deneyimi_onerileri.md)
- **Bağımlı:** 11.1
- **Son not:** Figür-kişi eşlemesi, RoadBalloon, RoadChatter, backstory/rapport, beş yeni defter türü; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **R0 Altyapı:** figür→karakter eşlemesi, `RoadBalloon`, `RoadChatter`, `backstory_id` ve `rapport`, yeni ledger türleri, `GameSession` alanları, yeni `EventEffect` türleri. Ön koşul: `RoadSignals` kaydı eksik (bkz. belge §10 madde 3).
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8d435e1`): Figür-kişi eşlemesi, RoadBalloon, RoadChatter, backstory/rapport, beş yeni defter türü; test TEST_PLANI.md'de.

</details>

### Y-B01 · Yol önerilerini (R0–R1) ana iş olarak uygula

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** 11.1
- **Son not:** R0 ve R1 kodda; R1 görsel onayı ONAY_PAKETI'nde.

<details><summary>Görev metni</summary>

- [ ] **Y-B01 Yol önerilerini (R0–R1) ana iş olarak uygula**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `dd0d737`): R0 ve R1 kodda; R1 görsel onayı ONAY_PAKETI'nde.
  - **Öncelik:** P1 · **Dalga:** 3 · **Bağımlı:** 11.1 · **İlgili:** R0, R1
  - **Ne:** §10b R0 (altyapı) ve R1 (insanlar: baloncuklar, yakınlık, prosedürel mezar) “öneri” statüsünden çıkar, uygulanır. Sıralama teknik önceliğe göre: önce 11.1, sonra R0, sonra R1.
  - **Kullanıcı notu:** “İşlerin sırası tamamen teknik önceliklere dayanarak yapılacak zira bu işlerin hepsini claude'un 2-3 session'da yapmasını bekliyorum zaten.”
  - **Kabul:** R0 ve R1'in §10b'deki kabul ölçütleri sağlandı; testler geçti.
  - **Literatür:** R11, R12, R22

</details>

### R1 · İnsanlar

- **Durum:** test bekliyor · **Öncelik:** Öneri · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10b_yol_deneyimi_onerileri.md](referans/gorevler/10b_yol_deneyimi_onerileri.md)
- **Bağımlı:** R0
- **Son not:** 15 hikâye (5 geçmiş x 3 bölüm) tr/en; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **R1 İnsanlar:** #1 yanına yürü ve konuş, #3 kamp ateşi hikâyesi, #2 bağlar ve yan yana yürüme, #4 yoldaşların görünür özerk eylemleri.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `dd0d737`): 15 hikâye (5 geçmiş x 3 bölüm) tr/en; test TEST_PLANI.md'de.

</details>

### Y-C17 · Yoldaşın kendi hikâyesi ve ilişkileri

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-B01
- **Son not:** Geçmiş ve hedef her yoldaşta, üç kartlık kişisel zincir kamp hikâyesi olarak, bağ kayıtta; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C17 Yoldaşın kendi hikâyesi ve ilişkileri**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `dd0d737`): Geçmiş ve hedef her yoldaşta, üç kartlık kişisel zincir kamp hikâyesi olarak, bağ kayıtta; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4 · **Bağımlı:** Y-B01 · **İlgili:** R0, R1
  - **Ne:** Geçmiş, kişisel hedef, 2–3 kartlık kişisel zincir; yoldaşlar arası dostluk ve husumet.
  - **Kabul:** Her yoldaşta geçmiş ve hedef; kişisel zincirler; ilişki değeri kayıtta.
  - **Literatür:** R11, R25

</details>

### Y-B03 · İşaretleri bulmacaya çevir: belirsizlik ve bedel

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** 11.1
- **Son not:** Dört tür x 2-3 gerçek; gerçek kayıtta; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B03 İşaretleri bulmacaya çevir: belirsizlik ve bedel**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `e87e40e`): Dört tür x 2-3 gerçek; gerçek kayıtta; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 3 · **Bağımlı:** 11.1 · **İlgili:** R2
  - **Ne:** İşaretler belirsiz olur (duman köy yangını da olabilir, haydut kampı da). İşarete yürümek bilgi verir ama öbür bölge açık kalır. Aynı anda iki işaret çıkabilir. Kehanet (omen) türü buraya bağlanır.
  - **Kabul:** İşaret türünü görmek çözümü belirlemiyor; kayıt ve yüklemede belirsizlik durumu korunuyor.
  - **Literatür:** R16, R9

</details>

### Y-F09 · Görevler: öncü, ortancı, artçı; sınıflar ayrı

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Tasarım notu docs/design_notes/gorev_rolleri.md; eski kayıt göçü; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-F09 Görevler: öncü, ortancı, artçı; sınıflar ayrı**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `40276b9`): Tasarım notu docs/design_notes/gorev_rolleri.md; eski kayıt göçü; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 4 · **İlgili:** Y-B04, Y-B12
  - **Ne:** Kullanıcı notu: görevler üçe indirilir (öncü, ortancı, artçı) ve iş kapsamları bu üçüne dağılır. Sınıflar görevden tamamen bağımsız olur (kolcu, savaşçı, kâtip gibi, masaüstü RPG usulü). Mevcut 6 görevin etkileri üç göreve ve gerekiyorsa sınıflara dağıtılır; kayıp olmaz. Y-B04 ve Y-B12 ile birlikte tasarlanır.
  - **Kullanıcı notu:** “Görevleri sadeleştirebiliriz, sadece öncü, artçı, ve ortancı gibi görevler olabilir, iş kapsamları da bu üçüne göre dağılabilir. sınıflar ise tamamen bu görevlerden bağımsız olabilir kolcu, savaşçı, katip vs gibi bira dnd usulü.”
  - **Kabul:** Onaylı tasarım notu; eski kayıtlar yeni görevlere göç ediyor; testler.
  - **Literatür:** R16

</details>

### Y-B04 · Dikkat bölgelerine yeri doldurulamaz roller ver

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Rol sahibi kendi bölgesinde saatlik %3.5 x güç; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B04 Dikkat bölgelerine yeri doldurulamaz roller ver**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `40276b9`): Rol sahibi kendi bölgesinde saatlik %3.5 x güç; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 3 · **İlgili:** Y-F09
  - **Ne:** Ön: izci bilgisi ve erken uyarı. Vagonlar: kırılmayı önceden görür, yükü korur. Arka: geride kalanı yakalar, takip edeni fark eder. Her rolün sonucu ekranda görünür. Y-F09'daki öncü, ortancı ve artçı görevleriyle birlikte tasarlanır.
  - **Kullanıcı notu:** “Mantıklı, tamamdır.”
  - **Kabul:** Simülatörde “hep önde dur” stratejisi diğerlerinden belirgin biçimde üstün değil.
  - **Literatür:** R16, R21

</details>

### Y-B12 · Kampı karar anına çevir; ertesi günün dizilişi

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** 12.2c
- **Son not:** Öncü +1 stres/gün; nöbet ertesi günün tehlikesini düşürür; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B12 Kampı karar anına çevir; ertesi günün dizilişi**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `40276b9`): Öncü +1 stres/gün; nöbet ertesi günün tehlikesini düşürür; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 3 · **Bağımlı:** 12.2c · **İlgili:** Y-B04, Y-F09
  - **Ne:** Akşam 2–3 eylem: nöbet sırası, yaralıyı sarmak, hikâye anlatmak (stres), tamir, av hazırlığı. Kullanıcı notu: ertesi gün kimin önde, ortada, arkada gideceği de kampta seçilir; önde olmanın karaktere bir bedeli vardır ve bu bedel yüzünden kişi gece arkaya alınabilir.
  - **Kullanıcı notu:** “Evet, saydıklarına ek olarak sonraki gün kim önde, arkada, ortada gidecek buna da karar verilebilir burada zira önde olmanın maliyeti olabilir o karaktere ve bu maliyet sonucu arkaya almak isteyebiliriz gece.”
  - **Kabul:** Kamp eylem paneli; diziliş seçimi ve önde gitmenin bedeli testli.
  - **Literatür:** R22

</details>

### Y-B02 · Yol yönetmeni: gerilimi kervanın durumuna göre ayarla

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Sessizlik ihtimali artırır, ağır karttan sonra rahatlama, zorda ağır kart seyrek; gece işaret x1.5, ateş/nöbet/ışık önler; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B02 Yol yönetmeni: gerilimi kervanın durumuna göre ayarla**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `c330b93`): Sessizlik ihtimali artırır, ağır karttan sonra rahatlama, zorda ağır kart seyrek; gece işaret x1.5, ateş/nöbet/ışık önler; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 3 · **İlgili:** Y-B12, Y-C20
  - **Ne:** Olay ve işaret seçimi stres, açlık, borç ve son olayların sertliğine bakan bir yönetmenden geçer: gerilim → zirve → rahatlama eğrisi. `EventEngine` ağırlık kancası kullanılır. Kullanıcı notu: akşam ve gece olasılık artar; önlem alınmışsa (nöbet, ateş, fener ya da meşale, kamp yeri seçimi) artış düşer.
  - **Kullanıcı notu:** “Çok mantıklı! ayrıca akşamları da bu olasılık artmalı gerekli önlemler alınmazsa.”
  - **Kabul:** Simülatörde yönetmen açıkken üç sessiz gün üst üste gelme oranı ve art arda iki ağır kart oranı ölçülüp raporlanır; gece önlem alınınca olay oranı düşer.
  - **Literatür:** R18, R19, R77

</details>

### Y-B05 · Havaya karşı küçük kararlar

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Beş hava, yedi karar; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B05 Havaya karşı küçük kararlar**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `f92a1cc`): Beş hava, yedi karar; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3
  - **Ne:** Fırtınada sığın, bekle ya da devam et; siste yavaşla ya da fener yak; yağmurda çamurlu kestirme ya da uzun yol. Kart değil, tek tıklık kararlar.
  - **Kabul:** Her hava türü için en az bir karar; açık hava artık tamamen nötr değil.
  - **Literatür:** R16

</details>

### Y-C20 · Fener ya da meşaleyle gece yürüyüşü

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Karanlıkta ışıksız yürüyüş takat ve tehlike bedeli; fener 1 yağ/gece, meşale 2/gece; CC0 fener/meşale modeli ve sesi sonraki tur; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C20 Fener ya da meşaleyle gece yürüyüşü**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `f92a1cc`): Karanlıkta ışıksız yürüyüş takat ve tehlike bedeli; fener 1 yağ/gece, meşale 2/gece; CC0 fener/meşale modeli ve sesi sonraki tur; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3 · **İlgili:** Y-B02, Y-G08, 8.10
  - **Ne:** Gece fener ya da meşaleyle yürümek: süre kazancı karşılığında tehlike ve takat bedeli. Kullanıcı notu: meşale fenerin alternatifi; fener varsa oyuncu fener de yakabilir, seçim oyuncunun. Fener yağı ve meşale sarf malzemesidir.
  - **Kullanıcı notu:** “meşale de olabilri fener alternatifi olarak, isterse fener de yakar varsa. oyuncuya bağlı olsun yani.”
  - **Kabul:** Gece yürüyüşü eylemi; fener ve meşale farkı; görsel ışık kaynağı yolda görünüyor.
  - **Kaynaklar ve teknik (CC0 araştırması):** Fener: Poly Haven `Lantern_01`; meşale: Kenney Survival Kit (CC0). Ses: Freesound CC0 `torch ignite`, `match strike`, `lantern creak`.
  - **Literatür:** R16

</details>

### Y-B10 · Başka kervanlarla karşılaşma

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Askerî konvoy (borç ve arama), mülteci (minnet ve yoldaş), hacı (mevcut zincir), rakip tüccar (bilgi satın al, iftira); test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B10 Başka kervanlarla karşılaşma**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `b8ba074`): Askerî konvoy (borç ve arama), mülteci (minnet ve yoldaş), hacı (mevcut zincir), rakip tüccar (bilgi satın al, iftira); test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3
  - **Ne:** Askerî konvoy, mülteci kafilesi, hacı kafilesi, rakip tüccar. Yolda uzaktan görünür; takas, bilgi, yolcu ya da çatışma sunar.
  - **Kabul:** En az 4 kervan türü; her biri yolda görünür ve kendi kart zinciri var.
  - **Literatür:** R11

</details>

### Y-B11 · Yolun hafızası: mezarlar, enkaz, eski kül

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Prosedürel çizim (CC0 model sonraki tur); test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B11 Yolun hafızası: mezarlar, enkaz, eski kül**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `a31c52c`): Prosedürel çizim (CC0 model sonraki tur); test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3 · **İlgili:** R1
  - **Ne:** Ölenin mezarı, kırılan vagonun enkazı, önceki kampın külü aynı yolda kalır ve kayda yazılır. İkinci geçişte yol farklı görünür.
  - **Kabul:** Ölüm ve kamp konumları kayıtta; aynı yoldan geçerken görünüyor.
  - **Kaynaklar ve teknik (CC0 araştırması):** Mezar ve enkaz modelleri: Kenney Graveyard Kit (CC0), Quaternius `Broken Cart`; dinî sembol yok; mürekkep geçişi.
  - **Literatür:** R11, R12

</details>

### Y-B08 · Günün satırı: akşam kampında defter cümlesi

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P08 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 2026-10-20: gün boyu izler (ölüm, vagon, savaş, açlık, hikâye, olay), akşam kampında en ağır izden üç edebi cümle, oyuncu birini seçer ya da yazmaz (DiaryPanel); defterin Düşenler sayfasında görünür. test_waybook_pages.

<details><summary>Görev metni</summary>

- [ ] **Y-B08 Günün satırı: akşam kampında defter cümlesi**
  - **Öncelik:** P1 · **Dalga:** 3 · **İlgili:** R3, Y-H03
  - **Ne:** Her akşam günün en önemli olayı tek bir cümleye dönüşür ve deftere yazılır; oyuncu düzeltebilir. Cümleler edebi, sayısız (bkz. Y-H03).
  - **Kabul:** Her kamp bir satır üretiyor; satırlar kayıtta; yerelleştirme anahtarları var.
  - **Literatür:** R12, R11

</details>

### R2 · Hafıza

- **Durum:** test bekliyor · **Öncelik:** Öneri · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10b_yol_deneyimi_onerileri.md](referans/gorevler/10b_yol_deneyimi_onerileri.md)
- **Bağımlı:** R0
- **Son not:** #7 günün cümlesi (Y-B08) kullanıcı kararı bekliyor (serbest metin mi); test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **R2 Hafıza:** #5 ölüler yolda kalır (mezarlar), #7 günün cümlesi, #6 dönüm taşı, #8 yol enkazları, #19 yol seni hatırlar.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `a31c52c`): #7 günün cümlesi (Y-B08) kullanıcı kararı bekliyor (serbest metin mi); test TEST_PLANI.md'de.

</details>

### R4 · Risk

- **Durum:** test bekliyor · **Öncelik:** Öneri · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/10b_yol_deneyimi_onerileri.md](referans/gorevler/10b_yol_deneyimi_onerileri.md)
- **Bağımlı:** R0
- **Son not:** #15 gece yürüyüşü Y-C20'de; #16 v1 kart ve günlük (görsel v2: vagonlar suya girer, sonraki tur); test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **R4 Risk:** #15 gece yürüyüşü, #16 nehir geçidi.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4d5f4ed`): #15 gece yürüyüşü Y-C20'de; #16 v1 kart ve günlük (görsel v2: vagonlar suya girer, sonraki tur); test TEST_PLANI.md'de.

</details>

### Y-B09 · Yolu dolu yap, sonra hızlandırmayı kaldır

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-B01, Y-B02, Y-B03
- **Son not:** Ölçüm hedefi tutmazsa SPEEDS tek satırla geri açılır; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-B09 Yolu dolu yap, sonra hızlandırmayı kaldır**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4017eda`): Ölçüm hedefi tutmazsa SPEEDS tek satırla geri açılır; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 3 · **Bağımlı:** Y-B01, Y-B02, Y-B03 · **İlgili:** 12.2c
  - **Ne:** Kullanıcı kararı: hızlandırma kalkmalı. Yol o kadar dolu ve seyri yüksek olmalı ki oyuncu hızlandırmak istememeli. Adımlar: (1) 1x hızda her 60–90 saniyede en az bir karar ya da bilgi hedefi koy ve simülatörle ölç; (2) B01–B13 ve R0–R5 bu hedefi sağlayınca 1.5x ve 3x hızları kaldır; duraklatma ve yavaşlatma kalır (erişilebilirlik için “olay gelince duraklat”, Y-H07).
  - **Kullanıcı notu:** “Aslına bakarsan hızlandırma kalkmalı. yolda olmak o kadar dolu bir eylem olmalı ki oyuncu oylu hızlandıramamalı, aynı zamanda da ortam o kadar dolu, yoğun, seyri yüksek olmalı ki hızlandırmak istememeli.”
  - **Kabul:** Ölçüm raporu hedefi gösteriyor; hız düğmeleri kaldırıldı; 12.2c'deki “3x'te bile yavaş” sorunu yürüme hızı düzeltilerek ayrıca çözüldü.
  - **Literatür:** R3, R4

</details>

## Paket P09

### Y-C07 · Savaştan bedelli geri çekilme

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Yük üçte bir, vagon feda (enkaz yolda), artçı darbe alır; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C07 Savaştan bedelli geri çekilme**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5f32931`): Yük üçte bir, vagon feda (enkaz yolda), artçı darbe alır; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4
  - **Ne:** Zorda kalınca kaçış mümkün: yük bırakmak, bir vagonu feda etmek ya da bir kişiyi artçı bırakmak.
  - **Kullanıcı notu:** “Zorda kalınılsa yapılabilmeli evet.”
  - **Kabul:** Geri çekilme eylemi ve bedelleri testli.
  - **Literatür:** R16, R17

</details>

### Y-C08 · Düşmanlara kişilik ver

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Reis lideri, kurt en yaralıyı (oran), muhafız Kıyı'dakini bitirmez; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C08 Düşmanlara kişilik ver**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5f32931`): Reis lideri, kurt en yaralıyı (oran), muhafız Kıyı'dakini bitirmez; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 4
  - **Ne:** Haydut reisi önce lideri hedefler, kurt sürüsü yaralıyı kovalar, muhafız teslim olmayı teklif eder, ayı kaçana saldırmaz.
  - **Kabul:** Düşman türü başına davranış profili; testler.
  - **Literatür:** R22

</details>

### Y-D06 · Kırılma: davranışla yaşatılan olay

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Dört kip son kötü huydan; ekran efekti yok; yol kartı; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-D06 Kırılma: davranışla yaşatılan olay**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5f32931`): Dört kip son kötü huydan; ekran efekti yok; yol kartı; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 4 · **İlgili:** 2.5
  - **Ne:** Kullanıcı notu: ekranda efekt ya da filtre değil, olay. Stres eşiği aşılınca karakter bir kırılma durumu kazanır ve davranışıyla gösterir: kendini öne atar, bütün hasarı üstüne çeker, emre uymaz ya da arkadaşına saldırır. Yolda kart, savaşta davranış olarak. Ekran efekti yok (2.5).
  - **Kullanıcı notu:** “Evet ama bu ekranda görülen bir efekt gibi değil, bir olay gibi olmalı. referans oyunda mesela stres eşiği aşıldığında bir treat kazanıyor ve saçma hareketlere girmeye başlıyor karakter. kendini öne atıyor, tüm damage'ı kendine çekiyor ya da takım arkadaşlarına saldırıyor vs. direkt yaşatarak gösteriyor olayı, ekrana ucuz bir filtre koyarak değil.”
  - **Kabul:** Kırılma durumları savaş yapay zekâsında ve yol kartlarında; ekran efekti yok; testler.
  - **Literatür:** R22

</details>

### Y-C03 · Ganimet: eşya, kıyafet, sarf, nadir bulgu

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Tablolar data/config/loot.json; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C03 Ganimet: eşya, kıyafet, sarf, nadir bulgu**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5d4018d`): Tablolar data/config/loot.json; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4
  - **Ne:** Savaş ve olaylardan eşya, kıyafet, iksir ve nadir bulgu düşer. `GRANT_OUTFIT` eklenir; kıyafet ganimete bağlanır.
  - **Kabul:** Zafer ekranında ganimet; ganimet tabloları veri dosyasında; testler.
  - **Literatür:** R79, R5

</details>

### Y-C04 · Sarf malzemesi ve yolda tedavi

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Sargı +8 can ve kanama, iksir +12 can ve Kıyı'da direnç +20; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C04 Sarf malzemesi ve yolda tedavi**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5d4018d`): Sargı +8 can ve kanama, iksir +12 can ve Kıyı'da direnç +20; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4 · **İlgili:** Y-F03
  - **Ne:** Bandaj, iksir ve merhem kampta ve savaşta kullanılır; Ölümün Kıyısı'nda direnç için de kullanılabilir.
  - **Kabul:** Bandaj artık tüketiliyor; savaşta ve kampta kullanım testli.
  - **Literatür:** R16

</details>

### Y-F03 · Atölye ve vagon envanterini anlamlandır

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C04
- **Son not:** Her tarifin tüketicisi RecipeCatalog.OUTPUT_USES'ta; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-F03 Atölye ve vagon envanterini anlamlandır**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5d4018d`): Her tarifin tüketicisi RecipeCatalog.OUTPUT_USES'ta; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4 · **Bağımlı:** Y-C04 · **İlgili:** Y-C20, Y-F04T
  - **Ne:** Gerçek üretim döngüsü: bandaj → tedavi, branda → tamir, av derisi → kıyafet, yağ → fener, meşale. Vagon başına envanter bu döngüye hizmet eder.
  - **Kabul:** Her tarifin oyunda bir tüketicisi var; testler.
  - **Literatür:** R16

</details>

### Y-F04T · Vagon atölyesi ekranını özelleştir

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-F03
- **Son not:** Mantık değişmedi, yalnızca ekran; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-F04T Vagon atölyesi ekranını özelleştir**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4d6fb67`): Mantık değişmedi, yalnızca ekran; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-F03
  - **Köken:** onaylanmayan **F04** önerisinin altındaki kullanıcı notu.
  - **Ne:** Kullanıcı notundan türetildi (hub'ı kaldırma önerisi reddedildi): şehir kapısı şehre girmek, vagona gitmek atölyeye gitmek demek. Hub kalır; asıl iş atölye ekranının vagona özgü, kendine ait bir ekran olması.
  - **Kullanıcı notu:** “şehir kapısına basmak şehre girmek demek. vagona gitmek ise oradaki atölyeye gitmek demek. asıl olması gereken şey vagon atölyesinin ekranını özelleştirmek.”
  - **Kabul:** Atölye ekranı taslağı onaylandı ve uygulandı.

</details>

### Y-C05 · Sakatlık, hastalık, hekim ve ilaç stoğu

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 5 dert; veba şehrinde varışta bulaşma; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C05 Sakatlık, hastalık, hekim ve ilaç stoğu**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `c4a5782`): 5 dert; veba şehrinde varışta bulaşma; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 4 · **İlgili:** Y-C19
  - **Ne:** Yarı kalıcı yaralar, vebayla bağlantılı salgın, şehirde hekim ve sınırlı ilaç stoğu. Kullanıcı notu: kervanın şehre getirdiği tedarik o şehrin ilaç ve ilgili stoklarını etkiler.
  - **Kullanıcı notu:** “Evet ve o zaman dediğim gibi, bizim bu şehre sağladığımız tedarik bu konudaki stokları da etkilemeli.”
  - **Kabul:** Sakatlık ve hastalık kayıtta; teslim edilen ilaç ve malzeme şehir stoğunu artırıyor.
  - **Literatür:** R30, R22

</details>

### Y-F01 · Moral ve takat: kervanın nefesi, ama takat bedende kalır

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** docs/design_notes/moral_ve_takat.md; kod onaydan sonra. | 2026-10-19 karar: not onaylandı; kod yazılacak. | 2026-10-20: kişi başına yorgunluk (0-100), kervanın takati en yorgun kişiye bağlı; normal tempo yavaşlamaz, yalnız hızlı tempo kilitlenir; savaşta küçük isabet/kaçınma cezası. test_fatigue. Commit 4af6c2f.

<details><summary>Görev metni</summary>

- [ ] **Y-F01 Moral ve takat: kervanın nefesi, ama takat bedende kalır**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `86fdc4b`): docs/design_notes/moral_ve_takat.md; kod onaydan sonra.
  - **Öncelik:** P2 · **Dalga:** 4
  - **Ne:** Moral seferin ortak göstergesi olarak takatle bağlanır, ama kullanıcı notu gereği takat aynı zamanda kişiye ait fiziksel bir durumdur (yorgunluk, yürüme, savaş). Tasarım notu: hangi değer kervana, hangisi kişiye ait. Stres kişide kalır; kırgınlık portrede görünür.
  - **Kullanıcı notu:** “takat aynı zamanda fiziksel bir durum olmalı ama.”
  - **Kabul:** Onaylı tasarım notu; arayüzde göstergeler sadeleşmeden okunur hâlde.
  - **Literatür:** R1, R4

</details>

### Y-C16 · İşe almayı zorlaştır ve kişileştir

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Pano 1-2 kişi, lonca 1, savaş/vebada -1; fiyat +%30; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C16 İşe almayı zorlaştır ve kişileştir**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `ba7b508`): Pano 1-2 kişi, lonca 1, savaş/vebada -1; fiyat +%30; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4
  - **Ne:** Adayın neden geldiği, ne istediği, kimden kaçtığı. Yalnızca mecbur olanlar katılır (15 Ekim isteği). Fiyat ve bulunurluk sertleşir.
  - **Kullanıcı notu:** “Zaten ben 15 ekimde istemişim bunu evet. onaylıyorum.”
  - **Kabul:** Aday kartında geçmiş ve istek; aday sayısı ve fiyatları yeni tabloda.
  - **Literatür:** R17, R22

</details>

### Y-C15 · Orta ve geç oyuna yeni tehditler

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Evre 10 ve 25 seferde; pusu, savaş/veba/haraç haberi, rakip kervan, gümrük sıklaşır; yükselen haraç tutarı sonraki tur; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-C15 Orta ve geç oyuna yeni tehditler**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `c890afe`): Evre 10 ve 25 seferde; pusu, savaş/veba/haraç haberi, rakip kervan, gümrük sıklaşır; yükselen haraç tutarı sonraki tur; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 4
  - **Ne:** Bölge açıldıkça yeni düşman, dünya krizleri (savaş, kıtlık), rakip kervan, yükselen haraç.
  - **Kabul:** Kariyer simülatöründe orta ve geç dönem kazanma oranları hedef aralıkta.
  - **Literatür:** R4, R80

</details>

### Y-F07T · Büyücüyü nadir olay düşmanı olarak bağla

- **Durum:** test bekliyor · **Öncelik:** P3 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06
- **Son not:** Ağırlık 0.08, tehlike 0.35+, bir kez; lore kararı (Y-E06) metni değiştirebilir; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-F07T Büyücüyü nadir olay düşmanı olarak bağla**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `dcd1edc`): Ağırlık 0.08, tehlike 0.35+, bir kez; lore kararı (Y-E06) metni değiştirebilir; test TEST_PLANI.md'de.
  - **Öncelik:** P3 · **Dalga:** 4 · **Bağımlı:** Y-E06
  - **Köken:** onaylanmayan **F07** önerisinin altındaki kullanıcı notu.
  - **Ne:** Kullanıcı notundan türetildi: büyücü ve 7 büyü kaldırılmaz; nadir bir olayla doğabilir.
  - **Kullanıcı notu:** “nadir bir olay evet ama olabilir, kaldırmak yok.”
  - **Kabul:** Büyücü en az bir nadir olaydan doğuyor; büyüler savaşta çalışıyor.

</details>

## Paket P10

### Y-D01 · Kader Modu (ironman) ve açık zorluk ayarları

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P10 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Standart = bugünkü denge; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **Y-D01 Kader Modu (ironman) ve açık zorluk ayarları**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `897b6d2`): Standart = bugünkü denge; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4
  - **Ne:** Tek kayıt ve şehirde elle kayıt yok. Yanında açık ayarlar: ölümcül darbe direnci, açlık şiddeti, olay sertliği. Gizli zorluk ayarı yok. Not: kullanıcı lider ölümü için ayrıca bir zorluk artışı istemiyor (D02 onaylanmadı); standart ayarlar bugünkü dengede kalır.
  - **Kullanıcı notu:** “tamamdır, haklısın.”
  - **Kabul:** Yeni oyun ekranında mod ve ayarlar; Kader Modu'nda elle kayıt kapalı; testler.
  - **Literatür:** R80, R36, R23

</details>

### Y-D03 · Soy mirası: kervan bitince ne kalır

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P10 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Arşiv user://lineage_archive.json; ün payı %20, tavan 6.

<details><summary>Görev metni</summary>

- [ ] **Y-D03 Soy mirası: kervan bitince ne kalır**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `20d8861`): Arşiv user://lineage_archive.json; ün payı %20, tavan 6.
  - **Öncelik:** P1 · **Dalga:** 4
  - **Ne:** Yeni kervan eski soyun defterini, mezarlarını ve ününü görür; bir eşya ya da itibar mirası; eski kervanın mezarı haritada.
  - **Kabul:** Run over sonrası yeni oyun eski soyu okuyor; miras kayıt dosyasında.
  - **Literatür:** R54, R42

</details>

## Paket P11

### Y-E07 · Paylaşılabilir defter sayfası ve güncel Codex

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P11 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Defter sayfası kaydı ve Codex otomatik sayfa aracı yazıldı; dışa aktarım ve PDF hiç koşmadı, "71 sayfa" doğrulanmadı. | 2026-10-20: dışa aktarım (71 olay) ve PDF (110 sayfa) koşturuldu; kapak sayıları veriden. Commit f935975.

<details><summary>Görev metni</summary>

- [ ] **Y-E07 Paylaşılabilir defter sayfası ve güncel Codex**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `35a0db9`): Codex 29 elle + 42 otomatik sayfa; PDF dışa aktarım sonrası yeniden üretilecek.
  - **Öncelik:** P2 · **Dalga:** 5
  - **Ne:** Seferin ya da soyun özeti ekran görüntüsüne uygun tek bir defter sayfası; Codex olay bölümü güncellenir.
  - **Kabul:** Defter sayfası dışa aktarılabiliyor; Codex katalogla eşit.
  - **Literatür:** R11, R44

</details>

## Paket P12

### 9.1 · Ortak UI kiti v2

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Kenney UI Pack RPG Expansion + Fantasy UI Borders (CC0) indirildi; tools/ui_kit_ink.py ile mürekkep ve palet renklerine boyandı (build/ui_kit); önizleme referans/taslaklar/y_91_ui_kit.png. Seçim köşebendinin ortası dolu çıktı. Onaydan sonra temaya bağlanır. | 2026-10-19 karar: beklet: kit, önceki düzeltmelerle birlikte ilgili sahnelerde örnekle gösterilecek. | 2026-10-20 kullanıcı kararı: köşebentler kaldırıldı (select_corner kitten ve örneklerden çıktı). | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş). | 2026-10-21 uygulandı (K8): kit plakaları ipucu ve fiş, başlık şeridi pazar yan panellerinde, olay kartı FRAMED_PANEL, ilk seçenek ve taverna sohbet düğmesi PRIMARY_BUTTON; test_waybook_theme kilitliyor.

<details><summary>Görev metni</summary>

- [ ] **9.1 Ortak UI kiti v2** (K-01, K-03, T-02…T-12)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kenney UI Pack RPG Expansion + Fantasy UI Borders (CC0) indirilince kâğıt-mürekkep diline boyanır; Y-G11T ve 9.4-9.9 taslaklarındaki ince çerçeve ve kehribar vurgu bu kitin hedefi.
  - 9-slice panel çerçevesi, başlık şeridi, kırmızı ana eylem düğmesi (tüm durumlarıyla), tooltip plakası, seçim köşebentleri.
  - **Kaynak (CC0, 2026-10-17):** Kenney UI Pack RPG Expansion (85 dosya) ve Kenney Fantasy UI Borders (140 çerçeve), ikisi de CC0. Çerçeveler kâğıt ve mürekkep diline yeniden boyanır (stil rehberi Y-G01); kullanıcının reddettiği çizik, deri ve nine-slice süs dili kullanılmaz (25–27 Eylül kararları). Süsleme ve vinyet için Old Book Illustrations “Ornaments” görselleri (görseller serbest, açıklama metinleri NC, kopyalanmaz). Ayrıntı: `../ICERIK_IHTIYACLARI.md` G-7.

</details>

### 12.2 · Yol görünümü: büyük revizyon (overhaul)

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** 12.2a, 12.2e, 9.9, 9.10 bu notta sıralı. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş). | 2026-10-21 uygulandı (K5): güneş/ay tek Gauss parıltısı (radial_glow), bulutlar, ufuk bandı, sis şeridi, uzak/orta soğuk ve ön sıcak renk ayarı, gece fener ışığı; screenshot_road_light.gd.

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

### 12.2e · Yol sahnesi estetik olarak güzel değil; her detayı yeniden tasarla: çimen, yol, arka plan, güneş

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Bağımlı:** 12.2d
- **Son not:** Gerçek şeritlerle; değişen yalnızca gök, güneş-ışık, renk derecelendirmesi, sis şeridi, gece feneri. | 2026-10-19 karar: onay; yol sahnesine uygulanacak. | 2026-10-20: ArtPalette.SKIES onaylı taslağa göre (band anahtarı), ufukta sıcak bant, güneş hale + küçük çekirdek. Commit 4af6c2f.

<details><summary>Görev metni</summary>

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

</details>

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

### 12.2a · Şehir kapısı görünümü çok kötü ("rezalet"), baştan tasarlanmalı

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** settlement_gates.py her yerleşimin kapısını kasabasından türetir (gök, ışık, kar, mimari değer); render WAYBORNE_TOWN_CFG/OUT ile build/gates altına. Yuvarlak Tower minareye benzediği için kullanılmadı. | 2026-10-19 karar: onay; 27 yerleşimin kapısı render edilecek. | 2026-10-20: GateArrival: gerçek girişte şehrin kapı resmi 1.6 s, sonra solar; gündüz evresinde gündüz kapısı. 27 kapının gündüz renderları sürüyor (gates_phases.json). | 27 kapı x gece/gündüz render edildi ve denetlendi, tame_palette ile.

<details><summary>Görev metni</summary>

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

### Y-G10T · Şehir ekranı: insanlar ve şehir görünsün

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Oyunun gövde ve giysi kareleriyle meydanda halk; kervan yok. Uygulamada kalabalık ayrı katman: town_scene içinde sahne ışığı ve örtmeyle render, saatle yoğunluk (gece az, pazar günü çok), krizde (9.3) azalır ve yüzler değişir. | 2026-10-19 karar: insanların ışığı ortama aykırı; gece/akşam çok daha az insan; herkes yürüyor, sahne kurgulanmalı (duran, konuşan, satan). | 2026-10-21 uygulandı (K12): TownsfolkLayer; gece 4, akşam +5 kişi, arka plandan ışık örneklenir, bekçi feneriyle; screenshot_city_moods.gd.

<details><summary>Görev metni</summary>

- [ ] **Y-G10T Şehir ekranı: insanlar ve şehir görünsün**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Oyunun gövde ve giysi kareleriyle meydanda halk; kervan yok. Uygulamada kalabalık ayrı katman: town_scene içinde sahne ışığı ve örtmeyle render, saatle yoğunluk (gece az, pazar günü çok), krizde (9.3) azalır ve yüzler değişir.
  - **Öncelik:** P1 · **Dalga:** 6 · **İlgili:** 12.1, 12.2a, 9.3
  - **Köken:** onaylanmayan **G10** önerisinin altındaki kullanıcı notu.
  - **Ne:** Kullanıcı notundan türetildi (kervan merkezli şehir önerisi reddedildi): şehir menüsü iyileştirilir, insanlar ve şehir görünür. Savaşın ve kıtlığın içinde bu işi yapmanın motivasyonu halkların kendisidir; ekran bunu hissettirmeli. Kervan şehre girmez. 12.1 ve 12.2a ile birlikte; önce taslak kare onaya.
  - **Kullanıcı notu:** “Şehir menüsü iyileştirilebilir, evet başka oyuna çok benziyor fakat insanlar ve şehir gözükmeli. Bizim yolda olmamız büyük bir tehlike ve bu işin özünde şu durumda, savaşın ve kıtlığın içinde bu işi yapmamızın bir motivasyonu olmalı, o motivasyon ise halkların kendisi. ayrıca şehre kervan girmez.”
  - **Kabul:** Onaylı taslak; şehirde insanlar görünüyor; kervan şehir içinde gösterilmiyor.

</details>

### 9.3 · CityFront durum varyantları

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Bağımlı:** 9.1
- **Son not:** Piksel hizalı renk ve ışık türetimi; gerçek uygulamada gök town_post adım 1de varyanta göre değişecek (taslakta ay her varyantta kalıyor). Kalabalık ve hasar katmanları Y-G10T ile. | 2026-10-19 karar: sabah/gündüz/akşam/gece ve her şehre kültüre göre ayrı varyant (N33 ile birlikte). | 2026-10-20: 27 yerleşim x sabah/gündüz/akşam yeniden render ediliyor (town_phases.py, towns_phases.json, kültürün ufku korunur); CityFront.background_path saate göre seçer. Denetimde akşam göğü mordan nötr koyu taşa çekildi, sabah güneşi yumuşak kenarlı. Render bitince görsel kontrol ve commit. | 2026-10-20: 81 evre resmi render edildi ve denetlendi; mor gece gökleri town_post.tame_palette ile arduvaza, sabah ılık ve puslu. Commit 0b7eeeb; test_phases_audio.

<details><summary>Görev metni</summary>

- [ ] **9.3 CityFront durum varyantları** (A-25…A-29, T-01)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Piksel hizalı renk ve ışık türetimi; gerçek uygulamada gök town_post adım 1de varyanta göre değişecek (taslakta ay her varyantta kalıyor). Kalabalık ve hasar katmanları Y-G10T ile.
  - Varyantlar: alacakaranlık, gece, gri, kriz.
  - Katmanlar: pencere ışığı, ışık huzmesi, hasar ve kalabalık.
  - Hepsi mevcut `mask.png` ile piksel hizalı olacak.

</details>

### 9.4 · Mekân ekranları

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Bağımlı:** 9.1
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19: taverna oyunda canlı (TavernRoom: barmen, garson yürüyüşü, ozan, 4-6 müşteri, şömine alevi, mumlar, sohbet modu); ekran görüntüsüyle kontrol edildi, onay bekliyor. Eski dedikodu satın alma düzeni hizmetler panelinde duruyor, N34 değiştirecek. | 2026-10-19 karar: popup değil, referanstaki gibi tam ekran oda; mankenler canlı, önceden belirlenmiş rotasyonlarla hareketli ve rollü (konuk, müzisyen, barmen, yardımcı). Mekân iskeleti taslağı (y_94) silindi, taverna bu ekranı izler. | 2026-10-20: tavernada masadaki konuklar sit_box klibiyle oturuyor; masa ve bank gerçek ölçülerde (0.75 / 0.46 m) yeniden render edildi, bardak masada (el kalkmadan bardak kalkmıyordu).

<details><summary>Görev metni</summary>

- [ ] **9.4 Mekân ekranları** (T-02…T-09)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Ortak bir iskelet.
  - Büyük sahip portresi.
  - Mekânın mimarisinden türeyen yuvalar: kilise nişi, taverna fıçısı, şifacı kapısı.

</details>

### 9.5 · Pazar, erzak ve envanter

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19: oyunda uygulandı - pazar terazisi (MarketScale: mühür içinde mal ve sikke, sepet büyüdükçe parça sayısı artar, kol dengeye göre yaylı eğilir, düşen parça yerine oturur); ekran görüntüsüyle kontrol edildi, onay bekliyor. | 2026-10-19 karar: terazili tek ekran gereksiz; pazar Y-G11T masa ekranı olacak, terazi referans görseldeki gibi. | 2026-10-21 kullanıcı: oyundaki hali kalsın; vagon ve karakter çantaları açılır-kapanır bölüm olarak eklendi (K10).

<details><summary>Görev metni</summary>

- [ ] **9.5 Pazar, erzak ve envanter** (T-12, T-08)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Üstte fiyatlı mal kartları, altta kervan envanteri.

</details>

### 9.6 · Karakter ve stat ekranı

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19 karar: onay ("güzel"). | 2026-10-20: üç sütunlu karakter ekranı (kimlik, huylar ve statlar, beceriler ve dirençler), Kişi / Kuşam ve görev sekmeleri, SegmentBar. Denetimde düzeltildi: önizleme figürü render çözünürlüğünün üstüne büyütülmüyor (bulanıklık), kırgınlık işaretleri koyu zeminde açık mürekkeple. Commit 4af6c2f.

<details><summary>Görev metni</summary>

- [ ] **9.6 Karakter ve stat ekranı** (K-01)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Üç sütun: kimlik ve figür / huylar ve statlar / beceriler ve dirençler.

</details>

### 9.7 · Roster kartı ve seviye rozeti

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19 karar: onay ("güzel"). | 2026-10-20: RosterCard ve seviye rozeti (party ekranı). Kart başlığındaki açlık çetelesi kaldırıldı (durum satırı söylüyor, ismi kesiyordu). Commit 4af6c2f.

<details><summary>Görev metni</summary>

- [ ] **9.7 Roster kartı ve seviye rozeti** (K-01, T-02, T-11)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Seçili ve yaralı durumlarıyla.

</details>

### 9.8 · Savaş ekranı

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19 karar: savaş arka planı savaşın olduğu yere göre; karakterlerin altında stilize can barı, can sağ panelden izlenmemeli. | 2026-10-21 taslaktaki savaş ekranı alındı (K9, bkz. Y-G05).

<details><summary>Görev metni</summary>

- [ ] **9.8 Savaş ekranı** (K-03…K-05)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Alt panel: solda aktif üye, sağda hedef kartı.
  - Tur madalyonu.
  - Kritik vuruşta renk değişimi ve yakınlaşma.
  - `g9_seal` ile uyumlu bir öldürücü darbe mührü.

</details>

### Y-G05 · Savaş ekranını yeniden kur

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Biyom plakası yolun kendi şeritlerinden; figürler ekranın %32si. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş). | 2026-10-21 uygulandı (K9): tur madalyonu, tam ekran, yetenek kartları (isabet %/kilit sebebi), hedef paneli; kanama/kritik efektleri kullanıcı kararıyla eklenmedi.

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

### 9.9 · Yol HUD'u

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Alt panel (P18) zaten sekmeli: harita ve envanter orada. | 2026-10-19 karar: harita ve envanterle birlikte gösterilecek; sağ üstteki moral/stres/takat paneli kalkar, alt panele iner. | 2026-10-21 kullanıcı: oyundaki hali iyi, taslak silindi (y_99_yol_hud.png).

<details><summary>Görev metni</summary>

- [ ] **9.9 Yol HUD'u** (K-02; çatlak efekti kaldırılacak, bkz. §2.5)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Alt panel (P18) zaten sekmeli: harita ve envanter orada.
  - `SurvivalGauge` ince çubuk, amblem ve çentiklerle çizilecek.
  - Harita ve envanter sekmeli alt panel.
  - Bu iş §8 ile bağlantılı.

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

### 9.12 · Kilise ve mezarlık arka planı

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Kenney Graveyard Kit (CC0, haçsız) ile sakin ve nöbet varyantları: tools/ui_scenes/graveyard_scene.py; taslak referans/taslaklar/y_912_mezarlik_sakin_nobet.png. Onaydan sonra kilise ekranına (b5_church yerine) bağlanır. | 2026-10-19 karar: onay; kilise ekranına bağlanacak. | 2026-10-20: kilise mezarlığı tam çözünürlükte sakin ve nöbet (yas) varyantı; church.gd yas varsa nöbet resmini açar. Commit 4af6c2f.

<details><summary>Görev metni</summary>

- [ ] **9.12 Kilise ve mezarlık arka planı** (A-01, A-06, A-14, T-03)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kenney Graveyard Kit (CC0) indirilince town_scene hattıyla sakin ve nöbet varyantları; dini sembol yok, lore (Y-E06) işaretleri bekleniyor.
  - Tek illüstrasyondan sakin ve nöbet varyantları.
  - **Kaynak:** Kenney Graveyard Kit (CC0; mezar taşı, çit, kripta). Kural: gerçek dinî yapı ve figür yok; haç ve benzeri semboller çıkarılır. Lore'daki inançlara (Y-E06) göre özgün işaretler.

</details>

### 9.2 · Ana menü gece kampı, katmanlı

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
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

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
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

### Y-G14 · Tipografi birliği

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G01
- **Son not:** IM Fell Türkçe harflerin hepsini taşıyor (fontTools ile ölçüldü).

<details><summary>Görev metni</summary>

- [ ] **Y-G14 Tipografi birliği**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `c8cf507`): IM Fell Türkçe harflerin hepsini taşıyor (fontTools ile ölçüldü).
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-G01
  - **Ne:** Harita, arayüz, defter ve kartlarda aynı üç yazı yüzü; haritadaki sans-serif kalkar.
  - **Kabul:** Yazı yüzü listesi stil rehberinde; ekranlar uyumlu.
  - **Kaynaklar ve teknik (CC0 araştırması):** Fontlar SIL OFL 1.1 (OFL.txt dağıtıma, Credits'te liste): IM Fell English yalnızca temel Latin; Türkçe ğ, ş, İ, ı eksik olabilir → test edilir, eksikse yalnızca İngilizce başlıklarda. Gövde EB Garamond (latin-ext ve Kiril), alternatif Cormorant Garamond, rakamlar için Old Standard TT; Çince Noto Serif SC, EB Garamond'un arkasında fallback. `../ICERIK_IHTIYACLARI.md` G-8.

</details>

### DFT1 · Defter sayfası okunur olsun (cetvel çizgileri)

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/referans/gorevler/09_art_ikinci_tur.md](referans/referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Kullanıcı bildirimi (2026-10-19). tools/ledger_unrule.py: kaynak art_source/waybook/l1_ledger_ruled.jpg, çıktı data/assets/ui/waybook/l1_ledger.jpg; cetvel normalize evrişimle silindi, CC0 kâğıt dokusu eklendi. Lekelerin içinde küçük ızgara parçaları kaldı.

## Paket P14

### Y-H07 · Erişilebilirlik ve oynanış ayarları

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P14 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Üç ayar kodda ama kapsamı dar: metin boyu yalnız tema taban boyu (elle verilmiş boylar sabit), desenli şerit yalnız savaş seçeneği şeridi, otomatik duraklama yalnız yol işareti ve karşılaşma işareti. Denenmedi.

<details><summary>Görev metni</summary>

- [ ] **Y-H07 Erişilebilirlik ve oynanış ayarları**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `20d0400`): Ayarlar settings.cfg de; hızlandırma Y-B09 ile kalktı, duraklatma kaldı.
  - **Öncelik:** P2 · **Dalga:** 6 · **İlgili:** Y-B09
  - **Ne:** Metin boyutu, renk körlüğü için kan şeridine desen, olay gelince otomatik duraklat. Hızlandırma Y-B09 gereği kalkacak; duraklatma kalır.
  - **Kabul:** Ayarlar menüsünde; testler.

</details>

## Paket P16

### N29 · Vadiye özgü yeşil çayır biyomu

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N28
- **Son not:** Kod, veri ve dört katman hazır; testler ve ekran görüntüsü TEST_PLANI.md'de, onay ONAY_PAKETI.md'de.

<details><summary>Görev metni</summary>

- [ ] **N29 Vadiye özgü yeşil çayır biyomu** (`CO`)
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5ae38c4`): Kod, veri ve dört katman hazır; testler ve ekran görüntüsü TEST_PLANI.md'de, onay ONAY_PAKETI.md'de.
  - Bugün vadinin açık tarım arazisi "bozkır" şeridiyle çiziliyor (kuru, sarı ot). Vadi (Tyrell benzetmesi) bereketli: yeşil çayır, ekin tarlası, çit ve ağaç sırası, uzakta yumuşak tepeler.
  - Yeni biyom `meadow`: `ArtPalette` dört rolü (gökyüzü/uzak/yakın/flora), `tools/ui_scenes/road_scene.py` `BIOMES` girdisi ve dört katmanın (far, mid, ground, fore) Blender render'ı, `road_post.py`; `RouteTerrain.BIOME_CHAIN`, isim anahtarı (`TERRAIN_MEADOW`, tr/en), hava eğilimi (`RouteWeather`), ağaç çizimi.
  - Üreteç (`build_settlements.py`): vadi bölgesindeki açık arazi bozkır değil çayır; bozkır göçebe ve güney kuru topraklarında kalır.
  - **Kabul:** Belvanor-İlsande yolu çayır; ekran görüntüsü senin onayına; `test_grim_ui` şerit kenar testleri ve `test_route_terrain` geçer.

</details>

### N30 · Bozkırda yol durakları arasını aç

- **Durum:** test bekliyor · **Öncelik:** P2 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N28
- **Son not:** Bozkırda durak aralığı 6 gün; test TEST_PLANI.md'de.

<details><summary>Görev metni</summary>

- [ ] **N30 Bozkırda yol durakları arasını aç** (`C`)
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5ae38c4`): Bozkırda durak aralığı 6 gün; test TEST_PLANI.md'de.
  - Göçebe bozkırında (ör. Selvicar-Orbeyan, 35 gün) yol beş yurtta durur; harita noktası durakları arasındaki en az aralık 3 gün.
  - Bozkır parçalarında aralık daha geniş (öneri 6 gün) ya da yol başına harita noktası durağı sınırı; dağ/su geçidi durakları etkilenmez.
  - **Kabul:** Selvicar-Orbeyan'da yurt durağı en çok 3; `test_route_terrain` geçer.

</details>

## Paket P18

### N23 · Eski HUD parçalarını kaldır

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N18, N19, N20, N22
- **Son not:** Tab ile açılan CaravanStatusPanel kontrat listesini de gösterdiği için duruyor; panelin Yük sekmesine kontratlar taşınınca kalkar (karar senin). | 2026-10-20: eski Tab paneli (CaravanStatusPanel, StatusOverlay) kaldırıldı; kontratlar kontrol panelinin Yük sekmesinde, Durum düğmesi ve Tab kontrol panelinin Durum sekmesini açıyor.

<details><summary>Görev metni</summary>

- [ ] **N23 Eski HUD parçalarını kaldır** (`C`)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `e967039`): Tab ile açılan CaravanStatusPanel kontrat listesini de gösterdiği için duruyor; panelin Yük sekmesine kontratlar taşınınca kalkar (karar senin).
  - Üst şerit ve yan göstergelerden panelde olanlar kalkar; yinelenen metin kalmaz; testler güncellenir.

</details>

### N31 · Oyun hissi incelemesi ve planı (6 alan)

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Son not:** Altı alan incelendi; N31a-N31f alt görevleri 14_yeni_dunya.md ye eklendi (gorevler.json a bir sonraki durum.py taramasında).

<details><summary>Görev metni</summary>

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

</details>

### N31a · Ölçüm: beat kaydı ve boş dakika raporu

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: log_beat + playtest_beats.jsonl; playtest_report.py boş dakika, en uzun ara, savaş/kamp süresi, ekran süresi.

<details><summary>Görev metni</summary>

- [ ] **N31a Ölçüm: beat kaydı ve boş dakika raporu** (`C`) - oyuncu testinde her karar ve bilgi anı gerçek saniyeyle; playtest_report boş dakikaları, savaş ve kamp sürelerini yazar. (M, P1) Ayrıntı: `docs/design_notes/oyun_hissi_plani.md` §1.

</details>

### N31b · Işık modeli ve sis şeridi koda

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: 12.2e ile güneş halesi ve ufuk bandı yolda (commit 4af6c2f). Ayrı sis şeridi eklenmedi; 12.2e onaylı ışık modeli yeterli görüldü.

<details><summary>Görev metni</summary>

- [ ] **N31b Işık modeli ve sis şeridi koda** (`CO`) - 12.2e taslağı onaylanınca TravelBand gök, hale, evre derecelendirmesi, sis şeridi. (M, P1) §2.

</details>

### N31c · Ses otobüsleri, çeşitleme, ayar kaydırıcıları

- **Durum:** test bekliyor · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: dört ses otobüsü, Ayarlar'da dört sürgü, tekrarsız çeşit, Kenney CC0 arayüz sesleri (indirildi, KUNYE.tsv). Commit 461be41.

<details><summary>Görev metni</summary>

- [ ] **N31c Ses otobüsleri, çeşitleme, ayar kaydırıcıları** (`C`) - müzik/ortam/efekt/arayüz otobüsleri, AudioStreamRandomizer, Ayarlar'da dört kaydırıcı. (M, P1) §3.

</details>

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
