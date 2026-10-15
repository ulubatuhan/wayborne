class_name GrimTownView
extends Control

## Şehir merkezi, Darkest Dungeon düzeninde: yandan bakılan, katmanlı bir
## kasaba sokağı; her mekân bir bina. Üstüne gelinen bina fenerle aydınlanır,
## öbürleri karanlığa çekilir; tıklayınca bağlam menüsü açılır.
##
## `venue_pressed(scene_path)` CityView ile aynı sinyal - city_map.gd onu
## değiştirmeden bağlayabilir. Binalar PropArt render'ları (CC0 Quaternius/
## Kenney); hiçbir referans görüntüsünden piksel alınmadı.

signal venue_hovered(index: int)
signal venue_pressed(scene_path: String)
signal venue_menu_requested(index: int, anchor: Vector2)

## Her mekân: başlık anahtarı, hedef sahne, sokaktaki yeri (genişliğin
## payı), eşyalar [id, x payından ofset metre, yükseklik çarpanı, ayna].
const VENUES: Array = [
	{"key": "UI_GRIM_VENUE_YARD", "scene": Nav.CARAVAN_YARD, "x": 0.095,
		"props": [["sawmill", 0.0, 1.0, false], ["covered_wagon", 1.2, 1.0, false], ["hay", 4.6, 1.0, false]]},
	{"key": "UI_GRIM_VENUE_MARKET", "scene": Nav.ECONOMY, "x": 0.275,
		"props": [["stall_cart", -1.6, 1.0, false], ["market_cart", 1.8, 1.0, true], ["barrels_mv", 3.4, 1.0, false]]},
	{"key": "UI_GRIM_VENUE_GUILD", "scene": Nav.GUILD, "x": 0.45,
		"props": [["house_2", 0.0, 1.0, false]]},
	{"key": "UI_GRIM_VENUE_TAVERN", "scene": Nav.TAVERN, "x": 0.625,
		"props": [["house_1", 0.0, 1.0, true], ["torch", 3.4, 1.0, false]]},
	{"key": "UI_GRIM_VENUE_CHURCH", "scene": Nav.CHURCH, "x": 0.785,
		"props": [["outpost", 0.0, 1.0, false], ["well", 2.8, 1.0, false]]},
	{"key": "UI_GRIM_VENUE_WARDROBE", "scene": Nav.WARDROBE, "x": 0.925,
		"props": [["tent", 0.0, 1.0, false], ["torch", -3.0, 1.0, false]]},
]
const GROUND_SHARE: float = 0.80
## Sokak ölçeği: piksel / metre, ekran yüksekliğinin payı olarak.
const METRE_SHARE: float = 0.042
const DIM_TINT: Color = Color(0.60, 0.58, 0.62)
const LIT_TINT: Color = Color(1.12, 1.02, 0.9)

var hovered: int = -1
var _time: float = 0.0
var _hit_rects: Array[Rect2] = []

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_time(t: float) -> void:
	_time = t
	queue_redraw()

func set_hovered(index: int) -> void:
	if index == hovered:
		return
	hovered = index
	venue_hovered.emit(index)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func metres_to_px() -> float:
	return size.y * METRE_SHARE

func ground_y() -> float:
	return size.y * GROUND_SHARE

## Bir mekânın ekrandaki tıklanabilir dikdörtgeni (bütün eşyalarının birleşimi).
func venue_rect(index: int) -> Rect2:
	if index < 0 or index >= _hit_rects.size():
		return Rect2()
	return _hit_rects[index]

## Bir noktanın hangi mekâna düştüğü; hiçbiri değilse -1. Arkadaki değil
## öndeki kazansın diye sondan başa bakılıyor.
func venue_at(point: Vector2) -> int:
	for i in range(_hit_rects.size() - 1, -1, -1):
		if _hit_rects[i].has_point(point):
			return i
	return -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		set_hovered(venue_at(event.position))
	elif event is InputEventMouseButton and event.pressed:
		var i := venue_at(event.position)
		if i < 0:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			venue_menu_requested.emit(i, _menu_anchor(i))
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			venue_pressed.emit(String(VENUES[i]["scene"]))

func _menu_anchor(i: int) -> Vector2:
	var r := venue_rect(i)
	return Vector2(r.get_center().x, r.position.y)

func _draw() -> void:
	_draw_sky()
	_draw_far_town()
	_draw_ground()
	_hit_rects.clear()
	for i in VENUES.size():
		_hit_rects.append(_draw_venue(i))
	_draw_fog()

func _draw_sky() -> void:
	var gy := ground_y()
	ArtDraw.gradient_band(self, Rect2(0, 0, size.x, gy), Color(0.09, 0.09, 0.11), ArtPalette.GRIM_SLATE.darkened(0.25))
	# Kül bulutunun arkasında ölgün bir güneş: ışık yok değil, boğulmuş.
	var glow := GrimTheme.texture("lantern_glow.png")
	if glow != null:
		var r := size.y * 0.22
		draw_texture_rect(glow, Rect2(Vector2(size.x * 0.72, gy * 0.40) - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 0.85, 0.75, 0.35))
	draw_circle(Vector2(size.x * 0.72, gy * 0.40), size.y * 0.035, Color(0.86, 0.66, 0.50, 0.45))
	ArtDraw.ridge(self, Rect2(0, 0, size.x, gy), gy * 0.72, gy * 0.10, size.x * 0.33, 0.3,
		Color(0.16, 0.17, 0.19), 7)
	ArtDraw.ridge(self, Rect2(0, 0, size.x, gy), gy * 0.82, gy * 0.06, size.x * 0.21, 1.1,
		Color(0.12, 0.12, 0.13), 11)

