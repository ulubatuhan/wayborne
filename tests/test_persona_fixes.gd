extends RefCounted

## Oyuncu profili çalışmasının (bölüm 18) yedi önerisinin kilitleri.
## Her test bir ölçüme dayanıyor; gerekçeler
## `docs/design_notes/oyuncu_profilleri.md`.

func suite_name() -> String:
	return "Persona Fixes"

func run(t) -> void:
	_test_meal_modes_cost_different_amounts(t)
	_test_day_labour_pays_time_not_money(t)
	_test_day_labour_is_only_for_the_hungry(t)
	_test_seen_cards_are_counted(t)
	_test_last_decisions_are_remembered(t)
	_test_standing_milestone_is_written_once(t)

func _session_in_city(gold: int = 250) -> GameSession:
	var session := GameSession.new(gold, 20, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	return session

# --- Ö2: sofra kipinin bedeli görünür ---

func _test_meal_modes_cost_different_amounts(t) -> void:
	# Ablasyonun en sert bulgusu: tayfayı beslemek dayanıklılığı üç
	# seferden on bire değiştiriyor. Bu ağırlıkta bir kararın bedeli
	# ekranda yazılı olmalı - ve aritmetiği dağıtımla aynı yerden gelmeli.
	var session := _session_in_city()
	var all_mode := session.daily_provisions_for_mode(GameSession.MEAL_MODE_ALL)
	var party := session.daily_provisions_for_mode(GameSession.MEAL_MODE_PARTY_ONLY)
	var crew := session.daily_provisions_for_mode(GameSession.MEAL_MODE_CREW_ONLY)
	t.eq(all_mode, session.get_daily_provision_consumption(), "herkes kipi günlük tüketimin tamamı")
	t.eq(party + crew, all_mode, "parti ve tayfa payları tamamı eder")
	t.ok(party < all_mode, "yalnız partiyi beslemek daha ucuz")
	t.ge(float(session.daily_provisions_for_mode(GameSession.MEAL_MODE_SELF_ONLY)), 0.0,
		"lider kipi de bir sayı döndürür")

# --- Ö3: gündelik iş ---

func _test_day_labour_pays_time_not_money(t) -> void:
	var session := _session_in_city()
	session.change_provisions(-session.get_provisions())
	var purse := session.wallet.balance
	var day := session.total_days_elapsed
	t.ok(session.can_work_a_day(), "aç kervan bir gün çalışabilir")
	var earned := session.work_a_day()
	t.ok(earned > 0, "çalışmak erzak kazandırır")
	t.eq(session.wallet.balance, purse, "ama tek kuruş para vermez")
	t.eq(session.total_days_elapsed, day + 1, "bir gün geçer: ödenen zamandır")
	# Zenginleşmeye yol yok: kazanç bir günlük tüketimin biraz üstü.
	t.le(
		float(earned),
		float(session.get_daily_provision_consumption()) * GameSession.DAY_LABOUR_PROVISION_FACTOR + 1.0,
		"kazanç bir günlük ekmeğin biraz üstünde kalır"
	)

func _test_day_labour_is_only_for_the_hungry(t) -> void:
	# İhtiyacı **sefer** belirler, bugünkü depo değil: 20 erzakla duran bir
	# kervan 111 erzaklık yola bakarken düğme gizleniyordu - tam gerektiği
	# anda. Ekran görüntüsü yakaladı.
	var fed := _session_in_city()
	fed.change_provisions(fed.get_daily_provision_consumption() * 5)
	t.not_ok(fed.should_offer_day_labour(0), "eksiği olmayan kervana sunulmaz")
	t.ok(fed.should_offer_day_labour(40), "ama uzun yolda eksiği varsa sunulur")
	var on_road := _session_in_city()
	on_road.change_provisions(-on_road.get_provisions())
	var plan := CaravanPlan.new(WorldMapData.get_locations()[0], 5, 6, 1)
	on_road.start_journey(WorldMapData.get_locations()[0].location_id, 5, 0.1, plan)
	t.not_ok(on_road.can_work_a_day(), "yolda gündelik iş yok")
	t.not_ok(on_road.should_offer_day_labour(40), "yolda eksik de olsa sunulmaz")
	t.eq(on_road.get_day_labour_block_reason(), "UI_LABOUR_ON_ROAD", "sebebi söylenir")

# --- Ö4, Ö5: sayılabilirlik ve ölümün nedeni ---

func _test_seen_cards_are_counted(t) -> void:
	var session := _session_in_city()
	t.eq(session.get_seen_event_count(), 0, "yeni kervan hiç kart görmemiştir")
	session.note_event_seen("evt_a")
	session.note_event_seen("evt_b")
	session.note_event_seen("evt_a")
	t.eq(session.get_seen_event_count(), 2, "aynı kart iki kez sayılmaz")
	session.note_event_seen("")
	t.eq(session.get_seen_event_count(), 2, "boş kimlik sayılmaz")
	# Kayıttan döner: sayaç soy boyunca birikiyor.
	var restored := GameSession.new(0, 0, 1)
	restored.load_from_dict(session.to_save_dict())
	t.eq(restored.get_seen_event_count(), 2, "sayaç kayıttan döner")

func _test_last_decisions_are_remembered(t) -> void:
	var session := _session_in_city()
	for index in 5:
		session.note_decision("evt_%d" % index, "CHOICE_%d" % index)
	t.eq(
		session.recent_decisions.size(), GameSession.RECENT_DECISION_COUNT,
		"yalnız son üç karar tutulur"
	)
	t.eq(
		String((session.recent_decisions[2] as Dictionary).get("choice", "")), "CHOICE_4",
		"en yenisi sonda"
	)
	var restored := GameSession.new(0, 0, 1)
	restored.load_from_dict(session.to_save_dict())
	t.eq(restored.recent_decisions.size(), GameSession.RECENT_DECISION_COUNT,
		"son kararlar kayıttan döner")

# --- Ö7: ad ile ödül ---

func _test_standing_milestone_is_written_once(t) -> void:
	# Tüccar profili emeğinin karşılığını göremiyordu: kese yatay
	# (P8'in kasıtlı sonucu). Verilen şey para değil tanınma.
	var session := _session_in_city()
	var before := _milestone_lines(session)
	session.change_reputation(GameSession.STANDING_MILESTONES[0] + 2)
	var after := _milestone_lines(session)
	t.ok(after > before, "eşik geçilince deftere satır düşer")
	# Bir daha düşmez: aynı eşik her itibar hareketinde tekrar yazılmaz.
	session.change_reputation(1)
	t.eq(_milestone_lines(session), after, "aynı eşik ikinci kez yazılmaz")
	# Kese bu işte hiç değişmiyor - kâr tavanı korunuyor.
	var purse := session.wallet.balance
	session.change_reputation(GameSession.STANDING_MILESTONES[1])
	t.eq(session.wallet.balance, purse, "tanınma para getirmez")
	t.ok(_milestone_lines(session) > after, "sonraki eşik de yazılır")

func _milestone_lines(session: GameSession) -> int:
	var count := 0
	for entry in session.ledger.entries:
		if String(entry.get("cause", "")) == "LEDGER_CAUSE_STANDING_MILESTONE":
			count += 1
	return count
