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
	multiplier *= _dynamic_multiplier(item, location, conditions, day)
	return maxi(1, int(round(item.base_price * multiplier)))

static func get_sell_price(
	item: Item, location: Location, conditions: MarketConditions = null, day: int = 0
) -> int:
	var multiplier := BASE_SELL_MULTIPLIER
	if location != null and location.demands.has(item.item_id):
		multiplier = DEMAND_SELL_MULTIPLIER
	multiplier *= _dynamic_multiplier(item, location, conditions, day)
	return maxi(1, int(round(item.base_price * multiplier)))

static func _dynamic_multiplier(
	item: Item, location: Location, conditions: MarketConditions, day: int
) -> float:
	if conditions == null or location == null:
		return 1.0
	return conditions.get_price_multiplier(item.item_id, location.location_id, day)
