extends RefCounted

## WorldEvents: ekleme/süre dolumu, rota/şehir eşleşmesi, rota tehlikesine
## eklenen pay, kayıt/yükleme gidiş-dönüşü ve GameSession'ın bunu
## get_route_danger()/build_event_context() üstünden nasıl okuduğu.

func suite_name() -> String:
	return "WorldEvents"

func run(t) -> void:
	_test_add_and_expire(t)
	_test_route_vs_city_matching(t)
	_test_route_danger_delta_stacks(t)
	_test_save_round_trip(t)
	_test_game_session_route_danger_reads_world_events(t)
	_test_event_context_flags(t)
	_test_commission_blocked_without_active_event(t)
	_test_commission_blocked_without_resources(t)
	_test_commission_fulfillment_war_supply(t)
	_test_commission_fulfillment_plague_relief(t)
	_test_commission_cannot_be_repeated_while_same_event_is_active(t)
	_test_commission_reopens_for_a_new_event_instance(t)

func _test_add_and_expire(t) -> void:
	var events := WorldEvents.new()
	events.add_event(WorldEvents.Kind.REGIONAL_WAR, "a|b", 10, 15)
	t.eq(events.get_active(10).size(), 1, "eklenen olay hemen aktif")
	t.eq(events.get_active(24).size(), 1, "süresi dolmadan hâlâ aktif")
	t.eq(events.get_active(26).size(), 0, "süresi dolunca artık aktif değil")

	events.advance_day(26)
	t.eq(events.get_active(10).size(), 0, "advance_day süresi dolanı gerçekten düşürür")

func _test_route_vs_city_matching(t) -> void:
	var events := WorldEvents.new()
	var route_key := RouteConditions.route_key("test_loc_a", "test_loc_b")
	events.add_event(WorldEvents.Kind.REGIONAL_WAR, route_key, 5, 20)
	events.add_event(WorldEvents.Kind.PLAGUE, "test_loc_c", 5, 20)

	t.ok(events.has_kind_on_route(WorldEvents.Kind.REGIONAL_WAR, route_key, 5), "rota olayı rotada bulunur")
	t.not_ok(events.has_kind_on_city(WorldEvents.Kind.REGIONAL_WAR, route_key, 5), "rota olayı şehir sorgusunda çıkmaz")
	t.ok(events.has_kind_on_city(WorldEvents.Kind.PLAGUE, "test_loc_c", 5), "şehir olayı şehirde bulunur")
	t.not_ok(events.has_kind_on_route(WorldEvents.Kind.PLAGUE, "test_loc_c", 5), "şehir olayı rota sorgusunda çıkmaz")
	t.not_ok(events.has_kind_on_city(WorldEvents.Kind.PLAGUE, "test_loc_d", 5), "başka bir şehirde bulunmaz")

func _test_route_danger_delta_stacks(t) -> void:
	var events := WorldEvents.new()
	var route_key := RouteConditions.route_key("test_loc_a", "test_loc_b")
	t.almost(events.get_route_danger_delta(route_key, 5), 0.0, "olay yokken pay sıfır")

	events.add_event(WorldEvents.Kind.REGIONAL_WAR, route_key, 5, 20)
	var war_only := events.get_route_danger_delta(route_key, 5)
	t.ok(war_only > 0.0, "savaş rota tehlikesine pozitif bir pay ekler")

	events.add_event(WorldEvents.Kind.BANDIT_TRIBUTE, route_key, 5, 20)
	var stacked := events.get_route_danger_delta(route_key, 5)
	t.ok(stacked > war_only, "iki olay aynı rotada payları toplar")

func _test_save_round_trip(t) -> void:
	var events := WorldEvents.new()
	var route_key := RouteConditions.route_key("test_loc_a", "test_loc_b")
	events.add_event(WorldEvents.Kind.BANDIT_TRIBUTE, route_key, 3, 12)
	events.add_event(WorldEvents.Kind.TRADE_FAIR, "test_loc_c", 3, 10)

	var restored := WorldEvents.new()
	restored.load_from_dict(events.to_save_dict())

	t.eq(restored.get_active(3).size(), 2, "iki olay da korunur")
	t.ok(
		restored.has_kind_on_route(WorldEvents.Kind.BANDIT_TRIBUTE, route_key, 3),
		"rota olayı gidiş-dönüşten sonra da doğru okunur"
	)
	t.ok(
		restored.has_kind_on_city(WorldEvents.Kind.TRADE_FAIR, "test_loc_c", 3),
		"şehir olayı gidiş-dönüşten sonra da doğru okunur"
	)

