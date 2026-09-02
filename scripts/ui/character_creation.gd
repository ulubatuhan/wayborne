extends Control

## Yeni oyunun giriş ekranı: kültür, isim, boy, ten rengi, stat dağıtımı
## ve tayfa büyüklüğü. Buradan çıkınca kalıcı oturum kurulmuş, oyuncunun
## karakteri partiye yerleşmiş olur.
##
## Tayfa büyüklüğü (vagonları süren kişi sayısı) ile savaş partisi
## (adı olan en fazla 4 kişi) ayrı kavramlar: ilki kargo kapasitesini,
## ikincisi çarpışmayı belirler.

const STAT_POINTS: int = 6

## Vagonları süren tayfa: her vagonda en fazla iki kişi kalır.
const MIN_CREW_SIZE: int = 1
const MAX_CREW_SIZE: int = 12
const PEOPLE_PER_WAGON: int = 2
const DEFAULT_CREW_SIZE: int = 4

const DEFAULT_STARTING_GOLD: int = 250
const DEFAULT_STARTING_PROVISIONS: int = 20

const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)
const PERK_COLOR: Color = Color(0.75, 0.85, 1.0)

var _base_stats: CharacterStats = CharacterStats.new()
var _spent_points: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _culture_button: OptionButton
var _culture_description: Label
var _culture_bonus: Label
var _culture_perk: Label
var _class_button: OptionButton
var _class_description: Label
var _name_edit: LineEdit
var _height_slider: HSlider
var _height_label: Label
var _skin_button: OptionButton
var _skin_preview: ColorRect
var _points_label: Label
var _stat_rows: Array[Dictionary] = []
var _crew_spin: SpinBox
var _crew_wagon_label: Label
var _summary_label: Label
var _start_button: Button

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer

func _ready() -> void:
	_rng.randomize()
	_build_ui()
	_on_culture_selected(0)

func _build_ui() -> void:
	_build_culture_section()
	_content.add_child(HSeparator.new())
	_build_class_section()
	_content.add_child(HSeparator.new())
	_build_identity_section()
	_content.add_child(HSeparator.new())
	_build_stats_section()
	_content.add_child(HSeparator.new())
	_build_crew_section()
	_content.add_child(HSeparator.new())

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(_summary_label)

	_start_button = Button.new()
	_start_button.text = "Yola Çık"
	_start_button.pressed.connect(_on_start_pressed)
	_content.add_child(_start_button)

	var back_button := Button.new()
	back_button.text = Nav.label_for(Nav.MAIN_MENU)
	back_button.pressed.connect(_on_back_pressed)
	_content.add_child(back_button)

func _build_culture_section() -> void:
	_content.add_child(_make_section_title("Kültür"))

	_culture_button = OptionButton.new()
	for culture in CultureCatalog.get_cultures():
		_culture_button.add_item(culture.culture_name)
	_culture_button.item_selected.connect(_on_culture_selected)
	_content.add_child(_culture_button)

	_culture_description = _make_hint_label()
	_content.add_child(_culture_description)

	_culture_bonus = Label.new()
	_content.add_child(_culture_bonus)

	_culture_perk = Label.new()
	_culture_perk.autowrap_mode = TextServer.AUTOWRAP_WORD
	_culture_perk.modulate = PERK_COLOR
	_content.add_child(_culture_perk)

func _build_class_section() -> void:
	_content.add_child(_make_section_title("Sınıf"))

	_class_button = OptionButton.new()
	for character_class in ClassCatalog.get_classes():
		_class_button.add_item(character_class.display_name)
	_class_button.item_selected.connect(_on_class_selected)
	_content.add_child(_class_button)

	_class_description = _make_hint_label()
	_content.add_child(_class_description)

