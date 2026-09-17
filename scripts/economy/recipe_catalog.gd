class_name RecipeCatalog
extends RefCounted

## Atölye'nin sabit tarif tablosu (bkz. ItemCatalog deseni - bir kez kurulup
## statik önbelleğe alınır). Üç örnek tarif, kullanıcının kendi isteğiyle
## en basit hâliyle: bandaj craftlamak, vagon bezini malzemeyle tamir etmek,
## bir malı sökup bandaja çevirmek.

const CRAFT_BANDAGE: String = "craft_bandage"
const REPAIR_WAGON_CANVAS: String = "repair_wagon_canvas"
const DISMANTLE_TO_BANDAGE: String = "dismantle_to_bandage"

static var _cache: Array[CraftingRecipe] = []
static var _by_id: Dictionary = {}

static func get_recipes() -> Array[CraftingRecipe]:
	_ensure_built()
	return _cache

static func get_recipe(recipe_id: String) -> CraftingRecipe:
	_ensure_built()
	return _by_id.get(recipe_id)

static func _ensure_built() -> void:
	if not _cache.is_empty():
		return

	var bandage := CraftingRecipe.new()
	bandage.recipe_id = CRAFT_BANDAGE
	bandage.recipe_name_key = "RECIPE_CRAFT_BANDAGE_NAME"
	bandage.description_key = "RECIPE_CRAFT_BANDAGE_DESC"
	bandage.inputs = {"test_cloth": 2}
	bandage.effect = CraftingRecipe.Effect.ITEM
	bandage.output_item_id = "test_bandage"
	bandage.output_quantity = 1
	_cache.append(bandage)

	var repair := CraftingRecipe.new()
	repair.recipe_id = REPAIR_WAGON_CANVAS
	repair.recipe_name_key = "RECIPE_REPAIR_CANVAS_NAME"
	repair.description_key = "RECIPE_REPAIR_CANVAS_DESC"
	repair.inputs = {"test_cloth": 3}
	repair.effect = CraftingRecipe.Effect.WAGON_REPAIR
	_cache.append(repair)

	# "Sök": bir işlenmiş kürk bandaj dolgusuna yeter - başka bir malın
	# bandaja giden ikinci, daha ucuz bir yolu (kullanıcının kendi
	# ifadesiyle "dismantle edip bandaj yapmak").
	var dismantle := CraftingRecipe.new()
	dismantle.recipe_id = DISMANTLE_TO_BANDAGE
	dismantle.recipe_name_key = "RECIPE_DISMANTLE_NAME"
	dismantle.description_key = "RECIPE_DISMANTLE_DESC"
	dismantle.inputs = {"test_furs": 1}
	dismantle.effect = CraftingRecipe.Effect.ITEM
	dismantle.output_item_id = "test_bandage"
	dismantle.output_quantity = 2
	_cache.append(dismantle)

	for recipe in _cache:
		_by_id[recipe.recipe_id] = recipe
