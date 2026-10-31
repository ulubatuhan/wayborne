extends Node

## Autoload: oyunun sesi. Üç iş yapıyor - hangi ekranda hangi parçanın
## çaldığını bilmek, aradaki geçişi yumuşatmak, ve üstüne binen kısa
## efektlerle (kapı gıcırtısı, bir düğüm anının vurgusu) ortam sesini
## (rüzgar) çalmak.
##
## Bu dosyada bilerek hiçbir `class_name`'e başvurulmuyor: autoload'lar
## global script sınıf önbelleği hazır olmadan ayrıştırılıyor (bkz.
## CLAUDE.md Autoload rule). `AudioStreamPlayer` motorun kendi tipi,
## projenin bir sınıfı değil - o yüzden sorun değil.
##
## **Müzik için iki çalıcı var, çünkü geçiş kesme değil geçiştir.** Tek
## çalıcıyla parça değiştirmek sesi bıçak gibi kesiyor; şehre varış ile
## yolun bitişi arasındaki an oyunun en çok "vardık" demesi gereken anı ve
## bir kesme onu bozuyor. `_active` sönerken `_standby` açılıyor, sonra
## ikisi yer değiştiriyor. Ortam sesinin (bkz. `play_ambience`) kendi ayrı
## çalıcısı var - müzikle aynı anda solabilmeli (başlangıç ekranında rüzgar
## sönerken yol müziği yükseliyor), o yüzden müziğin iki çalıcısına
## karışamaz. Tek kerelik efektler (bkz. `play_sfx`) hiç kalıcı bir çalıcı
## paylaşmıyor - her çağrı kendi geçici `AudioStreamPlayer`'ını kurup
## bitince kendini siliyor, çünkü ikisi üst üste gelebilir.
##
## Parça dosyaları `data/assets/audio/` altında ve `preload` edilmiyor:
## autoload derlenirken çözülen bir yol, dosya adı değişince sessizce
## değil *gürültülü* patlasın diye çalışma anında `load()` ile alınıyor.
## Efekt dosyaları (rüzgar/tokmak/kapı) şimdilik basit birer yer tutucu -
## gerçek kayıt/foley gelene kadar saf koddan (`wave`/sinüs/gürültü)
## üretildi, tıpkı elle çizilmiş sanat gelene kadar `_draw()`'un yaptığı
## gibi (bkz. Art Rules). `AudioManager`'ın kendisi hangisini çaldığını
## bilmiyor - dosya değişince kod hiç değişmeden gerçek kayda geçer.

## Ekran -> parça. Ana menü ile yol aynı parçayı paylaşıyor: ikisi de
## "yoldasın" hissi, şehir ise varış. Üçüncü bir parça gelene kadar bu
## eşleme tek yerde durmalı, yoksa her ekran kendi dosya yolunu yazar
## (aynı gerekçe: ArtPalette'in tek renk kaynağı olması).
const TRACK_ROAD: String = "road"
const TRACK_CITY: String = "city"

## Müzik kullanılmıyor (kullanıcının kararı): parça yok, çalma çağrıları sessizce geçer.
const TRACK_PATHS: Dictionary = {}

## Geçiş süresi. Kısa olursa kesme gibi duyuluyor, uzun olursa iki parça
## birbirine karışıyor - ölçüldü, 1.4 saniye ikisinin arası.
const FADE_SECONDS: float = 1.4

## Sessizliğin dB karşılığı. `linear_to_db(0)` eksi sonsuz döndürüyor ve
## bir Tween onu sayı olarak taşıyamıyor, o yüzden sonlu bir taban.
const SILENT_DB: float = -60.0

