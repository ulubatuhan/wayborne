extends SceneTree

## Yolun ışığı (görev 12.2e, taslak y_122e_yol_isik): dört gün evresi × üç
## biyom, taslağın tablosuyla aynı düzende. **Test değil** - PNG basar; tek
## tablo `road_light_shots/tablo.png`. Kervan çizilmiyor (taslakta da yok),
## gece fenerin yol üstündeki dairesi şeridin kendi çizimi.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_road_light.gd

const SHOT_DIR: String = "user://road_light_shots"
const FRAME: Vector2i = Vector2i(960, 540)
const PHASES: Array = [
	["safak", JourneyClock.Phase.DAWN], ["gunduz", JourneyClock.Phase.NOON],
	["aksam", JourneyClock.Phase.EVENING], ["gece", JourneyClock.Phase.NIGHT],
]
const BIOMES: Array[String] = ["meadow", "forest", "mountain"]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = FRAME
	var band := TravelBand.new()
	band.size = Vector2(FRAME)
	get_root().add_child(band)
	var sheet := Image.create(FRAME.x * 2 + 40, FRAME.y * 3 / 2 + 40, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.055, 0.05, 0.06))
	for row in BIOMES.size():
		var found := _terrain_with(BIOMES[row])
		band.set_route(found.terrain)
		band.set_weather(RouteWeather.CLEAR)
		var day: float = found.day
		band.set_route_progress(day / float(found.terrain.total_days), day)
		for col in PHASES.size():
			band.set_phase(PHASES[col][1], 0.5)
			for _frame in 5:
				await process_frame
			var image := get_root().get_texture().get_image().get_region(Rect2i(Vector2i.ZERO, FRAME))
			image.save_png("%s/%s_%s.png" % [SHOT_DIR, BIOMES[row], PHASES[col][0]])
			image.convert(Image.FORMAT_RGB8)
			image.resize(FRAME.x / 2, FRAME.y / 2, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()),
				Vector2i(8 + col * (FRAME.x / 2 + 8), 8 + row * (FRAME.y / 2 + 8)))
	sheet.save_png("%s/tablo.png" % SHOT_DIR)
	quit()

func _terrain_with(biome: String) -> Dictionary:
	for attempt in 600:
		var terrain := RouteTerrain.build("shot_probe_%d" % attempt, 6)
		for segment in terrain.segments:
			if String(segment.biome) != biome:
				continue
			return {"terrain": terrain, "day": (float(segment.from_day) + float(segment.to_day)) * 0.5}
	return {"terrain": RouteTerrain.build("shot_probe_0", 6), "day": 1.0}
