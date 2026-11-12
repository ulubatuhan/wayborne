extends RefCounted

## Y-C13 + N32 / T16-09: adı olan, hatırlayan kişiler ve yolun reisi.

func suite_name() -> String:
	return "People"

func run(t) -> void:
	_test_city_people(t)
	_test_chain(t)
	_test_aging_and_death(t)
	_test_regard_opens_doors(t)
	_test_chief(t)
	_test_save(t)

func _session(place: String = "liraven") -> GameSession:
	var session := GameSession.new(800, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	session.current_location_id = place
	session.people.ensure_city(place, session.total_days_elapsed)
	return session

func _test_city_people(t) -> void:
	var a := _session()
	var b := _session()
	var people := a.people.city_people("liraven")
	t.eq(people.size(), 3, "her şehirde üç kalıcı kişi")
	for i in people.size():
		t.eq(String(people[i]["name"]), String(b.people.city_people("liraven")[i]["name"]), "kişiler tohumdan, yüklemeyle değişmez")
		var age := People.age_years(people[i], a.total_days_elapsed)
		t.ok(age >= People.MIN_AGE and age <= People.MAX_AGE + 1, "yaş makul")
	a.people.greet_city("liraven", 5)
	a.people.greet_city("liraven", 5)
	t.eq(int(a.people.city_people("liraven")[0]["met"]), 1, "aynı gün bir kez görür")

func _test_chain(t) -> void:
	var session := _session()
	var id := "liraven_" + People.ROLE_GUILD
	var chain := session.people.offer_chain(id, session.total_days_elapsed)
	t.ok(not chain.is_empty(), "iş verilir")
	t.ok(WorldMapData.get_location_by_id("liraven").demands.has(String(chain["item"])), "şehrin istediği mal")
	# IP-009: istek bir yön söyler (şehir adı değil), yoksa oyuncu nerede
	# arayacağını bilemiyordu - ölçümde hiçbir zincir tamamlanmamıştı.
	var hint := session.people.chain_hint(id)
	t.ok(hint in ["UI_DIR_NORTH", "UI_DIR_SOUTH", "UI_DIR_EAST", "UI_DIR_WEST", ""], "ipucu bir yön ya da boş")
	t.eq(session.people.chain_hint("yok_boyle_biri"), "", "olmayan kişi ipucu vermez")
	t.not_ok(session.can_deliver_chain(id), "mal yokken teslim edilemez")
	session.add_to_cargo(ItemCatalog.get_item(String(chain["item"])), int(chain["qty"]))
	var gold := session.wallet.balance
	var rep := session.reputation
	t.ok(session.deliver_chain(id), "teslim edilir")
	t.eq(session.wallet.balance, gold + int(chain["gold"]), "ödül keseye")
	t.ok(session.reputation > rep, "bölgede ad")
	t.eq(int(session.people.person(id)["chain_step"]), 1, "zincir ilerler")
	t.eq(People.regard(session.people.person(id)), 1, "gönlü iyileşir")
	var next := session.people.offer_chain(id, session.total_days_elapsed)
	t.ok(int(next["qty"]) > int(chain["qty"]), "sonraki iş büyür")
	for _day in People.CHAIN_DAYS + 2:
		session.advance_day()
	t.ok(int(session.people.person(id)["grudge"]) >= 1, "tutulmayan söz kin bırakır")
	t.ok(String(session.journal[-1]["text"]).length() > 0, "deftere yazılır")

func _test_aging_and_death(t) -> void:
	var session := _session()
	var id := "liraven_" + People.ROLE_LENDER
	session.people.persons[id]["born"] = session.total_days_elapsed - 85 * Scarcity.YEAR_DAYS
	var died := false
	for _day in 900:
		session.advance_day()
		if not bool(session.people.person(id)["alive"]):
			died = true
			break
	t.ok(died, "çok yaşlı biri bir gün ölür")

func _test_regard_opens_doors(t) -> void:
	var session := _session()
	var lodging := session.get_lodging_cost()
	var fee := session.get_loan_fee_percent()
	session.people.persons["liraven_" + People.ROLE_INNKEEPER]["favor"] = 3
	session.people.persons["liraven_" + People.ROLE_LENDER]["favor"] = 2
	t.ok(session.get_lodging_cost() < lodging, "taverna sahibi dostuna ucuz oda verir")
	t.ok(session.get_loan_fee_percent() < fee, "tefeci dostuna ucuz kredi verir")
	session.people.persons["liraven_" + People.ROLE_INNKEEPER]["favor"] = 0
	session.people.persons["liraven_" + People.ROLE_INNKEEPER]["grudge"] = 2
	t.ok(session.get_lodging_cost() > lodging, "küs taverna sahibi pahalı")

func _test_chief(t) -> void:
	var people := People.new()
	var id := people.chief_escaped("vadi", 10, ["valley"] as Array[String])
	t.eq(people.chief_in("vadi"), id, "kaçan reis bölgesinde kayıtlı")
	t.eq(int(people.person(id)["rank"]), 1, "çetesi büyür")
	t.eq(people.chief_escaped("vadi", 30, ["valley"] as Array[String]), id, "ikinci kaçış aynı reis")
	t.eq(int(people.person(id)["grudge"]), 2, "kini artar")
	people.active_chief = id
	var text := people.fill_names("{nemesis}: {scar}")
	t.ok(not text.contains("{"), "kart metni adla dolar")
	t.ok(text.begins_with(String(people.person(id)["name"])), "ad yerinde")
	people.chief_killed(id, 40)
	t.eq(people.chief_in("vadi"), "", "ölen reis yolu tutmaz")
	var event := EventCatalog.get_event("evt_chief_returns")
	t.ok(event != null, "reis kartı katalogda")
	var session := _session()
	t.eq(float(session.build_event_context().get("chief_here", 0.0)), 0.0, "reis yokken kart çıkmaz")
	session.people.chief_escaped(session.current_region(), 1, ["valley"] as Array[String])
	t.eq(float(session.build_event_context().get("chief_here", 0.0)), 1.0, "kinli reis varken kart çıkabilir")

func _test_save(t) -> void:
	var session := _session()
	session.people.offer_chain("liraven_" + People.ROLE_GUILD, 0)
	session.people.chief_escaped("vadi", 3, ["valley"] as Array[String])
	var copy := GameSession.new(0, 0, 1)
	copy.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	t.eq(copy.people.persons.size(), session.people.persons.size(), "kişiler kayıtta")
	t.eq(int(copy.people.person("liraven_" + People.ROLE_GUILD)["chain"]["qty"]), int(session.people.person("liraven_" + People.ROLE_GUILD)["chain"]["qty"]), "iş kayıtta")
	t.ok(not copy.people.chief_in("vadi").is_empty(), "reis kayıtta")
