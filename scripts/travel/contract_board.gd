class_name ContractBoard
extends RefCounted

## Dinamik kontrat panosu (görev Y-C02, kullanıcı notu): pano her varışta
## şehir + günden tohumlanarak yeniden kurulur, aynı varışta ekranı açıp
## kapatmak onu değiştirmez. Beş tür:
## - Teslimat (en sık): tüccar gelmez, malını bizim vagonumuz taşır.
## - Eşlik: tüccar kendi vagonuyla (ya da eşeğiyle) kervana katılır.
## - Vagonsuz tüccar: kendisi ve malı gelir, malı bizim vagonumuzda; ücrete
##   vagon kirası eklenir.
## - Yolcu: bir-üç kişi, yük yok, ağız var.
## - Kaçak yük: teslimatın kaçak tuz taşıyanı - çok öder, gümrükte el konabilir.
## Her türün süre baskılı ("acele") hâli olabilir: kısa vade, yüksek ücret,
## geç varışta ücretin yarısı.
## Kimliği `c|şehir|gün|sıra`: kayıttan dönen kabul edilmiş bir kontrat aynı
## tohumdan yeniden kurulur (bkz. GameSession.find_offer).

const ID_PREFIX: String = "c"
const MIN_OFFERS: int = 4
const MAX_OFFERS: int = 7
## Tür ağırlıkları: teslimat en sık (kullanıcı notu).
const KIND_WEIGHTS: Dictionary = {
	MerchantOffer.KIND_DELIVERY: 0.48,
	MerchantOffer.KIND_ESCORT: 0.20,
	MerchantOffer.KIND_WAGONLESS: 0.14,
	MerchantOffer.KIND_PASSENGER: 0.12,
	MerchantOffer.KIND_CONTRABAND: 0.06,
}
const RUSH_CHANCE: float = 0.25
const RUSH_PAY: float = 1.35
const DELIVERY_DAY_PAY: int = 11
const DELIVERY_PER_CARGO: int = 2
const PASSENGER_DAY_PAY: int = 4
const WAGON_RENT_PER_DAY: int = 6
const CONTRABAND_PAY: float = 1.7

static func make_id(origin_id: String, day: int, index: int) -> String:
	return "%s|%s|%d|%d" % [ID_PREFIX, origin_id, day, index]

## Kimlikten (şehir, gün) - panoyu yeniden kurmak için. Dinamik değilse [].
static func parse_id(merchant_id: String) -> Array:
	var parts := merchant_id.split("|")
	if parts.size() != 4 or parts[0] != ID_PREFIX:
		return []
	return [String(parts[1]), int(parts[2])]

static func roll(origin_id: String, day: int) -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	var origin := WorldMapData.get_location_by_id(origin_id)
	if origin == null or not SettlementRules.offers_contracts(origin.settlement_type):
		return offers
	var routes: Array[TravelRoute] = []
	for route in WorldMapData.get_routes_from(origin_id):
		var destination := WorldMapData.get_location_by_id(route.to_location_id)
		if destination != null and SettlementRules.accepts_contracts(destination.settlement_type):
			routes.append(route)
	if routes.is_empty():
		return offers
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("contract_board|%s|%d" % [origin_id, day])
	var count := rng.randi_range(MIN_OFFERS, MAX_OFFERS)
	var used := {}
	for i in count:
		var route: TravelRoute = routes[rng.randi_range(0, routes.size() - 1)]
		var offer := _make(origin_id, route, _roll_kind(rng), rng, make_id(origin_id, day, i))
		# Kervan tüccarları adıyla tutar: aynı panoda iki aynı ad olmasın.
		var tries := 0
		while used.has(offer.merchant_name) and tries < 8:
			offer.merchant_name = _name(rng)
			tries += 1
		used[offer.merchant_name] = true
		offers.append(offer)
	return offers

static func _roll_kind(rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	var acc := 0.0
	for kind in KIND_WEIGHTS:
		acc += float(KIND_WEIGHTS[kind])
		if roll <= acc:
			return String(kind)
	return MerchantOffer.KIND_DELIVERY

static func _make(origin_id: String, route: TravelRoute, kind: String, rng: RandomNumberGenerator, merchant_id: String) -> MerchantOffer:
	var days := route.travel_days
	var offer := MerchantOffer.new()
	offer.merchant_id = merchant_id
	offer.kind = kind
	offer.origin_location_id = origin_id
	offer.destination_location_id = route.to_location_id
	offer.merchant_name = _name(rng)
	offer.wagon_count = 0
	offer.contract_deadline_days = days + WorldMapData.CONTRACT_DEADLINE_BUFFER_DAYS
	var pay := 0
	if kind == MerchantOffer.KIND_ESCORT:
		var big := rng.randf() < 0.35
		offer.wagon_count = 2 if big else 1
		if days > 4 and rng.randf() < 0.3:
			# Eşekli tüccar: vagon havuzuna dokunmaz.
			offer.wagon_count = 0
			offer.donkey_count = 1 if days <= 8 else 2
			pay = 18 + days * WorldMapData.CONTRACT_DAY_PAY_DONKEY
		else:
			pay = (70 + days * WorldMapData.CONTRACT_DAY_PAY_LARGE) if big else (30 + days * WorldMapData.CONTRACT_DAY_PAY_SMALL)
			offer.required_reputation = WorldMapData.CONTRACT_REPUTATION_FOR_LARGE if big else 0
	elif kind == MerchantOffer.KIND_DELIVERY or kind == MerchantOffer.KIND_CONTRABAND:
		offer.cargo_weight = rng.randi_range(6, 16)
		offer.cargo_item_id = ItemCatalog.CONTRABAND_SALT if kind == MerchantOffer.KIND_CONTRABAND else ItemCatalog.CONTRACT_GOODS
		pay = 15 + days * DELIVERY_DAY_PAY + offer.cargo_weight * DELIVERY_PER_CARGO
		if kind == MerchantOffer.KIND_CONTRABAND:
			pay = int(round(float(pay) * CONTRABAND_PAY))
	elif kind == MerchantOffer.KIND_WAGONLESS:
		offer.cargo_weight = rng.randi_range(8, 14)
		offer.cargo_item_id = ItemCatalog.CONTRACT_GOODS
		offer.wagon_rent = days * WAGON_RENT_PER_DAY
		pay = 20 + days * DELIVERY_DAY_PAY + offer.wagon_rent
	elif kind == MerchantOffer.KIND_PASSENGER:
		offer.passengers = rng.randi_range(1, 3)
		pay = 10 + days * PASSENGER_DAY_PAY * offer.passengers
	if rng.randf() < RUSH_CHANCE:
		offer.rush = true
		offer.contract_deadline_days = days + 1
		pay = int(round(float(pay) * RUSH_PAY))
		offer.wagon_rent = int(round(float(offer.wagon_rent) * RUSH_PAY))
	offer.potential_profit = pay
	return offer

static func _name(rng: RandomNumberGenerator) -> String:
	var cultures := CultureCatalog.get_cultures()
	var culture: Culture = cultures[rng.randi_range(0, cultures.size() - 1)]
	var pool := culture.name_pool
	return String(pool[rng.randi_range(0, pool.size() - 1)]) if not pool.is_empty() else "?"
