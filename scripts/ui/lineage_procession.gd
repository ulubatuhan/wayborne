class_name LineageProcession
extends Control

## Soy sonu: defterde üstü çizili adların sahipleri ufukta yürür (görev Y-G23).
## Ortaçağın ölüm dansı geleneğinden: ölenler sıra olup yola devam eder. Her
## siluetin altında adı, üstü çizili. Kervan bitti ama yol bitmedi; onlar hâlâ
## yürüyor. Işık soğuk ve soluk (tek sıcak kaynak kuralı); gökte ateş yok.
## Reduce Motion açıksa sıra yerinde durur.

const MAX_WALKERS: int = 12
const WALK_SPEED: float = 14.0
const SPACING: float = 130.0
const HORIZON: float = 0.70
const STRIDE_HZ: float = 0.9
const SKY_TOP: Color = Color(0.17, 0.18, 0.22)
const SKY_LOW: Color = Color(0.46, 0.48, 0.52)
const GROUND: Color = Color(0.10, 0.10, 0.11)
const SILHOUETTE: Color = Color(0.06, 0.06, 0.07)
const NAME_COLOR: Color = Color(0.80, 0.79, 0.76)

var names: Array[String] = []
var still: bool = false
var _time: float = 0.0

## Defterden yürüyecek adlar: ölüm sırasıyla, her ad bir kez. Ayrılan yoldaş
## yürümez; o ölmedi, yalnızca gitti.
static func names_from(ledger: CaravanLedger) -> Array[String]:
	var out: Array[String] = []
	if ledger == null:
		return out
	for entry in ledger.entries:
		if String(entry.get("kind", "")) != CaravanLedger.KIND_DIED:
			continue
		var name := String(entry.get("name", ""))
		if name.is_empty() or out.has(name):
			continue
		out.append(name)
	return out.slice(maxi(0, out.size() - MAX_WALKERS))

## Bir yürüyenin x'i: sıra sağa yürür, ekrandan çıkan soldan yeniden girer.
static func walker_x(index: int, time: float, width: float, count: int) -> float:
	var span := maxf(width, float(count) * SPACING) + SPACING
	return fposmod(width * 0.5 - float(index) * SPACING + time * WALK_SPEED, span) - SPACING * 0.5

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 230)

func _process(delta: float) -> void:
	if still or not is_visible_in_tree():
		return
	_time += delta
	queue_redraw()

func _draw() -> void:
	var horizon := size.y * HORIZON
	var steps := 18
	for i in steps:
		var u := float(i) / float(steps)
		draw_rect(Rect2(0, horizon * u, size.x, horizon / float(steps) + 1.0), SKY_TOP.lerp(SKY_LOW, u))
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), GROUND)
	var font := get_theme_default_font()
	for i in names.size():
		var x := walker_x(i, _time, size.x, names.size())
		var phase := _time * TAU * STRIDE_HZ + float(i) * 1.7
		_draw_walker(Vector2(x, horizon), phase, i == 0)
		_draw_name(font, names[i], Vector2(x, horizon + 34.0))

func _draw_walker(feet: Vector2, phase: float, leads: bool) -> void:
	var h := 70.0
	var bob := absf(sin(phase)) * 2.0
	var knee := feet + Vector2(0, -h * 0.26 - bob)
	var swing := sin(phase) * h * 0.12
	draw_line(knee, feet + Vector2(swing, 0), SILHOUETTE, 4.0)
	draw_line(knee, feet + Vector2(-swing, 0), SILHOUETTE, 4.0)
	var shoulder := feet + Vector2(2, -h * 0.80 - bob)
	# Pelerin: omuzdan dize, arkası rüzgârla biraz açık. Başı öne eğik.
	draw_colored_polygon(PackedVector2Array([
		shoulder + Vector2(-7, 0), shoulder + Vector2(6, 1), knee + Vector2(8, 2),
		knee + Vector2(-11 - absf(swing) * 0.3, 4),
	]), SILHOUETTE)
	# Sırtta yük: yürüyenler yolun yükünü hâlâ taşıyor.
	draw_colored_polygon(PackedVector2Array([
		shoulder + Vector2(-6, 2), shoulder + Vector2(-16, 6), shoulder + Vector2(-15, 24), shoulder + Vector2(-6, 22),
	]), SILHOUETTE)
	draw_circle(shoulder + Vector2(4, -7), 6.0, SILHOUETTE)
	if leads:
		# Başta yürüyenin değneği.
		draw_line(shoulder + Vector2(9, 6), feet + Vector2(16, 0), SILHOUETTE, 2.5)

func _draw_name(font: Font, text: String, centre: Vector2) -> void:
	if font == null:
		return
	var font_size := 17
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var left := centre - Vector2(width * 0.5, 0)
	draw_string(font, left, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, NAME_COLOR)
	var strike := left.y - float(font_size) * 0.30
	draw_line(Vector2(left.x - 3, strike), Vector2(left.x + width + 3, strike), NAME_COLOR, 1.5)
