extends Control

const POINT_SIZE: Vector2 = Vector2(130, 44)
const ROUTE_WIDTH: float = 3.0
const PIN_FILE: String = "k5_pip_filled.png"
const PIN_CLOSED_FILE: String = "k5_pip_hollow.png"
const PIN_SIZE: float = 22.0
## Uzun şehir adı raptiyenin iki yanına taşabilsin (yazı kutuya sığdırılmıyor).
const LABEL_OVERHANG: float = 40.0
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
	$MarginContainer/VBoxContainer/TitleLabel.text = tr("UI_MAP_TITLE")
	_session = GameState.get_session()
	_current_location_id = _session.current_location_id
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)
	_build_map()
	_show_hint()
	var row: Control = _map_panel.get_parent()
	row.resized.connect(_fit_map)
	_fit_map()

## Harita, yazısız bir arazi parşömeni (B6): şehirler ve yollar görselde
## yok, `Location.map_position`'dan canlı çiziliyor - isim, yol durumu ve
## dil ne olursa olsun resim doğru kalıyor (Localization Rules).
const MAP_ART_FILE: String = "b6_map.png"
## Şehir düğümleri en fazla ~(650, 400)'e uzanıyor; parşömen biraz taşsın ki
## kenardaki şehir de kâğıdın üstünde dursun.
const MAP_ART_MARGIN: Vector2 = Vector2(30.0, 30.0)
## Şehirlerin konumları 700x420'lik sabit bir tuvalde; 1920 genişlikte bu
## ekranın köşesinde küçük bir kâğıt kalıyordu (ölçüldü). Tuval, satırın
## bu oranına kadar büyüyor - bilgi paneline yer bırakarak.
const MAP_BASE_SIZE: Vector2 = Vector2(700.0, 420.0)
const MAP_ROW_SHARE: float = 0.58
const MAP_MAX_SCALE: float = 1.8

var _map_canvas: Control

## Haritanın ölçeği: satırın genişliğinin MAP_ROW_SHARE'i ve yüksekliği
## içinde kalan en büyük değer, asla 1'in altında değil.
static func map_scale(row_size: Vector2) -> float:
	var padded := MAP_BASE_SIZE + MAP_ART_MARGIN * 2.0
	var by_width := row_size.x * MAP_ROW_SHARE / padded.x
	var by_height := row_size.y / padded.y
	return clampf(minf(by_width, by_height), 1.0, MAP_MAX_SCALE)

func _fit_map() -> void:
	var row: Control = _map_panel.get_parent()
	var factor := map_scale(row.size)
	_map_canvas.scale = Vector2(factor, factor)
	_map_canvas.position = MAP_ART_MARGIN * factor
	_map_panel.custom_minimum_size = (MAP_BASE_SIZE + MAP_ART_MARGIN * 2.0) * factor

func _build_map() -> void:
	# Bütün harita tek bir tuvalde, tek bir ölçekle - düğmeler de ölçekle
	# birlikte tıklanıyor, konumlar Location.map_position olarak kalıyor.
	_map_canvas = Control.new()
	_map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(_map_canvas)
	var art := TextureRect.new()
	art.texture = WaybookTheme.texture(MAP_ART_FILE)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.position = -MAP_ART_MARGIN
	art.size = MAP_BASE_SIZE + MAP_ART_MARGIN * 2.0
	_map_canvas.add_child(art)

	for route in WorldMapData.get_routes_from(_current_location_id):
		var from_location := WorldMapData.get_location_by_id(route.from_location_id)
		var to_location := WorldMapData.get_location_by_id(route.to_location_id)
		if from_location == null or to_location == null:
			continue
		_map_canvas.add_child(_build_route_line(
			from_location.map_position, to_location.map_position, _session.get_route_state(route)
		))

	for location in WorldMapData.get_locations():
		_map_canvas.add_child(_build_location_point(location))

func _build_route_line(
	from_position: Vector2, to_position: Vector2, state: RouteConditions.State
) -> Line2D:
	var line := Line2D.new()
	line.points = PackedVector2Array([from_position, to_position])
	line.width = ROUTE_WIDTH
	line.default_color = ROUTE_STATE_COLORS[int(state)]
	return line

