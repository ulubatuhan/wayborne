extends RefCounted

## Yol kesenler ve dövüş garantisi (kullanıcı kararı 2026-11-07).

func suite_name() -> String:
	return "RoadRaiders"

func run(t) -> void:
	_test_guarantee_regions(t)
	_test_debt_ramp_and_force(t)
	_test_forced_draw_picks_a_fighting_card(t)
	_test_deserters_region_rule(t)
	_test_cards_exist_and_offer_three_roads(t)
	_test_plunder_takes_all_but_spares_provisions(t)
	_test_decoy_hands_over_the_cheapest(t)
	_test_ambush_puts_enemies_first(t)

func _session(origin: String = "liraven") -> GameSession:
	var session := GameSession.new(500, 40, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	session.current_location_id = origin
	return session

func _travel(session: GameSession, destination: String, days: int = 4) -> void:
	var place := WorldMapData.get_location_by_id(destination)
	session.start_journey(destination, days, 0.4, CaravanPlan.new(place, days))

## Garanti kutsal bölgede ve bozkırda işlemez; krallığın kendi şehirleri
## arasında da işlemez ama krallıktan sınıra çıkan yolda işler.
func _test_guarantee_regions(t) -> void:
	var holy := _session()
	_travel(holy, "orvahel")
	t.not_ok(holy.combat_guarantee_applies(), "Avuçiçi yolunda dövüş garantisi yok")

	var steppe := _session()
	_travel(steppe, "serai_orbeyan")
	t.not_ok(steppe.combat_guarantee_applies(), "Gokyurt yolunda dövüş garantisi yok")

	var inner := _session("vastrevar")
	_travel(inner, "dravoss")
	t.not_ok(inner.combat_guarantee_applies(), "krallığın iki şehri arasında garanti yok")

	var outward := _session("vastrevar")
	_travel(outward, "tolvarin")
	t.ok(outward.combat_guarantee_applies(), "krallıktan sınıra çıkan yolda garanti var")

	var ordinary := _session()
	_travel(ordinary, "ondrelle")
	t.ok(ordinary.combat_guarantee_applies(), "sıradan yolda garanti var")
	t.ok(ordinary.journey_needs_combat(), "henüz dövüşülmedi, borç duruyor")
	ordinary.note_combat_triggered()
	t.not_ok(ordinary.journey_needs_combat(), "bir dövüş borcu kapatır")

## Rampa son üç günde dövüş kartlarını öne çeker, son günde zorunlu olur.
func _test_debt_ramp_and_force(t) -> void:
	var director := RoadDirector.new()
	var fighter := EventCatalog.get_event("evt_bandit_ambush")
	var quiet := EventCatalog.get_event("evt_forgotten_cache")
	t.ok(fighter != null and quiet != null, "kartlar bulundu")
	t.ok(RoadDirector.can_fight(fighter), "pusu kartı dövüşe açılır")
	t.not_ok(RoadDirector.can_fight(quiet), "zula kartı dövüşe açılmaz")

	var early := {"combat_due": 1.0, "days_left": 9.0}
	t.almost(director.combat_debt_multiplier(fighter, early), 1.0, "yolun başında rampa yok")
	var late := {"combat_due": 1.0, "days_left": 2.0}
	t.almost(director.combat_debt_multiplier(fighter, late), RoadDirector.COMBAT_DUE_WEIGHT,
		"son günlerde dövüş kartı ağırlaşır")
	t.almost(director.combat_debt_multiplier(quiet, late), RoadDirector.COMBAT_DUE_OTHER_WEIGHT,
		"son günlerde öbürleri kısılır")
	t.ok(director.combat_debt_multiplier(quiet, late) > 0.0, "hiçbir kart havuzdan çıkmaz")
	var paid := {"combat_due": 0.0, "days_left": 1.0}
	t.almost(director.combat_debt_multiplier(fighter, paid), 1.0, "borç kapalıysa rampa yok")

	t.ok(EventEngine.combat_forced({"combat_due": 1.0, "days_left": 1.0}), "son gün zorunlu")
	t.not_ok(EventEngine.combat_forced({"combat_due": 1.0, "days_left": 2.0}), "iki gün kala değil")
	t.not_ok(EventEngine.combat_forced({"combat_due": 0.0, "days_left": 1.0}), "borç yoksa değil")

## Zorunlu günde havuz dövüş kartlarına iniyor ve gün kesin kart veriyor.
func _test_forced_draw_picks_a_fighting_card(t) -> void:
	var session := _session()
	_travel(session, "ondrelle", 1)
	var engine := EventEngine.new(EventCatalog.get_road_events(), 4242)
	engine.director = RoadDirector.new()
	var context := session.build_event_context()
	t.almost(engine.get_daily_chance(context), 1.0, "zorunlu günde kart kesin çıkar")
	var drawn := 0
	for attempt in 12:
		var event := engine.draw_event(session.total_days_elapsed, context)
		if event != null:
			drawn += 1
			t.ok(RoadDirector.can_fight(event), "zorunlu günde çekilen kart dövüşe açılır: %s" % event.event_id)
	t.ok(drawn > 0, "zorunlu günde kart çekilebildi")

func _test_deserters_region_rule(t) -> void:
	var steppe := _session()
	_travel(steppe, "serai_orbeyan")
	t.not_ok(steppe.deserters_on_this_road(), "bozkırda asker kaçağı yok")
	var inner := _session("vastrevar")
	_travel(inner, "dravoss")
	t.not_ok(inner.deserters_on_this_road(), "krallığın şehirleri arasında kaçak yok")
	var outward := _session("vastrevar")
	_travel(outward, "tolvarin")
	t.ok(outward.deserters_on_this_road(), "krallıktan çıkan yolda kaçak var")
	var holy := _session()
	_travel(holy, "orvahel")
	t.ok(holy.deserters_on_this_road(), "Avuçiçi yolunda kaçak var (garanti yok, kaçak var)")

## Üç kartın da üç yolu olmalı: ver, dövüş, blöf. Blöf zekâ zarı taşımalı
## ve tutmazsa pusuya düşmeli.
func _test_cards_exist_and_offer_three_roads(t) -> void:
	for event_id in ["evt_deserter_levy", "evt_cargo_toll", "evt_road_ultimatum"]:
		var event := EventCatalog.get_event(String(event_id))
		t.ok(event != null, "kart katalogda: %s" % event_id)
		if event == null:
			continue
		t.eq(event.choices.size(), 3, "%s üç yol sunar" % event_id)
		t.ok(RoadDirector.can_fight(event), "%s dövüşe açılabilir" % event_id)
		var bluff := event.choices[2]
		t.ok(bluff.check != null, "%s blöfü bir zar ister" % event_id)
		if bluff.check != null:
			t.eq(bluff.check.stat, CharacterStats.Kind.INTELLECT, "%s blöfü zekâya bakar" % event_id)
		t.ne(bluff.unavailable_text_key, "", "%s blöfü kilitliyken sebebini yazar" % event_id)
		var ambushes := false
		for outcome in bluff.outcomes:
			for effect in outcome.effects:
				if effect.type == EventEffect.Type.TRIGGER_AMBUSH:
					ambushes = true
		t.ok(ambushes, "%s blöfü tutmazsa pusu" % event_id)

func _test_plunder_takes_all_but_spares_provisions(t) -> void:
	var session := _session()
	for item_id in ["test_grain", "honey", "test_cloth"]:
		var item := ItemCatalog.get_item(String(item_id))
		if item != null:
			session.add_to_cargo_or_bag(item, 4)
	var before_provisions := session.get_provisions()
	var items_before := session.get_cargo_item_count()
	t.ge(items_before, 2, "yağmalanacak yük var")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	session.plunder_cargo(1.0, rng, false)
	t.eq(session.get_cargo_item_count(), 0, "hepsini isteyen hepsini alır")
	t.eq(session.get_provisions(), before_provisions, "erzağa dokunulmaz")

func _test_decoy_hands_over_the_cheapest(t) -> void:
	var session := _session()
	var cheap := ItemCatalog.get_item("test_grain")
	var dear := ItemCatalog.get_item("jewelry")
	if cheap == null or dear == null:
		return
	session.add_to_cargo_or_bag(cheap, 2)
	session.add_to_cargo_or_bag(dear, 2)
	var decoy := session.get_swindle_item()
	t.ok(decoy != null and decoy.base_price <= dear.base_price, "yem en ucuz kalem")
	EventEffectApplier.apply(
		[EventEffect.make(EventEffect.Type.CARGO_DECOY)] as Array[EventEffect], session
	)
	t.eq(session.get_total_quantity(dear.item_id), 2, "pahalı mal kalır")
	t.eq(session.get_total_quantity(cheap.item_id), 1, "ucuz maldan bir tane gider")

## Pusuda ilk round'u düşman açar; ikinci round normale döner.
func _test_ambush_puts_enemies_first(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var party: Array[CharacterData] = [
		CharacterData.create("Hızlı", CultureCatalog.NOMAD, CharacterStats.new()),
	]
	var units: Array[CombatUnit] = [CombatUnit.from_character(party[0], 1, false)]
	# Oyuncu kasten hızlı: pusu olmasaydı sıra onda olurdu.
	units[0].initiative = 99
	var enemies := EnemyCatalog.build_squad(EnemyCatalog.KIND_BANDIT, "vadi", 0.3, 1, rng, 1, "steppe")
	var encounter := CombatEncounter.new(units, enemies, rng, "Haydutlar")
	encounter.ambushed = true
	encounter.start()
	var order := encounter.turn_order()
	t.ok(not order.is_empty() and not order[0].is_player_side, "pusuda ilk hamle düşmanın")

	var fair_rng := RandomNumberGenerator.new()
	fair_rng.seed = 21
	var fair_units: Array[CombatUnit] = [CombatUnit.from_character(party[0], 1, false)]
	fair_units[0].initiative = 99
	var fair_enemies := EnemyCatalog.build_squad(EnemyCatalog.KIND_BANDIT, "vadi", 0.3, 1, fair_rng, 1, "steppe")
	var fair := CombatEncounter.new(fair_units, fair_enemies, fair_rng, "Haydutlar")
	fair.start()
	var fair_order := fair.turn_order()
	t.ok(not fair_order.is_empty() and fair_order[0].is_player_side,
		"pusu yoksa hızlı olan önce oynar")
