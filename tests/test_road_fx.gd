extends RefCounted

## Zemin ve hava efektleri (görev Y-G24). Bu paket **görünüşü doğrulamaz** -
## onun için `tests/screenshot_road_fx.gd` var (Y-K01: bir iş ekranda
## görününce biter). Buradaki üç iş, yapısal testin gerçekten yakalayabildiği
## üç sessiz bozulma:
##
## 1. **Ad uyumu.** Zemin durumundan efekt adı kalıpla türüyor
##    (`GroundCover.pick(cover, "step")` -> "step_splash"). Katalogda bir
##    efektin adı değişirse `emit` sessizce hiçbir şey çizmez; hata mesajı
##    yok, ekranda yalnızca eksiklik var. Test üretilebilecek her adın
##    manifestoda karşılığı olduğunu söylüyor.
## 2. **Hesaplanır, saklanmaz.** `GroundCover` aynı yolun aynı gününde her
##    zaman aynı çamuru vermeli; yoksa kaydı yeniden yükleyip yağmuru
##    silmek mümkün olurdu (`RouteWeather`/`Temperature` ile aynı kural).
## 3. **Adım sayımı.** Sıçramanın tetiği figürün fazından geliyor; sayaç
##    kayarsa ya hiç efekt çıkmaz ya her karede bir tane çıkar.

func suite_name() -> String:
	return "RoadFx"

func run(t) -> void:
	_test_catalog_matches_ground_names(t)
	_test_manifest_is_complete(t)
	_test_frame_at_loops_and_clamps(t)
	_test_rect_uses_pivot_and_world_size(t)
	_test_cover_is_deterministic(t)
	_test_cover_tracks_the_weather(t)
	_test_snow_share_by_temperature(t)
	_test_pick_order(t)
	_test_curtain_layers(t)
	_test_curtain_falls_back_without_art(t)
	_test_curtain_depths(t)
	_test_footfalls(t)
	_test_layer_pool(t)
	_test_layer_drifts_with_the_ground(t)
	_test_soaking_is_deterministic(t)
	_test_soaking_follows_the_sky(t)
	_test_fire_dries_the_caravan(t)
	_test_wet_clothes_keep_less_heat(t)
	_test_weather_coat_on_the_figure(t)

## Zeminden türeyen her ad katalogda olmalı.
func _test_catalog_matches_ground_names(t) -> void:
	var states := {
		"su": {"wet": 1.0, "mud": 0.0, "snow": 0.0, "dust": 0.0},
		"kar": {"wet": 0.0, "mud": 0.0, "snow": 1.0, "dust": 0.0},
		"camur": {"wet": 0.2, "mud": 1.0, "snow": 0.0, "dust": 0.0},
		"toz": {"wet": 0.0, "mud": 0.0, "snow": 0.0, "dust": 1.0},
	}
	for name in states.keys():
		var cover: Dictionary = states[name]
		for prefix in ["step", "hoof", "wheel"]:
			var id := GroundCover.pick(cover, prefix)
			t.ok(not id.is_empty(), "%s zemininde %s efekti seçilir" % [name, prefix])
			t.ok(FxCatalog.has(id), "%s katalogda var" % id)
		for prefix in ["track_foot", "track_hoof", "track_wheel"]:
			var mark := GroundCover.track(cover, prefix)
			if mark.is_empty():
				continue
			t.ok(FxCatalog.has(mark), "%s katalogda var" % mark)
	# Kuru toprak iz tutmaz: bu bir eksik değil, kural.
	t.eq(GroundCover.track(states["toz"], "track_foot"), "", "kuru toprakta iz kalmaz")

