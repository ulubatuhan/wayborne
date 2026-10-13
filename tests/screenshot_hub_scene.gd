extends SceneTree

## Gerçek `world_hub.tscn`'i canlı bir oturumla açıp fotoğraflayan araç
## (test değil). `screenshot_hub.gd` kervanı elle kuruyor ve sahnenin
## kendisinin eklediklerini - şehir kapısı, kapı dışındaki yerleşim,
## değirmen, yarım vagonun arabası - göstermiyor. Lideri kapıya ve köyün
## önüne taşıyıp üç kare basar.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_hub_scene.gd

const SHOT_DIR: String = "user://hub_scene_shots"
const STOPS: Array = [[150.0, "01_degirmen"], [800.0, "02_koy"], [1640.0, "03_kapi"]]

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = Vector2i(1600, 900)
	await _settle()
	var state := get_root().get_node_or_null("GameState")
	var session: GameSession = state.call("get_session")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	session.start_playthrough(CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng)
	session.set_flag(GameSession.ONBOARDING_FLAG)
	session.owned_wagon_count = 2
	session.owned_donkeys = 1
	session.owned_half_wagons = 1
	session.owned_dogs = 1
	var hub: Node = load("res://scenes/world/world_hub.tscn").instantiate()
	get_root().add_child(hub)
	await _settle()
	for stop in STOPS:
		var player: Control = hub.get("_player")
		player.position.x = float(stop[0])
		for i in 90:
			await process_frame
		var image := get_root().get_texture().get_image()
		image.save_png("%s/%s.png" % [SHOT_DIR, stop[1]])
	quit()

func _settle() -> void:
	for i in 4:
		await process_frame
