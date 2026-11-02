extends RefCounted

## T16-06 (kullanıcı, 2026-11-02; N34): tavernada gece kalmak ve oyun masası.

func suite_name() -> String:
	return "TavernLodging"

func run(t) -> void:
	_test_lodging(t)
	_test_scarcity_raises_the_room(t)
	_test_game_table_opens_and_closes(t)

func _session() -> GameSession:
	var session := GameSession.new(500, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	session.current_location_id = "liraven"
	return session

func _test_lodging(t) -> void:
	var session := _session()
	for character in session.party:
		character.change_fatigue(70)
		character.current_hp = maxi(1, character.get_max_hp() / 2)
	session.change_stress(30)
	var day := session.total_days_elapsed
	var gold := session.wallet.balance
	var cost := session.get_lodging_cost()
	var stress := session.party_stress
	t.ok(cost > 0 and session.can_afford_lodging(), "oda tutulabilmeli")
	session.lodge_night()
	t.eq(session.total_days_elapsed, day + 1, "bir gece bir gün")
	t.eq(session.wallet.balance, gold - cost, "oda parası ödenir")
	t.eq(session.party_stress, stress - GameSession.LODGING_STRESS_RELIEF, "stres biraz iner")
	for character in session.party:
		t.eq(character.fatigue, 0, "yatakta uyuyan dinlenir")
		t.ok(character.current_hp > character.get_max_hp() / 2, "yaralar biraz kapanır")
	var last: Dictionary = session.journal[-1]
	t.eq(String(last.get("place", "")), "liraven", "deftere o şehirde yazılır")
	session.wallet.spend(session.wallet.balance)
	t.not_ok(session.can_afford_lodging(), "parası olmayan oda tutamaz")
	var day_after := session.total_days_elapsed
	session.lodge_night()
	t.eq(session.total_days_elapsed, day_after, "parasızken gün geçmez")

func _test_scarcity_raises_the_room(t) -> void:
	var session := _session()
	var calm := session.get_lodging_cost()
	session.city_morale["liraven"] = 0.0
	t.ok(session.get_lodging_cost() >= calm, "kıtlık oda fiyatını düşürmez")

func _test_game_table_opens_and_closes(t) -> void:
	var game := TavernGame.new()
	var root := Control.new()
	root.add_child(game)
	game._ready()
	var closed := [false]
	game.closed.connect(func(): closed[0] = true)
	var leave := game.find_child("LeaveButton", true, false) as Button
	t.ok(leave != null, "masadan kalkma düğmesi olmalı")
	leave.pressed.emit()
	t.ok(closed[0], "masadan kalkınca ekran kapanır")
	root.free()
