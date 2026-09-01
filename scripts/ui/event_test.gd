extends Control

## Sefer ekranı. Kervan planlayıcıdan gerçek bir seferle gelindiğinde
## kalıcı oturumu yürütür; test menüsünden doğrudan açıldığında kendi
## geçici seferini kurar, böylece gerçek kaydı kirletmez.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const TRAVEL_SCENE: String = "res://scenes/tests/travel_test.tscn"

const SYNTHETIC_JOURNEY_DAYS: int = 8
const SYNTHETIC_DANGER: float = 0.4
const SYNTHETIC_WAGONS: int = 4
const SYNTHETIC_MERCHANTS: Array = ["Test Tüccar 1", "Test Tüccar 2", "Test Tüccar 3"]

const LOCKED_COLOR: Color = Color(0.65, 0.6, 0.55)
const IMMEDIATE_COLOR: Color = Color(0.95, 0.8, 0.45)
const OUTCOME_COLOR: Color = Color(0.75, 0.85, 1.0)

## Pazarlık başarısız olursa tam bedel ödenir; başarı indirim demektir.
const HAGGLE_FAIL_MORALE: int = -8
const HAGGLE_DRAIN_RATE: float = 25.0

var _session: GameSession
var _engine: EventEngine
var _current_event: GameEvent
var _current_day: int = 0
var _is_live_journey: bool = false
var _pending_haggle_max: int = 0

var _seed_spin: SpinBox
var _state_label: Label
var _card_panel: VBoxContainer
var _haggle_holder: VBoxContainer
var _log_list: VBoxContainer
var _advance_button: Button
var _draw_button: Button
var _reset_button: Button
var _arrive_button: Button

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer

func _ready() -> void:
	_build_ui()
	_init_journey()

