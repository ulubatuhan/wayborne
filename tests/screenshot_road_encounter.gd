extends SceneTree

## Yolda yaklaşan olay işaretinin (`RoadEncounter`) ve savaş sahnesinin
## görsel doğrulaması. **Test değil** - `screenshot_road.gd` deseninin
## aynısı, PNG basar.
##
## Koşturmak:
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_road_encounter.gd

const SHOT_DIR: String = "user://encounter_shots"
const VIEW_SIZE: Vector2i = Vector2i(1920, 320)

var _band: TravelBand
var _caravan: RoadCaravan

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	var root := get_root()
	root.size = VIEW_SIZE

	_band = TravelBand.new()
	_band.position = Vector2.ZERO
	_band.size = Vector2(VIEW_SIZE)
	root.add_child(_band)

	_caravan = RoadCaravan.new()
	_band.add_actor_layer(_caravan)
	_band.ground_line_changed.connect(_caravan.set_ground_line)
	_caravan.column_length_changed.connect(_band.set_column_length)

	var session := GameSession.new()
	session.caravan.wagon_count = 2
	session.party = [CharacterData.create("Deneme", CultureCatalog.NOMAD, CharacterStats.new())]
	_caravan.configure(session)
	_caravan.set_speed(1.0)

	_band.set_route(RouteTerrain.build("test|route", 6))
	_band.set_weather(RouteWeather.CLEAR)
	_band.set_phase(JourneyClock.Phase.NOON, 0.5)
	_band.set_route_progress(0.15, 0.9)
	_caravan.set_light(_band.get_light())
	await _settle()

	for kind in ["wolf", "bandit", "guard", "clerk"]:
		var marker := RoadEncounter.new()
		marker.setup(kind)
		_band.add_actor_layer(marker)
		marker.set_screen_position(_band.screen_position_for_day(1.25))
		await _settle()
		_save("marker_%s.png" % kind)
		marker.queue_free()
		await _settle()

	# Savaş sahnesi: `_band`'in yerini `CombatPanel` alsaydı görüneceği hâl.
	var stage := VBoxContainer.new()
	stage.position = Vector2.ZERO
	stage.size = Vector2(VIEW_SIZE)
	root.add_child(stage)
	var panel := CombatPanel.new()
	stage.add_child(panel)
	var party: Array[CharacterData] = [
		CharacterData.create("Kaptan", CultureCatalog.NOMAD, CharacterStats.new()),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	panel.start_combat(party, 0.4, rng, 0, "wildlife", "")
	await _settle()
	_save("combat_stage.png")

	quit()

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
