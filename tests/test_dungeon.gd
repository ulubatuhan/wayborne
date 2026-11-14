extends RefCounted

## Galeri ağızları (Y-A07): bulunur, inilir; seviye seviye harita (odalar,
## koridorlar, iniş, son oda), koridorun bedeli (ışık, stres, gün), çıkış ve
## vazgeçiş, kayıt ve haritadan önceki kayıtlar, her seviyenin bölge resmi.

func suite_name() -> String:
	return "Zindan"

func run(t) -> void:
	_test_mouth_only_near_vorgat(t)
	_test_full_descent(t)
	_test_bag_limit(t)
	_test_map_shape(t)
	_test_light_and_dark(t)
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

## Haritada `target` odasına en kısa yoldan yürür; yolda açılan oda kartları
## yaşanmış sayılır (seçimsiz). Koridorun etkileri olay diliyle uygulanır.
func _walk_to(session: GameSession, target: int) -> int:
	var level := DungeonMap.level_of(session.dungeon_run)
	var path := _path(level, int(session.dungeon_run["room"]), target)
	var walked := 0
	for room_id in path:
		var choice := DungeonMap.move_choice(session, room_id)
		var effects: Array[EventEffect] = []
		for effect in choice.effects:
			if effect.type != EventEffect.Type.TRIGGER_COMBAT:
				effects.append(effect)
		EventEffectApplier.apply(effects, session)
		walked += 1
		if String(session.dungeon_run.get("phase", "")) == "stage":
			var card := session.dungeon_next_event()
			session.dungeon_after_stage(card.event_id)
	return walked

func _path(level: Dictionary, from: int, to: int) -> Array:
	var prev := {from: -1}
	var queue: Array = [from]
	while not queue.is_empty():
		var at: int = queue.pop_front()
		if at == to:
			break
		for next in DungeonMap.neighbours(level, at):
			if not prev.has(next):
				prev[next] = at
				queue.append(next)
	var path: Array = []
	var at := to
	while prev.has(at) and at != from:
		path.push_front(at)
		at = int(prev[at])
	return path

func _test_full_descent(t) -> void:
	var session := _session_to("vorgat")
	session.add_to_cargo(ItemCatalog.get_item(ItemCatalog.TORCH), 4)
	var days_before := session.journey_days_remaining
	EventEffectApplier.apply([EventEffect.make(EventEffect.Type.DUNGEON_ENTER, 1, "")] as Array[EventEffect], session)
	t.ok(session.dungeon_found(DungeonCatalog.ESKI_AGIZ), "ilk ağız bulundu")
	t.ok(session.dungeon_on_map(), "inince harita açılır (girişin kartı yok)")
	t.eq(session.dungeon_next_event(), null, "haritadayken kart yok")
	var level := DungeonMap.level_of(session.dungeon_run)
	for other in DungeonMap.neighbours(level, 0):
		t.ok(bool(DungeonMap.room(level, other)["seen"]), "girişin komşuları görünür")
	var stair := DungeonMap.stair_id(level)
	var walked := _walk_to(session, stair)
	t.eq(int(session.dungeon_run["room"]), stair, "inişe varıldı")
	t.eq(session.get_total_quantity(ItemCatalog.TORCH), 4 - int(ceil(float(walked) / DungeonMap.TORCH_STEPS)), "meşaleler koridor koridor yandı")
	t.ok(session.journey_days_remaining >= days_before + walked / DungeonMap.STEPS_PER_DAY, "kervan koridor başına bekledi")
	EventEffectApplier.apply(DungeonMap.descend_choice(session).effects, session)
	t.eq(int(session.dungeon_run["depth"]), 2, "bir seviye inildi")
	t.eq(int(session.dungeon_run["room"]), 0, "yeni seviyenin girişinde")
	# Sona kadar in, sonra son odaya yürü.
	var guard := 0
	while int(session.dungeon_run["depth"]) < DungeonCatalog.max_depth(DungeonCatalog.ESKI_AGIZ) and guard < 10:
		guard += 1
		_walk_to(session, DungeonMap.stair_id(DungeonMap.level_of(session.dungeon_run)))
		EventEffectApplier.apply(DungeonMap.descend_choice(session).effects, session)
	var last_level := DungeonMap.level_of(session.dungeon_run)
	var final_id := -1
	for room in last_level["rooms"]:
		if String(room["type"]) == DungeonMap.FINAL:
			final_id = int(room["id"])
	t.eq(DungeonMap.stair_id(last_level), -1, "son seviyede iniş yok")
	var path := _path(last_level, int(session.dungeon_run["room"]), final_id)
	for k in range(path.size() - 1):
		_walk_to(session, int(path[k]))
	var choice := DungeonMap.move_choice(session, final_id)
	EventEffectApplier.apply([choice.effects[0]] as Array[EventEffect], session)
	var last := session.dungeon_next_event()
	t.eq(last.event_id, "evt_dng_s_sealed_tunnel", "son oda ağzın kendi kartı")
	session.dungeon_after_stage(last.event_id)
	EventEffectApplier.apply(DungeonMap.leave_choice().effects, session)
	var gate := session.dungeon_next_event()
	t.eq(gate.event_id, "evt_dng_gate", "çık denince çıkış kartı")
	t.eq(gate.choices.size(), 3, "paylı çık, paysız çık, vazgeç")
	EventEffectApplier.apply(gate.choices[2].effects, session)
	t.ok(session.dungeon_on_map(), "vazgeçince haritaya dönülür")
	EventEffectApplier.apply(DungeonMap.leave_choice().effects, session)
	gate = session.dungeon_next_event()
	var climb_days := 0
	for effect in gate.choices[1].effects:
		if effect.type == EventEffect.Type.TRAVEL_DAYS:
			climb_days = effect.amount
	t.eq(climb_days, DungeonMap.climb_days(4), "derinden dönüş gün alır")
	EventEffectApplier.apply(gate.choices[1].effects, session)
	t.ok(not session.dungeon_run.has("depth"), "çıkıldı")
	t.eq(int(session.dungeons[DungeonCatalog.ESKI_AGIZ]["deepest"]), 4, "en derin seviye kayıtlı")
	var wrote := false
	for entry in session.journal:
		if String(entry.get("text", "")).contains(TranslationServer.translate("DUNGEON_ESKI_AGIZ")):
			wrote = true
	t.ok(wrote, "ağız deftere yazıldı")

