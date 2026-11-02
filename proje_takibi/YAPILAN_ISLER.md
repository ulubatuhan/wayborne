# Yapılan işler

Bitmiş ve doğrulanmış (testi ya da kullanıcı onayı geçmiş) görevler. Kod dalı: `wayborne`, `yerel/yapilacaklar-p05-p06` (önceki tur `yerel/yapilacaklar-p01-p04`). Push edilmedi.

Toplam: **189** görev. Belgeler `referans/belge_uret.py` ile `referans/gorevler.json`'dan üretilir.

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

### 1.4 · Belgeleri temizle

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/01_isim_kurali.md](referans/gorevler/01_isim_kurali.md)
- **Son not:** Codex PDF Windows yazı tipleriyle yeniden üretildi; metinde yasaklı sözcük yok (pypdf ile tarandı). | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **1.4 Belgeleri temizle**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8b9db66`): Codex PDF Windows yazı tipleriyle yeniden üretildi; metinde yasaklı sözcük yok (pypdf ile tarandı).
  - `CLAUDE.md`, `README.md`, `docs/ui/REDESIGN.md`, `GELISIM_GECMISI.md` (§6 N-9).
  - `docs/codex/codex_body.py` ve `codex_events_data.py`: oyuncuya dönük PDF metni üretiyorlar, öncelikli.

</details>

### 1.5 · Doğrulama

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/01_isim_kurali.md](referans/gorevler/01_isim_kurali.md)
- **Son not:** git grep sıfır; kural tests/test_naming_rule.gd ile korunuyor. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **1.5 Doğrulama:** `git grep` ile yasak kelime taraması (liste: CLAUDE_BASLANGIC.md) hiçbir sonuç vermemeli. Sonra testleri ve CI'ı çalıştır.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8b9db66`): git grep sıfır; kural tests/test_naming_rule.gd ile korunuyor.

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

### 4.4 · Olay anahtarlarını açık yaz

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P02 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/04_kod_kalitesi.md](referans/gorevler/04_kod_kalitesi.md)
- **Son not:** 2026-10-20: EventCatalog._event başlık ve metin anahtarını açık alıyor (71 çağrı); Düşenler sayfasının hikâye özeti de açık tablodan (CampStory.STORY_LINE_KEYS). Kullanıcıya sorulmadı: kural CLAUDE.md'de zaten açık. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **4.4 Olay anahtarlarını açık yaz** (§3D)
  - `event_catalog.gd:2173` anahtarları `"%s_TITLE"` ile çalışma anında kuruyor; CLAUDE.md kuralı bunu yasaklıyor.
  - Kasıtlı bir istisna olup olmadığını kullanıcıya sor.

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

### Y-A01 · Oyun vaadini yaz ve belgelere işle

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Tasarım belgesi ve Steam metni taslağı yazıldı; vaat cümlesi onay bekliyor. | 2026-11-01 kullanıcı onayı.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Görev şablonuna zorunlu 'Sütun' satırı eklendi. | 2026-11-01 kullanıcı onayı.

<details><summary>Görev metni</summary>

- [ ] **Y-A02 Dört tasarım sütununu yazıya dök**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `7083b90`): Görev şablonuna zorunlu 'Sütun' satırı eklendi.
  - **Öncelik:** P1 · **Dalga:** 1 · **İlgili:** 6.3
  - **Ne:** Yol yaşar · İnsanlar aşınır · Defter unutmaz · Ticaret bilgi oyunudur. CLAUDE.md'nin başına “Sütunlar” bölümü olarak eklensin; her yeni sistem en az birine hizmet ettiğini belirtsin. Kullanıcının “derinleşme, asla sadeleştirme” ilkesi sütunların üstünde durur.
  - **Kabul:** Sütunlar CLAUDE.md'de; yeni görev şablonunda “hangi sütun” satırı var.
  - **Literatür:** R6, R10

</details>

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

### Y-F11 · CLAUDE.md'yi kayıpsız incelt

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 243 satır (CityView ve eski menü arka planı tarihçesi) arşive taşındı; dersler iki maddede kaldı. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-F11 CLAUDE.md'yi kayıpsız incelt**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `7083b90`): 243 satır (CityView ve eski menü arka planı tarihçesi) arşive taşındı; dersler iki maddede kaldı.
  - **Öncelik:** P2 · **Dalga:** 1 · **İlgili:** 6.3
  - **Ne:** Kullanıcı notu: mevcut olmayan ve eski ayrıntılar kaldırılabilir, mevcut sistem daha sade ve öz anlatılabilir, ama bilgi kaybı olmamalı. Çıkarılan her bölüm `docs/arsiv/` altına taşınır.
  - **Kullanıcı notu:** “mevcut olmayan, eski detaylar kaldırılabilir ya da mevcut sistem daha sade ve öz bir şekilde açıklanabilir ama kayıp yaşanmamalı burada.”
  - **Kabul:** CLAUDE.md kısaldı; çıkarılan metin arşivde; hiçbir geçerli kural kaybolmadı (fark listesi kullanıcıya sunuldu).

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

### Y-J13 · Yerelleştirme sırası ve terim sözlüğü

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P03 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Çeviri sırası ve 50 terimlik sözlük. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-J13 Yerelleştirme sırası ve terim sözlüğü**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `7083b90`): Çeviri sırası ve 50 terimlik sözlük.
  - **Öncelik:** P2 · **Dalga:** 5
  - **Ne:** Önce İngilizce ve Türkçe, sonra Basitleştirilmiş Çince, Almanca, Rusça. Metin hacmi büyümeden terim sözlüğü.
  - **Kabul:** Terim sözlüğü; çeviri sırası belgede.
  - **Literatür:** R39

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

### 12.2c · Kamp: karakterler ateşe çok yavaş yürüyor (3x'te bile); ateşe varana kadar sabah oluyor; ateş ilk varan kişiyle yansın

- **Durum:** bitti · **Öncelik:** P0 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** Ateş sesi (tutuşma + çıtırtı döngüsü, prosedürel) eklendi; ekranda ve kulakla doğrulanacak. | 2026-11-01: ölçüldü; yürüyüş 2,4 oyun saati yiyordu, kurulum/söküm yürüyüşünde saat CAMP_WALK_CLOCK_SCALE (0.2) ile akıyor, test sınırı 0,5 saat. Yoldaki kamp alevi render konisi yerine katmanlı dalgalanan diller. Kapandı. | 2026-11-02 kullanıcı: yarım oyun saati hedefi kullanıcının değildi; asıl ölçüt T16-01.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** Kod ve test önceki turda; gözle doğrulanacak. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **12.2b Yol üstündeki kule (durak), kamp kurulduktan sonra kadrajdan bir anda kaçıyor.**
    - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `0b5e4b6`): Kod ve test önceki turda; gözle doğrulanacak.
    - **Gözlem (kullanıcı):** Yolda giderken karşıya bir kule çıkıyor; kamp kuruluyor; ardından kule bir anda kadrajdan kayboluyor.
    - **Yer:** Durak çizimi `travel_band.gd:951-1006` (`STOP_SPRITES`, karakol kulesi `:993-1006`).
    - **Olası sebep:** Kamp kurulunca `_layout()` ya da bant kayması yeniden hesaplanıyor (kamp yerleşimi, `road_caravan.gd` `_refresh_gather_targets()` notu), ya da duraklar yolun "önündeki boş alana" göre yerleştirildiği için kamp konumu değişince durak çapası kayıyor.
    - **Çözüm:** Durağın dünya konumu, yol mesafesi cinsinden sabit olsun; kamp ve yeniden düzenleme onu kaydırmasın.
    - **Test:** Kampa girmeden önce ve sonra durağın ekran x'i aynı (ya da yalnızca kamera hareketi kadar farklı).

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

### 5.1 · `_process` döngülerinin gereksiz çalışmasını durdur

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/05_performans.md](referans/gorevler/05_performans.md)
- **Son not:** Ortam animasyonları görünmezken çizilmiyor ve en çok 30 Hz; terazi dengede işlemeyi bırakıyor; kumanda ve geçiş elle denenecek. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **5.1 `_process` döngülerinin gereksiz çalışmasını durdur**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `9d924e7`): Ortam animasyonları görünmezken çizilmiyor ve en çok 30 Hz; terazi dengede işlemeyi bırakıyor; kumanda ve geçiş elle denenecek.
  - `GamepadCursor` kumanda yokken çalışmasın (O-6).
  - `SceneInk` yalnız sahne geçişinde çalışsın (O-7).
  - `SurvivalGauge`, `AshFall`, `SmokeWisps`, `LanternGlow` ve `TradeScales` değer değişmezken yeniden çizmesin (O-8).

</details>

### Y-H04 · Hiçbir ekranda sıkışma kalmasın

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P04 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Paneller Esc'i ele alıyor; karar panelleri yutuyor; yapısal test eklendi. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-H04 Hiçbir ekranda sıkışma kalmasın**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `9c85ade`): Paneller Esc'i ele alıyor; karar panelleri yutuyor; yapısal test eklendi.
  - **Öncelik:** P1 · **Dalga:** 1
  - **Ne:** Her ekrandan Esc ile geri çıkış, sabit kısayollar, tutarlı geri düğmesi. Otomatik testle denetlenir.
  - **Kabul:** Her ekran için geri çıkış testi geçiyor.

</details>

## Paket P05

### 10.1 · Binici atın biraz fazla önünde oturuyor, çok az geriye alınmalı

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10_yol_figurleri.md](referans/gorevler/10_yol_figurleri.md)
- **Son not:** Binici at boyunun %5'i geride; iniş noktası aynı. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10_yol_figurleri.md](referans/gorevler/10_yol_figurleri.md)
- **Son not:** Oturan figürde kol salınımı yok; ride klibi dinlenme karesinde. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10_yol_figurleri.md](referans/gorevler/10_yol_figurleri.md)
- **Son not:** Ok öküzün boynuna uzanıyor, boyunduruk üst katmanda. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

### Y-G03 · Saç ve başlıklar

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P05 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 2026-10-20 kullanıcı: lore'a bağlı değil. | 2026-11-01 kayıt düzeltmesi: DEVAM_NOTU C3: 42 saç kümesi ve 42 HD küme oyunda (sarık/sakal CC0 kaynak bulununca).

<details><summary>Görev metni</summary>

- [ ] **Y-G03 Saç ve başlıklar**
  - **Öncelik:** P1 · **Dalga:** 6 · **İlgili:** 10.1, 10.2, 10.3
  - **Ne:** Kukuleta, kalpak, sarık, başörtüsü, miğfer, şapka; kültürlere göre dağılım. Gerçek dinî figür ya da yapıya gönderme yok.
  - **Kabul:** Yoldaki ve menülerdeki figürlerde kel manken kalmadı.
  - **Kaynaklar ve teknik (CC0 araştırması):** MakeHuman topluluk paketleri: **hair01** (CC0; 25 saç, örgüler), **bodyparts05** (CC0; sakal ve bıyık), **hats01** (CC0; çuval başlık, haydut için), **hats02** (CC0; miğferler, üzerindeki dinî sembol kaldırılıp yeniden dokulanır), **suits02** `monk_robe_hood` (CC0; kesimi sadeleştirilip kervan kukuletası olur). Künye zorunlu (CC-BY): **hats03** `elvs_charity_veil1` (başörtüsü), `mindfront_sherpa_hat` (kalpağa en yakın), **hats04** miğferler, hair02/03, bodyparts06. CC0 türban, sarık ve kalpak yok: Blender'da kapüşon kalıbından, torus ve kumaş simülasyonuyla modellenir; kalpak silindir ve kürk parçacığıyla. Mürekkep geçişinde kürk zaten taramaya döner, düşük detay yeter. `../ICERIK_IHTIYACLARI.md` G-1.

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

