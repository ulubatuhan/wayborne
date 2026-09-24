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
	_test_shrine_weight_follows_terrain(t)
	_test_highland_challenge_weight_follows_terrain(t)
	_test_road_patrol_has_fight_option(t)
	_test_bandit_ambush_toll_scales_with_danger(t)

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

## `RouteTerrain` bir yol parçasını biyoma uygun bir sunak durağıyla
## çizebiliyor (bkz. RouteTerrain.STOP_SHRINE) - evt_roadside_shrine bu
## durağın önünden geçilen gün neredeyse kesin, başka günler nadiren
## çekilmeli. road_journey.gd bu bayrağı context'e "near_shrine" olarak
## ekliyor (bkz. o dosyanın _run_day'i); burada katalogdaki olayın kendi
## ağırlık tepkisini doğruca sınıyoruz - motoru koşturmaya gerek yok.
func _test_shrine_weight_follows_terrain(t) -> void:
	var events := EventCatalog.get_road_events()
	var shrine_event: GameEvent = null
	for event in events:
		if event.event_id == "evt_roadside_shrine":
			shrine_event = event
			break
	t.ne(shrine_event, null, "evt_roadside_shrine katalogda var")

	var away_weight := shrine_event.get_weight({"near_shrine": 0.0})
	var near_weight := shrine_event.get_weight({"near_shrine": 1.0})
	t.ok(away_weight > 0.0, "sunak yokken bile küçük bir şans kalır")
	t.ok(near_weight > away_weight * 5.0, "sunağın önündeyken ağırlık kayda değer büyür")

## Faz 17 PR-6: aynı desen dağ geçidi için - Güç Sınavı geçidin önünden
## geçilen gün kayda değer artmalı, katalogda tanımı ele geçirir.
func _test_highland_challenge_weight_follows_terrain(t) -> void:
	var events := EventCatalog.get_road_events()
	var highland_event: GameEvent = null
	for event in events:
		if event.event_id == "evt_culture_highland_challenge":
			highland_event = event
			break
	t.ne(highland_event, null, "evt_culture_highland_challenge katalogda var")

	var away_weight := highland_event.get_weight({"near_mountain_pass": 0.0})
	var near_weight := highland_event.get_weight({"near_mountain_pass": 1.0})
	t.ok(away_weight > 0.0, "geçit yokken bile küçük bir şans kalır")
	t.ok(near_weight > away_weight * 3.0, "geçidin önündeyken ağırlık kayda değer büyür")

## Faz 17 PR-6 eksiği: evt_road_patrol'ün kendi metni ("haydutları
## temizlemeye niyetliler") hiçbir zaman gerçek bir savaşa açılmıyordu -
## artık üçüncü bir seçenek "bandit" türünde TRIGGER_COMBAT açıyor,
## evt_guard_patrol'ün "guard" türünden (muhafızla kavga, kazanınca itibar
## kaybettirir) bilerek ayrı.
func _test_road_patrol_has_fight_option(t) -> void:
	var events := EventCatalog.get_road_events()
	var patrol_event: GameEvent = null
	for event in events:
		if event.event_id == "evt_road_patrol":
			patrol_event = event
			break
	t.ne(patrol_event, null, "evt_road_patrol katalogda var")

	var fight_choice: EventChoice = null
	for choice in patrol_event.choices:
		if choice.text_key == "EVT_PATROL_OPT_FIGHT":
			fight_choice = choice
			break
	t.ne(fight_choice, null, "devriyeyle birlikte dövüşme seçeneği var")

	var triggers_bandit_combat := false
	for effect in fight_choice.effects:
		if effect.type == EventEffect.Type.TRIGGER_COMBAT and effect.text_value == "bandit":
			triggers_bandit_combat = true
	t.ok(triggers_bandit_combat, "seçenek haydut türünde bir savaş açıyor, muhafız değil")

## Faz 17 PR-6 eksiği: fidye artık sabit 120 GG değil, yolun tehlikesine
## göre üç banda ölçekleniyor - EnemyCatalog.build_bandit_squad'ın kadroyu
## zaten aynı danger değerine göre ölçeklendirdiği ekonominin fidye
## tarafındaki eksik parçası. LESS_THAN'in tüm amacı sınırda (0.35/0.6)
## iki bandın birden "uygun" sayılıp rastgeleleşmesini engellemek -
## burada doğrudan sınanıyor.
func _test_bandit_ambush_toll_scales_with_danger(t) -> void:
	var events := EventCatalog.get_road_events()
	var ambush_event: GameEvent = null
	for event in events:
		if event.event_id == "evt_bandit_ambush":
			ambush_event = event
			break
	t.ne(ambush_event, null, "evt_bandit_ambush katalogda var")

	var pay_choice: EventChoice = null
	for choice in ambush_event.choices:
		if choice.text_key == "EVT_AMBUSH_OPT_PAY":
			pay_choice = choice
			break
	t.ne(pay_choice, null, "fidye seçeneği bulundu")
	t.eq(pay_choice.outcomes.size(), 3, "fidye üç banda ayrılmış")

	var engine := EventEngine.new(events, 7)
	var low := engine.resolve_outcome(pay_choice, {"danger": 0.1})
	var mid := engine.resolve_outcome(pay_choice, {"danger": 0.4})
	var high := engine.resolve_outcome(pay_choice, {"danger": 0.9})
	t.ne(low, null, "düşük tehlikede bir sonuç var")
	t.ne(mid, null, "orta tehlikede bir sonuç var")
	t.ne(high, null, "yüksek tehlikede bir sonuç var")
	t.eq(int(low.effects[0].amount), -80, "düşük tehlikede fidye en ucuz")
	t.eq(int(mid.effects[0].amount), -130, "orta tehlikede fidye orta")
	t.eq(int(high.effects[0].amount), -190, "yüksek tehlikede fidye en pahalı")
	t.ok(
		absf(high.effects[0].amount) > absf(low.effects[0].amount),
		"tehlikeli bir yolda haydutlar daha çok fidye ister"
	)

	# Bantlar örtüşmemeli: sınırda (0.35, 0.6) her zaman tam olarak bir
	# sonuç uygun olmalı, ikisi birden değil.
	for boundary in [0.35, 0.6]:
		var available := 0
		for outcome in pay_choice.outcomes:
			if outcome.is_available({"danger": boundary}):
				available += 1
		t.eq(available, 1, "sınırda (%s) tam olarak bir bant uygun" % boundary)
