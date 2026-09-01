class_name WorldMapData
extends RefCounted

## Placeholder dünya verisi. Gerçek lore/harita gelince buradaki tablolar
## veri dosyalarından (data/config/) okunacak şekilde değiştirilecek.

const START_LOCATION_ID: String = "test_loc_a"

## Şehirler arası ticaret zinciri: her şehir bir malı ucuza üretir ve
## başka birinin ürettiği malı pahalıya arar. A→D→B→A ve C↔E iki kapalı
## döngü oluşturur, ikisi de gerçek rotalarla (bkz. _get_edges) bağlı.
static func get_locations() -> Array[Location]:
	var locations: Array[Location] = []
	locations.append(_make_location(
		"test_loc_a", "Test Şehir A", Vector2(110, 210), ["test_grain"], ["test_furs"]
	))
	locations.append(_make_location(
		"test_loc_b", "Test Şehir B", Vector2(330, 90), ["test_furs"], ["test_weapon"]
	))
	locations.append(_make_location(
		"test_loc_c", "Test Şehir C", Vector2(360, 330), ["test_cloth"], ["test_potion"]
	))
	locations.append(_make_location(
		"test_loc_d", "Test Şehir D", Vector2(560, 180), ["test_weapon"], ["test_grain"]
	))
	locations.append(_make_location(
		"test_loc_e", "Test Şehir E", Vector2(590, 370), ["test_potion"], ["test_cloth"]
	))
	return locations

static func get_location_by_id(location_id: String) -> Location:
	for location in get_locations():
		if location.location_id == location_id:
			return location
	return null

static func get_routes_from(from_location_id: String) -> Array[TravelRoute]:
	var routes: Array[TravelRoute] = []
	for route in _get_all_routes():
		if route.from_location_id == from_location_id:
			routes.append(route)
	return routes

static func get_route(from_location_id: String, to_location_id: String) -> TravelRoute:
	for route in _get_all_routes():
		if route.from_location_id == from_location_id and route.to_location_id == to_location_id:
			return route
	return null

## origin_location_id: teklifi veren tüccarın şu an bulunduğu şehir.
## Oyuncu oradaysa teklif görünür - başka bir şehirdeki tüccar burada
## çıkmaz.
static func get_offers_for_destination(
	destination_location_id: String, origin_location_id: String
) -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	for offer in _get_all_offers():
		if offer.destination_location_id != destination_location_id:
			continue
		if offer.origin_location_id != origin_location_id:
			continue
		offers.append(offer)
	return offers

## Kenarlar iki yönlü rota ve teklif üretimi için tek kaynak: her kenar
## [şehir_a, şehir_b, gün, tehlike] olarak tanımlanır, iki yöne de aynı
## değerlerle uygulanır. Her şehrin en az iki komşusu olacak şekilde
## kurulmuş (A merkez, B-D-E arasında ayrıca kısayollar var).
static func _get_edges() -> Array:
	return [
		["test_loc_a", "test_loc_b", 3, 0.20],
		["test_loc_a", "test_loc_c", 4, 0.35],
		["test_loc_a", "test_loc_d", 6, 0.50],
		["test_loc_a", "test_loc_e", 8, 0.65],
		["test_loc_b", "test_loc_d", 4, 0.30],
		["test_loc_c", "test_loc_e", 5, 0.40],
		["test_loc_d", "test_loc_e", 3, 0.25],
	]

static func _get_all_routes() -> Array[TravelRoute]:
	var routes: Array[TravelRoute] = []
	for edge in _get_edges():
		routes.append(_make_route(edge[0], edge[1], edge[2], edge[3]))
		routes.append(_make_route(edge[1], edge[0], edge[2], edge[3]))
	return routes

static func _get_all_offers() -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	var id_counter := 1
	for edge in _get_edges():
		offers.append_array(_offers_for_direction(edge[0], edge[1], edge[2], id_counter))
		id_counter += 10
		offers.append_array(_offers_for_direction(edge[1], edge[0], edge[2], id_counter))
		id_counter += 10
	return offers

## Her yön için iki teklif: küçük/ucuz bir vagon ve büyük/kârlı bir vagon.
## Kâr, yolun uzunluğuna göre ölçekleniyor - uzun ve tehlikeli rotalar
## daha çok ödüyor, riski anlamlı kılan da bu.
static func _offers_for_direction(
	origin_id: String, destination_id: String, travel_days: int, id_base: int
) -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	var profiles := [
		{"wagons": 1, "profit": 30 + travel_days * 8},
		{"wagons": 2, "profit": 70 + travel_days * 14},
	]
	for i in range(profiles.size()):
		var profile: Dictionary = profiles[i]
		var merchant_number: int = id_base + i
		offers.append(_make_offer(
			"m_%d" % merchant_number,
			"Tüccar %d" % merchant_number,
			origin_id,
			destination_id,
			profile.profit,
			profile.wagons
		))
	return offers

static func _make_location(
	location_id: String, location_name: String, map_position: Vector2,
	produces: Array, demands: Array
) -> Location:
	var location := Location.new()
	location.location_id = location_id
	location.location_name = location_name
	location.map_position = map_position
	var produces_typed: Array[String] = []
	for item_id in produces:
		produces_typed.append(item_id)
	var demands_typed: Array[String] = []
	for item_id in demands:
		demands_typed.append(item_id)
	location.produces = produces_typed
	location.demands = demands_typed
	return location

static func _make_route(from_location_id: String, to_location_id: String, travel_days: int, danger_level: float) -> TravelRoute:
	var route := TravelRoute.new()
	route.from_location_id = from_location_id
	route.to_location_id = to_location_id
	route.travel_days = travel_days
	route.danger_level = danger_level
	return route

static func _make_offer(
	merchant_id: String, merchant_name: String, origin_location_id: String,
	destination_location_id: String, potential_profit: int, wagon_count: int
) -> MerchantOffer:
	var offer := MerchantOffer.new()
	offer.merchant_id = merchant_id
	offer.merchant_name = merchant_name
	offer.origin_location_id = origin_location_id
	offer.destination_location_id = destination_location_id
	offer.potential_profit = potential_profit
	offer.wagon_count = wagon_count
	return offer
