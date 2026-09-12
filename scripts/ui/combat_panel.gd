class_name CombatPanel
extends VBoxContainer

## Savaş arayüzünün yeniden kullanılabilir hali. Yol olaylarındaki
## TRIGGER_COMBAT etkisi ve dev panelindeki savaş testi bunu kullanır,
## böylece savaş mantığı tek yerde durur (bkz. HagglingPanel deseni).
##
## Sahne dosyası yok: panel kendini kodda kurar, yolculuk ekranının içine
## gömülür. Böylece sefer sırasında sahne değiştirip durum taşımak
## gerekmez.
##
## **Bu ekran bir savaş alanı, bir liste değil.** Önceki hali dikey bir
## yığındı - düşman listesi, parti listesi, yetenek tuşları, *ayrı* bir
## hedef tuşu listesi - ve mevkiler yalnızca sayı olarak yazıyordu. Yani
## motor pozisyona dayalıydı ama ekran değildi; pozisyonun bütün anlamı
## kaybolduğu için savaş bir visual novel gibi okunuyordu. Şimdi iki
## karşılıklı saf var, hedef sahnede tıklanıyor, mevki kilidi yetenek
## kartının üzerindeki belirteçlerden okunuyor.

## dead_characters: savaşta kalıcı ölen CharacterData listesi (bkz.
## CombatUnit'in Ölümün Kıyısı bölümü). Panel bunu *uygulamaz* - partiden
## çıkarma ve liderliğin devri oturumun işi, ekranın değil.
signal combat_finished(victory, xp_awarded, downed_count, dead_characters)  # bool, int, int, Array[CharacterData]

const LOCKED_COLOR: Color = Color(0.6, 0.6, 0.6)
const MAX_LOG_LINES: int = 40

## Mevki belirteçleri: dolu daire "burada durabilir" / "buraya vurabilir",
## boş daire duramaz/vuramaz. DD'nin yetenek ikonundaki nokta dizisinin
## karşılığı - sayı yerine şekil, çünkü oyuncunun bunu okumak için durup
## düşünmemesi gerekiyor.
const MARK_ON: String = "●"
const MARK_OFF: String = "○"
const LAUNCH_COLOR: Color = Color(0.95, 0.82, 0.45)
const SKILL_CARD_WIDTH: float = 156.0
## Savaş alanının en az yüksekliği. İlk denemede alan 900 pikselin
## üst 200'ünde ince bir şeritti; DD'de savaş alanı ekranın kendisidir.
const STAGE_HEIGHT: float = 380.0
const TARGET_MARK_COLOR: Color = Color(0.90, 0.45, 0.40)

var _encounter: CombatEncounter
var _selected_skill: CombatSkill
var _built: bool = false

var _round_label: Label
var _order_strip: HBoxContainer
var _player_row: HBoxContainer
var _enemy_row: HBoxContainer
var _active_label: Label
var _hint_label: Label
var _skill_row: HBoxContainer
var _extra_row: HBoxContainer
var _result_label: Label
var _continue_button: Button
var _log_scroll: ScrollContainer
var _log_list: VBoxContainer

func _ready() -> void:
	_ensure_built()

## Verilen parti ve tehlike seviyesiyle yeni bir savaş açar. Parti
## CharacterData listesidir; sıralaması mevki sırasıdır. party_stress
## GameSession'dan geçirilir - kırılma noktasını aşmış (bkz.
## CharacterData.is_stressed) her karakter emirlere kulak asmayabilir.
func start_combat(
	party: Array[CharacterData], danger_level: float,
	rng: RandomNumberGenerator = null, party_stress: int = 0,
	enemy_kind: String = "bandit", region_id: String = ""
) -> void:
	_ensure_built()

	var combat_rng := rng
	if combat_rng == null:
		combat_rng = RandomNumberGenerator.new()
		combat_rng.randomize()

	var units: Array[CombatUnit] = []
	var position := 1
	var level_total := 0
	for character in party:
		if position > CombatEncounter.MAX_SIDE_SIZE:
			break
		units.append(CombatUnit.from_character(character, position, character.is_stressed(party_stress)))
		level_total += character.level
		position += 1

	var average_level := int(round(float(level_total) / float(maxi(1, units.size()))))
	var enemies := EnemyCatalog.build_squad(
		enemy_kind, region_id, danger_level, units.size(), combat_rng, average_level
	)
	var enemy_label := EnemyCatalog.get_kind_label(enemy_kind)

	_apply_muhafiz_opening_bonus(party, units)

	_encounter = CombatEncounter.new(units, enemies, combat_rng, enemy_label)
	_encounter.log_added.connect(_on_log_added)
	_encounter.state_changed.connect(_on_state_changed)

	_selected_skill = null
	_result_label.text = ""
	_continue_button.visible = false
	_clear_children(_log_list)

	_encounter.start()
	_refresh()

