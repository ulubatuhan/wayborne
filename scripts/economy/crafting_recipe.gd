class_name CraftingRecipe
extends Resource

## Bir tarif: bir kervanın toplam envanterinden (vagonlar + kişisel
## çantalar, bkz. GameSession.get_total_quantity) tükettiği mallar ve
## ürettiği sonuç. `RecipeCatalog` bunları listeler, `GameSession.craft()`
## uygular - Rust tarzı basit bir Atölye: malzeme + tek tık.

## Sonuç bir eşya mı (kargoya yazılır) yoksa vagon onarımı mı - ikisi de
## "malzeme tüket" şeklinde ama biri üretir, biri kervanın kendi hasarını
## azaltır. İkinci bir sistem icat etmiyor: onarım zaten var
## (GameSession.repair_wagons, para karşılığı); bu yalnızca aynı hasar
## sayacına malzemeyle ulaşan ikinci bir yol.
enum Effect { ITEM, WAGON_REPAIR }

@export var recipe_id: String = ""
@export var recipe_name_key: String = ""
@export var description_key: String = ""

var recipe_name: String:
	get: return tr(recipe_name_key)

var description: String:
	get: return tr(description_key)

## item_id -> tüketilecek miktar.
@export var inputs: Dictionary = {}

@export var effect: Effect = Effect.ITEM
@export var output_item_id: String = ""
@export var output_quantity: int = 1
