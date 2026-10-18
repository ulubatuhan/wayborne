class_name SettlementRules
extends RefCounted

## Yerleşim türlerinin kuralları (görev N4, kullanıcı kararı 2026-10-18):
##
## | | Şehir | Kasaba | Kervansaray |
## |---|---|---|---|
## | Tesis | hepsi | lonca ve kervan avlusu yok | kervan avlusu var, lonca yok |
## | Ticaret | tam | payı düşük, temel mal ucuz, her mal yok | değişik mal, alış pahalı, satış ucuz |
## | Kontrat varışı | evet | evet | hayır |
##
## Kural tek yerde: ekranlar (CityFront levhaları, brifing), pazar fiyatı
## (MarketPricing), stok ve hazine (GameSession, MarketConditions) ve kontrat
## panosu (WorldMapData) buradan okur.

const CITY: String = "city"
const TOWN: String = "town"
const CARAVANSERAI: String = "caravanserai"

const MARKET: String = "market"
const GUILD: String = "guild"
const TAVERN: String = "tavern"
const CHURCH: String = "church"
const CARAVAN_YARD: String = "caravan_yard"
const WARDROBE: String = "wardrobe"

const FACILITIES: Dictionary = {
	CITY: [MARKET, GUILD, TAVERN, CHURCH, CARAVAN_YARD, WARDROBE],
	TOWN: [MARKET, TAVERN, CHURCH, WARDROBE],
	CARAVANSERAI: [MARKET, TAVERN, CARAVAN_YARD],
}

## Temel mallar: kasabada daha ucuz. Erzak her yerde bulunur.
const BASIC_GOODS: Array[String] = ["test_grain", "fish", "test_furs", "test_cloth", "provisions"]
const TOWN_BASIC_BUY_MULTIPLIER: float = 0.85
## Ticaret payı: kasabanın stoğu ve hazinesi şehrinkinin bu kadarı.
const TRADE_SHARE: Dictionary = {CITY: 1.0, TOWN: 0.5, CARAVANSERAI: 0.6}
## Kervansaray: alırken pahalı, satarken ucuz (yolcunun mecburiyetinden kâr).
const CARAVANSERAI_BUY_MULTIPLIER: float = 1.3
const CARAVANSERAI_SELL_MULTIPLIER: float = 0.75

static func has_facility(settlement_type: String, facility: String) -> bool:
	return (FACILITIES.get(settlement_type, FACILITIES[CITY]) as Array).has(facility)

static func facilities(settlement_type: String) -> Array:
	return (FACILITIES.get(settlement_type, FACILITIES[CITY]) as Array).duplicate()

static func accepts_contracts(settlement_type: String) -> bool:
	return settlement_type == CITY or settlement_type == TOWN

## Kontrat panosu lonca demek: yalnızca loncası olan yerden kontrat çıkar.
static func offers_contracts(settlement_type: String) -> bool:
	return has_facility(settlement_type, GUILD)

static func trade_share(settlement_type: String) -> float:
	return float(TRADE_SHARE.get(settlement_type, 1.0))

## Alış fiyatına türün katkısı (üretim ve dinamik çarpanlardan ayrı).
static func buy_multiplier(settlement_type: String, item_id: String) -> float:
	if settlement_type == CARAVANSERAI:
		return CARAVANSERAI_BUY_MULTIPLIER
	if settlement_type == TOWN and BASIC_GOODS.has(item_id):
		return TOWN_BASIC_BUY_MULTIPLIER
	return 1.0

static func sell_multiplier(settlement_type: String, _item_id: String) -> float:
	if settlement_type == CARAVANSERAI:
		return CARAVANSERAI_SELL_MULTIPLIER
	return 1.0
