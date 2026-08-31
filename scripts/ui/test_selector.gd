extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

# Bir sistemi test edilebilir hale getirmek için burada boş string yerine
# ilgili sahnenin yolunu yazmak yeterli.
const TEST_SCENES: Dictionary = {
	"economy": "res://scenes/tests/economy_test.tscn",
	"haggling": "res://scenes/tests/haggling_test.tscn",
	"events": "res://scenes/tests/event_test.tscn",
	"combat": "",
	"city": "",
	"travel": "res://scenes/tests/travel_test.tscn",
}

@onready var _buttons: Dictionary = {
	"economy": $VBoxContainer/EconomyButton,
	"haggling": $VBoxContainer/HagglingButton,
	"events": $VBoxContainer/EventsButton,
	"combat": $VBoxContainer/CombatButton,
	"city": $VBoxContainer/CityButton,
	"travel": $VBoxContainer/TravelButton,
}

@onready var _back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	for key in _buttons:
		var scene_path: String = TEST_SCENES[key]
		var button: Button = _buttons[key]
		button.disabled = scene_path.is_empty()
		if not scene_path.is_empty():
			button.pressed.connect(_on_test_button_pressed.bind(scene_path))

	_back_button.pressed.connect(_on_back_pressed)

func _on_test_button_pressed(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
