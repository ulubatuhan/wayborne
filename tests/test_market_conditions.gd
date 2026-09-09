extends RefCounted

## Kârın kaynağı yalnızca şehirler arası fiyat farkı değil: enflasyon,
## mevsim, oyuncunun kendi ticaretinin yarattığı arz-talep kayması ve
## ekonomik/politik şoklar da fiyatı oynatır.
##
## En kritik davranış arz-talep baskısı: bir rotayı sonsuza kadar sağmayı
## engelleyen şey o. Baskı işlemezse oyunun ekonomisi tek döngüde kırılır.

func suite_name() -> String:
	return "MarketConditions"

func run(t) -> void:
	_test_inflation_grows_and_caps(t)
	_test_seasons_cycle(t)
	_test_seasonal_goods(t)
	_test_trade_pressure_moves_prices(t)
	_test_pressure_decays(t)
	_test_shocks_apply_and_expire(t)
	_test_multiplier_stays_sane(t)
	_test_pricing_reads_conditions(t)
	_test_save_round_trip(t)

func _test_inflation_grows_and_caps(t) -> void:
	t.ok(
		is_equal_approx(MarketConditions.get_inflation_multiplier(0), 1.0),
		"ilk gün enflasyon yok"
	)
	t.ok(
		MarketConditions.get_inflation_multiplier(100) > MarketConditions.get_inflation_multiplier(10),
		"zaman geçtikçe fiyatlar tırmanır"
	)
	t.ok(
		is_equal_approx(MarketConditions.get_inflation_multiplier(99999), MarketConditions.INFLATION_CAP),
		"enflasyon tavanda durur - geç oyun ulaşılmaz olmamalı"
	)

func _test_seasons_cycle(t) -> void:
	t.eq(MarketConditions.get_season(0), MarketConditions.Season.SPRING, "oyun ilkbaharda başlar")
	t.eq(
		MarketConditions.get_season(MarketConditions.SEASON_LENGTH_DAYS),
		MarketConditions.Season.SUMMER, "bir mevsim sonra yaz"
	)
	t.eq(
		MarketConditions.get_season(MarketConditions.SEASON_LENGTH_DAYS * 3),
		MarketConditions.Season.WINTER, "dördüncü mevsim kış"
	)
	t.eq(
		MarketConditions.get_season(MarketConditions.SEASON_LENGTH_DAYS * 4),
		MarketConditions.Season.SPRING, "yıl başa döner"
	)
	t.eq(MarketConditions.get_days_into_season(0), 0, "mevsimin ilk günü")
	t.eq(
		MarketConditions.get_days_into_season(MarketConditions.SEASON_LENGTH_DAYS + 5), 5,
		"mevsim içi gün sayacı doğru"
	)

func _test_seasonal_goods(t) -> void:
	var autumn := MarketConditions.SEASON_LENGTH_DAYS * 2
	var winter := MarketConditions.SEASON_LENGTH_DAYS * 3

	t.ok(
		MarketConditions.get_season_multiplier("test_grain", autumn) < 1.0,
		"hasat mevsiminde tahıl ucuzlar"
	)
	t.ok(
		MarketConditions.get_season_multiplier("test_furs", winter) > 1.0,
		"kışın kürk pahalanır"
	)
	t.ok(
		is_equal_approx(MarketConditions.get_season_multiplier("test_weapon", winter), 1.0),
		"mevsimden etkilenmeyen mal sabit kalır"
	)

func _test_trade_pressure_moves_prices(t) -> void:
	var conditions := MarketConditions.new()
	var neutral := conditions.get_price_multiplier("test_grain", "loc_a", 0)

	conditions.record_purchase("loc_a", "test_grain", 20)
	var after_buying := conditions.get_price_multiplier("test_grain", "loc_a", 0)
	t.ok(after_buying > neutral, "alım o malı o şehirde pahalandırır")

	# Başka şehir etkilenmemeli - baskı yerel.
	t.ok(
		is_equal_approx(conditions.get_price_multiplier("test_grain", "loc_b", 0), neutral),
		"baskı yalnızca alım yapılan şehirde"
	)
	# Başka mal etkilenmemeli. Karşılaştırma malın kendi öncesi/sonrası
	# üzerinden: tahılın mevsim çarpanı var, kumaşın yok - ikisini
	# birbiriyle kıyaslamak baskıyı değil mevsimi ölçerdi.
	var cloth_untouched := MarketConditions.new()
	t.ok(
		is_equal_approx(
			conditions.get_price_multiplier("test_cloth", "loc_a", 0),
			cloth_untouched.get_price_multiplier("test_cloth", "loc_a", 0)
		),
		"baskı yalnızca alınan malda"
	)

	var selling := MarketConditions.new()
	selling.record_sale("loc_a", "test_grain", 20)
	t.ok(
		selling.get_price_multiplier("test_grain", "loc_a", 0) < neutral,
		"satış o malı o şehirde ucuzlatır"
	)

	# Baskı sınırsız büyümemeli - yoksa tek mal fiyatı uçurulabilirdi.
	var extreme := MarketConditions.new()
	extreme.record_purchase("loc_a", "test_grain", 100000)
	t.ok(
		extreme.get_pressure("loc_a", "test_grain") <= MarketConditions.PRESSURE_LIMIT + 0.001,
		"baskı tavanı aşmaz"
	)

