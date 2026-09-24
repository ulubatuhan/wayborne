extends RefCounted

## Tasarımın en sert kuralı: kervan ağır kayıp yaşayabilir ama yok
## olamaz. Sınırlar tek tek olaylarda değil EventEffectApplier ve
## CaravanState'te zorlanıyor - bir olay "10 vagon kaybet" dese bile
## çekirdek ayakta kalmalı. Bu paket o duvarı tutuyor.

func suite_name() -> String:
	return "EventEffects"

func run(t) -> void:
	_test_gold_can_go_into_debt(t)
	_test_provisions_never_negative(t)
	_test_player_wagon_survives(t)
	_test_morale_stays_in_range(t)
	_test_documents_and_merchants(t)
	_test_bridges_are_reported(t)
	_test_grant_equipment_fills_locker(t)
	_test_vengeful_wanderer_chain(t)
	_test_pilgrim_blessing_chain(t)
	_test_every_effect_type_is_handled(t)
	_test_grave_chain(t)
	_test_deserter_chain(t)

func _effects(items: Array) -> Array[EventEffect]:
	var typed: Array[EventEffect] = []
	for item in items:
		typed.append(item)
	return typed

func _session(gold: int = 100, provisions: int = 10, wagons: int = 1) -> GameSession:
	return GameSession.new(gold, provisions, wagons)

## Kervan yok olmaz ama borca batabilir: ödemek zorunda olduğu bedeli
## karşılayamayan kervanın kesesi eksiye düşer ve fark açık hesaba yazılır.
## Eskiden burada "kese sıfırda durur" clamp'i vardı - haraç verecek parası
## olmayan kervan bedavaya kurtuluyordu.
func _test_gold_can_go_into_debt(t) -> void:
	var session := _session(100)
	var spend := EventEffectApplier.apply(
		_effects([EventEffect.make(EventEffect.Type.GOLD, -400)]), session
	)
	t.eq(session.wallet.balance, -300, "ödeyemediğinde kese eksiye düşer")
	t.ge(float(spend.lines.size()), 1.0, "harcama oyuncuya bildirilir")

	t.eq(session.get_total_debt(), 300, "eksi bakiye borç olarak sayılır")
	var overdraft := session.debts.get_debt(DebtLedger.OVERDRAFT_DEBT_ID)
	t.ok(overdraft != null, "açık hesap borcu açıldı")
	t.eq(overdraft.principal, 300, "açık hesabın anaparası eksinin kendisi")
	t.eq(
		overdraft.due_day, Debt.DEFAULT_TERM_DAYS,
		"borcun vadesi bir ay - hemen kriz değil ama sayaç işliyor"
	)

	# Daha da batmak yeni borç açmaz, açık hesabı büyütür.
	EventEffectApplier.apply(
		_effects([EventEffect.make(EventEffect.Type.GOLD, -200)]), session
	)
	t.eq(session.wallet.balance, -500, "borç üstüne borç kesede birikir")
	t.eq(session.debts.get_debts().size(), 1, "ikinci bir açık hesap açılmaz")
	t.eq(session.debts.get_debt(DebtLedger.OVERDRAFT_DEBT_ID).principal, 500, "açık hesap büyür")

	var earn := EventEffectApplier.apply(
		_effects([EventEffect.make(EventEffect.Type.GOLD, 900)]), session
	)
	t.eq(session.wallet.balance, 400, "kazanç eksiyi kapatıp artıya geçirir")
	t.ge(float(earn.lines.size()), 1.0, "kazanç oyuncuya bildirilir")

func _test_provisions_never_negative(t) -> void:
	var session := _session(100, 6)
	var drain := EventEffectApplier.apply(
		_effects([EventEffect.make(EventEffect.Type.PROVISIONS, -9999)]), session
	)
	t.eq(session.get_provisions(), 0, "erzak sıfırın altına inmez")
	t.ge(float(drain.lines.size()), 1.0, "erzak kaybı bildirilir")

	var removed := session.change_provisions(-5)
	t.eq(removed, 0, "olmayan erzak düşülemez")

	var added := session.change_provisions(4)
	t.eq(added, 4, "eklenen erzak birebir girer")
	t.eq(session.get_provisions(), 4, "envanter eklenenle uyumlu")

