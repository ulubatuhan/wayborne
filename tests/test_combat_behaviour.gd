extends RefCounted

## Savaşta davranış (görevler Y-C08, Y-D06, Y-C07): düşmanın huyu hedefini
## seçer, kırılan kişi kipine göre davranır, zorda kalan kervan bedelli
## geri çekilir (ayıya karşı bedelsiz).

func suite_name() -> String:
	return "CombatBehaviour"

func run(t) -> void:
	_test_enemy_temperaments(t)
	_test_break_modes(t)
	_test_retreat(t)

func _unit(name: String, hp: int, max_hp: int, position: int, player: bool) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.display_name = name
	unit.max_hp = max_hp
	unit.current_hp = hp
	unit.position = position
	unit.is_player_side = player
	return unit

func _test_enemy_temperaments(t) -> void:
	t.eq(CombatUnit.behavior_for(EnemyCatalog.LEADER), "leader_hunter", "eşkıya reisi lideri avlar")
	t.eq(CombatUnit.behavior_for(EnemyCatalog.WOLF), "pack", "kurt sürü huylu")
	t.eq(CombatUnit.behavior_for(EnemyCatalog.CITY_GUARD), "guard", "muhafız teslim alır")
	t.eq(CombatUnit.behavior_for(EnemyCatalog.BEAR), "beast", "ayı kaçanı kovalamaz")
	var leader := _unit("Lider", 30, 30, 2, true)
	leader.is_leader = true
	var weak := _unit("Yaralı", 5, 30, 1, true)
	var targets: Array[CombatUnit] = [weak, leader]
	var hunter := _unit("Reis", 20, 20, 1, false)
	hunter.behavior = "leader_hunter"
	t.eq(CombatEncounter.pick_target(hunter, targets), leader, "reis canı tam olsa da lideri seçer")
	var plain := _unit("Kesici", 20, 20, 1, false)
	t.eq(CombatEncounter.pick_target(plain, targets), weak, "huysuz düşman en zayıfa gider")
	var big := _unit("İri", 9, 40, 1, true)
	var small := _unit("Ufak", 6, 8, 2, true)
	var wolf := _unit("Kurt", 12, 12, 1, false)
	wolf.behavior = "pack"
	var pack_targets: Array[CombatUnit] = [small, big]
	t.eq(CombatEncounter.pick_target(wolf, pack_targets), big, "kurt canı oranca en azı kovalar")
	var door := _unit("Kıyıda", 0, 30, 1, true)
	door.on_deaths_door = true
	var standing := _unit("Ayakta", 25, 30, 2, true)
	var guard := _unit("Muhafız", 20, 20, 1, false)
	guard.behavior = "guard"
	var guard_targets: Array[CombatUnit] = [door, standing]
	t.eq(CombatEncounter.pick_target(guard, guard_targets), standing, "muhafız Kıyı'dakini bitirmez")
	standing.taunt_rounds = 1
	var taunt_targets: Array[CombatUnit] = [weak, leader, standing]
	t.eq(CombatEncounter.pick_target(hunter, taunt_targets), standing, "kışkırtan her düşmanın hedefi")

func _with_trait(trait_id: String) -> CharacterData:
	var c := CharacterData.create("Kırık", CultureCatalog.VALLEY, CharacterStats.new())
	c.trait_ids.append(trait_id)
	return c

func _test_break_modes(t) -> void:
	t.eq(_with_trait(TraitCatalog.WEAK_ARM).get_break_mode(), CharacterData.BREAK_RECKLESS, "zayıf kol öne atılır")
	t.eq(_with_trait(TraitCatalog.FRAIL_CONSTITUTION).get_break_mode(), CharacterData.BREAK_MARTYR, "çelimsiz darbeyi üstüne çeker")
	t.eq(_with_trait(TraitCatalog.OFF_PUTTING).get_break_mode(), CharacterData.BREAK_LASHES_OUT, "itici arkadaşına saldırır")
	t.eq(_with_trait(TraitCatalog.DULL_WIT).get_break_mode(), CharacterData.BREAK_DEFIANT, "kalın kafa emre uymaz")
	t.eq(CharacterData.create("Sağlam", CultureCatalog.VALLEY, CharacterStats.new()).get_break_mode(), CharacterData.BREAK_DEFIANT, "kötü huyu yoksa emre uymaz")
	# Kendi başına davranış: zar her seferinde tutsun diye ret tavanda.
	var rash := _unit("Atak", 20, 20, 3, true)
	rash.is_stressed = true
	rash.refusal_bonus = 200
	rash.break_mode = CharacterData.BREAK_RECKLESS
	var front := _unit("Ön", 20, 20, 1, true)
	var mid := _unit("Orta", 20, 20, 2, true)
	var foe := _unit("Düşman", 20, 20, 1, false)
	var party: Array[CombatUnit] = [front, mid, rash]
	var foes: Array[CombatUnit] = [foe]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var encounter := CombatEncounter.new(party, foes, rng)
	t.ok(_act(encounter, rash), "kırılan kendi başına davranır")
	t.eq(rash.position, 1, "öne atılan en öne geçer")
	rash.break_mode = CharacterData.BREAK_LASHES_OUT
	var before := front.current_hp + mid.current_hp
	_act(encounter, rash)
	t.ok(front.current_hp + mid.current_hp < before, "arkadaşına saldırır")
	t.ok(front.current_hp >= 1 and mid.current_hp >= 1, "arkadaşını öldürmez")
	rash.break_mode = CharacterData.BREAK_MARTYR
	_act(encounter, rash)
	t.ok(rash.taunt_rounds > 0, "şehit darbeleri üstüne çeker")

## Ret zarı tavanda %95: tutana kadar dene (deterministik tohum, sınırlı).
func _act(encounter: CombatEncounter, unit: CombatUnit) -> bool:
	for i in 40:
		if encounter._try_refuse_order(unit):
			return true
	return false

func _test_retreat(t) -> void:
	var a := _unit("A", 20, 20, 1, true)
	var b := _unit("B", 20, 20, 2, true)
	var foe := _unit("Eşkıya", 20, 20, 1, false)
	var party: Array[CombatUnit] = [a, b]
	var foes: Array[CombatUnit] = [foe]
	var encounter := CombatEncounter.new(party, foes, RandomNumberGenerator.new())
	t.not_ok(encounter.can_retreat(), "taze kadro kaçamaz")
	a.current_hp = 4
	b.current_hp = 6
	t.ok(encounter.can_retreat(), "kadronun canı yarının altında: kaçış açık")
	t.not_ok(encounter.retreat_is_free(), "eşkıya kovalar")
	var bear := _unit("Ayı", 40, 40, 1, false)
	bear.behavior = "beast"
	var bear_foes: Array[CombatUnit] = [bear]
	var bear_fight := CombatEncounter.new(party, bear_foes, RandomNumberGenerator.new())
	t.ok(bear_fight.retreat_is_free(), "ayıdan kaçmak bedava")
