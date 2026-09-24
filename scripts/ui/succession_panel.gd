class_name SuccessionPanel
extends CanvasLayer

## Liderlik devri artık bir kayıt satırı değil, bir sahne. Oyunun tek
## "non-negotiable" kuralı - kervan asla tükenmez, ama lider ölürse kıdemli
## yoldaş adı devralır (bkz. CLAUDE.md Lineage Rules) - şimdiye kadar
## `UI_ROAD_NEW_LEADER` log satırından ibaretti; playtest'in okuduğu diğer
## on bir satırdan biri gibi kayıp gidiyordu.
##
## OnboardingPanel'in deseni: sahnesiz, `.new()` ile kurulur. Ama bilerek
## OnboardingPanel'den bir yerde ayrılıyor - perdeye tıklamak ve Esc burada
## KAPATMIYOR. Törenin tek çıkışı "Devam Et" tuşu: bu an atlanabilir olursa
## bir bildirimden farkı kalmaz.

## Faz 18: devir artık bir karar. Adaylar kıdem sırasıyla listelenir,
## kıdemli önceden seçili gelir; oyuncu başkasını seçerse kıdemli bunu
## unutmaz (bkz. `GameSession.appoint_heir`). Tören yine atlanamaz - tek
## çıkış seçimi onaylamak.

signal dismissed
## heir: CharacterData
signal heir_chosen(heir)

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.85)
const PANEL_WIDTH: float = 640.0
const SELECTED_COLOR: Color = Color(1.0, 0.9, 0.6)
const IDLE_COLOR: Color = Color(0.75, 0.72, 0.66)

var _candidates: Array[CharacterData] = []
var _selected: CharacterData = null
var _candidate_buttons: Array[Button] = []
var _heir_label: Label = null
var _heir_cameo: PortraitCameo = null

## Düşenin adı büyük yazılıp üstü mürekkeple çiziliyor; seçilen varisin
## portresi madalyonda; onay düğmesinin üstünde mühür (bkz. Waybook UI
## Rules - geri alınamaz karar mühürlü cilt ve mühür taşır).
const FALLEN_NAME_FONT_SIZE: int = 30
const HEIR_CAMEO_HEIGHT: float = 120.0
const SEAL_HEIGHT: float = 64.0

func setup(
	caravan_name: String, fallen_name: String, fallen_line: String,
	candidates: Array[CharacterData], generation: int
) -> void:
	_candidates = candidates
	_selected = candidates[0] if not candidates.is_empty() else null
	layer = 70
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
	panel.theme_type_variation = WaybookTheme.SEAL_PANEL
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var eyebrow := Label.new()
	eyebrow.text = tr("UI_SUCCESSION_TITLE")
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.modulate = ArtPalette.GOLD_DIM
	vbox.add_child(eyebrow)

	var name_label := Label.new()
	name_label.text = tr("UI_SUCCESSION_CARAVAN") % caravan_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.modulate = ArtPalette.GOLD
	vbox.add_child(name_label)

	var generation_label := Label.new()
	generation_label.text = tr("UI_SUCCESSION_GENERATION") % generation
	generation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(generation_label)

	vbox.add_child(HSeparator.new())

	var struck := StruckLine.new().setup(fallen_name, true)
	struck.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	struck.label.add_theme_font_size_override("font_size", FALLEN_NAME_FONT_SIZE)
	vbox.add_child(struck)

	var fallen_label := Label.new()
	fallen_label.text = tr("UI_SUCCESSION_FALLEN") % fallen_name
	fallen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallen_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(fallen_label)

	if not fallen_line.is_empty():
		var cause_label := Label.new()
		cause_label.text = fallen_line
		cause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cause_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		cause_label.modulate = ArtPalette.GOLD_DIM
		vbox.add_child(cause_label)

	var prompt := Label.new()
	prompt.text = tr("UI_SUCCESSION_CHOOSE")
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(prompt)

	for index in candidates.size():
		var candidate := candidates[index]
		var button := Button.new()
		button.text = candidate_line(candidate, index == 0)
		button.toggle_mode = true
		button.pressed.connect(_on_candidate_pressed.bind(candidate))
		vbox.add_child(button)
		_candidate_buttons.append(button)

	var heir_row := HBoxContainer.new()
	heir_row.alignment = BoxContainer.ALIGNMENT_CENTER
	heir_row.add_theme_constant_override("separation", 14)
	vbox.add_child(heir_row)
	_heir_cameo = PortraitCameo.new().setup(_selected, HEIR_CAMEO_HEIGHT)
	heir_row.add_child(_heir_cameo)
	_heir_label = Label.new()
	_heir_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_heir_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_heir_label.custom_minimum_size = Vector2(PANEL_WIDTH * 0.5, 0.0)
	_heir_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_heir_label.add_theme_font_size_override("font_size", 16)
	heir_row.add_child(_heir_label)

	var seal := WaybookTheme.picture("g9_seal.png", SEAL_HEIGHT)
	seal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(seal)

	var continue_button := Button.new()
	continue_button.text = tr("UI_SUCCESSION_CONFIRM")
	continue_button.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_button)
	_refresh_selection()

## "Ad · Sv N · stres S · (kıdemli)" ve varsa en ağır kırgınlık.
static func candidate_line(candidate: CharacterData, is_senior: bool) -> String:
	var line := String(TranslationServer.translate("UI_SUCCESSION_CANDIDATE")) % [
		candidate.character_name, candidate.level, candidate.stress
	]
	if is_senior:
		line += " · " + String(TranslationServer.translate("UI_SUCCESSION_SENIOR"))
	var grievance := candidate.get_top_grievance()
	if not grievance.is_empty():
		line += " · " + String(TranslationServer.translate(grievance_label_key(grievance)))
	return line

static func grievance_label_key(grievance: String) -> String:
	match grievance:
		CharacterData.GRIEVANCE_UNFED:
			return "UI_GRIEVANCE_UNFED"
		CharacterData.GRIEVANCE_BENCHED:
			return "UI_GRIEVANCE_BENCHED"
		CharacterData.GRIEVANCE_WITNESSED_DEATH:
			return "UI_GRIEVANCE_WITNESSED_DEATH"
		CharacterData.GRIEVANCE_PASSED_OVER:
			return "UI_GRIEVANCE_PASSED_OVER"
	return grievance

func get_selected() -> CharacterData:
	return _selected

func select(candidate: CharacterData) -> void:
	if _candidates.has(candidate):
		_selected = candidate
		_refresh_selection()

func _on_candidate_pressed(candidate: CharacterData) -> void:
	select(candidate)

func _refresh_selection() -> void:
	for index in _candidate_buttons.size():
		var chosen := _candidates[index] == _selected
		_candidate_buttons[index].button_pressed = chosen
		_candidate_buttons[index].modulate = SELECTED_COLOR if chosen else IDLE_COLOR
	if _heir_label == null or _selected == null:
		return
	if _heir_cameo != null:
		_heir_cameo.setup(_selected, HEIR_CAMEO_HEIGHT)
	var text := tr("UI_SUCCESSION_HEIR") % _selected.character_name
	if not _candidates.is_empty() and _selected != _candidates[0]:
		text += "\n" + tr("UI_SUCCESSION_PASSED_OVER_WARNING") % _candidates[0].character_name
	_heir_label.text = text

func _on_continue_pressed() -> void:
	if _selected != null:
		heir_chosen.emit(_selected)
	dismissed.emit()
	queue_free()