### Y-G15 · Vagon ve kurt tek kaynaktan

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P05 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Savaş kurdu kartın rengine çekildi; vagon zaten tek kaynak. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-G15 Vagon ve kurt tek kaynaktan**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8b303d0`): Savaş kurdu kartın rengine çekildi; vagon zaten tek kaynak.
  - **Öncelik:** P2 · **Dalga:** 6
  - **Ne:** Menü, yol, kamp, kapı ve harita işaretinde aynı vagon render'ı; olay kartındaki kurtla savaş kurdu aynı renk ve konturda.
  - **Kabul:** Varlık kaynakları tekilleşti.

</details>

### 5.5 · Gömülü base64 içeren 8 `.gltf` dosyasını `.glb`'ye çevir

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P05 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/05_performans.md](referans/gorevler/05_performans.md)
- **Son not:** Sekiz hayvan .gltf dosyası kayıpsız çevirici (tools/gltf_to_glb.py, JSON aynı ve ikili veri birebir, doğrulandı) ile .glb oldu: 25 MB -> 16 MB. beasts.json ve beast_skin örneği güncellendi; Blender'da Horse.glb içe aktarımı denendi (6 nesne, 13 eylem). Render hattı baştan sona koşturulmadı.

<details><summary>Görev metni</summary>

- [x] **5.5 Gömülü base64 içeren 8 `.gltf` dosyasını `.glb`'ye çevir** (O-12, depodan ~7 MB tasarruf)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `5c47fbd`): Sekiz hayvan .gltf dosyası kayıpsız çevirici (tools/gltf_to_glb.py, JSON aynı ve ikili veri birebir, doğrulandı) ile .glb oldu: 25 MB -> 16 MB. beasts.json ve beast_skin örneği güncellendi; Blender'da Horse.glb içe aktarımı denendi (6 nesne, 13 eylem). Render hattı baştan sona koşturulmadı.

</details>

### 5.2 · Mipmap'leri içe aktarma ayarıyla üret

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P05 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/05_performans.md](referans/gorevler/05_performans.md)
- **Son not:** 2026-10-20: project.godot [importer_defaults] texture mipmaps; içe aktarılmış dokuda çalışma anı kopyası yok; yerel 1537 .import çevrildi ve yeniden içe aktarıldı (596 -> 855 MB önbellek). Commit bd9e560. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **5.2 Mipmap'leri içe aktarma ayarıyla üret** (O-4)
  - Çalışma anındaki `_with_mipmaps` kopyalamasını kaldır.
  - Ayar tüm projeye mi, belirli klasörlere mi uygulanacak, kullanıcıya sor (§7 madde 10).

</details>

### 5.3 · `BodyFrames` önbelleğine çıkarma politikası ekle

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P05 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/05_performans.md](referans/gorevler/05_performans.md)
- **Son not:** LRU çıkarma (96 küme) ve ölçüm raporu. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **5.3 `BodyFrames` önbelleğine çıkarma politikası ekle** (O-9). Önce bellek kullanımını ölç.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `9534722`): LRU çıkarma (96 küme) ve ölçüm raporu.

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

### 8.5 · Yazı ile yolun çakışmasını gider

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Son not:** 126 etikete opak kâğıt halesi, yazı IM FELL; 161+85 karo yeniden yazıldı. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **8.5 Yazı ile yolun çakışmasını gider.** Bazı kent adlarının altından yol geçiyor (örnek: Vastrevar). Yazının arkasına kâğıt renginde bir halo ya da maske ekle; `_text()` ve `_road_raster()` sırası.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `c59fb3a`): 126 etikete opak kâğıt halesi, yazı IM FELL; 161+85 karo yeniden yazıldı.

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

### Y-B13 · Aynı rotada farklı yol: mevsim ve kestirmeler

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C01
- **Son not:** İlkbahar su basar, yaz kurutur, kış dağı yavaşlatır; kestirme -%20 gün, orta üçte bir dağ/orman, tehlike +15 (boş pay); test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-B13 Aynı rotada farklı yol: mevsim ve kestirmeler**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `824187d`): İlkbahar su basar, yaz kurutur, kış dağı yavaşlatır; kestirme -%20 gün, orta üçte bir dağ/orman, tehlike +15 (boş pay); test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** Y-C01
  - **Ne:** Rota tohumu mevsime ve dünya olayına göre değişir; riskli kestirmeler ve alternatif patikalar eklenir. Harita aktarımıyla (Y-C01) birlikte yapılır.
  - **Kabul:** Aynı rota iki farklı mevsimde farklı arazi veriyor; kestirme seçimi planlayıcıda.
  - **Literatür:** R15

</details>

### Y-F10 · Tehlikenin dökümünü göster

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Planlayıcıda taban, yol durumu, dünya olayı, zamanla büyüme; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-F10 Tehlikenin dökümünü göster**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `cefadb6`): Planlayıcıda taban, yol durumu, dünya olayı, zamanla büyüme; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 2
  - **Ne:** Planlayıcıda tehlike yüzdesinin kaynakları: taban, zamanla büyüme, rota durumu, hava, dünya olayı, duman.
  - **Kabul:** Döküm ekranda; değerler motorla birebir.
  - **Literatür:** R1, R4

</details>

### 8.10 · Harita saate göre kararıp aydınlansın (gündüz, akşam, gece)

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Son not:** Çarpan ton katmanı, kararma eğrisi yolun gökyüzüyle aynı; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P06 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/08_dunya_haritasi.md](referans/gorevler/08_dunya_haritasi.md)
- **Bağımlı:** 8.10
- **Son not:** 250 ışık, türe göre (şehir 6-12, kasaba 3-5, köy 1-2, harabe yok); test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P06 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** 8.1, 8.2
- **Son not:** GameSession.map_trail/journey_camps kayıtta; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turunda düzeltildi: kamp işareti renksiz mürekkep çadır.

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

### Y-C10 · Fiyat defteri: bilgi eskir, söylenti yanıltır

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Varışta görülen fiyat yazılır, 20 günden eski soluk; söylenti 2-6 gün eski ve yüzde 25 yanlış; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C10 Fiyat defteri: bilgi eskir, söylenti yanıltır**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `abc9d82`): Varışta görülen fiyat yazılır, 20 günden eski soluk; söylenti 2-6 gün eski ve yüzde 25 yanlış; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 2
  - **Ne:** Görülen fiyatlar tarihli olarak deftere yazılır ve eskir. Taverna dedikodusu başka şehrin fiyatını satar; bazen yanlıştır.
  - **Kabul:** Fiyat defteri ekranı; eskime ve yanlış söylenti testli.
  - **Literatür:** R9, R16

</details>

### Y-C11 · Gizli fiyat katmanlarını görünür kıl

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Satırda kısa etiketler, üstüne gelince katman başına bir cümle; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C11 Gizli fiyat katmanlarını görünür kıl**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `6014abe`): Satırda kısa etiketler, üstüne gelince katman başına bir cümle; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 2
  - **Ne:** Mal satırında mevsim, enflasyon, arz baskısı ve dünya olayı işaretleri; üzerine gelince açıklama (Y-H03'e uygun, edebi dil).
  - **Kabul:** Yedi katmanın her biri ekranda bir işaretle görünüyor.
  - **Literatür:** R1, R4

</details>

### Y-C19 · Mal çeşitliliği: bozulan, kaçak, nadir

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C01
- **Son not:** Al-sat sömürüsü (kendi alımının şişirdiği fiyata geri satış) %90 tavanla kapandı; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C19 Mal çeşitliliği: bozulan, kaçak, nadir**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `9b79738`): Al-sat sömürüsü (kendi alımının şişirdiği fiyata geri satış) %90 tavanla kapandı; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C01
  - **Ne:** Balık ve meyve bozulur; kaçak mal yüksek kâr ve muhafız riski; nadir mal yalnızca özel alıcıya; toplu alım indirimi.
  - **Kabul:** Yeni mal türleri ve kuralları; sömürü testleri geçiyor.
  - **Literatür:** R16

</details>

### Y-B07 · Sofrayı anlamlı karar yap: erzak türleri

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Erzak payı ve planlayıcı sözü değişmedi; çeşni yalnız sofra açıkken; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-B07 Sofrayı anlamlı karar yap: erzak türleri**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `05ce4d8`): Erzak payı ve planlayıcı sözü değişmedi; çeşni yalnız sofra açıkken; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3 · **İlgili:** Y-C19
  - **Ne:** Ekmek, kuru et, tahıl ve şarap gibi erzak türleri farklı etkiler verir (takat, moral, bozulma). Bolluk varken de ara sıra ziyafet akşamı seçimi gelir. Kalıcı emir korunur; sofra yalnızca gerçek bir seçim varken sorulur.
  - **Kabul:** Erzak türleri ekonomi ve sofrada; kalıcı emirle günlük akış bozulmuyor.
  - **Literatür:** R16

</details>

### Y-B06 · Yolda erzak kaynağı: av, toplama, köy

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Av 10 erzak; köy 5 ve 4.7 altın/erzak (şehir 4); toplama +10 erzak, +1 gün; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-B06 Yolda erzak kaynağı: av, toplama, köy**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `fa60be3`): Av 10 erzak; köy 5 ve 4.7 altın/erzak (şehir 4); toplama +10 erzak, +1 gün; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 3
  - **Ne:** Av savaşı erzak getirir; köy durağında erzak alınabilir; toplayıcılık zaman kaybettirir.
  - **Kabul:** Av zaferi erzak ekliyor; köy durağında erzak alımı var; testler var.
  - **Literatür:** R51, R17

</details>

### Y-C02 · Dinamik kontratlar ve yeni kontrat ekranı

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P07 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C01
- **Son not:** Lonca görevleri statik kaldı; teslimatta tüccar yolda yok (tüccar diyaloğu bu kontratlarda anlamsız, onay paketinde not); test TEST_PLANI.md'de. | 2026-11-01 kullanıcı onayı: ekran ve lonca görevlerinin sabit kalması olduğu gibi.

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

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C02
- **Son not:** Hırsız kaçar, çaresiz tehlikede döner, kinci kavga çıkarır, sadık erzak paylaşır; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-F05 Tüccar mizacını yola bağla**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `ee5ea65`): Hırsız kaçar, çaresiz tehlikede döner, kinci kavga çıkarır, sadık erzak paylaşır; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** Y-C02
  - **Ne:** Diyalogla öğrenilen mizaç yolda karşılık bulur: hırsız tüccar gece kaçar, korkak tüccar ilk tehlikede geri döner.
  - **Kabul:** Her mizacın en az bir yol olayı var.
  - **Literatür:** R16

</details>

### Y-C22 · Ahlaki zorunluluk: doğru seçenek yok, bedel bir insana düşer

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P07 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C21
- **Son not:** 2026-10-30 kullanıcı: üç konuşmadan dersler (docs/design_notes/kitlik_tasarim_dersleri.md). Feda kartları, baskın seçenek raporu, aç şehre satma ikilemi, kıtlık paleti. Güç ve ödül kesilmez, bedelli olur (kullanıcı onayı bekleniyor). | 2026-11-01: beş feda kartı, günlükte feda satırı, kıtlık paleti. | 2026-11-01 doğrulama turunda düzeltildi: baskın seçenek 9 -> 0.

<details><summary>Görev metni</summary>

- [ ] **Y-C22 Ahlaki zorunluluk: doğru seçenek yok, bedel bir insana düşer**
  - **Öncelik:** P1 · **Dalga:** 2 · **Bağımlı:** Y-C21 · **İlgili:** Y-E01, Y-B08
  - **Ne:** Kıtlık kartlarında baskın seçenek olmaz; her seçenek bir kaynaktan ya da adı olan bir kişiden bir şey alır. Feda kartları (yaşlıyı köyde bırakmak, hastayı karantinaya almak, bir vagonu aç kasabaya ayırmak), aç şehre yükü satmak ya da satmamak ikilemi, feda kararından sonra günlüğün o kararı anan cümleleri. Görsel dil: kıtlık derecesine bağlı soluk, kontrastlı, kirli palet (dünyada, arayüz okunaklı kalır).
  - **Sınır:** kullanıcının ilkesi (derinleşme, asla sadeleştirme) gereği güç ve ödül sistemleri kesilmez, bedelli olur. Kaldırılacak bir sistem varsa kullanıcı karar verir.
  - **Kullanıcı notu:** "GDC - Lessons from Frostpunk & This War of Mine: Geleneksel ödül ve güçlenme mekaniklerini kaldırarak oyuncuya doğru ya da yanlış seçenekler değil, yalnızca kervan üyelerini feda etmek gibi ağır bedelleri olan ahlaki zorunluluklar sunulmalı; görsel dil ise umutsuzluğu pekiştirecek soluk, kontrastlı ve kirli bir paletle inşa edilmelidir."
  - **Kabul:** `EventQuality` baskın seçenek kontrolü ve raporu; en az beş feda kartı; şehir hâline bağlı palet ekran görüntüsüyle.
  - **Tasarım notu:** `docs/design_notes/kitlik_tasarim_dersleri.md` §1

</details>

### Y-C23 · Yenilmez çevre ve domino zinciri

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P07 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C21
- **Son not:** 2026-10-30 kullanıcı: üç konuşmadan dersler (docs/design_notes/kitlik_tasarim_dersleri.md). Sistemlerin bedelleri birbirini tetikler (aks, yol, erzak, ateş, savaş); kampta son eşyaları yakma eylemleri; zincir dertler listesinde cümleyle görünür. | 2026-11-01: domino zinciri, dertler cümlesi, yönetmen ağırlığı, dört son çare. | 2026-11-01 doğrulama turunda düzeltildi: onay kutuları görünür.

<details><summary>Görev metni</summary>

- [ ] **Y-C23 Yenilmez çevre ve domino zinciri**
  - **Öncelik:** P1 · **Dalga:** 2 · **Bağımlı:** Y-C21 · **İlgili:** Y-B02, Y-B03, Y-C20
  - **Ne:** Soğuk ve kıtlık yenilen bir düşman değil, dayanılan bir şey; atlatılan kış ganimet vermez. Var olan sistemlerin bedelleri birbirini tetikler (kırık aks yolu uzatır, uzayan yol erzağı bitirir, açlık ateşi getirir, ateşli biri savaşta düşer); `RoadDirector` açık zincirin sonraki halkasına ağırlık verir. Kampta son eşyaları tüketme eylemleri: brandayı, tohumluk buğdayı, kürkü, sandığı ve vagon tahtasını yakmak ya da yemek. Zincir dertler listesinde cümleyle görünür.
  - **Kullanıcı notu:** "Jacob Geller - Fear of Cold: Çevresel zorlukların (soğuk, kıtlık) yenilemez bir düşman gibi kurgulanması gerektiği belirtilerek, kervanın yolda yaptığı küçücük bir hatanın kelebek etkisiyle büyük bir felakete dönüştüğü ve oyuncuyu elindeki son eşyaları tüketmeye iten acımasız "domino taşı" mekaniklerinin tasarlanması öneriliyor."
  - **Kabul:** zincir halkaları testli; dört yakma/yeme eylemi kamp panelinde; "doğru stoklayan aç kalmaz" sözü korunur (test_provisions yeşil).
  - **Tasarım notu:** `docs/design_notes/kitlik_tasarim_dersleri.md` §2

</details>

### Y-C24 · Çözülemeyen problem: büyüme yeni kriz doğurur

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P07 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C21
- **Son not:** 2026-10-30 kullanıcı: üç konuşmadan dersler (docs/design_notes/kitlik_tasarim_dersleri.md). Ün ve servet el koyma, haraç, hizip doğurur; bir krizi çözen hamle öbürünü besler; simulate_career denge raporu (sakin sefer dizisi). | 2026-11-01: üç büyüme krizi; simulate_career: dertsiz %25-27, en uzun sakin dizi 4-5. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C24 Çözülemeyen problem: büyüme yeni kriz doğurur**
  - **Öncelik:** P1 · **Dalga:** 2 · **Bağımlı:** Y-C21 · **İlgili:** Y-C15, Y-C17, Y-C12
  - **Ne:** Oyuncu kusursuz dengeye ulaşmaz. Ün artınca aç şehirler yüke el koymak ister, dolu kese haydut ve haraççı çeker, kalabalık kadroda hizipler büyür, çok vagon kıtlıkta çok ağız demek. Bir krizi çözen hamle öbürünü besler; her yeni sistem için "bunu çözen hamle neyi bozuyor?" cevabı yazılır. Final sonrası da dertler büyür.
  - **Kullanıcı notu:** "Adam Millard - How To Design An Unsolvable Problem: Hayatta kalma gerilimini sürekli kılmak için oyuncunun asla kusursuz bir dengeye ulaşamaması gerektiği, kervan büyüdükçe veya zenginleştikçe sistemin otomatik olarak yeni krizler üreterek oyuncuyu daima "tam bir çözümü olmayan" dinamik problemleri yönetmeye mecbur bırakması gerektiği anlatılıyor."
  - **Kabul:** `simulate_career` denge raporu (dertsiz sefer sayısı, en uzun sakin dizi); hiçbir politika uzun sakin diziye ulaşmıyor; en az üç büyüme krizi oyunda.
  - **Tasarım notu:** `docs/design_notes/kitlik_tasarim_dersleri.md` §3

</details>

### Y-C27 · Gokyurt misafirliği

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Gokyurt'ta (gocebe) varışta bir gece konsey öder; varış ekranında satır. | 2026-10-31 onay turu: Onay turunda onaylandı.

<details><summary>Görev metni</summary>

- [x] **Y-C27 Gokyurt misafirliği**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Gokyurt'ta (gocebe) varışta bir gece konsey öder; varış ekranında satır.
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Gokyurt'taki kervansaray ve öbür konaklamalarda bir gün konaklama ve yeme içme ücretsiz; bedeli konsey öder. Öbür kervansaraylarda bu eskiden vardı, kıtlıkta kaldırıldı. Oyunda gün yalnızca yolda aktığı için varışta bir misafir gecesi olarak çevrilir (erzak harcanmadan dinlenme).
  - **Kullanıcı notu:** "Gokyurt'ta yer alan kervansaray ve diğer konaklama imkanlarında bir gün ücretsiz konaklama ve yeme içme konsey tarafından karşılanır. Bu tavır diğer kervansaraylarda da eskiden olsa da bu kıtlık döneminde kaldırılmıştır."
  - **Kabul:** Orbeyan'a varışta misafirlik; öbür kervansaraylarda yok; `denge-olcum` ile ölçüldü.

</details>

### Y-C28 · Yolcu defteri

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C10
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Kervansarayda meyhaneci yolcu defterini okutur: iki yolun haberi. | 2026-10-31 onay turu: Onay turunda onaylandı.

<details><summary>Görev metni</summary>

- [x] **Y-C28 Yolcu defteri**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Kervansarayda meyhaneci yolcu defterini okutur: iki yolun haberi.
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C10 · **Kim:** C
  - **Ne:** Kervansaray tavernasında söylenti şansı yüksek; defterde son geçen kervanların yönü, yol tehlikesi ve tarihli fiyatlar (söylenti yalan olabilir).
  - **Kullanıcı notu:** "Yolcu defteri: Onay."
  - **Kabul:** Kervansarayda bilgi şehirdekinden zengin; test eder.

</details>

### Y-C29 · Tarafsız zemin: Duvenmor

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Yasak mekanizması (ban_location, haritada kilitli planla düğmesi) hazır; kavga kartı kart partisi 1'de onay bekliyor. | 2026-10-31 onay turu: Kavga kartı onaylandı. | 2026-10-31: kart oyunda (EventCatalog, events.csv).

<details><summary>Görev metni</summary>

- [ ] **Y-C29 Tarafsız zemin: Duvenmor**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kavga kartı onaylandı.
  - **Durum (2026-10-31):** kısmen. Yasak mekanizması (ban_location, haritada kilitli planla düğmesi) hazır; kavga kartı kart partisi 1'de onay bekliyor.
  - **Öncelik:** P3 · **Dalga:** 2 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Duvenmor'un içinde kılıç çekilmez; çeken kervan bir daha giremez. Tetikleyici bir yol düşmanlığının kervansarayda sürmesi (rakip kervan, intikamcı tüccar).
  - **Kullanıcı notu:** "Tarafsız zemin: Onay."
  - **Kabul:** Yasak kaydı kayıtta tutulur ve giriş kilitli, nedeniyle görünür.

</details>

### Y-C32 · Bedeli erzakla öde

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Haraç kartında erzakla öde seçeneği (8 erzak, moral -4). | 2026-10-31 onay turu: Onay turunda onaylandı.

<details><summary>Görev metni</summary>

- [x] **Y-C32 Bedeli erzakla öde**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Haraç kartında erzakla öde seçeneği (8 erzak, moral -4).
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Haraç ve bedel kartlarına para yerine erzak seçeneği; ödememek o yolun tehlikesini yükseltir. Gönüllü seçenek, planlayıcının erzak hesabına girmez.
  - **Kullanıcı notu:** "Bedeli erzakla öde: Onay."
  - **Kabul:** Kart seçeneği ve yol tehlikesi testi.

</details>

### Y-C34 · Hacı kafilesine katılmak

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P07 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C25
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31 onay turu: Kullanıcı kararı: kervanın inancı kervanbaşının inancıdır; rol yapma seçeneği Karizma/manipülasyon kontrolüyle. | 2026-10-31: kervanbaşı inancı ve Avuçiçi kafilesi kartı oyunda; ilan panosunda kafile ilanı sonraki adım. | 2026-11-01: inanç ekranda; kafile ilanı (hacı kafilesi Septisist). | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C34 Hacı kafilesine katılmak**
  - **Onay turu (2026-10-31):** açık. Kullanıcı kararı: kervanın inancı kervanbaşının inancıdır; rol yapma seçeneği Karizma/manipülasyon kontrolüyle.
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C25 · **Kim:** CK
  - **Ne:** Avuçiçi yolunda bir kafileye katılma seçeneği: güvenli ama yavaş ve kurallı. Şart aynı inançtan olmak ya da rol yapmak; rol yapan yakalanırsa Avuçiçi'nin El'i taşıyan inançsıza cezası (Ç14'e bağlı). Kervanın inancını tutan bir değer gerekir.
  - **Kullanıcı notu:** "Ek bir seçenek olarak eklenebilir ama aynı dinden olmamız lazım ya da rol yapmalıyız."
  - **Kabul:** Karar: kervanın inancı neye göre belirlenir.

</details>

### Y-C35 · İlan panosu

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C02
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Lonca sekmesi İlan Panosu; kafile ve sürücü ilanları Y-C34'ü bekliyor. | 2026-10-31 onay turu: Kullanıcı (onay turu): Düzenle - menü sekmesi değil, ilanların çivili kâğıt olarak asılı durduğu görünür bir pano olmalı. | 2026-10-31: NoticeBoard - ilanlar tahtaya çivili parşömen plakalar; kasabada pano boş ve nedeni yazar. Kafile/sürücü ilanları Y-C34 ile. | 2026-11-01: kafile ve sürücü ilanları panoda.

<details><summary>Görev metni</summary>

- [x] **Y-C35 İlan panosu**
  - **Onay turu (2026-10-31):** kısmen. Kullanıcı (onay turu): Düzenle - menü sekmesi değil, ilanların çivili kâğıt olarak asılı durduğu görünür bir pano olmalı.
  - **Durum (2026-10-31):** test bekliyor. Lonca sekmesi İlan Panosu; kafile ve sürücü ilanları Y-C34'ü bekliyor.
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C02 · **Kim:** C
  - **Ne:** Kontrat panosunun adı İlan Panosu olur; kafile ve sürücü ilanları da aynı panoda.
  - **Kullanıcı notu:** "Bu ilanlar da kontrat panosunda olabilir. Bu panoya kontrat panosu yerine ilan panosu deriz mesela."
  - **Kabul:** Çeviri anahtarları ve ekran görüntüsü.

</details>

## Paket P08

### R0 · Altyapı

- **Durum:** bitti · **Öncelik:** Öneri · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/10b_yol_deneyimi_onerileri.md](referans/gorevler/10b_yol_deneyimi_onerileri.md)
- **Bağımlı:** 11.1
- **Son not:** Figür-kişi eşlemesi, RoadBalloon, RoadChatter, backstory/rapport, beş yeni defter türü; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **R0 Altyapı:** figür→karakter eşlemesi, `RoadBalloon`, `RoadChatter`, `backstory_id` ve `rapport`, yeni ledger türleri, `GameSession` alanları, yeni `EventEffect` türleri. Ön koşul: `RoadSignals` kaydı eksik (bkz. belge §10 madde 3).
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8d435e1`): Figür-kişi eşlemesi, RoadBalloon, RoadChatter, backstory/rapport, beş yeni defter türü; test TEST_PLANI.md'de.

