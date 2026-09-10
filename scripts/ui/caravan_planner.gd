extends Control

## Kervan planlayıcı. Erzağı gerçek envanterden okur, eksiği cüzdandan
## satın aldırır ve onaylandığında kervanı gerçekten yola çıkarır.

const SHORTFALL_COLOR: Color = Color(0.9, 0.45, 0.35)
const SATISFIED_COLOR: Color = Color(0.45, 0.8, 0.45)

var _session: GameSession
var _plan: CaravanPlan
var _destination: Location
var _route_danger: float = 0.0
var _route_state: RouteConditions.State = RouteConditions.State.OPEN
var _offer_rows: Array[Dictionary] = []

var _wagon_counter_label: Label
var _gold_label: Label
var _party_label: Label
var _documents_label: Label
var _required_provisions_label: Label
var _current_provisions_label: Label
var _shortfall_label: Label
var _profit_label: Label
var _morale_label: Label
var _morale_reasons: VBoxContainer
var _buy_provisions_button: Button
var _confirm_button: Button
var _result_label: Label

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer

func _ready() -> void:
	_session = GameState.get_session()

	_destination = WorldMapData.get_location_by_id(TravelContext.selected_destination_id)
	var origin := WorldMapData.get_location_by_id(_session.current_location_id)

	if _destination == null or origin == null:
		_build_missing_context_ui()
		return

	var route := WorldMapData.get_route(origin.location_id, _destination.location_id)
	var travel_days: int = 1
	if route != null:
		# Süre ve tehlike yolun ham tablosundan değil o günkü halinden
		# geliyor (bkz. RouteConditions): çamur yolu uzatır, eşkıya
		# tehlikeyi yükseltir. İzci bunun üstüne biner - öndeki tehlikeyi
		# ve en kısa yolu bilir, kervandaysa yol kısalır (asla bir günün
		# altına inmez), bkz. DutyCatalog.IZCI.
		var izci_reduction := _session.get_duty_flat_reduction(DutyCatalog.IZCI)
		travel_days = maxi(1, _session.get_route_travel_days(route) - izci_reduction)
		_route_danger = _session.get_route_danger(route)
		_route_state = _session.get_route_state(route)

	_plan = CaravanPlan.new(
		_destination, travel_days, CaravanPlan.DEFAULT_MAX_WAGONS, _session.owned_wagon_count
	)
	# Erzak hesabının kervana bağlı parçaları: kimi besleyeceğimiz, kültürün
	# iştahı ve levazımcının tasarrufu. Bunlar verilmezse plan yolun gerçekte
	# yiyeceğinden az bir sayı gösterir.
	_plan.caravan_party_size = _session.get_party().size()
	_plan.provision_multiplier = _session.get_daily_provision_multiplier()
	_plan.provision_reduction = _session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI)

	_session.wallet.balance_changed.connect(_on_wallet_changed)
	_session.inventory.item_added.connect(_on_inventory_changed)
	_session.inventory.item_removed.connect(_on_inventory_changed)

	_build_ui(origin, _destination, travel_days)
	_refresh()

func _build_missing_context_ui() -> void:
	var label := Label.new()
	label.text = tr("UI_PLANNER_NO_DESTINATION")
	_content.add_child(label)

	var back_button := Button.new()
	back_button.text = tr("UI_BACK_TO_MAP")
	back_button.pressed.connect(_on_map_pressed)
	$MarginContainer/VBoxContainer.add_child(back_button)

func _build_ui(origin: Location, destination: Location, travel_days: int) -> void:
	var title := Label.new()
	title.text = tr("UI_PLANNER_TITLE") % [origin.location_name, destination.location_name]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)

	var route_label := Label.new()
	var state_note := ""
	if _route_state != RouteConditions.State.OPEN:
		state_note = " · %s" % RouteConditions.get_state_label(_route_state)
	route_label.text = tr("UI_PLANNER_ROUTE") % [
		travel_days,
		state_note,
		int(_route_danger * 100.0),
		_plan.max_wagons,
		_plan.player_wagon_count,
	]
	_content.add_child(route_label)

	_gold_label = Label.new()
	_content.add_child(_gold_label)

	_wagon_counter_label = Label.new()
	_content.add_child(_wagon_counter_label)

	_content.add_child(HSeparator.new())

	var merchants_title := Label.new()
	merchants_title.text = tr("UI_PLANNER_MERCHANTS")
	_content.add_child(merchants_title)

	var accepted_offers := _session.get_accepted_offers_for_destination(destination.location_id)
	if accepted_offers.is_empty():
		var hint_label := Label.new()
		hint_label.text = tr("UI_NO_CONTRACTS_FOR_DESTINATION")
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_content.add_child(hint_label)
	for offer in accepted_offers:
		_content.add_child(_build_offer_row(offer))

	_content.add_child(HSeparator.new())

	var summary_title := Label.new()
	summary_title.text = tr("UI_PLANNER_SUMMARY")
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

	# Çıkış morali görünmezse mekanik sessiz bir cezaya dönüşür: oyuncu
	# neden düşük moralle yola çıktığını göremez (bkz. GameSession.
	# get_departure_morale_breakdown).
	_content.add_child(HSeparator.new())
	_morale_label = Label.new()
	_content.add_child(_morale_label)
	_morale_reasons = VBoxContainer.new()
	_content.add_child(_morale_reasons)

	_buy_provisions_button = Button.new()
	_buy_provisions_button.pressed.connect(_on_buy_provisions_pressed)
	_content.add_child(_buy_provisions_button)

	_confirm_button = Button.new()
	_confirm_button.text = tr("UI_CONFIRM_CARAVAN")
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_content.add_child(_confirm_button)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(_result_label)

	_content.add_child(HSeparator.new())

	# Çıkış tuşları kaydırma kutusunun dışında: plan uzadıkça (kontratlar,
	# erzak, moral dökümü) aşağı kayıp ekrandan taşmasınlar - pazar
	# ekranında bir kez yaşanan tuzak (bkz. World Navigation Rules).
	var exit_row := $MarginContainer/VBoxContainer

	var map_button := Button.new()
	map_button.text = tr("UI_BACK_TO_MAP")
	map_button.pressed.connect(_on_map_pressed)
	exit_row.add_child(map_button)

	var back_button := Button.new()
	back_button.text = Nav.return_label()
	back_button.pressed.connect(_on_back_pressed)
	exit_row.add_child(back_button)

