extends Control

## Girişte seçilen dil tüm oyun için geçerli olur.
##
## Tayfa büyüklüğü ve karakterin kendisi artık burada değil, karakter
## oluşturma ekranında seçiliyor - "Yeni Oyun" oraya gider, oturum da
## orada kurulur.
const LOCALES: Array[String] = ["tr", "en"]
const LOCALE_NAMES: Array[String] = ["Türkçe", "English"]

@onready var _continue_button: Button = $VBoxContainer/ContinueButton
@onready var _play_button: Button = $VBoxContainer/PlayButton
@onready var _language_button: OptionButton = $VBoxContainer/LanguageRow/LanguageButton
@onready var _language_label: Label = $VBoxContainer/LanguageRow/LanguageLabel

var _confirm_dialog: ConfirmationDialog

func _ready() -> void:
	_continue_button.visible = SaveManager.has_save()
	_continue_button.pressed.connect(_on_continue_pressed)
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
	_continue_button.text = tr("UI_CONTINUE")
	_play_button.text = tr("UI_PLAY")

func _on_continue_pressed() -> void:
	var session = SaveManager.load_session()
	if session == null:
		return
	GameState.set_session(session)
	Nav.return_scene = Nav.CITY_MAP
	get_tree().change_scene_to_file(Nav.CITY_MAP)

func _on_play_pressed() -> void:
	if SaveManager.has_save():
		_confirm_new_game()
	else:
		_open_character_creation()

func _confirm_new_game() -> void:
	if _confirm_dialog == null:
		_confirm_dialog = ConfirmationDialog.new()
		_confirm_dialog.confirmed.connect(_open_character_creation)
		add_child(_confirm_dialog)
	_confirm_dialog.dialog_text = tr("UI_NEW_GAME_CONFIRM")
	_confirm_dialog.popup_centered()

## Kayıt yalnızca karakter oluşturma tamamlanınca silinir; oyuncu geri
## dönerse eski kaydı yerinde durur.
func _open_character_creation() -> void:
	get_tree().change_scene_to_file(Nav.CHARACTER_CREATION)
