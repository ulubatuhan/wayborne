class_name CombatEncounter
extends RefCounted

## Darkest Dungeon tarzı sıra tabanlı çarpışma. Dört mevkilik iki saf,
## inisiyatif sırasına göre tek tek hamle. UI'dan bağımsız: sinyalleri
## dinleyen herhangi bir panel bunu sürebilir, testte de doğrudan
## örneklenebilir.
##
## Kervan kuralı burada da geçerli: yenilgi kervanın sonu değildir; düşen
## karakterler ölmez, 1 canla ayağa kaldırılır (bkz. CaravanState clamp'leri).

signal log_added(line)  # String
signal state_changed(new_state)  # State
signal turn_started(unit)  # CombatUnit

enum State {
	ONGOING,
	VICTORY,
	DEFEAT,
}

const MAX_SIDE_SIZE: int = 4
const CRIT_MULTIPLIER: float = 1.5
const MIN_HIT_CHANCE: int = 5
const MAX_HIT_CHANCE: int = 95

## Kırılma noktasını aşmış (CombatUnit.is_stressed) bir savaşçının, sırası
## geldiğinde emirlere kulak asmama ihtimali - DD'deki "irrasyonel"
## davranışın en sade hâli: hamle yapamaz, sırası boşa gider.
const STRESS_REFUSAL_CHANCE: int = 20

var state: State = State.ONGOING
var round_number: int = 1
var player_units: Array[CombatUnit] = []
var enemy_units: Array[CombatUnit] = []

var _order: Array[CombatUnit] = []
var _order_index: int = 0
var _rng: RandomNumberGenerator

func _init(party: Array[CombatUnit], enemies: Array[CombatUnit], rng: RandomNumberGenerator = null) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		_rng.randomize()

	player_units = party.slice(0, MAX_SIDE_SIZE)
	enemy_units = enemies.slice(0, MAX_SIDE_SIZE)
	_repack(player_units)
	_repack(enemy_units)
	_build_order()

## Savaşı başlatır ve sıra düşmandaysa onların hamlelerini işler; sıra
## oyuncuya gelince durur.
func start() -> void:
	_emit_log("Haydutlar yolu kesti! %d kişilik kadron karşılarında." % player_units.size())
	_run_until_player_turn()

func get_active_unit() -> CombatUnit:
	if _order.is_empty():
		return null
	return _order[_order_index]

func is_over() -> bool:
	return state != State.ONGOING

func is_player_turn() -> bool:
	var unit := get_active_unit()
	return not is_over() and unit != null and unit.is_player_side

## Bir yeteneğin şu an vurabileceği hedefler. Ölüler ve menzil dışındaki
## mevkiler elenir.
func get_valid_targets(unit: CombatUnit, skill: CombatSkill) -> Array[CombatUnit]:
	var targets: Array[CombatUnit] = []
	if not unit.can_use_skill(skill):
		return targets

	match skill.target_kind:
		CombatSkill.Target.SELF:
			targets.append(unit)
		CombatSkill.Target.ALLY:
			for candidate in _side_of(unit):
				if candidate.is_alive() and skill.can_reach(candidate.position):
					targets.append(candidate)
		_:
			for candidate in _opposing_side(unit):
				if candidate.is_alive() and skill.can_reach(candidate.position):
					targets.append(candidate)
	return targets

## Oyuncunun hamlesi. Geçersiz hamlede false döner ve sıra ilerlemez.
func use_skill(skill: CombatSkill, target: CombatUnit) -> bool:
	var unit := get_active_unit()
	if is_over() or unit == null or not unit.can_use_skill(skill):
		return false
	if target == null or not get_valid_targets(unit, skill).has(target):
		return false

	_resolve_skill(unit, skill, target)
	unit.start_cooldown(skill)
	_after_action()
	return true

## Sırayı harcayarak iki yoldaşın yerini değiştirir - mevki kilidine
## takılan bir kadro böyle toparlanır.
func swap_player_positions(first: CombatUnit, second: CombatUnit) -> bool:
	var unit := get_active_unit()
	if is_over() or unit == null or not unit.is_player_side:
		return false
	if first == null or second == null or first == second:
		return false
	if not player_units.has(first) or not player_units.has(second):
		return false

	var temp := first.position
	first.position = second.position
	second.position = temp
	player_units.sort_custom(func(a, b): return a.position < b.position)
	_emit_log("%s ile %s yer değiştirdi." % [first.display_name, second.display_name])
	_after_action()
	return true