func _draw_far_town() -> void:
	var gy := ground_y()
	var m := metres_to_px() * 0.34
	var far := Color(0.17, 0.18, 0.21)
	for spec in [["windmill", 0.36, false], ["mill_wooden", 0.56, true], ["house_2", 0.22, false],
			["house_1", 0.70, true], ["sawmill", 0.86, false]]:
		var id := String(spec[0])
		if not PropArt.has(id):
			continue
		var k := m / PropArt.ppm(id)
		var base := Vector2(size.x * float(spec[1]), gy - size.y * 0.10)
		PropArt.draw_all(self, id, base, k, far, bool(spec[2]))
	draw_rect(Rect2(0, gy - size.y * 0.10, size.x, size.y * 0.10), Color(0.10, 0.10, 0.11))
	ArtDraw.gradient_band(self, Rect2(0, gy - size.y * 0.16, size.x, size.y * 0.08), Color(0.3, 0.32, 0.35, 0.0), Color(0.3, 0.32, 0.35, 0.18))

func _draw_ground() -> void:
	var gy := ground_y()
	ArtDraw.gradient_band(self, Rect2(0, gy, size.x, size.y - gy), Color(0.13, 0.11, 0.10), ArtPalette.GRIM_CHARCOAL)
	# Çamurlu sokak: birkaç koyu leke ve tekerlek izi.
	for i in 14:
		var x := fposmod(float(i) * 151.0 + 37.0, size.x)
		ArtDraw.ellipse(self, Vector2(x, gy + 26 + (i % 3) * 18), Vector2(70 + (i % 4) * 22, 7), Color(0, 0, 0, 0.22))
	draw_line(Vector2(0, gy + 62), Vector2(size.x, gy + 58), Color(0, 0, 0, 0.25), 3.0)
	draw_line(Vector2(0, gy + 84), Vector2(size.x, gy + 88), Color(0, 0, 0, 0.25), 3.0)

func _draw_venue(i: int) -> Rect2:
	var spec: Dictionary = VENUES[i]
	var gy := ground_y()
	var m := metres_to_px()
	var cx := size.x * float(spec["x"])
	var lit := i == hovered
	var tint := LIT_TINT if lit else (DIM_TINT if hovered >= 0 else Color(0.9, 0.88, 0.88))
	if lit:
		_draw_light_pool(Vector2(cx, gy))
	var rect := Rect2()
	var first := true
	for p in spec["props"]:
		var id := String(p[0])
		if not PropArt.has(id):
			continue
		var k := m / PropArt.ppm(id) * float(p[2])
		var base := Vector2(cx + float(p[1]) * m, gy)
		ArtDraw.contact_shadow(self, base, PropArt.bounds(id, base, k, bool(p[3])).size.x * 0.9, 0.35)
		PropArt.draw_all(self, id, base, k, tint, bool(p[3]))
		if id == "torch":
			_draw_torch_flame(PropArt.bounds(id, base, k).position + Vector2(PropArt.bounds(id, base, k).size.x * 0.5, 4))
		var b := PropArt.bounds(id, base, k, bool(p[3]))
		rect = b if first else rect.merge(b)
		first = false
	_draw_sign(i, rect, lit)
	return rect

func _draw_light_pool(base: Vector2) -> void:
	var glow := GrimTheme.texture("lantern_glow.png")
	if glow == null:
		return
	var f := LanternGlow.flicker(_time, 3.0)
	var r := size.y * 0.30 * f
	draw_texture_rect(glow, Rect2(base - Vector2(r * 1.3, r * 1.25), Vector2(r * 2.6, r * 1.6)), false,
		Color(1, 1, 1, 0.55))

func _draw_torch_flame(tip: Vector2) -> void:
	var f := LanternGlow.flicker(_time, tip.x)
	var glow := GrimTheme.texture("lantern_glow.png")
	if glow != null:
		var r := 46.0 * f
		draw_texture_rect(glow, Rect2(tip - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 1, 1, 0.7))
	var h := 16.0 * f
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-5, 0), tip + Vector2(0, -h), tip + Vector2(5, 0)]),
		ArtPalette.GRIM_AMBER)

## Binanın üstünde asılı, yırtık bir tabela. Seçili olanın adı kehribar.
func _draw_sign(i: int, rect: Rect2, lit: bool) -> void:
	var font := GrimTheme.title_font()
	var text := tr(String(VENUES[i]["key"]))
	var fs := 22 if lit else 18
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var at := Vector2(rect.get_center().x - w * 0.5, rect.position.y - 18)
	if lit:
		var blot := GrimTheme.texture("ink_blot.png")
		if blot != null:
			draw_texture_rect(blot, Rect2(at + Vector2(-26, -30), Vector2(w + 60, 44)), false, Color(1, 1, 1, 0.9))
	var col := ArtPalette.GRIM_AMBER if lit else Color(ArtPalette.GRIM_PARCHMENT, 0.75)
	draw_string(font, at + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.9))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

## Önde, yere yakın sürünen sis: iki kayan gürültü bandı.
func _draw_fog() -> void:
	var gy := ground_y()
	for band in 2:
		var y := gy + 10.0 + band * 26.0
		var shift := fposmod(_time * (8.0 + band * 5.0), 240.0)
		for j in int(size.x / 240.0) + 2:
			var x := j * 240.0 - shift
			ArtDraw.ellipse(self, Vector2(x, y), Vector2(170, 20 + band * 6), Color(0.55, 0.56, 0.58, 0.06))
