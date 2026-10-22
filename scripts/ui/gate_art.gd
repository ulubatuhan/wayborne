class_name GateArt
extends RefCounted

## Bir yerleşimin kapı kesiti (PropArt `gate_<id>`, `gate_cutout.py`): yolun iki
## ucunda ve hub'da aynı çizim. Arkadan öne: surun ardındaki şehir ("town"
## katmanı, pusla, biraz yukarıda ve küçük - yandan dik kamerada sur arkasını
## örterdi), geçidin karanlığı, kanat ya da parmaklık, sur ("body"), gecede
## meşaleler. Kanat ve parmaklık resimde değil, burada çiziliyor: açılıp
## kapanmaları kervanın uzaklığına bağlı.

const TOWN_RAISE: float = 0.30
const TOWN_SCALE: float = 0.80
const TOWN_HAZE: float = 0.30
const PASSAGE_TOP: Color = Color(0.035, 0.03, 0.028)
const PASSAGE_FLOOR: Color = Color(0.16, 0.13, 0.10)
const IRON: Color = Color(0.11, 0.10, 0.10)
const PLANK: Color = Color(0.30, 0.20, 0.12)
const FLAME: Color = Color(1.0, 0.66, 0.28)
## Parmaklık açıkken boyunun bu kadarı surun içine çekilir.
const LIFT_SHARE: float = 0.92
## Kanat açıkken genişliğinin bu kadarına (menteşe yanına) iner.
const SWING_MIN: float = 0.16

const KIND_STONE := "stone"
const KIND_WOOD := "wood"
const KIND_FELT := "felt"

## Surun (body katmanı) metre boyu: ölçek ondan; arkadaki şehir dahil edilirse
## yüksek bir kule bütün kapıyı küçültüyordu.
static func body_height_m(id: String) -> float:
	var tex := PropArt.texture(id, "body")
	if tex == null or not PropArt.has_layer(id, "town"):
		return PropArt.size_m(id).z
	return float(tex.get_height()) / PropArt.ppm(id)

static func has_door(id: String) -> bool:
	return PropArt.info(id).get("pivots", {}).has("door_top")

## Geçidin ekrandaki dikdörtgeni (taban yerde). Kesitte yoksa boş.
static func door_rect(id: String, base: Vector2, k: float) -> Rect2:
	if not has_door(id):
		return Rect2()
	var l := PropArt.pivot(id, "door_l", base, k)
	var r := PropArt.pivot(id, "door_r", base, k)
	var top := PropArt.pivot(id, "door_top", base, k)
	return Rect2(Vector2(l.x, top.y), Vector2(r.x - l.x, base.y - top.y))

## Bütün kesitin ekrandaki sınırı (arkadaki şehir kaydırılmış hâliyle).
static func bounds(id: String, base: Vector2, k: float) -> Rect2:
	var out := PropArt.layer_rect(id, "body", base, k)
	if out.size == Vector2.ZERO:
		return PropArt.bounds(id, base, k)
	var town := PropArt.layer_rect(id, "town", _town_base(id, base, k), k * TOWN_SCALE)
	return out.merge(town) if town.size != Vector2.ZERO else out

static func _town_base(id: String, base: Vector2, k: float) -> Vector2:
	var body := PropArt.layer_rect(id, "body", base, k)
	return base + Vector2(0.0, -body.size.y * TOWN_RAISE)

## `open` 0..1 kanadın açıklığı, `night` 0..1 gecenin payı, `kind` surun
## malzemesi (Location.wall): taşta parmaklık, kütükte iki kanat, keçede yok.
static func draw(
	canvas: CanvasItem, id: String, base: Vector2, k: float, tint: Color, haze: Color,
	open: float, night: float, kind: String
) -> void:
	if PropArt.has_layer(id, "town"):
		var town_tint := tint.lerp(Color(haze, 1.0), TOWN_HAZE)
		town_tint.a = 1.0
		PropArt.draw_layer(canvas, id, "town", _town_base(id, base, k), k * TOWN_SCALE, town_tint)
	var door := door_rect(id, base, k)
	if door.size.x > 1.0 and kind != KIND_FELT:
		_draw_passage(canvas, door, tint, night)
		if kind == KIND_WOOD:
			_draw_doors(canvas, door, tint, open)
		else:
			_draw_portcullis(canvas, door, tint, open)
	elif PropArt.has_layer(id, "gate"):
		PropArt.draw_gate_leaf(canvas, id, base, k, tint, open)
	for layer in PropArt.info(id).get("layers", {}).keys():
		if layer != "town" and layer != "gate":
			PropArt.draw_layer(canvas, id, layer, base, k, tint)
	if night > 0.15 and door.size.x > 1.0:
		_draw_lights(canvas, door, base, kind, clampf((night - 0.15) / 0.5, 0.0, 1.0))

