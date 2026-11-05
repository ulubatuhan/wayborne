extends SceneTree

## Borç göçünü (P10-P13) fotoğraflayan araç. **Test değil** - PNG basar.
##
## İki kare: Lonca'nın defter sekmesi (borç satırları + mal avansı) ve
## Waybook'un özet sayfasındaki borç satırları. Değişen şeylerin hepsi
## oyuncunun gördüğü metin; testler sayıları doğruluyor, satırın sığdığını
## ve okunduğunu yalnız ekran gösterir (Y-K01).
##
## Koşturmak:
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_debt.gd

const SHOT_DIR: String = "user://debt_shots"
const VIEW: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var root := get_root()
	root.size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()
	get_root().get_node("UserSettings").call("set_locale", "tr")

	_setup()
	var guild: Control = load("res://scenes/game/guild.tscn").instantiate()
	root.add_child(guild)
	await _settle()
	# Borç sekmesi: satırlar ve mal avansı yan yana.
	var tabs: TabContainer = guild.get_node("MarginContainer/VBoxContainer/TabContainer")
	tabs.current_tab = 1
	await _settle()
	_save("01_lonca_defter.png")
	guild.queue_free()
	await _settle()

	# `setup` **ağaca eklenmeden önce**: sayfalar `_ready`'de kuruluyor ve
	# oturum o anda yoksa özet boş çıkıyor (ilk denemede öyle çıktı).
	var waybook: CanvasLayer = load("res://scripts/ui/waybook_panel.gd").new()
	waybook.call("setup", get_root().get_node("GameState").call("get_session"))
	root.add_child(waybook)
	await _settle()
	_save("02_defter_borclari.png")
	waybook.queue_free()
	await _settle()
	print("bitti")
	quit()

func _setup() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.total_days_elapsed = 40
	session.wallet.earn(600)
	session.owned_wagon_count = 2
	var place: Location = null
	for candidate in WorldMapData.get_locations():
		if not candidate.produces.is_empty():
			place = candidate
			break
	if place == null:
		place = WorldMapData.get_locations()[0]
	session.current_location_id = place.location_id
	# Üç borç: vadesi gelmemiş para borcu, vadesi geçmiş yüzlü borç ve bir
	# mal avansı. Üç satırın üçü de farklı okunmalı.
	# Avans **önce**: kredi hattı öbür borçlarla dolduktan sonra alınamaz -
	# ki bu doğru davranış, ama fotoğrafta üçüncü satır eksik kalıyordu.
	var item := ItemCatalog.get_item(String(place.produces[0]))
	if item != null:
		session.take_goods_advance(item, 10)
	var plain := session.debts.borrow("DEBT_CREDITOR_GUILD", 240, session.total_days_elapsed)
	plain.due_day = session.total_days_elapsed + 18
	var late := session.debts.borrow("DEBT_CREDITOR_MONEYLENDER", 150, session.total_days_elapsed)
	late.due_day = session.total_days_elapsed - 12
	session.people.ensure_city(place.location_id, session.total_days_elapsed)
	for person in session.people.city_people(place.location_id):
		if String(person.get("role", "")) == People.ROLE_LENDER:
			late.bind_to_person(String(person.get("id", "")), place.location_id)
			late.creditor_name = String(person.get("name", late.creditor_name))
			break
	print("  %s · borç %d" % [place.location_id, session.get_total_debt()])

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