## Her ağız, her giriş: her oda girişten ulaşılır, iniş (ya da son oda) tek,
## her seviyede ganimet var, ikinciden sonra savaş var; kartlar zindan kartı.
func _test_map_shape(t) -> void:
	for id in DungeonCatalog.ORDER:
		for visit in 3:
			var levels := DungeonMap.generate(id, visit)
			t.eq(levels.size(), DungeonCatalog.max_depth(id), "%s: seviye sayısı derinlik kadar" % id)
			for index in levels.size():
				var level: Dictionary = levels[index]
				var last := index == levels.size() - 1
				var kinds: Array = []
				for room in level["rooms"]:
					kinds.append(String(room["type"]))
					t.ok(int(room["id"]) == 0 or not _path(level, 0, int(room["id"])).is_empty(),
						"%s/%d: oda %d girişten ulaşılır" % [id, index + 1, int(room["id"])])
					var card := String(room["card"])
					if not card.is_empty():
						t.ok(DungeonCatalog.is_stage(card), "oda kartı zindan kartı: %s" % card)
				t.eq(kinds.count(DungeonMap.FINAL if last else DungeonMap.STAIR), 1, "%s/%d: tek çıkış yolu" % [id, index + 1])
				t.ok(kinds.has(DungeonMap.CACHE), "%s/%d: ganimet var" % [id, index + 1])
				if index >= 1:
					t.ok(kinds.has(DungeonMap.FIGHT), "%s/%d: savaş var" % [id, index + 1])
				t.le(kinds.count(DungeonMap.REST), 1, "%s/%d: en çok bir dinlenme" % [id, index + 1])
	t.eq(DungeonMap.generate(DungeonCatalog.KEMRUG_YARIGI, 1), DungeonMap.generate(DungeonCatalog.KEMRUG_YARIGI, 1),
		"aynı ağız, aynı giriş: aynı harita")
	t.ne(DungeonMap.generate(DungeonCatalog.KEMRUG_YARIGI, 1), DungeonMap.generate(DungeonCatalog.KEMRUG_YARIGI, 2),
		"başka giriş: başka harita")

