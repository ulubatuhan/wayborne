extends SceneTree

## Erzak stoğunu (P5) ve sözün yeni hâlini (P9/B) planlayıcı ekranında
## fotoğraflayan araç. **Test değil** - PNG basar.
##
## Neden gerekli: değişen şey oyuncunun gördüğü bir cümle ("Bu şehirde
## yalnız N erzak var") ve düğmenin yazdığı sayı. Yapısal test rakamı
## doğrular, satırın okunup okunmadığını göremez (Y-K01).
##
## Koşturmak:
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_provisioning.gd

const SHOT_DIR: String = "user://provision_shots"
const VIEW: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var root := get_root()
	root.size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()

	# Üç hâl: rafı yeten bir şehir, yetmeyen bir kasaba, ve kıtlığın
	# derinleştiği geç bir gün.
	for state in [
		["01_sehir", SettlementRules.CITY, 1],
		["02_kasaba", SettlementRules.TOWN, 1],
		["03_gec_oyun_kitlik", SettlementRules.CITY, 320],
	]:
		_setup(String(state[1]), int(state[2]))
		var screen: Control = load("res://scenes/game/caravan_planner.tscn").instantiate()
		root.add_child(screen)
		await _settle()
		_save("%s.png" % String(state[0]))
		screen.queue_free()
		await _settle()
	print("bitti")
	quit()

func _setup(settlement_type: String, day: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.total_days_elapsed = day
	# Rafı yetmeyen bir yer seçmek için türe göre ara.
	var origin: Location = null
	for place in WorldMapData.get_locations():
		if place.settlement_type == settlement_type:
			origin = place
			break
	if origin == null:
		origin = WorldMapData.get_locations()[0]
	session.current_location_id = origin.location_id
	# Uzun bir hedef: komşu yollardan en uzunu.
	var best := ""
	var best_days := 0
	for route in WorldMapData.get_routes_from(origin.location_id):
		if route.travel_days > best_days:
			best_days = route.travel_days
			best = route.to_location_id if route.to_location_id != origin.location_id else route.from_location_id
	if best.is_empty():
		best = WorldMapData.START_LOCATION_ID
	TravelContext.selected_destination_id = best
	session.change_provisions(-session.get_provisions())

func _settle() -> void:
	for _frame in 10:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
