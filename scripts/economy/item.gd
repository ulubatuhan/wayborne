class_name Item
extends Resource

@export var item_id: String = ""
## Saklanan sey ceviri anahtari (bkz. data/locale/game.csv); gosterilen
## metin asagidaki hesaplanan ozelliklerden okunur. Bu ayrim sayesinde
## bu alanlari okuyan ekranlarin hicbiri degismeden cevrilebilir oldu
## - bkz. CLAUDE.md Localization Rules.
@export var item_name_key: String = ""
@export var description_key: String = ""

var item_name: String:
	get: return tr(item_name_key)

var description: String:
	get: return tr(description_key)

@export var base_price: int = 0
@export var stack_size: int = 99
## Vagon kargo kapasitesi bu birimle ölçülür (bkz. GameSession.CARGO_PER_WAGON).
@export var unit_weight: float = 1.0
