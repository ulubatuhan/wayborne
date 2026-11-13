extends SceneTree

## Kervanın üstündeki hava (kar ve ıslaklık) - **gerçek yol ekranında**, gün
## ortasında, kervana yakın kırpılmış. Test değil, PNG basar (Y-K01).
##
## `screenshot_road_fx.gd` on hâli sırayla çekiyor ve saat aralarında
## ilerliyor (gece karesi kervanı maviye boyuyor); bu araç yalnız kervanın
## üstüne bakıyor, saati sabit tutuyor ve iki dakikada bitiyor.
##
## Koşturmak:
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_weather_coat.gd

const SHOT_DIR: String = "user://coat_shots"
const VIEW_SIZE: Vector2i = Vector2i(1920, 1080)
const WARM_FRAMES: int = 40
## Kırpma: kervanın baş kısmı (atlı, yürüyen, öküz, vagon).
const CROP := Rect2(0.18, 0.33, 0.44, 0.25)

## ad, hava, kervanın üstündeki su, kar
const STATES: Array = [
	["01_kuru", RouteWeather.OVERCAST, 0.0, 0.0],
	["02_islak", RouteWeather.OVERCAST, 1.0, 0.0],
	["03_karli", RouteWeather.OVERCAST, 0.05, 1.0],
	["04_hafif_kar", RouteWeather.OVERCAST, 0.0, 0.45],
]

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW_SIZE
	DisplayServer.window_set_size(VIEW_SIZE)
	await _settle()
	_start_journey()
	var screen: Control = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	var band: TravelBand = screen.get("_band")
	var caravan: RoadCaravan = screen.get("_caravan")
	# Saat sabit: öğle. Hız sıfır, yoksa kareler arasında akşam olur.
	var clock: JourneyClock = screen.get("_clock")
	clock.total_hours = 12.0
	clock.set_speed_index(0)
	# Teşhis: COAT_MATERIAL=0 ile grubun gölgelendiricisi kapatılır.
	if OS.get_environment("COAT_MATERIAL") == "0":
		var group: CanvasGroup = screen.get("_coat_group")
		group.material = null
	for state in STATES:
		screen.set("_weather", String(state[1]))
		band.set_weather(String(state[1]))
		screen.set("_soaking", {"wet": float(state[2]), "snow": float(state[3])})
		caravan.set_soaking(float(state[2]), float(state[3]), true)
		# Gökten düşen perde kapalı: bakılan şey kervanın üstü, yağış değil.
		var curtains: Array[WeatherCurtain] = screen.get("_curtains")
		for curtain in curtains:
			curtain.set_layers([] as Array[Dictionary])
		band.set_curtain_rain(true)
		for _frame in WARM_FRAMES:
			await process_frame
		_save(String(state[0]))
	print("bitti")
	quit()

func _start_journey() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var state := get_root().get_node_or_null("GameState")
	var session: GameSession = state.call("get_session")
	var player := CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(player, rng)
	session.owned_wagon_count = 2
	session.current_location_id = "rivecande"
	var destination_id := WorldMapData.START_LOCATION_ID
	var destination := WorldMapData.get_location_by_id(destination_id)
	var days := WorldMapData.get_route("rivecande", destination_id).travel_days
	var plan := CaravanPlan.new(destination, days)
	session.start_journey(destination_id, days, 0.38, plan)

func _settle() -> void:
	for _frame in 10:
		await process_frame

func _save(name: String) -> void:
	var image := get_root().get_texture().get_image()
	var w := float(image.get_width())
	var h := float(image.get_height())
	var crop := image.get_region(Rect2i(
		int(w * CROP.position.x), int(h * CROP.position.y),
		int(w * CROP.size.x), int(h * CROP.size.y)
	))
	crop.resize(crop.get_width() * 3 / 2, crop.get_height() * 3 / 2, Image.INTERPOLATE_LANCZOS)
	crop.save_png("%s/%s.png" % [SHOT_DIR, name])
	image.save_png("%s/%s_tam.png" % [SHOT_DIR, name])
	print("  -> ", name)
