extends SceneTree

## Şehir dışı yürüyüş alanının görsel doğrulama aracı. **Test değil** -
## PNG basar (bkz. screenshot_road.gd, screenshot_city.gd).
##
## Sahnenin kendisi *yüklenmiyor*: `--script` kipinde autoload'lar
## kurulmuyor, o yüzden `GameState.get_session()` okuyan bir ekran bu
## araçta ayağa kalkmıyor (denendi: "Identifier not found: GameState").
## Onun yerine ekranın kullandığı bileşenler tek başına kuruluyor -
## doğrulanacak olan zaten onların görüntüsü.
##
## Koşturmak:
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_hub.gd

const SHOT_DIR: String = "user://hub_shots"
const GROUND_Y: float = 430.0
const VIEW_SIZE: Vector2i = Vector2i(1400, 620)

var _leader: WalkFigure
var _escorts: Array[WalkFigure] = []
var _wagons: Array[WagonFigure] = []
var _oxen: Array[WalkFigure] = []

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	var root := get_root()
	root.size = VIEW_SIZE

	var scenery := HubScenery.new()
	root.add_child(scenery)
	scenery.setup(
		Rect2(Vector2(-200.0, -160.0), Vector2(1800.0, 820.0)),
		GROUND_Y, WorldMapData.START_LOCATION_ID
	)

	# Kervan: atlı lider önde, iki yoldaş, iki vagon ve tayfaları -
	# world_hub'ın kurduğu dizilişin aynısı.
	_leader = _figure(
		WalkFigure.KIND_MOUNTED, ClassCatalog.GUARD,
		Vector2(150.0, 128.0), Vector2(900.0, GROUND_Y - 128.0)
	)
	_escorts.append(_figure(
		WalkFigure.KIND_PERSON, ClassCatalog.HUNTER,
		Vector2(46.0, 82.0), Vector2(806.0, GROUND_Y - 82.0)
	))
	_escorts.append(_figure(
		WalkFigure.KIND_PERSON, ClassCatalog.BREAKER,
		Vector2(46.0, 86.0), Vector2(742.0, GROUND_Y - 86.0)
	))

	for index in 2:
		var wagon := WagonFigure.new()
		wagon.position = Vector2(520.0 - float(index) * 250.0, GROUND_Y - 96.0)
		root.add_child(wagon)
		wagon.setup(Vector2(132.0, 96.0), index == 0)
		_wagons.append(wagon)
		# Vagonu çeken öküz - world_hub'daki dizilişin aynısı.
		_oxen.append(_figure(
			WalkFigure.KIND_OX, "bandit", Vector2(146.0, 86.0),
			Vector2(wagon.position.x + 152.0, GROUND_Y - 86.0)
		))
		for slot in 2:
			_figure(
				WalkFigure.KIND_PERSON, ClassCatalog.GUARD, Vector2(44.0, 76.0),
				Vector2(
					wagon.position.x + 74.0 - float(slot) * 34.0,
					GROUND_Y - 76.0 + float(slot) * 4.0
				)
			)

	await _settle()
	_save("01_duran_kervan.png")

	# Yürüyüş fazı ve tekerlek dönüşü ancak hareketle görünüyor.
	for _step in 24:
		_leader.advance(0.05, 9.0)
		for escort in _escorts:
			escort.advance(0.05, 8.0)
		for wagon in _wagons:
			wagon.roll(12.0)
		for ox in _oxen:
			ox.advance(0.05, 8.5)
		await process_frame
	await _settle()
	_save("02_yuruyen_kervan.png")

	print("Görüntüler: ", ProjectSettings.globalize_path(SHOT_DIR))
	quit(0)

func _figure(
	kind: String, archetype: String, figure_size: Vector2, at: Vector2
) -> WalkFigure:
	var figure := WalkFigure.new()
	figure.size = figure_size
	figure.position = at
	get_root().add_child(figure)
	figure.set_kind(
		kind, archetype, 1.0, CharacterData.get_skin_tone_color(1),
		kind == WalkFigure.KIND_PERSON
	)
	figure.set_phase_offset(at.x * 0.03)
	return figure

func _settle() -> void:
	for _frame in 5:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	var region := Rect2i(Vector2i.ZERO, Vector2i(
		mini(VIEW_SIZE.x, image.get_width()), mini(VIEW_SIZE.y, image.get_height())
	))
	image = image.get_region(region)
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", image.get_size())
