class_name MarketPricing
extends RefCounted

## Fiyatın taban katmanı: bir şehrin ürettiği mal ucuza alınır, aradığı mal
## yüksek fiyata satılır. Şehirler arası bu fark kârın **bir** kaynağıdır,
## tek kaynağı değil - enflasyon, mevsim, oyuncunun kendi ticaretinin
## yarattığı arz-talep kayması ve ekonomik/politik şoklar MarketConditions
## katmanında yaşar ve buradaki taban fiyatı çarpar.
##
## conditions verilmezse her çarpan 1.0 olur; bu katmanı bilmeyen bir
## çağıran eski davranışı görür.
##
## Buradaki oranlar denge için ayarlanacak yer tutuculardır.

const PRODUCE_BUY_MULTIPLIER: float = 0.6
const DEMAND_SELL_MULTIPLIER: float = 1.7
const BASE_SELL_MULTIPLIER: float = 0.5
## Kaçak mal (Y-C19): kervansarayda kaçakçıdan ucuz, şehirde ve kasabada
## pahalı satılır - kâr yüksek, bedeli gümrük. Nadir mal yalnız şehirde.
const CONTRABAND_BUY_MULTIPLIER: float = 0.55
const CONTRABAND_SELL_MULTIPLIER: float = 1.9
const RARE_SELL_MULTIPLIER: float = 1.6
## Toplu alım: bir seferde BULK_MIN_QUANTITY ve üstü alana indirim.
const BULK_MIN_QUANTITY: int = 20
const BULK_DISCOUNT: float = 0.06

static func bulk_total(unit_price: int, quantity: int) -> int:
	var total := unit_price * quantity
	if quantity >= BULK_MIN_QUANTITY:
		total = int(round(float(total) * (1.0 - BULK_DISCOUNT)))
	return maxi(quantity, total)

## Alış kapalıysa sebebi (çeviri anahtarı), açıksa "".
static func buy_block_reason(item: Item, location: Location) -> String:
	if item.rare:
		return "UI_MARKET_RARE_NO_SELLER"
	if item.contraband and (location == null or location.settlement_type != SettlementRules.CARAVANSERAI):
		return "UI_MARKET_CONTRABAND_NO_SELLER"
	return ""

static func sell_block_reason(item: Item, location: Location) -> String:
	if item.rare and (location == null or location.settlement_type != SettlementRules.CITY):
		return "UI_MARKET_RARE_NO_BUYER"
	if item.contraband and location != null and location.settlement_type == SettlementRules.CARAVANSERAI:
		return "UI_MARKET_CONTRABAND_NO_BUYER"
	return ""

static func _place_multiplier(item: Item, location: Location, selling: bool) -> float:
	if selling:
		if item.rare:
			return RARE_SELL_MULTIPLIER
		if item.contraband:
			return CONTRABAND_SELL_MULTIPLIER
		return DEMAND_SELL_MULTIPLIER if location != null and location.demands.has(item.item_id) else BASE_SELL_MULTIPLIER
	if item.contraband:
		return CONTRABAND_BUY_MULTIPLIER
	return PRODUCE_BUY_MULTIPLIER if location != null and location.produces.has(item.item_id) else 1.0

static func get_buy_price(
	item: Item, location: Location, conditions: MarketConditions = null, day: int = 0
) -> int:
	var multiplier := _place_multiplier(item, location, false)
	if location != null:
		# Yerleşim türü: kasabada temel mal ucuz, kervansarayda her şey pahalı.
		multiplier *= SettlementRules.buy_multiplier(location.settlement_type, item.item_id)
	multiplier *= _dynamic_multiplier(item, location, conditions, day)
	return maxi(1, int(round(item.base_price * multiplier)))

static func get_sell_price(
	item: Item, location: Location, conditions: MarketConditions = null, day: int = 0
) -> int:
	var multiplier := _place_multiplier(item, location, true)
	if location != null:
		# Kervansaray yolcudan ucuza alır.
		multiplier *= SettlementRules.sell_multiplier(location.settlement_type, item.item_id)
	multiplier *= _dynamic_multiplier(item, location, conditions, day)
	return maxi(1, int(round(item.base_price * multiplier)))