func _test_game_session_route_danger_reads_world_events(t) -> void:
	var session := GameSession.new(100, 20, 1)
	var route := WorldMapData.get_routes_from(WorldMapData.START_LOCATION_ID)[0]
	var base_danger := session.get_route_danger(route)

	var route_key := RouteConditions.route_key(route.from_location_id, route.to_location_id)
	session.world_events.add_event(WorldEvents.Kind.REGIONAL_WAR, route_key, 0, 20)
	var with_war := session.get_route_danger(route)

	t.ok(with_war > base_danger, "aktif bir bölgesel savaş rota tehlikesini artırır")

func _test_event_context_flags(t) -> void:
	var session := GameSession.new(100, 20, 1)
	session.journey_origin_id = "test_loc_a"
	session.journey_destination_id = "test_loc_b"

	var context := session.build_event_context()
	t.eq(context.get("route_has_regional_war"), 0.0, "olay yokken bayrak sıfır")
	t.eq(context.get("destination_has_plague"), 0.0, "olay yokken bayrak sıfır")

	var route_key := RouteConditions.route_key("test_loc_a", "test_loc_b")
	session.world_events.add_event(WorldEvents.Kind.BANDIT_TRIBUTE, route_key, 0, 20)
	session.world_events.add_event(WorldEvents.Kind.PLAGUE, "test_loc_b", 0, 20)

	var updated_context := session.build_event_context()
	t.eq(updated_context.get("route_has_bandit_tribute"), 1.0, "aktif haraç bayrağa yansır")
	t.eq(updated_context.get("destination_has_plague"), 1.0, "aktif veba bayrağa yansır")
	t.eq(updated_context.get("route_has_regional_war"), 0.0, "ilgisiz tür etkilenmez")

## Faz 17: lonca özel görevleri - dört görevin hepsi WorldEvents.get_active_by_kind
## üstünden harita çapında (kervanın o an nerede olduğuna bakmadan) okunuyor.
func _test_commission_blocked_without_active_event(t) -> void:
	var session := GameSession.new(500, 50, 1)
	t.not_ok(
		session.get_commission_block_reason(WorldEvents.Kind.REGIONAL_WAR).is_empty(),
		"aktif savaş yokken görev kilitli"
	)
	t.not_ok(session.fulfill_commission(WorldEvents.Kind.REGIONAL_WAR), "kilitliyken tamamlanamaz")

func _test_commission_blocked_without_resources(t) -> void:
	var session := GameSession.new(500, 5, 1)
	session.world_events.add_event(WorldEvents.Kind.REGIONAL_WAR, "test_loc_a|test_loc_b", 0, 20)
	t.eq(
		session.get_commission_block_reason(WorldEvents.Kind.REGIONAL_WAR),
		"UI_COMMISSION_NEED_PROVISIONS",
		"olay aktif ama erzak yetersizken doğru sebep döner"
	)
	t.not_ok(session.fulfill_commission(WorldEvents.Kind.REGIONAL_WAR), "kaynak yetersizken tamamlanamaz")

func _test_commission_fulfillment_war_supply(t) -> void:
	var session := GameSession.new(500, 50, 1)
	session.world_events.add_event(WorldEvents.Kind.REGIONAL_WAR, "test_loc_a|test_loc_b", 0, 20)
	var before_gold := session.wallet.balance
	var before_reputation := session.reputation
	var before_provisions := session.get_provisions()

	t.ok(session.fulfill_commission(WorldEvents.Kind.REGIONAL_WAR), "koşullar tamamsa görev başarılı")
	t.eq(
		session.get_provisions(), before_provisions - GameSession.COMMISSION_WAR_SUPPLY_PROVISIONS,
		"erzak tam olarak talep edilen kadar düşer"
	)
	t.eq(
		session.wallet.balance, before_gold + GameSession.COMMISSION_WAR_SUPPLY_REWARD_GOLD,
		"altın ödülü eklenir"
	)
	t.eq(
		session.reputation, before_reputation + GameSession.COMMISSION_WAR_SUPPLY_REWARD_REPUTATION,
		"itibar ödülü eklenir"
	)

