class_name CampActionsPanel
extends CanvasLayer

## Kamp bir karar anı (görev Y-B12): ertesi günün dizilişi (öncü, ortancı,
## artçı) ve akşamın en fazla iki eylemi (nöbet, yaralı sarmak, tamir, av
## hazırlığı, hikâye). Öncü önde olmanın bedelini taşır (stres); yorgun öncü
## gece arkaya alınabilir. Esc ve "Olduğu gibi" dizilişi değiştirmeden kapatır.

signal confirmed(formation: Array, actions: Array)  # [CharacterData|null x3], [String]

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const PANEL_WIDTH: float = 580.0
const ROLE_KEYS: Array[String] = ["DUTY_VANGUARD_NAME", "DUTY_MIDDLE_NAME", "DUTY_REAR_NAME"]
const ACTION_KEYS: Dictionary = {
	"watch": "UI_CAMP_ACT_WATCH", "wounds": "UI_CAMP_ACT_WOUNDS", "repair": "UI_CAMP_ACT_REPAIR",
	"hunt": "UI_CAMP_ACT_HUNT", "tales": "UI_CAMP_ACT_TALES",
}

var _session: GameSession
var _card: PanelContainer
var _backdrop: ColorRect
var _pickers: Array[OptionButton] = []
var _checks: Dictionary = {}
var _done: bool = false

func setup(session: GameSession) -> CampActionsPanel:
	_session = session
	return self

func _ready() -> void:
	layer = 64
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	_backdrop = ColorRect.new()
	_backdrop.color = BACKDROP_COLOR
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	center.add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_card.add_child(col)
	var title := Label.new()
	title.text = tr("UI_CAMP_PANEL_TITLE")
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	col.add_child(title)
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.text = tr("UI_CAMP_FORMATION_HINT") % GameSession.VANGUARD_DAILY_STRESS
	col.add_child(hint)
	var party := _session.get_party()
	for i in DutyCatalog.ROLES.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.text = tr(ROLE_KEYS[i])
		label.custom_minimum_size = Vector2(120, 0)
		row.add_child(label)
		var picker := OptionButton.new()
		picker.add_item(tr("UI_CAMP_ROLE_EMPTY"))
		var holder := _session.get_duty_holder(DutyCatalog.ROLES[i])
		for j in party.size():
			var who := party[j]
			picker.add_item("%s (%s %d)" % [who.character_name, tr("UI_CAMP_STRESS_SHORT"), who.stress])
			if who == holder:
				picker.select(j + 1)
		row.add_child(picker)
		_pickers.append(picker)
		col.add_child(row)
	col.add_child(HSeparator.new())
	var actions_title := Label.new()
	actions_title.text = tr("UI_CAMP_ACTIONS_TITLE") % GameSession.CAMP_ACTION_LIMIT
	col.add_child(actions_title)
	for action in GameSession.CAMP_ACTIONS:
		var check := CheckBox.new()
		check.text = tr(String(ACTION_KEYS[action]))
		check.toggled.connect(func(_on: bool) -> void: _limit_actions())
		_checks[action] = check
		col.add_child(check)
	var confirm := Button.new()
	confirm.text = tr("UI_CAMP_CONFIRM")
	confirm.pressed.connect(_confirm)
	col.add_child(confirm)
	WaybookTheme.present(_card, _backdrop, self)

## İki eylem seçilince ötekiler kilitlenir (kilitli, gizli değil).
func _limit_actions() -> void:
	var chosen := 0
	for action in _checks:
		if (_checks[action] as CheckBox).button_pressed:
			chosen += 1
	for action in _checks:
		var check: CheckBox = _checks[action]
		check.disabled = not check.button_pressed and chosen >= GameSession.CAMP_ACTION_LIMIT

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_confirm()

func _confirm() -> void:
	if _done:
		return
	_done = true
	var party := _session.get_party()
	var formation: Array = []
	var used := {}
	for picker in _pickers:
		var index := picker.selected - 1
		var who: CharacterData = party[index] if index >= 0 and index < party.size() else null
		# Bir kişi iki rolde olamaz: ikinci seçim boş sayılır.
		if who != null and used.has(who):
			who = null
		if who != null:
			used[who] = true
		formation.append(who)
	var actions: Array = []
	for action in _checks:
		if (_checks[action] as CheckBox).button_pressed:
			actions.append(String(action))
	WaybookTheme.dismiss(_card, _backdrop, self, func():
		confirmed.emit(formation, actions)
		queue_free()
	)
