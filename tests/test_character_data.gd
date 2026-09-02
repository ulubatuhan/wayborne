extends RefCounted

## Boy süs değil: uzun daha çok can taşır, kısa daha iyi kaçınır. Kayıt
## gidiş-dönüşü de burada, çünkü parti artık kayda giriyor.

func suite_name() -> String:
	return "CharacterData"

func run(t) -> void:
	_test_height_affects_body(t)
	_test_max_hp_composition(t)
	_test_dict_round_trip(t)
	_test_class_and_skills(t)

func _test_height_affects_body(t) -> void:
	var base := CharacterStats.new()

	var tall := CharacterData.create("Uzun", CultureCatalog.HIGHLAND, base, 195, 0)
	var short := CharacterData.create("Kısa", CultureCatalog.HIGHLAND, base, 158, 0)
	var middling := CharacterData.create("Orta", CultureCatalog.HIGHLAND, base, 174, 0)

	t.ge(float(tall.get_height_hp_bonus()), 1.0, "uzun boy can ekler")
	t.le(float(tall.get_height_dodge_bonus()), -1.0, "uzun boy kaçınmayı düşürür")
	t.le(float(short.get_height_hp_bonus()), -1.0, "kısa boy can düşürür")
	t.ge(float(short.get_height_dodge_bonus()), 1.0, "kısa boy kaçınma ekler")
	t.eq(middling.get_height_hp_bonus(), 0, "orta boy nötr")
	t.eq(middling.get_height_dodge_bonus(), 0, "orta boy kaçınmada da nötr")

	t.ge(float(tall.get_max_hp()), float(short.get_max_hp()) + 1.0, "uzun daha dayanıklı")
	t.ge(float(short.get_dodge()), float(tall.get_dodge()) + 1.0, "kısa daha çevik kaçar")

func _test_max_hp_composition(t) -> void:
	var character := CharacterData.create("Deneme", CultureCatalog.NOMAD, CharacterStats.new(), 174, 1)

	var expected := (
		character.stats.get_max_hp()
		+ character.get_character_class().bonus_max_hp
		+ character.get_height_hp_bonus()
	)
	t.eq(character.get_max_hp(), expected, "can = stat + sınıf + boy")
	t.eq(character.current_hp, character.get_max_hp(), "yeni karakter tam canla başlar")

	character.apply_damage(9999)
	t.eq(character.current_hp, 0, "can sıfırın altına inmez")
	t.not_ok(character.is_alive(), "canı sıfırsa ayakta değil")

	character.apply_heal(9999)
	t.eq(character.current_hp, character.get_max_hp(), "can tavanı aşmaz")

func _test_dict_round_trip(t) -> void:
	var stats := CharacterStats.new()
	stats.perception = 8

	var original := CharacterData.create("Bozkurt", CultureCatalog.PORT, stats, 188, 3)
	original.hire_cost = 145
	original.apply_damage(7)

	var restored := CharacterData.from_dict(original.to_dict())

	t.eq(restored.character_name, original.character_name, "isim korunur")
	t.eq(restored.culture_id, original.culture_id, "kültür korunur")
	t.eq(restored.class_id, original.class_id, "sınıf korunur")
	t.eq(restored.height_cm, original.height_cm, "boy korunur")
	t.eq(restored.skin_tone, original.skin_tone, "ten rengi korunur")
	t.eq(restored.hire_cost, original.hire_cost, "ücret korunur")
	t.eq(restored.current_hp, original.current_hp, "anlık can korunur")
	t.eq(restored.get_max_hp(), original.get_max_hp(), "tavan can yeniden hesaplanır")

	# Kültür bonusu kayda girmiş hâliyle saklanıyor; yüklerken ikinci kez
	# uygulanmamalı, yoksa her kayıt/yükleme karakteri güçlendirirdi.
	t.eq(restored.stats.get_value(CharacterStats.Kind.CHARISMA),
		original.stats.get_value(CharacterStats.Kind.CHARISMA),
		"kültür bonusu yüklemede tekrar uygulanmaz")

func _test_class_and_skills(t) -> void:
	var character := CharacterData.create("Muhafız", CultureCatalog.VALLEY, CharacterStats.new())

	t.eq(character.class_id, ClassCatalog.GUARD, "varsayılan sınıf Kervan Muhafızı")
	t.eq(character.get_skills().size(), 4, "muhafızın dört yeteneği var")
	t.ne(ClassCatalog.get_character_class_or_default("yok"), null, "sınıf çözümlemesi null dönmez")

	var height_clamped := CharacterData.create("Dev", CultureCatalog.NOMAD, CharacterStats.new(), 999, 0)
	t.eq(height_clamped.height_cm, CharacterData.MAX_HEIGHT_CM, "boy tavanda kırpılır")
