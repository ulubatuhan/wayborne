extends RefCounted

## Motorun sözleşmesi: bir-kez olaylar tekrar çıkmaz, bekleme süresi
## dolmadan aynı olay dönmez, triggered_only olaylar açılmadan çekilmez
## ve aynı tohum aynı diziyi verir (tekrarlanabilir kayıtlar için şart).

func suite_name() -> String:
	return "EventEngine"

func run(t) -> void:
	_test_fire_only_once(t)
	_test_cooldown(t)
	_test_max_per_journey(t)
	_test_triggered_only(t)
	_test_conditions_filter(t)
	_test_seed_is_reproducible(t)
	_test_daily_chance_follows_danger(t)
	_test_shipped_catalog_is_sane(t)
	_test_shrine_weight_follows_terrain(t)
	_test_highland_challenge_weight_follows_terrain(t)
	_test_road_patrol_has_fight_option(t)
	_test_hunting_trip_weight_follows_terrain(t)
	_test_hunting_trip_hunt_option_opens_hunt_combat(t)
	_test_bandit_ambush_toll_scales_with_danger(t)
	_test_echo_changes_the_card_on_its_second_coming(t)
	_test_echo_weight(t)
	_test_echo_never_erases_a_cost(t)
	_test_news_events_frame_by_culture(t)
	_test_road_director(t)
	_test_combat_guarantee_rotates_the_card(t)
	_test_career_threats(t)

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

## IP-005: bekleme "iki gün sonra yine" der, tavan "bu yolculukta yeter" der.
func _test_max_per_journey(t) -> void:
	var event := _make_event("tavanli")
	event.max_per_journey = 2

	var engine := EventEngine.new(_pool([event]), 99)
	engine.mark_fired(event, 1)
	t.eq(engine.get_eligible_events(2, {}).size(), 1, "birinciden sonra hâlâ uygun")
	engine.mark_fired(event, 2)
	t.eq(engine.get_eligible_events(3, {}).size(), 0, "tavana varınca bu seferde bir daha çıkmaz")

	# Sayaç seferin kaydıyla birlikte taşınır: yarıda kaydedilip yüklenen bir
	# sefer tavanı sıfırlayıp sömürü kapısı açmasın.
	var ikinci := EventEngine.new(_pool([event]), 99)
	ikinci.load_from_dict(engine.to_dict())
	t.eq(ikinci.get_eligible_events(4, {}).size(), 0, "kayıttan dönünce tavan korunur")

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

## Avlanma girişimi ormanda/dağda çok daha olası - aynı desen (bkz.
## _test_highland_challenge_weight_follows_terrain), yeni context
## anahtarları için (bkz. EventResolver.biome_context).
func _test_hunting_trip_weight_follows_terrain(t) -> void:
	var events := EventCatalog.get_road_events()
	var hunt_event: GameEvent = null
	for event in events:
		if event.event_id == "evt_hunting_trip":
			hunt_event = event
			break
	t.ne(hunt_event, null, "evt_hunting_trip katalogda var")

	var away_weight := hunt_event.get_weight({"near_forest": 0.0, "near_mountain": 0.0})
	var forest_weight := hunt_event.get_weight({"near_forest": 1.0, "near_mountain": 0.0})
	var mountain_weight := hunt_event.get_weight({"near_forest": 0.0, "near_mountain": 1.0})
	t.ok(away_weight > 0.0, "ne ormanda ne dağdayken bile küçük bir şans kalır")
	t.ok(forest_weight > away_weight * 3.0, "ormandayken ağırlık kayda değer büyür")
	t.ok(mountain_weight > away_weight, "dağdayken de ağırlık büyür")
	t.ok(forest_weight > mountain_weight, "erkek geyik/geyik ormanda dağdan daha olası")