func _test_commission_fulfillment_plague_relief(t) -> void:
	var session := GameSession.new(500, 50, 1)
	session.world_events.add_event(WorldEvents.Kind.PLAGUE, "test_loc_b", 0, 20)
	t.not_ok(
		session.get_commission_block_reason(WorldEvents.Kind.PLAGUE).is_empty(),
		"iksir yokken görev kilitli"
	)

	var potion := ItemCatalog.get_item(GameSession.COMMISSION_PLAGUE_ITEM_ID)
	session.add_to_cargo(potion, GameSession.COMMISSION_PLAGUE_ITEM_COUNT)
	t.ok(session.get_commission_block_reason(WorldEvents.Kind.PLAGUE).is_empty(), "iksir eklenince görev açılır")

	var before_gold := session.wallet.balance
	t.ok(session.fulfill_commission(WorldEvents.Kind.PLAGUE), "koşullar tamamsa görev başarılı")
	t.eq(
		session.get_total_quantity(GameSession.COMMISSION_PLAGUE_ITEM_ID), 0,
		"iksirler tüketilir"
	)
	t.eq(
		session.wallet.balance, before_gold + GameSession.COMMISSION_PLAGUE_REWARD_GOLD,
		"altın ödülü eklenir"
	)

## Faz 17 PR-8: ölçüm sırasında bulunan gerçek bir sömürü - `fulfill_commission`
## hiçbir tekrar koruması taşımıyordu, yani aynı Ticaret Fuarı (80 harcayıp
## 140 kazandıran) olayı açık kaldığı 8-30 gün boyunca sınırsızca
## tekrarlanabiliyordu. Bir haber, bir katkı: aynı olay örneği (aynı
## started_day) sürerken ikinci bir tamamlama parayı/itibarı değiştirmemeli.
func _test_commission_cannot_be_repeated_while_same_event_is_active(t) -> void:
	var session := GameSession.new(500, 50, 1)
	session.world_events.add_event(WorldEvents.Kind.TRADE_FAIR, "test_loc_a", 0, 20)

	t.ok(session.fulfill_commission(WorldEvents.Kind.TRADE_FAIR), "ilk katkı başarılı")
	var gold_after_first := session.wallet.balance
	var reputation_after_first := session.reputation

	t.eq(
		session.get_commission_block_reason(WorldEvents.Kind.TRADE_FAIR),
		"UI_COMMISSION_ALREADY_FULFILLED",
		"aynı olay sürerken ikinci katkı kilitli"
	)
	t.not_ok(
		session.fulfill_commission(WorldEvents.Kind.TRADE_FAIR),
		"aynı olay örneği sürerken ikinci kez tamamlanamaz"
	)
	t.eq(session.wallet.balance, gold_after_first, "ikinci denemede altın değişmez")
	t.eq(session.reputation, reputation_after_first, "ikinci denemede itibar değişmez")

## Süresi dolup **yeni** bir haber gelince (farklı started_day) görev
## tekrar açılmalı - kapatılan yalnızca "aynı haberi tekrar tekrar sağma",
## dünyanın bir daha hiç aynı türden olay yaşamaması değil.
func _test_commission_reopens_for_a_new_event_instance(t) -> void:
	var session := GameSession.new(500, 50, 1)
	session.world_events.add_event(WorldEvents.Kind.BANDIT_TRIBUTE, "test_loc_a", 0, 8)
	t.ok(session.fulfill_commission(WorldEvents.Kind.BANDIT_TRIBUTE), "ilk katkı başarılı")

	session.total_days_elapsed = 9
	session.world_events.advance_day(9)
	t.not_ok(
		session.has_active_world_event(WorldEvents.Kind.BANDIT_TRIBUTE),
		"eski olay süresi dolunca düşer"
	)

	session.world_events.add_event(WorldEvents.Kind.BANDIT_TRIBUTE, "test_loc_b", 9, 8)
	t.ok(
		session.get_commission_block_reason(WorldEvents.Kind.BANDIT_TRIBUTE).is_empty(),
		"yeni bir olay örneği görevi tekrar açar"
	)
	var reputation_before_second := session.reputation
	t.ok(
		session.fulfill_commission(WorldEvents.Kind.BANDIT_TRIBUTE),
		"yeni olay örneğinde ikinci katkı da başarılı"
	)
	t.eq(
		session.reputation,
		reputation_before_second + GameSession.COMMISSION_TRIBUTE_REWARD_REPUTATION,
		"yeni örnekteki katkı da ödülünü verir"
	)
