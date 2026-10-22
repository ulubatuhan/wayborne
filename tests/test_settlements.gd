extends RefCounted

## Yeni dünya (görevler N1-N6, N9; §14): harita v3'ün 27 yerleşimi, yollar,
## yerleşim türü kuralları, başlangıç yeri ve eski kayıtların göçü.

func suite_name() -> String:
	return "Settlements"

func run(t) -> void:
	_test_catalog(t)
	_test_routes(t)
	_test_facilities(t)
	_test_contracts(t)
	_test_prices(t)
	_test_start_location(t)
	_test_legacy_save(t)
	_test_town_art(t)
	_test_wall_material(t)

## Saat -> beklenen dosya (CityFront.PHASE_FILES): şafak sabah, öğle gündüz, akşam akşam, gece taban.
const TOWN_PHASE_HOURS: Dictionary = {
	6: "background_morning.jpg", 12: "background_day.jpg", 18: "background_evening.jpg", 23: "background.jpg",
}

func _count(type: String) -> int:
	var n := 0
	for location in WorldMapData.get_locations():
		if location.settlement_type == type:
			n += 1
	return n

func _test_catalog(t) -> void:
	t.eq(_count(SettlementRules.CITY), 12, "12 şehir")
	t.eq(_count(SettlementRules.TOWN), 12, "12 kasaba")
	t.eq(_count(SettlementRules.CARAVANSERAI), 3, "3 kervansaray")
	for location in WorldMapData.get_locations():
		t.ok(not location.region.is_empty(), "bölgesi var: %s" % location.location_id)
		t.ok(not location.location_name.is_empty(), "adı var: %s" % location.location_id)
		t.ok(location.map_position.x > 0.0 and location.map_position.x < 16012.0, "haritada: %s" % location.location_id)
		t.ok(location.location_id == location.location_id.to_lower() and not location.location_id.contains(" "), "kimlik ASCII ve küçük harf: %s" % location.location_id)
		if location.settlement_type != SettlementRules.CITY:
			t.ok(not location.available.is_empty(), "kasaba ve kervansarayda her mal yok: %s" % location.location_id)
			for item_id in location.produces:
				t.ok(location.sells(item_id), "ürettiğini satar: %s %s" % [location.location_id, item_id])
	TranslationServer.set_locale("en")
	t.eq(WorldMapData.get_location_by_id("serai_orbeyan").location_name, "Orbeyan Caravanserai", "İngilizce tür sözcüğü")
	TranslationServer.set_locale("tr")
	t.eq(WorldMapData.get_location_by_id("serai_orbeyan").location_name, "Orbeyan Kervansarayı", "Türkçe tür sözcüğü")
	t.eq(WorldMapData.get_location_by_id("vastrevar").location_name, "Vastrevar", "özel ad her dilde aynı")

func _test_routes(t) -> void:
	for location in WorldMapData.get_locations():
		var routes := WorldMapData.get_routes_from(location.location_id)
		t.ok(routes.size() >= 1, "yalnız kalan yer yok: %s" % location.location_id)
		for route in routes:
			t.ok(route.travel_days >= 2, "iki yer arası en az iki gün: %s-%s" % [route.from_location_id, route.to_location_id])
			t.ok(route.danger_level > 0.0 and route.danger_level < 1.0, "tehlike aralıkta")
			t.ok(WorldMapData.get_route_path(route.from_location_id, route.to_location_id).size() >= 2, "yolun haritada çizgisi var")
	var reached := {"vastrevar": true}
	var queue: Array[String] = ["vastrevar"]
	while not queue.is_empty():
		var here: String = queue.pop_back()
		for route in WorldMapData.get_routes_from(here):
			if not reached.has(route.to_location_id):
				reached[route.to_location_id] = true
				queue.append(route.to_location_id)
	t.eq(reached.size(), 27, "her yere yolla varılır")
	var days := _shortest_days("auderin", "orsolune")
	t.ok(absi(days - 61) <= 3, "kuzeyden güneye yaklaşık 61 gün (%d)" % days)

func _shortest_days(a: String, b: String) -> int:
	var dist := {a: 0}
	var open: Array[String] = [a]
	while not open.is_empty():
		open.sort_custom(func(x, y): return int(dist[x]) < int(dist[y]))
		var here: String = open.pop_front()
		for route in WorldMapData.get_routes_from(here):
			var nd: int = int(dist[here]) + route.travel_days
			if nd < int(dist.get(route.to_location_id, 1 << 30)):
				dist[route.to_location_id] = nd
				open.append(route.to_location_id)
	return int(dist.get(b, -1))

