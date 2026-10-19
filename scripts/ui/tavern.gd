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
## Fiyat söylentisi (görev Y-C10): komşu şehirlerin fiyatı, bazen yanlış.
var _price_rumor_list: VBoxContainer

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _info_label: Label = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/InfoLabel
@onready var _rumor_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/RumorList
@onready var _map_button: Button = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/MapButton
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	WaybookTheme.fit_desk_workspace(self)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	# Sahne dosyasındaki yazı yalnızca editör içindir; oyuncunun gördüğü her
	# metin koddan, anahtarla gelir (bkz. Localization Rules).
	_info_label.text = tr("UI_TAVERN_HINT")
	_map_button.text = tr("UI_GO_TO_WORLD_MAP")
	_session = GameState.get_session()
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)
	_map_button.pressed.connect(_on_map_pressed)
	RecruitButton.add_before(_back_button, RecruitCatalog.VENUE_TAVERN, Nav.TAVERN)

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

	_content.add_child(HSeparator.new())
	var price_heading := Label.new()
	price_heading.autowrap_mode = TextServer.AUTOWRAP_WORD
	price_heading.text = tr("UI_PRICE_RUMOR_HEADING") % int(round(GameSession.PRICE_RUMOR_FALSE_CHANCE * 100.0))
	_content.add_child(price_heading)
	_price_rumor_list = VBoxContainer.new()
	_content.add_child(_price_rumor_list)
	var book_button := Button.new()
	book_button.text = tr("UI_PRICE_BOOK_OPEN")
	book_button.pressed.connect(func(): add_child(PriceBookPanel.new().setup(_session)))
	_content.add_child(book_button)

	_session.wallet.balance_changed.connect(_on_wallet_changed)
	_build_rows()
	_refresh_rows()
	_refresh_feast()
	_refresh_price_rumors()

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

## Komşu her şehir için bir satır: bildiğimizin yaşı, söylentinin bedeli ya
## da neden alınamadığı (kilitli düğme sebebiyle, gizlenmez).
func _refresh_price_rumors() -> void:
	for child in _price_rumor_list.get_children():
		child.queue_free()
	for route in WorldMapData.get_routes_from(_session.current_location_id):
		var target := route.to_location_id
		var destination := WorldMapData.get_location_by_id(target)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label := Label.new()
		name_label.text = destination.location_name if destination != null else target
		name_label.custom_minimum_size = Vector2(160, 0)
		row.add_child(name_label)
		var age := _session.get_price_age(target)
		var known := Label.new()
		known.custom_minimum_size = Vector2(200, 0)
		known.text = tr("UI_PRICE_RUMOR_UNKNOWN") if age < 0 else tr("UI_PRICE_RUMOR_KNOWN") % age
		row.add_child(known)
		var button := Button.new()
		button.text = tr("UI_PRICE_RUMOR_BUY") % _session.get_price_rumor_cost(target)
		var reason := _session.get_price_rumor_block_reason(target)
		button.disabled = not reason.is_empty()
		button.pressed.connect(func():
			if _session.buy_price_rumor(target):
				_refresh_price_rumors())
		row.add_child(button)
		if not reason.is_empty():
			var why := Label.new()
			why.text = tr(reason)
			why.modulate = Color(0.75, 0.72, 0.66)
			row.add_child(why)
		_price_rumor_list.add_child(row)

func _on_wallet_changed(_new_balance: int) -> void:
	_refresh_price_rumors()
	_refresh_rows()
	_refresh_feast()
	_purification_panel.refresh()

func _on_map_pressed() -> void:
	SceneInk.go(Nav.open(Nav.TAVERN, Nav.TRAVEL))

func _on_back_pressed() -> void:
	SceneInk.go(Nav.back())
