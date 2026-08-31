extends Control

const TEST_SELECTOR_SCENE: String = "res://scenes/ui/test_selector.tscn"

## Girişte seçilen dil tüm oyun için geçerli olur.
const LOCALES: Array[String] = ["tr", "en"]
const LOCALE_NAMES: Array[String] = ["Türkçe", "English"]

@onready var _play_button: Button = $VBoxContainer/PlayButton
@onready var _language_button: OptionButton = $VBoxContainer/LanguageRow/LanguageButton
@onready var _language_label: Label = $VBoxContainer/LanguageRow/LanguageLabel

func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_setup_language_selector()

func _setup_language_selector() -> void:
	for i in range(LOCALES.size()):
		_language_button.add_item(LOCALE_NAMES[i], i)

	var current_locale := TranslationServer.get_locale().substr(0, 2)
	var selected := LOCALES.find(current_locale)
	_language_button.select(maxi(selected, 0))

	_language_button.item_selected.connect(_on_language_selected)
	_refresh_texts()

func _on_language_selected(index: int) -> void:
	if index < 0 or index >= LOCALES.size():
		return
	TranslationServer.set_locale(LOCALES[index])
	_refresh_texts()

func _refresh_texts() -> void:
	_language_label.text = tr("UI_LANGUAGE")
	_play_button.text = tr("UI_PLAY")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(TEST_SELECTOR_SCENE)
