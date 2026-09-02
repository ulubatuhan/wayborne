extends RefCounted

## Tasarımın en sert kuralı: kervan ağır kayıp yaşayabilir ama yok
## olamaz. Sınırlar tek tek olaylarda değil EventEffectApplier ve
## CaravanState'te zorlanıyor - bir olay "10 vagon kaybet" dese bile
## çekirdek ayakta kalmalı. Bu paket o duvarı tutuyor.

func suite_name() -> String:
	return "EventEffects"

func run(t) -> void:
	_test_gold_never_negative(t)
	_test_provisions_never_negative(t)
	_test_player_wagon_survives(t)
	_test_morale_stays_in_range(t)
	_test_documents_and_merchants(t)
	_test_bridges_are_reported(t)

func _effects(items: Array) -> Array[EventEffect]:
	var typed: Array[EventEffect] = []
	for item in items:
		typed.append(item)
	return typed

func _session(gold: int = 100, provisions: int = 10, wagons: int = 1) -> GameSession:
	return GameSession.new(gold, provisions, wagons)

func _test_gold_never_negative(t) -> void:
	var session := _session(100)
	var spend := EventEffectApplier.apply(
		_effects([EventEffect.make(EventEffect.Type.GOLD, -9999)]), session
	)
	t.eq(session.wallet.balance, 0, "ödeyemediğinde borca girmez, kese boşalır")
	t.ge(float(spend.lines.size()), 1.0, "harcama oyuncuya bildirilir")

	var earn := EventEffectApplier.apply(
		_effects([EventEffect.make(EventEffect.Type.GOLD, 250)]), session
	)
	t.eq(session.wallet.balance, 250, "kazanç normal işler")
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
