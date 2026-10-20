# Değişiklik kaydı (başka bir Claude sohbetine aktarım için)

Bu dosya, 2026-10-19 toplu çalışmasında ve öncesindeki iki yerel dalda yapılan **bütün** değişiklikleri tek yerde toplar. Yeni bir sohbet önce bunu, sonra dört durum belgesini okumalı.

## Nerede ne var

| Yer | İçerik |
|---|---|
| `wayborne/` (git) | Oyun deposu. Dal `yerel/yapilacaklar-p05-p06` (önceki `yerel/yapilacaklar-p01-p04`, ikisi de `main` üstünde). **Push yok.** Commit iletilerinde Claude ibaresi yok (KVKK). |
| `TODO/YAPILAN_ISLER.md` | Bitmiş ve doğrulanmış görevler |
| `TODO/TEST_BEKLEYEN.md` | Kodu bitmiş, testi akşam koşusunda; başında koşunun adımları |
| `TODO/YARIM_VE_ONAY_BEKLEYEN.md` | Kısmen yapılanlar ve taslağı/planı onayda olanlar; indirme durumu |
| `TODO/KALAN_ISLER.md` | Başlanmamışlar: kullanıcı işi, kararı, lore, yeni alt görevler |
| `TODO/referans/` | Görev kaydı (`gorevler.json`), görevlerin ayrıntılı bölüm metinleri (`gorevler/`), belgeler, referans görseller, harita, kontrol görüntüleri, taslaklar (`taslaklar/`), belge üreteci (`belge_uret.py`) |
| `araclar/indirilenler/` | 2026-10-19'da indirilen CC0 paketler (Kenney x5, Poly Haven Lantern 01); kopyaları `wayborne/art_source` |

## Kurallar (yeni sohbet için)

- Kullanıcı bilgisayarda çalışırken Godot açılmaz (pencere); Blender `-b` serbest. Testler akşam, `TEST_BEKLEYEN.md`.
- referans oyunun adı, kısaltması ve küçük köy türünün eski İngilizce adı depo dosyalarına yazılmaz. Dini sembol yok. PC hedef, Web yalnız test.
- İndirme yalnız kullanıcı izniyle (son izin: yalnız CC0). Ücretli üretim maliyet tahmini ve onay ister.
- Kullanım %80'i geçince eldeki iş bitirilir, not alınır, durulur.
- Görev durumu değişince `TODO/referans/gorevler.json` güncellenir ve `python -X utf8 referans/belge_uret.py` (TODO içinden) koşulur.

## Commit listesi (main..HEAD, eskiden yeniye)

- **32f9ac4** (2026-10-18) 6.1 (satır sonu kısmı): .gitattributes ile metin dosyaları LF'e sabitlendi  
  `.gitattributes`
- **af1f044** (2026-10-18) 6.2: .gitignore boşlukları dolduruldu  
  `.gitignore`
- **ded1091** (2026-10-18) 2.1: dışa aktarımdan tests/ ve tools/ çıkarıldı  
  `export_presets.cfg`
- **5dfcc5b** (2026-10-18) 2.4: paket başına test süresi ölçüldü, tests.yml'e içe aktarma önbelleği eklendi  
  `.github/workflows/tests.yml`, `tests/run_tests.gd`
- **6868274** (2026-10-18) Y-K02: ekran görüntüsü karşılaştırma aracı ve screenshots iş akışı  
  `.github/workflows/screenshots.yml`, `tools/ci/screenshot_diff.py`, `tools/ci/test_screenshot_diff.py`
- **0dc0f02** (2026-10-18) 1.1 + 9.13: yol durağı türü ve resmi oyuna özgü adlarla yeniden adlandırıldı  
  `data/assets/ui/waybook/e6j_village.jpg`, `data/config/world_places.json`, `data/locale/game.csv`, `scripts/events/event_catalog.gd`, `scripts/events/event_resolver.gd`, `scripts/travel/route_terrain.gd`, `scripts/ui/road_journey.gd`, `scripts/ui/travel_band.gd` ve 2 dosya daha
- **aa01c40** (2026-10-18) 1.2: savaş testi dosyası ve paket adı test_combat_core olarak yeniden adlandırıldı  
  `scripts/combat/combat_skill.gd`, `scripts/combat/combat_unit.gd`, `scripts/combat/skill_catalog.gd`, `tests/run_tests.gd`, `tests/test_caravan_layout.gd`, `tests/test_combat_core.gd`
- **35f65f5** (2026-10-18) 1.3: kod, test ve araç yorumlarındaki başka oyun anmaları kaldırıldı  
  `scripts/autoload/game_session.gd`, `scripts/campaign/caravan_ledger.gd`, `scripts/character/character_data.gd`, `scripts/character/character_stats.gd`, `scripts/character/equipment.gd`, `scripts/character/equipment_catalog.gd`, `scripts/character/trait.gd`, `scripts/combat/combat_encounter.gd` ve 19 dosya daha
- **bb0d5d2** (2026-10-18) 1.4 + 1.5: belgelerdeki başka-oyun anmaları ve eski durak adı temizlendi  
  `CLAUDE.md`, `GELISIM_GECMISI.md`, `README.md`, `docs/art-prompts.md`, `docs/codex/codex_body.py`, `docs/codex/codex_events_data.py`, `docs/event-window-blueprint.md`, `docs/gemini-prompts.md` ve 1 dosya daha
- **7d16b27** (2026-10-18) 3.1: kullanılmayan 20 fonksiyon silindi  
  `scripts/autoload/audio_manager.gd`, `scripts/autoload/game_session.gd`, `scripts/campaign/campaign_catalog.gd`, `scripts/character/beast_skin.gd`, `scripts/character/character_data.gd`, `scripts/combat/combat_skill.gd`, `scripts/economy/inventory.gd`, `scripts/ui/combat_figure.gd` ve 7 dosya daha
- **d692d28** (2026-10-18) 3.2: dinleyicisi olmayan 6 sinyal ve emit satırları silindi  
  `scripts/autoload/game_state.gd`, `scripts/combat/combat_encounter.gd`, `scripts/economy/inventory.gd`, `scripts/travel/caravan_plan.gd`, `scripts/ui/save_slots_panel.gd`
- **e561542** (2026-10-18) 3.3: kullanılmayan sabit ve üyeler silindi  
  `scripts/autoload/scene_ink.gd`, `scripts/economy/debt.gd`, `scripts/economy/item.gd`, `scripts/travel/location.gd`, `scripts/ui/art_palette.gd`, `scripts/ui/combat_panel.gd`, `scripts/ui/hub_scenery.gd`, `scripts/ui/wardrobe.gd` ve 1 dosya daha
- **5cfed17** (2026-10-18) 3.5: kullanılmayan 34 çeviri anahtarı silindi  
  `data/locale/events.csv`, `data/locale/ui.csv`
