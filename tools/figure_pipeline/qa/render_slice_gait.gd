## Asama 3 kanit: siluetten kurulan deri (skin.tres), GERCEK yuruyus fazlari
## boyunca - CLAUDE.md'ye duslen notun ve bu kilavuzun 14.1'inin gerektirdigi
## "tek pozda bakma" testi.
##   godot --headless --script res://tools/figure_pipeline/qa/render_slice_gait.gd -- <skin.tres> <texture.png>
extends SceneTree

const PHASES: int = 4
const CELL: Vector2 = Vector2(360.0, 420.0)
const MARGIN: float = 16.0
const DRAW_H: float = 380.0
const OUT: String = "user://slice_gait.png"

var _skin: BeastSkin
var _tex: Texture2D

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	_skin = load(args[0])
	var img := Image.load_from_file(args[1])
	_tex = ImageTexture.create_from_image(img)

	var size := Vector2(MARGIN * 2.0 + CELL.x * PHASES, MARGIN * 2.0 + CELL.y)
	var root := Control.new()
	root.size = size
	var bg := ColorRect.new()
	bg.color = Color(0.85, 0.83, 0.79)
	bg.size = size
	root.add_child(bg)

	for i in PHASES:
		var phase := TAU * float(i) / float(PHASES)
		root.add_child(_cell(i, phase))

	get_root().add_child(root)
	get_root().content_scale_size = Vector2i(size)
	await process_frame
	await process_frame
	var image := get_root().get_texture().get_image()
	image.save_png(OUT)
	print("yazildi: ", ProjectSettings.globalize_path(OUT), " ", image.get_size())
	quit()

func _cell(index: int, phase: float) -> Control:
	var holder := Control.new()
	holder.position = Vector2(MARGIN + CELL.x * index, MARGIN)
	holder.size = CELL
	var label := Label.new()
	label.text = "faz %d/%d" % [index + 1, PHASES]
	label.add_theme_font_size_override("font_size", 12)
	holder.add_child(label)
	var painter := SlicePainter.new()
	painter.size = CELL
	painter.setup(_skin, _tex, phase)
	holder.add_child(painter)
	return holder

class SlicePainter extends Control:
	var skin: BeastSkin
	var tex: Texture2D
	var phase: float

	func setup(s: BeastSkin, t: Texture2D, p: float) -> void:
		skin = s; tex = t; phase = p
		queue_redraw()

	func _draw() -> void:
		var h: float = FigureRig.REF_H
		var joints := FigureRig.pose(Vector2.ZERO, h, phase, 1.0, 1.0)
		var scale: float = DRAW_H / h
		var anchor := Vector2(size.x * 0.65, size.y * 0.92)
		var base := Transform2D(Vector2(scale, 0.0), Vector2(0.0, scale), anchor)

		var xforms: Dictionary = {}
		for bone in skin.bone_names:
			var spec: Dictionary = FigureRig.BONES[bone]
			var a_rest: Vector2 = skin.joint(spec.a)
			var b_rest: Vector2 = skin.joint(spec.b)
			var a_now: Vector2 = joints[spec.a]
			var b_now: Vector2 = joints[spec.b]
			var theta := 0.0
			if (b_now - a_now).length() > 0.0001 and (b_rest - a_rest).length() > 0.0001:
				theta = (b_now - a_now).angle() - (b_rest - a_rest).angle()
			var x_axis := Vector2(1.0, 0.0).rotated(theta)
			var y_axis := Vector2(0.0, 1.0).rotated(theta)
			xforms[bone] = Transform2D(x_axis, y_axis, a_now - a_rest.rotated(theta))

		var verts := skin.vertices
		var ids := skin.bone_ids
		var weights := skin.bone_weights
		var points := PackedVector2Array()
		points.resize(verts.size())
		for i in verts.size():
			var v := verts[i]
			var p := Vector2.ZERO
			for n in BeastSkin.INFLUENCES:
				var w: float = weights[i * BeastSkin.INFLUENCES + n]
				if w > 0.0:
					var bone_name: String = skin.bone_names[ids[i * BeastSkin.INFLUENCES + n]]
					p += (xforms[bone_name] * v) * w
			points[i] = p

		draw_set_transform_matrix(base)
		var item := get_canvas_item()
		for layer in skin.layer_count():
			var v0 := skin.layer_vertex_offsets[layer]
			var v1 := skin.layer_vertex_offsets[layer + 1]
			RenderingServer.canvas_item_add_triangle_array(
				item, skin.layer_indices(layer), points.slice(v0, v1),
				PackedColorArray([Color.WHITE]), skin.layer_uvs(layer),
				PackedInt32Array(), PackedFloat32Array(), tex.get_rid()
			)
		draw_set_transform_matrix(Transform2D.IDENTITY)
