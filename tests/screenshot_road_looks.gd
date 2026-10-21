extends SceneTree

## Yolun haritaya göre görünüşleri (görev Y-G07): her biyom düz, soğuk (kuzey),
## sıcak (güney) ve ufkunda dağla, öğle ışığında. **Test değil** - PNG basar;
## tek tablo `road_look_shots/tablo.png` (satır biyom, sütun görünüş). Bir
## görünüşün resmi yoksa şerit bir alttakine düşüyor (RoadStrips.fallback_chain),
## yani eksik varyant tabloda düz biyom olarak görünür.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_road_looks.gd

const SHOT_DIR: String = "user://road_look_shots"
const FRAME: Vector2i = Vector2i(960, 540)
const BIOMES: Array[String] = ["steppe", "meadow", "forest", "lake", "marsh", "mountain"]
## [ad, iklim, ufukta dağ]
const LOOKS: Array = [["duz", "", false], ["soguk", "cold", false], ["sicak", "warm", false], ["dag", "", true]]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = FRAME
	var band := TravelBand.new()
	band.size = Vector2(FRAME)
	get_root().add_child(band)
	var cell := FRAME / 2
	var sheet := Image.create(LOOKS.size() * (cell.x + 8) + 8, BIOMES.size() * (cell.y + 8) + 8, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.055, 0.05, 0.06))
	for row in BIOMES.size():
		for col in LOOKS.size():
			var terrain := _terrain(BIOMES[row], String(LOOKS[col][1]), bool(LOOKS[col][2]))
			band.set_route(terrain)
			band.set_weather(RouteWeather.CLEAR)
			band.set_route_progress(0.5, float(terrain.total_days) * 0.5)
			band.set_phase(JourneyClock.Phase.NOON, 0.5)
			for _frame in 5:
				await process_frame
			var image := get_root().get_texture().get_image().get_region(Rect2i(Vector2i.ZERO, FRAME))
			image.save_png("%s/%s_%s.png" % [SHOT_DIR, BIOMES[row], LOOKS[col][0]])
			image.convert(Image.FORMAT_RGB8)
			image.resize(cell.x, cell.y, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(image, Rect2i(Vector2i.ZERO, cell), Vector2i(8 + col * (cell.x + 8), 8 + row * (cell.y + 8)))
	sheet.save_png("%s/tablo.png" % SHOT_DIR)
	quit()

## Tek parçalı bir yol: bütün gün aynı biyom ve görünüş, geçiş karışmasın.
func _terrain(biome: String, climate: String, peaks: bool) -> RouteTerrain:
	var terrain := RouteTerrain.new()
	terrain.route_key = "look_shot"
	terrain.total_days = 6
	terrain.segments.append({
		"biome": biome, "from_day": 0.0, "to_day": 6.0, "stop": RouteTerrain.STOP_NONE,
		"slope": 0.0, "climate": climate, "peaks": peaks,
	})
	return terrain
