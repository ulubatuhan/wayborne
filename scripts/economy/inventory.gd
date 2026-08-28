class_name Inventory
extends RefCounted

signal item_added(item: Item, quantity: int)
signal item_removed(item: Item, quantity: int)

var max_slots: int = 20

var _entries: Dictionary = {}

func _init(slots: int = 20) -> void:
	max_slots = slots

func add_item(item: Item, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false
	if not _entries.has(item.item_id) and _entries.size() >= max_slots:
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

func is_full() -> bool:
	return _entries.size() >= max_slots
