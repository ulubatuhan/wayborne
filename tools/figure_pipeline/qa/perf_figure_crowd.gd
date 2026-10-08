## Asama 0: Performans testi - Yol A (mevcut BeastSkin/BeastRig.skin_deform).
## 50 figur, her biri 5 derinlik katmani x (govde+4 parca) = 25 mesh'e esdeger
## ~3000 vertex, vertex basina en fazla 3 kemik agirlikli (BeastSkin.INFLUENCES),
## farkli yuruyus fazlarinda. 600 kare boyunca kare suresi + yalnizca
## deform+draw suresi ayri olculur.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tools/figure_pipeline/qa/perf_figure_crowd.gd
extends SceneTree

const FIGURE_COUNT: int = 50
const FRAMES: int = 600
const TARGET_VERTS_PER_FIGURE: int = 3000
const OUT: String = "user://perf_path_a.json"

# BeastRig'in gercek 15 kemigi - gercek skin_deform/draw_skin'i, gercek bir
# tur kaydina ihtiyac duymadan calistirabilmek icin ayni bone_names kumesi.
const BONE_NAMES: PackedStringArray = [
	"body", "neck", "head", "tail",
	"hind_far_upper", "hind_far_lower", "hind_far_foot",
	"fore_far_upper", "fore_far_lower", "fore_far_foot",
	"hind_near_upper", "hind_near_lower", "hind_near_foot",
	"fore_near_upper", "fore_near_lower", "fore_near_foot",
]
# Her kemigin REF_H-yerel (a -> b) dogrultusu - sentetik, yalnizca bir
# izgaranin nereye yerlesecegini belirler, gercek bir hayvanin olcumu degil.
const BONE_REST: Dictionary = {
	"body": [Vector2(-70, 0), Vector2(70, 0)],
	"neck": [Vector2(70, 0), Vector2(110, -60)],
	"head": [Vector2(110, -60), Vector2(150, -80)],
	"tail": [Vector2(-70, 0), Vector2(-120, 10)],
	"hind_far_upper": [Vector2(-60, 10), Vector2(-60, 60)],
	"hind_far_lower": [Vector2(-60, 60), Vector2(-60, 110)],
	"hind_far_foot": [Vector2(-60, 110), Vector2(-60, 130)],
	"fore_far_upper": [Vector2(60, 10), Vector2(60, 60)],
	"fore_far_lower": [Vector2(60, 60), Vector2(60, 110)],
	"fore_far_foot": [Vector2(60, 110), Vector2(60, 130)],
	"hind_near_upper": [Vector2(-55, 10), Vector2(-55, 60)],
	"hind_near_lower": [Vector2(-55, 60), Vector2(-55, 110)],
	"hind_near_foot": [Vector2(-55, 110), Vector2(-55, 130)],
	"fore_near_upper": [Vector2(55, 10), Vector2(55, 60)],
	"fore_near_lower": [Vector2(55, 60), Vector2(55, 110)],
	"fore_near_foot": [Vector2(55, 110), Vector2(55, 130)],
}

var _skin: BeastSkin
var _tex: Texture2D
var _figures: Array = []  # [{phase, canvas}]
var _frame_times: PackedFloat32Array = []
var _skin_times: PackedFloat32Array = []
var _frame_count: int = 0
var _t_frame_start: int = 0

