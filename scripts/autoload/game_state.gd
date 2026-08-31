extends Node

## Autoload: kalıcı oyun oturumunu tutar. Durum mantığının kendisi
## GameSession içinde (RefCounted) durduğu için test sahneleri
## autoload'a dokunmadan kendi oturumlarını kurabilir.
##
## Tipler class_name yerine preload ile çözülüyor: autoload'lar global
## script class cache hazır olmadan ayrıştırılıyor, bu yüzden bir
## class_name'e ada göre başvurmak "Could not find type" hatası veriyor.
## preload yol üzerinden çözdüğü için bu sıralamadan etkilenmiyor.

const GameSessionScript := preload("res://scripts/autoload/game_session.gd")

signal session_reset()

var session: GameSessionScript

func _ready() -> void:
	start_new_game()

func start_new_game(starting_gold: int = 250, starting_provisions: int = 20) -> void:
	session = GameSessionScript.new(starting_gold, starting_provisions)
	session_reset.emit()
