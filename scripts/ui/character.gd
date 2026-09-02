extends Control

## Tek bir karakterin ayrıntı ekranı: stat/yetkinlik yatırımı, görev
## ataması, multiclass seçimi ve (Faz 7'ye kadar) ekipman yer tutucuları.
## Parti ekranından "Karakter" düğmesiyle açılır; hangi üyeyi gösterdiği
## Nav.character_target_index'ten okunur.

const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)
const PERK_COLOR: Color = Color(0.75, 0.85, 1.0)
const LOCKED_COLOR: Color = Color(0.6, 0.6, 0.6)
const POSITIVE_COLOR: Color = Color(0.6, 0.85, 0.6)
const NEGATIVE_COLOR: Color = Color(0.9, 0.6, 0.55)
const EQUIPMENT_SLOTS: Array[String] = ["Silah", "Zırh", "Yüzük", "Kolye"]

var _session: GameSession
var _character: CharacterData

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	# Bu ekran yalnızca parti ekranından açılıyor, dönüş hedefi de her
	# zaman orası - Nav.return_scene'e dokunmuyoruz ki parti ekranının
	# kendi dönüş hedefi (dünya ya da şehir haritası) burada kaybolmasın.
	_back_button.text = "Partiye Dön"
	_back_button.pressed.connect(_on_back_pressed)

	var party := _session.get_party()
	var index := clampi(Nav.character_target_index, 0, maxi(0, party.size() - 1))
	_character = party[index] if not party.is_empty() else _session.get_player_character()

	_refresh()

func _refresh() -> void:
	_clear_children(_content)
	_build_identity_section()
	_content.add_child(HSeparator.new())
	_build_traits_section()
	_content.add_child(HSeparator.new())
	_build_progress_section()
	_content.add_child(HSeparator.new())
	_build_stats_section()
	_content.add_child(HSeparator.new())
	_build_skills_section()
	_content.add_child(HSeparator.new())
	_build_duty_section()
	if _character.can_multiclass():
		_content.add_child(HSeparator.new())
		_build_multiclass_section()
	_content.add_child(HSeparator.new())
	_build_equipment_section()

func _build_identity_section() -> void:
	_content.add_child(_make_section_title(_character.get_summary_line()))

	var appearance := Label.new()
	appearance.text = _character.get_appearance_line()
	appearance.modulate = HINT_COLOR
	_content.add_child(appearance)

	var hp := Label.new()
	hp.text = "Can %d/%d" % [_character.current_hp, _character.get_max_hp()]
	_content.add_child(hp)

	var derived := Label.new()
	derived.text = "İnisiyatif %d · İsabet %d · Kaçınma %d · Kritik %%%d · Hasar +%d" % [
		_character.stats.get_initiative(),
		_character.get_accuracy(),
		_character.get_dodge(),
		_character.get_crit_chance(),
		_character.get_damage_bonus(),
	]
	derived.modulate = HINT_COLOR
	_content.add_child(derived)

	var perk := Label.new()
	perk.text = _character.get_culture().perk_text
	perk.autowrap_mode = TextServer.AUTOWRAP_WORD
	perk.modulate = PERK_COLOR
	_content.add_child(perk)

func _build_traits_section() -> void:
	_content.add_child(_make_section_title("Huylar"))

	var traits := _character.get_traits()
	if traits.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Henüz bir huyu yok."
		empty_label.modulate = HINT_COLOR
		_content.add_child(empty_label)
		return

	for trait_resource in traits:
		var row := Label.new()
		var fresh := _character.is_trait_fresh(
			trait_resource.trait_id, _session.total_days_elapsed
		)
		row.text = "%s — %s%s" % [
			trait_resource.display_name,
			trait_resource.description,
			" (taze, tavernada/kilisede arındırılabilir)" if fresh else "",
		]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.modulate = POSITIVE_COLOR if trait_resource.is_positive else NEGATIVE_COLOR
		_content.add_child(row)

func _build_progress_section() -> void:
	_content.add_child(_make_section_title("İlerleme"))

	var level_label := Label.new()
	if _character.level >= CharacterData.MAX_LEVEL:
		level_label.text = "Seviye %d (tavan)" % _character.level
	else:
		var required := CharacterData.xp_required_for_level(_character.level)
		level_label.text = "Seviye %d — %d/%d XP" % [_character.level, _character.xp, required]
	_content.add_child(level_label)

	var auto_check := CheckBox.new()
	auto_check.text = "Seviye atlayınca otomatik dağıt"
	auto_check.button_pressed = _character.auto_allocate
	auto_check.toggled.connect(_on_auto_allocate_toggled)
	_content.add_child(auto_check)

	if not _character.auto_allocate:
		var pending := Label.new()
		pending.text = "Harcanmamış: %d stat puanı · %d yetkinlik puanı" % [
			_character.unspent_stat_points, _character.unspent_skill_points
		]
		pending.modulate = HINT_COLOR
		_content.add_child(pending)

func _build_stats_section() -> void:
	_content.add_child(_make_section_title("Statlar"))
	for kind in CharacterStats.KIND_ORDER:
		_content.add_child(_build_stat_row(kind))

