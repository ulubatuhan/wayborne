extends SceneTree

## H2'nin ekran doğrulaması (Y-K01): bedel kadro dışına düştüğünde seçenek
## düğmesi **kimin ödeyeceğini** yazıyor mu. **Test değil** - PNG basar.
##
## İki hâl aynı kart için çekilir: yoldaşlı kervan (taşıyıcı yoldaş) ve
## yalnız kervanbaşı (taşıyıcı adı yazılı tayfa eli). Yapısal test adın
## doldurulduğunu görür; ekran görüntüsü düğmede *okunduğunu* görür.
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_bedel.gd

const SHOT_DIR: String = "user://bedel_shots"
const VIEW_SIZE: Vector2i = Vector2i(1600, 900)
## İnanç mahkemesi: "teslim et" seçeneği BEDEL taşıyor ve kart artık kadro
## koşulu istemiyor, yani kadro 1'de de açılıyor.
const CARD: String = "evt_faith_tribunal"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW_SIZE
	await process_frame
	var settings := get_root().get_node_or_null("UserSettings")
	if settings != null:
		settings.call("set_locale", "tr")
	await _shoot("yoldasli", true)
	await _shoot("yalniz", false)
	await _shoot_deserter()
	quit()

func _session(with_companion: bool) -> GameSession:
	var session := GameSession.new(900, 60, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	session.start_playthrough(
		CharacterData.create("Veysel", CultureCatalog.VALLEY, CharacterStats.new()), rng
	)
	if with_companion:
		session.add_to_party(
			CharacterData.create("Sevda", CultureCatalog.NOMAD, CharacterStats.new()))
	else:
		var others: Array[CharacterData] = []
		for member in session.get_party():
			if not member.is_player:
				others.append(member)
		for member in others:
			session.dismiss(member)
	return session

func _shoot(label: String, with_companion: bool) -> void:
	var session := _session(with_companion)
	var origin := WorldMapData.get_location_by_id(session.current_location_id)
	var route: TravelRoute = null
	for candidate in WorldMapData.get_routes_from(origin.location_id):
		if session.is_route_open(candidate):
			route = candidate
			break
	if route == null:
		push_warning("açık yol yok")
		return
	var days := session.get_route_travel_days(route)
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	var plan := CaravanPlan.new(destination, days, session.get_wagon_capacity(), 1)
	plan.caravan_party_size = session.get_party().size()
	plan.crew_hands = session.get_crew_hands()
	session.start_journey(destination.location_id, days, session.get_route_danger(route), plan)
	# Yol ekranı oturumu GameState'ten okur: kurduğumuz kervanı oraya koymazsak
	# ekranda varsayılan demo kervanı görünür.
	var state := get_root().get_node_or_null("GameState")
	if state != null:
		state.call("set_session", session)

	var screen: Node = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	var event: GameEvent = EventCatalog.get_event(CARD)
	if event == null:
		push_warning("kart yok: %s" % CARD)
		screen.queue_free()
		return
	screen.call("_present_event", event)
	await _settle()
	print("  taşıyıcı: %s" % BedelSecici.bearer_name(BedelSecici.RULE_UNSWORN, session))
	_save("%s_%s.png" % [CARD, label])
	screen.queue_free()
	await _settle()

## Y-E13: yolu kesen grubun içindeki tanıdık yüz - kart onun adını okuyor.
func _shoot_deserter() -> void:
	var session := _session(true)
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
	session.start_journey(destination.location_id, days, session.get_route_danger(route), plan)
	session.waiting_enemy = "Tepeli Mert"
	var state := get_root().get_node_or_null("GameState")
	if state != null:
		state.call("set_session", session)
	var screen: Node = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	screen.call("_present_event", EventCatalog.get_event("evt_deserter_face"))
	await _settle()
	_save("evt_deserter_face.png")
	screen.queue_free()
	await _settle()

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  %s" % file_name)
