extends RefCounted

## Sıcaklık (°C): mevsim, iklim, biyom, saat ve hava bir derece üretiyor;
## gece soğuğu giysiye göre insanlara, dondurucu gün erzağa işliyor. En
## önemli iddia: planlayıcının soğuk payıyla stoklayan kervan kışın da aç
## kalmıyor (Provision Rules'un sözü).

const SAMPLE_KEYS: Array[String] = ["kuzey|güney", "a|b", "dag|ova", "x|y"]

func suite_name() -> String:
	return "Temperature"

func run(t) -> void:
	_test_season_is_continuous(t)
	_test_geography_and_hour(t)
	_test_weather(t)
	_test_ration_share(t)
	_test_cold_load_and_clothes(t)
	_test_outfit_warmth(t)
	_test_cold_reserve_keeps_the_provision_promise(t)
	_test_map_winter_reserve(t)
	_test_session_cold_night(t)
	_test_session_ration(t)

func _test_season_is_continuous(t) -> void:
	var worst := 0.0
	for day in range(0, 240):
		worst = maxf(worst, absf(Temperature.seasonal_mean(day + 1) - Temperature.seasonal_mean(day)))
	t.le(worst, 1.0, "mevsim geçişinde derece bir günde birden fazla sıçramıyor")
	var length := MarketConditions.SEASON_LENGTH_DAYS
	t.almost(Temperature.seasonal_mean(length / 2), Temperature.SEASON_MEAN[0], "mevsim ortası mevsimin ortalaması")
	t.ok(Temperature.seasonal_mean(length * 3 + length / 2) < Temperature.seasonal_mean(length + length / 2),
		"kış yazdan soğuk")
	t.almost(Temperature.seasonal_mean(length * 4 + 7), Temperature.seasonal_mean(7), "yıl dönüyor")

func _test_geography_and_hour(t) -> void:
	var day := 100
	var meadow := Temperature.daily_mean(day, ArtPalette.BIOME_MEADOW, "", RouteWeather.CLEAR)
	t.ok(Temperature.daily_mean(day, ArtPalette.BIOME_MEADOW, "cold", RouteWeather.CLEAR) < meadow, "kuzey soğuk")
	t.ok(Temperature.daily_mean(day, ArtPalette.BIOME_MEADOW, "warm", RouteWeather.CLEAR) > meadow, "güney sıcak")
	t.ok(Temperature.daily_mean(day, ArtPalette.BIOME_MOUNTAIN, "", RouteWeather.CLEAR) < meadow, "dağ soğuk")
	var noon := Temperature.celsius(day, 14.0, ArtPalette.BIOME_STEPPE, "", RouteWeather.CLEAR)
	var night := Temperature.celsius(day, 3.0, ArtPalette.BIOME_STEPPE, "", RouteWeather.CLEAR)
	t.ok(noon > night + 10.0, "bozkırda gündüz yakar, gece dondurur")
	t.almost(night, Temperature.daily_low(day, ArtPalette.BIOME_STEPPE, "", RouteWeather.CLEAR), "en soğuk saat 03:00")
	t.eq(Temperature.celsius(day, 9.0, "forest", "cold", RouteWeather.RAIN),
		Temperature.celsius(day, 9.0, "forest", "cold", RouteWeather.RAIN), "aynı gün aynı derece")

func _test_weather(t) -> void:
	var day := 50
	t.ok(Temperature.swing(ArtPalette.BIOME_STEPPE, RouteWeather.OVERCAST) < Temperature.swing(ArtPalette.BIOME_STEPPE, RouteWeather.CLEAR),
		"bulut gece-gündüz farkını kapatır")
	t.ok(Temperature.daily_mean(day, "meadow", "", RouteWeather.STORM) < Temperature.daily_mean(day, "meadow", "", RouteWeather.CLEAR),
		"fırtına soğutur")
	t.eq(Temperature.round_text(-4.4), "−4 °C", "eksi derece gerçek eksiyle")
	t.eq(Temperature.round_text(12.6), "13 °C", "derece yuvarlanır")

func _test_ration_share(t) -> void:
	t.almost(Temperature.ration_share(5.0), 0.0, "donmayan gün fazla yemiyor")
	t.almost(Temperature.ration_share(-1.0), Temperature.RATION_SHARE_FREEZE, "dondurucu gün çeyrek fazla")
	t.almost(Temperature.ration_share(-20.0), Temperature.RATION_SHARE_HARD, "ayaz yarım fazla")
	var base := CaravanPlan.daily_consumption(3, 2, 0)
	var cold := CaravanPlan.daily_consumption(3, 2, 0, 1.0 + Temperature.RATION_SHARE_HARD)
	t.ok(cold > base, "ayazda günlük erzak artıyor (%d > %d)" % [cold, base])

