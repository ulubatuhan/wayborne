extends SceneTree

## Test değil, bir araç: `FigureRig`'in parça tablosunu (tuval, pivot,
## dinlenme yönü) `docs/wardrobe/rig_spec.json`'a, hayvan iskeletininkini
## (`BeastRig`, tür başına) `docs/beasts/beast_rig_spec.json`'a yazıyor. Şablon çizen ve
## ressamın parça sayfasını dilimleyen Python araçları (tools/wardrobe_*.py)
## bu dosyayı okuyor - iskeleti ikinci kez yazmıyorlar. `test_wardrobe.gd`
## dosyanın güncel olduğunu doğruluyor; iskelet değişince bu aracı yeniden
## çalıştır:
##
##     godot --headless --script res://tests/export_rig_spec.gd

const OUT_PATH: String = "res://docs/wardrobe/rig_spec.json"
const BEAST_OUT_PATH: String = "res://docs/beasts/beast_rig_spec.json"

func _init() -> void:
	_write(OUT_PATH, spec_json())
	_write(BEAST_OUT_PATH, beast_spec_json())
	quit()

func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("  -> ", path)

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

static func _point(point: Vector2) -> Array:
	return [snappedf(point.x, 0.01), snappedf(point.y, 0.01)]

## Her tür için parça uçları ve dinlenme eklemleri; tuval/pivot türler
## arasında ortak (tek sayfa düzeni).
static func beast_spec() -> Dictionary:
	var parts := {}
	for part in BeastRig.PART_ORDER:
		var entry: Dictionary = BeastRig.PARTS[part]
		parts[part] = {"canvas": [entry.canvas.x, entry.canvas.y], "pivot": _point(entry.pivot)}
	var species := {}
	for name in BeastRig.SPECIES_ORDER:
		var ends := {}
		for part in BeastRig.PART_ORDER:
			ends[part] = _point(BeastRig.PARTS[part].pivot + BeastRig.part_rest_vector(name, part))
		var joints := {}
		var rest := BeastRig.rest_pose(name)
		for joint in rest.keys():
			joints[joint] = _point(rest[joint])
		var painted := {}
		var paint := BeastRig.paint_pose(name)
		for joint in paint.keys():
			painted[joint] = _point(paint[joint])
		species[name] = {
			"ends": ends, "rest_joints": joints, "paint_joints": painted,
			"layers": BeastRig.SPECIES[name].layers,
		}
	return {
		"ref_h": BeastRig.REF_H,
		"cell": [BeastRig.CELL.x, BeastRig.CELL.y],
		"part_order": BeastRig.PART_ORDER,
		"parts": parts,
		"bones": BeastRig.BONES,
		"draw_order": BeastRig.DRAW_ORDER,
		"species_order": BeastRig.SPECIES_ORDER,
		"species": species,
	}

static func beast_spec_json() -> String:
	return JSON.stringify(beast_spec(), "  ", true) + "\n"