## Savaş bittiğinde canları asıl karakterlere yazar; düşenler 1 canla
## ayağa kalkar - kervan yok olmaz.
func write_back_party() -> void:
	for unit in player_units:
		if unit.current_hp <= 0:
			unit.current_hp = 1
		unit.write_back()

func get_downed_count() -> int:
	var downed := 0
	for unit in player_units:
		if not unit.is_alive():
			downed += 1
	return downed

# --- İç işleyiş ---

func _after_action() -> void:
	if _check_end():
		return
	_advance_turn()
	_run_until_player_turn()

func _run_until_player_turn() -> void:
	while not is_over():
		var unit := get_active_unit()
		if unit == null:
			return

		if is_player_turn():
			if not _try_refuse_order(unit):
				break
			_advance_turn()
			continue

		_run_enemy_turn(unit)
		if _check_end():
			return
		_advance_turn()

	if not is_over():
		turn_started.emit(get_active_unit())

## Stresten kırılmış bir savaşçı sırası geldiğinde emre kulak asmayabilir -
## sırası tamamen boşa gider, oyuncuya hiçbir seçenek sunulmaz. true
## dönerse tur zaten tüketildi, çağıran _advance_turn()'e geçmeli.
func _try_refuse_order(unit: CombatUnit) -> bool:
	if not unit.is_stressed:
		return false
	if _rng.randi_range(1, 100) > STRESS_REFUSAL_CHANCE:
		return false
	_emit_log("%s emirlere kulak asmıyor." % unit.display_name)
	return true

func _run_enemy_turn(unit: CombatUnit) -> void:
	var choice := _pick_enemy_action(unit)
	if choice.is_empty():
		_emit_log("%s hizasını düzeltiyor." % unit.display_name)
		_shuffle_forward(unit)
		return
	var skill: CombatSkill = choice.skill
	var target: CombatUnit = choice.target
	_resolve_skill(unit, skill, target)
	unit.start_cooldown(skill)

## En zayıf ulaşılabilir hedefi seçer - haydutlar yaralıyı bitirmeye çalışır.
func _pick_enemy_action(unit: CombatUnit) -> Dictionary:
	for skill in unit.skills:
		var targets := get_valid_targets(unit, skill)
		if targets.is_empty():
			continue
		var best: CombatUnit = targets[0]
		for candidate in targets:
			if candidate.current_hp < best.current_hp:
				best = candidate
		return {"skill": skill, "target": best}
	return {}

## Mevki kilidine takılan düşman bir sıra öne geçer.
func _shuffle_forward(unit: CombatUnit) -> void:
	var side := _side_of(unit)
	var index := side.find(unit)
	if index <= 0:
		return
	var ahead := side[index - 1]
	var temp := unit.position
	unit.position = ahead.position
	ahead.position = temp
	side.sort_custom(func(a, b): return a.position < b.position)

