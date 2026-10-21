extends RefCounted

## Yolun coğrafyası ve havası. İkisi de "hesaplanır, saklanmaz" ailesinden
## (bkz. test_route_conditions.gd), o yüzden kilitlenen ilk şey aynı:
## kaydı yeniden yükleyen oyuncu aynı yolu ve aynı havayı buluyor.
##
## İkinci kilit daha önemli: hava **yeni bir sistem uydurmuyor**. Bütün
## etkisi var olan kolları çeviriyor ve açık hava tam nötr - yoksa hava
## bir olay olmaktan çıkıp her sefere binen gizli bir vergi olur, ki bu
## tam olarak kıtlık hatasının yaptığı şeydi (bkz. Provision Rules).

const SAMPLE_KEYS: Array[String] = [
	"loc_karakonak|loc_kurtbogazi",
	"loc_ipekevi|loc_kurtbogazi",
	"loc_demirkapi|loc_ipekevi",
	"loc_karakonak|loc_yesilova",
	"loc_demirkapi|loc_yesilova",
]

func suite_name() -> String:
	return "RouteTerrain"

func run(t) -> void:
	_test_terrain_is_reproducible(t)
	_test_terrain_varies_between_routes(t)
	_test_segments_cover_the_whole_route(t)
	_test_segment_lookup_never_falls_off(t)
	_test_biomes_do_not_jump(t)
	_test_stops_never_land_on_the_city(t)
	_test_colors_exist_for_every_day(t)
	_test_every_biome_and_stop_is_named(t)
	_test_weather_is_reproducible(t)
	_test_weather_changes_from_day_to_day(t)
	_test_clear_weather_is_neutral(t)
	_test_weather_levers_stay_in_range(t)
	_test_biome_bias_actually_biases(t)
	_test_visuals_match_the_mechanics(t)
	_test_weather_reserve_keeps_the_provision_promise(t)
	_test_condition_reserve_keeps_the_provision_promise(t)
	_test_weather_reserve_stays_proportionate(t)
	_test_slope_speed_factor_stays_in_range(t)
	_test_terrain_reserve_keeps_the_provision_promise(t)
	_test_camp_order_reserve_keeps_the_provision_promise(t)
	_test_map_terrain_covers_every_route(t)
	_test_map_terrain_mirrors_by_direction(t)
	_test_map_terrain_follows_geography(t)
	_test_map_routes_keep_the_provision_promise(t)
	_test_seasons_and_shortcuts(t)
	_test_river_fords(t)
	_test_map_looks(t)

func _test_terrain_is_reproducible(t) -> void:
	for key in SAMPLE_KEYS:
		var first := RouteTerrain.build(key, 5)
		var second := RouteTerrain.build(key, 5)
		t.eq(
			first.segments.size(), second.segments.size(),
			"aynı anahtar aynı parça sayısını vermeli (%s)" % key
		)
		for index in first.segments.size():
			t.eq(
				String(first.segments[index].biome), String(second.segments[index].biome),
				"aynı anahtar aynı biyomu vermeli (%s/%d)" % [key, index]
			)
			t.eq(
				String(first.segments[index].stop), String(second.segments[index].stop),
				"aynı anahtar aynı durağı vermeli (%s/%d)" % [key, index]
			)
			t.almost(
				first.segments[index].slope, second.segments[index].slope,
				"aynı anahtar aynı eğimi vermeli (%s/%d)" % [key, index]
			)

## Beş rotanın hepsi aynı araziden geçiyorsa tohum işe yaramıyor demektir:
## "farklı yollarda yol da değişmeli" kuralı bu.
func _test_terrain_varies_between_routes(t) -> void:
	var signatures := {}
	for key in SAMPLE_KEYS:
		var terrain := RouteTerrain.build(key, 5)
		var parts: Array[String] = []
		for segment in terrain.segments:
			parts.append(String(segment.biome))
		signatures["|".join(parts)] = true
	t.ge(
		float(signatures.size()), 2.0,
		"farklı rotalar aynı araziyi tekrarlamamalı"
	)

func _test_segments_cover_the_whole_route(t) -> void:
	for days in [1, 2, 3, 5, 8]:
		for key in SAMPLE_KEYS:
			var terrain := RouteTerrain.build(key, days)
			t.ge(float(terrain.segments.size()), 1.0, "her yolun en az bir parçası olmalı")
			t.almost(
				float(terrain.segments[0].from_day), 0.0,
				"ilk parça sıfırdan başlamalı (%s/%d)" % [key, days]
			)
			t.almost(
				float(terrain.segments[-1].to_day), float(days),
				"son parça varışta bitmeli (%s/%d)" % [key, days]
			)
			for index in range(1, terrain.segments.size()):
				t.almost(
					float(terrain.segments[index].from_day),
					float(terrain.segments[index - 1].to_day),
					"parçalar arasında boşluk olmamalı (%s/%d/%d)" % [key, days, index]
				)
			for segment in terrain.segments:
				var length := float(segment.to_day) - float(segment.from_day)
				t.ge(length, 0.0, "parça geriye doğru olmamalı")
				if terrain.segments.size() > 1:
					# Tek parçalı bir yol tanım gereği tüm süre kadardır;
					# asgari uzunluk kuralı ancak bölünme varsa anlamlı.
					t.ge(
						length, RouteTerrain.MIN_SEGMENT_DAYS - 0.001,
						"okunmayacak kadar kısa parça olmamalı (%s/%d)" % [key, days]
					)

