class_name WorldMapData
extends RefCounted

## Beş şehirlik dünya verisi. Şema oturduğunda buradaki tablolar veri
## dosyalarından (data/config/) okunacak şekilde değiştirilecek -
## location_id'ler ("test_loc_a" vb.) o yüzden kalıcı kayıtlarla uyumlu
## kalmak için bilerek değiştirilmedi, yalnızca location_name'ler ve
## tüccar isimleri Faz 7 PR-D'de gerçek lore'a döndü.
##
## Tüm tablolar bir kez kurulup statik önbelleğe alınıyor (bkz. ItemCatalog
## ile aynı desen): içerik büyüdükçe her çağrıda sıfırdan yeniden inşa
## etmek (önceki hali) veri arttıkça donmaya dönüşürdü. Location/TravelRoute/
## MerchantOffer nesneleri hep okunuyor, hiçbir çağıran onları mutate
## etmiyor - bu yüzden aynı örneği paylaşmak güvenli.

const START_LOCATION_ID: String = "test_loc_a"

## Bir şehrin ürettiği malın pazardaki başlangıç/varış stoğu.
const PRODUCED_GOOD_STOCK: int = 30

## Kontrat panosu (bkz. GameSession.accepted_contracts): kabul edilen bir
## kontrat, yolun süresinden bu kadar fazla gün içinde sefere çıkılmazsa
## süresi dolar. Büyük (2 vagonluk) kontratlar bir miktar itibar ister.
const CONTRACT_DEADLINE_BUFFER_DAYS: int = 10
const CONTRACT_REPUTATION_FOR_LARGE: int = 5

static var _built: bool = false
static var _locations: Array[Location] = []
static var _location_by_id: Dictionary = {}
static var _routes_by_from: Dictionary = {}
static var _route_by_pair: Dictionary = {}
static var _offers_by_origin_destination: Dictionary = {}
static var _offers_by_origin: Dictionary = {}
static var _offer_by_merchant_id: Dictionary = {}

static func get_locations() -> Array[Location]:
	_ensure_built()
	return _locations

static func get_location_by_id(location_id: String) -> Location:
	_ensure_built()
	return _location_by_id.get(location_id)

static func get_routes_from(from_location_id: String) -> Array[TravelRoute]:
	_ensure_built()
	var routes: Array[TravelRoute] = []
	for route in _routes_by_from.get(from_location_id, []):
		routes.append(route)
	return routes

static func get_route(from_location_id: String, to_location_id: String) -> TravelRoute:
	_ensure_built()
	return _route_by_pair.get(_pair_key(from_location_id, to_location_id))

## origin_location_id: teklifi veren tüccarın şu an bulunduğu şehir.
## Oyuncu oradaysa teklif görünür - başka bir şehirdeki tüccar burada
## çıkmaz.
static func get_offers_for_destination(
	destination_location_id: String, origin_location_id: String
) -> Array[MerchantOffer]:
	_ensure_built()
	var offers: Array[MerchantOffer] = []
	for offer in _offers_by_origin_destination.get(_pair_key(origin_location_id, destination_location_id), []):
		offers.append(offer)
	return offers

## Bir şehirden (hedef fark etmeksizin) çıkan tüm teklifler - Tüccar
## Loncası'nın kontrat panosu için.
static func get_offers_from_origin(origin_location_id: String) -> Array[MerchantOffer]:
	_ensure_built()
	var offers: Array[MerchantOffer] = []
	for offer in _offers_by_origin.get(origin_location_id, []):
		offers.append(offer)
	return offers

static func get_offer_by_merchant_id(merchant_id: String) -> MerchantOffer:
	_ensure_built()
	return _offer_by_merchant_id.get(merchant_id)

static func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_build_locations()
	_build_routes_and_offers()

## Şehirler arası ticaret zinciri: her şehir bir malı ucuza üretir ve
## başka birinin ürettiği malı pahalıya arar. Karakonak (merkez) →
## Demirkapı → Kurtboğazı → Karakonak ve İpekevi ↔ Yeşilova iki kapalı
## döngü oluşturur, ikisi de gerçek rotalarla (bkz. _get_edges) bağlı.
static func _build_locations() -> void:
	_locations.append(_make_location(
		"test_loc_a", "Karakonak", Vector2(110, 210), ["test_grain"], ["test_furs"]
	))
	_locations.append(_make_location(
		"test_loc_b", "Kurtboğazı", Vector2(330, 90), ["test_furs"], ["test_weapon"]
	))
	_locations.append(_make_location(
		"test_loc_c", "İpekevi", Vector2(360, 330), ["test_cloth"], ["test_potion"]
	))
	_locations.append(_make_location(
		"test_loc_d", "Demirkapı", Vector2(560, 180), ["test_weapon"], ["test_grain"]
	))
	_locations.append(_make_location(
		"test_loc_e", "Yeşilova", Vector2(590, 370), ["test_potion"], ["test_cloth"]
	))
	for location in _locations:
		_location_by_id[location.location_id] = location
		for item_id in location.produces:
			location.stock_per_item[item_id] = PRODUCED_GOOD_STOCK

