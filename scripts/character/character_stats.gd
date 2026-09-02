class_name CharacterStats
extends RefCounted

## Altı temel stat ve bunlardan türeyen savaş/yol değerleri. UI'dan
## bağımsız: sahne ağacı gerektirmez, doğrudan örneklenip test edilebilir.
##
## Türetilmiş değerler tek yerde durur - hem karakter ekranı hem savaş
## motoru buradan okur, formül iki yere kopyalanmaz.

const BASE_VALUE: int = 5
const MIN_VALUE: int = 1
const MAX_VALUE: int = 15

## 10'a kadar statın her puanı tam değer katar; 10'un üstü yarı değerde -
## seviye atlayınca statı hep aynı yere yığmanın getirisi azalır. stat=5
## (başlangıç değeri) her zaman 0 döner, böylece türetilmiş formüller
## baseline'da değişmeden kalır.
static func effective_value(raw: int) -> float:
	return float(mini(raw, 10) - BASE_VALUE) + 0.5 * float(maxi(0, raw - 10))

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

func get_effective_value(kind: Kind) -> float:
	return effective_value(get_value(kind))

# --- Türetilmiş değerler ---
# Her formül baseline (stat=5, effective=0) sonucu + katsayı * effective(stat)
# biçiminde: 10'a kadar eski davranışla birebir aynı, 10 üstü yavaşlar.

func get_max_hp() -> int:
	return 40 + int(round(4.0 * get_effective_value(Kind.ENDURANCE)))

func get_initiative() -> int:
	return 10 + int(round(get_effective_value(Kind.AGILITY)))

func get_accuracy() -> int:
	return 80 + int(round(2.0 * get_effective_value(Kind.PERCEPTION)))

func get_dodge() -> int:
	return 10 + int(round(2.0 * get_effective_value(Kind.AGILITY)))

func get_crit_chance() -> int:
	return 7 + int(round(get_effective_value(Kind.PERCEPTION)))

func get_damage_bonus() -> int:
	return 5 + int(round(get_effective_value(Kind.STRENGTH)))

func get_support_power() -> int:
	return 5 + int(round(get_effective_value(Kind.INTELLECT)))

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
