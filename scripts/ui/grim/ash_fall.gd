class_name AshFall
extends Control

## Ekranın önünden süzülen kül. Parçacık sistemi değil: her pulun konumu
## `flake_position(i, t)` ile saf olarak hesaplanıyor, yani bir ekran
## görüntüsü hangi karede alınırsa alınsın aynı şeyi gösteriyor ve
## "Hareketi Azalt" açıkken zaman dondurulabiliyor.

const COUNT: int = 110
const FALL_SPEED: float = 26.0
const DRIFT: float = 22.0

var density: float = 1.0
var _time: float = 0.0
var _tex: Texture2D

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_tex = GrimTheme.texture("ash_flake.png")

func set_time(t: float) -> void:
	_time = t
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

static func _hash01(i: int, salt: int) -> float:
	return float(hash(i * 7919 + salt * 104729) & 0xFFFF) / 65535.0

## Pulun ekrandaki yeri; ekranın altından çıkınca tepeden yeniden girer.
static func flake_position(i: int, t: float, area: Vector2) -> Vector2:
	var speed := FALL_SPEED * (0.5 + _hash01(i, 1))
	var span := area.y + 40.0
	var y := fposmod(_hash01(i, 2) * span + t * speed, span) - 20.0
	var x := _hash01(i, 3) * area.x + sin(t * (0.3 + _hash01(i, 4)) + i) * DRIFT
	return Vector2(fposmod(x, area.x), y)

func _draw() -> void:
	if _tex == null:
		_tex = GrimTheme.texture("ash_flake.png")
		if _tex == null:
			return
	var n := int(COUNT * density)
	for i in n:
		var p := flake_position(i, _time, size)
		var s := 7.0 + _hash01(i, 5) * 10.0
		var a := 0.25 + _hash01(i, 6) * 0.5
		draw_texture_rect(_tex, Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), false, Color(1, 1, 1, a))
