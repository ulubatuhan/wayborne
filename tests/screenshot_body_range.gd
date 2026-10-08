## Beden aralığını basar: her satır bir varyant (cinsiyet x kilo), sütunlar
## boy (155 / 172 / 200 / 230 / 250 cm) ve dört ten rengi. Figürler yürür,
## hepsi aynı zemin çizgisinde: boy orantılı mı, ten rengi değişiyor mu,
## varyantlar ayırt ediliyor mu - tek bakışta.
##
##   godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_body_range.gd [-- body_male_average ...]
extends SceneTree

const HEIGHTS: Array[int] = [155, 172, 200, 230, 250]
const CELL: Vector2 = Vector2(120.0, 250.0)
const FIGURE_H: float = 150.0
const MARGIN: float = 20.0
const OUT: String = "user://body_range.png"

func _init() -> void:
	WaybookTheme.install()
	var variants: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		variants.append(String(arg))
	if variants.is_empty():
		for g in Wardrobe.GENDER_KEYS:
			for w in Wardrobe.BODY_WEIGHT_KEYS:
				variants.append("body_%s_%s" % [g, w])
	var cols := HEIGHTS.size() + 4
	var size := Vector2(MARGIN * 2.0 + 150.0 + CELL.x * cols, MARGIN * 2.0 + CELL.y * variants.size())
	var root := Control.new()
	root.size = size
	var bg := ColorRect.new()
	bg.color = Color(0.86, 0.84, 0.80)
	bg.size = size
	root.add_child(bg)
	for row in variants.size():
		var label := Label.new()
		label.text = variants[row]
		label.position = Vector2(MARGIN, MARGIN + CELL.y * row + CELL.y * 0.5)
		root.add_child(label)
		var ground := ColorRect.new()
		ground.color = Color(0.5, 0.45, 0.4)
		ground.size = Vector2(size.x - MARGIN * 2.0, 2.0)
		ground.position = Vector2(MARGIN, MARGIN + CELL.y * (row + 1) - 10.0)
		root.add_child(ground)
		for col in cols:
			var cm := HEIGHTS[col] if col < HEIGHTS.size() else CharacterData.DEFAULT_HEIGHT_CM
			var tone := 1 if col < HEIGHTS.size() else col - HEIGHTS.size()
			var f := WalkFigure.new()
			f.size = Vector2(CELL.x, FIGURE_H)
			f.position = Vector2(MARGIN + 150.0 + CELL.x * col, MARGIN + CELL.y * (row + 1) - 10.0 - FIGURE_H)
			f.set_kind(
				WalkFigure.KIND_PERSON, "guard", CharacterData.height_scale_for(cm),
				CharacterData.get_skin_tone_color(tone), false, {}, variants[row]
			)
			f.set_phase_offset(1.3)
			f.advance(0.0, 1.0)
			root.add_child(f)
			if row == 0:
				var head := Label.new()
				head.text = ("%d cm" % cm) if col < HEIGHTS.size() else ("ten %d" % tone)
				head.position = Vector2(MARGIN + 150.0 + CELL.x * col + 20.0, 2.0)
				root.add_child(head)
	get_root().add_child(root)
	get_root().content_scale_size = Vector2i(size)
	await process_frame
	await process_frame
	var image := get_root().get_texture().get_image()
	image.save_png(OUT)
	print("yazildi: ", ProjectSettings.globalize_path(OUT), " ", image.get_size())
	quit()
