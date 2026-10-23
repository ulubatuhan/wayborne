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
	# UserSettings dili ilk karede kendi kaydından kuruyor.
	TranslationServer.set_locale("tr")
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
	# Düşenler açılımı (görev 9.11): rütbeli mezar işaretleri ve hikâye satırları.
	panel.set_fallen_page(true)
	await _settle()
	_save("01b_dusenler.png")
	panel.queue_free()

	var candidates: Array[CharacterData] = session.party.duplicate()
	var succession := SuccessionPanel.new()
	var testimony := {}
	for index in candidates.size():
		testimony[candidates[index]] = {"served_days": 43 - index * 20, "benched": index == 1}
	succession.setup(
		session.caravan_name, "Ahmet", "Ahmet — kurtlara yem oldu, Kurtboğazı yakınında (gün 43)",
		candidates, 3, testimony
	)
	get_root().add_child(succession)
	# Mürekkep darbesi yarı yoldayken ve bittikten sonra.
	await _wait_seconds(0.9)
	_save("02_devir_darbe.png")
	await _wait_seconds(1.2)
	_save("03_devir.png")
	succession.queue_free()
	await _settle()

	# Günün satırı (Y-B08): akşam kampında üç cümle.
	var road := _lineage_session()
	var destination := WorldMapData.get_location_by_id(WorldMapData.START_LOCATION_ID)
	road.start_journey(WorldMapData.START_LOCATION_ID, 4, 0.2, CaravanPlan.new(destination, 4))
	road.note_beat(GameSession.BEAT_DEATH, ["Zeynep"])
	var diary := DiaryPanel.new().setup(road.diary_candidates())
	get_root().add_child(diary)
	await _wait_seconds(0.6)
	_save("05_gunun_satiri.png")
	diary.queue_free()
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
	var result := session.resolve_deaths(leader, "LEDGER_CAUSE_COMBAT_WILDLIFE", "zelmarin")
	if bool(result.get("awaiting_heir", false)):
		session.appoint_heir(result["heir_candidates"][0])
	var elif_id := session.party[0].character_id if not session.party.is_empty() else ""
	session.ledger.record(CaravanLedger.KIND_STORY, "Elif", 50, 2, elif_id, "STORY_DEBTOR_1")
	session.ledger.record(CaravanLedger.KIND_STORY, "Elif", 55, 2, elif_id, "STORY_DEBTOR_2")
	session.total_days_elapsed = 61
	session.call("_starve_one_crew_member")
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
