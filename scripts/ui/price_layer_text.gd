class_name PriceLayerText
extends RefCounted

## Fiyat katmanlarının satırdaki kısa adları ve açıklaması: [etiketler, ipucu].
## Sapma eşiği %2 - yuvarlama gürültüsü işaret sayılmaz.
const LAYER_MARK_THRESHOLD: float = 0.02
const LAYER_TAG_KEYS: Dictionary = {
	"place": "UI_PRICE_TAG_PLACE", "settlement": "UI_PRICE_TAG_SETTLEMENT",
	"inflation": "UI_PRICE_TAG_INFLATION", "season": "UI_PRICE_TAG_SEASON",
	"pressure": "UI_PRICE_TAG_PRESSURE", "event": "UI_PRICE_TAG_EVENT", "world": "UI_PRICE_TAG_WORLD",
}
const LAYER_UP_KEYS: Dictionary = {
	"place": "UI_PRICE_WHY_PLACE_DEMAND", "settlement": "UI_PRICE_WHY_SETTLEMENT_UP",
	"inflation": "UI_PRICE_WHY_INFLATION", "season": "UI_PRICE_WHY_SEASON_UP",
	"pressure": "UI_PRICE_WHY_PRESSURE_UP", "event": "UI_PRICE_WHY_EVENT_UP", "world": "UI_PRICE_WHY_WORLD",
}
const LAYER_DOWN_KEYS: Dictionary = {
	"place": "UI_PRICE_WHY_PLACE_PRODUCE", "settlement": "UI_PRICE_WHY_SETTLEMENT_DOWN",
	"inflation": "UI_PRICE_WHY_INFLATION", "season": "UI_PRICE_WHY_SEASON_DOWN",
	"pressure": "UI_PRICE_WHY_PRESSURE_DOWN", "event": "UI_PRICE_WHY_EVENT_DOWN", "world": "UI_PRICE_WHY_WORLD",
}

static func marks(item: Item, location: Location, conditions: MarketConditions, day: int) -> Array[String]:
	var tags: Array[String] = []
	var why: Array[String] = []
	var seen := {}
	for selling in [false, true]:
		for layer in MarketPricing.price_layers(item, location, conditions, day, selling):
			var name := String(layer["layer"])
			var m := float(layer["multiplier"])
			# Satışın tabanı (yarı fiyat) bir sapma değil, satıcının payı.
			if name == MarketPricing.LAYER_PLACE and selling and is_equal_approx(m, MarketPricing.BASE_SELL_MULTIPLIER):
				continue
			if absf(m - 1.0) < LAYER_MARK_THRESHOLD or seen.has(name):
				continue
			seen[name] = true
			tags.append(String(TranslationServer.translate(String(LAYER_TAG_KEYS[name]))))
			var key := String((LAYER_UP_KEYS if m > 1.0 else LAYER_DOWN_KEYS)[name])
			var line := String(TranslationServer.translate(key))
			if name == MarketPricing.LAYER_WORLD:
				line = line % String(TranslationServer.translate(String(layer["arg"])))
			why.append("%s (×%.2f)" % [line, m])
	var out: Array[String] = [" · ".join(tags), "\n".join(why)]
	return out
