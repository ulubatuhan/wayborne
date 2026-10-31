extends RefCounted

## Karanlık arayüz taslağının sözleşmeleri - görünüşü değil (o ekran
## görüntüsünün işi), eğrilerin ve eşlemelerin kendisini kilitliyor: her
## hareket dinlenmede başlayıp dinlenmede bitiyor, gösterge kötüleştikçe
## tek yönde kötüleşiyor, terazi doğru tarafa eğiliyor, menü binayı
## örtmüyor, her dokunun ve ses iminin dosyası var.

func suite_name() -> String:
	return "GrimUi"

func run(t) -> void:
	_test_gauge_curves(t)
	_test_scales(t)
	_test_notice_motion(t)
	_test_market_meter(t)
	_test_motion_is_pure(t)
	_test_menu_beside_building(t)
	_test_assets_exist(t)
	_test_celsius(t)
	_test_city_front_mapping(t)
	_test_town_assets(t)
	_test_road_strips(t)
	_test_title_menu(t)
	_test_gauge_pictures(t)

func _test_gauge_curves(t) -> void:
	t.eq(SurvivalGauge.fill_fraction(150, 100), 1.0, "dolum tavanda kalıyor")
	t.eq(SurvivalGauge.fill_fraction(-5, 100), 0.0, "dolum tabanda kalıyor")
	t.eq(SurvivalGauge.severity(1.0, true), 0.0, "dolu moral: kötülük yok")
	t.eq(SurvivalGauge.severity(1.0, false), 1.0, "tam tehlike: en kötü")
	var low_max := 0.0
	var high_min := 2.0
	for k in 60:
		var time := k * 0.07
		low_max = maxf(low_max, SurvivalGauge.flame_height(0.1, time))
		high_min = minf(high_min, SurvivalGauge.flame_height(0.9, time))
	t.ok(low_max < high_min, "titreme ne kadar olursa olsun sıcak alev soğuktan uzun")
	t.ok(SurvivalGauge.flame_height(0.0, 1.0) > 0.0, "sıfırda bile köz kalıyor")
	t.ok(SurvivalGauge.flame_colour(0.0).b > SurvivalGauge.flame_colour(1.0).b, "soğuyan alev maviye kayıyor")
	var calm := 0.0
	var rough := 0.0
	for k in 40:
		calm = maxf(calm, absf(SurvivalGauge.meniscus(k / 40.0, 0.7, 0.0)))
		rough = maxf(rough, absf(SurvivalGauge.meniscus(k / 40.0, 0.7, 1.0)))
	t.ok(rough > calm, "boşalan şişe daha çok çalkalanıyor")

func _test_scales(t) -> void:
	t.eq(TradeScales.beam_angle(100, 100), 0.0, "eşit kefeler dengede")
	t.ok(TradeScales.beam_angle(100, 140) > 0.0, "fazla teklif sağa eğiyor")
	t.ok(TradeScales.beam_angle(140, 100) < 0.0, "fazla istek sola eğiyor")
	t.eq(TradeScales.beam_angle(1, 100000), TradeScales.MAX_TILT, "kol devrilmiyor")
	t.ok(is_equal_approx(TradeScales.beam_angle(20, 30), TradeScales.beam_angle(2000, 3000)),
		"eğim göreli: aynı oran aynı açı")

func _test_notice_motion(t) -> void:
	t.ok(GrimNotice.drop_offset(0.0) < 0.0, "kart yukarıdan başlıyor")
	t.eq(GrimNotice.drop_offset(GrimNotice.DROP_SECONDS), 0.0, "düşüş tam yerinde bitiyor")
	t.eq(GrimNotice.drop_offset(5.0), 0.0, "oturduktan sonra kıpırdamıyor")
	t.eq(GrimNotice.fade_alpha(1.0), 1.0, "kart okunurken tam görünür")
	t.eq(GrimNotice.fade_alpha(GrimNotice.DROP_SECONDS + GrimNotice.HOLD_SECONDS + GrimNotice.FADE_SECONDS), 0.0,
		"solma tam sıfırda bitiyor")
	t.ok(GrimNotice.sound_cue(GrimNotice.Severity.LOSS) in WaybookTheme.SOUND_CUES, "kaybın ses imi tabloda")
	t.ok(GrimNotice.sound_cue(GrimNotice.Severity.OMEN) in WaybookTheme.SOUND_CUES, "alametin ses imi tabloda")
	t.ok(GrimNotice.sound_cue(GrimNotice.Severity.GAIN) in WaybookTheme.SOUND_CUES, "kazancın ses imi tabloda")

