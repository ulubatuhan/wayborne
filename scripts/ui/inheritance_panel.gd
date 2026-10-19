class_name InheritancePanel
extends CanvasLayer

## Yeni oyunun ilk sahnesi (görev Y-C14): kervan oyuncunun değil babasınındı.
## Baba hastalanınca kervanı, adını ve borcunu devretti. Defterin ilk satırı
## onun; borç ve vadesi ilk dönemin saati. Onboarding'in üstünde açılır,
## kapanınca onboarding görünür. Mühürlü panel (geri alınmaz bir an).

signal dismissed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.78)
const PANEL_WIDTH: float = 640.0

var _session: GameSession
var _card: PanelContainer
var _backdrop: ColorRect
var _dismissing: bool = false

func setup(session: GameSession) -> InheritancePanel:
	_session = session
	return self

func _ready() -> void:
	layer = 60
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
	_card.theme_type_variation = WaybookTheme.SEAL_PANEL
	_card.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	center.add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	_card.add_child(col)
	var title := Label.new()
	title.text = tr("UI_INHERIT_TITLE")
	title.add_theme_font_size_override("font_size", 24)
	col.add_child(title)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.text = text_for(_session)
	col.add_child(body)
	var take := Button.new()
	take.text = tr("UI_INHERIT_DISMISS")
	take.pressed.connect(_on_take_pressed)
	col.add_child(take)
	take.grab_focus.call_deferred()
	WaybookTheme.present(_card, _backdrop, self)

## Sahnenin metni: babanın adı, borcun tutarı, alacaklı ve vade günü -
## hepsi oturumdan, test bunu okur.
static func text_for(session: GameSession) -> String:
	var debt := session.debts.get_debt(GameSession.FATHER_DEBT_ID)
	var amount := debt.principal if debt != null else 0
	var due := debt.due_day if debt != null else 0
	return TranslationServer.translate("UI_INHERIT_TEXT") % [
		session.get_father_name(), amount,
		TranslationServer.translate(GameSession.FATHER_CREDITOR_KEY), due + 1,
	]

## Devir geri alınmaz: Esc yutulur ama kapatmaz, perde de kapatmaz; yalnızca
## düğme (SuccessionPanel'in kuralı). Yutulmazsa alttaki ekranı kapatırdı.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()

func _on_take_pressed() -> void:
	if _dismissing:
		return
	_dismissing = true
	WaybookTheme.dismiss(_card, _backdrop, self, func():
		dismissed.emit()
		queue_free()
	)