</details>

### Y-B01 · Yol önerilerini (R0–R1) ana iş olarak uygula

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** 11.1
- **Son not:** R0 ve R1 kodda; R1 görsel onayı ONAY_PAKETI'nde. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** Öneri · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10b_yol_deneyimi_onerileri.md](referans/gorevler/10b_yol_deneyimi_onerileri.md)
- **Bağımlı:** R0
- **Son not:** 15 hikâye (5 geçmiş x 3 bölüm) tr/en; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **R1 İnsanlar:** #1 yanına yürü ve konuş, #3 kamp ateşi hikâyesi, #2 bağlar ve yan yana yürüme, #4 yoldaşların görünür özerk eylemleri.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `dd0d737`): 15 hikâye (5 geçmiş x 3 bölüm) tr/en; test TEST_PLANI.md'de.

</details>

### Y-C17 · Yoldaşın kendi hikâyesi ve ilişkileri

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-B01
- **Son not:** Geçmiş ve hedef her yoldaşta, üç kartlık kişisel zincir kamp hikâyesi olarak, bağ kayıtta; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C17 Yoldaşın kendi hikâyesi ve ilişkileri**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `dd0d737`): Geçmiş ve hedef her yoldaşta, üç kartlık kişisel zincir kamp hikâyesi olarak, bağ kayıtta; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4 · **Bağımlı:** Y-B01 · **İlgili:** R0, R1
  - **Ne:** Geçmiş, kişisel hedef, 2–3 kartlık kişisel zincir; yoldaşlar arası dostluk ve husumet.
  - **Kabul:** Her yoldaşta geçmiş ve hedef; kişisel zincirler; ilişki değeri kayıtta.
  - **Literatür:** R11, R25

