extends Control

## Zenginlik hedefine (GameSession.GOAL_GOLD) ulaşıldığında bir kereye
## mahsus açılan kutlama ekranı - bkz. road_journey.gd
## _on_enter_city_pressed. Oyunun DD tarzı felsefesinde yenilgi/"game
## over" yok, bu yüzden bu bir bitiş değil, oyuna kaldığı yerden devam
## edilen bir kilometre taşı. Yalnızca oradan açıldığı için "Devam Et"
## Nav.return_scene'e değil, doğrudan Nav.CITY_MAP'e döner (bkz.
## settings.gd'nin aynı deseni).

@onready var _summary_label: Label = $MarginContainer/VBoxContainer/SummaryLabel
@onready var _continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)

	var session: GameSession = GameState.get_session()
	_summary_label.text = (
		"%d gün süren yolculuğun sonunda kese %d GG'ye ulaştı.\n" +
		"İtibar: %d · Parti: %d kişi · Vagon: %d"
	) % [
		session.total_days_elapsed,
		session.wallet.balance,
		session.reputation,
		session.get_party().size(),
		session.owned_wagon_count,
	]

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file(Nav.CITY_MAP)
