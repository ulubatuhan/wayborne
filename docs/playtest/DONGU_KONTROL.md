# İki haftalık döngü: kontrol listesi (Y-K01)

Her döngü oynanabilir bir derleme ve beş dakikalık bir video ile biter. "Bitti" yalnızca gerçek ekranın görüntüsüyle
doğrulanınca denir (CLAUDE.md, Testing). Bu dosya her döngüde kopyalanır: `docs/playtest/dongu_YYYY-MM-DD.md`.

## 1. Derleme

- [ ] `godot --headless --import` iki kez (temiz klonda ilk koşu 1 ile biter).
- [ ] `godot --headless --script res://tests/run_tests.gd`: 0 kalan, betik hatası taraması temiz.
- [ ] `git diff project.godot` boş (içe aktarma `windows_native_title` satırını düşürebiliyor).
- [ ] Windows dışa aktarımı (PC hedefi) açılıyor; ana menü, yeni oyun, ilk şehir.
- [ ] Web derlemesi açılıyor (yalnızca test; performans ölçüt değil).

## 2. Ekran görüntüleri (döngünün kanıtı)

Araçlar `tests/screenshot_*.gd`. Bu döngüde değişen her ekran için en az bir görüntü:

- [ ] Ana menü (`screenshot_menu.gd`)
- [ ] Şehir ekranı, en az bir şehir, bir kasaba, bir kervansaray (`screenshot_settlements.gd`)
- [ ] Yol ekranı ve kontrol paneli (`screenshot_journey_screen.gd`)
- [ ] Harita ve açılır harita (`screenshot_screens.gd -- 1920 1080 world_map`, `screenshot_map_popup.gd`)
- [ ] Savaş (`screenshot_combat.gd`)
- [ ] Kamp sırası (`screenshot_camp.gd`)

## 3. Beş dakikalık video (çekim listesi)

| Süre | Sahne | Ne görünmeli |
|---|---|---|
| 0:00-0:30 | Ana menü, yeni oyun | Kültür ve başlangıç şehri |
| 0:30-1:30 | Şehir | Pazar alımı, lonca kontratı, planlayıcı |
| 1:30-3:00 | Yol | Kolonda yürüme, bir işaret, bir olay kartı, kontrol paneli sekmeleri, M ile harita |
| 3:00-4:00 | Kamp ve sofra | Ateşe yürüyüş, kim yesin kararı |
| 4:00-5:00 | Varış ya da savaş | Teslim ve itibar, ya da bir savaşın sonu |

## 4. Döngü notu

- Bu döngüde kapanan görevler (kimlik ve commit):
- Görüntüyle doğrulananlar:
- Doğrulanamayanlar ve nedeni:
- Oynarken sıkılınan anlar (Y-A06 günlüğüne de):
