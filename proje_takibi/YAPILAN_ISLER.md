# Yapılan işler

Bitmiş ve doğrulanmış (testi ya da kullanıcı onayı geçmiş) görevler. Kod dalı: `wayborne`, `yerel/yapilacaklar-p05-p06` (önceki tur `yerel/yapilacaklar-p01-p04`). Push edilmedi.

Toplam: **73** görev. Belgeler `referans/belge_uret.py` ile `referans/gorevler.json`'dan üretilir.

## Paket P01

### 6.2 · `.gitignore` boşluklarını doldur

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P01 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/06_depo_hijyeni.md](referans/gorevler/06_depo_hijyeni.md)
- **Son not:** *.blend1, *.blend@, Thumbs.db, .DS_Store, *.log, *.orig eklendi; hiçbir dosyayla eşleşmeyen data_*/ satırı kaldırıldı.

<details><summary>Görev metni</summary>

- [x] **6.2 `.gitignore` boşluklarını doldur** (H-8)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `af1f044`): *.blend1, *.blend@, Thumbs.db, .DS_Store, *.log, *.orig eklendi; hiçbir dosyayla eşleşmeyen data_*/ satırı kaldırıldı.
  - Ekle: `*.blend1`, `*.blend@`, `Thumbs.db`, `.DS_Store`, `*.log`, `*.orig`.
  - `data_*/` satırını kaldır.

</details>

### 6.1 · LFS ve `.gitattributes` ekle

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P01 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/06_depo_hijyeni.md](referans/gorevler/06_depo_hijyeni.md)
- **Son not:** .gitattributes eklendi (metin dosyaları LF, ikililer binary). Bu makinedeki core.autocrlf=true yüzünden CRLF'ye dönen iki spec JSON'u iki testi kırıyordu; artık geçiyor. LFS taşıması (`git lfs migrate`, geçmişi yeniden yazar) kullanıcı onayı bekliyor, yapılmadı. git-lfs 3.7.1 kurulu. | 2026-10-20 kullanıcı kararı: LFS taşıması (git lfs migrate, geçmiş yeniden yazılır) ONAYLANDI. | 2026-10-20 güncelleme: push yok, geçmiş yeniden yazılmayacak; kullanıcı dosyaları yeni bir dala kendisi alacak. Yalnızca .gitattributes LFS kuralları. | 2026-10-20: .gitattributes LFS kuralları (png, jpg, ogg, wav, mp3, glb, blend, npz, pdf, ttf, otf). Geçmiş yeniden yazılmadı (kullanıcı kararı). Yeni dalda: git lfs install && git add --renormalize . | 2026-10-20 (son): geniş LFS kuralları denendi ve GERİ ALINDI: geçmiş düz blob, klonda pointer uyarısı; taşınırsa ~500 MB LFS ve CI her koşuda indirir (ücretsiz aylık 1 GB kota). En büyük dosya 2,2 MB, 100 MB sınırı sorun değil. Yalnız harita karoları LFS. Karar kullanıcıda. | 2026-10-21 kullanıcı kararı: LFS taşıması yapılmayacak, bugünkü hâliyle (yalnız harita karoları LFS) kalsın.

<details><summary>Görev metni</summary>

- [ ] **6.1 LFS ve `.gitattributes` ekle** (§5 H-1, H-9)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `32f9ac4`): .gitattributes eklendi (metin dosyaları LF, ikililer binary). Bu makinedeki core.autocrlf=true yüzünden CRLF'ye dönen iki spec JSON'u iki testi kırıyordu; artık geçiyor. LFS taşıması (`git lfs migrate`, geçmişi yeniden yazar) kullanıcı onayı bekliyor, yapılmadı. git-lfs 3.7.1 kurulu.
  - İkili dosyalar LFS'e gitsin.
  - Metin dosyaları için `eol=lf` tanımla (Windows'tan yapılacak commitler için gerekli).
  - Geçmişi yeniden yazmak (`git lfs migrate`) **kullanıcı onayı** ister (§7 madde 11).

</details>

### 2.1 · Dışa aktarımlardan test ve araçları çıkar

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P01 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/02_yuksek_etkili.md](referans/gorevler/02_yuksek_etkili.md)
- **Son not:** export_presets.cfg Web ön ayarına exclude_filter="tests/*, tools/*" eklendi; oyun kodu bu klasörlere çalışma anında başvurmuyor (yalnızca yorumlar). Yapılmadı: DevPanel'in PC sürümünde kalıp kalmayacağı kararı (kullanıcıya soruldu) ve henüz var olmayan PC (Windows) ön ayarı (dışa aktarma şablonları kurulu değil). | 2026-10-20 kullanıcı kararı: DevPanel şimdilik PC sürümünde KALSIN.

<details><summary>Görev metni</summary>

- [x] **2.1 Dışa aktarımlardan test ve araçları çıkar** (§4 O-1; PC dışa aktarımı asıl hedef, Web yalnız test için)
  - **Kapandı (2026-10-21, kullanıcı kararı):** Web derlemesi ve `export_presets.cfg` tamamen kaldırıldı; oyun klonlanıp yerelde oynanıyor, dışa aktarım yok. Aşağıdaki not tarihçedir. (Önceki durum: `yerel/yapilacaklar-p01-p04`, commit `ded1091`): export_presets.cfg Web ön ayarına exclude_filter="tests/*, tools/*" eklendi; oyun kodu bu klasörlere çalışma anında başvurmuyor (yalnızca yorumlar). Yapılmadı: DevPanel'in PC sürümünde kalıp kalmayacağı kararı (kullanıcıya soruldu) ve henüz var olmayan PC (Windows) ön ayarı (dışa aktarma şablonları kurulu değil).
  - `export_presets.cfg` içine `exclude_filter="tests/*, tools/*"` ekle.
  - Önce `test_selector.tscn`'in yalnız `scripts/` kullandığını doğrula.
  - `DevPanel` ve `test_selector` PC sürümünde kalmalı mı, kullanıcıya sor (§7 madde 4). Web test derlemesinde kalabilir.

</details>

### 2.4 · Test sürelerini ölç, sonra CI önbelleği ekle

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P01 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/02_yuksek_etkili.md](referans/gorevler/02_yuksek_etkili.md)
- **Son not:** run_tests.gd en yavaş on paketi ve toplamı basıyor. Ölçüm: paketler toplam 20,6 sn (en yavaşı Navigation 4,8 sn), soğuk içe aktarma ~100 sn, sıcak ~13 sn. tests.yml'e .godot + **/*.import + **/*.translation önbelleği eklendi; deploy.yml'e bilerek eklenmedi. CI önbelleği GitHub'da henüz koşturulmadı, ilk koşuda kontrol edilmeli.

<details><summary>Görev metni</summary>

- [x] **2.4 Test sürelerini ölç, sonra CI önbelleği ekle** (§4 O-10, O-11)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `5dfcc5b`): run_tests.gd en yavaş on paketi ve toplamı basıyor. Ölçüm: paketler toplam 20,6 sn (en yavaşı Navigation 4,8 sn), soğuk içe aktarma ~100 sn, sıcak ~13 sn. tests.yml'e .godot + **/*.import + **/*.translation önbelleği eklendi; deploy.yml'e bilerek eklenmedi. CI önbelleği GitHub'da henüz koşturulmadı, ilk koşuda kontrol edilmeli.
  - `run_tests.gd`'ye paket başına süre yazdır.
  - CI'da `.godot/imported` için `actions/cache` ekle.

</details>

### Y-K03 · Oyun ölçümü

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P01 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 2026-10-20: simulate_career OLCUM satırı, tools/measure_report.py, .github/workflows/olcum.yml (elle+haftalık), ilk rapor docs/olcum/OLCUM_2026-10-20.md (sefer 14-16 gün / 11-12 dk, 5-6 kart, 0,04-0,06 ölüm). Oyuncu ölçümü Ayarlar izniyle, varsayılan kapalı; session satırı oturum uzunluğu için.

<details><summary>Görev metni</summary>

- [ ] **Y-K03 Oyun ölçümü**
  - **Öncelik:** P2 · **Dalga:** 1
  - **Ne:** Sefer süresi, kart sayısı, ölüm oranı, oturum uzunluğu. Kullanıcı notu: “github'da çalışıyoruz normalde.” Simülatör ölçümleri GitHub Actions çıktısı olarak tutulabilir; oyuncu tarafı ölçüm yalnızca izinle ve yerel dosyaya. Notun anlamı kullanıcıya sorulup netleştirilmeli.
  - **Kullanıcı notu:** “github'da çalışıyoruz normalde.”
  - **Kabul:** Ölçüm raporu CI'da; oyun içi ölçüm izinli.
  - **Literatür:** R79

</details>

## Paket P02

### 1.1 · "mezra" yeniden adlandırması

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P02 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/01_isim_kurali.md](referans/gorevler/01_isim_kurali.md)
- **Son not:** STOP_MEZRA / "mezra", near_mezra bayrağı, game.csv anahtarı STOP_MEZRA (İngilizce metin Village), world_places.json türü ih_mezra. Kayda sızma yok (durak türü kayda yazılmıyor, near_* bayrakları her gün yeniden hesaplanıyor). Ad önerim; haritanın kendi Türkçe adı zaten Mezra. Beğenilmezse tek toplu değiştirmeyle başka ada çevrilir.

<details><summary>Görev metni</summary>

- [x] **1.1 "mezra" yeniden adlandırması**
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `0dc0f02`): STOP_MEZRA / "mezra", near_mezra bayrağı, game.csv anahtarı STOP_MEZRA (İngilizce metin Village), world_places.json türü ih_mezra. Kayda sızma yok (durak türü kayda yazılmıyor, near_* bayrakları her gün yeniden hesaplanıyor). Ad önerim; haritanın kendi Türkçe adı zaten Mezra. Beğenilmezse tek toplu değiştirmeyle başka ada çevrilir.
  - Kod:
    - `scripts/travel/route_terrain.gd`: `STOP_MEZRA = "mezra"` ve satır 134, 136, 140, 249, 255
    - `near_mezra`: `scripts/events/event_resolver.gd:40`, `scripts/events/event_catalog.gd:1629,1639`
    - `scripts/ui/travel_band.gd:957,987` ve `scripts/ui/road_journey.gd:169,2074`
  - Testler: `tests/test_memory.gd:629-630`, `tests/test_route_terrain.gd:171`
  - Çeviri: `data/locale/game.csv:330` içindeki `STOP_MEZRA` anahtarı. Görünen metin de gözden geçirilmeli.
  - Veri: `data/config/world_places.json` içinde 12 adet `"kind": "ih_mezra"`.
  - Varlık: `data/assets/ui/waybook/e6j_mezra.jpg`. Dosya adını ve başvuruları birlikte değiştir.
  - Yeni ad oyuna özgü olmalı. Örnek: `STOP_MEZRA` / `"mezra"`. Kullanıcıya bir öneri sun.
  - **Önce doğrula** (§7 madde 2): `STOP_MEZRA` değeri kayıt dosyasına sızıyor mu? Bak: `GameSession.to_save_dict()`, `JourneyController.to_dict()`. Sızıyorsa eski kayıtları okumak için bir eşleme ekle.

