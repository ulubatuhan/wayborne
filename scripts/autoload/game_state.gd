extends Node

## Autoload: kalıcı oyun oturumunu tutar. Durum mantığının kendisi
## GameSession içinde (RefCounted) durduğu için test sahneleri
## autoload'a dokunmadan kendi oturumlarını kurabilir.

signal session_reset()

var session: GameSession

func _ready() -> void:
	start_new_game()

func start_new_game(starting_gold: int = 250, starting_provisions: int = 20) -> void:
	session = GameSession.new(starting_gold, starting_provisions)
	session_reset.emit()
