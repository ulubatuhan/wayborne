extends Control

## Taverna: rota dedikodusu satar. Tehlike seviyesi varsayılan olarak
## kaba bir bant (dünya haritasında gösterilir) - tam yüzdeyi öğrenmek
## için burada ödeme yapılır. Bilgi kalıcıdır (bkz. GameSession.
## known_routes), rota simetrik olduğu için öğrenince iki yön de kaydolur.

const BASE_RUMOR_COST: int = 10
const PER_DAY_RUMOR_COST: int = 5

## Tavernadaki huy arındırma, Kilise'den daha pahalı - içmekle unutmak
## Kilise'nin uzmanlaştığı işten daha kolay değil (bkz. church.gd).
const PURIFICATION_COST: int = 60

var _session: GameSession
var _rows: Array[Dictionary] = []
var _purification_panel: PurificationPanel

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _info_label: Label = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/InfoLabel
@onready var _rumor_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/RumorList
@onready var _map_button: Button = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/MapButton
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_session = GameState.get_session()
	_back_button.text = Nav.return_label()
	_back_button.pressed.connect(_on_back_pressed)
	_map_button.pressed.connect(_on_map_pressed)
	_add_recruit_button(RecruitCatalog.VENUE_TAVERN, Nav.TAVERN)

	var location := WorldMapData.get_location_by_id(_session.current_location_id)
	_title_label.text = "Taverna" if location == null else "%s Tavernası" % location.location_name

	_content.add_child(HSeparator.new())
	_purification_panel = PurificationPanel.new()
	_content.add_child(_purification_panel)
	_purification_panel.setup(_session, "Huy Arındır", PURIFICATION_COST)
	_purification_panel.trait_removed.connect(_refresh_rows)

	_session.wallet.balance_changed.connect(_on_wallet_changed)
	_build_rows()
	_refresh_rows()

func _build_rows() -> void:
	for route in WorldMapData.get_routes_from(_session.current_location_id):
		_rumor_list.add_child(_build_row(route))

func _build_row(route: TravelRoute) -> HBoxContainer:
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = destination.location_name if destination != null else route.to_location_id
	name_label.custom_minimum_size = Vector2(160, 0)
	row.add_child(name_label)

	var status_label := Label.new()
	status_label.custom_minimum_size = Vector2(220, 0)
	row.add_child(status_label)

	var buy_button := Button.new()
	buy_button.pressed.connect(_on_buy_pressed.bind(route))
	row.add_child(buy_button)

	_rows.append({
		"route": route,
		"status_label": status_label,
		"buy_button": buy_button,
	})
	return row

## Liman şehrinden gelen bir kervancı her dedikoduyu daha ucuza duyar
## (bkz. Culture.rumor_cost_multiplier).
func _rumor_cost(route: TravelRoute) -> int:
	var base_cost := BASE_RUMOR_COST + route.travel_days * PER_DAY_RUMOR_COST
	var cost := float(base_cost) * _session.get_rumor_cost_multiplier()
	cost *= 1.0 - _session.get_duty_discount(DutyCatalog.TELLAL)
	return maxi(1, int(round(cost)))

func _refresh_rows() -> void:
	for row in _rows:
		var route: TravelRoute = row.route
		var status_label: Label = row.status_label
		var buy_button: Button = row.buy_button
		var known := _session.is_route_known(_session.current_location_id, route.to_location_id)

		if known:
			var effective_danger := _session.get_effective_danger(route.danger_level)
			status_label.text = "%d gün · Tehlike: %d%%" % [route.travel_days, int(effective_danger * 100.0)]
			buy_button.text = "Öğrenildi"
			buy_button.disabled = true
		else:
			var cost := _rumor_cost(route)
			status_label.text = "%d gün · Tehlike: bilinmiyor" % route.travel_days
			buy_button.text = "Dedikodu Satın Al (%d GG)" % cost
			buy_button.disabled = not _session.wallet.can_afford(cost)

func _on_buy_pressed(route: TravelRoute) -> void:
	var cost := _rumor_cost(route)
	if not _session.wallet.can_afford(cost):
		return
	_session.wallet.spend(cost)
	_session.learn_route(_session.current_location_id, route.to_location_id)
	_refresh_rows()

func _on_wallet_changed(_new_balance: int) -> void:
	_refresh_rows()
	_purification_panel.refresh()

func _on_map_pressed() -> void:
	Nav.return_scene = Nav.CITY_MAP
	get_tree().change_scene_to_file(Nav.TRAVEL)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)

## Tayfa ekranı ortak; hangi mekândan girildiğini gönderen ekran bildirir
## (bkz. Nav.recruit_venue). Geri tuşu buraya döner.
func _add_recruit_button(venue: String, own_scene: String) -> void:
	var button := Button.new()
	button.text = "Tayfa Ara"
	button.pressed.connect(_on_recruit_button_pressed.bind(venue, own_scene))
	var container := _back_button.get_parent()
	container.add_child(button)
	container.move_child(button, _back_button.get_index())

func _on_recruit_button_pressed(venue: String, own_scene: String) -> void:
	Nav.recruit_venue = venue
	Nav.return_scene = own_scene
	get_tree().change_scene_to_file(Nav.RECRUIT)