func _build_identity_section() -> void:
	_content.add_child(_make_section_title("Kimlik"))

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	var name_title := Label.new()
	name_title.text = "İsim"
	name_title.custom_minimum_size = Vector2(120, 0)
	name_row.add_child(name_title)

	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size = Vector2(240, 0)
	_name_edit.text_changed.connect(_on_name_changed)
	name_row.add_child(_name_edit)

	var random_button := Button.new()
	random_button.text = "Rastgele"
	random_button.pressed.connect(_roll_random_name)
	name_row.add_child(random_button)
	_content.add_child(name_row)

	var height_row := HBoxContainer.new()
	height_row.add_theme_constant_override("separation", 8)
	var height_title := Label.new()
	height_title.text = "Boy"
	height_title.custom_minimum_size = Vector2(120, 0)
	height_row.add_child(height_title)

	_height_slider = HSlider.new()
	_height_slider.custom_minimum_size = Vector2(240, 0)
	_height_slider.min_value = CharacterData.MIN_HEIGHT_CM
	_height_slider.max_value = CharacterData.MAX_HEIGHT_CM
	_height_slider.step = 1
	_height_slider.value = CharacterData.DEFAULT_HEIGHT_CM
	_height_slider.value_changed.connect(_on_height_changed)
	height_row.add_child(_height_slider)

	_height_label = Label.new()
	_height_label.custom_minimum_size = Vector2(220, 0)
	height_row.add_child(_height_label)
	_content.add_child(height_row)

	var skin_row := HBoxContainer.new()
	skin_row.add_theme_constant_override("separation", 8)
	var skin_title := Label.new()
	skin_title.text = "Ten Rengi"
	skin_title.custom_minimum_size = Vector2(120, 0)
	skin_row.add_child(skin_title)

	_skin_button = OptionButton.new()
	for index in CharacterData.SKIN_TONE_NAMES.size():
		_skin_button.add_item(CharacterData.get_skin_tone_name(index))
	_skin_button.select(1)
	_skin_button.item_selected.connect(_on_skin_selected)
	skin_row.add_child(_skin_button)

	_skin_preview = ColorRect.new()
	_skin_preview.custom_minimum_size = Vector2(48, 24)
	skin_row.add_child(_skin_preview)
	_content.add_child(skin_row)

func _build_stats_section() -> void:
	_content.add_child(_make_section_title("Statlar"))

	_points_label = Label.new()
	_content.add_child(_points_label)

	for kind in CharacterStats.KIND_ORDER:
		_content.add_child(_build_stat_row(kind))

func _build_stat_row(kind: CharacterStats.Kind) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = CharacterStats.kind_name(kind)
	name_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_label)

	var minus_button := Button.new()
	minus_button.text = "−"
	minus_button.pressed.connect(_on_stat_changed.bind(kind, -1))
	row.add_child(minus_button)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(value_label)

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.pressed.connect(_on_stat_changed.bind(kind, 1))
	row.add_child(plus_button)

	var description_label := _make_hint_label()
	description_label.text = CharacterStats.kind_description(kind)
	row.add_child(description_label)

	_stat_rows.append({
		"kind": kind,
		"value_label": value_label,
		"minus": minus_button,
		"plus": plus_button,
	})
	return row

func _build_crew_section() -> void:
	_content.add_child(_make_section_title("Tayfa"))

	var crew_row := HBoxContainer.new()
	crew_row.add_theme_constant_override("separation", 8)

	var crew_title := Label.new()
	crew_title.text = tr("UI_PARTY_SIZE")
	crew_title.custom_minimum_size = Vector2(120, 0)
	crew_row.add_child(crew_title)

	_crew_spin = SpinBox.new()
	_crew_spin.min_value = MIN_CREW_SIZE
	_crew_spin.max_value = MAX_CREW_SIZE
	_crew_spin.value = DEFAULT_CREW_SIZE
	_crew_spin.value_changed.connect(_on_crew_size_changed)
	crew_row.add_child(_crew_spin)

	_crew_wagon_label = Label.new()
	crew_row.add_child(_crew_wagon_label)
	_content.add_child(crew_row)

	var note := _make_hint_label()
	note.text = "Tayfa vagonları sürer ve kargo kapasiteni belirler. Yola tek başına çıkarsın; adı olan yoldaşları şehirde ve yolda toplarsın. Her vagonda iki kişi yattığı için partin vagon sayınla büyür, savaş alanı dört mevkiden ibaret olduğu için tavanı %d kişidir." % GameSession.MAX_PARTY_SIZE
	_content.add_child(note)

func _make_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	return label

func _make_hint_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.modulate = HINT_COLOR
	return label

# --- Girdi olayları ---

func _on_culture_selected(_index: int) -> void:
	var culture := _selected_culture()
	_culture_description.text = culture.description
	_culture_bonus.text = "Kültür bonusu: %s" % culture.get_bonus_summary()
	_culture_perk.text = culture.perk_text
	if _name_edit.text.strip_edges().is_empty():
		_roll_random_name()
	_refresh()

func _on_name_changed(_new_text: String) -> void:
	_refresh()

func _on_class_selected(_index: int) -> void:
	_refresh()