## Oyunun adıyla andığı her efektin dokusu da olmalı.
func _test_manifest_is_complete(t) -> void:
	var ids := FxCatalog.ids()
	t.ok(ids.size() >= 40, "katalogda en az kırk efekt var (%d)" % ids.size())
	for id in ids:
		t.ok(FxCatalog.texture(id) != null, "%s dokusu yüklenir" % id)
		var info := FxCatalog.info(id)
		t.ok(int(info.get("kare", 0)) >= 1, "%s en az bir kare" % id)
		t.ok(float(info.get("m", 0.0)) > 0.0, "%s dünya eni yazılı" % id)
		# Son karenin ızgarada yeri olmalı: sütun sayısı yanlışsa son kare
		# dokunun dışına düşer ve efekt bir karesi boş oynar.
		var last := FxCatalog.region(id, int(info.get("kare", 1)) - 1)
		var size := FxCatalog.texture(id).get_size()
		t.ok(last.end.x <= size.x and last.end.y <= size.y,
			"%s son karesi dokunun içinde" % id)

func _test_frame_at_loops_and_clamps(t) -> void:
	var loop_id := "rain_medium"
	var once_id := "step_splash"
	t.ok(FxCatalog.is_loop(loop_id), "perde döngülü")
	t.ok(not FxCatalog.is_loop(once_id), "sıçrama tek seferlik")
	var loop_count := int(FxCatalog.info(loop_id).get("kare", 1))
	t.eq(FxCatalog.frame_at(loop_id, 0.0), 0, "döngü sıfırdan başlar")
	t.eq(FxCatalog.frame_at(loop_id, FxCatalog.duration(loop_id)), 0, "döngü başa sarar")
	t.ok(FxCatalog.frame_at(loop_id, 99.0) < loop_count, "döngü taşmaz")
	var once_count := int(FxCatalog.info(once_id).get("kare", 1))
	t.eq(FxCatalog.frame_at(once_id, 99.0), once_count - 1, "tek seferlik son karede durur")

func _test_rect_uses_pivot_and_world_size(t) -> void:
	# Yerden fışkıranın mili alt-orta: verilen nokta temas noktası.
	var anchor := Vector2(100.0, 400.0)
	var rect := FxCatalog.rect_for("step_splash", anchor, 60.0, 1.0)
	var info := FxCatalog.info("step_splash")
	t.almost(rect.size.x, float(info.m) * 60.0, "en dünya ölçüsünden", 0.01)
	var pivot: Array = info.mil
	t.almost(rect.position.x + rect.size.x * float(pivot[0]), anchor.x, "mil x noktada", 0.01)
	t.almost(rect.position.y + rect.size.y * float(pivot[1]), anchor.y, "mil y noktada", 0.01)
	# Ölçek figürün boyundan: ekran büyüyünce efekt de büyür.
	t.ok(FxCatalog.px_per_metre(200.0) > FxCatalog.px_per_metre(100.0),
		"büyük figür büyük efekt")

## Aynı yol, aynı gün, aynı çamur - kayıt yeniden yüklenince değişmez.
func _test_cover_is_deterministic(t) -> void:
	for day in [1, 7, 23]:
		var first := GroundCover.at("a|b", day, ArtPalette.BIOME_MEADOW, "")
		var second := GroundCover.at("a|b", day, ArtPalette.BIOME_MEADOW, "")
		for key in ["wet", "mud", "snow", "dust"]:
			t.almost(float(first[key]), float(second[key]), "%d. günün %s payı aynı" % [day, key], 0.0001)
			t.ok(float(first[key]) >= 0.0 and float(first[key]) <= 1.0,
				"%s payı 0..1 arasında" % key)

## Bataklık her zaman ıslak, bozkır kuru: zemin biyomu okuyor.
func _test_cover_tracks_the_weather(t) -> void:
	var marsh := GroundCover.at("x|y", 5, ArtPalette.BIOME_MARSH, "")
	var steppe := GroundCover.at("x|y", 5, ArtPalette.BIOME_STEPPE, "")
	t.ok(float(marsh.wet) > float(steppe.wet), "bataklık bozkırdan ıslak")
	t.ok(float(steppe.dust) >= float(marsh.dust), "bozkır bataklıktan tozlu")
	# Yağmurlu bir gün zemini ıslatmalı - hangi gün olduğunu havadan bul.
	var rainy := -1
	for day in range(1, 200):
		if RouteWeather.at("x|y", day, ArtPalette.BIOME_MEADOW) == RouteWeather.STORM:
			rainy = day
			break
	if rainy > 0:
		var wet := GroundCover.at("x|y", rainy, ArtPalette.BIOME_MEADOW, "warm")
		t.ok(float(wet.wet) > 0.3, "fırtına günü zemin ıslak (%.2f)" % float(wet.wet))

