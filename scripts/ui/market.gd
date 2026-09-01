extends Control

## Şehir pazarı. Kalıcı oturumun cüzdanı ve envanteri üzerinde çalışır:
## burada aldığın erzak, sefere çıkarken kervan planlayıcıda görünür.
## Fiyatlar bulunduğun şehre göre değişir (bkz. MarketPricing), satın
## alma vagon kargo kapasitesiyle (bkz. GameSession.get_cargo_capacity)
## ve şehrin ürettiği malın stoğuyla (bkz. GameSession.market_stock)
## sınırlıdır. Miktar seçilip toptan alınabilir; toptan alım için
## sticker fiyat yerine HagglingPanel üzerinden pazarlık da açılabilir -
## pazarlık koparsa alım bedelsiz iptal olur (zorunlu karşılaşma değil).

const GRID_COLUMNS: int = 5
const GRID_ROWS: int = 4
const SLOT_SIZE: Vector2 = Vector2(80, 80)
const EMPTY_SLOT_COLOR: Color = Color(0.2, 0.2, 0.2)
const FILLED_SLOT_COLOR: Color = Color(0.3, 0.5, 0.3)

const MESSAGE_COLOR: Color = Color(0.9, 0.45, 0.35)
const TRADE_NOTE_COLOR: Color = Color(0.75, 0.85, 1.0)

const MAX_BUY_QUANTITY: int = 99
const MARKET_HAGGLE_GREED: float = 0.4
const MARKET_HAGGLE_REPUTATION: float = 0.3
const MARKET_HAGGLE_DRAIN_RATE: float = 20.0

var _session: GameSession
var _shop_items: Array[Item] = []
var _current_location: Location
var _shop_rows: Array[Dictionary] = []

var _pending_purchase_item: Item
var _pending_purchase_quantity: int = 0

@onready var _location_note_label: Label = $MarginContainer/VBoxContainer/LocationNoteLabel
@onready var _balance_value_label: Label = $MarginContainer/VBoxContainer/BalanceRow/BalanceValueLabel
@onready var _cargo_value_label: Label = $MarginContainer/VBoxContainer/BalanceRow/CargoValueLabel
@onready var _message_label: Label = $MarginContainer/VBoxContainer/MessageLabel
@onready var _shop_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentRow/ShopPanel/ShopList
@onready var _inventory_grid: GridContainer = $MarginContainer/VBoxContainer/ContentRow/InventoryPanel/InventoryGrid
@onready var _haggle_holder: VBoxContainer = $MarginContainer/VBoxContainer/HaggleHolder
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
	_refresh_shop_rows()
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
	row.add_theme_constant_override("separation", 6)

	var name_label := Label.new()
	name_label.text = item.item_name
	name_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_label)

	var price_label := Label.new()
	price_label.text = "Al: %d GG · Sat: %d GG" % [_get_buy_price(item), _get_sell_price(item)]
	price_label.custom_minimum_size = Vector2(160, 0)
	row.add_child(price_label)

	var stock_label := Label.new()
	stock_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(stock_label)

	var quantity_spin := SpinBox.new()
	quantity_spin.min_value = 1
	quantity_spin.max_value = MAX_BUY_QUANTITY
	quantity_spin.value = 1
	quantity_spin.custom_minimum_size = Vector2(70, 0)
	row.add_child(quantity_spin)

	var buy_button := Button.new()
	buy_button.text = "Al"
	buy_button.pressed.connect(_on_buy_pressed.bind(item, quantity_spin))
	row.add_child(buy_button)

	var haggle_button := Button.new()
	haggle_button.text = "Pazarlık Et"
	haggle_button.pressed.connect(_on_haggle_pressed.bind(item, quantity_spin))
	row.add_child(haggle_button)

	var sell_button := Button.new()
	sell_button.text = "Sat"
	sell_button.pressed.connect(_on_sell_pressed.bind(item, quantity_spin))
	row.add_child(sell_button)

	_shop_rows.append({
		"item": item,
		"stock_label": stock_label,
		"buy_button": buy_button,
		"haggle_button": haggle_button,
	})
	return row

func _refresh_shop_rows() -> void:
	for row in _shop_rows:
		var item: Item = row.item
		var stock_label: Label = row.stock_label
		var remaining := _session.get_market_stock(item.item_id)

		if remaining < 0:
			stock_label.text = ""
		else:
			stock_label.text = "Stok: %d" % remaining

		var out_of_stock := remaining == 0
		row.buy_button.disabled = out_of_stock
		row.haggle_button.disabled = out_of_stock

