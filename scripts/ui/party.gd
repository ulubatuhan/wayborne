extends Control

## Parti ekranı: kimler yanında, ne kadar dayanıklılar, hangi mevkide
## duruyorlar. Sıralama savaştaki mevki sırasıdır (1 = en önde), bu yüzden
## burada sıra değiştirmek savaşı doğrudan etkiler.
##
## Tayfa toplama burada değil - o mekâna bağlı (bkz. RecruitPanel). Burası
## eldekini görüp düzenlediğin yer.

const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)
const PERK_COLOR: Color = Color(0.75, 0.85, 1.0)
const HURT_COLOR: Color = Color(0.9, 0.55, 0.45)
const LOCKED_COLOR: Color = Color(0.6, 0.6, 0.6)

var _session: GameSession

@onready var _info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_back_button.text = Nav.return_label()
	_back_button.pressed.connect(_on_back_pressed)
	_refresh()

func _refresh() -> void:
	var party := _session.get_party()
	_info_label.text = "Parti %d/%d · %d vagon · Sıra savaştaki mevki sırasıdır (1 = en önde). Her vagonda iki kişi yatar, savaş alanı dört mevkiden ibarettir." % [
		party.size(),
		_session.get_party_capacity(),
		_session.owned_wagon_count,
	]

	_clear_children(_content)
	for index in party.size():
		_content.add_child(_build_member_card(party[index], index, party.size()))

func _build_member_card(character: CharacterData, index: int, party_size: int) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)

	var portrait := ColorRect.new()
	portrait.color = CharacterData.get_skin_tone_color(character.skin_tone)
	portrait.custom_minimum_size = Vector2(28, 28)
	header.add_child(portrait)

	var name_label := Label.new()
	name_label.text = "%d. %s" % [index + 1, character.get_summary_line()]
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.custom_minimum_size = Vector2(460, 0)
	header.add_child(name_label)

	# Oyuncunun kendisi (party[0]) çıkarılamaz ama yerini değiştirebilir.
	if index > 0:
		header.add_child(_build_move_button("↑", index, index - 1))
	if index < party_size - 1:
		header.add_child(_build_move_button("↓", index, index + 1))
	if index > 0:
		var dismiss_button := Button.new()
		dismiss_button.text = "Yol Ver"
		dismiss_button.pressed.connect(_on_dismiss_pressed.bind(character))
		header.add_child(dismiss_button)
	else:
		var you_label := Label.new()
		you_label.text = "(sen)"
		you_label.modulate = LOCKED_COLOR
		header.add_child(you_label)

	card.add_child(header)

	var hp_label := Label.new()
	hp_label.text = "Can %d/%d · %s" % [
		character.current_hp, character.get_max_hp(), character.get_appearance_line()
	]
	if character.current_hp < character.get_max_hp():
		hp_label.modulate = HURT_COLOR
	card.add_child(hp_label)

	var stats_label := Label.new()
	stats_label.text = _stats_line(character)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(stats_label)

	var derived_label := Label.new()
	derived_label.text = "İnisiyatif %d · İsabet %d · Kaçınma %d · Kritik %%%d · Hasar +%d" % [
		character.stats.get_initiative(),
		character.stats.get_accuracy(),
		character.get_dodge(),
		character.stats.get_crit_chance(),
		character.stats.get_damage_bonus(),
	]
	derived_label.modulate = HINT_COLOR
	card.add_child(derived_label)

	var perk_label := Label.new()
	perk_label.text = character.get_culture().perk_text
	perk_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	perk_label.modulate = PERK_COLOR
	card.add_child(perk_label)

	for skill in character.get_skills():
		card.add_child(_build_skill_label(skill, index + 1))

	card.add_child(HSeparator.new())
	return card

func _build_move_button(text: String, from_index: int, to_index: int) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(_on_move_pressed.bind(from_index, to_index))
	return button

## Yetenek bu mevkiden kullanılamıyorsa gizlenmiyor, sebebiyle
## gösteriliyor - savaş panelindeki kuralın aynısı.
func _build_skill_label(skill: CombatSkill, position: int) -> Label:
	var label := Label.new()
	label.text = "  • %s (%s)" % [skill.display_name, skill.get_position_summary()]
	if not skill.can_use_from(position):
		label.text += " — bu mevkiden kullanılamaz"
		label.modulate = LOCKED_COLOR
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label

func _stats_line(character: CharacterData) -> String:
	var parts: Array[String] = []
	for kind in CharacterStats.KIND_ORDER:
		parts.append("%s %d" % [
			CharacterStats.kind_name(kind), character.stats.get_value(kind)
		])
	return " · ".join(parts)

func _on_move_pressed(from_index: int, to_index: int) -> void:
	if _session.swap_party_positions(from_index, to_index):
		_refresh()

func _on_dismiss_pressed(character: CharacterData) -> void:
	if _session.dismiss(character):
		_refresh()

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)