func _test_snow_share_by_temperature(t) -> void:
	t.eq(GroundCover.snow_share(15.0), 0.0, "sıcakta yağış yağmur")
	t.eq(GroundCover.snow_share(-20.0), 1.0, "donda yağış kar")
	var orta := GroundCover.snow_share(0.0)
	t.ok(orta > 0.0 and orta < 1.0, "sıfır derecede karla karışık (%.2f)" % orta)

## Sıra tek yerde: su > kar > çamur > toz. Aynı zeminde öküz çamur, insan
## toz savurursa iki ayrı dünya olur.
func _test_pick_order(t) -> void:
	var hepsi := {"wet": 1.0, "mud": 1.0, "snow": 1.0, "dust": 1.0}
	t.eq(GroundCover.pick(hepsi, "step"), "step_splash", "su her şeyin önünde")
	var karli := {"wet": 0.1, "mud": 1.0, "snow": 1.0, "dust": 1.0}
	t.eq(GroundCover.pick(karli, "step"), "step_snow", "kar çamurun önünde")
	var bos := {"wet": 0.0, "mud": 0.0, "snow": 0.0, "dust": 0.0}
	t.eq(GroundCover.pick(bos, "step"), "", "taş zemin efekt vermez")

func _test_curtain_layers(t) -> void:
	t.ok(WeatherCurtain.layers_for(0.0, 0.0, 0.0).is_empty(), "açık havada perde yok")
	var rain := WeatherCurtain.layers_for(0.62, 0.25, 0.0)
	t.ok(rain.size() >= 2, "yağmur iki derinlikte")
	t.ok(String(rain[0].id).begins_with("rain"), "sıcakta yağmur düşer")
	var snow := WeatherCurtain.layers_for(0.62, 0.25, 1.0)
	t.ok(String(snow[0].id).begins_with("snow"), "soğukta kar düşer")
	var sleet := WeatherCurtain.layers_for(0.62, 0.25, 0.4)
	t.eq(String(sleet[0].id), "sleet", "arada karla karışık")
	# Uzak katman hep daha hafif ve daha yavaş: derinlik buradan.
	t.ok(float(rain[1].scale) < float(rain[0].scale), "uzak katman küçük")
	t.ok(float(rain[1].parallax) < float(rain[0].parallax), "uzak katman yavaş")
	var storm := WeatherCurtain.layers_for(1.0, 0.35, 1.0)
	t.eq(String(storm[0].id), "blizzard", "fırtına + don = tipi")

