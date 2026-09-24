extends SceneTree

## Yönetim ekranlarını (pazar, lonca, taverna, avlu, kilise, harita,
## planlayıcı, tayfa, karakter, parti, karakter oluşturma) canlı bir oturumla
## tek tek açıp fotoğraflayan araç. **Test değil** - PNG basar (bkz.
## screenshot_road.gd). Her ekranın kendi Waybook arka planını ve metnin o
## zemin üstünde okunup okunmadığını görmek için: yapısal testler bunu
## göremez.
##
## Koşturmak:
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_screens.gd -- [genişlik yükseklik]

const SHOT_DIR: String = "user://screen_shots"
const SCREENS: Array[String] = [
	"res://scenes/game/market.tscn",
	"res://scenes/game/guild.tscn",
	"res://scenes/game/tavern.tscn",
	"res://scenes/game/caravan_yard.tscn",
	"res://scenes/game/church.tscn",
	"res://scenes/game/world_map.tscn",
	"res://scenes/game/caravan_planner.tscn",
	"res://scenes/game/recruit.tscn",
	"res://scenes/game/character.tscn",
	"res://scenes/game/party.tscn",
	"res://scenes/ui/character_creation.tscn",
	"res://scenes/world/city_map.tscn",
]

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var args := OS.get_cmdline_user_args()
	var view := Vector2i(1920, 1080)
	if args.size() >= 2:
		view = Vector2i(int(args[0]), int(args[1]))
	get_root().size = view
	DisplayServer.window_set_size(view)
	# Autoload'lar ilk kareden sonra ağaçta (bkz. screenshot_journey_screen).
	await _settle()
	_prepare_session()

	for path in SCREENS:
		var screen: Node = load(path).instantiate()
		get_root().add_child(screen)
		await _settle()
		_save("%s_%dx%d.png" % [path.get_file().get_basename(), view.x, view.y])
		screen.queue_free()
		await _settle()
	quit()

## Bir kriz şehri, bir borç ve dolu bir parti: satırların, mühürlerin ve
## parmak izinin gerçekten göründüğü bir hâl.
func _prepare_session() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var state := get_root().get_node_or_null("GameState")
	var session: GameSession = state.call("get_session")
	var player := CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(player, rng)
	session.set_flag(GameSession.ONBOARDING_FLAG)
	session.owned_wagon_count = 2
	session.add_to_cargo(ItemCatalog.get_item("test_grain"), 12)
	session.add_to_cargo(ItemCatalog.get_item("silk"), 3)
	session.spend_or_owe(400)
	session.total_days_elapsed = 60
	# Kenar notları görünsün: bir kırgınlık, bir açlık çetelesi, bir huy.
	var companion: CharacterData = session.party[session.party.size() - 1]
	companion.add_grievance(CharacterData.GRIEVANCE_UNFED)
	companion.add_grievance(CharacterData.GRIEVANCE_UNFED)
	companion.add_grievance(CharacterData.GRIEVANCE_WITNESSED_DEATH)
	companion.consecutive_hungry_days = 2
	companion.duty_id = DutyCatalog.LEVAZIMCI
	# Yakın bir ölüm: şehir brifingi yas kurdelesini taşısın.
	var fallen := CharacterData.create("Yaruk", CultureCatalog.NOMAD, CharacterStats.new())
	session.add_to_party(fallen)
	var dead: Array[CharacterData] = [fallen]
	session.resolve_deaths(dead, "LEDGER_CAUSE_COMBAT_WILDLIFE", session.current_location_id)

func _settle() -> void:
	for _frame in 10:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