</details>

### Y-B03 · İşaretleri bulmacaya çevir: belirsizlik ve bedel

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** 11.1
- **Son not:** Dört tür x 2-3 gerçek; gerçek kayıtta; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-B03 İşaretleri bulmacaya çevir: belirsizlik ve bedel**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `e87e40e`): Dört tür x 2-3 gerçek; gerçek kayıtta; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 3 · **Bağımlı:** 11.1 · **İlgili:** R2
  - **Ne:** İşaretler belirsiz olur (duman köy yangını da olabilir, haydut kampı da). İşarete yürümek bilgi verir ama öbür bölge açık kalır. Aynı anda iki işaret çıkabilir. Kehanet (omen) türü buraya bağlanır.
  - **Kabul:** İşaret türünü görmek çözümü belirlemiyor; kayıt ve yüklemede belirsizlik durumu korunuyor.
  - **Literatür:** R16, R9

</details>

### Y-F09 · Görevler: öncü, ortancı, artçı; sınıflar ayrı

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Tasarım notu docs/design_notes/gorev_rolleri.md; eski kayıt göçü; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Rol sahibi kendi bölgesinde saatlik %3.5 x güç; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** 12.2c
- **Son not:** Öncü +1 stres/gün; nöbet ertesi günün tehlikesini düşürür; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turunda düzeltildi: onay kutuları görünür.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Sessizlik ihtimali artırır, ağır karttan sonra rahatlama, zorda ağır kart seyrek; gece işaret x1.5, ateş/nöbet/ışık önler; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Beş hava, yedi karar; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-B05 Havaya karşı küçük kararlar**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `f92a1cc`): Beş hava, yedi karar; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3
  - **Ne:** Fırtınada sığın, bekle ya da devam et; siste yavaşla ya da fener yak; yağmurda çamurlu kestirme ya da uzun yol. Kart değil, tek tıklık kararlar.
  - **Kabul:** Her hava türü için en az bir karar; açık hava artık tamamen nötr değil.
  - **Literatür:** R16

</details>

### Y-C20 · Fener ya da meşaleyle gece yürüyüşü

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Karanlıkta ışıksız yürüyüş takat ve tehlike bedeli; fener 1 yağ/gece, meşale 2/gece; CC0 fener/meşale modeli ve sesi sonraki tur; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Askerî konvoy (borç ve arama), mülteci (minnet ve yoldaş), hacı (mevcut zincir), rakip tüccar (bilgi satın al, iftira); test TEST_PLANI.md'de. | 2026-11-01 doğrulama turunda düzeltildi: kullanıcı: başka kervanların kendi figürü şimdilik gerekmez.

<details><summary>Görev metni</summary>

- [ ] **Y-B10 Başka kervanlarla karşılaşma**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `b8ba074`): Askerî konvoy (borç ve arama), mülteci (minnet ve yoldaş), hacı (mevcut zincir), rakip tüccar (bilgi satın al, iftira); test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 3
  - **Ne:** Askerî konvoy, mülteci kafilesi, hacı kafilesi, rakip tüccar. Yolda uzaktan görünür; takas, bilgi, yolcu ya da çatışma sunar.
  - **Kabul:** En az 4 kervan türü; her biri yolda görünür ve kendi kart zinciri var.
  - **Literatür:** R11

</details>

### Y-B11 · Yolun hafızası: mezarlar, enkaz, eski kül

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Prosedürel çizim (CC0 model sonraki tur); test TEST_PLANI.md'de. | 2026-11-01 doğrulama turunda düzeltildi: yol hafızası işaretleri büyütüldü.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P08 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 2026-10-20: gün boyu izler (ölüm, vagon, savaş, açlık, hikâye, olay), akşam kampında en ağır izden üç edebi cümle, oyuncu birini seçer ya da yazmaz (DiaryPanel); defterin Düşenler sayfasında görünür. test_waybook_pages. | 2026-11-01 kullanıcı onayı: olduğu gibi kalır (üç hazır cümleden biri ya da hiç; serbest metin yok).

<details><summary>Görev metni</summary>

- [ ] **Y-B08 Günün satırı: akşam kampında defter cümlesi**
  - **Öncelik:** P1 · **Dalga:** 3 · **İlgili:** R3, Y-H03
  - **Ne:** Her akşam günün en önemli olayı tek bir cümleye dönüşür ve deftere yazılır; oyuncu düzeltebilir. Cümleler edebi, sayısız (bkz. Y-H03).
  - **Kabul:** Her kamp bir satır üretiyor; satırlar kayıtta; yerelleştirme anahtarları var.
  - **Literatür:** R12, R11

</details>

### R2 · Hafıza

- **Durum:** bitti · **Öncelik:** Öneri · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10b_yol_deneyimi_onerileri.md](referans/gorevler/10b_yol_deneyimi_onerileri.md)
- **Bağımlı:** R0
- **Son not:** #7 günün cümlesi (Y-B08) kullanıcı kararı bekliyor (serbest metin mi); test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **R2 Hafıza:** #5 ölüler yolda kalır (mezarlar), #7 günün cümlesi, #6 dönüm taşı, #8 yol enkazları, #19 yol seni hatırlar.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `a31c52c`): #7 günün cümlesi (Y-B08) kullanıcı kararı bekliyor (serbest metin mi); test TEST_PLANI.md'de.

</details>

### R4 · Risk

- **Durum:** bitti · **Öncelik:** Öneri · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/10b_yol_deneyimi_onerileri.md](referans/gorevler/10b_yol_deneyimi_onerileri.md)
- **Bağımlı:** R0
- **Son not:** #15 gece yürüyüşü Y-C20'de; #16 v1 kart ve günlük (görsel v2: vagonlar suya girer, sonraki tur); test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **R4 Risk:** #15 gece yürüyüşü, #16 nehir geçidi.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4d5f4ed`): #15 gece yürüyüşü Y-C20'de; #16 v1 kart ve günlük (görsel v2: vagonlar suya girer, sonraki tur); test TEST_PLANI.md'de.

</details>

### Y-B09 · Yolu dolu yap, sonra hızlandırmayı kaldır

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-B01, Y-B02, Y-B03
- **Son not:** Ölçüm hedefi tutmazsa SPEEDS tek satırla geri açılır; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-B09 Yolu dolu yap, sonra hızlandırmayı kaldır**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4017eda`): Ölçüm hedefi tutmazsa SPEEDS tek satırla geri açılır; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 3 · **Bağımlı:** Y-B01, Y-B02, Y-B03 · **İlgili:** 12.2c
  - **Ne:** Kullanıcı kararı: hızlandırma kalkmalı. Yol o kadar dolu ve seyri yüksek olmalı ki oyuncu hızlandırmak istememeli. Adımlar: (1) 1x hızda her 60–90 saniyede en az bir karar ya da bilgi hedefi koy ve simülatörle ölç; (2) B01–B13 ve R0–R5 bu hedefi sağlayınca 1.5x ve 3x hızları kaldır; duraklatma ve yavaşlatma kalır (erişilebilirlik için “olay gelince duraklat”, Y-H07).
  - **Kullanıcı notu:** “Aslına bakarsan hızlandırma kalkmalı. yolda olmak o kadar dolu bir eylem olmalı ki oyuncu oylu hızlandıramamalı, aynı zamanda da ortam o kadar dolu, yoğun, seyri yüksek olmalı ki hızlandırmak istememeli.”
  - **Kabul:** Ölçüm raporu hedefi gösteriyor; hız düğmeleri kaldırıldı; 12.2c'deki “3x'te bile yavaş” sorunu yürüme hızı düzeltilerek ayrıca çözüldü.
  - **Literatür:** R3, R4

</details>

### Y-B14 · Yol kenarı kervansarayları

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Yol kenarı kervansaray durakları (eskimiş, harabe, haydut elinde) yolda ve şeritte; üç kartı kart partisi 1'de onay bekliyor. | 2026-10-31 onay turu: Duraklar onaylandı; üç kart onaylandı. | 2026-10-31: kart oyunda (EventCatalog, events.csv).

<details><summary>Görev metni</summary>

- [ ] **Y-B14 Yol kenarı kervansarayları**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Duraklar onaylandı; üç kart onaylandı.
  - **Durum (2026-10-31):** kısmen. Yol kenarı kervansaray durakları (eskimiş, harabe, haydut elinde) yolda ve şeritte; üç kartı kart partisi 1'de onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Yol üstünde kervansaray durakları: çoğu eskimiş, ücra ama açık; çok azı kapanmış harabe; bazıları haydutların elinde. Oyun metninde "han" denmez, kervansaray denir. Harita verisi (`build_settlements.py`) ve durak kartı düzeni (`near_<durak>`).
  - **Kullanıcı notu:** "Mevcut kervansaraylar içinden, (han demiyoruz) bazıları eskimiş, ücra bir yer haline gelmiş ama hala açık olabilir ya da çok azı kapanmış harabe de olabilir, haydutlar tarafından ele geçirilmiş de olabilir."
  - **Kabul:** Her durak hâlinin kartı ve görünüşü; `test_route_terrain` erzak sözünü yeniden sınar.

</details>

### Y-B15 · Kuyu durağı

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Kuyu durağı: yolda türetilen durak, faydası bir kez. | 2026-10-31 onay turu: Onay turunda onaylandı.

<details><summary>Görev metni</summary>

- [x] **Y-B15 Kuyu durağı**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Kuyu durağı: yolda türetilen durak, faydası bir kez.
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Çöl ve bozkır kesimlerinde kuyu durağı. Yeni bir su kaynağı değil: erzak ve yorgunluk kollarına bağlanır. "Doğru stoklayan aç kalmaz" sözü korunur.
  - **Kullanıcı notu:** "Kuyu durağı: Onay."
  - **Kabul:** `test_route_terrain` her yolda erzak sözünü sınar.

</details>

### Y-B16 · Küçük lütuf anı

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P08 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Kampta nadir an (akşam başına ~0,077, en az 7 gün arayla; test_waybook_pages ölçer), sinema bantları ve tek cümle, günlük o akşam lütfu yazar. tests/screenshot_mercy.gd. | 2026-10-31 onay turu: Onay turunda onaylandı.

<details><summary>Görev metni</summary>

- [x] **Y-B16 Küçük lütuf anı**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Kampta nadir an (akşam başına ~0,077, en az 7 gün arayla; test_waybook_pages ölçer), sinema bantları ve tek cümle, günlük o akşam lütfu yazar. tests/screenshot_mercy.gd.
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Kampta nadir, arayüzsüz, bir an tutulan sahne; ardından günlük cümlesi seçimi (`DiaryPanel`). Nadir olması ağırlığını korur.
  - **Kullanıcı notu:** "Küçük lütuf anı: Onay."
  - **Kabul:** Sıklık `simulate_road_beats` ile ölçüldü; sahne görüntüsü onaylandı.

</details>

## Paket P09

### Y-C07 · Savaştan bedelli geri çekilme

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Yük üçte bir, vagon feda (enkaz yolda), artçı darbe alır; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Reis lideri, kurt en yaralıyı (oran), muhafız Kıyı'dakini bitirmez; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C08 Düşmanlara kişilik ver**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5f32931`): Reis lideri, kurt en yaralıyı (oran), muhafız Kıyı'dakini bitirmez; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 4
  - **Ne:** Haydut reisi önce lideri hedefler, kurt sürüsü yaralıyı kovalar, muhafız teslim olmayı teklif eder, ayı kaçana saldırmaz.
  - **Kabul:** Düşman türü başına davranış profili; testler.
  - **Literatür:** R22