func _build_synthetic_skin() -> BeastSkin:
	var per_bone := int(ceil(float(TARGET_VERTS_PER_FIGURE) / float(BONE_NAMES.size())))
	var cols := 8
	var rows := int(ceil(float(per_bone) / float(cols)))
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var bone_ids := PackedInt32Array()
	var bone_weights := PackedFloat32Array()
	var indices := PackedInt32Array()
	var layer_v_off := PackedInt32Array([0])
	var layer_i_off := PackedInt32Array([0])
	var layer_tex := PackedStringArray()
	var layer_far := PackedInt32Array()

	for bi in BONE_NAMES.size():
		var bone_name: String = BONE_NAMES[bi]
		var ab: Array = BONE_REST[bone_name]
		var a: Vector2 = ab[0]
		var b: Vector2 = ab[1]
		var dir := (b - a)
		var perp := Vector2(-dir.y, dir.x).normalized()
		var half_width := 14.0
		var base := verts.size()
		for r in rows:
			var t := float(r) / float(maxi(rows - 1, 1))
			var center := a.lerp(b, t)
			for c in cols:
				var s := (float(c) / float(maxi(cols - 1, 1))) * 2.0 - 1.0
				var p := center + perp * (half_width * s)
				verts.append(p)
				uvs.append(Vector2(float(c) / float(cols - 1), t))
				# Govdeye/komsu kemige hafif agirlik - INFLUENCES=3 dolu kullanilsin diye.
				var next_bi := mini(bi + 1, BONE_NAMES.size() - 1)
				var own_w := 0.8
				bone_ids.append(bi); bone_weights.append(own_w)
				bone_ids.append(next_bi); bone_weights.append(0.15)
				bone_ids.append(0); bone_weights.append(0.05)
		for r in rows - 1:
			for c in cols - 1:
				var i0 := base + r * cols + c
				var i1 := base + r * cols + c + 1
				var i2 := base + (r + 1) * cols + c
				var i3 := base + (r + 1) * cols + c + 1
				indices.append(i0); indices.append(i1); indices.append(i2)
				indices.append(i1); indices.append(i3); indices.append(i2)
		layer_tex.append("perf_part_%d" % bi)
		layer_far.append(0)
		layer_v_off.append(verts.size())
		layer_i_off.append(indices.size())

	var skin := BeastSkin.new()
	skin.ref_h = 256.0
	skin.joint_names = PackedStringArray([
		"hip_top", "shoulder_top", "saddle", "neck_base", "poll", "muzzle",
		"tail_root", "tail_tip",
		"hind_far_root", "hind_far_knee", "hind_far_foot", "hind_far_toe",
		"fore_far_root", "fore_far_knee", "fore_far_foot", "fore_far_toe",
		"hind_near_root", "hind_near_knee", "hind_near_foot", "hind_near_toe",
		"fore_near_root", "fore_near_knee", "fore_near_foot", "fore_near_toe",
	])
	var jp := PackedVector2Array()
	for i in skin.joint_names.size():
		jp.append(Vector2.ZERO)  # skin_bone_transform yalnizca BONES'un a/b'sini joint()'ten okur, asagida elle set ediyoruz
	skin.joint_points = jp
	skin.vertices = verts
	skin.uvs = uvs
	skin.indices = indices
	skin.bone_names = BONE_NAMES
	skin.bone_ids = bone_ids
	skin.bone_weights = bone_weights
	skin.layer_textures = layer_tex
	skin.layer_far = layer_far
	skin.layer_vertex_offsets = layer_v_off
	skin.layer_index_offsets = layer_i_off

	# joint() haritasini BONE_REST'ten gercek a/b konumlariyla dolduruyoruz
	# (skin_bone_transform `ground + _placed(skin, spec.a,...)` okuyor).
	var names2 := []
	var points2 := PackedVector2Array()
	var seen := {}
	for bone_name2 in BONE_NAMES:
		var ab2: Array = BONE_REST[bone_name2]
		for idx in [0, 1]:
			var jn: String = (BeastRig.BONES[bone_name2] as Dictionary)["a" if idx == 0 else "b"]
			if not seen.has(jn):
				seen[jn] = true
				names2.append(jn)
				points2.append(ab2[idx])
	skin.joint_names = PackedStringArray(names2)
	skin.joint_points = points2
	return skin


func _solid_texture(color: Color, size: int = 8) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


class FigureCanvas extends Node2D:
	var skin: BeastSkin
	var tex: Texture2D
	var phase: float
	var ground: Vector2
	var h: float = 180.0
	var skin_usec: int = 0

	# draw_skin() yerine birebir ayni ic dongu - part_texture()'un tur
	# baslatmasi gereken sahte "perf" turunu atlamak icin tek fark, gercek
	# dokuyu degil sabit bir yer tutucuyu baglamak (RenderingServer'a giden
	# canvas_item_add_triangle_array cagrisi ve argumanlari birebir ayni).
	func _draw() -> void:
		var t0 := Time.get_ticks_usec()
		var joints := _joints_for(phase)
		var tone := Color(0.7, 0.7, 0.65, 1.0)
		var points := BeastRig.skin_deform(skin, joints, h, 1.0)
		var item := get_canvas_item()
		for layer in skin.layer_count():
			var v0 := skin.layer_vertex_offsets[layer]
			var v1 := skin.layer_vertex_offsets[layer + 1]
			RenderingServer.canvas_item_add_triangle_array(
				item, skin.layer_indices(layer), points.slice(v0, v1),
				PackedColorArray([tone]), skin.layer_uvs(layer),
				PackedInt32Array(), PackedFloat32Array(), tex.get_rid()
			)
		skin_usec = Time.get_ticks_usec() - t0

	func _joints_for(p: float) -> Dictionary:
		# Gercek bir yuruyus degil, her kemigin a/b'sini kucuk bir genlikle
		# oynatan, deform maliyetini (kemik donusumu + agirlikli karisim)
		# gercekci olcekte tetikleyen bir hareket.
		var joints := {"ground": ground}
		var bob := sin(p * 2.0) * h * 0.02
		var swing := sin(p) * h * 0.08
		var k := h / skin.ref_h
		for i in skin.joint_names.size():
			var jn: String = skin.joint_names[i]
			var rest: Vector2 = skin.joint_points[i]
			var extra := Vector2(sin(p + rest.x * 0.01) * h * 0.03, cos(p + rest.y * 0.01) * h * 0.02)
			joints[jn] = ground + Vector2(rest.x * k, rest.y * k + bob) + extra
		return joints


