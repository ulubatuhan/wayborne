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
var _feast_label: Label
var _feast_button: Button

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
	_title_label.text = tr("UI_TAVERN_TITLE") if location == null else tr("UI_TAVERN_TITLE_CITY") % location.location_name

	_content.add_child(HSeparator.new())
	_purification_panel = PurificationPanel.new()
	_content.add_child(_purification_panel)
	_purification_panel.setup(_session, tr("UI_PURIFY_TRAIT"), PURIFICATION_COST)
	_purification_panel.trait_removed.connect(_refresh_rows)

	# Ziyafet: stresin paralı kolu. Varış rahatlaması artık seferin
	# getirdiğini tek başına eritmiyor (bkz. GameSession.get_city_rest_relief),
	# o yüzden oyuncunun kesesiyle müdahale edebileceği bir yol olmalı -
	# yoksa stres kaçınılmaz bir sayaca dönerdi.
	_content.add_child(HSeparator.new())
	_feast_label = Label.new()
	_feast_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(_feast_label)
	_feast_button = Button.new()
	_feast_button.pressed.connect(_on_feast_pressed)
	_content.add_child(_feast_button)

	_session.wallet.balance_changed.connect(_on_wallet_changed)
	_build_rows()
	_refresh_rows()
	_refresh_feast()

func _refresh_feast() -> void:
	_feast_label.text = tr("UI_TAVERN_FEAST_HINT") % [
		_session.party_stress, GameSession.MAX_STRESS, GameSession.FEAST_STRESS_RELIEF
	]
	_feast_button.text = tr("UI_TAVERN_FEAST") % _session.get_feast_cost()
	_feast_button.disabled = not _session.can_afford_feast()

func _on_feast_pressed() -> void:
	if _session.throw_feast():
		_refresh_feast()

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

		# Yolun o günkü hali herkesin gözü önünde - çamura batmış bir geçit
		# dedikodu değil, meydan sohbeti. Parayla öğrenilen şey tehlikenin
		# *yüzdesi* (bkz. GameSession.known_routes), yolun durumu değil.
		var days := _session.get_route_travel_days(route)
		var state := _session.get_route_state(route)
		var state_note := ""
		if state != RouteConditions.State.OPEN:
			state_note = " · %s" % RouteConditions.get_state_label(state)

		if known:
			var effective_danger := _session.get_route_danger(route)
			status_label.text = tr("UI_TAVERN_ROUTE_KNOWN") % [
				days, int(effective_danger * 100.0), state_note
			]
			buy_button.text = tr("UI_TAVERN_LEARNED")
			buy_button.disabled = true
		else:
			var cost := _rumor_cost(route)
			status_label.text = tr("UI_TAVERN_ROUTE_UNKNOWN") % [days, state_note]
			buy_button.text = tr("UI_TAVERN_BUY_RUMOUR") % cost
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
	_refresh_feast()
	_purification_panel.refresh()

func _on_map_pressed() -> void:
	Nav.return_scene = Nav.CITY_MAP
	get_tree().change_scene_to_file(Nav.TRAVEL)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)

## Tayfa ekranı ortak; hangi mekândan girildiğini gönderen ekran bildirir
## (bkz. Nav.recruit_venue). Geri tuşu buraya döner - ama bunu
## return_scene'e yazarak değil (o bu ekranın *kendi* geri hedefi,
## ezilirse şehre çıkış kapanır), Nav.recruit_return_scene üzerinden.
func _add_recruit_button(venue: String, own_scene: String) -> void:
	var button := Button.new()
	button.text = tr("UI_LOOK_FOR_CREW")
	button.pressed.connect(_on_recruit_button_pressed.bind(venue, own_scene))
	var container := _back_button.get_parent()
	container.add_child(button)
	container.move_child(button, _back_button.get_index())

func _on_recruit_button_pressed(venue: String, own_scene: String) -> void:
	get_tree().change_scene_to_file(Nav.open_recruit(venue, own_scene))