</details>

### Y-D06 · Kırılma: davranışla yaşatılan olay

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Dört kip son kötü huydan; ekran efekti yok; yol kartı; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Tablolar data/config/loot.json; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C03 Ganimet: eşya, kıyafet, sarf, nadir bulgu**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5d4018d`): Tablolar data/config/loot.json; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4
  - **Ne:** Savaş ve olaylardan eşya, kıyafet, iksir ve nadir bulgu düşer. `GRANT_OUTFIT` eklenir; kıyafet ganimete bağlanır.
  - **Kabul:** Zafer ekranında ganimet; ganimet tabloları veri dosyasında; testler.
  - **Literatür:** R79, R5

</details>

### Y-C04 · Sarf malzemesi ve yolda tedavi

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Sargı +8 can ve kanama, iksir +12 can ve Kıyı'da direnç +20; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C04 Sarf malzemesi ve yolda tedavi**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5d4018d`): Sargı +8 can ve kanama, iksir +12 can ve Kıyı'da direnç +20; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4 · **İlgili:** Y-F03
  - **Ne:** Bandaj, iksir ve merhem kampta ve savaşta kullanılır; Ölümün Kıyısı'nda direnç için de kullanılabilir.
  - **Kabul:** Bandaj artık tüketiliyor; savaşta ve kampta kullanım testli.
  - **Literatür:** R16

</details>

### Y-F03 · Atölye ve vagon envanterini anlamlandır

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C04
- **Son not:** Her tarifin tüketicisi RecipeCatalog.OUTPUT_USES'ta; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-F03 Atölye ve vagon envanterini anlamlandır**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5d4018d`): Her tarifin tüketicisi RecipeCatalog.OUTPUT_USES'ta; test TEST_PLANI.md'de.
  - **Öncelik:** P1 · **Dalga:** 4 · **Bağımlı:** Y-C04 · **İlgili:** Y-C20, Y-F04T
  - **Ne:** Gerçek üretim döngüsü: bandaj → tedavi, branda → tamir, av derisi → kıyafet, yağ → fener, meşale. Vagon başına envanter bu döngüye hizmet eder.
  - **Kabul:** Her tarifin oyunda bir tüketicisi var; testler.
  - **Literatür:** R16

</details>

### Y-F04T · Vagon atölyesi ekranını özelleştir

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-F03
- **Son not:** Mantık değişmedi, yalnızca ekran; test TEST_PLANI.md'de. | 2026-11-01 kullanıcı onayı.

<details><summary>Görev metni</summary>

