extends RefCounted

## Savaşın iki değişmez kuralı burada kilitleniyor:
##   1. Mevki kilidi gerçek - yanlış saftan yetenek kullanılamaz.
##   2. Yenilgi ölüm değil - düşen karakter 1 canla kalkar.
## Ayrıca motorun kilitlenmediği (her savaşın bittiği) doğrulanıyor.

const MAX_AUTOPLAY_ACTIONS: int = 400

func suite_name() -> String:
	return "Combat"

func run(t) -> void:
	_test_skill_position_gating(t)
	_test_cooldowns(t)
	_test_valid_targets_respect_range(t)
	_test_squad_scales_with_party(t)
	_test_defeat_is_not_death(t)
	_test_encounter_terminates(t)
	_test_swap_reorders_ranks(t)

func _make_hero(hero_name: String) -> CharacterData:
	return CharacterData.create(hero_name, CultureCatalog.VALLEY, CharacterStats.new(), 174, 1)

func _make_party(size: int) -> Array[CombatUnit]:
	var units: Array[CombatUnit] = []
	for index in size:
		units.append(CombatUnit.from_character(_make_hero("Yoldaş %d" % (index + 1)), index + 1))
	return units

func _make_enemies(size: int) -> Array[CombatUnit]:
	var units: Array[CombatUnit] = []
	for index in size:
		units.append(CombatUnit.from_enemy(EnemyCatalog.get_enemy(EnemyCatalog.CUTTER), index + 1))
	return units

func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func _test_skill_position_gating(t) -> void:
	var shield_bash := SkillCatalog.get_skill(SkillCatalog.SHIELD_BASH)
	var sling := SkillCatalog.get_skill(SkillCatalog.SLING_SHOT)

	t.ok(shield_bash.can_use_from(1), "kalkan darbesi öndeyken kullanılır")
	t.not_ok(shield_bash.can_use_from(4), "kalkan darbesi en arkadan kullanılamaz")
	t.ok(sling.can_use_from(4), "sapan arkadan kullanılır")
	t.not_ok(sling.can_use_from(1), "sapan öndeyken kullanılamaz")
	t.not_ok(sling.can_reach(1), "sapan en öndeki düşmana ulaşamaz")

	var unit := CombatUnit.from_character(_make_hero("Ön Saf"), 1)
	t.ok(unit.can_use_skill(shield_bash), "1. mevkide kalkan darbesi açık")
	t.not_ok(unit.can_use_skill(sling), "1. mevkide sapan kilitli")
	t.not_ok(
		unit.get_skill_block_reason(sling).is_empty(),
		"kilitli yetenek sebebini bildirir"
	)

func _test_cooldowns(t) -> void:
	var rally := SkillCatalog.get_skill(SkillCatalog.RALLY)
	t.ok(rally.is_heal(), "toparlan bir iyileştirme")
	t.eq(rally.cooldown_rounds, 2, "toparlan iki tur bekler")

	var unit := CombatUnit.from_character(_make_hero("Şifacı"), 3)
	t.ok(unit.can_use_skill(rally), "başlangıçta bekleme yok")

	unit.start_cooldown(rally)
	t.not_ok(unit.can_use_skill(rally), "kullanınca beklemeye girer")

	unit.tick_cooldowns()
	t.not_ok(unit.can_use_skill(rally), "bir tur sonra hâlâ bekliyor")

	unit.tick_cooldowns()
	t.ok(unit.can_use_skill(rally), "iki tur sonra tekrar açılır")

func _test_valid_targets_respect_range(t) -> void:
	var encounter := CombatEncounter.new(_make_party(1), _make_enemies(4), _seeded_rng(11))
	var shield_bash := SkillCatalog.get_skill(SkillCatalog.SHIELD_BASH)
	var attacker := encounter.player_units[0]

	var targets := encounter.get_valid_targets(attacker, shield_bash)
	t.eq(targets.size(), 2, "kalkan darbesi yalnızca ilk iki mevkiye ulaşır")
	for target in targets:
		t.le(float(target.position), 2.0, "hedef menzil içinde")

	var sling := SkillCatalog.get_skill(SkillCatalog.SLING_SHOT)
	t.eq(
		encounter.get_valid_targets(attacker, sling).size(),
		0,
		"kullanılamayan yetenek hedef üretmez"
	)

