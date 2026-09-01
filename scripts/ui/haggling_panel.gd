class_name HagglingPanel
extends VBoxContainer

## Pazarlık arayüzünün yeniden kullanılabilir hali. Hem Pazarlık test
## sahnesi hem de yol olaylarındaki TRIGGER_HAGGLING etkisi bunu kullanır,
## böylece pazarlık mantığı tek bir yerde durur.

signal deal_made(price: int)
signal haggling_failed()

const PATIENCE_HIGH_COLOR: Color = Color(0.3, 0.75, 0.3)
const PATIENCE_LOW_COLOR: Color = Color(0.75, 0.2, 0.2)

var _session: HagglingSession
var _built: bool = false

var _range_value_label: Label
var _patience_bar: ProgressBar
var _offer_slider: HSlider
var _offer_value_label: Label
var _submit_button: Button
var _final_offer_panel: VBoxContainer
var _final_offer_label: Label
var _result_label: Label
var _log_list: VBoxContainer

func _ready() -> void:
	_ensure_built()

## Yeni bir pazarlık oturumu açar. Panel sahneye girmeden de çağrılabilir.
func start_haggling(
	base_price: float,
	merchant_greed: float,
	reputation: float,
	player_speech: int,
	player_charisma: int,
	patience_drain_rate: float,
	has_final_offer_perk: bool
) -> void:
	_ensure_built()

	_session = HagglingSession.new(
		base_price,
		merchant_greed,
		reputation,
		player_speech,
		player_charisma,
		patience_drain_rate,
		has_final_offer_perk
	)
	_session.patience_changed.connect(_on_patience_changed)
	_session.counter_offer_made.connect(_on_counter_offer_made)
	_session.final_chance_offered.connect(_on_final_chance_offered)
	_session.state_changed.connect(_on_state_changed)

	var slider_range := _session.get_slider_range()
	_offer_slider.min_value = slider_range.x
	_offer_slider.max_value = slider_range.y
	_offer_slider.value = (slider_range.x + slider_range.y) / 2.0
	_range_value_label.text = "%d GG - %d GG" % [slider_range.x, slider_range.y]

	_patience_bar.value = 100
	_patience_bar.modulate = PATIENCE_HIGH_COLOR
	_result_label.text = ""
	_final_offer_panel.visible = false
	_submit_button.disabled = false

	_clear_log()
	_add_log_entry("Pazarlık başladı. Tüccarın açılış fiyatı: %d GG" % _session.p_start)

func _ensure_built() -> void:
	if _built:
		return
	_built = true

	add_theme_constant_override("separation", 6)

	var range_row := HBoxContainer.new()
	var range_title := Label.new()
	range_title.text = "Teklif Aralığı:"
	range_title.custom_minimum_size = Vector2(120, 0)
	_range_value_label = Label.new()
	_range_value_label.text = "-"
	range_row.add_child(range_title)
	range_row.add_child(_range_value_label)
	add_child(range_row)

	var patience_row := HBoxContainer.new()
	var patience_title := Label.new()
	patience_title.text = "Tüccar Sabrı:"
	patience_title.custom_minimum_size = Vector2(120, 0)
	_patience_bar = ProgressBar.new()
	_patience_bar.custom_minimum_size = Vector2(300, 24)
	_patience_bar.min_value = 0
	_patience_bar.max_value = 100
	_patience_bar.value = 100
	patience_row.add_child(patience_title)
	patience_row.add_child(_patience_bar)
	add_child(patience_row)

	var offer_row := HBoxContainer.new()
	var offer_title := Label.new()
	offer_title.text = "Teklifin:"
	offer_title.custom_minimum_size = Vector2(120, 0)
	_offer_slider = HSlider.new()
	_offer_slider.custom_minimum_size = Vector2(300, 0)
	_offer_slider.step = 0.5
	_offer_slider.value_changed.connect(_on_offer_slider_changed)
	_offer_value_label = Label.new()
	_offer_value_label.custom_minimum_size = Vector2(80, 0)
	offer_row.add_child(offer_title)
	offer_row.add_child(_offer_slider)
	offer_row.add_child(_offer_value_label)
	add_child(offer_row)

	_submit_button = Button.new()
	_submit_button.text = "Teklif Ver"
	_submit_button.disabled = true
	_submit_button.pressed.connect(_on_submit_offer_pressed)
	add_child(_submit_button)

	_final_offer_panel = VBoxContainer.new()
	_final_offer_panel.visible = false
	_final_offer_label = Label.new()
	_final_offer_panel.add_child(_final_offer_label)
	var final_buttons_row := HBoxContainer.new()
	var accept_button := Button.new()
	accept_button.text = "Kabul Et"
	accept_button.pressed.connect(_on_final_offer_response.bind(true))
	var reject_button := Button.new()
	reject_button.text = "Reddet"
	reject_button.pressed.connect(_on_final_offer_response.bind(false))
	final_buttons_row.add_child(accept_button)
	final_buttons_row.add_child(reject_button)
	_final_offer_panel.add_child(final_buttons_row)
	add_child(_final_offer_panel)

	_result_label = Label.new()
	add_child(_result_label)

	var log_title := Label.new()
	log_title.text = "Pazarlık Günlüğü"
	add_child(log_title)

	_log_list = VBoxContainer.new()
	add_child(_log_list)

func _on_offer_slider_changed(value: float) -> void:
	_offer_value_label.text = "%d GG" % value

func _on_submit_offer_pressed() -> void:
	if _session == null:
		return
	var offer := _offer_slider.value
	_add_log_entry("Sen: %d GG teklif ettin." % offer)
	_session.submit_offer(offer)

func _on_patience_changed(new_patience: float) -> void:
	_patience_bar.value = new_patience
	_patience_bar.modulate = PATIENCE_HIGH_COLOR.lerp(PATIENCE_LOW_COLOR, 1.0 - (new_patience / 100.0))

func _on_counter_offer_made(npc_offer: float) -> void:
	_add_log_entry("Tüccar: '%d GG öneriyorum.'" % npc_offer)

func _on_final_chance_offered(locked_offer: float) -> void:
	_add_log_entry("Tüccar öfkeleniyor... 'Bu son kararım, işine gelirse!'")
	_final_offer_label.text = "Son Teklif: %d GG" % locked_offer
	_final_offer_panel.visible = true
	_submit_button.disabled = true

func _on_final_offer_response(accept: bool) -> void:
	_session.respond_to_final_offer(accept)
	_final_offer_panel.visible = false

func _on_state_changed(new_state: HagglingSession.State) -> void:
	match new_state:
		HagglingSession.State.SUCCESS_DEAL:
			var price := int(_session.final_price)
			_result_label.text = "Anlaşma sağlandı! Fiyat: %d GG" % price
			_submit_button.disabled = true
			deal_made.emit(price)
		HagglingSession.State.ANGER_QUIT:
			_result_label.text = "Tüccar öfkeyle masayı terk etti!"
			_submit_button.disabled = true
			_final_offer_panel.visible = false
			haggling_failed.emit()

func _add_log_entry(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_log_list.add_child(label)

func _clear_log() -> void:
	for child in _log_list.get_children():
		_log_list.remove_child(child)
		child.queue_free()
