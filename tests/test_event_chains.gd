extends RefCounted

## Uzun zincirler (Y-E02): bir kararın karşılığı başka bir şehre giden yolda ya
## da varisin döneminde açılır; zincirin aşaması kayıtta ve bağlamda.

func suite_name() -> String:
	return "EventChains"

func run(t) -> void:
	_test_effect_advances(t)
	_test_other_city(t)
	_test_named_city(t)
	_test_heir(t)
	_test_save(t)

func _journey(session: GameSession, destination_id: String) -> void:
	var destination := WorldMapData.get_location_by_id(destination_id)
	var days := maxi(1, WorldMapData.get_route(session.current_location_id, destination_id).travel_days)
	session.start_journey(destination_id, days, 0.3, CaravanPlan.new(destination, days))

func _neighbours(from_id: String) -> Array[String]:
	var out: Array[String] = []
	for route in WorldMapData.get_routes_from(from_id):
		out.append(route.to_location_id)
	return out

func _test_effect_advances(t) -> void:
	var session := GameSession.new(200, 20, 1)
	var effects: Array[EventEffect] = [EventEffect.make(EventEffect.Type.CHAIN_ADVANCE, 3, "debt_of_honour|1|other_city")]
	EventEffectApplier.apply(effects, session)
	t.eq(session.get_chain_stage("debt_of_honour"), 1, "etki zinciri ilk aşamaya taşır")
	t.eq(int(session.build_event_context()["chain_debt_of_honour"]), 1, "aşama bağlamda")
	t.eq(int(session.build_event_context()["chain_debt_of_honour_ripe"]), 0, "gün gelmeden karşılık açılmaz")

func _test_other_city(t) -> void:
	var session := GameSession.new(200, 20, 1)
	var home := session.current_location_id
	session.advance_chain("c", 1, "other_city", 0)
	t.not_ok(session.is_chain_ripe("c"), "şehirde beklerken karşılık yok")
	var next := _neighbours(home)
	if next.is_empty():
		t.ok(false, "başlangıç şehrinin komşusu yok")
		return
	_journey(session, next[0])
	t.ok(session.is_chain_ripe("c"), "başka bir şehre giden yolda karşılık açılır")

func _test_named_city(t) -> void:
	var session := GameSession.new(200, 20, 1)
	var next := _neighbours(session.current_location_id)
	if next.size() < 1:
		return
	session.advance_chain("c", 2, "city:" + next[0], 0)
	_journey(session, next[0])
	t.ok(session.is_chain_ripe("c"), "adı verilen şehre giden yolda açılır")
	t.eq(int(session.build_event_context()["chain_c_ripe"]), 2, "olgun aşama bağlamda")

func _test_heir(t) -> void:
	var session := GameSession.new(200, 20, 1)
	session.advance_chain("oath", 1, "heir", 0)
	t.not_ok(session.is_chain_ripe("oath"), "aynı kuşakta karşılık gelmez")
	session.lineage_generation += 1
	t.ok(session.is_chain_ripe("oath"), "varisin döneminde gelir")
	session.advance_chain("oath", GameSession.CHAIN_DONE)
	t.not_ok(session.is_chain_ripe("oath"), "kapanan zincir bir daha açılmaz")

func _test_save(t) -> void:
	var session := GameSession.new(200, 20, 1)
	session.advance_chain("oath", 2, "heir", 5)
	var reloaded := GameSession.new(0, 0, 1)
	reloaded.load_from_dict(session.to_save_dict())
	t.eq(reloaded.get_chain_stage("oath"), 2, "zincir kayıtta")
	t.eq(int((reloaded.event_chains["oath"] as Dictionary)["after_day"]), 5, "zincirin günü kayıtta")