func _test_squad_scales_with_party(t) -> void:
	var lonely := EnemyCatalog.build_bandit_squad(0.6, 1, _seeded_rng(3))
	var full := EnemyCatalog.build_bandit_squad(0.6, 4, _seeded_rng(3))
	var calm := EnemyCatalog.build_bandit_squad(0.1, 4, _seeded_rng(3))

	t.eq(lonely.size(), 2, "tek başına yola çıkan iki haydutla karşılaşır")
	t.eq(full.size(), 4, "dolu kadro dolu kadroyla karşılaşır")
	t.eq(calm.size(), 2, "sakin yolda kadro küçük")
	t.le(float(full.size()), float(CombatEncounter.MAX_SIDE_SIZE), "saf dört mevkiyi aşmaz")

	for index in full.size():
		t.eq(full[index].position, index + 1, "düşman mevkileri 1'den başlayarak sıralı")

func _test_defeat_is_not_death(t) -> void:
	var hero := _make_hero("Düşen")
	var party: Array[CombatUnit] = [CombatUnit.from_character(hero, 1)]
	var encounter := CombatEncounter.new(party, _make_enemies(1), _seeded_rng(5))

	encounter.player_units[0].current_hp = 0
	t.eq(encounter.get_downed_count(), 1, "düşen sayılır")

	encounter.write_back_party()
	t.eq(hero.current_hp, 1, "düşen karakter 1 canla ayağa kalkar")
	t.ok(hero.is_alive(), "kervan yok olmaz")

func _test_encounter_terminates(t) -> void:
	# Motorun kilitlenmediğinin kanıtı: birden çok tohumda savaş bitmeli.
	var seeds: Array[int] = [1, 17, 99, 1234]
	for seed_value in seeds:
		var encounter := CombatEncounter.new(_make_party(2), _make_enemies(3), _seeded_rng(seed_value))
		encounter.start()

		var actions := 0
		while not encounter.is_over() and actions < MAX_AUTOPLAY_ACTIONS:
			if not _take_any_player_action(encounter):
				break
			actions += 1

		t.ok(encounter.is_over(), "tohum %d ile savaş sonuca bağlanır" % seed_value)
		t.le(float(actions), float(MAX_AUTOPLAY_ACTIONS) - 1.0, "tohum %d makul turda biter" % seed_value)

## Sırası gelen oyuncuya ilk uygun hamleyi yaptırır; hamle kalmazsa false.
func _take_any_player_action(encounter: CombatEncounter) -> bool:
	if not encounter.is_player_turn():
		return false

	var unit := encounter.get_active_unit()
	for skill in unit.skills:
		var targets := encounter.get_valid_targets(unit, skill)
		if not targets.is_empty():
			return encounter.use_skill(skill, targets[0])

	# Hiçbir yetenek menzil bulamadıysa saf değiştirmek de bir hamledir.
	var living: Array[CombatUnit] = []
	for candidate in encounter.player_units:
		if candidate.is_alive():
			living.append(candidate)
	if living.size() >= 2:
		return encounter.swap_player_positions(living[0], living[1])
	return false

func _test_swap_reorders_ranks(t) -> void:
	var encounter := CombatEncounter.new(_make_party(2), _make_enemies(2), _seeded_rng(42))
	var first := encounter.player_units[0]
	var second := encounter.player_units[1]
	var first_position := first.position
	var second_position := second.position

	t.ok(encounter.swap_player_positions(first, second), "yer değiştirme kabul edilir")
	t.eq(first.position, second_position, "birinci arkaya geçer")
	t.eq(second.position, first_position, "ikinci öne geçer")
	t.eq(encounter.player_units[0].position, 1, "liste mevkiye göre yeniden sıralanır")
	t.not_ok(
		encounter.swap_player_positions(first, first),
		"aynı kişiyle yer değiştirilemez"
	)
