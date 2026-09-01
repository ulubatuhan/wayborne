extends Control

## Çarpışma test sahnesi (F1 dev panelinden açılır). Kalıcı oturuma
## dokunmaz: kendi test partisini kurar, böylece savaş dengesi gerçek
## kaydı bozmadan denenebilir.

const TEST_PARTY_CULTURES: Array[String] = [
	CultureCatalog.HIGHLAND,
	CultureCatalog.NOMAD,
	CultureCatalog.VALLEY,
	CultureCatalog.FISHER,
]

var _panel: CombatPanel
var _danger_slider: HSlider
var _danger_label: Label
var _result_label: Label

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_back_button.text = Nav.return_label()
	_back_button.pressed.connect(_on_back_pressed)

	var danger_row := HBoxContainer.new()
	danger_row.add_theme_constant_override("separation", 8)

	var danger_title := Label.new()
	danger_title.text = "Tehlike"
	danger_title.custom_minimum_size = Vector2(80, 0)
	danger_row.add_child(danger_title)

	_danger_slider = HSlider.new()
	_danger_slider.custom_minimum_size = Vector2(240, 0)
	_danger_slider.min_value = 0
	_danger_slider.max_value = 100
	_danger_slider.step = 5
	_danger_slider.value = 40
	_danger_slider.value_changed.connect(_on_danger_changed)
	danger_row.add_child(_danger_slider)

	_danger_label = Label.new()
	danger_row.add_child(_danger_label)
	_content.add_child(danger_row)

	var start_button := Button.new()
	start_button.text = "Yeni Çarpışma"
	start_button.pressed.connect(_start_combat)
	_content.add_child(start_button)

	_result_label = Label.new()
	_content.add_child(_result_label)

	_panel = CombatPanel.new()
	_panel.combat_finished.connect(_on_combat_finished)
	_content.add_child(_panel)

	_on_danger_changed(_danger_slider.value)
	_start_combat()

func _start_combat() -> void:
	_result_label.text = ""
	var party: Array[CharacterData] = []
	for index in TEST_PARTY_CULTURES.size():
		var culture := CultureCatalog.get_culture_or_default(TEST_PARTY_CULTURES[index])
		party.append(CharacterData.create(
			culture.name_pool[index % culture.name_pool.size()],
			culture.culture_id,
			CharacterStats.new()
		))
	_panel.start_combat(party, _danger_slider.value / 100.0)

func _on_danger_changed(value: float) -> void:
	_danger_label.text = "%d%%" % int(value)

func _on_combat_finished(victory: bool) -> void:
	_result_label.text = "Sonuç: zafer" if victory else "Sonuç: yenilgi"

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)
