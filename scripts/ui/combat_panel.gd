class_name CombatPanel
extends VBoxContainer

## Savaş arayüzünün yeniden kullanılabilir hali. Yol olaylarındaki
## TRIGGER_COMBAT etkisi ve dev panelindeki savaş testi bunu kullanır,
## böylece savaş mantığı tek yerde durur (bkz. HagglingPanel deseni).
##
## Sahne dosyası yok: panel kendini kodda kurar, yolculuk ekranının içine
## gömülür. Böylece sefer sırasında sahne değiştirip durum taşımak
## gerekmez.

signal combat_finished(victory)  # bool

const ENEMY_COLOR: Color = Color(0.85, 0.45, 0.4)
const PLAYER_COLOR: Color = Color(0.55, 0.8, 0.55)
const DOWNED_COLOR: Color = Color(0.5, 0.5, 0.5)
const LOCKED_COLOR: Color = Color(0.6, 0.6, 0.6)
const MAX_LOG_LINES: int = 40

var _encounter: CombatEncounter
var _selected_skill: CombatSkill
var _built: bool = false

var _enemy_list: VBoxContainer
var _party_list: VBoxContainer
var _turn_label: Label
var _action_list: VBoxContainer
var _target_list: VBoxContainer
var _result_label: Label
var _continue_button: Button
var _log_scroll: ScrollContainer
var _log_list: VBoxContainer

func _ready() -> void:
	_ensure_built()

## Verilen parti ve tehlike seviyesiyle yeni bir savaş açar. Parti
## CharacterData listesidir; sıralaması mevki sırasıdır.
func start_combat(party: Array[CharacterData], danger_level: float, rng: RandomNumberGenerator = null) -> void:
	_ensure_built()

	var combat_rng := rng
	if combat_rng == null:
		combat_rng = RandomNumberGenerator.new()
		combat_rng.randomize()

	var units: Array[CombatUnit] = []
	var position := 1
	for character in party:
		if position > CombatEncounter.MAX_SIDE_SIZE:
			break
		units.append(CombatUnit.from_character(character, position))
		position += 1

	var enemies := EnemyCatalog.build_bandit_squad(danger_level, units.size(), combat_rng)

	_encounter = CombatEncounter.new(units, enemies, combat_rng)
	_encounter.log_added.connect(_on_log_added)
	_encounter.state_changed.connect(_on_state_changed)

	_selected_skill = null
	_result_label.text = ""
	_continue_button.visible = false
	_clear_children(_log_list)

	_encounter.start()
	_refresh()

func _ensure_built() -> void:
	if _built:
		return
	_built = true

	add_theme_constant_override("separation", 6)

	var enemy_title := Label.new()
	enemy_title.text = "Haydutlar"
	add_child(enemy_title)
	_enemy_list = VBoxContainer.new()
	add_child(_enemy_list)

	var party_title := Label.new()
	party_title.text = "Kadron"
	add_child(party_title)
	_party_list = VBoxContainer.new()
	add_child(_party_list)

	_turn_label = Label.new()
	add_child(_turn_label)

	_action_list = VBoxContainer.new()
	add_child(_action_list)

	_target_list = VBoxContainer.new()
	add_child(_target_list)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_result_label)

	_continue_button = Button.new()
	_continue_button.text = "Devam"
	_continue_button.visible = false
	_continue_button.pressed.connect(_on_continue_pressed)
	add_child(_continue_button)

	var log_title := Label.new()
	log_title.text = "Çarpışma Günlüğü"
	add_child(log_title)

	_log_scroll = ScrollContainer.new()
	_log_scroll.custom_minimum_size = Vector2(0, 160)
	_log_list = VBoxContainer.new()
	_log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_list)
	add_child(_log_scroll)

func _refresh() -> void:
	_refresh_roster(_enemy_list, _encounter.enemy_units, ENEMY_COLOR)
	_refresh_roster(_party_list, _encounter.player_units, PLAYER_COLOR)
	_refresh_actions()

func _refresh_roster(container: VBoxContainer, units: Array[CombatUnit], color: Color) -> void:
	_clear_children(container)
	var active := _encounter.get_active_unit()
	for unit in units:
		var label := Label.new()
		var marker := "▶ " if unit == active and not _encounter.is_over() else "   "
		label.text = "%s%d. %s — %d/%d" % [marker, unit.position, unit.display_name, unit.current_hp, unit.max_hp]
		label.modulate = color if unit.is_alive() else DOWNED_COLOR
		container.add_child(label)

