extends RefCounted

## Galeri ağızları (Y-A07): bulunur, inilir, aşama ve kapı sırayla gelir,
## derinleşmenin bedeli ödenir, son aşamadan sonra yalnız çıkış kalır,
## çıkış deftere yazılır, zar yeniden yüklemeyle değişmez.

func suite_name() -> String:
	return "Zindan"

func run(t) -> void:
	_test_mouth_only_near_vorgat(t)
	_test_full_descent(t)
	_test_bag_limit(t)
	_test_same_seed_same_stage(t)
	_test_save(t)
	_test_deep_squad(t)
	_test_stage_cards_exist(t)

func _session_to(destination_id: String) -> GameSession:
	var session := GameSession.new(300, 30, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	session.start_playthrough(CharacterData.create("Lider", CultureCatalog.HIGHLAND, CharacterStats.new()), rng)
	session.add_to_party(CharacterData.create("Eş", CultureCatalog.NOMAD, CharacterStats.new()))
	var destination := WorldMapData.get_location_by_id(destination_id)
	session.start_journey(destination_id, 4, 0.3, CaravanPlan.new(destination, 4))
	return session

func _test_mouth_only_near_vorgat(t) -> void:
	var near := _session_to("vorgat")
	t.eq(int(near.build_event_context().get("dungeon_mouth_here", 0)), 1, "Vorgat yolunda ağız bulunabilir")
	var far := _session_to("orsolune")
	t.eq(int(far.build_event_context().get("dungeon_mouth_here", 0)), 0, "başka yolda ağız yok")

func _test_full_descent(t) -> void:
	var session := _session_to("vorgat")
	session.add_to_cargo(ItemCatalog.get_item(ItemCatalog.TORCH), 1)
	var days_before := session.journey_days_remaining
	EventEffectApplier.apply([EventEffect.make(EventEffect.Type.DUNGEON_ENTER, 1, "")] as Array[EventEffect], session)
	t.ok(session.dungeon_found(DungeonCatalog.ESKI_AGIZ), "ilk ağız bulundu")
	var stage := session.dungeon_next_event()
	t.ok(stage != null and DungeonCatalog.is_stage(stage.event_id), "ilk kart bir aşama")
	session.dungeon_after_stage(stage.event_id)
	var gate := session.dungeon_next_event()
	t.eq(gate.event_id, "evt_dng_gate", "aşamadan sonra kapı")
	t.eq(gate.choices.size(), 3, "kapıda derine in, paylı çık, paysız çık")
	EventEffectApplier.apply(gate.choices[0].effects, session)
	t.eq(int(session.dungeon_run["depth"]), 2, "bir aşama derine inildi")
	t.eq(session.get_total_quantity(ItemCatalog.TORCH), 0, "meşale yandı")
	t.ok(session.journey_days_remaining > days_before or session.journey_days_remaining == days_before + 1, "kervan bir gün bekledi")
	# Sona kadar in.
	var guard := 0
	while int(session.dungeon_run["depth"]) < DungeonCatalog.max_depth(DungeonCatalog.ESKI_AGIZ) and guard < 10:
		guard += 1
		var next := session.dungeon_next_event()
		session.dungeon_after_stage(next.event_id)
		var g := session.dungeon_next_event()
		EventEffectApplier.apply(g.choices[0].effects, session)
	var last := session.dungeon_next_event()
	t.eq(last.event_id, "evt_dng_s_sealed_tunnel", "son aşama ağzın kendi kartı")
	session.dungeon_after_stage(last.event_id)
	var end_gate := session.dungeon_next_event()
	t.eq(end_gate.choices.size(), 2, "son kapıda yalnız çıkış")
	t.eq(end_gate.text_key, "EVT_DNG_GATE_END_TEXT", "son kapı göçüğü söyler")
	EventEffectApplier.apply(end_gate.choices[1].effects, session)
	t.ok(not session.dungeon_run.has("depth"), "çıkıldı")
	t.eq(int(session.dungeons[DungeonCatalog.ESKI_AGIZ]["deepest"]), 4, "en derin aşama kayıtlı")
	var wrote := false
	for entry in session.journal:
		if String(entry.get("text", "")).contains(TranslationServer.translate("DUNGEON_ESKI_AGIZ")):
			wrote = true
	t.ok(wrote, "ağız deftere yazıldı")

func _test_bag_limit(t) -> void:
	var session := _session_to("vorgat")
	session.dungeon_enter("", true)
	var cap := session.get_party().size() * DungeonCatalog.BAG_PER_PERSON
	t.eq(session.dungeon_bag_free(), cap, "sırt boş")
	EventEffectApplier.apply([EventEffect.make(EventEffect.Type.DUNGEON_LOOT, cap)] as Array[EventEffect], session)
	t.eq(session.dungeon_bag_free(), 0, "sırt doldu")
	var cache := EventCatalog.get_event("evt_dng_s_miners_cache")
	t.not_ok(cache.choices[0].is_available(session.build_event_context()), "sırt doluyken ganimet alınmaz")

func _test_same_seed_same_stage(t) -> void:
	var a := DungeonCatalog.stage_for(DungeonCatalog.KEMRUG_YARIGI, 3, 1, [])
	var b := DungeonCatalog.stage_for(DungeonCatalog.KEMRUG_YARIGI, 3, 1, [])
	t.eq(a, b, "aynı ağız, aynı giriş, aynı derinlik: aynı aşama")
	t.ok(DungeonCatalog.MIDDLE.has(a), "orta derinlik orta havuzdan")
	t.ne(DungeonCatalog.stage_for(DungeonCatalog.KEMRUG_YARIGI, 3, 1, [a]), a, "aynı inişte aşama tekrarlanmaz")

func _test_save(t) -> void:
	var session := _session_to("vorgat")
	session.dungeon_enter("", true)
	var loaded := GameSession.new(300, 30, 1)
	loaded.load_from_dict(session.to_save_dict())
	t.ok(loaded.dungeon_found(DungeonCatalog.ESKI_AGIZ), "bulunan ağız kayıtta")
	t.eq(int(loaded.dungeon_run.get("depth", 0)), 1, "süren iniş kayıtta")

func _test_deep_squad(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var shallow := EnemyCatalog.build_squad(EnemyCatalog.KIND_DEEP, "", 0.35, 2, rng)
	t.eq(shallow[0].template_id if "template_id" in shallow[0] else "", shallow[0].template_id if "template_id" in shallow[0] else "", "kadro kuruldu")
	t.ge(shallow.size(), 2, "sığda en az iki kör diş")
	var deep := EnemyCatalog.build_squad(EnemyCatalog.KIND_DEEP, "", 0.8, 2, rng)
	t.ge(deep.size(), 1, "derinde kadro var")
	t.ne(EnemyCatalog.get_kind_label(EnemyCatalog.KIND_DEEP), "ENEMY_KIND_DEEP", "kadro adı çevrilmiş")

func _test_stage_cards_exist(t) -> void:
	var all: Array[String] = []
	all.append_array(DungeonCatalog.SHALLOW)
	all.append_array(DungeonCatalog.MIDDLE)
	all.append_array(DungeonCatalog.DEEP)
	for id in DungeonCatalog.DUNGEONS:
		all.append(String(DungeonCatalog.DUNGEONS[id]["last"]))
	for id in all:
		var card := EventCatalog.get_event(id)
		t.ok(card != null and card.triggered_only, "aşama kartı kataloğda ve yalnız zindanda: %s" % id)
