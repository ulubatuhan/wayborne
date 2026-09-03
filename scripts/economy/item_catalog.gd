class_name ItemCatalog
extends RefCounted

## id -> Item çözümlemesi. Olaylar envantere eşya eklerken yalnızca id
## bildirir; nesnenin kendisi buradan gelir.
##
## item_id'ler ("test_grain" vb.) kalıcı kayıtlarda ve olay tanımlarında
## (bkz. event_catalog.gd) saklandığı için değiştirilmez - yalnızca
## item_name/description'ı gerçek lore'a çevirmek güvenlidir (bkz. Faz 7
## PR-D).

static var _cache: Dictionary = {}

static func get_item(item_id: String) -> Item:
	if _cache.is_empty():
		_build_cache()
	return _cache.get(item_id)

## Şehir pazarında alınıp satılabilen mallar, sabit sırayla.
static func get_trade_goods() -> Array[Item]:
	var ids := [
		GameSession.PROVISIONS_ITEM_ID,
		"test_grain",
		"test_cloth",
		"test_weapon",
		"test_potion",
		"test_furs",
	]
	var items: Array[Item] = []
	for item_id in ids:
		var item := get_item(item_id)
		if item != null:
			items.append(item)
	return items

static func get_all_items() -> Array[Item]:
	if _cache.is_empty():
		_build_cache()
	var items: Array[Item] = []
	for item in _cache.values():
		items.append(item)
	return items

static func _build_cache() -> void:
	_add(GameSession.PROVISIONS_ITEM_ID, GameSession.PROVISIONS_ITEM_NAME, GameSession.PROVISIONS_UNIT_PRICE, 0.5)
	_add("test_grain", "Buğday", 5, 1.0)
	_add("test_cloth", "Top Kumaş", 12, 1.5)
	_add("test_weapon", "Demirci Malı Silah", 40, 2.5)
	_add("test_potion", "Otacı İksiri", 20, 0.5)
	_add("test_furs", "İşlenmiş Kürk", 30, 2.0)

static func _add(item_id: String, item_name: String, base_price: int, unit_weight: float) -> void:
	var item := Item.new()
	item.item_id = item_id
	item.item_name = item_name
	item.base_price = base_price
	item.unit_weight = unit_weight
	_cache[item_id] = item