func _refresh_actions() -> void:
	_clear_children(_action_list)
	_clear_children(_target_list)

	if _encounter.is_over() or not _encounter.is_player_turn():
		_turn_label.text = ""
		return

	var unit := _encounter.get_active_unit()
	_turn_label.text = "Tur %d — sıra %s'de (%d. mevki)" % [
		_encounter.round_number, unit.display_name, unit.position
	]

	for skill in unit.skills:
		_action_list.add_child(_build_skill_button(unit, skill))

	for swap_row in _build_swap_rows():
		_action_list.add_child(swap_row)

	if _selected_skill != null:
		_build_target_buttons(unit, _selected_skill)

## Kilitli yetenek gizlenmez, sebebiyle birlikte gösterilir - oyuncu
## mevki kilidini böyle öğrenir (bkz. olay ekranındaki kilitli seçenekler).
func _build_skill_button(unit: CombatUnit, skill: CombatSkill) -> Button:
	var button := Button.new()
	var reason := unit.get_skill_block_reason(skill)
	if reason.is_empty():
		button.text = "%s (%s)" % [skill.display_name, skill.get_position_summary()]
		button.pressed.connect(_on_skill_pressed.bind(skill))
	else:
		button.text = "%s — %s" % [skill.display_name, reason]
		button.disabled = true
		button.modulate = LOCKED_COLOR
	button.tooltip_text = skill.description
	return button

func _build_swap_rows() -> Array[Button]:
	var buttons: Array[Button] = []
	var units := _encounter.player_units
	for index in units.size() - 1:
		var first := units[index]
		var second := units[index + 1]
		if not first.is_alive() or not second.is_alive():
			continue
		var button := Button.new()
		button.text = "Yer değiştir: %s ↔ %s" % [first.display_name, second.display_name]
		button.pressed.connect(_on_swap_pressed.bind(first, second))
		buttons.append(button)
	return buttons

func _build_target_buttons(unit: CombatUnit, skill: CombatSkill) -> void:
	var targets := _encounter.get_valid_targets(unit, skill)
	var title := Label.new()
	if targets.is_empty():
		title.text = "%s için menzilde hedef yok." % skill.display_name
		_target_list.add_child(title)
		return

	title.text = "%s — hedef seç:" % skill.display_name
	_target_list.add_child(title)
	for target in targets:
		var button := Button.new()
		button.text = "%d. %s (%d/%d)" % [target.position, target.display_name, target.current_hp, target.max_hp]
		button.pressed.connect(_on_target_pressed.bind(skill, target))
		_target_list.add_child(button)

func _on_skill_pressed(skill: CombatSkill) -> void:
	_selected_skill = skill
	_refresh_actions()

func _on_target_pressed(skill: CombatSkill, target: CombatUnit) -> void:
	_selected_skill = null
	_encounter.use_skill(skill, target)
	_refresh()

func _on_swap_pressed(first: CombatUnit, second: CombatUnit) -> void:
	_selected_skill = null
	_encounter.swap_player_positions(first, second)
	_refresh()

func _on_log_added(line: String) -> void:
	var label := Label.new()
	label.text = line
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_log_list.add_child(label)
	while _log_list.get_child_count() > MAX_LOG_LINES:
		var oldest := _log_list.get_child(0)
		_log_list.remove_child(oldest)
		oldest.queue_free()
	_scroll_log_to_bottom()

func _scroll_log_to_bottom() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)

func _on_state_changed(new_state: CombatEncounter.State) -> void:
	if new_state == CombatEncounter.State.VICTORY:
		_result_label.text = "Zafer! Haydutların bıraktıklarını topluyorsun."
	else:
		_result_label.text = "Yenilgi. Haydutlar yüklerin bir kısmını alıp kayboldu."
	_continue_button.visible = true

func _on_continue_pressed() -> void:
	var victory := _encounter.state == CombatEncounter.State.VICTORY
	_encounter.write_back_party()
	_continue_button.visible = false
	combat_finished.emit(victory)

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
