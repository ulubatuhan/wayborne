extends SceneTree

## U4 ve U6'nın ekran doğrulaması (Y-K01). **Test değil** - PNG basar:
## varıştaki ustalık satırları ve yapacak işi kalmamış şehrin önerisi.
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_retention.gd

const SHOT_DIR: String = "user://retention_shots"
const VIEW_SIZE: Vector2i = Vector2i(1600, 900)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW_SIZE
	await process_frame
	var settings := get_root().get_node_or_null("UserSettings")
	if settings != null:
		settings.call("set_locale", "tr")
	await _shoot_arrival(0, "varis_temiz")
	await _shoot_arrival(3, "varis_ac")
	await _shoot_city()
	await _shoot_planner()
	quit()

func _session() -> GameSession:
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

## Varış özeti: ustalık satırları (kaç gün aç kalındı, kiler kaç gün yeter).
func _shoot_arrival(hungry_days: int, file_name: String) -> void:
	var session := _session()
	var routes := WorldMapData.get_routes_from(session.current_location_id)
	if routes.is_empty():
		return
	var destination := WorldMapData.get_location_by_id(routes[0].to_location_id)
	var days := session.get_route_travel_days(routes[0])
	session.start_journey(destination.location_id, days, 0.3, CaravanPlan.new(destination, days))
	session.journey_hungry_days = hungry_days
	session.journey_days_remaining = 0

	var screen: Node = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	var payout: Dictionary = session.finish_journey()
	screen.call("_render_arrival_summary", payout)
	await _settle()
	_save("%s.png" % file_name)
	screen.queue_free()
	await _settle()

## Yapacak işi kalmamış şehir: panel yine bedelli bir şey öneriyor.
func _shoot_city() -> void:
	var session := _session()
	session.change_provisions(400)
	for offer in session.get_contract_board():
		session.accept_contract(offer)
		break
	var panel := CityBriefPanel.new()
	get_root().add_child(panel)
	panel.setup(session)
	await _settle()
	await _settle()
	_save("sehir_bos_tur.png")
	panel.queue_free()
	await _settle()

## Büyümenin bedeli (U3): kalabalık kervanın planlayıcıda okunan faturası -
## vagon bakımı ve kalabalık kolonun moral eksisi.
func _shoot_planner() -> void:
	var session := _session()
	session.owned_wagon_count = 5
	session._sync_wagon_inventories()
	session._sync_crew_names()
	for i in 3:
		session.add_to_party(CharacterData.create(
			"Yoldaş %d" % (i + 1), CultureCatalog.HIGHLAND, CharacterStats.new()
		))
	for candidate in WorldMapData.get_routes_from(session.current_location_id):
		if session.is_route_open(candidate):
			TravelContext.selected_destination_id = candidate.to_location_id
			break
	var screen: Node = load("res://scenes/game/caravan_planner.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	await _settle()
	_save("buyume_bedeli.png")
	screen.queue_free()
	await _settle()

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	get_root().get_texture().get_image().save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  %s" % file_name)
