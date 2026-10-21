class_name WorldMapData
extends RefCounted

## Dünya verisi: harita v3'ün oynanabilir yerleşimleri (12 şehir, 12 kasaba,
## 3 kervansaray) ve aralarındaki yollar `data/config/settlements.json`'dan
## okunuyor (üreten: tools/worldmap/build_settlements.py; görev N1-N6). Eski
## beş yer tutucu şehir (test_loc_a..e) kalktı; eski kayıtlar
## GameSession._migrate_save ile yeni yerlere taşınıyor.
##
## Tüm tablolar bir kez kurulup statik önbelleğe alınıyor (bkz. ItemCatalog
## ile aynı desen). Location/TravelRoute/MerchantOffer nesneleri hep
## okunuyor, hiçbir çağıran onları mutate etmiyor - aynı örneği paylaşmak
## güvenli.

const DATA_PATH: String = "res://data/config/settlements.json"

## Eski yer tutucu şehirlerin yeni karşılıkları (kayıt göçü ve testler).
## Coğrafi ve ekonomik karakterine en yakın yer: merkez kavşak -> bozkır kapısı
## Tolvarin, dağ geçidi -> maden kasabası Kesgrav, ipek -> Ilsande, demir ->
## garnizon kenti Dravoss, kıyı ova -> güney limanı Orsolune.
const LEGACY_IDS: Dictionary = {
	"test_loc_a": "tolvarin",
	"test_loc_b": "kesgrav",
	"test_loc_c": "ilsande",
	"test_loc_d": "dravoss",
	"test_loc_e": "orsolune",
}

## Sentetik seferler ve "hiçbir şey yoksa" yedeği. Gerçek oyun kültüre göre
## başlar (bkz. GameSession.roll_starting_location).
const START_LOCATION_ID: String = "vastrevar"

## Bir şehrin ürettiği malın pazardaki başlangıç/varış stoğu.
const PRODUCED_GOOD_STOCK: int = 30

## Kontrat panosu (bkz. GameSession.accepted_contracts): kabul edilen bir
## kontrat, yolun süresinden bu kadar fazla gün içinde sefere çıkılmazsa
## süresi dolar. Büyük (2 vagonluk) kontratlar bir miktar itibar ister.
const CONTRACT_DEADLINE_BUFFER_DAYS: int = 10
const CONTRACT_REPUTATION_FOR_LARGE: int = 5
## Kontratın günlük ücreti (bkz. _offers_for_direction).
const CONTRACT_DAY_PAY_SMALL: int = 14
const CONTRACT_DAY_PAY_LARGE: int = 24
const CONTRACT_DAY_PAY_DONKEY: int = 9

static var _built: bool = false
static var _locations: Array[Location] = []
static var _location_by_id: Dictionary = {}
static var _routes_by_from: Dictionary = {}
static var _route_by_pair: Dictionary = {}
static var _offers_by_origin: Dictionary = {}
static var _offer_by_merchant_id: Dictionary = {}
static var _start_candidates: Dictionary = {}
static var _route_paths: Dictionary = {}
static var _route_meta: Dictionary = {}
static var _map_lights: PackedVector3Array = PackedVector3Array()

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
	var data := _load_data()
	_build_locations(data)
	_build_routes_and_offers(data)
	_build_guild_wagon_quests()

static func _load_data() -> Dictionary:
	var text := FileAccess.get_file_as_string(DATA_PATH)
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("WorldMapData: cannot read %s" % DATA_PATH)
		return {"settlements": [], "routes": []}
	return parsed

## Kültürün başlangıç adayları (bkz. GameSession.roll_starting_location).
static func get_start_candidates(culture_id: String) -> Array[String]:
	_ensure_built()
	var result: Array[String] = []
	for location_id in _start_candidates.get(culture_id, []):
		result.append(String(location_id))
	return result

## Haritadaki yerleşim ışıkları (görev 8.11): (x, y, titreme fazı), harita
## pikseli. `build_settlements.py` yerleşim türüne göre üretir; harabe ışıksız.
static func get_map_lights() -> PackedVector3Array:
	_ensure_built()
	return _map_lights