## Varış anında `day == total_days` geliyor ve son parça okunmalı; bunun
## kırılması ekranın son gününde arazinin bozkıra dönmesi demek.
func _test_segment_lookup_never_falls_off(t) -> void:
	var terrain := RouteTerrain.build(SAMPLE_KEYS[0], 6)
	var probes: Array[float] = [-3.0, 0.0, 0.01, 2.5, 5.999, 6.0, 9.0]
	for day in probes:
		var segment := terrain.segment_at(day)
		t.ok(segment.has("biome"), "her gün bir parçaya düşmeli (%s)" % str(day))
		t.ok(
			ArtPalette.TERRAIN.has(terrain.biome_at(day)),
			"biyom palette tanımlı olmalı (%s)" % str(day)
		)
		t.le(absf(terrain.slope_at(day)), 0.7, "eğim sınırda kalmalı (%s)" % str(day))

func _test_biomes_do_not_jump(t) -> void:
	for key in SAMPLE_KEYS:
		var terrain := RouteTerrain.build(key, 8)
		for index in range(1, terrain.segments.size()):
			var previous := RouteTerrain.BIOME_CHAIN.find(String(terrain.segments[index - 1].biome))
			var current := RouteTerrain.BIOME_CHAIN.find(String(terrain.segments[index].biome))
			t.ge(float(previous), 0.0, "biyom zincirde olmalı")
			t.le(
				float(absi(current - previous)), 2.0,
				"bozkırdan dağa sıçranmamalı (%s/%d)" % [key, index]
			)

func _test_stops_never_land_on_the_city(t) -> void:
	for key in SAMPLE_KEYS:
		var terrain := RouteTerrain.build(key, 7)
		t.eq(
			String(terrain.segments[-1].stop), RouteTerrain.STOP_NONE,
			"son parçanın sonu şehir, orada ara durak olmamalı (%s)" % key
		)
		for stop in terrain.get_stops():
			t.ne(
				String(stop.stop), RouteTerrain.STOP_NONE,
				"durak listesi boş durak taşımamalı"
			)
			t.ok(
				float(stop.day) > 0.0 and float(stop.day) < float(terrain.total_days),
				"durak yolun içinde olmalı (%s)" % key
			)

func _test_colors_exist_for_every_day(t) -> void:
	var terrain := RouteTerrain.build(SAMPLE_KEYS[1], 5)
	for step in 21:
		var day := float(step) * 0.25
		var colors := terrain.terrain_colors_at(day)
		for role in ["near", "far", "flora", "accent"]:
			t.ok(
				colors.has(role),
				"arazi rengi '%s' rolünü taşımalı (%s)" % [role, str(day)]
			)

func _test_every_biome_and_stop_is_named(t) -> void:
	for biome in ArtPalette.TERRAIN.keys():
		var key := RouteTerrain.biome_name_key(String(biome))
		t.ne(tr(key), key, "biyom adı çeviride tanımlı olmalı (%s)" % biome)
	var stops: Array[String] = [
		RouteTerrain.STOP_MEZRA, RouteTerrain.STOP_OUTPOST, RouteTerrain.STOP_MINE,
		RouteTerrain.STOP_PASS, RouteTerrain.STOP_SHRINE, RouteTerrain.STOP_BRIDGE,
	]
	for stop in stops:
		var key := RouteTerrain.stop_name_key(stop)
		t.ne(tr(key), key, "durak adı çeviride tanımlı olmalı (%s)" % stop)

func _test_weather_is_reproducible(t) -> void:
	for key in SAMPLE_KEYS:
		for day in 12:
			var biome := RouteTerrain.build(key, 5).biome_at(float(day))
			t.eq(
				RouteWeather.at(key, day, biome), RouteWeather.at(key, day, biome),
				"aynı gün aynı yolda aynı hava olmalı (%s/%d)" % [key, day]
			)

## Hava her gün aynı kalıyorsa tohumda günü kullanmıyoruz demektir -
## sefer boyunca tek bir hava, aslında hiç hava olmaması gibi.
func _test_weather_changes_from_day_to_day(t) -> void:
	var seen := {}
	for day in 60:
		seen[RouteWeather.at(SAMPLE_KEYS[2], day, ArtPalette.BIOME_STEPPE)] = true
	t.ge(float(seen.size()), 3.0, "hava günlere göre değişmeli")

## En sık hava tam nötr olmalı: kervan çoğu gün havadan etkilenmemeli,
## yoksa `PACE`/`DANGER_DELTA` ölçülmüş dengeye sessiz bir zam biner.
func _test_clear_weather_is_neutral(t) -> void:
	t.almost(RouteWeather.pace_multiplier(RouteWeather.CLEAR), 1.0, "açık hava yolu yavaşlatmamalı")
	t.almost(RouteWeather.danger_delta(RouteWeather.CLEAR), 0.0, "açık hava tehlikeyi artırmamalı")
	t.eq(RouteWeather.morale_bite(RouteWeather.CLEAR), 0, "açık hava morali kırmamalı")
	var visuals := RouteWeather.visuals(RouteWeather.CLEAR)
	t.almost(float(visuals.rain), 0.0, "açık havada yağmur çizilmemeli")
	t.almost(float(visuals.fog), 0.0, "açık havada sis çizilmemeli")
	t.almost(float(visuals.gloom), 0.0, "açık hava gökyüzünü karartmamalı")
	t.eq(
		RouteWeather.WEIGHTS.keys().reduce(
			func(best, kind): return kind if float(RouteWeather.WEIGHTS[kind]) > float(RouteWeather.WEIGHTS[best]) else best,
			RouteWeather.CLEAR
		),
		RouteWeather.CLEAR,
		"açık hava en ağır seçenek olmalı"
	)

