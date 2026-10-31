extends Control

## Dünya haritası ekranı (görev N7): harita v3, karo katmanıyla (WorldMapView,
## MapTileView). Yerleşimler ve buradan çıkan yollar haritanın üstüne çizilir;
## sağ sütun seçilen hedefin bilgisini ve "Bu rotayı planla" düğmesini taşır.
##
## "Buradasın" işaretinin çevresindeki halka Ruin Rules'un
## `POWER_SCALE_PER_PARTY_MEMBER`'ının görsel yankısı: vagon arttıkça daralır
## ("güçlendim" değil "sıkıştım").

## Yolun o günkü hali (bkz. RouteConditions) çizgiye de vuruyor: harita
## tek bakışta hangi geçidin kapalı, hangisinin eşkıya kaynadığını
## söylemezse dinamik rota diye bir şey oyuncu için yok demektir.
const ROUTE_STATE_COLORS: Array[Color] = [
	Color(0.45, 0.40, 0.32),
	Color(0.55, 0.50, 0.25),
	Color(0.62, 0.32, 0.28),
	Color(0.32, 0.30, 0.30),
]

## Bir vagonda (sefere yeni çıkmış bir kervan) halka en geniş; bu sayıda
## vagona ulaşınca en dar hâline iner - sonrası aynı minimumda kalır,
## çünkü halka bir uyarı işareti, sonsuza dek küçülen bir çizim değil.
const SAFE_ZONE_RING_MAX_RADIUS: float = 46.0
const SAFE_ZONE_RING_MIN_RADIUS: float = 20.0
const SAFE_ZONE_RING_WAGONS_FOR_MIN: int = 6

## Saf, testable bir eşleme - `owned_wagon_count`'tan halka yarıçapına.
## Ters orantı doğrusal: yeni bir eğri icat etmenin ölçülecek bir şeyi yok,
## bu yalnızca zaten var olan mekanik gerçeğin bir görsel etiketi.
static func safe_zone_ring_radius(owned_wagon_count: int) -> float:
	var span := maxi(1, SAFE_ZONE_RING_WAGONS_FOR_MIN - 1)
	var t := clampf(float(owned_wagon_count - 1) / float(span), 0.0, 1.0)
	return lerpf(SAFE_ZONE_RING_MAX_RADIUS, SAFE_ZONE_RING_MIN_RADIUS, t)

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
	_select_default_destination()

var _map_view: WorldMapView

## Harita ekranın büyük kısmını alır; karo katmanı ve işaretler bir arada.
## Boyut çapayla değil, panelin `resized`'ıyla (bkz. Art Rules'un çapa tuzağı).
func _build_map() -> void:
	_map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_panel.size_flags_stretch_ratio = 2.2
	_map_panel.custom_minimum_size = Vector2(640, 420)
	_map_panel.clip_contents = true
	_map_view = WorldMapView.new()
	_map_view.tiles.mouse_filter = Control.MOUSE_FILTER_PASS
	_map_panel.add_child(_map_view)
	_map_panel.resized.connect(_fit_map)
	_map_view.current_location_id = _current_location_id
	_map_view.hour = _session.last_clock_hour
	_map_view.trail = _session.map_trail
	_map_view.camps = _session.journey_camps
	_map_view.graves = _session.map_graves()
	_map_view.safe_ring_radius = safe_zone_ring_radius(_session.owned_wagon_count)
	var routes: Array = []
	for route in WorldMapData.get_routes_from(_current_location_id):
		routes.append({"to": route.to_location_id, "color": ROUTE_STATE_COLORS[int(_session.get_route_state(route))]})
	_map_view.routes = routes
	_map_view.location_pressed.connect(func(id): _on_location_pressed(WorldMapData.get_location_by_id(id)))
	_map_view.location_hovered.connect(func(id): _on_location_hovered(WorldMapData.get_location_by_id(id)))
	var bar := HBoxContainer.new()
	bar.position = Vector2(12, 12)
	bar.add_theme_constant_override("separation", 6)
	_map_panel.add_child(bar)
	for spec in [["UI_MAP_GO_CARAVAN", func(): _map_view.focus_caravan(0.3)], ["+", func(): _map_view.tiles.zoom_by(1.4, _map_view.size * 0.5)], ["-", func(): _map_view.tiles.zoom_by(1.0 / 1.4, _map_view.size * 0.5)], ["UI_MAP_WHOLE", func(): _map_view.tiles.reset_view()]]:
		var b := Button.new()
		b.text = tr(String(spec[0])) if String(spec[0]).begins_with("UI_") else String(spec[0])
		b.pressed.connect(spec[1])
		bar.add_child(b)
	_fit_map.call_deferred()