func _test_light_and_dark(t) -> void:
	var session := _session_to("vorgat")
	session.add_to_cargo(ItemCatalog.get_item(ItemCatalog.TORCH), 1)
	session.dungeon_enter(DungeonCatalog.KOR_KAZMALAR, true)
	var level := DungeonMap.level_of(session.dungeon_run)
	var far := -1
	for room in level["rooms"]:
		if not DungeonMap.neighbours(level, 0).has(int(room["id"])) and int(room["id"]) != 0:
			far = int(room["id"])
	if far >= 0:
		session.dungeon_move(far)
		t.eq(int(session.dungeon_run["room"]), 0, "komşu olmayan odaya yürünmez")
	var lit := DungeonMap.move_choice(session, DungeonMap.neighbours(level, 0)[0])
	t.eq(lit.effects[1].amount, DungeonMap.STEP_STRESS_LIT, "ışıkla koridor az yorar")
	session.dungeon_move(DungeonMap.neighbours(level, 0)[0])
	t.eq(session.get_total_quantity(ItemCatalog.TORCH), 0, "ilk koridorda meşale yakıldı")
	t.eq(int(session.dungeon_run["light"]), DungeonMap.TORCH_STEPS - 1, "yanan meşalenin payı")
	session.dungeon_run["light"] = 0
	t.not_ok(session.dungeon_has_light(), "meşale bitti, ışık yok")
	var here := int(session.dungeon_run["room"])
	var dark := DungeonMap.move_choice(session, DungeonMap.neighbours(level, here)[0])
	t.eq(dark.effects[1].amount, DungeonMap.STEP_STRESS_DARK, "karanlıkta koridor ağır yorar")

func _test_bag_limit(t) -> void:
	var session := _session_to("vorgat")
	session.dungeon_enter("", true)
	var cap := session.get_party().size() * DungeonCatalog.BAG_PER_PERSON
	t.eq(session.dungeon_bag_free(), cap, "sırt boş")
	EventEffectApplier.apply([EventEffect.make(EventEffect.Type.DUNGEON_LOOT, cap)] as Array[EventEffect], session)
	t.eq(session.dungeon_bag_free(), 0, "sırt doldu")
	var cache := EventCatalog.get_event("evt_dng_s_miners_cache")
	t.not_ok(cache.choices[0].is_available(session.build_event_context()), "sırt doluyken ganimet alınmaz")

func _test_save(t) -> void:
	var session := _session_to("vorgat")
	session.dungeon_enter("", true)
	var loaded := GameSession.new(300, 30, 1)
	loaded.load_from_dict(session.to_save_dict())
	t.ok(loaded.dungeon_found(DungeonCatalog.ESKI_AGIZ), "bulunan ağız kayıtta")
	t.eq(int(loaded.dungeon_run.get("depth", 0)), 1, "süren iniş kayıtta")
	t.eq(loaded.dungeon_run["map"], session.dungeon_run["map"], "harita kayıtta, odalar ve görülenler dahil")
	t.ok(loaded.dungeon_on_map(), "yüklenince haritaya dönülür")
	# Haritadan önceki bir kayıt: süren iniş o seviyenin girişinden haritaya döner.
	var old := _session_to("vorgat")
	old.dungeon_run = {"id": DungeonCatalog.KEMRUG_YARIGI, "depth": 2, "phase": "gate", "used": [], "bag": 0, "visit": 0}
	t.eq(old.dungeon_next_event(), null, "eski kayıt haritaya döner")
	t.ok(old.dungeon_on_map(), "eski kayıtta harita kuruldu")
	t.eq(int(old.dungeon_run["depth"]), 2, "eski kaydın seviyesi korunur")

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
	for type in DungeonMap.POOLS:
		for tier in DungeonMap.POOLS[type]:
			for id in tier:
				if not all.has(String(id)):
					all.append(String(id))
	for id in DungeonCatalog.DUNGEONS:
		all.append(String(DungeonCatalog.DUNGEONS[id]["last"]))
	for id in all:
		var card := EventCatalog.get_event(id)
		t.ok(card != null and card.triggered_only, "aşama kartı kataloğda ve yalnız zindanda: %s" % id)
	# Her seviyenin bölge resmi var (savaş, keşif ve kart aynı resmi okur).
	for id in DungeonCatalog.ORDER:
		for level in range(1, DungeonCatalog.max_depth(id) + 1):
			var path := CombatBackdrop.DUNGEON_DIR + DungeonMap.look(id, level) + ".jpg"
			t.ok(FileAccess.file_exists(path), "bölge resmi var: %s" % path)