## --- Tazelik (Ana Hedefler: eşya bozulması) ---
## Bozulan malın yaşı satış fiyatına girer: raf ömrünün ilk çeyreğinde taze
## fiyatına, sonra raf ömrünün sonuna kadar FRESHNESS_FLOOR'a iner. Çürüme
## (GameSession.spoil_perishables) miktarı yer, bu fiyatı: üç günlük balık
## hâlâ balıktır ama tezgâhta tazesi gibi satılmaz.
const FRESHNESS_FULL_SHARE: float = 0.25
const FRESHNESS_FLOOR: float = 0.6

static func freshness_multiplier(item: Item, age_days: float) -> float:
	if item == null or item.shelf_days <= 0 or age_days <= 0.0:
		return 1.0
	var shelf := float(item.shelf_days)
	var t := clampf((age_days - shelf * FRESHNESS_FULL_SHARE) / (shelf * (1.0 - FRESHNESS_FULL_SHARE)), 0.0, 1.0)
	return lerpf(1.0, FRESHNESS_FLOOR, t)

## --- Fiyatın katmanları (görev Y-C11) ---
## Yedi katman, her biri {"layer", "multiplier", "arg"}: yer (şehir üretir ya
## da arar), yerleşim türü, enflasyon, mevsim, arz baskısı, olay şoku, dünya
## olayı. Hepsi her zaman listede; ekran yalnızca 1.0'dan sapanı işaretler.
## Çarpımları (toplam kenetlenmediyse) fiyatın kendisi - test bunu sınar.
const LAYER_PLACE: String = "place"
const LAYER_SETTLEMENT: String = "settlement"
const LAYER_INFLATION: String = "inflation"
const LAYER_SEASON: String = "season"
const LAYER_PRESSURE: String = "pressure"
const LAYER_EVENT: String = "event"
const LAYER_WORLD: String = "world"
const LAYERS: Array[String] = [
	LAYER_PLACE, LAYER_SETTLEMENT, LAYER_INFLATION, LAYER_SEASON, LAYER_PRESSURE, LAYER_EVENT, LAYER_WORLD,
]

static func price_layers(
	item: Item, location: Location, conditions: MarketConditions, day: int, selling: bool
) -> Array[Dictionary]:
	var place := _place_multiplier(item, location, selling)
	var settlement := 1.0
	if location != null:
		if selling:
			settlement = SettlementRules.sell_multiplier(location.settlement_type, item.item_id)
		else:
			settlement = SettlementRules.buy_multiplier(location.settlement_type, item.item_id)
	var inflation := 1.0
	var season := 1.0
	var pressure := 1.0
	var shocks := {"event": 1.0, "world": 1.0, "world_label": ""}
	if conditions != null and location != null:
		inflation = MarketConditions.get_inflation_multiplier(day)
		season = MarketConditions.get_season_multiplier(item.item_id, day)
		pressure = 1.0 + conditions.get_pressure(location.location_id, item.item_id)
		shocks = conditions.get_shock_parts(location.location_id, item.item_id, day)
	return [
		{"layer": LAYER_PLACE, "multiplier": place, "arg": ""},
		{"layer": LAYER_SETTLEMENT, "multiplier": settlement, "arg": location.settlement_type if location != null else ""},
		{"layer": LAYER_INFLATION, "multiplier": inflation, "arg": ""},
		{"layer": LAYER_SEASON, "multiplier": season, "arg": ""},
		{"layer": LAYER_PRESSURE, "multiplier": pressure, "arg": ""},
		{"layer": LAYER_EVENT, "multiplier": float(shocks["event"]), "arg": ""},
		{"layer": LAYER_WORLD, "multiplier": float(shocks["world"]), "arg": String(shocks["world_label"])},
	]

static func _dynamic_multiplier(
	item: Item, location: Location, conditions: MarketConditions, day: int
) -> float:
	if conditions == null or location == null:
		return 1.0
	return conditions.get_price_multiplier(item.item_id, location.location_id, day)
