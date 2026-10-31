# Wayborne - Godot 4 Project Guide

> **New here? Read `CLAUDE_BASLANGIC.md` first:** what this branch is, where the TODO registry (`proje_takibi/`)
> and the change log live, the user's working rules, and the resume point.

## Vaat ve Sütunlar

> **Durum: öneri, kullanıcı onayı bekliyor (görev Y-A01, Y-A02).** Cümleler yapılacaklar listesindeki kullanıcı notlarından
> alındı; onaylanınca bu kutu kalkar.

**Vaat.** Bir kervanı kuşaklar boyu yolda tut. Her karar yola bir iz, her ölüm deftere bir satır olur.

Her yeni özellik bu cümleye karşı sınanır: yola ya da deftere bir iz bırakmıyorsa gerekçesi sorulur.

**Dört sütun.** Yol yaşar · İnsanlar aşınır · Defter unutmaz · Ticaret bilgi oyunudur.

- Her yeni sistem ya da görev, hizmet ettiği sütunu (en az birini) adıyla belirtir.
- Sütunların üstünde kullanıcının ilkesi durur: **derinleşme, asla sadeleştirme.** Bir sistemi sadeleştirerek çözmek
  önerilmez; ölçülmüş ve korunan sistemler (beş kapasite yolu, merkez, kıyafet statları, haydut büyücü, beden statları)
  kesilmez.

## Çalışma düzeni: az token, aynı kalite (kullanıcı kararı, 2026-10-30)

Amaç: kaliteden ödün vermeden daha az okumak ve daha az yazmak. Kısalık açıklığın önüne geçmez; şüphede açık yaz.

**Az oku.**
- Önce ara, sonra oku: `Grep`/`Glob` ile yeri bul, dosyayı satır aralığıyla (`offset`/`limit`) oku. Büyük dosyayı
  (`game_session.gd`, `road_journey.gd`, kural becerileri) baştan sona okuma.
- Birden çok dizine, ada ya da kalıba yayılan geniş aramalar alt ajana (Explore) verilir; yalnızca sonucu döner.
  Kullanıcı bunu çalışma düzeni olarak onayladı.
- `proje_takibi/` altındaki üretilmiş belgeler (`KALAN_ISLER.md`, `YAPILAN_ISLER.md`, `TEST_BEKLEYEN.md`,
  `YARIM_VE_ONAY_BEKLEYEN.md`, `TEST_TURU.md`) bağlama alınmaz. Görev değişikliği `referans/gorevler.json` ve
  `referans/gorevler/*.md` üzerinden yapılır, belgeler `referans/belge_uret.py` ile yeniden üretilir; bir görevi
  aramak için `grep -n "<görev no>"` yeter.
- Testler `tools/test_ozet.sh` ile koşar: tam çıktı dosyaya, ekrana yalnızca kalanlar ve özet satırı. Uzun komut
  çıktısı (render, içe aktarma, simülatör) bir günlük dosyasına yazılır, sonra `grep`/`tail` ile bakılır.
- Düzenlenen dosya doğrulamak için yeniden okunmaz; ekran görüntüsü yalnızca değişen ekran için çekilir.

**Az yaz.**
- Ara mesajlar tek cümle: ne yapıyorum. Süreci anlatma, sonucu söyle.
- Sonuç raporu: ne değişti, ne doğrulandı, ne açık kaldı, senden ne gerekiyor. Aynı bilgiyi iki kez yazma; tablo
  yalnızca karşılaştırma varsa.
- Bilinen bir kararı yeniden tartışma, uygulamayacağın seçenekleri sayma.

**Asla kısaltılmayanlar.** Kod, dosya yolları, komutlar, hata mesajları, sayılar ve ölçümler; kullanıcıya sorulan
sorular ve onay listeleri; oyun içi metinler, lore ve tarihçe; bu dosyadaki kuralların "neden"i. Bu dosya ve lore
belgeleri hiçbir araçla otomatik sıkıştırılmaz.

## Kural becerileri (bu dosyanın bölünmüş hâli, kullanıcı kararı 2026-10-30)

Bu dosya her oturumda baştan sona yükleniyordu (~370 KB). Sistem kuralları metni değişmeden proje becerilerine
taşındı (`.claude/skills/kurallar-*/SKILL.md`); burada yalnızca her oturumda geçerli olanlar kaldı.

