class_name EnemyTemplate
extends Resource

## Bir düşman türünün sayıları. CombatUnit.from_enemy() bunu savaş
## alanındaki bir savaşçıya çevirir.

@export var enemy_id: String = ""
@export var display_name: String = ""

@export var max_hp: int = 20
@export var accuracy: int = 75
@export var dodge: int = 4
@export var crit_chance: int = 4
@export var damage_bonus: int = 2
@export var initiative: int = 8

@export var skill_ids: Array[String] = []

## Düşmanın tercih ettiği mevkiler; sıra kurulurken öne mi arkaya mı
## yerleşeceğini belirler (küçük sayı = önde).
@export var preferred_position: int = 1
