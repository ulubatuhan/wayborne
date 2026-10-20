# §3. Atıl kod temizliği (düşük risk)

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

Kaynak: §1B–§1G. "İleride işe yarar" diye işaretlenenler §2'de, onlara **dokunma**.

- [x] **3.1 Kullanılmayan 20 fonksiyonu sil** (§1B tablosu)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `7d16b27`): 20 fonksiyon silindi (git grep -w ile yeniden doğrulandı); scaled_texture ile birlikte ölü kalan _scaled_cache de gitti.
  - `set_lunge` ve `apply_action_animation` silinirken ilgili bayat yorumları da temizle (§3A).
- [x] **3.2 Dinleyicisi olmayan 6 sinyali ve emit satırlarını sil** (§1C)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `d692d28`): 6 sinyal ve emit satırları silindi; item_removed'in yerel değişkeni de kalktı.
- [x] **3.3 Kullanılmayan 11 sabit ve üyeyi sil** (§1D)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `e561542`): Kullanılmayan sabit ve üyeler silindi (denetim listesindeki 12 öğe). Debt.source serbest dize, 'penalty' ile karşılaştırılmıyor; eski kayıtlar etkilenmez. LUNGE_DISTANCE'in yanlış yerdeki animasyon yorumu _process'in üstüne taşındı.
  - `Debt.SOURCE_PENALTY` için önce eski kayıt uyumluluğunu kontrol et (§7 madde 8).
- [ ] **3.4 Kullanılmayan varlıkları üretim hattıyla birlikte kaldır** (§1E)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `153173a`): 42 fx sprite (31'i kaldı), k1_slot, k2_door, r4c_danger, r4d_stamina, b10_city.jpg silindi; fx_assets.py açık sprite listesine, waybook araçları güncellendi. Efektler screenshot_combat_fx.gd ile gözle doğrulandı. Bilerek yapılmadı: 13 kullanılmayan eşya paketi ve 6 silah eşyası duruyor (yakında gelecek ganimet, ekipman, biyom ve kamp işleri kullanabilir; yeniden render pahalı; silahlar için denetim kullanıcıya sorulmasını istiyor).
  - 42 fx sprite. Ayrıca `tools/fx_assets.py` içindeki `FAMILIES` listesini daralt.
  - `k1_slot`, `k2_door`, `r4c_danger`, `r4d_stamina`. Ayrıca `tools/waybook_assets.py`'yi güncelle.
  - 13 eşya paketi.
  - Kullanılmayan 6 silah eşyası (§7 madde 5): önce kullanıcıya sor.
- [x] **3.5 Kullanılmayan 41 çeviri anahtarını sil** (§1F)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `5cfed17`): 34 anahtar silindi. Ham tarama 162 aday verdi; 128'i dinamik kurulan (olay başlık/metin, LEDGER_CAUSE_COMBAT_%s) ya da tutulacak UI_GRIM_*. Denetimdeki 41 rakamı tutulan 7 UI_GRIM_* anahtarını da içeriyordu. CLAUDE.md hâlâ UI_ROAD_STATE ve UI_CITY_HOVER_HINT'ten söz ediyor (4.2'de düzeltilecek).
  - `UI_GRIM_CLOSE/ENTER/NAV_LEAVE` kalsın (§2).
- [ ] **3.6 Ölü araç ve belgeleri kaldır ya da arşivle** (§1G)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `b247080`): Kapı şablonu, Aşama 0 performans denemeleri, Faz 1 kapısı, eski oynatıcı ve atlas betikleri, mesh-deform kalıntıları silindi; ASAMA*, FAZ1_GATE, VALIDATION docs/archive/figure_pipeline/ altına taşındı. DENETİM YANILMIŞ: config/variants/*_medium.json (clip.json ve canlı qa/check_config.py male_medium'u şart koşuyor) ve side_check_camera_minusX.png (layers.json, check_config.py) ölü değil, tutuldu. Kullanıcı kararı bekleyen: build_beasts.py, docs/art-prompts.md ve docs/event-window-blueprint.md (denetim §7 madde 13, 15).
  - Gate şablonu, perf denemeleri, Faz 1 kapısı, mesh-deform kalıntıları, `*_medium.json`.
  - Tarih notlarını `docs/archive/` altına taşı.
  - `qa/faz1_tests.py`, `wardrobe_cut.py` ve `wardrobe_paint_reference.py` **canlı**, dokunma.
- [x] **3.7 `art_source/` içindeki reddedilmiş kaynakları depodan çıkar** (§1H, ~17 MB)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `9deffb7`): Önlük, MegaKit vagonu, Bridge.blend ve 15 reddedilmiş waybook sayfası (~17 MB) kaldırıldı; künyeler (credits.gd, CREDITS.md, iki LICENSES.md) güncellendi. A0_style_anchor.jpg bilerek tutuldu.
  - Önlük (apron): künyesini de kaldır (`credits.gd:17`, `CREDITS.md:17`, `LICENSES.md:18`).
  - MegaKit arabası ve `Bridge.blend`.
  - 15 reddedilmiş waybook sayfası.