**Kural: bir sisteme dokunmadan, onu tasarlamadan ya da hakkında karar vermeden önce o sistemin kural becerisini
yükle** (Skill aracı ya da dosyayı oku). Bir iş birden çok sisteme değiyorsa hepsini yükle. Koddaki "bkz. CLAUDE.md
<başlık> Rules" başvuruları başlığı taşıyan beceriye bakar; başlıklar aynen korundu.

| beceri | bölümler | ne zaman |
|---|---|---|
| `kurallar-olay` | scripts/events, Event Engine Rules, Event Character Rules | olay kartı, etki, zincir, olay motoru |
| `kurallar-karakter` | scripts/character, Character & Party, Lineage, Stress, Progression | kişi, parti, kültür, sınıf, huy, ekipman, işe alma, ölüm ve varis, defter, stres, yorgunluk, seviye |
| `kurallar-savas` | scripts/combat, Combat Rules, Ruin Rules | savaş motoru, beceri, düşman, durum etkisi, kazanma oranı dengesi |
| `kurallar-yol` | Road Layer, Route Terrain & Weather, Temperature, Route, En-Route Plan, Road Movement, Journey Time, Road Encounter, Road Screen Layout, Encounter Timing | yol ekranı, yolculuk, kamp, tempo, hava, arazi, sapma, karşılaşma |
| `kurallar-sanat` | Audio, Art, Rendered Road, Prop | çizim, palet, sahne, render edilmiş yol ve eşya, ses |
| `kurallar-figur` | Wardrobe & Rig | insan ve hayvan figürü, giysi, iskelet, render hattı, yürüyüş |
| `kurallar-arayuz` | Title Screen, Waybook UI, Motion, scripts/world, World Navigation, Save & Menu, Localization | ekran, tema, hareket, gezinme, kayıt, çeviri |
| `kurallar-ekonomi` | City Hub, Caravan Ruin, Provision, Morale, Economy, Kervan Envanteri, Haggling, Reputation, Playthrough Start | pazar, şehir, borç, vagon, erzak, moral, itibar, başlangıç |
| `kurallar-test` | Testing (ayrıntı) | test, simülatör, ekran görüntüsü aracı, ölçüm |
| `ekran-dogrula` | (iş akışı) | oyuncunun gördüğü bir şey değiştiğinde "bitti" demeden önce |
| `gorev` | (iş akışı) | `proje_takibi/` görev kaydına iş eklemek, durum değiştirmek |
| `olay-karti` | (iş akışı) | yeni olay kartı yazmak ya da eskisini düzeltmek |
| `denge-olcum` | (iş akışı) | bir sayıyı değiştirmek ya da denge raporu almak |
| `wayborne-lore`, `wayborne-metin` | lore ve metin | lore, tarihçe, oyun içi metin |

Bölmenin kendisi sıkıştırma değildir: hiçbir kural kısaltılmadı. Yeni bir kural ait olduğu becerinin ilgili başlığına
yazılır; bu dosyaya yalnızca her oturumda geçerli olan girer.

## Stack

- **Engine**: Godot 4.2+
- **Language**: GDScript
- **Target**: PC (Windows). Web derlemesi yalnızca test ve CI içindir; Web performansı bir ölçüt değildir.

## Folder Structure

```
wayborne/
├── project.godot           # Godot project configuration
├── CLAUDE.md              # This file
├── scenes/                # Game scenes (*.tscn files)
├── scripts/
│   ├── campaign/          # Ledger, lineage archive, start origins (no scenario system)
│   ├── economy/           # Economy & trade system scripts
│   ├── travel/            # Map, routes & caravan logistics scripts
│   ├── events/            # Event & dialogue system scripts
│   ├── character/         # Cultures, stats, classes & recruits
│   ├── combat/            # Combat & AI scripts
│   ├── world/             # Explorable 2D spaces & scene navigation
│   ├── ui/                # UI components & screens
│   ├── util/              # Shared helpers (NodeUtil, TextureLoader)
│   └── autoload/          # Global singleton scripts
├── data/
│   ├── config/            # JSON/YAML configuration files
│   ├── locale/            # Translation CSV (keys, tr, en)
│   └── assets/            # Game assets (sprites, sounds, fonts)
└── tests/                 # Headless GDScript tests + balance simulator
```

