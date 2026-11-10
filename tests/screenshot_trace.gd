extends SceneTree

## H3'ün ekran doğrulaması (Y-K01): bir kararın karşılığı geri döndüğünde
## oyuncu bunu **nereden** okuyor. **Test değil** - PNG basar.
##
## İki ekran: pazar tezgâhı (fiyat dönüşü, MarketPricing LAYER_EVENT'in
## sebep satırı) ve defterin yol günlüğü sayfası (dönüşün cümlesi, yeri
## adıyla anar). Yapısal test çarpanın değiştiğini görür; ekran görüntüsü
## oyuncunun bunu okuyabildiğini.
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_trace.gd

const SHOT_DIR: String = "user://trace_shots"
const VIEW: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()
	get_root().get_node("UserSettings").call("set_locale", "tr")
	var session := _session()
	await _market(session)
	await _waybook(session)
	await _accounts(session)
	await _brief(session)
	quit()

func _session() -> GameSession:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var session: GameSession = get_root().get_node("GameState").call("get_session")
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	session.total_days_elapsed = 120
	session.wallet.earn(3000)
	# Kriz fiyatından satılmış bir şehir: kin izi olgunlaşmış, karşılığı
	# varışta tezgâhta geliyor.
	session.note_trace_action("vurgun")
	var trace: Trace = session.leave_trace(
		Trace.TYPE_GRUDGE, Trace.BEARER_CITY, session.current_location_id, -1,
		Trace.DELAY_SHORT, Trace.RETURN_PRICE, 0.8)
	trace.olgunluk_gunu = session.total_days_elapsed
	var note := session.resolve_trace_return()
	print("  dönüş: %s" % note)
	# İkinci bir hesap daha: vadesi dolmamış bir minnet, sayfada üç durum
	# birden görünsün diye (dönen, bekleyen).
	session.note_trace_action("merhamet")
	session.leave_trace(
		Trace.TYPE_GRATITUDE, Trace.BEARER_CITY, session.current_location_id, 1,
		Trace.DELAY_LONG, Trace.RETURN_FACE, 0.6)
	return session

func _market(_session: GameSession) -> void:
	var screen: Control = load("res://scenes/game/market.tscn").instantiate()
	get_root().add_child(screen)
	await _settle()
	_save("01_pazar_iz.png")
	screen.queue_free()
	await _settle()

func _waybook(session: GameSession) -> void:
	var panel := WaybookPanel.new().setup(session)
	get_root().add_child(panel)
	await _settle()
	panel.call("set_journal_page", true)
	await _settle()
	_save("02_defter_gunluk.png")
	panel.queue_free()
	await _settle()

func _accounts(session: GameSession) -> void:
	var panel := WaybookPanel.new().setup(session)
	get_root().add_child(panel)
	await _settle()
	panel.call("set_accounts_page", true)
	await _settle()
	_save("03_acik_hesaplar.png")
	panel.queue_free()
	await _settle()

## Şehir özeti: dönen bir `yuz` izi kapıda bekleyeni adıyla söylüyor.
func _brief(session: GameSession) -> void:
	session.note_trace_action("kovma")
	var face: Trace = session.leave_trace(
		Trace.TYPE_GRUDGE, Trace.BEARER_CITY, session.current_location_id, -1,
		Trace.DELAY_SHORT, Trace.RETURN_FACE, 0.7)
	face.olgunluk_gunu = session.total_days_elapsed
	print("  yüz dönüşü: %s" % session.resolve_trace_return())
	var panel := CityBriefPanel.new()
	get_root().add_child(panel)
	panel.setup(session)
	await _settle()
	await _settle()
	_save("04_sehir_ozeti.png")
	panel.queue_free()
	await _settle()

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
