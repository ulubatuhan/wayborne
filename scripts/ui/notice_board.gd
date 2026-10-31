class_name NoticeBoard
extends PanelContainer

## Loncanın İlan Panosu (görev Y-C35, kullanıcı notu 2026-10-31: "Bir pano
## görmek istiyorum burada"). İlanlar bir listede değil, tahta bir panoya
## çivilenmiş plakalar: her biri biraz eğri, tepesinde bir çivi. Plaka kitin
## onaylı parşömen plakası (`WaybookTheme.plate_panel`, mürekkep yazı); eski
## G8 kâğıdı değil (kullanıcı onu araç ipucunda çirkin bulmuştu, bkz.
## kurallar-arayuz). Tahta soğuk ve soluk: ışığı loncanın mumundan alıyor
## sayılır, kendisi sıcak değil (tek sıcak kaynak). El çizimi gelince tahta
## `ARY-ilan_panosu`'nun `pano` katmanı olur.

const CARD_SIZE: Vector2 = Vector2(330, 178)
const TILT_DEGREES: float = 2.6
const WOOD: Color = Color(0.20, 0.17, 0.15)
const WOOD_DARK: Color = Color(0.13, 0.11, 0.10)
const WOOD_GRAIN: Color = Color(0.25, 0.22, 0.19)
const NAIL: Color = Color(0.36, 0.35, 0.34)
const PLANK_HEIGHT: float = 64.0
const RUSH_INK: Color = Color(0.48, 0.13, 0.10)

var cards: HFlowContainer = HFlowContainer.new()

func _init() -> void:
	var margin := StyleBoxEmpty.new()
	margin.content_margin_left = 22
	margin.content_margin_right = 22
	margin.content_margin_top = 22
	margin.content_margin_bottom = 26
	add_theme_stylebox_override("panel", margin)
	cards.add_theme_constant_override("h_separation", 18)
	cards.add_theme_constant_override("v_separation", 20)
	add_child(cards)
	# Boş pano da bir pano: en az iki sıra ilanlık tahta görünür.
	custom_minimum_size = Vector2(0, CARD_SIZE.y * 2.0 + 20 + 48)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

## Bir ilanı panoya çiviler. `seed` eğikliği belirler: aynı ilan her
## açılışta aynı açıyla asılı durur.
func pin(content: Control, seed: int, urgent: bool = false) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = CARD_SIZE
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", WaybookTheme.plate_panel())
	plate.size = CARD_SIZE - Vector2(8, 8)
	plate.position = Vector2(4, 6)
	plate.pivot_offset = plate.size * 0.5
	plate.rotation_degrees = tilt_for(seed)
	# Plaka sabit genişlikte: yazı sarılır, plaka komşusunun üstüne taşmaz.
	content.custom_minimum_size.x = CARD_SIZE.x - 8 - 36
	plate.add_child(content)
	ink(content, urgent)
	slot.add_child(plate)
	var nail := _Nail.new()
	nail.position = Vector2(CARD_SIZE.x * 0.5 - 6, 0)
	slot.add_child(nail)
	cards.add_child(slot)
	return slot

## Tohumdan eğiklik: -TILT..+TILT derece.
static func tilt_for(seed: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("notice|%d" % seed)
	return rng.randf_range(-TILT_DEGREES, TILT_DEGREES)

## Plakanın üstündeki yazı mürekkep rengi: temanın kemik rengi parşömende okunmuyor.
static func ink(node: Node, urgent: bool) -> void:
	if node is Label:
		var label := node as Label
		var accent := label.modulate != Color.WHITE
		label.modulate = Color.WHITE
		label.add_theme_color_override("font_color", RUSH_INK if (accent and urgent) else WaybookTheme.KIT_PLATE_TEXT)
	for child in node.get_children():
		ink(child, urgent)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, WOOD)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7741
	var y := 0.0
	while y < size.y:
		var h := minf(PLANK_HEIGHT, size.y - y)
		draw_rect(Rect2(0, y, size.x, h), WOOD.darkened(rng.randf_range(0.0, 0.18)))
		for _i in 3:
			var gy := y + rng.randf_range(8.0, h - 6.0)
			draw_line(Vector2(0, gy), Vector2(size.x, gy + rng.randf_range(-4.0, 4.0)), Color(WOOD_GRAIN, 0.35), 1.0)
		draw_line(Vector2(0, y), Vector2(size.x, y), WOOD_DARK, 2.0)
		y += PLANK_HEIGHT
	# Eski ilanlardan kalan çivi delikleri ve yırtık köşeler.
	for _i in int(size.x * size.y / 26000.0):
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		draw_circle(p, 1.6, WOOD_DARK)
	draw_rect(rect, WOOD_DARK, false, 6.0)

class _Nail extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(12, 12)
		size = Vector2(12, 12)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(Vector2(6, 7), 5.0, Color(0.0, 0.0, 0.0, 0.35))
		draw_circle(Vector2(6, 6), 4.5, NoticeBoard.NAIL)
		draw_circle(Vector2(5, 5), 1.6, NoticeBoard.NAIL.lightened(0.35))
