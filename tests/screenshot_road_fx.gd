extends SceneTree

## Zemin ve hava efektlerini **gerçek yol ekranında** fotoğraflayan araç
## (görev Y-G24). **Test değil** - hiçbir şey doğrulamaz, PNG basar.
##
## Neden gerekli: yapısal testler efektin havuza girdiğini görebilir ama
## ekranda göründüğünü göremez. Projenin kuralı bir işin ekranda görününce
## bittiği (Y-K01), ve bu iş baştan sona görünüşten ibaret.
##
## Her kare için ekran **yürür hâlde** birkaç saniye bırakılıyor: ayak
## basma, tekerlek teması ve yağmurun yere çarpması zamanla birikiyor,
## tek karede hiçbiri görünmez.
##
## Koşturmak:
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_road_fx.gd

const SHOT_DIR: String = "user://fx_shots"
const VIEW_SIZE: Vector2i = Vector2i(1920, 1080)
## Efektlerin birikmesi için her kareden önce bekleme.
const WARM_FRAMES: int = 150

## Fotoğraflanacak hâller: ad, hava, zemin, kar payı, nefes payı, kervanın
## **üstündeki** su ve kar (`Soaking`). Son ikisi zeminden ayrı: yol çamur
## olurken sırt kuru, kar erirken tersi olabilir.
const STATES: Array = [
	["01_kuru_toz", RouteWeather.CLEAR, {"wet": 0.0, "mud": 0.0, "snow": 0.0, "dust": 1.0}, 0.0, 0.0, 0.0, 0.0],
	["02_yagmur", RouteWeather.RAIN, {"wet": 0.78, "mud": 0.62, "snow": 0.0, "dust": 0.0}, 0.0, 0.0, 0.85, 0.0],
	["03_firtina", RouteWeather.STORM, {"wet": 1.0, "mud": 0.80, "snow": 0.0, "dust": 0.0}, 0.0, 0.0, 1.0, 0.0],
	["04_camur", RouteWeather.OVERCAST, {"wet": 0.30, "mud": 0.75, "snow": 0.0, "dust": 0.0}, 0.0, 0.35, 0.55, 0.0],
	["05_kar", RouteWeather.RAIN, {"wet": 0.10, "mud": 0.0, "snow": 0.85, "dust": 0.0}, 1.0, 1.0, 0.15, 0.75],
	["06_tipi", RouteWeather.STORM, {"wet": 0.05, "mud": 0.0, "snow": 1.0, "dust": 0.0}, 1.0, 1.0, 0.10, 1.0],
	["07_sis", RouteWeather.FOG, {"wet": 0.45, "mud": 0.35, "snow": 0.0, "dust": 0.0}, 0.0, 0.55, 0.45, 0.0],
	# Yağmur dindi, kervan hâlâ sırılsıklam: brandanın kenarı damlıyor.
	["09_islak_kervan", RouteWeather.OVERCAST, {"wet": 0.60, "mud": 0.55, "snow": 0.0, "dust": 0.0}, 0.0, 0.30, 1.0, 0.0],
	# Kar dindi, sırtlarda ve brandada duruyor.
	["10_karli_kervan", RouteWeather.OVERCAST, {"wet": 0.05, "mud": 0.0, "snow": 0.9, "dust": 0.0}, 1.0, 1.0, 0.10, 1.0],
]

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	var root := get_root()
	root.size = VIEW_SIZE
	DisplayServer.window_set_size(VIEW_SIZE)
	await _settle()
	_start_journey()

	var screen: Control = load("res://scenes/game/road_journey.tscn").instantiate()
	root.add_child(screen)
	await _settle()

	for state in STATES:
		_apply(screen, String(state[1]), state[2], float(state[3]), float(state[4]),
			float(state[5]), float(state[6]))
		for _frame in WARM_FRAMES:
			await process_frame
		_save("%s.png" % String(state[0]))

	# Tek bir efektin kendi karesi: katalog sayfası oyunun içinde.
	_apply(screen, RouteWeather.CLEAR, {"wet": 0.0, "mud": 0.0, "snow": 0.0, "dust": 0.0}, 0.0, 0.0, 0.0, 0.0)
	var front: FxLayer = screen.get("_fx_front")
	var caravan: RoadCaravan = screen.get("_caravan")
	var ground_y: float = caravan.get_ground_y()
	var ids := FxCatalog.ids()
	var shown := PackedStringArray()
	for id in ids:
		if String(FxCatalog.info(id).get("aile", "")) in ["perde", "sis"]:
			continue
		shown.append(id)
	var step := VIEW_SIZE.x / float(maxi(1, shown.size() + 1))
	for i in shown.size():
		front.emit(shown[i], Vector2(step * float(i + 1), ground_y), 2.0)
	# **Kare sayısı değil, geçen süre.** Yazılım render'ında bir kare ~100 ms
	# sürüyor, yani on dört kare 1.4 saniye: yarım saniyelik bir sıçrama o
	# ana kadar çoktan ölüp havuzdan düşmüş oluyor. İlk iki denemede
	# katalog sayfasının boş çıkması efektin zayıflığı değil, bu ölçüm
	# hatasıydı. İki kare, patlamanın tepesine denk geliyor.
	for _frame in 2:
		await process_frame
	_save("08_katalog.png")

	print("bitti")
	quit()

## Ekranın hava ve zemin durumunu doğrudan kurar. Normalde şafakta
## `_refresh_ground_fx` yazıyor; burada her hâli görmek için elle veriliyor.
func _apply(
	screen: Control, weather: String, cover: Dictionary, snow: float, breath: float,
	soak_wet: float = 0.0, soak_snow: float = 0.0
) -> void:
	var caravan: RoadCaravan = screen.get("_caravan")
	var band: TravelBand = screen.get("_band")
	screen.set("_weather", weather)
	screen.set("_snow_share", snow)
	screen.set("_ground_cover", cover)
	band.set_weather(weather)
	caravan.set_ground_cover(cover)
	caravan.set_breath_share(breath)
	screen.set("_soaking", {"wet": soak_wet, "snow": soak_snow})
	caravan.set_soaking(soak_wet, soak_snow, true)
	var visuals := RouteWeather.visuals(weather)
	var rain := float(visuals.get("rain", 0.0))
	var layers := WeatherCurtain.layers_for(
		rain, float(visuals.get("fog", 0.0)), snow
	)
	var curtains: Array[WeatherCurtain] = screen.get("_curtains")
	for curtain in curtains:
		curtain.set_layers(layers, rain, snow >= WeatherCurtain.SNOW_FULL)
	band.set_curtain_rain(rain > 0.01 and not layers.is_empty())
	var ground: FxLayer = screen.get("_fx_ground")
	var front: FxLayer = screen.get("_fx_front")
	ground.clear_all()
	front.clear_all()

func _start_journey() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var state := get_root().get_node_or_null("GameState")
	var session: GameSession = state.call("get_session")
	var player := CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(player, rng)
	session.owned_wagon_count = 2
	session.current_location_id = "rivecande"
	var destination_id := WorldMapData.START_LOCATION_ID
	var destination := WorldMapData.get_location_by_id(destination_id)
	var days := WorldMapData.get_route("rivecande", destination_id).travel_days
	var plan := CaravanPlan.new(destination, days)
	session.start_journey(destination_id, days, 0.38, plan)

func _settle() -> void:
	for _frame in 10:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", image.get_size())
