extends Node

## Autoload: kalıcı oyun oturumunu tutar. Durum mantığının kendisi
## GameSession içinde (RefCounted) durduğu için test sahneleri
## autoload'a dokunmadan kendi oturumlarını kurabilir.
##
## Bu dosyada bilerek hiçbir class_name'e başvurulmuyor - ne tip
## açıklamasında ne de gövdede. Autoload'lar global script class cache
## hazır olmadan ayrıştırılıyor; preload bile derleme anında çözdüğü
## için GameSession'ın kendi bağımlılıkları (Wallet, Inventory,
## CaravanState) üzerinden aynı hataya düşüyordu. load() çalışma anında
## çözdüğü ve oturum ilk erişimde kurulduğu için o noktada cache hazır.

const GAME_SESSION_PATH: String = "res://scripts/autoload/game_session.gd"

var _session = null

## Oturumu ilk erişimde oluşturur.
func get_session():
	if _session == null:
		start_new_game()
	return _session

func start_new_game(starting_gold: int = 250, starting_provisions: int = 20, starting_wagon_count: int = 1) -> void:
	var session_script := load(GAME_SESSION_PATH)
	_session = session_script.new(starting_gold, starting_provisions, starting_wagon_count)
	_session.log_first_times = UserSettings.allow_play_log
	_session.log_beat(_session.BEAT_LOG_SESSION)

## Gerçek oyun süresi (görev Y-H02): oyun duraklatılmadıkça her kare eklenir.
func _process(delta: float) -> void:
	if _session != null and not get_tree().paused:
		_session.play_seconds += delta

## SaveManager'ın yüklediği bir oturumu kalıcı hale getirir.
func set_session(session) -> void:
	_session = session
	if _session != null:
		_session.log_first_times = UserSettings.allow_play_log
		_session.log_beat(_session.BEAT_LOG_SESSION)

## Ölçüm izni (Y-K03) oyun sürerken değişince açık oturuma da geçer.
func set_play_log(on: bool) -> void:
	UserSettings.set_access("play_log", on)
	if _session != null:
		_session.log_first_times = on
