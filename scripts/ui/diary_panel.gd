class_name DiaryPanel
extends CanvasLayer

## Günün satırı (görev Y-B08): akşam kampının son anı. Günün en ağır izinden
## üç cümle; oyuncu birini deftere yazar ya da o gün hiçbirini. Cümleler
## edebi, sayısız (Y-H03); seçmek düzeltmektir - kâtip yazar, kervanbaşı
## hangisinin kalacağına karar verir. Esc "bugün yazma"dır, alttaki ekranı
## kapatmaz. Karar paneli olduğu için yol ekranı onu açık panel sayar.

signal chosen(key: String, args: Array)

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const PANEL_WIDTH: float = 620.0

var _candidates: Array[Dictionary] = []
var _card: PanelContainer
var _backdrop: ColorRect
var _done: bool = false

func setup(candidates: Array[Dictionary]) -> DiaryPanel:
	_candidates = candidates
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
	title.text = tr("DIARY_PANEL_TITLE")
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = ArtPalette.GOLD
	col.add_child(title)
	var hint := Label.new()
	hint.text = tr("DIARY_PANEL_HINT")
	hint.modulate = ArtPalette.BONE_DIM
	col.add_child(hint)
	for candidate in _candidates:
		col.add_child(_sentence_button(String(candidate.get("text", "")),
			String(candidate.get("key", "")), candidate.get("args", [])))
	var skip := Button.new()
	skip.text = tr("DIARY_SKIP")
	skip.pressed.connect(_choose.bind("", []))
	col.add_child(skip)
	WaybookTheme.present(_card, _backdrop, self)

## Cümle uzun olabilir: Godot 4.2'nin düğmesi metni sarmıyor, sarılan bir
## etiket düğmenin içinde duruyor ve düğmenin boyunu o belirliyor.
const SENTENCE_PAD: Vector2 = Vector2(14.0, 9.0)

func _sentence_button(text: String, key: String, args: Array) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(PANEL_WIDTH - 32.0, 0.0)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = SENTENCE_PAD.x
	label.offset_right = -SENTENCE_PAD.x
	label.offset_top = SENTENCE_PAD.y
	label.offset_bottom = -SENTENCE_PAD.y
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(label)
	label.minimum_size_changed.connect(func():
		button.custom_minimum_size.y = label.get_combined_minimum_size().y + SENTENCE_PAD.y * 2.0)
	button.pressed.connect(_choose.bind(key, args))
	return button

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_choose("", [])

func _choose(key: String, args: Array) -> void:
	if _done:
		return
	_done = true
	WaybookTheme.dismiss(_card, _backdrop, self, func():
		chosen.emit(key, args)
		queue_free()
	)
