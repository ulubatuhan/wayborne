extends Control

## Girişte seçilen dil tüm oyun için geçerli olur (bkz. scripts/ui/settings.gd
## - dil seçici artık burada değil, Ayarlar ekranında).
##
## Tayfa büyüklüğü ve karakterin kendisi artık burada değil, karakter
## oluşturma ekranında seçiliyor - "Yeni Oyun" oraya gider, oturum da
## orada kurulur.

@onready var _continue_button: Button = $VBoxContainer/ContinueButton
@onready var _play_button: Button = $VBoxContainer/PlayButton
@onready var _settings_button: Button = $VBoxContainer/SettingsButton
@onready var _quit_button: Button = $VBoxContainer/QuitButton

var _confirm_dialog: ConfirmationDialog

func _ready() -> void:
	_continue_button.visible = SaveManager.has_save()
	_continue_button.pressed.connect(_on_continue_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	_refresh_texts()

func _refresh_texts() -> void:
	_continue_button.text = tr("UI_CONTINUE")
	_play_button.text = tr("UI_PLAY")
	_settings_button.text = tr("UI_SETTINGS")
	_quit_button.text = tr("UI_QUIT")

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

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(Nav.SETTINGS)

func _on_quit_pressed() -> void:
	get_tree().quit()
