extends Control

## Kervansaray: hasarlı vagon onarımı, yeni vagon alımı ve demirci - Silah/
## Zırh'ın kalıcı tier yükseltmeleri (bkz. EquipmentCatalog). Satın alınan
## parça doğrudan bir karaktere değil kervanın ortak equipment_inventory
## deposuna düşer; hangi karaktere takılacağı karakter ekranında seçilir.
## İş mantığı GameSession'da (get_repair_cost/repair_wagons,
## get_next_wagon_cost/can_buy_wagon/buy_wagon, add_equipment) - burada
## yalnızca gösterim var.

const MESSAGE_COLOR: Color = Color(0.9, 0.45, 0.35)
const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)

var _session: GameSession
var _equipment_rows: Array[Dictionary] = []

@onready var _status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var _message_label: Label = $MarginContainer/VBoxContainer/MessageLabel
@onready var _repair_button: Button = $MarginContainer/VBoxContainer/RepairButton
@onready var _buy_wagon_button: Button = $MarginContainer/VBoxContainer/BuyWagonButton
var _sell_wagon_button: Button
@onready var _equipment_container: VBoxContainer = $MarginContainer/VBoxContainer/EquipmentScroll/EquipmentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	# Sahne dosyasındaki yazı yalnızca editör içindir; oyuncunun gördüğü
	# her metin koddan, anahtarla gelir (bkz. Localization Rules).
	$MarginContainer/VBoxContainer/TitleLabel.text = tr("UI_CITY_YARD")
	$MarginContainer/VBoxContainer/EquipmentTitle.text = tr("UI_YARD_SMITH_TITLE")
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_session.wallet.balance_changed.connect(_on_wallet_changed)
	_repair_button.pressed.connect(_on_repair_pressed)
	_buy_wagon_button.pressed.connect(_on_buy_wagon_pressed)
	_build_sell_wagon_button()
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)
	_build_equipment_shop()
	_refresh()

## Satış tuşu alma tuşunun hemen altında durur; ekranın kendi VBox'ında,
## kaydırma kutusunun dışında (bkz. World Navigation Rules).
func _build_sell_wagon_button() -> void:
	_sell_wagon_button = Button.new()
	_sell_wagon_button.pressed.connect(_on_sell_wagon_pressed)
	var container := _buy_wagon_button.get_parent()
	container.add_child(_sell_wagon_button)
	container.move_child(_sell_wagon_button, _buy_wagon_button.get_index() + 1)

## Silah/Zırh yalnızca burada satılır (price > 0) - Yüzük/Kolye pazarda
## yer almaz, yolda EventEffect.Type.GRANT_EQUIPMENT ile bulunur.
func _build_equipment_shop() -> void:
	for equipment_resource in EquipmentCatalog.get_all_equipment():
		if equipment_resource.price <= 0:
			continue
		_equipment_container.add_child(_build_equipment_row(equipment_resource))

func _build_equipment_row(equipment_resource: Equipment) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = tr("UI_YARD_SMITH_ITEM") % [
		equipment_resource.display_name,
		EquipmentCatalog.get_slot_display_name(equipment_resource.slot),
		equipment_resource.tier,
	]
	name_label.tooltip_text = equipment_resource.description
	name_label.custom_minimum_size = Vector2(260, 0)
	row.add_child(name_label)

	var owned_label := Label.new()
	owned_label.custom_minimum_size = Vector2(90, 0)
	owned_label.modulate = HINT_COLOR
	row.add_child(owned_label)

	var buy_button := Button.new()
	buy_button.pressed.connect(_on_buy_equipment_pressed.bind(equipment_resource))
	row.add_child(buy_button)

	_equipment_rows.append({"equipment": equipment_resource, "owned_label": owned_label, "buy_button": buy_button})
	return row

func _refresh_equipment_shop() -> void:
	for row in _equipment_rows:
		var equipment_resource: Equipment = row.equipment
		var owned_label: Label = row.owned_label
		var buy_button: Button = row.buy_button
		owned_label.text = tr("UI_YARD_IN_STORE") % _session.get_equipment_count(equipment_resource.equipment_id)
		buy_button.text = tr("UI_YARD_BUY") % equipment_resource.price
		buy_button.disabled = not _session.wallet.can_afford(equipment_resource.price)

func _refresh() -> void:
	# Vagon almak yalnızca kargo değil, parti kapasitesi de açıyor
	# (bkz. GameSession.get_party_capacity) - oyuncu bunu burada görsün.
	_status_label.text = tr("UI_YARD_SUMMARY") % [
		_session.owned_wagon_count,
		CaravanPlan.DEFAULT_MAX_WAGONS,
		_session.owned_wagon_damaged,
		_session.get_party().size(),
		_session.get_party_capacity(),
	]

	if _session.owned_wagon_damaged > 0:
		var repair_cost := _session.get_repair_cost()
		_repair_button.text = tr("UI_YARD_REPAIR_ALL") % repair_cost
		_repair_button.disabled = not _session.wallet.can_afford(repair_cost)
	else:
		_repair_button.text = tr("UI_YARD_NO_DAMAGE")
		_repair_button.disabled = true

	if _session.can_buy_wagon():
		var next_cost := _session.get_next_wagon_cost()
		_buy_wagon_button.text = tr("UI_YARD_BUY_WAGON") % next_cost
		_buy_wagon_button.disabled = not _session.wallet.can_afford(next_cost)
	else:
		_buy_wagon_button.text = tr("UI_YARD_WAGON_LIMIT") % CaravanPlan.DEFAULT_MAX_WAGONS
		_buy_wagon_button.disabled = true

	_refresh_sell_wagon()
	_refresh_equipment_shop()

## Satış kapalıysa *sebebiyle birlikte* gösterilir - gizlemek, oyuncuya
## neye hazırlanacağını öğretmez (bkz. kilitli olay seçimi kuralı).
func _refresh_sell_wagon() -> void:
	var reason := _session.get_wagon_sale_block_reason()
	if reason.is_empty():
		_sell_wagon_button.text = tr("UI_YARD_SELL_WAGON") % _session.get_wagon_sale_value()
		_sell_wagon_button.disabled = false
		return
	_sell_wagon_button.text = tr(reason)
	_sell_wagon_button.disabled = true

func _on_sell_wagon_pressed() -> void:
	if not _session.sell_wagon():
		_show_message(tr(_session.get_wagon_sale_block_reason()))
		return
	_clear_message()
	_refresh()

func _on_buy_equipment_pressed(equipment_resource: Equipment) -> void:
	if not _session.wallet.can_afford(equipment_resource.price):
		_show_message(tr("UI_YARD_CANNOT_AFFORD_GEAR"))
		return
	_session.wallet.spend(equipment_resource.price)
	_session.add_equipment(equipment_resource.equipment_id, 1)
	_clear_message()
	_refresh()

func _on_repair_pressed() -> void:
	if not _session.repair_wagons():
		_show_message(tr("UI_YARD_CANNOT_AFFORD_REPAIR"))
		return
	_clear_message()
	_refresh()

func _on_buy_wagon_pressed() -> void:
	if not _session.buy_wagon():
		_show_message(tr("UI_YARD_CANNOT_AFFORD_WAGON"))
		return
	_clear_message()
	_refresh()

func _on_wallet_changed(_new_balance: int) -> void:
	_refresh()

func _show_message(text: String) -> void:
	_message_label.text = text
	_message_label.modulate = MESSAGE_COLOR

func _clear_message() -> void:
	_message_label.text = ""

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.back())
