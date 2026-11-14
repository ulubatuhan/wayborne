extends SceneTree

## Galeri ağızları (Y-A07) gerçek yol ekranında: her ağzın her bölgesinde
## (ağız, geçit, galeri) seviye haritası, bölge resmiyle bir oda kartı ve kadro
## seçim penceresi kapatılmış bir savaş. Test değil, PNG basar (Y-K01).
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_dungeon.gd
## Yalnız bir ağız: DUNGEON=kemrug_yarigi; savaşsız: NO_COMBAT=1.

const SHOT_DIR: String = "user://dungeon_shots"
const VIEW_SIZE: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW_SIZE
	DisplayServer.window_set_size(VIEW_SIZE)
	await process_frame
	var settings := get_root().get_node_or_null("UserSettings")
	if settings != null:
		settings.call("set_locale", "tr")
	var only := OS.get_environment("DUNGEON")
	for dungeon_id in DungeonCatalog.ORDER:
		if only.is_empty() or only == dungeon_id:
			await _shoot_dungeon(dungeon_id)
	print("bitti")
	quit()

## Her bölgenin ilk seviyesi.
func _zone_levels(dungeon_id: String) -> Dictionary:
	var out := {}
	for level in range(1, DungeonCatalog.max_depth(dungeon_id) + 1):
		var zone := DungeonMap.zone(dungeon_id, level)
		if not out.has(zone):
			out[zone] = level
	return out

func _shoot_dungeon(dungeon_id: String) -> void:
	var zones := _zone_levels(dungeon_id)
	for zone in zones:
		var screen := await _open_road(dungeon_id, int(zones[zone]))
		var live: GameSession = screen.get("_session")
		screen.call("_open_dungeon_map")
		await _settle(3)
		_save("%s_%s_1_harita.png" % [dungeon_id, zone])
		var panel: Node = screen.get("_dungeon_map_panel")
		if panel != null:
			panel.queue_free()
			screen.set("_dungeon_map_panel", null)
		await _settle(1)
		# Oda kartı: bölge resmiyle.
		var card: GameEvent = EventCatalog.get_event("evt_dng_s_old_bones")
		screen.call("_present_event", card)
		await _settle(2)
		_save("%s_%s_2_kart.png" % [dungeon_id, zone])
		if OS.get_environment("NO_COMBAT") != "1":
			var wolves: GameEvent = EventCatalog.get_event("evt_dng_s_stone_wolves")
			screen.call("_present_event", wolves)
			await _settle(1)
			screen.call("_on_choice_pressed", wolves.choices[0])
			await _settle(1)
			var pre: Node = screen.get("_pre_combat_panel")
			if pre != null:
				pre.queue_free()
				screen.call("_on_pre_combat_confirmed", live.get_party())
			await _settle(5)
			_save("%s_%s_3_savas.png" % [dungeon_id, zone])
		screen.queue_free()
		await _settle(1)

func _open_road(dungeon_id: String, level: int) -> Node:
	var state := get_root().get_node_or_null("GameState")
	var session: GameSession = state.call("get_session")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	session.start_playthrough(CharacterData.create("Veysel", CultureCatalog.HIGHLAND, CharacterStats.new()), rng)
	session.add_to_party(CharacterData.create("Sevda", CultureCatalog.NOMAD, CharacterStats.new()))
	session.add_to_party(CharacterData.create("Demir", CultureCatalog.VALLEY, CharacterStats.new()))
	session.add_to_cargo(ItemCatalog.get_item(ItemCatalog.TORCH), 3)
	var destination := WorldMapData.get_location_by_id("vorgat")
	session.start_journey("vorgat", 5, 0.4, CaravanPlan.new(destination, 5))
	session.dungeon_enter(dungeon_id, true)
	# İstenen seviyeye in; ilk seviyede iki koridor yürünmüş olsun ki harita dolu görünsün.
	while int(session.dungeon_run["depth"]) < level:
		session.dungeon_deeper()
	var map := DungeonMap.level_of(session.dungeon_run)
	var first := DungeonMap.neighbours(map, 0)[0]
	session.dungeon_move(first)
	DungeonMap.room(map, first)["done"] = true
	session.dungeon_run["phase"] = "map"
	var screen: Node = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle(2)
	# Kendiliğinden açılan harita ya da kart (ilk karede) bu aracın sırasını bozmasın.
	var auto_panel: Node = screen.get("_dungeon_map_panel")
	if auto_panel != null:
		auto_panel.queue_free()
		screen.set("_dungeon_map_panel", null)
	await _settle(1)
	return screen

func _settle(rounds: int) -> void:
	for _frame in 8 * rounds:
		await process_frame

func _save(file_name: String) -> void:
	get_root().get_texture().get_image().save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  %s" % file_name)
