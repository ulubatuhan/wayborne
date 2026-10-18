class_name WorldMapView
extends Control

## Dünya haritası (görevler N7, N24): karo katmanının (MapTileView) üstünde
## yerleşim işaretleri, yollar ve atlı kervan. Hem şehirdeki harita ekranı
## hem yoldaki açılır harita bunu kullanır.
##
## Adlar haritanın kendi resminde yazılı (her dilde aynı özel ad); bu katman
## yalnızca işaret, yol ve kervan çizer, üstüne gelince adı ipucu olarak verir.

signal location_pressed(location_id: String)
signal location_hovered(location_id: String)

const RIDER_DIR: String = "res://data/assets/map/rider/"
## atan2 açısının 45°'lik dilimi -> yön adı (0 = doğu/sağ, saat yönünde).
const RIDER_ORDER: Array[String] = ["D", "GD", "G", "GB", "B", "KB", "K", "KD"]
const RIDER_SIZE: float = 84.0
const MARKER_RADIUS: Dictionary = {
	SettlementRules.CITY: 13.0, SettlementRules.TOWN: 10.0, SettlementRules.CARAVANSERAI: 9.0,
}
const HIT_RADIUS: float = 18.0
const ROUTE_WIDTH: float = 4.0

var tiles: MapTileView
var _overlay: Control

## Gösterilecek durum: ekran bunları yazar, harita yalnızca çizer.
var current_location_id: String = ""
## Seçili hedef (vurgulu).
var focused_location_id: String = ""
## Buradan çıkan yollar ve renkleri: [{"to": id, "color": Color}].
var routes: Array = []
## Yoldaysa: yolun çizgisi ve ilerleme (0-1); boşsa kervan bulunduğu yerde.
var journey_path: PackedVector2Array = PackedVector2Array()
var journey_progress: float = 0.0
## "Buradasın" halkasının yarıçapı (bkz. world_map.gd SafeZoneRing).
var safe_ring_radius: float = 0.0

var _rider_textures: Dictionary = {}
var _rider_anchor: Dictionary = {}
var _hovered: String = ""

func _init() -> void:
	clip_contents = true
	tiles = MapTileView.new()
	add_child(tiles)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	resized.connect(_on_resized)
	_load_rider()

func _ready() -> void:
	_on_resized()

func _on_resized() -> void:
	# Çapa değil doğrudan boyut (bkz. Art Rules: anchor-preset tuzağı).
	tiles.size = size
	_overlay.size = size

func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_overlay.queue_redraw()

## Kervanın şu anki harita konumu.
func caravan_position() -> Vector2:
	if journey_path.size() >= 2:
		return _point_along(journey_path, journey_progress)
	var here := WorldMapData.get_location_by_id(current_location_id)
	return here.map_position if here != null else Vector2(tiles.map_size) * 0.5

## Kervanı ortalar ("Kervana git").
func focus_caravan(zoom: float = 0.25) -> void:
	tiles.focus_on(caravan_position(), zoom)

func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and motion.button_mask == 0:
		var id := location_at(motion.position)
		if id != _hovered:
			_hovered = id
			tooltip_text = ""
			if not id.is_empty():
				var location := WorldMapData.get_location_by_id(id)
				tooltip_text = location.location_name
				location_hovered.emit(id)
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		var id := location_at(button.position)
		if not id.is_empty() and button.position.distance_to(_press_at) < 6.0:
			location_pressed.emit(id)
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
		_press_at = button.position

var _press_at: Vector2 = Vector2(-1000, -1000)

## Ekran noktasının altındaki yerleşim (en yakın, dokunma payıyla) ya da "".
func location_at(screen_point: Vector2) -> String:
	var best := ""
	var best_d := HIT_RADIUS
	for location in WorldMapData.get_locations():
		var d := tiles.map_to_screen(location.map_position).distance_to(screen_point)
		if d <= best_d:
			best = location.location_id
			best_d = d
	return best

# --- Çizim --------------------------------------------------------------------