- **9deffb7** (2026-10-18) 3.7: art_source içindeki reddedilmiş kaynaklar depodan çıkarıldı (~17 MB)  
  `CREDITS.md`, `art_source/models/clothes/makehuman/LICENSES.md`, `art_source/models/clothes/makehuman/elvs_ladies_apron/apron2.png`, `art_source/models/clothes/makehuman/elvs_ladies_apron/elvs_ladies_apron.mhclo`, `art_source/models/clothes/makehuman/elvs_ladies_apron/elvs_lady_apron1.mhmat`, `art_source/models/clothes/makehuman/elvs_ladies_apron/elvs_lady_apron1.obj`, `art_source/models/props/LICENSES.md`, `art_source/models/props/quaternius_megakit_village/LICENSE.txt` ve 20 dosya daha
- **b247080** (2026-10-18) 3.6: ölü araç, betik ve belgeler kaldırıldı; tarih notları docs/archive'e taşındı  
  `docs/archive/figure_pipeline/ASAMA1.md`, `docs/archive/figure_pipeline/ASAMA3.md`, `docs/archive/figure_pipeline/ASAMA4_NOTLAR.md`, `docs/archive/figure_pipeline/ASAMA_FULLBODY.md`, `docs/archive/figure_pipeline/FAZ1_GATE.md`, `docs/archive/figure_pipeline/VALIDATION.md`, `docs/gate/gate_palette.png`, `docs/gate/gate_template.png` ve 22 dosya daha
- **153173a** (2026-10-18) 3.4 (kısmen): kullanılmayan görsel varlıklar ve üretim hatları temizlendi  
  `data/assets/fx/circle_01.png`, `data/assets/fx/circle_03.png`, `data/assets/fx/circle_04.png`, `data/assets/fx/dirt_02.png`, `data/assets/fx/dirt_03.png`, `data/assets/fx/magic_01.png`, `data/assets/fx/magic_02.png`, `data/assets/fx/magic_05.png` ve 42 dosya daha
- **b756a52** (2026-10-18) 2.3 (kısmen): ölü CityView sınıfı ve ekran görüntüsü aracı kaldırıldı  
  `scripts/autoload/gamepad_cursor.gd`, `scripts/ui/city_view.gd`, `scripts/ui/grim/city_front.gd`, `scripts/ui/hub_scenery.gd`, `tests/screenshot_city.gd`, `tests/test_navigation.gd`
- **b3d43ce** (2026-10-18) 4.1: kodla çelişen bayat yorumlar düzeltildi  
  `scripts/autoload/dev_panel.gd`, `scripts/autoload/user_settings.gd`, `scripts/character/beast_rig.gd`, `scripts/character/figure_rig.gd`, `scripts/ui/road_journey.gd`
- **a29413e** (2026-10-18) 4.3 (kısmen): tekrarlanan yardımcılar tek kapıya indirildi  
  `scripts/character/beast_rig.gd`, `scripts/character/body_frames.gd`, `scripts/character/wardrobe.gd`, `scripts/ui/character.gd`, `scripts/ui/combat_panel.gd`, `scripts/ui/grim/city_front.gd`, `scripts/ui/grim/grim_drafts.gd`, `scripts/ui/grim/grim_theme.gd` ve 14 dosya daha
- **2b13dcc** (2026-10-18) 6.3 + Y-F11 + Y-A01/A02 + Y-K01 + Y-E03: CLAUDE.md incelt, vaat/sütun/kural ekle  
  `CLAUDE.md`, `docs/history/FAZ_ANLATILARI.md`
- **85c337b** (2026-10-18) 4.2: README, REDESIGN ve olay penceresi belgesindeki bayat olgular düzeltildi  
  `README.md`, `docs/event-window-blueprint.md`, `docs/ui/REDESIGN.md`
- **574669a** (2026-10-18) Y-J05: AI beyanı gerçek durumu anlatıyor, künyeye CC0 üreticiler, ambientCG ve yazı tipleri eklendi  
  `AI_DISCLOSURE.md`, `CREDITS.md`, `scripts/ui/credits.gd`
- **133f20d** (2026-10-18) 11.1: açık yol işaretleri sefer ortası kaydında saklanıyor  
  `scripts/travel/journey_controller.gd`, `scripts/travel/road_signals.gd`, `scripts/ui/road_journey.gd`, `tests/run_tests.gd`, `tests/test_road_signals_save.gd`
- **bffa479** (2026-10-18) 12.2c: kamp yürüyüşü üst sınırlı, ateş ilk varanla tutuşuyor, kamp sayacı herkes varınca başlıyor  
  `data/locale/ui.csv`, `scripts/travel/journey_controller.gd`, `scripts/ui/road_caravan.gd`, `scripts/ui/road_journey.gd`, `tests/screenshot_camp.gd`, `tests/test_camp_gathering.gd`
- **0b5e4b6** (2026-10-18) 12.2b: kamp ve durma sırasında manzara ölçeği yerinde kalıyor, duraklar kadrajdan kaçmıyor  
  `scripts/ui/road_journey.gd`, `tests/test_caravan_layout.gd`
- **2eaec93** (2026-10-18) 12.2d: yol zemin şeritlerinden kütük gibi okunan taşlar çıkarıldı  
  `.gitignore`, `data/assets/ui/road/forest/ground.png`, `data/assets/ui/road/lake/ground.png`, `data/assets/ui/road/marsh/ground.png`, `data/assets/ui/road/mountain/ground.png`, `data/assets/ui/road/steppe/ground.png`, `tools/ui_scenes/road_scene.py`, `tools/ui_scenes/town_scene.py`
- **6f3fdca** (2026-10-18) 2.2: yol ekranında her karede kurulan metinler yalnızca girdi değişince kuruluyor  
  `data/assets/ui/grim/crack_overlay.png`, `scripts/ui/road_journey.gd`
- **74b3a1a** (2026-10-18) 2.5: SurvivalGauge cam çatlağı efekti kaldırıldı  
  `scripts/ui/grim/survival_gauge.gd`, `tests/test_grim_ui.gd`, `tools/grim_ui_assets.py`
- **d69a3d5** (2026-10-18) 5.1 (kısmen) + Y-H04: boşta dönen _process döngüleri durduruldu, Esc her alt ekrandan geri götürüyor  
  `scripts/autoload/gamepad_cursor.gd`, `scripts/autoload/scene_ink.gd`, `scripts/autoload/ui_theme.gd`, `tests/test_navigation.gd`
- **7c5fe49** (2026-10-18) CLAUDE.md: kamp süresi ve manzara ölçeği kuralları (12.2c, 12.2b)  
  `CLAUDE.md`