func _fit_map() -> void:
	if _map_view == null:
		return
	_map_view.size = _map_panel.size
	if not _map_view.has_meta("focused_once") and _map_panel.size.x > 10.0:
		_map_view.set_meta("focused_once", true)
		_map_view.focus_caravan(0.12)

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

## Sağ sütun eskiden yalnızca "bir yere gelin" ipucuyla açılıyordu - dokunmada
## hover diye bir şey yok, o yüzden sütun dokunmatik bir cihazda hiç
## dolmuyordu. Açılışta ilk gidilebilir rota kendiliğinden seçili gelir;
## gidilebilir hiçbir rota yoksa (kuramsal, beş şehirlik haritada olmaz)
## eski statik ipucuna düşer.
func _select_default_destination() -> void:
	for route in WorldMapData.get_routes_from(_current_location_id):
		if not _session.is_route_open(route):
			continue
		var destination := WorldMapData.get_location_by_id(route.to_location_id)
		if destination == null:
			continue
		_focused_location = destination
		_refresh_info_panel()
		return
	_show_hint()

func _on_location_hovered(location: Location) -> void:
	if location == null:
		return
	_focused_location = location
	_refresh_info_panel()

## Tıklama artık doğrudan planlayıcıya atlamıyor - seçim yapıyor (hover ile
## aynı yol), "Bu rotayı planla" düğmesi kararı tamamlıyor. Fareyle gezinme
## deneyimini dokunmatikte de tek tıkla eşitliyor.
func _on_location_pressed(location: Location) -> void:
	if location == null:
		return
	_focused_location = location
	_refresh_info_panel()

func _refresh_info_panel() -> void:
	_clear_info_panel()
	if _map_view != null:
		_map_view.focused_location_id = _focused_location.location_id
	_add_info_label(_settlement_line(_focused_location))

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
			if offer.uses_donkey_escort():
				_add_info_label(tr("UI_MAP_CONTRACT_LINE_DONKEY") % [
					tr(offer.merchant_name), offer.donkey_count, offer.potential_profit
				])
			else:
				_add_info_label(tr("UI_MAP_CONTRACT_LINE") % [tr(offer.merchant_name), offer.wagon_count, offer.potential_profit])
		_add_info_label(tr("UI_TOTAL_POTENTIAL") % total_profit)

	var plan_button := Button.new()
	plan_button.text = tr("UI_MAP_PLAN") % _focused_location.location_name
	plan_button.pressed.connect(_on_plan_pressed)
	_info_panel.add_child(plan_button)
	# Yasaklı yer (Y-C29): düğme kilitli, nedeni yanında (gizlenmez).
	if _session.is_banned(_focused_location.location_id):
		plan_button.disabled = true
		_add_info_label(tr("UI_MAP_BANNED"))

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

## Yerin türü ve bölgesi; burada yapılabilecekler (kasabada lonca yok...).
func _settlement_line(location: Location) -> String:
	var type_key := {"city": "UI_SETTLEMENT_CITY", "town": "UI_SETTLEMENT_TOWN", "caravanserai": "UI_SETTLEMENT_CARAVANSERAI"}
	return "%s · %s" % [location.location_name, tr(String(type_key.get(location.settlement_type, "UI_SETTLEMENT_CITY")))]

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
