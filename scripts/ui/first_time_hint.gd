class_name FirstTimeHint
extends CanvasLayer

## İlk seferin içine yayılmış öğretim (görev Y-H01). Dört konuluk panel
## yerine altı konu, her biri ilk karşılaşıldığı anda tek cümleyle: ekranın
## üstünde iğneli bir kâğıt fişi (`SlipPanel`), tıklayınca ya da birkaç saniye
## sonra kalkar. Gösterildiği oturumun bayrağıyla bir kez (kayıtta); yardım
## düğmesi eski paneli hâlâ açar.

const TRADE: String = "trade"
const CONTRACT: String = "contract"
const PLANNER: String = "planner"
const ATTENTION: String = "attention"
const MEAL: String = "meal"
const COMBAT: String = "combat"

## Anahtarlar ve bayraklar tam yazılı (Localization Rules).
const TEXT_KEYS: Dictionary = {
	TRADE: "HINT_TRADE", CONTRACT: "HINT_CONTRACT", PLANNER: "HINT_PLANNER",
	ATTENTION: "HINT_ATTENTION", MEAL: "HINT_MEAL", COMBAT: "HINT_COMBAT",
}
const FLAGS: Dictionary = {
	TRADE: "hint_trade", CONTRACT: "hint_contract", PLANNER: "hint_planner",
	ATTENTION: "hint_attention", MEAL: "hint_meal", COMBAT: "hint_combat",
}
const SHOW_SECONDS: float = 9.0
const WIDTH: float = 620.0

var topic: String = ""
var _slip: PanelContainer

## Konu daha önce gösterilmediyse gösterir ve işaretler; gösterdiyse `true`.
static func show_once(host: Node, session: GameSession, which: String) -> bool:
	if host == null or session == null or not FLAGS.has(which):
		return false
	var flag := String(FLAGS[which])
	if session.has_flag(flag):
		return false
	session.set_flag(flag)
	var hint := FirstTimeHint.new()
	hint.topic = which
	host.add_child(hint)
	return true

func _ready() -> void:
	layer = 70
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.offset_top = 24.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_slip = PanelContainer.new()
	_slip.theme_type_variation = WaybookTheme.SLIP_PANEL
	_slip.custom_minimum_size = Vector2(WIDTH, 0.0)
	_slip.gui_input.connect(_on_slip_input)
	center.add_child(_slip)
	var label := Label.new()
	label.theme_type_variation = WaybookTheme.PAGE_LABEL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = tr(String(TEXT_KEYS.get(topic, "")))
	_slip.add_child(label)
	if is_inside_tree():
		get_tree().create_timer(SHOW_SECONDS).timeout.connect(_close)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _on_slip_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()

func _close() -> void:
	if is_queued_for_deletion():
		return
	queue_free()
