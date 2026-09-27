extends RefCounted

## Dört ayaklıların iskeleti (`BeastRig`). Görünüşü değil - o screenshot
## araçlarının işi - bir parçanın doğru ekleme oturduğunu, bacakların doğru
## yöne kırıldığını, uzak bacağın gövdenin arkasında kaldığını ve ressamın
## şablonunun oyunun okuduğu tabloyla aynı olduğunu kilitliyor.

const SPEC_TOOL: String = "res://tests/export_rig_spec.gd"
const SPEC_PATH: String = "res://docs/beasts/beast_rig_spec.json"
const FIXTURE_ROOT: String = "user://beast_test/"

func suite_name() -> String:
	return "BeastRig"

func run(t) -> void:
	_test_spec_file_is_current(t)
	_test_every_part_fits_its_canvas(t)
	_test_part_lands_on_its_joints(t)
	_test_legs_bend_the_right_way(t)
	_test_feet_stay_on_or_above_ground(t)
	_test_draw_order_is_depth(t)
	_test_extent_holds_the_pose(t)
	_test_discovery_layers_and_far_shading(t)

## Şablonu çizen ve resmi kesen Python araçları bu dosyayı okuyor. İskelet
## değişip dosya değişmezse ressamın şablonu oyunun iskeletinden sapar.
func _test_spec_file_is_current(t) -> void:
	var expected: String = load(SPEC_TOOL).beast_spec_json()
	var actual := FileAccess.get_file_as_string(SPEC_PATH)
	t.eq(actual, expected, "docs/beasts/beast_rig_spec.json güncel (tests/export_rig_spec.gd'yi çalıştır)")

## Tuvaller beş türün hepsini almalı: tek sayfa düzeni buna dayanıyor.
func _test_every_part_fits_its_canvas(t) -> void:
	for bone in BeastRig.DRAW_ORDER:
		t.ok(BeastRig.PARTS.has(String(BeastRig.BONES[bone].part)), "%s kemiğinin parçası tanımlı" % bone)
	for species in BeastRig.SPECIES_ORDER:
		for part in BeastRig.PART_ORDER:
			var entry: Dictionary = BeastRig.PARTS[part]
			var canvas := Rect2(Vector2.ZERO, Vector2(entry.canvas))
			t.ok(Vector2(entry.canvas).x <= BeastRig.CELL.x and Vector2(entry.canvas).y <= BeastRig.CELL.y, "%s tuvali sayfa hücresine sığıyor" % part)
			var end: Vector2 = entry.pivot + BeastRig.part_rest_vector(species, part)
			t.ok(canvas.grow(0.5).has_point(end), "%s/%s kemiğin ucu tuvalin içinde (%s)" % [species, part, end])

## Parçanın pivotu A ekleminde, ucu B ekleminde - her boyda, iki yöne de,
## yürürken de.
func _test_part_lands_on_its_joints(t) -> void:
	for species in BeastRig.SPECIES_ORDER:
		for facing in [1.0, -1.0]:
			for h in [BeastRig.REF_H, 90.0]:
				var joints := BeastRig.pose(species, Vector2(300, 400), h, 1.1, 1.0, facing)
				for bone in BeastRig.DRAW_ORDER:
					var spec: Dictionary = BeastRig.BONES[bone]
					var part := String(spec.part)
					var pivot: Vector2 = BeastRig.PARTS[part].pivot
					var rest := BeastRig.part_rest_vector(species, part)
					var xf := BeastRig.part_transform(species, part, joints[spec.a], joints[spec.b], h, facing)
					t.le((xf * pivot).distance_to(joints[spec.a]), 0.01, "%s/%s pivotu A'da" % [species, bone])
					var along: Vector2 = (xf * (pivot + rest)) - joints[spec.a]
					var bone_vec: Vector2 = joints[spec.b] - joints[spec.a]
					t.le(absf(along.angle_to(bone_vec)), 0.001, "%s/%s kemiğin yönüne dönüyor" % [species, bone])

## Ön bacağın dizi öne, arka bacağın topuğu geriye kırılıyor. Arka bacağı da
## öne bükmek dört ayaklının "tavuk bacağı" hatası olurdu.
func _test_legs_bend_the_right_way(t) -> void:
	for species in BeastRig.SPECIES_ORDER:
		for facing in [1.0, -1.0]:
			var joints := BeastRig.pose(species, Vector2.ZERO, 200.0, 0.0, 0.0, facing)
			for side in ["near", "far"]:
				t.ok(_knee_side(joints, "fore_" + side) * facing > 0.0, "%s ön diz öne kırılıyor (%d)" % [species, int(facing)])
				t.ok(_knee_side(joints, "hind_" + side) * facing < 0.0, "%s arka topuk geriye kırılıyor (%d)" % [species, int(facing)])

