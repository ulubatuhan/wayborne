class_name CharacterStats
extends RefCounted

## Altı temel stat ve bunlardan türeyen savaş/yol değerleri. UI'dan
## bağımsız: sahne ağacı gerektirmez, doğrudan örneklenip test edilebilir.
##
## Türetilmiş değerler tek yerde durur - hem karakter ekranı hem savaş
## motoru buradan okur, formül iki yere kopyalanmaz.

const BASE_VALUE: int = 5
const MIN_VALUE: int = 1
const MAX_VALUE: int = 10

enum Kind {
	STRENGTH,
	AGILITY,
	ENDURANCE,
	INTELLECT,
	PERCEPTION,
	CHARISMA,
}

const KIND_ORDER: Array[Kind] = [
	Kind.STRENGTH,
	Kind.AGILITY,
	Kind.ENDURANCE,
	Kind.INTELLECT,
	Kind.PERCEPTION,
	Kind.CHARISMA,
]

var strength: int = BASE_VALUE
var agility: int = BASE_VALUE
var endurance: int = BASE_VALUE
var intellect: int = BASE_VALUE
var perception: int = BASE_VALUE
var charisma: int = BASE_VALUE

static func kind_name(kind: Kind) -> String:
	match kind:
		Kind.STRENGTH:
			return "Güç"
		Kind.AGILITY:
			return "Çeviklik"
		Kind.ENDURANCE:
			return "Dayanıklılık"
		Kind.INTELLECT:
			return "Zeka"
		Kind.PERCEPTION:
			return "Sezgi"
		Kind.CHARISMA:
			return "Karizma"
	return "?"

## Statın oyunda ne işe yaradığı - karakter ekranında gösterilir.
static func kind_description(kind: Kind) -> String:
	match kind:
		Kind.STRENGTH:
			return "Yakın dövüş hasarı"
		Kind.AGILITY:
			return "İnisiyatif ve kaçınma"
		Kind.ENDURANCE:
			return "Can puanı"
		Kind.INTELLECT:
			return "Yardım/iyileştirme gücü"
		Kind.PERCEPTION:
			return "İsabet ve kritik"
		Kind.CHARISMA:
			return "Pazarlık ve tayfa ücreti"
	return ""

func get_value(kind: Kind) -> int:
	match kind:
		Kind.STRENGTH:
			return strength
		Kind.AGILITY:
			return agility
		Kind.ENDURANCE:
			return endurance
		Kind.INTELLECT:
			return intellect
		Kind.PERCEPTION:
			return perception
		Kind.CHARISMA:
			return charisma
	return 0

func set_value(kind: Kind, value: int) -> void:
	var clamped := clampi(value, MIN_VALUE, MAX_VALUE)
	match kind:
		Kind.STRENGTH:
			strength = clamped
		Kind.AGILITY:
			agility = clamped
		Kind.ENDURANCE:
			endurance = clamped
		Kind.INTELLECT:
			intellect = clamped
		Kind.PERCEPTION:
			perception = clamped
		Kind.CHARISMA:
			charisma = clamped

func add_value(kind: Kind, delta: int) -> void:
	set_value(kind, get_value(kind) + delta)

func copy() -> CharacterStats:
	var copied := CharacterStats.new()
	for kind in KIND_ORDER:
		copied.set_value(kind, get_value(kind))
	return copied

# --- Türetilmiş değerler ---

func get_max_hp() -> int:
	return 20 + endurance * 4

func get_initiative() -> int:
	return 5 + agility

func get_accuracy() -> int:
	return 70 + perception * 2

func get_dodge() -> int:
	return agility * 2

func get_crit_chance() -> int:
	return 2 + perception

func get_damage_bonus() -> int:
	return strength

func get_support_power() -> int:
	return intellect

func to_dict() -> Dictionary:
	return {
		"strength": strength,
		"agility": agility,
		"endurance": endurance,
		"intellect": intellect,
		"perception": perception,
		"charisma": charisma,
	}

static func from_dict(data: Dictionary) -> CharacterStats:
	var stats := CharacterStats.new()
	stats.strength = int(data.get("strength", BASE_VALUE))
	stats.agility = int(data.get("agility", BASE_VALUE))
	stats.endurance = int(data.get("endurance", BASE_VALUE))
	stats.intellect = int(data.get("intellect", BASE_VALUE))
	stats.perception = int(data.get("perception", BASE_VALUE))
	stats.charisma = int(data.get("charisma", BASE_VALUE))
	return stats
