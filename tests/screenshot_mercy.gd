extends SceneTree

## Küçük lütuf anı (görev Y-B16): yol sahnesinin kendisi, kamp kurulmuş,
## arayüz çekilmiş, altta tek cümle. **Test değil** - PNG basar:
## `mercy_shots/lutuf.png` ve arayüz döndükten sonra açılan günlük
## `mercy_shots/gunluk.png`.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_mercy.gd -- 1600 900

const SHOT_DIR: String = "user://mercy_shots"

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var view := Vector2i(1600, 900)
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		view = Vector2i(int(args[0]), int(args[1]))
	get_root().size = view
	DisplayServer.window_set_size(view)
	await _settle(8)
	var session := _start_journey()
	var screen: Control = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle(8)
	# Kamp kurulur, eylem paneli kapatılır: lütuf panelden sonra gelir.
	screen.call("_on_camp_pressed")
	await _settle(240)
	var camp_panel: Node = screen.get("_camp_panel")
	if camp_panel != null:
		camp_panel.queue_free()
		screen.set("_camp_panel", null)
	var party := session.get_party()
	var mercy := {"kind": "hum", "args": [party[0].character_name, party[party.size() - 1].character_name]}
	session.receive_small_mercy(mercy)
	TranslationServer.set_locale("tr")
	screen.call("_play_mercy_moment", mercy)
	# Yazılım çiziminde kare yavaş: sabit kare saymak anı kaçırıyor. Cümle
	# tam belirdiği an çekilir.
	var layer: Control = screen.get("_mercy_layer")
	var line: Control = layer.get_child(layer.get_child_count() - 1)
	while is_instance_valid(line) and line.modulate.a < 0.98:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/lutuf.png" % SHOT_DIR)
	screen.call("_end_mercy_moment")
	await _settle(30)
	get_root().get_texture().get_image().save_png("%s/gunluk.png" % SHOT_DIR)
	quit()

func _start_journey() -> GameSession:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var session: GameSession = get_root().get_node_or_null("GameState").call("get_session")
	var player := CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(player, rng)
	session.current_location_id = "rivecande"
	var destination := WorldMapData.get_location_by_id(WorldMapData.START_LOCATION_ID)
	var days := WorldMapData.get_route("rivecande", WorldMapData.START_LOCATION_ID).travel_days
	session.start_journey(WorldMapData.START_LOCATION_ID, days, 0.38, CaravanPlan.new(destination, days))
	return session

func _settle(frames: int) -> void:
	for _frame in frames:
		await process_frame
