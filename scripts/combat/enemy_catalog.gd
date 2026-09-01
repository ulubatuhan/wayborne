class_name EnemyCatalog
extends RefCounted

## Düşman tablosu ve pusu kadrosu kurucusu.
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. ItemCatalog deseni).

const CUTTER: String = "bandit_cutter"
const ARCHER: String = "bandit_archer"
const LEADER: String = "bandit_leader"

## Pusu kadrosu bu kadar savaşçıyı geçemez (savaş alanı 4 mevki).
const MAX_SQUAD_SIZE: int = 4

static var _enemies: Array[EnemyTemplate] = []
static var _enemy_by_id: Dictionary = {}

static func get_enemy(enemy_id: String) -> EnemyTemplate:
	_ensure_built()
	return _enemy_by_id.get(enemy_id)

## Tehlike seviyesine göre bir haydut kadrosu kurar (danger_level 0..1,
## GameSession ile aynı ölçek). Düşük tehlikede iki kesici, yükseldikçe
## okçu ve reis eklenir - yolun tehlikesi savaşta da hissedilsin diye.
##
## Kadro ayrıca partiden en fazla bir kişi fazla olabilir: tek başına yola
## çıkan bir oyuncu dört haydutla karşılaşmaz, ama hep de rahat etmez.
static func build_bandit_squad(
	danger_level: float, party_size: int, rng: RandomNumberGenerator
) -> Array[CombatUnit]:
	_ensure_built()

	var ids: Array[String] = [CUTTER, CUTTER]
	if danger_level >= 0.25:
		ids.append(ARCHER)
	if danger_level >= 0.55:
		ids.append(LEADER)
	elif danger_level >= 0.40 and rng.randf() < 0.5:
		ids.append(CUTTER)

	var templates: Array[EnemyTemplate] = []
	for enemy_id in ids:
		var template := get_enemy(enemy_id)
		if template != null:
			templates.append(template)
	templates.sort_custom(func(a, b): return a.preferred_position < b.preferred_position)

	var squad_size := mini(templates.size(), MAX_SQUAD_SIZE)
	squad_size = mini(squad_size, maxi(2, party_size + 1))

	var units: Array[CombatUnit] = []
	for index in squad_size:
		units.append(CombatUnit.from_enemy(templates[index], index + 1))
	return units

static func _ensure_built() -> void:
	if not _enemies.is_empty():
		return

	_enemies.append(_make(CUTTER, "Haydut Kesicisi", 24, 76, 5, 4, 3, 8, [SkillCatalog.CLEAVER], 1))
	_enemies.append(_make(ARCHER, "Haydut Okçusu", 18, 80, 8, 6, 2, 11, [SkillCatalog.BANDIT_ARROW], 3))
	_enemies.append(_make(
		LEADER, "Haydut Reisi", 34, 82, 6, 8, 5, 10,
		[SkillCatalog.BANDIT_ORDER, SkillCatalog.CLEAVER], 2
	))

	for enemy in _enemies:
		_enemy_by_id[enemy.enemy_id] = enemy

static func _make(
	enemy_id: String, display_name: String, max_hp: int, accuracy: int,
	dodge: int, crit_chance: int, damage_bonus: int, initiative: int,
	skill_ids: Array, preferred_position: int
) -> EnemyTemplate:
	var enemy := EnemyTemplate.new()
	enemy.enemy_id = enemy_id
	enemy.display_name = display_name
	enemy.max_hp = max_hp
	enemy.accuracy = accuracy
	enemy.dodge = dodge
	enemy.crit_chance = crit_chance
	enemy.damage_bonus = damage_bonus
	enemy.initiative = initiative
	var typed_skill_ids: Array[String] = []
	for skill_id in skill_ids:
		typed_skill_ids.append(skill_id)
	enemy.skill_ids = typed_skill_ids
	enemy.preferred_position = preferred_position
	return enemy
