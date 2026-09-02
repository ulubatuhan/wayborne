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

## skill_id -> 0-100 arası yetkinlik. Yalnızca oyuncu tarafında anlamlı;
## hasar/iyileştirmeyi ve bekleme süresini kademeli iyileştirir.
var skill_proficiency: Dictionary = {}

## Süreli stat değiştiriciler: her biri {"stat": "accuracy"/"dodge"/"damage",
## "amount": int, "rounds_left": int}. Tek yeni mekanik burada yaşıyor.
var _timed_modifiers: Array = []

## Yalnızca düşman tarafında anlamlı: yenilince oyuncuya verilen XP.
var xp_value: int = 0

## Yalnızca oyuncu tarafında dolu; savaş sonunda canı buraya yazarız.
var source_character: CharacterData = null

static func from_character(character: CharacterData, position: int) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.display_name = character.character_name
	unit.is_player_side = true
	unit.position = position
	unit.max_hp = character.get_max_hp()
	unit.current_hp = clampi(character.current_hp, 0, unit.max_hp)
	unit.accuracy = character.get_accuracy()
	unit.dodge = character.get_dodge()
	unit.crit_chance = character.get_crit_chance()
	unit.damage_bonus = character.get_damage_bonus()
	unit.support_power = character.stats.get_support_power()
	unit.initiative = character.stats.get_initiative()
	unit.damage_multiplier = character.get_culture().combat_damage_multiplier
	unit.skills = character.get_skills()
	unit.skill_proficiency = character.skill_proficiency.duplicate()
	unit.source_character = character
	return unit

## power_scale düşman istatistiklerini toptan büyütür/küçültür - ortalama
## parti seviyesine göre ölçeklenir, EnemyTemplate'in kendisi hiç değişmez.
static func from_enemy(template: EnemyTemplate, position: int, power_scale: float = 1.0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.display_name = template.display_name
	unit.is_player_side = false
	unit.position = position
	unit.max_hp = maxi(1, int(round(template.max_hp * power_scale)))
	unit.current_hp = unit.max_hp
	unit.accuracy = template.accuracy
	unit.dodge = template.dodge
	unit.crit_chance = template.crit_chance
	unit.damage_bonus = maxi(0, int(round(template.damage_bonus * power_scale)))
	unit.initiative = template.initiative
	unit.skills = SkillCatalog.get_skills(template.skill_ids)
	unit.xp_value = template.xp_value
	return unit

func is_alive() -> bool:
	return current_hp > 0

func apply_damage(amount: int) -> void:
	current_hp = clampi(current_hp - amount, 0, max_hp)

func apply_heal(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp)

func get_cooldown(skill_id: String) -> int:
	return int(_cooldowns.get(skill_id, 0))

## Yetkinlik bekleme süresini kısaltır: her 25 puan bir tur düşürür,
## Metin2 tarzı sürekli yatırımın savaşta hissedilmesi için.
func start_cooldown(skill: CombatSkill) -> void:
	if skill.cooldown_rounds <= 0:
		return
	var reduction := int(get_skill_proficiency(skill.skill_id) / 25)
	var reduced := maxi(0, skill.cooldown_rounds - reduction)
	if reduced > 0:
		_cooldowns[skill.skill_id] = reduced

func tick_cooldowns() -> void:
	for skill_id in _cooldowns.keys():
		var remaining := int(_cooldowns[skill_id]) - 1
		if remaining <= 0:
			_cooldowns.erase(skill_id)
		else:
			_cooldowns[skill_id] = remaining

func get_skill_proficiency(skill_id: String) -> int:
	return int(skill_proficiency.get(skill_id, 0))

## 0-100 yetkinlik hasarı/iyileştirmeyi %0'dan %50'ye kadar büyütür.
func get_proficiency_multiplier(skill_id: String) -> float:
	return 1.0 + float(get_skill_proficiency(skill_id)) / 200.0

func apply_modifier(stat: String, amount: int, rounds: int) -> void:
	if rounds <= 0 or amount == 0:
		return
	_timed_modifiers.append({"stat": stat, "amount": amount, "rounds_left": rounds})

func tick_modifiers() -> void:
	var kept: Array = []
	for modifier in _timed_modifiers:
		var remaining: int = int(modifier.rounds_left) - 1
		if remaining > 0:
			kept.append({"stat": modifier.stat, "amount": modifier.amount, "rounds_left": remaining})
	_timed_modifiers = kept

func _modifier_sum(stat: String) -> int:
	var total := 0
	for modifier in _timed_modifiers:
		if modifier.stat == stat:
			total += int(modifier.amount)
	return total

func get_effective_accuracy() -> int:
	return accuracy + _modifier_sum("accuracy")

func get_effective_dodge() -> int:
	return maxi(0, dodge + _modifier_sum("dodge"))

func get_effective_damage_bonus() -> int:
	return damage_bonus + _modifier_sum("damage")

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
