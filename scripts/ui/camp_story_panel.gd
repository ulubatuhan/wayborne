class_name CampStoryPanel
extends CanvasLayer

## Kamp ateşinde bir yoldaşın hikâyesi (görev R1 #3, Y-C17). Üç seçenek:
## dinle, sen anlat, uykuya çekil. Esc uykuya çekilmektir (kapatır, alttaki
## ekranı değil). Karar paneli olduğu için yol ekranı onu açık panel sayar.

signal chosen(choice: String)

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const PANEL_WIDTH: float = 560.0

var _teller: CharacterData
var _card: PanelContainer
var _backdrop: ColorRect
var _done: bool = false

func setup(teller: CharacterData) -> CampStoryPanel:
	_teller = teller
	return self

func _ready() -> void:
	layer = 65
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
	col.add_theme_constant_override("separation", 12)
	_card.add_child(col)
	var title := Label.new()
	title.text = tr("UI_STORY_TITLE") % _teller.character_name
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	col.add_child(title)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.text = tr(CampStory.next_key(_teller))
	col.add_child(body)
	for spec in [[CampStory.CHOICE_LISTEN, "UI_STORY_LISTEN"], [CampStory.CHOICE_OWN_TALE, "UI_STORY_OWN_TALE"], [CampStory.CHOICE_SLEEP, "UI_STORY_SLEEP"]]:
		var button := Button.new()
		button.text = tr(String(spec[1]))
		button.pressed.connect(_choose.bind(String(spec[0])))
		col.add_child(button)
	WaybookTheme.present(_card, _backdrop, self)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_choose(CampStory.CHOICE_SLEEP)

func _choose(choice: String) -> void:
	if _done:
		return
	_done = true
	WaybookTheme.dismiss(_card, _backdrop, self, func():
		chosen.emit(choice)
		queue_free()
	)
