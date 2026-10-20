# Wayborne — Kod ve Depo Denetimi

> **Not (2026-10-17, kullanıcı):** Wayborne bir **PC oyunu**. Web derlemesi yalnızca test için; Web performansı, Web paket boyutu ve Web VRAM sınırları **ölçüt değil**. Bu belgedeki Web gerekçeli maddeler PC açısından okunmalı; güncel öncelikler `../YAPILACAKLAR.md` dizininde.


- **Tarih:** 2026-10-17
- **Depo:** `D:\Users\u90238\Desktop\xx\wayborne`, dal `main`, 238 commit, HEAD `008ecb2`
- **Kapsam:** `git ls-files` ile izlenen 2139 dosya (420 MB çalışma ağacı, 570 MiB pack)
- **Yöntem:** Salt okunur. Depoda hiçbir dosya değişmedi. Kanıtlar `git grep`, `git ls-files`, `git rev-list --objects` ve scratchpad'deki Python taramalarından geliyor. Taramalar sınıf adı, `res://` yolu, `preload`/`load` dizesi, dosya adı ve kök ad üzerinden yapıldı. Yorum satırları sayılmadı. Dinamik kurulan yollar (`"icon_%s.png"`, `"eq_%s.png"`, `"item_%s.png"`, `"smoke_0%d"`, `"LEDGER_CAUSE_COMBAT_%s"`, `"%s_TITLE"`) elle çözüldü.
- **Uygulayıcıya not:** Her "kaldır" maddesinden sonra `godot --headless --script res://tests/run_tests.gd` çalıştırılmalı ve CI'daki betik-hatası taraması geçmeli (CLAUDE.md "CI is the real gate").

---

## Özet

| Bölüm | Madde sayısı |
|---|---|
| Kaldırılabilir (kesin atıl) | 64 satır: 1 sınıf (983 satır) + 1 araç sahnesi, 20 fonksiyon, 6 sinyal, 10 sabit/üye, 75 varlık dosyası (~1.4 MB oyun içi), 41 çeviri anahtarı, 15 araç/doküman dosyası, ~33 MB `art_source` |
| Gelecek için tutulacak | 19 |
| Hatalı/anlamsız kod | 27 (12 bayat yorum, 6 bayat doküman, 7 tekrarlanan yardımcı, 2 kural ihlali). TODO/FIXME/HACK: 0. `scripts/` içinde debug `print`: 0. Ulaşılamaz dal: 0 |
| Optimizasyon önerileri | 14 |
| Depo hijyeni | 11 |
| İsim kuralı ihlalleri | 9 grup (~200 tanımlayıcı/anahtar + 3 dosya adı + 1 dizin çifti) |
| Doğrulanması gerekenler | 18 |

**En önemli 5 bulgu**

1. **Web dışa aktarımına test ve araç betikleri giriyor, frame atlasları %81 boş.** `export_presets.cfg:8` `export_filter="all_resources"` ve `exclude_filter=""`. `tests/` (83 dosya) ve `tools/**/*.gd` (13 betik) Web derlemesine paketleniyor. Bunlardan ayrı olarak, karakter frame atlaslarının (`data/assets/characters/frames`, 311 sayfa, 383 Mpx) yalnızca %18.7'sinde opak piksel var. Gövde sayfalarında oran %10. Bu doluluk indirme boyutunu, VRAM kullanımını ve yükleme süresini doğrudan büyütüyor.
2. **`CityView` (983 satır) ve ona bağlı varlıklar artık oyunda kullanılmıyor.** Şehir ekranı `CityFront`'a geçti (`docs/ui/REDESIGN.md` §7.2 ✓). `scripts/ui/city_view.gd` yalnızca `tests/screenshot_city.gd`'den kuruluyor. Yalnız onun kullandığı 8 `iso_*` eşya (~425 KB) ve `b10_city.jpg` (205 KB) da artık atıl.
3. **Git geçmişinin yarısı yeniden üretilmiş ikili dosyalardan oluşuyor ve depoda LFS yok.** 596 MB'lık blob'un 290 MB'ı HEAD'de bulunmuyor. Bunun 224 MB'ı `data/assets/characters` (her render turu frame sayfalarını yeniden yazıyor). Geçmişte bir de silinmiş 33.5 MB'lık `human-base-meshes-bundle-v1.0.0.zip` var. `.gitattributes` dosyası ve LFS kuralı yok.
4. **Yol ekranında kare başına string üretimi var, üstelik kodun kendi yorumu bunu yapmamayı söylüyor.** `scripts/ui/road_journey.gd:2161-2165` "metin yalnızca gösterilen değer değişince kuruluyor" diyor. Buna rağmen aynı karede `_refresh_conditions()` (`:2223`, her karede 7 `tr()` + 4 format), `_refresh_command_panel()` (`:1267`, tooltip ve sofra düğmesi metni) ve ilerleme tooltip'i (`:2152`) her karede yeniden biçimleniyor.
5. **referans oyun kökenli isimler hâlâ kodda.** `scripts/ui/grim/` dizini ve `data/assets/ui/grim/` (42 dosya), `GrimTheme`/`GrimDrafts`/`GrimNotice` sınıfları, 13 adet `ArtPalette.GRIM_*` sabiti, 76 `UI_GRIM_*` çeviri anahtarı, `tests/test_combat_dd.gd`, `RouteTerrain.STOP_MEZRA`/`near_mezra`/`ih_mezra` ve `e6j_mezra.jpg`. CLAUDE.md'nin kendisi de (Ana Hedefler, karanlık arayüz maddesi) "Dosya ve sınıf adları oyuna özgü kalır" diyor.

---

## 1. Kaldırılabilir (kesin atıl)

"Kesin atıl" şu anlama geliyor: oyun kodu, sahneler, `project.godot`, `.tres` ve araç zinciri hiçbir yerden başvurmuyor ve CLAUDE.md, `docs/ui/REDESIGN.md`, `GELISIM_GECMISI.md` ya da README'de gelecek planı olarak geçmiyor. Planlarda geçenler §2'de.

**Risk ölçeği**
- **Düşük:** Silmek yalnız ölü kodu kaldırır.
- **Orta:** Başka bir yerde (araç, test, CLAUDE.md) eşzamanlı düzenleme gerekir.
- **Yüksek:** Davranış ya da kayıt uyumluluğu etkilenebilir.

### 1A. GDScript sınıfları ve betikler

| Dosya/öğe | Kanıt | Risk |
|---|---|---|
| `scripts/ui/city_view.gd` (`class_name CityView`, 983 satır) | `git grep -w CityView` sonucu, yorumlar hariç tek kullanım `tests/screenshot_city.gd:21,36`. `scripts/world/city_map.gd:26,48` artık `CityFront` kuruyor. REDESIGN.md §7.2: "✓ Şehir: city_map.tscn'de CityView yerine CityFront". Kendi `_process`'i de var (`:201`). | Orta. Birlikte silinmesi ya da güncellenmesi gerekenler: `tests/screenshot_city.gd`, `tests/test_props.gd:18-20` (iso eşya beklentileri), yorumlar (`scripts/autoload/gamepad_cursor.gd:4`, `scripts/ui/hub_scenery.gd:72`, `scripts/ui/grim/city_front.gd:13`, `tests/test_navigation.gd:295`) ve CLAUDE.md Art Rules'taki CityView maddeleri. |
| `tests/screenshot_city.gd` | Yalnız CityView'i çiziyor. Oyundaki şehir ekranını göstermiyor. | Düşük (CityView ile birlikte) |