func _test_cold_load_and_clothes(t) -> void:
	t.almost(Temperature.cold_load(20.0, 0.0, false), 0.0, "ılık gece yük bırakmıyor")
	t.eq(Temperature.band(Temperature.cold_load(4.0, 4.0, false)), 0, "köylü takımı ılık gecede üşümez")
	t.eq(Temperature.band(Temperature.cold_load(-8.0, 4.0, false)), 2, "köylü takımıyla −8'de donar")
	t.eq(Temperature.band(Temperature.cold_load(-18.0, 4.0, false)), 3, "köylü takımıyla −18 ayaz")
	t.ok(Temperature.band(Temperature.cold_load(-8.0, 4.0, true)) < 2, "ateş başında daha hafif")
	t.eq(Temperature.band(Temperature.cold_load(-8.0, 19.0, false)), 0, "kalın giyinen −8'de ateşsiz de üşümüyor")
	var person := CharacterData.create("Deneme", CultureCatalog.VALLEY, CharacterStats.new())
	person.outfit = {}
	t.almost(person.get_warmth(), 0.0, "orta kilo, çıplak: sıcaklık sıfır (sistem yokmuş gibi)")
	person.body_weight = CharacterData.BODY_WEIGHT_HEAVY
	t.ok(person.get_warmth() > 0.0, "iri beden ısınır")
	person.body_weight = CharacterData.BODY_WEIGHT_AVERAGE
	person.set_outfit_piece(OutfitCatalog.SLOT_JACKET, "wool_coat")
	t.almost(person.get_warmth(), 6.0, "yün palto altı derece")

func _test_outfit_warmth(t) -> void:
	var best := {}
	for piece in OutfitCatalog.get_all_pieces():
		t.ge(float(piece.warmth), 0.0, "sıcaklık negatif değil: %s" % piece.piece_id)
		best[piece.slot] = maxi(int(best.get(piece.slot, 0)), piece.warmth)
	var top := 0
	for slot in best:
		top += int(best[slot])
	t.ge(float(top), 15.0, "kalın giyinmek mümkün (%d °C)" % top)
	t.ok(OutfitCatalog.bonus_text(OutfitCatalog.get_piece("wool_coat")).contains("°C"), "terzi satırı sıcaklığı söylüyor")

## Haritada olmayan yollar (tohumlu zincir): kış başlangıçları, üç tempo.
## Kervan planlayıcının tahmininden hızlı ya da yavaş yürüse de yol günü
## yemek, o gün kervanın gerçekten bulunduğu parçanın soğuğuyla.
func _test_cold_reserve_keeps_the_provision_promise(t) -> void:
	var destination := WorldMapData.get_locations()[0]
	var winter := MarketConditions.SEASON_LENGTH_DAYS * 3
	var starved := 0
	var any_cold := false
	for key in SAMPLE_KEYS:
		for travel_days in [3, 6, 10]:
			for start_day in [winter + 2, winter + 15, winter + 27, 40]:
				var terrain := RouteTerrain.build(key, travel_days)
				var plan := _plan(destination, key, start_day, terrain, travel_days)
				any_cold = any_cold or plan.get_cold_provisions() > 0
				for pace in [1.0, 1.35]:
					if _walk_starves(plan, key, start_day, terrain, travel_days, pace):
						starved += 1
	t.ok(any_cold, "kış yolunda soğuk payı var")
	t.eq(starved, 0, "soğuk payıyla stoklayan kervan kışın aç kalmıyor")

## Haritanın her yolu, kışın ortasında.
func _test_map_winter_reserve(t) -> void:
	var start_day := MarketConditions.SEASON_LENGTH_DAYS * 3 + 14
	var starved := 0
	var checked := 0
	for location in WorldMapData.get_locations():
		for route in WorldMapData.get_routes_from(location.location_id):
			var key := RouteConditions.route_key(location.location_id, route.to_location_id)
			var terrain := RouteTerrain.build(key, route.travel_days, location.location_id, MarketConditions.Season.WINTER)
			var plan := _plan(location, key, start_day, terrain, route.travel_days)
			checked += 1
			for pace in [1.0, 1.35]:
				if _walk_starves(plan, key, start_day, terrain, route.travel_days, pace):
					starved += 1
	t.ok(checked > 0, "haritanın yolları denendi")
	t.eq(starved, 0, "haritanın hiçbir yolunda kış payı yetmezlik etmiyor")

func _plan(destination: Location, key: String, start_day: int, terrain: RouteTerrain, travel_days: int) -> CaravanPlan:
	var plan := CaravanPlan.new(destination, travel_days, 6, 2)
	plan.caravan_party_size = 3
	plan.travel_reserve_days = int(ceil(RouteWeather.forecast_extra_days(key, start_day, terrain, travel_days)))
	plan.cold_ration_shares = Temperature.forecast_ration_shares(key, start_day, terrain, travel_days)
	return plan

