class_name MealDistributionPanel
extends CanvasLayer

## Akşam sofrası: erzak artık sessizce herkese eşit dağılmıyor, oyuncu her
## gece kime yediğini seçiyor (bkz. GameSession.apply_meal_distribution).
## `SuccessionPanel`'in sahnesiz desenini kullanıyor ama bilerek ondan
## ayrılıyor - perde tam siyah değil (`road_journey.tscn`'nin kendi
## `Modal/Backdrop`'uyla aynı %55 alfa), çünkü bu ekranın arkasında yanan
## kamp ateşi ve ateşe yürüyen kervan görünmeli - karar kamp ateşinin
## başında veriliyor, kararın kendisi kadar önemli bir sahne detayı.

signal confirmed(mode, selected)  # String, Array[CharacterData]

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.55)
const PANEL_BACKGROUND: Color = Color(0.09, 0.08, 0.07)
const PANEL_BORDER: Color = Color(0.55, 0.45, 0.28)
const PANEL_WIDTH: float = 460.0

var _session: GameSession
var _mode: String = GameSession.MEAL_MODE_ALL
var _specific_checks: Dictionary = {}  # CharacterData -> CheckBox
var _mode_buttons: Dictionary = {}  # String -> Button
var _specific_list: VBoxContainer

func setup(session: GameSession) -> void:
	_session = session
	layer = 65

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BACKGROUND
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("UI_MEAL_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	vbox.add_child(title)

	var need := _session.get_daily_provision_consumption()
	var have := _session.get_provisions()
	var status := Label.new()
	status.text = tr("UI_MEAL_STATUS") % [have, need]
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(status)

	vbox.add_child(HSeparator.new())

	_add_mode_button(vbox, GameSession.MEAL_MODE_ALL, tr("UI_MEAL_MODE_ALL"))
	_add_mode_button(vbox, GameSession.MEAL_MODE_PARTY_ONLY, tr("UI_MEAL_MODE_PARTY_ONLY"))
	_add_mode_button(vbox, GameSession.MEAL_MODE_CREW_ONLY, tr("UI_MEAL_MODE_CREW_ONLY"))
	_add_mode_button(vbox, GameSession.MEAL_MODE_SPECIFIC, tr("UI_MEAL_MODE_SPECIFIC"))
	_add_mode_button(vbox, GameSession.MEAL_MODE_SELF_ONLY, tr("UI_MEAL_MODE_SELF_ONLY"))

	_specific_list = VBoxContainer.new()
	_specific_list.add_theme_constant_override("separation", 2)
	for character in _session.get_party():
		var check := CheckBox.new()
		check.text = character.character_name
		_specific_list.add_child(check)
		_specific_checks[character] = check
	vbox.add_child(_specific_list)

	vbox.add_child(HSeparator.new())

	var confirm_button := Button.new()
	confirm_button.text = tr("UI_MEAL_CONFIRM")
	confirm_button.pressed.connect(_on_confirm_pressed)
	vbox.add_child(confirm_button)

	_select_mode(GameSession.MEAL_MODE_ALL)

func _add_mode_button(container: VBoxContainer, mode: String, label: String) -> void:
	var button := Button.new()
	button.text = label
	button.toggle_mode = true
	button.pressed.connect(_select_mode.bind(mode))
	container.add_child(button)
	_mode_buttons[mode] = button

## Radyo düğmesi gibi - tek seferde bir mod seçili. `Belirli Kişiler`
## seçiliyken liste görünür, başka hiçbir modda görünmez: "hiçbiri" de
## bir seçenek olduğu için liste her zaman orada durup kafa karıştırmasın.
func _select_mode(mode: String) -> void:
	_mode = mode
	for button_mode in _mode_buttons:
		var button: Button = _mode_buttons[button_mode]
		button.button_pressed = button_mode == mode
	_specific_list.visible = mode == GameSession.MEAL_MODE_SPECIFIC

func _on_confirm_pressed() -> void:
	var selected: Array[CharacterData] = []
	if _mode == GameSession.MEAL_MODE_SPECIFIC:
		for character in _specific_checks:
			var check: CheckBox = _specific_checks[character]
			if check.button_pressed:
				selected.append(character)
	confirmed.emit(_mode, selected)
	queue_free()
