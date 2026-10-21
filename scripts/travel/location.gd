class_name Location
extends Resource

@export var location_id: String = ""
## Eski çeviri anahtarı yolu (testlerde elle kurulan yerler). Gerçek
## yerleşimlerin adları `names`'te, dile göre (bkz. data/config/settlements.json):
## özel ad her dilde aynı, tür sözcüğü ("Kervansarayı") dile göre.
@export var location_name_key: String = ""
## Dil kodu -> ad ("tr", "en", "zh_CN"). Boşsa `location_name_key` çevrilir.
@export var names: Dictionary = {}

var location_name: String:
	get:
		if names.is_empty():
			return tr(location_name_key)
		var locale := TranslationServer.get_locale()
		if names.has(locale):
			return String(names[locale])
		var short := locale.substr(0, 2)
		if names.has(short):
			return String(names[short])
		return String(names.get("en", location_id))

## Haritadaki yeri: dünya haritası görüntüsünün pikseli (16012x16013, bkz.
## MapTileView). Testlerde elle kurulan yerlerde küçük bir tuval olabilir.
@export var map_position: Vector2 = Vector2.ZERO

## Yerleşimin türü (bkz. SettlementRules): şehir, kasaba ya da kervansaray.
## Tesisleri, ticaret payını ve fiyat çarpanlarını bu belirler.
@export var settlement_type: String = SettlementRules.CITY
## Harita bölgesi ve kültürü ("vadi", "imparatorluk", ...).
@export var region: String = ""
@export var culture: String = ""
## Surun malzemesi ("stone" ya da "wood"): şehir resmindeki duvarla ve hub'daki kapıyla aynı kaynak (settlements.json `wall`).
@export var wall: String = "stone"

## Burada ucuza üretilen / burada aranıp pahalıya alınan mal id'leri.
## Aradaki fark ticaretin kâr kaynağı (bkz. MarketPricing).
@export var produces: Array[String] = []
@export var demands: Array[String] = []
## Pazarda bulunan mallar. Boşsa her mal (şehir); kasaba ve kervansarayda
## yalnızca bunlar (kullanıcı kararı: kasabada her ürün bulunmaz).
@export var available: Array[String] = []

## Şehrin ürettiği malın stok kapasitesi (item_id -> miktar). Yalnızca
## burada listelenen mallar stok sınırına tabi (bkz. GameSession.
## market_stock); listede olmayanlar sınırsız kabul edilir.
@export var stock_per_item: Dictionary = {}

## Bu pazarda bu mal alınıp satılabilir mi.
func sells(item_id: String) -> bool:
	if item_id == ItemCatalog.CONTRABAND_SALT or ItemCatalog.LIGHT_SUPPLIES.has(item_id):
		return true
	return available.is_empty() or available.has(item_id) or item_id == GameSession.PROVISIONS_ITEM_ID

func has_facility(facility: String) -> bool:
	return SettlementRules.has_facility(settlement_type, facility)
