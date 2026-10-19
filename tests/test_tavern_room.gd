extends RefCounted

## Canlı taverna (9.4): yürüyüş bir tur boyunca iki ucu gezer ve uçlarda durur,
## titreme sınırlı, bardak masadan ağıza çıkıp iner, her yer bilinen bir
## çapaya düşer, kalabalık günün tohumundan hep aynı kurulur.

func suite_name() -> String:
	return "TavernRoom"

func run(t) -> void:
	var start := TavernRoom.walk_progress(0.0)
	t.eq(start.x, 0.0, "garson sol uçtan başlar")
	t.eq(start.y, 1.0, "önce sağa yürür")
	var halfway := TavernRoom.walk_progress(0.25)
	t.eq(halfway.z, 1.0, "sağ uçta durur")
	t.eq(halfway.x, 1.0, "durduğu yer sağ uç")
	var back := TavernRoom.walk_progress(0.6)
	t.eq(back.y, -1.0, "sonra sola döner")
	var ends := TavernRoom.walk_progress(0.999)
	t.eq(ends.z, 1.0, "sol uçta durur")
	for k in 100:
		var f := TavernRoom.flicker(float(k) * 0.37, 1.3)
		t.ok(f > 0.45 and f < 1.05, "titreme sınırlı")
	t.eq(TavernRoom.drink_lift(TavernRoom.DRINK_SECONDS + 0.5, 0.0), 0.0, "içiş dışında bardak masada")
	t.eq(TavernRoom.drink_lift(TavernRoom.DRINK_SECONDS * 0.5, 0.0), 1.0, "içişin ortasında bardak ağız hizasında")
	t.eq(TavernRoom.drink_lift(0.0, 0.0), 0.0, "içiş başında bardak masada")
	for key in ["bartender", "waitress_left", "waitress_right", "bard", "fire", "counter_top", "table_a", "table_b", "table_c",
			"lantern_l", "lantern_r", "candle_a", "candle_b", "candle_c"] + TavernRoom.SEATS:
		t.ok(TavernLayout.ANCHORS.has(key), "çapa tanımlı: %s" % key)
		t.ok(float(TavernLayout.ANCHORS[key].person_h) > 0.05, "çapanın boyu var: %s" % key)
	var a := TavernRoom.new()
	a.size = Vector2(1280, 720)
	a.populate("belvanor", 12)
	var b := TavernRoom.new()
	b.size = Vector2(1280, 720)
	b.populate("belvanor", 12)
	t.eq(a.get_actor_count(), b.get_actor_count(), "aynı gün aynı kalabalık")
	t.ok(a.get_actor_count() >= 7 and a.get_actor_count() <= 9, "tezgâhçı, garson, ozan ve 4-6 müşteri")
	t.eq(a.character_of(0).character_name, b.character_of(0).character_name, "aynı gün aynı kişiler")
	a.free()
	b.free()
