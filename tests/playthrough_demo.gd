extends SceneTree

## Uçtan uca playthrough doğrulaması. Test değil - hiç kırmızı dönmez,
## okunabilir bir seyir günlüğü basar (bkz. simulate_journeys.gd ile aynı
## ayrım). Amacı: sahneyi açmadan, oyunun tam döngüsünün gerçekten
## dönüp dönmediğini görmek.
##
## Yol ekranının _process döngüsünü burada taklit ediyoruz: aynı
## JourneyClock ile aynı sırada (saat ilerlet -> dolan günleri işle),
## böylece ekranın yaptığı iş ile burada doğrulanan iş aynı kalıyor.
##
## Koşum:
##   godot --headless --script res://tests/playthrough_demo.gd

const LEGS: int = 4
const SEED_VALUE: int = 20260908

## Yol ekranı 60 FPS'te ~0.016 sn'lik delta ile besliyor; burada aynı
## ölçekte besleyip saatin gerçekten aynı şekilde aktığını görüyoruz.
const FRAME_DELTA: float = 1.0 / 60.0
const MAX_FRAMES_PER_LEG: int = 200000

var _rng := RandomNumberGenerator.new()

func _initialize() -> void:
	TranslationServer.set_locale("tr")
	_rng.seed = SEED_VALUE

	var session := GameSession.new(250, 20, 1)
	var hero := CharacterData.create(
		"Deneme Kervancısı", CultureCatalog.VALLEY, CharacterStats.new()
	)
	session.start_playthrough(hero, _rng)

	print("══ WAYBORNE PLAYTHROUGH ══")
	_print_start(session)

	for leg in range(LEGS):
		if not _run_leg(session, leg + 1):
			break

	print("")
	print("══ SONUÇ ══")
	print("  Gün: %d · Kese: %d GG · İtibar: %d · Vagon: %d · Stres: %d" % [
		session.total_days_elapsed, session.wallet.balance,
		session.reputation, session.owned_wagon_count, session.party_stress
	])
	print("  Parti: %s" % _party_line(session))
	print("  Envanter: %s" % _inventory_line(session))
	print("  Kampanya: %s" % _campaign_line(session))
	quit()

## Hikâye gerçekten ilerliyor mu? Bölüm katalogda durup hiç kapanmıyorsa
## bunu ancak burada, tam turu koşturan yerde görürüz (bkz. evt_mutiny'nin
## "katalogda var, oyunda yok" hikâyesi).
func _campaign_line(session: GameSession) -> String:
	var chapter := session.get_current_chapter()
	if chapter == null:
		return "hikâye tamamlandı - serbest ticaret"
	return "bölüm %d/%d (%s) · sefer %d · teslimat %d · şehir %d" % [
		session.campaign_chapter_index + 1,
		CampaignCatalog.chapter_count(),
		String(TranslationServer.translate(chapter.title_key)),
		session.journeys_completed,
		session.contracts_delivered,
		session.visited_location_ids.size(),
	]

func _print_start(session: GameSession) -> void:
	var here := WorldMapData.get_location_by_id(session.current_location_id)
	print("Başlangıç şehri : %s (rastgele)" % here.location_name)
	print("Parti           : %s" % _party_line(session))
	print("Kervan          : %d vagon · kapasite %d kişi · %d GG · %d erzak" % [
		session.owned_wagon_count, session.get_party_capacity(),
		session.wallet.balance, session.get_provisions()
	])

func _party_line(session: GameSession) -> String:
	var names: Array[String] = []
	for character in session.get_party():
		names.append("%s (%s)" % [
			character.character_name, character.get_character_class().display_name
		])
	return ", ".join(names)

func _inventory_line(session: GameSession) -> String:
	var parts: Array[String] = []
	for entry in session.inventory.get_all_entries():
		var item: Item = entry.item
		parts.append("%s×%d" % [item.item_name, entry.quantity])
	return "boş" if parts.is_empty() else ", ".join(parts)

