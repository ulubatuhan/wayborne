extends SceneTree

## IP-008: oyuncunun ilk saatte gördüğü ekranları **gerçek sahneleriyle**
## kurup fotoğraflar. Sürücü (playtest_driver.gd) yalnız kuralları oynuyor ve
## yol sahnesini hiç açmıyor; bu araç o boşluğu kapatır. Test değil: hiçbir
## şey doğrulamaz, PNG basar - bakan insandır (Y-K01, `ekran-dogrula`).
##
## Koşturmak:
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/playtest/playtest_ilk_saat.gd

const SHOT_DIR: String = "user://playtest_ilk_saat"
const VIEW_SIZE: Vector2i = Vector2i(1920, 1080)
const ORIGIN: String = "rivecande"

var _sayac: int = 0

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW_SIZE
	DisplayServer.window_set_size(VIEW_SIZE)
	await _settle()

	await _ana_menu()
	await _sehir_ozeti()
	await _kervan_avlusu()
	await _planlayici()
	await _yol()
	print("── ilk saat turu bitti: %d kare -> %s" % [_sayac, SHOT_DIR])
	quit()

## Oyuncunun ilk gördüğü ekran.
func _ana_menu() -> void:
	var menu: Node = load("res://scenes/ui/main_menu.tscn").instantiate()
	get_root().add_child(menu)
	await _settle()
	await _cek("ana_menu")
	menu.free()
	await _settle()

## Şehir özeti: tanıdığın isteği ve yön satırı (IP-009), vadesi geçmiş borçta
## tefecinin kapıdaki sözü (IP-013).
func _sehir_ozeti() -> void:
	var session := _kervan()
	# Vadesi geçmiş bir borç: kese eksiye düşsün, sonra günler geçsin.
	session.spend_or_owe(session.wallet.balance + 160)
	for _day in 40:
		session.advance_day()
	session.people.ensure_city(session.current_location_id, session.total_days_elapsed)
	session.people.offer_chain(
		session.current_location_id + "_" + People.ROLE_GUILD, session.total_days_elapsed
	)

	var brief := CityBriefPanel.new()
	brief.custom_minimum_size = Vector2(760, 900)
	get_root().add_child(brief)
	brief.setup(session)
	await _settle()
	await _cek("sehir_ozeti")
	brief.free()
	await _settle()

## Kervan avlusu: sıradaki büyüme adımı satırı (IP-006).
func _kervan_avlusu() -> void:
	var session := _kervan()
	session.wallet.spend(session.wallet.balance - 60)
	var yard: Node = load("res://scenes/game/caravan_yard.tscn").instantiate()
	get_root().add_child(yard)
	await _settle()
	await _cek("kervan_avlusu")
	yard.free()
	await _settle()

## Planlayıcı, eksik erzakla: gün olarak uyarı (IP-001).
func _planlayici() -> void:
	var session := _kervan()
	session.change_provisions(-session.get_provisions() + 8)
	session.current_location_id = ORIGIN
	TravelContext.selected_destination_id = WorldMapData.START_LOCATION_ID
	var planner: Node = load("res://scenes/game/caravan_planner.tscn").instantiate()
	get_root().add_child(planner)
	await _settle()
	await _cek("planlayici_eksik_erzak")
	planner.free()
	await _settle()

## Yolun kendisi, birinci gün.
func _yol() -> void:
	var session := _kervan()
	session.current_location_id = ORIGIN
	var destination := WorldMapData.get_location_by_id(WorldMapData.START_LOCATION_ID)
	var days := WorldMapData.get_route(ORIGIN, destination.location_id).travel_days
	var plan := CaravanPlan.new(destination, days)
	session.start_journey(destination.location_id, days, 0.38, plan)
	var screen: Node = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	await _cek("yol_gun_1")
	screen.free()
	await _settle()

func _kervan() -> GameSession:
	var state := get_root().get_node_or_null("GameState")
	var session: GameSession = state.call("get_session")
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	var player := CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(player, rng)
	return session

func _settle() -> void:
	for _frame in 24:
		await process_frame

func _cek(ad: String) -> void:
	_sayac += 1
	var image := get_root().get_texture().get_image()
	var file_name := "%02d_%s.png" % [_sayac, ad]
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", image.get_size())