func _test_weather_levers_stay_in_range(t) -> void:
	var kinds: Array[String] = [
		RouteWeather.CLEAR, RouteWeather.OVERCAST, RouteWeather.RAIN,
		RouteWeather.FOG, RouteWeather.STORM,
	]
	for kind in kinds:
		var pace := RouteWeather.pace_multiplier(kind)
		t.ok(pace > 0.0 and pace <= 1.0, "hava yolu hızlandırmamalı, durdurmamalı (%s)" % kind)
		var delta := RouteWeather.danger_delta(kind)
		t.ok(delta >= 0.0 and delta < 1.0, "tehlike zammı başlıktaki payda kalmalı (%s)" % kind)
		t.le(float(RouteWeather.morale_bite(kind)), 0.0, "hava moral vermemeli (%s)" % kind)
		var visuals := RouteWeather.visuals(kind)
		for role in ["rain", "fog", "gloom"]:
			t.ok(visuals.has(role), "görsel '%s' değerini taşımalı (%s)" % [role, kind])
			t.ok(
				float(visuals[role]) >= 0.0 and float(visuals[role]) <= 1.0,
				"görsel yoğunluk 0-1 arasında olmalı (%s/%s)" % [kind, role]
			)
		var name_key := RouteWeather.name_key(kind)
		t.ne(tr(name_key), name_key, "hava adı çeviride tanımlı olmalı (%s)" % kind)
	# Bilinmeyen bir hava adı nötr davranmalı: eksik bir anahtar oyunu
	# yavaşlatan sessiz bir cezaya dönüşmesin.
	t.almost(RouteWeather.pace_multiplier("kar_firtinasi"), 1.0, "tanımsız hava nötr olmalı")

## `test_traits.gd`'nin ezici-fark deseni: tek bir zarı değil, dağılımı
## kontrol ediyoruz. Bataklıkta bozkırdan belirgin şekilde daha sisli
## olmalı, yoksa BIOME_BIAS tablosu bağlanmamış demektir.
func _test_biome_bias_actually_biases(t) -> void:
	var samples := 900
	var marsh_fog := 0
	var steppe_fog := 0
	var steppe_clear := 0
	var marsh_clear := 0
	for day in samples:
		if RouteWeather.at("bias_probe", day, ArtPalette.BIOME_MARSH) == RouteWeather.FOG:
			marsh_fog += 1
		if RouteWeather.at("bias_probe", day, ArtPalette.BIOME_STEPPE) == RouteWeather.FOG:
			steppe_fog += 1
		if RouteWeather.at("bias_probe", day, ArtPalette.BIOME_STEPPE) == RouteWeather.CLEAR:
			steppe_clear += 1
		if RouteWeather.at("bias_probe", day, ArtPalette.BIOME_MARSH) == RouteWeather.CLEAR:
			marsh_clear += 1
	t.ge(
		float(marsh_fog), float(steppe_fog) * 2.0,
		"bataklık bozkırdan belirgin şekilde daha sisli olmalı (%d vs %d)" % [marsh_fog, steppe_fog]
	)
	t.ge(
		float(steppe_clear), float(marsh_clear) * 1.2,
		"bozkır açık kalmaya meyilli olmalı (%d vs %d)" % [steppe_clear, marsh_clear]
	)
	var mountain_storm := 0
	var steppe_storm := 0
	for day in samples:
		if RouteWeather.at("bias_probe", day, ArtPalette.BIOME_MOUNTAIN) == RouteWeather.STORM:
			mountain_storm += 1
		if RouteWeather.at("bias_probe", day, ArtPalette.BIOME_STEPPE) == RouteWeather.STORM:
			steppe_storm += 1
	t.ge(
		float(mountain_storm), float(steppe_storm) * 1.5,
		"dağda fırtına daha sık olmalı (%d vs %d)" % [mountain_storm, steppe_storm]
	)

## Görsel ile mekanik aynı tablodan çıkmalı: fırtına en çok yavaşlatan
## hava ise ekranda da en karanlık olan o olmalı. İkisi ayrışırsa oyuncu
## gördüğüyle hissettiği arasında bağ kuramaz.
func _test_visuals_match_the_mechanics(t) -> void:
	var kinds: Array[String] = [
		RouteWeather.CLEAR, RouteWeather.OVERCAST, RouteWeather.RAIN,
		RouteWeather.FOG, RouteWeather.STORM,
	]
	var slowest := RouteWeather.CLEAR
	var gloomiest := RouteWeather.CLEAR
	for kind in kinds:
		if RouteWeather.pace_multiplier(kind) < RouteWeather.pace_multiplier(slowest):
			slowest = kind
		if float(RouteWeather.visuals(kind).gloom) > float(RouteWeather.visuals(gloomiest).gloom):
			gloomiest = kind
	t.eq(slowest, gloomiest, "en çok yavaşlatan hava ekranda da en ağır olmalı")
	t.ge(
		RouteWeather.danger_delta(RouteWeather.FOG),
		RouteWeather.danger_delta(RouteWeather.RAIN),
		"görüş kapatan hava yağmurdan daha tehlikeli olmalı"
	)
	t.ge(
		float(RouteWeather.visuals(RouteWeather.FOG).fog),
		float(RouteWeather.visuals(RouteWeather.RAIN).fog),
		"sis ekranda da yağmurdan daha yoğun olmalı"
	)

