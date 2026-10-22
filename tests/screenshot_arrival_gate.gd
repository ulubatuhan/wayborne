extends SceneTree

## Yolun sonu: kervan varılacak yerleşimin kapısına yaklaşıyor (test değil,
## PNG basar). Kapı yolun kendi parçası olmalı - kervanla birlikte kayıyor,
## yolun gerisinde duruyor, geçidi varışta liderin burnunun önünde. İki yol:
## kütük surlu bir kasabaya ve taş surlu bir şehre.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_arrival_gate.gd

const SHOT_DIR: String = "user://arrival_gate_shots"
const VIEW_SIZE: Vector2i = Vector2i(1920, 1080)
## [çıkış, varış]
const ROADS: Array = [["tolvarin", "akavan"], ["akavan", "tolvarin"], ["caramine", "ilsande"]]
## Komut satırı: -- <çıkış> <varış> yalnız o yol.
## Varışa kalan yol, ekran genişliği cinsinden.
const REMAINING_SCREENS: Array = [0.9, 0.45, 0.15, 0.0]
## Yolun başı: çıkıştan bu kadar ekran sonra (kalkış kapısı arkada kalıyor).
const DEPARTED_SCREENS: Array = [0.0, 0.35]
## Saat: öğlen ve gece (meşaleler, geçitten sızan ışık).
const HOURS: Array = [12.0, 22.5]

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW_SIZE
	DisplayServer.window_set_size(VIEW_SIZE)
	await _frames(8)
	var args := OS.get_cmdline_user_args()
	var roads: Array = [[args[0], args[1]]] if args.size() >= 2 else ROADS
	for road in roads:
		await _shoot_road(String(road[0]), String(road[1]))
	quit()

func _shoot_road(origin: String, destination_id: String) -> void:
	_start_journey(origin, destination_id)
	var screen: Control = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _frames(8)
	screen.set("_pace", 0.0)
	var journey: JourneyController = screen.get("_journey")
	var band: TravelBand = screen.get("_band")
	var total := float(journey.journey_length_days)
	for share in DEPARTED_SCREENS:
		journey.days_covered = float(share) * VIEW_SIZE.x / maxf(1.0, band.get_pixels_per_day())
		screen.call("_refresh_time_ui")
		await _frames(30)
		_save("%s_from_%s_%02d.png" % [destination_id, origin, int(round(float(share) * 100.0))])
	for hour in HOURS:
		for share in REMAINING_SCREENS:
			var remaining_days := float(share) * VIEW_SIZE.x / maxf(1.0, band.get_pixels_per_day())
			journey.days_covered = maxf(0.0, total - remaining_days)
			# Saat yol ilerledikten sonra: gün sayısı saati de sürüklüyor.
			_set_hour(screen, float(hour))
			screen.call("_refresh_time_ui")
			await _frames(30)
			_save("%s_%02dh_%02d.png" % [destination_id, int(hour), int(round(float(share) * 100.0))])
	screen.queue_free()
	await _frames(4)

func _set_hour(screen: Control, hour: float) -> void:
	var clock: JourneyClock = screen.get("_clock")
	if clock != null:
		clock.total_hours = floor(clock.total_hours / 24.0) * 24.0 + hour

func _start_journey(origin: String, destination_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var session: GameSession = get_root().get_node_or_null("GameState").call("get_session")
	session.start_playthrough(CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng)
	session.owned_wagon_count = 2
	session.current_location_id = origin
	var destination := WorldMapData.get_location_by_id(destination_id)
	var days := WorldMapData.get_route(origin, destination_id).travel_days
	session.start_journey(destination_id, days, 0.38, CaravanPlan.new(destination, days))

func _frames(count: int) -> void:
	for _frame in count:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
