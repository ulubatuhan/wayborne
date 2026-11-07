extends SceneTree

## U2'nin ekran doğrulaması (Y-K01): bir olay kartının sonucu ekranda bir
## kişinin ya da bir yerin adını anıyor mu. **Test değil** - PNG basar.
##
## Gerçek yol ekranını kuruyor, gerçek kartı sunuyor, gerçek seçeneğe
## basıyor; günlükteki sonuç satırı ne yazıyorsa onu çekiyor. Yapısal test
## metnin doldurulduğunu görür, ekran görüntüsü *okunduğunu* görür.
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_named_cards.gd

const SHOT_DIR: String = "user://named_card_shots"
const VIEW_SIZE: Vector2i = Vector2i(1600, 900)
## Üç kart: biri kişi anan, biri yer anan, biri ikisi de olan zincir kartı.
const CARDS: Array = ["evt_bandit_ambush", "evt_forgotten_cache", "evt_road_wanderer"]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW_SIZE
	await process_frame
	# Dil ilk await'ten SONRA kuruluyor (bkz. kurallar-test: UserSettings
	# sahne ağacı kurulmadan locale'i geri alıyor).
	var settings := get_root().get_node_or_null("UserSettings")
	if settings != null:
		settings.call("set_locale", "tr")
	for card_id in CARDS:
		await _shoot(String(card_id))
	quit()

func _session() -> GameSession:
	var session := GameSession.new(900, 60, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	session.start_playthrough(
		CharacterData.create("Veysel", CultureCatalog.VALLEY, CharacterStats.new()), rng
	)
	session.add_to_party(CharacterData.create("Sevda", CultureCatalog.NOMAD, CharacterStats.new()))
	session.add_to_party(CharacterData.create("Demir", CultureCatalog.HIGHLAND, CharacterStats.new()))
	return session

func _shoot(card_id: String) -> void:
	var session := _session()
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

	var screen: Node = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()

	var event: GameEvent = EventCatalog.get_event(card_id)
	if event == null:
		push_warning("kart yok: %s" % card_id)
		screen.queue_free()
		return
	screen.call("_present_event", event)
	await _settle()
	_save("%s_kart.png" % card_id)

	# Sonucu OLAN ilk açık seçeneğe bas: yalnız garantili etkisi olan bir
	# seçenek günlüğe sonuç satırı düşürmez, yani doğrulanacak cümle çıkmaz.
	var context: Dictionary = session.build_event_context()
	for choice in event.choices:
		if choice.is_available(context) and not choice.outcomes.is_empty():
			screen.call("_on_choice_pressed", choice)
			break
	await _settle()
	# Sonuç satırı alt şeritte bir an görünüp etki satırlarıyla değişiyor;
	# okunacak yer sefer günlüğünün kendisi.
	screen.call("_on_log_toggled", true)
	await _settle()
	await _settle()
	_save("%s_sonuc.png" % card_id)
	screen.queue_free()
	await _settle()

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  %s" % file_name)
