## Asama 0: Performans testi - Yol C (GPU skinning: MeshInstance2D +
## canvas_item vertex shader'da iskelet donusumu).
##
## On kosul dogrulandi (bkz. tools/figure_pipeline/qa/_custom0_probe.gd):
## Godot 4.2/5.0'in canvas_item vertex shader'inda CUSTOM0/CUSTOM1 YOK -
## "Unknown identifier" ile derleme hatasi veriyor (3B'nin spatial
## shader'indan farkli). Bu yuzden kemik id/agirligi vertex COLOR'a (4
## float = 2 kemik * (id, agirlik)) paketleniyor; BeastSkin'in 3 etkisi
## yerine 2'ye dusuyor - bu YALNIZCA bu GPU kanitinin bir sinirlamasi,
## sonuc A/B lehine degil aleyhine (daha az is yapiyor, yine de kiyaslanacak).
## Kemik donusumleri (16 kemik * 3 vec2 = 48 vec2) figur basina KUCUK bir
## uniform dizisinde - CPU her karede yalnizca bu kucuk diziyi yazar,
## pahali per-vertex isi GPU'ya birakir.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tools/figure_pipeline/qa/perf_figure_crowd_c.gd
extends SceneTree

const FIGURE_COUNT: int = 50
const FRAMES: int = 600
const BONE_COUNT: int = 16
const VERTS_PER_BONE: int = 192  # Yol A/B ile ayni toplam: 3072
const OUT: String = "user://perf_path_c.json"

const SHADER_CODE := """
shader_type canvas_item;

uniform vec2 bones[48]; // BONE_COUNT * 3 (x_axis, y_axis, origin)

vec2 xform(int bi, vec2 p) {
	vec2 x_axis = bones[bi * 3 + 0];
	vec2 y_axis = bones[bi * 3 + 1];
	vec2 origin = bones[bi * 3 + 2];
	return vec2(dot(vec2(x_axis.x, y_axis.x), p), dot(vec2(x_axis.y, y_axis.y), p)) + origin;
}

void vertex() {
	int id0 = int(COLOR.r * 255.0 + 0.5);
	float w0 = COLOR.g;
	int id1 = int(COLOR.b * 255.0 + 0.5);
	float w1 = COLOR.a;
	vec2 rest = VERTEX;
	VERTEX = xform(id0, rest) * w0 + xform(id1, rest) * w1;
}
"""

var _frame_times: PackedFloat32Array = []
var _frame_count: int = 0
var _t_frame_start: int = 0
var _figures: Array = []
var _shader: Shader


class Fig:
	var mesh_instance: MeshInstance2D
	var material: ShaderMaterial
	var phase: float = 0.0
	var bone_rest: Array = []  # Vector2 a,b per kemik (yerel dinlenme)


func _build_figure(ground: Vector2, idx: int) -> Fig:
	var fig := Fig.new()
	fig.phase = TAU * float(idx) / float(FIGURE_COUNT)

	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var bone_rest: Array = []

	for bi in BONE_COUNT:
		var a := Vector2(0, -60.0 + bi * 8.0)
		var b := Vector2(0, -60.0 + (bi + 1) * 8.0)
		bone_rest.append([a, b])

	for bi in BONE_COUNT:
		var ab = bone_rest[bi]
		var a: Vector2 = ab[0]
		var b: Vector2 = ab[1]
		var next_bi := mini(bi + 1, BONE_COUNT - 1)
		var base := verts.size()
		var rows := VERTS_PER_BONE / 8
		for r in rows:
			var t := float(r) / float(maxi(rows - 1, 1))
			var center := a.lerp(b, t)
			for c in 8:
				var s := (float(c) / 7.0) * 2.0 - 1.0
				verts.append(center + Vector2(10.0 * s, 0.0))
				uvs.append(Vector2(float(c) / 7.0, t))
				colors.append(Color(float(bi) / 255.0, 0.85, float(next_bi) / 255.0, 0.15))
		for r in rows - 1:
			for c in 7:
				var i0 := base + r * 8 + c
				var i1 := base + r * 8 + c + 1
				var i2 := base + (r + 1) * 8 + c
				var i3 := base + (r + 1) * 8 + c + 1
				indices.append(i0); indices.append(i1); indices.append(i2)
				indices.append(i1); indices.append(i3); indices.append(i2)

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_COLOR] = colors
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.55, 0.45, 0.35))
	var tex := ImageTexture.create_from_image(img)

	var mat := ShaderMaterial.new()
	mat.shader = _shader
	var zero_bones := PackedVector2Array()
	zero_bones.resize(BONE_COUNT * 3)
	for i in zero_bones.size():
		zero_bones[i] = Vector2.ZERO
	mat.set_shader_parameter("bones", zero_bones)

	var mi := MeshInstance2D.new()
	mi.mesh = mesh
	mi.texture = tex
	mi.material = mat
	mi.position = ground

	fig.mesh_instance = mi
	fig.material = mat
	fig.bone_rest = bone_rest
	return fig


func _init() -> void:
	_shader = Shader.new()
	_shader.code = SHADER_CODE

	var root_container := Node2D.new()
	get_root().add_child(root_container)
	get_root().content_scale_size = Vector2i(1280, 720)

	var cols := 10
	for i in FIGURE_COUNT:
		var ground := Vector2(60 + (i % cols) * 120, 60 + (i / cols) * 120)
		var fig := _build_figure(ground, i)
		root_container.add_child(fig.mesh_instance)
		_figures.append(fig)

	_frame_times.resize(FRAMES)
	print("shader derlendi, figur basina vertex=", BONE_COUNT * VERTS_PER_BONE)


func _process(_delta: float) -> bool:
	if _frame_count >= FRAMES:
		_finish()
		return false
	for fig in _figures:
		fig.phase += 0.05
		var p: float = fig.phase
		var bones_data := PackedVector2Array()
		bones_data.resize(BONE_COUNT * 3)
		for bi in BONE_COUNT:
			var ab = fig.bone_rest[bi]
			var a: Vector2 = ab[0]
			var b: Vector2 = ab[1]
			# Yol A/B ile ayni genlikte sentetik hareket: her kemigi kendi
			# etrafinda kucuk acilarla dondur (gercek maliyet per-vertex
			# donusumde, acinin gercekciligi degil).
			var theta := sin(p + float(bi) * 0.3) * 0.25
			var rot := Transform2D(theta, Vector2.ZERO)
			var xf := Transform2D(rot.x, rot.y, a)
			bones_data[bi * 3 + 0] = xf.x
			bones_data[bi * 3 + 1] = xf.y
			bones_data[bi * 3 + 2] = xf.origin
		fig.material.set_shader_parameter("bones", bones_data)
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
		"path": "C_GPU_canvas_item_shader",
		"figure_count": FIGURE_COUNT,
		"verts_per_figure": BONE_COUNT * VERTS_PER_BONE,
		"influences_per_vertex": 2,
		"note": "CUSTOM0/1 canvas_item vertex shader'da yok (dogrulandi) - 2 etki COLOR'a paketlendi",
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