## Bu paketin en önemli iddiası. "Doğru stoklayan asla aç kalmaz"
## (bkz. Provision Rules) sözü havadan önce kolaydı: yol tam `travel_days`
## sürüyordu. Hava yolu yavaşlattığı an aynı rota daha çok gün yemeye
## başlıyor, yani söz ancak planlayıcı bu payı önceden isterse duruyor.
##
## Burada uçtan uca doğrulanan şey: planın istediği erzakla yola çıkan
## kervan, hava ne olursa olsun, yol bitmeden erzağı tüketmiyor.
## Yürüme satırı yol ekranının `_walk_at`'inin aynısı - headless bir test
## ekran betiğini koşturamıyor, o yüzden `playthrough_demo.gd`'nin
## yaptığının aynısını yapıyor: yolun `_process` sırasını bilerek
## taklit ediyor.
func _test_weather_reserve_keeps_the_provision_promise(t) -> void:
	var destination := WorldMapData.get_locations()[0]
	var starved := 0
	var checked := 0
	for key in SAMPLE_KEYS:
		for travel_days in [2, 3, 5, 7]:
			for start_day in [1, 14, 47, 103]:
				var terrain := RouteTerrain.build(key, travel_days)
				var plan := CaravanPlan.new(destination, travel_days, 6, 2)
				plan.caravan_party_size = 3
				plan.travel_reserve_days = int(ceil(
					RouteWeather.forecast_extra_days(key, start_day, terrain, travel_days)
				))

				var provisions := plan.get_required_provisions()
				var daily := plan.get_daily_consumption()
				var walked := 0.0
				var day := 0
				# Yol bitene kadar ileri yürüyoruz; her gün erzak yeniyor.
				while walked < float(travel_days) and day < travel_days * 4 + 10:
					var weather := RouteWeather.at(
						key, start_day + day, terrain.biome_at(walked)
					)
					provisions -= daily
					if provisions < 0:
						starved += 1
						break
					# Faz 17 PR-6: forecast_extra_days() eğimi de hesaba katıyor
					# artık (terrain != null verildiğinde hep) - buradaki elle
					# yürüyüş de aynı çarpanı okumalı, yoksa reserve inişli bir
					# rotada gerçek yürüyüşten daha hızlı bir yürüyüş varsayıp
					# payı küçültür.
					walked += RouteWeather.pace_multiplier(weather) * terrain.speed_factor_at(walked)
					day += 1
				checked += 1
				t.ge(
					float(walked), float(travel_days) - 0.001,
					"yol bitmeden erzak tükenmemeli (%s/%d gün/%d. gün)" % [key, travel_days, start_day]
				)
	t.eq(starved, 0, "hava payıyla stoklayan kervan hiç aç kalmamalı")

## Aynı söz, bu kez hava **ve** kervanın kendi kondisyonu (yüklü vagon,
## yaralı/kırılmış bir parti üyesi) birlikte yavaşlatırken - bkz.
## GameSession.get_caravan_theoretical_speed, road_journey.gd'nin
## `_walk_at()`'i. `forecast_extra_days`'in `condition_factor` parametresi
## ikisini aynı günlük yürüyüşte çarpıyor; burada da öyle yapılmalı, ayrı
## ayrı hesaplayıp toplamak (bileşik yavaşlamayı hafife alır) değil.
func _test_condition_reserve_keeps_the_provision_promise(t) -> void:
	var destination := WorldMapData.get_locations()[0]
	var starved := 0
	for key in SAMPLE_KEYS:
		for travel_days in [3, 5, 7]:
			for condition in [1.0, 0.85, GameSession.WAGON_MIN_SPEED_FACTOR]:
				var terrain := RouteTerrain.build(key, travel_days)
				var plan := CaravanPlan.new(destination, travel_days, 6, 2)
				plan.caravan_party_size = 3
				plan.travel_reserve_days = int(ceil(
					RouteWeather.forecast_extra_days(key, 1, terrain, travel_days, condition)
				))

				var provisions := plan.get_required_provisions()
				var daily := plan.get_daily_consumption()
				var walked := 0.0
				var day := 0
				while walked < float(travel_days) and day < travel_days * 8 + 16:
					var weather := RouteWeather.at(key, 1 + day, terrain.biome_at(walked))
					provisions -= daily
					if provisions < 0:
						starved += 1
						break
					# Faz 17 PR-6: eğim de aynı günlük yürüyüşün içinde.
					walked += RouteWeather.pace_multiplier(weather) * condition * terrain.speed_factor_at(walked)
					day += 1
				t.ge(
					float(walked), float(travel_days) - 0.001,
					"kondisyon payıyla stoklayan kervan yol bitmeden aç kalmamalı (%s/%d gün/%.2f kondisyon)"
						% [key, travel_days, condition]
				)
	t.eq(starved, 0, "kondisyon payıyla stoklayan kervan hiç aç kalmamalı")