## Şehir, parşömene mürekkeple yazılmış bir ad ve altında pirinç bir raptiye:
## kutu yok. Düz bir düğme kutusu (ve kapalı yolun karalanmış sekmesi)
## haritanın taramasının üstünde gri bir yama gibi duruyordu (ölçüldü).
## Kilitli şehir yine gizlenmiyor: soluk mürekkep ve sebebi yazıda.
func _build_location_point(location: Location) -> Control:
	var marker := Control.new()
	marker.position = location.map_position - (POINT_SIZE / 2.0)
	marker.size = POINT_SIZE
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pin := WaybookTheme.picture(PIN_FILE, PIN_SIZE)
	pin.position = Vector2((POINT_SIZE.x - PIN_SIZE) * 0.5, (POINT_SIZE.y - PIN_SIZE) * 0.5)
	pin.size = Vector2(PIN_SIZE, PIN_SIZE)
	marker.add_child(pin)

	var button := Button.new()
	button.theme_type_variation = WaybookTheme.MAP_LABEL
	button.position = Vector2(-LABEL_OVERHANG, POINT_SIZE.y * 0.5 + PIN_SIZE * 0.3)
	# Ölçüldü: metinle taşınan yükseklik 27-38 px'e düşüyordu - dokunma/
	# tıklama hedefi olarak dar. POINT_SIZE.y (44) zaten bu işaretin kendi
	# tasarlanmış boyu, tabanı da ondan alıyor.
	button.custom_minimum_size = Vector2(POINT_SIZE.x + LABEL_OVERHANG * 2.0, POINT_SIZE.y)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.add_child(button)

	var is_current := location.location_id == _current_location_id
	var route := WorldMapData.get_route(_current_location_id, location.location_id)

	if is_current:
		button.text = tr("UI_MAP_YOU_ARE_HERE") % location.location_name
		button.disabled = true
		# Buradasın: dolu raptiye, yazı da tam mürekkep (soluk değil).
		button.add_theme_color_override("font_disabled_color", ArtPalette.BLOOD)
	elif route == null or not _session.is_route_open(route):
		# Kapalı geçit tıklanamaz ama gizlenmez: kilitli olay seçenekleriyle
		# aynı kural - sebebiyle birlikte gösterilir (bkz. CLAUDE.md).
		button.text = location.location_name
		if route != null:
			button.text += "\n(%s)" % RouteConditions.get_state_label(RouteConditions.State.CLOSED)
		button.disabled = true
		pin.texture = WaybookTheme.texture(PIN_CLOSED_FILE)
		pin.modulate = Color(1, 1, 1, 0.6)
		button.mouse_entered.connect(_on_location_hovered.bind(location))
	else:
		button.text = location.location_name
		button.mouse_entered.connect(_on_location_hovered.bind(location))
		button.pressed.connect(_on_location_pressed.bind(location))

	button.text += _city_event_suffix(location.location_id)
	return marker

## Faz 17: haritanın büyük, adlı olayları (bkz. WorldEvents) burada da
## görünür olmalı - "her hidden penalty bir bug'dır" kuralının aynısı
## piyasa şoku ve rota tehlikesinde de geçerliydi. Şehir üzerine biner
## biner (veba/fuar), rota üzerine biner biner (savaş/haraç) - hedefe
## uygun sorgu okunur.
func _city_event_suffix(location_id: String) -> String:
	var labels: Array[String] = []
	for entry in _session.world_events.get_city_events(location_id, _session.total_days_elapsed):
		labels.append(_t(WorldEvents.get_label_key(int(entry["kind"]) as WorldEvents.Kind)))
	if labels.is_empty():
		return ""
	return "\n[%s]" % ", ".join(labels)

func _route_event_suffix(route: TravelRoute) -> String:
	if route == null:
		return ""
	var route_key := RouteConditions.route_key(route.from_location_id, route.to_location_id)
	var labels: Array[String] = []
	for entry in _session.world_events.get_route_events(route_key, _session.total_days_elapsed):
		labels.append(_t(WorldEvents.get_label_key(int(entry["kind"]) as WorldEvents.Kind)))
	if labels.is_empty():
		return ""
	return " · %s" % ", ".join(labels)

func _t(key: String) -> String:
	return String(TranslationServer.translate(key))

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
			_add_info_label(tr("UI_MAP_CONTRACT_LINE") % [tr(offer.merchant_name), offer.wagon_count, offer.potential_profit])
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
	state_note += _route_event_suffix(route)

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
		String(TranslationServer.translate("ROUTE_DETOUR_AVAILABLE")), " » ".join(names)
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
	SceneInk.go(Nav.open(Nav.TRAVEL, Nav.CARAVAN_PLANNER))

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
	SceneInk.go(Nav.back())