## Bir bacak: şehirde alışveriş + kontrat, sonra yol, sonra varış.
func _run_leg(session: GameSession, leg_number: int) -> bool:
	var origin := WorldMapData.get_location_by_id(session.current_location_id)
	var routes := WorldMapData.get_routes_from(session.current_location_id)
	if routes.is_empty():
		print("  (%s'den çıkan rota yok - duruldu)" % origin.location_name)
		return false

	# Kapalı geçit yok sayılmıyor: oyuncu da o yolu seçemez (bkz.
	# RouteConditions), demo da seçmemeli - yoksa gösterdiği akış oyunun
	# akışı olmaktan çıkardı.
	var open_routes: Array[TravelRoute] = []
	for candidate in routes:
		if session.is_route_open(candidate):
			open_routes.append(candidate)
	if open_routes.is_empty():
		print("  (%s'den çıkan açık rota yok - duruldu)" % origin.location_name)
		return false

	var route: TravelRoute = open_routes[_rng.randi_range(0, open_routes.size() - 1)]
	var destination := WorldMapData.get_location_by_id(route.to_location_id)

	# Süre ve tehlike yolun o günkü halinden okunuyor, ham tablodan değil.
	var travel_days := session.get_route_travel_days(route)
	var danger := session.get_route_danger(route)
	var state := session.get_route_state(route)
	var state_note := ""
	if state != RouteConditions.State.OPEN:
		state_note = ", %s" % RouteConditions.get_state_label(state)

	print("")
	print("── %d. BACAK: %s → %s (%d gün, tehlike %%%d%s)" % [
		leg_number, origin.location_name, destination.location_name,
		travel_days, int(round(danger * 100.0)), state_note
	])

	_sell_trade_goods(session, origin)
	_buy_trade_goods(session, origin)
	var plan := _build_plan(session, destination, route)
	_stock_provisions(session, plan)

	session.depart_with_contracts(plan.get_selected_offers())
	session.start_journey(destination.location_id, travel_days, danger, plan)

	_travel(session, travel_days)

	var payout := session.finish_journey()
	print("   Varış: brüt %d → net %d GG · XP %d%s" % [
		payout.gross, payout.net, payout.get("xp_awarded", 0),
		"" if int(payout.get("lost_contracts", 0)) == 0 else
			" · %d kontrat teslim edilemedi" % int(payout.get("lost_contracts", 0))
	])
	for entry in (payout.get("stress_breaks", []) as Array):
		var brk: Dictionary = entry
		print("   Kırılma: %s%s" % [
			brk.character_name, " (kervandan ayrıldı)" if brk.departed else ""
		])
	return true

## Vardığın şehirde talep edileni sat. Demo bunu uzun süre hiç yapmıyordu:
## mal alıp hiç satmıyor, envanterde biriktiriyordu. O yüzden bastığı
## ekonomi tablosu ticaretin kârını hiç göstermiyor, yalnızca kontrat
## gelirini gösteriyordu - erzak maliyetini değerlendirmek imkânsızdı.
func _sell_trade_goods(session: GameSession, origin: Location) -> void:
	var entries: Array = session.inventory.get_all_entries().duplicate()
	for entry in entries:
		var item: Item = (entry as Dictionary).item
		if item == null or item.item_id == GameSession.PROVISIONS_ITEM_ID:
			continue
		if not origin.demands.has(item.item_id):
			continue
		var item_id := item.item_id
		var quantity := session.inventory.get_quantity(item_id)
		if quantity <= 0:
			continue
		var unit_price := MarketPricing.get_sell_price(
			item, origin, session.market, session.total_days_elapsed
		)
		session.inventory.remove_item(item_id, quantity)
		session.wallet.earn(unit_price * quantity)
		session.record_sale(item_id, quantity)
		print("   Pazar: %d %s satıldı (%d GG)" % [
			quantity, item.item_name, unit_price * quantity
		])

## Şehirde ucuz olanı al: hedefin talep ettiği malı taşımak kârın kendisi.
func _buy_trade_goods(session: GameSession, origin: Location) -> void:
	for item_id in origin.produces:
		var item := ItemCatalog.get_item(item_id)
		if item == null:
			continue
		var unit_price := MarketPricing.get_buy_price(item, origin)
		var affordable := int(floor(float(session.wallet.balance) * 0.4 / float(maxi(1, unit_price))))
		var by_space := int(floor(session.get_cargo_space_remaining() / maxf(0.1, item.unit_weight)))
		var quantity := mini(mini(affordable, by_space), session.get_market_stock(item_id))
		if quantity <= 0:
			continue
		if session.inventory.add_item(item, quantity):
			session.consume_stock(item_id, quantity)
			session.wallet.spend(unit_price * quantity)
			print("   Pazar: %d %s alındı (%d GG)" % [
				quantity, item.item_name, unit_price * quantity
			])