func _draw_overlay() -> void:
	for entry in routes:
		var path := WorldMapData.get_route_path(current_location_id, String(entry["to"]))
		if path.size() < 2:
			continue
		var pts := PackedVector2Array()
		for p in path:
			pts.append(tiles.map_to_screen(p))
		var colour: Color = entry.get("color", ArtPalette.GRIM_AMBER)
		var focused := String(entry["to"]) == focused_location_id
		_overlay.draw_polyline(pts, Color(0, 0, 0, 0.35), ROUTE_WIDTH + 3.0, true)
		_overlay.draw_polyline(pts, colour, ROUTE_WIDTH + (2.0 if focused else 0.0), true)
	if journey_path.size() >= 2:
		var jp := PackedVector2Array()
		for p in journey_path:
			jp.append(tiles.map_to_screen(p))
		_overlay.draw_polyline(jp, Color(ArtPalette.GRIM_AMBER, 0.85), ROUTE_WIDTH, true)

	for location in WorldMapData.get_locations():
		var at := tiles.map_to_screen(location.map_position)
		if not Rect2(Vector2(-40, -40), size + Vector2(80, 80)).has_point(at):
			continue
		var r: float = MARKER_RADIUS.get(location.settlement_type, 10.0)
		var ink := Color(0.13, 0.10, 0.08, 0.9)
		var fill := Color(0.93, 0.86, 0.70, 0.9)
		if location.location_id == focused_location_id:
			fill = ArtPalette.GRIM_AMBER
		if location.location_id == _hovered:
			r *= 1.25
		match location.settlement_type:
			SettlementRules.CARAVANSERAI:
				var sq := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0)])
				_overlay.draw_colored_polygon(sq, fill)
				sq.append(sq[0])
				_overlay.draw_polyline(sq, ink, 2.0, true)
			SettlementRules.TOWN:
				_overlay.draw_circle(at, r, fill)
				_overlay.draw_arc(at, r, 0.0, TAU, 24, ink, 2.0, true)
			_:
				_overlay.draw_circle(at, r, fill)
				_overlay.draw_arc(at, r, 0.0, TAU, 28, ink, 2.5, true)
				_overlay.draw_arc(at, r * 0.45, 0.0, TAU, 16, ink, 2.0, true)
		if location.location_id == current_location_id and journey_path.is_empty() and safe_ring_radius > 0.0:
			_overlay.draw_arc(at, safe_ring_radius, 0.0, TAU, 48, Color(ArtPalette.BLOOD, 0.6), 2.5, true)
	_draw_rider()

func _draw_rider() -> void:
	var at := tiles.map_to_screen(caravan_position())
	var dir := "G"
	if journey_path.size() >= 2:
		var ahead := _point_along(journey_path, minf(1.0, journey_progress + 0.02))
		var behind := _point_along(journey_path, maxf(0.0, journey_progress - 0.02))
		dir = rider_direction(ahead - behind)
	var tex: Texture2D = _rider_textures.get(dir)
	if tex == null:
		_overlay.draw_circle(at, 8.0, ArtPalette.BLOOD)
		return
	var anchor: Vector2 = _rider_anchor.get(dir, Vector2(0.5, 0.94))
	var s := RIDER_SIZE
	_overlay.draw_texture_rect(tex, Rect2(at - anchor * s, Vector2(s, s)), false)

## Gidiş vektörünün yönü: en yakın 45°'ye yuvarlanır (harita görüntüleyicisiyle aynı).
static func rider_direction(delta: Vector2) -> String:
	if delta.length() < 0.001:
		return "G"
	var index := int(round(atan2(delta.y, delta.x) / (PI / 4.0)))
	index = ((index % 8) + 8) % 8
	return RIDER_ORDER[index]

## Çizgi boyunca, uzunluk payı kadar ilerideki nokta.
static func _point_along(path: PackedVector2Array, share: float) -> Vector2:
	var total := 0.0
	for i in range(path.size() - 1):
		total += path[i].distance_to(path[i + 1])
	var target := clampf(share, 0.0, 1.0) * total
	for i in range(path.size() - 1):
		var seg := path[i].distance_to(path[i + 1])
		if target <= seg:
			return path[i].lerp(path[i + 1], target / maxf(seg, 0.0001))
		target -= seg
	return path[path.size() - 1]

func _load_rider() -> void:
	var meta = JSON.parse_string(FileAccess.get_file_as_string(RIDER_DIR + "atli_yonler.json"))
	for dir in RIDER_ORDER:
		_rider_textures[dir] = TextureLoader.load_any(RIDER_DIR + "atli_%s.png" % dir)
		if meta is Dictionary and meta.has("yonler") and (meta["yonler"] as Dictionary).has(dir):
			var a: Array = meta["yonler"][dir]["anchor"]
			_rider_anchor[dir] = Vector2(float(a[0]), float(a[1]))
