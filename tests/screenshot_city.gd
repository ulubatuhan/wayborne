extends SceneTree

## Şehrin görsel doğrulama aracı. **Test değil** - PNG basar
## (bkz. screenshot_road.gd, screenshot_combat.gd).
##
## Beş şehir basıyor, çünkü yerleşim şehir tohumundan çıkıyor: "her şehir
## farklı görünüyor" iddiasının doğru olup olmadığı ancak beşini yan yana
## koyunca anlaşılıyor. Bir de balonun açık hâli, çünkü balon ekranın
## kenarına taşarsa var olma sebebi ortadan kalkıyor.
##
## Koşturmak:
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_city.gd

const SHOT_DIR: String = "user://city_shots"
const VIEW_SIZE: Vector2i = Vector2i(720, 520)

var _view: CityView

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	var root := get_root()
	root.size = Vector2i(900, 600)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.06, 0.06, 0.07)
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(VIEW_SIZE)
	root.add_child(backdrop)

	_view = CityView.new()
	_view.position = Vector2.ZERO
	_view.size = Vector2(VIEW_SIZE)
	root.add_child(_view)

	var index := 0
	for location in WorldMapData.get_locations():
		index += 1
		var session := GameSession.new()
		session.current_location_id = location.location_id
		_view.setup(session)
		await _settle()
		_save("%02d_%s.png" % [index, location.location_id])

	# Balon: hem ortadaki mekânda hem de sağ alt köşeye yakın bir noktada,
	# ekranın dışına taşmadığı görülsün.
	_view._update_hover(Vector2(VIEW_SIZE) * 0.5)
	await _settle()
	_save("90_balon_ortada.png")

	_view._update_hover(Vector2(VIEW_SIZE) - Vector2(40.0, 40.0))
	await _settle()
	_save("91_balon_kosede.png")

	print("Görüntüler: ", ProjectSettings.globalize_path(SHOT_DIR))
	quit(0)

func _settle() -> void:
	for _frame in 4:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	var region := Rect2i(Vector2i.ZERO, Vector2i(
		mini(VIEW_SIZE.x, image.get_width()), mini(VIEW_SIZE.y, image.get_height())
	))
	image = image.get_region(region)
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", image.get_size())