## Kenarlar iki yönlü rota ve teklif üretimi için tek kaynak: her kenar
## [şehir_a, şehir_b, gün, tehlike] olarak tanımlanır, iki yöne de aynı
## değerlerle uygulanır. Her şehrin en az iki komşusu olacak şekilde
## kurulmuş (Karakonak merkez, Kurtboğazı-Demirkapı-Yeşilova arasında
## ayrıca kısayollar var).
static func _build_routes_and_offers() -> void:
	var id_counter := 1
	for edge in _get_edges():
		_add_direction(edge[0], edge[1], edge[2], edge[3], id_counter)
		id_counter += 10
		_add_direction(edge[1], edge[0], edge[2], edge[3], id_counter)
		id_counter += 10

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

static func _add_direction(
	from_id: String, to_id: String, travel_days: int, danger_level: float, id_base: int
) -> void:
	var route := _make_route(from_id, to_id, travel_days, danger_level)
	if not _routes_by_from.has(from_id):
		_routes_by_from[from_id] = []
	_routes_by_from[from_id].append(route)
	_route_by_pair[_pair_key(from_id, to_id)] = route

	var offers := _offers_for_direction(from_id, to_id, travel_days, id_base)
	_offers_by_origin_destination[_pair_key(from_id, to_id)] = offers
	if not _offers_by_origin.has(from_id):
		_offers_by_origin[from_id] = []
	for offer in offers:
		_offers_by_origin[from_id].append(offer)
		_offer_by_merchant_id[offer.merchant_id] = offer

## Her yön için iki teklif: küçük/ucuz bir vagon ve büyük/kârlı bir vagon.
## Kâr, yolun uzunluğuna göre ölçekleniyor - uzun ve tehlikeli rotalar
## daha çok ödüyor, riski anlamlı kılan da bu.
static func _offers_for_direction(
	origin_id: String, destination_id: String, travel_days: int, id_base: int
) -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	var deadline := travel_days + CONTRACT_DEADLINE_BUFFER_DAYS
	var profiles := [
		{"wagons": 1, "profit": 30 + travel_days * 8, "reputation": 0},
		{"wagons": 2, "profit": 70 + travel_days * 14, "reputation": CONTRACT_REPUTATION_FOR_LARGE},
	]
	for i in range(profiles.size()):
		var profile: Dictionary = profiles[i]
		var merchant_number: int = id_base + i
		offers.append(_make_offer(
			"m_%d" % merchant_number,
			_merchant_name(merchant_number),
			origin_id,
			destination_id,
			profile.profit,
			profile.wagons,
			deadline,
			profile.reputation
		))
	return offers

## merchant_id kalıcıdır (bkz. GameSession.accepted_contracts), isim
## yalnızca gösterim - kültürlerin kendi isim havuzlarından (bkz.
## CultureCatalog) deterministik seçiliyor, hem "Tüccar 12" gibi çıplak
## bir numara kalmıyor hem de dünyanın beş kültürü tüccar tarafında da
## görünür oluyor.
static func _merchant_name(merchant_number: int) -> String:
	var cultures := CultureCatalog.get_cultures()
	var culture: Culture = cultures[merchant_number % cultures.size()]
	var pool := culture.name_pool
	return pool[(merchant_number / cultures.size()) % pool.size()]

static func _pair_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b]

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
	destination_location_id: String, potential_profit: int, wagon_count: int,
	contract_deadline_days: int, required_reputation: int
) -> MerchantOffer:
	var offer := MerchantOffer.new()
	offer.merchant_id = merchant_id
	offer.merchant_name = merchant_name
	offer.origin_location_id = origin_location_id
	offer.destination_location_id = destination_location_id
	offer.potential_profit = potential_profit
	offer.wagon_count = wagon_count
	offer.contract_deadline_days = contract_deadline_days
	offer.required_reputation = required_reputation
	return offer
