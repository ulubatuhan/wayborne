extends Control

## Pazarlık test sahnesi: parametreleri elle ayarlayıp HagglingPanel'i
## besler. Pazarlık mantığının kendisi panelde, burada yalnızca ayar
## kutuları var.

var _base_price_spin: SpinBox
var _greed_spin: SpinBox
var _reputation_spin: SpinBox
var _drain_rate_spin: SpinBox
var _speech_spin: SpinBox
var _charisma_spin: SpinBox
var _final_offer_check: CheckBox
var _panel: HagglingPanel

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

	_panel = HagglingPanel.new()
	_content.add_child(_panel)

	_content.add_child(HSeparator.new())

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
	# Tavan 100: en kötü teklifte tek hamlede sabrı çökertebilmek için.
	_drain_rate_spin = _add_spin_row(merchant_box, "Sabır Tükenme Katsayısı", 0.1, 100.0, 0.5, 25.0)

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
	_panel.start_haggling(
		_base_price_spin.value,
		_greed_spin.value,
		_reputation_spin.value,
		int(_speech_spin.value),
		int(_charisma_spin.value),
		_drain_rate_spin.value,
		_final_offer_check.button_pressed
	)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)
