class_name RoadBalloon
extends Control

## Yoldaşın başının üstünde kısa bir söz (görev R0, Y-B01). Figürü izler,
## `LIFETIME` gerçek saniye sonra söner. Tıklamayı yutmaz. Katman yol
## ekranının dünyasında, kervanın üstünde (bkz. road_journey._balloon_layer).

const LIFETIME: float = 4.0
const FADE: float = 0.4
const MAX_WIDTH: float = 300.0
const MIN_WIDTH: float = 60.0
const PAD: Vector2 = Vector2(10, 6)

var _target: WeakRef
var _age: float = 0.0
var _label: Label

func setup(figure: Control, text: String) -> RoadBalloon:
	_target = weakref(figure)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.text = text
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(0, 0)
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", ArtPalette.UI_TEXT_ON_PAGE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	# Kırılan bir etiketin en küçük genişliği tek harf: genişlik metnin kendisinden
	# ölçülür (yoksa balon harf harf dikey bir şeride dönüyordu, uzak görünümde görüldü).
	var font := _label.get_theme_font("font")
	var natural := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x if font != null else MAX_WIDTH
	var width := clampf(natural + 4.0, MIN_WIDTH, MAX_WIDTH)
	_label.size = Vector2(width, 0)
	_label.position = PAD
	return self

func _process(delta: float) -> void:
	_age += delta
	var figure: Control = _target.get_ref() if _target != null else null
	if figure == null or not figure.is_visible_in_tree() or _age >= LIFETIME:
		queue_free()
		return
	modulate.a = clampf((LIFETIME - _age) / FADE, 0.0, 1.0)
	var label_size := _label.get_combined_minimum_size()
	size = Vector2(_label.size.x, label_size.y) + PAD * 2.0
	var head := figure.get_global_transform_with_canvas() * Vector2(figure.size.x * 0.5, 0.0)
	var local := get_parent_control().get_global_transform_with_canvas().affine_inverse() * head
	position = local - Vector2(size.x * 0.5, size.y + 6.0)
	queue_redraw()

func _draw() -> void:
	draw_style_box(_box(), Rect2(Vector2.ZERO, size))
	var tip := Vector2(size.x * 0.5, size.y)
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-6, -1), tip + Vector2(6, -1), tip + Vector2(0, 7)]), PAPER)

const PAPER: Color = Color(0.93, 0.88, 0.76, 0.94)

static func _box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PAPER
	box.border_color = Color(0.17, 0.12, 0.09, 0.8)
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	return box
