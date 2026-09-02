extends RefCounted

## Faz 6 PR-B: adaylar artık oyuncu seviyesine göre ölçekleniyor ve dört
## sınıftan rastgele biriyle geliyor. Meydan hep acemi, lonca hep en az
## oyuncu kadar tecrübeli çıkarmalı.

func suite_name() -> String:
	return "RecruitCatalog"

func run(t) -> void:
	_test_level_spread_per_venue(t)
	_test_candidates_use_all_classes(t)
	_test_higher_level_costs_more(t)
	_test_granted_levels_are_spent(t)

func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func _test_level_spread_per_venue(t) -> void:
	var player_level := 10

	for run_index in 20:
		var market := RecruitCatalog.build_candidates(
			RecruitCatalog.VENUE_MARKET, _seeded_rng(run_index), player_level
		)
		for candidate in market:
			t.le(float(candidate.level), float(player_level - 1), "meydan oyuncudan tecrübeli çıkarmaz")

		var guild := RecruitCatalog.build_candidates(
			RecruitCatalog.VENUE_GUILD, _seeded_rng(run_index), player_level
		)
		for candidate in guild:
			t.ge(float(candidate.level), float(player_level), "lonca oyuncudan acemi çıkarmaz")

func _test_candidates_use_all_classes(t) -> void:
	var seen_classes: Dictionary = {}
	for seed_value in 40:
		var candidates := RecruitCatalog.build_candidates(
			RecruitCatalog.VENUE_TAVERN, _seeded_rng(seed_value), 5
		)
		for candidate in candidates:
			seen_classes[candidate.class_id] = true

	for character_class in ClassCatalog.get_classes():
		t.ok(seen_classes.has(character_class.class_id), "%s de aday olarak çıkabiliyor" % character_class.display_name)

func _test_higher_level_costs_more(t) -> void:
	var low_level := RecruitCatalog.build_candidates(RecruitCatalog.VENUE_MARKET, _seeded_rng(1), 1)
	var high_level := RecruitCatalog.build_candidates(RecruitCatalog.VENUE_GUILD, _seeded_rng(1), 20)

	t.ok(not low_level.is_empty() and not high_level.is_empty(), "her iki mekân da aday üretir")
	var cheapest_low := low_level[0].hire_cost
	var cheapest_high := high_level[0].hire_cost
	t.ok(cheapest_high > cheapest_low, "tecrübeli aday daha pahalıya gelir")

func _test_granted_levels_are_spent(t) -> void:
	var candidates := RecruitCatalog.build_candidates(RecruitCatalog.VENUE_GUILD, _seeded_rng(7), 15)
	for candidate in candidates:
		t.eq(candidate.unspent_stat_points, 0, "auto_allocate açık geldiği için puan birikmez")
		t.eq(candidate.unspent_skill_points, 0, "yetkinlik puanı da otomatik harcanır")
		t.eq(candidate.current_hp, candidate.get_max_hp(), "aday tam canla listelenir")
		if candidate.level > 1:
			var total_proficiency := 0
			for skill_id in candidate.skill_proficiency:
				total_proficiency += int(candidate.skill_proficiency[skill_id])
			t.ok(total_proficiency > 0, "seviyeli aday biraz yetkinlik biriktirmiş olur")
