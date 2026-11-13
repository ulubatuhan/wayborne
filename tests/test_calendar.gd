extends RefCounted

## Yılın dönemleri (Y-E08): gün sayısından hesaplanır, bağlama yazılır,
## ilgili kartları çoğaltır, kendi kartları yalnız döneminde gelir.

func suite_name() -> String:
	return "Takvim"

func run(t) -> void:
	_test_periods(t)
	_test_context(t)
	_test_weights_point_at_real_cards(t)

func _test_periods(t) -> void:
	t.eq(SideriaCalendar.period(0), "ilk_ot", "yılın ilk günü İlk Ot")
	t.eq(SideriaCalendar.period(65), "hac", "hac yürüyüşü")
	t.eq(SideriaCalendar.period(360 + 65), "hac", "takvim yıl yıl döner")
	t.eq(SideriaCalendar.period(100), "", "dönem dışı boş")
	t.eq(SideriaCalendar.days_until("panayir", 140), 10, "panayıra on gün")
	t.eq(SideriaCalendar.days_until("ilk_ot", 359), 1, "yılbaşına bir gün")
	for id in SideriaCalendar.PERIODS:
		var key := SideriaCalendar.name_key(String(id))
		t.ne(TranslationServer.translate(key), key, "dönem adı çevrilmiş: %s" % key)

func _test_context(t) -> void:
	var session := GameSession.new(200, 20, 1)
	session.total_days_elapsed = 301
	t.eq(int(session.build_event_context().get("takvim_tas_gecesi", 0)), 1, "Taş Gecesi bağlamda")
	session.total_days_elapsed = 120
	t.eq(int(session.build_event_context().get("takvim_tas_gecesi", 0)), 0, "dönem bitince bağlamdan düşer")

func _test_weights_point_at_real_cards(t) -> void:
	var ids := {}
	for event in EventCatalog.get_road_events():
		ids[event.event_id] = event
	for period in EventCatalog.CALENDAR_WEIGHTS:
		t.ok(SideriaCalendar.PERIODS.has(period), "ağırlık tablosundaki dönem takvimde: %s" % period)
		for event_id in EventCatalog.CALENDAR_WEIGHTS[period]:
			t.ok(ids.has(event_id), "dönem kartı kataloğda: %s" % event_id)
	var grave: GameEvent = ids.get("evt_grave_on_the_road")
	if grave != null:
		var base := grave.get_weight({"companions_died": 1})
		var night := grave.get_weight({"companions_died": 1, "takvim_tas_gecesi": 1})
		t.ok(night > base * 3.0, "Taş Gecesi mezar kartını çoğaltır: %.2f > %.2f" % [night, base])
