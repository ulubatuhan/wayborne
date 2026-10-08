## Herhangi bir Asama-3 skin.json'unu BeastSkin .tres'ine cevirir.
##   godot --headless --script res://tools/figure_pipeline/mesh/json_to_tres.gd -- <json_yolu> <tres_yolu>
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var json_path: String = args[0]
	var tres_path: String = args[1]
	var text := FileAccess.get_file_as_string(json_path)
	var data: Dictionary = JSON.parse_string(text)

	var skin := BeastSkin.new()
	skin.ref_h = data["ref_h"]
	skin.joint_names = PackedStringArray(data["joint_names"])
	var jp := PackedVector2Array()
	for p in data["joint_points"]:
		jp.append(Vector2(p[0], p[1]))
	skin.joint_points = jp
	skin.layer_textures = PackedStringArray(data["layer_textures"])
	skin.layer_far = PackedInt32Array(data["layer_far"])
	skin.layer_vertex_offsets = PackedInt32Array(data["layer_vertex_offsets"])
	skin.layer_index_offsets = PackedInt32Array(data["layer_index_offsets"])
	var verts := PackedVector2Array()
	for v in data["vertices"]:
		verts.append(Vector2(v[0], v[1]))
	skin.vertices = verts
	var uvs := PackedVector2Array()
	for u in data["uvs"]:
		uvs.append(Vector2(u[0], u[1]))
	skin.uvs = uvs
	skin.indices = PackedInt32Array(data["indices"])
	skin.bone_names = PackedStringArray(data["bone_names"])
	skin.bone_ids = PackedInt32Array(data["bone_ids"])
	var weights := PackedFloat32Array()
	for w in data["bone_weights"]:
		weights.append(w)
	skin.bone_weights = weights

	var err := ResourceSaver.save(skin, tres_path)
	print("saved: ", err, " verts=", verts.size(), " tris=", skin.indices.size() / 3)
	quit()
