class_name MapTileView
extends Control

## Dünya haritası karo katmanı (görev 8.1). 16012x16013 px'lik harita tek doku
## olarak GPU sınırını zorlar ve gereksiz VRAM tutar; bu yüzden 1024 px'lik
## karo piramidi (`data/assets/map/tiles/<seviye>/<x>_<y>.jpg`, seviye 0 tüm
## harita, en yüksek seviye tam çözünürlük) yakınlığa göre seçilir ve yalnızca
## görünen karolar yüklenir. Eşlemeler saf ve statik (Motion Rules): test aynı
## sayıları okuyor.
##
## Koordinatlar: "harita pikseli" tam çözünürlük görüntüdeki piksel (sol üst 0,0).
## `zoom` ekran pikseli / harita pikseli. Sürükleme kaydırır, tekerlek
## imlecin altındaki noktayı sabit tutarak yakınlaştırır; ekranda +/- düğmeleri
## de gerekir (tuş değil karar kuralı: her kontrolün görünür bir karşılığı) -
## bu bileşen yalnızca `zoom_by`/`pan_by` verir, düğmeleri kullanan ekran koyar.

const DEFAULT_TILE_SIZE: int = 1024
const DEFAULT_MAP_SIZE: Vector2i = Vector2i(16012, 16013)
const DEFAULT_MAX_LEVEL: int = 4
const TILE_DIR: String = "res://data/assets/map/tiles/"
## Önbellekte tutulan en fazla karo (1024x1024 RGB ~3 MB; 48 karo ~150 MB sınırı).
const CACHE_LIMIT: int = 48
## Bir karede yüklenen en fazla karo: kaydırırken kare düşmesin, eksik karo
## daha alçak seviyeden (ya da tüm haritadan) görünür.
const LOADS_PER_FRAME: int = 2
const MAX_ZOOM: float = 2.0
const ZOOM_STEP: float = 1.25

var tile_dir: String = TILE_DIR
var map_size: Vector2i = DEFAULT_MAP_SIZE
var tile_size: int = DEFAULT_TILE_SIZE
var max_level: int = DEFAULT_MAX_LEVEL

## Ekranın ortasındaki harita pikseli ve yakınlık.
var center: Vector2 = Vector2.ZERO
var zoom: float = 0.05

## "seviye/x_y" -> Texture2D; sıra son kullanılana göre (en eskisi başta).
var _cache: Dictionary = {}
var _order: Array[String] = []
var _loads_left: int = 0

func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	reset_view()
	resized.connect(_on_resized)

# --- Saf eşlemeler -----------------------------------------------------------

## Seviye `l` haritayı `2^(l-max)` oranında küçültür. Karo, ekranda en az kendi
## çözünürlüğünde görünsün diye `2^(l-max) >= zoom` olan en küçük seviye seçilir.
static func level_for_zoom(zoom_value: float, max_level_value: int) -> int:
	if zoom_value <= 0.0:
		return 0
	var level := int(ceil(float(max_level_value) + log(zoom_value) / log(2.0) - 1e-6))
	return clampi(level, 0, max_level_value)

## Seviyedeki karo ızgarasının boyutu (sütun, satır).
static func grid_size(level: int, map_size_value: Vector2i, tile_size_value: int, max_level_value: int) -> Vector2i:
	var scale := pow(2.0, float(level - max_level_value))
	return Vector2i(
		int(ceil(ceil(float(map_size_value.x) * scale) / float(tile_size_value))),
		int(ceil(ceil(float(map_size_value.y) * scale) / float(tile_size_value)))
	)