## Tek kerelik sesler (bkz. `play_sfx`) - müzik değil, bir anın vurgusu.
## Ayrı bir kayıt: bir "thud" çalarken bir başkası üst üste tetiklenebilir
## (kapı sesiyle aynı anda bir düğme tıklaması), o yüzden `_active`/
## `_standby` gibi paylaşılan tek bir çalıcıya kilitlenmiyor - her çağrı
## kendi geçici `AudioStreamPlayer`'ını kurup bitince kendini siliyor.
const SFX_THUD: String = "thud"
const SFX_GATE: String = "gate"
## Kamp ateşinin tutuşması (görev 12.2c): ilk figür ateşe varınca.
const SFX_FIRE_IGNITE: String = "fire_ignite"
## Savaş vuruşları (görev Y-H05). Kayıtlar gelene kadar dosya yok; play_sfx
## eksik dosyada sessizce geçer (Audio Rules).
const SFX_HIT: String = "hit"
const SFX_CRIT: String = "hit_crit"
const SFX_KILL: String = "hit_kill"
const SFX_VARIANTS: int = 5
const SFX_PITCH_JITTER: float = 0.06
## Arayüz sesleri (görev N31c): Kenney UI Audio ve RPG Audio, CC0
## (data/assets/audio/KUNYE.tsv). Basma beş, sayfa üç, para iki çeşit.
const SFX_UI_PRESS: String = "ui_press"
const SFX_UI_PAGE: String = "ui_page"
const SFX_UI_COIN: String = "ui_coin"
const SFX_UI_BOOK_OPEN: String = "ui_book_open"
const SFX_UI_BOOK_CLOSE: String = "ui_book_close"
## Çeşit sayısı `SFX_VARIANTS`'tan farklı olan sesler.
## Sessizlik anının beden sesleri (Y-H08): adım, nefes, sürünme.
const SFX_BODY_STEP: String = "body_step"
const SFX_BODY_BREATH: String = "body_breath"
const SFX_BODY_CRAWL: String = "body_crawl"
const SFX_VARIANT_COUNTS: Dictionary = {
	SFX_UI_PRESS: 5, SFX_UI_PAGE: 3, SFX_UI_COIN: 2,
	SFX_BODY_STEP: 3, SFX_BODY_BREATH: 2, SFX_BODY_CRAWL: 2,
}

## Ses otobüsleri (görev N31c): her katmanın kendi sürgüsü. Otobüsler kodda
## kuruluyor, bir .tres düzeninde değil - Audio Rules: içe aktarma ve
## düzen dosyalarına bağlanan ayar temiz bir klonda kaybolur.
const BUS_MUSIC: String = "Music"
const BUS_AMBIENCE: String = "Ambience"
const BUS_SFX: String = "Sfx"
const BUS_UI: String = "Ui"
const BUSES: Array[String] = [BUS_MUSIC, BUS_AMBIENCE, BUS_SFX, BUS_UI]
const SFX_PATHS: Dictionary = {
	SFX_THUD: "res://data/assets/audio/wooden_thud.wav",
	SFX_GATE: "res://data/assets/audio/gate_creak.wav",
	SFX_FIRE_IGNITE: "res://data/assets/audio/fire_ignite.wav",
	# Kenney Impact Sounds (CC0): beşer çeşit, rastgele biri, perde oynar.
	SFX_HIT: "res://data/assets/audio/combat/hit_%d.ogg",
	SFX_CRIT: "res://data/assets/audio/combat/hit_crit_%d.ogg",
	SFX_KILL: "res://data/assets/audio/combat/hit_kill_%d.ogg",
	SFX_UI_PRESS: "res://data/assets/audio/ui/press_%d.ogg",
	SFX_UI_PAGE: "res://data/assets/audio/ui/page_%d.ogg",
	SFX_UI_COIN: "res://data/assets/audio/ui/coin_%d.ogg",
	SFX_UI_BOOK_OPEN: "res://data/assets/audio/ui/book_open.ogg",
	SFX_UI_BOOK_CLOSE: "res://data/assets/audio/ui/book_close.ogg",
	SFX_BODY_STEP: "res://data/assets/audio/body/step_%d.wav",
	SFX_BODY_BREATH: "res://data/assets/audio/body/breath_%d.wav",
	SFX_BODY_CRAWL: "res://data/assets/audio/body/crawl_%d.wav",
}

## Sessizlik anı (Y-H08, kullanıcı notu: "tamamen sessizlik ve adım, sürünme,
## nefes gibi seslerin ... sadece onların duyulması daha etkili"). Müzik ve
## ortam sesi söner, `HUSH_SECONDS` boyunca yalnızca beden sesleri çalar, sonra
## ikisi geri gelir. Bir feda kararından ve bir ölümden sonra çalar.
const HUSH_SECONDS: float = 9.0
const HUSH_FADE_SECONDS: float = 0.6
const HUSH_BEAT_SECONDS: float = 0.9
var _hushing: bool = false

