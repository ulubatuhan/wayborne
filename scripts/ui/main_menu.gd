extends Control

## Girişte seçilen dil tüm oyun için geçerli olur (bkz. scripts/ui/settings.gd
## - dil seçici artık burada değil, Ayarlar ekranında).
##
## Tayfa büyüklüğü ve karakterin kendisi artık burada değil, karakter
## oluşturma ekranında seçiliyor - "Yeni Oyun" oraya gider, oturum da
## orada kurulur.

## Başlık ve butonların arkasındaki karartma. Manzaranın üstüne çıplak
## metin koymak, gökyüzünün açık olduğu yerde başlığı okunmaz yapıyor -
## olay kartının kendi opak kutusunu taşımasıyla aynı gerekçe.
const SCRIM_PAD: Vector2 = Vector2(56.0, 40.0)
const SCRIM_COLOR: Color = Color(0.04, 0.035, 0.045, 0.62)

@onready var _menu_box: VBoxContainer = $VBoxContainer
@onready var _continue_button: Button = $VBoxContainer/ContinueButton
@onready var _play_button: Button = $VBoxContainer/PlayButton
@onready var _settings_button: Button = $VBoxContainer/SettingsButton
@onready var _quit_button: Button = $VBoxContainer/QuitButton

var _confirm_dialog: ConfirmationDialog

func _ready() -> void:
	Nav.go_root(Nav.MAIN_MENU)
	# Ana menü ile yol aynı parçayı paylaşıyor (bkz. AudioManager):
	# menüdeki ekran da bir yol manzarası, aynı his.
	AudioManager.play_track(AudioManager.TRACK_ROAD)
	_build_backdrop()
	_continue_button.visible = SaveManager.has_save()
	_continue_button.pressed.connect(_on_continue_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	_refresh_texts()

## Manzara ve karartma butonların **arkasına** giriyor: `add_child` onları
## en sona koyar, `move_child(…, 0)` en başa. Sahne dosyasına eklemek
## yerine kodda kurulmalarının sebebi `PulseBar`/`OnboardingPanel` ile
## aynı - sahnesiz bir bileşen tek bir yerde tanımlı kalıyor.
func _build_backdrop() -> void:
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	move_child(backdrop, 0)

	var scrim := ColorRect.new()
	scrim.color = SCRIM_COLOR
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	move_child(scrim, 1)
	_fit_scrim(scrim)
	# Butonların kutusu yerleşim geçişinden önce doğru boyunu bilmiyor
	# (dil değişince metin de değişiyor), o yüzden karartma onu izliyor.
	_menu_box.resized.connect(_fit_scrim.bind(scrim))
	_menu_box.item_rect_changed.connect(_fit_scrim.bind(scrim))

func _fit_scrim(scrim: ColorRect) -> void:
	scrim.position = _menu_box.position - SCRIM_PAD
	scrim.size = _menu_box.size + SCRIM_PAD * 2.0

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
	get_tree().change_scene_to_file(Nav.go_root(Nav.CITY_MAP))

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
	get_tree().change_scene_to_file(Nav.open(Nav.MAIN_MENU, Nav.CHARACTER_CREATION))

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(Nav.open(Nav.MAIN_MENU, Nav.SETTINGS))

func _on_quit_pressed() -> void:
	get_tree().quit()
