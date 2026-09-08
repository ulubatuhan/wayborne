class_name EnemyTemplate
extends Resource

## Bir düşman türünün sayıları. CombatUnit.from_enemy() bunu savaş
## alanındaki bir savaşçıya çevirir.

@export var enemy_id: String = ""
## Saklanan sey ceviri anahtari (bkz. data/locale/game.csv); gosterilen
## metin asagidaki hesaplanan ozelliklerden okunur. Bu ayrim sayesinde
## bu alanlari okuyan ekranlarin hicbiri degismeden cevrilebilir oldu
## - bkz. CLAUDE.md Localization Rules.
@export var display_name_key: String = ""

var display_name: String:
	get: return tr(display_name_key)


@export var max_hp: int = 20
@export var accuracy: int = 75
@export var dodge: int = 4
@export var crit_chance: int = 4
@export var damage_bonus: int = 2
@export var initiative: int = 8

@export var skill_ids: Array[String] = []

## Yenilince partiye kazandırdığı tecrübe (bkz. CombatPanel.combat_finished).
@export var xp_value: int = 10

## Düşmanın tercih ettiği mevkiler; sıra kurulurken öne mi arkaya mı
## yerleşeceğini belirler (küçük sayı = önde).
@export var preferred_position: int = 1
