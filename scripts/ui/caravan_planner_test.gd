extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const TRAVEL_SCENE: String = "res://scenes/tests/travel_test.tscn"

const PROVISIONS_ITEM_ID: String = "test_provisions"
const PROVISIONS_ITEM_NAME: String = "Test Erzak"
const PROVISIONS_UNIT_PRICE: int = 4
const STARTING_PROVISIONS: int = 6

const SHORTFALL_COLOR: Color = Color(0.9, 0.45, 0.35)
const SATISFIED_COLOR: Color = Color(0.45, 0.8, 0.45)

var _plan: CaravanPlan
var _inventory: Inventory
var _provisions_item: Item
var _offer_rows: Array[Dictionary] = []

var _wagon_counter_label: Label
var _party_label: Label
var _documents_label: Label
var _required_provisions_label: Label
var _current_provisions_label: Label
var _shortfall_label: Label
var _profit_label: Label
var _result_label: Label
var _confirm_button: Button

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer

func _ready() -> void:
	var destination := WorldMapData.get_location_by_id(TravelContext.selected_destination_id)
	var origin := WorldMapData.get_location_by_id(TravelContext.current_location_id)

	if destination == null or origin == null:
		_build_missing_context_ui()
		return

	var route := WorldMapData.get_route(origin.location_id, destination.location_id)
	var travel_days: int = 1
	if route != null:
		travel_days = route.travel_days

	_plan = CaravanPlan.new(destination, travel_days)
	_inventory = Inventory.new()
	_provisions_item = _build_provisions_item()
	_set_inventory_provisions(STARTING_PROVISIONS)

	_build_ui(origin, destination, travel_days)
	_refresh()

func _build_missing_context_ui() -> void:
	var label := Label.new()
	label.text = "Hedef seçilmedi. Haritadan bir hedef seçerek buraya gel."
	_content.add_child(label)

	var back_button := Button.new()
	back_button.text = "Haritaya Dön"
	back_button.pressed.connect(_on_map_pressed)
	_content.add_child(back_button)

func _build_ui(origin: Location, destination: Location, travel_days: int) -> void:
	var title := Label.new()
	title.text = "Kervan Planı: %s → %s" % [origin.location_name, destination.location_name]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)

	var route_label := Label.new()
	route_label.text = "Yol: %d gün · Vagon limiti: %d (1'i senin)" % [travel_days, _plan.max_wagons]
	_content.add_child(route_label)

	_wagon_counter_label = Label.new()
	_content.add_child(_wagon_counter_label)

	_content.add_child(HSeparator.new())

	var merchants_title := Label.new()
	merchants_title.text = "Kervana Kabul Edilecek Tüccarlar"
	_content.add_child(merchants_title)

	for offer in WorldMapData.get_offers_for_destination(destination.location_id):
		_content.add_child(_build_offer_row(offer))

	_content.add_child(HSeparator.new())

	var provisions_title := Label.new()
	provisions_title.text = "Erzak (envanterden)"
	_content.add_child(provisions_title)

	var provisions_row := HBoxContainer.new()
	var provisions_spin_label := Label.new()
	provisions_spin_label.text = "Envanterdeki erzak:"
	provisions_spin_label.custom_minimum_size = Vector2(180, 0)
	var provisions_spin := SpinBox.new()
	provisions_spin.min_value = 0
	provisions_spin.max_value = 200
	provisions_spin.step = 1
	provisions_spin.value = STARTING_PROVISIONS
	provisions_spin.value_changed.connect(_on_provisions_changed)
	provisions_row.add_child(provisions_spin_label)
	provisions_row.add_child(provisions_spin)
	_content.add_child(provisions_row)

	_content.add_child(HSeparator.new())

	var summary_title := Label.new()
	summary_title.text = "Sefer Özeti"
	_content.add_child(summary_title)

	_party_label = Label.new()
	_documents_label = Label.new()
	_required_provisions_label = Label.new()
	_current_provisions_label = Label.new()
	_shortfall_label = Label.new()
	_profit_label = Label.new()
	_content.add_child(_party_label)
	_content.add_child(_documents_label)
	_content.add_child(_required_provisions_label)
	_content.add_child(_current_provisions_label)
	_content.add_child(_shortfall_label)
	_content.add_child(_profit_label)

	_confirm_button = Button.new()
	_confirm_button.text = "Kervanı Onayla"
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_content.add_child(_confirm_button)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(_result_label)

	_content.add_child(HSeparator.new())

	var map_button := Button.new()
	map_button.text = "Haritaya Dön"
	map_button.pressed.connect(_on_map_pressed)
	_content.add_child(map_button)

	var back_button := Button.new()
	back_button.text = "Ana Menüye Dön"
	back_button.pressed.connect(_on_back_pressed)
	_content.add_child(back_button)

