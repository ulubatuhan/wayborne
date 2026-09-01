extends Control

## Geliştirici menüsü. DevPanel autoload'u tarafından oyun başında bir kez
## kurulup gizlenir, F1 ile açılıp kapanır - normal oyun akışının bir
## parçası değildir, bu yüzden Nav.return_scene'e hiç dokunmaz: bir
## ekrana geçersen o ekranın geri tuşu seni buraya değil, paneli açtığın
## yere döndürür.

# Bir sistemi test edilebilir hale getirmek için burada boş string yerine
# ilgili sahnenin yolunu yazmak yeterli.
@onready var _test_scenes: Dictionary = {
	"economy": Nav.ECONOMY,
	"haggling": Nav.HAGGLING,
	"events": Nav.JOURNEY,
	"combat": Nav.COMBAT,
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

@onready var _close_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	for key in _buttons:
		var scene_path: String = _test_scenes[key]
		var button: Button = _buttons[key]
		button.disabled = scene_path.is_empty()
		if not scene_path.is_empty():
			button.pressed.connect(_on_test_button_pressed.bind(scene_path))

	_close_button.pressed.connect(_on_close_pressed)

func _on_test_button_pressed(scene_path: String) -> void:
	DevPanel.hide_panel()
	get_tree().change_scene_to_file(scene_path)

func _on_close_pressed() -> void:
	DevPanel.hide_panel()
