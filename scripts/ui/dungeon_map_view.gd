class_name DungeonMapView
extends Control

## Bir galeri seviyesinin haritası: odalar ve aralarındaki koridorlar
## (`DungeonMap`). Madencinin tebeşirle taşa çizdiği kroki gibi: kemik rengi
## çizgi, koyu zemin; görülmemiş oda soru işareti, görülmemiş koridor kesik
## çizgi. Bulunulan oda altın halkayla, gidilebilecek oda ince halkayla
## işaretli; tıklanınca `room_pressed`.
##
## Oda simgeleri çiziliyor, yazı tipinden çekilmiyor (Art Rules: arayüzün kendi
## küçük işaretleri çizilir).

signal room_pressed(room_id)  # int

const ROOM_RADIUS: float = 26.0
const PAD: Vector2 = Vector2(56.0, 40.0)
const LINE: Color = Color(0.80, 0.78, 0.72)
const LINE_DIM: Color = Color(0.80, 0.78, 0.72, 0.28)
const ROOM_FILL: Color = Color(0.09, 0.09, 0.10, 0.92)
const ROOM_DONE: Color = Color(0.14, 0.14, 0.15, 0.92)
const MARK: Color = Color(0.86, 0.84, 0.78)
const MARK_DONE: Color = Color(0.86, 0.84, 0.78, 0.45)

var level: Dictionary = {}
var current: int = 0
var reachable: Array[int] = []
var _hover: int = -1

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(640.0, 230.0)

func set_level(new_level: Dictionary, here: int, can_reach: Array[int]) -> void:
	level = new_level
	current = here
	reachable = can_reach
	queue_redraw()

func room_center(room: Dictionary) -> Vector2:
	var area := size - PAD * 2.0
	return PAD + Vector2(float(room["x"]) * area.x, float(room["y"]) * area.y)

func room_at(point: Vector2) -> int:
	for room in level.get("rooms", []):
		if room_center(room).distance_to(point) <= ROOM_RADIUS + 6.0:
			return int(room["id"])
	return -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered := room_at((event as InputEventMouseMotion).position)
		if hovered != _hover:
			_hover = hovered
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if reachable.has(hovered) else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var hit := room_at((event as InputEventMouseButton).position)
		if reachable.has(hit):
			room_pressed.emit(hit)
			accept_event()

func _get_tooltip(at_position: Vector2) -> String:
	var hit := room_at(at_position)
	if hit < 0:
		return ""
	var room := DungeonMap.room(level, hit)
	if not bool(room.get("seen", false)):
		return tr("UI_DNG_ROOM_UNSEEN")
	var text := tr(String(DungeonMap.TYPE_KEYS.get(String(room["type"]), "")))
	if bool(room.get("done", false)) and hit != current:
		text += "\n" + tr("UI_DNG_ROOM_DONE")
	return text

func _draw() -> void:
	if level.is_empty():
		return
	var rooms: Array = level.get("rooms", [])
	for link in level.get("links", []):
		var a := DungeonMap.room(level, int(link[0]))
		var b := DungeonMap.room(level, int(link[1]))
		var known := bool(a.get("done", false)) or bool(b.get("done", false))
		_corridor(room_center(a), room_center(b), known)
	for room in rooms:
		_room(room)

func _corridor(a: Vector2, b: Vector2, known: bool) -> void:
	var dir := (b - a).normalized()
	var start := a + dir * ROOM_RADIUS
	var end := b - dir * ROOM_RADIUS
	if known:
		draw_line(start, end, LINE, 3.0, true)
		return
	var length := start.distance_to(end)
	var t := 0.0
	while t < length:
		draw_line(start + dir * t, start + dir * minf(t + 9.0, length), LINE_DIM, 2.0, true)
		t += 16.0

func _room(room: Dictionary) -> void:
	var id := int(room["id"])
	var c := room_center(room)
	var seen := bool(room.get("seen", false))
	var done := bool(room.get("done", false))
	var r := ROOM_RADIUS
	draw_circle(c, r, ROOM_DONE if done else ROOM_FILL)
	draw_arc(c, r, 0.0, TAU, 40, LINE if seen else LINE_DIM, 2.0, true)
	if id == current:
		draw_arc(c, r + 6.0, 0.0, TAU, 48, ArtPalette.GOLD, 3.0, true)
	elif reachable.has(id):
		draw_arc(c, r + 5.0, 0.0, TAU, 48, ArtPalette.GOLD.darkened(0.25) if id == _hover else LINE_DIM, 2.0, true)
	if not seen:
		_question(c)
		return
	_glyph(String(room["type"]), c, MARK_DONE if done and id != current else MARK)