## Muhafız görevini tutan biri varsa kadro ilk tura iyi konumlanmış girer:
## herkese tek turluk bir isabet bonusu. DutyCatalog.get_duty_power()
## zaten sınıf eşleşmesini ve statı hesaba katıyor, burada yalnızca sayıya
## çeviriyoruz.
func _apply_muhafiz_opening_bonus(party: Array[CharacterData], units: Array[CombatUnit]) -> void:
	var holder: CharacterData = null
	for character in party:
		if character.duty_id == DutyCatalog.MUHAFIZ:
			holder = character
			break
	if holder == null:
		return

	var power := DutyCatalog.get_duty_power(holder, DutyCatalog.MUHAFIZ)
	var bonus := int(round(10.0 * (power - 1.0)))
	if bonus <= 0:
		return
	for unit in units:
		unit.apply_modifier("accuracy", bonus, 1)

# --- Kurulum ---

func _ensure_built() -> void:
	if _built:
		return
	_built = true

	add_theme_constant_override("separation", 6)
	_build_header()
	_build_field()
	_build_action_area()
	_build_log()

func _build_header() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)

	_round_label = Label.new()
	_round_label.custom_minimum_size = Vector2(90.0, 0.0)
	header.add_child(_round_label)

	# Tur sırası şeridi: hız zarı round başına sırayı değiştirdiği için
	# artık gerçekten bilgi taşıyor (bkz. CombatEncounter.SPEED_DIE).
	# Sabit sırada bunu göstermenin bir anlamı yoktu.
	_order_strip = HBoxContainer.new()
	_order_strip.add_theme_constant_override("separation", 4)
	header.add_child(_order_strip)

	add_child(header)

## İki karşılıklı saf. Oyuncu tarafı ters sırada diziliyor: 1. mevki
## ortaya, yani düşmanın 1. mevkisinin karşısına gelmeli - "ön saf" ancak
## karşı karşıya durunca anlam taşır.
func _build_field() -> void:
	# Figürler boşlukta duruyordu ve savaş bir tabloya benziyordu. Zemin
	# katmanı (karanlık kuyu + ufuk + meşale ışığı + vinyet) saflardan
	# *önce* çiziliyor; saflar onun üstünde duruyor.
	var stage := Panel.new()
	var stage_style := StyleBoxFlat.new()
	stage_style.bg_color = Color(0, 0, 0, 0)
	stage_style.border_color = Color(0.30, 0.25, 0.18, 0.8)
	stage_style.set_border_width_all(1)
	stage.add_theme_stylebox_override("panel", stage_style)
	# Dikeyde *uzamıyor*: EXPAND_FILL'de eldeki bütün boşluğu yutup
	# figürleri dibe itiyordu. Sahne her ekranda aynı yükseklikte durmalı.
	stage.custom_minimum_size = Vector2(0.0, STAGE_HEIGHT)
	stage.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(stage)

	var backdrop := CombatBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(backdrop)

	var field := HBoxContainer.new()
	field.set_anchors_preset(Control.PRESET_FULL_RECT)
	field.add_theme_constant_override("separation", 10)
	field.alignment = BoxContainer.ALIGNMENT_CENTER

	_player_row = HBoxContainer.new()
	_player_row.add_theme_constant_override("separation", 4)
	_player_row.alignment = BoxContainer.ALIGNMENT_END
	_player_row.size_flags_vertical = Control.SIZE_SHRINK_END
	_player_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(_player_row)

	# İki tarafın arasında ince bir boşluk yeter: zemin ve ışık havuzu
	# ayrımı zaten taşıyor, ek bir çizgi sahneyi ikiye biçiyordu.
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(26.0, 0.0)
	field.add_child(gap)

	_enemy_row = HBoxContainer.new()
	_enemy_row.add_theme_constant_override("separation", 4)
	_enemy_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_enemy_row.size_flags_vertical = Control.SIZE_SHRINK_END
	_enemy_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(_enemy_row)

	stage.add_child(field)