## Pay orantılı kalmalı: kötü hava yolu uzatıyor ama yolculuğu ikiye
## katlamıyor. Payın kontrolsüz büyümesi, erzak maliyetinin ticareti
## öldürmesi demek - ve bu ölçülmeden görünmez.
func _test_weather_reserve_stays_proportionate(t) -> void:
	var worst := 0
	for key in SAMPLE_KEYS:
		for travel_days in [2, 4, 6, 8]:
			var terrain := RouteTerrain.build(key, travel_days)
			for start_day in range(1, 40):
				var extra := int(ceil(
					RouteWeather.forecast_extra_days(key, start_day, terrain, travel_days)
				))
				t.ge(float(extra), 0.0, "hava payı negatif olamaz")
				worst = maxi(worst, extra)
				t.le(
					float(extra), float(travel_days),
					"hava payı yolun kendisinden uzun olmamalı (%s/%d)" % [key, travel_days]
				)
	# Sıfır çıkıyorsa hava yolu hiç yavaşlatmıyor demektir, yani mekanik
	# kol bağlanmamış - görsel bir süsten ibaret kalmış olur.
	t.ge(float(worst), 1.0, "en azından bazı seferlerde hava payı çıkmalı")

## Faz 17 PR-6: eğim artık gerçek bir yavaşlatıcı/hızlandırıcı.
func _test_slope_speed_factor_stays_in_range(t) -> void:
	var flat := RouteTerrain.new()
	flat.segments = [{
		"biome": ArtPalette.BIOME_STEPPE, "from_day": 0.0, "to_day": 5.0,
		"stop": RouteTerrain.STOP_NONE, "slope": RouteTerrain.SLOPE_FLAT,
	}]
	flat.total_days = 5
	t.ok(is_equal_approx(flat.speed_factor_at(2.0), 1.0), "düz arazide çarpan tam 1.0")

	var uphill := RouteTerrain.new()
	uphill.segments = [{
		"biome": ArtPalette.BIOME_MOUNTAIN, "from_day": 0.0, "to_day": 5.0,
		"stop": RouteTerrain.STOP_NONE, "slope": 0.7,
	}]
	uphill.total_days = 5
	t.ok(uphill.speed_factor_at(2.0) < 1.0, "tırmanış yavaşlatır")
	t.ge(uphill.speed_factor_at(2.0), RouteTerrain.MIN_SLOPE_SPEED_FACTOR, "yavaşlama tabanın altına inmez")

	var downhill := RouteTerrain.new()
	downhill.segments = [{
		"biome": ArtPalette.BIOME_LAKE, "from_day": 0.0, "to_day": 5.0,
		"stop": RouteTerrain.STOP_NONE, "slope": -0.7,
	}]
	downhill.total_days = 5
	t.ok(downhill.speed_factor_at(2.0) > 1.0, "iniş hafifçe hızlandırır")
	t.le(downhill.speed_factor_at(2.0), RouteTerrain.MAX_SLOPE_SPEED_FACTOR, "hızlanma tavanı aşmaz")

	# Bütün gerçek rotalarda da tavan/tabanın içinde kalmalı.
	for key in SAMPLE_KEYS:
		var terrain := RouteTerrain.build(key, 6)
		var day := 0.0
		while day <= 6.0:
			var factor := terrain.speed_factor_at(day)
			t.ge(factor, RouteTerrain.MIN_SLOPE_SPEED_FACTOR, "eğim çarpanı tabanda kenetli (%s)" % key)
			t.le(factor, RouteTerrain.MAX_SLOPE_SPEED_FACTOR, "eğim çarpanı tavanda kenetli (%s)" % key)
			day += 0.5

## Aynı söz, bu kez eğim de hava ve kondisyonla birlikte yavaşlatırken -
## `forecast_extra_days()`'in eğim payı, gerçek yürüyüşün (burada elle
## simüle edilen) aynı çarpanını okumalı, yoksa tırmanışlı bir rotada
## erzak sözü sessizce bozulur (bkz. hava/kondisyon testlerinin aynısı).
func _test_terrain_reserve_keeps_the_provision_promise(t) -> void:
	var destination := WorldMapData.get_locations()[0]
	var starved := 0
	for key in SAMPLE_KEYS:
		for travel_days in [3, 5, 7]:
			var terrain := RouteTerrain.build(key, travel_days)
			var plan := CaravanPlan.new(destination, travel_days, 6, 2)
			plan.caravan_party_size = 3
			plan.travel_reserve_days = int(ceil(
				RouteWeather.forecast_extra_days(key, 1, terrain, travel_days)
			))

			var provisions := plan.get_required_provisions()
			var daily := plan.get_daily_consumption()
			var walked := 0.0
			var day := 0
			while walked < float(travel_days) and day < travel_days * 8 + 16:
				var weather := RouteWeather.at(key, 1 + day, terrain.biome_at(walked))
				provisions -= daily
				if provisions < 0:
					starved += 1
					break
				walked += RouteWeather.pace_multiplier(weather) * terrain.speed_factor_at(walked)
				day += 1
			t.ge(
				float(walked), float(travel_days) - 0.001,
				"eğim payıyla stoklayan kervan yol bitmeden aç kalmamalı (%s/%d gün)" % [key, travel_days]
			)
	t.eq(starved, 0, "eğim payıyla stoklayan kervan hiç aç kalmamalı")

