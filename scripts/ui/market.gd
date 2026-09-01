extends Control

## Şehir pazarı. Kalıcı oturumun cüzdanı ve envanteri üzerinde çalışır:
## burada aldığın erzak, sefere çıkarken kervan planlayıcıda görünür.
## Fiyatlar bulunduğun şehre göre değişir (bkz. MarketPricing) ve satın
## alma vagon kargo kapasitesiyle sınırlıdır (bkz. GameSession.get_cargo_capacity).

const GRID_COLUMNS: int = 5
const GRID_ROWS: int = 4
const SLOT_SIZE: Vector2 = Vector2(80, 80)
const EMPTY_SLOT_COLOR: Color = Color(0.2, 0.2, 0.2)
const FILLED_SLOT_COLOR: Color = Color(0.3, 0.5, 0.3)

const MESSAGE_COLOR: Color = Color(0.9, 0.45, 0.35)
const TRADE_NOTE_COLOR: Color = Color(0.75, 0.85, 1.0)

var _session: GameSession
var _shop_items: Array[Item] = []
var _current_location: Location

@onready var _location_note_label: Label = $MarginContainer/VBoxContainer/LocationNoteLabel
@onready var _balance_value_label: Label = $MarginContainer/VBoxContainer/BalanceRow/BalanceValueLabel
@onready var _cargo_value_label: Label = $MarginContainer/VBoxContainer/BalanceRow/CargoValueLabel
@onready var _message_label: Label = $MarginContainer/VBoxContainer/MessageLabel
@onready var _shop_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentRow/ShopPanel/ShopList
@onready var _inventory_grid: GridContainer = $MarginContainer/VBoxContainer/ContentRow/InventoryPanel/InventoryGrid
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	_current_location = WorldMapData.get_location_by_id(_session.current_location_id)
	_inventory_grid.columns = GRID_COLUMNS
	_shop_items = ItemCatalog.get_trade_goods()

	_session.wallet.balance_changed.connect(_on_wallet_balance_changed)
	_session.inventory.item_added.connect(_on_inventory_changed)
	_session.inventory.item_removed.connect(_on_inventory_changed)
	_back_button.text = Nav.return_label()
	_back_button.pressed.connect(_on_back_pressed)

	_location_note_label.text = _build_trade_note()
	_location_note_label.modulate = TRADE_NOTE_COLOR
	_location_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_build_shop_rows()
	_refresh_header()
	_refresh_inventory_grid()

func _build_trade_note() -> String:
	if _current_location == null:
		return ""

	var produced_names := _item_names(_current_location.produces)
	var demanded_names := _item_names(_current_location.demands)
	var parts: Array[String] = []
	if not produced_names.is_empty():
		parts.append("Burada ucuz: %s" % ", ".join(produced_names))
	if not demanded_names.is_empty():
		parts.append("Burada aranan: %s" % ", ".join(demanded_names))
	return " · ".join(parts)

func _item_names(item_ids: Array[String]) -> Array[String]:
	var names: Array[String] = []
	for item_id in item_ids:
		var item := ItemCatalog.get_item(item_id)
		if item != null:
			names.append(item.item_name)
	return names

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
	buy_price_label.text = "Al: %d GG" % _get_buy_price(item)
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
	var price := _get_buy_price(item)
	if not _session.wallet.can_afford(price):
		_show_message("Yetersiz kese: %d GG gerekiyor." % price)
		return
	if item.item_id != GameSession.PROVISIONS_ITEM_ID and item.unit_weight > _session.get_cargo_space_remaining():
		_show_message("Vagon kapasitesi yetersiz: %.1f / %.1f dolu." % [
			_session.get_cargo_weight(), _session.get_cargo_capacity()
		])
		return
	if not _session.inventory.add_item(item, 1):
		_show_message("Envanterde yer yok.")
		return
	_session.wallet.spend(price)
	_clear_message()

func _on_sell_pressed(item: Item) -> void:
	if not _session.inventory.has_item(item.item_id, 1):
		_show_message("Envanterde %s yok." % item.item_name)
		return
	_session.inventory.remove_item(item.item_id, 1)
	_session.wallet.earn(_get_sell_price(item))
	_clear_message()

func _get_buy_price(item: Item) -> int:
	return MarketPricing.get_buy_price(item, _current_location)

func _get_sell_price(item: Item) -> int:
	return MarketPricing.get_sell_price(item, _current_location)

func _show_message(text: String) -> void:
	_message_label.text = text
	_message_label.modulate = MESSAGE_COLOR

func _clear_message() -> void:
	_message_label.text = ""

func _on_wallet_balance_changed(_new_balance: int) -> void:
	_refresh_header()

func _on_inventory_changed(_item: Item, _quantity: int) -> void:
	_refresh_header()
	_refresh_inventory_grid()

func _refresh_header() -> void:
	_balance_value_label.text = "%d GG" % _session.wallet.balance
	_cargo_value_label.text = "Kargo: %.1f / %.1f" % [
		_session.get_cargo_weight(), _session.get_cargo_capacity()
	]

func _refresh_inventory_grid() -> void:
	for child in _inventory_grid.get_children():
		_inventory_grid.remove_child(child)
		child.queue_free()

	var entries := _session.inventory.get_all_entries()
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
	get_tree().change_scene_to_file(Nav.return_scene)
