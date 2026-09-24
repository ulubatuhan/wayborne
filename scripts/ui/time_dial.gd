class_name TimeDial
extends Control

## Yol HUD'unun saat kadranı: üst yarısı güneş, alt yarısı yıldızlar
## (r3_dial), üstünde dönen bir ibre (r3_needle). Öğlen ibre güneşi,
## gece yarısı yıldızları gösteriyor - saatin metni yanında yazılı kalıyor,
## kadran onu okutmuyor, bir bakışta günün neresinde olunduğunu söylüyor.
##
## Sahnesiz (`PulseBar` deseni): `.new()` + `set_hour()`.

const DIAL_FILE: String = "r3_dial.png"
const NEEDLE_FILE: String = "r3_needle.png"
## İbrenin dokusu üstünde ölçüldü: topuzun merkezi ve sivri ucu.
const NEEDLE_PIVOT: Vector2 = Vector2(58.0, 83.0)
const NEEDLE_TIP: Vector2 = Vector2(1.0, 2.0)
## İbrenin boyu kadranın yarıçapına oranla - kadranın kenarını aşmasın.
const NEEDLE_REACH: float = 0.86

var _dial: Texture2D
var _needle: Texture2D
var _hour: float = 12.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial = WaybookTheme.texture(DIAL_FILE)
	_needle = WaybookTheme.texture(NEEDLE_FILE)

func set_hour(hour: float) -> void:
	if is_equal_approx(hour, _hour):
		return
	_hour = hour
	queue_redraw()

## Saat 12 yukarı, saat yönünde dönüyor; 0 aşağı (yıldızlar).
static func angle_for_hour(hour: float) -> float:
	return -PI * 0.5 + (hour - 12.0) / 24.0 * TAU

func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	draw_texture_rect(_dial, Rect2(origin, Vector2(side, side)), false)

	var native := NEEDLE_TIP - NEEDLE_PIVOT
	var scale := side * 0.5 * NEEDLE_REACH / native.length()
	var rotation_angle := angle_for_hour(_hour) - native.angle()
	draw_set_transform(origin + Vector2(side, side) * 0.5, rotation_angle, Vector2(scale, scale))
	draw_texture(_needle, -NEEDLE_PIVOT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
