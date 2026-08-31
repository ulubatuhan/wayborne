extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

const STARTING_JOURNEY_DAYS: int = 8
const STARTING_DANGER: float = 0.4
const STARTING_WAGONS: int = 4
const STARTING_MERCHANTS: Array = ["Test Tüccar 1", "Test Tüccar 2", "Test Tüccar 3"]

const LOCKED_COLOR: Color = Color(0.65, 0.6, 0.55)
const IMMEDIATE_COLOR: Color = Color(0.95, 0.8, 0.45)
const OUTCOME_COLOR: Color = Color(0.75, 0.85, 1.0)

var _session: GameSession
var _engine: EventEngine
var _current_event: GameEvent
var _current_day: int = 0

var _seed_spin: SpinBox
var _state_label: Label
var _card_panel: VBoxContainer
var _log_list: VBoxContainer
var _advance_button: Button
var _draw_button: Button

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer

func _ready() -> void:
	_build_ui()
	_start_new_journey()

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

	var reset_button := Button.new()
	reset_button.text = tr("EVT_TEST_RESET")
	reset_button.pressed.connect(_start_new_journey)
	controls_row.add_child(reset_button)

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

func _start_new_journey() -> void:
	_session = GameSession.new()
	_session.journey_days_remaining = STARTING_JOURNEY_DAYS
	_session.danger_level = STARTING_DANGER
	_session.caravan.wagon_count = STARTING_WAGONS
	_session.caravan.documents = STARTING_WAGONS
	var merchants: Array[String] = []
	for merchant_name in STARTING_MERCHANTS:
		merchants.append(merchant_name)
	_session.caravan.merchant_names = merchants

	_engine = EventEngine.new(EventCatalog.get_road_events(), int(_seed_spin.value))
	_current_day = 0
	_current_event = null

	_clear_children(_log_list)
	_clear_children(_card_panel)
	_set_journey_controls_enabled(true)
	_refresh_state()
	_add_log("Sefer başladı: %d gün yol, tehlike %d%%." % [
		_session.journey_days_remaining,
		int(_session.danger_level * 100.0),
	])

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

	if _session.journey_days_remaining <= 0:
		_finish_journey()

func _apply_side_channels(result: EventEffectApplier.Result) -> void:
	for event_id in result.unlocked_event_ids:
		_engine.unlock_event(event_id)
		_add_log("      (yeni olay açıldı)")
	for max_price in result.haggling_requests:
		# Pazarlık köprüsü henüz bağlı değil; şimdilik günlüğe düşülüyor.
		_add_log("      (pazarlık isteği: tavan %d GG)" % max_price)

func _finish_journey() -> void:
	_set_journey_controls_enabled(false)
	_add_log("Sefer tamamlandı. %d gün sürdü." % _current_day)
	EventBus.journey_finished.emit(_current_day)

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