func _test_facilities(t) -> void:
	for f in [SettlementRules.MARKET, SettlementRules.GUILD, SettlementRules.TAVERN, SettlementRules.CHURCH, SettlementRules.CARAVAN_YARD, SettlementRules.WARDROBE]:
		t.ok(SettlementRules.has_facility(SettlementRules.CITY, f), "şehirde her şey var: %s" % f)
	t.not_ok(SettlementRules.has_facility(SettlementRules.TOWN, SettlementRules.GUILD), "kasabada lonca yok")
	t.not_ok(SettlementRules.has_facility(SettlementRules.TOWN, SettlementRules.CARAVAN_YARD), "kasabada kervan avlusu yok")
	t.ok(SettlementRules.has_facility(SettlementRules.TOWN, SettlementRules.MARKET), "kasabada pazar var")
	t.ok(SettlementRules.has_facility(SettlementRules.CARAVANSERAI, SettlementRules.CARAVAN_YARD), "kervansarayda avlu var")
	t.not_ok(SettlementRules.has_facility(SettlementRules.CARAVANSERAI, SettlementRules.GUILD), "kervansarayda lonca yok")
	var session := GameSession.new()
	session.current_location_id = "selvicar"
	var model: Dictionary = load("res://scripts/world/city_map.gd").build_model(session)
	t.not_ok((model["facilities"] as Array).has(SettlementRules.GUILD), "kasaba ekranında lonca levhası yok")

func _test_contracts(t) -> void:
	var any := false
	for location in WorldMapData.get_locations():
		var offers := WorldMapData.get_offers_from_origin(location.location_id)
		if location.settlement_type != SettlementRules.CITY:
			t.eq(offers.size(), 0, "loncasız yerden kontrat çıkmaz: %s" % location.location_id)
		for offer in offers:
			any = true
			var destination := WorldMapData.get_location_by_id(offer.destination_location_id)
			t.ne(destination.settlement_type, SettlementRules.CARAVANSERAI, "kervansaray kontrat varışı olmaz: %s" % offer.merchant_id)
	t.ok(any, "şehirlerden kontrat çıkar")

func _test_prices(t) -> void:
	var grain := ItemCatalog.get_item("test_grain")
	var silk := ItemCatalog.get_item("silk")
	var city := Location.new()
	city.settlement_type = SettlementRules.CITY
	var town := Location.new()
	town.settlement_type = SettlementRules.TOWN
	var serai := Location.new()
	serai.settlement_type = SettlementRules.CARAVANSERAI
	t.ok(MarketPricing.get_buy_price(grain, town) < MarketPricing.get_buy_price(grain, city), "kasabada temel mal ucuz")
	t.eq(MarketPricing.get_buy_price(silk, town), MarketPricing.get_buy_price(silk, city), "kasabada lüks mal ucuz değil")
	t.ok(MarketPricing.get_buy_price(silk, serai) > MarketPricing.get_buy_price(silk, city), "kervansarayda alış pahalı")
	t.ok(MarketPricing.get_sell_price(silk, serai) < MarketPricing.get_sell_price(silk, city), "kervansarayda satış ucuz")
	t.ok(MarketConditions.default_city_gold("selvicar") < MarketConditions.default_city_gold("vastrevar"), "kasabanın hazinesi şehrinkinden az (ticaret payı)")

func _test_start_location(t) -> void:
	for culture in CultureCatalog.get_cultures():
		var candidates := WorldMapData.get_start_candidates(culture.culture_id)
		t.ok(not candidates.is_empty(), "kültürün başlangıç adayı var: %s" % culture.culture_id)
		for id in candidates:
			t.ne(WorldMapData.get_location_by_id(id).settlement_type, SettlementRules.CARAVANSERAI, "kervansarayda başlanmaz")
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var picked := GameSession.roll_starting_location(rng, culture.culture_id)
		t.ok(candidates.has(picked), "%s kültürü kendi bölgesinde başlar (%s)" % [culture.culture_id, picked])
	for id in WorldMapData.get_start_candidates(CultureCatalog.VALLEY):
		t.eq(WorldMapData.get_location_by_id(id).region, "vadi", "vadi kültürü Vadi bölgesinde başlar")