## İki yer arasındaki yolun harita üzerindeki çizgisi (harita pikseli).
static func get_route_path(from_location_id: String, to_location_id: String) -> PackedVector2Array:
	_ensure_built()
	var key := _pair_key(from_location_id, to_location_id)
	if _route_paths.has(key):
		return _route_paths[key]
	var reverse: PackedVector2Array = _route_paths.get(_pair_key(to_location_id, from_location_id), PackedVector2Array())
	var out := PackedVector2Array()
	for i in range(reverse.size() - 1, -1, -1):
		out.append(reverse[i])
	return out

## Yolun ek bilgisi: orman ve dağ payı, kervan yolu payı, duraklar.
static func get_route_meta(from_location_id: String, to_location_id: String) -> Dictionary:
	_ensure_built()
	return _route_meta.get(RouteConditions.route_key(from_location_id, to_location_id), {})

## Yolun haritadan gelen arazisi, yönsüz anahtarla (`RouteConditions.route_key`):
## {"from": çıkış şehri, "segments": [{"biome", "to" (0-1), "stop"}]}; haritada
## olmayan bir anahtar (test, sentetik sefer) için boş sözlük.
static func get_route_terrain(key: String) -> Dictionary:
	_ensure_built()
	var meta: Dictionary = _route_meta.get(key, {})
	var segments: Array = meta.get("terrain", [])
	if segments.is_empty():
		return {}
	return {"from": String(meta.get("terrain_from", "")), "segments": segments}

static func _build_locations(data: Dictionary) -> void:
	for entry in data.get("settlements", []):
		var s: Dictionary = entry
		var location := Location.new()
		location.location_id = String(s["id"])
		location.names = (s.get("name", {}) as Dictionary).duplicate()
		var pos: Array = s.get("pos", [0, 0])
		location.map_position = Vector2(float(pos[0]), float(pos[1]))
		location.settlement_type = String(s.get("type", SettlementRules.CITY))
		location.region = String(s.get("region", ""))
		location.culture = String(s.get("culture", ""))
		location.wall = String(s.get("wall", "stone"))
		location.produces = _typed(s.get("produces", []))
		location.demands = _typed(s.get("demands", []))
		location.available = _typed(s.get("available", []))
		var share := SettlementRules.trade_share(location.settlement_type)
		for item_id in location.produces:
			location.stock_per_item[item_id] = maxi(1, int(round(PRODUCED_GOOD_STOCK * share)))
		_locations.append(location)
		_location_by_id[location.location_id] = location
	for culture_id in (data.get("start_candidates", {}) as Dictionary):
		_start_candidates[culture_id] = data["start_candidates"][culture_id]
	for light in data.get("lights", []):
		var l: Array = light
		_map_lights.append(Vector3(float(l[0]), float(l[1]), float(l[2])))

static func _typed(values: Array) -> Array[String]:
	var out: Array[String] = []
	for v in values:
		out.append(String(v))
	return out

## Her yol iki yönlü; kontrat teklifi yalnızca loncası olan yerden (şehir)
## kontrat kabul eden yere (şehir ya da kasaba) çıkar - kervansaray ne
## kontrat verir ne kontratın varış yeri olur (kullanıcı kararı).
static func _build_routes_and_offers(data: Dictionary) -> void:
	var id_counter := 1
	for entry in data.get("routes", []):
		var r: Dictionary = entry
		var a := String(r["a"])
		var b := String(r["b"])
		var days := int(r.get("days", 1))
		var danger := float(r.get("danger", 0.3))
		var path := PackedVector2Array()
		for point in r.get("path", []):
			path.append(Vector2(float(point[0]), float(point[1])))
		_route_paths[_pair_key(a, b)] = path
		_route_meta[RouteConditions.route_key(a, b)] = {
			"forest_share": float(r.get("forest_share", 0.0)),
			"mountain_share": float(r.get("mountain_share", 0.0)),
			"caravan_road_share": float(r.get("caravan_road_share", 0.0)),
			"via": r.get("via", []),
			# Yol ekranının arazisi, `terrain_from` şehrinden okunacak sırada
			# (bkz. RouteTerrain.build, build_settlements.py terrain_segments).
			"terrain_from": String(r.get("terrain_from", a)),
			"terrain": r.get("terrain", []),
		}
		_add_direction(a, b, days, danger, id_counter)
		id_counter += 10
		_add_direction(b, a, days, danger, id_counter)
		id_counter += 10