func _build_stat_row(kind: CharacterStats.Kind) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = CharacterStats.kind_name(kind)
	name_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = str(_character.stats.get_value(kind))
	value_label.custom_minimum_size = Vector2(40, 0)
	row.add_child(value_label)

	var plus_button := Button.new()
	plus_button.text = "+"
	var maxed := _character.stats.get_value(kind) >= CharacterStats.MAX_VALUE
	if _character.auto_allocate:
		plus_button.disabled = true
		plus_button.tooltip_text = "Otomatik dağıtım açık"
	elif _character.unspent_stat_points <= 0:
		plus_button.disabled = true
		plus_button.tooltip_text = "Harcanmamış puan yok"
	elif maxed:
		plus_button.disabled = true
		plus_button.tooltip_text = "Tavanda"
	else:
		plus_button.pressed.connect(_on_stat_invest_pressed.bind(kind))
	row.add_child(plus_button)

	var description := Label.new()
	description.text = CharacterStats.kind_description(kind)
	description.modulate = HINT_COLOR
	row.add_child(description)

	return row

func _build_skills_section() -> void:
	_content.add_child(_make_section_title("Yetkinlik"))
	for skill in _character.get_skills():
		_content.add_child(_build_skill_row(skill))

func _build_skill_row(skill: CombatSkill) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = skill.display_name
	name_label.tooltip_text = skill.description
	name_label.custom_minimum_size = Vector2(160, 0)
	row.add_child(name_label)

	var proficiency := _character.get_skill_proficiency(skill.skill_id)
	var value_label := Label.new()
	value_label.text = "%d/%d" % [proficiency, CharacterData.MAX_SKILL_PROFICIENCY]
	value_label.custom_minimum_size = Vector2(60, 0)
	row.add_child(value_label)

	var plus_button := Button.new()
	plus_button.text = "+"
	if _character.auto_allocate:
		plus_button.disabled = true
		plus_button.tooltip_text = "Otomatik dağıtım açık"
	elif _character.unspent_skill_points <= 0:
		plus_button.disabled = true
		plus_button.tooltip_text = "Harcanmamış puan yok"
	elif proficiency >= CharacterData.MAX_SKILL_PROFICIENCY:
		plus_button.disabled = true
		plus_button.tooltip_text = "Tavanda"
	else:
		plus_button.pressed.connect(_on_skill_invest_pressed.bind(skill.skill_id))
	row.add_child(plus_button)

	return row

func _build_duty_section() -> void:
	_content.add_child(_make_section_title("Görev"))

	var note := Label.new()
	note.text = "Bir görevi yalnızca bir kişi tutabilir; başka birine verince eskisi boşa çıkar."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.modulate = HINT_COLOR
	_content.add_child(note)

	var duty_button := OptionButton.new()
	duty_button.add_item("Yok")
	var duties := DutyCatalog.get_duties()
	var selected_index := 0
	for i in duties.size():
		var duty: Duty = duties[i]
		var holder := _session.get_duty_holder(duty.duty_id)
		var suffix := ""
		if holder != null and holder != _character:
			suffix = " (%s tutuyor)" % holder.character_name
		duty_button.add_item("%s%s" % [duty.display_name, suffix])
		if _character.duty_id == duty.duty_id:
			selected_index = i + 1
	duty_button.select(selected_index)
	duty_button.item_selected.connect(_on_duty_selected.bind(duties))
	_content.add_child(duty_button)

func _build_multiclass_section() -> void:
	_content.add_child(_make_section_title("İkinci Sınıf"))

	var note := Label.new()
	note.text = "Yedinci seviyeden sonra ikinci bir sınıfın yeteneklerini de kullanabilirsin."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.modulate = HINT_COLOR
	_content.add_child(note)

	var class_button := OptionButton.new()
	class_button.add_item("Yok")
	var options: Array[CharacterClass] = []
	var selected_index := 0
	for character_class in ClassCatalog.get_classes():
		if character_class.class_id == _character.class_id:
			continue
		options.append(character_class)
		class_button.add_item(character_class.display_name)
		if _character.second_class_id == character_class.class_id:
			selected_index = options.size()
	class_button.select(selected_index)
	class_button.item_selected.connect(_on_second_class_selected.bind(options))
	_content.add_child(class_button)

func _build_equipment_section() -> void:
	_content.add_child(_make_section_title("Ekipman"))

	var note := Label.new()
	note.text = "Faz 7'de gelecek."
	note.modulate = HINT_COLOR
	_content.add_child(note)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for slot_name in EQUIPMENT_SLOTS:
		var slot_button := Button.new()
		slot_button.text = slot_name
		slot_button.disabled = true
		slot_button.modulate = LOCKED_COLOR
		slot_button.tooltip_text = "Faz 7'de gelecek"
		row.add_child(slot_button)
	_content.add_child(row)

func _make_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	return label

# --- Girdi olayları ---

func _on_stat_invest_pressed(kind: CharacterStats.Kind) -> void:
	_character.invest_stat_point(kind)
	_refresh()

func _on_skill_invest_pressed(skill_id: String) -> void:
	_character.invest_skill_point(skill_id)
	_refresh()

func _on_auto_allocate_toggled(pressed: bool) -> void:
	_character.auto_allocate = pressed
	if pressed:
		_character.flush_pending_points()
	_refresh()

func _on_duty_selected(index: int, duties: Array) -> void:
	if index <= 0:
		_session.assign_duty(_character, "")
	else:
		var duty: Duty = duties[index - 1]
		_session.assign_duty(_character, duty.duty_id)
	_refresh()

func _on_second_class_selected(index: int, options: Array) -> void:
	if index <= 0:
		_character.clear_second_class()
	else:
		var character_class: CharacterClass = options[index - 1]
		_character.set_second_class(character_class.class_id)
	_refresh()

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.PARTY)
