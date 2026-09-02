extends RefCounted

## Motorun sözleşmesi: bir-kez olaylar tekrar çıkmaz, bekleme süresi
## dolmadan aynı olay dönmez, triggered_only olaylar açılmadan çekilmez
## ve aynı tohum aynı diziyi verir (tekrarlanabilir kayıtlar için şart).

func suite_name() -> String:
	return "EventEngine"

func run(t) -> void:
	_test_fire_only_once(t)
	_test_cooldown(t)
	_test_triggered_only(t)
	_test_conditions_filter(t)
	_test_seed_is_reproducible(t)
	_test_daily_chance_follows_danger(t)
	_test_shipped_catalog_is_sane(t)

func _make_event(event_id: String, weight: float = 1.0) -> GameEvent:
	var event := GameEvent.new()
	event.event_id = event_id
	event.title_key = "TEST_TITLE"
	event.text_key = "TEST_TEXT"
	event.base_weight = weight
	return event

func _pool(events: Array) -> Array[GameEvent]:
	var typed: Array[GameEvent] = []
	for event in events:
		typed.append(event)
	return typed

func _test_fire_only_once(t) -> void:
	var event := _make_event("bir_kez")
	event.fire_only_once = true

	var engine := EventEngine.new(_pool([event]), 99)
	t.ne(engine.draw_event(1, {}), null, "ilk çekimde gelir")

	engine.mark_fired(event, 1)
	t.eq(engine.draw_event(2, {}), null, "işaretlendikten sonra bir daha gelmez")

func _test_cooldown(t) -> void:
	var event := _make_event("beklemeli")
	event.cooldown_days = 3

	var engine := EventEngine.new(_pool([event]), 99)
	engine.mark_fired(event, 1)

	t.eq(engine.get_eligible_events(2, {}).size(), 0, "bekleme sırasında uygun değil")
	t.eq(engine.get_eligible_events(3, {}).size(), 0, "son bekleme gününde de değil")
	t.eq(engine.get_eligible_events(4, {}).size(), 1, "bekleme dolunca tekrar uygun")

func _test_triggered_only(t) -> void:
	var event := _make_event("zincir")
	event.triggered_only = true

	var engine := EventEngine.new(_pool([event]), 99)
	t.eq(engine.draw_event(1, {}), null, "açılmadan çekilmez")

	engine.unlock_event("zincir")
	t.ne(engine.draw_event(1, {}), null, "açılınca çekilir")

	engine.mark_fired(event, 1)
	t.eq(engine.draw_event(2, {}), null, "çıktıktan sonra kilit geri kapanır")

func _test_conditions_filter(t) -> void:
	var event := _make_event("zengin")
	event.conditions = _conditions([
		EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 100),
	])

	var engine := EventEngine.new(_pool([event]), 99)
	t.eq(engine.get_eligible_events(1, {"gold": 40}).size(), 0, "koşul tutmazsa elenir")
	t.eq(engine.get_eligible_events(1, {"gold": 100}).size(), 1, "koşul tutunca girer")
	t.eq(engine.get_eligible_events(1, {}).size(), 0, "anahtar yoksa koşul tutmaz")

func _conditions(items: Array) -> Array[EventCondition]:
	var typed: Array[EventCondition] = []
	for item in items:
		typed.append(item)
	return typed

func _test_seed_is_reproducible(t) -> void:
	var first_sequence := _draw_sequence(4242)
	var second_sequence := _draw_sequence(4242)
	var other_sequence := _draw_sequence(7)

	t.eq(first_sequence, second_sequence, "aynı tohum aynı diziyi verir")
	t.ne(first_sequence, other_sequence, "farklı tohum farklı dizi verir")

func _draw_sequence(seed_value: int) -> Array[String]:
	var engine := EventEngine.new(_pool([
		_make_event("a", 1.0), _make_event("b", 1.0), _make_event("c", 1.0),
	]), seed_value)

	# Uzun dizi: iki farklı tohumun tesadüfen aynı sırayı vermesi
	# ihtimalini ihmal edilebilir kılıyor, test kırılgan olmasın.
	var drawn: Array[String] = []
	for day in range(1, 17):
		var event := engine.draw_event(day, {})
		drawn.append("-" if event == null else event.event_id)
	return drawn

func _test_daily_chance_follows_danger(t) -> void:
	var engine := EventEngine.new(_pool([_make_event("a")]), 1)

	var calm := engine.get_daily_chance({"danger": 0.0})
	var risky := engine.get_daily_chance({"danger": 1.0})

	t.ge(risky, calm, "tehlike arttıkça olay ihtimali artar")
	t.le(risky, EventEngine.MAX_DAILY_EVENT_CHANCE, "ihtimal tavanı aşmaz")
	t.ge(calm, 0.0, "ihtimal negatif olmaz")

## Oyunun gerçekten sevk ettiği havuz: kimlikler tekil mi, metin
## anahtarları dolu mu, her seçeneğin bir karşılığı var mı.
func _test_shipped_catalog_is_sane(t) -> void:
	var events := EventCatalog.get_road_events()
	t.ge(float(events.size()), 10.0, "yol havuzunda en az on olay var")

	var seen_ids: Dictionary = {}
	for event in events:
		t.not_ok(seen_ids.has(event.event_id), "olay kimliği tekil: %s" % event.event_id)
		seen_ids[event.event_id] = true
		t.not_ok(event.title_key.is_empty(), "%s başlık anahtarı var" % event.event_id)
		t.not_ok(event.text_key.is_empty(), "%s metin anahtarı var" % event.event_id)
		t.ge(float(event.choices.size()), 1.0, "%s en az bir seçenek sunar" % event.event_id)

		for choice in event.choices:
			t.not_ok(choice.text_key.is_empty(), "%s seçenek metni var" % event.event_id)
			# Her seçenek ya doğrudan etki ya da bir sonuç tablosu taşımalı;
			# ikisi de yoksa seçenek hiçbir şey yapmıyor demektir.
			t.ok(
				not choice.effects.is_empty() or not choice.outcomes.is_empty(),
				"%s seçeneğinin bir karşılığı var" % event.event_id
			)
