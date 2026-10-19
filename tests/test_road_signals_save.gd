extends RefCounted

## Açık yol işaretlerinin sefer ortası kaydından geri gelmesi (TODO 11.1).
## İşaretler yalnızca yol ekranında yaşıyordu; kayıt yüklenince açık işaretler
## kayboluyordu. Artık JourneyController taşıyor ve kayıtta yazılıyor.

const NO_ZONE: String = "none"

func suite_name() -> String:
	return "RoadSignalsSave"

func run(t) -> void:
	_test_dict_round_trip(t)
	_test_bad_entries_are_dropped(t)
	_test_old_save_without_signals(t)
	_test_full_save_round_trip_and_escalation(t)
	_test_truth_is_hidden_and_kept(t)

func _journey_with_open_signal(seed_value: int) -> JourneyController:
	var journey := JourneyController.new()
	journey.clock = JourneyClock.new()
	journey.engine = EventEngine.new(EventCatalog.get_road_events(), seed_value)
	journey.journey_length_days = 6
	journey.signal_rng.seed = seed_value
	# Hiçbir bölgede ilgilenilmiyor (geçersiz bölge adı): işaret çözülmez.
	# Bir işaret açılana kadar saat ilerlet.
	for i in 400:
		journey.signals.tick(1.0, NO_ZONE, journey.signal_rng)
		if journey.signals.has_open():
			break
	return journey

func _test_dict_round_trip(t) -> void:
	var journey := _journey_with_open_signal(11)
	t.ok(journey.signals.has_open(), "tohumlu zarla en az bir işaret açıldı")
	# Yaş sıfırdan farklı olsun ki "yaş" da kaydedildiği görülsün.
	journey.signals.tick(2.5, NO_ZONE, journey.signal_rng)
	var before := journey.signals.open_signals.duplicate(true)
	var data = JSON.parse_string(JSON.stringify(journey.to_dict()))
	var restored := JourneyController.new()
	restored.load_from_dict(data, EventCatalog.get_road_events())
	t.eq(restored.signals.get_open_kinds(), journey.signals.get_open_kinds(), "açık işaret türleri birebir aynı")
	for i in before.size():
		t.almost(float(restored.signals.open_signals[i]["age_hours"]), float(before[i]["age_hours"]), "işaret yaşı birebir aynı")

func _test_bad_entries_are_dropped(t) -> void:
	var signals := RoadSignals.new()
	signals.from_dict({"open": [
		{"kind": "bilinmeyen", "age_hours": 3.0},
		{"kind": RoadSignals.KIND_WHEEL, "age_hours": -5.0},
		{"kind": RoadSignals.KIND_WHEEL, "age_hours": 1.0},
		"çöp",
		{"kind": RoadSignals.KIND_SMOKE, "age_hours": 2.0},
		{"kind": RoadSignals.KIND_STRAGGLER, "age_hours": 2.0},
	]})
	t.eq(signals.get_open_kinds(), [RoadSignals.KIND_WHEEL, RoadSignals.KIND_SMOKE], "bilinmeyen ve yinelenen girdi atılır, MAX_OPEN aşılmaz")
	t.almost(float(signals.open_signals[0]["age_hours"]), 0.0, "eksi yaş sıfıra kenetlenir")

func _test_old_save_without_signals(t) -> void:
	var journey := _journey_with_open_signal(23)
	var data = JSON.parse_string(JSON.stringify(journey.to_dict()))
	data.erase("signals")
	var restored := JourneyController.new()
	restored.signals.open_signals.append({"kind": RoadSignals.KIND_WHEEL, "age_hours": 1.0})
	restored.load_from_dict(data, EventCatalog.get_road_events())
	t.ok(not restored.signals.has_open(), "signals alanı olmayan eski kayıt boş listeyle açılır")

func _test_full_save_round_trip_and_escalation(t) -> void:
	var session := GameSession.new(500, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	session.start_playthrough(
		CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng
	)
	var route := WorldMapData.get_routes_from(session.current_location_id)[0]
	session.journey_origin_id = session.current_location_id
	session.journey_destination_id = route.to_location_id if route.from_location_id == session.current_location_id else route.from_location_id
	session.journey_total_days = 6
	session.journey_days_remaining = 5
	var journey := _journey_with_open_signal(31)
	var kinds_before := journey.signals.get_open_kinds()
	session.journey_snapshot = journey.to_dict()

	var fresh := GameSession.new(0, 0)
	fresh.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	t.ok(fresh.is_journey_active(), "sefer kaydı seferi taşıyor")
	var restored := JourneyController.new()
	restored.load_from_dict(fresh.journey_snapshot, EventCatalog.get_road_events())
	t.eq(restored.signals.get_open_kinds(), kinds_before, "kayıt dosyasından geçen işaretler aynı")

	# Yüklemeden sonra işaret, ihmal edilince yine büyür.
	var escalated: Array = []
	for i in int(RoadSignals.ESCALATE_HOURS) + 2:
		var outcome := restored.signals.tick(1.0, NO_ZONE, RandomNumberGenerator.new())
		escalated.append_array(outcome["escalated"])
		if not escalated.is_empty():
			break
	t.ok(escalated.has(kinds_before[0]), "yüklenen işaret ihmal edilince büyür")

## Belirsizlik (görev Y-B03): işaretin türü gerçeğini belirlemez, her türün
## birden çok gerçeği var ve çekilişleri dağılır; gerçek kayıttan döner, bozuk
## ya da eksik gerçek varsayılana düşer.
func _test_truth_is_hidden_and_kept(t) -> void:
	for kind in RoadSignals.ALL_KINDS:
		var seen := {}
		var rng := RandomNumberGenerator.new()
		rng.seed = 41
		for i in 300:
			seen[RoadSignals.roll_truth(kind, rng)] = true
		t.ok(seen.size() >= 2, "%s türü birden çok gerçeğe çıkar" % kind)
		for truth in seen:
			t.ok(RoadSignals.TRUTH_RESOLVED_KEYS.has(truth) and RoadSignals.TRUTH_ESCALATED_KEYS.has(truth), "%s gerçeğinin iki sonucu yazılı" % truth)
	var signals := RoadSignals.new()
	signals.open_signals = [{"kind": RoadSignals.KIND_SMOKE, "age_hours": 1.0, "truth": "herders"}]
	var copy := RoadSignals.new()
	copy.from_dict(JSON.parse_string(JSON.stringify(signals.to_dict())))
	t.eq(RoadSignals.truth_of(copy.open_signals[0]), "herders", "gerçek kayıttan döner")
	copy.from_dict({"open": [{"kind": RoadSignals.KIND_WHEEL, "age_hours": 1.0, "truth": "uydurma"}]})
	t.eq(RoadSignals.truth_of(copy.open_signals[0]), RoadSignals.default_truth(RoadSignals.KIND_WHEEL), "bilinmeyen gerçek varsayılana düşer")
	var resolved := RoadSignals.new()
	resolved.open_signals = [{"kind": RoadSignals.KIND_OMEN, "age_hours": 0.0, "truth": "true_omen"}]
	var outcome := resolved.tick(1.0, RoadAttention.ZONE_REAR, RandomNumberGenerator.new())
	t.eq(outcome["resolved_truths"], ["true_omen"], "ilgilenen gerçeği öğrenir")