- [ ] **Y-F04T Vagon atölyesi ekranını özelleştir**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4d6fb67`): Mantık değişmedi, yalnızca ekran; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-F03
  - **Köken:** onaylanmayan **F04** önerisinin altındaki kullanıcı notu.
  - **Ne:** Kullanıcı notundan türetildi (hub'ı kaldırma önerisi reddedildi): şehir kapısı şehre girmek, vagona gitmek atölyeye gitmek demek. Hub kalır; asıl iş atölye ekranının vagona özgü, kendine ait bir ekran olması.
  - **Kullanıcı notu:** “şehir kapısına basmak şehre girmek demek. vagona gitmek ise oradaki atölyeye gitmek demek. asıl olması gereken şey vagon atölyesinin ekranını özelleştirmek.”
  - **Kabul:** Atölye ekranı taslağı onaylandı ve uygulandı.

</details>

### Y-C06 · Ekipmanı 12 parçadan 35'in üstüne çıkar

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P09 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:**  | 2026-11-01 kayıt düzeltmesi: DEVAM_NOTU C4: 36 ekipman oyunda (24527c4).

<details><summary>Görev metni</summary>

- [ ] **Y-C06 Ekipmanı 12 parçadan 35'in üstüne çıkar**
  - **Öncelik:** P2 · **Dalga:** 4
  - **Ne:** Ağırlık takılarda: huylarla sinerji kuran, bedeli olan, lanetli parçalar.
  - **Kabul:** En az 35 parça; denge ölçümü güncel.
  - **Kaynaklar ve teknik (CC0 araştırması):** Eşya ikonları: game-icons.net siyah siluetleri mürekkep stiline uygun ama CC BY 3.0 (her ikonun yazarı künyeye). Alternatif: 3B prop render + mürekkep geçişi (Poly Haven, Quaternius Fantasy Props, MakeHuman equipment01: yay, savaş çekici, kaba kılıç, hançer, CC0). `../ICERIK_IHTIYACLARI.md` G-7.
  - **Literatür:** R79

</details>

### Y-C05 · Sakatlık, hastalık, hekim ve ilaç stoğu

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 5 dert; veba şehrinde varışta bulaşma; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** docs/design_notes/moral_ve_takat.md; kod onaydan sonra. | 2026-10-19 karar: not onaylandı; kod yazılacak. | 2026-10-20: kişi başına yorgunluk (0-100), kervanın takati en yorgun kişiye bağlı; normal tempo yavaşlamaz, yalnız hızlı tempo kilitlenir; savaşta küçük isabet/kaçınma cezası. test_fatigue. Commit 4af6c2f. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Pano 1-2 kişi, lonca 1, savaş/vebada -1; fiyat +%30; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Evre 10 ve 25 seferde; pusu, savaş/veba/haraç haberi, rakip kervan, gümrük sıklaşır; yükselen haraç tutarı sonraki tur; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C15 Orta ve geç oyuna yeni tehditler**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `c890afe`): Evre 10 ve 25 seferde; pusu, savaş/veba/haraç haberi, rakip kervan, gümrük sıklaşır; yükselen haraç tutarı sonraki tur; test TEST_PLANI.md'de.
  - **Öncelik:** P2 · **Dalga:** 4
  - **Ne:** Bölge açıldıkça yeni düşman, dünya krizleri (savaş, kıtlık), rakip kervan, yükselen haraç.
  - **Kabul:** Kariyer simülatöründe orta ve geç dönem kazanma oranları hedef aralıkta.
  - **Literatür:** R4, R80

</details>

### Y-F07T · Büyücüyü nadir olay düşmanı olarak bağla

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06
- **Son not:** Ağırlık 0.08, tehlike 0.35+, bir kez; lore kararı (Y-E06) metni değiştirebilir; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-F07T Büyücüyü nadir olay düşmanı olarak bağla**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `dcd1edc`): Ağırlık 0.08, tehlike 0.35+, bir kez; lore kararı (Y-E06) metni değiştirebilir; test TEST_PLANI.md'de.
  - **Öncelik:** P3 · **Dalga:** 4 · **Bağımlı:** Y-E06
  - **Köken:** onaylanmayan **F07** önerisinin altındaki kullanıcı notu.
  - **Ne:** Kullanıcı notundan türetildi: büyücü ve 7 büyü kaldırılmaz; nadir bir olayla doğabilir.
  - **Kullanıcı notu:** “nadir bir olay evet ama olabilir, kaldırmak yok.”
  - **Kabul:** Büyücü en az bir nadir olaydan doğuyor; büyüler savaşta çalışıyor.

</details>

### Y-C33 · Ant bağı

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P09 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C17
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31 onay turu: Kullanıcı kararı: ant bağını yalnızca Gokyurtlular ve dağ kabileleri içer. | 2026-10-31: ant bağı oyunda (kurallar-karakter Oath & Creed Rules). | 2026-11-01: ant kardeşleri. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-C33 Ant bağı**
  - **Onay turu (2026-10-31):** açık. Kullanıcı kararı: ant bağını yalnızca Gokyurtlular ve dağ kabileleri içer.
  - **Öncelik:** P2 · **Dalga:** 4 · **Bağımlı:** Y-C17 · **Kim:** C
  - **Ne:** İki yoldaşın bağı +3'e çıkınca birbirine söz verir; söz bozulursa ağır kırgınlık. Göçebe töresinden.
  - **Kullanıcı notu:** "Gokyurt'ta ant bağı: Onay."
  - **Kabul:** Bağ ve kırgınlık testi; soru: yalnızca Gokyurtlu yoldaşlar mı, herkes mi.

</details>

## Paket P10

### Y-D01 · Kader Modu (ironman) ve açık zorluk ayarları

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P10 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Standart = bugünkü denge; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turunda düzeltildi: Kader Modu kutusu görünür, stat satırları düzeldi.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P10 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Arşiv user://lineage_archive.json; ün payı %20, tavan 6. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P11 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Defter sayfası kaydı ve Codex otomatik sayfa aracı yazıldı; dışa aktarım ve PDF hiç koşmadı, "71 sayfa" doğrulanmadı. | 2026-10-20: dışa aktarım (71 olay) ve PDF (110 sayfa) koşturuldu; kapak sayıları veriden. Commit f935975. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-E07 Paylaşılabilir defter sayfası ve güncel Codex**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `35a0db9`): Codex 29 elle + 42 otomatik sayfa; PDF dışa aktarım sonrası yeniden üretilecek.
  - **Öncelik:** P2 · **Dalga:** 5
  - **Ne:** Seferin ya da soyun özeti ekran görüntüsüne uygun tek bir defter sayfası; Codex olay bölümü güncellenir.
  - **Kabul:** Defter sayfası dışa aktarılabiliyor; Codex katalogla eşit.
  - **Literatür:** R11, R44

</details>

### Y-C26 · Vebanın hiç bulaşmadığı köyler

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P11 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C25
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Kart taslağı kart partisi 1'de (docs/design_notes/kart_partisi_01.md), onay bekliyor. | 2026-10-31 onay turu: Kart onaylandı; kullanıcı notu: zorla girince ticarette ciddi dezavantaj ve itibar doğrudan zedelenmeli. | 2026-10-31: kart oyunda (EventCatalog, events.csv).

<details><summary>Görev metni</summary>

- [ ] **Y-C26 Vebanın hiç bulaşmadığı köyler**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kart onaylandı; kullanıcı notu: zorla girince ticarette ciddi dezavantaj ve itibar doğrudan zedelenmeli.
  - **Durum (2026-10-31):** öneri. Kart taslağı kart partisi 1'de (docs/design_notes/kart_partisi_01.md), onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-C25 · **Kim:** C
  - **Ne:** Bazı köylere veba hiç bulaşmamış (kurtulan değil). Oyun nedenini açıklamaz. Durak ya da olay zinciri; lore kaydı LORE.md §6b.
  - **Kullanıcı notu:** "Vebanın hiç bulaşmadığı köyler olabilir, kurtulan köy olmasın."
  - **Kabul:** Kartlar onaya 10'luk partiyle gider.

</details>

### Y-E09 · Yozlaşmış yol bekçisi kartı

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P11 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C31
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Kart taslağı kart partisi 1'de, onay bekliyor. | 2026-10-31 onay turu: Kart partisi 1 onaylandı. | 2026-10-31: kart oyunda (EventCatalog, events.csv).

<details><summary>Görev metni</summary>

- [ ] **Y-E09 Yozlaşmış yol bekçisi kartı**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kart partisi 1 onaylandı.
  - **Durum (2026-10-31):** öneri. Kart taslağı kart partisi 1'de, onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-C31 · **Kim:** C
  - **Ne:** Yol bekçisi zayıf görünen kervandan fazla ister, fiş vermez, muaf olandan da alır.
  - **Kullanıcı notu:** "Yozlaşmış yol bekçisi: Onay."
  - **Kabul:** Kalite listesinden geçer; onaya 10'luk partide.

</details>

### Y-E10 · Esirlikten kaçış zinciri

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P11 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-E02
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Kart taslağı kart partisi 1'de, onay bekliyor. | 2026-10-31 onay turu: Kart partisi 1 onaylandı. | 2026-10-31: kart oyunda (EventCatalog, events.csv).

<details><summary>Görev metni</summary>

- [ ] **Y-E10 Esirlikten kaçış zinciri**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kart partisi 1 onaylandı.
  - **Durum (2026-10-31):** öneri. Kart taslağı kart partisi 1'de, onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-E02 · **Kim:** C
  - **Ne:** Kervandan biri ya da lider esir düşer; kaçarken gizli sebepleri olan yabancılar geçici olarak gruba katılır.
  - **Kullanıcı notu:** "Esirlikten kaçış zinciri: Onay."
  - **Kabul:** Zincir taslağı onaya gider.

</details>

### Y-E11 · Gezgin oyuncular ve tövbe alayı

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P11 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: İki kart taslağı kart partisi 1'de, onay bekliyor. | 2026-10-31 onay turu: Kart partisi 1 onaylandı. | 2026-10-31: kart oyunda (EventCatalog, events.csv).

<details><summary>Görev metni</summary>

- [ ] **Y-E11 Gezgin oyuncular ve tövbe alayı**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kart partisi 1 onaylandı.
  - **Durum (2026-10-31):** öneri. İki kart taslağı kart partisi 1'de, onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** - · **Kim:** C
  - **Ne:** İki yol kartı: gezgin oyuncular (küçük lütuf, haber) ve tövbe alayı (kıtlıkta yardım ister; Septisizm ve Yumruk gözünden başka okunur).
  - **Kullanıcı notu:** "Gezgin oyuncular ve tövbe alayı: Onay."
  - **Kabul:** Kalite listesinden geçer; onaya partide.

</details>

### Y-E12 · Gizli güdülü kılavuz

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P11 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Kart taslağı kart partisi 1'de, onay bekliyor. | 2026-10-31 onay turu: Kart partisi 1 onaylandı. | 2026-10-31: kart oyunda (EventCatalog, events.csv).

<details><summary>Görev metni</summary>

- [ ] **Y-E12 Gizli güdülü kılavuz**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kart partisi 1 onaylandı.
  - **Durum (2026-10-31):** öneri. Kart taslağı kart partisi 1'de, onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Kervanı bir yere götürmeyi öneren kılavuz yalnızca olayda çıkar, kiralanamaz. Saklı bir sebebi var (`NpcDisposition`).
  - **Kullanıcı notu:** "Gizli güdülü kılavuz: Onay. (Yerel rehber kiralamak: Red, buna para verecek imkânımız olmamalı hiç.)"
  - **Kabul:** Kart onaya partide.

</details>

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

## Paket P12

### 9.1 · Ortak UI kiti v2

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Kenney UI Pack RPG Expansion + Fantasy UI Borders (CC0) indirildi; tools/ui_kit_ink.py ile mürekkep ve palet renklerine boyandı (build/ui_kit); önizleme referans/taslaklar/y_91_ui_kit.png. Seçim köşebendinin ortası dolu çıktı. Onaydan sonra temaya bağlanır. | 2026-10-19 karar: beklet: kit, önceki düzeltmelerle birlikte ilgili sahnelerde örnekle gösterilecek. | 2026-10-20 kullanıcı kararı: köşebentler kaldırıldı (select_corner kitten ve örneklerden çıktı). | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş). | 2026-10-21 uygulandı (K8): kit plakaları ipucu ve fiş, başlık şeridi pazar yan panellerinde, olay kartı FRAMED_PANEL, ilk seçenek ve taverna sohbet düğmesi PRIMARY_BUTTON; test_waybook_theme kilitliyor. | 2026-11-01 doğrulama turunda düzeltildi: olay kartı içi opak, kart 820 px, son düğme çerçevenin içinde.

<details><summary>Görev metni</summary>

- [ ] **9.1 Ortak UI kiti v2** (K-01, K-03, T-02…T-12)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kenney UI Pack RPG Expansion + Fantasy UI Borders (CC0) indirilince kâğıt-mürekkep diline boyanır; Y-G11T ve 9.4-9.9 taslaklarındaki ince çerçeve ve kehribar vurgu bu kitin hedefi.
  - 9-slice panel çerçevesi, başlık şeridi, kırmızı ana eylem düğmesi (tüm durumlarıyla), tooltip plakası, seçim köşebentleri.
  - **Kaynak (CC0, 2026-10-17):** Kenney UI Pack RPG Expansion (85 dosya) ve Kenney Fantasy UI Borders (140 çerçeve), ikisi de CC0. Çerçeveler kâğıt ve mürekkep diline yeniden boyanır (stil rehberi Y-G01); kullanıcının reddettiği çizik, deri ve nine-slice süs dili kullanılmaz (25–27 Eylül kararları). Süsleme ve vinyet için Old Book Illustrations “Ornaments” görselleri (görseller serbest, açıklama metinleri NC, kopyalanmaz). Ayrıntı: `../ICERIK_IHTIYACLARI.md` G-7.

</details>

### 12.2 · Yol görünümü: büyük revizyon (overhaul)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** 12.2a, 12.2e, 9.9, 9.10 bu notta sıralı. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş). | 2026-10-21 uygulandı (K5): güneş/ay tek Gauss parıltısı (radial_glow), bulutlar, ufuk bandı, sis şeridi, uzak/orta soğuk ve ön sıcak renk ayarı, gece fener ışığı; screenshot_road_light.gd. | 2026-11-01 kullanıcı onayı.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Bağımlı:** 12.2d
- **Son not:** Gerçek şeritlerle; değişen yalnızca gök, güneş-ışık, renk derecelendirmesi, sis şeridi, gece feneri. | 2026-10-19 karar: onay; yol sahnesine uygulanacak. | 2026-10-20: ArtPalette.SKIES onaylı taslağa göre (band anahtarı), ufukta sıcak bant, güneş hale + küçük çekirdek. Commit 4af6c2f. | 2026-11-01 kullanıcı onayı.

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

### 12.2a · Şehir kapısı görünümü çok kötü ("rezalet"), baştan tasarlanmalı

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/12_sehir_ve_yol_gorunumu.md](referans/gorevler/12_sehir_ve_yol_gorunumu.md)
- **Son not:** settlement_gates.py her yerleşimin kapısını kasabasından türetir (gök, ışık, kar, mimari değer); render WAYBORNE_TOWN_CFG/OUT ile build/gates altına. Yuvarlak Tower minareye benzediği için kullanılmadı. | 2026-10-19 karar: onay; 27 yerleşimin kapısı render edilecek. | 2026-10-20: GateArrival: gerçek girişte şehrin kapı resmi 1.6 s, sonra solar; gündüz evresinde gündüz kapısı. 27 kapının gündüz renderları sürüyor (gates_phases.json). | 27 kapı x gece/gündüz render edildi ve denetlendi, tame_palette ile. | 2026-11-01: tam ekran GateArrival 2026-10-22 kullanıcı kararıyla silinmişti; kapılar yolun iki ucunda (çıkış ve varış) oyunda. Kapandı.

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

### Y-G10T · Şehir ekranı: insanlar ve şehir görünsün

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Oyunun gövde ve giysi kareleriyle meydanda halk; kervan yok. Uygulamada kalabalık ayrı katman: town_scene içinde sahne ışığı ve örtmeyle render, saatle yoğunluk (gece az, pazar günü çok), krizde (9.3) azalır ve yüzler değişir. | 2026-10-19 karar: insanların ışığı ortama aykırı; gece/akşam çok daha az insan; herkes yürüyor, sahne kurgulanmalı (duran, konuşan, satan). | 2026-10-21 uygulandı (K12): TownsfolkLayer; gece 4, akşam +5 kişi, arka plandan ışık örneklenir, bekçi feneriyle; screenshot_city_moods.gd. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Bağımlı:** 9.1
- **Son not:** Piksel hizalı renk ve ışık türetimi; gerçek uygulamada gök town_post adım 1de varyanta göre değişecek (taslakta ay her varyantta kalıyor). Kalabalık ve hasar katmanları Y-G10T ile. | 2026-10-19 karar: sabah/gündüz/akşam/gece ve her şehre kültüre göre ayrı varyant (N33 ile birlikte). | 2026-10-20: 27 yerleşim x sabah/gündüz/akşam yeniden render ediliyor (town_phases.py, towns_phases.json, kültürün ufku korunur); CityFront.background_path saate göre seçer. Denetimde akşam göğü mordan nötr koyu taşa çekildi, sabah güneşi yumuşak kenarlı. Render bitince görsel kontrol ve commit. | 2026-10-20: 81 evre resmi render edildi ve denetlendi; mor gece gökleri town_post.tame_palette ile arduvaza, sabah ılık ve puslu. Commit 0b7eeeb; test_phases_audio. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **9.3 CityFront durum varyantları** (A-25…A-29, T-01)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Piksel hizalı renk ve ışık türetimi; gerçek uygulamada gök town_post adım 1de varyanta göre değişecek (taslakta ay her varyantta kalıyor). Kalabalık ve hasar katmanları Y-G10T ile.
  - Varyantlar: alacakaranlık, gece, gri, kriz.
  - Katmanlar: pencere ışığı, ışık huzmesi, hasar ve kalabalık.
  - Hepsi mevcut `mask.png` ile piksel hizalı olacak.

</details>

### 9.4 · Mekân ekranları

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Bağımlı:** 9.1
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19: taverna oyunda canlı (TavernRoom: barmen, garson yürüyüşü, ozan, 4-6 müşteri, şömine alevi, mumlar, sohbet modu); ekran görüntüsüyle kontrol edildi, onay bekliyor. Eski dedikodu satın alma düzeni hizmetler panelinde duruyor, N34 değiştirecek. | 2026-10-19 karar: popup değil, referanstaki gibi tam ekran oda; mankenler canlı, önceden belirlenmiş rotasyonlarla hareketli ve rollü (konuk, müzisyen, barmen, yardımcı). Mekân iskeleti taslağı (y_94) silindi, taverna bu ekranı izler. | 2026-10-20: tavernada masadaki konuklar sit_box klibiyle oturuyor; masa ve bank gerçek ölçülerde (0.75 / 0.46 m) yeniden render edildi, bardak masada (el kalkmadan bardak kalkmıyordu). | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **9.4 Mekân ekranları** (T-02…T-09)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Ortak bir iskelet.
  - Büyük sahip portresi.
  - Mekânın mimarisinden türeyen yuvalar: kilise nişi, taverna fıçısı, şifacı kapısı.

</details>

### 9.5 · Pazar, erzak ve envanter

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19: oyunda uygulandı - pazar terazisi (MarketScale: mühür içinde mal ve sikke, sepet büyüdükçe parça sayısı artar, kol dengeye göre yaylı eğilir, düşen parça yerine oturur); ekran görüntüsüyle kontrol edildi, onay bekliyor. | 2026-10-19 karar: terazili tek ekran gereksiz; pazar Y-G11T masa ekranı olacak, terazi referans görseldeki gibi. | 2026-10-21 kullanıcı: oyundaki hali kalsın; vagon ve karakter çantaları açılır-kapanır bölüm olarak eklendi (K10). | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **9.5 Pazar, erzak ve envanter** (T-12, T-08)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Üstte fiyatlı mal kartları, altta kervan envanteri.

</details>

### 9.6 · Karakter ve stat ekranı

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19 karar: onay ("güzel"). | 2026-10-20: üç sütunlu karakter ekranı (kimlik, huylar ve statlar, beceriler ve dirençler), Kişi / Kuşam ve görev sekmeleri, SegmentBar. Denetimde düzeltildi: önizleme figürü render çözünürlüğünün üstüne büyütülmüyor (bulanıklık), kırgınlık işaretleri koyu zeminde açık mürekkeple. Commit 4af6c2f. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **9.6 Karakter ve stat ekranı** (K-01)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Üç sütun: kimlik ve figür / huylar ve statlar / beceriler ve dirençler.

</details>

### 9.7 · Roster kartı ve seviye rozeti

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19 karar: onay ("güzel"). | 2026-10-20: RosterCard ve seviye rozeti (party ekranı). Kart başlığındaki açlık çetelesi kaldırıldı (durum satırı söylüyor, ismi kesiyordu). Commit 4af6c2f. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **9.7 Roster kartı ve seviye rozeti** (K-01, T-02, T-11)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Seçili ve yaralı durumlarıyla.

</details>

### Y-G04 · Büst portreler

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G02, Y-G03
- **Son not:** MPFB2 eklentisi GPL lisanslı (CC0 değil); kullanıcının izni "CC0 ise indir" olduğu için indirilmedi. MPFB izni gelince figür hattıyla büst portre render edilir. | 2026-11-01 kayıt düzeltmesi: DEVAM_NOTU C5: büst portreleri oyunda, ekranda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-G04 Büst portreler**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): MPFB2 yerelde kurulu değil; figür hattıyla yakın plan render + mürekkep geçişi için gerekli. Taslaklardaki (9.4, 9.6) portre yuvası bu render için.
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-G02, Y-G03 · **İlgili:** 9.6, 9.7
  - **Ne:** Karakter, parti, taverna adayı ve mezar defteri için olay kartı üslubunda büst portreler.
  - **Kabul:** Portreler dört ekranda.
  - **Kaynaklar ve teknik (CC0 araştırması):** Portreler figür render'ının yakın planından mürekkep geçişiyle. Duruş ve tarama yönü için BHL, Rijksmuseum ve Met CC0 gravür portreleri yalnızca referans; kopyalanmaz. `../ICERIK_IHTIYACLARI.md` G-5.
  - **Literatür:** R26

</details>

### 9.8 · Savaş ekranı

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak). | 2026-10-19 karar: savaş arka planı savaşın olduğu yere göre; karakterlerin altında stilize can barı, can sağ panelden izlenmemeli. | 2026-10-21 taslaktaki savaş ekranı alındı (K9, bkz. Y-G05). | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **9.8 Savaş ekranı** (K-03…K-05)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): arayuz_taslaklari.py yeniden üretir; figürler oyunun gövde ve giysi kareleri (büyütüldüğü için yumuşak).
  - Alt panel: solda aktif üye, sağda hedef kartı.
  - Tur madalyonu.
  - Kritik vuruşta renk değişimi ve yakınlaşma.
  - `g9_seal` ile uyumlu bir öldürücü darbe mührü.

</details>

### Y-G05 · Savaş ekranını yeniden kur

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Biyom plakası yolun kendi şeritlerinden; figürler ekranın %32si. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş). | 2026-10-21 uygulandı (K9): tur madalyonu, tam ekran, yetenek kartları (isabet %/kilit sebebi), hedef paneli; kanama/kritik efektleri kullanıcı kararıyla eklenmedi. | 2026-11-01 kullanıcı onayı.

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

### 9.9 · Yol HUD'u

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Alt panel (P18) zaten sekmeli: harita ve envanter orada. | 2026-10-19 karar: harita ve envanterle birlikte gösterilecek; sağ üstteki moral/stres/takat paneli kalkar, alt panele iner. | 2026-10-21 kullanıcı: oyundaki hali iyi, taslak silindi (y_99_yol_hud.png). | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **9.9 Yol HUD'u** (K-02; çatlak efekti kaldırılacak, bkz. §2.5)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Alt panel (P18) zaten sekmeli: harita ve envanter orada.
  - `SurvivalGauge` ince çubuk, amblem ve çentiklerle çizilecek.
  - Harita ve envanter sekmeli alt panel.
  - Bu iş §8 ile bağlantılı.

</details>

### 9.12 · Kilise ve mezarlık arka planı

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Son not:** Kenney Graveyard Kit (CC0, haçsız) ile sakin ve nöbet varyantları: tools/ui_scenes/graveyard_scene.py; taslak referans/taslaklar/y_912_mezarlik_sakin_nobet.png. Onaydan sonra kilise ekranına (b5_church yerine) bağlanır. | 2026-10-19 karar: onay; kilise ekranına bağlanacak. | 2026-10-20: kilise mezarlığı tam çözünürlükte sakin ve nöbet (yas) varyantı; church.gd yas varsa nöbet resmini açar. Commit 4af6c2f. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **9.12 Kilise ve mezarlık arka planı** (A-01, A-06, A-14, T-03)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kenney Graveyard Kit (CC0) indirilince town_scene hattıyla sakin ve nöbet varyantları; dini sembol yok, lore (Y-E06) işaretleri bekleniyor.
  - Tek illüstrasyondan sakin ve nöbet varyantları.
  - **Kaynak:** Kenney Graveyard Kit (CC0; mezar taşı, çit, kripta). Kural: gerçek dinî yapı ve figür yok; haç ve benzeri semboller çıkarılır. Lore'daki inançlara (Y-E06) göre özgün işaretler.

</details>

### Y-G08 · Fener, oyunun görsel motifi

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Emblem oyunda (ana menü başlığı). Menünün ışık kaynağı yalnızca taslakta (Y-G16), oyunda değil: beş yerin dördü. | 2026-10-21 kullanıcı kararı: motif ateş ve fener birlikte. Menüde ateş kalır, fener yolda (kervan feneri, atlı işaret) ve arayüz kehribar vurgusunda motif olur; 'beş yer' bu tanıma göre yeniden sayılacak. | 2026-11-02 kullanıcı: kapatıldı.

<details><summary>Görev metni</summary>

- [ ] **Y-G08 Fener, oyunun görsel motifi**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `3784072`): Beş yerden üçü var, biri taslakta (menü), logo amblemi Poly Haven Lantern_01 indirmesine bağlı.
  - **Öncelik:** P1 · **Dalga:** 6 · **İlgili:** 8.11, Y-C20
  - **Ne:** Atlı işaretin feneri, yoldaki kervan feneri, menünün ışık kaynağı, arayüzün kehribar vurgusu, logo yanında küçük amblem.
  - **Kabul:** Motif stil rehberinde; beş yerde uygulanmış.
  - **Kaynaklar ve teknik (CC0 araştırması):** Fener modeli: Poly Haven `Lantern_01` (CC0), render ve mürekkep geçişi.
  - **Literatür:** R58

</details>

### Y-G14 · Tipografi birliği

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G01
- **Son not:** IM Fell Türkçe harflerin hepsini taşıyor (fontTools ile ölçüldü). | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-G14 Tipografi birliği**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `c8cf507`): IM Fell Türkçe harflerin hepsini taşıyor (fontTools ile ölçüldü).
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-G01
  - **Ne:** Harita, arayüz, defter ve kartlarda aynı üç yazı yüzü; haritadaki sans-serif kalkar.
  - **Kabul:** Yazı yüzü listesi stil rehberinde; ekranlar uyumlu.
  - **Kaynaklar ve teknik (CC0 araştırması):** Fontlar SIL OFL 1.1 (OFL.txt dağıtıma, Credits'te liste): IM Fell English yalnızca temel Latin; Türkçe ğ, ş, İ, ı eksik olabilir → test edilir, eksikse yalnızca İngilizce başlıklarda. Gövde EB Garamond (latin-ext ve Kiril), alternatif Cormorant Garamond, rakamlar için Old Standard TT; Çince Noto Serif SC, EB Garamond'un arkasında fallback. `../ICERIK_IHTIYACLARI.md` G-8.

</details>

### Y-G17 · Tek sıcak kaynak: kural ve bütün sahnelerin denetimi

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C22
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Kural yazılı; denetim docs/ui/sicak_kaynak_denetimi.md (akşam şehir resimleri aykırı, render gerekir; güneş ışık kaynağı mı kararı kullanıcıda). | 2026-10-31 onay turu: Kullanıcı kararı: güneşin halesi de soğuk (akşam ve kış güneşi soğuktur). | 2026-11-01: şehir akşam/gece/şafak resimleri gölgelendiricide soğur, güneş soğuk, şalvar soluk.

<details><summary>Görev metni</summary>

- [ ] **Y-G17 Tek sıcak kaynak: kural ve bütün sahnelerin denetimi**
  - **Onay turu (2026-10-31):** kısmen. Kullanıcı kararı: güneşin halesi de soğuk (akşam ve kış güneşi soğuktur).
  - **Durum (2026-10-31):** kısmen. Kural yazılı; denetim docs/ui/sicak_kaynak_denetimi.md (akşam şehir resimleri aykırı, render gerekir; güneş ışık kaynağı mı kararı kullanıcıda).
  - **Öncelik:** P1 · **Dalga:** 6 · **Bağımlı:** Y-C22 · **Kim:** CO
  - **Ne:** Dünyada sıcak renk yalnızca bir ışık kaynağından gelir: ateş, fener, meşale, pencere ışığı, defter sayfası. Kural `kurallar-sanat` Art Rules'a yazıldı. Kalan: yol, şehir, savaş, hub, kervansaray ve kart görsellerinin denetim listesi, aykırı olanların sırayla düzeltilmesi; her düzeltme ekran görüntüsüyle.
  - **Kullanıcı notu:** "Tek sıcak kaynak: Onay. Bunu gene kurallara yaz çünkü buna göre çok düzenleme gerekecek."
  - **Kabul:** Denetim listesi `docs/ui/` altında; her sahne için önce ve sonra görüntüsü.

</details>

### Y-G18 · Kıtlık paleti bölgeye göre: Gokyurt en geç solar

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C21, Y-G17
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-11-01: GrimGrade kıtlıkla solar; Gokyurt en geç. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-G18 Kıtlık paleti bölgeye göre: Gokyurt en geç solar**
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-C21, Y-G17 · **Kim:** C
  - **Ne:** Kıtlığın derecesi bölge başına bir değer; palet o değere göre solar. Gokyurt hâlâ öbür yerlere göre daha sağlıklı, bu yüzden en geç solar. Bağlarla ilgisi yok.
  - **Kullanıcı notu:** "Hayır bağ ile ilgili bir şey olmamalı bu. Gokyurt hala diğer yerlere kıyasla daha sağlıklı bir yer o sebeple palet daha geç solabilir orada."
  - **Kabul:** Aynı saatte Gokyurt yolu ile Vadi yolunun görüntüsü yan yana; test bölge değerinin palete geçtiğini doğrular.

</details>

### Y-G19 · Portreler baştan yorgun ve aşınmış

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Yönergesi docs/el_cizimi/PORTRE_YONERGESI.md; ara çözüm bust_ink.gdshader weariness (soğuk ışık, soluk renk, derin gölge). | 2026-10-31 onay turu: Onay turunda onaylandı.

<details><summary>Görev metni</summary>

- [x] **Y-G19 Portreler baştan yorgun ve aşınmış**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Yönergesi docs/el_cizimi/PORTRE_YONERGESI.md; ara çözüm bust_ink.gdshader weariness (soğuk ışık, soluk renk, derin gölge).
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Karakter portreleri bir duruma göre aşınmaz, baştan öyle çizilir: yorgun, aşınmış yüzler. El çizimi programının portre yönergesine (`docs/el_cizimi/`) girer; mevcut `BustPortrait` mürekkep gölgelendirmesi ara çözüm olarak aynı yöne çekilir.
  - **Kullanıcı notu:** "Karakter portreleri direkt bu şekilde çizilmeli, zaten aşınmış, yorgun olmalı."
  - **Kabul:** Yönerge yazıldı; mevcut portrelerin önce ve sonra görüntüsü onaylandı.

</details>

### Y-G20 · Olay kartının görsel dili bölgeye göre

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: CardRegionLook: sekiz bölgenin göğü, tonu, örtüsü, çerçeve deseni; vebalı bölgede solma. Tablo: tests/screenshot_card_regions.gd. | 2026-10-31 onay turu: Onay turunda onaylandı.

<details><summary>Görev metni</summary>

- [x] **Y-G20 Olay kartının görsel dili bölgeye göre**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. CardRegionLook: sekiz bölgenin göğü, tonu, örtüsü, çerçeve deseni; vebalı bölgede solma. Tablo: tests/screenshot_card_regions.gd.
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Kartın çizim dili kartın türüne göre değişmez, bölgeye göre değişir (Gokyurt, Vaelghard, Vadi, Ayazkaya...).
  - **Kullanıcı notu:** "Bölgeye göre farklılık olmalı, karta göre de farklılık olmasın."
  - **Kabul:** Üç bölgenin kart görünüşü yan yana onaylandı.

</details>

### Y-G21 · Kart açılışında yavaş kayma

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: CardDrift: kart resmi açılırken yavaşça yaklaşıp kayar; Reduce Motion'da durur; ağaca girince başlar (CI düzeltmesi). | 2026-10-31 onay turu: Onay turunda onaylandı.

<details><summary>Görev metni</summary>

- [x] **Y-G21 Kart açılışında yavaş kayma**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. CardDrift: kart resmi açılırken yavaşça yaklaşıp kayar; Reduce Motion'da durur; ağaca girince başlar (CI düzeltmesi).
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Olay kartının resmi açılırken yavaşça kayar (paralaks); Reduce Motion açıkken kayma yok.
  - **Kullanıcı notu:** "Yavaş kayan kart açılışı: Onay."
  - **Kabul:** Hareket eğrisi duruştan başlayıp duruşta biter (`test_motion` kalıbı); görüntü onaylandı.

</details>

### Y-G22 · Bataklık görünüşü: gri-yeşil sis

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: TravelBand._draw_marsh_mist: havadan bağımsız gri-yeşil perde, zemin örtüsü, alçak tutamlar; biyom geçişiyle açılır. screenshot_road_looks marsh satırı. | 2026-10-31 onay turu: Onay turunda onaylandı.

<details><summary>Görev metni</summary>

- [x] **Y-G22 Bataklık görünüşü: gri-yeşil sis**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. TravelBand._draw_marsh_mist: havadan bağımsız gri-yeşil perde, zemin örtüsü, alçak tutamlar; biyom geçişiyle açılır. screenshot_road_looks marsh satırı.
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Samuran ve Liraven çevresindeki yol kesimleri için çamurlu, sisli, gri-yeşil yol katmanları (`RoadStrips` görünüşü).
  - **Kullanıcı notu:** "Gri-yeşil sisli bataklık: Onay."
  - **Kabul:** `screenshot_road_looks` tablosunda bataklık görünüşü.

</details>

### Y-C30 · Kıtlıkta kervansaray: kapıya bırakılan yemek

- **Durum:** bitti · **Öncelik:** P3 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: Kıtlıkta kervansaray sahibinin kapıya bıraktığı tas: meyhane açılış satırı. | 2026-10-31 onay turu: Onay turunda onaylandı.

<details><summary>Görev metni</summary>

- [x] **Y-C30 Kıtlıkta kervansaray: kapıya bırakılan yemek**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Kıtlıkta kervansaray sahibinin kapıya bıraktığı tas: meyhane açılış satırı.
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Kıtlığın kervansaraydaki izi küçük kalır: diyalogda bir ayrıntı ya da hancının kapıya yemek bıraktığının görüldüğü bir sahne.
  - **Kullanıcı notu:** "Diyalogda belirtilen küçük bir detay ya da sadece görsel olarak hancının kapıya yemek bıraktığını gördüğümüz bir yer olabilir."
  - **Kabul:** Satır ya da görüntü onaylandı.

</details>

## Paket P13

### Y-H08 · Sessizlik anları

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P13 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: AudioManager.hush: feda ve ölümden sonra müzik susar, adım, nefes, sürünme; yer tutucu sesler. | 2026-10-31 onay turu: Onay turunda onaylandı (sesler yer tutucu).

<details><summary>Görev metni</summary>

- [x] **Y-H08 Sessizlik anları**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı (sesler yer tutucu).
  - **Durum (2026-10-31):** test bekliyor. AudioManager.hush: feda ve ölümden sonra müzik susar, adım, nefes, sürünme; yer tutucu sesler.
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Bir feda kararından sonra ya da çok gergin anlarda müzik ve ortam sesi kesilir; yalnızca adım, sürünme ve nefes sesleri duyulur.
  - **Kullanıcı notu:** "Tamamen sessizlik ve adım, sürünme, nefes gibi seslerin daha belirgin olması, daha doğrusu sadece onların duyulması daha etkili."
  - **Kabul:** Ses varlıkları (CC0 ya da sentez yer tutucu); geçiş `AudioManager` üzerinden.

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

### Y-H07 · Erişilebilirlik ve oynanış ayarları

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P14 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Üç ayar kodda ama kapsamı dar: metin boyu yalnız tema taban boyu (elle verilmiş boylar sabit), desenli şerit yalnız savaş seçeneği şeridi, otomatik duraklama yalnız yol işareti ve karşılaşma işareti. Denenmedi. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **Y-H07 Erişilebilirlik ve oynanış ayarları**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `20d0400`): Ayarlar settings.cfg de; hızlandırma Y-B09 ile kalktı, duraklatma kaldı.
  - **Öncelik:** P2 · **Dalga:** 6 · **İlgili:** Y-B09
  - **Ne:** Metin boyutu, renk körlüğü için kan şeridine desen, olay gelince otomatik duraklat. Hızlandırma Y-B09 gereği kalkacak; duraklatma kalır.
  - **Kabul:** Ayarlar menüsünde; testler.

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

### N29 · Vadiye özgü yeşil çayır biyomu

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P16 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N28
- **Son not:** Kod, veri ve dört katman hazır; testler ve ekran görüntüsü TEST_PLANI.md'de, onay ONAY_PAKETI.md'de. | 2026-11-01 kullanıcı onayı.

<details><summary>Görev metni</summary>

- [ ] **N29 Vadiye özgü yeşil çayır biyomu** (`CO`)
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5ae38c4`): Kod, veri ve dört katman hazır; testler ve ekran görüntüsü TEST_PLANI.md'de, onay ONAY_PAKETI.md'de.
  - Bugün vadinin açık tarım arazisi "bozkır" şeridiyle çiziliyor (kuru, sarı ot). Vadi (Tyrell benzetmesi) bereketli: yeşil çayır, ekin tarlası, çit ve ağaç sırası, uzakta yumuşak tepeler.
  - Yeni biyom `meadow`: `ArtPalette` dört rolü (gökyüzü/uzak/yakın/flora), `tools/ui_scenes/road_scene.py` `BIOMES` girdisi ve dört katmanın (far, mid, ground, fore) Blender render'ı, `road_post.py`; `RouteTerrain.BIOME_CHAIN`, isim anahtarı (`TERRAIN_MEADOW`, tr/en), hava eğilimi (`RouteWeather`), ağaç çizimi.
  - Üreteç (`build_settlements.py`): vadi bölgesindeki açık arazi bozkır değil çayır; bozkır göçebe ve güney kuru topraklarında kalır.
  - **Kabul:** Belvanor-İlsande yolu çayır; ekran görüntüsü senin onayına; `test_grim_ui` şerit kenar testleri ve `test_route_terrain` geçer.

