class_name CombatSkill
extends Resource

## Darkest Dungeon tarzı mevki kilitli yetenek: hem kullanıcının hangi
## sırada durması gerektiğini hem de hangi sıradaki hedefe ulaşabildiğini
## taşır. Mevkiler 1..4 arasıdır; 1 en önde, 4 en arkada.

enum Target {
	ENEMY,
	ALLY,
	SELF,
}

@export var skill_id: String = ""
@export var display_name: String = ""
@export var description: String = ""

@export var target_kind: Target = Target.ENEMY

## Yeteneği kullanabilmek için gereken kendi mevkiler.
@export var usable_positions: Array[int] = [1, 2, 3, 4]
## Ulaşılabilen hedef mevkileri.
@export var target_positions: Array[int] = [1, 2, 3, 4]

@export var base_damage: int = 0
## Hasara eklenen rastgele aralık: [-variance, +variance].
@export var damage_variance: int = 0
@export var heal_amount: int = 0

@export var accuracy_bonus: int = 0
@export var crit_bonus: int = 0

## Kaç tur beklemesi gerektiği. 0 = her tur kullanılabilir.
@export var cooldown_rounds: int = 0

## Açık ise hasar/iyileştirme Güç yerine Zeka'dan ölçeklenir.
@export var scales_with_support: bool = false

func can_use_from(position: int) -> bool:
	return position in usable_positions

func can_reach(position: int) -> bool:
	return position in target_positions

func is_heal() -> bool:
	return heal_amount > 0

## "Mevki 1-2 · Hedef 1-2" gibi tek satırlık özet - buton ipucunda gösterilir.
func get_position_summary() -> String:
	return "Mevki %s · Hedef %s" % [
		_format_positions(usable_positions),
		_format_positions(target_positions),
	]

func _format_positions(positions: Array[int]) -> String:
	var parts: Array[String] = []
	for position in positions:
		parts.append(str(position))
	return "-".join(parts)

## Mevki listeleri düz Array olarak alınır ve içeride Array[int]'e
## çevrilir - çağrı yerinde köşeli parantezle yazmak kolay olsun diye.
static func to_position_array(values: Array) -> Array[int]:
	var positions: Array[int] = []
	for value in values:
		positions.append(int(value))
	return positions

static func make_attack(
	skill_id: String, display_name: String, description: String,
	usable_positions: Array, target_positions: Array,
	base_damage: int, damage_variance: int,
	accuracy_bonus: int = 0, crit_bonus: int = 0, cooldown_rounds: int = 0
) -> CombatSkill:
	var skill := CombatSkill.new()
	skill.skill_id = skill_id
	skill.display_name = display_name
	skill.description = description
	skill.target_kind = Target.ENEMY
	skill.usable_positions = to_position_array(usable_positions)
	skill.target_positions = to_position_array(target_positions)
	skill.base_damage = base_damage
	skill.damage_variance = damage_variance
	skill.accuracy_bonus = accuracy_bonus
	skill.crit_bonus = crit_bonus
	skill.cooldown_rounds = cooldown_rounds
	return skill