## Akşam kampı emri: her gün sekiz saat yol alınmıyor ve her akşam ateş
## kendi erzağını yiyor. Kalıcı bir emir sözü sessizce bozmamalı - planlayıcı
## emri biliyorsa, onun istediğini alan kervan yine aç kalmaz.
func _test_camp_order_reserve_keeps_the_provision_promise(t) -> void:
	var destination := WorldMapData.get_locations()[0]
	var walking_hours := 24.0 - GameSession.CAMP_HOURS
	var starved := 0
	for key in SAMPLE_KEYS:
		for travel_days in [3, 5, 7]:
			var terrain := RouteTerrain.build(key, travel_days)
			var plan := CaravanPlan.new(destination, travel_days, 6, 2)
			plan.caravan_party_size = 3
			plan.travel_reserve_days = int(ceil(RouteWeather.forecast_extra_days(
				key, 1, terrain, travel_days, 1.0, walking_hours
			)))
			plan.camp_provisions = GameSession.CAMP_PROVISIONS_COST * plan.get_provisioned_days()
			t.ok(plan.travel_reserve_days > 0, "kamp emri yolu uzatıyor (%s/%d)" % [key, travel_days])

			var provisions := plan.get_required_provisions()
			var daily := plan.get_daily_consumption()
			var walked := 0.0
			var day := 0
			while walked < float(travel_days) and day < travel_days * 8 + 16:
				var weather := RouteWeather.at(key, 1 + day, terrain.biome_at(walked))
				provisions -= daily + GameSession.CAMP_PROVISIONS_COST
				if provisions < 0:
					starved += 1
					break
				walked += (
					RouteWeather.pace_multiplier(weather) * terrain.speed_factor_at(walked)
					* walking_hours / 24.0
				)
				day += 1
	t.eq(starved, 0, "kamp emrini bilen planlayıcıyla stoklayan kervan aç kalmaz")

# --- Haritadan gelen arazi (yol biyomları haritaya bağlı) -----------------

## Haritanın her yolu, iki yönden. `[çıkış, varış, gün, anahtar]`.
func _map_legs() -> Array:
	var legs: Array = []
	for location in WorldMapData.get_locations():
		for route in WorldMapData.get_routes_from(location.location_id):
			legs.append([location.location_id, route.to_location_id, route.travel_days,
				RouteConditions.route_key(location.location_id, route.to_location_id)])
	return legs

func _test_map_terrain_covers_every_route(t) -> void:
	var legs := _map_legs()
	t.ge(float(legs.size()), 80.0, "haritanın 41 yolu iki yönden okunmalı")
	for leg in legs:
		var terrain := RouteTerrain.build(String(leg[3]), int(leg[2]), String(leg[0]))
		t.ok(not WorldMapData.get_route_terrain(String(leg[3])).is_empty(),
			"yolun haritadan arazisi var: %s" % leg[3])
		var cursor := 0.0
		for segment in terrain.segments:
			t.almost(float(segment.from_day), cursor, "parçalar boşluksuz: %s>%s" % [leg[0], leg[1]])
			t.ok(float(segment.to_day) >= float(segment.from_day), "parça geri gitmiyor: %s>%s" % [leg[0], leg[1]])
			cursor = float(segment.to_day)
		t.almost(cursor, float(leg[2]), "arazi yolun sonuna kadar: %s>%s" % [leg[0], leg[1]])
		t.eq(String(terrain.segments[-1].stop), RouteTerrain.STOP_NONE,
			"son parçanın sonu şehir, durak değil: %s>%s" % [leg[0], leg[1]])

## Aynı yol öbür yönden: biyomlar ters sırada, duraklar aynı yerlerde
## (günü yolun öbür ucundan sayılarak), eğimler aynı.
func _test_map_terrain_mirrors_by_direction(t) -> void:
	for leg in _map_legs():
		var key := String(leg[3])
		var days := int(leg[2])
		var forth := RouteTerrain.build(key, days, String(leg[0]))
		var back := RouteTerrain.build(key, days, String(leg[1]))
		var n := forth.segments.size()
		t.eq(back.segments.size(), n, "iki yön aynı sayıda parça: %s" % key)
		for k in n:
			var a: Dictionary = forth.segments[k]
			var b: Dictionary = back.segments[n - 1 - k]
			t.eq(String(a.biome), String(b.biome), "ters yönde biyom aynı yerde: %s" % key)
			t.almost(float(a.to_day), float(days) - float(b.from_day), "sınır aynada: %s" % key)
			t.almost(float(a.slope), float(b.slope), "eğim iki yönde aynı: %s" % key)
		var forth_stops := forth.get_stops()
		var back_stops := back.get_stops()
		t.eq(back_stops.size(), forth_stops.size(), "iki yönde aynı sayıda durak: %s" % key)
		if back_stops.size() == forth_stops.size():
			var m := forth_stops.size()
			for j in m:
				var there: Dictionary = forth_stops[j]
				var here: Dictionary = back_stops[m - 1 - j]
				t.eq(String(here.stop), String(there.stop), "durak iki yönde aynı: %s" % key)
				t.almost(float(days) - float(here.day), float(there.day), "durak iki yönde aynı yerde: %s" % key)

