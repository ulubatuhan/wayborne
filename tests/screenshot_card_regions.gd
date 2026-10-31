extends SceneTree

## Olay kartı resminin bölgelere göre görünüşü (görev Y-G20). **Test değil** -
## PNG basar: `card_region_shots/tablo.png`, her bölge iki hücre: vebasız ve
## hemen altında vebalı. Resim aynı biyomun manzarası, yalnızca bölge
## değişiyor - kartın dili bölgeden gelir, karttan değil.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_card_regions.gd

const SHOT_DIR: String = "user://card_region_shots"
const CELL: Vector2i = Vector2i(460, 190)
const COLUMNS: int = 4
const GAP: int = 10
const BIOME: String = "steppe"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var regions: Array = CardRegionLook.LOOKS.keys()
	var bands := ceili(float(regions.size()) / float(COLUMNS))
	var frame := Vector2i(GAP + COLUMNS * (CELL.x + GAP), GAP + bands * 2 * (CELL.y + GAP))
	get_root().size = frame
	var ground := ColorRect.new()
	ground.color = Color(0.11, 0.10, 0.09)
	ground.size = Vector2(frame)
	get_root().add_child(ground)
	for index in regions.size():
		for plague in 2:
			var col := index % COLUMNS
			var row := (index / COLUMNS) * 2 + plague
			var look := CardRegionLook.look_for(String(regions[index]), plague == 1)
			var holder := Control.new()
			holder.clip_contents = true
			holder.position = Vector2(GAP + col * (CELL.x + GAP), GAP + row * (CELL.y + GAP))
			holder.size = Vector2(CELL)
			var vignette := EventVignette.new()
			vignette.biome = BIOME
			vignette.look = look
			vignette.size = Vector2(CELL)
			holder.add_child(vignette)
			# Örtü tam-çapalı: boyutu kabından alır (oyundaki gibi).
			holder.add_child(CardRegionLook.overlay(look))
			get_root().add_child(holder)
	for _frame in 6:
		await process_frame
	get_root().get_texture().get_image().get_region(Rect2i(Vector2i.ZERO, frame)).save_png("%s/tablo.png" % SHOT_DIR)
	print("bölgeler: ", ", ".join(PackedStringArray(regions)))
	quit()
