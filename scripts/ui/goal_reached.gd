extends Control

## Zenginlik hedefine (GameSession.GOAL_GOLD) ulaşıldığında bir kereye
## mahsus açılan kutlama ekranı - bkz. road_journey.gd
## _on_enter_city_pressed. Oyunun DD tarzı felsefesinde yenilgi/"game
## over" yok, bu yüzden bu bir bitiş değil, oyuna kaldığı yerden devam
## edilen bir kilometre taşı. Yalnızca oradan açıldığı için "Devam Et"
## Şehre kök olarak döner - hedefe ulaşmak bir alt ekran değil, oyunun
## kaldığı yerden sürmesi (bkz.
## settings.gd'nin aynı deseni).

@onready var _summary_label: Label = $MarginContainer/VBoxContainer/SummaryLabel
@onready var _continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	$MarginContainer/VBoxContainer/TitleLabel.text = tr("UI_GOAL_TITLE")
	_continue_button.text = tr("UI_CONTINUE")
	_continue_button.pressed.connect(_on_continue_pressed)

	var session: GameSession = GameState.get_session()
	_summary_label.text = (
		tr("UI_GOAL_SUMMARY") +
		tr("UI_GOAL_STATS")
	) % [
		session.total_days_elapsed,
		session.wallet.balance,
		session.reputation,
		session.get_party().size(),
		session.owned_wagon_count,
	]

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file(Nav.go_root(Nav.CITY_MAP))
