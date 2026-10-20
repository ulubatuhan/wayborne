extends SceneTree

## Döngü videosu (görev Y-K01): docs/playtest/DONGU_KONTROL.md'deki beş dakikalık
## çekim listesini gerçek sahnelerle sırayla oynatır. **Test değil** - Godot'nun
## film yazıcısıyla birlikte koşturulur, kareleri o yazar:
##
##   godot --path . --resolution 1280x720 --position 20000,20000 --rendering-driver opengl3 \
##     --write-movie <depo dışı>/dongu.avi --fixed-fps 30 --script res://tests/record_loop.gd
##
## Sabit kare hızında oyun zamanı kare sayısından gelir; her sahne saniye
## cinsinden bir süre kalır. Tıklama yok: seçimler ekranın kendi işlevleriyle
## yapılıyor (ekran görüntüsü araçlarının yolu), kayıtta görünen her şey
## oyunun kendi çizimi.

const FPS: int = 30
const ORIGIN: String = "rivecande"
const SEED_VALUE: int = 2026

var _screen: Node = null

func _init() -> void:
	TranslationServer.set_locale("tr")
	await _hold(0.3)
	var session := _session()

	# 0:00 Ana menü: başlık evresi, sonra bir tuşla menü.
	await _show("res://scenes/ui/main_menu.tscn")
	await _hold(6.0)
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	await _hold(14.0)

	# 0:20 Şehir: önden kasaba, brifing; sonra pazar ve planlayıcı.
	await _show("res://scenes/world/city_map.tscn")
	await _hold(25.0)
	await _show("res://scenes/game/market.tscn")
	await _hold(18.0)
	var destination := _destination()
	TravelContext.selected_destination_id = destination
	await _show("res://scenes/game/caravan_planner.tscn")
	await _hold(17.0)

	# 1:20 Yol: kolon yürür, bir işaret ve bir kart, panel sekmeleri, harita.
	var days := WorldMapData.get_route(ORIGIN, destination).travel_days
	session.start_journey(destination, days, 0.38, CaravanPlan.new(WorldMapData.get_location_by_id(destination), days))
	await _show("res://scenes/game/road_journey.tscn")
	await _hold(30.0)
	_present_card()
	await _hold(9.0)
	_clear_card()
	var panel = _screen.get("_control_panel")
	if panel != null:
		for tab in [RoadControlPanel.TAB_STATUS, RoadControlPanel.TAB_CARGO, RoadControlPanel.TAB_MAP]:
			panel.select_tab(tab)
			await _hold(5.0)
		panel.select_tab(RoadControlPanel.TAB_PARTY)
	await _hold(20.0)
	if _screen.has_method("_open_map_popup"):
		_screen.call("_open_map_popup")
		await _hold(8.0)
		var popup = _screen.get("_map_popup")
		if popup != null and is_instance_valid(popup):
			popup.queue_free()
			_screen.set("_map_popup", null)
	await _hold(10.0)

	# 3:00 Kamp: ateşe yürüyüş ve oturuş.
	if _screen.has_method("_on_camp_pressed"):
		_screen.call("_on_camp_pressed")
	# Kamp eylemleri paneli ateşe yürüyüşü örtüyor: bir an görünsün, sonra onaylansın.
	await _hold(4.0)
	var camp_panel = _screen.get("_camp_panel")
	if camp_panel != null and is_instance_valid(camp_panel):
		camp_panel.call("_confirm")
	await _hold(41.0)

	# 3:45 Savaş: iki taraf da kendi sırasında oynar.
	await _show_combat()
	await _play_combat(45.0)

	# 4:35 Varış: kapı açılır, şehir.
	session.finish_journey()
	await _show("res://scenes/world/city_map.tscn")
	await _hold(20.0)
	quit()

func _session() -> GameSession:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED_VALUE
	var state := get_root().get_node_or_null("GameState")
	var session: GameSession = state.call("get_session")
	var player := CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(player, rng)
	session.set_flag(GameSession.ONBOARDING_FLAG)
	session.current_location_id = ORIGIN
	session.owned_wagon_count = 2
	session.add_to_cargo(ItemCatalog.get_item("fish"), 12)
	session.add_to_cargo(ItemCatalog.get_item("test_furs"), 4)
	return session

func _destination() -> String:
	var best: TravelRoute = null
	for route in WorldMapData.get_routes_from(ORIGIN):
		if best == null or route.travel_days < best.travel_days:
			best = route
	return best.to_location_id if best != null else WorldMapData.START_LOCATION_ID

func _show(path: String) -> void:
	if _screen != null and is_instance_valid(_screen):
		_screen.queue_free()
	_screen = load(path).instantiate()
	get_root().add_child(_screen)
	await _hold(0.2)

func _present_card() -> void:
	for event in EventCatalog.get_road_events():
		if event.event_id == "evt_landslide":
			_screen.call("_present_event", event)
			return

func _clear_card() -> void:
	NodeUtil.clear_children(_screen.get("_card_panel"))
	_screen.set("_current_event", null)

func _show_combat() -> void:
	if _screen != null and is_instance_valid(_screen):
		_screen.queue_free()
	var holder := MarginContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = ArtPalette.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(bg)
	var panel := CombatPanel.new()
	holder.add_child(panel)
	get_root().add_child(holder)
	_screen = holder
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED_VALUE
	panel.start_combat(get_root().get_node("GameState").call("get_session").get_party(), 0.75, rng, "bandit", "", "forest")
	await _hold(0.5)

func _play_combat(seconds: float) -> void:
	var panel: CombatPanel = _screen.get_child(1)
	var frames := int(seconds * FPS)
	var wait := 0
	for _frame in frames:
		await process_frame
		wait -= 1
		if panel._encounter != null and panel._encounter.state != CombatEncounter.State.ONGOING:
			await _hold(5.0)  # sonucu oku, sonra varış
			return
		if wait > 0 or panel._encounter == null:
			continue
		if not panel._encounter.is_player_turn():
			continue
		var active: CombatUnit = panel._encounter.get_active_unit()
		for skill in active.skills:
			if not active.can_use_skill(skill):
				continue
			var targets: Array = panel._encounter.get_valid_targets(active, skill)
			if targets.is_empty():
				continue
			panel._on_skill_pressed(skill)
			panel._on_unit_clicked(targets[0])
			break
		wait = int(1.6 * FPS)

func _hold(seconds: float) -> void:
	for _frame in maxi(1, int(seconds * FPS)):
		await process_frame