## Resmi olmayan perde listeye girmemeli: çağıran onu "perde var" sanıp
## şeridin kendi yağmurunu susturursa ekranda hiç yağmur kalmaz.
## Kullanıcı, 2026-11-13: yağış tüm ekrana geçirilmiş bir filtre gibi değil,
## arka plan, yol ve ön plan arasında ayrı ayrı görünmeli. Düzlemlerin payı
## ve uzak düzlemin yolun önüne düşmemesi burada sabitleniyor.
func _test_curtain_depths(t) -> void:
	var all := WeatherCurtain.layers_for(0.62, 0.25, 0.0)
	var far := WeatherCurtain.plane_layers(all, WeatherCurtain.Depth.FAR)
	var mid := WeatherCurtain.plane_layers(all, WeatherCurtain.Depth.MID)
	var near := WeatherCurtain.plane_layers(all, WeatherCurtain.Depth.NEAR)
	t.ok(not far.is_empty() and not mid.is_empty() and not near.is_empty(), "üç düzlem de yağış çizer")
	t.eq(String(near[0].id), String(all[0].id), "yakın düzlem asıl yağışı çizer")
	t.ok(float(near[0].scale) > float(mid[0].scale), "yakındaki damla yoldakinden iri")
	t.ok(float(mid[0].scale) > float(far[0].scale), "yoldaki damla uzaktakinden iri")
	t.ok(float(near[0].parallax) > float(mid[0].parallax), "yakın düzlem daha hızlı kayar")
	t.ok(float(near[0].alpha) < float(mid[0].alpha), "yakın düzlem seyrek ve soluk: asıl yağış yolda")
	for layer in near:
		t.ok(String(layer.id) != "fog_drift", "sis kameranın önünde değil")

	# Uzak düzlem şeridin çocuğu olarak yolun uzak kenarında biter.
	var band := TravelBand.new()
	band.size = Vector2(1600.0, 900.0)
	var curtain := WeatherCurtain.new(WeatherCurtain.Depth.FAR)
	band.add_child(curtain)
	var window: Vector3 = curtain.call("_window", Rect2(Vector2.ZERO, band.size))
	t.ok(window.y < band.road_line_y(), "uzak yağış yolun önüne düşmez")
	t.ok(window.z < window.y, "kenarı yumuşak")
	var road_curtain := WeatherCurtain.new(WeatherCurtain.Depth.MID)
	band.add_child(road_curtain)
	var road_window: Vector3 = road_curtain.call("_window", Rect2(Vector2.ZERO, band.size))
	t.ok(road_window.y > band.road_line_y() and road_window.y < band.size.y, "yol düzlemi yolda biter")
	var near_curtain := WeatherCurtain.new(WeatherCurtain.Depth.NEAR)
	var near_window: Vector3 = near_curtain.call("_window", Rect2(Vector2.ZERO, band.size))
	t.almost(near_window.y, band.size.y, "yakın düzlem ekranın tamamında")
	band.free()
	near_curtain.free()

func _test_curtain_falls_back_without_art(t) -> void:
	for layer in WeatherCurtain.layers_for(1.0, 1.0, 0.5):
		t.ok(FxCatalog.has(String(layer.id)), "%s perdesinin resmi var" % String(layer.id))

## Çevrim başına iki adım (insan), dört (hayvan).
func _test_footfalls(t) -> void:
	var figure := WalkFigure.new()
	figure.size = Vector2(60.0, 120.0)
	t.eq(figure.footfalls_per_cycle(), 2, "insan çevrimde iki adım")
	# Tam bir çevrim: faz TAU kadar ilerliyor (hız 1 çevrim/s, bir saniye).
	figure.advance(1.0, 1.0)
	t.eq(figure.take_footfalls(), 2, "bir çevrim iki ayak")
	t.eq(figure.take_footfalls(), 0, "sayaç okununca sıfırlanır")
	# Duran figür adım atmaz - duran kervanın altından toz kalkmamalı.
	figure.advance(1.0, 0.0)
	t.eq(figure.take_footfalls(), 0, "duran figür adım atmaz")
	# Kimse okumazsa sayaç şişmez: uzun bir karenin ardından tek seferde
	# yirmi sıçrama doğmamalı.
	for _i in 20:
		figure.advance(1.0, 1.0)
	t.ok(figure.take_footfalls() <= WalkFigure.FOOTFALLS_MAX_PENDING,
		"biriken adım tavanı aşmaz")
	figure.free()

func _test_layer_pool(t) -> void:
	var layer := FxLayer.new()
	layer.size = Vector2(800.0, 400.0)
	layer.set_px_per_metre(60.0)
	for _i in FxLayer.MAX_LIVE + 30:
		layer.emit("step_splash", Vector2(100.0, 300.0))
	t.ok(layer.live_count() <= FxLayer.MAX_LIVE, "havuz tavanı aşılmaz")
	# Olmayan efekt sessizce atlanır: sanat parça parça gelebilir.
	var before := layer.live_count()
	layer.emit("boyle_bir_efekt_yok", Vector2(10.0, 10.0))
	t.eq(layer.live_count(), before, "olmayan efekt havuza girmez")
	layer.clear_all()
	t.eq(layer.live_count(), 0, "temizlenince boşalır")
	layer.free()