</details>

### 9.13 · İsimlendirme temizliği, art tarafı

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Bağımlı:** 1.1
- **Son not:** e6j_mezra.jpg -> e6j_village.jpg, road_journey.gd başvurusu güncellendi (1.1 ile birlikte).

<details><summary>Görev metni</summary>

- [x] **9.13 İsimlendirme temizliği, art tarafı**
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `0dc0f02`): e6j_mezra.jpg -> e6j_village.jpg, road_journey.gd başvurusu güncellendi (1.1 ile birlikte).
  - `data/assets/ui/waybook/e6j_mezra.jpg` dosyasını `e6j_village.jpg` olarak yeniden adlandır.
  - `scripts/ui/road_journey.gd` içindeki başvuruyu güncelle.
  - Bu iş §1.1 ile birlikte yapılmalı.

</details>

### 1.2 · `tests/test_combat_dd.gd` dosyasını yeniden adlandır

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/01_isim_kurali.md](referans/gorevler/01_isim_kurali.md)
- **Son not:** tests/test_combat_core.gd, paket adı CombatCore, run_tests.gd kaydı ve koddaki yorum başvuruları.

<details><summary>Görev metni</summary>

- [x] **1.2 `tests/test_combat_dd.gd` dosyasını yeniden adlandır**
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `aa01c40`): tests/test_combat_core.gd, paket adı CombatCore, run_tests.gd kaydı ve koddaki yorum başvuruları.
  - Örnek ad: `test_combat_core.gd`.
  - `tests/run_tests.gd` içindeki kaydı da güncelle.

</details>

### 1.3 · Kod yorumlarındaki "referans oyun" ve "referans oyun" anmalarını kaldır

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/01_isim_kurali.md](referans/gorevler/01_isim_kurali.md)
- **Son not:** 48 anma (27 dosya) yeniden yazıldı; scripts, tests, tools, data altında metin dosyalarında kalan yok.

<details><summary>Görev metni</summary>

- [x] **1.3 Kod yorumlarındaki "referans oyun" ve "referans oyun" anmalarını kaldır**
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `35f65f5`): 48 anma (27 dosya) yeniden yazıldı; scripts, tests, tools, data altında metin dosyalarında kalan yok.
  - 27 "referans oyun" ve 29 "referans oyun" geçişi. Liste: §6 N-7, N-8.
  - Yorumun anlamını koru. "referans oyunda gibi" yerine mekaniği doğrudan anlat.
  - `art_palette.gd:144` içindeki "referans oyun #a02b19" yorumu da bu kapsamda.

</details>

### 3.1 · Kullanılmayan 20 fonksiyonu sil

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/03_atil_kod.md](referans/gorevler/03_atil_kod.md)
- **Son not:** 20 fonksiyon silindi (git grep -w ile yeniden doğrulandı); scaled_texture ile birlikte ölü kalan _scaled_cache de gitti.

<details><summary>Görev metni</summary>

- [x] **3.1 Kullanılmayan 20 fonksiyonu sil** (§1B tablosu)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `7d16b27`): 20 fonksiyon silindi (git grep -w ile yeniden doğrulandı); scaled_texture ile birlikte ölü kalan _scaled_cache de gitti.
  - `set_lunge` ve `apply_action_animation` silinirken ilgili bayat yorumları da temizle (§3A).

</details>

### 3.2 · Dinleyicisi olmayan 6 sinyali ve emit satırlarını sil

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/03_atil_kod.md](referans/gorevler/03_atil_kod.md)
- **Son not:** 6 sinyal ve emit satırları silindi; item_removed'in yerel değişkeni de kalktı.

<details><summary>Görev metni</summary>

- [x] **3.2 Dinleyicisi olmayan 6 sinyali ve emit satırlarını sil** (§1C)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `d692d28`): 6 sinyal ve emit satırları silindi; item_removed'in yerel değişkeni de kalktı.

</details>

### 3.3 · Kullanılmayan 11 sabit ve üyeyi sil

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/03_atil_kod.md](referans/gorevler/03_atil_kod.md)
- **Son not:** Kullanılmayan sabit ve üyeler silindi (denetim listesindeki 12 öğe). Debt.source serbest dize, 'penalty' ile karşılaştırılmıyor; eski kayıtlar etkilenmez. LUNGE_DISTANCE'in yanlış yerdeki animasyon yorumu _process'in üstüne taşındı.

<details><summary>Görev metni</summary>

- [x] **3.3 Kullanılmayan 11 sabit ve üyeyi sil** (§1D)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `e561542`): Kullanılmayan sabit ve üyeler silindi (denetim listesindeki 12 öğe). Debt.source serbest dize, 'penalty' ile karşılaştırılmıyor; eski kayıtlar etkilenmez. LUNGE_DISTANCE'in yanlış yerdeki animasyon yorumu _process'in üstüne taşındı.
  - `Debt.SOURCE_PENALTY` için önce eski kayıt uyumluluğunu kontrol et (§7 madde 8).

</details>

