extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const PATIENCE_HIGH_COLOR: Color = Color(0.3, 0.75, 0.3)
const PATIENCE_LOW_COLOR: Color = Color(0.75, 0.2, 0.2)

var _session: HagglingSession

var _base_price_spin: SpinBox
var _greed_spin: SpinBox
var _reputation_spin: SpinBox
var _drain_rate_spin: SpinBox
var _speech_spin: SpinBox
var _charisma_spin: SpinBox
var _final_offer_check: CheckBox

var _offer_slider: HSlider
var _offer_value_label: Label
var _patience_bar: ProgressBar
var _range_value_label: Label
var _result_label: Label
var _log_list: VBoxContainer
var _submit_button: Button
var _final_offer_panel: VBoxContainer
var _final_offer_label: Label

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var title := Label.new()
	title.text = "Pazarlık Testi (Kingdom Come Tarzı)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)

	_content.add_child(_build_config_section())

	var start_button := Button.new()
	start_button.text = "Pazarlığı Başlat"
	start_button.pressed.connect(_on_start_pressed)
	_content.add_child(start_button)

	_content.add_child(HSeparator.new())

	var range_row := HBoxContainer.new()
	var range_title := Label.new()
	range_title.text = "Teklif Aralığı:"
	range_title.custom_minimum_size = Vector2(120, 0)
	_range_value_label = Label.new()
	_range_value_label.text = "-"
	range_row.add_child(range_title)
	range_row.add_child(_range_value_label)
	_content.add_child(range_row)

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
	_content.add_child(patience_row)

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
	_content.add_child(offer_row)

	_submit_button = Button.new()
	_submit_button.text = "Teklif Ver"
	_submit_button.disabled = true
	_submit_button.pressed.connect(_on_submit_offer_pressed)
	_content.add_child(_submit_button)

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
	_content.add_child(_final_offer_panel)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_result_label)

	var log_title := Label.new()
	log_title.text = "Pazarlık Günlüğü"
	_content.add_child(log_title)

	_log_list = VBoxContainer.new()
	_content.add_child(_log_list)

	var back_button := Button.new()
	back_button.text = "Ana Menüye Dön"
	back_button.pressed.connect(_on_back_pressed)
	_content.add_child(back_button)

func _build_config_section() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)

	var merchant_box := VBoxContainer.new()
	var merchant_title := Label.new()
	merchant_title.text = "Tüccar"
	merchant_box.add_child(merchant_title)

	_base_price_spin = _add_spin_row(merchant_box, "Taban Fiyat", 1.0, 1000.0, 1.0, 100.0)
	_greed_spin = _add_spin_row(merchant_box, "Açgözlülük (0-1)", 0.0, 1.0, 0.05, 0.5)
	_reputation_spin = _add_spin_row(merchant_box, "İtibar (0-1)", 0.0, 1.0, 0.05, 0.3)
	_drain_rate_spin = _add_spin_row(merchant_box, "Sabır Tükenme Katsayısı", 0.1, 10.0, 0.1, 1.0)

	var player_box := VBoxContainer.new()
	var player_title := Label.new()
	player_title.text = "Oyuncu"
	player_box.add_child(player_title)

	_speech_spin = _add_spin_row(player_box, "Konuşma", 0.0, 30.0, 1.0, 0.0)
	_charisma_spin = _add_spin_row(player_box, "Karizma", 0.0, 30.0, 1.0, 0.0)

	var final_offer_row := HBoxContainer.new()
	var final_offer_title := Label.new()
	final_offer_title.text = "Son Teklif Yeteneği"
	_final_offer_check = CheckBox.new()
	final_offer_row.add_child(final_offer_title)
	final_offer_row.add_child(_final_offer_check)
	player_box.add_child(final_offer_row)

	row.add_child(merchant_box)
	row.add_child(player_box)
	return row

func _add_spin_row(parent: VBoxContainer, label_text: String, min_value: float, max_value: float, step: float, default_value: float) -> SpinBox:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.value = default_value
	row.add_child(label)
	row.add_child(spin)
	parent.add_child(row)
	return spin

func _on_start_pressed() -> void:
	_session = HagglingSession.new(
		_base_price_spin.value,
		_greed_spin.value,
		_reputation_spin.value,
		int(_speech_spin.value),
		int(_charisma_spin.value),
		_drain_rate_spin.value,
		_final_offer_check.button_pressed
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
			_result_label.text = "Anlaşma sağlandı! Fiyat: %d GG" % _session.final_price
			_submit_button.disabled = true
		HagglingSession.State.ANGER_QUIT:
			_result_label.text = "Tüccar öfkeyle masayı terk etti!"
			_submit_button.disabled = true
			_final_offer_panel.visible = false

func _add_log_entry(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_log_list.add_child(label)

func _clear_log() -> void:
	for child in _log_list.get_children():
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
