extends SceneTree

## Waybook anlarını fotoğraflayan araç. **Test değil** - hiçbir şey
## doğrulamaz, PNG basar (bkz. screenshot_road.gd). Defter paneli, liderlik
## devri ve sonun kapalı defteri bir yapısal testin göremediği şeyler:
## mürekkep darbesi ismin üstünden geçiyor mu, portre madalyonun içinde mi,
## yazı sayfanın çizgilerinde okunuyor mu.
##
## Koşturmak:
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_waybook.gd

const SHOT_DIR: String = "user://waybook_shots"
const VIEW_SIZE: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW_SIZE
	await _settle()
	WaybookTheme.install()

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.25, 0.28, 0.24)
	backdrop.size = Vector2(VIEW_SIZE)
	get_root().add_child(backdrop)

	var session := _lineage_session()
	var panel := WaybookPanel.new().setup(session)
	get_root().add_child(panel)
	await _settle()
	_save("01_defter.png")
	panel.queue_free()

	var candidates: Array[CharacterData] = session.party.duplicate()
	var succession := SuccessionPanel.new()
	succession.setup(session.caravan_name, "Ahmet", "Ahmet — kurtlara yem oldu, Kurtboğazı yakınında (gün 43)", candidates, 3)
	get_root().add_child(succession)
	# Mürekkep darbesi yarı yoldayken ve bittikten sonra.
	await _wait_seconds(0.9)
	_save("02_devir_darbe.png")
	await _wait_seconds(1.2)
	_save("03_devir.png")
	succession.queue_free()
	await _settle()

	var closed := WaybookTheme.picture("m3_closed.png", 260.0)
	closed.position = Vector2(VIEW_SIZE) * 0.5 - closed.custom_minimum_size * 0.5
	get_root().add_child(closed)
	await _settle()
	_save("04_son.png")
	quit()

## İki kuşak, iki ölü, bir ayrılan: defterin bütün satır türleri görünsün.
func _lineage_session() -> GameSession:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var session := GameSession.new(250, 20)
	var player := CharacterData.create("Ahmet", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(player, rng)
	for name in ["Elif", "Mert", "Zeynep"]:
		session.add_to_party(CharacterData.create(name, CultureCatalog.NOMAD, CharacterStats.new()))
	session.total_days_elapsed = 18
	var first: Array[CharacterData] = [session.party[2]]
	session.resolve_deaths(first, "LEDGER_CAUSE_STARVED", WorldMapData.START_LOCATION_ID)
	session.total_days_elapsed = 43
	var leader: Array[CharacterData] = [session.get_player_character()]
	var result := session.resolve_deaths(leader, "LEDGER_CAUSE_COMBAT_WILDLIFE", "test_loc_b")
	if bool(result.get("awaiting_heir", false)):
		session.appoint_heir(result["heir_candidates"][0])
	return session

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", image.get_size())