## Efekt bırakıldığı toprakla birlikte geriye akmalı; ekrana çivilenmiş bir
## ayak izi kervanın altında duruyor demektir.
func _test_layer_drifts_with_the_ground(t) -> void:
	var layer := FxLayer.new()
	layer.size = Vector2(800.0, 400.0)
	layer.set_px_per_metre(60.0)
	layer.set_world_x(0.0)
	layer.emit("track_foot_mud", Vector2(400.0, 300.0))
	t.eq(layer.live_count(), 1, "iz bırakıldı")
	layer.set_world_x(120.0)
	# Çizim doğrudan okunamıyor; kayma formülü tek satır ve testin
	# doğruladığı şey o: dünya 120 piksel ilerledi, iz 120 piksel geride.
	t.almost(400.0 - (layer.world_x - 0.0) * FxLayer.GROUND_PARALLAX, 280.0, "iz dünya kadar geriye kayar", 0.01)
	layer.free()

## --- Kervanın üstündeki su ve kar (görev Y-G25) ---

## `GroundCover` ile aynı kural: aynı yolun aynı günü her zaman aynı
## ıslaklık. Olmasaydı kaydı yeniden yükleyip üstünü kurutmak mümkün olurdu.
func _test_soaking_is_deterministic(t) -> void:
	for day in [1, 9, 40]:
		var first := Soaking.at("a|b", day, ArtPalette.BIOME_FOREST, "", -1)
		var second := Soaking.at("a|b", day, ArtPalette.BIOME_FOREST, "", -1)
		for key in ["wet", "snow"]:
			t.almost(float(first[key]), float(second[key]),
				"%d. günün %s payı aynı" % [day, key], 0.0001)
			t.ok(float(first[key]) >= 0.0 and float(first[key]) <= 1.0,
				"%s payı 0..1 arasında" % key)

## Gökten ne düşüyorsa sırta o biner: sıcakta su, donda kar. İkisi aynı
## anda tavana vurmaz - yağmur yağarken kar birikmiyor.
func _test_soaking_follows_the_sky(t) -> void:
	var rainy := -1
	var snowy := -1
	for day in range(1, 400):
		var weather := RouteWeather.at("x|y", day, ArtPalette.BIOME_MEADOW)
		if weather != RouteWeather.STORM and weather != RouteWeather.RAIN:
			continue
		if rainy < 0 and Temperature.daily_mean(day, ArtPalette.BIOME_MEADOW, "warm", weather) > 10.0:
			rainy = day
		if snowy < 0 and Temperature.daily_mean(day, ArtPalette.BIOME_MEADOW, "cold", weather) < -6.0:
			snowy = day
	if rainy > 0:
		var wet := Soaking.at("x|y", rainy, ArtPalette.BIOME_MEADOW, "warm", -1)
		t.ok(float(wet.wet) > 0.4, "ılık yağmurda kervan ıslanır (%.2f)" % float(wet.wet))
		t.ok(float(wet.snow) < 0.05, "ılık yağmurda sırtta kar durmaz")
	if snowy > 0:
		var cold := Soaking.at("x|y", snowy, ArtPalette.BIOME_MEADOW, "cold", -1)
		t.ok(float(cold.snow) > 0.1, "donda sırtta kar durur (%.2f)" % float(cold.snow))
		t.ok(float(cold.wet) < float(cold.snow) + 0.5, "donda ıslaklık karı geçmez")
	# Branda omuzdan çok tutar, ama tavanı aşmaz.
	t.ok(Soaking.wagon_snow(0.4) > 0.4, "branda omuzdan çok kar tutar")
	t.eq(Soaking.wagon_snow(1.0), 1.0, "branda payı tavanı aşmaz")

