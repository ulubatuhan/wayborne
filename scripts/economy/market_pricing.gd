class_name MarketPricing
extends RefCounted

## Fiyat şehre göre değişir: bir şehrin ürettiği mal ucuza alınır, aradığı
## mal yüksek fiyata satılır. Aradaki fark ticaretin kâr kaynağıdır -
## bir malı üreten şehirden alıp arayan şehirde satmak kâr getirir.

const PRODUCE_BUY_MULTIPLIER: float = 0.6
const DEMAND_SELL_MULTIPLIER: float = 1.7
const BASE_SELL_MULTIPLIER: float = 0.5

static func get_buy_price(item: Item, location: Location) -> int:
	var multiplier := 1.0
	if location != null and location.produces.has(item.item_id):
		multiplier = PRODUCE_BUY_MULTIPLIER
	return int(round(item.base_price * multiplier))

static func get_sell_price(item: Item, location: Location) -> int:
	var multiplier := BASE_SELL_MULTIPLIER
	if location != null and location.demands.has(item.item_id):
		multiplier = DEMAND_SELL_MULTIPLIER
	return int(round(item.base_price * multiplier))
