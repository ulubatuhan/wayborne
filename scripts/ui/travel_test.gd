extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const CARAVAN_PLANNER_SCENE: String = "res://scenes/tests/caravan_planner_test.tscn"

const POINT_SIZE: Vector2 = Vector2(130, 44)
const ROUTE_COLOR: Color = Color(0.45, 0.4, 0.32)
const ROUTE_WIDTH: float = 3.0
const CURRENT_LOCATION_COLOR: Color = Color(1.0, 0.85, 0.4)
const REACHABLE_COLOR: Color = Color(0.75, 0.85, 1.0)
const UNREACHABLE_COLOR: Color = Color(0.5, 0.5, 0.5)

var _session: GameSession
var _current_location_id: String = WorldMapData.START_LOCATION_ID
var _focused_location: Location

@onready var _map_panel: Control = $MarginContainer/VBoxContainer/ContentRow/MapPanel
@onready var _info_panel: VBoxContainer = $MarginContainer/VBoxContainer/ContentRow/InfoScroll/InfoPanel
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	_current_location_id = _session.current_location_id
	_back_button.pressed.connect(_on_back_pressed)
	_build_map()
	_show_hint()

func _build_map() -> void:
	for route in WorldMapData.get_routes_from(_current_location_id):
		var from_location := WorldMapData.get_location_by_id(route.from_location_id)
		var to_location := WorldMapData.get_location_by_id(route.to_location_id)
		if from_location == null or to_location == null:
			continue
		_map_panel.add_child(_build_route_line(from_location.map_position, to_location.map_position))

	for location in WorldMapData.get_locations():
		_map_panel.add_child(_build_location_point(location))

func _build_route_line(from_position: Vector2, to_position: Vector2) -> Line2D:
	var line := Line2D.new()
	line.points = PackedVector2Array([from_position, to_position])
	line.width = ROUTE_WIDTH
	line.default_color = ROUTE_COLOR
	return line

func _build_location_point(location: Location) -> Button:
	var button := Button.new()
	button.custom_minimum_size = POINT_SIZE
	button.size = POINT_SIZE
	button.position = location.map_position - (POINT_SIZE / 2.0)

	var is_current := location.location_id == _current_location_id
	var route := WorldMapData.get_route(_current_location_id, location.location_id)

	if is_current:
		button.text = "%s\n(buradasın)" % location.location_name
		button.disabled = true
		button.modulate = CURRENT_LOCATION_COLOR
	elif route == null:
		button.text = location.location_name
		button.disabled = true
		button.modulate = UNREACHABLE_COLOR
	else:
		button.text = location.location_name
		button.modulate = REACHABLE_COLOR
		button.mouse_entered.connect(_on_location_hovered.bind(location))
		button.pressed.connect(_on_location_pressed.bind(location))

	return button

func _show_hint() -> void:
	_clear_info_panel()
	var current := WorldMapData.get_location_by_id(_current_location_id)
	_add_info_label("Mevcut Konum: %s" % current.location_name)
	_add_info_label("Bir hedefin üzerine gel: oraya gitmek isteyen tüccarlar ve potansiyel getiri burada listelenir.")

func _on_location_hovered(location: Location) -> void:
	_focused_location = location
	_refresh_info_panel()

func _on_location_pressed(location: Location) -> void:
	_go_to_planner(location)

func _refresh_info_panel() -> void:
	_clear_info_panel()

	var route := WorldMapData.get_route(_current_location_id, _focused_location.location_id)
	if route == null:
		_add_info_label("Buraya doğrudan bir yol yok.")
		return

	_add_info_label("Hedef: %s" % _focused_location.location_name)
	_add_info_label("Yol: %d gün · Tehlike: %d%%" % [route.travel_days, int(route.danger_level * 100.0)])

	var offers := WorldMapData.get_offers_for_destination(_focused_location.location_id)
	_add_info_label("Buraya gitmek isteyen tüccarlar (%d):" % offers.size())

	var total_profit := 0
	for offer in offers:
		total_profit += offer.potential_profit
		_add_info_label("  • %s — %d vagon — +%d GG" % [offer.merchant_name, offer.wagon_count, offer.potential_profit])

	_add_info_label("Toplam potansiyel getiri: %d GG" % total_profit)

	var plan_button := Button.new()
	plan_button.text = "Planla: %s" % _focused_location.location_name
	plan_button.pressed.connect(_on_plan_pressed)
	_info_panel.add_child(plan_button)

func _on_plan_pressed() -> void:
	if _focused_location == null:
		return
	_go_to_planner(_focused_location)

func _go_to_planner(location: Location) -> void:
	TravelContext.selected_destination_id = location.location_id
	get_tree().change_scene_to_file(CARAVAN_PLANNER_SCENE)

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
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
