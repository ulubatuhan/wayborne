extends RefCounted

## Canlı taverna (9.4): oda alanı tam genişlikte örter, kişiler derinliğe göre
## büyür, herkesin bir rotası var ve rota yürünür (meyhaneci tezgâh arkasında
## kalır, yardımcı masalara gider, ozan şöminenin öbür yanına geçer, konuk
## gelip gider), titreme sınırlı, bardak masadan ağıza çıkıp iner, her yer
## bilinen bir çapaya düşer, kalabalık günün tohumundan hep aynı kurulur.

func suite_name() -> String:
	return "TavernRoom"

func run(t) -> void:
	_test_pure_curves(t)
	_test_anchors(t)
	_test_population(t)
	_test_routes_move(t)

func _test_pure_curves(t) -> void:
	var wide := TavernRoom.cover_rect(Vector2(1920, 700), TavernRoom.ASPECT, TavernRoom.FOCUS_Y)
	t.almost(wide.size.x, 1920.0, "oda genişliği tam örter")
	t.ok(wide.position.y <= 0.0 and wide.end.y >= 700.0, "oda yüksekliği alanı boşluksuz örter")
	var tall := TavernRoom.cover_rect(Vector2(800, 900), TavernRoom.ASPECT, TavernRoom.FOCUS_Y)
	t.ok(tall.size.y >= 900.0 and tall.position.x <= 0.0 and tall.end.x >= 800.0, "dar alanda da boşluk kalmaz")
	t.ok(TavernRoom.person_share_at(0.78) > TavernRoom.person_share_at(0.65), "öndeki kişi arkadakinden büyük")
	for key in TavernRoom.SEATS:
		var a: Dictionary = TavernLayout.ANCHORS[key]
		t.almost(TavernRoom.person_share_at(float(a.y)), float(a.person_h), "derinlik doğrusu çapayla uyuşur: %s" % key, 0.01)
	var step := TavernRoom.step_toward(Vector2.ZERO, Vector2(10, 0), 4.0)
	t.eq(step, Vector2(4, 0), "adım hedefe doğru")
	t.eq(TavernRoom.step_toward(Vector2.ZERO, Vector2(3, 0), 4.0), Vector2(3, 0), "adım hedefi aşmaz")
	for k in 100:
		var f := TavernRoom.flicker(float(k) * 0.37, 1.3)
		t.ok(f > 0.45 and f < 1.05, "titreme sınırlı")
	t.eq(TavernRoom.drink_lift(TavernRoom.DRINK_SECONDS + 0.5, 0.0), 0.0, "içiş dışında bardak masada")
	t.eq(TavernRoom.drink_lift(TavernRoom.DRINK_SECONDS * 0.5, 0.0), 1.0, "içişin ortasında bardak ağız hizasında")
	t.eq(TavernRoom.drink_lift(0.0, 0.0), 0.0, "içiş başında bardak masada")

func _test_anchors(t) -> void:
	for key in ["bartender", "bar_pour", "pickup", "serve_a", "serve_b", "bard", "bard_right", "door",
			"aisle_a1", "aisle_a2", "aisle_b1", "aisle_b2", "fire", "counter_top", "table_a", "table_b", "table_c",
			"lantern_l", "lantern_r", "candle_a", "candle_b", "candle_c"] + TavernRoom.SEATS:
		t.ok(TavernLayout.ANCHORS.has(key), "çapa tanımlı: %s" % key)
		t.ok(float(TavernLayout.ANCHORS[key].person_h) > 0.05, "çapanın boyu var: %s" % key)
	for key in TavernRoom.ROLE_LABEL_KEYS:
		t.ok(TranslationServer.translate(String(TavernRoom.ROLE_LABEL_KEYS[key])) != String(TavernRoom.ROLE_LABEL_KEYS[key]), "rolün adı çevrilmiş: %s" % key)

func _room() -> TavernRoom:
	var room := TavernRoom.new()
	room.size = Vector2(1920, 720)
	room.populate("belvanor", 12)
	return room

func _test_population(t) -> void:
	var a := _room()
	var b := _room()
	t.eq(a.get_actor_count(), b.get_actor_count(), "aynı gün aynı kalabalık")
	t.ok(a.get_actor_count() >= 8 and a.get_actor_count() <= 9, "meyhaneci, yardımcı, ozan, 4-5 konuk ve gelip giden biri")
	t.eq(a.character_of(0).character_name, b.character_of(0).character_name, "aynı gün aynı kişiler")
	var roles := {}
	for i in a.get_actor_count():
		roles[a.role_of(i)] = true
	for role in [TavernRoom.ROLE_BARTENDER, TavernRoom.ROLE_WAITRESS, TavernRoom.ROLE_BARD, TavernRoom.ROLE_PATRON, TavernRoom.ROLE_VISITOR]:
		t.ok(roles.has(role), "rol var: %s" % role)
	a.free()
	b.free()

func _index_of(room: TavernRoom, role: String) -> int:
	for i in room.get_actor_count():
		if room.role_of(i) == role:
			return i
	return -1

func _test_routes_move(t) -> void:
	var room := _room()
	var bar := _index_of(room, TavernRoom.ROLE_BARTENDER)
	var helper := _index_of(room, TavernRoom.ROLE_WAITRESS)
	var bard := _index_of(room, TavernRoom.ROLE_BARD)
	var visitor := _index_of(room, TavernRoom.ROLE_VISITOR)
	var bar_xs := {}
	var helper_xs := {}
	var bard_sides := {}
	var visitor_seen := false
	var bar_y := room.position_of(bar).y
	var bar_stays := true
	for k in 120:
		room.simulate(1.0)
		bar_xs[snappedf(room.position_of(bar).x, 0.02)] = true
		helper_xs[snappedf(room.position_of(helper).x, 0.05)] = true
		bard_sides[room.position_of(bard).x < 0.5] = true
		if room.position_of(visitor).x < 0.95:
			visitor_seen = true
		if absf(room.position_of(bar).y - bar_y) > 0.001:
			bar_stays = false
	t.ok(bar_xs.size() >= 3, "meyhaneci tezgâh boyunca gidip gelir")
	t.ok(bar_stays, "meyhaneci tezgâhın arkasından çıkmaz")
	t.ok(helper_xs.size() >= 5, "yardımcı masaları dolaşır")
	t.eq(bard_sides.size(), 2, "ozan şöminenin iki yanında da çalar")
	t.ok(visitor_seen, "konuk kapıdan girip odaya gelir")
	room.free()