- **5c47fbd** (2026-10-18) 5.5: gömülü base64 içeren 8 hayvan .gltf dosyası .glb'ye çevrildi  
  `art_source/models/animals/quaternius_gltf/glTF/Bull.glb`, `art_source/models/animals/quaternius_gltf/glTF/Bull.gltf`, `art_source/models/animals/quaternius_gltf/glTF/Deer.glb`, `art_source/models/animals/quaternius_gltf/glTF/Deer.gltf`, `art_source/models/animals/quaternius_gltf/glTF/Donkey.glb`, `art_source/models/animals/quaternius_gltf/glTF/Donkey.gltf`, `art_source/models/animals/quaternius_gltf/glTF/Horse.glb`, `art_source/models/animals/quaternius_gltf/glTF/Horse.gltf` ve 11 dosya daha
- **04f0db7** (2026-10-18) 8.9: harita üretim hattı tools/worldmap altına alındı  
  `tools/worldmap/README.md`, `tools/worldmap/atlas/names/names.json`, `tools/worldmap/atlas/names/names_i18n.json`, `tools/worldmap/atlas/names/names_i18n.py`, `tools/worldmap/atlas/names/places_v2.json`, `tools/worldmap/atlas/names/regions.py`, `tools/worldmap/atlas/places.json`, `tools/worldmap/atlas/places_v3.json` ve 52 dosya daha
- **b5f543a** (2026-10-18) 8.1 (kısmen): harita karo katmanı MapTileView  
  `.gitignore`, `project.godot`, `scripts/ui/map_tile_view.gd`, `tests/run_tests.gd`, `tests/screenshot_map_tiles.gd`, `tests/test_map_tile_view.gd`, `tools/worldmap/install_tiles.py`
- **0f71c17** (2026-10-18) project.godot: --import çalıştırmasının yanlışlıkla yeniden yazdığı satırlar geri alındı (windows_native_title)  
  `project.godot`
- **c3527b0** (2026-10-18) N1-N3: 27 oynanabilir yerleşim, yol grafiği ve süreler harita v3'ten  
  `data/config/settlements.json`, `docs/design_notes/yerlesimler_rapor.md`, `tools/worldmap/build_settlements.py`
- **f8c9df2** (2026-10-18) N5, N9 verisi: yerleşim başına mallar ve kültüre göre başlangıç adayları  
  `data/config/settlements.json`, `docs/design_notes/yerlesimler_rapor.md`, `tools/worldmap/build_settlements.py`, `tools/worldmap/economy.json`
- **887fa0c** (2026-10-18) N6 + N4 + N9: oyun yeni dünyada; eski beş yer tutucu şehir kalktı  
  `data/locale/game.csv`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/combat/enemy_catalog.gd`, `scripts/economy/market_conditions.gd`, `scripts/economy/market_pricing.gd`, `scripts/events/event_catalog.gd`, `scripts/travel/location.gd` ve 17 dosya daha
- **b4a41c2** (2026-10-18) N7 + N24: dünya haritası ekranı yeni haritada, yolda açılır harita; karolar Git LFS ile oyunda  
  `.gitattributes`, `.github/workflows/deploy.yml`, `.github/workflows/screenshots.yml`, `.github/workflows/tests.yml`, `.gitignore`, `data/assets/map/rider/atli_B.png`, `data/assets/map/rider/atli_D.png`, `data/assets/map/rider/atli_G.png` ve 354 dosya daha
- **bf9f5ff** (2026-10-18) N8: yeni dünyada denge ölçümü; kontrat günlük ücreti ve başlangıç kuralı  
  `data/config/settlements.json`, `docs/design_notes/denge_yeni_dunya.md`, `docs/design_notes/yerlesimler_rapor.md`, `scripts/travel/world_map_data.gd`, `tools/worldmap/build_settlements.py`
- **f405e82** (2026-10-18) P18: yol ekranına sekmeli kontrol paneli  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/ui/road_control_panel.gd`, `scripts/ui/road_journey.gd`, `tests/run_tests.gd`, `tests/screenshot_journey_screen.gd`, `tests/test_road_control_panel.gd`
- **67c47ba** (2026-10-19) P17 (N11-N15): her yerleşime kendi şehir resmi; stil rehberi  
  `CLAUDE.md`, `data/assets/ui/towns/akavan/background.jpg`, `data/assets/ui/towns/akavan/mask.json`, `data/assets/ui/towns/akavan/mask.png`, `data/assets/ui/towns/auderin/background.jpg`, `data/assets/ui/towns/auderin/mask.json`, `data/assets/ui/towns/auderin/mask.png`, `data/assets/ui/towns/belvanor/background.jpg` ve 80 dosya daha
- **19555b5** (2026-10-19) Yol ve harita düzeltmeleri: dağ zirvesi kesiği, atlının gölgesi, koltuktaki sürücü  
  `CLAUDE.md`, `data/assets/map/rider/atli_B.png`, `data/assets/map/rider/atli_D.png`, `data/assets/map/rider/atli_G.png`, `data/assets/map/rider/atli_GB.png`, `data/assets/map/rider/atli_GD.png`, `data/assets/map/rider/atli_K.png`, `data/assets/map/rider/atli_KB.png` ve 9 dosya daha
- **2c8be40** (2026-10-19) N28: yol ekranının arazisi haritadan  
  `CLAUDE.md`, `data/config/settlements.json`, `scripts/travel/route_terrain.gd`, `scripts/travel/world_map_data.gd`, `scripts/ui/caravan_planner.gd`, `scripts/ui/road_journey.gd`, `tests/test_route_terrain.gd`, `tools/worldmap/build_settlements.py`
- **5ae38c4** (2026-10-19) N29 + N30: vadiye yeşil çayır biyomu; bozkırda durak aralığı açıldı  
  `CLAUDE.md`, `data/assets/ui/road/meadow/far.png`, `data/assets/ui/road/meadow/fore.png`, `data/assets/ui/road/meadow/ground.png`, `data/assets/ui/road/meadow/layout.json`, `data/assets/ui/road/meadow/mid.png`, `data/config/settlements.json`, `data/locale/game.csv` ve 8 dosya daha
- **8b9db66** (2026-10-19) 1.4 + 1.5: Codex PDF yeniden üretildi; isim kuralı testle korunuyor  
  `CLAUDE.md`, `docs/Wayborne-Codex.pdf`, `docs/codex/codex_base.py`, `tests/run_tests.gd`, `tests/test_naming_rule.gd`, `tools/worldmap/README.md`, `tools/worldmap/build_settlements.py`
- **3e35324** (2026-10-19) 4.3: hareket azaltma okuması tek kapıda (NodeUtil.reduce_motion)  
  `scripts/ui/combat_panel.gd`, `scripts/ui/waybook_theme.gd`, `scripts/util/node_util.gd`, `tests/test_util.gd`
- **7083b90** (2026-10-19) Y-A01, Y-K01, Y-F11, Y-J13: tasarım belgesi, mağaza metni, döngü listesi, terim sözlüğü; CLAUDE.md inceldi  
  `CLAUDE.md`, `docs/design/TASARIM.md`, `docs/history/CLAUDE_ARSIV.md`, `docs/localization/TERIM_SOZLUGU.md`, `docs/playtest/DONGU_KONTROL.md`, `docs/steam/MAGAZA_METNI.md`