## Görülmemiş oda: soru işareti, iki çizgi ve bir nokta.
func _question(c: Vector2) -> void:
	draw_arc(c + Vector2(0, -5), 7.0, PI * 1.1, PI * 2.25, 12, LINE_DIM, 2.5, true)
	draw_line(c + Vector2(2.5, 1.0), c + Vector2(0, 6.0), LINE_DIM, 2.5, true)
	draw_circle(c + Vector2(0, 12.0), 2.0, LINE_DIM)

func _glyph(type: String, c: Vector2, col: Color) -> void:
	match type:
		DungeonMap.ENTRY:
			# Merdiven ya da ip: iki dikme, üç basamak.
			draw_line(c + Vector2(-6, -12), c + Vector2(-6, 12), col, 2.0, true)
			draw_line(c + Vector2(6, -12), c + Vector2(6, 12), col, 2.0, true)
			for y in [-7, 0, 7]:
				draw_line(c + Vector2(-6, y), c + Vector2(6, y), col, 2.0, true)
		DungeonMap.PASS:
			# Dar geçit: iki kaya arasında kıvrılan yol.
			draw_polyline(PackedVector2Array([c + Vector2(-12, 8), c + Vector2(-4, -6), c + Vector2(4, 6),
				c + Vector2(12, -8)]), col, 2.5, true)
		DungeonMap.FIGHT:
			# Çapraz iki bıçak.
			draw_line(c + Vector2(-11, -11), c + Vector2(11, 11), col, 3.0, true)
			draw_line(c + Vector2(11, -11), c + Vector2(-11, 11), col, 3.0, true)
			draw_line(c + Vector2(-13, -5), c + Vector2(-5, -13), col, 2.0, true)
			draw_line(c + Vector2(13, -5), c + Vector2(5, -13), col, 2.0, true)
		DungeonMap.CACHE:
			# Sandık: gövde ve kapak.
			draw_rect(Rect2(c + Vector2(-11, -3), Vector2(22, 12)), col, false, 2.0)
			draw_arc(c + Vector2(0, -3), 11.0, PI, TAU, 12, col, 2.0, true)
			draw_line(c + Vector2(0, -3), c + Vector2(0, 3), col, 2.0, true)
		DungeonMap.REST:
			# Niş: kemer ve içinde yatan bir çizgi.
			draw_arc(c + Vector2(0, 4), 11.0, PI, TAU, 14, col, 2.0, true)
			draw_line(c + Vector2(-11, 4), c + Vector2(-11, 10), col, 2.0, true)
			draw_line(c + Vector2(11, 4), c + Vector2(11, 10), col, 2.0, true)
			draw_line(c + Vector2(-7, 7), c + Vector2(7, 7), col, 2.5, true)
		DungeonMap.RELIC:
			# Kalıntı: kesme taş ve üstünde kadim oluk.
			draw_rect(Rect2(c + Vector2(-8, -11), Vector2(16, 22)), col, false, 2.0)
			for y in [-5, 1, 7]:
				draw_line(c + Vector2(-4, y), c + Vector2(4, y), col, 1.5, true)
		DungeonMap.STAIR:
			# İniş: aşağı inen basamaklar.
			draw_polyline(PackedVector2Array([c + Vector2(-12, -10), c + Vector2(-5, -10), c + Vector2(-5, -3),
				c + Vector2(2, -3), c + Vector2(2, 4), c + Vector2(9, 4), c + Vector2(9, 11)]), col, 2.5, true)
		DungeonMap.FINAL:
			# Son oda: kapalı bir kapı, kemerli.
			draw_arc(c + Vector2(0, -2), 9.0, PI, TAU, 12, col, 2.5, true)
			draw_line(c + Vector2(-9, -2), c + Vector2(-9, 12), col, 2.5, true)
			draw_line(c + Vector2(9, -2), c + Vector2(9, 12), col, 2.5, true)
			draw_line(c + Vector2(-9, 12), c + Vector2(9, 12), col, 2.5, true)
			draw_line(c + Vector2(-3, 3), c + Vector2(3, 9), col, 2.0, true)
			draw_line(c + Vector2(3, 3), c + Vector2(-3, 9), col, 2.0, true)
