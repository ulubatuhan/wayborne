extends RefCounted

## Dinamik kontratlar (görev Y-C02): pano tohumdan ve her varışta yeni, beş
## tür, teslimat en sık, vagon kirası ücrette, emanet yük vagonda taşınır ve
## eksikse teslim edilmez, acele kontrat geç kalınca yarı ödenir, kabul
## edilen kontrat kayıttan döner.

const ORIGIN: String = WorldMapData.START_LOCATION_ID

func suite_name() -> String:
	return "Contracts"

func run(t) -> void:
	_test_board_is_seeded(t)
	_test_kinds_and_pay(t)
	_test_delivery_round_trip(t)
	_test_lost_goods_and_late_rush(t)
	_test_accepted_contract_survives_a_reload(t)

func _session() -> GameSession:
	var session := GameSession.new(2000, 200, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	session.current_location_id = ORIGIN
	return session

func _test_board_is_seeded(t) -> void:
	var a := ContractBoard.roll(ORIGIN, 12)
	var b := ContractBoard.roll(ORIGIN, 12)
	t.ok(a.size() >= ContractBoard.MIN_OFFERS and a.size() <= ContractBoard.MAX_OFFERS, "panoda dört-yedi ilan")
	var same := a.size() == b.size()
	for i in mini(a.size(), b.size()):
		if a[i].merchant_id != b[i].merchant_id or a[i].kind != b[i].kind or a[i].potential_profit != b[i].potential_profit:
			same = false
	t.ok(same, "aynı şehir ve gün aynı pano")
	var other := ContractBoard.roll(ORIGIN, 13)
	var differs := other.size() != a.size()
	for i in mini(a.size(), other.size()):
		if a[i].kind != other[i].kind or a[i].destination_location_id != other[i].destination_location_id:
			differs = true
	t.ok(differs, "başka varışta başka pano")
	var names := {}
	var unique := true
	for offer in a:
		if names.has(offer.merchant_name):
			unique = false
		names[offer.merchant_name] = true
	t.ok(unique, "bir panoda aynı ad iki kez yok")
	t.eq(ContractBoard.roll("serai_orbeyan", 3).size(), 0, "loncası olmayan yerde pano yok")

func _test_kinds_and_pay(t) -> void:
	var counts := {}
	var rent_ok := true
	var mouths_ok := true
	var rush := 0
	var total := 0
	for day in range(0, 300, 3):
		for offer in ContractBoard.roll(ORIGIN, day):
			total += 1
			counts[offer.kind] = int(counts.get(offer.kind, 0)) + 1
			if offer.rush:
				rush += 1
			var route := WorldMapData.get_route(ORIGIN, offer.destination_location_id)
			if offer.kind == MerchantOffer.KIND_WAGONLESS:
				var expected := route.travel_days * ContractBoard.WAGON_RENT_PER_DAY
				if offer.rush:
					expected = int(round(float(expected) * ContractBoard.RUSH_PAY))
				if offer.wagon_rent != expected or offer.potential_profit <= offer.wagon_rent:
					rent_ok = false
			var mouths := offer.mouths()
			if (offer.kind == MerchantOffer.KIND_DELIVERY and mouths != 0) or (offer.kind == MerchantOffer.KIND_PASSENGER and mouths != offer.passengers):
				mouths_ok = false
	t.eq(counts.size(), 5, "beş tür de panoya çıkar")
	var most := ""
	for kind in counts:
		if most.is_empty() or int(counts[kind]) > int(counts[most]):
			most = String(kind)
	t.eq(most, MerchantOffer.KIND_DELIVERY, "teslimat en sık tür")
	t.ok(rent_ok, "vagonsuz tüccarın ücreti vagon kirasını içerir")
	t.ok(mouths_ok, "teslimat ağız katmaz, yolcu sayısı kadar katar")
	var share := float(rush) / float(total)
	t.ok(share > 0.15 and share < 0.35, "ilanların dörtte biri kadarı acele (%.2f)" % share)

func _first_of_kind(session: GameSession, kind: String) -> MerchantOffer:
	for day in range(0, 60):
		session.total_days_elapsed = day
		for offer in session.get_contract_board():
			if offer.kind == kind and not offer.rush:
				return offer
	return null

func _depart(session: GameSession, offer: MerchantOffer) -> void:
	session.accept_contract(offer)
	var destination := WorldMapData.get_location_by_id(offer.destination_location_id)
	var route := WorldMapData.get_route(ORIGIN, offer.destination_location_id)
	var plan := CaravanPlan.new(destination, route.travel_days, session.get_wagon_capacity(), session.owned_wagon_count)
	plan.cargo_room = session.get_cargo_space_remaining()
	plan.toggle_merchant(offer)
	session.depart_with_contracts(plan.get_selected_offers())
	session.start_journey(offer.destination_location_id, route.travel_days, 0.2, plan)

func _test_delivery_round_trip(t) -> void:
	var session := _session()
	var offer := _first_of_kind(session, MerchantOffer.KIND_DELIVERY)
	t.ok(offer != null, "teslimat ilanı bulundu")
	if offer == null:
		return
	_depart(session, offer)
	t.eq(session.get_total_quantity(ItemCatalog.CONTRACT_GOODS), offer.cargo_weight, "emanet yük vagona yüklendi")
	t.eq(session.caravan.get_contract_mouths(), 0, "teslimat kervana ağız katmaz")
	var gold := session.wallet.balance
	var payout := session.finish_journey()
	t.eq(int(payout["delivered_contracts"]), 1, "yük varınca teslim edilir")
	t.ok(session.wallet.balance > gold, "ücret ödenir")
	t.eq(session.get_total_quantity(ItemCatalog.CONTRACT_GOODS), 0, "emanet yük iner")
	var plan := CaravanPlan.new(WorldMapData.get_location_by_id(offer.destination_location_id), 3)
	plan.cargo_room = float(offer.cargo_weight) - 1.0
	t.not_ok(plan.toggle_merchant(offer), "yük sığmıyorsa kontrat plana girmez")

func _test_lost_goods_and_late_rush(t) -> void:
	var session := _session()
	var offer := _first_of_kind(session, MerchantOffer.KIND_DELIVERY)
	if offer == null:
		return
	_depart(session, offer)
	session.remove_from_cargo_or_bags(ItemCatalog.CONTRACT_GOODS, 1)
	var reputation := session.reputation
	var payout := session.finish_journey()
	t.eq(int(payout["lost_goods_contracts"]), 1, "eksik yükle teslimat olmaz")
	t.eq(int(payout["delivered_contracts"]), 0, "teslim sayılmaz")
	t.ok(session.reputation < reputation, "teslim edilmeyen kontrat itibar yer")

	var rushed := _session()
	var hurry: MerchantOffer = null
	for day in range(0, 200):
		rushed.total_days_elapsed = day
		for candidate in rushed.get_contract_board():
			if candidate.rush and candidate.kind == MerchantOffer.KIND_PASSENGER:
				hurry = candidate
		if hurry != null:
			break
	t.ok(hurry != null, "acele yolcu ilanı bulundu")
	if hurry == null:
		return
	_depart(rushed, hurry)
	rushed.total_days_elapsed += hurry.contract_deadline_days + 3
	var late := rushed.finish_journey()
	t.eq(int(late["late_contracts"]), 1, "geç kalan acele kontrat sayılır")
	t.eq(int(late["gross"]), int(round(float(hurry.potential_profit) * GameSession.LATE_RUSH_PAY_SHARE)), "geç kalınca ücretin yarısı")

func _test_accepted_contract_survives_a_reload(t) -> void:
	var session := _session()
	session.total_days_elapsed = 21
	var offer: MerchantOffer = session.get_contract_board()[0]
	session.accept_contract(offer)
	var copy := GameSession.new(0, 0)
	copy.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	var found := copy.find_offer(offer.merchant_id)
	t.ok(found != null, "kabul edilen kontrat kayıttan sonra bulunur")
	if found != null:
		t.eq(found.kind, offer.kind, "türü aynı")
		t.eq(found.potential_profit, offer.potential_profit, "ücreti aynı")
		t.eq(found.destination_location_id, offer.destination_location_id, "hedefi aynı")
	t.eq(copy.get_accepted_offers_for_destination(offer.destination_location_id).size() >= 1, true, "planlayıcı onu görür")
