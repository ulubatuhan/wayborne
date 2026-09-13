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
	_test_weather_reserve_stays_proportionate(t)

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
		RouteTerrain.STOP_HAMLET, RouteTerrain.STOP_OUTPOST, RouteTerrain.STOP_MINE,
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
				plan.weather_reserve_days = int(ceil(
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
					walked += RouteWeather.pace_multiplier(weather)
					day += 1
				checked += 1
				t.ge(
					float(walked), float(travel_days) - 0.001,
					"yol bitmeden erzak tükenmemeli (%s/%d gün/%d. gün)" % [key, travel_days, start_day]
				)
	t.eq(starved, 0, "hava payıyla stoklayan kervan hiç aç kalmamalı")
	t.ge(float(checked), 80.0, "yeterince kombinasyon denenmiş olmalı")

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
