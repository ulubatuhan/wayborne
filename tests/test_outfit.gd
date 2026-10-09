extends RefCounted

## Kıyafet sistemi: OutfitCatalog'un çözümleyicileri (WalkFigure ve
## CombatFigure'ın ikisinin de okuduğu tek mantık) ve kıyafetin karakterden
## savaş birimine doğru taşınması. Bkz. CLAUDE.md Kervan Envanteri Rules'un
## yanındaki "kıyafet sisteminin kapsamı" notu - bu paket o notun kapattığı
## boşluğu (figürler outfit'e hiç bakmıyordu) kilitliyor.

func suite_name() -> String:
	return "Outfit"

func run(t) -> void:
	_test_resolve_color_falls_back_when_empty(t)
	_test_resolve_color_returns_piece_color(t)
	_test_resolve_torso_color_jacket_overrides_shirt(t)
	_test_resolve_torso_color_shirt_alone(t)
	_test_resolve_headgear_no_hat_means_no_override(t)
	_test_resolve_headgear_hat_overrides_shape_and_color(t)
	_test_unknown_piece_id_falls_back(t)
	_test_combat_unit_carries_outfit_from_character(t)
	_test_enemy_units_have_no_outfit(t)
	_test_figures_accept_outfit_without_error(t)
	_test_every_piece_has_art_for_every_body(t)
	_test_garment_frames_match_body_layout(t)
	_test_wear_and_take_off_go_through_the_locker(t)
	_test_choices_are_only_what_is_owned(t)
	_test_locker_survives_save(t)
	_test_legacy_ids_migrate(t)
	_test_recruits_come_dressed_deterministically(t)
	_test_boots_switch_the_walk(t)

func _test_resolve_color_falls_back_when_empty(t) -> void:
	var fallback := Color(0.1, 0.2, 0.3)
	var result := OutfitCatalog.resolve_color({}, OutfitCatalog.SLOT_PANTS, fallback)
	t.eq(result, fallback, "boş outfit sözlüğü hep fallback'e düşer")

func _test_resolve_color_returns_piece_color(t) -> void:
	var outfit := {OutfitCatalog.SLOT_PANTS: "peasant_pants"}
	var piece := OutfitCatalog.get_piece("peasant_pants")
	var result := OutfitCatalog.resolve_color(outfit, OutfitCatalog.SLOT_PANTS, Color.BLACK)
	t.eq(result, piece.color, "seçili parçanın kendi rengi dönmeli")

func _test_resolve_torso_color_jacket_overrides_shirt(t) -> void:
	var outfit := {
		OutfitCatalog.SLOT_SHIRT: "peasant_shirt",
		OutfitCatalog.SLOT_JACKET: "ranger_jacket",
	}
	var jacket := OutfitCatalog.get_piece("ranger_jacket")
	var result := OutfitCatalog.resolve_torso_color(outfit, Color.BLACK)
	t.eq(result, jacket.color, "ceket varken gömleğin üstünü kapatır")

func _test_resolve_torso_color_shirt_alone(t) -> void:
	var outfit := {OutfitCatalog.SLOT_SHIRT: "peasant_shirt"}
	var shirt := OutfitCatalog.get_piece("peasant_shirt")
	var result := OutfitCatalog.resolve_torso_color(outfit, Color.BLACK)
	t.eq(result, shirt.color, "ceket yoksa gömlek rengi kullanılır")

## Sistemin en önemli garantisi: kıyafetsiz bir karakter (tayfa, düşman,
## kıyafet seçmemiş oyuncu) bu sistem hiç var olmadan önceki gibi çiziliyor
## olmalı - `override` bu yüzden false döner, çağıran `color` alanına hiç
## bakmamalı.
func _test_resolve_headgear_no_hat_means_no_override(t) -> void:
	var result := OutfitCatalog.resolve_headgear({}, "helmet")
	t.not_ok(bool(result.override), "şapka seçilmemişken override olmamalı")
	t.eq(String(result.kind), "helmet", "fallback kafa şekli aynen dönmeli")

func _test_resolve_headgear_hat_overrides_shape_and_color(t) -> void:
	var outfit := {OutfitCatalog.SLOT_HAT: "ranger_hood"}
	var piece := OutfitCatalog.get_piece("ranger_hood")
	var result := OutfitCatalog.resolve_headgear(outfit, "helmet")
	t.ok(bool(result.override), "kukulete seçiliyken override true olmalı")
	t.eq(String(result.kind), "hood", "kukulete WalkFigure/CombatFigure'ın 'hood' şeklini kullanmalı")
	t.eq(result.color, piece.color, "kafanın rengi kukuletenin kendi rengi olmalı")

