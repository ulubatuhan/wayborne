extends SceneTree

## Ana menüyü fotoğraflayan araç. **Test değil** - hiçbir şey doğrulamaz,
## PNG basar (bkz. screenshot_road.gd).
##
## Menü uzun süre çizilmemiş tek ekrandı ve kimse fark etmedi, çünkü
## yapısal testler yerleşimi doğruluyor, görünümü değil. Oyunun ilk
## gördüğü kare bu.
##
## Koşturmak:
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_menu.gd

const SHOT_DIR: String = "user://menu_shots"
const VIEW_SIZE: Vector2i = Vector2i(1920, 1080)

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	var root := get_root()
	root.size = VIEW_SIZE
	await _settle()

	var screen: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(screen)
	await _settle()
	_save("01_baslik_ekrani.png")

	# "Bir tuşa basın" evresinden menüye - sahne değişmeden, aynı ekranın
	# canlı kalan bir geçişi (bkz. main_menu.gd'nin dosya başı notu). Gerçek
	# bir tuş basımını simüle etmek gerekiyor, çünkü geçiş `_unhandled_input`
	# üzerinden tetikleniyor.
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_SPACE
	key_event.pressed = true
	Input.parse_input_event(key_event)
	await _settle()
	# Belirme animasyonu (`REVEAL_SECONDS` + kademeler) bitene kadar bekle.
	for _frame in 60:
		await process_frame
	_save("02_ana_menu.png")

	quit()

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", image.get_size())
