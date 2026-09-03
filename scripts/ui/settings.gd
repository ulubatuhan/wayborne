extends Control

## Ana menüden açılan tek ayar ekranı - şimdilik dil seçimi (eskiden ana
## menüde duruyordu, bkz. main_menu.gd). Yalnızca ana menüden açıldığı
## için geri tuşu Nav.return_scene'e değil, doğrudan Nav.MAIN_MENU'ye
## döner (bkz. character.gd'nin aynı deseni, CLAUDE.md World Navigation
## Rules).
const LOCALES: Array[String] = ["tr", "en"]
const LOCALE_NAMES: Array[String] = ["Türkçe", "English"]

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _language_label: Label = $MarginContainer/VBoxContainer/LanguageRow/LanguageLabel
@onready var _language_button: OptionButton = $MarginContainer/VBoxContainer/LanguageRow/LanguageButton
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
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
	_title_label.text = tr("UI_SETTINGS")
	_language_label.text = tr("UI_LANGUAGE")
	_back_button.text = tr("UI_BACK_TO_MENU")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.MAIN_MENU)
