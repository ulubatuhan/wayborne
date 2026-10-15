class_name SmokeWisps
extends Control

## Ekranın altından yükselen duman: üst üste binen, yavaşça kayıp genişleyen
## yarı saydam elipsler. AshFall gibi saf bir zaman fonksiyonu.

const COUNT: int = 16
const RISE_SECONDS: float = 14.0

var _time: float = 0.0

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_time(t: float) -> void:
	_time = t
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

## Bir duman topağının ömür payı 0..1 (0 doğar, 1 söner).
static func puff_age(i: int, t: float) -> float:
	return fposmod(t / RISE_SECONDS + float(i) / COUNT, 1.0)

static func puff_alpha(age: float) -> float:
	return sin(age * PI) * 0.10

func _draw() -> void:
	for i in COUNT:
		var age := puff_age(i, _time)
		var x := size.x * (0.05 + 0.9 * fposmod(float(i) * 0.618, 1.0)) + sin(_time * 0.2 + i) * 40.0 + age * 80.0
		var y := size.y * (1.05 - age * 0.75)
		var r := Vector2(90.0, 40.0) * (0.6 + age * 1.8)
		ArtDraw.ellipse(self, Vector2(x, y), r, Color(ArtPalette.GRIM_ASH.darkened(0.45), puff_alpha(age)))