func _build_action_area() -> void:
	_active_label = Label.new()
	add_child(_active_label)

	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hint_label.modulate = Color(0.72, 0.70, 0.64)
	add_child(_hint_label)

	_skill_row = HBoxContainer.new()
	_skill_row.add_theme_constant_override("separation", 6)
	add_child(_skill_row)

	_extra_row = HBoxContainer.new()
	_extra_row.add_theme_constant_override("separation", 6)
	add_child(_extra_row)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_result_label)

	_continue_button = Button.new()
	_continue_button.text = tr("UI_COMBAT_CONTINUE")
	_continue_button.visible = false
	_continue_button.pressed.connect(_on_continue_pressed)
	add_child(_continue_button)

func _build_log() -> void:
	_log_scroll = ScrollContainer.new()
	_log_scroll.custom_minimum_size = Vector2(0, 96)
	_log_list = VBoxContainer.new()
	_log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_list)
	add_child(_log_scroll)

# --- Tazeleme ---

func _refresh() -> void:
	if _encounter == null:
		return
	_refresh_header()
	_refresh_side(_player_row, _encounter.player_units, true)
	_refresh_side(_enemy_row, _encounter.enemy_units, false)
	_refresh_actions()

func _refresh_header() -> void:
	_round_label.text = tr("UI_COMBAT_ROUND") % _encounter.round_number
	_clear_children(_order_strip)
	if _encounter.is_over():
		return
	var active := _encounter.get_active_unit()
	for unit in _encounter.get_turn_order():
		if not unit.is_alive():
			continue
		_order_strip.add_child(_build_order_chip(unit, unit == active))

func _build_order_chip(unit: CombatUnit, is_active: bool) -> Label:
	var chip := Label.new()
	chip.text = unit.display_name
	chip.add_theme_font_size_override("font_size", 9)
	if is_active:
		chip.modulate = CombatUnitSlot.ACTIVE_BORDER
	elif unit.is_player_side:
		chip.modulate = Color(0.6, 0.74, 0.6)
	else:
		chip.modulate = Color(0.78, 0.55, 0.52)
	return chip

## Bir safın mevkilerini kurar. Oyuncu tarafı ters diziliyor (bkz.
## _build_field). Hedeflenebilirlik seçili yetenekten geliyor, o yüzden
## her tazelemede yeniden hesaplanıyor.
func _refresh_side(row: HBoxContainer, units: Array[CombatUnit], reversed_order: bool) -> void:
	_clear_children(row)

	var ordered: Array[CombatUnit] = units.duplicate()
	ordered.sort_custom(func(a, b): return a.position < b.position)
	if reversed_order:
		ordered.reverse()

	var active := _encounter.get_active_unit()
	var targets := _current_targets()
	for unit in ordered:
		var slot := CombatUnitSlot.new()
		row.add_child(slot)
		slot.bind(unit, unit == active and not _encounter.is_over(), targets.has(unit))
		slot.clicked.connect(_on_unit_clicked)

func _current_targets() -> Array[CombatUnit]:
	var empty: Array[CombatUnit] = []
	if _selected_skill == null or _encounter.is_over() or not _encounter.is_player_turn():
		return empty
	return _encounter.get_valid_targets(_encounter.get_active_unit(), _selected_skill)

func _refresh_actions() -> void:
	_clear_children(_skill_row)
	_clear_children(_extra_row)

	if _encounter.is_over() or not _encounter.is_player_turn():
		_active_label.text = ""
		_hint_label.text = ""
		return

	var unit := _encounter.get_active_unit()
	_active_label.text = tr("UI_COMBAT_ACTIVE") % [
		unit.display_name, unit.position, unit.get_effective_accuracy(), unit.protection
	]
	if _selected_skill != null:
		_hint_label.text = tr("UI_COMBAT_HINT_PICK_TARGET") % _selected_skill.display_name
	else:
		_hint_label.text = tr("UI_COMBAT_HINT_PICK_SKILL")

	for skill in unit.skills:
		_skill_row.add_child(_build_skill_card(unit, skill))

	_build_extra_actions()

