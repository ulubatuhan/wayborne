extends Control

const POINT_SIZE: Vector2 = Vector2(130, 44)
const ROUTE_WIDTH: float = 3.0
const CURRENT_LOCATION_COLOR: Color = Color(1.0, 0.85, 0.4)
const REACHABLE_COLOR: Color = Color(0.75, 0.85, 1.0)
const UNREACHABLE_COLOR: Color = Color(0.5, 0.5, 0.5)
## Yolun o günkü hali (bkz. RouteConditions) çizgiye de vuruyor: harita
## tek bakışta hangi geçidin kapalı, hangisinin eşkıya kaynadığını
## söylemezse dinamik rota diye bir şey oyuncu için yok demektir.
const ROUTE_STATE_COLORS: Array[Color] = [
	Color(0.45, 0.40, 0.32),
	Color(0.55, 0.50, 0.25),
	Color(0.62, 0.32, 0.28),
	Color(0.32, 0.30, 0.30),
]

var _session: GameSession
var _current_location_id: String = WorldMapData.START_LOCATION_ID
var _focused_location: Location

@onready var _map_panel: Control = $MarginContainer/VBoxContainer/ContentRow/MapPanel
@onready var _info_panel: VBoxContainer = $MarginContainer/VBoxContainer/ContentRow/InfoScroll/InfoPanel
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	_current_location_id = _session.current_location_id
	_back_button.text = Nav.return_label()
	_back_button.pressed.connect(_on_back_pressed)
	_build_map()
	_show_hint()

func _build_map() -> void:
	for route in WorldMapData.get_routes_from(_current_location_id):
		var from_location := WorldMapData.get_location_by_id(route.from_location_id)
		var to_location := WorldMapData.get_location_by_id(route.to_location_id)
		if from_location == null or to_location == null:
			continue
		_map_panel.add_child(_build_route_line(
			from_location.map_position, to_location.map_position, _session.get_route_state(route)
		))

	for location in WorldMapData.get_locations():
		_map_panel.add_child(_build_location_point(location))

func _build_route_line(
	from_position: Vector2, to_position: Vector2, state: RouteConditions.State
) -> Line2D:
	var line := Line2D.new()
	line.points = PackedVector2Array([from_position, to_position])
	line.width = ROUTE_WIDTH
	line.default_color = ROUTE_STATE_COLORS[int(state)]
	return line

func _build_location_point(location: Location) -> Button:
	var button := Button.new()
	button.custom_minimum_size = POINT_SIZE
	button.size = POINT_SIZE
	button.position = location.map_position - (POINT_SIZE / 2.0)

	var is_current := location.location_id == _current_location_id
	var route := WorldMapData.get_route(_current_location_id, location.location_id)

	if is_current:
		button.text = tr("UI_MAP_YOU_ARE_HERE") % location.location_name
		button.disabled = true
		button.modulate = CURRENT_LOCATION_COLOR
	elif route == null or not _session.is_route_open(route):
		# Kapalı geçit tıklanamaz ama gizlenmez: kilitli olay seçenekleriyle
		# aynı kural - sebebiyle birlikte gösterilir (bkz. CLAUDE.md).
		button.text = location.location_name
		if route != null:
			button.text += "\n(%s)" % RouteConditions.get_state_label(RouteConditions.State.CLOSED)
		button.disabled = true
		button.modulate = UNREACHABLE_COLOR
		button.mouse_entered.connect(_on_location_hovered.bind(location))
	else:
		button.text = location.location_name
		button.modulate = REACHABLE_COLOR
		button.mouse_entered.connect(_on_location_hovered.bind(location))
		button.pressed.connect(_on_location_pressed.bind(location))

	return button

func _show_hint() -> void:
	_clear_info_panel()
	var current := WorldMapData.get_location_by_id(_current_location_id)
	_add_info_label(tr("UI_MAP_CURRENT") % current.location_name)
	_add_info_label(tr("UI_MAP_HINT"))

func _on_location_hovered(location: Location) -> void:
	_focused_location = location
	_refresh_info_panel()

func _on_location_pressed(location: Location) -> void:
	_go_to_planner(location)