## Avlanma başarılı olunca "hunt" türünde gerçek bir savaş açmalı -
## EnemyCatalog.KIND_HUNT'ın deer/stag kadrosu, evt_wild_animal'ın
## "wildlife" açması gibi ama kendi türünden.
func _test_hunting_trip_hunt_option_opens_hunt_combat(t) -> void:
	var events := EventCatalog.get_road_events()
	var hunt_event: GameEvent = null
	for event in events:
		if event.event_id == "evt_hunting_trip":
			hunt_event = event
			break
	t.ne(hunt_event, null, "evt_hunting_trip katalogda var")

	var hunt_choice: EventChoice = null
	for choice in hunt_event.choices:
		if choice.text_key == "EVT_HUNTING_TRIP_OPT_HUNT":
			hunt_choice = choice
			break
	t.ne(hunt_choice, null, "avlanma seçeneği var")
	t.ne(hunt_choice.check, null, "avlanma bir skill-check'e bağlı")
	t.eq(hunt_choice.check.stat, CharacterStats.Kind.PERCEPTION, "check Sezgi'ye bağlı")

	var triggers_hunt_combat := false
	for outcome in hunt_choice.outcomes:
		for effect in outcome.effects:
			if effect.type == EventEffect.Type.TRIGGER_COMBAT and effect.text_value == EnemyCatalog.KIND_HUNT:
				triggers_hunt_combat = true
	t.ok(triggers_hunt_combat, "başarılı yaklaşma \"hunt\" türünde bir savaş açıyor")

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
	# Fidyenin tabanı: beş ağzın bir haftalık erzağı (kullanıcı kararı
	# 2026-11-07) - bkz. GameSession.RANSOM_FLOOR_GOLD.
	t.eq(int(low.effects[0].amount), -GameSession.RANSOM_FLOOR_GOLD, "düşük tehlikede fidye tabanda")
	t.eq(int(mid.effects[0].amount), -EventCatalog.AMBUSH_RANSOM_MID, "orta tehlikede fidye orta")
	t.eq(int(high.effects[0].amount), -EventCatalog.AMBUSH_RANSOM_HIGH, "yüksek tehlikede fidye en pahalı")
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

## A5 (bkz. akademik kaynak önerileri): aynı haber kartı, kervanın lideri
## hangi kültürdense ona göre farklı bir gövde anahtarına düşer - olayın
## mekanik etkisi (WORLD_EVENT_START'ın taşıdığı rota tehlikesi/fiyat
## şoku) bu seçime hiç bağlı değil, yalnızca çeviri anahtarı değişir.
func _test_news_events_frame_by_culture(t) -> void:
	var war_key := EventCatalog.get_culture_framed_text_key("evt_regional_war_news", CultureCatalog.NOMAD)
	t.eq(war_key, "EVT_WAR_NEWS_NOMAD_TEXT", "göçebe kendi çerçevesini alır")
	t.ne(
		EventCatalog.get_culture_framed_text_key("evt_regional_war_news", CultureCatalog.PORT),
		war_key,
		"iki farklı kültür iki farklı anahtar okur"
	)
	t.eq(
		EventCatalog.get_culture_framed_text_key("evt_bandit_ambush", CultureCatalog.NOMAD), "",
		"haber olmayan bir olayın kültür çerçevesi yok - çağıran event.text_key'e düşer"
	)
	t.eq(
		EventCatalog.get_culture_framed_text_key("evt_regional_war_news", "bilinmeyen_kultur"), "",
		"tanımsız bir kültürde de boş döner"
	)

	# Dört haber olayının hepsi, beş kültürün hepsi için gerçek bir çevirisi
	# olan bir anahtar taşımalı - CSV'de eksik bir satır burada yakalanır.
	var news_ids := [
		"evt_regional_war_news", "evt_plague_outbreak_news",
		"evt_trade_fair_news", "evt_bandit_tribute_zone_news",
	]
	var cultures := [
		CultureCatalog.NOMAD, CultureCatalog.VALLEY, CultureCatalog.HIGHLAND,
		CultureCatalog.PORT, CultureCatalog.FISHER,
	]
	for event_id in news_ids:
		for culture_id in cultures:
			var key: String = EventCatalog.get_culture_framed_text_key(event_id, culture_id)
			t.ok(not key.is_empty(), "%s / %s için bir anahtar var" % [event_id, culture_id])
			t.ne(tr(key), key, "%s çevirisi tanımlı" % key)

