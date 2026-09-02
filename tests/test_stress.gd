extends RefCounted

## Parti stresi: kırılma zarı, emir reddi, kamp ve STRESS olay etkisi.
## Moral (CaravanState.morale) sefer başına sıfırlanır; stres tam tersi -
## GameSession'da kalıcıdır, yalnızca şehir dinlenmesi ya da kamp azaltır.

func suite_name() -> String:
	return "Stress"

func run(t) -> void:
	_test_change_stress_clamps(t)
	_test_stress_resistance_scales_with_endurance(t)
	_test_resolve_stress_breaks(t)
	_test_resolve_stress_breaks_skips_calm_party(t)
	_test_make_camp(t)
	_test_stress_event_effect(t)
	_test_stressed_unit_sometimes_refuses(t)
	_test_calm_unit_never_refuses(t)

func _test_change_stress_clamps(t) -> void:
	var session := GameSession.new(100, 0, 1)
	t.eq(session.party_stress, 0, "sefer başlamadan stres sıfır")

	session.change_stress(150)
	t.eq(session.party_stress, GameSession.MAX_STRESS, "stres tavanı aşmaz")

	session.change_stress(-500)
	t.eq(session.party_stress, 0, "stres negatife düşmez")

func _test_stress_resistance_scales_with_endurance(t) -> void:
	var low := CharacterData.new()
	low.stats = CharacterStats.new()
	low.stats.endurance = 1

	var baseline := CharacterData.new()
	baseline.stats = CharacterStats.new()

	var high := CharacterData.new()
	high.stats = CharacterStats.new()
	high.stats.endurance = CharacterStats.MAX_VALUE

	t.ok(low.get_stress_resistance() < baseline.get_stress_resistance(), "düşük dayanıklılık direnci düşürür")
	t.ok(high.get_stress_resistance() > baseline.get_stress_resistance(), "yüksek dayanıklılık direnci artırır")

	t.not_ok(baseline.is_stressed(0), "stressiz kervan kimseyi kırmaz")
	t.ok(baseline.is_stressed(GameSession.MAX_STRESS), "tavan stres herkesi kırar")

func _test_resolve_stress_breaks(t) -> void:
	var session := GameSession.new(200, 0, 2)
	var leader := session.get_player_character()
	leader.stats = CharacterStats.new()
	leader.stats.endurance = 1  # düşük direnç: kolay kırılsın

	var companion := CharacterData.new()
	companion.character_name = "Yoldaş"
	companion.class_id = ClassCatalog.GUARD
	companion.stats = CharacterStats.new()
	companion.stats.endurance = 1
	session.party.append(companion)

	session.party_stress = GameSession.MAX_STRESS
	session.total_days_elapsed = 20

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var results := session.resolve_stress_breaks(rng)

	t.eq(results.size(), 2, "tavan streste herkes kırılır")
	for entry in results:
		var data: Dictionary = entry
		t.ok(data.has("affliction"), "sonuç kutbu bildiriyor")
		if not String(data.trait_id).is_empty():
			var granted_trait := TraitCatalog.get_trait(data.trait_id)
			t.eq(granted_trait.is_positive, not bool(data.affliction), "verilen huyun kutbu zar sonucuyla eşleşir")

	# Oyuncu hiçbir zaman ayrılmaz.
	var leader_entry: Dictionary = {}
	for entry in results:
		if String((entry as Dictionary).character_name) == leader.character_name:
			leader_entry = entry
	t.not_ok(bool(leader_entry.get("departed", false)), "oyuncu kırılsa da kervanı terk etmez")

func _test_resolve_stress_breaks_skips_calm_party(t) -> void:
	var session := GameSession.new(100, 0, 1)
	session.party_stress = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var results := session.resolve_stress_breaks(rng)
	t.eq(results.size(), 0, "stres sıfırken kimse kırılmaz")

func _test_make_camp(t) -> void:
	var session := GameSession.new(100, 5, 1)
	session.party_stress = 50

	var result := session.make_camp()
	t.eq(result.provisions_spent, GameSession.CAMP_PROVISIONS_COST, "kamp erzak yer")
	t.eq(session.get_provisions(), 5 - GameSession.CAMP_PROVISIONS_COST, "erzak düşer")
	t.eq(session.party_stress, 50 - GameSession.CAMP_STRESS_RELIEF, "stres belirgin azalır")

	var poor_session := GameSession.new(100, 1, 1)
	var poor_result := poor_session.make_camp()
	t.eq(poor_result.provisions_spent, 1, "erzak yetmezse olanın hepsi harcanır, borca girilmez")
	t.eq(poor_session.get_provisions(), 0, "erzak negatife düşmez")

func _test_stress_event_effect(t) -> void:
	var session := GameSession.new(100, 0, 1)
	session.party_stress = 40

	var relief: Array[EventEffect] = [EventEffect.make(EventEffect.Type.STRESS, -15)]
	EventEffectApplier.apply(relief, session)
	t.eq(session.party_stress, 25, "olumlu STRESS etkisi azaltır")

	var strain: Array[EventEffect] = [EventEffect.make(EventEffect.Type.STRESS, 30)]
	EventEffectApplier.apply(strain, session)
	t.eq(session.party_stress, 55, "olumsuz STRESS etkisi artırır")

func _make_hero(hero_name: String) -> CharacterData:
	return CharacterData.create(hero_name, CultureCatalog.VALLEY, CharacterStats.new())

func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

## Tek çekiliş yerine kırk bağımsız tohumda ezici marj kullanılıyor - aynı
## gerekçe test_event_engine.gd'nin tohum-tekrarlanabilirlik testinde ve
## test_traits.gd'nin seed dağıtım testinde de geçerli.
func _test_stressed_unit_sometimes_refuses(t) -> void:
	var refusal_seen := false
	for seed_value in 40:
		var unit := CombatUnit.from_character(_make_hero("Gergin"), 1, true)
		var enemy := CombatUnit.from_enemy(EnemyCatalog.get_enemy(EnemyCatalog.CUTTER), 1)
		var rng := _seeded_rng(9500 + seed_value)
		var encounter := CombatEncounter.new([unit], [enemy], rng)

		var refused := false
		encounter.log_added.connect(func(line): refused = refused or ("kulak asmıyor" in line))
		encounter.start()

		if refused:
			refusal_seen = true
			break
	t.ok(refusal_seen, "kırk denemede stresli birim en az bir kez emir dinlemiyor")

func _test_calm_unit_never_refuses(t) -> void:
	for seed_value in 15:
		var unit := CombatUnit.from_character(_make_hero("Sakin"), 1, false)
		var enemy := CombatUnit.from_enemy(EnemyCatalog.get_enemy(EnemyCatalog.CUTTER), 1)
		var rng := _seeded_rng(9700 + seed_value)
		var encounter := CombatEncounter.new([unit], [enemy], rng)

		var refused := false
		encounter.log_added.connect(func(line): refused = refused or ("kulak asmıyor" in line))
		encounter.start()

		t.not_ok(refused, "stressiz birim hiç emir reddetmez (tohum %d)" % seed_value)