func _test_market_meter(t) -> void:
	t.eq(MarketMeter.filled_notches(0.0), 0, "boş stok çentiksiz")
	t.eq(MarketMeter.filled_notches(1.0), MarketMeter.NOTCHES, "dolu stok bütün çentikler")
	t.eq(MarketMeter.pressure(1.0), 0.0, "taban fiyatta baskı yok")
	t.ok(MarketMeter.pressure(1.3) > 0.0 and MarketMeter.pressure(0.7) < 0.0, "pahalılık yukarı, ucuzluk aşağı")
	t.eq(MarketMeter.pressure(9.0), 1.0, "ok tavanda kalıyor")
	for stock in [0.05, 0.3, 0.9]:
		var key := MarketMeter.scarcity_key(stock)
		t.ok(TranslationServer.translate(key) != key, "kıtlık anahtarı çevrilmiş: %s" % key)

func _test_motion_is_pure(t) -> void:
	var area := Vector2(800, 600)
	t.eq(AshFall.flake_position(7, 3.2, area), AshFall.flake_position(7, 3.2, area), "kül aynı anda aynı yerde")
	var inside := true
	for i in 40:
		var p := AshFall.flake_position(i, i * 0.9, area)
		inside = inside and p.x >= 0.0 and p.x <= area.x and p.y >= -20.0 and p.y <= area.y + 20.0
	t.ok(inside, "kül ekranın içinde dolaşıyor")
	t.eq(SmokeWisps.puff_alpha(0.0), 0.0, "duman görünmezken doğuyor")
	t.ok(SmokeWisps.puff_alpha(1.0) < 0.001, "duman görünmezken sönüyor")
	t.eq(InkMenu.blot_reveal(0.0), 0.0, "leke hover'dan önce yok")
	t.eq(InkMenu.blot_reveal(1.0), 1.0, "leke tam açılıyor")
	t.ok(LanternGlow.flicker(0.0, 1.0) > 0.7, "fener titrerken sönmüyor")

func _test_menu_beside_building(t) -> void:
	var screen := Vector2(1920, 1080)
	var menu := Vector2(330, 220)
	for building in [Rect2(100, 500, 300, 360), Rect2(1500, 520, 300, 340), Rect2(1700, 600, 200, 260)]:
		var at := GrimDrafts.menu_position(screen, building, menu)
		var rect := Rect2(at, menu)
		t.ok(not rect.intersects(building), "menü binayı örtmüyor: %s" % building)
		t.ok(rect.position.x >= 0.0 and rect.end.x <= screen.x, "menü ekranın içinde: %s" % building)

func _test_assets_exist(t) -> void:
	for name in ["ash_flake.png", "vignette.png", "grime_overlay.png", "frost_overlay.png", "tatter_mask.png",
			"notice_card.png", "ink_blot.png", "lantern_glow.png"]:
		t.ok(WaybookTheme.grim_texture(name) != null, "doku var: %s" % name)
	for cue in WaybookTheme.SOUND_CUES:
		var path := WaybookTheme.SFX_DIR + String(WaybookTheme.SOUND_CUES[cue])
		t.ok(FileAccess.file_exists(path) or ResourceLoader.exists(path), "ses imi var: %s" % cue)
	t.ok(WaybookTheme.title_font() != null, "başlık yazı yüzü yükleniyor")

func _test_celsius(t) -> void:
	t.eq(SurvivalGauge.celsius_fraction(SurvivalGauge.CELSIUS_MIN), 0.0, "en soğukta alev dibe yakın")
	t.eq(SurvivalGauge.celsius_fraction(SurvivalGauge.CELSIUS_MAX), 1.0, "en sıcakta alev tam")
	t.eq(SurvivalGauge.celsius_fraction(-80.0), 0.0, "derece tabanda kalıyor")
	t.eq(SurvivalGauge.celsius_text(-4.2), "−4 °C", "eksi derece gerçek eksi işaretiyle")
	t.eq(SurvivalGauge.celsius_text(12.0), "12 °C", "artı derece işaretsiz")

