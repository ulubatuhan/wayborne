class_name WorldMapData
extends RefCounted

## Placeholder dünya verisi. Gerçek lore/harita gelince buradaki tablolar
## veri dosyalarından (data/config/) okunacak şekilde değiştirilecek.

const START_LOCATION_ID: String = "test_loc_a"

static func get_locations() -> Array[Location]:
	var locations: Array[Location] = []
	locations.append(_make_location("test_loc_a", "Test Şehir A", Vector2(110, 210)))
	locations.append(_make_location("test_loc_b", "Test Şehir B", Vector2(330, 90)))
	locations.append(_make_location("test_loc_c", "Test Şehir C", Vector2(360, 330)))
	locations.append(_make_location("test_loc_d", "Test Şehir D", Vector2(560, 180)))
	locations.append(_make_location("test_loc_e", "Test Şehir E", Vector2(590, 370)))
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

static func get_offers_for_destination(destination_location_id: String) -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	for offer in _get_all_offers():
		if offer.destination_location_id == destination_location_id:
			offers.append(offer)
	return offers

static func _get_all_routes() -> Array[TravelRoute]:
	var routes: Array[TravelRoute] = []
	routes.append(_make_route("test_loc_a", "test_loc_b", 3, 0.20))
	routes.append(_make_route("test_loc_a", "test_loc_c", 4, 0.35))
	routes.append(_make_route("test_loc_a", "test_loc_d", 6, 0.50))
	routes.append(_make_route("test_loc_a", "test_loc_e", 8, 0.65))
	return routes

static func _get_all_offers() -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	offers.append(_make_offer("m_b1", "Test Tüccar 1", "test_loc_b", 45, 1))
	offers.append(_make_offer("m_b2", "Test Tüccar 2", "test_loc_b", 110, 2))
	offers.append(_make_offer("m_b3", "Test Tüccar 3", "test_loc_b", 35, 1))

	offers.append(_make_offer("m_c1", "Test Tüccar 4", "test_loc_c", 60, 1))
	offers.append(_make_offer("m_c2", "Test Tüccar 5", "test_loc_c", 150, 3))
	offers.append(_make_offer("m_c3", "Test Tüccar 6", "test_loc_c", 40, 1))

	offers.append(_make_offer("m_d1", "Test Tüccar 7", "test_loc_d", 130, 2))
	offers.append(_make_offer("m_d2", "Test Tüccar 8", "test_loc_d", 70, 1))
	offers.append(_make_offer("m_d3", "Test Tüccar 9", "test_loc_d", 55, 1))
	offers.append(_make_offer("m_d4", "Test Tüccar 10", "test_loc_d", 120, 2))

	offers.append(_make_offer("m_e1", "Test Tüccar 11", "test_loc_e", 90, 1))
	offers.append(_make_offer("m_e2", "Test Tüccar 12", "test_loc_e", 180, 2))
	return offers

static func _make_location(location_id: String, location_name: String, map_position: Vector2) -> Location:
	var location := Location.new()
	location.location_id = location_id
	location.location_name = location_name
	location.map_position = map_position
	return location

static func _make_route(from_location_id: String, to_location_id: String, travel_days: int, danger_level: float) -> TravelRoute:
	var route := TravelRoute.new()
	route.from_location_id = from_location_id
	route.to_location_id = to_location_id
	route.travel_days = travel_days
	route.danger_level = danger_level
	return route

static func _make_offer(merchant_id: String, merchant_name: String, destination_location_id: String, potential_profit: int, wagon_count: int) -> MerchantOffer:
	var offer := MerchantOffer.new()
	offer.merchant_id = merchant_id
	offer.merchant_name = merchant_name
	offer.destination_location_id = destination_location_id
	offer.potential_profit = potential_profit
	offer.wagon_count = wagon_count
	return offer