## Kervanın yola hangi ruh haliyle çıkacağı ve nedeni.
func _refresh_departure_morale() -> void:
	var departure := _session.get_departure_morale()
	_morale_label.text = tr("UI_PLANNER_DEPARTURE_MORALE") % [
		departure, CaravanState.MAX_MORALE
	]

	for child in _morale_reasons.get_children():
		_morale_reasons.remove_child(child)
		child.queue_free()

	var breakdown := _session.get_departure_morale_breakdown()
	if breakdown.is_empty():
		var good_day := Label.new()
		good_day.text = tr("UI_MORALE_GOOD_DAY")
		_morale_reasons.add_child(good_day)
		return

	for entry in breakdown:
		var line := Label.new()
		line.text = "  %s %+d" % [tr(String(entry["key"])), int(entry["amount"])]
		line.modulate = SATISFIED_COLOR if int(entry["amount"]) > 0 else SHORTFALL_COLOR
		_morale_reasons.add_child(line)

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
	wagon_label.text = tr("UI_PLANNER_WAGONS") % offer.wagon_count
	wagon_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(wagon_label)

	var profit_label := Label.new()
	profit_label.text = tr("UI_PLANNER_PROFIT") % offer.potential_profit
	profit_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(profit_label)

	_offer_rows.append({"offer": offer, "checkbox": checkbox})
	return row

func _on_offer_toggled(_toggled_on: bool, offer: MerchantOffer, checkbox: CheckBox) -> void:
	if not _plan.toggle_merchant(offer):
		# Vagon limiti dolu: seçim geri alınır.
		checkbox.set_pressed_no_signal(false)
	_refresh()

func _on_wallet_changed(_new_balance: int) -> void:
	_refresh()

func _on_inventory_changed(_item: Item, _quantity: int) -> void:
	_refresh()

func _on_buy_provisions_pressed() -> void:
	var shortfall := _plan.get_provisions_shortfall(_session.get_provisions())
	if shortfall <= 0:
		return

	var cost := shortfall * GameSession.PROVISIONS_UNIT_PRICE
	if not _session.wallet.can_afford(cost):
		return

	_session.wallet.spend(cost)
	_session.change_provisions(shortfall)

func _refresh() -> void:
	_refresh_departure_morale()
	_gold_label.text = tr("UI_PURSE") % _session.wallet.balance
	_wagon_counter_label.text = tr("UI_PLANNER_WAGON_SLOTS") % [
		_plan.get_used_wagon_count(),
		_plan.get_available_wagon_slots(),
	]

	for row in _offer_rows:
		var offer: MerchantOffer = row.offer
		var checkbox: CheckBox = row.checkbox
		checkbox.disabled = not _plan.is_selected(offer) and not _plan.can_add_offer(offer)

	var current_provisions := _session.get_provisions()
	var required_provisions := _plan.get_required_provisions()
	var shortfall := _plan.get_provisions_shortfall(current_provisions)

	_party_label.text = tr("UI_PLANNER_PARTY") % [
		_plan.get_party_size(),
		_plan.get_total_wagon_count(),
	]
	_documents_label.text = tr("UI_PLANNER_DOCUMENTS") % _plan.get_required_documents()
	_required_provisions_label.text = tr("UI_PLANNER_PROVISIONS_NEEDED") % required_provisions
	_current_provisions_label.text = tr("UI_PLANNER_PROVISIONS_HELD") % current_provisions

	var shortfall_cost := shortfall * GameSession.PROVISIONS_UNIT_PRICE
	if shortfall > 0:
		_shortfall_label.text = tr("UI_PLANNER_PROVISIONS_SHORT") % [shortfall, shortfall_cost]
		_shortfall_label.modulate = SHORTFALL_COLOR
		_buy_provisions_button.visible = true
		_buy_provisions_button.text = tr("UI_PLANNER_BUY_PROVISIONS") % shortfall_cost
		_buy_provisions_button.disabled = not _session.wallet.can_afford(shortfall_cost)
		_confirm_button.disabled = true
		_confirm_button.text = tr("UI_PLANNER_BLOCKED")
	else:
		_shortfall_label.text = tr("UI_PLANNER_READY")
		_shortfall_label.modulate = SATISFIED_COLOR
		_buy_provisions_button.visible = false
		_confirm_button.disabled = false
		_confirm_button.text = tr("UI_CONFIRM_CARAVAN")

	_profit_label.text = tr("UI_TOTAL_POTENTIAL") % _plan.get_total_profit()

func _on_confirm_pressed() -> void:
	if _plan.get_provisions_shortfall(_session.get_provisions()) > 0:
		return

	_session.depart_with_contracts(_plan.get_selected_offers())
	_session.start_journey(
		_destination.location_id,
		_plan.travel_days,
		_route_danger,
		_plan
	)
	get_tree().change_scene_to_file(Nav.JOURNEY)

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file(Nav.TRAVEL)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)