</details>

### N30 · Bozkırda yol durakları arasını aç

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P16 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N28
- **Son not:** Bozkırda durak aralığı 6 gün; test TEST_PLANI.md'de. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **N30 Bozkırda yol durakları arasını aç** (`C`)
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `5ae38c4`): Bozkırda durak aralığı 6 gün; test TEST_PLANI.md'de.
  - Göçebe bozkırında (ör. Selvicar-Orbeyan, 35 gün) yol beş yurtta durur; harita noktası durakları arasındaki en az aralık 3 gün.
  - Bozkır parçalarında aralık daha geniş (öneri 6 gün) ya da yol başına harita noktası durağı sınırı; dağ/su geçidi durakları etkilenmez.
  - **Kabul:** Selvicar-Orbeyan'da yurt durağı en çok 3; `test_route_terrain` geçer.

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

### N23 · Eski HUD parçalarını kaldır

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N18, N19, N20, N22
- **Son not:** Tab ile açılan CaravanStatusPanel kontrat listesini de gösterdiği için duruyor; panelin Yük sekmesine kontratlar taşınınca kalkar (karar senin). | 2026-10-20: eski Tab paneli (CaravanStatusPanel, StatusOverlay) kaldırıldı; kontratlar kontrol panelinin Yük sekmesinde, Durum düğmesi ve Tab kontrol panelinin Durum sekmesini açıyor. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **N23 Eski HUD parçalarını kaldır** (`C`)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `e967039`): Tab ile açılan CaravanStatusPanel kontrat listesini de gösterdiği için duruyor; panelin Yük sekmesine kontratlar taşınınca kalkar (karar senin).
  - Üst şerit ve yan göstergelerden panelde olanlar kalkar; yinelenen metin kalmaz; testler güncellenir.

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

