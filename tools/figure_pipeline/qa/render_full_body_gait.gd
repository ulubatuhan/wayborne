## Tam vucut kaniti: FigureRig.DRAW_ORDER sirasiyla ustuste cizilen 14 ayri
## skin.tres (her kemigin kendi siluet-mesh'i), AYNI paylasilan poz (joints)
## uzerinden - tek bir kemigin degil, butun figurun gercek yuruyus fazlari
## + kol kaldirma pozu boyunca kopuksuz calistigini gosterir.
##   godot --headless --script res://tools/figure_pipeline/qa/render_full_body_gait.gd -- <variant_dir>
extends SceneTree

const CELL: Vector2 = Vector2(260.0, 460.0)
const MARGIN: float = 16.0
const DRAW_H: float = 400.0
const OUT: String = "user://full_body_gait.png"

# [etiket, phase, motion, lean] - yuruyusun birkac fazi + kol kaldirma
# (raised_arm pozu icin motion=0, phase=0, ama lean'i kolu kaldirmak icin
# ayri bir eksen olarak FigureRig.pose dogrudan desteklemiyor; bunun yerine
# yuruyusun genis adim fazini (kollar da o fazda en acik) "kol kaldirma"
# yerine kullaniyoruz - FigureRig'in tek hareket parametresi phase/motion).
const FRAMES: Array = [
	["dinlenme", 0.0, 0.0],
	["faz 1/4", 0.0, 1.0],
	["faz 2/4", TAU * 0.25, 1.0],
	["faz 3/4", TAU * 0.5, 1.0],
	["faz 4/4", TAU * 0.75, 1.0],
]

var _skins: Dictionary = {}
var _texs: Dictionary = {}

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var variant_dir: String = args[0]
	var layers_dir := variant_dir.path_join("layers")

	for bone in FigureRig.DRAW_ORDER:
		if bone == FigureRig.WEAPON:
			continue
		var skin_path := layers_dir.path_join(bone).path_join("skin.tres")
		var tex_path := layers_dir.path_join(bone).path_join("texture.png")
		if not FileAccess.file_exists(skin_path):
			print("UYARI: eksik katman, atlaniyor: ", bone)
			continue
		_skins[bone] = load(skin_path)
		var img := Image.load_from_file(tex_path)
		_texs[bone] = ImageTexture.create_from_image(img)

	var size := Vector2(MARGIN * 2.0 + CELL.x * FRAMES.size(), MARGIN * 2.0 + CELL.y)
	var root := Control.new()
	root.size = size
	var bg := ColorRect.new()
	bg.color = Color(0.85, 0.83, 0.79)
	bg.size = size
	root.add_child(bg)

	for i in FRAMES.size():
		var f: Array = FRAMES[i]
		root.add_child(_cell(i, f[0], f[1], f[2]))

	get_root().add_child(root)
	get_root().content_scale_size = Vector2i(size)
	await process_frame
	await process_frame
	var image := get_root().get_texture().get_image()
	image.save_png(OUT)
	print("yazildi: ", ProjectSettings.globalize_path(OUT), " ", image.get_size(), " katman sayisi: ", _skins.size())
	quit()

func _cell(index: int, label_text: String, phase: float, motion: float) -> Control:
	var holder := Control.new()
	holder.position = Vector2(MARGIN + CELL.x * index, MARGIN)
	holder.size = CELL
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	holder.add_child(label)
	var painter := FullBodyPainter.new()
	painter.size = CELL
	painter.setup(_skins, _texs, phase, motion)
	holder.add_child(painter)
	return holder

class FullBodyPainter extends Control:
	var skins: Dictionary
	var texs: Dictionary
	var phase: float
	var motion: float

	func setup(s: Dictionary, t: Dictionary, p: float, m: float) -> void:
		skins = s; texs = t; phase = p; motion = m
		queue_redraw()

	func _draw() -> void:
		var h: float = FigureRig.REF_H
		var joints := FigureRig.pose(Vector2.ZERO, h, phase, motion, 1.0)
		var scale: float = DRAW_H / h
		var anchor := Vector2(size.x * 0.5, size.y * 0.95)
		var base := Transform2D(Vector2(scale, 0.0), Vector2(0.0, scale), anchor)

		draw_set_transform_matrix(base)
		var item := get_canvas_item()
		for bone_key in FigureRig.DRAW_ORDER:
			if not skins.has(bone_key):
				continue
			var skin: BeastSkin = skins[bone_key]
			var tex: Texture2D = texs[bone_key]

			var xforms: Dictionary = {}
			for bone in skin.bone_names:
				if not FigureRig.BONES.has(bone):
					continue
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
						if xforms.has(bone_name):
							p += (xforms[bone_name] * v) * w
				points[i] = p

			for layer in skin.layer_count():
				var v0 := skin.layer_vertex_offsets[layer]
				var v1 := skin.layer_vertex_offsets[layer + 1]
				RenderingServer.canvas_item_add_triangle_array(
					item, skin.layer_indices(layer), points.slice(v0, v1),
					PackedColorArray([Color.WHITE]), skin.layer_uvs(layer),
					PackedInt32Array(), PackedFloat32Array(), tex.get_rid()
				)
		draw_set_transform_matrix(Transform2D.IDENTITY)