### 1B. Fonksiyonlar (tanım satırı dışında hiçbir kod/sahne/araç başvurusu yok, dize ile çağrı da yok)

| Dosya:satır | Fonksiyon | Not | Risk |
|---|---|---|---|
| `scripts/autoload/audio_manager.gd:119` | `stop_music` | — | Düşük |
| `scripts/autoload/audio_manager.gd:125` | `get_current_track` | — | Düşük |
| `scripts/autoload/game_session.gd:600` | `get_stressed_characters` | — | Düşük |
| `scripts/autoload/game_session.gd:2577` | `has_earned_wagon_milestone` | — | Düşük |
| `scripts/campaign/campaign_catalog.gd:71` | `get_chapter_by_id` | — | Düşük |
| `scripts/character/beast_skin.gd:43` | `has_joint` | — | Düşük |
| `scripts/character/character_data.gd:824` | `get_gender_and_weight_line` | — | Düşük |
| `scripts/combat/combat_skill.gd:104` | `is_area` | — | Düşük |
| `scripts/economy/inventory.gd:94` | `has_item` | — | Düşük |
| `scripts/ui/combat_figure.gd:420` | `set_lunge` | Eski PR-7 sarmalayıcısı. Yerini `set_shift` aldı. | Düşük |
| `scripts/ui/combat_unit_slot.gd:322` | `apply_action_animation` | Eski PR-7 yolu. Yerini `apply_fx` aldı (`combat_panel.gd` yalnız `apply_fx` çağırıyor). | Düşük |
| `scripts/ui/grim/grim_drafts.gd:40` | `_chip` | Özel ve hiç çağrılmıyor. | Düşük |
| `scripts/ui/road_caravan.gd:651` | `is_leader_mounted` | — | Düşük |
| `scripts/ui/road_caravan.gd:1087` | `_leader_centre_rel` | Özel ve hiç çağrılmıyor. | Düşük |
| `scripts/ui/succession_panel.gd:197` | `get_selected` | — | Düşük |
| `scripts/ui/travel_band.gd:235` | `get_weather` | — | Düşük |
| `scripts/ui/travel_band.gd:380` | `get_turn_blend` | — | Düşük |
| `scripts/ui/travel_band.gd:390` | `get_caravan_anchor` | — | Düşük |
| `scripts/ui/walk_figure.gd:245` | `get_action` | — | Düşük |
| `scripts/ui/waybook_theme.gd:148` | `scaled_texture` | — | Düşük |

### 1C. Dinleyicisi olmayan sinyaller (emit ediliyor, hiçbir yerde `connect`/`await`/sahne bağlantısı yok)

CLAUDE.md, dinleyicisi olmayan `EventBus`'ı aynı gerekçeyle silmişti ("Don't reintroduce a bus without a subscriber").

| Dosya:satır | Sinyal | Emit yerleri | Risk |
|---|---|---|---|
| `scripts/autoload/game_state.gd:16` | `session_reset` | `:29`, `:34` | Düşük (emit satırları da silinir) |
| `scripts/combat/combat_encounter.gd:14` | `turn_started` | `:285` | Düşük |
| `scripts/economy/inventory.gd:4` | `item_added` | `:69` | Düşük |
| `scripts/economy/inventory.gd:5` | `item_removed` | `:86` | Düşük |
| `scripts/travel/caravan_plan.gd:11` | `selection_changed` | `:83`, `:90` | Düşük |
| `scripts/ui/save_slots_panel.gd:23` | `changed` | 2 emit. `in_game_menu.gd` ve `saves_screen.gd` bağlanmıyor. | Düşük |

### 1D. Kullanılmayan sabitler ve üyeler (adın kod/sahne/.tres içindeki tek geçişi tanımın kendisi)

| Dosya:satır | Öğe | Risk |
|---|---|---|
| `scripts/autoload/scene_ink.gd:26` | `SETTINGS_PATH` | Düşük |
| `scripts/economy/debt.gd:14` | `SOURCE_PENALTY` | Düşük (kayıtlarda `"penalty"` kaynağı yazılıyor mu, bkz. §7) |
| `scripts/economy/item.gd:19` | `@export var stack_size` | Düşük. Hiçbir `.tres` set etmiyor. |
| `scripts/travel/location.gd:15` | `@export var connections` | Düşük. Kenarlar `WorldMapData`'da tutuluyor. |
| `scripts/ui/art_palette.gd:42` | `UI_BACKDROP_SOLEMN` | Düşük |
| `scripts/ui/art_palette.gd:56-57` | `UI_TINT_HOVER`, `UI_TINT_PRESSED` | Düşük |
| `scripts/ui/art_palette.gd:153` | `GRIM_SLATE` | Düşük |
| `scripts/ui/combat_panel.gd:39` | `LUNGE_DISTANCE` (üstündeki 4 satırlık doc yorumu da yanlış öğeye bağlı) | Düşük |
| `scripts/ui/hub_scenery.gd:37` | `SKY_TOP_RATIO` | Düşük |
| `scripts/ui/wardrobe.gd:24` | `DROP_OK_COLOR` | Düşük |
| `tests/screenshot_turnaround.gd:51` | `_turn_clock` | Düşük |

### 1E. `data/` altındaki varlıklar (oyunda hiç okunmuyor)

| Dosya/öğe | Kanıt | Risk |
|---|---|---|
| `data/assets/fx/` altındaki 42 sprite (~290 KB): `circle_01/03/04`, `dirt_02/03`, `magic_01/02/05`, `muzzle_01-05`, `scorch_01-03`, `scratch_01`, `slash_01/03/04`, `smoke_01/09/10`, `spark_01-04/07`, `star_01/02/03/05/07/08/09`, `trace_01/02/04-07`, `twirl_03` | Sprite'lar yalnızca `scripts/ui/status_fx.gd` ve `scripts/ui/combat_fx_layer.gd` içindeki literal adlar ve `"smoke_0%d" % (4+i%5)` / `"flame_0%d"` ile okunuyor. Kullanılan küme 31 dosya, bu 42'si dışarıda kalıyor. Hepsi `export_filter=all_resources` ile Web'e gidiyor. | Orta. `tools/fx_assets.py:31-32`'deki `FAMILIES` listesinden `muzzle`, `scorch` ve `scratch` de çıkarılmalı ve dosya listesi daraltılmalı, yoksa yeniden üretimde dosyalar geri gelir. |
| `data/assets/ui/waybook/k1_slot.png` (62 KB), `k2_door.png` (78 KB) | Kodda başvuru yok. `combat_unit_slot.gd:30`: "Woodgrain K1/K2 dokuları tamamen kaldırıldı". | Orta. `tools/waybook_assets.py:355,357` hâlâ yazıyor, oradan da kaldırılmalı. |
| `data/assets/ui/waybook/r4c_danger.png`, `r4d_stamina.png` (~30 KB) | `"r4"` araması yalnızca `r4_vial`, `r4a_morale` ve `r4b_stress`'i buluyor. Yol HUD'u `SurvivalGauge`'a geçti. | Orta. `tools/waybook_assets.py:343` de güncellenmeli. |
| `data/assets/ui/waybook/b10_city.jpg` (205 KB) | Oyun kodunda/sahnelerde başvuru yok. Yalnız `tools/waybook_assets.py:330` ve `tools/waybook_ingest_v2.py:109` üretiyor. Şehir artık `CityFront`. | Orta (araç listesi de güncellenmeli) |
| `data/assets/props/iso_{inn,bell_tower,house_1,house_2,house_3,stable,market_stand_1,market_stand_2}` (~425 KB) | Tek kullanıcı ölü `city_view.gd:631-637`. Diğer başvuru yalnız `tests/test_props.gd:18-20`. | Orta. CityView ile birlikte gider. `tools/figure_pipeline/props/props.json` girdileri de silinmeli. |
| `data/assets/props/iso_blacksmith`, `iso_well` | Hiçbir `.gd` dosyasında yok, CityView dahil. Yalnız `props.json:516,551`. | Düşük |
| Kodda hiç çizilmeyen 13 eşya paketi: `backpack`, `bags_mv`, `barrel`, `bonfire_stones`, `crate`, `crate_carrot`, `fence`, `sack`, `saddlebag`, `signpost_single`, `stall_cart`, `weapon_bow` (CLAUDE.md Prop Rules: "Yay ... ve asa prosedürel"), `weapon_arrow` | `PropArt.has/draw*` çağrılarında ve `WEAPON_PROPS`'ta (`walk_figure.gd:819-825`) bu id'ler yok. Toplam ~322 KB, kalan silahlar dahil. | Düşük. Silahların kalanı için bkz. §7. |

