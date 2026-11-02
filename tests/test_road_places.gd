extends RefCounted

## T16-11 (kullanıcı, 2026-10-29): haritada adı olan her yer oynanabilir.

func suite_name() -> String:
	return "RoadPlaces"

func run(t) -> void:
	_test_every_named_place_is_on_a_road(t)
	_test_cards(t)
	_test_seen_places_are_remembered(t)

func _test_every_named_place_is_on_a_road(t) -> void:
	var places := WorldMapData.get_all_road_places()
	t.ok(places.size() >= 90, "haritanın adlı yerleri yollara bağlı (%d)" % places.size())
	var kinds := {}
	for entry in places:
		var place: Dictionary = entry
		kinds[String(place["kind"])] = true
		var parts := String(place["route"]).split("|")
		t.ok(WorldMapData.get_route(parts[0], parts[1]) != null, "%s gerçek bir yolda" % place["id"])
		t.ok(float(place["share"]) >= 0.0 and float(place["share"]) <= 1.0, "%s yolun üstünde" % place["id"])
		t.ok(EventCatalog.PLACE_EVENTS.has(String(place["visit"])), "%s için kart var" % place["id"])
		t.ok(not String((place["name"] as Dictionary).get("tr", "")).is_empty(), "%s adı var" % place["id"])
	for kind in ["in_yurtcamp", "ih_mezra", "ia_abbey", "iw_tower", "ir_ruins", "iv_fishvillage", "ix_mountaintribe"]:
		t.ok(kinds.has(kind), "%s türü oynanabilir" % kind)

func _test_cards(t) -> void:
	for visit in EventCatalog.PLACE_EVENTS:
		var on_road := EventCatalog.place_visit_event(String(visit), 0)
		var off_road := EventCatalog.place_visit_event(String(visit), 3)
		t.ok(on_road.choices.size() >= 2, "%s kartında seçim var" % visit)
		var detour := false
		for effect in off_road.choices[0].effects:
			if effect.type == EventEffect.Type.TRAVEL_DAYS and effect.amount == 6:
				detour = true
		t.ok(detour, "%s: yoldan uzak yere uğramak gidiş-dönüş gün ister" % visit)
		t.not_ok(on_road.is_eligible({"gold": 500}), "%s rastgele çekilmez" % visit)
	var people := People.new()
	people.active_place_name = "Kaynurak Obası"
	people.active_place_off = 2
	t.eq(people.fill_names("{place}, {off}"), "Kaynurak Obası, 4", "kart metni yerin adıyla dolar")

func _test_seen_places_are_remembered(t) -> void:
	var session := GameSession.new(100, 0, 1)
	session.note_road_place("place_0", "Kaynurak Obası")
	session.note_road_place("place_0", "Kaynurak Obası")
	t.eq(session.seen_places.size(), 1, "yer bir kez yazılır")
	t.eq(session.journal.size(), 1, "deftere bir satır")
	var copy := GameSession.new(0, 0, 1)
	copy.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	t.ok(copy.seen_places.has("place_0"), "görülen yerler kayıtta")