func _test_pressure_decays(t) -> void:
	var conditions := MarketConditions.new()
	conditions.record_purchase("loc_a", "test_grain", 30)
	var initial := conditions.get_pressure("loc_a", "test_grain")
	t.ok(initial > 0.0, "baskı oluştu")

	for day in range(1, 11):
		conditions.advance_day(day)
	var later := conditions.get_pressure("loc_a", "test_grain")
	t.ok(later < initial, "pazar zamanla kendini toparlar")
	t.ok(later >= 0.0, "baskı ters yöne geçmez")

	# Uzun süre sonra tamamen sönmeli.
	for day in range(11, 200):
		conditions.advance_day(day)
	t.ok(
		is_zero_approx(conditions.get_pressure("loc_a", "test_grain")),
		"yeterince beklenirse baskı tamamen söner"
	)

func _test_shocks_apply_and_expire(t) -> void:
	var conditions := MarketConditions.new()
	var before := conditions.get_price_multiplier("test_weapon", "loc_d", 10)

	conditions.add_shock("loc_d", "test_weapon", 1.4, 20)
	t.ok(
		conditions.get_price_multiplier("test_weapon", "loc_d", 10) > before,
		"şok fiyatı yukarı iter"
	)
	t.eq(conditions.get_active_shocks(10).size(), 1, "şok aktif görünür")

	# Şehrin tamamını etkileyen şok (item_id boş)
	conditions.add_shock("loc_e", "", 0.7, 20)
	t.ok(
		conditions.get_price_multiplier("test_cloth", "loc_e", 10) < 1.0,
		"mal belirtilmeyen şok şehrin tamamını etkiler"
	)

	# Süresi dolunca etkisi kalkmalı ve defterden düşmeli.
	conditions.advance_day(21)
	t.ok(
		is_equal_approx(conditions.get_price_multiplier("test_weapon", "loc_d", 21),
			MarketConditions.get_inflation_multiplier(21)),
		"süresi dolan şokun etkisi kalkar"
	)
	t.eq(conditions.get_active_shocks(21).size(), 0, "süresi dolan şok listeden düşer")

func _test_multiplier_stays_sane(t) -> void:
	var conditions := MarketConditions.new()
	# Bütün katmanları aynı yöne yığ - toplam çarpan yine de kenetlenmeli.
	for _index in 10:
		conditions.add_shock("loc_a", "test_grain", MarketConditions.SHOCK_LIMIT, 100)
	conditions.record_purchase("loc_a", "test_grain", 100000)

	var multiplier := conditions.get_price_multiplier("test_grain", "loc_a", 500)
	t.ok(
		multiplier <= MarketConditions.TOTAL_MULTIPLIER_MAX + 0.001,
		"katmanlar üst üste binse de çarpan tavanı aşmaz"
	)
	t.ok(
		multiplier >= MarketConditions.TOTAL_MULTIPLIER_MIN,
		"çarpan tabanın altına inmez"
	)

## Katman gerçekten fiyata yansımalı - MarketConditions doğru hesaplayıp
## MarketPricing onu yok sayarsa sistem hiç çalışmamış olur.
func _test_pricing_reads_conditions(t) -> void:
	var item := ItemCatalog.get_item("test_grain")
	var location := WorldMapData.get_location_by_id(WorldMapData.START_LOCATION_ID)

	var base_buy := MarketPricing.get_buy_price(item, location)
	var base_sell := MarketPricing.get_sell_price(item, location)

	var conditions := MarketConditions.new()
	conditions.add_shock(location.location_id, "test_grain", 2.0, 50)

	t.ok(
		MarketPricing.get_buy_price(item, location, conditions, 10) > base_buy,
		"şok alım fiyatına yansır"
	)
	t.ok(
		MarketPricing.get_sell_price(item, location, conditions, 10) > base_sell,
		"şok satış fiyatına da yansır"
	)

	# Katman verilmezse eski davranış korunmalı.
	t.eq(
		MarketPricing.get_buy_price(item, location, null, 10), base_buy,
		"katman verilmeyince fiyat tabandaki gibi kalır"
	)
	t.ok(MarketPricing.get_buy_price(item, location, conditions, 10) >= 1, "fiyat asla sıfırlanmaz")

func _test_save_round_trip(t) -> void:
	var conditions := MarketConditions.new()
	conditions.record_purchase("loc_a", "test_grain", 25)
	conditions.add_shock("loc_d", "test_weapon", 1.5, 40)

	var restored := MarketConditions.new()
	restored.load_from_dict(conditions.to_save_dict())

	t.ok(
		is_equal_approx(
			restored.get_pressure("loc_a", "test_grain"),
			conditions.get_pressure("loc_a", "test_grain")
		),
		"arz-talep baskısı kayıttan döner"
	)
	t.eq(restored.get_active_shocks(10).size(), 1, "aktif şok kayıttan döner")
	t.ok(
		is_equal_approx(
			restored.get_price_multiplier("test_weapon", "loc_d", 10),
			conditions.get_price_multiplier("test_weapon", "loc_d", 10)
		),
		"kayıttan dönen piyasa aynı fiyatı verir"
	)

	# Eksik alanlı (eski) kayıt çökmeden baskısız/şoksuz açılmalı. Mevsimi
	# olmayan bir mal seçiliyor ki ölçülen şey gerçekten "kayıt boş geldi"
	# olsun - tahılın ilkbahar çarpanı sonucu 1.0'dan uzaklaştırırdı.
	var legacy := MarketConditions.new()
	legacy.load_from_dict({})
	t.ok(
		is_equal_approx(legacy.get_price_multiplier("test_weapon", "loc_a", 0), 1.0),
		"eski kayıt baskısız ve şoksuz açılır"
	)
	t.ok(
		is_zero_approx(legacy.get_pressure("loc_a", "test_grain")),
		"eski kayıtta arz-talep baskısı yok"
	)
