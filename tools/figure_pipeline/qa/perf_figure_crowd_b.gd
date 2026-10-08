## Asama 0: Performans testi - Yol B (Godot yerlesik Polygon2D + Skeleton2D).
## Ayni olcek: 50 figur, figur basina ~3000 vertex (16 "kemik" × ~192 vertex,
## Polygon2D.bones ile agirlikli), farkli fazlarda Bone2D donusleri.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tools/figure_pipeline/qa/perf_figure_crowd_b.gd
extends SceneTree

const FIGURE_COUNT: int = 50
const FRAMES: int = 600
const BONE_COUNT: int = 16
const VERTS_PER_BONE: int = 192  # 16*192 = 3072, Yol A ile ayni toplam
const OUT: String = "user://perf_path_b.json"

var _frame_times: PackedFloat32Array = []
var _frame_count: int = 0
var _t_frame_start: int = 0
var _figures: Array = []


func _init() -> void:
	# Gercek Polygon2D "bones" API'si: add_bone(path, weights) - weights
	# TUM polygon vertex'leri icin TEK bir kemigin agirlik dizisi (N float,
	# N = vertex sayisi), iskelet kemigi basina bir kez cagrilir.
	var root_container := Node2D.new()
	get_root().add_child(root_container)
	get_root().content_scale_size = Vector2i(1280, 720)

	var cols := 10
	for i in FIGURE_COUNT:
		var ground := Vector2(60 + (i % cols) * 120, 60 + (i / cols) * 120)
		var fig := _build_real_figure(ground, i)
		root_container.add_child(fig.root)
		_figures.append(fig)

	_frame_times.resize(FRAMES)


class Fig:
	var root: Node2D
	var bones: Array = []
	var phase: float = 0.0


func _build_real_figure(ground: Vector2, idx: int) -> Fig:
	var fig := Fig.new()
	fig.phase = TAU * float(idx) / float(FIGURE_COUNT)
	var root := Node2D.new()
	root.position = ground
	fig.root = root

	var skeleton := Skeleton2D.new()
	root.add_child(skeleton)
	var bones: Array[Bone2D] = []
	var prev: Bone2D = null
	for i in BONE_COUNT:
		var b := Bone2D.new()
		b.name = "bone_%d" % i
		if prev:
			prev.add_child(b)
			b.position = Vector2(0, 8)
		else:
			skeleton.add_child(b)
			b.position = Vector2(0, -60)
		b.apply_rest()
		bones.append(b)
		prev = b
	fig.bones = bones

	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.55, 0.45, 0.35))
	var tex := ImageTexture.create_from_image(img)

	var poly := Polygon2D.new()
	poly.texture = tex
	root.add_child(poly)
	poly.skeleton = poly.get_path_to(skeleton)

	var n := BONE_COUNT * VERTS_PER_BONE
	var verts := PackedVector2Array()
	verts.resize(n)
	var uvs := PackedVector2Array()
	uvs.resize(n)
	var per_bone_weights: Array[PackedFloat32Array] = []
	for bi in BONE_COUNT:
		var zero := PackedFloat32Array()
		zero.resize(n)
		per_bone_weights.append(zero)

	var vi := 0
	for bi in BONE_COUNT:
		var base_y := -60.0 + bi * 8.0
		var own_arr: PackedFloat32Array = per_bone_weights[bi]
		var next_bi := mini(bi + 1, BONE_COUNT - 1)
		var next_arr: PackedFloat32Array = per_bone_weights[next_bi]
		for k in VERTS_PER_BONE:
			var row := k / 8
			var col := k % 8
			verts[vi] = Vector2(-20.0 + col * 5.0, base_y + row * 0.3)
			uvs[vi] = Vector2(float(col) / 7.0, float(row) / float(VERTS_PER_BONE / 8 - 1))
			var own_w := 0.85
			own_arr[vi] = own_w
			if next_bi != bi:
				next_arr[vi] = 1.0 - own_w
			vi += 1
		per_bone_weights[bi] = own_arr
		per_bone_weights[next_bi] = next_arr
	poly.polygon = verts
	poly.uv = uvs
	poly.invert_enabled = false
	for bi in BONE_COUNT:
		poly.add_bone(poly.get_path_to(bones[bi]), per_bone_weights[bi])
	return fig


func _process(_delta: float) -> bool:
	if _frame_count >= FRAMES:
		_finish()
		return false
	for fig in _figures:
		fig.phase += 0.05
		var p: float = fig.phase
		var bones: Array = fig.bones
		for i in bones.size():
			var b: Bone2D = bones[i]
			b.rotation = sin(p + float(i) * 0.3) * 0.25
	if _frame_count > 0:
		_frame_times[_frame_count - 1] = float(Time.get_ticks_usec() - _t_frame_start) / 1000.0
	_t_frame_start = Time.get_ticks_usec()
	_frame_count += 1
	return false


func _percentile(arr: PackedFloat32Array, p: float) -> float:
	var sorted := arr.duplicate()
	sorted.sort()
	var idx := int(clamp(p * float(sorted.size() - 1), 0, sorted.size() - 1))
	return sorted[idx]


func _finish() -> void:
	var ft := _frame_times.slice(1, FRAMES - 1)
	var avg_f := 0.0
	for v in ft: avg_f += v
	avg_f /= ft.size()
	var result := {
		"path": "B_Polygon2D_Skeleton2D",
		"figure_count": FIGURE_COUNT,
		"verts_per_figure": BONE_COUNT * VERTS_PER_BONE,
		"frames_measured": ft.size(),
		"frame_ms_avg": avg_f,
		"frame_ms_p95": _percentile(ft, 0.95),
		"frame_ms_p99": _percentile(ft, 0.99),
	}
	print(JSON.stringify(result, "  "))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "  "))
	f.close()
	print("yazildi: ", ProjectSettings.globalize_path(OUT))
	quit()
