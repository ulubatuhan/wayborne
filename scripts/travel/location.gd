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
