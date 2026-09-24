extends RefCounted

## Huylar (Trait): katalog şekli, statlarla orantılı seed dağıtımı, en
## fazla üç huy kuralı, "taze" pencere ve türetilmiş değerlere yansıması.

func suite_name() -> String:
	return "Traits"

func run(t) -> void:
	_test_catalog_is_balanced(t)
	_test_seed_roll_leans_with_stats(t)
	_test_grant_and_remove(t)
	_test_max_three_traits(t)
	_test_fresh_window(t)
	_test_derived_values_include_traits(t)
	_test_dict_round_trip(t)
	_test_grant_trait_effect_targets_player(t)
	_test_behavioral_hooks(t)

func _test_catalog_is_balanced(t) -> void:
	var traits := TraitCatalog.get_traits()
	t.eq(traits.size(), 16, "sekiz stat için birer olumlu birer olumsuz huy (Faz 17: Bilgelik/İnanç eklendi)")

	var positive_count := 0
	var seen_ids: Dictionary = {}
	var seen_stats: Dictionary = {}
	for trait_resource in traits:
		if trait_resource.is_positive:
			positive_count += 1
		t.not_ok(seen_ids.has(trait_resource.trait_id), "huy kimliği tekil: %s" % trait_resource.trait_id)
		seen_ids[trait_resource.trait_id] = true
		var stat_key := "%d_%s" % [trait_resource.affinity_stat, trait_resource.is_positive]
		t.not_ok(seen_stats.has(stat_key), "her stat için tek yönde tek huy: %s" % stat_key)
		seen_stats[stat_key] = true
	t.eq(positive_count, 8, "yarısı olumlu")
	t.eq(seen_stats.size(), CharacterStats.KIND_ORDER.size() * 2, "sekiz statın hepsi kaplı")

## Statlar hepsi tavanda olan bir karakter, olumlu huylara ezici oranda
## eğilir - tek tek çekilişler rastgele ama otuz bağımsız tohumda bu denli
## büyük bir farkın tesadüfen kapanma ihtimali ihmal edilebilir (bkz.
## test_event_engine.gd _test_seed_is_reproducible'daki aynı gerekçe).
func _test_seed_roll_leans_with_stats(t) -> void:
	var maxed := CharacterStats.new()
	for kind in CharacterStats.KIND_ORDER:
		maxed.set_value(kind, CharacterStats.MAX_VALUE)

	var positive_hits := 0
	var draws := 30
	for seed_value in draws:
		var rng := RandomNumberGenerator.new()
		rng.seed = 9000 + seed_value
		var trait_id := TraitCatalog.roll_seed_trait(maxed, rng)
		var trait_resource := TraitCatalog.get_trait(trait_id)
		t.ne(trait_resource, null, "her zaman geçerli bir huy döner")
		if trait_resource.is_positive:
			positive_hits += 1
	t.ge(float(positive_hits), float(draws) * 0.7, "tavan statlı karakter büyük oranda olumlu huy alır")

func _make_character() -> CharacterData:
	return CharacterData.create("Deneme", CultureCatalog.VALLEY, CharacterStats.new())

func _test_grant_and_remove(t) -> void:
	var character := _make_character()
	t.not_ok(character.has_trait(TraitCatalog.MIGHTY_ARM), "başlangıçta huy yok")

	t.ok(character.grant_trait(TraitCatalog.MIGHTY_ARM, 3), "geçerli huy kabul edilir")
	t.ok(character.has_trait(TraitCatalog.MIGHTY_ARM), "huy artık üzerinde")
	t.not_ok(character.grant_trait(TraitCatalog.MIGHTY_ARM, 5), "aynı huy iki kez verilmez")
	t.not_ok(character.grant_trait("yok_boyle_bir_huy", 3), "katalogda olmayan huy reddedilir")

	t.ok(character.remove_trait(TraitCatalog.MIGHTY_ARM), "huy silinebilir")
	t.not_ok(character.has_trait(TraitCatalog.MIGHTY_ARM), "silinen huy artık yok")
	t.not_ok(character.remove_trait(TraitCatalog.MIGHTY_ARM), "olmayan huy silinemez")