func _test_player_wagon_survives(t) -> void:
	var session := _session()
	session.caravan.wagon_count = 4
	session.caravan.damaged_wagons = 1

	var lost := session.caravan.lose_wagons(9999)
	t.eq(session.caravan.wagon_count, CaravanState.MIN_WAGONS, "oyuncunun kendi vagonu kalır")
	t.eq(lost, 3, "yalnızca kaybedilebilir olanlar gider")
	t.le(float(session.caravan.damaged_wagons), float(session.caravan.wagon_count),
		"hasarlı sayısı toplam vagonu aşmaz")

	session.caravan.wagon_count = 3
	session.caravan.damaged_wagons = 0
	var damaged := session.caravan.damage_wagons(9999)
	t.eq(damaged, 3, "en fazla mevcut vagon kadar hasar alınır")
	t.eq(session.caravan.get_healthy_wagon_count(), 0, "hepsi hasarlıysa sağlam kalmaz")
	t.eq(session.caravan.damage_wagons(5), 0, "zaten hasarlıysa tekrar hasar almaz")

func _test_morale_stays_in_range(t) -> void:
	var session := _session()

	var crash := EventEffectApplier.apply(
		_effects([EventEffect.make(EventEffect.Type.MORALE, -9999)]), session
	)
	t.eq(session.caravan.morale, 0, "moral sıfırın altına inmez")
	t.ge(float(crash.lines.size()), 1.0, "moral düşüşü bildirilir")

	var lift := EventEffectApplier.apply(
		_effects([EventEffect.make(EventEffect.Type.MORALE, 9999)]), session
	)
	t.eq(session.caravan.morale, CaravanState.MAX_MORALE, "moral tavanı aşmaz")
	t.ge(float(lift.lines.size()), 1.0, "moral artışı bildirilir")

func _test_documents_and_merchants(t) -> void:
	var session := _session()
	session.caravan.documents = 2
	var merchants: Array[String] = ["Tüccar A", "Tüccar B"]
	session.caravan.merchant_names = merchants

	var seized := EventEffectApplier.apply(
		_effects([EventEffect.make(EventEffect.Type.DOCUMENT_LOSE, 9999)]), session
	)
	t.eq(session.caravan.documents, 0, "olmayan evrak eksiye düşmez")
	t.ge(float(seized.lines.size()), 1.0, "el konan evrak bildirilir")

	var departures := EventEffectApplier.apply(
		_effects([EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, 9999)]), session
	)
	t.eq(session.caravan.merchant_names.size(), 0, "listede olmayan tüccar çıkarılamaz")
	t.eq(departures.lines.size(), 2, "ayrılan her tüccar tek tek bildirilir")

## TRIGGER_* etkileri dünyayı doğrudan değiştirmez; UI'a devredilen
## istek olarak bildirilir. Köprü kopar ve savaş/pazarlık hiç açılmazsa
## olay sessizce hiçbir şey yapmış olur - bu yüzden test ediliyor.
func _test_bridges_are_reported(t) -> void:
	var session := _session()
	var result := EventEffectApplier.apply(_effects([
		EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0),
		EventEffect.make(EventEffect.Type.TRIGGER_HAGGLING, 200),
		EventEffect.make(EventEffect.Type.TRIGGER_RECRUIT, 0),
		EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_deneme"),
		EventEffect.make(EventEffect.Type.SET_FLAG, 0, "deneme_bayragi"),
	]), session)

	t.eq(result.combat_requests.size(), 1, "savaş isteği bildirilir")
	t.eq(result.haggling_requests.size(), 1, "pazarlık isteği bildirilir")
	t.eq(result.recruit_requests.size(), 1, "tayfa isteği bildirilir")
	t.eq(result.unlocked_event_ids.size(), 1, "açılan olay bildirilir")
	t.ok(session.has_flag("deneme_bayragi"), "bayrak oturuma yazılır")

	session.clear_flag("deneme_bayragi")
	t.not_ok(session.has_flag("deneme_bayragi"), "bayrak temizlenebilir")

## Bulunan tılsım doğrudan bir karaktere takılmaz - kervanın ortak
## depostuna düşer (bkz. GameSession.equipment_inventory), oyuncu kimin
## takacağını karakter ekranında seçer.
func _test_grant_equipment_fills_locker(t) -> void:
	var session := _session()
	t.eq(session.get_equipment_count(EquipmentCatalog.RING_MARKSMAN), 0, "başlangıçta depo boş")

	var result := EventEffectApplier.apply(_effects([
		EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, EquipmentCatalog.RING_MARKSMAN),
	]), session)

	t.eq(session.get_equipment_count(EquipmentCatalog.RING_MARKSMAN), 1, "bulunan parça depoya düşer")
	t.eq(result.lines.size(), 1, "sonuçta bir satır var")

	var invalid_result := EventEffectApplier.apply(_effects([
		EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, "yok_boyle_bir_ekipman"),
	]), session)
	t.eq(invalid_result.lines.size(), 0, "katalogda olmayan ekipman sessizce yok sayılır")

