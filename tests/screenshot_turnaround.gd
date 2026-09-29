extends SceneTree

## Kervanın geri dönüşünü gerçek yol sahnesinde kare kare basan araç. **Test
## değil** - PNG basar (bkz. screenshot_journey_screen.gd). Dönüşün sırası
## (lider çevirir, emir baştan kuyruğa iner, birimler yerinde döner), kamera
## kayması ve dönüşten sonra sola yürüyen kervan tek bir yapısal testin
## göremeyeceği şeyler.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_turnaround.gd

const SHOT_DIR: String = "user://turnaround_shots"
const VIEW_SIZE: Vector2i = Vector2i(1920, 1080)

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
	# Yolun ortasına: dönüşün kat edilmiş bir yolu olsun.
	screen.set("_days_covered", 2.3)
	await _wait(1.0)
	_save("00_ileri.png")

	# Lider kolonda geriye gidiyor: sola bakmalı, geri geri yürümemeli.
	var caravan: RoadCaravan = screen.get("_caravan")
	screen.set("_leader_target", -caravan.get_column_length() * 0.6)
	screen.set("_has_leader_target", true)
	await _wait(1.2)
	_save("01_lider_geri.png")
	screen.set("_leader_target", 0.0)
	await _wait(3.0)

	screen.call("_on_turn_back_pressed")
	for moment in [0.3, 1.5, 3.5, 5.5, 7.5, 9.0]:
		await _wait_until(caravan, moment)
		_save("02_donus_%04.1f.png" % moment)
	await _wait(2.5)
	_save("03_geri_yolda.png")
	await _wait(2.0)
	_save("04_geri_yolda_2.png")
	quit()

var _turn_clock: float = 0.0

func _wait_until(caravan: RoadCaravan, moment: float) -> void:
	while caravan.is_turning() and float(caravan.get("_turn_time")) < moment:
		await process_frame

func _start_journey() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	var player := CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(player, rng)
	session.owned_wagon_count = 2
	session.wallet.earn(2000)
	session.adopt_dog()
	session.buy_donkey()
	var origin := session.current_location_id
	var route: TravelRoute = WorldMapData.get_routes_from(origin)[0]
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	var plan := CaravanPlan.new(destination, 6)
	session.start_journey(route.to_location_id, 6, 0.3, plan)

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
