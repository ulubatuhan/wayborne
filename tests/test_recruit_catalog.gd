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
	_test_recruit_heights_stay_natural(t)
	_test_hard_and_personal_recruiting(t)

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

## Oyuncu 2,5 m'ye kadar seçebilir; rastgele adaylar doğal tavanda kalır.
func _test_recruit_heights_stay_natural(t) -> void:
	var tallest := 0
	for seed_value in 40:
		for c in RecruitCatalog.build_candidates(RecruitCatalog.VENUE_MARKET, _seeded_rng(seed_value)):
			tallest = maxi(tallest, c.height_cm)
	t.le(float(tallest), float(CharacterData.NATURAL_MAX_HEIGHT_CM), "aday boyu doğal tavanı aşmaz")

## İşe almak zor ve kişisel (görev Y-C16): pano bir-iki kişi, savaşta bir eksik,
## herkesin neden geldiği belli, iyi aday nadir, fiyat yeni tabloda.
func _test_hard_and_personal_recruiting(t) -> void:
	var top := 0
	var total := 0
	for seed_value in 200:
		for venue in [RecruitCatalog.VENUE_MARKET, RecruitCatalog.VENUE_TAVERN, RecruitCatalog.VENUE_GUILD]:
			var counts: Array = RecruitCatalog.VENUE_COUNTS[venue]
			var list := RecruitCatalog.build_candidates(venue, _seeded_rng(seed_value), 5)
			t.ok(list.size() >= int(counts[0]) and list.size() <= int(counts[1]), "%s panosu bir-iki kişi" % venue)
			for c in list:
				t.ok(CharacterData.BACKSTORY_KEYS.has(c.backstory_id), "adayın neden geldiği belli")
				t.ge(float(c.hire_cost), float(RecruitCatalog.get_venue_profile(venue)[2]), "fiyat yeni tablonun tabanında")
				if venue == RecruitCatalog.VENUE_GUILD:
					total += 1
					if c.level == 5 + RecruitCatalog.VENUE_GUILD_LEVEL_SPREAD[1]:
						top += 1
		var pressed := RecruitCatalog.build_candidates(RecruitCatalog.VENUE_MARKET, _seeded_rng(seed_value), 5, 0, 1)
		t.le(float(pressed.size()), float(RecruitCatalog.VENUE_COUNTS["market"][1] - 1), "savaşta pano daha boş")
	t.ok(float(top) / float(maxi(1, total)) < 0.2, "loncanın en tecrübelisi nadir (%d/%d)" % [top, total])
