class_name InkMenu
extends VBoxContainer

## Ana menü girdileri: düğme kutusu yok, yalnızca yazı. Üstüne gelince
## arkasına bir mürekkep darbesi yayılır (soldan sağa, `blot_reveal`), sol
## başına kan rengi bir çentik düşer. Seçimi söyleyen şey kutu değil leke -
## kutulu kontroller oyuncu tarafından zaten reddedildi.

signal chosen(index: int)

const ROW_HEIGHT: float = 52.0
const ROW_WIDTH: float = 420.0
const REVEAL_SECONDS: float = 0.22

var _rows: Array[Control] = []
var _hover: Array[float] = []
var _target: Array[float] = []

func setup(entries: Array) -> InkMenu:
	add_theme_constant_override("separation", 2)
	for i in entries.size():
		var row := _make_row(String(entries[i]), i)
		_rows.append(row)
		_hover.append(0.0)
		_target.append(0.0)
		add_child(row)
	return self

## Darbenin görünen payı 0..1 (eğri: hızlı başlar, yavaş oturur).
static func blot_reveal(u: float) -> float:
	var k := clampf(u, 0.0, 1.0)
	return 1.0 - pow(1.0 - k, 3.0)

## Ekran görüntüsü için bir girdiyi üstüne gelinmiş göstermek.
func force_hover(index: int) -> void:
	for i in _hover.size():
		_hover[i] = 1.0 if i == index else 0.0
		_target[i] = _hover[i]
		_rows[i].queue_redraw()

func _make_row(text: String, index: int) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(ROW_WIDTH, ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.draw.connect(_draw_row.bind(row, index))
	var label := GrimTheme.label(text, GrimTheme.HEADING_SIZE + 2, ArtPalette.GRIM_PARCHMENT, true)
	label.position = Vector2(44, 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	row.set_meta("label", label)
	row.mouse_entered.connect(func(): _target[index] = 1.0)
	row.mouse_exited.connect(func(): _target[index] = 0.0)
	row.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			chosen.emit(index))
	return row

func _process(delta: float) -> void:
	for i in _rows.size():
		var step := delta / REVEAL_SECONDS
		var before := _hover[i]
		_hover[i] = move_toward(_hover[i], _target[i], step)
		if before != _hover[i]:
			_rows[i].queue_redraw()

func _draw_row(row: Control, index: int) -> void:
	var reveal := blot_reveal(_hover[index])
	var label: Label = row.get_meta("label")
	label.add_theme_color_override("font_color",
		ArtPalette.GRIM_PARCHMENT.lerp(ArtPalette.GRIM_AMBER, reveal))
	if reveal <= 0.0:
		return
	var tex := GrimTheme.texture("ink_blot.png")
	if tex != null:
		var w := row.size.x * reveal
		row.draw_texture_rect_region(tex, Rect2(Vector2(18, 2), Vector2(w, row.size.y - 4)),
			Rect2(Vector2.ZERO, Vector2(tex.get_width() * reveal, tex.get_height())), Color(1, 1, 1, 0.92))
	row.draw_colored_polygon(PackedVector2Array([
		Vector2(18, row.size.y * 0.5 - 7), Vector2(32, row.size.y * 0.5), Vector2(18, row.size.y * 0.5 + 7)]),
		Color(ArtPalette.GRIM_CRIMSON, reveal))
