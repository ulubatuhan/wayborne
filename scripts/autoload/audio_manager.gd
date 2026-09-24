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

const TRACK_PATHS: Dictionary = {
	TRACK_ROAD: "res://data/assets/audio/copper_for_the_traveler.mp3",
	TRACK_CITY: "res://data/assets/audio/high_noon_in_the_square.mp3",
}

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
const SFX_PATHS: Dictionary = {
	SFX_THUD: "res://data/assets/audio/wooden_thud.wav",
	SFX_GATE: "res://data/assets/audio/gate_creak.wav",
}

## Ortam sesi (bkz. `play_ambience`) - müziğin *altında* değil, müziğin
## **yerine** duran bir katman: başlangıç ekranında henüz müzik yok, yalnızca
## rüzgar var. Kendi çalıcısı ve kendi solması var, müzikten bağımsız -
## ikisi aynı anda solabilmeli (rüzgar sönerken yol müziği yükseliyor).
const AMBIENCE_WIND: String = "wind"
const AMBIENCE_PATHS: Dictionary = {
	AMBIENCE_WIND: "res://data/assets/audio/wind_ambience.wav",
}
const AMBIENCE_FADE_SECONDS: float = 1.6

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

func _ready() -> void:
	# Oyun duraklatılsa bile müzik sürsün: duraklamada kesilen müzik
	# oyunun çöktüğü izlenimi veriyor.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_active = _make_player()
	_standby = _make_player()
	_ambience_player = _make_player()

func _make_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = SILENT_DB
	add_child(player)
	return player

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

func stop_music() -> void:
	_current_track = ""
	_kill_fade()
	_active.stop()
	_standby.stop()

func get_current_track() -> String:
	return _current_track

## Tek kerelik bir ses çalar (bkz. `SFX_*`). Dosya eksikse sessizce hiçbir
## şey yapmıyor - `_load_stream` ile aynı gerekçe: bir ses efekti asset'i
## henüz gelmemişse oyun onsuz da çalışmalı, çökmemeli.
func play_sfx(sfx_id: String) -> void:
	var path: String = SFX_PATHS.get(sfx_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = _target_db()
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
	_fade_ambience(_target_db())

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
	if _fade == null or not _fade.is_running():
		_active.volume_db = _target_db()
	# Ortam sesi de aynı tek tercihi okuyor (bkz. dosyanın başındaki not) -
	# ayarlar ekranında sürgü değişince rüzgar de anında güncellenmeli.
	if not _current_ambience.is_empty() and (_ambience_fade == null or not _ambience_fade.is_running()):
		_ambience_player.volume_db = _target_db()

## Tercihin sahibi `UserSettings` (settings.cfg'yi o yazıyor); burası
## yalnızca okuyup uyguluyor.
func get_music_volume() -> float:
	if _music_volume < 0.0:
		_music_volume = UserSettings.load_music_volume()
	return _music_volume

## Sessize alınmış müzik hâlâ çalıyor olmalı: sesi açınca parça kaldığı
## yerden devam etsin, baştan başlamasın.
func _target_db() -> float:
	var volume := get_music_volume()
	if volume <= 0.0:
		return SILENT_DB
	return linear_to_db(volume)

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
	_active.volume_db = _target_db()

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