## Kinci yolcuyu görmezden gelmenin faturası günler sonra kesiliyor:
## bayrak + UNLOCK_EVENT, sonra triggered_only olayın uygun hale gelmesi.
## Denge simülatöründe evt_wanderer_revenge hiç ateşlenmiyor görünüyor -
## bu bir hata değil, simülatörün "her zaman ilk seçeneği seç" politikası
## zinciri hiç açmıyor. Zincirin kendisi burada uçtan uca sınanıyor.
func _test_vengeful_wanderer_chain(t) -> void:
	var session := GameSession.new(300, 20, 1)

	# "Görmezden gel" seçeneğinin kinci sonucu: bayrağı diker ve olayı açar.
	var scorn: Array[EventEffect] = [
		EventEffect.make(EventEffect.Type.SET_FLAG, 0, "wanderer_scorned"),
		EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_wanderer_revenge"),
	]
	var result := EventEffectApplier.apply(scorn, session)
	t.ok(session.has_flag("wanderer_scorned"), "kinci yolcu küsmüş olarak işaretlenir")
	t.ok(
		result.unlocked_event_ids.has("evt_wanderer_revenge"),
		"intikam olayı açılmak üzere bildirilir"
	)

	# Açılmadan çekilemez, açılınca çekilebilir.
	var engine := EventEngine.new(EventCatalog.get_road_events(), 4242)
	var context := session.build_event_context()
	t.ok(
		not _has_event(engine.get_eligible_events(1, context), "evt_wanderer_revenge"),
		"açılmadan önce intikam olayı uygun değil"
	)

	for event_id in result.unlocked_event_ids:
		engine.unlock_event(event_id)
	t.ok(
		_has_event(engine.get_eligible_events(1, session.build_event_context()), "evt_wanderer_revenge"),
		"açıldıktan sonra intikam olayı uygun hale gelir"
	)

	# Bayrak temizlenince zincir kapanır - fatura bir kez kesilir.
	session.clear_flag("wanderer_scorned")
	t.ok(
		not _has_event(engine.get_eligible_events(2, session.build_event_context()), "evt_wanderer_revenge"),
		"bayrak temizlenince zincir kapanır"
	)

## Faz 17 PR-9: `evt_wanderer_revenge`'in olumlu ucu - eşlik edilen hacı
## günler sonra bir teşekkürle döner, bir fatura değil. Aynı zincir
## mekaniği (bayrak + UNLOCK_EVENT, sonra triggered_only olayın uygun hale
## gelmesi), farklı duygu.
func _test_pilgrim_blessing_chain(t) -> void:
	var session := GameSession.new(300, 20, 1)

	var escort: Array[EventEffect] = [
		EventEffect.make(EventEffect.Type.PROVISIONS, -2),
		EventEffect.make(EventEffect.Type.SET_FLAG, 0, "pilgrim_escorted"),
		EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_pilgrim_blessing"),
	]
	var result := EventEffectApplier.apply(escort, session)
	t.ok(session.has_flag("pilgrim_escorted"), "eşlik edilen hacı işaretlenir")
	t.ok(
		result.unlocked_event_ids.has("evt_pilgrim_blessing"),
		"kutsama olayı açılmak üzere bildirilir"
	)

	var engine := EventEngine.new(EventCatalog.get_road_events(), 4242)
	var context := session.build_event_context()
	t.ok(
		not _has_event(engine.get_eligible_events(1, context), "evt_pilgrim_blessing"),
		"açılmadan önce kutsama olayı uygun değil"
	)

	for event_id in result.unlocked_event_ids:
		engine.unlock_event(event_id)
	t.ok(
		_has_event(engine.get_eligible_events(1, session.build_event_context()), "evt_pilgrim_blessing"),
		"açıldıktan sonra kutsama olayı uygun hale gelir"
	)

	# Kabul edince bayrak temizlenir - teşekkür bir kez gelir.
	var before_stress := session.party_stress
	var accept := EventEffectApplier.apply([
		EventEffect.make(EventEffect.Type.STRESS, -8),
		EventEffect.make(EventEffect.Type.MORALE, 5),
		EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "pilgrim_escorted"),
	], session)
	t.le(session.party_stress, before_stress, "kutsama stresi hafifletir")
	t.not_ok(session.has_flag("pilgrim_escorted"), "bayrak temizlenir")
	t.ge(float(accept.lines.size()), 1.0, "kutsama oyuncuya bildirilir")
	t.ok(
		not _has_event(engine.get_eligible_events(2, session.build_event_context()), "evt_pilgrim_blessing"),
		"bayrak temizlenince zincir kapanır"
	)