## Saf: sessizlikte hangi beden sesi hangi sırayla (test bunu okur). Adımlar
## arasına her dördüncü vuruşta bir nefes; sürünmeyle başlayabilir (yerde biri).
static func hush_sequence(seconds: float, crawl: bool) -> Array[String]:
	var beats: Array[String] = []
	var count := int(floor(seconds / HUSH_BEAT_SECONDS))
	for index in count:
		if index == 0 and crawl:
			beats.append(SFX_BODY_CRAWL)
		elif index % 4 == 3:
			beats.append(SFX_BODY_BREATH)
		else:
			beats.append(SFX_BODY_STEP)
	return beats

func hush(crawl: bool = false) -> void:
	if _hushing:
		return
	_hushing = true
	var music_db := _active.volume_db
	var ambience_db := _ambience_player.volume_db
	var down := create_tween().set_parallel(true)
	down.tween_property(_active, "volume_db", SILENT_DB, HUSH_FADE_SECONDS)
	down.tween_property(_ambience_player, "volume_db", SILENT_DB, HUSH_FADE_SECONDS)
	for sfx_id in hush_sequence(HUSH_SECONDS, crawl):
		await get_tree().create_timer(HUSH_BEAT_SECONDS).timeout
		play_sfx(sfx_id)
	var up := create_tween().set_parallel(true)
	up.tween_property(_active, "volume_db", music_db, HUSH_FADE_SECONDS * 2.0)
	up.tween_property(_ambience_player, "volume_db", ambience_db, HUSH_FADE_SECONDS * 2.0)
	_hushing = false

## Ortam sesi (bkz. `play_ambience`) - müziğin *altında* değil, müziğin
## **yerine** duran bir katman: başlangıç ekranında henüz müzik yok, yalnızca
## rüzgar var. Kendi çalıcısı ve kendi solması var, müzikten bağımsız -
## ikisi aynı anda solabilmeli (rüzgar sönerken yol müziği yükseliyor).
const AMBIENCE_WIND: String = "wind"
## Kamp ateşinin çıtırtısı, kamp boyunca (görev 12.2c).
const AMBIENCE_FIRE: String = "fire"
const AMBIENCE_PATHS: Dictionary = {
	AMBIENCE_WIND: "res://data/assets/audio/wind_ambience.wav",
	AMBIENCE_FIRE: "res://data/assets/audio/fire_crackle.wav",
}
const AMBIENCE_FADE_SECONDS: float = 1.6

## Yolun ortam sesi tablosu (görev N31f): hava × saat × yer. Kampta ateş;
## yolda rüzgâr kapalı ve sert havada, gece açık havada da (ıssızlık).
## Anahtarlar RouteWeather'ın kimlikleri (Autoload rule: sınıf anılmıyor).
## Yağmur, orman ve şehir uğultusu kayıtları gelince tablo genişler (Y-I01).
const ROAD_AMBIENCE: Dictionary = {
	"storm": AMBIENCE_WIND, "rain": AMBIENCE_WIND, "overcast": AMBIENCE_WIND,
}
## Savaşta müzik bu kadar kısılır (dB): vuruşlar ve çığlıklar öne çıksın.
const COMBAT_DUCK_DB: float = -12.0
const DUCK_SECONDS: float = 0.8
var _ducked: bool = false

## Saf: hangi ortam katmanı çalmalı ("" = sessiz).
static func road_ambience_for(weather: String, night: bool, camping: bool) -> String:
	if camping:
		return AMBIENCE_FIRE
	if ROAD_AMBIENCE.has(weather):
		return String(ROAD_AMBIENCE[weather])
	return AMBIENCE_WIND if night else ""

## Yol ekranının çağırdığı kapı: tablo "" diyorsa katman söner.
func set_road_ambience(weather: String, night: bool, camping: bool) -> void:
	var id := road_ambience_for(weather, night, camping)
	if id.is_empty():
		stop_ambience()
	else:
		play_ambience(id)

