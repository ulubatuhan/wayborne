extends SceneTree

## Yolda açılır harita (test değil, PNG basar): Vastrevar'dan Rivecande'ye
## giden kervan yolun %40'ında. Karolar `tools/worldmap/install_tiles.py`
## ile kurulmuş (ya da LFS'ten gelmiş) olmalı.
##
##   godot --path . --resolution 1920x1080 --script res://tests/screenshot_map_popup.gd

func _init() -> void:
	TranslationServer.set_locale("tr")
	WaybookTheme.install()
	var root := get_root()
	root.size = Vector2i(1920, 1080)
	var path := WorldMapData.get_route_path("vastrevar", "rivecande")
	var popup := MapPopup.new().setup("vastrevar", "rivecande", path, 0.4)
	root.add_child(popup)
	for _frame in 90:
		await process_frame
	root.get_texture().get_image().save_png("user://map_popup.png")
	print("yazildi: map_popup")
	quit()
