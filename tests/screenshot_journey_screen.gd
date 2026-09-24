extends SceneTree

## Yol ekranının **gerçek sahnesini** kurup fotoğraflayan araç. **Test
## değil** - hiçbir şey doğrulamaz, PNG basar (bkz. screenshot_road.gd).
##
## Diğer screenshot araçlarından farkı şu: onlar `TravelBand`'i tek başına
## kuruyor, yani *manzarayı* gösteriyor ama ekranın yerleşimini
## göstermiyor. Ekranın asıl şikâyeti ise yerleşimdi ("oyun hâlâ text
## based RPG gibi"), o yüzden burada `road_journey.tscn`'in kendisi
## açılıyor - HUD şeritleri, olay kartı ve kayıt katmanı dahil.
##
## Koşturmak:
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_journey_screen.gd

const SHOT_DIR: String = "user://journey_shots"
const VIEW_SIZE: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	var root := get_root()
	var view := VIEW_SIZE
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		view = Vector2i(int(args[0]), int(args[1]))
	root.size = view
	DisplayServer.window_set_size(view)

	# Autoload'lar ağaca ancak ilk kareden sonra giriyor ve `GameState`
	# adı bu betik derlenirken henüz tanımlı değil - o yüzden düğüm
	# yolundan, adıyla anılmadan alınıyor (aynı gerekçe autoload
	# kuralında da yazılı).
	await _settle()
	_start_journey()

	var screen: Control = load("res://scenes/game/road_journey.tscn").instantiate()
	root.add_child(screen)
	await _settle()
	_save("01_yol_%dx%d.png" % [view.x, view.y])

	# Olay kartı: EU4 yerleşiminin asıl sınandığı kare.
	screen.call("_present_event", EventCatalog.get_road_events()[0])
	await _settle()
	_save("02_olay_karti.png")

	# Zara bağlı seçenekler: başında zarı atan statın amblemi.
	for event in EventCatalog.get_road_events():
		if event.event_id == "evt_landslide":
			screen.call("_clear_children", screen.get("_card_panel"))
			screen.call("_present_event", event)
	await _settle()
	_save("02b_olay_karti_zar.png")

	# Kervan dökümü: playtest'in "My Caravan Status" isteği.
	screen.call("_on_status_toggled", true)
	await _settle()
	_save("03_durum.png")
	screen.call("_on_status_toggled", false)
	screen.call("_clear_children", screen.get("_card_panel"))
	screen.set("_current_event", null)

	# Yıpranmış bir kervan: stres ve açlık kenar lekeleri, açık bir yol
	# işareti ve sofra kâseleri aynı karede.
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	session.change_stress(60)
	# Biri ortalamadan belirgin yukarıda: stres şişesinde onun çentiği.
	session.change_character_stress(session.party[session.party.size() - 1], 30)
	for character in session.party:
		character.consecutive_hungry_days = 3
	screen.call("_flash_signal_icon", RoadSignals.KIND_WHEEL, ArtPalette.UI_SIGNAL_ESCALATED)
	screen.call("_refresh_state")
	var meal := MealDistributionPanel.new()
	meal.setup(session)
	root.add_child(meal)
	await _settle()
	meal.call("_select_mode", GameSession.MEAL_MODE_SELF_ONLY)
	await _settle()
	_save("04_yipranmis.png")

	quit()

func _start_journey() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var state := get_root().get_node_or_null("GameState")
	var session: GameSession = state.call("get_session")
	var player := CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(player, rng)
	session.owned_wagon_count = 2

	var destination := WorldMapData.get_location_by_id(WorldMapData.START_LOCATION_ID)
	var plan := CaravanPlan.new(destination, 6)
	session.start_journey(WorldMapData.START_LOCATION_ID, 6, 0.4, plan)

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", image.get_size())
