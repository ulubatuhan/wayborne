extends SceneTree

## Her yerleşimin şehir ekranı (P17, görevler N12-N15): kervan o yerde
## dururken `city_map.tscn`'i açıp fotoğraflar. **Test değil** - PNG basar.
## Kasabada lonca ve avlu levhası, kervansarayda lonca ve tapınak levhası
## olmamalı; resim yerleşimin kendi resmi olmalı (eski beş kasabanın
## yedeği değil).
##
##   godot --path . --resolution 1920x1080 --script res://tests/screenshot_settlements.gd -- [kimlik ...]

const SHOT_DIR: String = "user://settlement_shots"

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var view := Vector2i(1920, 1080)
	get_root().size = view
	DisplayServer.window_set_size(view)
	for _frame in 10:
		await process_frame
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	session.start_playthrough(CharacterData.create("Kervanbaşı", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	session.set_flag(GameSession.ONBOARDING_FLAG)
	for hint_flag in FirstTimeHint.FLAGS.values():
		session.set_flag(String(hint_flag))
	var only := OS.get_cmdline_user_args()
	var city_map: Script = load("res://scripts/world/city_map.gd")
	for location in WorldMapData.get_locations():
		if not only.is_empty() and not only.has(location.location_id):
			continue
		session.current_location_id = location.location_id
		var screen: Node = load("res://scenes/world/city_map.tscn").instantiate()
		get_root().add_child(screen)
		for _frame in 12:
			await process_frame
		get_root().get_texture().get_image().save_png("%s/%s.png" % [SHOT_DIR, location.location_id])
		print("  -> ", location.location_id, " (", city_map.town_dir(location.location_id), ")")
		screen.queue_free()
		for _frame in 4:
			await process_frame
	quit()
