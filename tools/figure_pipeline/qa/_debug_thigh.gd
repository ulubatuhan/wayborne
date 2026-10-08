extends SceneTree
func _init() -> void:
	var skin: BeastSkin = load("res://build/figures/variants/male_medium/layers/thigh_back/skin.tres")
	var h: float = FigureRig.REF_H
	for phase_i in range(5):
		var phase := TAU * float(phase_i) / 4.0
		var joints := FigureRig.pose(Vector2.ZERO, h, phase, 1.0, 1.0)
		print("--- phase ", phase_i, " ---")
		for bone in skin.bone_names:
			var spec: Dictionary = FigureRig.BONES[bone]
			var a_rest: Vector2 = skin.joint(spec.a)
			var b_rest: Vector2 = skin.joint(spec.b)
			var a_now: Vector2 = joints[spec.a]
			var b_now: Vector2 = joints[spec.b]
			var theta := 0.0
			if (b_now - a_now).length() > 0.0001 and (b_rest - a_rest).length() > 0.0001:
				theta = (b_now - a_now).angle() - (b_rest - a_rest).angle()
			print(bone, " a=", spec.a, " b=", spec.b, " a_rest=", a_rest, " b_rest=", b_rest, " a_now=", a_now, " b_now=", b_now, " theta_deg=", rad_to_deg(theta))
	var ids := skin.bone_ids
	var weights := skin.bone_weights
	var n := skin.vertices.size()
	var torso_idx := skin.bone_names.find("torso")
	var max_torso_w := 0.0
	var max_torso_vi := -1
	for i in n:
		for k in 3:
			if ids[i*3+k] == torso_idx:
				var w: float = weights[i*3+k]
				if w > max_torso_w:
					max_torso_w = w
					max_torso_vi = i
	print("max torso agirligi: ", max_torso_w, " vertex: ", max_torso_vi, " pos(fig): ", skin.vertices[max_torso_vi] if max_torso_vi >= 0 else "yok")
	quit()
