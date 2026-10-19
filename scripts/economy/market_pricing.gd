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

static func get_buy_price(
	item: Item, location: Location, conditions: MarketConditions = null, day: int = 0
) -> int:
	var multiplier := 1.0
	if location != null and location.produces.has(item.item_id):
		multiplier = PRODUCE_BUY_MULTIPLIER
	if location != null:
		# Yerleşim türü: kasabada temel mal ucuz, kervansarayda her şey pahalı.
		multiplier *= SettlementRules.buy_multiplier(location.settlement_type, item.item_id)
	multiplier *= _dynamic_multiplier(item, location, conditions, day)
	return maxi(1, int(round(item.base_price * multiplier)))

static func get_sell_price(
	item: Item, location: Location, conditions: MarketConditions = null, day: int = 0
) -> int:
	var multiplier := BASE_SELL_MULTIPLIER
	if location != null and location.demands.has(item.item_id):
		multiplier = DEMAND_SELL_MULTIPLIER
	if location != null:
		# Kervansaray yolcudan ucuza alır.
		multiplier *= SettlementRules.sell_multiplier(location.settlement_type, item.item_id)
	multiplier *= _dynamic_multiplier(item, location, conditions, day)
	return maxi(1, int(round(item.base_price * multiplier)))

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
	var place := 1.0
	var settlement := 1.0
	if location != null:
		if selling:
			place = DEMAND_SELL_MULTIPLIER if location.demands.has(item.item_id) else BASE_SELL_MULTIPLIER
			settlement = SettlementRules.sell_multiplier(location.settlement_type, item.item_id)
		else:
			place = PRODUCE_BUY_MULTIPLIER if location.produces.has(item.item_id) else 1.0
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