## Maske resimle aynı "kapla" dönüşümüyle okunmalı, yoksa üstüne gelinen
## bina ile aydınlanan bina başka binalar olur.
func _test_city_front_mapping(t) -> void:
	t.eq(CityFront.cover_to_image(Vector2(100, 50), Vector2(1920, 1080), Vector2(1920, 1080)), Vector2(100, 50),
		"aynı oran: dönüşüm birim")
	t.eq(CityFront.cover_to_image(Vector2(0, 0), Vector2(1000, 1000), Vector2(2000, 1000)), Vector2(500, 0),
		"dar ekran: resmin iki yanı eşit kırpılıyor")
	t.eq(CityFront.cover_to_image(Vector2(960, 540), Vector2(960, 540), Vector2(1920, 1080)), Vector2(1920, 1080),
		"küçük ekran: ölçek resme göre")
	var ids := {}
	for v in CityFront.VENUES:
		ids[int(v["id"])] = true
	t.eq(ids.size(), CityFront.VENUES.size(), "her levhanın kendi maske numarası var")
	t.ok(not ids.has(CityFront.GATE_ID), "kapı levha değil, Yola Çık düğmesi")

## Her şehrin resmi ve maskesi var; maskenin mekân sırası levhalarınkiyle aynı
## (town_post.py VENUE_IDS -> CityFront.VENUES, numara = sıra + 1).
func _test_town_assets(t) -> void:
	for city in ["karakonak", "kurtbogazi", "ipekevi", "demirkapi", "yesilova", "camp"]:
		var dir: String = CityFront.TOWNS_DIR + String(city) + "/"
		t.ok(FileAccess.file_exists(dir + "background.jpg"), "%s: resim var" % city)
		t.ok(FileAccess.file_exists(dir + "mask.png"), "%s: maske var" % city)
	var meta = JSON.parse_string(FileAccess.get_file_as_string(CityFront.TOWNS_DIR + "karakonak/mask.json"))
	t.ok(meta is Dictionary, "maske tanımı okunuyor")
	if meta is Dictionary:
		var names: Array = meta["venues"]
		for v in CityFront.VENUES:
			t.eq(String(names[int(v["id"]) - 1]), String(v["icon"]), "maske sırası: %s" % v["icon"])
		t.eq(String(names[CityFront.GATE_ID - 1]), "gate", "maske sırası: kapı")
	for name in ["strip_wood.png", "plate.png", "plate_hover.png", "banner.png", "crest.png", "card.png"]:
		t.ok(CityFront.kit(name) != null, "takım: %s" % name)
	for v in CityFront.VENUES:
		t.ok(CityFront.kit("icon_%s.png" % v["icon"]) != null, "ikon: %s" % v["icon"])


## Yolun render edilmiş katmanları: her biyomda dördü de var, render'ın
## bağlantı noktaları kodun bildiğiyle aynı, döşeme dikişsiz ve biyom
## geçişi rengin geçişiyle aynı oranı okuyor.
func _test_road_strips(t) -> void:
	for biome in ["steppe", "meadow", "forest", "lake", "mountain", "marsh"]:
		t.ok(RoadStrips.has_biome(biome), "yol katmanları var: %s" % biome)
		var layout = JSON.parse_string(FileAccess.get_file_as_string(
			RoadStrips.DIR + biome + "/layout.json"))
		t.ok(layout is Dictionary, "%s: layout okunuyor" % biome)
		if not layout is Dictionary:
			continue
		for layer in RoadStrips.LAYERS:
			var spec: Dictionary = RoadStrips.SPEC[layer]
			t.ok(absf(float(layout[layer]["anchor_px"]) - float(spec["anchor_px"])) < 0.5,
				"%s/%s: bağlantı noktası render'la aynı" % [biome, layer])
		t.ok(absf(float(layout["ground"]["road_px"]) - float(RoadStrips.SPEC["ground"]["road_px"])) < 0.5,
			"%s: yol merkezi render'la aynı" % biome)
		var img := RoadStrips.texture(biome, RoadStrips.GROUND).get_image()
		if img.is_compressed():
			img.decompress()
		t.ok(_seam_error(img) < 0.08, "%s: zemin dikişsiz döşeniyor" % biome)
	# Haritanın her parçasının görünüşü (Y-G07) dört katmanını da buluyor; varyant
	# klasörlerinin bağlantı noktaları biyomunkiyle aynı.
	var looks := {}
	for location in WorldMapData.get_locations():
		for route in WorldMapData.get_routes_from(location.location_id):
			var mapped := WorldMapData.get_route_terrain(
				RouteConditions.route_key(location.location_id, route.to_location_id))
			for seg in mapped.get("segments", []):
				looks[RouteTerrain.look_of(seg)] = true
	for look in looks:
		for layer in RoadStrips.LAYERS:
			t.ok(RoadStrips.texture(String(look), layer) != null, "%s/%s çizilebiliyor" % [look, layer])
	for dir_name in DirAccess.get_directories_at(RoadStrips.DIR):
		if not dir_name.contains("_"):
			continue
		var vlayout = JSON.parse_string(FileAccess.get_file_as_string(RoadStrips.DIR + dir_name + "/layout.json"))
		t.ok(vlayout is Dictionary, "%s: layout okunuyor" % dir_name)
		if not vlayout is Dictionary:
			continue
		for layer in vlayout:
			t.ok(absf(float(vlayout[layer]["anchor_px"]) - float(RoadStrips.SPEC[layer]["anchor_px"])) < 0.5,
				"%s/%s: bağlantı noktası render'la aynı" % [dir_name, layer])
	var terrain := RouteTerrain.build("karakonak|ipekevi", 12)
	for day in [0.0, 1.3, 2.9, 5.5, 8.2, 11.9]:
		var blend := terrain.biome_blend_at(day)
		t.ok(float(blend.ratio) >= 0.0 and float(blend.ratio) <= 1.0, "geçiş oranı 0-1")
		t.eq(String(blend.from), terrain.biome_at(day), "geçiş bugünün biyomundan başlıyor")