- **6630a09** (2026-10-19) Y-E03 + Y-J05: yedi karta cazip ama riskli seçenek; ses künyesi ve lisans testi  
  `AI_DISCLOSURE.md`, `data/assets/audio/KUNYE.tsv`, `data/locale/events.csv`, `docs/design_notes/olay_kart_incelemesi.md`, `scripts/events/event_catalog.gd`, `scripts/events/event_effect_applier.gd`, `tests/run_tests.gd`, `tests/test_audio_credits.gd`
- **968111f** (2026-10-19) 12.2c: kamp ateşinin sesi  
  `data/assets/audio/KUNYE.tsv`, `data/assets/audio/fire_crackle.wav`, `data/assets/audio/fire_ignite.wav`, `scripts/autoload/audio_manager.gd`, `scripts/ui/road_caravan.gd`, `scripts/ui/road_journey.gd`, `tools/audio/make_fire_sounds.py`
- **9d924e7** (2026-10-19) 5.1 (O-8): ortam animasyonları görünmezken çizilmiyor, en çok 30 Hz; terazi dengede duruyor  
  `scripts/ui/grim/ash_fall.gd`, `scripts/ui/grim/lantern_glow.gd`, `scripts/ui/grim/smoke_wisps.gd`, `scripts/ui/grim/survival_gauge.gd`, `scripts/ui/grim/trade_scales.gd`, `scripts/util/node_util.gd`, `tests/test_util.gd`
- **9c85ade** (2026-10-19) Y-H04: Esc açık paneli kapatıyor, altındaki ekranı değil  
  `scripts/ui/caravan_cargo_panel.gd`, `scripts/ui/caravan_overview_panel.gd`, `scripts/ui/meal_distribution_panel.gd`, `scripts/ui/merchant_dialogue_panel.gd`, `scripts/ui/pre_combat_panel.gd`, `scripts/ui/succession_panel.gd`, `scripts/ui/wagon_panel.gd`, `tests/run_tests.gd` ve 1 dosya daha
- **ba76d99** (2026-10-19) 10.1 + 10.2 + 10.4: binici eyerde, atta kol sallamıyor, öküz koşulu  
  `scripts/character/figure_rig.gd`, `scripts/ui/art_draw.gd`, `scripts/ui/road_caravan.gd`, `scripts/ui/walk_figure.gd`, `tests/test_caravan_layout.gd`, `tests/test_gait.gd`
- **4250a4a** (2026-10-19) Y-G12 (kısmen): çıplak ten yok - görünüşte boş gömlek, pantolon ve ayakkabı yuvası köylü takımıyla çiziliyor  
  `scripts/character/character_data.gd`, `scripts/character/outfit_catalog.gd`, `scripts/ui/walk_figure.gd`, `tests/test_outfit.gd`
- **8b303d0** (2026-10-19) Y-G15: kurt tek kaynaktan - savaş kurdu olay kartının rengine çekildi; vagon zaten tek kaynaktan  
  `scripts/ui/combat_figure.gd`
- **9534722** (2026-10-19) 5.3: kare kümesi önbelleğine çıkarma politikası (en uzun süredir istenmeyen, 96 küme sınırı)  
  `scripts/character/body_frames.gd`, `tests/test_util.gd`
- **afccc63** (2026-10-19) Y-G02 (öneri): ortak mürekkep geçişi aracı ve önce/sonra denemesi  
  `docs/design_notes/npr_gecisi.md`, `tools/npr/ink_pass.py`
- **c59fb3a** (2026-10-19) 8.5: harita etiketlerinin altındaki yol kapandı; yazılar asıl yazı tipiyle (IM FELL)  
  `data/assets/map/tiles/0/0_0.jpg`, `data/assets/map/tiles/1/0_0.jpg`, `data/assets/map/tiles/1/0_1.jpg`, `data/assets/map/tiles/1/1_0.jpg`, `data/assets/map/tiles/1/1_1.jpg`, `data/assets/map/tiles/2/0_0.jpg`, `data/assets/map/tiles/2/0_1.jpg`, `data/assets/map/tiles/2/0_2.jpg` ve 239 dosya daha
- **dc516c6** (2026-10-19) 8.4: kullanılmayan world_places.json kaldırıldı  
  `data/config/world_places.json`
- **4eca777** (2026-10-19) Harita saati tutuyor: saat tonu, yerleşim ışıkları ve kervanın izi (8.10, 8.11, Y-G09)  
  `CLAUDE.md`, `data/config/settlements.json`, `scripts/autoload/game_session.gd`, `scripts/travel/world_map_data.gd`, `scripts/ui/road_control_panel.gd`, `scripts/ui/road_journey.gd`, `scripts/ui/world_map.gd`, `scripts/ui/world_map_view.gd` ve 2 dosya daha
- **cefadb6** (2026-10-19) Planlayıcıda tehlikenin dökümü, motorun adımlarından (Y-F10)  
  `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/ui/caravan_planner.gd`, `tests/test_world_map_data.gd`
- **824187d** (2026-10-19) Aynı rotada farklı yol: mevsim araziyi değiştirir, planlayıcıda kestirme (Y-B13)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/travel/route_terrain.gd`, `scripts/ui/caravan_planner.gd`, `scripts/ui/road_journey.gd`, `tests/test_memory.gd`, `tests/test_route_terrain.gd`
- **0c1b9d6** (2026-10-19) Başlangıç: kervan babadan borçlu devralınıyor, devir sahnesi (Y-C14)  
  `CLAUDE.md`, `data/locale/game.csv`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/ui/character_creation.gd`, `scripts/ui/inheritance_panel.gd`, `scripts/world/city_map.gd`, `tests/playthrough_demo.gd` ve 2 dosya daha
- **abc9d82** (2026-10-19) Fiyat defteri: görülen fiyat tarihli ve eskir, tavernada yanılabilen fiyat söylentisi (Y-C10)  
  `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/ui/market.gd`, `scripts/ui/price_book_panel.gd`, `scripts/ui/tavern.gd`, `tests/test_city_commerce.gd`
- **6014abe** (2026-10-19) Pazar satırında fiyatın yedi katmanı işaret ve açıklamayla (Y-C11)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/economy/market_conditions.gd`, `scripts/economy/market_pricing.gd`, `scripts/ui/market.gd`, `scripts/ui/price_layer_text.gd`, `tests/test_market_conditions.gd`
- **9b79738** (2026-10-19) Mal çeşitliliği: bozulan balık, kaçak tuz ve gümrük, nadir mühür, toplu alım; al-sat sömürüsü kapandı (Y-C19)  
  `CLAUDE.md`, `data/locale/events.csv`, `data/locale/game.csv`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/economy/item.gd`, `scripts/economy/item_catalog.gd`, `scripts/economy/market_pricing.gd` ve 7 dosya daha
