class_name Inventory
extends RefCounted

signal item_added(item: Item, quantity: int)
signal item_removed(item: Item, quantity: int)

var max_slots: int = 20

## Ağırlık, slot sayısından ayrı ve bağlayıcı bir kısıt: bir vagon çok
## çeşit değil çok *yük* taşıyamaz. Vagon başına kapasite GameSession'dan
## gelir (bkz. CARGO_PER_WAGON) ve vagon alınıp kaybedildikçe güncellenir.
## 0.0 = sınırsız - kısıtı umursamayan testler ve kurulum anı için.
var weight_limit: float = 0.0

## Ağırlık kısıtından muaf mallar. Erzak buradadır: kendi sefer formülüyle
## zaten sınırlı ve kargo kapasitesine dahil değil (bkz. GameSession.
## get_cargo_weight) - kısıt onu da saysaydı yola çıkmak için erzak
## almak kargo yerinden çalardı.
var exempt_item_ids: Array[String] = []

var _entries: Dictionary = {}

func _init(slots: int = 20, limit: float = 0.0) -> void:
	max_slots = slots
	weight_limit = limit

## Muaf olmayan malların toplam ağırlığı.
func get_total_weight() -> float:
	var total := 0.0
	for entry in _entries.values():
		var item: Item = entry.item
		if exempt_item_ids.has(item.item_id):
			continue
		total += item.unit_weight * float(entry.quantity)
	return total

func get_remaining_weight() -> float:
	if weight_limit <= 0.0:
		return INF
	return maxf(0.0, weight_limit - get_total_weight())

## Verilen maldan ağırlık sınırına kaç tane daha sığdığı. Pazar ekranı
## "kaç tane alabilirim" sorusunu buradan cevaplar.
func get_addable_quantity(item: Item) -> int:
	if weight_limit <= 0.0 or exempt_item_ids.has(item.item_id):
		return 999999
	if item.unit_weight <= 0.0:
		return 999999
	return int(floor(get_remaining_weight() / item.unit_weight))

func has_space_for(item: Item, quantity: int = 1) -> bool:
	if not _entries.has(item.item_id) and _entries.size() >= max_slots:
		return false
	return quantity <= get_addable_quantity(item)

## Hem slot hem ağırlık kısıtı burada zorlanır - eklemenin tek kapısı
## burası olduğu için olay ödülü de pazar alımı da aynı kurala tabi.
func add_item(item: Item, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false
	if not has_space_for(item, quantity):
		return false

	if _entries.has(item.item_id):
		_entries[item.item_id].quantity += quantity
	else:
		_entries[item.item_id] = {"item": item, "quantity": quantity}

	item_added.emit(item, quantity)
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0 or not _entries.has(item_id):
		return false

	var entry: Dictionary = _entries[item_id]
	if entry.quantity < quantity:
		return false

	entry.quantity -= quantity
	var item: Item = entry.item

	if entry.quantity <= 0:
		_entries.erase(item_id)

	item_removed.emit(item, quantity)
	return true

func get_quantity(item_id: String) -> int:
	if _entries.has(item_id):
		return _entries[item_id].quantity
	return 0

func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_quantity(item_id) >= quantity

func get_all_entries() -> Array:
	return _entries.values()
