extends Control

const TEST_SELECTOR_SCENE: String = "res://scenes/ui/test_selector.tscn"

@onready var _play_button: Button = $VBoxContainer/PlayButton

func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(TEST_SELECTOR_SCENE)
