## FigureActions'ın bütün kliplerini çubuk figür olarak basar - 3B render
## saatler sürüyor, bir pozun yanlışlığı burada saniyede görünür. Her satır
## bir klip, her hücre bir kare; zemin çizgisi, silah ve yay kirişi dahil.
##
##   godot --path . --rendering-driver opengl3 --script res://tests/screenshot_poses.gd
extends SceneTree

const CELL: Vector2 = Vector2(118.0, 205.0)
const H: float = 120.0
const PER_COLUMN: int = 5
const COLUMN_W: float = 960.0
const OUT: String = "user://poses.png"

class Sheet extends Control:
	var rows: Array = []

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.88, 0.86, 0.82))
		var font := ThemeDB.fallback_font
		for n in rows.size():
			var clip: String = rows[n]
			var r := n % PER_COLUMN
			var x0 := float(n / PER_COLUMN) * COLUMN_W
			draw_string(font, Vector2(x0 + 6, r * CELL.y + 16), clip, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.BLACK)
			for i in FigureActions.frame_count(clip):
				var ground := Vector2(x0 + 70.0 + i * CELL.x, (r + 1) * CELL.y - 12.0)
				draw_line(ground - Vector2(60, 0), ground + Vector2(60, 0), Color(0.5, 0.45, 0.4), 1.0)
				_figure(FigureActions.pose(clip, i, ground, H, 1.0))

	func _figure(j: Dictionary) -> void:
		for bone in FigureRig.BONES:
			var spec: Dictionary = FigureRig.BONES[bone]
			if not j.has(spec.a) or not j.has(spec.b):
				continue
			var col := Color(0.55, 0.5, 0.48) if spec.back else Color(0.15, 0.12, 0.1)
			if bone == FigureRig.WEAPON:
				col = Color(0.6, 0.15, 0.1)
			draw_line(j[spec.a], j[spec.b], col, 3.0 if bone != FigureRig.WEAPON else 2.0)
		draw_circle(j["head"], H * 0.058, Color(0.15, 0.12, 0.1))
		var draw_amt := float(j["draw"].x)
		if draw_amt > 0.0:
			draw_line(j["weapon_tip"], j["hand_back"], Color(0.2, 0.4, 0.8), 1.0)
			var bottom: Vector2 = j["hand_front"] * 2.0 - j["weapon_tip"]
			draw_line(bottom, j["hand_back"], Color(0.2, 0.4, 0.8), 1.0)

func _init() -> void:
	var sheet := Sheet.new()
	sheet.rows = FigureActions.CLIPS.keys()
	sheet.size = Vector2(1920, 1080)
	get_root().add_child(sheet)
	get_root().content_scale_size = Vector2i(sheet.size)
	get_root().size = Vector2i(sheet.size)
	await process_frame
	await process_frame
	var image := get_root().get_texture().get_image()
	image.save_png(OUT)
	print("yazildi: ", ProjectSettings.globalize_path(OUT), " ", image.get_size())
	quit()
