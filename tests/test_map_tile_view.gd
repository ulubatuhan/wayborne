extends RefCounted

## Dünya haritası karo katmanı (görev 8.1): seviye seçimi, görünen karolar,
## kaydırma/yakınlaştırma geometrisi, önbellek sınırı ve gerçek bir (küçük,
## sentetik) piramitten yükleme. Gerçek 49 MB'lık karolar depoda değil; tüm
## iddialar karo boyutundan bağımsız yazıldı.

const MAP: Vector2i = Vector2i(16012, 16013)
const TILE: int = 1024
const MAX_LEVEL: int = 4
const FIXTURE_DIR: String = "user://map_tiles_test/"

func suite_name() -> String:
	return "MapTileView"

func run(t) -> void:
	_test_level_choice(t)
	_test_grid_and_visible_tiles(t)
	_test_view_geometry(t)
	_test_cache_and_loading(t)

func _test_level_choice(t) -> void:
	t.eq(MapTileView.level_for_zoom(1.0, MAX_LEVEL), 4, "tam çözünürlükte en ince seviye")
	t.eq(MapTileView.level_for_zoom(2.0, MAX_LEVEL), 4, "iki kat yakında da en ince seviye (üstü yok)")
	t.eq(MapTileView.level_for_zoom(0.5, MAX_LEVEL), 3, "yarım ölçekte bir alt seviye")
	t.eq(MapTileView.level_for_zoom(0.26, MAX_LEVEL), 3, "yarımdan az ama çeyrekten çok: yine yeterli çözünürlük")
	t.eq(MapTileView.level_for_zoom(0.25, MAX_LEVEL), 2, "çeyrek ölçek")
	t.eq(MapTileView.level_for_zoom(0.0001, MAX_LEVEL), 0, "çok uzakta tüm harita karosu")
	t.eq(MapTileView.level_for_zoom(0.0, MAX_LEVEL), 0, "sıfır yakınlık güvenli")
	# Seçilen seviyenin çözünürlüğü ekrandan hiçbir zaman düşük değil.
	var ok := true
	for i in range(1, 200):
		var zoom := float(i) * 0.01
		var level := MapTileView.level_for_zoom(zoom, MAX_LEVEL)
		var scale := pow(2.0, float(level - MAX_LEVEL))
		if level < MAX_LEVEL and scale < zoom - 1e-6:
			ok = false
	t.ok(ok, "seçilen seviye ekran çözünürlüğünü karşılıyor (ya da en ince)")

func _test_grid_and_visible_tiles(t) -> void:
	t.eq(MapTileView.grid_size(4, MAP, TILE, MAX_LEVEL), Vector2i(16, 16), "seviye 4: 16x16 karo (görüntüleyicideki 256 dosya)")
	t.eq(MapTileView.grid_size(3, MAP, TILE, MAX_LEVEL), Vector2i(8, 8), "seviye 3: 8x8")
	t.eq(MapTileView.grid_size(0, MAP, TILE, MAX_LEVEL), Vector2i(1, 1), "seviye 0: tek karo")
	var tiles := MapTileView.visible_tiles(4, Rect2(0, 0, 100, 100), MAP, TILE, MAX_LEVEL)
	t.eq(tiles, [Vector2i(0, 0)] as Array[Vector2i], "köşedeki küçük pencere tek karo")
	tiles = MapTileView.visible_tiles(4, Rect2(1000, 1000, 100, 100), MAP, TILE, MAX_LEVEL)
	t.eq(tiles.size(), 4, "karo kesişiminde dört karo")
	tiles = MapTileView.visible_tiles(4, Rect2(-500, -500, 100000, 100000), MAP, TILE, MAX_LEVEL)
	t.eq(tiles.size(), 256, "bütün haritayı kaplayan pencere 256 karo, taşan kenar kırpılıyor")
	tiles = MapTileView.visible_tiles(2, Rect2(0, 0, 16012, 16013), MAP, TILE, MAX_LEVEL)
	t.eq(tiles.size(), 16, "seviye 2 tüm harita 16 karo")

