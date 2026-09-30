extends RefCounted

## İskelet (`FigureRig`) ve giyilebilir sprite katmanları (`Wardrobe`).
## Görünüşü doğrulamıyor - o, screenshot araçlarının işi - ama bir parçanın
## doğru ekleme oturduğunu, doğru yöne döndüğünü, doğru sırada çizildiğini
## ve ressamın şablonunun oyunun okuduğu tabloyla aynı olduğunu kilitliyor.

const SPEC_TOOL: String = "res://tests/export_rig_spec.gd"
const SPEC_PATH: String = "res://docs/wardrobe/rig_spec.json"
const FIXTURE_ROOT: String = "user://wardrobe_test/"

func suite_name() -> String:
	return "Wardrobe"

func run(t) -> void:
	_test_spec_file_is_current(t)
	_test_every_bone_has_a_part_inside_its_canvas(t)
	_test_part_lands_on_its_joints(t)
	_test_left_facing_part_is_mirrored(t)
	_test_draw_order_is_depth(t)
	_test_knee_bends_forward(t)
	_test_weapon_hangs_at_rest(t)
	_test_loadout_layers_and_discovery(t)
	_test_back_limb_shading(t)
	_test_combat_figure_switches_to_rig(t)
	_test_body_variant_id_falls_back(t)

## Şablonu çizen ve parça sayfasını dilimleyen Python araçları bu dosyayı
## okuyor. İskelet değişip dosya değişmezse ressamın şablonu oyunun
## iskeletinden sessizce sapar.
func _test_spec_file_is_current(t) -> void:
	var expected: String = load(SPEC_TOOL).spec_json()
	var actual := FileAccess.get_file_as_string(SPEC_PATH)
	t.eq(actual, expected, "docs/wardrobe/rig_spec.json güncel (tests/export_rig_spec.gd'yi çalıştır)")

func _test_every_bone_has_a_part_inside_its_canvas(t) -> void:
	for bone in FigureRig.DRAW_ORDER:
		var part := String(FigureRig.BONES[bone].part)
		t.ok(FigureRig.PARTS.has(part), "%s kemiğinin parçası (%s) tanımlı" % [bone, part])
	for part in FigureRig.PART_ORDER:
		var entry: Dictionary = FigureRig.PARTS[part]
		var canvas := Rect2(Vector2.ZERO, Vector2(entry.canvas))
		var pivot: Vector2 = entry.pivot
		var end := pivot + FigureRig.part_rest_vector(part)
		t.ok(canvas.has_point(pivot), "%s pivotu tuvalin içinde" % part)
		t.ok(canvas.grow(0.5).has_point(end), "%s kemiğin öbür ucu tuvalin içinde (%s)" % [part, end])
	t.eq(FigureRig.PART_ORDER.size(), FigureRig.PARTS.size(), "her parça sayfada bir hücrede")

## Dinlenme pozunda parçanın pivotu A eklemine, pivot + dinlenme vektörü B
## eklemine düşmeli - her boyda. Yürüyüş pozunda da pivot A'da kalıyor ve
## parça kemiğin yönüne dönüyor.
func _test_part_lands_on_its_joints(t) -> void:
	for h in [FigureRig.REF_H, 96.0, 180.0]:
		var joints := FigureRig.pose(Vector2(200, 300), h, 0.0, 0.0, 1.0)
		for bone in FigureRig.DRAW_ORDER:
			var spec: Dictionary = FigureRig.BONES[bone]
			var part := String(spec.part)
			var pivot: Vector2 = FigureRig.PARTS[part].pivot
			var rest := FigureRig.part_rest_vector(part)
			var a: Vector2 = joints[spec.a]
			var b: Vector2 = joints[spec.b]
			var xf := FigureRig.part_transform(pivot, rest, a, b, h, 1.0)
			t.le((xf * pivot).distance_to(a), 0.01, "%s pivotu A'da (h=%d)" % [bone, int(h)])
			t.le((xf * (pivot + rest)).distance_to(b), 0.05, "%s ucu B'de (h=%d)" % [bone, int(h)])
	var walking := FigureRig.pose(Vector2(200, 300), 180.0, 1.3, 1.0, 1.0)
	var spec: Dictionary = FigureRig.BONES[FigureRig.THIGH_FRONT]
	var pivot: Vector2 = FigureRig.PARTS.thigh.pivot
	var rest := FigureRig.part_rest_vector("thigh")
	var a: Vector2 = walking[spec.a]
	var b: Vector2 = walking[spec.b]
	var xf := FigureRig.part_transform(pivot, rest, a, b, 180.0, 1.0)
	t.le((xf * pivot).distance_to(a), 0.01, "yürürken uyluk kalçada")
	var along := (xf * (pivot + rest)) - a
	t.le(absf(along.angle_to(b - a)), 0.001, "yürürken uyluk dize doğru dönüyor")

