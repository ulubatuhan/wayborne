## Faz 0 olcumu: gercek yol sahnesinde (1920x1080) figurlerin ekran boyu.
## tests/screenshot_journey_screen.gd'nin sahne kurulumunun aynisi.
extends SceneTree
func _init() -> void:
	TranslationServer.set_locale("tr")
	var root := get_root()
	root.size = Vector2i(1920, 1080)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	for i in 8: await process_frame
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var state := root.get_node_or_null("GameState")
	var session: GameSession = state.call("get_session")
	var player := CharacterData.create("Kervanbasi", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(player, rng)
	session.owned_wagon_count = 2
	var dest := WorldMapData.get_location_by_id(WorldMapData.START_LOCATION_ID)
	session.start_journey(WorldMapData.START_LOCATION_ID, 6, 0.4, CaravanPlan.new(dest, 6))
	var screen: Control = load("res://scenes/game/road_journey.tscn").instantiate()
	root.add_child(screen)
	for i in 12: await process_frame
	var found: Array = []
	_collect(screen, found)
	for w in found:
		var sc: Vector2 = w.get_global_transform().get_scale()
		print("WalkFigure kind=", w.get("_kind"), " box=", w.size, " global_scale=", sc, " box_h_px=", w.size.y * sc.y, " fig_scale=", w.get("_scale"))
	print("viewport=", root.size)
	quit()
func _collect(n: Node, out: Array) -> void:
	if n is WalkFigure:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)
