extends SceneTree

## Test değil, bir araç: `FigureRig`'in parça tablosunu (tuval, pivot,
## dinlenme yönü) `docs/wardrobe/rig_spec.json`'a yazıyor. Şablon çizen ve
## ressamın parça sayfasını dilimleyen Python araçları (tools/wardrobe_*.py)
## bu dosyayı okuyor - iskeleti ikinci kez yazmıyorlar. `test_wardrobe.gd`
## dosyanın güncel olduğunu doğruluyor; iskelet değişince bu aracı yeniden
## çalıştır:
##
##     godot --headless --script res://tests/export_rig_spec.gd

const OUT_PATH: String = "res://docs/wardrobe/rig_spec.json"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/wardrobe"))
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	file.store_string(spec_json())
	file.close()
	print("  -> ", OUT_PATH)
	quit()

static func spec() -> Dictionary:
	var rest := FigureRig.rest_pose()
	var parts := {}
	for part in FigureRig.PART_ORDER:
		var entry: Dictionary = FigureRig.PARTS[part]
		var pivot: Vector2 = entry.pivot
		var rest_vector := FigureRig.part_rest_vector(part)
		parts[part] = {
			"canvas": [entry.canvas.x, entry.canvas.y],
			"pivot": [snappedf(pivot.x, 0.01), snappedf(pivot.y, 0.01)],
			"end": [snappedf(pivot.x + rest_vector.x, 0.01), snappedf(pivot.y + rest_vector.y, 0.01)],
		}
	var joints := {}
	for joint in rest.keys():
		var point: Vector2 = rest[joint]
		joints[joint] = [snappedf(point.x, 0.01), snappedf(point.y, 0.01)]
	return {
		"ref_h": FigureRig.REF_H,
		"part_order": FigureRig.PART_ORDER,
		"parts": parts,
		"bones": FigureRig.BONES,
		"draw_order": FigureRig.DRAW_ORDER,
		"rest_joints": joints,
		"head_radius": snappedf(FigureRig.head_radius(FigureRig.REF_H), 0.01),
	}

static func spec_json() -> String:
	return JSON.stringify(spec(), "  ", true) + "\n"