## Sol ve sağ kenar sütunlarının ortalama farkı: döşeme dikişsizse sağ
## kenarın komşusu sol kenar, fark komşu iki sütunun farkı kadar küçük.
func _seam_error(img: Image) -> float:
	var w := img.get_width()
	var total := 0.0
	var n := 0
	for y in range(0, img.get_height(), 4):
		var a := img.get_pixel(0, y)
		var b := img.get_pixel(w - 1, y)
		if a.a < 0.5 or b.a < 0.5:
			continue
		total += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
		n += 3
	return total / float(maxi(1, n))

## Ana menü: kayıt yoksa "Devam Et" ve "Kayıtlar" yok; klavye vurgusu
## satırlar arasında dönüyor, aynı anda tek satır vurgulu.
func _test_title_menu(t) -> void:
	var menu_script: GDScript = load("res://scripts/ui/main_menu.gd")
	var fresh: Array = menu_script.menu_entries(false, false)
	t.ok(not fresh.has("UI_CONTINUE") and not fresh.has("UI_MAIN_MENU_SAVES"), "kayıtsız menüde devam/kayıtlar yok")
	t.eq(menu_script.menu_entries(true, true).size(), 5, "kayıtlı menüde beş girdi")
	var menu := InkMenu.new().setup(["a", "b", "c"])
	t.eq(menu.focused_index(), -1, "başta vurgu yok")
	menu.move_focus(1)
	t.eq(menu.focused_index(), 0, "ilk adım ilk satıra")
	menu.move_focus(-1)
	t.eq(menu.focused_index(), 2, "yukarı baştan sona dönüyor")
	menu.free()
	var gauge := SurvivalGauge.new().setup(SurvivalGauge.Kind.VIAL, Color.WHITE, "Stres", false)
	gauge.set_marker(80.0, "Ayşe 80")
	t.ok(gauge.is_marker_visible() and gauge.tooltip_text.contains("Ayşe"), "göstergede kişi çentiği ve adı")
	gauge.set_marker(-1.0)
	t.ok(not gauge.is_marker_visible() and gauge.tooltip_text == "Stres", "çentik kalkınca ad da kalkıyor")
	gauge.free()

