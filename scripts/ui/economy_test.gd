extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const STARTING_BALANCE: int = 100
const GRID_COLUMNS: int = 5
const GRID_ROWS: int = 4
const SLOT_SIZE: Vector2 = Vector2(80, 80)
const EMPTY_SLOT_COLOR: Color = Color(0.2, 0.2, 0.2)
const FILLED_SLOT_COLOR: Color = Color(0.3, 0.5, 0.3)
const SELL_PRICE_MULTIPLIER: float = 0.5

var _wallet: Wallet
var _inventory: Inventory
var _shop_items: Array[Item] = []

@onready var _balance_value_label: Label = $MarginContainer/VBoxContainer/BalanceRow/BalanceValueLabel
@onready var _shop_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentRow/ShopPanel/ShopList
@onready var _inventory_grid: GridContainer = $MarginContainer/VBoxContainer/ContentRow/InventoryPanel/InventoryGrid
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_wallet = Wallet.new(STARTING_BALANCE)
	_inventory = Inventory.new(GRID_COLUMNS * GRID_ROWS)
	_inventory_grid.columns = GRID_COLUMNS

	_shop_items = _build_shop_items()
	_inventory.add_item(_shop_items[0], 3)

	_wallet.balance_changed.connect(_on_wallet_balance_changed)
	_inventory.item_added.connect(_on_inventory_changed)
	_inventory.item_removed.connect(_on_inventory_changed)
	_back_button.pressed.connect(_on_back_pressed)

	_build_shop_rows()
	_refresh_balance_label()
	_refresh_inventory_grid()

func _build_shop_items() -> Array[Item]:
	return [
		_make_item("test_grain", "Test Tahıl", 5),
		_make_item("test_cloth", "Test Kumaş", 12),
		_make_item("test_weapon", "Test Silah", 40),
		_make_item("test_potion", "Test İksir", 20),
	]

func _make_item(item_id: String, item_name: String, price: int) -> Item:
	var item := Item.new()
	item.item_id = item_id
	item.item_name = item_name
	item.base_price = price
	return item

func _build_shop_rows() -> void:
	for item in _shop_items:
		_shop_list.add_child(_build_shop_row(item))

func _build_shop_row(item: Item) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = item.item_name
	name_label.custom_minimum_size = Vector2(140, 0)
	row.add_child(name_label)

	var buy_price_label := Label.new()
	buy_price_label.text = "Al: %d GG" % item.base_price
	buy_price_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(buy_price_label)

	var sell_price_label := Label.new()
	sell_price_label.text = "Sat: %d GG" % _get_sell_price(item)
	sell_price_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(sell_price_label)

	var buy_button := Button.new()
	buy_button.text = "Al"
	buy_button.pressed.connect(_on_buy_pressed.bind(item))
	row.add_child(buy_button)

	var sell_button := Button.new()
	sell_button.text = "Sat"
	sell_button.pressed.connect(_on_sell_pressed.bind(item))
	row.add_child(sell_button)

	return row

func _on_buy_pressed(item: Item) -> void:
	if not _wallet.can_afford(item.base_price):
		return
	if not _inventory.add_item(item, 1):
		return
	_wallet.spend(item.base_price)

func _on_sell_pressed(item: Item) -> void:
	if not _inventory.has_item(item.item_id, 1):
		return
	_inventory.remove_item(item.item_id, 1)
	_wallet.earn(_get_sell_price(item))

func _get_sell_price(item: Item) -> int:
	return int(item.base_price * SELL_PRICE_MULTIPLIER)

func _on_wallet_balance_changed(_new_balance: int) -> void:
	_refresh_balance_label()

func _on_inventory_changed(_item: Item, _quantity: int) -> void:
	_refresh_inventory_grid()

func _refresh_balance_label() -> void:
	_balance_value_label.text = "%d GG" % _wallet.balance

func _refresh_inventory_grid() -> void:
	for child in _inventory_grid.get_children():
		child.queue_free()

	var entries := _inventory.get_all_entries()
	var total_slots := GRID_COLUMNS * GRID_ROWS

	for i in range(total_slots):
		if i < entries.size():
			var entry: Dictionary = entries[i]
			var item: Item = entry.item
			var label_text := "%s\nx%d" % [item.item_name, entry.quantity]
			_inventory_grid.add_child(PlaceholderHelper.create_box(SLOT_SIZE, FILLED_SLOT_COLOR, label_text))
		else:
			_inventory_grid.add_child(PlaceholderHelper.create_box(SLOT_SIZE, EMPTY_SLOT_COLOR, ""))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
