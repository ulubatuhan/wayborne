extends SceneTree

## Fiyatın nedenini söyleyen kısa metni (P7) pazar tezgâhında fotoğraflayan
## araç. **Test değil** - PNG basar.
##
## Neden gerekli: değişen şey satır notunun kendisi. Testler çarpan
## kalmadığını ve en çok üç neden yazıldığını doğruluyor; satırın tezgâha
## sığdığını ve okunduğunu yalnız ekran gösterir (Y-K01).
##
## Koşturmak:
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_price_marks.gd

const SHOT_DIR: String = "user://price_mark_shots"
const VIEW: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var root := get_root()
	root.size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()
	get_root().get_node("UserSettings").call("set_locale", "tr")

	# İki hâl: sıradan bir gün ve kıtlığın konuştuğu bir gün.
	await _shoot("01_sakin", 1, false)
	await _shoot("02_kitlik", 320, true)
	print("bitti")
	quit()

func _shoot(file_name: String, day: int, want_scarcity: bool) -> void:
	_setup(day, want_scarcity)
	var screen: Control = load("res://scenes/game/market.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	_save("%s.png" % file_name)
	screen.queue_free()
	await _settle()

func _setup(day: int, want_scarcity: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.total_days_elapsed = day
	session.wallet.earn(4000)
	var chosen: Location = null
	var best := -1.0
	for place in WorldMapData.get_locations():
		if place.settlement_type != SettlementRules.CITY:
			continue
		var degree := Scarcity.degree(place.region, day)
		if want_scarcity:
			if degree > best:
				best = degree
				chosen = place
		elif chosen == null or degree < best:
			best = degree
			chosen = place
	if chosen == null:
		chosen = WorldMapData.get_locations()[0]
	session.current_location_id = chosen.location_id
	print("  %s gün %d kıtlık %.2f" % [chosen.location_id, day, best])

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
