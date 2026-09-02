class_name PulseBar
extends Control

## Moral/stres gibi bir değeri gösteren, "değişince parlayıp sakinleşince
## geri solan" bir çubuk - sürekli göz tırmalamasın diye varsayılan olarak
## soluk durur, bir değişiklik olduğunda tam görünür olur, birkaç saniye
## sonra tekrar soluklaşır (bkz. world_hub.gd).

const IDLE_ALPHA: float = 0.35
const VISIBLE_ALPHA: float = 1.0
const FADE_DELAY: float = 2.5
const FADE_DURATION: float = 1.2
const BAR_SIZE: Vector2 = Vector2(150, 16)

var _value: float = 0.0
var _max_value: float = 100.0
var _label_prefix: String = ""
var _has_value: bool = false

var _background: ColorRect
var _fill: ColorRect
var _label: Label
var _fade_tween: Tween
var _built: bool = false

func _ready() -> void:
	_ensure_built()

## setup()/set_value() de çağırır (bkz. CombatPanel/RecruitPanel deseni) -
## _ready()'nin add_child()'dan hemen sonra senkron çalıştığına
## güvenmiyoruz, çocuklar ilk gerektiğinde kurulur.
func _ensure_built() -> void:
	if _built:
		return
	_built = true

	custom_minimum_size = BAR_SIZE
	modulate.a = IDLE_ALPHA

	_background = ColorRect.new()
	_background.color = Color(0.18, 0.18, 0.2, 0.85)
	_background.size = BAR_SIZE
	add_child(_background)

	_fill = ColorRect.new()
	_fill.color = Color(0.6, 0.75, 0.5)
	_fill.size = Vector2(0.0, BAR_SIZE.y)
	add_child(_fill)

	_label = Label.new()
	_label.size = BAR_SIZE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 11)
	add_child(_label)

func setup(label_prefix: String, fill_color: Color) -> void:
	_ensure_built()
	_label_prefix = label_prefix
	_fill.color = fill_color

## Değer değişmediyse yalnızca metni/doluluğu tazeler, parlamaz - ilk
## çağrıda (henüz değer yokken) da parlamıyor, oyun açılır açılmaz çubuk
## göz tırmalamasın diye.
func set_value(new_value: float, max_value: float = 100.0) -> void:
	_ensure_built()
	var changed := _has_value and not is_equal_approx(new_value, _value)
	_has_value = true
	_value = new_value
	_max_value = maxf(1.0, max_value)

	_fill.size.x = BAR_SIZE.x * clampf(_value / _max_value, 0.0, 1.0)
	_label.text = "%s %d" % [_label_prefix, int(round(_value))]

	if changed:
		_pulse()

func _pulse() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	modulate.a = VISIBLE_ALPHA
	_fade_tween = create_tween()
	_fade_tween.tween_interval(FADE_DELAY)
	_fade_tween.tween_property(self, "modulate:a", IDLE_ALPHA, FADE_DURATION)
