extends SceneTree
func _init() -> void:
	var skin: BeastSkin = load("res://build/figures/variants/male_medium/layers/thigh_back/skin.tres")
	var h: float = FigureRig.REF_H
	var phase := TAU * 0.75
	var joints := FigureRig.pose(Vector2.ZERO, h, phase, 1.0, 1.0)

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
	var core_xform: Transform2D = xforms[skin.bone_names[0]]
	var worst := []
	for i in verts.size():
		var v := verts[i]
		var p_blend := Vector2.ZERO
		for n in BeastSkin.INFLUENCES:
			var w: float = weights[i * BeastSkin.INFLUENCES + n]
			if w > 0.0:
				var bone_name: String = skin.bone_names[ids[i * BeastSkin.INFLUENCES + n]]
				p_blend += (xforms[bone_name] * v) * w
		var p_core := core_xform * v
		var dist := (p_blend - p_core).length()
		worst.append([dist, i, v, p_blend, p_core])
	worst.sort_custom(func(a, b): return a[0] > b[0])
	for k in min(8, worst.size()):
		var e: Array = worst[k]
		var vi: int = e[1]
		var w3 := []
		for n in 3:
			w3.append([skin.bone_names[ids[vi*3+n]], weights[vi*3+n]])
		print("dist=", e[0], " vi=", vi, " rest=", e[2], " blend=", e[3], " core_only=", e[4], " weights=", w3)
	quit()