func _resolve_skill(unit: CombatUnit, skill: CombatSkill, target: CombatUnit) -> void:
	if skill.is_heal():
		var healed := _roll_heal(unit, skill)
		target.apply_heal(healed)
		_apply_skill_modifier(skill, target)
		_emit_log("%s, %s yeteneğiyle %s'in %d canını sardı." % [
			unit.display_name, skill.display_name, target.display_name, healed
		])
		return

	## Saf değiştirici (hasarsız, iyileştirmesiz buff/debuff) isabet
	## atmadan doğrudan uygulanır - kendine/yoldaşa şans devreye girmez.
	if skill.target_kind != CombatSkill.Target.ENEMY and skill.base_damage == 0:
		_apply_skill_modifier(skill, target)
		_emit_log("%s, %s yeteneğini kullandı." % [unit.display_name, skill.display_name])
		return

	var hit_chance := clampi(
		unit.get_effective_accuracy() + skill.accuracy_bonus - target.get_effective_dodge(),
		MIN_HIT_CHANCE,
		MAX_HIT_CHANCE
	)
	if _rng.randi_range(1, 100) > hit_chance:
		_emit_log("%s ıskaladı (%s)." % [unit.display_name, skill.display_name])
		return

	var is_crit := _rng.randi_range(1, 100) <= unit.crit_chance + skill.crit_bonus
	var damage := _roll_damage(unit, skill, is_crit)
	target.apply_damage(damage)
	_apply_skill_modifier(skill, target)

	if is_crit:
		_emit_log("KRİTİK! %s, %s ile %s'e %d hasar verdi." % [
			unit.display_name, skill.display_name, target.display_name, damage
		])
	else:
		_emit_log("%s, %s ile %s'e %d hasar verdi." % [
			unit.display_name, skill.display_name, target.display_name, damage
		])

	if not target.is_alive():
		if target.is_player_side:
			_emit_log("%s yere yığıldı." % target.display_name)
		else:
			_emit_log("%s devrildi." % target.display_name)
		_repack(_side_of(target))

func _apply_skill_modifier(skill: CombatSkill, target: CombatUnit) -> void:
	if skill.has_modifier():
		target.apply_modifier(skill.modifier_stat, skill.modifier_amount, skill.modifier_rounds)

func _roll_damage(unit: CombatUnit, skill: CombatSkill, is_crit: bool) -> int:
	var variance := _rng.randi_range(-skill.damage_variance, skill.damage_variance)
	var scaling := unit.support_power if skill.scales_with_support else unit.get_effective_damage_bonus()
	var raw := (
		float(skill.base_damage + variance + scaling)
		* unit.damage_multiplier
		* unit.get_proficiency_multiplier(skill.skill_id)
	)
	if is_crit:
		raw *= CRIT_MULTIPLIER
	return maxi(1, int(round(raw)))

func _roll_heal(unit: CombatUnit, skill: CombatSkill) -> int:
	var variance := _rng.randi_range(-skill.damage_variance, skill.damage_variance)
	var base := skill.heal_amount + variance + int(unit.support_power / 2.0)
	return maxi(1, int(round(float(base) * unit.get_proficiency_multiplier(skill.skill_id))))

func _build_order() -> void:
	_order.clear()
	_order.append_array(player_units)
	_order.append_array(enemy_units)
	_order.sort_custom(func(a, b): return a.initiative > b.initiative)
	_order_index = 0
	if not _order.is_empty() and not _order[0].is_alive():
		_advance_turn()

func _advance_turn() -> void:
	if _order.is_empty():
		return
	for _step in _order.size() + 1:
		_order_index += 1
		if _order_index >= _order.size():
			_order_index = 0
			round_number += 1
			for unit in _order:
				unit.tick_cooldowns()
				unit.tick_modifiers()
		if _order[_order_index].is_alive():
			return

func _check_end() -> bool:
	if is_over():
		return true
	if not _any_alive(enemy_units):
		state = State.VICTORY
		_emit_log("Haydutlar dağıldı. Yol yeniden senin.")
		state_changed.emit(state)
		return true
	if not _any_alive(player_units):
		state = State.DEFEAT
		_emit_log("Kadron yere serildi; haydutlar kervana daldı.")
		state_changed.emit(state)
		return true
	return false

func _any_alive(units: Array[CombatUnit]) -> bool:
	for unit in units:
		if unit.is_alive():
			return true
	return false

func _side_of(unit: CombatUnit) -> Array[CombatUnit]:
	return player_units if unit.is_player_side else enemy_units

func _opposing_side(unit: CombatUnit) -> Array[CombatUnit]:
	return enemy_units if unit.is_player_side else player_units

## Ölenler saftan düşer, hayatta kalanlar öne kayar - mevki kilidi
## anlamını korusun diye.
func _repack(units: Array[CombatUnit]) -> void:
	units.sort_custom(func(a, b): return a.position < b.position)
	var next_position := 1
	for unit in units:
		if unit.is_alive():
			unit.position = next_position
			next_position += 1
	for unit in units:
		if not unit.is_alive():
			unit.position = next_position
			next_position += 1

func _emit_log(line: String) -> void:
	log_added.emit(line)
