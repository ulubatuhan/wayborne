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
## Yalnızca emir kipinde: oyuncu vazgeçti, emir değişmedi.
signal cancelled

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.55)
const PANEL_WIDTH: float = 460.0
## Sofra: her kişinin önünde dolu ya da boş bir kâse (r8a/r8b). Seçim
## yapılırken kimin aç kalacağını isimle ve resimle gösteriyor - onay
## basılmadan önce.
const BOWL_FULL_FILE: String = "r8a_bowl_full.png"
const BOWL_EMPTY_FILE: String = "r8b_bowl_empty.png"
const BOWL_SIZE: float = 30.0

var _session: GameSession
var _mode: String = GameSession.MEAL_MODE_ALL
var _specific_checks: Dictionary = {}  # CharacterData -> CheckBox
var _mode_buttons: Dictionary = {}  # String -> Button
var _specific_list: VBoxContainer
var _bowls: Dictionary = {}  # CharacterData -> TextureRect
var _crew_bowl: TextureRect

## `policy_only`: gece değil, emir ekranı - yemek dağıtılmıyor, yalnızca
## kalıcı sofra emri değişiyor (yol ekranındaki "Sofra" düğmesi).
func setup(session: GameSession, policy_only: bool = false) -> void:
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

	vbox.add_child(_build_table())

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
		check.toggled.connect(func(_on: bool) -> void: _refresh_bowls())
		_specific_list.add_child(check)
		_specific_checks[character] = check
	vbox.add_child(_specific_list)

	vbox.add_child(HSeparator.new())

	var confirm_button := Button.new()
	confirm_button.text = tr("UI_MEAL_SAVE_POLICY" if policy_only else "UI_MEAL_CONFIRM")
	confirm_button.pressed.connect(_on_confirm_pressed)
	vbox.add_child(confirm_button)

	if policy_only:
		var cancel_button := Button.new()
		cancel_button.text = tr("UI_CANCEL")
		cancel_button.pressed.connect(_on_cancel_pressed)
		vbox.add_child(cancel_button)

	# Seçim bir kalıcı emir: oyuncu neden bu ekranı her gece görmediğini ve
	# ne zaman yeniden göreceğini bilsin.
	var note := Label.new()
	note.text = tr("UI_MEAL_STANDING_NOTE")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.add_theme_font_size_override("font_size", 14)
	note.modulate = ArtPalette.UI_HUD_NOTE
	vbox.add_child(note)

	for character in _session.get_meal_policy_selected():
		(_specific_checks[character] as CheckBox).button_pressed = true
	_select_mode(_session.meal_policy_mode)

func _build_table() -> Control:
	var table := HFlowContainer.new()
	table.alignment = FlowContainer.ALIGNMENT_CENTER
	table.add_theme_constant_override("h_separation", 14)
	for character in _session.get_party():
		_bowls[character] = _add_place(table, character.character_name)
	# Tayfa ve tüccarlar isimsiz, tek bir kâse - ama ekranda.
	_crew_bowl = _add_place(table, tr("UI_MEAL_CREW_PLACE"))
	return table

func _add_place(table: Container, name_text: String) -> TextureRect:
	var place := VBoxContainer.new()
	place.alignment = BoxContainer.ALIGNMENT_END
	var bowl := WaybookTheme.picture(BOWL_FULL_FILE, BOWL_SIZE)
	place.add_child(bowl)
	var label := Label.new()
	label.text = name_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	place.add_child(label)
	table.add_child(place)
	return bowl

func _refresh_bowls() -> void:
	var fed := _session.get_meal_fed_party(_mode, _checked())
	for character in _bowls:
		_set_bowl(_bowls[character], fed.has(character))
	_set_bowl(_crew_bowl, _session.meal_feeds_crew(_mode))

func _set_bowl(bowl: TextureRect, full: bool) -> void:
	bowl.texture = WaybookTheme.texture(BOWL_FULL_FILE if full else BOWL_EMPTY_FILE)
	bowl.modulate = Color.WHITE if full else ArtPalette.UI_TINT_DISABLED

func _checked() -> Array[CharacterData]:
	var selected: Array[CharacterData] = []
	for character in _specific_checks:
		var check: CheckBox = _specific_checks[character]
		if check.button_pressed:
			selected.append(character)
	return selected

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
	_refresh_bowls()

func _on_confirm_pressed() -> void:
	var selected: Array[CharacterData] = []
	if _mode == GameSession.MEAL_MODE_SPECIFIC:
		selected = _checked()
	confirmed.emit(_mode, selected)
	queue_free()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()