## Savaşta müzik kısılır, bitince geri gelir. Otobüsün düzeyine dokunmaz
## (oyuncunun sürgüsü), çalıcının kendi düzeyiyle oynar.
func set_combat_duck(on: bool) -> void:
	if on == _ducked:
		return
	_ducked = on
	if _fade != null and _fade.is_running():
		return
	var tween := create_tween()
	tween.tween_property(_active, "volume_db", COMBAT_DUCK_DB if on else _target_db(), DUCK_SECONDS)

var _active: AudioStreamPlayer
var _standby: AudioStreamPlayer
var _current_track: String = ""
var _ambience_player: AudioStreamPlayer
var _ambience_fade: Tween
var _current_ambience: String = ""
## -1 = henüz okunmadı. Varsayılan değerin **tek** sahibi
## `UserSettings.DEFAULT_MUSIC_VOLUME`; burada ikinci bir sayı tutmak,
## ikisi ayrıştığı gün sessizce yanlış sesle açılmak demekti. Tembel
## okuma aynı zamanda autoload sırasına olan bağımlılığı da siliyor.
var _music_volume: float = -1.0
var _fade: Tween
## Her çeşitli ses için son çalınan çeşit: aynısı arka arkaya gelmesin.
var _last_variant: Dictionary = {}

func _ready() -> void:
	# Oyun duraklatılsa bile müzik sürsün: duraklamada kesilen müzik
	# oyunun çöktüğü izlenimi veriyor.
	process_mode = Node.PROCESS_MODE_ALWAYS

	ensure_buses()
	_active = _make_player(BUS_MUSIC)
	_standby = _make_player(BUS_MUSIC)
	_ambience_player = _make_player(BUS_AMBIENCE)
	for bus in BUSES:
		_apply_bus_volume(bus, get_bus_volume(bus))

func _make_player(bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = SILENT_DB
	player.bus = bus
	add_child(player)
	return player

## Dört otobüs, hepsi Master'a akar. Var olanı yeniden kurmaz.
static func ensure_buses() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, "Master")

## 0.0 - 1.0, otobüs başına. Müzik eski anahtarını korur (eski ayarlar
## dosyası sessizce sıfırlanmasın).
func get_bus_volume(bus: String) -> float:
	if bus == BUS_MUSIC:
		return get_music_volume()
	return UserSettings.load_volume(bus)

func set_bus_volume(bus: String, volume: float) -> void:
	if bus == BUS_MUSIC:
		set_music_volume(volume)
		return
	UserSettings.save_volume(bus, volume)
	_apply_bus_volume(bus, volume)

