extends SceneTree

## Tek kararlık pazarlığı (P1, P2, P4) pazar ekranında fotoğraflayan araç.
## **Test değil** - PNG basar.
##
## Neden gerekli: değişen şey üç düğme, şans satırı ve kıtlıkta değişen
## cümle. Yapısal test sayıları doğrular, satırın sığıp sığmadığını ve
## düğmelerin okunup okunmadığını göremez (Y-K01).
##
## Koşturmak:
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_haggling.gd

const SHOT_DIR: String = "user://haggle_shots"
const VIEW: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var root := get_root()
	root.size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()
	# Autoload'lar `_init` anında henüz ağaçta değil: dil ilk beklemeden
	# sonra kuruluyor. (TranslationServer'ı doğrudan kurmak yetmez;
	# UserSettings açılışta kayıtlı dili geri yazıyor.)
	get_root().get_node("UserSettings").call("set_locale", "tr")

	# Dört kare: açılış (üç düğme), direnip kaybetmiş masa, kıtlıkta
	# "Üstele" ve üstelemenin sonucu.
	await _shoot("01_acilis", 1, false, "")
	await _shoot("02_kaybedilmis_direnis", 1, false, "lose")
	await _shoot("03_kitlikta_ustele", 320, true, "")
	await _shoot("04_ustelenmis", 320, true, "win")

	print("bitti")
	quit()

func _shoot(name: String, day: int, want_scarcity: bool, push: String) -> void:
	_setup(day, want_scarcity)
	var screen: Control = load("res://scenes/game/market.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	# Kefeye iki kalem koy ve pazarlığı aç: oyuncunun yaptığı sıra
	# (`_select_buy` satıra tıklamanın ta kendisi).
	var shop: Array = screen.get("_shop_items")
	var put := 0
	for entry in shop:
		var item: Item = entry
		if not MarketPricing.buy_block_reason(item, screen.get("_current_location")).is_empty():
			continue
		screen.call("_select_buy", item)
		put += 1
		if put >= 2:
			break
	await _settle()
	screen.call("_on_haggle_pressed")
	await _settle()
	if not push.is_empty():
		_force_push(screen, push == "win")
		await _settle()
	_save("%s.png" % name)
	screen.queue_free()
	await _settle()

## Zarı beklemek yerine sonucu doğrudan kuruyor: fotoğrafın konusu
## sonucun görüntüsü, zarın kendisi değil.
func _force_push(screen: Control, won: bool) -> void:
	var holder: Node = screen.get("_haggle_holder")
	if holder == null:
		return
	for child in holder.get_children():
		if not (child is HagglingPanel):
			continue
		var panel := child as HagglingPanel
		var rng := RandomNumberGenerator.new()
		# Kazanma şansı tavanda bile 0.85; 0.0 her zaman kazanır, 0.999
		# her zaman kaybeder.
		rng.seed = _seed_for(won)
		panel.set("_rng", rng)
		panel.call("_on_push_pressed")
		return

func _seed_for(won: bool) -> int:
	var rng := RandomNumberGenerator.new()
	for candidate in range(1, 500):
		rng.seed = candidate
		var roll := rng.randf()
		if won and roll < 0.1:
			return candidate
		if not won and roll > 0.95:
			return candidate
	return 1

func _setup(day: int, want_scarcity: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.total_days_elapsed = day
	session.wallet.earn(4000)
	# Kıtlığın derecesi bölgeye ve güne bağlı; en kıt bölgeyi seç.
	var chosen: Location = null
	var best_degree := -1.0
	for place in WorldMapData.get_locations():
		if place.settlement_type != SettlementRules.CITY:
			continue
		var degree := Scarcity.degree(place.region, day)
		if want_scarcity:
			if degree > best_degree:
				best_degree = degree
				chosen = place
		elif chosen == null or degree < best_degree or best_degree < 0.0:
			best_degree = degree
			chosen = place
	if chosen == null:
		chosen = WorldMapData.get_locations()[0]
	session.current_location_id = chosen.location_id
	print("  %s gün %d kıtlık %.2f" % [chosen.location_id, day, best_degree])

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
