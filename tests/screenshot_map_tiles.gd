extends SceneTree

## Harita karo katmanı (test değil, PNG basar): tüm harita, orta yakınlık ve
## tam yakınlıkta bir şehir. Karolar `tools/worldmap/install_tiles.py` ile
## kurulmuş olmalı.
##
##   godot --path . --resolution 1920x1080 --script res://tests/screenshot_map_tiles.gd

const SHOTS: Array = [
	["01_tum_harita", Vector2(8006, 8006), -1.0],
	["02_orta_yakinlik", Vector2(6433, 3556), 0.25],
	["03_tam_yakin_sehir", Vector2(6433, 3556), 1.0],
]

func _init() -> void:
	var root := get_root()
	root.size = Vector2i(1920, 1080)
	var view := MapTileView.new()
	view.size = Vector2(1920, 1080)
	root.add_child(view)
	await process_frame
	if not view.has_tiles():
		print("karo yok: tools/worldmap/install_tiles.py ile kur")
		quit()
		return
	for shot in SHOTS:
		if float(shot[2]) < 0.0:
			view.reset_view()
		else:
			view.focus_on(shot[1], float(shot[2]))
		# Karolar kare başına sınırlı yükleniyor: dolmaları için bekle.
		for _frame in 60:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("user://map_%s.png" % shot[0])
		print("yazildi: map_", shot[0], " seviye=", MapTileView.level_for_zoom(view.zoom, view.max_level), " onbellek=", view.cached_tile_count())
	quit()