func _test_max_three_traits(t) -> void:
	var character := _make_character()
	t.ok(character.grant_trait(TraitCatalog.MIGHTY_ARM, 0), "birinci huy")
	t.ok(character.grant_trait(TraitCatalog.NIMBLE_STEP, 0), "ikinci huy")
	t.ok(character.grant_trait(TraitCatalog.IRON_CONSTITUTION, 0), "üçüncü huy")
	t.not_ok(character.grant_trait(TraitCatalog.SHARP_EYE, 0), "dördüncü huy reddedilir")
	t.eq(character.trait_ids.size(), CharacterData.MAX_TRAITS, "tavan üçte kalır")

func _test_fresh_window(t) -> void:
	var character := _make_character()
	character.grant_trait(TraitCatalog.MIGHTY_ARM, 10)

	t.ok(character.is_trait_fresh(TraitCatalog.MIGHTY_ARM, 10), "verildiği gün tazedir")
	t.ok(
		character.is_trait_fresh(TraitCatalog.MIGHTY_ARM, 10 + CharacterData.TRAIT_FRESH_WINDOW_DAYS),
		"pencerenin son günü hâlâ tazedir"
	)
	t.not_ok(
		character.is_trait_fresh(TraitCatalog.MIGHTY_ARM, 10 + CharacterData.TRAIT_FRESH_WINDOW_DAYS + 1),
		"pencere kapanınca kalıcılaşır"
	)
	t.not_ok(character.is_trait_fresh("yok_boyle_bir_huy", 10), "tutulmayan huy taze sayılmaz")

func _test_derived_values_include_traits(t) -> void:
	var character := _make_character()
	var base_hp := character.get_max_hp()
	var base_dodge := character.get_dodge()
	var base_accuracy := character.get_accuracy()
	var base_damage := character.get_damage_bonus()

	character.grant_trait(TraitCatalog.IRON_CONSTITUTION, 0)
	character.grant_trait(TraitCatalog.CLUMSY_FOOT, 0)
	character.grant_trait(TraitCatalog.PRUDENT, 0)

	t.eq(character.get_max_hp(), base_hp + 4, "Demir Bünye canı artırır")
	t.eq(character.get_dodge(), maxi(0, base_dodge - 3), "Beceriksiz Ayak kaçınmayı düşürür")
	t.eq(character.get_accuracy(), base_accuracy + 2, "Basiretli isabeti artırır")
	t.eq(character.get_damage_bonus(), base_damage, "ilgisiz huy hasarı değiştirmez")

func _test_dict_round_trip(t) -> void:
	var original := _make_character()
	original.grant_trait(TraitCatalog.SHARP_EYE, 4)
	original.grant_trait(TraitCatalog.OFF_PUTTING, 7)

	var restored := CharacterData.from_dict(original.to_dict())

	t.eq(restored.trait_ids.size(), 2, "huy sayısı korunur")
	t.ok(restored.has_trait(TraitCatalog.SHARP_EYE), "ilk huy korunur")
	t.ok(restored.has_trait(TraitCatalog.OFF_PUTTING), "ikinci huy korunur")
	t.ok(restored.is_trait_fresh(TraitCatalog.SHARP_EYE, 4), "verildiği gün korunur")
	t.not_ok(
		restored.is_trait_fresh(TraitCatalog.SHARP_EYE, 4 + CharacterData.TRAIT_FRESH_WINDOW_DAYS + 1),
		"pencere gidiş-dönüşten sonra da doğru hesaplanır"
	)

func _test_grant_trait_effect_targets_player(t) -> void:
	var session := GameSession.new(100, 0, 1)
	var leader := session.get_player_character()
	session.total_days_elapsed = 12

	var effect := EventEffect.make(EventEffect.Type.GRANT_TRAIT, 0, TraitCatalog.NEARSIGHTED)
	var effects: Array[EventEffect] = [effect]
	var result := EventEffectApplier.apply(effects, session)

	t.ok(leader.has_trait(TraitCatalog.NEARSIGHTED), "huy oyuncunun karakterine verilir")
	t.ok(leader.is_trait_fresh(TraitCatalog.NEARSIGHTED, 12), "verildiği gün oturumun gününden okunur")
	t.eq(result.lines.size(), 1, "sonuçta bir satır var")

	# Tavan doluyken sessizce hiçbir şey yapmamalı - olay kilitlenmemeli.
	leader.grant_trait(TraitCatalog.MIGHTY_ARM, 12)
	leader.grant_trait(TraitCatalog.NIMBLE_STEP, 12)
	t.eq(leader.trait_ids.size(), CharacterData.MAX_TRAITS, "tavan dolu")
	var overflow_result := EventEffectApplier.apply([
		EventEffect.make(EventEffect.Type.GRANT_TRAIT, 0, TraitCatalog.IRON_CONSTITUTION)
	], session)
	t.eq(overflow_result.lines.size(), 0, "tavan doluyken yeni huy sessizce reddedilir")