func _on_buy_pressed(item: Item, quantity_spin: SpinBox) -> void:
	var quantity := int(quantity_spin.value)
	if quantity <= 0:
		return

	var price := _get_buy_price(item) * quantity
	if not _session.wallet.can_afford(price):
		_show_message("Yetersiz kese: %d GG gerekiyor." % price)
		return
	if not _has_enough_stock(item, quantity):
		_show_message("Stokta yeterli %s yok." % item.item_name)
		return
	if not _has_enough_cargo_space(item, quantity):
		_show_message("Vagon kapasitesi yetersiz: %.1f / %.1f dolu." % [
			_session.get_cargo_weight(), _session.get_cargo_capacity()
		])
		return
	if not _session.inventory.add_item(item, quantity):
		_show_message("Envanterde yer yok.")
		return

	_session.consume_stock(item.item_id, quantity)
	_session.wallet.spend(price)
	_clear_message()

func _on_haggle_pressed(item: Item, quantity_spin: SpinBox) -> void:
	var quantity := int(quantity_spin.value)
	if quantity <= 0:
		return
	if not _has_enough_stock(item, quantity):
		_show_message("Stokta yeterli %s yok." % item.item_name)
		return
	if not _has_enough_cargo_space(item, quantity):
		_show_message("Vagon kapasitesi yetersiz: %.1f / %.1f dolu." % [
			_session.get_cargo_weight(), _session.get_cargo_capacity()
		])
		return

	_pending_purchase_item = item
	_pending_purchase_quantity = quantity
	_set_shop_controls_enabled(false)
	_clear_children(_haggle_holder)

	var base_price := _get_buy_price(item) * quantity

	var intro := Label.new()
	intro.text = "Pazarlık: %d adet %s için tüccar %d GG istiyor." % [quantity, item.item_name, base_price]
	_haggle_holder.add_child(intro)

	var panel := HagglingPanel.new()
	_haggle_holder.add_child(panel)
	panel.deal_made.connect(_on_haggle_deal)
	panel.haggling_failed.connect(_on_haggle_failed)
	panel.start_haggling(
		float(base_price), MARKET_HAGGLE_GREED, MARKET_HAGGLE_REPUTATION, 0, 0, MARKET_HAGGLE_DRAIN_RATE, false
	)

func _on_haggle_deal(price: int) -> void:
	if not _session.wallet.can_afford(price):
		_show_message("Anlaşılan fiyatı ödeyecek kesen yok, alım iptal edildi.")
		_close_haggling()
		return
	if not _session.inventory.add_item(_pending_purchase_item, _pending_purchase_quantity):
		_show_message("Envanterde yer yok, alım iptal edildi.")
		_close_haggling()
		return

	_session.consume_stock(_pending_purchase_item.item_id, _pending_purchase_quantity)
	_session.wallet.spend(price)
	_show_message("Pazarlık tuttu: %d GG ödendi." % price)
	_close_haggling()

func _on_haggle_failed() -> void:
	_show_message("Pazarlık koptu, alım gerçekleşmedi.")
	_close_haggling()

func _close_haggling() -> void:
	_clear_children(_haggle_holder)
	_pending_purchase_item = null
	_pending_purchase_quantity = 0
	_set_shop_controls_enabled(true)
	_refresh_shop_rows()

func _set_shop_controls_enabled(enabled: bool) -> void:
	for row in _shop_rows:
		row.buy_button.disabled = not enabled
		row.haggle_button.disabled = not enabled
	if enabled:
		_refresh_shop_rows()

func _on_sell_pressed(item: Item, quantity_spin: SpinBox) -> void:
	var quantity := int(quantity_spin.value)
	if quantity <= 0:
		return
	if not _session.inventory.has_item(item.item_id, quantity):
		_show_message("Envanterde yeterli %s yok." % item.item_name)
		return
	_session.inventory.remove_item(item.item_id, quantity)
	_session.wallet.earn(_get_sell_price(item) * quantity)
	_clear_message()

func _has_enough_stock(item: Item, quantity: int) -> bool:
	var remaining := _session.get_market_stock(item.item_id)
	return remaining < 0 or remaining >= quantity

func _has_enough_cargo_space(item: Item, quantity: int) -> bool:
	if item.item_id == GameSession.PROVISIONS_ITEM_ID:
		return true
	return item.unit_weight * quantity <= _session.get_cargo_space_remaining()

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
	_refresh_shop_rows()
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

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)
