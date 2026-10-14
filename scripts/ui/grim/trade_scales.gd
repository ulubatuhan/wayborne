class_name TradeScales
extends Control

## Pazarlığın ortası bir terazi: sol kefe tüccarın istediği, sağ kefe senin
## verdiğin. Kol hangi tarafa eğiliyorsa anlaşma o tarafa ağır basıyor -
## bir sayı karşılaştırmasının nesne hâli. Sayılar kefelerin altında yazılı
## kalıyor (sayısal şeffaflık); kolun açısı aynı farkın ikinci okuması.

const MAX_TILT: float = 0.32
const TILT_GAIN: float = 0.9
const SETTLE_SPEED: float = 6.0

var asking: float = 100.0
var offered: float = 100.0
var _angle: float = 0.0

func _init() -> void:
	custom_minimum_size = Vector2(320, 300)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_values(ask: float, offer: float, snap: bool = false) -> void:
	asking = ask
	offered = offer
	if snap:
		_angle = beam_angle(asking, offered)
	queue_redraw()

## Kolun açısı (radyan). Pozitif: sağ kefe (teklif) ağır basıyor. Fark
## göreli ölçülüyor - 10 sikkelik fark 20'lik malda büyük, 2000'likte değil.
static func beam_angle(left_value: float, right_value: float) -> float:
	var heavier := maxf(maxf(left_value, right_value), 1.0)
	return clampf((right_value - left_value) / heavier * TILT_GAIN, -MAX_TILT, MAX_TILT)

func _process(delta: float) -> void:
	var target := beam_angle(asking, offered)
	_angle = lerpf(_angle, target, clampf(delta * SETTLE_SPEED, 0.0, 1.0))
	queue_redraw()

func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.28)
	var arm := size.x * 0.38
	var iron := ArtPalette.GRIM_IRON.lightened(0.15)
	var rust := ArtPalette.GRIM_RUST
	# Direk ve ayak.
	draw_rect(Rect2(c + Vector2(-4, 0), Vector2(8, size.y * 0.62)), iron)
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - 48, size.y * 0.92), Vector2(c.x + 48, size.y * 0.92),
		Vector2(c.x + 20, size.y * 0.86), Vector2(c.x - 20, size.y * 0.86)]), iron.darkened(0.2))
	# Kol: açı dönen tek eksen.
	var dir := Vector2(cos(_angle), sin(_angle))
	var left_end := c - dir * arm
	var right_end := c + dir * arm
	draw_line(left_end, right_end, rust.lightened(0.1), 6.0)
	draw_line(left_end, right_end, iron.lightened(0.2), 2.0)
	draw_circle(c, 9.0, rust)
	draw_circle(c, 4.0, ArtPalette.GRIM_AMBER.darkened(0.3))
	# İbre: tam ortada durursa denge.
	draw_line(c, c + Vector2(sin(_angle), -cos(_angle)) * 38.0, ArtPalette.GRIM_PARCHMENT, 2.0)
	_draw_pan(left_end, asking, tr("UI_GRIM_SCALES_ASKING"), ArtPalette.GRIM_CRIMSON)
	_draw_pan(right_end, offered, tr("UI_GRIM_SCALES_OFFER"), ArtPalette.GRIM_AMBER)

func _draw_pan(hook: Vector2, amount: float, text: String, coin_tint: Color) -> void:
	var drop := size.y * 0.30
	var pan := hook + Vector2(0, drop)
	var w := size.x * 0.17
	draw_line(hook, pan + Vector2(-w, 0), Color(ArtPalette.GRIM_IRON, 0.9), 1.2)
	draw_line(hook, pan + Vector2(w, 0), Color(ArtPalette.GRIM_IRON, 0.9), 1.2)
	# Sikke yığını: miktarın kaba bir göstergesi, kesin sayı altta.
	var coins := clampi(int(ceil(amount / 25.0)), 1, 9)
	for i in coins:
		var y := pan.y - 4 - i * 4
		draw_rect(Rect2(Vector2(pan.x - 13 + (i % 2) * 3, y), Vector2(24, 4)), coin_tint.darkened(0.15 + 0.05 * (i % 3)))
	draw_colored_polygon(PackedVector2Array([
		pan + Vector2(-w, 0), pan + Vector2(w, 0), pan + Vector2(w * 0.7, 10), pan + Vector2(-w * 0.7, 10)]),
		ArtPalette.GRIM_RUST.darkened(0.1))
	var font := WaybookTheme.get_font()
	var number := "%d" % roundi(amount)
	var nw := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(font, pan + Vector2(-nw * 0.5, 36), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ArtPalette.GRIM_PARCHMENT)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, pan + Vector2(-tw * 0.5, 54), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ArtPalette.GRIM_PARCHMENT_DIM)