- **05ce4d8** (2026-10-19) Sofranın çeşnisi: şarap, bal, taze balık ve haftalık ziyafet akşamı (Y-B07)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/ui/meal_distribution_panel.gd`, `scripts/ui/road_journey.gd`, `tests/test_standing_orders.gd`
- **71a5964** (2026-10-19) Ziyafet testi: moral tavanı  
  `tests/test_standing_orders.gd`
- **fa60be3** (2026-10-19) Yolda erzak: av eti, köy durağında erzak, toplayıcılık bir gün yer (Y-B06)  
  `CLAUDE.md`, `data/locale/events.csv`, `scripts/autoload/game_session.gd`, `scripts/events/event_catalog.gd`, `scripts/ui/road_journey.gd`, `tests/test_event_effects.gd`
- **2bc6802** (2026-10-19) Dinamik kontrat panosu: beş tür, acele, vagon kirası, emanet yük; ilan tahtası görünümü (Y-C02)  
  `CLAUDE.md`, `data/locale/game.csv`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/economy/item_catalog.gd`, `scripts/travel/caravan_plan.gd`, `scripts/travel/caravan_state.gd`, `scripts/travel/contract_board.gd` ve 8 dosya daha
- **ee5ea65** (2026-10-19) Tüccar mizacı yolda: dört mizaca dört kart, hedefli ayrılma (Y-F05)  
  `CLAUDE.md`, `data/locale/events.csv`, `scripts/autoload/game_session.gd`, `scripts/events/event_catalog.gd`, `scripts/events/event_effect_applier.gd`, `scripts/travel/caravan_state.gd`, `tests/test_event_effects.gd`