## Harita pikselinde verilen dikdörtgenin dokunduğu karolar.
static func visible_tiles(
	level: int, view: Rect2, map_size_value: Vector2i, tile_size_value: int, max_level_value: int
) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var grid := grid_size(level, map_size_value, tile_size_value, max_level_value)
	var scale := pow(2.0, float(level - max_level_value))
	var span := float(tile_size_value) / scale  # bir karonun harita pikselindeki kenarı
	var x0 := clampi(int(floor(view.position.x / span)), 0, grid.x - 1)
	var x1 := clampi(int(floor(view.end.x / span)), 0, grid.x - 1)
	var y0 := clampi(int(floor(view.position.y / span)), 0, grid.y - 1)
	var y1 := clampi(int(floor(view.end.y / span)), 0, grid.y - 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			tiles.append(Vector2i(x, y))
	return tiles

## Tüm haritanın ekrana tam sığdığı yakınlık.
static func fit_zoom(view_size: Vector2, map_size_value: Vector2i) -> float:
	if map_size_value.x <= 0 or map_size_value.y <= 0:
		return 1.0
	return minf(view_size.x / float(map_size_value.x), view_size.y / float(map_size_value.y))

## Merkezi harita sınırlarında tutar: harita ekranı doldurduğunda kenar boşluk
## göstermez, ekrandan küçükse ortalanır.
static func clamp_center(
	center_value: Vector2, zoom_value: float, view_size: Vector2, map_size_value: Vector2i
) -> Vector2:
	var half := view_size / (2.0 * zoom_value)
	var result := center_value
	for axis in 2:
		var extent := float(map_size_value.x if axis == 0 else map_size_value.y)
		if half[axis] * 2.0 >= extent:
			result[axis] = extent * 0.5
		else:
			result[axis] = clampf(center_value[axis], half[axis], extent - half[axis])
	return result

# --- Görünüm -----------------------------------------------------------------

func min_zoom() -> float:
	return fit_zoom(size, map_size)

func reset_view() -> void:
	zoom = maxf(min_zoom(), 0.0001)
	center = Vector2(map_size) * 0.5
	queue_redraw()

func screen_to_map(screen_pos: Vector2) -> Vector2:
	return center + (screen_pos - size * 0.5) / zoom

func map_to_screen(map_pos: Vector2) -> Vector2:
	return (map_pos - center) * zoom + size * 0.5

func visible_map_rect() -> Rect2:
	var half := size / (2.0 * zoom)
	return Rect2(center - half, half * 2.0)

## Haritada bir noktayı ortalar (kervana git).
func focus_on(map_pos: Vector2, zoom_value: float = -1.0) -> void:
	if zoom_value > 0.0:
		zoom = clampf(zoom_value, min_zoom(), MAX_ZOOM)
	center = clamp_center(map_pos, zoom, size, map_size)
	queue_redraw()

## `anchor` (ekran pikseli) altındaki harita noktası yerinde kalır.
func zoom_by(factor: float, anchor: Vector2) -> void:
	var before := screen_to_map(anchor)
	zoom = clampf(zoom * factor, min_zoom(), MAX_ZOOM)
	center = before - (anchor - size * 0.5) / zoom
	center = clamp_center(center, zoom, size, map_size)
	queue_redraw()

func pan_by(screen_delta: Vector2) -> void:
	center = clamp_center(center - screen_delta / zoom, zoom, size, map_size)
	queue_redraw()

func _on_resized() -> void:
	zoom = clampf(zoom, min_zoom(), MAX_ZOOM)
	center = clamp_center(center, zoom, size, map_size)
	queue_redraw()

# --- Girdi -------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(ZOOM_STEP, button.position)
			accept_event()
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0 / ZOOM_STEP, button.position)
			accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		pan_by(motion.relative)
		accept_event()
		return
	var pinch := event as InputEventMagnifyGesture
	if pinch != null:
		zoom_by(pinch.factor, pinch.position)
		accept_event()
		return
	var drag := event as InputEventPanGesture
	if drag != null:
		pan_by(-drag.delta * 8.0)
		accept_event()

# --- Karolar -----------------------------------------------------------------

func tile_path(level: int, x: int, y: int) -> String:
	return "%s%d/%d_%d.jpg" % [tile_dir, level, x, y]

func has_tiles() -> bool:
	var path := tile_path(0, 0, 0)
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)

func cached_tile_count() -> int:
	return _cache.size()

## Önbellekteki karo ya da yüklenemiyorsa null. Kare başına yükleme sınırı
## aşılmışsa yüklemeyi bir sonraki kareye bırakır (null döner, çizim sürer).
func tile(level: int, x: int, y: int, force: bool = false) -> Texture2D:
	var key := "%d/%d_%d" % [level, x, y]
	if _cache.has(key):
		_order.erase(key)
		_order.append(key)
		return _cache[key]
	if not force and _loads_left <= 0:
		return null
	_loads_left -= 1
	var tex := TextureLoader.load_any(tile_path(level, x, y))
	if tex == null:
		return null
	_cache[key] = tex
	_order.append(key)
	while _order.size() > CACHE_LIMIT:
		var oldest: String = _order.pop_front()
		_cache.erase(oldest)
	return tex

func _process(_delta: float) -> void:
	_loads_left = LOADS_PER_FRAME
	# Karo yüklemek çizimi tetikler: eksik karolar sırayla dolar.
	if is_visible_in_tree():
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.09, 0.08))
	var view := visible_map_rect()
	# Önce tüm harita (seviye 0), sonra daha ince seviyeler: ince karo henüz
	# yüklenmediyse boşluk değil bulanık harita görünür.
	var wanted := level_for_zoom(zoom, max_level)
	var levels: Array[int] = [0]
	for level in [wanted - 1, wanted]:
		if level > 0 and not levels.has(level):
			levels.append(level)
	for level in levels:
		var scale := pow(2.0, float(level - max_level))
		var span := float(tile_size) / scale
		for t in visible_tiles(level, view, map_size, tile_size, max_level):
			var tex := tile(level, t.x, t.y, level == 0)
			if tex == null:
				continue
			var origin := map_to_screen(Vector2(float(t.x) * span, float(t.y) * span))
			# Kenardaki karo tam kare olmayabilir: gerçek boyu kullanılıyor.
			var size_map := Vector2(tex.get_size()) / scale
			draw_texture_rect(tex, Rect2(origin, size_map * zoom), false)