func _test_view_geometry(t) -> void:
	var view := Vector2(1920, 1080)
	var fit := MapTileView.fit_zoom(view, MAP)
	t.almost(fit, 1080.0 / 16013.0, "tüm harita ekrana sığar (kısa kenara göre)")
	var centered := MapTileView.clamp_center(Vector2(-50, 99999), fit, view, MAP)
	t.almost(centered.y, 16013.0 * 0.5, "ekrandan küçük eksen ortalanır")
	var zoomed := MapTileView.clamp_center(Vector2(-50, -50), 1.0, view, MAP)
	t.almost(zoomed.x, 960.0, "yakınken merkez sol sınırda kenetlenir (boşluk göstermez)")
	t.almost(zoomed.y, 540.0, "yakınken merkez üst sınırda kenetlenir")
	zoomed = MapTileView.clamp_center(Vector2(99999, 99999), 1.0, view, MAP)
	t.almost(zoomed.x, 16012.0 - 960.0, "sağ sınır")
	t.almost(zoomed.y, 16013.0 - 540.0, "alt sınır")

	var map_view := MapTileView.new()
	map_view.size = view
	map_view.reset_view()
	t.almost(map_view.zoom, fit, "açılışta tüm harita görünür")
	# Yakınlaşırken imlecin altındaki harita noktası sabit kalır.
	map_view.focus_on(Vector2(8000, 8000), 0.2)
	var anchor := Vector2(400, 300)
	var before := map_view.screen_to_map(anchor)
	map_view.zoom_by(1.25, anchor)
	var after := map_view.screen_to_map(anchor)
	t.ok(before.distance_to(after) < 0.01, "yakınlaştırma imlecin altındaki noktayı yerinde tutar")
	t.ok(map_view.zoom > 0.2, "yakınlaştı")
	map_view.zoom_by(1000.0, anchor)
	t.almost(map_view.zoom, MapTileView.MAX_ZOOM, "yakınlık üst sınırda kalır")
	map_view.zoom_by(0.0001, anchor)
	t.almost(map_view.zoom, fit, "uzaklaşma tüm haritadan öteye geçmez")
	# Kaydırma: ekran piksel farkı kadar harita noktası kayar ve sınırda durur.
	map_view.focus_on(Vector2(8000, 8000), 1.0)
	var c0 := map_view.center
	map_view.pan_by(Vector2(100, 0))
	t.almost(map_view.center.x, c0.x - 100.0, "sağa sürükleme merkezi sola kaydırır")
	map_view.pan_by(Vector2(-1.0e7, 0))
	t.almost(map_view.center.x, 16012.0 - 960.0, "kaydırma harita kenarında durur")
	var rect := map_view.visible_map_rect()
	t.ok(rect.end.x <= 16012.0 + 0.01, "görünen alan haritanın dışına taşmaz")
	map_view.free()

func _test_cache_and_loading(t) -> void:
	# Küçük sentetik piramit: 3 seviye, 8 px'lik karolar, 16x16 harita.
	DirAccess.make_dir_recursive_absolute(FIXTURE_DIR)
	var paths: Array[String] = []
	for level in 3:
		var grid := int(pow(2.0, float(level)))
		DirAccess.make_dir_recursive_absolute("%s%d" % [FIXTURE_DIR, level])
		for y in grid:
			for x in grid:
				var image := Image.create(8, 8, false, Image.FORMAT_RGB8)
				image.fill(Color(float(x) / 4.0, float(y) / 4.0, float(level) / 2.0))
				var path := "%s%d/%d_%d.jpg" % [FIXTURE_DIR, level, x, y]
				image.save_jpg(path, 0.9)
				paths.append(path)
	var view := MapTileView.new()
	view.tile_dir = FIXTURE_DIR
	view.map_size = Vector2i(32, 32)
	view.tile_size = 8
	view.max_level = 2
	t.ok(view.has_tiles(), "piramit var")
	var empty := MapTileView.new()
	empty.tile_dir = "user://yok_boyle_bir_klasor/"
	t.not_ok(empty.has_tiles(), "karo olmayan klasör has_tiles false")
	empty.free()

	t.ok(view.tile(0, 0, 0, true) != null, "seviye 0 karosu yüklenir")
	t.ok(view.tile(2, 3, 3, true) != null, "en ince seviyenin son karosu yüklenir")
	t.ok(view.tile(2, 9, 9, true) == null, "olmayan karo null, çökme yok")
	t.eq(view.cached_tile_count(), 2, "iki karo önbellekte")
	# Kare başına yükleme sınırı: zorlamasız istek, hakkı bitince null döner.
	view._loads_left = 0
	t.ok(view.tile(1, 0, 0) == null, "kare yükleme hakkı bitince zorlamasız karo ertelenir")
	view._loads_left = 1
	t.ok(view.tile(1, 0, 0) != null, "hak varken yüklenir")

	# Önbellek sınırı: en eskisi atılır, son kullanılan korunur.
	view._cache.clear()
	view._order.clear()
	view.tile(0, 0, 0, true)
	for i in MapTileView.CACHE_LIMIT + 5:
		view._cache["x/%d" % i] = view.tile(0, 0, 0, true)
		view._order.append("x/%d" % i)
	view.tile(1, 1, 1, true)
	t.ok(view.cached_tile_count() <= MapTileView.CACHE_LIMIT, "önbellek sınırı aşılmaz (%d)" % view.cached_tile_count())
	view.free()
	for path in paths:
		DirAccess.remove_absolute(path)
	for level in 3:
		DirAccess.remove_absolute("%s%d" % [FIXTURE_DIR, level])
	DirAccess.remove_absolute(FIXTURE_DIR)
