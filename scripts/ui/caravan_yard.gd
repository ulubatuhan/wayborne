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
@onready var _equipment_container: VBoxContainer = $MarginContainer/VBoxContainer/EquipmentScroll/EquipmentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_session.wallet.balance_changed.connect(_on_wallet_changed)
	_repair_button.pressed.connect(_on_repair_pressed)
	_buy_wagon_button.pressed.connect(_on_buy_wagon_pressed)
	_back_button.text = Nav.return_label()
	_back_button.pressed.connect(_on_back_pressed)
	_build_equipment_shop()
	_refresh()

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
	name_label.text = "%s (%s, tier %d)" % [
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
		owned_label.text = "Depoda: %d" % _session.get_equipment_count(equipment_resource.equipment_id)
		buy_button.text = "Satın Al (%d GG)" % equipment_resource.price
		buy_button.disabled = not _session.wallet.can_afford(equipment_resource.price)

func _refresh() -> void:
	# Vagon almak yalnızca kargo değil, parti kapasitesi de açıyor
	# (bkz. GameSession.get_party_capacity) - oyuncu bunu burada görsün.
	_status_label.text = "Sahip olduğun vagon: %d / %d · Hasarlı: %d · Parti kapasiten: %d/%d" % [
		_session.owned_wagon_count,
		CaravanPlan.DEFAULT_MAX_WAGONS,
		_session.owned_wagon_damaged,
		_session.get_party().size(),
		_session.get_party_capacity(),
	]

	if _session.owned_wagon_damaged > 0:
		var repair_cost := _session.get_repair_cost()
		_repair_button.text = "Tümünü Onar (%d GG)" % repair_cost
		_repair_button.disabled = not _session.wallet.can_afford(repair_cost)
	else:
		_repair_button.text = "Hasar Yok"
		_repair_button.disabled = true

	if _session.can_buy_wagon():
		var next_cost := _session.get_next_wagon_cost()
		_buy_wagon_button.text = "Yeni Vagon Al (%d GG)" % next_cost
		_buy_wagon_button.disabled = not _session.wallet.can_afford(next_cost)
	else:
		_buy_wagon_button.text = "Vagon Limiti Doldu (%d)" % CaravanPlan.DEFAULT_MAX_WAGONS
		_buy_wagon_button.disabled = true

	_refresh_equipment_shop()

func _on_buy_equipment_pressed(equipment_resource: Equipment) -> void:
	if not _session.wallet.can_afford(equipment_resource.price):
		_show_message("Bu parça için yeterli kesen yok.")
		return
	_session.wallet.spend(equipment_resource.price)
	_session.add_equipment(equipment_resource.equipment_id, 1)
	_clear_message()
	_refresh()

func _on_repair_pressed() -> void:
	if not _session.repair_wagons():
		_show_message("Onarım için yeterli kesen yok.")
		return
	_clear_message()
	_refresh()

func _on_buy_wagon_pressed() -> void:
	if not _session.buy_wagon():
		_show_message("Yeni vagon için yeterli kesen yok ya da limit doldu.")
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
	get_tree().change_scene_to_file(Nav.return_scene)