static func _add_direction(
	from_id: String, to_id: String, travel_days: int, danger_level: float, id_base: int
) -> void:
	var route := _make_route(from_id, to_id, travel_days, danger_level)
	if not _routes_by_from.has(from_id):
		_routes_by_from[from_id] = []
	_routes_by_from[from_id].append(route)
	_route_by_pair[_pair_key(from_id, to_id)] = route

	var origin: Location = _location_by_id.get(from_id)
	var destination: Location = _location_by_id.get(to_id)
	if origin == null or destination == null:
		return
	if not SettlementRules.offers_contracts(origin.settlement_type):
		return
	if not SettlementRules.accepts_contracts(destination.settlement_type):
		return
	var offers := _offers_for_direction(from_id, to_id, travel_days, id_base)
	if not _offers_by_origin.has(from_id):
		_offers_by_origin[from_id] = []
	for offer in offers:
		_offers_by_origin[from_id].append(offer)
		_offer_by_merchant_id[offer.merchant_id] = offer

## Her yön için üç teklif: küçük/ucuz bir vagon, büyük/kârlı bir vagon ve
## kendi eşekleriyle gelen bağımsız bir tüccar. Kâr, yolun uzunluğuna göre
## ölçekleniyor - uzun ve tehlikeli rotalar daha çok ödüyor, riski anlamlı
## kılan da bu. Eşekli tüccar en küçük vagonlu tekliften bilerek daha az
## kazandırıyor - taşıdığı yük de daha az - ama karşılığında vagon
## almaya/almamaya hiç dokunmuyor: yalın (az vagonlu, kontrat ağırlıklı)
## bir kervanın Campaign Rules'un "buying wagons crowds out contracts"
## çelişkisine hiç girmeden alabileceği tek kontrat türü.
static func _offers_for_direction(
	origin_id: String, destination_id: String, travel_days: int, id_base: int
) -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	var deadline := travel_days + CONTRACT_DEADLINE_BUFFER_DAYS
	# Kısa/güvenli bir yol tek eşekle yürünür, uzun bir yol yükünü iki
	# eşeğe böler - vagon tekliflerinin uzunluğa göre büyüyen kârıyla aynı
	# mantık, burada hayvan sayısında.
	var donkeys := 1 if travel_days <= 4 else 2
	# Günlük ücret, kontratın kervana kattığı ağzın erzağını (tüccar başına
	# günde ~4 GG) karşılayıp üstüne kâr bırakır: yeni dünyada yollar uzun
	# (2-38 gün, görev N8), günlük ücret düşük kalsaydı uzun yol zararına olurdu.
	var profiles := [
		{"wagons": 1, "donkeys": 0, "profit": 30 + travel_days * CONTRACT_DAY_PAY_SMALL, "reputation": 0},
		{"wagons": 2, "donkeys": 0, "profit": 70 + travel_days * CONTRACT_DAY_PAY_LARGE, "reputation": CONTRACT_REPUTATION_FOR_LARGE},
		{"wagons": 0, "donkeys": donkeys, "profit": 18 + travel_days * CONTRACT_DAY_PAY_DONKEY, "reputation": 0},
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
			profile.reputation,
			profile.donkeys
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
	contract_deadline_days: int, required_reputation: int, donkey_count: int = 0
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
	offer.donkey_count = donkey_count
	return offer

## Loncanın özel vagon görevleri - normal kontrat panosuyla **aynı**
## kabul/taşı/teslim akışını kullanıyor (bkz. GameSession.accept_contract,
## guild.gd'nin sıradan kontrat listesi), yalnızca karşılığı altın değil.
## Sabit `merchant_id`'leri var (kayıt uyumluluğu ve GameSession.
## _apply_guild_wagon_quest_rewards()'ın teslimat kontrolü için) ve
## `merchant_name`'leri kültürlerin isim havuzundan gelmiyor - kasıtlı,
## çünkü havuzdan gelen bir isimle çakışırsa teslimat kontrolü (isim
## eşleştirmesi, bkz. CaravanState.merchant_names) yanlış kontrata ödül
## verebilirdi.
##
## İki aile, iki farklı tekrar kuralı - ikisi de bilerek, ekonominin iki
## farklı kaynağını yansıtıyor:
##
## **Vagon bağışları kalıcı olarak bir kereye mahsus** (bkz.
## GameSession.is_guild_wagon_quest_delivered): bir vagon kalıcı bir
## kapasite artışı, `WAGON_PURCHASE_COST_STEP`'in her seferinde biraz
## daha pahalılaştırdığı satın alma eğrisini bedavaya deler. Sınırsız
## tekrar, Faz 17 PR-8'in kapattığı fulfill_commission sömürüsünün aynısı
## olurdu - bu yüzden `grants_wagon_on_delivery == true` olan her görev
## `GameSession._delivered_wagon_quest_ids`'e girer ve bir daha hiç
## açılmaz. İki tane var (Vagon Bağışı, Sınır Karakolu Vagonu) - tek bir
## rotaya sıkışmasın diye, ama sayı bilerek az: her biri haritanın uzun/
## tehlikeli kenarlarından birine oturuyor ve yüksek itibar istiyor.
##
## **Kargo görevleri sıradan bir kontrat gibi tekrar tekrar kabul
## edilebilir** - mücevher/baharat/bal/ipek kalıcı bir kapasite değil,
## piyasada zaten alınıp satılan bir mal; sınırı zaten `MarketConditions`
## (arz-talep baskısı, şehir hazinesi) taşıyor, ikinci bir "bir kereye
## mahsus" kilidi burada gereksiz ve yalnızca içeriği tekdüzeleştirirdi.
## Dört tane var, dördü de haritanın farklı bir kenarına ve farklı bir
## şehrin kendi ürettiği mala oturuyor - "lonca kervanları" tek bir
## rotayı sürekli aynı iki görevle değil, gerçek bir havuzla karşılıyor.
const GUILD_WAGON_GRANT_QUEST_ID: String = "guild_wagon_grant"
const GUILD_WAGON_GRANT_2_QUEST_ID: String = "guild_wagon_grant_2"
const GUILD_WAGON_FREIGHT_QUEST_ID: String = "guild_wagon_freight"
const GUILD_WAGON_FREIGHT_SPICE_QUEST_ID: String = "guild_wagon_freight_spice"
const GUILD_WAGON_FREIGHT_HONEY_QUEST_ID: String = "guild_wagon_freight_honey"
const GUILD_WAGON_FREIGHT_SILK_QUEST_ID: String = "guild_wagon_freight_silk"

const _GUILD_WAGON_QUEST_IDS: Array[String] = [
	GUILD_WAGON_GRANT_QUEST_ID,
	GUILD_WAGON_GRANT_2_QUEST_ID,
	GUILD_WAGON_FREIGHT_QUEST_ID,
	GUILD_WAGON_FREIGHT_SPICE_QUEST_ID,
	GUILD_WAGON_FREIGHT_HONEY_QUEST_ID,
	GUILD_WAGON_FREIGHT_SILK_QUEST_ID,
]

static func get_guild_wagon_quests() -> Array[MerchantOffer]:
	_ensure_built()
	var quests: Array[MerchantOffer] = []
	for quest_id in _GUILD_WAGON_QUEST_IDS:
		# .get() Variant döner - CLAUDE.md'nin `:=` / Variant tuzağı burada
		# da geçerli, kaynağa açık tip vermeden `:=` derleme hatası verir.
		var quest: MerchantOffer = _offer_by_merchant_id.get(quest_id)
		if quest != null:
			quests.append(quest)
	return quests

static func _build_guild_wagon_quests() -> void:
	# Vagon Bağışı - Vastrevar'ın (kuzeyin başkenti, en büyük lonca) kuzey
	# körfezi limanı Rivecande'ye uzun ve tekinsiz yolu (17 gün, %38): lonca
	# vagonunu ancak gerçekten güvendiği bir kervana emanet eder.
	var grant := _make_offer(
		GUILD_WAGON_GRANT_QUEST_ID, "UI_GUILD_WAGON_GRANT_NAME",
		"vastrevar", "rivecande", 0, 1, 17 + CONTRACT_DEADLINE_BUFFER_DAYS, 25
	)
	grant.grants_wagon_on_delivery = true
	_register_offer(grant)

	# Sınır Karakolu Vagonu - doğu sınırındaki Ezmerak'tan Eski Ahit'in kutsal
	# kenti Orvahel'e (8 gün, %33): ikinci kalıcı vagon başka bir bölgede.
	var grant2 := _make_offer(
		GUILD_WAGON_GRANT_2_QUEST_ID, "UI_GUILD_WAGON_GRANT2_NAME",
		"ezmerak", "orvahel", 0, 1, 8 + CONTRACT_DEADLINE_BUFFER_DAYS, 20
	)
	grant2.grants_wagon_on_delivery = true
	_register_offer(grant2)

	# Fazla Yük Sevkiyatı - Zelmarin kuyumcularının fazlası Orvahel'e (27 gün).
	var freight_jewelry := _make_offer(
		GUILD_WAGON_FREIGHT_QUEST_ID, "UI_GUILD_WAGON_FREIGHT_NAME",
		"zelmarin", "orvahel", 0, 1, 27 + CONTRACT_DEADLINE_BUFFER_DAYS, 10
	)
	freight_jewelry.cargo_reward_item_id = "jewelry"
	freight_jewelry.cargo_reward_quantity = 5
	_register_offer(freight_jewelry)

	# Baharat Taşımacılığı - Orsolune limanının baharatı Zelmarin'e (33 gün).
	var freight_spice := _make_offer(
		GUILD_WAGON_FREIGHT_SPICE_QUEST_ID, "UI_GUILD_WAGON_FREIGHT_SPICE_NAME",
		"orsolune", "zelmarin", 0, 1, 33 + CONTRACT_DEADLINE_BUFFER_DAYS, 8
	)
	freight_spice.cargo_reward_item_id = "spice"
	freight_spice.cargo_reward_quantity = 8
	_register_offer(freight_spice)

	# Bal Taşımacılığı - Ezmerak arıcılarının balı bataklık kasabası Golcavar'a
	# (2 gün): itibar istemiyor, havuzun yeni oyuncuya açık girişi.
	var freight_honey := _make_offer(
		GUILD_WAGON_FREIGHT_HONEY_QUEST_ID, "UI_GUILD_WAGON_FREIGHT_HONEY_NAME",
		"ezmerak", "golcavar", 0, 1, 2 + CONTRACT_DEADLINE_BUFFER_DAYS, 0
	)
	freight_honey.cargo_reward_item_id = "honey"
	freight_honey.cargo_reward_quantity = 10
	_register_offer(freight_honey)

	# İpek Taşımacılığı - Ilsande atölyelerinin ipeği bağ kasabası Caramine'e (3 gün).
	var freight_silk := _make_offer(
		GUILD_WAGON_FREIGHT_SILK_QUEST_ID, "UI_GUILD_WAGON_FREIGHT_SILK_NAME",
		"ilsande", "caramine", 0, 1, 3 + CONTRACT_DEADLINE_BUFFER_DAYS, 5
	)
	freight_silk.cargo_reward_item_id = "silk"
	freight_silk.cargo_reward_quantity = 6
	_register_offer(freight_silk)

static func _register_offer(offer: MerchantOffer) -> void:
	if not _offers_by_origin.has(offer.origin_location_id):
		_offers_by_origin[offer.origin_location_id] = []
	_offers_by_origin[offer.origin_location_id].append(offer)
	_offer_by_merchant_id[offer.merchant_id] = offer