## Sola bakan figürde rig eklemleri aynalıyor; parçanın resmi de aynalanmalı,
## yoksa sola yürüyen biri kılıcını sırtından tutar.
func _test_left_facing_part_is_mirrored(t) -> void:
	var h := FigureRig.REF_H
	var joints := FigureRig.pose(Vector2(200, 600), h, 0.0, 0.0, -1.0)
	for bone in FigureRig.DRAW_ORDER:
		var spec: Dictionary = FigureRig.BONES[bone]
		var part := String(spec.part)
		var pivot: Vector2 = FigureRig.PARTS[part].pivot
		var rest := FigureRig.part_rest_vector(part)
		var xf := FigureRig.part_transform(pivot, rest, joints[spec.a], joints[spec.b], h, -1.0)
		t.le((xf * (pivot + rest)).distance_to(joints[spec.b]), 0.05, "%s sola bakarken de B'de" % bone)
	var torso: Dictionary = FigureRig.BONES[FigureRig.TORSO]
	var pivot: Vector2 = FigureRig.PARTS.torso.pivot
	var xf := FigureRig.part_transform(
		pivot, FigureRig.part_rest_vector("torso"), joints[torso.a], joints[torso.b], h, -1.0
	)
	var front := xf * (pivot + Vector2(30, 0))
	t.ok(front.x < (joints[torso.a] as Vector2).x, "sola bakan gövdenin önü solda (resim aynalandı)")

## Derinlik çizim sırası: arka kol ve arka bacak gövdenin arkasında, ön kol
## gövdenin ve başın önünde, silah ön elin altında (parmaklar sapı sarsın).
func _test_draw_order_is_depth(t) -> void:
	var order := FigureRig.DRAW_ORDER
	t.eq(order.size(), FigureRig.BONES.size(), "her kemik çizim sırasında bir kez")
	var torso := order.find(FigureRig.TORSO)
	for bone in [FigureRig.UPPER_ARM_BACK, FigureRig.THIGH_BACK, FigureRig.THIGH_FRONT]:
		t.ok(order.find(bone) < torso, "%s gövdenin arkasında" % bone)
	for bone in [FigureRig.HEAD, FigureRig.UPPER_ARM_FRONT, FigureRig.HAND_FRONT]:
		t.ok(order.find(bone) > torso, "%s gövdenin önünde" % bone)
	t.ok(order.find(FigureRig.WEAPON) < order.find(FigureRig.HAND_FRONT), "silah ön elin altında")
	t.ok(
		order.find(FigureRig.THIGH_BACK) < order.find(FigureRig.THIGH_FRONT),
		"arka bacak ön bacağın arkasında"
	)
	var seated := FigureRig.bones_for(true)
	t.ok(not seated.has(FigureRig.THIGH_BACK), "binicinin arka bacağı atın arkasında kalıyor, çizilmiyor")
	t.ok(seated.has(FigureRig.THIGH_FRONT), "binicinin ön bacağı çiziliyor")

## İnsan dizi yürüme yönüne kırılır. Ters bükülen diz (tavuk bacağı) sprite
## pantolonda hemen okunur; prosedürel çöp bacakta bu hataya uzun süre
## kimse fark etmemişti.
func _test_knee_bends_forward(t) -> void:
	for facing in [1.0, -1.0]:
		var joints := FigureRig.pose(Vector2(0, 0), 200.0, 0.0, 0.0, facing)
		var hip: Vector2 = joints.hip
		var ankle: Vector2 = joints.ankle_front
		var knee: Vector2 = joints.knee_front
		var line_x := lerpf(hip.x, ankle.x, (knee.y - hip.y) / (ankle.y - hip.y))
		t.ok((knee.x - line_x) * facing > 0.0, "diz yürüme yönüne kırılıyor (facing %d)" % int(facing))

