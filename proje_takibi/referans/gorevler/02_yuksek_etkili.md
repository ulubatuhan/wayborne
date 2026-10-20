# §2. Yüksek etkili düzeltmeler

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

- [ ] **2.1 Dışa aktarımlardan test ve araçları çıkar** (§4 O-1; PC dışa aktarımı asıl hedef, Web yalnız test için)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `ded1091`): export_presets.cfg Web ön ayarına exclude_filter="tests/*, tools/*" eklendi; oyun kodu bu klasörlere çalışma anında başvurmuyor (yalnızca yorumlar). Yapılmadı: DevPanel'in PC sürümünde kalıp kalmayacağı kararı (kullanıcıya soruldu) ve henüz var olmayan PC (Windows) ön ayarı (dışa aktarma şablonları kurulu değil).
  - `export_presets.cfg` içine `exclude_filter="tests/*, tools/*"` ekle.
  - Önce `test_selector.tscn`'in yalnız `scripts/` kullandığını doğrula.
  - `DevPanel` ve `test_selector` PC sürümünde kalmalı mı, kullanıcıya sor (§7 madde 4). Web test derlemesinde kalabilir.
- [x] **2.2 Yol ekranında her karede yapılan metin üretimini kaldır** (§4 O-2)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `6f3fdca`): Koşullar satırı, ilerleme ipucu, emir paneli ve tüccar satırı yalnızca girdi (biyom, hava, tempo, dil...) değişince metin kuruyor.
  - Üç yer: `road_journey.gd:2223` (`_refresh_conditions`), `:1267` (`_refresh_command_panel`), `:2152` (ilerleme tooltip'i).
  - Metni yalnızca gösterilen değer değişince yeniden kur. Dosyanın kendi yorumu (`:2161-2165`) bunu zaten istiyor.
- [ ] **2.3 Ölü `CityView` sınıfını ve bağlı varlıklarını kaldır** (§1A, §1E)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `b756a52`): city_view.gd (983 satır) ve screenshot_city.gd silindi; yorum başvuruları CityFront/TravelBand'e çevrildi. Kanıt: şehir CityFront'a geçti (REDESIGN §7.2), kullanıcı önden görünüm istiyor, izometrik dönüş planı yok. DENETİM YANILMIŞ: iso_* eşyaları ölü değil, tools/ui_scenes/ui_kit.py şehir madalyonlarını iso_stable, iso_market_stand_1, iso_house_2, iso_inn, iso_bell_tower'dan üretiyor; 10 iso_* eşyası ve test_props.gd beklentileri tutuldu. Kullanıcı onayı hâlâ açık: istenmezse commit geri alınabilir. CLAUDE.md Art Rules'taki CityView maddeleri 4.2'de.
  - Dosyalar: `scripts/ui/city_view.gd`, `tests/screenshot_city.gd`, 10 adet `iso_*` eşya, `b10_city.jpg`.
  - İlişkili listeler: `tests/test_props.gd:18-20`, `props.json` girdileri, `tools/waybook_assets.py` ve `waybook_ingest_v2.py`.
  - Bayat yorumlar: §3A'daki 4 CityView yorumu.
  - CLAUDE.md Art Rules'taki CityView maddeleri.
  - **Önce doğrula** (§7 madde 6): izometrik şehre dönüş planı yok mu?
- [x] **2.4 Test sürelerini ölç, sonra CI önbelleği ekle** (§4 O-10, O-11)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `5dfcc5b`): run_tests.gd en yavaş on paketi ve toplamı basıyor. Ölçüm: paketler toplam 20,6 sn (en yavaşı Navigation 4,8 sn), soğuk içe aktarma ~100 sn, sıcak ~13 sn. tests.yml'e .godot + **/*.import + **/*.translation önbelleği eklendi; deploy.yml'e bilerek eklenmedi. CI önbelleği GitHub'da henüz koşturulmadı, ilk koşuda kontrol edilmeli.
  - `run_tests.gd`'ye paket başına süre yazdır.
  - CI'da `.godot/imported` için `actions/cache` ekle.
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
