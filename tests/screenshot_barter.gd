extends SceneTree

## Takası (P6) pazar ekranında fotoğraflayan araç. **Test değil** - PNG basar.
##
## Neden gerekli: değişen şey terazinin sağ kefesi. Testler takasın payını
## ve kolun eğimini doğruluyor; iki kefede de mal olduğunun *görülmesini*
## yalnız ekran gösterir (Y-K01).
##
## Koşturmak:
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_barter.gd

const SHOT_DIR: String = "user://barter_shots"
const VIEW: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var root := get_root()
	root.size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()
	get_root().get_node("UserSettings").call("set_locale", "tr")

	await _shoot("01_altinla", false)
	await _shoot("02_takas", true)
	print("bitti")
	quit()

func _shoot(file_name: String, barter: bool) -> void:
	_setup()
	var screen: Control = load("res://scenes/game/market.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	_fill_basket(screen)
	await _settle()
	if barter:
		screen.call("_on_barter_pressed")
		await _settle()
		_offer_cargo(screen)
		await _settle()
	# Yay yerine otursun: fotoğraf kolun hedefini göstersin.
	var scale: Node = screen.get("_scale")
	if scale != null:
		scale.call("settle_now")
	await _settle()
	_save("%s.png" % file_name)
	screen.queue_free()
	await _settle()

func _fill_basket(screen: Control) -> void:
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

func _offer_cargo(screen: Control) -> void:
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	for item_id in ["provisions", "test_cloth", "test_furs"]:
		if session.get_total_quantity(item_id) <= 0:
			continue
		var item := ItemCatalog.get_item(item_id)
		if item == null:
			continue
		screen.call("_offer_more", item)
		screen.call("_offer_more", item)
		return

func _setup() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.total_days_elapsed = 320
	session.wallet.earn(4000)
	var chosen: Location = null
	var best := -1.0
	for place in WorldMapData.get_locations():
		if place.settlement_type != SettlementRules.CITY:
			continue
		var degree := Scarcity.degree(place.region, 320)
		if degree > best:
			best = degree
			chosen = place
	if chosen == null:
		chosen = WorldMapData.get_locations()[0]
	session.current_location_id = chosen.location_id
	# Verecek bir şeyi olsun: kargo boşsa takas ekranı boş görünür.
	session.add_to_cargo(ItemCatalog.get_item("test_cloth"), 6)
	print("  %s kıtlık %.2f" % [chosen.location_id, best])

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
