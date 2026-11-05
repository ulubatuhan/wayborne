extends SceneTree

## Oyun günlüğü turunun düzelttiklerini ekranda gösteren araç.
## **Test değil** - PNG basar (Y-K01: bir iş ekranda görününce biter).
##
## Dört kare, dört bulgu:
##   01 yolda "Yiyecek ara" emri - aç kervanın elinde bir hamle var mı
##   02 taverna: konaklama ve şölen kapalıysa **sebebini söylüyor mu**
##   03 kilise: bağış kapalıysa sebebini söylüyor mu
##   04 yol ekranı: gecikme kartından sonra kat edilen yol görünüyor mu
##
## Koşturmak:
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_diary_fixes.gd

const SHOT_DIR: String = "user://diary_shots"
const VIEW: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var root := get_root()
	root.size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()
	root.get_node("UserSettings").call("set_locale", "tr")

	await _shoot_road("01_yolda_yiyecek_ara", 0)
	await _shoot_city("02_taverna_sebepler", "res://scenes/game/tavern.tscn", 5)
	await _shoot_city("03_kilise_sebep", "res://scenes/game/church.tscn")
	await _shoot_road("04_gecikmeden_sonra_ilerleme", 5)
	print("bitti")
	quit()

# --- Yol ekranı ---

func _shoot_road(file_name: String, delay_days: int) -> void:
	var session := _fresh_session()
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
	session.start_journey(destination.location_id, days, session.get_route_danger(route), plan)
	# Erzağı dibe çek: arama emri tam da bu anda görünmeli.
	session.change_provisions(-session.get_provisions() + 2)
	if days > 2:
		session.journey_days_remaining -= 2
	if delay_days > 0:
		EventEffectApplier.apply(
			[EventEffect.make(EventEffect.Type.TRAVEL_DAYS, delay_days)], session
		)
	print("  %s: %d/%d gün, erzak %d, arama %d getirir" % [
		file_name, session.get_days_travelled(), session.journey_total_days,
		session.get_provisions(), session.get_forage_yield(session.get_route_terrain_biome() if session.has_method("get_route_terrain_biome") else ""),
	])
	var screen: Node = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	# Arama emri "Emirler" panelinde: o günün kartı varsa kaldır, paneli aç.
	var card: Node = screen.get("_card_panel")
	if card != null:
		NodeUtil.clear_children(card)
		screen.call("_refresh_modal")
	screen.call("_on_orders_toggled", true)
	await _settle()
	await _settle()
	_save("%s.png" % file_name)
	screen.queue_free()
	await _settle()

# --- Şehir ekranları ---

func _shoot_city(file_name: String, scene_path: String, tab_index: int = -1) -> void:
	var session := _fresh_session()
	# Kese boş, kimse yorgun değil: iki ayrı sebep aynı ekranda görünsün.
	session.wallet.balance = 0
	print("  %s: kese %d, stres %d, oda sebebi %s, şölen sebebi %s" % [
		file_name, session.wallet.balance, session.party_stress,
		session.get_lodging_block_reason(), session.get_feast_block_reason(),
	])
	var screen: Node = load(scene_path).instantiate()
	get_root().add_child(screen)
	await _settle()
	# Konaklama ve şölen "Hizmetler" sekmesinde: sekmeyi aç.
	var panel: Node = screen.get("_panel")
	if panel != null and tab_index >= 0:
		panel.call("select_tab", tab_index)
	await _settle()
	await _settle()
	_save("%s.png" % file_name)
	screen.queue_free()
	await _settle()

func _fresh_session() -> GameSession:
	var rng := RandomNumberGenerator.new()
	rng.seed = 770505
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	# Aynı oturum dört kare boyunca yaşıyor: önceki karenin seferi
	# temizlenmezse şehir ekranları "yoldasın" cevabını verir.
	session.journey_destination_id = ""
	session.journey_days_remaining = 0
	session.journey_total_days = 0
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.inherit_father_caravan()
	return session

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