func _init() -> void:
	_skin = _build_synthetic_skin()
	print("sentetik skin: vertex=", _skin.vertices.size(), " ucgen=", _skin.indices.size() / 3,
		" katman=", _skin.layer_count())

	# BeastRig.draw_skin -> part_texture(species, part) cagiriyor; bizim
	# "perf" turumuz icin dokusu olmadigindan draw_skin texture==null'da
	# katmani atlar. Testin gercek maliyeti deform+ciz cagrisinin KENDISI
	# oldugu icin (dolu dokulu bir karakterin de ayni sayida ucgeni var),
	# BeastRig.part_texture'i atlayip katmanlari KENDIMIZ cizelim - draw_skin'in
	# ic dongusunu birebir kopyalayan, yalnizca dokuyu sabit bir yer tutucuyla
	# degistiren bir surum kullaniyoruz (skin_deform birebir gercek fonksiyon).
	var root := Node2D.new()
	get_root().add_child(root)
	get_root().content_scale_size = Vector2i(1280, 720)

	var placeholder := _solid_texture(Color(0.55, 0.45, 0.35))
	var cols := 10
	for i in FIGURE_COUNT:
		var fig := FigureCanvas.new()
		fig.skin = _skin
		fig.tex = placeholder
		fig.phase = TAU * float(i) / float(FIGURE_COUNT)
		fig.position = Vector2(60 + (i % cols) * 120, 60 + (i / cols) * 120)
		fig.ground = Vector2.ZERO
		root.add_child(fig)
		_figures.append(fig)

	_frame_times.resize(FRAMES)
	_skin_times.resize(FRAMES)


func _process(_delta: float) -> bool:
	if _frame_count >= FRAMES:
		_finish()
		return false
	for fig in _figures:
		fig.phase += 0.05
		fig.queue_redraw()
	# queue_redraw yalnizca isaretler; gercek _draw() cagrisi bu surecin
	# render asamasinda olur. Kare suresini tum surecin (process+render)
	# bir sonraki process'e kadar gecen gercek suresiyle olcuyoruz.
	if _frame_count > 0:
		_frame_times[_frame_count - 1] = float(Time.get_ticks_usec() - _t_frame_start) / 1000.0
		var s := 0
		for fig in _figures:
			s += fig.skin_usec
		_skin_times[_frame_count - 1] = float(s) / 1000.0
	_t_frame_start = Time.get_ticks_usec()
	_frame_count += 1
	return false


func _percentile(arr: PackedFloat32Array, p: float) -> float:
	var sorted := arr.duplicate()
	sorted.sort()
	var idx := int(clamp(p * float(sorted.size() - 1), 0, sorted.size() - 1))
	return sorted[idx]


func _finish() -> void:
	# ilk ve son (henuz olculmemis) kareyi at
	var ft := _frame_times.slice(1, FRAMES - 1)
	var st := _skin_times.slice(1, FRAMES - 1)
	var avg_f := 0.0
	var avg_s := 0.0
	for v in ft: avg_f += v
	for v in st: avg_s += v
	avg_f /= ft.size()
	avg_s /= st.size()
	var result := {
		"path": "A_BeastSkin",
		"figure_count": FIGURE_COUNT,
		"verts_per_figure": _skin.vertices.size(),
		"tris_per_figure": _skin.indices.size() / 3,
		"frames_measured": ft.size(),
		"frame_ms_avg": avg_f,
		"frame_ms_p95": _percentile(ft, 0.95),
		"frame_ms_p99": _percentile(ft, 0.99),
		"skin_ms_avg": avg_s,
		"skin_ms_p95": _percentile(st, 0.95),
		"skin_ms_p99": _percentile(st, 0.99),
	}
	print(JSON.stringify(result, "  "))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "  "))
	f.close()
	print("yazildi: ", ProjectSettings.globalize_path(OUT))
	quit()
