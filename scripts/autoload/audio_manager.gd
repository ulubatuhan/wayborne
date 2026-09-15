extends Node

## Autoload: oyunun müziği. Tek iş yapıyor - hangi ekranda hangi parçanın
## çaldığını bilmek ve aradaki geçişi yumuşatmak.
##
## Bu dosyada bilerek hiçbir `class_name`'e başvurulmuyor: autoload'lar
## global script sınıf önbelleği hazır olmadan ayrıştırılıyor (bkz.
## CLAUDE.md Autoload rule). `AudioStreamPlayer` motorun kendi tipi,
## projenin bir sınıfı değil - o yüzden sorun değil.
##
## **İki çalıcı var, çünkü geçiş kesme değil geçiştir.** Tek çalıcıyla
## parça değiştirmek sesi bıçak gibi kesiyor; şehre varış ile yolun
## bitişi arasındaki an oyunun en çok "vardık" demesi gereken anı ve bir
## kesme onu bozuyor. `_active` sönerken `_standby` açılıyor, sonra ikisi
## yer değiştiriyor.
##
## Parça dosyaları `data/assets/audio/` altında ve `preload` edilmiyor:
## autoload derlenirken çözülen bir yol, dosya adı değişince sessizce
## değil *gürültülü* patlasın diye çalışma anında `load()` ile alınıyor.

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

var _active: AudioStreamPlayer
var _standby: AudioStreamPlayer
var _current_track: String = ""
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

## 0.0 - 1.0. Ayarlar ekranı bunu çağırıyor; değer hem anında uygulanıyor
## hem `user://settings.cfg`'ye yazılıyor (dil ile aynı dosya, aynı
## gerekçe: tercih "Yeni Oyun"da sıfırlanmamalı).
func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	UserSettings.save_music_volume(_music_volume)
	if _fade == null or not _fade.is_running():
		_active.volume_db = _target_db()

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