## Yol yönetmeni (görev Y-B02): sessizlik gerilimi biriktirir, ağır karttan
## sonra rahatlama gelir, zorlanan kervana ağır kart seyrekleşir, durum kayıtta.
func _test_road_director(t) -> void:
	var director := RoadDirector.new()
	director.begin_day(5)
	t.almost(director.chance_multiplier(), 1.0, "sessizlik yokken ihtimal nötr")
	director.note_quiet()
	director.note_quiet()
	director.note_quiet()
	t.ok(director.chance_multiplier() > 1.0, "üç sessiz gün ihtimali artırır")
	t.le(director.chance_multiplier(), RoadDirector.MAX_QUIET_BOOST, "artış tavanlı")
	var combat := EventCatalog.get_event("evt_bandit_ambush")
	var forage := EventCatalog.get_event("evt_forage")
	t.ok(combat != null and RoadDirector.is_heavy(combat), "savaş açan kart ağırdır")
	t.not_ok(RoadDirector.is_heavy(forage), "yol kenarı toplama hafiftir")
	director.note_card(combat, 5)
	t.eq(director.quiet_streak, 0, "kart sessizliği sıfırlar")
	director.begin_day(6)
	t.ok(director.weight_multiplier(combat, {}) < 1.0, "ağır kartın ertesi günü ağır kart seyrek")
	t.ok(director.chance_multiplier() < 1.0, "ertesi gün biraz sessiz")
	director.begin_day(9)
	t.almost(director.weight_multiplier(combat, {}), 1.0, "rahatlama bir gün sürer")
	t.ok(director.weight_multiplier(combat, {"hungry": 1.0}) < 1.0, "aç kervana ağır kart seyrek")
	t.ok(director.weight_multiplier(forage, {"stress": 80.0}) > 1.0, "zorlanan kervana hafif kart sık")
	var copy := RoadDirector.new()
	copy.load_from_dict(JSON.parse_string(JSON.stringify(director.to_dict())))
	t.eq(copy.last_heavy_day, 5, "yönetmen durumu kayıttan döner")
	var engine := EventEngine.new(EventCatalog.get_road_events(), 99)
	engine.director = RoadDirector.new()
	var restored := EventEngine.new(EventCatalog.get_road_events(), 99)
	restored.director = RoadDirector.new()
	engine.director.note_quiet()
	restored.load_from_dict(JSON.parse_string(JSON.stringify(engine.to_dict())))
	t.eq(restored.director.quiet_streak, 1, "motor kaydı yönetmeni taşır")

## Orta ve geç oyunun tehditleri (görev Y-C15): evre ilerledikçe tehdit
## kartlarının ağırlığı artar, diğerleri değişmez.
func _test_career_threats(t) -> void:
	for event_id in EventCatalog.CAREER_THREATS:
		var event := EventCatalog.get_event(String(event_id))
		t.ok(event != null, "%s katalogda" % event_id)
		var early := event.get_weight({"career_stage": 0.0})
		var mid := event.get_weight({"career_stage": 1.0})
		var late := event.get_weight({"career_stage": 2.0})
		t.ok(late > mid and mid > early, "%s evreyle sıklaşır" % event_id)
	var forage := EventCatalog.get_event("evt_forage")
	t.almost(forage.get_weight({"career_stage": 2.0}), forage.get_weight({"career_stage": 0.0}), "tehdit olmayan kart değişmez")
	var session := GameSession.new(0, 0)
	t.eq(session.get_career_stage(), 0, "taze kervan erken evrede")
	session.journeys_completed = GameSession.CAREER_LATE_JOURNEYS
	t.eq(session.get_career_stage(), 2, "uzun kariyer geç evrede")

# --- §D-A4: yankı çözücü (görev H9) ---