func _build_offer_row(offer: MerchantOffer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var checkbox := CheckBox.new()
	checkbox.toggled.connect(_on_offer_toggled.bind(offer, checkbox))
	row.add_child(checkbox)

	var name_label := Label.new()
	name_label.text = offer.merchant_name
	name_label.custom_minimum_size = Vector2(160, 0)
	row.add_child(name_label)

	var wagon_label := Label.new()
	wagon_label.text = "%d vagon" % offer.wagon_count
	wagon_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(wagon_label)

	var profit_label := Label.new()
	profit_label.text = "+%d GG" % offer.potential_profit
	profit_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(profit_label)

	_offer_rows.append({"offer": offer, "checkbox": checkbox})
	return row

func _on_offer_toggled(_toggled_on: bool, offer: MerchantOffer, checkbox: CheckBox) -> void:
	if not _plan.toggle_merchant(offer):
		# Vagon limiti dolu: seçim geri alınır.
		checkbox.set_pressed_no_signal(false)
	_refresh()

func _on_provisions_changed(value: float) -> void:
	_set_inventory_provisions(int(value))
	_refresh()

func _refresh() -> void:
	_wagon_counter_label.text = "Vagon: %d / %d (tüccarlara açık slot)" % [
		_plan.get_used_wagon_count(),
		_plan.get_available_wagon_slots(),
	]

	for row in _offer_rows:
		var offer: MerchantOffer = row.offer
		var checkbox: CheckBox = row.checkbox
		checkbox.disabled = not _plan.is_selected(offer) and not _plan.can_add_offer(offer)

	var current_provisions := _inventory.get_quantity(PROVISIONS_ITEM_ID)
	var required_provisions := _plan.get_required_provisions()
	var shortfall := _plan.get_provisions_shortfall(current_provisions)

	_party_label.text = "Parti büyüklüğü: %d kişi · Toplam vagon: %d" % [
		_plan.get_party_size(),
		_plan.get_total_wagon_count(),
	]
	_documents_label.text = "Gerekli evrak: %d adet (vagon başına 1)" % _plan.get_required_documents()
	_required_provisions_label.text = "Gerekli erzak: %d birim" % required_provisions
	_current_provisions_label.text = "Elindeki erzak: %d birim" % current_provisions

	if shortfall > 0:
		_shortfall_label.text = "Satın alınacak erzak: %d birim (≈ %d GG)" % [
			shortfall,
			shortfall * PROVISIONS_UNIT_PRICE,
		]
		_shortfall_label.modulate = SHORTFALL_COLOR
	else:
		_shortfall_label.text = "Erzak yeterli, satın alma gerekmiyor."
		_shortfall_label.modulate = SATISFIED_COLOR

	_profit_label.text = "Toplam potansiyel getiri: %d GG" % _plan.get_total_profit()

func _on_confirm_pressed() -> void:
	var current_provisions := _inventory.get_quantity(PROVISIONS_ITEM_ID)
	var shortfall := _plan.get_provisions_shortfall(current_provisions)

	_result_label.text = "Kervan onaylandı: %d tüccar, %d vagon, %d evrak, %d birim erzak eksiği. Beklenen getiri: %d GG." % [
		_plan.get_selected_offers().size(),
		_plan.get_total_wagon_count(),
		_plan.get_required_documents(),
		shortfall,
		_plan.get_total_profit(),
	]

func _build_provisions_item() -> Item:
	var item := Item.new()
	item.item_id = PROVISIONS_ITEM_ID
	item.item_name = PROVISIONS_ITEM_NAME
	item.base_price = PROVISIONS_UNIT_PRICE
	return item

func _set_inventory_provisions(amount: int) -> void:
	var current := _inventory.get_quantity(PROVISIONS_ITEM_ID)
	if current > 0:
		_inventory.remove_item(PROVISIONS_ITEM_ID, current)
	if amount > 0:
		_inventory.add_item(_provisions_item, amount)

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file(TRAVEL_SCENE)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