### 1F. Çeviri anahtarları (CSV'de tanımlı, hiçbir `.gd`/`.tscn` dosyasında yok, dinamik desenlerle de eşleşmiyor)

| Anahtarlar | Kanıt / köken | Risk |
|---|---|---|
| `ui.csv`: `UI_PLAY`, `UI_PARTY_SIZE`, `UI_PARTY_WAGON_NOTE` | Eski ana menü ve karakter oluşturma | Düşük |
| `ui.csv`: `UI_CITY_{MARKET,TAVERN,YARD,GUILD,CHURCH}_DESC`, `UI_CITY_HUD`, `UI_CITY_INFO`, `UI_CITY_VIEW_PARTY`, `UI_CITY_LEAVE_BY_GATE`, `UI_CITY_DAMAGED_SUFFIX`, `UI_CITY_HOVER_HINT` | Eski şehir ekranı. CLAUDE.md `UI_CITY_HOVER_HINT`'in kullanılmadığını zaten kabul ediyor. | Düşük |
| `ui.csv`: `UI_GOAL_TITLE`, `UI_GOAL_SUMMARY`, `UI_GOAL_STATS` | `goal_reached.tscn` silinmiş (Lineage Rules: "The target and its screen are gone") | Düşük |
| `ui.csv`: `UI_COMBAT_YOUR_SIDE`, `UI_COMBAT_LOG`, `UI_COMBAT_UNIT`, `UI_COMBAT_TURN`, `UI_COMBAT_NO_TARGET`, `UI_COMBAT_PICK_TARGET`, `UI_COMBAT_TARGET` | Liste tabanlı eski savaş ekranı | Düşük |
| `ui.csv`: `UI_ROAD_COMBAT_DEATH`, `UI_ROAD_STATE` | `UI_ROAD_STATE` CLAUDE.md'de hâlâ "three lines by design" diye anılıyor. Kodda yok. | Düşük (CLAUDE.md cümlesi de düzeltilmeli) |
| `ui.csv`: `UI_INGAME_MENU_SETTINGS` | CLAUDE.md: "Settings is deliberately not in InGameMenu" | Düşük |
| `ui.csv`: `UI_WAYBOOK_DAYS`, `UI_WAYBOOK_UNWRITTEN` | — | Düşük |
| `events.csv`: `EVT_TEST_TITLE`, `EVT_TEST_ADVANCE`, `EVT_TEST_STATE`, `EVT_AMBUSH_FIGHT_WIN`, `EVT_AMBUSH_FIGHT_LOSE` | Pusu artık gerçek savaş açıyor. `EVT_TEST_*` anahtarlarından `RESET`, `LOG` ve `QUIET_DAY` hâlâ kullanılıyor. | Düşük |

`UI_GRIM_CLOSE`, `UI_GRIM_ENTER`, `UI_GRIM_NAV_LEAVE` ve `UI_GRIM_N_*` anahtarları da kullanılmıyor ama taslak bileşenlere ait oldukları için §2'de tutulacak.

### 1G. Araçlar ve dokümanlar (oyun dışı)

| Dosya/öğe | Kanıt | Risk |
|---|---|---|
| `tools/gate_template.py`, `docs/gate/gate_template.png`, `docs/gate/gate_palette.png`, `docs/gemini-prompts-gate.md` (~27 KB) | CLAUDE.md "Kapandı (Faz 25)": "Gemini kapı prompt'u (`docs/gemini-prompts-gate.md`) kullanılmadı". Kapı artık render edilmiş bir eşya. | Düşük |
| `tools/figure_pipeline/qa/perf_figure_crowd.gd`, `perf_figure_crowd_b.gd`, `perf_figure_crowd_c.gd` | Aşama 0 performans denemeleri. Karar `PERF.md`'ye yazıldı. Kod ve araç başvurusu yok, yalnız `PERF.md`. | Düşük |
| `tools/figure_pipeline/qa/gate_faz1.sh` | `cd /home/user/wayborne` ve `/tmp/Godot_v4.2.2...` sabit kodlanmış, bu ortamda çalışmaz. Faz 1 kapısı (FAZ1_GATE.md: "Kapı GEÇİLMEDİ") eski hattın kapısı. | Düşük |
| `tools/figure_pipeline/godot/capture_player.gd`, `figure_player.gd`, `export_clip_angles.gd`, `mesh/build_atlas.py`, `qa/run_faz1.py`, `qa/walk_gif.py`, `qa/validate_tests_on_old.py` | Yalnızca `gate_faz1.sh` ya da birbirleri çağırıyor. `build.py`/`run_build.py` zincirinde yoklar. `export_clip_angles.gd` hiç başvurulmuyor ve var olmayan `build/figures/faz1` dizinine yazıyor. | Düşük. Uyarı: `qa/faz1_tests.py` **canlı**, `run_build.py:21` import ediyor. |
| Mesh-deform (Yol B) kalıntıları: `tools/figure_pipeline/mesh/silhouette_mesh.py`, `blender/render_passes.py`, `blender/render_variant_debug.py`, `mesh/json_to_tres.gd`, `qa/render_full_body_gait.gd`, `qa/render_slice_gait.gd`, `qa/side_check_render.py` | POSTMORTEM.md:219 katmanlı kare render'a geçişi önerdi ve oyun artık `BodyFrames` kullanıyor. Bu dosyalara yalnız birbirleri ve DECISION.md / ASAMA_FULLBODY.md başvuruyor. | Düşük |
| `tools/figure_pipeline/config/variants/male_medium.json`, `female_medium.json` | `"_provisional"`. `config/build.json:3-10` yalnız `*_average/lean/heavy` kullanıyor. Başvuranlar yalnız yukarıdaki ölü betikler ve `make_variant.py`'nin docstring örneği. | Düşük (docstring örneği de güncellenmeli) |
| `tools/figure_pipeline/config/evidence/side_check_camera_minusX.png` (59 KB) | Yalnız `side_check_render.py` ile ilgili kanıt görseli | Düşük |
| Tarih notları: `tools/figure_pipeline/ASAMA1.md`, `ASAMA3.md`, `ASAMA4_NOTLAR.md`, `ASAMA_FULLBODY.md`, `FAZ1_GATE.md`, `qa/VALIDATION.md` | Hiçbiri canlı belgelerden (RULES/CLAUDE) başvurulmuyor. Silmek yerine `docs/archive/`'a taşınabilir. | Düşük |

