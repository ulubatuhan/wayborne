class_name SkillCatalog
extends RefCounted

## Yetenek tablosu. Hem oyuncu sınıfları hem düşmanlar buradan okur, böylece
## bir yeteneğin sayıları tek yerde durur.
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. ItemCatalog deseni).

# Oyuncu yetenekleri
const SHIELD_BASH: String = "shield_bash"
const SPEAR_THRUST: String = "spear_thrust"
const SLING_SHOT: String = "sling_shot"
const RALLY: String = "rally"

# Düşman yetenekleri
const CLEAVER: String = "bandit_cleave"
const BANDIT_ARROW: String = "bandit_arrow"
const BANDIT_ORDER: String = "bandit_order"

static var _skills: Array[CombatSkill] = []
static var _skill_by_id: Dictionary = {}

static func get_skill(skill_id: String) -> CombatSkill:
	_ensure_built()
	return _skill_by_id.get(skill_id)

## Kimliklerden yetenek listesi kurar; bilinmeyen kimlikleri sessizce atlar.
static func get_skills(skill_ids: Array[String]) -> Array[CombatSkill]:
	var skills: Array[CombatSkill] = []
	for skill_id in skill_ids:
		var skill := get_skill(skill_id)
		if skill != null:
			skills.append(skill)
	return skills

static func _ensure_built() -> void:
	if not _skills.is_empty():
		return

	_skills.append(CombatSkill.make_attack(
		SHIELD_BASH,
		"Kalkan Darbesi",
		"Öndeki düşmanı kalkanla iter; isabetli ama vuruşu hafiftir.",
		[1, 2], [1, 2],
		6, 2, 10, 0
	))

	_skills.append(CombatSkill.make_attack(
		SPEAR_THRUST,
		"Mızrak Saplaması",
		"Uzun mızrakla ikinci sıraya kadar uzanır.",
		[1, 2, 3], [1, 2, 3],
		9, 3, 0, 3
	))

	_skills.append(CombatSkill.make_attack(
		SLING_SHOT,
		"Sapan Atışı",
		"Arkadan atılan taş, düşmanın arka saflarını bulur.",
		[3, 4], [2, 3, 4],
		7, 4, -5, 5
	))

	var rally := CombatSkill.new()
	rally.skill_id = RALLY
	rally.display_name = "Toparlan"
	rally.description = "Bir yoldaşının yarasını sarar. İki turda bir kullanılabilir."
	rally.target_kind = CombatSkill.Target.ALLY
	rally.usable_positions = CombatSkill.to_position_array([2, 3, 4])
	rally.target_positions = CombatSkill.to_position_array([1, 2, 3, 4])
	rally.heal_amount = 8
	rally.damage_variance = 2
	rally.cooldown_rounds = 2
	rally.scales_with_support = true
	_skills.append(rally)

	_skills.append(CombatSkill.make_attack(
		CLEAVER,
		"Satır Savurması",
		"Haydut satırını öndeki hedefe indirir.",
		[1, 2], [1, 2],
		8, 3, 0, 3
	))

	_skills.append(CombatSkill.make_attack(
		BANDIT_ARROW,
		"Kısa Yay",
		"Arkadan atılan ok, en zayıf halkayı arar.",
		[2, 3, 4], [1, 2, 3, 4],
		6, 3, 5, 5
	))

	_skills.append(CombatSkill.make_attack(
		BANDIT_ORDER,
		"Reisin Emri",
		"Reis sopasını sallayarak öne saldırır.",
		[1, 2, 3], [1, 2],
		11, 4, 5, 5
	))

	for skill in _skills:
		_skill_by_id[skill.skill_id] = skill