## Bir yetenek kartı: adı, iki mevki belirteci satırı ve kilitliyse
## sebebi. Kilitli yetenek gizlenmez - oyuncu mevki kilidini böyle
## öğrenir (bkz. olay ekranındaki kilitli seçenekler).
func _build_skill_card(unit: CombatUnit, skill: CombatSkill) -> Control:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 1)
	# Eşit genişlik: ilk görüntüde kartlar ad uzunluğuna göre farklı
	# genişlikteydi ve satır tırtıklı duruyordu.
	card.custom_minimum_size = Vector2(SKILL_CARD_WIDTH, 0.0)

	var button := Button.new()
	button.text = skill.display_name
	button.tooltip_text = skill.description
	button.toggle_mode = true
	button.button_pressed = skill == _selected_skill

	var reason := unit.get_skill_block_reason(skill)
	if reason.is_empty():
		button.pressed.connect(_on_skill_pressed.bind(skill))
	else:
		button.disabled = true
		button.modulate = LOCKED_COLOR
		button.tooltip_text = "%s\n%s" % [skill.description, reason]
	card.add_child(button)

	card.add_child(_build_mark_row(tr("UI_COMBAT_MARK_LAUNCH"), skill.usable_positions, LAUNCH_COLOR))
	card.add_child(_build_mark_row(tr("UI_COMBAT_MARK_TARGET"), skill.target_positions, TARGET_MARK_COLOR))
	return card

func _build_mark_row(prefix: String, positions: Array[int], color: Color) -> Label:
	var marks := ""
	for rank in range(1, CombatEncounter.MAX_SIDE_SIZE + 1):
		marks += MARK_ON if positions.has(rank) else MARK_OFF
	var label := Label.new()
	label.text = "%s %s" % [prefix, marks]
	label.add_theme_font_size_override("font_size", 11)
	label.modulate = color
	return label

## Yetenek dışı eylemler: mevki değiştirmek ve turu geçmek. Turu geçmek
## motorun kendisi için de gerekli - elinde kullanılabilir yeteneği
## kalmamış bir savaşçı yoksa sırayı hiç bırakamaz (bkz.
## CombatEncounter.pass_turn).
func _build_extra_actions() -> void:
	var units := _encounter.player_units
	for index in units.size() - 1:
		var first := units[index]
		var second := units[index + 1]
		if not first.is_alive() or not second.is_alive():
			continue
		var button := Button.new()
		button.text = tr("UI_COMBAT_SWAP") % [first.display_name, second.display_name]
		button.pressed.connect(_on_swap_pressed.bind(first, second))
		_extra_row.add_child(button)

	var pass_button := Button.new()
	pass_button.text = tr("UI_COMBAT_PASS")
	pass_button.pressed.connect(_on_pass_pressed)
	_extra_row.add_child(pass_button)

# --- Girdi ---

func _on_skill_pressed(skill: CombatSkill) -> void:
	# Aynı yeteneğe ikinci basış seçimi kaldırır: hedef seçmekten
	# vazgeçmenin bir yolu olmalı.
	_selected_skill = null if _selected_skill == skill else skill
	_refresh()

func _on_unit_clicked(target: CombatUnit) -> void:
	if _selected_skill == null:
		return
	var skill := _selected_skill
	_selected_skill = null
	_encounter.use_skill(skill, target)
	_refresh()

func _on_swap_pressed(first: CombatUnit, second: CombatUnit) -> void:
	_selected_skill = null
	_encounter.swap_player_positions(first, second)
	_refresh()

func _on_pass_pressed() -> void:
	_selected_skill = null
	_encounter.pass_turn()
	_refresh()

# --- Kayıt ve bitiş ---

func _on_log_added(line: String) -> void:
	var label := Label.new()
	label.text = line
	label.add_theme_font_size_override("font_size", 10)
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
		_result_label.text = tr("UI_COMBAT_VICTORY") % _encounter.enemy_label
	else:
		_result_label.text = tr("UI_COMBAT_DEFEAT") % _encounter.enemy_label
	_continue_button.visible = true
	_refresh()

func _on_continue_pressed() -> void:
	var victory := _encounter.state == CombatEncounter.State.VICTORY
	var xp_awarded := 0
	for unit in _encounter.enemy_units:
		if not unit.is_alive():
			xp_awarded += unit.xp_value
	# downed_count write_back_party()'den önce okunmalı - o çağrı düşenleri
	# 1 canla ayağa kaldırıyor, sonrasında kimse "düşmüş" sayılmıyor.
	var downed_count := _encounter.get_downed_count()
	var dead := _encounter.get_dead_characters()
	_encounter.write_back_party()
	_continue_button.visible = false
	combat_finished.emit(victory, xp_awarded, downed_count, dead)

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
