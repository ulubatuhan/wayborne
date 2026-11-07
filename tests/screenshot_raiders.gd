extends SceneTree

## Yol kesenlerin ekran doğrulaması (Y-K01, kullanıcı kararı 2026-11-07).
## **Test değil** - PNG basar: üç kart ve blöfü tutmayınca açılan pusu
## savaşı. Yapısal test kartın kurulduğunu görür; ekran görüntüsü üç yolun
## da okunduğunu ve blöfün sebebiyle kilitlendiğini görür.
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_raiders.gd

const SHOT_DIR: String = "user://raider_shots"
const VIEW_SIZE: Vector2i = Vector2i(1600, 900)
const CARDS: Array = ["evt_deserter_levy", "evt_cargo_toll", "evt_road_ultimatum"]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW_SIZE
	await process_frame
	var settings := get_root().get_node_or_null("UserSettings")
	if settings != null:
		settings.call("set_locale", "tr")
	for card_id in CARDS:
		await _shoot(String(card_id), true)
	# Yükü olmayan kervan: blöf kilitli, sebebi yazıyor.
	await _shoot("evt_road_ultimatum", false, "_boş")
	quit()

## Yol ekranı GameState'in oturumunu okur - buradan kurulan ayrı bir
## GameSession ekrana hiç ulaşmaz (ilk denemede kart "verecek yükün yok"
## yazdı, çünkü yük başka bir oturumdaydı).
func _session(_with_cargo: bool) -> GameSession:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	session.journey_destination_id = ""
	session.journey_days_remaining = 0
	session.journey_total_days = 0
	session.start_playthrough(
		CharacterData.create("Veysel", CultureCatalog.VALLEY, CharacterStats.new()), rng
	)
	return session

## Yük seferden SONRA konur: `start_journey` kervanı plandan yeniden kurar.
func _load_cargo(session: GameSession) -> void:
	for item_id in ["test_grain", "honey", "test_cloth", "jewelry"]:
		var item := ItemCatalog.get_item(String(item_id))
		if item != null:
			session.add_to_cargo_or_bag(item, 5)

func _shoot(card_id: String, with_cargo: bool, suffix: String = "") -> void:
	var session := _session(with_cargo)
	var origin := WorldMapData.get_location_by_id(session.current_location_id)
	var route: TravelRoute = null
	for candidate in WorldMapData.get_routes_from(origin.location_id):
		if session.is_route_open(candidate):
			route = candidate
			break
	if route == null:
		return
	var days := session.get_route_travel_days(route)
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	var plan := CaravanPlan.new(destination, days, session.get_wagon_capacity(), 1)
	plan.caravan_party_size = session.get_party().size()
	session.start_journey(destination.location_id, days, 0.6, plan)
	if with_cargo:
		_load_cargo(session)
	else:
		# Boş kervan: blöfün verecek bir şeyi yok, kilit sebebiyle görünmeli.
		var strip := RandomNumberGenerator.new()
		strip.seed = 1
		session.plunder_cargo(1.0, strip, false)

	var screen: Node = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	var event: GameEvent = EventCatalog.get_event(card_id)
	if event == null:
		screen.queue_free()
		return
	screen.call("_present_event", event)
	await _settle()
	_save("%s%s.png" % [card_id, suffix])
	screen.queue_free()
	await _settle()

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	get_root().get_texture().get_image().save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  %s" % file_name)
