class_name InGameMenu
extends CanvasLayer

## Oyun içi duraklatma menüsü. `OnboardingPanel` deseni: sahnesiz,
## `.new()` ile kurulur, Esc/perdeye tıklama ile kapanır.
##
## Var olma sebebi tek bir şikâyet (playtest): `world_hub.gd`'nin "Menü"
## tuşu ve `road_journey.gd`'nin canlı seferdeki çıkış tuşu ikisi de
## dosdoğru ana menüye atlıyordu - "oyun içinde menüye dönünce ana
## menüye gitmeyelim direkt". Artık ikisi de önce burayı açıyor; ana
## menüye gitmek kendi onaylı seçeneği oldu, sürprizle değil. Esc de
## her ikisinden bağımsız olarak aynı katmanı açıyor.
##
## Ayarlar burada yok, bilerek: `Nav.open()` geçerli sahneyi yığına
## iter, ama yol ekranı (`Nav.JOURNEY`) yığından hiç girilmeyen bir kök
## gibi davranıyor (bkz. Road Movement Rules - "sefer bitirme
## eylemleri ana menüye gider, yığın üzerinden değil"). Ayarlar'ı buraya
## eklemek sefer sürerken `Nav.JOURNEY`'i yığına itmek anlamına gelirdi,
## ki bu daha önce hiç sınanmamış bir yol - geri tuşu sahneyi
## `road_journey.tscn`'i sıfırdan yeniden yükleyerek "geri getirirdi".
## Sahne değiştirmemek en güvenlisi, o yüzden bu katman kendi içinde
## kalıyor.
##
## Kaydet burada ayrı bir düğme değil - `can_save` doğruysa
## `SaveSlotsPanel` "Buraya Kaydet"i kendisi gösteriyor, yanlışsa nedenini
## yazıyor (bkz. SaveManager'ın başındaki not: sefer alanları hiç
## serileştirilmiyor, yani sefer sürerken kayıt sessizce sefer bilgisini
## kaybettirirdi).

signal dismissed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.72)
const PANEL_WIDTH: float = 520.0

var _can_save: bool = true
var _root: Control
var _backdrop: ColorRect
## Devinen "kart" (`panel`) - `backdrop`in kardeşi, `root`'un torunu değil
## (bkz. OnboardingPanel'in aynı yorumu): yalnızca bu ölçekleniyor/soluyor.
var _card: PanelContainer
var _menu_page: VBoxContainer
var _saves_page: VBoxContainer
var _saves_panel: SaveSlotsPanel
var _confirm_dialog: ConfirmationDialog
## Kapanış üç yoldan (tuş/perde/Esc) tetiklenebiliyor - devinim sürerken
## ikincisi ikinci bir tween başlatıp `dismissed`i iki kez yaymasın diye.
var _dismissing: bool = false

func setup(can_save: bool) -> void:
	_can_save = can_save

func _ready() -> void:
	layer = 60
	_build()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_backdrop = ColorRect.new()
	_backdrop.color = BACKDROP_COLOR
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.gui_input.connect(_on_backdrop_input)
	_root.add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	center.add_child(panel)
	_card = panel

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	panel.add_child(stack)

	var title := Label.new()
	title.text = tr("UI_INGAME_MENU_TITLE")
	title.add_theme_font_size_override("font_size", 22)
	stack.add_child(title)

	_menu_page = VBoxContainer.new()
	_menu_page.add_theme_constant_override("separation", 8)
	stack.add_child(_menu_page)
	_build_menu_page()

	_saves_page = VBoxContainer.new()
	_saves_page.add_theme_constant_override("separation", 8)
	_saves_page.visible = false
	stack.add_child(_saves_page)
	_build_saves_page()

	WaybookTheme.present(_card, _backdrop, self)

func _build_menu_page() -> void:
	var resume := Button.new()
	resume.text = tr("UI_INGAME_MENU_RESUME")
	resume.pressed.connect(_on_dismiss_pressed)
	_menu_page.add_child(resume)

	var saves := Button.new()
	saves.text = tr("UI_INGAME_MENU_SAVES")
	saves.pressed.connect(_on_saves_pressed)
	_menu_page.add_child(saves)

	var quit := Button.new()
	quit.text = tr("UI_INGAME_MENU_QUIT")
	quit.pressed.connect(_on_quit_pressed)
	_menu_page.add_child(quit)

func _build_saves_page() -> void:
	_saves_panel = SaveSlotsPanel.new()
	_saves_page.add_child(_saves_panel)
	_saves_panel.loaded.connect(_on_save_loaded)

	var back := Button.new()
	back.text = tr("UI_BACK")
	back.pressed.connect(_on_saves_back_pressed)
	_saves_page.add_child(back)

func _on_saves_pressed() -> void:
	_menu_page.visible = false
	_saves_page.visible = true
	_saves_panel.setup(_can_save)

func _on_saves_back_pressed() -> void:
	_saves_page.visible = false
	_menu_page.visible = true

func _on_save_loaded(session) -> void:
	GameState.set_session(session)
	SceneInk.go(Nav.resume_scene(session))

func _on_quit_pressed() -> void:
	if _confirm_dialog == null:
		_confirm_dialog = ConfirmationDialog.new()
		_confirm_dialog.confirmed.connect(_on_quit_confirmed)
		_root.add_child(_confirm_dialog)
	_confirm_dialog.dialog_text = tr("UI_INGAME_MENU_QUIT_CONFIRM")
	_confirm_dialog.popup_centered()

func _on_quit_confirmed() -> void:
	SceneInk.go(Nav.go_root(Nav.MAIN_MENU))

## Perdeye tıklamak da kapatır - OnboardingPanel'in aynı gerekçesi.
func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_dismiss_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_dismiss_pressed()
		get_viewport().set_input_as_handled()

func _on_dismiss_pressed() -> void:
	if _dismissing:
		return
	_dismissing = true
	WaybookTheme.dismiss(_card, _backdrop, self, func():
		dismissed.emit()
		queue_free()
	)