### 1H. `art_source/` altındaki kaynaklar (hiçbir araç config'i okumuyor)

| Dosya/öğe | Boyut | Kanıt | Risk |
|---|---|---|---|
| `art_source/models/clothes/makehuman/elvs_ladies_apron/` (4 dosya) | 5.37 MB | CLAUDE.md: "**The apron was cut.**". `tools/figure_pipeline/config/outfits.json` içinde yok, `outfit_*apron*` frame seti de yok. | Orta. CC-BY künyesini de kaldırmak gerekir: `scripts/ui/credits.gd:17`, `CREDITS.md:17`, `art_source/models/clothes/makehuman/LICENSES.md:18`. |
| `art_source/models/props/quaternius_megakit_village/` (`Prop_Wagon.gltf/.bin`, `T_WoodTrim_BaseColor.png`, LICENSE) | 2.19 MB | `props.json` ve `tools/` içinde "megakit" ya da "Prop_Wagon" yok. CLAUDE.md Prop Rules: "MegaKit'in arabası tek akslı ve gevşek parçalı" (reddedildi). | Orta. Lisans tablosu (`art_source/models/props/LICENSES.md:8`) ve `CREDITS.md:38`'deki paket listesi de güncellenmeli. |
| `art_source/models/props/quaternius_modular_medieval/Bridge.blend` | 0.48 MB | `props.json` aynı paketten yalnız TallWall, TallWallEntrance, Tower ve WatchTowerWRoof kullanıyor. | Düşük |
| `art_source/waybook/` içinde reddedilen sayfalar: `G1_page_surface`, `G2_binding_frame`, `G3_seal_frame`, `G4_button_tab`, `G5_disabled_scratchout`, `G7_scrollbar_ribbon`, `G10_grain_stain_overlay`, `G11a_edge_bleed_v2`, `G11b_danger_edge_frost`, `G11b_edge_frost_v2`, `M1_waybook_cover_closed`, `M2_waybook_open_spread`, `R1_hud_top_strap`, `R2_hud_bottom_strap`, `R5_event_card_parchment` (15 jpg) | 9.79 MB | `tools/`, `scripts/` ve `docs/` içinde dosya adı geçmiyor. CLAUDE.md Waybook UI Rules: deri krom (G2/G3/G4/G7/R1), G5, G11 kenarları ve M1/M2 kitabı oyuncu tarafından reddedildi. "Nothing painted ships unread". | Düşük. İstenirse depo dışında arşivlenir. |

---

## 2. Gelecek için tutulacak (KEEP)

| Öğe | Durum (bugün) | Belge referansı |
|---|---|---|
| `scripts/ui/grim/grim_notice.gd` (`GrimNotice`) + `UI_GRIM_N_DEATH_*`, `UI_GRIM_N_PLAGUE_*` anahtarları + `GrimDrafts.push_notice` (`grim_drafts.gd:193`) | Yalnız taslak ve testlerde | REDESIGN.md §7.4 "defter olayları → GrimNotice", §4. CLAUDE.md Ana Hedefler "`GrimNotice`" |
| `scripts/ui/grim/trade_scales.gd`, `market_meter.gd` | Yalnız taslak ve testlerde | REDESIGN.md §7.5 "Pazar ve envanter", §4 "İlk turda onaylandı" |
| `scripts/ui/grim/worn_cell.gd` + `item_wear.gdshader` | Yalnız taslak | REDESIGN.md §7.6. CLAUDE.md Ana Hedefler "Eşya bozulması mekaniği" |
| `scripts/ui/grim/lantern_glow.gd`, `smoke_wisps.gd`, `ash_fall.gd` | Kısmen bağlı | REDESIGN.md §4 "Atmosfer ve kutusuz menü" |
| `scripts/ui/grim/grim_drafts.gd` (taslak ekran kurucusu) + `GrimDrafts.menu_position` (`:175`) | `title()` ve `tr_key()` üretimde. Geri kalanı taslak. | REDESIGN.md §4 "`GrimDrafts` Taslak ekranları kurar", §7. Adı için bkz. §6. |
| `UI_GRIM_CLOSE`, `UI_GRIM_ENTER`, `UI_GRIM_NAV_LEAVE` | Kullanılmıyor | REDESIGN.md §5/§7 (bağlanacak ekranlar). Bağlanmazsa §1F'ye taşınır. |
| `SurvivalGauge` Celsius kipi (`survival_gauge.gd:79-87`) | Gerçek veri yok | CLAUDE.md Ana Hedefler "Sıcaklık, Celsius derecesiyle". REDESIGN.md §7.6 |
| `scripts/character/body_frames.gd:21` `KIND_HAIR` | Kullanılmıyor | CLAUDE.md Wardrobe & Rig Rules: "`BodyFrames.KIND_HAIR` is the slot; `render_frames.py --hair`" |
| `EnemyCatalog.ROGUE_MAGE` | Hiç doğmuyor (testle kilitli) | CLAUDE.md Combat Rules "ready and never spawned ... lore decision" |
| `data/config/world_places.json` (46 KB, kodda hiçbir okuyucusu yok) | Henüz bağlı değil | CLAUDE.md Ana Hedefler "Evrenin lore'u ve tarihi". `docs/lore/SORULAR.md` "Faz G — Coğrafya" |
| `docs/lore/*` (LORE, TARIHCE, SORULAR, iki harita jpg ~0.9 MB) | Doküman | CLAUDE.md Ana Hedefler (lore) |
| `docs/ui/mockups/` (24 jpg, 5.75 MB) | Onaylı tasarım referansı | REDESIGN.md §7 (kalan ekranlar bağlanana kadar). Bağlandıktan sonra depo dışına alınabilir. |
| `docs/gemini-prompts.md`, `docs/wayborne_gorsel_denetim.xlsx` | Açık iş listesi | CLAUDE.md Ana Hedefler "Waybook'un kalan sanat borcu" (5 ikon) |
| `art_source/waybook/A0_style_anchor.jpg` | Hiçbir araç okumuyor | Aynı madde (yeni ikon üretiminde üslup çapası). Bkz. §7. |
| `tools/cjk_font_subset.py` | Elle çalıştırılıyor | CLAUDE.md Waybook UI Rules: "re-run it when the zh_CN/ja columns are filled" |
| `tools/waybook_ingest_v2.py` | Tek seferlik teslimat aracı | CLAUDE.md Waybook UI Rules "sibling tool for that shape" |
| `tools/wardrobe_cut.py`, `tools/wardrobe_paint_reference.py`, `tools/wardrobe_mannequin.py` | Boyama rotası terk edildi ama ilk ikisi `tools/human_body_parts.py:44-45` tarafından **import ediliyor** | CLAUDE.md "`wardrobe_mannequin.py` stays" |
| `tools/figure_pipeline/qa/faz1_tests.py`, `mesh/posterize.py` | Canlı (`run_build.py:21`, `pack_*.py`) | CLAUDE.md "figure pipeline" |
| `GameSession.resolve_combat_deaths` (`game_session.gd:919`, yalnız testlerde) | Harness sarmalayıcısı | CLAUDE.md Lineage Rules: "survives only as the backward-compatible wrapper the harnesses use" |

---

## 3. Hatalı / anlamsız kod

### 3A. Kodla çelişen bayat yorumlar