func _test_weapon_hangs_at_rest(t) -> void:
	var rest := FigureRig.rest_pose()
	var hang: Vector2 = rest.weapon_tip - rest.hand_front
	t.le(absf(hang.x), 0.01, "dinlenmede silah dimdik aşağı sarkıyor")
	t.ok(hang.y > 0.0, "silahın ucu elin altında")

## Resim yolundan bulunuyor, liste yok; resmi olmayan kalem yüke girmiyor;
## katmanlar gömlek < ceket < zırh < silah sırasında.
func _test_loadout_layers_and_discovery(t) -> void:
	_write_fixture("fx_shirt", ["torso"])
	_write_fixture("fx_jacket", ["torso", "upper_arm"])
	_write_fixture("fx_armor", ["torso"])
	_write_fixture("fx_sword", ["weapon"])
	var previous := Wardrobe.root_path
	Wardrobe.root_path = FIXTURE_ROOT
	Wardrobe.clear_cache()
	var outfit := {
		OutfitCatalog.SLOT_JACKET: "fx_jacket",
		OutfitCatalog.SLOT_SHIRT: "fx_shirt",
		OutfitCatalog.SLOT_PANTS: "fx_no_art",
	}
	var equipped := {EquipmentCatalog.SLOT_WEAPON: "fx_sword", EquipmentCatalog.SLOT_ARMOR: "fx_armor"}
	var loadout := Wardrobe.loadout_of(outfit, equipped)
	t.eq(
		Array(loadout), ["fx_shirt", "fx_jacket", "fx_armor", "fx_sword"],
		"resmi olan kalemler alttan üste: gömlek, ceket, zırh, silah"
	)
	t.ok(not loadout.has("fx_no_art"), "resmi olmayan kalem prosedürel çizimde kalıyor")
	t.ok(Wardrobe.part_texture("fx_jacket", "upper_arm") != null, "yeni bırakılmış PNG içe aktarılmadan okunuyor")
	t.eq(Wardrobe.part_texture("fx_jacket", "thigh"), null, "kalemin kapsamadığı parça yok")
	t.ok(Wardrobe.has_part(loadout, "weapon"), "silah resmi olan yük eldeki silahı gösteriyor")
	t.ok(not Wardrobe.has_part(PackedStringArray(["fx_shirt"]), "weapon"), "silahsız yük sırttaki silüette kalıyor")
	Wardrobe.root_path = previous
	Wardrobe.clear_cache()

## Sanat henüz gelmediği sürece hiçbir cinsiyet/kilo varyantı düz "body"den
## farklı davranmamalı - CharacterData Faz'ının kendi garantisi (bkz. o
## dosyanın "fresh character unchanged" notu). Sanat gelince (burada
## fixture'la taklit ediliyor) doğru varyant seçilmeli.
func _test_body_variant_id_falls_back(t) -> void:
	var previous := Wardrobe.root_path
	Wardrobe.root_path = FIXTURE_ROOT
	# `_write_fixture` yazdığı PNG'yi hiçbir yerde silmiyor - bu testin
	# kendisi de dahil. `user://wardrobe_test/` gerçek bir disk yolu
	# olduğu için bir önceki koşudan kalan "body_male_heavy" fixture'ı
	# bu satırdan önce zaten diskte durabiliyordu, ki bu da "sanat yokken
	# fallback'e düşer" iddiasını -sanat aslında hep vardı diye- kalıcı
	# olarak yanlış çıkarıyordu. Fallback'i sınamadan önce kendi fixture'ını
	# kesin olarak temizlemek, testin kendi geçmiş koşularından bağımsız
	# olmasını sağlıyor - `simulate_journeys.gd`'nin "seed her zaman
	# tohumlanır" disipliniyle aynı aile: bir test kendi önceki koşusuna
	# bağımlıysa flake'ten farksızdır.
	_remove_fixture("body_male_heavy")
	Wardrobe.clear_cache()
	t.eq(
		Wardrobe.body_id_for(CharacterData.GENDER_MALE, CharacterData.BODY_WEIGHT_HEAVY),
		Wardrobe.BODY_ID,
		"sanatı olmayan varyant düz body'ye düşer"
	)
	_write_fixture("body_male_heavy", ["torso"])
	Wardrobe.clear_cache()
	t.eq(
		Wardrobe.body_id_for(CharacterData.GENDER_MALE, CharacterData.BODY_WEIGHT_HEAVY),
		"body_male_heavy",
		"sanatı eklenen varyant kendi kimliğiyle seçilir"
	)
	t.eq(
		Wardrobe.body_id_for(CharacterData.GENDER_FEMALE, CharacterData.BODY_WEIGHT_LEAN),
		Wardrobe.BODY_ID,
		"başka bir varyantın sanatı bu varyantı etkilemez"
	)
	# Bir sonraki koşunun aynı tuzağa düşmemesi için kendi fixture'ını
	# temizleyerek çıkıyor - yazdığı şeyi silen tek test bu dosyada, çünkü
	# yalnızca bu test "önce yok, sonra var" sırasına bağımlı.
	_remove_fixture("body_male_heavy")
	Wardrobe.root_path = previous
	Wardrobe.clear_cache()

