extends SceneTree

## G2-G8'in oyuncuya görünen yüzünü ekranda gösteren araç.
## **Test değil** - PNG basar (Y-K01).
##
## Beş kare:
##   01 kervansaray: eksik el ve "El tut" (G2)
##   02 yol durumu: "N el eksik · M vagon sürülemiyor" (G2)
##   03 pazar: "… için gerekir" ve "… bekliyor" notları (G3, G4)
##   04 planlayıcı: tehlike dökümünde kolonun payı (G6)
##   05 vagon atölyesi: eksik malzeme sayıyla (G3)
##
## Koşturmak:
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_g_fixes.gd

const SHOT_DIR: String = "user://g_shots"
const VIEW: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var root := get_root()
	root.size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()
	root.get_node("UserSettings").call("set_locale", "tr")

	await _shoot_city("01_kervansaray_el_tut", "res://scenes/game/caravan_yard.tscn")
	await _shoot_road("02_yolda_eksik_el")
	await _shoot_city("03_pazar_notlari", "res://scenes/game/market.tscn")
	await _shoot_planner("04_planlayici_kolon")
	await _shoot_wagon("05_vagon_atolyesi")
	print("bitti")
	quit()

## Dağılmış, kalabalık bir kervan: eksik el, boşta vagon, uzun kolon.
func _battered_session() -> GameSession:
	var rng := RandomNumberGenerator.new()
	rng.seed = 880606
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	session.journey_destination_id = ""
	session.journey_days_remaining = 0
	session.journey_total_days = 0
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.inherit_father_caravan()
	session.owned_wagon_count = 4
	session._sync_wagon_inventories()
	# İki el aç kalıp gitti: bir vagon boşta.
	session.crew_missing = 3
	session.crew_lost_to_hunger = 5
	session._sync_crew_names()
	session.wallet.balance = 300
	# Birinin bir isteği olsun ki pazar onu yazsın.
	session.people.ensure_city(session.current_location_id, session.total_days_elapsed)
	for person in session.people.city_people(session.current_location_id):
		session.people.offer_chain(String((person as Dictionary).get("id", "")), 0)
	print("  el %d/%d · boşta vagon %d · kolon hızı %.2f · kolon tehlikesi +%.2f · el ücreti %d" % [
		session.get_crew_hands(), session.get_crew_need(), session.get_idle_wagon_count(),
		session.get_convoy_speed_factor(), session.get_convoy_danger_share(),
		session.get_crew_hire_cost(),
	])
	return session

func _shoot_city(file_name: String, scene_path: String) -> void:
	_battered_session()
	var screen: Node = load(scene_path).instantiate()
	get_root().add_child(screen)
	await _settle()
	await _settle()
	_save("%s.png" % file_name)
	screen.queue_free()
	await _settle()

func _shoot_road(file_name: String) -> void:
	var session := _battered_session()
	var origin := WorldMapData.get_location_by_id(session.current_location_id)
	var route: TravelRoute = null
	for candidate in WorldMapData.get_routes_from(origin.location_id):
		if session.is_route_open(candidate):
			route = candidate
			break
	var days := session.get_route_travel_days(route)
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	var plan := CaravanPlan.new(destination, days, session.get_wagon_capacity(), 1)
	plan.caravan_party_size = session.get_party().size()
	plan.crew_hands = session.get_crew_hands()
	session.start_journey(destination.location_id, days, session.get_route_danger(route), plan)
	var screen: Node = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	var card: Node = screen.get("_card_panel")
	if card != null:
		NodeUtil.clear_children(card)
		screen.call("_refresh_modal")
	await _settle()
	_save("%s.png" % file_name)
	screen.queue_free()
	await _settle()

## Vagon atölyesi bir sahne değil, çalışma anında kurulan bir panel
## (bkz. world_hub._open_wagon_panel) - WagonPanel gibi kuruluyor.
func _shoot_wagon(file_name: String) -> void:
	var session := _battered_session()
	var panel := WagonPanel.new()
	get_root().add_child(panel)
	panel.setup(session, 0)
	await _settle()
	await _settle()
	_save("%s.png" % file_name)
	panel.queue_free()
	await _settle()

func _shoot_planner(file_name: String) -> void:
	var session := _battered_session()
	var origin := WorldMapData.get_location_by_id(session.current_location_id)
	for candidate in WorldMapData.get_routes_from(origin.location_id):
		if session.is_route_open(candidate):
			TravelContext.selected_destination_id = candidate.to_location_id
			break
	var screen: Node = load("res://scenes/game/caravan_planner.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	await _settle()
	_save("%s.png" % file_name)
	screen.queue_free()
	await _settle()

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
