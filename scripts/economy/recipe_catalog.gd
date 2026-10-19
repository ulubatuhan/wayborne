class_name RecipeCatalog
extends RefCounted

## Atölye'nin sabit tarif tablosu (bkz. ItemCatalog deseni - bir kez kurulup
## statik önbelleğe alınır). Üç örnek tarif, kullanıcının kendi isteğiyle
## en basit hâliyle: bandaj craftlamak, vagon bezini malzemeyle tamir etmek,
## bir malı sökup bandaja çevirmek.

const CRAFT_BANDAGE: String = "craft_bandage"
const REPAIR_WAGON_CANVAS: String = "repair_wagon_canvas"
const DISMANTLE_TO_BANDAGE: String = "dismantle_to_bandage"
## Görev Y-F03: her tarifin oyunda bir tüketicisi var (bkz. OUTPUT_USES).
const SEW_FUR_HAT: String = "sew_fur_hat"
const RENDER_FISH_OIL: String = "render_fish_oil"
const MAKE_TORCHES: String = "make_torches"
## Çıktı -> onu tüketen sistem (test bunu sınar): sargı savaşta ve kampta,
## branda vagon tamirinde, kürk başlık giyilir, yağ fenerde, meşale gecede.
const OUTPUT_USES: Dictionary = {
	"test_bandage": "CombatEncounter.use_consumable / GameSession.apply_camp_actions",
	"wagon_repair": "GameSession.craft_in_wagon (owned_wagon_damaged)",
	"fur_hat": "GameSession.wear_outfit",
	"lantern_oil": "GameSession.light_for_night",
	"torch": "GameSession.light_for_night",
}

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

	_cache.append(_make(SEW_FUR_HAT, "RECIPE_SEW_FUR_HAT_NAME", "RECIPE_SEW_FUR_HAT_DESC", {"test_furs": 2}, CraftingRecipe.Effect.OUTFIT, "fur_hat", 1))
	_cache.append(_make(RENDER_FISH_OIL, "RECIPE_FISH_OIL_NAME", "RECIPE_FISH_OIL_DESC", {"fish": 2}, CraftingRecipe.Effect.ITEM, ItemCatalog.LANTERN_OIL, 1))
	_cache.append(_make(MAKE_TORCHES, "RECIPE_TORCHES_NAME", "RECIPE_TORCHES_DESC", {"test_cloth": 1}, CraftingRecipe.Effect.ITEM, ItemCatalog.TORCH, 2))

	for recipe in _cache:
		_by_id[recipe.recipe_id] = recipe

static func _make(id: String, name_key: String, desc_key: String, inputs: Dictionary, effect: CraftingRecipe.Effect, output: String, quantity: int) -> CraftingRecipe:
	var recipe := CraftingRecipe.new()
	recipe.recipe_id = id
	recipe.recipe_name_key = name_key
	recipe.description_key = desc_key
	recipe.inputs = inputs
	recipe.effect = effect
	recipe.output_item_id = output
	recipe.output_quantity = quantity
	return recipe
