extends SceneTree

## Yol manzarasının görsel doğrulama aracı. **Test değil** - hiçbir şeyi
## doğrulamaz, PNG basar (bkz. screenshot_combat.gd ve simulate_journeys.gd
## deseni).
##
## Savaş ekranında öğrenilen dersin aynısı: yapısal test düzeni doğrular,
## *görüntüyü* doğrulamaz. Savaş alanı "testler geçiyor" diye bitmiş
## sayılmış, alınan görüntü figürlerin renkli dikdörtgen ve ışığın ekranı
## yutan turuncu bir küre olduğunu göstermişti. Yolun beş biyomu, beş
## havası ve dört gün evresi var; hiçbirini görmeden "oldu" demek aynı
## hatayı tekrarlamak olurdu.
##
## Koşturmak:
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_road.gd

const SHOT_DIR: String = "user://road_shots"
const VIEW_SIZE: Vector2i = Vector2i(1500, 460)

## Her kare: dosya adı, biyom, hava, gün evresi, yolun katedilen oranı.
const SHOTS: Array[Dictionary] = [
	{"file": "01_bozkir_gunduz", "biome": "steppe", "weather": "clear",
	 "phase": JourneyClock.Phase.NOON, "progress": 0.18},
	{"file": "02_orman_sabah", "biome": "forest", "weather": "clear",
	 "phase": JourneyClock.Phase.MORNING, "progress": 0.35},
	{"file": "03_orman_yagmur", "biome": "forest", "weather": "rain",
	 "phase": JourneyClock.Phase.AFTERNOON, "progress": 0.45},
	{"file": "04_gol_aksam", "biome": "lake", "weather": "clear",
	 "phase": JourneyClock.Phase.EVENING, "progress": 0.55},
	{"file": "05_gol_sis", "biome": "lake", "weather": "fog",
	 "phase": JourneyClock.Phase.MORNING, "progress": 0.60},
	{"file": "06_dag_firtina", "biome": "mountain", "weather": "storm",
	 "phase": JourneyClock.Phase.AFTERNOON, "progress": 0.72},
	{"file": "07_dag_safak", "biome": "mountain", "weather": "clear",
	 "phase": JourneyClock.Phase.DAWN, "progress": 0.80},
	{"file": "08_bataklik_gece", "biome": "marsh", "weather": "overcast",
	 "phase": JourneyClock.Phase.NIGHT, "progress": 0.88},
	{"file": "09_varis_yakin", "biome": "steppe", "weather": "clear",
	 "phase": JourneyClock.Phase.EVENING, "progress": 0.97},
]

var _band: TravelBand
var _caravan: RoadCaravan

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	var root := get_root()
	root.size = VIEW_SIZE

	# Şeridin boyu elle veriliyor: headless pencere proje varsayılanında
	# açılıyor ve tam-dikdörtgen bir çapa şeridi 1080 piksele geriyordu -
	# oyunda hiç görülmeyecek bir oran.
	_band = TravelBand.new()
	_band.position = Vector2.ZERO
	_band.size = Vector2(VIEW_SIZE)
	root.add_child(_band)

	_caravan = RoadCaravan.new()
	_band.add_child(_caravan)
	_band.ground_line_changed.connect(_caravan.set_ground_line)
	_caravan.configure(_build_session())

	for shot in SHOTS:
		# `RouteTerrain` tohumdan üretiliyor, yani "bana orman ver" diye
		# bir kapısı yok - olmaması da doğru, yoksa oyun da araziyi
		# seçebilirdi. O yüzden istenen biyoma *sahip* bir rota arayıp
		# günü o parçanın ortasına koyuyoruz.
		#
		# İlk hâlinde yalnızca "sıfırıncı günde bu biyom mu" diye
		# bakıyordum ve sonra günü 0.35'e alıyordum: kare çoktan başka bir
		# parçaya düşmüş oluyordu, yani "orman" karesinde orman yoktu.
		# Ölçtüğünü sandığın şeyi ölçmemek - bu depoda dördüncü kez.
		var found := _terrain_with(String(shot.biome))
		_band.set_route(found.terrain)
		_band.set_weather(String(shot.weather))
		_band.set_phase(shot.phase, 0.45)
		var day: float = found.day
		_band.set_route_progress(day / float(found.terrain.total_days), day)
		_caravan.set_light(_band.get_light())
		_caravan.set_speed(1.0)
		await _settle()
		_save("%s.png" % String(shot.file))

	# Kamp: ateş, sıcak ışık ve duran figürler.
	_band.set_phase(JourneyClock.Phase.NIGHT, 0.3)
	_band.set_camping(true)
	_caravan.set_light(_band.get_light())
	_caravan.set_speed(0.0)
	await _settle()
	_save("10_kamp.png")

	# Lider kolona indi: kervanın önü işaretli, lider arkada.
	_band.set_camping(false)
	_band.set_phase(JourneyClock.Phase.NOON, 0.5)
	_caravan.set_light(_band.get_light())
	_caravan.set_speed(1.0)
	_caravan.set_detached(true)
	_caravan.set_leader_offset(-320.0)
	await _settle()
	_save("11_lider_kolonda.png")

	print("Görüntüler: ", ProjectSettings.globalize_path(SHOT_DIR))
	quit(0)

## İstenen biyomu taşıyan bir rota ve o parçanın ortasındaki gün.
func _terrain_with(biome: String) -> Dictionary:
	for attempt in 600:
		var terrain := RouteTerrain.build("shot_probe_%d" % attempt, 6)
		for segment in terrain.segments:
			if String(segment.biome) != biome:
				continue
			var middle: float = (float(segment.from_day) + float(segment.to_day)) * 0.5
			return {"terrain": terrain, "day": middle}
	var fallback := RouteTerrain.build("shot_probe_0", 6)
	return {"terrain": fallback, "day": 1.0}

## Dört sınıflı bir parti ve iki vagon: kolonun tamamı tek karede
## görülebilsin.
func _build_session() -> GameSession:
	var session := GameSession.new()
	session.owned_wagon_count = 2
	var culture := CultureCatalog.get_cultures()[0]
	var classes: Array[String] = [
		ClassCatalog.GUARD, ClassCatalog.HUNTER, ClassCatalog.BREAKER
	]
	for index in classes.size():
		var character := CharacterData.create(
			culture.name_pool[index % culture.name_pool.size()],
			culture.culture_id, CharacterStats.new(),
			CharacterData.DEFAULT_HEIGHT_CM + (index - 1) * 14, index,
			classes[index]
		)
		if index == 0:
			character.is_player = true
		session.party.append(character)
	return session

func _settle() -> void:
	for _frame in 5:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	# Yalnızca şeridin durduğu bölge: pencerenin kalanı boş ve karenin
	# oranını bozuyor.
	var region := Rect2i(Vector2i.ZERO, Vector2i(
		mini(VIEW_SIZE.x, image.get_width()), mini(VIEW_SIZE.y, image.get_height())
	))
	image = image.get_region(region)
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", image.get_size())