func _test_legacy_save(t) -> void:
	var session := GameSession.new(500, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	var data: Dictionary = JSON.parse_string(JSON.stringify(session.to_save_dict()))
	data["version"] = 3
	data["current_location_id"] = "test_loc_d"
	data["visited_location_ids"] = {"test_loc_d": true, "test_loc_a": true}
	data["accepted_contracts"] = {"m_1": 0}
	data["journey"] = {"origin_id": "test_loc_a", "destination_id": "test_loc_e", "total_days": 8, "days_remaining": 3}
	var fresh := GameSession.new(0, 0)
	fresh.load_from_dict(data)
	t.eq(fresh.current_location_id, "tolvarin", "yeni dünyada olmayan yarım sefer çıkış yerinde biter (eski merkez -> Tolvarin)")
	t.not_ok(fresh.is_journey_active(), "geçersiz sefer düşer")
	t.ok(fresh.visited_location_ids.has("dravoss"), "ziyaret edilen yerler çevrildi")
	t.ok(fresh.accepted_contracts.is_empty(), "eski kontrat teklifleri düşer")
	t.ok(WorldMapData.get_location_by_id(fresh.current_location_id) != null, "kayıt geçerli bir yerde açılır")

## P17: her yerleşimin kendi şehir resmi ve tıklama maskesi var; eski beş
## kasabanın yedeğine düşen yer kalmadı (`city_map.town_dir`).
func _test_town_art(t) -> void:
	var city_map: Script = load("res://scripts/world/city_map.gd")
	var towns = JSON.parse_string(FileAccess.get_file_as_string("res://tools/ui_scenes/towns.json"))
	for location in WorldMapData.get_locations():
		var id := location.location_id
		t.ok(towns is Dictionary and (towns as Dictionary).has(id), "sahne tanımı var: %s" % id)
		t.ok(FileAccess.file_exists(CityFront.TOWNS_DIR + id + "/background.jpg"), "şehir resmi var: %s" % id)
		t.ok(FileAccess.file_exists(CityFront.TOWNS_DIR + id + "/mask.png"), "tıklama maskesi var: %s" % id)
		t.eq(city_map.town_dir(id), id, "kendi resmini okur: %s" % id)
		# Dört vaktin her biri kendi resmine çözülür ve yüklenir (eksik evre sessizce
		# gece resmine düşerdi; render kuyruğu yarıda kalırsa bunu bu test yakalar).
		for hour in TOWN_PHASE_HOURS:
			var path := CityFront.background_path(id, float(hour))
			t.eq(path, CityFront.TOWNS_DIR + id + "/" + String(TOWN_PHASE_HOURS[hour]),
				"%s saat %d kendi evre resmini okur" % [id, hour])
			t.ok(TextureLoader.load_any(path) != null, "%s saat %d resmi yükleniyor" % [id, hour])

## Sur malzemesi tek kaynaktan: şehir resmindeki duvar (towns.json `wood`),
## kapı sahnesi ve hub kapısı aynı `wall` alanını izler. Biri kütük, ötekisi
## taş çıkarsa oyuncu kütük surlu kasabaya taş kapıdan girmiş olur.
func _test_wall_material(t) -> void:
	var towns = JSON.parse_string(FileAccess.get_file_as_string("res://tools/ui_scenes/towns.json"))
	var wood := 0
	for location in WorldMapData.get_locations():
		var town: Dictionary = (towns as Dictionary).get(location.location_id, {})
		var town_wood := false
		var town_yurt := false
		for p in town.get("props", []) + town.get("buildings", []):
			if (p as Dictionary).get("kind", "") == "wallrow" and (p as Dictionary).get("wood", false):
				town_wood = true
			if String((p as Dictionary).get("kind", "")).begins_with("builder:yurt"):
				town_yurt = true
		t.ok(location.wall in ["wood", "stone", "felt"], "sur malzemesi tanımlı: %s" % location.location_id)
		t.eq(location.wall == "felt", town_yurt, "göçebe obası keçe, sur yok: %s" % location.location_id)
		if not town_yurt:
			t.eq(location.wall == "wood", town_wood, "sur malzemesi kasaba sahnesiyle aynı: %s" % location.location_id)
		if location.wall == "wood":
			wood += 1
	t.ok(wood > 0, "kütük surlu yerleşim var")
	t.ok(PropArt.has("palisade_gate"), "kütük kapının hub resmi var")
	_test_own_gates(t)

## Yolun sonu ve hub şehrin kendi kapısını çiziyor (kendi kapı sahnesinden kesit,
## bkz. gate_cutout.py): her yerleşimin kesiti var, geçidi çapada, tabanı yerde.
func _test_own_gates(t) -> void:
	for location in WorldMapData.get_locations():
		var id := "gate_" + location.location_id
		t.ok(PropArt.has(id), "kendi kapı kesiti var: %s" % location.location_id)
		t.eq(location.gate_prop_id(), id, "kendi kapısını okur: %s" % location.location_id)
		if PropArt.has(id):
			var box := PropArt.layer_rect(id, "body", Vector2.ZERO, 1.0)
			t.ok(box.position.x < 0.0 and box.end.x > 0.0, "geçit kesitin içinde: %s" % location.location_id)
			t.ok(absf(box.end.y) <= 4.0, "taban yerde: %s" % location.location_id)
			t.ok(PropArt.has_layer(id, "town"), "surun arkasında şehir katmanı var: %s" % location.location_id)
			# Geçit render'dan ölçülüyor: bir vagon geçmeli (2 m'den geniş, 2.5 m'den yüksek).
			var door := GateArt.door_rect(id, Vector2.ZERO, 1.0 / PropArt.ppm(id))
			t.ok(door.size.x >= 2.0 and door.size.y >= 2.5, "geçit vagon geçecek kadar: %s %s" % [location.location_id, door.size])
			t.ok(absf(door.get_center().x) < 0.5, "geçit çapada: %s" % location.location_id)
