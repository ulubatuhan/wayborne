extends RefCounted

## Kalıcı emirler: aynı karar her gün yeniden sorulmuyor, ama bir emir
## kimseyi oyuncunun haberi olmadan öldürmüyor (bkz. GameSession'daki
## "Kalıcı emirler" notu).

func suite_name() -> String:
	return "StandingOrders"

func run(t) -> void:
	_test_meal_policy_asks_only_when_it_matters(t)
	_test_policy_asks_before_starvation_bites(t)
	_test_combat_roster_is_remembered(t)
	_test_orders_survive_a_reload(t)
	_test_feast_evening_extras(t)

func _session() -> GameSession:
	var session := GameSession.new(500, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	session.start_playthrough(
		CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng
	)
	return session

func _companion(session: GameSession) -> CharacterData:
	for character in session.get_party():
		if not character.is_player:
			return character
	return null

func _test_meal_policy_asks_only_when_it_matters(t) -> void:
	var session := _session()
	session.change_provisions(500)
	t.eq(session.meal_policy_mode, GameSession.MEAL_MODE_ALL, "varsayılan emir: herkes yer")
	t.not_ok(session.meal_needs_decision(), "erzak bolken sofra sorulmaz")

	session.change_provisions(-session.get_provisions())
	t.ok(session.meal_needs_decision(), "erzak yetmeyince sofra yeniden açılır")

func _test_policy_asks_before_starvation_bites(t) -> void:
	var session := _session()
	session.change_provisions(500)
	session.set_meal_policy(GameSession.MEAL_MODE_SELF_ONLY)
	var companion := _companion(session)
	var asked_before_damage := false
	for _night in 10:
		if session.meal_needs_decision():
			asked_before_damage = companion.current_hp == companion.get_max_hp()
			break
		session.apply_meal_distribution(session.meal_policy_mode, session.get_meal_policy_selected())
	t.ok(asked_before_damage, "emir biri açlıktan can kaybetmeden önce sofrayı açar")
	t.ok(
		companion.consecutive_hungry_days + 1 >= GameSession.STARVATION_HP_LOSS_START_DAY,
		"soru tam eşikte geliyor, daha erken değil"
	)

	# Belirli kişiler kipi kimlikle hatırlanıyor.
	var crew_policy := _session()
	crew_policy.set_meal_policy(GameSession.MEAL_MODE_SPECIFIC, [_companion(crew_policy)] as Array[CharacterData])
	var selected := crew_policy.get_meal_policy_selected()
	t.eq(selected.size(), 1, "seçili kişi hatırlanıyor")
	t.ok(selected.has(_companion(crew_policy)), "seçilen doğru kişi")

func _test_combat_roster_is_remembered(t) -> void:
	var session := _session()
	var leader := session.get_player_character()
	var companion := _companion(session)
	t.eq(session.get_remembered_combat_order().size(), session.get_party().size(), "hatıra yokken bütün parti")
	t.ok(session.is_in_remembered_roster(companion), "hatıra yokken herkes dahil")

	session.remember_combat_roster([companion] as Array[CharacterData])
	var order := session.get_remembered_combat_order()
	t.eq(order[0], companion, "son kadro sırasıyla başa geliyor")
	t.ok(order.has(leader), "dışarıda kalan da listede - kutusu boş")
	t.not_ok(session.is_in_remembered_roster(leader), "dışarıda tutulan dışarıda hatırlanıyor")

func _test_orders_survive_a_reload(t) -> void:
	var session := _session()
	var companion := _companion(session)
	session.set_meal_policy(GameSession.MEAL_MODE_SPECIFIC, [companion] as Array[CharacterData])
	session.standing_camp_at_dusk = true
	session.remember_combat_roster([companion] as Array[CharacterData])
	var fresh := GameSession.new(0, 0)
	fresh.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	t.eq(fresh.meal_policy_mode, GameSession.MEAL_MODE_SPECIFIC, "sofra emri kayıttan döner")
	t.eq(fresh.get_meal_policy_selected().size(), 1, "seçili kişi kayıttan döner")
	t.ok(fresh.standing_camp_at_dusk, "akşam kampı emri kayıttan döner")
	t.eq(fresh.combat_roster_ids.size(), 1, "savaş kadrosu kayıttan döner")

## Sofranın çeşnisi (görev Y-B07): şarap, bal, balık sofraya çıkar ve etkisini
## verir; bolluk varken haftada bir ziyafet akşamı sofrayı açar; çeşni yoksa
## kalıcı emir sessiz kalır.
func _test_feast_evening_extras(t) -> void:
	var session := _session()
	session.add_to_cargo(ItemCatalog.get_item(GameSession.PROVISIONS_ITEM_ID), 200)
	var destination := WorldMapData.get_routes_from(session.current_location_id)[0].to_location_id
	session.start_journey(destination, 10, 0.2, CaravanPlan.new(WorldMapData.get_location_by_id(destination), 10))
	session.total_days_elapsed = GameSession.FEAST_EVENING_INTERVAL + 1
	t.ok(session.get_meal_extras().is_empty(), "çeşni malı yokken liste boş")
	t.not_ok(session.meal_needs_decision(), "çeşnisiz bolluk akşamı sofra sorulmaz")
	session.add_to_cargo(ItemCatalog.get_item("wine"), 10)
	session.add_to_cargo(ItemCatalog.get_item("fish"), 10)
	t.eq(session.get_meal_extras().size(), 2, "şarap ve balık sofraya çıkabilir")
	t.ok(session.meal_needs_decision(), "haftada bir ziyafet akşamı sofrayı açar")
	var morale_before := session.caravan.morale
	session.caravan.change_morale(-30)
	var low := session.caravan.morale
	session.caravan.stamina = 50
	var units := int(ceil(float(session.get_meal_mouths()) / 4.0))
	var served := session.serve_meal_extras(["wine", "fish"])
	t.eq(served.size(), 2, "iki çeşni sofrada")
	t.eq(session.caravan.morale, mini(low + 6, morale_before), "şarap moral verir")
	t.eq(session.caravan.stamina, 62, "balık takat verir")
	t.eq(session.get_total_quantity("wine"), 10 - units, "şarap ağız sayısına göre eksilir")
	t.not_ok(session.is_feast_evening(), "ziyafetten sonra sayaç sıfırlanır")
	t.not_ok(session.meal_needs_decision(), "ertesi akşam sofra yeniden sorulmaz")
	var copy := GameSession.new(0, 0)
	copy.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	t.eq(copy.last_feast_evening_day, session.last_feast_evening_day, "ziyafet günü kayıttan döner")