func _test_back_limb_shading(t) -> void:
	_write_fixture("fx_gloves", ["hand"])
	_write_fixture("fx_boots", ["foot", "foot_back"])
	var previous := Wardrobe.root_path
	Wardrobe.root_path = FIXTURE_ROOT
	Wardrobe.clear_cache()
	var back_hand := Wardrobe.bone_texture("fx_gloves", FigureRig.HAND_BACK)
	t.ok(back_hand.texture != null and back_hand.shade, "arka el ön elin resmini karartılmış kullanıyor")
	var front_hand := Wardrobe.bone_texture("fx_gloves", FigureRig.HAND_FRONT)
	t.ok(front_hand.texture != null and not front_hand.shade, "ön el karartılmıyor")
	var back_foot := Wardrobe.bone_texture("fx_boots", FigureRig.FOOT_BACK)
	t.ok(back_foot.texture != null and not back_foot.shade, "kendi _back resmi olan arka uzuv onu karartmadan kullanıyor")
	Wardrobe.root_path = previous
	Wardrobe.clear_cache()

## İnsanlar savaşta da iskeletten (manken + kuşam) çiziliyor - kuşanılan
## kılıç orada da elinde. Canavar hiçbir zaman insan iskeletine geçmiyor.
func _test_combat_figure_switches_to_rig(t) -> void:
	var figure := CombatFigure.new()
	figure.setup("guard", true, "normal", 0.0)
	t.ok(figure.uses_rig(), "mankenin sanatı olduğundan çıplak birim de iskelette")
	var previous := Wardrobe.root_path
	Wardrobe.root_path = FIXTURE_ROOT + "no_such_dir/"
	Wardrobe.clear_cache()
	figure.setup("guard", true, "normal", 0.0)
	t.ok(not figure.uses_rig(), "beden sanatı olmayan kurulumda sprite'sız birim prosedürel silüette")
	Wardrobe.root_path = previous
	Wardrobe.clear_cache()
	figure.setup("guard", true, "normal", 0.0, {}, PackedStringArray(["fx_sword"]))
	t.ok(figure.uses_rig(), "sprite'lı kalem giyen birim iskelete geçiyor")
	figure.setup("wolf", false, "normal", 0.0, {}, PackedStringArray(["fx_sword"]))
	t.ok(not figure.uses_rig(), "canavar hiçbir zaman insan iskeletine geçmiyor")
	figure.free()

func _write_fixture(item_id: String, parts: Array) -> void:
	var dir := FIXTURE_ROOT + item_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for part in parts:
		var base := String(part).trim_suffix("_back")
		var canvas: Vector2i = FigureRig.PARTS[base].canvas
		var image := Image.create(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.6, 0.4, 0.3, 1.0))
		image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [dir, part]))

## `_write_fixture`'ın tersi: dizindeki tüm dosyaları, sonra dizinin
## kendisini siler. Dizin hiç yoksa (ilk koşu, ya da zaten temiz) no-op.
func _remove_fixture(item_id: String) -> void:
	var dir_path := ProjectSettings.globalize_path(FIXTURE_ROOT + item_id)
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			DirAccess.remove_absolute(dir_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(dir_path)