func _roll_random_name() -> void:
	var pool := _selected_culture().name_pool
	if pool.is_empty():
		return
	_name_edit.text = pool[_rng.randi_range(0, pool.size() - 1)]
	_refresh()

func _on_height_changed(_value: float) -> void:
	_refresh()

func _on_skin_selected(index: int) -> void:
	_skin_preview.color = CharacterData.get_skin_tone_color(index)
	_refresh()

func _on_stat_changed(kind: CharacterStats.Kind, delta: int) -> void:
	if delta > 0 and _spent_points >= STAT_POINTS:
		return
	var before := _base_stats.get_value(kind)
	if delta < 0 and before <= CharacterStats.BASE_VALUE:
		return

	_base_stats.add_value(kind, delta)
	_spent_points += _base_stats.get_value(kind) - before
	_refresh()

func _on_crew_size_changed(_value: float) -> void:
	_refresh()

# --- Görsel tazeleme ---

func _refresh() -> void:
	var culture := _selected_culture()
	var character_class := _selected_class()
	var preview := _build_character()

	_class_description.text = "%s Uygun görev: %s." % [
		character_class.description, DutyCatalog.get_duty(character_class.duty_id).display_name
	]

	_points_label.text = "Dağıtılacak puan: %d / %d" % [STAT_POINTS - _spent_points, STAT_POINTS]
	for row in _stat_rows:
		var kind: CharacterStats.Kind = row.kind
		var base_value := _base_stats.get_value(kind)
		var final_value := preview.stats.get_value(kind)
		var bonus := culture.get_stat_bonus(kind)
		var value_label: Label = row.value_label
		if bonus == 0:
			value_label.text = str(final_value)
		else:
			value_label.text = "%d (%d%+d)" % [final_value, base_value, bonus]
		var minus_button: Button = row.minus
		var plus_button: Button = row.plus
		minus_button.disabled = base_value <= CharacterStats.BASE_VALUE
		plus_button.disabled = _spent_points >= STAT_POINTS or base_value >= CharacterStats.MAX_VALUE

	_height_label.text = "%d cm — %s" % [int(_height_slider.value), _height_effect_text(preview)]
	_skin_preview.color = CharacterData.get_skin_tone_color(_skin_button.selected)
	_crew_wagon_label.text = tr("UI_PARTY_WAGON_NOTE") % _wagons_for_crew_size(int(_crew_spin.value))

	_summary_label.text = "%s\nCan %d · İnisiyatif %d · İsabet %d · Kaçınma %d · Kritik %%%d" % [
		preview.get_summary_line(),
		preview.get_max_hp(),
		preview.stats.get_initiative(),
		preview.stats.get_accuracy(),
		preview.get_dodge(),
		preview.stats.get_crit_chance(),
	]
	_start_button.disabled = _name_edit.text.strip_edges().is_empty()

func _height_effect_text(preview: CharacterData) -> String:
	var hp_bonus := preview.get_height_hp_bonus()
	var dodge_bonus := preview.get_height_dodge_bonus()
	if hp_bonus == 0 and dodge_bonus == 0:
		return "orta boy, dengeli"
	return "Can %+d · Kaçınma %+d" % [hp_bonus, dodge_bonus]

func _selected_culture() -> Culture:
	return CultureCatalog.get_cultures()[maxi(_culture_button.selected, 0)]

func _selected_class() -> CharacterClass:
	return ClassCatalog.get_classes()[maxi(_class_button.selected, 0)]

func _build_character() -> CharacterData:
	return CharacterData.create(
		_name_edit.text.strip_edges(),
		_selected_culture().culture_id,
		_base_stats,
		int(_height_slider.value),
		_skin_button.selected,
		_selected_class().class_id
	)

func _wagons_for_crew_size(crew_size: int) -> int:
	var wagons := ceili(float(crew_size) / float(PEOPLE_PER_WAGON))
	return clampi(wagons, CaravanState.MIN_WAGONS, CaravanPlan.DEFAULT_MAX_WAGONS)

# --- Çıkış ---

func _on_start_pressed() -> void:
	var character := _build_character()
	if character.character_name.is_empty():
		return

	SaveManager.delete_save()
	GameState.start_new_game(
		DEFAULT_STARTING_GOLD,
		DEFAULT_STARTING_PROVISIONS,
		_wagons_for_crew_size(int(_crew_spin.value))
	)
	GameState.get_session().set_player_character(character)

	Nav.return_scene = Nav.WORLD_HUB
	get_tree().change_scene_to_file(Nav.WORLD_HUB)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.MAIN_MENU)
