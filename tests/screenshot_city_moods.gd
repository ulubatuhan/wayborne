extends SceneTree

## Şehrin hâlleri (görev 9.3, taslak y_93_sehir_varyant): olağan, gri (kapalı
## hava) ve kriz (veba, yolunda savaş), gündüz ve gece. **Test değil** - PNG
## basar. Şehir ekranını gerçek oturumla açıyor; hâli oturumdan değil doğrudan
## seçiyor ki üçü de aynı şehirde, aynı saatte görülsün.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_city_moods.gd -- [yer]

const SHOT_DIR: String = "user://city_mood_shots"
const MOOD_NAMES: Array[String] = ["olagan", "gri", "kriz"]

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
	var args := OS.get_cmdline_user_args()
	session.current_location_id = String(args[0]) if not args.is_empty() else "vastrevar"
	var city_map: Script = load("res://scripts/world/city_map.gd")
	for hour in [12.0, 18.5, 22.0]:
		session.last_clock_hour = hour
		for mood in MOOD_NAMES.size():
			var front := CityFront.new()
			get_root().add_child(front)
			var model: Dictionary = city_map.call("build_model", session)
			model["mood"] = mood
			front.setup(city_map.call("town_dir", session.current_location_id), model)
			for _frame in 8:
				await process_frame
			get_root().get_texture().get_image().save_png("%s/%s_%02d_%s.png" % [
				SHOT_DIR, session.current_location_id, int(hour), MOOD_NAMES[mood]])
			front.queue_free()
			for _frame in 3:
				await process_frame
	quit()
