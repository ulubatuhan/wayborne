class_name MapPopup
extends CanvasLayer

## Yolda açılır dünya haritası (görev N24): M tuşu ya da alt şeritteki
## "Harita" düğmesi. Kervan kendi yolunun üstünde, gittiği yöne bakarak
## çiziliyor; zaman bu sırada durur (yol ekranı bunu açık panel sayar).
## Esc, arka plan ve düğme kapatır.

signal closed

const LAYER: int = 60
const MARGIN_SHARE: float = 0.06

var view: WorldMapView
var _root: Control
var _frame: PanelContainer

## `path`: yolun harita çizgisi (çıkıştan hedefe); `progress` 0-1.
func setup(current_location_id: String, destination_id: String, path: PackedVector2Array, progress: float) -> MapPopup:
	layer = LAYER
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			close())
	_root.add_child(backdrop)
	_frame = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL, 0.95)
	box.border_color = Color(ArtPalette.GRIM_AMBER, 0.55)
	box.set_border_width_all(2)
	box.set_content_margin_all(10)
	_frame.add_theme_stylebox_override("panel", box)
	_root.add_child(_frame)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_frame.add_child(col)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	col.add_child(bar)
	var title := Label.new()
	title.text = TranslationServer.translate("UI_ROAD_MAP_TITLE")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title)
	var go := Button.new()
	go.text = TranslationServer.translate("UI_MAP_GO_CARAVAN")
	bar.add_child(go)
	var whole := Button.new()
	whole.text = TranslationServer.translate("UI_MAP_WHOLE")
	bar.add_child(whole)
	var close_button := Button.new()
	close_button.text = TranslationServer.translate("UI_CLOSE")
	close_button.pressed.connect(close)
	bar.add_child(close_button)
	var holder := Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.clip_contents = true
	col.add_child(holder)
	view = WorldMapView.new()
	view.tiles.mouse_filter = Control.MOUSE_FILTER_PASS
	view.current_location_id = current_location_id
	view.focused_location_id = destination_id
	view.journey_path = path
	view.journey_progress = progress
	holder.add_child(view)
	holder.resized.connect(func():
		view.size = holder.size
		if not view.has_meta("framed") and holder.size.x > 10.0:
			view.set_meta("framed", true)
			view.focus_caravan(0.18))
	go.pressed.connect(func(): view.focus_caravan(0.3))
	whole.pressed.connect(func(): view.tiles.reset_view())
	return self

func _ready() -> void:
	_layout()
	get_viewport().size_changed.connect(_layout)

func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	_root.size = screen
	(_root.get_child(0) as Control).size = screen
	var margin := screen * MARGIN_SHARE
	_frame.position = margin
	_frame.size = screen - margin * 2.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func close() -> void:
	closed.emit()
	queue_free()
