extends RefCounted

## Faz 6 ilerleme katmanı: azalan getiri, XP/seviye eğrisi, stat/yetkinlik
## yatırımı, otomatik dağıtım ve multiclass kilidi.

func suite_name() -> String:
	return "Progression"

func run(t) -> void:
	_test_effective_value(t)
	_test_diminishing_returns_on_derived_stats(t)
	_test_xp_curve_and_level_up(t)
	_test_manual_investment(t)
	_test_auto_allocate_spreads_points(t)
	_test_multiclass_unlock(t)
	_test_level_cap(t)

func _make_character(character_name: String = "Deneme") -> CharacterData:
	return CharacterData.create(character_name, CultureCatalog.VALLEY, CharacterStats.new())

func _test_effective_value(t) -> void:
	t.almost(CharacterStats.effective_value(5), 0.0, "taban statın etkin değeri sıfır")
	t.almost(CharacterStats.effective_value(10), 5.0, "10'a kadar tam katkı")
	t.almost(CharacterStats.effective_value(15), 7.5, "10 üstü yarı katkı")
	t.almost(CharacterStats.effective_value(1), -4.0, "tabanın altı da orantılı düşer")

func _test_diminishing_returns_on_derived_stats(t) -> void:
	var stats := CharacterStats.new()
	stats.endurance = 10
	t.eq(stats.get_max_hp(), 60, "10'a kadar eski formülle birebir aynı")

	stats.endurance = 15
	t.eq(stats.get_max_hp(), 70, "10 üstünde büyüme yavaşlar (azalan getiri olmasaydı 80 olurdu)")

func _test_xp_curve_and_level_up(t) -> void:
	var character := _make_character()
	character.auto_allocate = false
	var base_strength := character.stats.strength

	var required := CharacterData.xp_required_for_level(1)
	t.eq(required, 50, "ilk seviye 50 XP ister")

	var gained := character.gain_xp(required)
	t.eq(gained, 1, "tam XP ile tek seviye atlar")
	t.eq(character.level, 2, "seviye ikiye çıkar")
	t.eq(character.xp, 0, "kullanılan XP sıfırlanır")
	t.eq(character.unspent_stat_points, 1, "seviye başına bir stat puanı birikir")
	t.eq(character.unspent_skill_points, 2, "seviye başına iki yetkinlik puanı birikir")
	t.eq(character.stats.strength, base_strength, "auto_allocate kapalıyken stat kendiliğinden değişmez")

	var next_required := CharacterData.xp_required_for_level(2)
	t.ok(next_required > required, "eğri katlanarak büyür")

	var multi_level := character.gain_xp(next_required + CharacterData.xp_required_for_level(3))
	t.eq(multi_level, 2, "yeterli XP birden çok seviye atlatır")
	t.eq(character.level, 4, "seviye ardışık atlar")

func _test_manual_investment(t) -> void:
	var character := _make_character()
	character.auto_allocate = false
	character.unspent_stat_points = 1
	character.unspent_skill_points = 1

	var before := character.stats.strength
	t.ok(character.invest_stat_point(CharacterStats.Kind.STRENGTH), "puan varken yatırım kabul edilir")
	t.eq(character.stats.strength, before + 1, "stat bir puan artar")
	t.eq(character.unspent_stat_points, 0, "puan harcanır")
	t.not_ok(character.invest_stat_point(CharacterStats.Kind.STRENGTH), "puan bitince yatırım reddedilir")

	var skill_id: String = character.get_character_class().skill_ids[0]
	t.ok(character.invest_skill_point(skill_id), "yetkinlik puanı kabul edilir")
	t.eq(character.get_skill_proficiency(skill_id), 1, "yetkinlik bir artar")
	t.not_ok(character.invest_skill_point(skill_id), "puan bitince yetkinlik yatırımı reddedilir")

func _test_auto_allocate_spreads_points(t) -> void:
	var character := _make_character()
	character.auto_allocate = true
	t.ok(character.stats.endurance <= CharacterStats.MAX_VALUE, "başlangıç stat tavanın altında")

	character.gain_xp(CharacterData.xp_required_for_level(1))
	t.eq(character.unspent_stat_points, 0, "otomatik dağıtımda puan birikmez")
	t.eq(character.unspent_skill_points, 0, "yetkinlik puanı da otomatik harcanır")

	var affinity: Array = character.get_character_class().stat_affinity
	if not affinity.is_empty():
		var invested_in_affinity := character.stats.get_value(affinity[0]) > CharacterStats.BASE_VALUE
		t.ok(invested_in_affinity, "otomatik dağıtım sınıfın yatkın olduğu stata gider")

func _test_multiclass_unlock(t) -> void:
	var character := _make_character()
	t.not_ok(character.can_multiclass(), "düşük seviyede multiclass kapalı")
	t.not_ok(character.set_second_class(ClassCatalog.HUNTER), "kilitliyken ikinci sınıf reddedilir")

	character.level = CharacterData.MULTICLASS_UNLOCK_LEVEL
	t.ok(character.can_multiclass(), "yedinci seviyede multiclass açılır")
	t.ok(character.set_second_class(ClassCatalog.HUNTER), "ikinci sınıf kabul edilir")
	t.not_ok(character.set_second_class(character.class_id), "kendi sınıfı ikinci sınıf olamaz")

	var skills := character.get_skills()
	var guard_skill := SkillCatalog.get_skill(SkillCatalog.SHIELD_BASH)
	var hunter_skill := SkillCatalog.get_skill(SkillCatalog.ARROW_SHOT)
	t.ok(skills.has(guard_skill), "ana sınıfın yeteneği kalır")
	t.ok(skills.has(hunter_skill), "ikinci sınıfın yeteneği eklenir")

func _test_level_cap(t) -> void:
	var character := _make_character()
	character.auto_allocate = true
	character.gain_xp(999999)
	t.eq(character.level, CharacterData.MAX_LEVEL, "seviye tavanı aşılmaz")
	t.eq(character.xp, 0, "tavanda fazla XP birikmez")
	t.eq(character.gain_xp(1000), 0, "tavandan sonra XP seviye atlatmaz")