### N31 · Oyun hissi incelemesi ve planı (6 alan)

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Son not:** Altı alan incelendi; N31a-N31f alt görevleri 14_yeni_dunya.md ye eklendi (gorevler.json a bir sonraki durum.py taramasında). | 2026-11-01 doğrulama turu: oyunda doğrulandı.

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

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: log_beat + playtest_beats.jsonl; playtest_report.py boş dakika, en uzun ara, savaş/kamp süresi, ekran süresi. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **N31a Ölçüm: beat kaydı ve boş dakika raporu** (`C`) - oyuncu testinde her karar ve bilgi anı gerçek saniyeyle; playtest_report boş dakikaları, savaş ve kamp sürelerini yazar. (M, P1) Ayrıntı: `docs/design_notes/oyun_hissi_plani.md` §1.

</details>

### N31b · Işık modeli ve sis şeridi koda

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: 12.2e ile güneş halesi ve ufuk bandı yolda (commit 4af6c2f). Ayrı sis şeridi eklenmedi; 12.2e onaylı ışık modeli yeterli görüldü. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **N31b Işık modeli ve sis şeridi koda** (`CO`) - 12.2e taslağı onaylanınca TravelBand gök, hale, evre derecelendirmesi, sis şeridi. (M, P1) §2.

</details>

### N31c · Ses otobüsleri, çeşitleme, ayar kaydırıcıları

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: dört ses otobüsü, Ayarlar'da dört sürgü, tekrarsız çeşit, Kenney CC0 arayüz sesleri (indirildi, KUNYE.tsv). Commit 461be41. | 2026-11-01 doğrulama turu: oyunda doğrulandı.

<details><summary>Görev metni</summary>

- [ ] **N31c Ses otobüsleri, çeşitleme, ayar kaydırıcıları** (`C`) - müzik/ortam/efekt/arayüz otobüsleri, AudioStreamRandomizer, Ayarlar'da dört kaydırıcı. (M, P1) §3.

</details>

### N31e · Tempoya bağlı toz, çamur ve kar

- **Durum:** bitti · **Öncelik:** P2 · **Paket:** P18 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: toz tempoya bağlı, yağmurda tekerlek çamuru. Kar tozu kaldı. | 2026-10-20: kışın kar savruğu (TravelBand.set_winter), toz tempoya bağlı, çamur sıçrantısı.

<details><summary>Görev metni</summary>

- [ ] **N31e Tempoya bağlı toz, çamur ve kar** (`C`) - toz yoğunluğu yürüyüş hızıyla, yağmurda tekerlek çamuru. (S, P2) §5.

</details>

## Paket P19

### T16-01 · Kamp: vagondan ateşe normal yürüyüş hızı, en öndeki attan ateşe en fazla 10 sn

- **Durum:** bitti · **Öncelik:** P1 · **Paket:** P19 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/16_oyun_testi_isleri.md](referans/gorevler/16_oyun_testi_isleri.md)
- **Son not:** 2026-11-02 kullanıcı listesi. Eski: 12.2c. | Bitti: normal yürüyüş hızı (WalkFigure.walk_ground_speed), yürüyüş+iniş ≤10 sn, lider ve öndekiler için atın önünde öncü ateşi (attan ateşe 1,5 sn iniş + 4,4 sn yürüyüş), ateş başına 8 yer, gelinen yandan yer seçimi, yürüyüşte saat 0.05x. Ekran: screenshot_camp.gd 10. saniyede herkes ateşte.

<details><summary>Görev metni</summary>

- [ ] **T16-01 Kamp: vagondan ateşe normal yürüyüş hızı, en öndeki attan ateşe en fazla 10 sn**
  - **Ne:** Kamp kurulunca insanlar vagondan ateşe normal yürüyüş hızıyla yürür (koşmaz). En uzaktaki kişi, en öndeki at, ateşe en fazla 10 saniyede varır. Yürüyüş sırasında oyun saati gece bitmeyecek hızda akar.
  - **Kim:** C · **Eski:** 12.2c

</details>