## Yol göstergeleri resimli kart (2026-10-22): her hâlin resmi var, resim
## kelimeyle aynı eşikte dönüyor, geçiş uçlarda tam.
func _test_gauge_pictures(t) -> void:
	for id in ["morale", "stress", "stamina", "danger"]:
		for state in 3:
			var path := SurvivalGauge.picture_path(id, state)
			t.ok(SurvivalGauge.picture_texture(path) != null, "gösterge resmi var: %s" % path)
	t.ok(SurvivalGauge.picture_texture(SurvivalGauge.PICTURE_DIR + "medallion.png") != null, "gösterge madalyonu var")
	var medallion := SurvivalGauge.picture_texture(SurvivalGauge.PICTURE_DIR + "medallion.png")
	for id in ["morale", "stress", "stamina", "danger"]:
		var tex := SurvivalGauge.picture_texture(SurvivalGauge.picture_path(id, 2))
		t.eq(tex.get_size(), medallion.get_size(), "resim madalyonla aynı tuvalde: %s" % id)
	t.eq(SurvivalGauge.picture_state(0.0, 100.0), 0, "sıfır değer düşük resim")
	t.eq(SurvivalGauge.picture_state(100.0, 100.0), 2, "tam değer yüksek resim")
	t.eq(SurvivalGauge.picture_state(45.0, 100.0), 1, "ortada orta resim")
	for v in [0.0, 24.0, 25.0, 49.0, 50.0, 74.0, 75.0, 100.0]:
		var word := Wording.band(v, 100.0)
		t.eq(SurvivalGauge.picture_state(v, 100.0), SurvivalGauge.BAND_TO_PICTURE[word],
			"resim kelimenin kademesini izliyor (%d)" % int(v))
	t.eq(SurvivalGauge.picture_fade(0.0), 0.0, "geçiş baştan başlıyor")
	t.eq(SurvivalGauge.picture_fade(SurvivalGauge.PICTURE_FADE_SECONDS * 2.0), 1.0, "geçiş tam bitiyor")
	var gauge := SurvivalGauge.new().setup_picture("stress", "Stres", false)
	gauge.set_value(10.0)
	gauge.set_value(90.0)
	t.eq(gauge._picture_state, 2, "yüksek stres en sıkı düğüm")
	t.eq(gauge._prev_picture_state, 0, "önceki resim geçiş için tutuluyor")
	gauge.free()
	_test_weather_gauge(t)

## Sıcaklık madalyonu havayı gösterir; değer yalnızca fare üstündeyken, birimiyle.
func _test_weather_gauge(t) -> void:
	for w in ["clear_day", "clear_night", "overcast", "rain", "fog", "storm", "snow", "blizzard"]:
		t.ok(SurvivalGauge.picture_texture(SurvivalGauge.PICTURE_DIR + "weather_%s.png" % w) != null,
			"hava resmi var: %s" % w)
	t.eq(SurvivalGauge.weather_picture(RouteWeather.CLEAR, false, 12.0), "clear_day", "gündüz açık hava güneş")
	t.eq(SurvivalGauge.weather_picture(RouteWeather.CLEAR, true, 12.0), "clear_night", "gece açık hava ay")
	t.eq(SurvivalGauge.weather_picture(RouteWeather.RAIN, false, 4.0), "rain", "sıfırın üstünde yağmur")
	t.eq(SurvivalGauge.weather_picture(RouteWeather.RAIN, false, -3.0), "snow", "sıfırın altında yağmur kar")
	t.eq(SurvivalGauge.weather_picture(RouteWeather.STORM, true, -9.0), "blizzard", "sıfırın altında fırtına tipi")
	t.eq(SurvivalGauge.weather_picture(RouteWeather.FOG, true, -9.0), "fog", "sis gece de sis")
	for w in [RouteWeather.CLEAR, RouteWeather.OVERCAST, RouteWeather.RAIN, RouteWeather.FOG, RouteWeather.STORM]:
		t.ok(SurvivalGauge.WEATHER_PICTURES.has(w), "her havanın resmi var: %s" % w)
	t.ok(SurvivalGauge.is_night(1.0) and not SurvivalGauge.is_night(13.0), "gece yarısı gece, öğlen gündüz")
	var warmth := SurvivalGauge.new().setup_weather("Sıcaklık")
	warmth.set_weather(RouteWeather.RAIN, false, -4.2)
	t.eq(warmth.value_text(), "−4 °C", "sıcaklık değeri birimiyle")
	t.ok(not warmth.is_value_shown(), "değer fare üstüne gelmeden görünmüyor")
	warmth.set_hovered(true)
	t.ok(warmth.is_value_shown(), "fare üstündeyken değer görünüyor")
	warmth.free()
	var danger := SurvivalGauge.new().setup_picture("danger", "Tehlike", false).with_unit(SurvivalGauge.Unit.PERCENT)
	danger.set_value(45.0)
	t.eq(danger.value_text(), "%45", "tehlike yüzdeyle")
	danger.free()
	var morale := SurvivalGauge.new().setup_picture("morale", "Moral")
	morale.set_value(72.0, 100.0)
	t.eq(morale.value_text(), "72/100", "moral puanla")
	morale.free()