func _knee_side(joints: Dictionary, leg: String) -> float:
	var root: Vector2 = joints[leg + "_root"]
	var foot: Vector2 = joints[leg + "_foot"]
	var knee: Vector2 = joints[leg + "_knee"]
	return knee.x - lerpf(root.x, foot.x, (knee.y - root.y) / (foot.y - root.y))

## Dururken dört ayak yerde; yürürken hiçbir ayak yerin altına inmiyor ve en
## az biri yerde (hayvan havada süzülmüyor).
func _test_feet_stay_on_or_above_ground(t) -> void:
	for species in BeastRig.SPECIES_ORDER:
		var rest := BeastRig.pose(species, Vector2(0, 500), 200.0, 0.0, 0.0, 1.0)
		for leg in ["fore_near", "fore_far", "hind_near", "hind_far"]:
			t.le(absf((rest[leg + "_foot"] as Vector2).y - 500.0), 0.001, "%s %s dururken yerde" % [species, leg])
		for step in 12:
			var joints := BeastRig.pose(species, Vector2(0, 500), 200.0, TAU * float(step) / 12.0, 1.0, 1.0)
			var grounded := 0
			for leg in ["fore_near", "fore_far", "hind_near", "hind_far"]:
				var y := (joints[leg + "_foot"] as Vector2).y
				t.le(y, 500.001, "%s %s yerin altına inmiyor" % [species, leg])
				if y >= 499.999:
					grounded += 1
			t.ok(grounded >= 1, "%s yürürken en az bir ayak yerde (adım %d)" % [species, step])

func _test_draw_order_is_depth(t) -> void:
	var order := BeastRig.DRAW_ORDER
	t.eq(order.size(), BeastRig.BONES.size(), "her kemik çizim sırasında bir kez")
	var body := order.find(BeastRig.BODY)
	for bone in order:
		if bool(BeastRig.BONES[bone].far):
			t.ok(order.find(bone) < body, "%s gövdenin arkasında" % bone)
	for bone in ["fore_near_upper", "hind_near_upper", BeastRig.NECK, BeastRig.HEAD]:
		t.ok(order.find(bone) > body, "%s gövdenin önünde" % bone)

## Savaş kutusu hayvanı bu kutuya sığdırıyor: dinlenme pozunun her eklemi
## içinde olmalı.
func _test_extent_holds_the_pose(t) -> void:
	for species in BeastRig.SPECIES_ORDER:
		var box := BeastRig.extent(species)
		for point in BeastRig.pose(species, Vector2.ZERO, 1.0, 0.0, 0.0, 1.0).values():
			t.ok(box.grow(0.001).has_point(point), "%s kutusu dinlenme pozunu içeriyor" % species)

## Resim yolundan bulunuyor; gövdesi olmayan tür prosedürelde kalıyor; takım
## yalnızca resmi varsa katman; uzak bacak kendi resmi yoksa karartılıyor.
func _test_discovery_layers_and_far_shading(t) -> void:
	_write_fixture("fx_wolf", ["head"])
	_write_fixture("horse", ["body", "fore_upper", "fore_upper_far", "hind_upper"])
	_write_fixture("horse_tack", ["body"])
	var previous := BeastRig.root_path
	BeastRig.root_path = FIXTURE_ROOT
	BeastRig.clear_cache()
	t.ok(not BeastRig.has_sprites("fx_wolf"), "gövdesi olmayan tür prosedürel çiziliyor")
	t.ok(BeastRig.has_sprites(BeastRig.HORSE), "gövde resmi olan tür iskelete geçiyor")
	t.eq(Array(BeastRig.layers_for(BeastRig.HORSE)), ["horse", "horse_tack"], "eyer atın üstünde bir katman")
	t.eq(Array(BeastRig.layers_for(BeastRig.OX)), ["ox"], "resmi olmayan boyunduruk katman değil")
	var own := BeastRig.bone_texture("horse", "fore_far_upper")
	t.ok(own.texture != null and not own.shade, "kendi _far resmi olan uzak bacak karartılmıyor")
	var shaded := BeastRig.bone_texture("horse", "hind_far_upper")
	t.ok(shaded.texture != null and shaded.shade, "uzak bacak yakın bacağın resmini karartılmış kullanıyor")
	var near := BeastRig.bone_texture("horse", "hind_near_upper")
	t.ok(near.texture != null and not near.shade, "yakın bacak karartılmıyor")
	BeastRig.root_path = previous
	BeastRig.clear_cache()

func _write_fixture(layer: String, parts: Array) -> void:
	var dir := FIXTURE_ROOT + layer
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for part in parts:
		var base := String(part).trim_suffix("_far")
		var canvas: Vector2i = BeastRig.PARTS[base].canvas
		var image := Image.create(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.5, 0.4, 0.3, 1.0))
		image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [dir, part]))