func _build_ui() -> void:
	var title := Label.new()
	title.text = tr("EVT_TEST_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)

	var controls_row := HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", 8)

	var seed_label := Label.new()
	seed_label.text = "Seed:"
	controls_row.add_child(seed_label)

	_seed_spin = SpinBox.new()
	_seed_spin.min_value = 0
	_seed_spin.max_value = 999999
	_seed_spin.step = 1
	_seed_spin.value = 1234
	controls_row.add_child(_seed_spin)

	_reset_button = Button.new()
	_reset_button.text = tr("EVT_TEST_RESET")
	_reset_button.pressed.connect(_on_reset_pressed)
	controls_row.add_child(_reset_button)

	_advance_button = Button.new()
	_advance_button.text = tr("EVT_TEST_ADVANCE")
	_advance_button.pressed.connect(_on_advance_day)
	controls_row.add_child(_advance_button)

	_draw_button = Button.new()
	_draw_button.text = tr("EVT_TEST_DRAW")
	_draw_button.pressed.connect(_on_force_draw)
	controls_row.add_child(_draw_button)

	_content.add_child(controls_row)
	_content.add_child(HSeparator.new())

	var state_title := Label.new()
	state_title.text = tr("EVT_TEST_STATE")
	_content.add_child(state_title)

	_state_label = Label.new()
	_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(_state_label)

	_content.add_child(HSeparator.new())

	_card_panel = VBoxContainer.new()
	_card_panel.add_theme_constant_override("separation", 6)
	_content.add_child(_card_panel)

	_haggle_holder = VBoxContainer.new()
	_content.add_child(_haggle_holder)

	_arrive_button = Button.new()
	_arrive_button.text = "Şehre Var"
	_arrive_button.visible = false
	_arrive_button.pressed.connect(_on_arrive_pressed)
	_content.add_child(_arrive_button)

	_content.add_child(HSeparator.new())

	var log_title := Label.new()
	log_title.text = tr("EVT_TEST_LOG")
	_content.add_child(log_title)

	_log_list = VBoxContainer.new()
	_content.add_child(_log_list)

	var back_button := Button.new()
	back_button.text = tr("UI_BACK_TO_MENU")
	back_button.pressed.connect(_on_back_pressed)
	_content.add_child(back_button)

func _init_journey() -> void:
	var live_session: GameSession = GameState.get_session()

	if live_session.is_journey_active():
		_is_live_journey = true
		_session = live_session
		_current_day = maxi(0, _session.journey_total_days - _session.journey_days_remaining)
		_reset_button.visible = false
		_seed_spin.editable = false
	else:
		_is_live_journey = false
		_start_synthetic_journey()

	_engine = EventEngine.new(EventCatalog.get_road_events(), int(_seed_spin.value))
	_current_event = null
	_clear_children(_card_panel)
	_clear_children(_haggle_holder)
	_set_journey_controls_enabled(true)
	_refresh_state()

	if _is_live_journey:
		var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
		var destination_name := "?" if destination == null else destination.location_name
		_add_log("%s yolundasın: %d gün, tehlike %d%%." % [
			destination_name,
			_session.journey_days_remaining,
			int(_session.danger_level * 100.0),
		])
	else:
		_add_log("Deneme seferi: %d gün yol, tehlike %d%%." % [
			_session.journey_days_remaining,
			int(_session.danger_level * 100.0),
		])

func _start_synthetic_journey() -> void:
	_session = GameSession.new()
	_session.journey_destination_id = WorldMapData.START_LOCATION_ID
	_session.journey_total_days = SYNTHETIC_JOURNEY_DAYS
	_session.journey_days_remaining = SYNTHETIC_JOURNEY_DAYS
	_session.danger_level = SYNTHETIC_DANGER
	_session.caravan.wagon_count = SYNTHETIC_WAGONS
	_session.caravan.documents = SYNTHETIC_WAGONS

	var merchants: Array[String] = []
	for merchant_name in SYNTHETIC_MERCHANTS:
		merchants.append(merchant_name)
	_session.caravan.merchant_names = merchants

	_current_day = 0

func _on_reset_pressed() -> void:
	if _is_live_journey:
		return
	_clear_children(_log_list)
	_init_journey()

func _on_advance_day() -> void:
	if _current_event != null:
		return

	_current_day += 1
	_session.journey_days_remaining = maxi(0, _session.journey_days_remaining - 1)

	# Yol her gün erzak yer: parti büyüdükçe saat daha hızlı işler.
	var daily_consumption := 1 + _session.caravan.merchant_names.size()
	_session.change_provisions(-daily_consumption)
	if _session.get_provisions() <= 0:
		_session.caravan.change_morale(-10)
		_add_log("Gün %d: Erzak tükendi, moral düşüyor." % _current_day)

	var event := _engine.roll_for_day(_current_day, _session.build_event_context())
	if event == null:
		_add_log("Gün %d: %s" % [_current_day, tr("EVT_TEST_QUIET_DAY")])
	else:
		_present_event(event)

	_refresh_state()
	if _session.journey_days_remaining <= 0 and _current_event == null:
		_finish_journey()

func _on_force_draw() -> void:
	if _current_event != null:
		return

	var event := _engine.draw_event(_current_day, _session.build_event_context())
	if event == null:
		_add_log(tr("EVT_TEST_NO_EVENT"))
		return
	_present_event(event)

func _present_event(event: GameEvent) -> void:
	_current_event = event
	_engine.mark_fired(event, _current_day)
	EventBus.road_event_fired.emit(event)

	_add_log("── %s" % tr(event.title_key))

	if not event.immediate_effects.is_empty():
		var immediate := EventEffectApplier.apply(event.immediate_effects, _session)
		_apply_side_channels(immediate)
		for line in immediate.lines:
			_add_log("   %s" % line, IMMEDIATE_COLOR)

	_render_card(event)
	_refresh_state()

func _render_card(event: GameEvent) -> void:
	_clear_children(_card_panel)

	var title := Label.new()
	title.text = tr(event.title_key)
	_card_panel.add_child(title)

	var body := Label.new()
	body.text = tr(event.text_key)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	_card_panel.add_child(body)

	var context := _session.build_event_context()
	for choice in event.choices:
		_card_panel.add_child(_build_choice_button(choice, context))

func _build_choice_button(choice: EventChoice, context: Dictionary) -> Button:
	var button := Button.new()
	var available := choice.is_available(context)

	if available:
		button.text = tr(choice.text_key)
		button.pressed.connect(_on_choice_pressed.bind(choice))
	else:
		# Kilitli seçenek gizlenmez: oyuncu neyi kaçırdığını görsün.
		button.text = "%s — %s" % [tr(choice.text_key), tr(choice.unavailable_text_key)]
		button.disabled = true
		button.modulate = LOCKED_COLOR

	return button

func _on_choice_pressed(choice: EventChoice) -> void:
	var resolved_event := _current_event
	_current_event = null
	_clear_children(_card_panel)

	_add_log("   → %s" % tr(choice.text_key))

	if not choice.effects.is_empty():
		var result := EventEffectApplier.apply(choice.effects, _session)
		_apply_side_channels(result)
		for line in result.lines:
			_add_log("      %s" % line)

	var outcome := _engine.resolve_outcome(choice, _session.build_event_context())
	if outcome != null:
		_add_log("   %s" % tr(outcome.text_key), OUTCOME_COLOR)
		var outcome_result := EventEffectApplier.apply(outcome.effects, _session)
		_apply_side_channels(outcome_result)
		for line in outcome_result.lines:
			_add_log("      %s" % line)

	EventBus.road_event_resolved.emit(resolved_event, choice)
	_refresh_state()
	_check_journey_end()

func _apply_side_channels(result: EventEffectApplier.Result) -> void:
	for event_id in result.unlocked_event_ids:
		_engine.unlock_event(event_id)
		_add_log("      (yeni olay açıldı)")

	if not result.haggling_requests.is_empty():
		_open_haggling(int(result.haggling_requests[0]))

## Bir olay pazarlık istediğinde gerçek pazarlık paneli açılır:
## anlaşırsan anlaştığın fiyatı, anlaşamazsan tam bedeli ödersin.
func _open_haggling(max_price: int) -> void:
	_pending_haggle_max = max_price
	_set_journey_controls_enabled(false)
	_clear_children(_haggle_holder)

	var intro := Label.new()
	intro.text = "Pazarlık: karşı taraf %d GG istiyor." % max_price
	_haggle_holder.add_child(intro)

	var panel := HagglingPanel.new()
	_haggle_holder.add_child(panel)
	panel.deal_made.connect(_on_haggle_deal)
	panel.haggling_failed.connect(_on_haggle_failed)
	panel.start_haggling(float(max_price), 0.5, 0.3, 0, 0, HAGGLE_DRAIN_RATE, false)

func _on_haggle_deal(price: int) -> void:
	var paid := mini(price, _session.wallet.balance)
	if paid > 0:
		_session.wallet.spend(paid)
	_add_log("      Pazarlık tuttu: %d GG ödendi." % paid, OUTCOME_COLOR)
	_close_haggling()

func _on_haggle_failed() -> void:
	var paid := mini(_pending_haggle_max, _session.wallet.balance)
	if paid > 0:
		_session.wallet.spend(paid)
	_session.caravan.change_morale(HAGGLE_FAIL_MORALE)
	_add_log("      Pazarlık koptu: tam bedel %d GG ödendi." % paid)
	_close_haggling()

func _close_haggling() -> void:
	_clear_children(_haggle_holder)
	_pending_haggle_max = 0
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

func _check_journey_end() -> void:
	if _session.journey_days_remaining <= 0 and _current_event == null:
		_finish_journey()

func _finish_journey() -> void:
	_set_journey_controls_enabled(false)
	_add_log("Sefer tamamlandı. %d gün sürdü." % _current_day)
	EventBus.journey_finished.emit(_current_day)

	if _is_live_journey:
		_arrive_button.visible = true

func _on_arrive_pressed() -> void:
	_session.finish_journey()
	EventBus.caravan_changed.emit()
	get_tree().change_scene_to_file(TRAVEL_SCENE)

func _set_journey_controls_enabled(enabled: bool) -> void:
	_advance_button.disabled = not enabled
	_draw_button.disabled = not enabled

func _refresh_state() -> void:
	var caravan := _session.caravan
	_state_label.text = "Gün %d · Kalan yol: %d gün · Tehlike: %d%%\nAltın: %d GG · Erzak: %d · İtibar: %d\nVagon: %d (%d hasarlı) · Tüccar: %d · Evrak: %d · Moral: %d" % [
		_current_day,
		_session.journey_days_remaining,
		int(_session.danger_level * 100.0),
		_session.wallet.balance,
		_session.get_provisions(),
		_session.reputation,
		caravan.wagon_count,
		caravan.damaged_wagons,
		caravan.merchant_names.size(),
		caravan.documents,
		caravan.morale,
	]

func _add_log(text: String, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if color != Color.WHITE:
		label.modulate = color
	_log_list.add_child(label)

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