- **8d435e1** (2026-10-19) Yol altyapısı ve yanına yürü konuş: figür-kişi eşlemesi, baloncuk, sohbet çekirdeği, geçmiş ve bağ, yeni defter türleri (R0, R1 #1, Y-B01)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/campaign/caravan_ledger.gd`, `scripts/character/character_data.gd`, `scripts/travel/road_chatter.gd`, `scripts/ui/road_balloon.gd`, `scripts/ui/road_caravan.gd` ve 3 dosya daha
- **dd0d737** (2026-10-19) Yoldaşların bağı, kendi kararları ve kamp ateşi hikâyeleri; kişisel geçmiş ve hedef (R1, Y-C17)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/character/camp_story.gd`, `scripts/character/character_data.gd`, `scripts/character/companion_life.gd`, `scripts/ui/camp_story_panel.gd`, `scripts/ui/character.gd` ve 5 dosya daha
- **e87e40e** (2026-10-19) İşaretler bulmaca: her işaretin gizli gerçeği, kehanet işareti, gerçeğe göre bedel ve ödül (Y-B03)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/travel/road_signals.gd`, `scripts/ui/road_journey.gd`, `tests/test_road_signals_save.gd`
- **40276b9** (2026-10-19) Görevler üç role iner, roller kendi bölgesine bakar, kampta diziliş ve akşam eylemleri (Y-F09, Y-B04, Y-B12)  
  `CLAUDE.md`, `data/locale/game.csv`, `data/locale/ui.csv`, `docs/design_notes/gorev_rolleri.md`, `scripts/autoload/game_session.gd`, `scripts/character/character_data.gd`, `scripts/character/duty_catalog.gd`, `scripts/travel/road_signals.gd` ve 5 dosya daha
- **c330b93** (2026-10-19) Yol yönetmeni: sessizlik gerilimi, ağır karttan sonra rahatlama, zorlanan kervan; gece işaretleri ve önlemler (Y-B02)  
  `CLAUDE.md`, `scripts/autoload/game_session.gd`, `scripts/events/event_engine.gd`, `scripts/events/road_director.gd`, `scripts/travel/journey_controller.gd`, `scripts/travel/road_signals.gd`, `scripts/ui/road_journey.gd`, `tests/simulate_journeys.gd` ve 1 dosya daha
- **f92a1cc** (2026-10-19) Havaya karşı küçük kararlar; gece yürüyüşü ve fener/meşale (Y-B05, Y-C20)  
  `CLAUDE.md`, `data/locale/game.csv`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/economy/item_catalog.gd`, `scripts/travel/location.gd`, `scripts/travel/weather_calls.gd`, `scripts/ui/road_caravan.gd` ve 3 dosya daha
- **b8ba074** (2026-10-19) Başka kervanlar: dört tür yolda görünür, her birinin kart zinciri (Y-B10)  
  `data/locale/events.csv`, `scripts/events/event_catalog.gd`, `scripts/ui/road_journey.gd`, `tests/test_event_effects.gd`
- **a31c52c** (2026-10-19) Yolun hafızası: mezar, lider taşı, enkaz, kül yolda kalır; yol kaç kez yüründüğünü hatırlar (Y-B11, R2)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/events/event_effect_applier.gd`, `scripts/ui/caravan_planner.gd`, `scripts/ui/road_journey.gd`, `scripts/ui/travel_band.gd`, `tests/test_lineage.gd` ve 1 dosya daha
- **4d5f4ed** (2026-10-19) Irmak geçidi: köprülerin bir kısmı geçit, tohumlu su seviyesi, seviyeye göre açılan kart (R4)  
  `CLAUDE.md`, `data/locale/events.csv`, `data/locale/game.csv`, `data/locale/ui.csv`, `scripts/events/event_catalog.gd`, `scripts/events/event_resolver.gd`, `scripts/travel/route_ford.gd`, `scripts/travel/route_terrain.gd` ve 3 dosya daha
- **4017eda** (2026-10-19) Hızlandırma kalktı (0.5x ve 1x kalır), yolun doluluk ölçümü (Y-B09)  
  `CLAUDE.md`, `scripts/travel/journey_clock.gd`, `tests/simulate_road_beats.gd`, `tests/test_journey_clock.gd`
- **5f32931** (2026-10-19) Düşman huyları, davranışla yaşanan kırılma (savaşta ve yolda), bedelli geri çekilme (Y-C08, Y-D06, Y-C07)  
  `CLAUDE.md`, `data/locale/events.csv`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/character/character_data.gd`, `scripts/combat/combat_encounter.gd`, `scripts/combat/combat_unit.gd`, `scripts/events/event_catalog.gd` ve 4 dosya daha
- **5d4018d** (2026-10-19) Ganimet tabloları ve zafer ekranında ganimet, GRANT_OUTFIT; savaşta ve kampta sargı/iksir; her tarifin tüketicisi (Y-C03, Y-C04, Y-F03)  
  `CLAUDE.md`, `data/config/loot.json`, `data/locale/game.csv`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/combat/combat_encounter.gd`, `scripts/combat/combat_unit.gd`, `scripts/economy/crafting_recipe.gd` ve 8 dosya daha
- **4d6fb67** (2026-10-19) Vagon atölyesi kendi ekranı: vagonun resmi, tayfası, hâli ve yükü, tezgâhta resimli tarif kartları (Y-F04T)  
  `data/locale/ui.csv`, `scripts/ui/wagon_panel.gd`
- **c4a5782** (2026-10-19) Sakatlık ve hastalık, hekim ve şehrin ilaç stoğu; satılan iksir stoğa girer (Y-C05)  
  `CLAUDE.md`, `data/locale/game.csv`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/character/character_data.gd`, `scripts/economy/market_conditions.gd`, `scripts/ui/church.gd`, `scripts/ui/road_journey.gd` ve 2 dosya daha
- **86fdc4b** (2026-10-19) Moral ve takat tasarım notu: takat kişinin bedeninde (Y-F01)  
  `docs/design_notes/moral_ve_takat.md`
- **ba7b508** (2026-10-19) İşe alma zor ve kişisel: az aday, savaşta daha az, pahalı, iyi aday nadir, neden geldiği kartta (Y-C16)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/character/recruit_catalog.gd`, `scripts/ui/recruit_panel.gd`, `tests/test_recruit_catalog.gd`
- **c890afe** (2026-10-19) Orta ve geç oyunda tehditler sıklaşır: kariyer evresi, tehdit kartı ağırlıkları, simülatör sayacı (Y-C15)  
  `CLAUDE.md`, `scripts/autoload/game_session.gd`, `scripts/events/event_catalog.gd`, `tests/simulate_career.gd`, `tests/test_event_engine.gd`
- **dcd1edc** (2026-10-19) Haydut büyücü nadir bir olaydan doğar, büyüleriyle savaşır (Y-F07T)  
  `CLAUDE.md`, `data/locale/events.csv`, `data/locale/game.csv`, `scripts/combat/enemy_catalog.gd`, `scripts/events/event_catalog.gd`, `scripts/ui/road_journey.gd`, `tests/test_combat_core.gd`
- **897b6d2** (2026-10-19) Kader Modu ve açık zorluk ayarları: ölümcül darbe, açlık, olay sertliği (Y-D01)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/combat/combat_unit.gd`, `scripts/events/road_director.gd`, `scripts/ui/character_creation.gd`, `scripts/ui/road_journey.gd`, `scripts/world/city_map.gd` ve 2 dosya daha
- **20d8861** (2026-10-19) Soy mirasi: biten soy arsive yazilir, yeni oyun mezarlarini, unu ve yadigarini okur (Y-D03)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/campaign/lineage_archive.gd`, `scripts/ui/character_creation.gd`, `scripts/ui/road_control_panel.gd`, `scripts/ui/road_journey.gd`, `scripts/ui/world_map.gd` ve 3 dosya daha
- **0428df4** (2026-10-19) Meta ilerleme: biten soylar bes yeni baslangic kokeni acar, guc degil takas (Y-D05)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/game_session.gd`, `scripts/campaign/lineage_archive.gd`, `scripts/campaign/start_origins.gd`, `scripts/ui/character_creation.gd`, `tests/test_lineage_archive.gd`
- **3069762** (2026-10-19) Uzun zincir altyapisi: CHAIN_ADVANCE, kayitli zincir durumu, baska sehirde ya da varis doneminde olgunlasan karsilik (Y-E02 sistem)  
  `CLAUDE.md`, `scripts/autoload/game_session.gd`, `scripts/events/event_effect.gd`, `scripts/events/event_effect_applier.gd`, `tests/run_tests.gd`, `tests/test_event_chains.gd`
- **cbe2b02** (2026-10-19) Olay havuzu altyapisi: kart kalite listesi, kalite raporu, finale kadar tekrar orani (Y-E01 sistem)  
  `CLAUDE.md`, `docs/design_notes/olay_uretim_duzeni.md`, `scripts/events/event_quality.gd`, `tests/report_event_quality.gd`, `tests/run_tests.gd`, `tests/simulate_career.gd`, `tests/test_event_quality.gd`
- **b76bb93** (2026-10-19) Zindanlar tasarim notu: giris, asama dizisi, savas, ganimet, kayip, bekleyen kervan (Y-A07)  
  `docs/design_notes/zindanlar.md`
- **35a0db9** (2026-10-19) Paylasilabilir defter sayfasi (PNG) ve katalogdan uretilen Codex olay sayfalari (Y-E07)  
  `CLAUDE.md`, `data/locale/ui.csv`, `docs/codex/README.md`, `docs/codex/codex_event.py`, `docs/codex/codex_events_auto.py`, `docs/codex/codex_main.py`, `scripts/campaign/ledger_page.gd`, `scripts/ui/waybook_panel.gd` ve 2 dosya daha
- **b620a9b** (2026-10-19) Sehir kamerasi bir tik geride: 20 mm lens ve toplu kasaba render betigi (12.1)  
  `tools/ui_scenes/render_all_towns.py`, `tools/ui_scenes/settlement_towns.py`, `tools/ui_scenes/towns.json`
- **2dd895a** (2026-10-19) Yol gorunumu revizyonu tasarim notu; gok ve isik taslagi (12.2, 12.2e)  
  `docs/design_notes/yol_revizyonu.md`
- **5bfcc7d** (2026-10-19) Sehir kapisi sahnesi: kasabadan turetilen kapi tanimi, Quaternius sur parcalari, tas boyasi; taslak ciktisi oyunun resimlerine yazilmaz (12.2a)  
  `tools/ui_scenes/gates.json`, `tools/ui_scenes/settlement_gates.py`, `tools/ui_scenes/town_post.py`, `tools/ui_scenes/town_scene.py`
- **c8cf507** (2026-10-19) Tipografi birligi: uc yazi yuzu stil rehberinde, yazi klasoru testle korunuyor (Y-G14)  
  `docs/ui/STIL_REHBERI.md`, `tests/test_waybook_theme.gd`
- **972c733** (2026-10-19) Savasa vurus hissi: kritikte yakinlasma ve anlatici satiri, olumde kisa duraklama, vurus ses kimlikleri (Y-H05)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/audio_manager.gd`, `scripts/ui/combat_fx.gd`, `scripts/ui/combat_panel.gd`, `tests/test_combat_fx.gd`
- **3784072** (2026-10-19) Fener motifi stil rehberinde: bes yer, logo amblemi indirme bekliyor (Y-G08)  
  `docs/ui/STIL_REHBERI.md`
- **6d2c0c2** (2026-10-19) Sayi degil soz: Wording, gosterge ipuclari once soz sonra sayi, etki satirlari, dil kilavuzu (Y-H03)  
  `CLAUDE.md`, `data/locale/game.csv`, `docs/design_notes/dil_kilavuzu.md`, `scripts/events/event_effect_applier.gd`, `scripts/ui/grim/survival_gauge.gd`, `scripts/ui/road_journey.gd`, `scripts/ui/wording.gd`, `tests/run_tests.gd` ve 1 dosya daha
- **2001285** (2026-10-19) Ogretim ilk seferin icinde: alti konu ilk karsilasildigi anda tek cumleyle; yeni oyun dort konuluk paneli acmiyor (Y-H01)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/ui/caravan_planner.gd`, `scripts/ui/first_time_hint.gd`, `scripts/ui/guild.gd`, `scripts/ui/market.gd`, `scripts/ui/meal_distribution_panel.gd`, `scripts/ui/road_journey.gd` ve 6 dosya daha
- **46fa60b** (2026-10-19) Ilk dakikalarin cizelgesi: oyun suresi, dort ilk isareti, oyuncu testi dosyasi ve raporu (Y-H02)  
  `docs/design_notes/ilk_on_dakika.md`, `scripts/autoload/game_session.gd`, `scripts/autoload/game_state.gd`, `scripts/events/event_effect_applier.gd`, `scripts/events/event_resolver.gd`, `tests/run_tests.gd`, `tests/test_first_minutes.gd`, `tests/test_memory.gd` ve 1 dosya daha
- **20d0400** (2026-10-19) Erisilebilirlik ve oynanis ayarlari: metin boyu, desenli savas seridi, yolda bir sey belirince duraklama (Y-H07)  
  `CLAUDE.md`, `data/locale/ui.csv`, `scripts/autoload/user_settings.gd`, `scripts/ui/pattern_stripe.gd`, `scripts/ui/road_journey.gd`, `scripts/ui/settings.gd`, `scripts/ui/waybook_theme.gd`, `tests/run_tests.gd` ve 1 dosya daha
- **f3e22fb** (2026-10-19) Kumanda, Steam Deck ve Xbox denetimi: bugunku sanal imlec, eksikler, sira (Y-H06)  
  `docs/design_notes/kumanda_denetimi.md`
- **7a44c6e** (2026-10-19) Demo ve Next Fest plani: Valve kurali dogrulandi, fest boyunca demo, EA festten sonra (Y-J04)  
  `docs/design_notes/demo_next_fest.md`
- **f5e6c40** (2026-10-19) Kliplenebilir anlar listesi: bes sahne, baslangic, son, tetikleme (Y-J09)  
  `docs/design_notes/kliplenebilir_anlar.md`
- **e967039** (2026-10-19) Ust seridin sayi satiri kalkti; itibar, vagon, tuccar ve evrak Durum sekmesinde (N23)  
  `data/locale/ui.csv`, `scripts/ui/road_control_panel.gd`, `scripts/ui/road_journey.gd`
- **ebd4e3a** (2026-10-19) Oyun hissi incelemesi ve plani: alti alan, durum, eksik, oneri, maliyet; alt gorevler (N31)  
  `docs/design_notes/oyun_hissi_plani.md`
- **370024b** (2026-10-19) Defter okunur: cetvel cizgileri silindi (ledger_unrule araci, normalize evrisim, CC0 kagit dokusu)  
  `art_source/waybook/l1_ledger_ruled.jpg`, `data/assets/ui/waybook/l1_ledger.jpg`, `tools/ledger_unrule.py`
- **a2b21b1** (2026-10-19) CC0 paketler eklendi: Kenney Castle Kit (tam), Graveyard Kit, Impact Sounds, UI Pack RPG Expansion, Fantasy UI Borders; Poly Haven Lantern 01; lisans ve kunye  
  `CREDITS.md`, `art_source/audio/LICENSES.md`, `art_source/audio/kenney_impact_sounds/License.txt`, `art_source/audio/kenney_impact_sounds/footstep_carpet_000.ogg`, `art_source/audio/kenney_impact_sounds/footstep_carpet_001.ogg`, `art_source/audio/kenney_impact_sounds/footstep_carpet_002.ogg`, `art_source/audio/kenney_impact_sounds/footstep_carpet_003.ogg`, `art_source/audio/kenney_impact_sounds/footstep_carpet_004.ogg` ve 517 dosya daha
- **1913854** (2026-10-19) Vurus sesleri: Kenney Impact Sounds, besli cesit, rastgele secim ve perde oynamasi (Y-H05)  
  `CLAUDE.md`, `data/assets/audio/combat/hit_0.ogg`, `data/assets/audio/combat/hit_1.ogg`, `data/assets/audio/combat/hit_2.ogg`, `data/assets/audio/combat/hit_3.ogg`, `data/assets/audio/combat/hit_4.ogg`, `data/assets/audio/combat/hit_crit_0.ogg`, `data/assets/audio/combat/hit_crit_1.ogg` ve 9 dosya daha
- **f9961ed** (2026-10-19) Fener amblemi: Lantern 01 render ve murekkep gecisi, ana menu basliginin yaninda (Y-G08)  
  `data/assets/ui/grim/lantern_emblem.png`, `docs/ui/STIL_REHBERI.md`, `scripts/ui/grim/grim_drafts.gd`, `tools/ui_scenes/lantern_emblem.py`, `tools/ui_scenes/lantern_emblem_post.py`
- **67ded6b** (2026-10-19) Mezarlik arka plani: Kenney Graveyard Kit ile sakin ve nobet varyantlari, hacsiz (9.12)  
  `tools/ui_scenes/graveyard_scene.py`, `tools/ui_scenes/graveyards.json`
- **019a8a5** (2026-10-19) UI kiti v2 taslagi: Kenney CC0 bicimleri murekkep ve palet renklerine boyandi, onaydan once oyuna girmiyor (9.1)  
  `tools/ui_kit_ink.py`
- **a8ac3ba** (2026-10-19) Bogazin adi: Drazvor Bogazi (dag kulturunun ses dili; 8.7)  
  `tools/worldmap/cm/geo_export.py`
- **4360a6e** (2026-10-19) Testlerin bulduğu hatalar: derleme hataları, köy takası karşılığı, ipucu fişi Esc, isim kuralı, eski testler  
  `scripts/ui/wording.gd`, `scripts/ui/road_caravan.gd`, `scripts/ui/road_journey.gd`, `scripts/events/event_catalog.gd`, `scripts/ui/first_time_hint.gd`
- **45bcf98** (2026-10-19) Canlı taverna (TavernRoom: oda render, anlık figürler, ateş, mum) ve pazar terazisi (MarketScale: mühür içinde mal ve sikke, yaylı eğim)  
  `scripts/ui/tavern_room.gd`, `scripts/ui/market_scale.gd`, `scripts/ui/tavern.gd`, `scripts/ui/market.gd`, `tools/ui_scenes/tavern_scene.py`
- **2b68b63** (2026-10-19) Aile borcu ölçümle yumuşatıldı: 180 altın, 120 gün, %4 faiz, -1 itibar  
  `scripts/economy/debt.gd`, `scripts/autoload/game_session.gd`
- **1cbff01** (2026-10-19) Aile borcu: metin, test ve denge notu  
  `docs/design_notes/denge_baba_borcu.md`
- **9d70aba** (2026-10-19) Kariyer ölçümü: eşiksiz ilan her itibarda açık (`MerchantOffer.is_open_to`), simülatör panoya göre yol seçer, kargo yerini ayırır, vagon onarır  
  `scripts/travel/merchant_offer.gd`, `scripts/ui/guild.gd`, `tests/simulate_career.gd`, `tests/test_city_commerce.gd`

## TODO klasörü düzeni (2026-10-19)

- Eski notlar kaldırıldı: `00_BASLA_BURADAN.md`, `IS_DAGILIMI.md`, `KALANLAR.md`, `YAPILACAKLAR.md`, `ONAY_PAKETI.md`, `TEST_PLANI.md`, `_arsiv/`, `devir/`. İçerikleri dört durum belgesine ve `referans/test_ve_onay_ekleri.md`'ye taşındı.
- Taşınanlar `referans/` altına: `gorevler/`, `gorevler.json`, `belgeler/`, `referanslar/`, `harita_final/`, `kontrol_goruntuleri/`, `taslaklar/`, `ICERIK_IHTIYACLARI.md`, `KONTROL_BELGESI.md`.
- Harita dışı değişiklik: `Harita_Calismasi/kod/cm/geo_export.py` ve `referans/harita_final/wayborne_harita.geojson` içinde boğaz adı Drazvor Boğazı (8.7).

## 2026-10-20 (gece)
- 4af6c2f: 9.6 karakter ekranı (üç sütun; figür önizlemesi render çözünürlüğünü aşmıyor, kırgınlık işaretleri açık mürekkep), 9.7 kadro kartı, Y-F01 kişi başına yorgunluk, 9.11 defterde Düşenler sayfası (rütbeli mezar işareti, hikâye satırları), 9.12 kilise mezarlığı, 12.2a kapı resmi, 12.2e yol göğü, balon genişliği.
- c8f0a21: tavernada gerçek oturuş (sit_box tüm beden ve giysilere eklendi), masa 0.75 / bank 0.46 m ile oda yeniden render; bardak masada; kadro kartı başlığındaki çetele kaldırıldı; evre resimlerinde akşam göğü mor değil, güneş yumuşak.
- fb3d2de: Y-B08 günün satırı (DiaryPanel).
- Taslak: Y-G16 menü kampı sit_box ile yeniden (TODO/referans/taslaklar/y_g16_menu_kamp.png).

## 2026-10-20 (sabah)
- 0020cca: kullanıcı kararı - UI kitinden köşebentler çıkarıldı (9.1); gravür efekti taslağı silindi, Y-G06 beklemede.
- 0b7eeeb, e94e924: 81 evre resmi (sabah/gündüz/akşam) ve tabanlar; mor ve doygun lacivert gökler arduvaza
  (town_post.tame_palette), sabah ılık ve puslu, güneş diski yumuşak.
- 998acda: yol balonu kâğıt etiketiyle (hale yazıyı lekeliyordu).
- 461be41: N31c ses otobüsleri, dört sürgü, Kenney CC0 arayüz sesleri (indirildi, KUNYE.tsv), Ayarlar tek sütun.
- dee753b: N34 söylenti satılmıyor (sohbetle), 4.4 açık anahtarlar, N31a beat kaydı ve rapor, N31e toz ve çamur,
  N31f ortam tablosu ve savaşta müzik kısma, N23 eski Tab paneli kalktı, Y-H03 etki satırları sözle.
- f935975: Codex dışa aktarımı ve PDF (110 sayfa), kapak sayıları veriden.
- 8f7b27a: N31d yol tepkileri (klipler tanımlı, render kuyrukta).
- bd9e560: 5.2 mipmap'ler içe aktarmadan.
- ef09582: planlayıcının moral dökümü sözle (Y-H03).
- e94e924, 1484e6f: şehir resimleri ve 27 kapı (gece/gündüz) yeni renk süzgeciyle; kapı resmi testi.
- d1057cf: N31d klipleri bütün setlerde; yorgun bekleyiş açık, bakış tepkisi kapalı (poz 3B'de başın üstünde).
- 2f814b7: 2.5 açlık kenar lekesi, 3.4/3.6 kullanılmayan eşya paketleri ve ölü belgeler silindi.
- 3671325, 3ba692f: Y-G02 mürekkep - eşya ve yol şeritlerine hafif geçiş (light_pass), figürlere oyunda birleşik siluet konturu (iç dikiş yok).
- 8a8f49f: Y-H03 kalanı (brifing yol satırı sözle), N31e kışın kar savruğu.
- c22fca5: 5.4 atlas sıkı paketleme (repack_atlas.py; 1139->295 sayfa, 473->182 Mpx; sayfa adı içerik özetli).
- a217f81: Y-K03 ölçüm - simulate_career OLCUM satırı, tools/measure_report.py, olcum.yml, docs/olcum/OLCUM_2026-10-20.md; oyuncu ölçümü Ayarlar izniyle (varsayılan kapalı).
- a756252, 68b9606: Y-K01 kayıt betiği tests/record_loop.gd; video depo dışında xx/video/dongu_2026-10-20.avi (4:30, 800 MB). README güncellendi.
- af53ca7: KULLANICI KARARI - çivili ilk kez ipucu fişleri (FirstTimeHint) metinleriyle kaldırıldı; öğretici notları kullanıcı yazacak.
- e413dd8: 8.9 harita hattı baştan sona koşturuldu (tools/worldmap/run_all.sh, çıktı Harita_Calismasi/rerun_1020), farklar README'de.
- 065b6a5: Y-G12 yakın plan HD idle kümeleri (276 küme).
- 72b1cf9: N31d look_ahead yeniden render; poz hâlâ yanlış, LOOK_ENABLED kapalı.
- 68b9606: 6.1 .gitattributes LFS kuralları (geçmiş yeniden yazılmadı; yeni dalda `git lfs install && git add --renormalize .`).
- 46dd8c1: KULLANICI KARARI - çivili kâğıt fiş (G8) ipucu baloncuğundan ve pazar fişinden kalktı; düz panel, g8_slip.png sevk edilmiyor.
- ddc6f89: 6.1 geniş LFS kuralları geri alındı (geçmiş düz blob; CI LFS kotası). Yalnız harita karoları LFS.
- Son commit: TODO klasörü `proje_takibi/` olarak depoya alındı (yasak kelimeler temizlendi), `CLAUDE_BASLANGIC.md`, `CLAUDE.md` yönlendirmesi, teslim notu güncel.
- Dal kararı (2026-10-20): GitHub dalı `Wayborne`; main ve dev kalacak, diğer dalların silinmesi ve sonraki kontroller yeni Claude'a bırakıldı (CLAUDE_BASLANGIC.md).
