extends SceneTree

func _init() -> void:
	# ArrayMesh ile CUSTOM0 kanalina bir deger yazip, canvas_item shader'inin
	# bunu gercekten okuyup okumadigini bir render-to-texture ile dogrula.
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	var verts := PackedVector2Array([Vector2(-50,-50), Vector2(50,-50), Vector2(50,50), Vector2(-50,50)])
	var uvs := PackedVector2Array([Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,1)])
	var colors := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	var custom0 := PackedFloat32Array([1.0,0.0,0.0,0.0,  0.0,1.0,0.0,0.0,  0.0,0.0,1.0,0.0,  0.0,0.0,0.0,1.0])
	var indices := PackedInt32Array([0,1,2, 0,2,3])
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_COLOR] = colors
	arr[Mesh.ARRAY_CUSTOM0] = custom0
	arr[Mesh.ARRAY_INDEX] = indices
	var fmt := (Mesh.ARRAY_FORMAT_VERTEX | Mesh.ARRAY_FORMAT_TEX_UV | Mesh.ARRAY_FORMAT_COLOR |
		Mesh.ARRAY_FORMAT_INDEX | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT))
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, fmt)
	print("ArrayMesh with CUSTOM0 (RGBA_FLOAT) created OK, surface count:", mesh.get_surface_count())

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
varying vec4 v_custom0;
void vertex() {
	v_custom0 = CUSTOM0;
}
void fragment() {
	COLOR = v_custom0;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader

	var mi := MeshInstance2D.new()
	mi.mesh = mesh
	mi.material = mat

	var root := Control.new()
	root.size = Vector2(100,100)
	root.add_child(mi)
	mi.position = Vector2(50,50)
	get_root().add_child(root)
	get_root().content_scale_size = Vector2i(100,100)
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png("user://custom0_test.png")
	var px := img.get_pixel(25, 75)  # should read vertex0 color-ish (top-left triangle area, custom0=(1,0,0,0))
	print("pixel at (25,75):", px, " (expect something close to (1,0,0,0) if CUSTOM0 reaches shader)")
	var px2 := img.get_pixel(75, 25)
	print("pixel at (75,25):", px2, " (expect close to (0,1,0,0) or blend)")
	print("saved:", ProjectSettings.globalize_path("user://custom0_test.png"))
	quit()