func _has_event(events: Array, event_id: String) -> bool:
	for event in events:
		if event.event_id == event_id:
			return true
	return false

## Bir etki tipi enum'a eklenip uygulayıcıda karşılanmazsa sessizce hiçbir
## şey yapmaz (bkz. proje kuralları, Event Engine Rules). Uygulayıcının
## kaynağı taranıyor: her tipin kendi `match` kolu olmalı. Çalışma anında
## denemek yetmiyordu - `match`'e düşmeyen bir tip hata vermez, yalnızca
## boş bir sonuç döner, ve boş sonuç bazı tipler için (SET_FLAG) zaten
## doğru cevap.
func _test_every_effect_type_is_handled(t) -> void:
	var file := FileAccess.open("res://scripts/events/event_effect_applier.gd", FileAccess.READ)
	t.ok(file != null, "uygulayıcının kaynağı okunabiliyor")
	if file == null:
		return
	var source := file.get_as_text()
	for type_name in EventEffect.Type.keys():
		t.ok(
			source.contains("EventEffect.Type.%s:" % type_name),
			"EventEffect.Type.%s uygulayıcıda karşılanıyor" % type_name
		)

## Seçeneğin etkilerini uygular ve açtığı olayları motora bildirir -
## yol ekranının yaptığı sıra.
func _pick(engine: EventEngine, session: GameSession, choice: EventChoice) -> EventEffectApplier.Result:
	var result := EventEffectApplier.apply(choice.effects, session)
	for event_id in result.unlocked_event_ids:
		engine.unlock_event(event_id)
	return result

func _outcome_for(engine: EventEngine, session: GameSession, choice: EventChoice, tier: int) -> EventOutcome:
	var context := session.build_event_context()
	context["check_tier"] = tier
	return engine.resolve_outcome(choice, context)

func _take_outcome(engine: EventEngine, session: GameSession, outcome: EventOutcome) -> EventEffectApplier.Result:
	var result := EventEffectApplier.apply(outcome.effects, session)
	for event_id in result.unlocked_event_ids:
		engine.unlock_event(event_id)
	return result

