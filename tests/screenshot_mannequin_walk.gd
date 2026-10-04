## Mankeni YÜRÜRKEN basar - durağan bir kare gövdenin oranını gösterir,
## yürüyüşünü göstermez. `screenshot_walk_cadence.gd` kolonun temposunu
## ölçer; bu araç tek bir figürü büyütüp gövde sanatını denetler.
##
##   godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_mannequin_walk.gd -- body body_new
##
## Argümanlar istenen kadar beden klasörü (varsayılan: `body`), her biri
## kendi satırı - iki sanat yan yana karşılaştırılabilsin.
extends SceneTree

const PHASES: int = 8
const FIGURE_H: float = 300.0
const CELL: Vector2 = Vector2(190.0, 360.0)
const MARGIN: float = 24.0
const OUT: String = "user://mannequin_walk.png"

func _init() -> void:
	WaybookTheme.install()
	var variants: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		variants.append(String(arg))
	if variants.is_empty():
		variants.append(Wardrobe.BODY_ID)

	var size := Vector2(
		MARGIN * 2.0 + CELL.x * PHASES, MARGIN * 2.0 + CELL.y * variants.size()
	)
	var root := Control.new()
	root.size = size
	var bg := ColorRect.new()
	bg.color = Color(0.86, 0.84, 0.80)
	bg.size = size
	root.add_child(bg)

	for row in variants.size():
		for i in PHASES:
			root.add_child(_cell(variants[row], i, row))

	get_root().add_child(root)
	get_root().content_scale_size = Vector2i(size)
	await process_frame
	await process_frame
	var image := get_root().get_texture().get_image()
	image.save_png(OUT)
	print("yazildi: ", ProjectSettings.globalize_path(OUT), " ", image.get_size())
	quit()

func _cell(body_id: String, index: int, row: int) -> Control:
	var holder := Control.new()
	holder.position = Vector2(MARGIN + CELL.x * index, MARGIN + CELL.y * row)
	holder.size = CELL

	var label := Label.new()
	label.text = "%s · %d/%d" % [body_id, index + 1, PHASES]
	label.position = Vector2(4.0, 4.0)
	holder.add_child(label)

	var figure := WalkFigure.new()
	figure.size = Vector2(CELL.x, FIGURE_H)
	figure.position = Vector2(0.0, CELL.y - FIGURE_H - 8.0)
	figure.set_kind(
		WalkFigure.KIND_PERSON, "guard", 1.0, Color(0.72, 0.56, 0.42), false, {}, body_id
	)
	figure.set_phase_offset(TAU * float(index) / float(PHASES))
	figure.advance(0.0, 1.0)
	holder.add_child(figure)
	return holder
