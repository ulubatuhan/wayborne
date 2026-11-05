extends RefCounted

## Y-C12 / T16-07: bölgesel itibar, jeopolitik yayılma ve hizipler.

func suite_name() -> String:
	return "Standing"

func run(t) -> void:
	_test_spill(t)
	_test_session_reputation_is_regional(t)
	_test_save_and_legacy(t)
	_test_factions_open_and_close_doors(t)

func _test_spill(t) -> void:
	var s := Standing.new()
	s.reset()
	s.change_region("vadi", 5.0)
	t.eq(s.region("vadi"), 5, "kazanılan bölgede tam")
	# Kullanıcı: "bir yerde 5 itibar kazanıyorsam diğer tarafta bu 0.5 olabilir".
	t.almost(float(s.regions["imparatorluk"]), 5.0 * Standing.spill("vadi", "imparatorluk"), "komşuya ağırlıkla yayılır")
	t.ok(Standing.spill("vadi", "imparatorluk") > 0.0 and Standing.spill("vadi", "imparatorluk") < 0.3, "komşu payı küçük")
	t.ok(float(s.regions["ahit"]) < 0.0, "Avuçiçi kâfir şehirlerde sevileni sevmez")
	var hostile := Standing.new()
	hostile.reset()
	hostile.change_region("gocebe", 10.0)
	t.ok(float(hostile.regions["imparatorluk"]) < 0.0, "göçebede ad yapan Vaelghard'da kaybeder")
	t.ok(float(hostile.regions["dag_maden"]) > float(hostile.regions["guney"]), "dost bölgeye uzak bölgeden çok yayılır")
	for id in Standing.region_ids():
		t.ok(absf(Standing.spill("vadi", String(id))) <= 1.0, "pay 1'i aşmaz")

func _session(place: String) -> GameSession:
	var session := GameSession.new(500, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	session.current_location_id = place
	return session

func _test_session_reputation_is_regional(t) -> void:
	var session := _session("liraven")
	session.change_reputation(10)
	t.eq(session.reputation, 10, "Vadi'de kazanılan Vadi'de görünür")
	session.current_location_id = "vastrevar"
	t.ok(session.reputation < 10, "Vaelghard'da aynı ad daha sönük")
	session.current_location_id = "liraven"
	session.reputation = 3
	t.eq(session.reputation, 3, "doğrudan yazım o bölgeye")
	session.change_reputation(-100)
	t.eq(session.reputation, int(Standing.MIN_VALUE), "dip korunur")

func _test_save_and_legacy(t) -> void:
	var session := _session("liraven")
	session.change_reputation(8)
	session.change_faction_standing(Standing.GUILD, 4)
	var copy := GameSession.new(0, 0, 1)
	copy.load_from_dict(session.to_save_dict())
	copy.current_location_id = "liraven"
	t.eq(copy.reputation, 8, "bölge itibarı kayıtta")
	t.eq(copy.standing.faction(Standing.GUILD), 4, "hizip kayıtta")
	var data := session.to_save_dict()
	data.erase("standing")
	data["reputation"] = 6
	var legacy := GameSession.new(0, 0, 1)
	legacy.load_from_dict(data)
	for id in Standing.region_ids():
		t.eq(legacy.standing.region(String(id)), 6, "eski kayıt: her bölge eski itibarla açılır")

func _test_factions_open_and_close_doors(t) -> void:
	var session := _session("liraven")
	var route := WorldMapData.get_routes_from("liraven")[0]
	var calm := session.get_route_danger(route)
	session.change_faction_standing(Standing.BROTHERHOOD, 15)
	t.ok(session.get_route_danger(route) < calm, "kardeşlikle arası iyi olana yol daha az tehlikeli")
	var parts := session.get_route_danger_breakdown(route)
	t.almost(float(parts[-1]["value"]), session.get_route_danger(route), "döküm son değeri tehlikeyle aynı")
	session.change_faction_standing(Standing.BROTHERHOOD, -40)
	t.ok(session.get_route_danger(route) > calm, "kılıç çekene yol daha tehlikeli")
	var fee := session.doctor_fee("deep_cut")
	session.change_faction_standing(Standing.CHURCH, 20)
	t.ok(session.doctor_fee("deep_cut") < fee or fee <= 1, "kiliseyle arası iyi olana hekim ucuz")
	session.reputation = GameSession.LOAN_MIN_REPUTATION - 1
	t.ne(session.get_advance_block_reason(), "", "itibarsız kervana avans yok")
	session.change_faction_standing(Standing.GUILD, 10)
	t.eq(session.get_advance_block_reason() == "UI_GUILD_LOAN_NO_TRUST", false, "loncanın defteri avansı açar")
	var gold := session.wallet.balance
	t.ok(session.donate_to_church(), "bağış yapılır")
	t.eq(session.wallet.balance, gold - GameSession.CHURCH_DONATION, "bağış keseden")
