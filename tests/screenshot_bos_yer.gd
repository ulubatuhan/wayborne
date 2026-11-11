extends SceneTree

## H7'nin ekran doğrulaması (Y-K01): Boş Yer ateşin başında **görünüyor**
## mu - gidenin koltuğuna kimse oturmuyor mu. **Test değil** - PNG basar.
## İki kare yan yana: dolu ateş ve bir yeri boş bırakılmış ateş.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x900x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_bos_yer.gd

const OUT: String = "user://bos_yer.png"
const BAND: Vector2i = Vector2i(1920, 900)
const DT: float = 1.0 / 30.0
## Kamp kurulup herkesin yerleşmesi için gereken süre (bkz. screenshot_camp).
const SETTLE_SECONDS: float = 12.0

var _band: TravelBand
var _caravan: RoadCaravan

func _init() -> void:
	TranslationServer.set_locale("tr")
	WaybookTheme.install()
	get_root().size = BAND
	_band = TravelBand.new()
	_band.size = Vector2(BAND)
	get_root().add_child(_band)
	_caravan = RoadCaravan.new()
	_band.add_actor_layer(_caravan)
	_band.ground_line_changed.connect(_caravan.set_ground_line)
	_caravan.column_length_changed.connect(_band.set_column_length)
	_band.set_phase(JourneyClock.Phase.EVENING, 0.6)
	var shots: Array[Image] = []
	for empty in [false, true]:
		shots.append(await _shoot(empty))
	_compose(shots)
	quit()

func _shoot(empty_seat: bool) -> Image:
	_caravan.configure(_build_session())
	_caravan.set_process(false)
	_caravan.set_light(_band.get_light())
	_band.set_camping(false)
	_caravan.set_camping(false)
	for _frame in 4:
		await process_frame
	_caravan.set_empty_seat(empty_seat)
	_band.set_camping(true)
	_caravan.set_camping(true)
	var elapsed := 0.0
	while elapsed < SETTLE_SECONDS:
		_caravan._process(DT)
		elapsed += DT
	_caravan.queue_redraw()
	for child in _caravan.get_children():
		(child as CanvasItem).queue_redraw()
	for _frame in 3:
		await process_frame
	return get_root().get_texture().get_image()

func _build_session() -> GameSession:
	var session := GameSession.new(300, 40, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	session.add_to_party(CharacterData.create("Yoldaş", CultureCatalog.NOMAD, CharacterStats.new()))
	return session

func _compose(shots: Array[Image]) -> void:
	var first := shots[0]
	var sheet := Image.create(first.get_width(), first.get_height() * shots.size(), false, Image.FORMAT_RGBA8)
	for index in shots.size():
		var img: Image = shots[index]
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(0, index * first.get_height()))
	sheet.save_png(OUT)
	print("  -> ", OUT)