## Geçidin içi: tepede kör karanlık, dipte yolun toprağı; gece şehrin
## sokağından sıcak bir ışık sızar.
static func _draw_passage(canvas: CanvasItem, d: Rect2, tint: Color, night: float) -> void:
	var top := PASSAGE_TOP * Color(tint.r, tint.g, tint.b)
	var floor_c := PASSAGE_FLOOR * Color(tint.r, tint.g, tint.b)
	top.a = 1.0
	floor_c.a = 1.0
	canvas.draw_polygon(PackedVector2Array([d.position, Vector2(d.end.x, d.position.y), d.end, Vector2(d.position.x, d.end.y)]),
		PackedColorArray([top, top, floor_c, floor_c]))
	if night > 0.2:
		ArtDraw.radial_glow(canvas, Vector2(d.get_center().x, d.end.y - d.size.y * 0.2),
			Vector2(d.size.x * 0.55, d.size.y * 0.45), FLAME, 0.55 * night)

static func _draw_portcullis(canvas: CanvasItem, d: Rect2, tint: Color, open: float) -> void:
	var visible := d.size.y * (1.0 - LIFT_SHARE * clampf(open, 0.0, 1.0))
	if visible < 1.0:
		return
	var iron := IRON * Color(tint.r, tint.g, tint.b)
	iron.a = 1.0
	var w := maxf(1.5, d.size.x * 0.045)
	var bars := 6
	for i in range(1, bars):
		var x := d.position.x + d.size.x * float(i) / float(bars)
		canvas.draw_line(Vector2(x, d.position.y), Vector2(x, d.position.y + visible + w), iron, w)
	var rows := int(ceil(visible / (d.size.y / 4.0)))
	for j in range(1, rows + 1):
		var y := d.position.y + minf(visible, d.size.y * float(j) / 4.0)
		canvas.draw_line(Vector2(d.position.x, y), Vector2(d.end.x, y), iron, w * 0.8)

## Kütük kapının iki kanadı: kapalıyken geçidi örter, açılırken menteşesine
## doğru daralır ve gölgeye girer (içeri dönüyor).
static func _draw_doors(canvas: CanvasItem, d: Rect2, tint: Color, open: float) -> void:
	var o := clampf(open, 0.0, 1.0)
	var wood := PLANK * Color(tint.r, tint.g, tint.b)
	wood.a = 1.0
	wood = wood.darkened(0.45 * o)
	var line := wood.darkened(0.45)
	var half := d.size.x * 0.5 * lerpf(1.0, SWING_MIN, o)
	for side in [0, 1]:
		var x0 := d.position.x if side == 0 else d.end.x - half
		var leaf := Rect2(x0, d.position.y, half, d.size.y)
		canvas.draw_rect(leaf, wood, true)
		var planks := 3
		for i in range(1, planks):
			var x := leaf.position.x + leaf.size.x * float(i) / float(planks)
			canvas.draw_line(Vector2(x, leaf.position.y), Vector2(x, leaf.end.y), line, 1.2)
		for t in [0.25, 0.75]:
			var y: float = leaf.position.y + leaf.size.y * float(t)
			canvas.draw_line(Vector2(leaf.position.x, y), Vector2(leaf.end.x, y), IRON, maxf(1.5, d.size.y * 0.03))
		canvas.draw_rect(leaf, line, false, 1.4)

## Gece: taşta ve kütükte geçidin iki yanında birer meşale, keçe obada
## geçidin önünde bir ateş.
static func _draw_lights(canvas: CanvasItem, d: Rect2, base: Vector2, kind: String, s: float) -> void:
	if kind == KIND_FELT:
		var fire := Vector2(d.get_center().x, base.y - d.size.y * 0.05)
		ArtDraw.radial_glow(canvas, fire, Vector2(d.size.x * 1.6, d.size.y * 0.9), FLAME, 0.55 * s)
		canvas.draw_circle(fire + Vector2(0, -d.size.y * 0.05), maxf(2.0, d.size.x * 0.05), Color(FLAME, 0.9 * s))
		return
	for x in [d.position.x - d.size.x * 0.22, d.end.x + d.size.x * 0.22]:
		var p := Vector2(x, d.end.y - d.size.y * 0.72)
		ArtDraw.radial_glow(canvas, p, Vector2(d.size.y * 0.9, d.size.y * 0.9), FLAME, 0.5 * s)
		canvas.draw_line(p + Vector2(0, d.size.y * 0.04), p + Vector2(0, d.size.y * 0.16), IRON, maxf(1.5, d.size.x * 0.04))
		var flame := PackedVector2Array([p + Vector2(-d.size.x * 0.05, 0), p + Vector2(0, -d.size.y * 0.1),
			p + Vector2(d.size.x * 0.05, 0), p + Vector2(0, d.size.y * 0.03)])
		canvas.draw_colored_polygon(flame, Color(FLAME, 0.95 * s))