## Kontrat panosundan hedefe giden teklifleri kabul edip vagona koy.
func _build_plan(session: GameSession, destination: Location, route: TravelRoute) -> CaravanPlan:
	# Erzak yolun o günkü süresine göre alınır: çamura batmış bir geçit
	# uzadığı kadar erzak yer.
	var plan := CaravanPlan.new(
		destination, session.get_route_travel_days(route),
		CaravanPlan.DEFAULT_MAX_WAGONS, session.owned_wagon_count
	)
	# Planlayıcı ekranıyla aynı kervan bilgisi - yoksa demo yolun gerçekte
	# yiyeceğinden az erzak stoklar (bkz. caravan_planner.gd).
	plan.caravan_party_size = session.get_party().size()
	plan.provision_multiplier = session.get_daily_provision_multiplier()
	plan.provision_reduction = session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI)
	for offer in WorldMapData.get_offers_from_origin(session.current_location_id):
		if offer.destination_location_id != destination.location_id:
			continue
		if not plan.can_add_offer(offer):
			continue
		session.accept_contract(offer)
		if plan.toggle_merchant(offer):
			print("   Lonca: %s kontratı alındı (%d GG, %d gün süre)" % [
				offer.merchant_name, offer.potential_profit, offer.contract_deadline_days
			])
	return plan

func _stock_provisions(session: GameSession, plan: CaravanPlan) -> void:
	var shortfall := plan.get_provisions_shortfall(session.get_provisions())
	if shortfall <= 0:
		return
	var cost := shortfall * GameSession.PROVISIONS_UNIT_PRICE
	if not session.wallet.can_afford(cost):
		print("   Erzak alınamadı (kese yetmiyor) - yolda açlık riski var")
		return
	session.wallet.spend(cost)
	var added := session.change_provisions(shortfall)
	print("   Erzak: %d alındı (%d GG)" % [added, cost])

## Yol ekranının _process döngüsünün birebir aynısı: saati ilerlet, dolan
## her günü işle. Olay çıkarsa ilk uygun seçenek seçilir (simülatörün de
## kullandığı sezgi - gerçek oyuncu zekâsını taklit etmiyor).
func _travel(session: GameSession, total_days: int) -> void:
	var clock := JourneyClock.new()
	var engine := EventEngine.new(EventCatalog.get_road_events(), _rng.randi())
	var day := 0
	var frames := 0
	var last_phase: int = -1

	while session.journey_days_remaining > 0 and frames < MAX_FRAMES_PER_LEG:
		frames += 1
		clock.advance(FRAME_DELTA)

		var phase := clock.get_phase()
		if phase != last_phase:
			last_phase = phase
			# Gün evresi değişimi görünsün: arka planın bu ritimle değişiyor.
			if clock.is_camp_time() and session.journey_days_remaining > 1:
				pass

		var elapsed := clock.take_elapsed_days()
		for _index in elapsed:
			if session.journey_days_remaining <= 0:
				break
			day += 1
			session.journey_days_remaining -= 1
			_consume_daily(session)
			var event := engine.roll_for_day(day, session.build_event_context())
			if event != null:
				engine.mark_fired(event, day)
				clock.consume_hours(1.5)
				_resolve_event(session, engine, event, day, clock)

	print("   Yol: %d gün sürdü · bitişte saat %s (%s) · moral %d · erzak %d" % [
		day, clock.get_clock_text(),
		TranslationServer.translate(JourneyClock.get_phase_key(clock.get_phase())),
		session.caravan.morale, session.get_provisions()
	])

## Yol ekranının _advance_contracts_and_provisions'ının aynısı: önce
## kontrat günü işler (süresi dolan varsa itibar yer), sonra erzak.
func _consume_daily(session: GameSession) -> void:
	for _merchant_id in session.advance_day():
		print("   Kontrat süresi doldu, itibar düştü.")
	var daily := 1 + session.caravan.merchant_names.size()
	daily = maxi(1, int(round(daily * session.get_daily_provision_multiplier())))
	daily = maxi(1, daily - session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI))
	session.change_provisions(-daily)
	if session.get_provisions() <= 0:
		session.caravan.change_morale(-10)
		session.change_stress(6)

func _resolve_event(
	session: GameSession, engine: EventEngine, event: GameEvent, day: int, clock: JourneyClock
) -> void:
	var context := session.build_event_context()
	var chosen: EventChoice = null
	for choice in event.choices:
		if choice.is_available(context):
			chosen = choice
			break
	if chosen == null:
		return

	print("   Gün %d (%s): %s → %s" % [
		day, clock.get_clock_text(), tr(event.title_key), tr(chosen.text_key)
	])

	var result := EventEffectApplier.apply(chosen.effects, session)
	for event_id in result.unlocked_event_ids:
		engine.unlock_event(event_id)
	# Savaş/pazarlık gibi yan kanallar yol ekranında panel açıyor ve zamandan
	# yiyor; burada paneli açamadığımız için yalnızca süresini işliyoruz.
	if not result.combat_requests.is_empty():
		clock.consume_hours(2.5)
	if not result.haggling_requests.is_empty():
		clock.consume_hours(1.0)

	var outcome := engine.resolve_outcome(chosen, session.build_event_context())
	if outcome != null:
		EventEffectApplier.apply(outcome.effects, session)