| Dosya:satır | Sorun | Önerilen düzeltme |
|---|---|---|
| `scripts/ui/road_journey.gd:3025-3028` | "Sefer sürerken kayıt hiç yapılamaz ... `to_save_dict()` sefer alanlarını hiç taşımıyor" diyor. `save_manager.gd:18-23` ve CLAUDE.md'ye göre sefer ortası otomatik kayıt var ve `journey` bloğu yazılıyor. | Yorumu "elle kayıt kapalı, otomatik kayıt sakin anlarda" diye yeniden yaz. |
| `scripts/autoload/dev_panel.gd:5-7` | "Nav.return_scene'e hiç dokunmadığı için" diyor. `return_scene` artık yok, yerine yığın var (`nav.gd:6`). | Yığın davranışını anlat. |
| `scripts/autoload/user_settings.gd:4` | "kayıt dosyasından (user://save.json)" diyor. Kayıtlar artık `user://saves/slot_N.json`. | Yolu düzelt. |
| `scripts/character/figure_rig.gd:15` | Var olmayan `tests/render_wardrobe_templates.gd`'ye başvuruyor. | Satırı sil ya da `tests/export_rig_spec.gd` yap. |
| `scripts/character/beast_rig.gd:250` | Silinmiş `tools/beast_cut.py`'ye başvuruyor. CLAUDE.md'ye göre deri rotası onun yerini aldı. | `tools/beast_skin.py`'ye çevir. |
| `tests/test_navigation.gd:295` | "mekânları artık `CityView`'dan alıyor" diyor. Gerçek kaynak `CityFront.VENUES`. | Adı düzelt. |
| `scripts/autoload/gamepad_cursor.gd:4` | Örnek olarak ölü `city_view.gd`'yi veriyor. | — |
| `scripts/ui/hub_scenery.gd:72` | "(bkz. CityView)" diyor. Şehir gökyüzü artık CityFront'ta. | — |
| `scripts/ui/grim/city_front.gd:13` | "CityView ile aynı sinyal" diyor. CityView kalkınca anlamsız kalır. | — |
| `scripts/ui/combat_panel.gd:35-39` | `_animate` ile ilgili doc yorumu `LUNGE_DISTANCE` sabitine yapışmış, ve o sabit kullanılmıyor. | Sabiti sil, yorumu `_animate`'e taşı. |
| `scripts/ui/combat_unit_slot.gd:318-321`, `scripts/ui/combat_figure.gd:413` | Ölü `apply_action_animation`/`set_lunge` yolunu "PR-7 katmanı" diye anlatıyor. | Fonksiyonlarla birlikte temizle. |
| `tools/fx_assets.py:31-32` | "Oyunun kullandığı aileler" listesinde `muzzle`, `scorch` ve `scratch` var. Oyun bu ailelerden hiçbirini kullanmıyor (bkz. §1E). | Listeyi daralt. |

### 3B. Bayat dokümanlar (yanlış bilgi veriyor)

| Dosya:satır | Sorun |
|---|---|
| `README.md:13-15` | "6 temel stat". Gerçekte 8 (CLAUDE.md Faz 17 PR-1). |
| `README.md:49-51` | "Altın negatife düşmez ... savaşta düşen biri ölmez". CLAUDE.md Caravan Ruin Rules (borç var) ve Combat Rules (ölüm gerçek) ile çelişiyor. |
| `README.md:71` (`data/config/ (henüz kullanılmıyor)`), `:104-106` ("yedi paket ve 300'den fazla doğrulama"; bugün 55 paket), `:128-132` ("Faz 0-7 tamam") | Güncel değil |
| `docs/ui/REDESIGN.md:3` | "Bu dal `main`'e birleştirilmedi" diyor. CLAUDE.md "Faz 27 ... birleştirildi". |
| `CLAUDE.md` | `:2486` "city map is a desk screen too now (B10, `b10_city.jpg`)" (artık CityFront). `:4683` SaveManager "yalnızca `user://save.json` ... yalnızca şehir varışında çağrılır". `:4725-4727` `game_config.json`/`enemy_data.json`/`quest_data.json` (bu dosyalar yok). `:7322` "Create your first scene in `scenes/main.tscn`". `:7330` "27 road events" (katalog 41+). |
| `docs/event-window-blueprint.md:3-4` | "Henüz hiçbir Godot kodu yazılmadı" diyor. Faz 22'de olay kartı resimleri bağlandı (`road_journey.gd:169` civarı `EVENT_CARD_ART`). Kısmen uygulanmış, durumu doğrulanmalı. |

### 3C. Tekrarlanan mantık (birleştirilebilir)

| Yardımcı | Kopyalar | Not |
|---|---|---|
| `_with_mipmaps(tex)` | `scripts/character/body_frames.gd:151`, `scripts/ui/prop_art.gd:68` | Birebir aynı. Tek statik yardımcıya taşınabilir (bkz. §4 O-4). |
| "import edilmişse `load`, değilse `Image.load_from_file`" doku yükleyici | `beast_rig.gd:297-300`, `wardrobe.gd:80-83`, `grim/city_front.gd:139-141`, `grim/grim_theme.gd:47-50`, `road_strips.gd:63-67` | 5 kopya. Tek bir `TextureLoader.load_any(path)` yeterli. |
| `_reduce_motion()` | `autoload/scene_ink.gd:103`, `ui/button_feedback.gd:133`, `ui/combat_panel.gd:601`, `ui/waybook_theme.gd:701` | 4 kopya, ikisi birebir aynı. |
| `_add_recruit_button` / `_on_recruit_button_pressed` | `guild.gd:278/286`, `market.gd:759/767`, `tavern.gd:165/173` | Gövdeler birebir aynı (md5 eşit). |
| `_clear_children` | `character.gd:538`, `combat_panel.gd:956`, `guild.gd:268`, `market.gd:749`, `party.gd:275`, `purification_panel.gd:109`, `recruit_panel.gd:180`, `road_journey.gd:3469` | 8 kopya |
| Statik `tr` sarmalayıcıları | `event_effect_applier.gd:42` (`_t`), `city_brief_model.gd:118` (`_t`), `world_map.gd:225` (`_t`), `grim/grim_drafts.gd:61` (`tr_key`) | 4 kopya |
| CI adımları | `.github/workflows/deploy.yml` (Import / Run tests / Fail on script errors) ve `tests.yml` | Aynı üç adım iki dosyada. Composite action ya da reusable workflow ile tekleştirilebilir. |

### 3D. Kurallarla çelişen kod

- `scripts/events/event_catalog.gd:2173-2174`: Olay başlık ve metin anahtarları `"%s_TITLE" % key_prefix` ile kuruluyor. CLAUDE.md Localization Rules "Write the keys out in full rather than assembling them at runtime" diyor. Tanımsız anahtar taraması bu anahtarları göremiyor. **Doğrulanmalı:** kasıtlı bir istisna mı?
- `scripts/ui/road_journey.gd:2161-2165`: Yorum kare başına string üretmeme sözü veriyor, ama aynı fonksiyon zincirinde `:2152`, `:2223-2236` ve `:1284-1293` her karede format yapıyor (bkz. §4 O-2).

Taranıp **temiz** çıkanlar: TODO/FIXME/HACK/XXX yok. `scripts/` içinde `print*` yok. `if false`, `breakpoint` ve `return` sonrası ulaşılamaz satır yok. Kodda var olmayan bir `res://` yoluna başvuru yok (yalnız üretilen `.translation` dosyaları ve araçların `build/` çıktıları, ki bunlar beklenen).

---

## 4. Optimizasyon önerileri