func _test_unknown_piece_id_falls_back(t) -> void:
	var outfit := {OutfitCatalog.SLOT_SHOES: "shoes_nonexistent"}
	var fallback := Color(0.4, 0.4, 0.4)
	var result := OutfitCatalog.resolve_color(outfit, OutfitCatalog.SLOT_SHOES, fallback)
	t.eq(result, fallback, "bozuk/tanınmayan bir piece_id fallback'e düşer")

func _test_combat_unit_carries_outfit_from_character(t) -> void:
	var character := CharacterData.create(
		"Test", CultureCatalog.NOMAD, CharacterStats.new(),
		CharacterData.DEFAULT_HEIGHT_CM, 0, ClassCatalog.GUARD
	)
	character.set_outfit_piece(OutfitCatalog.SLOT_JACKET, "ranger_jacket")
	var unit := CombatUnit.from_character(character, 1)
	t.eq(unit.outfit, character.outfit, "CombatUnit karakterin outfit'ini aynen taşımalı")
	t.ok(
		unit.outfit.get(OutfitCatalog.SLOT_JACKET, "") == "ranger_jacket",
		"taşınan sözlükte seçilen parça gerçekten var"
	)

func _test_enemy_units_have_no_outfit(t) -> void:
	var template := EnemyCatalog.get_enemy(EnemyCatalog.CUTTER)
	var unit := CombatUnit.from_enemy(template, 1)
	t.eq(unit.outfit, {}, "düşmanın hiç kıyafeti yok - kendi arketip paletinde kalır")

## Yapısal: yeni `outfit` parametresi geriye dönük uyumlu (varsayılanı boş
## sözlük) ve figürler bir outfit verildiğinde hatasız çiziyor. Görünümü
## bir assertion değil, screenshot araçları doğrular (bkz. CLAUDE.md
## Testing bölümü) - burada yalnızca API'nin çökmediğini kilitliyoruz.
func _test_figures_accept_outfit_without_error(t) -> void:
	var walk := WalkFigure.new()
	walk.size = Vector2(80, 160)
	walk.set_kind(
		WalkFigure.KIND_PERSON, "guard", 1.0, Color(0.7, 0.5, 0.4), false,
		{OutfitCatalog.SLOT_HAT: "ranger_hood", OutfitCatalog.SLOT_PANTS: "ranger_pants"}
	)
	t.ok(true, "WalkFigure.set_kind() outfit ile çağrılabiliyor")
	walk.free()

	var combat := CombatFigure.new()
	combat.size = Vector2(120, 200)
	combat.setup(
		"guard", true, "normal", 0.0,
		{OutfitCatalog.SLOT_JACKET: "ranger_jacket", OutfitCatalog.SLOT_HAT: "ranger_hood"}
	)
	t.ok(true, "CombatFigure.setup() outfit ile çağrılabiliyor")
	combat.free()

const BODIES: Array[String] = [
	"body_male_average", "body_male_lean", "body_male_heavy",
	"body_female_average", "body_female_lean", "body_female_heavy",
]

func _all_pieces() -> Array[OutfitPiece]:
	var out: Array[OutfitPiece] = []
	for slot in OutfitCatalog.ALL_SLOTS:
		out.append_array(OutfitCatalog.get_pieces_for_slot(slot))
	return out

## Giysi giyilip çıkarılabiliyorsa her bedende render'ı olmalı - yoksa bir
## bedende görünür, ötekinde görünmez olur ve kimse sebebini bilmez.
func _test_every_piece_has_art_for_every_body(t) -> void:
	for piece in _all_pieces():
		for body in BODIES:
			var id := OutfitCatalog.frames_id(piece, body)
			t.ok(BodyFrames.for_body(id) != null, "%s kare kümesi var" % id)

## Giysi bedenin karesine binecek: klip adları ve kare sayıları birebir.
func _test_garment_frames_match_body_layout(t) -> void:
	var body := BodyFrames.for_body("body_male_average")
	for piece in _all_pieces():
		var g := BodyFrames.for_body(OutfitCatalog.frames_id(piece, "body_male_average"))
		if g == null or body == null:
			continue
		t.eq(g.clip_names, body.clip_names, "%s: klipler bedeninkiyle aynı" % piece.piece_id)
		t.eq(g.clip_frames, body.clip_frames, "%s: kare sayıları aynı" % piece.piece_id)
		var total := 0
		for n in g.clip_frames:
			total += n
		t.eq(g.offsets.size(), total * BodyFrames.LAYERS.size() * BodyFrames.KINDS,
			"%s: kayıt sayısı beden düzeninde" % piece.piece_id)
		var found := false
		for layer in BodyFrames.LAYERS.size():
			if not g.entry("walk", 0, layer, BodyFrames.KIND_BODY).is_empty():
				found = true
		t.ok(found, "%s: yürüyüşün ilk karesinde en az bir katman dolu" % piece.piece_id)