func _walk_starves(plan: CaravanPlan, key: String, start_day: int, terrain: RouteTerrain, travel_days: int, pace: float) -> bool:
	var provisions := plan.get_required_provisions()
	var walked := 0.0
	var day := 0
	while walked < float(travel_days) and day < travel_days * 8 + 16:
		var segment := terrain.segment_at(walked)
		var share := Temperature.ration_share(Temperature.segment_low(key, start_day + day, segment))
		provisions -= CaravanPlan.daily_consumption(
			plan.caravan_party_size, plan.player_wagon_count, 0, 1.0 + share
		)
		if provisions < 0:
			return true
		var weather := RouteWeather.at(key, start_day + day, terrain.biome_at(walked))
		walked += RouteWeather.pace_multiplier(weather) * terrain.speed_factor_at(walked) * pace
		day += 1
	return false

func _session() -> GameSession:
	var session := GameSession.new(500, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	session.start_playthrough(
		CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng
	)
	return session

func _on_road(session: GameSession) -> void:
	var destination := WorldMapData.get_routes_from(session.current_location_id)[0]
	var plan := CaravanPlan.new(WorldMapData.get_location_by_id(destination.to_location_id), destination.travel_days)
	session.start_journey(destination.to_location_id, destination.travel_days, 0.2, plan)

func _test_session_cold_night(t) -> void:
	var session := _session()
	_on_road(session)
	var winter_day := MarketConditions.SEASON_LENGTH_DAYS * 3 + 14
	session.total_days_elapsed = winter_day
	var cold := session.get_party()[0]
	cold.outfit = {}
	var warm := session.get_party()[1]
	for piece in ["fur_hat", "fisherman_sweater", "wool_coat", "leather_gloves", "viking_pants", "riding_boots"]:
		warm.set_outfit_piece(OutfitCatalog.get_piece(piece).slot, piece)
	cold.stress = 0
	warm.stress = 0
	session.set_road_sky("a|b", winter_day, ArtPalette.BIOME_STEPPE, "cold", RouteWeather.CLEAR)
	t.ok(session.get_road_night_low() < -12.0, "kuzey bozkırının kış gecesi ayaz (%.1f)" % session.get_road_night_low())
	t.ok(session.get_cold_band(warm) < session.get_cold_band(cold), "kalın giyinen daha az üşür")
	t.ok(session.get_cold_band(warm, true) < session.get_cold_band(warm), "ateş ılıtır")
	# Yalnızca gecenin soğuğu: advance_day'in yol stresi ve öbür payları karışmasın.
	session._cold_night()
	t.ok(cold.stress > warm.stress, "giysisiz olan daha çok üşüdü (%d > %d)" % [cold.stress, warm.stress])
	t.ok(not session.cold_notes.is_empty(), "günlüğe soğuk notu düştü")

	# Ateş: aynı gece ateş başında kalın giyinen hiç üşümez.
	var fresh := _session()
	_on_road(fresh)
	fresh.total_days_elapsed = winter_day
	var a := fresh.get_party()[1]
	for piece in ["fur_hat", "fisherman_sweater", "wool_coat", "leather_gloves", "viking_pants", "riding_boots"]:
		a.set_outfit_piece(OutfitCatalog.get_piece(piece).slot, piece)
	a.body_weight = CharacterData.BODY_WEIGHT_AVERAGE
	a.stress = 0
	fresh.set_road_sky("a|b", winter_day, ArtPalette.BIOME_STEPPE, "cold", RouteWeather.CLEAR)
	fresh.last_fire_day = winter_day
	fresh._cold_night()
	t.eq(a.stress, 0, "kalın giyinen ateş başında ayazı atlatır")

	var copy := GameSession.new(0, 0, 1)
	copy.load_from_dict(JSON.parse_string(JSON.stringify(fresh.to_save_dict())))
	t.eq(copy.last_fire_day, fresh.last_fire_day, "ateşin günü kayıtta kalır")

func _test_session_ration(t) -> void:
	var session := _session()
	var city := session.get_daily_provision_consumption()
	session.set_road_sky("a|b", MarketConditions.SEASON_LENGTH_DAYS * 3 + 14, ArtPalette.BIOME_MOUNTAIN, "cold", RouteWeather.STORM)
	t.eq(session.get_daily_provision_consumption(), city, "şehirde soğuk payı yok")
	_on_road(session)
	session.set_road_sky("a|b", MarketConditions.SEASON_LENGTH_DAYS * 3 + 14, ArtPalette.BIOME_MOUNTAIN, "cold", RouteWeather.STORM)
	t.ok(session.get_daily_provision_consumption() > city, "ayazda yolda daha çok yeniyor")
	session.set_road_sky("a|b", MarketConditions.SEASON_LENGTH_DAYS + 14, ArtPalette.BIOME_MEADOW, "warm", RouteWeather.CLEAR)
	t.eq(session.get_daily_provision_consumption(), city, "yazın pay yok")
