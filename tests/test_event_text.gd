extends RefCounted

## U1 + U2 (uzman ölçümü 2026-11-07): çekilişin hafızası ve metinde ad anma.

func suite_name() -> String:
	return "EventText"

func run(t) -> void:
	_test_tokens_never_reach_the_screen(t)
	_test_person_is_the_one_who_rolled(t)
	_test_place_is_the_road_destination(t)
	_test_catalog_outcomes_name_someone(t)
	_test_novelty_favours_unseen(t)
	_test_recent_ring_is_bounded_and_saved(t)

func _session() -> GameSession:
	var session := GameSession.new(800, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	session.current_location_id = "liraven"
	return session

func _test_tokens_never_reach_the_screen(t) -> void:
	var session := _session()
	# Karşılığı olmayan işaretler cümleyi bozmadan silinir.
	var filled := EventText.fill("{nemesis} adamları {place} yolunu kesmiş.", session, null, "x")
	t.not_ok(filled.contains("{"), "çözülemeyen işaret ekrana çıkmaz")
	t.not_ok(filled.contains("  "), "işaretin yerinde çift boşluk kalmaz")
	t.ok(filled.begins_with("adamları"), "cümle baştan kırılmaz: %s" % filled)
	# Oturum yoksa (önizleme, araç) da aynı kural.
	t.not_ok(EventText.fill("{who} geldi.", null).contains("{"), "oturumsuz da temizlenir")

func _test_person_is_the_one_who_rolled(t) -> void:
	var session := _session()
	var check := SkillCheck.new()
	check.stat = CharacterStats.Kind.CHARISMA
	check.source = SkillCheck.Source.LEADER
	var leader := session.get_player_character()
	t.eq(EventText.fill("{who} konuştu.", session, check), "%s konuştu." % leader.character_name,
		"lider check'inde ad lideri gösterir")
	# Check yoksa ad tohumdan: aynı anahtar aynı kişiyi verir.
	var first := EventText.fill("{who}", session, null, "evt_x")
	t.eq(EventText.fill("{who}", session, null, "evt_x"), first, "aynı tohum aynı ad")

func _test_place_is_the_road_destination(t) -> void:
	var session := _session()
	var here := EventText.fill("{town} pazarı", session)
	t.ne(here, "", "şehirdeyken bulunulan yerin adı gelir")
	t.not_ok(here.contains("{"), "yer işareti çözülür")
	var routes := WorldMapData.get_routes_from("liraven")
	if routes.is_empty():
		return
	var destination := WorldMapData.get_location_by_id(routes[0].to_location_id)
	session.start_journey(routes[0].to_location_id, 4, 0.3, CaravanPlan.new(destination, 4))
	var on_road := EventText.fill("{town} yolunda", session)
	t.ok(on_road.ends_with("yolunda"), "yolda gidilen şehrin adı gelir: %s" % on_road)
	t.ne(on_road, "yolunda", "ad boş gelmez")

## U2'nin ölçüsü: katalogdaki sonuç metinleri bir kişi ya da yer anmalı.
## İki kart bilerek adsız (bkz. docs/design_notes/uzman_degerlendirme.md U2),
## o yüzden eşik %95.
func _test_catalog_outcomes_name_someone(t) -> void:
	var session := _session()
	var total := 0
	var named := 0
	var leaked: Array[String] = []
	for event in EventCatalog.get_road_events():
		for choice in event.choices:
			for outcome in choice.outcomes:
				total += 1
				var raw := tr(outcome.text_key)
				if raw.contains(EventText.WHO) or raw.contains(EventText.TOWN):
					named += 1
				var shown := EventText.fill(raw, session, choice.check, outcome.text_key)
				if shown.contains("{") and leaked.size() < 5:
					leaked.append(outcome.text_key)
	t.ok(total > 150, "katalogda sonuç var: %d" % total)
	t.eq(leaked.size(), 0, "hiçbir sonuç ekrana işaret sızdırmaz: %s" % str(leaked))
	t.ge(float(named) / float(maxi(1, total)), 0.95, "sonuçların neredeyse hepsi ad anar: %d/%d" % [named, total])

func _test_novelty_favours_unseen(t) -> void:
	var director := RoadDirector.new()
	var seen := {"evt_old": true, "evt_recent": true}
	var context := {"seen_cards": seen, "recent_cards": ["evt_recent"]}
	t.almost(director.novelty_multiplier("evt_new", context), RoadDirector.UNSEEN_CARD_WEIGHT,
		"hiç görülmemiş kart kayırılır")
	t.almost(director.novelty_multiplier("evt_old", context), RoadDirector.SEEN_CARD_WEIGHT,
		"eskiden görülmüş kart hafifçe sönümlenir")
	t.almost(director.novelty_multiplier("evt_recent", context), RoadDirector.RECENT_CARD_WEIGHT,
		"yeni görülmüş kart bastırılır")
	t.ok(director.novelty_multiplier("evt_recent", context) > 0.0, "hiçbir kart havuzdan çıkmaz")
	# Hafızayı taşımayan bir bağlam eski davranışı alır.
	t.almost(director.novelty_multiplier("evt_new", {}), 1.0, "hafızasız bağlam çarpan uygulamaz")

func _test_recent_ring_is_bounded_and_saved(t) -> void:
	var session := _session()
	for i in RoadDirector.DOMINO_NEXT.size() + GameSession.RECENT_CARD_MEMORY + 4:
		session.note_event_seen("evt_%d" % i)
	t.le(session.recent_card_ids.size(), GameSession.RECENT_CARD_MEMORY, "halka sınırlı")
	# Aynı kart iki kez gelirse halkada bir kez durur, en sonda.
	session.note_event_seen("evt_0")
	t.eq(session.recent_card_ids.count("evt_0"), 1, "tekrar eden kart halkada bir kez")
	t.eq(String(session.recent_card_ids[-1]), "evt_0", "en son görülen sonda")
	var reloaded := GameSession.new(0, 0, 1)
	reloaded.load_from_dict(session.to_save_dict())
	t.eq(reloaded.recent_card_ids, session.recent_card_ids, "halka kayda yazılır")