func _person() -> CharacterData:
	return CharacterData.create(
		"Dolap", CultureCatalog.NOMAD, CharacterStats.new(),
		CharacterData.DEFAULT_HEIGHT_CM, 0, ClassCatalog.GUARD
	)

func _test_wear_and_take_off_go_through_the_locker(t) -> void:
	var session := GameSession.new()
	var who := _person()
	t.not_ok(session.wear_outfit(who, "peasant_shirt"), "dolapta yoksa giyilemez")
	t.eq(who.get_outfit_piece(OutfitCatalog.SLOT_SHIRT), "", "başarısız giyme hiçbir şeyi değiştirmez")
	session.add_outfit("peasant_pants")
	session.add_outfit("ranger_pants")
	t.ok(session.wear_outfit(who, "peasant_pants"), "dolaptakini giyer")
	t.eq(session.get_outfit_count("peasant_pants"), 0, "giyilen dolaptan düşer")
	t.ok(session.wear_outfit(who, "ranger_pants"), "aynı slota başkası")
	t.eq(session.get_outfit_count("peasant_pants"), 1, "çıkan dolaba döner")
	t.eq(who.get_outfit_piece(OutfitCatalog.SLOT_PANTS), "ranger_pants", "yeni parça üstünde")
	t.ok(session.take_off_outfit(who, OutfitCatalog.SLOT_PANTS), "çıkarılır")
	t.eq(session.get_outfit_count("ranger_pants"), 1, "çıkarılan dolaba")
	t.not_ok(session.take_off_outfit(who, OutfitCatalog.SLOT_PANTS), "boş slot çıkarılamaz")
	session.add_outfit("no_such_piece")
	t.eq(session.get_outfit_count("no_such_piece"), 0, "katalogda olmayan dolaba girmez")

func _test_choices_are_only_what_is_owned(t) -> void:
	var session := GameSession.new()
	var who := _person()
	t.eq(session.get_outfit_choices(who, OutfitCatalog.SLOT_HAT), [""] as Array[String],
		"hiçbir şey yoksa yalnızca 'hiçbiri'")
	session.add_outfit("ranger_hood")
	t.eq(session.get_outfit_choices(who, OutfitCatalog.SLOT_HAT),
		["", "ranger_hood"] as Array[String], "dolaptaki seçenek olur")
	session.wear_outfit(who, "ranger_hood")
	t.eq(session.get_outfit_choices(who, OutfitCatalog.SLOT_HAT),
		["", "ranger_hood"] as Array[String], "giyilen de seçenek (çıkarmak için)")

func _test_locker_survives_save(t) -> void:
	var session := GameSession.new()
	session.add_outfit("ranger_boots", 2)
	var loaded := GameSession.new()
	loaded.load_from_dict(session.to_save_dict())
	t.eq(loaded.get_outfit_count("ranger_boots"), 2, "dolap kayda giriyor")

func _test_legacy_ids_migrate(t) -> void:
	var who := _person()
	var data := who.to_dict()
	data["outfit"] = {"shirt": "shirt_linen", "hat": "hat_felt", "shoes": "shoes_boots"}
	var back := CharacterData.from_dict(data)
	t.eq(back.get_outfit_piece(OutfitCatalog.SLOT_SHIRT), "peasant_shirt", "eski gömlek gerçek gömleğe")
	t.eq(back.get_outfit_piece(OutfitCatalog.SLOT_SHOES), "ranger_boots", "eski çizme gerçek çizmeye")
	t.eq(back.get_outfit_piece(OutfitCatalog.SLOT_HAT), "", "karşılığı olmayan düşer")

func _test_recruits_come_dressed_deterministically(t) -> void:
	var dressed := 0
	for seed_value in 12:
		var a := RandomNumberGenerator.new()
		a.seed = seed_value
		var b := RandomNumberGenerator.new()
		b.seed = seed_value
		var one := RecruitCatalog.build_starting_companion(a)
		var two := RecruitCatalog.build_starting_companion(b)
		t.eq(one.outfit, two.outfit, "aynı tohum aynı kıyafet")
		if not one.outfit.is_empty():
			dressed += 1
		for slot in one.outfit:
			t.ok(OutfitCatalog.get_piece(str(one.outfit[slot])) != null, "adayın kıyafeti katalogda")
	t.ok(dressed >= 10, "adayların neredeyse hepsi giyinik geliyor (%d/12)" % dressed)

func _test_boots_switch_the_walk(t) -> void:
	t.ok(OutfitCatalog.wears_boots({OutfitCatalog.SLOT_SHOES: "ranger_boots"}), "çizme bileği tutar")
	t.not_ok(OutfitCatalog.wears_boots({}), "yalın ayak walk klibi")