### Folder Descriptions

- **scenes/**: Store all `.tscn` files here, organized by functionality
  - Use descriptive names: `main_menu.tscn`, `gameplay_hud.tscn`
  - Keep subscenes in subfolders for complex scenes

- **scripts/economy/**: Game economy logic
  - Trading systems
  - Currency management
  - Resource calculations

- **scripts/travel/**: Map & caravan logistics
  - Locations, routes and world map data
  - Caravan composition (wagon limits, documents, provisions)
  - Travel context shared between map and planner screens
  - `JourneyController`: the non-visual half of a journey (distance covered,
    calendar day, pace, camp, pending encounter, clock, event engine) -
    `road_journey.gd` keeps only presentation and input, reaching the state
    through property aliases. It is what makes the mid-journey autosave and
    headless tests of the walk/arrival rules possible.

- **scripts/ui/**: User interface scripts
  - Menu controllers
  - HUD management
  - Popup dialogs

- **scripts/autoload/**: Global singleton scripts (configured in project settings)
  - `GameState` (registered autoload): holds the persistent `GameSession`
  - `GameSession` (plain RefCounted): wallet, inventory, caravan, flags,
    reputation, journey — instantiable in tests without touching the autoload
  - There is deliberately **no signal bus.** `EventBus` was an autoload with
    four signals, five `emit()` sites and **zero listeners** — nothing ever
    connected to it, in script or in any `.tscn`. It could not have had a
    durable listener either: navigation is `change_scene_to_file()`, so every
    screen that might subscribe is freed on the next scene change, and the
    only long-lived objects are the autoloads themselves. Screens read
    `GameState.get_session()` directly. Don't reintroduce a bus without a
    subscriber that actually outlives a scene.
  - `DevPanel` (registered autoload): F1 geliştirici menüsü. `test_selector.tscn`'i
    çalışma anında `load()` ile kurup bir CanvasLayer'a gizli ekler; F1 açıp
    kapatır. Bir hedefe geçerken gezinme yığınına *o anki* sahneyi iter, o
    yüzden hedefin geri tuşu paneli açtığın yere döner, panele değil.
  - `SaveManager` (registered autoload): `GameSession.to_save_dict()` /
    `load_from_dict()` içeriği bilir, burada yalnızca `user://save.json`
    G/Ç'si var. Yalnızca şehir varışında (`finish_journey()` sonrası)
    çağrılır - sefer/kervan alanları o an her zaman sıfırlanmış olduğu
    için hiç serileştirilmez. `GameSession`'ı `load()` ile kurup normal
    örnek metodu çağırır, hiçbir yerde `class_name` ile anmaz.
  - `AudioManager` (registered autoload): music crossfade, ambience and
    one-shot SFX - see Audio Rules and Title Screen Rules.

**Autoload rule:** never reference a `class_name` inside an autoload script —
not in a type annotation, not in a body. Autoloads are parsed before the global
script class cache is ready, so `var x: GameSession` or `GameSession.new()`
fails with *"Could not find type"* and the autoload silently never instantiates
(the build still reports success — check the CI import log for
`Failed to create an autoload`).

`preload()` does **not** fix this: it resolves at compile time, so the failure
just moves down into the preloaded script's own `class_name` references. Use
runtime `load("res://…")` inside a function and construct lazily on first
access. Leave signal parameters untyped (their types are documentation only in
GDScript) and note the intended type in a comment.

**The `:=` / Variant trap.** Not just `load()` - any expression the static
checker can't type (a `for` loop over a plain `Array` returned by
`Array.duplicate()`, a value from `Dictionary.get()`, anything untyped)
makes `:=` fail to parse with `Cannot infer the type of "x" variable`. This
has broken a shipped-green build repeatedly (`city_map.gd`, `run_tests.gd`,
`simulate_journeys.gd`, `resolve_stress_breaks()`) because Godot's own
parser still prints `SCRIPT ERROR` and exits 0 - only the CI log grep
catches it. Fix by giving the *source* value an explicit type before the
loop/assignment (`var typed: Array[CharacterData] = untyped_result`), not by
chasing every downstream `:=` that happens to fail.

**Lambdas capture outer locals by value, not by reference.** A lambda
connected to a signal (`signal.connect(func(x): outer_flag = true)`)
reassigns its own private copy of `outer_flag`, not the enclosing
function's variable - reading `outer_flag` afterwards still sees the old
value. This silently made an early draft of `test_stress.gd`'s refusal test
pass/fail on a value that never actually changed. Capture a reference type
instead - a one-element `Array` used as a shared box (`var flag := [false]`,
mutate `flag[0]` inside the lambda) is the standard GDScript workaround.

- **data/config/**: Game configuration files
  - `game_config.json`: Game-wide settings
  - `enemy_data.json`: Enemy definitions
  - `quest_data.json`: Quest definitions

- **data/assets/**: Game assets
  - Sprite sheets
  - Audio files
  - Fonts
  - UI textures

## Coding Standards

### GDScript Style Guide

#### Naming Conventions
- **Classes**: `PascalCase` (e.g., `PlayerController`, `EnemySpawner`)
- **Functions**: `snake_case` (e.g., `take_damage()`, `calculate_loot()`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `MAX_HEALTH`, `SPAWN_RATE`)
- **Variables**: `snake_case` (e.g., `player_health`, `current_scene`)
- **Private members**: Prefix with `_` (e.g., `_internal_state`, `_update_visuals()`)

#### Class Structure
```gdscript
extends Node

# Constants at top
const DAMAGE_MULTIPLIER = 1.5
const MAX_ATTEMPTS = 3

# Properties/variables
var health: int = 100
var _is_alive: bool = true
var _animation_speed: float = 1.0

# Exported variables for editor
@export var base_damage: float = 10.0
@export var attack_range: float = 50.0

# Signals
signal health_changed(new_health)
signal died

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

# Public methods
func take_damage(amount: int) -> void:
	pass

# Private methods (leading underscore)
func _update_visuals() -> void:
	pass
```

#### Type Hints
- Always use type hints for clarity
- ✅ `func calculate_damage(base: float) -> float:`
- ❌ `func calculate_damage(base):`

#### Comments
- Only comment the "why", not the "what"
- Self-documenting code is preferred
- Avoid redundant comments

```gdscript
# ✅ Good - explains intent
func apply_knockback(direction: Vector2) -> void:
	# Knockback scales with impact force to feel more dynamic
	velocity = direction * impact_force * 2.0

# ❌ Avoid - restates code
func apply_knockback(direction: Vector2) -> void:
	# Set velocity to direction times impact force times 2
	velocity = direction * impact_force * 2.0
```

### Project Best Practices

#### Scene Management
- Keep scenes focused and modular
- Use inheritance for shared behavior
- Prefer composition over deep hierarchies

#### Script Organization
- One public class per file (match filename to class name)
- Keep functions < 30 lines
- Extract complex logic into helper functions

#### Signal Usage
- Define signals at script top after constants
- Use descriptive signal names: `health_changed`, `item_picked_up`
- Emit signals for state changes only

#### Resource Loading
- Use `preload()` for scenes/resources known at edit time
- Use `load()` for dynamic runtime loading
- Cache loaded resources when reused

```gdscript
# ✅ Preload at top
var enemy_scene = preload("res://scenes/enemy.tscn")

# ❌ Load every time
var enemy_scene = load("res://scenes/enemy.tscn")
```

#### Error Handling
- Check for null returns: `assert(resource != null, "Missing resource")`
- Validate input parameters
- Log meaningful error messages

```gdscript
func load_enemy_data(enemy_id: int) -> Dictionary:
	var data = _load_json("res://data/enemies.json")
	assert(data != null, "Failed to load enemy data")
	assert(enemy_id in data, "Unknown enemy: %d" % enemy_id)
	return data[enemy_id]
```

### Performance Tips

1. **Avoid dynamic typing** - Use type hints for better performance
2. **Cache references** - Store frequently accessed nodes/resources
3. **Use object pooling** - Reuse bullets, enemies, effects instead of creating/destroying
4. **Optimize physics** - Use AABB checks before expensive collision tests
5. **Profile before optimizing** - Use Godot's profiler to identify bottlenecks

### Testing

Ayrıntı, geçmiş ölçüm hataları ve araç listesi `kurallar-test` becerisinde. Her oturumda geçerli olanlar:

- Testler `tools/test_ozet.sh` ile koşar (tam çıktı dosyaya). Elle: `godot --headless --script res://tests/run_tests.gd`.
- `tests/` altında `class_name` yok; bir paket `suite_name()` ve `run(t)` taşır, `run_tests.gd`'nin `SUITE_PATHS`'ine
  eklenir. Her RNG tohumlanır; aynı tohumdan iki bağımsız şey türetilmez.
- Sömürü olan yerde formülü değil sömürünün kapandığını doğrula. Bir rapor şaşırtıcıysa önce ölçüm aracından şüphelen.
- **Bir iş ekranda görününce biter (Y-K01).** Oyuncunun gördüğü her değişiklik gerçek ekranın görüntüsüyle
  doğrulanır (`ekran-dogrula` becerisi); yapısal testler görünüşü görmez.
- **CI asıl kapıdır.** Godot ayrıştırma hatasında bile 0 ile çıkar; `tests.yml` günlükte `SCRIPT ERROR`, `Parse
  Error`, `Compile Error`, `Failed to load script`, `Failed to create an autoload` arar. Bu adımı derleme geçsin diye
  asla kaldırma.

## CI/CD

**There is no web build any more (user's decision, 2026-10-21).** The game is played locally on PC from a clone; the Web
export, the GitHub Pages deploy, `export_presets.cfg` and `web/coi-serviceworker.js` were removed. The browser tab
could not hold the game (about 1.2 GB of imported textures against the tab's memory limit, `SBOX_FATAL_MEMORY_EXCEEDED`).
`.github/workflows/tests.yml` runs on every push (`Wayborne` included) and every PR: import, the full suite and the
script-error gate described above. Never remove that gate to make a build pass.

### Local Testing

Open `project.godot` in Godot 4.2.2 and press Play (import twice after pulling atlas changes:
`godot --headless --import`, run it again). Run the tests with
`godot --headless --script res://tests/run_tests.gd`.

## Development Status

### Ana Hedefler

Oyunun aktif, henüz kapanmamış hedeflerinin tek listesi - **bundan sonra
yeni bir açık iş burada birikir, Development Status'un tarih akışı içine
dağılmış ayrı notlar olarak değil.** Bir madde kapandığında buradan
silinir; tarihçesi (nasıl karara bağlandığı, ölçümü) aşağıdaki Faz
anlatısında kalır - bu liste yalnızca "şu an açık olan ne" sorusuna cevap
verir.

- **Waybook'un kalan sanat borcu - Faz 22'de büyük ölçüde kapandı.**
  İkinci sanat turu (bkz. aşağıdaki Faz 22 anlatısı) yönetim ekranı
  arka planlarını, mal/durum/stat/görev/sınıf ikonlarını, haritayı ve
  mührü çok daha yüksek çözünürlükte yeniden gönderdi ve hepsi
  `data/assets/ui/waybook`'a işlendi. Beş sorunlu ikon 2026-10-22'de kapandı:
  `tools/icon_discs.py` çıplak ya da bozuk gelen stat/görev ikonlarını (çeviklik, dayanıklılık, zekâ, sezgi, tellal)
  ailenin parşömen diskine oturtuyor ve `eq_ring_charmed`'ın boncuğunu maviye çeviriyor; gözcü portresi, terazi ve
  kırık mühür kalıyor. Açık kalan yalnızca wardrobe'un kıyafet parça sayfaları (B kategorisi, artık istenmiyor,
  giysiler 3B render). Tam liste ve
  her satırın durumu `docs/wayborne_gorsel_denetim.xlsx`'te.
- **Gerçek seslendirme + savaş nidaları** (#7, #11). `AudioManager`'ın
  bugünkü sentezlenmiş placeholder'larının yerini gerçek kayıt alacak;
  Faz 13 PR-D'nin kısa metin yorumları (`unit_barked`) bunun metin
  karşılığı olarak zaten kurulu.
- **Codex'in olay bölümünde tasarım notları eksik.** Karar ağaçları kataloğun 71 olayının hepsini kapsıyor (Y-E07,
  2026-10-22'de yeniden üretildi); elle yazılmış tasarım notu yalnızca 29 kartta. Kalan kartların notu lore kapanınca
  yazılır.
- **Evrenin lore'u ve tarihi tamamlanıyor.** `docs/lore/LORE.md` (evren) ve
  `docs/lore/TARIHCE.md` (zaman çizelgesi) oyunda bugün var olan her bilgiyi
  [Kanon]/[İma]/[Boş] diye işaretliyor; harita ve mekanikler bu iki belgenin
  [Boş] satırları dolunca somut zemine oturacak (dünyanın adı, beylikler,
  kültürlerin yurtları, deniz/liman, lonca ve kilisenin kökeni).
- **Bütün görseller el çizimi (kullanıcı hedefi, 2026-10-22; program 2026-10-27).** Kullanıcı oyunun bütün görsellerini
  tablette (ibis Paint X) kendisi çiziyor; amaç AI beyanından olabildiğince kurtulmak. Tek liste
  `tools/el_cizimi/envanter.py` (676 satır, eski ve kullanılmayan dosyalar hariç); şablonlar `sablon_uret.py` (hizalı
  referans, katman haritası, adlı katmanlı PSD; zipler depoda değil), takip `docs/el_cizimi/el_cizimi_takip.xlsx`
  (`takip_excel.py`, çizerin girdileri korunur), teslim `art_source/el_cizimi/gelen/` -> `al.py` (doğrular, oyuna işler,
  durumu "Oyunda" yapar; ardından ekran görüntüsü). Süreç: `docs/el_cizimi/SUREC.md`. Figürler tek rölanti çizimi,
  oyun kemiklerle büker: pilot `docs/el_cizimi/pilot/PILOT.md` (14 pozda çalışıyor; etek/cüppe tek parça `etek`
  katmanı). Açık: `HumanSkin` (GDScript) ilk gerçek beden çizimiyle kurulacak; ince/iri beden türetme denenmedi.
  Öncelik 1 (181 AI görsel) bitince `AI_DISCLOSURE.md` yeniden yazılır.
- **Kamp ateşi başında oturma postürü (kullanıcı isteği, 2026-10-23).** Bugün kamp kurulunca herkes ateşin iki yanında
  ayakta duruyor (`RoadCaravan.CAMPFIRE_SEATS`). İstenen: ateşin etrafında oturan, ısınan kervan. Yapılacaklar:
  `FigureActions`'a oturma klipleri (`sit_fire`: bağdaş/kütükte oturuş, eller ateşe; birkaç varyant), MPFB hattında
  altı beden ve bütün giysiler için render (`render_frames.py`/`render_outfits.py --clips`), varınca yürüyüşten
  oturuşa geçiş (dismount/climb_down gibi kalçadan köklü), koltuk düzeni oturan figüre göre yeniden (yükseklik farkı),
  ateşin önünde/arkasında oturma için çizim sırası, kalkışta tersine oynatma; vitrin kamp karesi yeniden çekilir.
- **Kıtlık: oyunun ağırlık merkezi ticaretten ulaştırmaya kayıyor (kullanıcı, 2026-10-29; görev Y-C21).** Kıtanın
  tamamını etkileyen bir olay (büyülü ve devasa ya da mevsimlerin değişmesi; sebebi lore kararı) bir kıtlık başlatır
  ve bütün savaşlar temelde ondan doğar. Ticaret kalır ama kıt ve pahalı olur (sistem kesilmez, derinleşir); oyunun
  odağı kervanı bir noktadan öbürüne sağ salim ulaştırmak. Her şehir arka planda bir moral/mental durum taşır; kervanın
  ulaştırdığı yük onu düzeltir; bu durum o şehirdeki olayları ve kervana yaklaşımı değiştirir. Hedef his: kıtlık ve
  yokluk her mekanikte ve ortamda hissedilir, hiçbir şey kolay değildir. Ayrıntı ve karar listesi
  `proje_takibi/referans/gorevler/13_yonetmen_onerileri.md` Y-C21; bölgesel itibarla (Y-C12) birlikte tasarlanır.
- **Kıtlığın üç tasarım dersi (kullanıcı, 2026-10-30; görevler Y-C22, Y-C23, Y-C24).** Tasarım notu
  `docs/design_notes/kitlik_tasarim_dersleri.md`.
  - *Ahlaki zorunluluk:* kıtlık kartlarında doğru seçenek yok, her seçenek bir şeyi feda eder ve bedel adı olan
    birine düşer; palet kıtlık derecesiyle solar ve kirlenir (dünyada; arayüz okunaklı kalır).
  - *Yenilmez çevre ve domino:* soğuk ve kıtlık yenilmez, dayanılır; var olan sistemlerin bedelleri birbirini
    tetikler ve kervan son eşyalarını yakmaya, yemeye itilir.
  - *Çözülemeyen problem:* büyüme ve servet kendiliğinden yeni kriz doğurur; bir krizi çözen hamle öbürünü
    besler; `simulate_career` sakin sefer dizilerini ölçer.
  - Sınır: güç ve ödül sistemleri kesilmez, bedelli olur (derinleşme, asla sadeleştirme); bir sistemin kalkmasına
    kullanıcı karar verir. "Doğru stoklayan aç kalmaz" sözü korunur.
- **Film ve kervan fikirleri (kullanıcı, 2026-10-31; görevler Y-G17..Y-G23, Y-C25..Y-C35, Y-B14..Y-B16,
  Y-E09..Y-E12, Y-H08, Y-A08).** Ayrıntı `proje_takibi/referans/gorevler/15_film_kervan_fikirleri.md`. Öne çıkanlar:
  tek sıcak kaynak kuralı (`kurallar-sanat`), veba bir dünya hâli (kart açılmadan görünür), yol kenarı kervansarayları,
  geçiş belgesi, portreler baştan yorgun. **Senaryo sistemi yok (2026-10-31):** beş
  bölümlü kampanya kaldırıldı; oyun kıtlık içinde kervanı ilerletmek ve ek görevlerle geçer, konforlu final yok (Y-A08).
- **Haritada adı olan her yer oynanabilir olmalı (kullanıcı, 2026-10-29).** Bugün 27 yerleşim oynanabilir; obalar,
  kabile yurtları, mezralar, manastırlar, kuleler ve harabeler yalnızca harita adı. Hepsi bir durak, olay ya da
  ziyaret edilebilir yer olarak oyuna girmeli. Lore'un bu yerler için verdiği bilgi (`docs/lore/LORE.md` §15) bu işin
  girdisi.
- **Eski kuşam listesi (B-01..B-20) artık boyanmayacak.** Giysi 2B boyama
  yolu (parça sayfası, sonra `wardrobe_cut.py`) yerini 3B render'a bıraktı;
  `docs/gemini-prompts-wardrobe.md` ve şablonları silindi; yeni kalemler
  CC0 3B paketlerden giydirilip render ediliyor.

**Kapanmış fazların anlatıları `docs/history/FAZ_ANLATILARI.md`'de.** Faz 0-27'nin kapanış notları, denge ölçümleri ve
çözülmüş-sorun kayıtları oraya, metin değişmeden taşındı; bu dosya yalnızca geçerli kuralları ve açık hedefleri tutar. Koddaki
"bkz. CLAUDE.md Faz N" başvuruları o belgeye bakar.

## Quick Start

1. Open `project.godot` in Godot 4.2+
2. Create your first scene in `scenes/main.tscn`
3. Create scripts in appropriate `scripts/` subfolders
4. Reference scenes/scripts using `res://` paths
5. Push to `Wayborne` (the only and default branch); `tests.yml` runs the suite

## Codex

`docs/Wayborne-Codex.pdf` is the game's design document — covering
every mechanic in prose, plus a one-page decision tree for each road event it documents (29 written by hand, the rest generated from the
catalog export since task Y-E07; rebuild the PDF after the export) (trigger, options, weighted outcomes, effects). It is
**generated**, not written: `docs/codex/` holds the reportlab source and
`python3 docs/codex/codex_main.py` rebuilds the PDF in place. This file
(CLAUDE.md) stays the rule book — what must never be broken and why; the
codex is the explanation, for a reader who has not read the code.

Its event chapter has two layers (task Y-E07). Hand-written pages with design notes live in
`docs/codex/codex_events_data.py`; every catalog event without one gets a generated decision tree from
`docs/codex/events_export.json`, which Godot itself writes (`godot --headless --script res://tests/export_codex_events.gd`),
so nothing parses GDScript from Python and the codex stays equal to the catalog. Re-run the export, then
`codex_main.py`, after changing events.

## Useful Links

- [Godot 4 Documentation](https://docs.godotengine.org/en/stable/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [HTML5 Export Guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
