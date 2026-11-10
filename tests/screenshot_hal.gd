extends SceneTree

## H6'nın ekran doğrulaması (Y-K01): hâl ekranda **sıfat ve cümle** olarak
## okunuyor mu - Kabuk ve Çatlak hiçbir yerde sayı olarak görünmemeli (§F).
## **Test değil** - PNG basar.
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_hal.gd

const SHOT_DIR: String = "user://hal_shots"
const VIEW: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()
	get_root().get_node("UserSettings").call("set_locale", "tr")
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	session.add_to_party(CharacterData.create("Sönük", CultureCatalog.NOMAD, CharacterStats.new()))
	session.add_to_party(CharacterData.create("Yorgun", CultureCatalog.HIGHLAND, CharacterStats.new()))
	session.total_days_elapsed = 140
	var party := session.get_party()
	party[1].kabuk = 5.0
	party[2].catlak = 4.5
	party[2].character_name = "Sönük Kişi"
	for member in party:
		member.update_state(session.total_days_elapsed, true)
	for member in party:
		print("  %s -> %s" % [member.character_name, member.hal])
	var panel := CaravanOverviewPanel.new()
	get_root().add_child(panel)
	panel.setup(session)
	await _settle()
	await _settle()
	_save("kadro_hal.png")
	quit()

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