### 3.5 · Kullanılmayan 41 çeviri anahtarını sil

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/03_atil_kod.md](referans/gorevler/03_atil_kod.md)
- **Son not:** 34 anahtar silindi. Ham tarama 162 aday verdi; 128'i dinamik kurulan (olay başlık/metin, LEDGER_CAUSE_COMBAT_%s) ya da tutulacak UI_GRIM_*. Denetimdeki 41 rakamı tutulan 7 UI_GRIM_* anahtarını da içeriyordu. CLAUDE.md hâlâ UI_ROAD_STATE ve UI_CITY_HOVER_HINT'ten söz ediyor (4.2'de düzeltilecek).

<details><summary>Görev metni</summary>

- [x] **3.5 Kullanılmayan 41 çeviri anahtarını sil** (§1F)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `5cfed17`): 34 anahtar silindi. Ham tarama 162 aday verdi; 128'i dinamik kurulan (olay başlık/metin, LEDGER_CAUSE_COMBAT_%s) ya da tutulacak UI_GRIM_*. Denetimdeki 41 rakamı tutulan 7 UI_GRIM_* anahtarını da içeriyordu. CLAUDE.md hâlâ UI_ROAD_STATE ve UI_CITY_HOVER_HINT'ten söz ediyor (4.2'de düzeltilecek).
  - `UI_GRIM_CLOSE/ENTER/NAV_LEAVE` kalsın (§2).

</details>

### 3.6 · Ölü araç ve belgeleri kaldır ya da arşivle

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P02 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/03_atil_kod.md](referans/gorevler/03_atil_kod.md)
- **Son not:** Kapı şablonu, Aşama 0 performans denemeleri, Faz 1 kapısı, eski oynatıcı ve atlas betikleri, mesh-deform kalıntıları silindi; ASAMA*, FAZ1_GATE, VALIDATION docs/archive/figure_pipeline/ altına taşındı. DENETİM YANILMIŞ: config/variants/*_medium.json (clip.json ve canlı qa/check_config.py male_medium'u şart koşuyor) ve side_check_camera_minusX.png (layers.json, check_config.py) ölü değil, tutuldu. Kullanıcı kararı bekleyen: build_beasts.py, docs/art-prompts.md ve docs/event-window-blueprint.md (denetim §7 madde 13, 15). | 2026-10-20 kullanıcı kararı: ölü araç ve belgeler SİLİNSİN. | 2026-10-20: tam test koşusu 0 kalan.

<details><summary>Görev metni</summary>

- [ ] **3.6 Ölü araç ve belgeleri kaldır ya da arşivle** (§1G)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `b247080`): Kapı şablonu, Aşama 0 performans denemeleri, Faz 1 kapısı, eski oynatıcı ve atlas betikleri, mesh-deform kalıntıları silindi; ASAMA*, FAZ1_GATE, VALIDATION docs/archive/figure_pipeline/ altına taşındı. DENETİM YANILMIŞ: config/variants/*_medium.json (clip.json ve canlı qa/check_config.py male_medium'u şart koşuyor) ve side_check_camera_minusX.png (layers.json, check_config.py) ölü değil, tutuldu. Kullanıcı kararı bekleyen: build_beasts.py, docs/art-prompts.md ve docs/event-window-blueprint.md (denetim §7 madde 13, 15).
  - Gate şablonu, perf denemeleri, Faz 1 kapısı, mesh-deform kalıntıları, `*_medium.json`.
  - Tarih notlarını `docs/archive/` altına taşı.
  - `qa/faz1_tests.py`, `wardrobe_cut.py` ve `wardrobe_paint_reference.py` **canlı**, dokunma.

</details>

### 3.7 · `art_source/` içindeki reddedilmiş kaynakları depodan çıkar

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/03_atil_kod.md](referans/gorevler/03_atil_kod.md)
- **Son not:** Önlük, MegaKit vagonu, Bridge.blend ve 15 reddedilmiş waybook sayfası (~17 MB) kaldırıldı; künyeler (credits.gd, CREDITS.md, iki LICENSES.md) güncellendi. A0_style_anchor.jpg bilerek tutuldu.

<details><summary>Görev metni</summary>

- [x] **3.7 `art_source/` içindeki reddedilmiş kaynakları depodan çıkar** (§1H, ~17 MB)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `9deffb7`): Önlük, MegaKit vagonu, Bridge.blend ve 15 reddedilmiş waybook sayfası (~17 MB) kaldırıldı; künyeler (credits.gd, CREDITS.md, iki LICENSES.md) güncellendi. A0_style_anchor.jpg bilerek tutuldu.
  - Önlük (apron): künyesini de kaldır (`credits.gd:17`, `CREDITS.md:17`, `LICENSES.md:18`).
  - MegaKit arabası ve `Bridge.blend`.
  - 15 reddedilmiş waybook sayfası.

</details>

### 3.4 · Kullanılmayan varlıkları üretim hattıyla birlikte kaldır

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P02 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/03_atil_kod.md](referans/gorevler/03_atil_kod.md)
- **Son not:** 42 fx sprite (31'i kaldı), k1_slot, k2_door, r4c_danger, r4d_stamina, b10_city.jpg silindi; fx_assets.py açık sprite listesine, waybook araçları güncellendi. Efektler screenshot_combat_fx.gd ile gözle doğrulandı. Bilerek yapılmadı: 13 kullanılmayan eşya paketi ve 6 silah eşyası duruyor (yakında gelecek ganimet, ekipman, biyom ve kamp işleri kullanabilir; yeniden render pahalı; silahlar için denetim kullanıcıya sorulmasını istiyor). | 2026-10-20 kullanıcı kararı: kullanılmayan varlıklar SİLİNSİN. | 2026-10-20: tam test koşusu 0 kalan.

<details><summary>Görev metni</summary>

- [ ] **3.4 Kullanılmayan varlıkları üretim hattıyla birlikte kaldır** (§1E)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `153173a`): 42 fx sprite (31'i kaldı), k1_slot, k2_door, r4c_danger, r4d_stamina, b10_city.jpg silindi; fx_assets.py açık sprite listesine, waybook araçları güncellendi. Efektler screenshot_combat_fx.gd ile gözle doğrulandı. Bilerek yapılmadı: 13 kullanılmayan eşya paketi ve 6 silah eşyası duruyor (yakında gelecek ganimet, ekipman, biyom ve kamp işleri kullanabilir; yeniden render pahalı; silahlar için denetim kullanıcıya sorulmasını istiyor).
  - 42 fx sprite. Ayrıca `tools/fx_assets.py` içindeki `FAMILIES` listesini daralt.
  - `k1_slot`, `k2_door`, `r4c_danger`, `r4d_stamina`. Ayrıca `tools/waybook_assets.py`'yi güncelle.
  - 13 eşya paketi.
  - Kullanılmayan 6 silah eşyası (§7 madde 5): önce kullanıcıya sor.

</details>

### 4.1 · Bayat yorumları düzelt

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/04_kod_kalitesi.md](referans/gorevler/04_kod_kalitesi.md)
- **Son not:** Yolun menü yorumu, DevPanel, UserSettings, FigureRig, BeastRig yorumları düzeltildi; öteki yedi bayat yorum 3.1, 3.3, 3.4, 2.3 ile zaten gitmişti.

<details><summary>Görev metni</summary>

- [x] **4.1 Bayat yorumları düzelt** (§3A, 12 madde)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `b3d43ce`): Yolun menü yorumu, DevPanel, UserSettings, FigureRig, BeastRig yorumları düzeltildi; öteki yedi bayat yorum 3.1, 3.3, 3.4, 2.3 ile zaten gitmişti.
  - Örnek: `road_journey.gd:3025` "kayıt yapılamaz" diyor, oysa yapılabiliyor.
  - Örnek: `user_settings.gd:4` hâlâ `save.json` yolunu gösteriyor.

</details>

### 2.3 · Ölü `CityView` sınıfını ve bağlı varlıklarını kaldır

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P02 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/02_yuksek_etkili.md](referans/gorevler/02_yuksek_etkili.md)
- **Bağımlı:** 7
- **Son not:** city_view.gd (983 satır) ve screenshot_city.gd silindi; yorum başvuruları CityFront/TravelBand'e çevrildi. Kanıt: şehir CityFront'a geçti (REDESIGN §7.2), kullanıcı önden görünüm istiyor, izometrik dönüş planı yok. DENETİM YANILMIŞ: iso_* eşyaları ölü değil, tools/ui_scenes/ui_kit.py şehir madalyonlarını iso_stable, iso_market_stand_1, iso_house_2, iso_inn, iso_bell_tower'dan üretiyor; 10 iso_* eşyası ve test_props.gd beklentileri tutuldu. Kullanıcı onayı hâlâ açık: istenmezse commit geri alınabilir. CLAUDE.md Art Rules'taki CityView maddeleri 4.2'de. | 2026-10-21 kullanıcı onayı: CityView silinmiş kalsın, izometrik dönüş yok.

<details><summary>Görev metni</summary>

- [ ] **2.3 Ölü `CityView` sınıfını ve bağlı varlıklarını kaldır** (§1A, §1E)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `b756a52`): city_view.gd (983 satır) ve screenshot_city.gd silindi; yorum başvuruları CityFront/TravelBand'e çevrildi. Kanıt: şehir CityFront'a geçti (REDESIGN §7.2), kullanıcı önden görünüm istiyor, izometrik dönüş planı yok. DENETİM YANILMIŞ: iso_* eşyaları ölü değil, tools/ui_scenes/ui_kit.py şehir madalyonlarını iso_stable, iso_market_stand_1, iso_house_2, iso_inn, iso_bell_tower'dan üretiyor; 10 iso_* eşyası ve test_props.gd beklentileri tutuldu. Kullanıcı onayı hâlâ açık: istenmezse commit geri alınabilir. CLAUDE.md Art Rules'taki CityView maddeleri 4.2'de.
  - Dosyalar: `scripts/ui/city_view.gd`, `tests/screenshot_city.gd`, 10 adet `iso_*` eşya, `b10_city.jpg`.
  - İlişkili listeler: `tests/test_props.gd:18-20`, `props.json` girdileri, `tools/waybook_assets.py` ve `waybook_ingest_v2.py`.
  - Bayat yorumlar: §3A'daki 4 CityView yorumu.
  - CLAUDE.md Art Rules'taki CityView maddeleri.
  - **Önce doğrula** (§7 madde 6): izometrik şehre dönüş planı yok mu?

</details>

## Paket P03

### Y-K01 · İki haftalık döngü ve ekranda doğrulanmış “bitti”

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P03 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Kural CLAUDE.md'de, döngü kontrol listesi ve 5 dk çekim listesi yazıldı. Kalan: döngü videosu ve derleme (kullanıcının takvimi). | 2026-10-20: tests/record_loop.gd çekim listesini gerçek sahnelerle oynatıyor; video xx/video/dongu_2026-10-20.avi (4:30, 1280x720 MJPEG, 800 MB, depo dışı; ffmpeg yok, sıkıştırılmadı).

<details><summary>Görev metni</summary>

- [ ] **Y-K01 İki haftalık döngü ve ekranda doğrulanmış “bitti”**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `7083b90`): Kural CLAUDE.md'de, döngü kontrol listesi ve 5 dk çekim listesi yazıldı. Kalan: döngü videosu ve derleme (kullanıcının takvimi).
  - **Öncelik:** P1 · **Dalga:** 1
  - **Ne:** Her döngü sonunda oynanabilir derleme ve 5 dakikalık video. “Bitti” yalnızca ekran görüntüsüyle doğrulanınca denir.
  - **Kabul:** Kural CLAUDE.md'de; her döngünün videosu var.

</details>

### Y-G01 · Stil cümlesi ve bir sayfalık stil rehberi

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Stil cümlesi kullanıcı onaylı; rehber docs/ui/STIL_REHBERI.md (N11).

<details><summary>Görev metni</summary>

- [x] **Y-G01 Stil cümlesi ve bir sayfalık stil rehberi**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): Stil cümlesi kullanıcı onaylı; rehber docs/ui/STIL_REHBERI.md (N11).
  - **Öncelik:** P1 · **Dalga:** 1 · **İlgili:** 12.2e
  - **Ne:** Kullanıcı notu: cümle çok iyi kurgulanmalı. Taslak: “Wayborne, bir kervan kâtibinin defterine ve haritasına mürekkeple çizilmiş bir dünyadır.” Rehber: kâğıt ve mürekkep renk kodları, 3 ton kuralı, kontur kalınlığı, tarama yönü, tek sıcak ışık ve vinyet, kırmızı yalnızca kan, kayıp ve ana eylem, kehribar yalnızca ışık. Cümle ve rehber görsel örneklerle kullanıcı onayına sunulur.
  - **Kullanıcı notu:** “evet ama bu cümle çok iyi kurgulanmalı.”
  - **Kabul:** Onaylı stil cümlesi ve rehber `docs/` altında; §9 ve §12 rehbere bağlandı.
  - **Literatür:** R58

</details>

### 4.2 · Bayat belgeleri düzelt

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P03 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/04_kod_kalitesi.md](referans/gorevler/04_kod_kalitesi.md)
- **Son not:** README (sekiz stat, borç ve ölüm kuralı, 56 paket, faz durumu, util ve config), REDESIGN durum satırı, event-window-blueprint durum satırı; CLAUDE.md'de CityView, silinen anahtarlar ve görsel, hedef platform, codex sayıları, scripts/util (commit 2b13dcc).

<details><summary>Görev metni</summary>

- [x] **4.2 Bayat belgeleri düzelt** (§3B)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `85c337b`): README (sekiz stat, borç ve ölüm kuralı, 56 paket, faz durumu, util ve config), REDESIGN durum satırı, event-window-blueprint durum satırı; CLAUDE.md'de CityView, silinen anahtarlar ve görsel, hedef platform, codex sayıları, scripts/util (commit 2b13dcc).
  - README: stat sayısı, borç, ölüm, paket sayısı, faz durumu.
  - `REDESIGN.md:3`.
  - CLAUDE.md'deki 5 yanlış cümle.
  - `event-window-blueprint.md`.

</details>

### 6.3 · `CLAUDE.md`'yi incelt

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/06_depo_hijyeni.md](referans/gorevler/06_depo_hijyeni.md)
- **Son not:** Development Status'un Ana Hedefler sonrası kısmı (2130 satır, 148 KB) docs/history/FAZ_ANLATILARI.md'ye metin değişmeden taşındı; kayıpsızlık betikle doğrulandı. CLAUDE.md 480 KB'dan 332 KB'a indi. Kural bölümlerine (Art Rules, Wardrobe vb.) dokunulmadı: onlar kural ve gerekçe iç içe, ayıklamak kullanıcı onayı ister. Koddaki 'bkz. CLAUDE.md Faz N' başvuruları artık history dosyasına bakıyor.

<details><summary>Görev metni</summary>

- [x] **6.3 `CLAUDE.md`'yi incelt** (H-11, 475 KB)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `2b13dcc`): Development Status'un Ana Hedefler sonrası kısmı (2130 satır, 148 KB) docs/history/FAZ_ANLATILARI.md'ye metin değişmeden taşındı; kayıpsızlık betikle doğrulandı. CLAUDE.md 480 KB'dan 332 KB'a indi. Kural bölümlerine (Art Rules, Wardrobe vb.) dokunulmadı: onlar kural ve gerekçe iç içe, ayıklamak kullanıcı onayı ister. Koddaki 'bkz. CLAUDE.md Faz N' başvuruları artık history dosyasına bakıyor.
  - Kurallar kalsın; faz anlatılarını `docs/history/` altına taşı.
  - **Kullanıcı onayı** iste.

</details>

### Y-J05 · AI beyanını ve CREDITS'i düzelt

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Ses künyesi ve lisans testi eklendi. Kalan (kullanıcı): iki müzik parçasının kaynağı.

<details><summary>Görev metni</summary>

- [x] **Y-J05 AI beyanını ve CREDITS'i düzelt**
  - **Kapandı (2026-10-21):** Ses künyesi ve lisans testi var; kaynağı belirsiz iki müzik parçası kullanıcı kararıyla silindi, `AI_DISCLOSURE.md` "oyunda müzik yoktur" diyor, künyede BEKLENİYOR satırı kalmadı (`tests/test_audio_credits.gd` bunu zorluyor). Yeni müzik gelirse (Y-I02) künyesiyle gelir.
  - **Öncelik:** P1 · **Dalga:** 1
  - **Ne:** `AI_DISCLOSURE.md` hâlâ “bütün görseller prosedürel” diyor; düzeltilir: AI görselleri, AI sesleri, 3B render'lar, CC0 paketler. Kullanıcı notu: kullanılan CC0 üreticileri de CREDITS'e eklenir (zorunlu olmasa da).
  - **Kullanıcı notu:** “tamamdır, buraya kullandığımız co0 üreticileri de eklemek gerekir bence belki zorunlu olmasa bile.”
  - **Kabul:** Beyan ve CREDITS güncel; her CC0 paketin üreticisi ve bağlantısı listede.
  - **Kaynaklar ve teknik (CC0 araştırması):** Künye düzeni: tek bir künye kaydı (dosya, kaynak, yazar, URL, lisans, lisans sayfası, indirme tarihi, değişiklik); ses için `audio/CREDITS.csv` ve derlemede NC ya da Sampling+ lisansı görünce duran kontrol; Quaternius indirmelerinde tarih ve lisans sayfası ekran görüntüsü (CC0 ile QAL ayrımı); OFL ve MIT metinleri dağıtım klasörüne; CC-BY varlıklar oyun içi Credits ekranında zorunlu. `../ICERIK_IHTIYACLARI.md` L bölümü.
  - **Literatür:** R67, R68, R71

</details>

## Paket P04

### 11.1 · `RoadSignals` kaydedilmiyor; sefer ortasında kayıt yüklenince açık işaretler kayboluyor

- **Durum:** bitti · **Öncelik:** P0 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/11_hatalar.md](referans/gorevler/11_hatalar.md)
- **Son not:** Açık işaretler JourneyController'a taşındı ve sefer kaydında 'signals' alanı olarak yazılıyor; eski kayıtta alan yoksa boş liste. Yeni paket RoadSignalsSave (tür ve yaş birebir, kayıt dosyasından geçiş, eski kayıt, yüklemeden sonra büyüme); alan okuma satırı çıkarılınca 4 doğrulama kırılıyor (mutasyonla doğrulandı).

<details><summary>Görev metni</summary>

- [x] **11.1 `RoadSignals` kaydedilmiyor; sefer ortasında kayıt yüklenince açık işaretler kayboluyor.**
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `133f20d`): Açık işaretler JourneyController'a taşındı ve sefer kaydında 'signals' alanı olarak yazılıyor; eski kayıtta alan yoksa boş liste. Yeni paket RoadSignalsSave (tür ve yaş birebir, kayıt dosyasından geçiş, eski kayıt, yüklemeden sonra büyüme); alan okuma satırı çıkarılınca 4 doğrulama kırılıyor (mutasyonla doğrulandı).
  - **Gelen uyarı, aynen:** "RoadSignals kaydedilmiyor. Sefer ortası kayıt yüklenince açık işaretler kayboluyor. Omen ve adlı işaretten önce düzeltilmeli."
  - **Kanıt:**
    - Açık işaretler `RoadSignals.open_signals` (`scripts/travel/road_signals.gd:83`) içinde tutuluyor.
    - O nesne yalnız yol ekranında yaşıyor: `scripts/ui/road_journey.gd:369` `var _signals := RoadSignals.new()`; `:1472` `_signals.clear()`.
    - Sefer kaydını yazan `GameSession._journey_save_block()` (`scripts/autoload/game_session.gd:3084-3095`) yalnızca şunları içeriyor: `origin_id`, `destination_id`, `total_days`, `days_remaining`, `danger_level`, `caravan`, `controller`. İşaretler yok.
    - Yükleme: çağrı `:3285`, fonksiyon `_load_journey_block()` `:3097`.
  - **Çözüm:**
    1. `RoadSignals`'a `to_dict()` / `from_dict()` ekle: `open_signals` (tür, bölge, yaş/saat, büyüme durumu) ve RNG tohumu ya da sayaç.
    2. `_journey_save_block()` içine `"signals"` alanı olarak yaz.
    3. Yükleme sırasında `road_journey.gd` ekranı `_signals`'ı oturumdaki kayıttan kursun, `clear()` ile sıfırlamasın.
    4. Eski kayıtlarda alan yoksa boş listeyle başlasın; geriye dönük uyumluluk testi olsun.
  - **Öncelik:** "Omen" ve "adlı işaret" özelliklerinden önce yapılmalı, çünkü onlar da aynı açık işaret listesine dayanacak.
  - **Test (zorunlu):** `tests/` altında yeni bir paket:
    - (a) Sefer başlat, en az bir işaret açılana kadar ilerle (tohumlu RNG).
    - (b) `to_save_dict()` → `from_save_dict()` ile kaydet ve yükle.
    - (c) Açık işaret türleri ve yaşları birebir aynı mı?
    - (d) Yüklemeden sonra işaret, ihmal edilince yine büyüyor mu?
    - (e) `signals` alanı olmayan eski kayıt yükleniyor mu?
  - Ardından `godot --headless --script res://tests/run_tests.gd` çalıştır; CI'daki betik-hatası taraması da geçmeli.

</details>

### 12.2d · Kervanın altında, yerde ağaç kütüğü gibi çubuklar görünüyor; anlamsız duruyor

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** Kullanıcı 12.2d şeritlerinin kalmasını onayladı.

<details><summary>Görev metni</summary>

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

### 2.2 · Yol ekranında her karede yapılan metin üretimini kaldır

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/02_yuksek_etkili.md](referans/gorevler/02_yuksek_etkili.md)
- **Son not:** Koşullar satırı, ilerleme ipucu, emir paneli ve tüccar satırı yalnızca girdi (biyom, hava, tempo, dil...) değişince metin kuruyor.

<details><summary>Görev metni</summary>

- [x] **2.2 Yol ekranında her karede yapılan metin üretimini kaldır** (§4 O-2)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `6f3fdca`): Koşullar satırı, ilerleme ipucu, emir paneli ve tüccar satırı yalnızca girdi (biyom, hava, tempo, dil...) değişince metin kuruyor.
  - Üç yer: `road_journey.gd:2223` (`_refresh_conditions`), `:1267` (`_refresh_command_panel`), `:2152` (ilerleme tooltip'i).
  - Metni yalnızca gösterilen değer değişince yeniden kur. Dosyanın kendi yorumu (`:2161-2165`) bunu zaten istiyor.

</details>

### 2.5 · Stres ve moral düştükçe gelen yıpranma efektini kaldır

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P04 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/02_yuksek_etkili.md](referans/gorevler/02_yuksek_etkili.md)
- **Son not:** Cam çatlağı efekti, crack_overlay.png, üreticisi ve testleri kaldırıldı. KULLANICI KARARI BEKLİYOR: açlık kenar lekesi g11_edge_scorch de kalksın mı. | 2026-10-20 kullanıcı kararı: açlık kenar lekesi (g11_edge_scorch) de KALKSIN. | 2026-10-20: tam test koşusu 0 kalan.

<details><summary>Görev metni</summary>

- [ ] **2.5 Stres ve moral düştükçe gelen yıpranma efektini kaldır** (kullanıcı isteği, 2026-10-17)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `74b3a1a`): Cam çatlağı efekti, crack_overlay.png, üreticisi ve testleri kaldırıldı. KULLANICI KARARI BEKLİYOR: açlık kenar lekesi g11_edge_scorch de kalksın mı.
  - **Efekt:** Yol HUD'undaki `SurvivalGauge` şişelerinin "cam çatlağı". Moral, stres, açlık ve yorgunluk kötüleştikçe `crack_overlay.png` belirginleşiyor.
  - **Kod:** `scripts/ui/grim/survival_gauge.gd`
    - `:6-7` ve `:21-22` (yorum ve `CRACK_FROM`)
    - `:102-103` (`crack_amount`)
    - `:178-183` (çizim)
  - **Testler:** `tests/test_grim_ui.gd:31-37` (`crack_amount` testleri) ve `:111` (`crack_overlay.png` varlık listesi).
  - **Varlık:** `data/assets/ui/grim/crack_overlay.png`. Başka kullanıcısı kalmazsa sil; `tools/grim_ui_assets.py` de onu üretiyorsa oradan da çıkar.
  - **Kural:** Bilgi kaybı yok. Sayı ve sıvı seviyesi aynı gerçeği göstermeye devam ediyor (SurvivalGauge "sayı kaybolmuyor" kuralı).
  - **Kullanıcıya sor:** Yol ekranında bir kenar efekti daha var: açlık arttıkça gelen `g11_edge_scorch.png` lekesi (`road_journey.gd:281`, `:594`, `:3450`). Stres ve don kenar lekeleri daha önce kaldırılmıştı; bu sonuncusu da kalksın mı?
  - CLAUDE.md'deki SurvivalGauge ve Waybook UI Rules maddelerini güncelle.

</details>

## Paket P05

### 10.3 · Vagon sürücüsü hâlâ eski manken modeliyle çiziliyor; yeni mankenlerden olmalı

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10_yol_figurleri.md](referans/gorevler/10_yol_figurleri.md)
- **Bağımlı:** 10.2
- **Son not:** N27 ile kapandı: koltukta gerçek sürücü figürü.

<details><summary>Görev metni</summary>

- [x] **10.3 Vagon sürücüsü hâlâ eski manken modeliyle çiziliyor; yeni mankenlerden olmalı.**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `19555b5`): N27 ile kapandı: koltukta gerçek sürücü figürü.
  - **Yer:** `scripts/ui/art_draw.gd:471` (`wagon_driver_seat`). Arabacı `:541-542` ve `:579` civarında silüet olarak vagonla birlikte çiziliyor (`draw_driver`).
  - **Çözüm:** Arabacıyı vagon çiziminden çıkar. Koltukta oturan gerçek bir `WalkFigure` olarak çiz:
    - yeni manken frame'leri (`BodyFrames`), atanmış tayfa üyesinin beden ve kıyafetiyle,
    - `seated=true` ve `ride` ya da `sit` klibiyle.
  - **Kolaylık:** Kampta figürün koltuktan kalkıp ateşe yürümesi zaten `road_caravan.gd:851` (`_driver_bench_position`) ile aynı noktayı kullanıyor. Geçiş doğal olur.
  - `draw_driver=false` yolu zaten var.

</details>

### Y-G02 · Ortak mürekkep geçişi (NPR)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G01
- **Son not:** Araç ve önce/sonra denemesi hazır; hatlara bağlama onaydan sonra (docs/design_notes/npr_gecisi.md). | 2026-10-20 kullanıcı: bütün hatlarda uygula. | 2026-10-20: eşya ve yol şeritlerine hafif mürekkep (light_pass, 3671325); figürlere oyunda birleşik siluet konturu (parçalar 4 yöne kaydırılıp mürekkep renginde arkaya, iç dikiş yok; kalınlık 0.9-2.2 px). Yol ve karakter ekranında görüntüyle denetlendi.

<details><summary>Görev metni</summary>

- [ ] **Y-G02 Ortak mürekkep geçişi (NPR)**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `afccc63`): Araç ve önce/sonra denemesi hazır; hatlara bağlama onaydan sonra (docs/design_notes/npr_gecisi.md).
  - **Öncelik:** P1 · **Dalga:** 6 · **Bağımlı:** Y-G01
  - **Ne:** Render sonrası tek geçiş: mürekkep konturu, 3 tonlu tarama, kâğıt dokusu. Karakter, hayvan, vagon, kasaba ve yol aynı geçişten çıkar.
  - **Kabul:** Geçiş bütün render hatlarında; önce ve sonra karşılaştırması onaylandı.
  - **Kaynaklar ve teknik (CC0 araştırması):** Sprite'lar Blender'da çevrimdışı pişirilir (Blender çıktısı serbest): Line Art ya da Freestyle kontur, compositor'da Depth ve Normal üzerinden Sobel kenar → mürekkep konturu, ışık değeri 3 eşiğe bölünüp 45°, yoğun 45° ve 45°+135° tarama, en sonda kâğıt dokusu Multiply. Tek şablon `.blend`: tek sıcak fener ışığı soldan, sabit kamera. Godot tarafında yalnızca kâğıt overlay, fener ışık maskesi ve kırmızı dışı desatürasyon. 3B önizleme için hazır shader'lar: godotshaders “Post-Process Outline (Depth/Normal)” ve “Advanced Hatching” (CC0), “Hatching shader” (MIT, lisans metni dağıtıma). GPLv3 shader kullanılmaz; hexaquo.at kodu (CC BY-SA) kopyalanmaz, yalnızca teknik referans. Tarama dokuları (3 ton, 512² döşenebilir) Krita ya da Inkscape'te kendimiz üretiriz. Kâğıt: TextureCan Paper 0027, 0006, 0024 (CC0), ambientCG Paper (CC0). `../ICERIK_IHTIYACLARI.md` G-4, G-6.
  - **Literatür:** R58

</details>

### Y-G12 · Gardırop: çıplak ten yok, karakterin kendi mankeni yüksek çözünürlükte

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Çıplak ten kısmı yapıldı. Yüksek çözünürlüklü manken yapılmadı: MPFB bu Blender kurulumunda yok ve indirme denenmedi (MPFB ürettiği render CC0 kullanılabilir, kod GPL). | 2026-10-20: WAYBORNE_HD=3 ile idle karesi 3x render (6 beden + giysiler), pack_hd.py ile *_hd kümeleri; WalkFigure.hd duran figürde kullanıyor. Karakter ekranı, gardırop ve konuşma portresi görüntüyle keskin doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-G12 Gardırop: çıplak ten yok, karakterin kendi mankeni yüksek çözünürlükte**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `4250a4a`): Görünüşte boş yuvalar köylü takımıyla çiziliyor. Kalan: gardırop için yüksek çözünürlüklü manken (MPFB gerekli).
  - **Öncelik:** P1 · **Dalga:** 6
  - **Ne:** Varsayılan katman en az keten gömlek ve pantolon. Kullanıcı notu: gardıroptaki manken yoldakinden daha düşük kaliteli görünüyor; gardırop için aynı mankenin daha yüksek çözünürlüklü render'ı gerekir. Standart manken değil, seçili karakterin kendi mankeni.
  - **Kullanıcı notu:** “evet, ayrıca gardroptaki mankenin görüntü kalitesi de iyleştirilmeli. yolda daha az pikselle kaliteli bir manken gösteribliyorken aynı mankeni gardropta gördüğümüzda daha çok pikselde aynı kaliteyi veremiyoruz o yüzden gardropta aynı mankenin daha yüksek çözünürlüküsü olması laızm diye düşünüyorum. (burada dikkat edilmesi gereken şey standart bir manken değil, hangi karakter ise onun mankeni olmalı)”
  - **Kabul:** Gardıropta seçili karakterin yüksek çözünürlüklü render'ı; çıplak ten hiçbir ekranda yok.

</details>

### 5.5 · Gömülü base64 içeren 8 `.gltf` dosyasını `.glb`'ye çevir

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P05 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/05_performans.md](referans/gorevler/05_performans.md)
- **Son not:** Sekiz hayvan .gltf dosyası kayıpsız çevirici (tools/gltf_to_glb.py, JSON aynı ve ikili veri birebir, doğrulandı) ile .glb oldu: 25 MB -> 16 MB. beasts.json ve beast_skin örneği güncellendi; Blender'da Horse.glb içe aktarımı denendi (6 nesne, 13 eylem). Render hattı baştan sona koşturulmadı.

<details><summary>Görev metni</summary>

- [x] **5.5 Gömülü base64 içeren 8 `.gltf` dosyasını `.glb`'ye çevir** (O-12, depodan ~7 MB tasarruf)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `5c47fbd`): Sekiz hayvan .gltf dosyası kayıpsız çevirici (tools/gltf_to_glb.py, JSON aynı ve ikili veri birebir, doğrulandı) ile .glb oldu: 25 MB -> 16 MB. beasts.json ve beast_skin örneği güncellendi; Blender'da Horse.glb içe aktarımı denendi (6 nesne, 13 eylem). Render hattı baştan sona koşturulmadı.

</details>

### 5.4 · Karakter frame atlaslarını sıkı paketle

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P05 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/05_performans.md](referans/gorevler/05_performans.md)
- **Bağımlı:** 6.1
- **Son not:** 2026-10-20: repack_atlas.py (kopya parçalar tek dikdörtgen, ufuk çizgisi paketi, yükseklik 64 katı, sayfa adı içerik özetli); 1139 sayfa/473 Mpx -> 295/182 Mpx, disk 163->128 MB. Bütün paketleyiciler sonunda çağırıyor. İçe aktarma: --headless --import (iki kez) ya da --editor --quit-after; meşgul makinede 3000 kare yetmiyor.

<details><summary>Görev metni</summary>

- [ ] **5.4 Karakter frame atlaslarını sıkı paketle** (O-3)
  - En yüksek VRAM ve indirme kazancı burada: doluluk %18,7, sayfa sayısı 3–5 kat azalabilir.
  - Önce hücre gerekçesini doğrula (§7 madde 9).
  - LFS'ten (6.1) sonra yap, çünkü tüm frame setleri yeniden yazılacak.

</details>

## Paket P06

### 8.9 · Harita kodunu depoya ekle

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Son not:** Harita hattı tools/worldmap altında (atlas, cm, zemin, mapview). Üç mutlak yol göreli; referans oyun adları, ih_mezra (ih_mezra) ve referans oyun değişkenleri temizlendi (kcd klasörü zemin oldu). Büyük ara veriler depo dışında. YAPILMADI: hattın baştan sona yeniden koşturulması (yalnızca py_compile). fields.npz LFS kararı 6.1'e bağlı. | 2026-10-20: hat baştan sona koşturuldu (tools/worldmap/run_all.sh, çıktı Harita_Calismasi/rerun_1020). v3_final ile ortalama piksel farkı 10,8: kıyı, dağ, orman, kent, ad aynı. Kalan: elle kesilmiş roads katmanı kodda yok (kervan yolu kalın çizgisi eksik), birkaç kent ayak izi farklı. Bulunan iki hata: kcd->zemin adlandırması world_kcd.json girdisini kırmıştı; CM_PEAKS/CM_RELIEF betiğe yazıldı.

<details><summary>Görev metni</summary>

- [ ] **8.9 Harita kodunu depoya ekle.**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `04f0db7`): Harita hattı tools/worldmap altında (atlas, cm, zemin, mapview). Üç mutlak yol göreli; referans oyun adları, ih_mezra (ih_mezra) ve referans oyun değişkenleri temizlendi (kcd klasörü zemin oldu). Büyük ara veriler depo dışında. YAPILMADI: hattın baştan sona yeniden koşturulması (yalnızca py_compile). fields.npz LFS kararı 6.1'e bağlı.
  - Kod ve veri hattı (`kcd/`, `atlas/`, `cm/`) şu an yalnızca `Harita_Calismasi/` altında; depoda `tools/worldmap/` gibi bir yere alınmalı.
  - Büyük ara veriler (`fields.npz` vb.) LFS'e ya da depo dışına.
  - Betiklerdeki `D:/…` yolları göreli yapılmalı.

</details>

### 8.1 · Harita ekranını yeni haritayla değiştir

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P06 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Son not:** Harita ekranı yeni haritada (WorldMapView, MapTileView); N7 ile kapandı.

<details><summary>Görev metni</summary>

- [x] **8.1 Harita ekranını yeni haritayla değiştir.**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b4a41c2`): Harita ekranı yeni haritada (WorldMapView, MapTileView); N7 ile kapandı.
  - **Bugünkü durum:** Oyundaki dünya haritası (`scenes/game/world_map.tscn`, `scripts/ui/world_map.gd`, `scripts/travel/world_map_data.gd`) yer tutucu `b6_map` parşömenini kullanıyor.
  - **Yeni harita:** Tek parça 16k bir doku GPU doku sınırını (çoğu kartta 16384) zorlar ve gereksiz VRAM tutar. Kullanılacak olan `../harita_final/goruntuleyici/t/<seviye>/<x>_<y>.jpg` karo piramidi: 1024 px karolar, 5 seviye (seviye 4 tam çözünürlük).
  - **Uygulama:** Godot'ta yakınlığa göre seviye seçen ve yalnızca görünen karoları yükleyen bir karo katmanı.
  - **Yer:** Karoları `data/assets/map/tiles/` altına koy; LFS'e alınması önerilir (§6.1).
  - **Kabul kriteri:** Sürükleme ve kaydırmayla yakınlaşma çalışıyor; tam yakınlıkta yazılar okunur; mobilde bellek sınırı içinde kalıyor.

</details>

### 8.2 · Oyuncunun konumunu haritada göster ve takip et

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P06 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Bağımlı:** 8.1
- **Son not:** Atlı kervan 8 yönlü, yolda yolun üstünde; Kervana git düğmesi ve açılır harita onu ortalar (N7, N24). Gölgesi 19555b5.

<details><summary>Görev metni</summary>

- [x] **8.2 Oyuncunun konumunu haritada göster ve takip et.**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b4a41c2`): Atlı kervan 8 yönlü, yolda yolun üstünde; Kervana git düğmesi ve açılır harita onu ortalar (N7, N24). Gölgesi 19555b5.
  - **İşaret:** At ve binici, `../harita_final/isaret_atli/atli_<yön>_<px>.png`.
    - 8 yön: `K`, `KD`, `D`, `GD`, `G`, `GB`, `B`, `KB`. Gidiş yönüne göre seçilir; formül `../harita_final/BENIOKU.md` içinde.
    - Bağlama noktası `atli_yonler.json` dosyasındaki `anchor`.
    - Kullanıcı onaylı tasarım ve kararlar: `../belgeler/ATLI_ISARET.md`.
    - Sürüm 1 sabit karelerden oluşuyor. İleride yürüme animasyonu istenirse `rider_marker.py`, at modelinin animasyon karelerinden aynı yöntemle render edebilir.
  - **Konum kaynağı:** Kervanın dünya konumu. Seyahatte iki yerleşim arasındaki yol parçası boyunca, ilerleme oranıyla enterpolasyon yapılır (8.3'teki yol grafiği).
  - **Arayüz:** "Kervana git" düğmesi. Harita açılınca kervan ortalanır.
  - **Referans:** Görüntüleyicideki davranış (`goruntuleyici/index.html`) bunun basit bir örneği.

</details>

### 8.3 · Oyun dünyasını `wayborne_harita.geojson` üzerine oturt

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P06 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Bağımlı:** 8.1
- **Son not:** Oyun dünyası wayborne_harita.geojson'dan (N1-N6): 27 yerleşim, 41 yol, süreler; arazi de haritadan (N28, 2c8be40).

<details><summary>Görev metni</summary>

- [x] **8.3 Oyun dünyasını `wayborne_harita.geojson` üzerine oturt.**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `887fa0c`): Oyun dünyası wayborne_harita.geojson'dan (N1-N6): 27 yerleşim, 41 yol, süreler; arazi de haritadan (N28, 2c8be40).
  - **Yerleşimler:** Oyundaki şehir ve yer kimliklerini (`test_loc_a…e`, `world_places.json`) GeoJSON `place_<n>` kimlikleriyle eşle.
  - **Seyahat:** Seyahat ve rota sistemi `yol` kenarları ile `yol_düğümü` düğümlerinden kurulan grafikte çalışsın.
    - Kenar ağırlığı: `length_px`.
    - Yol sınıfı (ana yol/patika) hız ve tehlikeyi etkileyebilir.
  - **Bölge kuralları:** Kültür bölgesi, orman, dağ ve su gibi kurallar ilgili çokgenlerden sorgulansın: nokta-çokgen testi.
  - **Ölçek:** Koordinatlar görüntü pikseli; dünya ızgarasına dönüşüm `BENIOKU.md` içinde. Oyun içi mesafe ölçeği (piksel başına gün ya da km) tasarım kararı, kullanıcıya sor.
  - **Testler:** Her yerleşimin yol ağına bağlı olduğu (izole yer yok); kaldırılan kervansarayların ve deniz yollarının oyunda da olmadığı.

</details>

### 8.4 · `world_places.json`'ı GeoJSON ile eşitle

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P06 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Bağımlı:** 8.3, 1.1
- **Son not:** Kullanılmayan eski yer listesi kaldırıldı; tek kaynak GeoJSON -> settlements.json.

<details><summary>Görev metni</summary>

- [x] **8.4 `world_places.json`'ı GeoJSON ile eşitle.**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `dc516c6`): Kullanılmayan eski yer listesi kaldırıldı; tek kaynak GeoJSON -> settlements.json.
  - Bugün `data/config/world_places.json` hiçbir kod tarafından okunmuyor ve içinde 12 adet `ih_mezra` var (§1.1, isim kuralı).
  - Harita v3'teki yer listesi (`atlas/places_v3.json`, GeoJSON `yerleşim`) tek doğruluk kaynağı olsun.
  - Kaldırılan kervansaraylar (Tarvessa, Ombrakal) ve taşınan yerleşimler oyunda da güncellenmeli.

</details>

### Y-C01 · Haritanın tamamını oyuna aktar (ya hep ya hiç)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P06 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** 8.1, Y-E06
- **Son not:** Haritanın tamamı oyunda: 341 karo Git LFS ile, bütün yerleşimler ve yollar (N1-N7).

<details><summary>Görev metni</summary>

- [x] **Y-C01 Haritanın tamamını oyuna aktar (ya hep ya hiç)**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b4a41c2`): Haritanın tamamı oyunda: 341 karo Git LFS ile, bütün yerleşimler ve yollar (N1-N7).
  - **Öncelik:** P1 · **Dalga:** 2 · **Bağımlı:** 8.1, Y-E06 · **İlgili:** 8.3, 8.4
  - **Ne:** Kullanıcı kararı: kademeli aktarım yok, haritanın tamamı hemen ve tam kapasiteyle aktarılır. 128 yerin hepsi oynanabilir dünyaya girer. Bölgelere kendi malları, düşmanları ve olayları verilir. Ekonomi, kontrat ve rota tabloları elle yazılmış koddan JSON veriye taşınır. `test_loc_a…e` kimlikleri kalkar. Bu görev 8.3 ve 8.4'ü kapsar ve onlara ekonomi, kontrat ve olay tasarımını ekler.
  - **Kullanıcı notu:** “HAYIR! YA HEP YA HİÇ! BU İŞİ TAM YAPACAĞIZ VE HEMEN YAPACAĞIZ TAM KAPASİTEDE!”
  - **Kabul:** Oyun yalnızca GeoJSON ve JSON veriden kuruluyor; 128 yer yüklenebilir; simülatörler yeni dünyada çalışıyor ve sömürü testleri geçiyor.
  - **Literatür:** R26

</details>

### 8.8 · Atlas sayfasını güncelle

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Son not:** Eski claude.ai atlas sayfası okunamadı; yeni harita, 27 yerleşim (tr/en/zh, tür, kültür, mallar, komşular) ve 41 yol (gün, tehlike, arazi) TODO/belgeler/atlas/ATLAS.md'de. Kervansarayların zh adı veride eksik.

<details><summary>Görev metni</summary>

- [x] **8.8 Atlas sayfasını güncelle.** Yeni harita ve kültüre göre adlar oraya hiç işlenmedi.
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Eski claude.ai atlas sayfası okunamadı; yeni harita, 27 yerleşim (tr/en/zh, tür, kültür, mallar, komşular) ve 41 yol (gün, tehlike, arazi) TODO/belgeler/atlas/ATLAS.md'de. Kervansarayların zh adı veride eksik.

</details>

### 8.6 · Sahne nesne sayısını kontrol et

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P06 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Son not:** Bilgi maddesi: kullanıcı v3'ü onayladı; eylem gerekmiyor.

<details><summary>Görev metni</summary>

- [x] **8.6 Sahne nesne sayısını kontrol et.** Yeniden kurulan sahnede yaklaşık 118.500 nesne var, orijinalde 201.956 vardı. Fark, orijinal sahnenin kodun eski bir sürümüyle üretilmesinden geliyor. Kullanıcı v3'ü onayladı, yalnız bilgi olarak duruyor.
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Bilgi maddesi: kullanıcı v3'ü onayladı; eylem gerekmiyor.

</details>

## Paket P07

### Y-C14 · Başlangıç: babadan borçlu kervan

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P07 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 180 altın, 120 gün, %4 gecikme faizi, -1 itibar (alacaklı akraba); ilk değerler (240/60/%15/-3) kariyeri kilitliyordu. Ölçüm ve kanıt: docs/design_notes/denge_baba_borcu.md; simulate_career 8/8 (kontratçı final 5/8). | 2026-10-19 karar: yeni değerler onaylandı (180/120/%4/-1).

<details><summary>Görev metni</summary>

- [ ] **Y-C14 Başlangıç: babadan borçlu kervan**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `0c1b9d6`): 240 altın, 60 gün, alacaklı lonca; tutar ve vade ölçülecek; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 2 · **İlgili:** Y-D04
  - **Ne:** Kullanıcı notu: kervan oyuncunun değil babasınındır; baba hastalık yüzünden kervanı borçlu olarak devreder. Oyun bu devirle açılır; ana borç ve vadesi ilk dönemin saatidir. Babanın durumu ilk olay zincirine bağlanabilir (iyileşir, ölür, defterde kurucu satırı).
  - **Kullanıcı notu:** “Kervan bizim değil babamızın olsun ve babamız bize devretsin hastalıktan ötürü, borçlu bir şekilde devretmiş olsun ve de.”
  - **Kabul:** Yeni oyun devir sahnesiyle başlıyor; başlangıç borcu ve vadesi testli; kurucu satırı babayı gösteriyor.
  - **Literatür:** R17

</details>

## Paket P11

### Y-A08 · Senaryo sistemi kaldırıldı, konforlu final yok

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P11 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C21
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. 2026-10-31: senaryo (kampanya) sistemi kaldırıldı.

<details><summary>Görev metni</summary>

- [x] **Y-A08 Kampanya: konforlu final yok**
  - **Yapıldı (2026-10-31):** kullanıcı "oyundaki mevcut senaryo sistemini ve kurgusunu kaldır" dedi. `CampaignCatalog`, `CampaignChapter`, bölüm sayacı, şehir özetindeki hikâye bloğu, çeviri anahtarları, Codex bölümü ve kural notları silindi; `simulate_career` bölüme değil sefer sayısına bakıyor.
  - **Öncelik:** P1 · **Dalga:** 5 · **Bağımlı:** Y-C21 · **Kim:** CO
  - **Ne:** "Kendi hanını kur" gibi bir final yok. Oyun zorluk ve kıtlık içinde geçer; yapılan tek şey kervanı ilerletmek ve ek görevleri başarmak. Kampanya bölümlerinin hedefleri ve metinleri buna göre yeniden yazılır (defter III'teki kampanya metni sorusu da buraya bağlı).
  - **Kullanıcı notu:** "Böyle bir final olmayacak, oyun zorluk ve kıtlık içinde geçecek, şimdilik tek yaptığımız ve yapabildiğimiz kervanı ilerletmek ve ek görevleri başarmak."
  - **Kabul:** Yeni bölüm taslağı onaylandı; `simulate_career` yeniden ölçüldü.

</details>

## Paket P14

### Y-H03 · Her sonucun nedeni, edebi dille

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P14 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Yalnız moral ve stres etki satırları ve dört gösterge ipucu söze çevrildi. Tehlike, erzak, altın, itibar satırları, planlayıcı dökümü, şehir brifingi, karakter ekranı hâlâ sayı. | 2026-10-20: erzak, tehlike, itibar, altın etki satırları da sözle (Wording.change_line). Kalan: planlayıcı dökümü, şehir brifingi, karakter ekranı. | 2026-10-20: kalan kısım (kısa rota satırı, şehir ve karakter ekranı sözleri) yapıldı.

<details><summary>Görev metni</summary>

- [ ] **Y-H03 Her sonucun nedeni, edebi dille**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `6d2c0c2`): Dil kılavuzu docs/design_notes/dil_kilavuzu.md; planlayıcı dökümü ve şehir brifingi sonraki adım.
  - **Öncelik:** P1 · **Dalga:** 6
  - **Ne:** Kullanıcı notu: sayı değil söz. “Moral −10” yerine “Moral düşük: iki gündür aç” gibi edebi, yazılı ifadeler. Sayılar istenirse ipucu kutusunda ikinci planda.
  - **Kullanıcı notu:** “olabildiğince edebi ya da yazılı olarak yazsın, -10 moral yerine moral düşük yazsın gibi.”
  - **Kabul:** Neden satırları ipuçlarında ve defterde; dil kılavuzu yazıldı.
  - **Literatür:** R1, R4

</details>

### Y-H01 · Onboarding'i ilk seferin içine yay

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P14 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C14
- **Son not:** Babadan devir sahnesi (Y-C14) yeni oyunun ilk anı olarak kalıyor; dört konuluk panel yardım düğmesinde. | 2026-10-20 KULLANICI KARARI: çivili ipucu fişleri (FirstTimeHint) metinleriyle kaldırıldı ("iğrenç duruyor"); öğretici notları kullanıcı sonra yazacak. Dört konuluk panel yardım düğmesinde. | 2026-10-20 (son): çivili kâğıt fiş (G8) ipucu baloncuklarından ve pazar fişinden de kalktı, düz panel (46dd8c1). | 2026-10-21 kullanıcı kararı: şimdilik öğretici ve yardım paneli YOK, sonra eklenecek. Dört konuluk panel, Yardım düğmeleri ve F3 kaldırıldı (UI_ONBOARD_*, UI_HELP_*). Madde kapandı; öğretim sonra yeni bir görev olarak açılır.

<details><summary>Görev metni</summary>

- [ ] **Y-H01 Onboarding'i ilk seferin içine yay**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `2001285`): Babadan devir sahnesi (Y-C14) yeni oyunun ilk anı olarak kalıyor; dört konuluk panel yardım düğmesinde.
  - **Öncelik:** P1 · **Dalga:** 6 · **Bağımlı:** Y-C14
  - **Ne:** Dört konuluk panel kalkar. İlk sefer rehberli: ticaret, kontrat, planlayıcı, dikkat, sofra, savaş; her biri ilk karşılaşıldığı anda tek cümleyle. Babadan devir başlangıcıyla (Y-C14) birleşir.
  - **Kabul:** Yeni oyuncu testinde altı konu ilk seferde öğreniliyor.
  - **Literatür:** R78

</details>

## Paket P15

### Y-J04 · Demo ve Next Fest planı

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P15 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-J01T
- **Son not:** Valve kuralı Steamworks sayfasından: fest için oyun çıkmamış olmalı ve çıkış festten sonra planlı; EAya festte girmek festten çıkarır. | 2026-10-19 karar: plan onaylandı.

<details><summary>Görev metni</summary>

- [ ] **Y-J04 Demo ve Next Fest planı**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `7a44c6e`): Valve kuralı Steamworks sayfasından: fest için oyun çıkmamış olmalı ve çıkış festten sonra planlı; EAya festte girmek festten çıkarır.
  - **Öncelik:** P1 · **Dalga:** 7 · **Bağımlı:** Y-J01T
  - **Ne:** Kullanıcı planı: fest öncesi kısıtlı bir sürüm paylaşmak, fest sırasında Erken Erişim tam sürümünü paylaşmak. Dikkat: Next Fest yalnızca henüz çıkmamış oyunlar içindir ve Erken Erişim bir çıkış sayılır; Erken Erişime fest sırasında girilirse oyun festten çıkabilir. Valve'ın güncel kuralları kontrol edilmeli. Öneri: fest boyunca demo, Erken Erişim festten 4–10 hafta sonra. Demo: menüde geri bildirim bağlantısı, yayıncılara önden gönderim.
  - **Kullanıcı notu:** “mantıklı, fest öncesinde kısıtlı bir vers paylaşıp festte erken erişim tam sürümü paylaşabilirim.”
  - **Kabul:** Valve kuralı doğrulandı; demo ve Erken Erişim tarihleri kesinleşti; demo yayında.
  - **Literatür:** R61, R62, R64

</details>

## Paket P16

### N1 · Yerleşim kataloğu (27 oynanabilir yer)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Son not:** 27 yerleşim (12 şehir, 12 kasaba, 3 kervansaray), settlements.json.

<details><summary>Görev metni</summary>

- [x] **N1 Yerleşim kataloğu** (`C`, Y-C01'in parçası)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `c3527b0`): 27 yerleşim (12 şehir, 12 kasaba, 3 kervansaray), settlements.json.
  - `wayborne_harita.geojson` ve `atlas/places_v3.json`'dan 29 oynanabilir yer: kimlik (kararlı, ASCII), tür (şehir, kasaba, kervansaray), kültür, boyut, harita konumu, adlar (tr, en, zh).
  - Çıktı: `data/config/settlements.json`; `world_places.json` bununla eşitlenir (8.4).
  - **Kabul:** Test: 12 + 12 + 5 yer, kimlikler tekil, kültür ve tür dolu.

</details>

### N2 · Yol grafiği

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N1
- **Son not:** 41 yol, tek bağlı graf, her yer en az iki komşulu.

<details><summary>Görev metni</summary>

- [x] **N2 Yol grafiği** (`C`, 8.3 ile birlikte)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `c3527b0`): 41 yol, tek bağlı graf, her yer en az iki komşulu.
  - Haritanın yollarından (kervan yolu ve ara yollar) yerleşimleri bağlayan graf; her kenarın uzunluğu harita pikselinde, güzergâh üzerinden (kuş uçuşu değil).
  - Her yerleşimin en az iki komşusu olsun; hiçbir yer ayrık kalmasın (`RouteConditions`'ın "şehir mühürlenemez" kuralı yeni grafta da geçerli).

</details>

### N3 · Mesafe ölçeği ve süreler

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N2
- **Son not:** Kuzey-güney 61 gün; yollar 2-38 gün, ortanca 8. Rapor docs/design_notes/yerlesimler_rapor.md.

<details><summary>Görev metni</summary>

- [x] **N3 Mesafe ölçeği ve süreler** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `c3527b0`): Kuzey-güney 61 gün; yollar 2-38 gün, ortanca 8. Rapor docs/design_notes/yerlesimler_rapor.md.
  - **Karar:** x = 81 → kuzey ucu ile güney ucu arası **61 gün**.
  - Ölçek, haritanın en kuzeydeki oynanabilir yeri ile en güneydeki arasındaki en kısa yol 61 gün etsin diye bulunur; tüm kenarların günü bundan türer, yuvarlanır.
  - Gün, **kervanın gerçek yürüyüş hızından** (1 gün = 45 sn gerçek zaman, 1x) ölçülür; komşu iki yerleşim arası hedef **5–12 gün** (yaklaşık 4–9 dakika), uçtan uca ~3x/4 gün.
  - Tehlike: bölge, biyom ve yerleşim türünden türer (kervan yolu güvenli, ıssız geçit tehlikeli); tehlikenin dökümü gösterilir (Y-F10).
  - **Kabul:** Tablo (yerleşim çifti, gün, tehlike) sana sunulur; onayla kilitlenir.

</details>

### N4 · Yerleşim kuralları (şehir, kasaba, kervansaray)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N1
- **Son not:** SettlementRules: tesisler, ticaret payı, kasaba temel mal indirimi, kervansaray alış/satış çarpanı; kontrat hedefi yalnız şehir/kasaba.

<details><summary>Görev metni</summary>

- [x] **N4 Yerleşim kuralları** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `887fa0c`): SettlementRules: tesisler, ticaret payı, kasaba temel mal indirimi, kervansaray alış/satış çarpanı; kontrat hedefi yalnız şehir/kasaba.
  - Yukarıdaki tablo koda: `settlements.json` her yerleşimin `facilities` listesini, `trade_share` (ticaret payı), `price_bias` (temel ürün çarpanı), `goods_available` (bulunan mallar) ve `buy_markup`/`sell_markdown` alanlarını taşır.
  - Kontrat panosu ve kontrat varışı yalnızca şehir ve kasabaya bağlanır; kervansaray hiçbir kontratın hedefi olamaz (test).
  - Kasabada lonca ve kervan avlusu düğmesi çıkmaz; kervansarayda lonca çıkmaz, avlu çıkar (test, her tür için ekran düğmeleri).

</details>

### N5 · Mal tablosu

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N1
- **Son not:** tools/worldmap/economy.json.

<details><summary>Görev metni</summary>

- [x] **N5 Mal tablosu** (`C`, kullanıcı Claude'a bıraktı)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f8c9df2`): tools/worldmap/economy.json.
  - Her yerleşimin ürettiği ve aradığı mallar: haritadaki kültür, boyut ve coğrafyadan (kıyı: balık, dağ: demir ve kürk, vadi: tahıl ve şarap). Tablo `goods_by_place.md` olarak bilgi için sunulur.
  - Kasaba: temel mallar (tahıl, balık, kürk, kumaş) ucuz, çeşit az. Kervansaray: nadir ve değişik mallar, alış pahalı, satış ucuz.
  - Çıktı özet tablo `goods_by_place.md`; onaydan sonra `settlements.json`.

</details>

### N6 · Eski beş şehri sök, kayıt göçü

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N1, N2, N4
- **Son not:** Eski beş şehir söküldü; SAVE_VERSION 4, kayıt göçü testli.

<details><summary>Görev metni</summary>

- [x] **N6 Eski beş şehri sök** (`C`, büyük)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `887fa0c`): Eski beş şehir söküldü; SAVE_VERSION 4, kayıt göçü testli.
  - `test_loc_a…e`, `world_map_data.gd`'deki beş şehir ve yedi kenar, ona bağlı olaylar (`near_*` bayrakları, Kurtboğazı ve Demirkapı bölge kadroları, `region_id`), kampanya bölümleri, kontrat teklifleri, lonca vagon görevleri, testler ve ekran yazıları.
  - **Kayıt göçü:** eski kayıttaki `test_loc_*` kimlikleri yeni bir yerleşime eşlenir (`SAVE_VERSION` artar, `_migrate_save`); göç testi.
  - Kampanya bölümlerinin şehir bağımlılıkları yeni yerleşimlere yeniden yazılır.

</details>

### N7 · Harita ekranı: karo, işaretler, atlı kervan

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N2
- **Son not:** WorldMapView: karo, işaretler, yollar, 8 yönlü atlı. Atlının gölgesi 19555b5'te düzeltildi.

<details><summary>Görev metni</summary>

- [x] **N7 Harita ekranı** (`C`, 8.1 ve 8.2 ile birlikte)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b4a41c2`): WorldMapView: karo, işaretler, yollar, 8 yönlü atlı. Atlının gölgesi 19555b5'te düzeltildi.
  - Yeni harita (`MapTileView`, hazır) + yerleşim işaretleri (tür simgesi) + atlı kervan (8 yön) + "Kervana git" düğmesi; yol durumu çizgiye vurur.
  - Karolar (49 MB) oyuna girer: yeni dosyalar Git LFS ile izlenir (geçmiş yeniden yazılmaz).

</details>

### N8 · Denge yeniden ölçümü

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N3, N6
- **Son not:** Kontrat günlük ücreti 14; 8 kervandan 1'i finale ulaşmıyor (politika batışı). docs/design_notes/denge_yeni_dunya.md.

<details><summary>Görev metni</summary>

- [x] **N8 Denge yeniden ölçümü** (`C`, N6 sonrası)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `bf9f5ff`): Kontrat günlük ücreti 14; 8 kervandan 1'i finale ulaşmıyor (politika batışı). docs/design_notes/denge_yeni_dunya.md.
  - Yollar uzayınca erzak vaadi ("doğru stoklayan aç kalmaz"), kontrat süreleri, kampanya temposu ve yolda olay sayısı yeniden ölçülür (`simulate_journeys`, `simulate_career`); ölçüm tabloları CLAUDE.md'ye.
  - Uzun yol, günlük olay sıklığının ve kamp ihtiyacının yeniden ayarını isteyebilir (Y-B02 yol yönetmeni).

</details>

### N9 · Başlangıç yeri

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N1
- **Son not:** Kültüre göre başlangıç adayları; ilk yolu 10 günü geçmeyen şehir/kasaba.

<details><summary>Görev metni</summary>

- [x] **N9 Başlangıç yeri** (`C`, karar verildi)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `887fa0c`): Kültüre göre başlangıç adayları; ilk yolu 10 günü geçmeyen şehir/kasaba.
  - Karakter oluşturmada seçilen kültürün bölgesindeki ya da en yakın bölgedeki rastgele bir şehir veya kasaba; kervansaray değil.
  - Oyunun bugünkü 5 kültürü (göçebe, vadi, dağ, liman, balıkçı) harita bölgelerine eşlenir: göçebe → göçebe boyları (bölgede şehir yok, en yakın şehir/kasaba), vadi → Vadi, dağ → dağ kabileleri ve madenler, liman → güney kentleri, balıkçı → balıkçı köylerine en yakın kıyı şehir ve kasabaları. Tohum yeni oyunun tohumundan (yeniden yükleme değiştirmez).
  - **Açık soru (engellemez):** Haritada 8 kültür var, oyunda 5. Eski imparatorluk ve sınır halkları oynanabilir kültür olsun mu? Sonra sorulacak.

</details>

### N24 · Yolda açılır harita (tuş ve düğme)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N7
- **Son not:** M tuşu ve Harita düğmesi; zaman durur.

<details><summary>Görev metni</summary>

- [x] **N24 Yolda açılır harita** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b4a41c2`): M tuşu ve Harita düğmesi; zaman durur.
  - Yol ekranında bir tuş (öneri M) ve ekranda düğme: haritayı açılır pencerede gösterir, kervan ortada, hedef ve rota işaretli; zaman bu sırada durur (karar paneli gibi). Esc ve düğme kapatır.
  - Aynı bileşen yol panelinin Harita sekmesinde küçük hâliyle (N21).

</details>

### N28 · Yol biyomları haritanın gerçek arazisinden

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N2
- **Son not:** Biyom ve duraklar güzergâhtan ölçülüyor; iki yönden okunuyor. Kullanıcı istedi (2026-10-19).

<details><summary>Görev metni</summary>

- [x] **N28 Yol biyomları haritanın gerçek arazisinden** (`C`)
  - Dağ, bataklık, göl, orman, bozkır güzergâhtan ölçülür; duraklar geçit, köprü ve yoldaki harita noktaları. Ters yönde dizi ters okunur.
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `2c8be40`).

</details>

## Paket P17

### N10 · Veriden kurulan yerleşim menüsü

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P17 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N4
- **Son not:** Levhalar tesis listesinden; olmayan mekân yok.

<details><summary>Görev metni</summary>

- [x] **N10 Veriden kurulan menü** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `887fa0c`): Levhalar tesis listesinden; olmayan mekân yok.
  - `city_map.gd` ve `CityFront` düğme listesini yerleşimin tesislerinden kursun; tesis yoksa düğme yok (disabled-with-reason kuralı yalnızca olan ama kilitli işler için).

</details>

### N11 · Stil rehberi (Y-G01 kapısı)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P17 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Son not:** docs/ui/STIL_REHBERI.md.

<details><summary>Görev metni</summary>

- [x] **N11 Stil rehberi** (`C`, Y-G01)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): docs/ui/STIL_REHBERI.md.
  - Stil cümlesi onaylı (yukarıda). Bir sayfalık rehber: kâğıt ve mürekkep renk kodları, 3 ton kuralı, kontur, tarama, tek sıcak ışık, kırmızı yalnızca kan/kayıp/ana eylem, kehribar yalnızca ışık. `docs/` altına.

</details>

### N12 · İskelet ve ilk örnek yerleşim

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P17 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N10, N11
- **Son not:** Ortak iskelet + tools/ui_scenes/settlement_towns.py.

<details><summary>Görev metni</summary>

- [x] **N12 İskelet ve ilk örnek** (`C`, ekran görüntüsü gösterilir)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): Ortak iskelet + tools/ui_scenes/settlement_towns.py.
  - Ortak iskelet (mekân levhaları, kadro kartları, alt şerit) ve **tek** yerleşimde (öneri: Vastrevar) tam tasarım; ekran görüntüsü onayı.

</details>

### N13 · Şehir menüleri (12)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P17 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N12
- **Son not:** 12 şehir render edildi. Kullanıcı gözüyle onay bekliyor (TODO/KONTROL_BELGESI.md).

<details><summary>Görev metni</summary>

- [x] **N13 Şehir menüleri, 12 yer** (`C`, ekran görüntüsü gösterilir)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): 12 şehir render edildi. Kullanıcı gözüyle onay bekliyor (TODO/KONTROL_BELGESI.md).
  - 3'erli dört parti, her parti senin onayınla. Her şehir kültürünün mimarisinden (göçebe, vadi, dağ, liman, eski imparatorluk, sınır halkı…) türer; lore gerekir (Y-E06).

</details>

### N14 · Kasaba menüleri (12)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P17 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N12
- **Son not:** 12 kasaba render edildi; kasabalar seyrek, ev sayısı artırılabilir.

<details><summary>Görev metni</summary>

- [x] **N14 Kasaba menüleri, 12 yer** (`C`, ekran görüntüsü gösterilir)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): 12 kasaba render edildi; kasabalar seyrek, ev sayısı artırılabilir.
  - Küçük şablon (daha az mekân), yerel arka plan ve yapılar; dört parti.

</details>

### N15 · Kervansaray menüleri (3)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P17 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N12
- **Son not:** 3 kervansaray render edildi.

<details><summary>Görev metni</summary>

- [x] **N15 Kervansaray menüleri, 3 yer** (`C`, ekran görüntüsü gösterilir)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `67c47ba`): 3 kervansaray render edildi.
  - Han avlusu iskeleti, yerel manzara; tek parti.
- **Üretim yolu:** Mevcut hat (`tools/ui_scenes/town_scene.py`, `towns.json`, Blender 4.2 yerelde kurulu) yerleşim başına bir JSON girdisiyle kurulur; elle boyama yok.

</details>

## Paket P18

### N16 · Yol paneli: tasarım ve örnek ekran

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Son not:** Gökyüzü şeridi kalktı, panel altta.

<details><summary>Görev metni</summary>

- [x] **N16 Tasarım ve örnek ekran** (`C`, ekran görüntüsü gösterilir)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Gökyüzü şeridi kalktı, panel altta.
  - Sekmelerin yerleşimi, yazı boyutları ve renkler; önce **statik örnek ekran** (gerçek veriyle ekran görüntüsü), onay sonra kodlama.

</details>

### N17 · Yol paneli iskeleti

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N16
- **Son not:** RoadControlPanel, beş sekme.

<details><summary>Görev metni</summary>

- [x] **N17 Panel iskeleti** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): RoadControlPanel, beş sekme.
  - Üstteki boş gökyüzü şeridinin kaldırılması: `TravelBand` ve `TravelForeground` yüksekliği ve ufuk/zemin çizgisi bu kadar yukarı kayar, güneş/ay yayı ve ağaç hattı yeniden hesaplanır (oranlar `HORIZON_RATIO`, `BAND_HEIGHT`'a göre).
  - Altta alan açılır: sekme çubuğu ve sekme içeriği; bugünkü alt çim şeridi panelin arkasında kalır ya da kırpılır.
  - Farklı ekran boyutlarında (1280×720'den 2560×1440'a) sahne ve panel oranı bozulmaz; ekran görüntüleri onay için.

</details>

### N18 · Kadro sekmesi

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N17
- **Son not:** Kişi kartları + kervanın nabzı (moral, takat, tehlike, erzak).

<details><summary>Görev metni</summary>

- [x] **N18 Kadro sekmesi** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Kişi kartları + kervanın nabzı (moral, takat, tehlike, erzak).

</details>

### N19 · Durum sekmesi

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N17
- **Son not:** Göstergeler, sayılar, dertler kelimeyle.

<details><summary>Görev metni</summary>

- [x] **N19 Durum sekmesi** (`C`, `SurvivalGauge` ince çubuk, 9.9 ile birlikte)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Göstergeler, sayılar, dertler kelimeyle.

</details>

### N20 · Yük sekmesi

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N17
- **Son not:** Vagonlar, mallar, kontratlar.

<details><summary>Görev metni</summary>

- [x] **N20 Yük sekmesi** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Vagonlar, mallar, kontratlar.

</details>

### N21 · Harita sekmesi

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N17, N7
- **Son not:** Küçük harita, Büyüt (M), Kervana git.

<details><summary>Görev metni</summary>

- [x] **N21 Harita sekmesi** (`C`, N7'ye bağlı)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Küçük harita, Büyüt (M), Kervana git.

</details>

### N22 · Defter ve emirler sekmesi

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N17
- **Son not:** Son olaylar ve kalıcı emirler.

<details><summary>Görev metni</summary>

- [x] **N22 Defter ve emirler sekmesi** (`C`)
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f405e82`): Son olaylar ve kalıcı emirler.
  - Bugünkü sol-üst emir paneli ve Tab ile açılan `CaravanStatusPanel` buraya taşınır; ikisi tek kapıdan.

</details>

### N25 · Dağ zirvelerindeki düz kesik

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Son not:** Dağ biyomunun uzak katmanı 768 karede yeniden render edildi; road_scene.py biyom başına kare boyu. Kullanıcı ekran görüntüsüyle bildirdi (2026-10-19).

<details><summary>Görev metni</summary>

- [x] **N25 Dağ zirvelerindeki düz kesik** (`C`)
  - Dağ biyomunun uzak katmanı 768 karede yeniden render edildi; road_scene.py biyom başına kare boyu.
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `19555b5`).

</details>

### N26 · Haritadaki atlının gölgesi toynaklara otursun

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Son not:** Gölge ve bağlantı noktası dört toynağın ortasında; 8 yön yeniden üretildi. Kullanıcı ekran görüntüsüyle bildirdi (2026-10-19).

<details><summary>Görev metni</summary>

- [x] **N26 Haritadaki atlının gölgesi toynaklara otursun** (`C`)
  - Gölge ve bağlantı noktası dört toynağın ortasında; 8 yön yeniden üretildi.
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `19555b5`).

</details>

### N27 · Vagon sürücüsü yeni gövdeyle

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Son not:** Koltukta düz silüet yerine gerçek figür (climb_down ilk karesi). Kullanıcı ekran görüntüsüyle bildirdi (2026-10-19).

<details><summary>Görev metni</summary>

- [x] **N27 Vagon sürücüsü yeni gövdeyle** (`C`)
  - Koltukta düz silüet yerine gerçek figür (climb_down ilk karesi).
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `19555b5`).

</details>

### N31e · Tempoya bağlı toz, çamur ve kar

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: toz tempoya bağlı, yağmurda tekerlek çamuru. Kar tozu kaldı. | 2026-10-20: kışın kar savruğu (TravelBand.set_winter), toz tempoya bağlı, çamur sıçrantısı.

<details><summary>Görev metni</summary>

- [ ] **N31e Tempoya bağlı toz, çamur ve kar** (`C`) - toz yoğunluğu yürüyüş hızıyla, yağmurda tekerlek çamuru. (S, P2) §5.

</details>