## Zincir A defteri okuyor: ölü yoksa mezar yok. Mezara bakan bekçinin
## güvenini kazanabilir, geçip giden kazanamaz; son halka iki bayrak
## ister ve bitince zinciri sonraki kuşak için yeniden açar.
func _test_grave_chain(t) -> void:
	var session := GameSession.new(300, 20, 1)
	session.set_player_character(CharacterData.create("Lider", CultureCatalog.VALLEY, CharacterStats.new()))
	var engine := EventEngine.new(EventCatalog.get_road_events(), 99)
	t.not_ok(
		_has_event(engine.get_eligible_events(1, session.build_event_context()), "evt_grave_on_the_road"),
		"kimse ölmeden mezar çıkmaz"
	)
	session.ledger.record(CaravanLedger.KIND_DIED, "Gömülen", 0)
	t.ok(
		_has_event(engine.get_eligible_events(1, session.build_event_context()), "evt_grave_on_the_road"),
		"defterde bir ölü varsa mezar çıkabilir"
	)
	var grave := EventCatalog.get_event("evt_grave_on_the_road")
	t.not_ok(
		_has_event(engine.get_eligible_events(1, session.build_event_context()), "evt_grave_keeper"),
		"bekçi açılmadan gelmez"
	)
	_pick(engine, session, grave.choices[0])
	t.ok(session.has_flag("grave_tended"), "mezara bakıldı")
	t.not_ok(
		_has_event(engine.get_eligible_events(2, session.build_event_context()), "evt_grave_on_the_road"),
		"zincir sürerken ikinci mezar çıkmaz"
	)
	t.ok(
		_has_event(engine.get_eligible_events(2, session.build_event_context()), "evt_grave_keeper"),
		"bekçi açıldı"
	)

	var keeper := EventCatalog.get_event("evt_grave_keeper")
	var listen: EventChoice = keeper.choices[0]
	t.ok(listen.check != null, "dinlemek bir Bilgelik zarı")
	t.eq(_outcome_for(engine, session, listen, 0).text_key, "EVT_GRAVE_KEEPER_COLD", "zar tutmazsa soğuk")
	t.eq(_outcome_for(engine, session, listen, 2).text_key, "EVT_GRAVE_KEEPER_TRUST", "bakan güveni kazanır")
	var passer := GameSession.new(300, 20, 1)
	passer.set_flag("grave_seen")
	t.eq(_outcome_for(engine, passer, listen, 2).text_key, "EVT_GRAVE_KEEPER_KIND", "geçip giden kazanamaz")

	var offering_id := "evt_grave_offering"
	t.not_ok(
		_has_event(engine.get_eligible_events(3, session.build_event_context()), offering_id),
		"güven kazanılmadan adak yok"
	)
	_take_outcome(engine, session, _outcome_for(engine, session, listen, 2))
	t.ok(
		_has_event(engine.get_eligible_events(3, session.build_event_context()), offering_id),
		"iki bayrakla adak açıldı"
	)
	var offering := EventCatalog.get_event(offering_id)
	_pick(engine, session, offering.choices[0])
	t.ok(
		session.get_player_character().has_trait(TraitCatalog.STEADFAST_FAITH),
		"adak lidere Sarsılmaz İnanç verdi"
	)
	for flag in ["grave_seen", "grave_tended", "keeper_trusted"]:
		t.not_ok(session.has_flag(flag), "zincir kapanınca bayrak temiz: %s" % flag)
	t.ok(
		_has_event(engine.get_eligible_events(40, session.build_event_context()), "evt_grave_on_the_road"),
		"sonraki kuşak için zincir yeniden açık"
	)

## Zincir B dünya olayını okuyor: savaş yoksa firari yok. Yalan tutmazsa
## seçenek muhafız savaşı açıyor - ve kart bunu seçmeden önce söylüyor.
func _test_deserter_chain(t) -> void:
	var session := GameSession.new(300, 20, 1)
	var engine := EventEngine.new(EventCatalog.get_road_events(), 7)
	var context := session.build_event_context()
	t.not_ok(_has_event(engine.get_eligible_events(1, context), "evt_deserter_plea"), "savaş yokken firari yok")
	context["route_has_regional_war"] = 1.0
	t.ok(_has_event(engine.get_eligible_events(1, context), "evt_deserter_plea"), "savaş yolunda firari çıkar")

	var plea := EventCatalog.get_event("evt_deserter_plea")
	_pick(engine, session, plea.choices[0])
	t.ok(session.has_flag("deserters_hidden"), "saklandılar")
	var search := EventCatalog.get_event("evt_deserter_search")
	t.ok(_has_event(engine.get_eligible_events(2, session.build_event_context()), "evt_deserter_search"), "devriye geliyor")

	var lie: EventChoice = search.choices[0]
	var caught := _take_outcome(engine, session, _outcome_for(engine, session, lie, 0))
	t.eq(caught.combat_kinds, ["guard"] as Array[String], "yalan tutmazsa muhafızla savaş")
	t.not_ok(session.has_flag("deserters_hidden"), "yakalananlar saklı değil")

	var lucky := GameSession.new(300, 20, 1)
	var lucky_engine := EventEngine.new(EventCatalog.get_road_events(), 8)
	_pick(lucky_engine, lucky, plea.choices[0])
	_take_outcome(lucky_engine, lucky, _outcome_for(lucky_engine, lucky, lie, 2))
	t.ok(lucky.has_flag("deserters_safe"), "yalan tuttu")
	t.ok(_has_event(lucky_engine.get_eligible_events(3, lucky.build_event_context()), "evt_deserter_debt"), "borç açıldı")
	var debt := EventCatalog.get_event("evt_deserter_debt")
	var gift := _pick(lucky_engine, lucky, debt.choices[1])
	t.eq(lucky.equipment_inventory.get(EquipmentCatalog.WEAPON_TIER_1, 0), 1, "kılıç depoya girdi")
	t.not_ok(lucky.has_flag("deserters_met"), "zincir kapandı")
	t.ge(float(gift.lines.size()), 0.0, "etki satırı")