## Coğrafya: kullanıcının kuralı "coğrafya gerçeklerini düşünmeden
## ilerleme". İlk sürümde vadideki Belvanor-İlsande yolu dağ yolu çıkıyordu.
func _test_map_terrain_follows_geography(t) -> void:
	var vale := RouteTerrain.build(RouteConditions.route_key("belvanor", "ilsande"), 6, "belvanor")
	for segment in vale.segments:
		t.ne(String(segment.biome), ArtPalette.BIOME_MOUNTAIN, "vadi yolu dağ değil")
	t.eq(vale.biome_at(3.0), ArtPalette.BIOME_MEADOW, "vadinin açık arazisi çayır (N29)")
	var peaks := RouteTerrain.build(RouteConditions.route_key("brazdun", "kesgrav"), 2, "brazdun")
	t.eq(peaks.biome_at(1.0), ArtPalette.BIOME_MOUNTAIN, "dağ kabilelerinin yolu dağ")
	var swamp := RouteTerrain.build(RouteConditions.route_key("golcavar", "ezmerak"), 2, "golcavar")
	t.eq(swamp.biome_at(0.5), ArtPalette.BIOME_MARSH, "bataklık kasabasının çıkışı bataklık")
	var seen := {}
	for leg in _map_legs():
		for segment in RouteTerrain.build(String(leg[3]), int(leg[2]), String(leg[0])).segments:
			seen[String(segment.biome)] = true
	t.eq(seen.size(), RouteTerrain.BIOME_CHAIN.size(), "haritada altı biyomun hepsi var")

## Erzak vaadi haritanın gerçek yollarında da: planlayıcının eğim ve hava
## payını alan kervan yolun sonuna aç varmaz (uzun yollar dahil, 38 güne dek).
func _test_map_routes_keep_the_provision_promise(t) -> void:
	var destination := WorldMapData.get_locations()[0]
	var starved := 0
	for leg in _map_legs():
		var key := String(leg[3])
		var travel_days := int(leg[2])
		var terrain := RouteTerrain.build(key, travel_days, String(leg[0]))
		var plan := CaravanPlan.new(destination, travel_days, 6, 2)
		plan.caravan_party_size = 3
		plan.travel_reserve_days = int(ceil(RouteWeather.forecast_extra_days(key, 1, terrain, travel_days)))
		var provisions := plan.get_required_provisions()
		var daily := plan.get_daily_consumption()
		var walked := 0.0
		var day := 0
		while walked < float(travel_days) and day < travel_days * 8 + 16:
			var weather := RouteWeather.at(key, 1 + day, terrain.biome_at(walked))
			provisions -= daily
			if provisions < 0:
				starved += 1
				break
			walked += RouteWeather.pace_multiplier(weather) * terrain.speed_factor_at(walked)
			day += 1
	t.eq(starved, 0, "haritanın hiçbir yolunda payıyla stoklayan kervan aç kalmamalı")

## Aynı rotada farklı yol (görev Y-B13): her mevsim ve kestirme arazisi yolu
## boşluksuz kaplar, şehirde durmaz, erzak sözünü tutar; mevsim gerçekten
## araziyi değiştirir, kestirme gerçekten kısalır ve zor araziden geçer.
func _biomes(terrain: RouteTerrain) -> Array:
	var out: Array = []
	for segment in terrain.segments:
		out.append(String(segment.biome))
	return out

func _test_seasons_and_shortcuts(t) -> void:
	var destination := WorldMapData.get_locations()[0]
	var gaps := 0
	var starved := 0
	var seasonal := 0
	var shortcuts := 0
	var rough_middle := true
	var winter_slower := true
	for leg in _map_legs():
		var key := String(leg[3])
		var base_days := int(leg[2])
		var spring := RouteTerrain.build(key, base_days, String(leg[0]), MarketConditions.Season.SPRING)
		var summer := RouteTerrain.build(key, base_days, String(leg[0]), MarketConditions.Season.SUMMER)
		if _biomes(spring) != _biomes(summer):
			seasonal += 1
		var winter := RouteTerrain.build(key, base_days, String(leg[0]), MarketConditions.Season.WINTER)
		var autumn := RouteTerrain.build(key, base_days, String(leg[0]), MarketConditions.Season.AUTUMN)
		for i in winter.segments.size():
			if winter.speed_factor_at(float(winter.segments[i].from_day) + 0.01) > autumn.speed_factor_at(float(autumn.segments[i].from_day) + 0.01) + 1e-6:
				winter_slower = false
		for season in 4:
			for shortcut in [false, true]:
				if shortcut and not RouteTerrain.shortcut_available(base_days):
					continue
				var days := RouteTerrain.shortcut_days(base_days) if shortcut else base_days
				var terrain := RouteTerrain.build(key, days, String(leg[0]), season, shortcut)
				var cursor := 0.0
				for segment in terrain.segments:
					if absf(float(segment.from_day) - cursor) > 1e-4 or float(segment.to_day) < float(segment.from_day):
						gaps += 1
					cursor = float(segment.to_day)
				if absf(cursor - float(days)) > 1e-4 or String(terrain.segments[-1].stop) != RouteTerrain.STOP_NONE:
					gaps += 1
				if shortcut:
					shortcuts += 1
					if not (terrain.biome_at(days * 0.5) in [ArtPalette.BIOME_MOUNTAIN, ArtPalette.BIOME_FOREST]):
						rough_middle = false
				var plan := CaravanPlan.new(destination, days, 6, 2)
				plan.caravan_party_size = 3
				plan.travel_reserve_days = int(ceil(RouteWeather.forecast_extra_days(key, 1, terrain, days)))
				var provisions := plan.get_required_provisions()
				var daily := plan.get_daily_consumption()
				var walked := 0.0
				var day := 0
				while walked < float(days) and day < days * 8 + 16:
					var weather := RouteWeather.at(key, 1 + day, terrain.biome_at(walked))
					provisions -= daily
					if provisions < 0:
						starved += 1
						break
					walked += RouteWeather.pace_multiplier(weather) * terrain.speed_factor_at(walked)
					day += 1
	t.eq(gaps, 0, "her mevsimde ve kestirmede arazi yolu boşluksuz kaplar, şehirde durmaz")
	t.eq(starved, 0, "mevsimli ve kestirmeli yolda da payıyla stoklayan aç kalmaz")
	t.ge(float(seasonal), 5.0, "ilkbahar ve yaz en az beş yolda farklı arazi verir (%d)" % seasonal)
	t.ok(shortcuts > 0, "haritada kestirmesi olan yol var")
	t.ok(rough_middle, "kestirmenin ortası dağ ya da orman")
	t.ok(winter_slower, "kış hiçbir parçayı hızlandırmaz (dağ karla yavaşlar)")
	t.ok(RouteTerrain.shortcut_days(10) < 10, "kestirme yolu kısaltır")
	t.ok(RouteTerrain.shortcut_danger(0.3) > 0.3 and RouteTerrain.shortcut_danger(0.95) <= 1.0, "kestirme tehlikeyi boş paya artırır")
	t.ok(not RouteTerrain.shortcut_available(RouteTerrain.SHORTCUT_MIN_DAYS - 1), "kısa yolda kestirme yok")

