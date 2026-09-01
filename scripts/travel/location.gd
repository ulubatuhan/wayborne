class_name Location
extends Resource

@export var location_id: String = ""
@export var location_name: String = ""
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