## Faz 17: davranışsal kancalar - check_bonus, xp/deathblow/stress payları
## ve savaş içi emir reddi. Hiçbiri huysuz bir karakterde etkin değil
## (bkz. Trait'in kendi "her formül taban stat 5'te eski davranışla birebir
## aynı" kuralı) - bu yüzden testler her seferinde önce huysuz temeli,
## sonra huylu farkı ölçüyor.
func _test_behavioral_hooks(t) -> void:
	var character := _make_character()
	var base_xp_bonus := character.get_xp_bonus_percent()
	var base_deathblow_bonus := character.get_deathblow_resist_bonus()
	var base_stress_resist := character.get_stress_resistance()
	var base_check := character.get_check_modifier(CharacterStats.Kind.WISDOM)

	character.grant_trait(TraitCatalog.KEEN_MIND, 0)
	t.eq(
		character.get_xp_bonus_percent(), base_xp_bonus + 8,
		"Keskin Zihin XP oranını artırır"
	)
	t.ok(
		character.get_check_modifier(CharacterStats.Kind.WISDOM) > base_check,
		"olumlu huy kendi statının check'ine pozitif pay ekler"
	)

	var faithful := _make_character()
	faithful.grant_trait(TraitCatalog.STEADFAST_FAITH, 0)
	t.eq(
		faithful.get_deathblow_resist_bonus(), base_deathblow_bonus + 5,
		"Sarsılmaz İnanç ölümcül vuruş direncini artırır"
	)

	var wavering := _make_character()
	wavering.grant_trait(TraitCatalog.WAVERING_FAITH, 0)
	t.eq(
		wavering.get_deathblow_resist_bonus(), base_deathblow_bonus - 5,
		"Sarsılmış İnanç ölümcül vuruş direncini azaltır"
	)
	t.ok(
		wavering.get_check_modifier(CharacterStats.Kind.FAITH) < 0.0,
		"olumsuz huy kendi statının check'ine negatif pay ekler"
	)

	var sturdy := _make_character()
	sturdy.grant_trait(TraitCatalog.IRON_CONSTITUTION, 0)
	t.eq(
		sturdy.get_stress_resistance(), base_stress_resist + 5,
		"Demir Bünye stres direncini artırır"
	)

	var frail := _make_character()
	frail.grant_trait(TraitCatalog.FRAIL_CONSTITUTION, 0)
	t.eq(
		frail.get_stress_resistance(), base_stress_resist - 5,
		"Zayıf Bünye stres direncini azaltır"
	)

	# PR-3'ün tamamlanan ilk kancası: aynı stress_resistance_bonus artık
	# günlük yıpranma hızını da bükebiliyor - eşiği değil, hızı.
	var base_daily_mult := character.get_daily_stress_gain_multiplier()
	t.almost(base_daily_mult, 1.0, "huysuz karakterde günlük stres çarpanı tam 1.0")
	t.ok(
		sturdy.get_daily_stress_gain_multiplier() < base_daily_mult,
		"Demir Bünye günlük yıpranmayı yavaşlatır"
	)
	t.ok(
		frail.get_daily_stress_gain_multiplier() > base_daily_mult,
		"Zayıf Bünye günlük yıpranmayı hızlandırır"
	)

	# refusal_bonus: olumlu huy sakinleştirir (negatif pay), olumsuz tetikler.
	var calm := _make_character()
	calm.grant_trait(TraitCatalog.REASSURING, 0)
	t.ok(calm.get_refusal_bonus() < 0, "olumlu huy emir reddini azaltır")

	var jumpy := _make_character()
	jumpy.grant_trait(TraitCatalog.OFF_PUTTING, 0)
	t.ok(jumpy.get_refusal_bonus() > 0, "olumsuz huy emir reddini artırır")

	# CombatUnit.from_character bu payı taşıyor mu - savaşın kendi okuduğu
	# sarmalayıcı, ham stats değil (bkz. CLAUDE.md'nin sarmalayıcı kuralı).
	var unit := CombatUnit.from_character(jumpy, 1, true)
	t.eq(unit.refusal_bonus, jumpy.get_refusal_bonus(), "CombatUnit huy payını taşır")
