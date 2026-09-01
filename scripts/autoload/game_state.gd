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

signal session_reset()

var _session = null

## Oturumu ilk erişimde oluşturur.
func get_session():
	if _session == null:
		start_new_game()
	return _session

func has_session() -> bool:
	return _session != null

func start_new_game(starting_gold: int = 250, starting_provisions: int = 20) -> void:
	var session_script := load(GAME_SESSION_PATH)
	_session = session_script.new(starting_gold, starting_provisions)
	session_reset.emit()

## SaveManager'ın yüklediği bir oturumu kalıcı hale getirir.
func set_session(session) -> void:
	_session = session
	session_reset.emit()
