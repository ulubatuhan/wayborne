extends SceneTree

## Yürüyüşün *hareketini* gösteren araç. **Test değil** - PNG basar.
##
## Tek kare bir yürüyüşün hızı hakkında hiçbir şey söylemiyor: bacaklar
## doğru yerde ama kadans altı kat hızlı olabilir ve kare bunu gizler.
## Bu araç iki saniyeyi eşit aralıklı karelere bölüp **tek bir şeride**
## basıyor, ve her karenin altına o anki zemin kaymasını işaretliyor -
## yani ayağın yere göre kayıp kaymadığı resimden okunabiliyor.
##
## Koşturmak:
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_walk_cadence.gd

const SHOT_DIR: String = "user://cadence_shots"
const DEFAULT_BAND: Vector2i = Vector2i(1920, 1080)
const SECONDS: float = 1.2
const FRAMES: int = 8
const STEP: float = 1.0 / 60.0
## Zemine çakılı işaretler (piksel aralığı): basan ayak her karede aynı
## işaretin üstünde kalmalı - kayan ayak işaretten uzaklaşır.
const TICK_SPACING: float = 48.0

var BAND: Vector2i = DEFAULT_BAND

var _band: TravelBand
var _caravan: RoadCaravan

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		BAND = Vector2i(int(args[0]), int(args[1]))
	var root := get_root()
	root.size = BAND

	_band = TravelBand.new()
	_band.size = Vector2(BAND)
	root.add_child(_band)
	_caravan = RoadCaravan.new()
	_band.add_actor_layer(_caravan)
	_band.ground_line_changed.connect(_caravan.set_ground_line)
	_caravan.column_length_changed.connect(_band.set_column_length)
	_caravan.configure(_build_session())
	# Ölçek yerleşimden geliyor (figür boyu): önce bir kare otursun.
	await _settle()
	_caravan.set_ground_speed(_caravan.get_walk_ground_speed())
	# Manzara da aynı hızla: yol ekranının ölçeği (bkz. road_journey
	# `_update_world_scale`) normal tempoda tam bu.
	_band.set_pixels_per_day(_caravan.get_walk_ground_speed() * JourneyClock.REAL_SECONDS_PER_DAY)
	# Kervan ağacın içinde, yani Godot da her karede `_process` çağırıyor.
	# İlk hâlinde bu açıktı ve kareler arasında *gerçek* kare süresi kadar
	# daha yürüyorlardı - üstelik yazılım rasterleyicisinde o süre uzun.
	# Sonuç: 2.6 ile 0.43 neredeyse aynı şeridi basıyordu, çünkü resmi
	# yazan benim adımım değil ağacın kendi `_process`'iydi. Ölçtüğünü
	# sandığın şeyi ölçmemek - bu depoda kaçıncı kez.
	_caravan.set_process(false)

	var frames: Array[Image] = []
	var elapsed := 0.0
	var next := 0.0
	# Zemin gerçek hızıyla kayıyor: 1x tempoda bir gün 45 saniye, bir gün
	# PIXELS_PER_DAY piksel - yani ayağın kayıp kaymadığı burada görülür.
	while frames.size() < FRAMES:
		if elapsed >= next:
			await _settle()
			frames.append(_with_ticks(get_root().get_texture().get_image()))
			next += SECONDS / float(FRAMES)
		_band.set_route_progress(0.0, elapsed / JourneyClock.REAL_SECONDS_PER_DAY)
		_caravan._process(STEP)
		elapsed += STEP

	_save_strip(frames, "yurume_%dpx.png" % BAND.y)
	print("zemin %.1f px/s, %d kare, %.1f sn" % [_caravan.get_ground_speed(), FRAMES, SECONDS])
	print("Görüntüler: ", ProjectSettings.globalize_path(SHOT_DIR))
	quit(0)

## Kervanın durduğu bant (zemin çizgisinin üstünde bir figür boyu, altında
## biraz) ve zemine çakılı kırmızı işaretler.
func _with_ticks(image: Image) -> Image:
	var ground := _caravan.get_ground_y()
	var person := _caravan.get_person_height()
	var top := int(maxf(0.0, ground - person * 1.9))
	var bottom := int(minf(float(image.get_height()), ground + person * 0.25))
	var ppd := _band.get_pixels_per_day()
	var day0: float = _band.get("_day_position")
	var first := floorf((day0 * ppd - float(image.get_width())) / TICK_SPACING)
	for k in int(float(image.get_width()) * 2.0 / TICK_SPACING) + 2:
		var x := _band.screen_x_for_day((first + k) * TICK_SPACING / ppd)
		if x >= 0.0 and x < image.get_width() - 2:
			image.fill_rect(Rect2i(int(x), int(ground) + 2, 2, int(person * 0.12)), Color(0.9, 0.1, 0.1))
	return image.get_region(Rect2i(0, top, image.get_width(), bottom - top))

## Kareleri alt alta tek bir şeride diziyor - göz iki kareyi yan yana
## görmeden hareketi okuyamıyor.
func _save_strip(frames: Array[Image], file_name: String) -> void:
	if frames.is_empty():
		return
	var w: int = frames[0].get_width()
	var h: int = frames[0].get_height()
	var sheet := Image.create(w, h * frames.size(), false, frames[0].get_format())
	for index in frames.size():
		sheet.blit_rect(frames[index], Rect2i(0, 0, w, h), Vector2i(0, h * index))
	sheet.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", sheet.get_size())

func _build_session() -> GameSession:
	var session := GameSession.new(2000, 20, 2)
	session.owned_wagon_count = 2
	session.adopt_dog()
	session.buy_donkey()
	var culture := CultureCatalog.get_cultures()[0]
	for index in 3:
		var character := CharacterData.create(
			culture.name_pool[index % culture.name_pool.size()],
			culture.culture_id, CharacterStats.new(),
			CharacterData.DEFAULT_HEIGHT_CM, index, ClassCatalog.GUARD
		)
		if index == 0:
			character.is_player = true
		session.party.append(character)
	return session

func _settle() -> void:
	for _frame in 3:
		await process_frame