func _echo_session() -> GameSession:
	var session := GameSession.new(500, 40, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19
	session.start_playthrough(
		CharacterData.create("Lider", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	return session

## Teşhis A6: tekrar eden kart ilk cevabı bilmiyordu - aynı metin, aynı
## seçenekler. İkinci gelişte gövde değişmeli ve en az bir bedel kaymalı.
func _test_echo_changes_the_card_on_its_second_coming(t) -> void:
	var session := _echo_session()
	var event := EventCatalog.get_event("evt_bandit_ambush")
	t.ok(event != null, "kart katalogda")
	t.eq(session.echo_count(event.event_id), 0, "ilk gelişte yankı yok")
	var echo_key := EventCatalog.get_echo_line_key(event.event_id)
	t.ok(not echo_key.is_empty(), "kartın yankı cümlesi var")
	t.ne(tr(echo_key), echo_key, "yankı cümlesi çevrilmiş")

	var choice: EventChoice = event.choices[0]
	session.note_decision(event.event_id, choice.text_key)
	t.eq(session.echo_count(event.event_id), 1, "cevap yankı defterine yazıldı")
	t.eq(session.echo_choice(event.event_id), choice.text_key, "hangi cevap olduğu da")

	# Aynı cevap pahalı, öteki ucuz - ama ikisi de açık.
	t.eq(EventResolver._echo_scale(session, event, choice), GameSession.ECHO_REPEAT_COST,
		"aynı cevabın bedeli ağırlaşıyor")
	if event.choices.size() > 1:
		t.eq(EventResolver._echo_scale(session, event, event.choices[1]), GameSession.ECHO_OTHER_COST,
			"öteki cevabın bedeli hafifliyor")

## Görülmüş ama değişmiş kart yeni sayılır; üçüncü gelişten sonra seyreler.
func _test_echo_weight(t) -> void:
	var director := RoadDirector.new()
	var context := {"seen_cards": {"evt_bandit_ambush": true}, "recent_cards": [], "yankilar": {}}
	var plain: float = director.novelty_multiplier("evt_bandit_ambush", context)
	context["yankilar"] = {"evt_bandit_ambush": {"n": 1}}
	var echoed: float = director.novelty_multiplier("evt_bandit_ambush", context)
	t.ok(echoed > plain, "yankılı kart görülmüş karttan ağır")
	context["yankilar"] = {"evt_bandit_ambush": {"n": RoadDirector.ECHO_FADE_FROM}}
	t.eq(director.novelty_multiplier("evt_bandit_ambush", context), RoadDirector.ECHO_FADE_WEIGHT,
		"üçüncü gelişten sonra seyreliyor")

## Bedel ölçeklenirken sıfıra yuvarlanmıyor ve bayraklar ölçeklenmiyor.
func _test_echo_never_erases_a_cost(t) -> void:
	var cheap: Array[EventEffect] = [
		EventEffect.make(EventEffect.Type.GOLD, -1),
		EventEffect.make(EventEffect.Type.SET_FLAG, 0, "bayrak"),
	]
	var scaled := EventResolver._scaled(cheap, GameSession.ECHO_OTHER_COST)
	t.eq(scaled[0].amount, -1, "küçülen bedel kaybolmuyor")
	t.eq(scaled[1].type, EventEffect.Type.SET_FLAG, "bayrak ölçeklenmiyor")

## IP-003: dövüş garantisi dövüşü garanti eder, aynı pusuyu değil.
func _test_combat_guarantee_rotates_the_card(t) -> void:
	var director := RoadDirector.new()
	var fighter := _make_event("evt_dovusen")
	fighter.choices = _choices([
		EventChoice.make("OPT", _fx_list([EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0)])),
	])
	var quiet := _make_event("evt_sessiz")
	var context := {"combat_due": 1.0, "days_left": 1.0, "recent_cards": []}
	var fresh := director.combat_debt_multiplier(fighter, context)
	t.almost(fresh, RoadDirector.COMBAT_DUE_WEIGHT, "görülmemiş dövüş kartı garantiyi tam alır")
	context["recent_cards"] = ["evt_dovusen"]
	var repeat := director.combat_debt_multiplier(fighter, context)
	t.almost(repeat, RoadDirector.COMBAT_DUE_REPEAT_WEIGHT, "yakında görülen dövüş kartı kısılır")
	t.ok(repeat < fresh, "sıra görülmemiş olana geçer")
	t.ok(repeat > 0.0, "havuzda tek dövüş kartı kalsa bile yol kesilebilir")
	t.almost(director.combat_debt_multiplier(quiet, context), RoadDirector.COMBAT_DUE_OTHER_WEIGHT,
		"dövüşsüz kart garantiden pay almaz")

func _fx_list(items: Array) -> Array[EventEffect]:
	var typed: Array[EventEffect] = []
	for item in items:
		typed.append(item)
	return typed

func _choices(items: Array) -> Array[EventChoice]:
	var typed: Array[EventChoice] = []
	for item in items:
		typed.append(item)
	return typed
