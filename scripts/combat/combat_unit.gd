class_name CombatUnit
extends RefCounted

## Savaş alanındaki tek bir savaşçı. Oyuncu tarafında bir CharacterData'yı
## sarmalar (can savaş bitince ona geri yazılır), düşman tarafında
## EnemyTemplate'ten kurulur. Savaş motoru yalnızca bu tipi tanır.

var display_name: String = ""
var is_player_side: bool = false
## 1 en önde, 4 en arkada.
var position: int = 1

var max_hp: int = 10
var current_hp: int = 10

var accuracy: int = 70
var dodge: int = 0
var crit_chance: int = 5
var damage_bonus: int = 0
var support_power: int = 0
var initiative: int = 5
var damage_multiplier: float = 1.0

var skills: Array[CombatSkill] = []

## skill_id -> kaç tur daha bekleyeceği.
var _cooldowns: Dictionary = {}

## Yalnızca oyuncu tarafında dolu; savaş sonunda canı buraya yazarız.
var source_character: CharacterData = null

static func from_character(character: CharacterData, position: int) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.display_name = character.character_name
	unit.is_player_side = true
	unit.position = position
	unit.max_hp = character.get_max_hp()
	unit.current_hp = clampi(character.current_hp, 0, unit.max_hp)
	unit.accuracy = character.stats.get_accuracy()
	unit.dodge = character.get_dodge()
	unit.crit_chance = character.stats.get_crit_chance()
	unit.damage_bonus = character.stats.get_damage_bonus()
	unit.support_power = character.stats.get_support_power()
	unit.initiative = character.stats.get_initiative()
	unit.damage_multiplier = character.get_culture().combat_damage_multiplier
	unit.skills = character.get_skills()
	unit.source_character = character
	return unit

static func from_enemy(template: EnemyTemplate, position: int) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.display_name = template.display_name
	unit.is_player_side = false
	unit.position = position
	unit.max_hp = template.max_hp
	unit.current_hp = template.max_hp
	unit.accuracy = template.accuracy
	unit.dodge = template.dodge
	unit.crit_chance = template.crit_chance
	unit.damage_bonus = template.damage_bonus
	unit.initiative = template.initiative
	unit.skills = SkillCatalog.get_skills(template.skill_ids)
	return unit

func is_alive() -> bool:
	return current_hp > 0

func apply_damage(amount: int) -> void:
	current_hp = clampi(current_hp - amount, 0, max_hp)

func apply_heal(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp)

func get_cooldown(skill_id: String) -> int:
	return int(_cooldowns.get(skill_id, 0))

func start_cooldown(skill: CombatSkill) -> void:
	if skill.cooldown_rounds > 0:
		_cooldowns[skill.skill_id] = skill.cooldown_rounds

func tick_cooldowns() -> void:
	for skill_id in _cooldowns.keys():
		var remaining := int(_cooldowns[skill_id]) - 1
		if remaining <= 0:
			_cooldowns.erase(skill_id)
		else:
			_cooldowns[skill_id] = remaining

## Yetenek şu an kullanılabilir mi; kullanılamıyorsa neden - UI kilitli
## butonu sebebiyle birlikte gösterir (bkz. olay ekranındaki kilitli
## seçenekler).
func get_skill_block_reason(skill: CombatSkill) -> String:
	if not skill.can_use_from(position):
		return "%d. mevkiden kullanılamaz" % position
	var remaining := get_cooldown(skill.skill_id)
	if remaining > 0:
		return "%d tur bekliyor" % remaining
	return ""

func can_use_skill(skill: CombatSkill) -> bool:
	return get_skill_block_reason(skill).is_empty()

## Savaş bittiğinde canı asıl karaktere geri yazar.
func write_back() -> void:
	if source_character != null:
		source_character.current_hp = current_hp
