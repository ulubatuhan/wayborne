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
	_test_hamlet_mapping(t)
	_test_town_assets(t)

func _test_gauge_curves(t) -> void:
	t.eq(SurvivalGauge.fill_fraction(150, 100), 1.0, "dolum tavanda kalıyor")
	t.eq(SurvivalGauge.fill_fraction(-5, 100), 0.0, "dolum tabanda kalıyor")
	t.eq(SurvivalGauge.severity(1.0, true), 0.0, "dolu moral: kötülük yok")
	t.eq(SurvivalGauge.severity(1.0, false), 1.0, "tam tehlike: en kötü")
	t.eq(SurvivalGauge.crack_amount(0.0), 0.0, "sağlam şişe çatlamıyor")
	t.eq(SurvivalGauge.crack_amount(SurvivalGauge.CRACK_FROM), 0.0, "çatlak eşikte başlıyor")
	t.eq(SurvivalGauge.crack_amount(1.0), 1.0, "en kötüde tam çatlak")
	var last := -1.0
	var monotone := true
	for i in 21:
		var c := SurvivalGauge.crack_amount(i / 20.0)
		monotone = monotone and c >= last
		last = c
	t.ok(monotone, "çatlak kötüleştikçe yalnızca artıyor")
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
	t.ok(GrimNotice.sound_cue(GrimNotice.Severity.LOSS) in GrimTheme.SOUND_CUES, "kaybın ses imi tabloda")
	t.ok(GrimNotice.sound_cue(GrimNotice.Severity.OMEN) in GrimTheme.SOUND_CUES, "alametin ses imi tabloda")
	t.ok(GrimNotice.sound_cue(GrimNotice.Severity.GAIN) in GrimTheme.SOUND_CUES, "kazancın ses imi tabloda")

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
			"crack_overlay.png", "notice_card.png", "ink_blot.png", "lantern_glow.png"]:
		t.ok(GrimTheme.texture(name) != null, "doku var: %s" % name)
	for cue in GrimTheme.SOUND_CUES:
		var path := GrimTheme.SFX_DIR + String(GrimTheme.SOUND_CUES[cue])
		t.ok(FileAccess.file_exists(path) or ResourceLoader.exists(path), "ses imi var: %s" % cue)
	t.ok(GrimTheme.title_font() != null, "başlık yazı yüzü yükleniyor")

func _test_celsius(t) -> void:
	t.eq(SurvivalGauge.celsius_fraction(SurvivalGauge.CELSIUS_MIN), 0.0, "en soğukta alev dibe yakın")
	t.eq(SurvivalGauge.celsius_fraction(SurvivalGauge.CELSIUS_MAX), 1.0, "en sıcakta alev tam")
	t.eq(SurvivalGauge.celsius_fraction(-80.0), 0.0, "derece tabanda kalıyor")
	t.eq(SurvivalGauge.celsius_text(-4.2), "−4 °C", "eksi derece gerçek eksi işaretiyle")
	t.eq(SurvivalGauge.celsius_text(12.0), "12 °C", "artı derece işaretsiz")

## Maske resimle aynı "kapla" dönüşümüyle okunmalı, yoksa üstüne gelinen
## bina ile aydınlanan bina başka binalar olur.
func _test_hamlet_mapping(t) -> void:
	t.eq(GrimHamlet.cover_to_image(Vector2(100, 50), Vector2(1920, 1080), Vector2(1920, 1080)), Vector2(100, 50),
		"aynı oran: dönüşüm birim")
	t.eq(GrimHamlet.cover_to_image(Vector2(0, 0), Vector2(1000, 1000), Vector2(2000, 1000)), Vector2(500, 0),
		"dar ekran: resmin iki yanı eşit kırpılıyor")
	t.eq(GrimHamlet.cover_to_image(Vector2(960, 540), Vector2(960, 540), Vector2(1920, 1080)), Vector2(1920, 1080),
		"küçük ekran: ölçek resme göre")
	var ids := {}
	for v in GrimHamlet.VENUES:
		ids[int(v["id"])] = true
	t.eq(ids.size(), GrimHamlet.VENUES.size(), "her levhanın kendi maske numarası var")
	t.ok(not ids.has(GrimHamlet.GATE_ID), "kapı levha değil, Yola Çık düğmesi")

## Her şehrin resmi ve maskesi var; maskenin mekân sırası levhalarınkiyle aynı
## (town_post.py VENUE_IDS -> GrimHamlet.VENUES, numara = sıra + 1).
func _test_town_assets(t) -> void:
	for city in ["karakonak", "kurtbogazi", "ipekevi", "demirkapi", "yesilova", "camp"]:
		var dir: String = GrimHamlet.TOWNS_DIR + String(city) + "/"
		t.ok(FileAccess.file_exists(dir + "background.jpg"), "%s: resim var" % city)
		t.ok(FileAccess.file_exists(dir + "mask.png"), "%s: maske var" % city)
	var meta = JSON.parse_string(FileAccess.get_file_as_string(GrimHamlet.TOWNS_DIR + "karakonak/mask.json"))
	t.ok(meta is Dictionary, "maske tanımı okunuyor")
	if meta is Dictionary:
		var names: Array = meta["venues"]
		for v in GrimHamlet.VENUES:
			t.eq(String(names[int(v["id"]) - 1]), String(v["icon"]), "maske sırası: %s" % v["icon"])
		t.eq(String(names[GrimHamlet.GATE_ID - 1]), "gate", "maske sırası: kapı")
	for name in ["strip_wood.png", "plate.png", "plate_hover.png", "banner.png", "crest.png", "card.png"]:
		t.ok(GrimHamlet.kit(name) != null, "takım: %s" % name)
	for v in GrimHamlet.VENUES:
		t.ok(GrimHamlet.kit("icon_%s.png" % v["icon"]) != null, "ikon: %s" % v["icon"])
