class_name Location
extends Resource

@export var location_id: String = ""
## Saklanan sey ceviri anahtari (bkz. data/locale/game.csv); gosterilen
## metin asagidaki hesaplanan ozelliklerden okunur. Bu ayrim sayesinde
## bu alanlari okuyan ekranlarin hicbiri degismeden cevrilebilir oldu
## - bkz. CLAUDE.md Localization Rules.
@export var location_name_key: String = ""

var location_name: String:
	get: return tr(location_name_key)

@export var map_position: Vector2 = Vector2.ZERO
@export var connections: Array[String] = []

## Burada ucuza üretilen / burada aranıp pahalıya alınan mal id'leri.
## Aradaki fark ticaretin kâr kaynağı (bkz. MarketPricing).
@export var produces: Array[String] = []
@export var demands: Array[String] = []

## Şehrin ürettiği malın stok kapasitesi (item_id -> miktar). Yalnızca
## burada listelenen mallar stok sınırına tabi (bkz. GameSession.
## market_stock); listede olmayanlar sınırsız kabul edilir.
@export var stock_per_item: Dictionary = {}