func _apply_bus_volume(bus: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var v := clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_mute(index, v <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(v) if v > 0.0 else SILENT_DB)

## Bir sesin hangi çeşidi: aynı çeşit arka arkaya gelmez (iki çeşit varsa
## sırayla). Saf fonksiyon, test edilebilsin diye `last` dışarıdan.
static func pick_variant(count: int, last: int, roll: int) -> int:
	if count <= 1:
		return 0
	var pick := posmod(roll, count - 1)
	return pick + 1 if pick >= last and last >= 0 else pick

## Ekranların çağırdığı tek kapı. Aynı parça zaten çalıyorsa hiçbir şey
## yapmıyor - yoksa şehir içinde ekran değiştirmek parçayı her seferinde
## baştan başlatırdı.
func play_track(track_id: String) -> void:
	if track_id == _current_track:
		return
	var stream := _load_stream(track_id)
	if stream == null:
		return

	_current_track = track_id
	_standby.stream = stream
	_standby.volume_db = SILENT_DB
	_standby.play()
	_crossfade()

## Tek kerelik bir ses çalar (bkz. `SFX_*`). Dosya eksikse sessizce hiçbir
## şey yapmıyor - `_load_stream` ile aynı gerekçe: bir ses efekti asset'i
## henüz gelmemişse oyun onsuz da çalışmalı, çökmemeli.
func play_sfx(sfx_id: String) -> void:
	var path: String = SFX_PATHS.get(sfx_id, "")
	# Çeşitli sesler (`%d` taşıyan yol): SFX_VARIANTS tanesinden biri,
	# perdesi ±SFX_PITCH_JITTER - aynı vuruş iki kez aynı duyulmasın.
	var varied := path.contains("%d")
	if varied:
		var count := int(SFX_VARIANT_COUNTS.get(sfx_id, SFX_VARIANTS))
		var variant := pick_variant(count, int(_last_variant.get(sfx_id, -1)), randi())
		_last_variant[sfx_id] = variant
		path = path % variant
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	# Ses düzeyi otobüsün: arayüz sesleri Ui, gerisi Sfx.
	player.bus = BUS_UI if sfx_id.begins_with("ui_") else BUS_SFX
	player.volume_db = 0.0
	if varied:
		player.pitch_scale = randf_range(1.0 - SFX_PITCH_JITTER, 1.0 + SFX_PITCH_JITTER)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

## Ortam sesini başlatır/değiştirir - müzikten ayrı bir katman (bkz.
## `_ambience_player`'ın notu). Aynı katman zaten çalıyorsa dokunmuyor,
## `play_track`'in aynı deseni.
func play_ambience(ambience_id: String) -> void:
	if ambience_id == _current_ambience:
		return
	_current_ambience = ambience_id
	var path: String = AMBIENCE_PATHS.get(ambience_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	if stream is AudioStreamWAV:
		# Döngü bayrağı içe aktarma ayarında değil burada - `_load_stream`'in
		# mp3 için yaptığı aynı şey, aynı gerekçeyle (.import depoda tutulmuyor).
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_ambience_player.stream = stream
	_ambience_player.volume_db = SILENT_DB
	_ambience_player.play()
	_fade_ambience(0.0)

func stop_ambience() -> void:
	if _current_ambience.is_empty():
		return
	_current_ambience = ""
	_fade_ambience(SILENT_DB, true)

func _fade_ambience(target_db: float, stop_after: bool = false) -> void:
	if _ambience_fade != null and _ambience_fade.is_valid():
		_ambience_fade.kill()
	_ambience_fade = create_tween()
	_ambience_fade.tween_property(_ambience_player, "volume_db", target_db, AMBIENCE_FADE_SECONDS)
	if stop_after:
		_ambience_fade.tween_callback(_ambience_player.stop)

## 0.0 - 1.0. Ayarlar ekranı bunu çağırıyor; değer hem anında uygulanıyor
## hem `user://settings.cfg`'ye yazılıyor (dil ile aynı dosya, aynı
## gerekçe: tercih "Yeni Oyun"da sıfırlanmamalı).
func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	UserSettings.save_music_volume(_music_volume)
	# Düzey Music otobüsünde (N31c); ortamın kendi otobüsü ve sürgüsü var.
	_apply_bus_volume(BUS_MUSIC, _music_volume)

## Tercihin sahibi `UserSettings` (settings.cfg'yi o yazıyor); burası
## yalnızca okuyup uyguluyor.
func get_music_volume() -> float:
	if _music_volume < 0.0:
		_music_volume = UserSettings.load_music_volume()
	return _music_volume

## Çalıcının kendi düzeyi tam; ses düzeyi otobüste (N31c). Sessize alınmış
## müzik yine de çalıyor: otobüs susuyor, parça kaldığı yerden sürüyor.
func _target_db() -> float:
	return 0.0

func _crossfade() -> void:
	_kill_fade()
	_fade = create_tween()
	_fade.set_parallel(true)
	_fade.tween_property(_active, "volume_db", SILENT_DB, FADE_SECONDS)
	_fade.tween_property(_standby, "volume_db", _target_db(), FADE_SECONDS)
	_fade.chain().tween_callback(_finish_crossfade)

func _finish_crossfade() -> void:
	_active.stop()
	var previous := _active
	_active = _standby
	_standby = previous
	_active.volume_db = COMBAT_DUCK_DB if _ducked else _target_db()

func _kill_fade() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = null

## Parçalar döngüde çalıyor. Döngü bayrağı içe aktarma ayarında değil
## burada kuruluyor: `.import` dosyaları depoda tutulmuyor, yani orada
## ayarlanan bir bayrak temiz bir klonda kaybolurdu.
func _load_stream(track_id: String) -> AudioStream:
	var path: String = TRACK_PATHS.get(track_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	if stream is AudioStreamMP3:
		stream.loop = true
	return stream