## Irmak geçidi (görev R4 #16): haritanın bazı köprüleri geçittir (iki yönden
## aynı yerde - ayna testi kapsar), su seviyesi tohumdan ve sınırlı, kart
## seviyeye göre doğru seçeneği açar.
func _test_river_fords(t) -> void:
	var fords := 0
	for leg in _map_legs():
		for segment in RouteTerrain.build(String(leg[3]), int(leg[2]), String(leg[0])).segments:
			if String(segment.stop) == RouteTerrain.STOP_FORD:
				fords += 1
	t.ok(fords > 0, "haritada ırmak geçidi var (%d)" % fords)
	var levels := {}
	for day in range(1, 200):
		var level := RouteFord.water_level("a|b", day, ArtPalette.BIOME_LAKE)
		t.eq(level, RouteFord.water_level("a|b", day, ArtPalette.BIOME_LAKE), "su seviyesi tohumlu")
		levels[level] = true
		t.ok(RouteFord.water_level("a|b", day, ArtPalette.BIOME_MARSH) >= level, "bataklık daha yüksek")
	t.eq(levels.size(), 3, "üç seviye de görülür")
	var ford := EventCatalog.get_event("evt_river_ford")
	t.ok(ford != null, "geçit kartı katalogda")
	var low := {"near_ford": 1.0, "water_level": 0.0, "gold": 100.0, "provisions": 50.0}
	var high := {"near_ford": 1.0, "water_level": 2.0, "gold": 100.0, "provisions": 50.0}
	t.ok(ford.choices[0].is_available(low) and not ford.choices[0].is_available(high), "alçak suda geçilir, yüksekte kilitli")
	t.ok(ford.choices[1].is_available(high) and not ford.choices[1].is_available(low), "selde geçmek yalnız yüksek suda")
	t.ok(ford.is_eligible(low) and not ford.is_eligible({"near_ford": 0.0}), "kart yalnız geçitte")
	t.ok(String(TranslationServer.translate(RouteTerrain.stop_name_key(RouteTerrain.STOP_FORD))) != "STOP_FORD", "geçidin adı var")


## Haritadaki konuma göre görünüş (görev Y-G07): kuzey soğuk, güney sıcak, dağa
## yakın parçanın ufkunda dağ; iki yönden aynı parça aynı görünüş.
func _test_map_looks(t) -> void:
	for leg in _map_legs():
		var key := String(leg[3])
		var forth := RouteTerrain.build(key, int(leg[2]), String(leg[0]))
		var back := RouteTerrain.build(key, int(leg[2]), String(leg[1]))
		var n := forth.segments.size()
		for k in n:
			var a: Dictionary = forth.segments[k]
			t.ok(String(a.get("climate", "")) in ["", "cold", "warm"], "iklim bilinen bir değer: %s" % key)
			if String(a.biome) == ArtPalette.BIOME_MOUNTAIN:
				t.ok(not RouteTerrain.look_of(a).ends_with("_peaks"), "dağın ufkuna ayrıca dağ konmuyor: %s" % key)
			if back.segments.size() == n:
				t.eq(RouteTerrain.look_of(back.segments[n - 1 - k]), RouteTerrain.look_of(a),
					"ters yönde görünüş aynı: %s" % key)
	var north := RouteTerrain.build(RouteConditions.route_key("brazdun", "kesgrav"), 2, "brazdun")
	t.eq(north.look_at(1.0), "mountain_cold", "kuzey dağları soğuk")
	var south := RouteTerrain.build(RouteConditions.route_key("orsolune", "serai_seyvan"), 4, "orsolune")
	t.ok(south.look_at(1.0).contains("_warm"), "güneyin yolu sıcak")
	t.eq(RoadStrips.fallback_chain("forest_cold_peaks"),
		PackedStringArray(["forest_cold_peaks", "forest_cold", "forest_peaks", "forest"]),
		"varyantın eksik katmanı bir alttakine düşüyor")
	t.eq(RoadStrips.fallback_chain("marsh"), PackedStringArray(["marsh"]), "düz biyom kendisi")