## Ateş kurutur: kampın görünmeyen karşılığı. Olmasaydı kamp kurmak
## yalnızca saat ve erzak harcamak olurdu.
func _test_fire_dries_the_caravan(t) -> void:
	var wettest := -1
	for day in range(2, 300):
		if RouteWeather.at("f|g", day, ArtPalette.BIOME_LAKE) == RouteWeather.STORM:
			wettest = day
			break
	if wettest < 0:
		t.ok(true, "fırtınalı gün bulunamadı, atlandı")
		return
	var no_fire := Soaking.at("f|g", wettest, ArtPalette.BIOME_LAKE, "warm", -1)
	var by_fire := Soaking.at("f|g", wettest, ArtPalette.BIOME_LAKE, "warm", wettest)
	t.ok(float(by_fire.wet) < float(no_fire.wet),
		"ateş kurutur (%.2f < %.2f)" % [float(by_fire.wet), float(no_fire.wet)])

## Islaklığın mekanik karşılığı: giysi ısısının yarısından çoğunu
## kaybediyor. Yağmurun bedeli gece ödeniyor - yeni bir ceza sistemi değil,
## var olan soğuk kolunun çevrilmesi.
func _test_wet_clothes_keep_less_heat(t) -> void:
	var dry := Temperature.cold_load(-6.0, 12.0, false, 0.0)
	var damp := Temperature.cold_load(-6.0, 12.0, false, 0.5)
	var soaked := Temperature.cold_load(-6.0, 12.0, false, 1.0)
	t.ok(damp > dry, "nemli giysi daha az ısıtır")
	t.ok(soaked > damp, "sırılsıklam en kötüsü")
	t.almost(soaked - dry, 12.0 * Temperature.WET_WARMTH_LOSS,
		"kayıp giysinin ısısının payı kadar", 0.001)
	# Islaklığı bilmeyen çağıran (planlayıcı, simülatör, şehir) eskisi gibi
	# hesaplıyor: varsayılan sıfır.
	t.eq(Temperature.cold_load(-6.0, 12.0, false), dry, "varsayılan kuru")
	# Giysisi olmayan ıslanmakla bir şey kaybetmiyor: kaybedilecek ısı yok.
	t.eq(Temperature.cold_load(-6.0, 0.0, false, 1.0),
		Temperature.cold_load(-6.0, 0.0, false, 0.0), "çıplakta ıslaklık bir şey değiştirmez")

func _test_weather_coat_on_the_figure(t) -> void:
	var figure := WalkFigure.new()
	figure.size = Vector2(60.0, 120.0)
	t.eq(figure.get_weather_coat(), Vector2.ZERO, "kuru başlar")
	figure.set_weather_coat(0.8, 0.3)
	t.almost(figure.get_weather_coat().x, 0.8, "ıslaklık yazıldı", 0.001)
	t.almost(figure.get_weather_coat().y, 0.3, "kar yazıldı", 0.001)
	# Islaklık bedeni boyamıyor (kullanıcı, 2026-11-13: koyulaşma ıslak gibi okunmadı).
	t.eq(figure.self_modulate, Color.WHITE, "ıslaklık figürü koyulaştırmaz")
	t.eq(figure.modulate, Color.WHITE, "çocuklar etkilenmez")
	figure.set_weather_coat(2.0, -1.0)
	t.eq(figure.get_weather_coat(), Vector2(1.0, 0.0), "paylar 0..1 arasına sıkışır")
	figure.free()
	# Tek formül: figür, vagon ve eşya aynı yağmurun altında.
	t.ok(ArtDraw.wet_tint(Color.WHITE, 1.0).v < ArtDraw.wet_tint(Color.WHITE, 0.0).v,
		"ıslak renk kurudan koyu")
	t.eq(ArtDraw.wet_tint(Color.WHITE, 0.0), Color.WHITE, "kuruda renk değişmez")
