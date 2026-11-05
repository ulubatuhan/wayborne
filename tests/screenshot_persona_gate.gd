extends SceneTree

## Profil çalışmasının bulduğu ölümcül anı ekranda gösteren araç.
## **Test değil** - PNG basar.
##
## Bulgu (bkz. `docs/design_notes/oyuncu_profilleri.md`): planlayıcıyı
## okumayan ve tayfayı besleyen bir oyuncu ilk seferde 35 günlük bir yola
## 85 erzak gereğiyle çıkıyor, rafta 69 var ve kervan üçüncü seferde
## ölüyor. Soru şu: **ekran bunu söylüyor mu?** Simülatör sayıyı görür,
## oyuncu ekranı görür; ikisi aynı şeyi söylemiyorsa mekanik görünmez bir
## ceza olur (Y-K01).
##
## İki kare: ölümcül uzun yol ve güvenli kısa yol - aynı kervan, aynı gün.
##
## Koşturmak:
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_persona_gate.gd

const SHOT_DIR: String = "user://persona_shots"
const VIEW: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var root := get_root()
	root.size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()
	get_root().get_node("UserSettings").call("set_locale", "tr")

	await _shoot("01_uzun_yol", true)
	await _shoot("02_kisa_yol", false)
	print("bitti")
	quit()

func _shoot(file_name: String, longest: bool) -> void:
	_setup(longest)
	var screen: Control = load("res://scenes/game/caravan_planner.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	_save("%s.png" % file_name)
	screen.queue_free()
	await _settle()

func _setup(longest: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 515000
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.inherit_father_caravan()
	# Oyunun başladığı hâl: 250 altın, 20 erzak, tek vagon.
	session.wallet.balance = 250
	session.change_provisions(20 - session.get_provisions())
	var origin := WorldMapData.get_location_by_id(session.current_location_id)
	var best := ""
	var best_days := -1
	for route in WorldMapData.get_routes_from(origin.location_id):
		var days := session.get_route_travel_days(route)
		var target := route.to_location_id if route.to_location_id != origin.location_id else route.from_location_id
		if best.is_empty() or (days > best_days if longest else days < best_days):
			best_days = days
			best = target
	TravelContext.selected_destination_id = best
	print("  %s -> %s (%d gün, kese %d, erzak %d, rafta %d)" % [
		origin.location_id, best, best_days, session.wallet.balance,
		session.get_provisions(), session.get_provision_stock(),
	])

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