| # | Öneri | Kanıt | Beklenen etki |
|---|---|---|---|
| O-1 | `export_presets.cfg`'ye `exclude_filter="tests/*, tools/*"` ekle. `.gdignore` kullanma, çünkü `godot --script res://tools/...` çağrıları kırılır. | `export_presets.cfg:8-10` `all_resources` ve boş exclude. `tests/` 83 dosya, `tools/` 13 `.gd`. | Web paketi küçülür, test kodu oyuncuya gitmez. Boyut etkisi küçük, hijyen etkisi yüksek. **Önce** `test_selector.tscn`'in yalnız `scripts/` kullandığını doğrula. |
| O-2 | Yol ekranındaki kare başına string üretimini "değer değişince" kalıbına çevir: `_refresh_conditions` (`road_journey.gd:2223`; biyom/hava/tempo değişince), `_refresh_command_panel` (`:1267`; tooltip ve sofra metni yalnız durum değişince), ilerleme tooltip'i (`:2152`; yüzde değişince). | Kodun kendi yorumu (`:2161-2165`) Web'de "saniyede 180 gereksiz string" maliyetini zaten ölçmüş. | Web'de GC baskısı ve kare dalgalanması azalır (düşük-orta). |
| O-3 | Frame atlas paketlemesini sıkılaştır (maxrects ya da kırpılmış hücre). | 311 sayfa, 383 Mpx, opak doluluk **%18.7**. Gövde sayfalarında %10 (6 × 2048² sayfa/beden). Sıkıştırmasız RGBA olarak hepsi yüklenirse ~1.5 GB, mipmap ile +%33. | VRAM ve indirme boyutu için **en yüksek etki**: sayfa sayısında 3-5 kat azalma potansiyeli. Paketleyici `tools/figure_pipeline/mesh/pack_frames.py` / `pack_outfits.py`. Sabit hücre gerekçesini doğrula (§7). |
| O-4 | Çalışma anındaki `_with_mipmaps` yerine içe aktarma ayarı kullan: `project.godot`'a `[importer_defaults]` → `texture={"mipmaps/generate": true}` (izlenen bir dosya), ya da yalnız `frames/` ve `props/` için `.import` dosyalarını izlemeye al. | `body_frames.gd:151-159` ve `prop_art.gd:68` her sayfayı `get_image()` → `generate_mipmaps()` → `ImageTexture.create_from_image` ile **kopyalıyor**. CPU'da işleniyor, bellekte iki kopya duruyor, ilk çizimde takılma yapıyor. | Yükleme takılması ve RAM/VRAM kopyası ortadan kalkar (orta). CLAUDE.md'deki ".import depoda değil" gerekçesi `[importer_defaults]` ile aşılır. |
| O-5 | Kullanılmayan 42 fx sprite'ını, 21 eşya paketini ve 5 waybook dokusunu (§1E) üretim hattından çıkar. | §1E | Web paketi ~1.4 MB küçülür (düşük-orta) |
| O-6 | `GamepadCursor._process` (`gamepad_cursor.gd:69`) kumanda yokken çalışmasın: `Input.joy_connection_changed` sinyaline bağlan, kumanda yokken `set_process(false)`. | Oyun boyunca her karede `Input.get_connected_joypads()` dizisi üretiliyor. | Düşük |
| O-7 | `SceneInk._process` (`scene_ink.gd:168`) yalnız geçiş sırasında açık olsun (`go()` içinde `set_process(true)`, gelişte kapat). | Her karede `current_scene` sorgulanıyor. | Düşük |
| O-8 | Sürekli `queue_redraw` yapan bileşenlere boşta kalma kipi ekle: `SurvivalGauge._process` (`grim/survival_gauge.gd:73`, yol HUD'unda 4 adet), `AshFall` (`:28`), `SmokeWisps` (`:20`), `LanternGlow` (`:32`), `TradeScales` (`:34`). Değer sabitken animasyonu 15-20 Hz'e düşür ya da shader'a taşı. | Koşulsuz `_time += delta; queue_redraw()` | Yol ekranında küçük CPU ve batch kazancı (düşük) |
| O-9 | `BodyFrames._cache`/`_textures` (`body_frames.gd:76`) için çıkarma politikası ekle. | Statik sözlük süreç boyunca büyüyor. 286 set var (50 giysi × 6 beden). Wardrobe ekranında gezinmek sayfaları kalıcı tutuyor. | Uzun oturumda bellek (orta, **ölçülmeli**) |
| O-10 | Test süresini görünür kıl: `tests/run_tests.gd`'ye paket başına `Time.get_ticks_msec()` yaz. | Koşucuda zamanlama yok. Ağır aday paketler: `test_localization.gd` (her CSV hücresi için font `has_char`), `test_outfit.gd:157-176` (50 giysi × frames.tres), `test_combat_dd.gd:487,496` (600'lük döngüler), `test_route_terrain.gd`. | Optimizasyondan önce ölçüm (CLAUDE.md "Profile before optimizing") |
| O-11 | CI'da `.godot/imported` önbelleği: `actions/cache` anahtarı `hashFiles('data/**','project.godot')`. | `tests.yml` ve `deploy.yml` her koşuda ~1000 dokuyu sıfırdan içe aktarıyor (yeniden deneme mantığıyla birlikte). | CI süresinde muhtemelen en büyük kazanç (**ölçülmeli**) |
| O-12 | `art_source/models/animals/quaternius_gltf/glTF/*.gltf` (8 dosya) base64 gömülü tampon taşıyor. `.glb`'ye dönüştür. | `grep "base64,"`: 8 dosyanın hepsinde var (27 MB). | Depo -%25 civarı (~7 MB), araçlar aynı veriyi okur |
| O-13 | Tekrarlanan yardımcıları birleştir (§3C). | — | Bakım ve okunabilirlik |
| O-14 | Büyük dosyaları böl. | `game_session.gd` 3575 satır, `road_journey.gd` 3495 satır, `event_catalog.gd` 2260 satır. CLAUDE.md "Keep functions < 30 lines". | Bakım (uzun vadeli, düşük öncelik) |

---

## 5. Depo hijyeni (boyutlarla)

| # | Bulgu | Boyut | Öneri |
|---|---|---|---|
| H-1 | LFS ve `.gitattributes` yok. İkili dosyalar düz git'te. | Çalışma ağacı 420 MB. Pack 570 MiB. | Yeni commitler için LFS: `data/assets/characters/frames/**`, `art_source/**`, `*.blend`, `*.gltf`, `*.glb`, `*.bin`, `*.obj`, `*.mhclo`, `*.png`/`*.jpg` (büyük olanlar), `*.mp3`, `*.otf`/`*.ttf`. Geçmişi yeniden yazmak (`git lfs migrate`) ayrı ve onay isteyen bir karar (bkz. §7). |
| H-2 | Geçmişte HEAD'de olmayan blob'lar | 290 MB / 596 MB. Bunun 224 MB'ı `data/assets/characters` (frame sayfalarının eski render'ları), 16 MB'ı `data/assets/ui`. | Frame'ler her render turunda yeniden yazılıyor. LFS ile geçmiş büyümesi durur. |
| H-3 | Geçmişte silinmiş `art_source/models/human-base-meshes-bundle-v1.0.0.zip` | 33.5 MB | Yalnız history rewrite ile temizlenir. |
| H-4 | `data/assets/characters/frames` (597 dosya) | 151 MB (en büyük tek klasör). Sayfa başına 1-2 MB PNG. | O-3 (paketleme) ve LFS. Posterize edildikleri halde sayfa başına 7-15 bin renk var, palet PNG'ye düşürme sanatsal onay gerektirir. |
| H-5 | `art_source/` | 205 MB: `models` 131 MB (`clothes` 59, `props` 41, `animals` 28, `ui_scenes` 2.5), `waybook` 57.6 MB, `textures` 13 MB, `fx` 3.6 MB | Kaynak dosyaların depoda kalması tasarım gereği (araçlar okuyor). LFS'e alınabilir. Atıl kısım (~17 MB) §1H'de. |
| H-6 | Uzantıya göre ikililer: `.blend` 43 dosya / 30.3 MB. `.gltf` 35 / 27.6 MB (8'i gömülü base64). `.obj` 40 / 18.7 MB. `.mhclo` 40 / 12.5 MB. `.mhmat` 40 / 0.03 MB. `.png` 813 / 190 MB. `.jpg` 175 / 88 MB. `.tres` 297 / 26 MB (frames.tres ~150 KB/adet). | — | `.mhclo`/`.obj`/`.mhmat` MakeHuman kaynakları araçların girdisi, depoda kalmalı ama LFS'e alınmalı. En büyükleri: `elvs_caesar_sandals1` (.obj 6.3 MB + .mhclo 3.3 MB, outfits.json'da kullanılıyor, **canlı**) ve `elvs_ladies_apron` (5.4 MB, **atıl**). |
| H-7 | En büyük tekil dosyalar | `T_Ranger_BaseColor.png` 6.6 MB, `elvs_mh_cesaersandalf1.obj` 6.3 MB, `T_Peasant_BaseColor.png` 5.1 MB, `high_noon_in_the_square.mp3` 4.3 MB, hayvan `.gltf` dosyaları 3.1-3.7 MB | Dokular gltf ile birlikte kullanılıyor (canlı). |
| H-8 | `.gitignore` boşlukları | — | Ekle: `*.blend1`, `*.blend@` (Blender yedekleri), `.DS_Store`, `Thumbs.db`, `*.log` (CI'nin `import.log`/`tests.log` dosyaları yerelde de oluşur), `*.orig`. `data_*/` satırı Mono kalıntısı ve `data_` önekli her klasörü yutar. Proje Mono değil, kaldırılabilir. Bugün çalışma ağacı temiz: izlenmeyen ya da yok sayılan dosya yok. |
| H-9 | Satır sonları | Kod dosyaları LF. `core.autocrlf=true` bu makinede açık. Yalnız 3. parti `.obj/.mhclo/.txt` dosyaları CRLF. | `.gitattributes`: `*.gd *.tscn *.tres *.py *.csv *.json *.md text eol=lf`, ikililer için `binary`. Windows makinesinden yapılacak commitlerde CI güvenliği sağlar. |
| H-10 | Deneme ve kalıntı görünümlü dosyalar | `tools/figure_pipeline/qa/perf_figure_crowd_b.gd`, `_c.gd`, `render_variant_debug.py`, `validate_tests_on_old.py`, `gate_faz1.sh`, `config/variants/*_medium.json`, `ASAMA*.md` (§1G). `scripts/ui/grim/grim_drafts.gd` taslak ama kısmen üretimde (§2). | §1G |
| H-11 | `CLAUDE.md` 475 KB (7300+ satır). Faz anlatıları, ölçüm tabloları ve tarih kuralların içine karışmış. | 0.48 MB (geçmişte 1.06 MB eski sürüm) | Yeni oturumlara bağlam maliyeti yüksek, bayat cümleler birikiyor (bkz. §3B). Kurallar kalsın, "Development Status" ve ölçüm anlatıları `GELISIM_GECMISI.md` ya da `docs/history/` altına taşınsın. **Kullanıcı onayı gerekir.** |

---

## 6. İsim kuralı ihlalleri (referans oyun'a özgü adlar)

| # | Kapsam | Yerler | Not |
|---|---|---|---|
| N-1 | Dizin ve dosya adları | `scripts/ui/grim/` (14 dosya), `data/assets/ui/grim/` (28 dosya, `kit/` dahil), `tests/test_grim_ui.gd`, `tests/screenshot_grim_ui.gd`, `tools/grim_ui_assets.py` | "Grim"in referans oyun kökenli olup olmadığını doğrula (§7). REDESIGN.md §1 referans tablosu tasarımın referans oyun mezra ve kadro ekranlarından alındığını yazıyor. CLAUDE.md Ana Hedefler: "Dosya ve sınıf adları oyuna özgü kalır (başka bir oyunun terimi değil)". |
| N-2 | Sınıflar | `GrimTheme` (97 geçiş), `GrimDrafts` (21), `GrimNotice` (23) | N-1 ile birlikte. REDESIGN §7.1 zaten GrimTheme'in WaybookTheme'e taşınmasını planlıyor. |
| N-3 | Palet sabitleri | `scripts/ui/art_palette.gd` içinde 13 `GRIM_*` (`GRIM_PARCHMENT`, `GRIM_CRIMSON`, `GRIM_AMBER`, `GRIM_RUST`, `GRIM_CHARCOAL`, `GRIM_IRON`, `GRIM_SLATE_LIGHT`, `GRIM_BILE`, `GRIM_ASH`, `GRIM_FROST` ...) | Yorum `:144` "referans oyun #a02b19" diye referans veriyor. |
| N-4 | Çeviri anahtarları | `data/locale/ui.csv` içinde 76 `UI_GRIM_*` anahtarı | Yeniden adlandırmada `.gd` ve `.tscn` başvuruları da güncellenmeli. `test_localization.gd` tanımsız anahtarları yakalar. |
| N-5 | Test dosya adı | `tests/test_combat_dd.gd` (ve `tests/run_tests.gd` içindeki kaydı) | — |
| N-6 | "mezra" | `scripts/travel/route_terrain.gd:25` `STOP_MEZRA = "mezra"` (+ `:134,136,140,249,255`). `scripts/events/event_resolver.gd:40` ve `event_catalog.gd:1629,1639` `near_mezra`. `scripts/ui/travel_band.gd:957,987`. `scripts/ui/road_journey.gd:169,2074`. `tests/test_memory.gd:629-630`, `tests/test_route_terrain.gd:171`. `data/locale/game.csv:330` anahtarı `STOP_MEZRA`. `data/config/world_places.json` içinde 12 kez `"kind": "ih_mezra"`. `data/assets/ui/waybook/e6j_mezra.jpg`. | Durak tohumdan hesaplanıyor ve kayda yazılmıyor (Route Terrain Rules), bu yüzden yeniden adlandırma kayıt uyumluluğunu bozmamalı. Yine de doğrula (§7). CSV'deki İngilizce görünen metin ("mezra") genel bir kelime, ayrı karar. |
| N-7 | Kod yorumlarında "referans oyun" kısaltması | 27 geçiş: `game_session.gd:1262`, `character_data.gd:555`, `character_stats.gd:222`, `equipment.gd:6`, `equipment_catalog.gd:18`, `trait.gd:37`, `combat_encounter.gd:77,82,180,185`, `combat_unit.gd:229,247`, `enemy_catalog.gd:203`, `event_catalog.gd:645,1068`, `combat_figure.gd:23`, `combat_panel.gd:46,64`, `combat_unit_slot.gd:20`, `grim/city_front.gd:289`, `tools/ui_scenes/town_post.py:11`, `town_scene.py:131,309`, `ui_kit.py:228`, `tests/test_equipment.gd:138` ... | Tanımlayıcı değil, yorum. Kural "dosyaların içinde" dediği için listeleniyor, kapsamı doğrulanmalı (§7). |
| N-8 | Kod ve araç yorumlarında "referans oyun" | 29 geçiş: `combat_encounter.gd:4`, `combat_skill.gd:4,58`, `equipment.gd:4,35`, `trait.gd:4`, `combat_unit.gd:117,305`, `character_data.gd:607,709`, `character_stats.gd:201`, `caravan_ledger.gd:11`, `road_signals.gd:76`, `combat_backdrop.gd:5`, `road_journey.gd:2716`, `game_session.gd:587`, `tests/simulate_journeys.gd:644`, `tests/test_combat_dd.gd:3`, `tests/test_equipment.gd:86`, `tools/grim_ui_assets.py:4`, `tools/ui_scenes/town_post.py:1`, `town_scene.py:1`, `docs/codex/codex_body.py:41,358,385,432,436,442`, `codex_events_data.py:436,498` | Codex dosyaları oyuncuya dönük PDF metni üretiyor. Kapsam için §7. |
| N-9 | Dokümanlar | `CLAUDE.md` (referans oyun 14, "referans oyun" 13, "mezra" 2), `README.md` (3), `docs/ui/REDESIGN.md` (referans oyun 2, "referans oyun" 4, "mezra" 1, "grim" 15), `GELISIM_GECMISI.md` (2) | Tasarım referansı olarak anılıyor. Kural dokümanları da kapsıyorsa yeniden yazılmalı. |

**Uygulama önerisi:** N-1..N-6 tek bir PR'da toplanabilir. Sıra: önce sınıf, sabit ve anahtar yeniden adlandırması (`git mv` + toplu değiştirme), sonra `run_tests.gd` + CI taraması. `art_palette.gd`'nin `GRIM_*` bloğu REDESIGN §7.1'in planladığı WaybookTheme'e taşınma işiyle birlikte yapılırsa iş iki kez yapılmaz.

---

## 7. Doğrulanması gerekenler

1. **"Grim" referans oyun kökenli mi?** Kullanıcı kuralı "Grim... if referans oyun-derived" diyor. Kod ve REDESIGN.md referans oyunda referans gösteriyor ama "grim" İngilizcede genel bir sıfat. Karar kullanıcıda. CLAUDE.md'deki "başka bir oyunun terimi değil" cümlesi yeniden adlandırma lehine.
2. **"mezra" yeniden adlandırması:** `STOP_MEZRA` değeri kayda, olay bağlamı anahtarlarına (`near_mezra`) ya da codex'e sızıyor mu? `GameSession.to_save_dict()` ve `JourneyController.to_dict()` incelenmeli. `world_places.json` içindeki `ih_mezra` ne anlama geliyor ve hangi araç üretiyor? (Kodda okuyucu yok.)
3. **Yorum ve dokümanlardaki referans oyun/referans oyun anmaları (N-7..N-9) kurala dahil mi?** Yalnız tanımlayıcılar mı, yoksa düzyazı referansı da mı? Codex PDF'i oyuncuya dönük.
4. **`DevPanel` (F1) ve `test_selector.tscn` Web sürümünde kalmalı mı?** Autoload her başlangıçta paneli kuruyor (`dev_panel.gd:17-25`) ve `OS.is_debug_build()` kontrolü yok. README bunu bir özellik olarak anlatıyor, kasıtlı olabilir.
5. **Kullanılmayan silah eşyaları** (`weapon_sword_1`, `weapon_sword_3`, `weapon_axe`, `weapon_club`, `weapon_dagger`, `weapon_shield_heater`): ileride ganimet ya da donanım kademeleri için mi render edildiler? Ana Hedefler'de yalnız `GRANT_OUTFIT` var, silah yok. Plan yoksa §1E'ye taşınır.
6. **`CityView` + `iso_*` + `b10_city.jpg` birlikte silinsin mi?** REDESIGN §7.2 ✓ diyor. Izometrik şehre dönüş planı var mı, kontrol et.
7. **Yalnız testlerden çağrılan 36 public fonksiyon** (ör. `GameSession.has_route_override:482`, `is_run_over:1019`, `RouteConditions.clear_override:84`, `RouteTerrain.stop_name_key:247`, `RoadCaravan` içindeki 13 `get_*` erişimcisi, `Nav.reset:155`) test API'si olarak mı kalacak? Özellikle `stop_name_key`: durak adları hiçbir ekranda gösterilmiyor mu? CLAUDE.md "the planner prints them in one line" diyor.
8. **`Debt.SOURCE_PENALTY`**: eski kayıtlarda `"penalty"` kaynağı yazılmış olabilir mi? Silmeden önce `debt_ledger.gd` yükleme yolunu kontrol et.
9. **Atlas doluluğu (%18.7) bilinçli mi?** Kareler arası hizalama ya da sabit hücre gerekçesi var mı? `pack_frames.py`/`pack_outfits.py` incelenmeli. Değişiklik bütün frame setlerinin yeniden paketlenmesini (≈150 MB yeni blob) gerektirir. H-1'den sonra yapılmalı.
10. **`[importer_defaults]` ile mipmap** tüm projeye mi uygulanmalı, yoksa yalnız belirli klasörlere `.import` dosyası izleyerek mi? UI dokularında mipmap gereksiz VRAM demek.
11. **LFS geçmiş göçü** (`git lfs migrate import --everything`): commit hash'lerini değiştirir, açık PR'ları ve klonları etkiler. Yalnız ileriye dönük LFS de bir seçenek.
12. **`art_source/waybook/A0_style_anchor.jpg`** yeni ikon üretiminde (Ana Hedefler, 5 açık ikon) kullanılacak mı?
13. **`docs/art-prompts.md` ve `docs/event-window-blueprint.md`**: dünya sahneleri artık Blender render'ı (Faz 25/27). Bu iki prompt/plan dokümanı hâlâ geçerli mi, yoksa arşive mi taşınmalı?
14. **Test süresi:** CI süresi ve ağır paketler bu denetimde ölçülemedi (Godot çalıştırılmadı). O-10 ve O-11 için önce ölçüm.
15. **`tools/figure_pipeline/beasts/build_beasts.py`**: hiçbir dosya başvurmuyor ama giriş noktası olabilir (`render_beast`/`pack_beasts`'i sırayla çağırıyor). CLAUDE.md yalnız `render_beast.py` ve `pack_beasts.py`'yi anıyor. Kullanılıyorsa CLAUDE.md'ye eklenmeli.
16. **`tests/screenshot_*` ile kurulan `perf_50.gd` ve QA `.gd` betikleri** O-1'deki exclude ile Web'den çıkar. `tools/figure_pipeline/godot/export_clips.gd` CLAUDE.md'de canlı, çıkarılmadığından emin ol (yalnız export'tan çıkıyor, depodan değil).
17. **Olay anahtarlarının `"%s_TITLE"` ile kurulması** (§3D) kasıtlı bir istisna mı? Değilse anahtarlar `_event()` çağrılarına açık yazılmalı.
18. **`UI_GRIM_CLOSE` / `UI_GRIM_ENTER` / `UI_GRIM_NAV_LEAVE`**: REDESIGN'daki bağlanacak ekranlarda kullanılacak mı? Kullanılmayacaksa §1F'ye eklenir.

---

### Ek: Kullanılan tarama betikleri

Scratchpad: `an1.py` (boyutlar), `an2.py` (sınıf, fonksiyon, sinyal ve sabit başvuruları), `an3.py` (`data/` varlıkları), `an4.py` (ulaşılamaz kod). Ek olarak `git rev-list --objects --all | git cat-file --batch-check` (geçmiş boyutu) ve PIL ile atlas doluluk ölçümü kullanıldı. Hepsi salt okunur.
