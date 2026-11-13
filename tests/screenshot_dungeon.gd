extends SceneTree

## Galeri ağzı (Y-A07) gerçek yol ekranında: ağız kartı, inince gelen ilk
## aşama, kapı kartı ve kör dişlerle savaş. Test değil, PNG basar (Y-K01).
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_dungeon.gd

const SHOT_DIR: String = "user://dungeon_shots"
const VIEW_SIZE: Vector2i = Vector2i(1600, 900)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW_SIZE
	await process_frame
	var settings := get_root().get_node_or_null("UserSettings")
	if settings != null:
		settings.call("set_locale", "tr")
	var state := get_root().get_node_or_null("GameState")
	var session: GameSession = state.call("get_session")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	session.start_playthrough(CharacterData.create("Veysel", CultureCatalog.HIGHLAND, CharacterStats.new()), rng)
	session.add_to_party(CharacterData.create("Sevda", CultureCatalog.NOMAD, CharacterStats.new()))
	session.add_to_party(CharacterData.create("Demir", CultureCatalog.VALLEY, CharacterStats.new()))
	var destination := WorldMapData.get_location_by_id("vorgat")
	session.start_journey("vorgat", 5, 0.4, CaravanPlan.new(destination, 5))
	var screen: Node = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	var live: GameSession = screen.get("_session")
	screen.call("_present_event", EventCatalog.get_event("evt_dng_mouth"))
	await _settle()
	_save("01_agiz.png")
	var mouth: GameEvent = EventCatalog.get_event("evt_dng_mouth")
	screen.call("_on_choice_pressed", mouth.choices[0])
	await _settle()
	await _settle()
	_save("02_ilk_asama.png")
	var stage: GameEvent = screen.get("_current_event")
	if stage != null:
		# Sonucu olmayan ilk seçenek (düz bir yol) seçilir, kapı gelir.
		for choice in stage.choices:
			if choice.outcomes.is_empty() and choice.is_available(live.build_event_context()):
				screen.call("_on_choice_pressed", choice)
				break
	await _settle()
	await _settle()
	_save("03_kapi.png")
	# Kör dişler: taş kurtları aşaması, savaşa gir.
	var wolves: GameEvent = EventCatalog.get_event("evt_dng_s_stone_wolves")
	screen.call("_present_event", wolves)
	await _settle()
	screen.call("_on_choice_pressed", wolves.choices[0])
	await _settle()
	var pre: Node = screen.get("_pre_combat_panel")
	if pre != null:
		_save("04_savas_oncesi.png")
		screen.call("_on_pre_combat_confirmed", live.get_party())
		for _i in 30:
			await process_frame
		_save("05_savas.png")
	print("bitti")
	quit()

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	get_root().get_texture().get_image().save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  %s" % file_name)