func _refresh_info_panel() -> void:
	_clear_info_panel()

	var route := WorldMapData.get_route(_current_location_id, _focused_location.location_id)
	if route == null:
		_add_info_label(tr("UI_MAP_NO_DIRECT_ROUTE"))
		_add_detour_hint()
		return

	_add_info_label(tr("UI_MAP_DESTINATION") % _focused_location.location_name)
	_add_info_label(_route_summary(route))

	# Kapalı yol çıkmaz sokak değil: dolambaçlı yol varsa oyuncu görmeli,
	# yoksa harita kendini kilitlemiş gibi görünür.
	if not _session.is_route_open(route):
		_add_detour_hint()
		return

	var offers := _session.get_accepted_offers_for_destination(_focused_location.location_id)
	if offers.is_empty():
		_add_info_label(tr("UI_NO_CONTRACTS_FOR_DESTINATION"))
	else:
		_add_info_label(tr("UI_MAP_ACCEPTED_CONTRACTS") % offers.size())
		var total_profit := 0
		for offer in offers:
			total_profit += offer.potential_profit
			_add_info_label(tr("UI_MAP_CONTRACT_LINE") % [offer.merchant_name, offer.wagon_count, offer.potential_profit])
		_add_info_label(tr("UI_TOTAL_POTENTIAL") % total_profit)

	var plan_button := Button.new()
	plan_button.text = tr("UI_MAP_PLAN") % _focused_location.location_name
	plan_button.pressed.connect(_on_plan_pressed)
	_info_panel.add_child(plan_button)

## Tehlike yüzdesi Taverna'da öğrenilmişse ya da kervanda bir İzci
## varsa (bkz. DutyCatalog.IZCI - ücretsiz, ödeme gerektirmeyen keşif)
## tam gösterilir; ikisi de yoksa kaba bir bant gösterir (bkz.
## GameSession.known_routes).
## Süre ve tehlike artık rotanın ham tablosundan değil, yolun **o günkü**
## halinden okunuyor (bkz. GameSession.get_route_travel_days/_danger):
## ekranda görülen ile yolda yaşanan ayrışmasın diye.
func _route_summary(route: TravelRoute) -> String:
	var days := _session.get_route_travel_days(route)
	var effective_danger := _session.get_route_danger(route)
	var state := _session.get_route_state(route)
	var state_note := ""
	if state != RouteConditions.State.OPEN:
		state_note = " · %s" % RouteConditions.get_state_label(state)

	if _session.is_route_known(_current_location_id, route.to_location_id):
		return tr("UI_MAP_ROUTE_KNOWN") % [days, int(effective_danger * 100.0), state_note]
	if _session.get_duty_holder(DutyCatalog.IZCI) != null:
		return tr("UI_MAP_ROUTE_SCOUTED") % [
			days, int(effective_danger * 100.0), state_note
		]
	return tr("UI_MAP_ROUTE_UNKNOWN") % [
		days, _danger_band(effective_danger), state_note
	]

## Doğrudan yol kapalı ya da hiç yokken alternatifi gösterir.
func _add_detour_hint() -> void:
	var path := _session.find_open_path(_focused_location.location_id)
	if path.size() < 2:
		# Sebep satırını çağıran yazıyor ("yol yok" mu "geçit kapalı" mı) -
		# burada yalnızca alternatifin olmadığı söyleniyor.
		_add_info_label(String(TranslationServer.translate("ROUTE_NO_PATH")))
		return

	var names: Array[String] = []
	for location_id in path:
		var stop := WorldMapData.get_location_by_id(location_id)
		names.append(stop.location_name if stop != null else location_id)
	_add_info_label("%s: %s" % [
		String(TranslationServer.translate("ROUTE_DETOUR_AVAILABLE")), " → ".join(names)
	])
	_add_info_label(tr("UI_MAP_FIRST_STOP") % names[1])

func _danger_band(danger: float) -> String:
	if danger < 0.3:
		return tr("UI_DANGER_LOW")
	if danger < 0.55:
		return tr("UI_DANGER_MEDIUM")
	return tr("UI_DANGER_HIGH")

func _on_plan_pressed() -> void:
	if _focused_location == null:
		return
	_go_to_planner(_focused_location)

func _go_to_planner(location: Location) -> void:
	TravelContext.selected_destination_id = location.location_id
	get_tree().change_scene_to_file(Nav.CARAVAN_PLANNER)

func _add_info_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_info_panel.add_child(label)

func _clear_info_panel() -> void:
	for child in _info_panel.get_children():
		_info_panel.remove_child(child)
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)
