extends SceneTree

## Soy sonu ekranı (görev Y-G23): yol sahnesinin kendisi açılır, defterde
## ölüm satırları olan bir kervanın bitiş paneli gösterilir. **Test değil** -
## PNG basar: `lineage_end_shots/soy_sonu_*.png` (iki kare: yürüyüş sürüyor).
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_lineage_end.gd -- 1600 900

const SHOT_DIR: String = "user://lineage_end_shots"
const DEAD: Array[String] = ["Aybike", "Tolun", "Mirel", "Saruca", "Edrin", "Kayra Ana", "Bertil"]

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var view := Vector2i(1600, 900)
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		view = Vector2i(int(args[0]), int(args[1]))
	get_root().size = view
	DisplayServer.window_set_size(view)
	await _settle()
	var session := _start_journey()
	var day := 3
	for name in DEAD:
		session.ledger.record(CaravanLedger.KIND_DIED, name, day, 1)
		day += 11
	session.ledger.record(CaravanLedger.KIND_DEPARTED, "Gidip Giden", day, 1)
	var screen: Control = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	screen.set("_is_live_journey", false)
	screen.call("_show_run_over")
	screen.call("_refresh_modal")
	for shot in 2:
		for _frame in 90:
			await process_frame
		get_root().get_texture().get_image().save_png("%s/soy_sonu_%d.png" % [SHOT_DIR, shot])
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

func _settle() -> void:
	for _frame in 8:
		await process_frame
