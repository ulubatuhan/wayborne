extends Control

# Bir sistemi test edilebilir hale getirmek için burada boş string yerine
# ilgili sahnenin yolunu yazmak yeterli.
@onready var _test_scenes: Dictionary = {
	"economy": Nav.ECONOMY,
	"haggling": Nav.HAGGLING,
	"events": Nav.JOURNEY,
	"combat": "",
	"city": Nav.CITY_MAP,
	"travel": Nav.TRAVEL,
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
	# Seçiciye hangi ekrandan gelindiyse geri tuşu oraya dönmeli.
	Nav.selector_return_scene = Nav.return_scene
	Nav.return_scene = Nav.TEST_SELECTOR

	for key in _buttons:
		var scene_path: String = _test_scenes[key]
		var button: Button = _buttons[key]
		button.disabled = scene_path.is_empty()
		if not scene_path.is_empty():
			button.pressed.connect(_on_test_button_pressed.bind(scene_path))

	_back_button.text = Nav.label_for(Nav.selector_return_scene)
	_back_button.pressed.connect(_on_back_pressed)

func _on_test_button_pressed(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func _on_back_pressed() -> void:
	Nav.return_scene = Nav.selector_return_scene
	get_tree().change_scene_to_file(Nav.selector_return_scene)
