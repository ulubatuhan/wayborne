class_name TraitCatalog
extends RefCounted

## Huy tablosu: altı stata karşılık gelen bir olumlu, bir olumsuz huy -
## on iki huy. Seed dağıtımı (roll_seed_trait) karakterin statlarıyla
## orantılı ağırlıklanır; olay sonuçları (GRANT_TRAIT) belirli bir huyu
## doğrudan verir.
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. ItemCatalog deseni).

const MIGHTY_ARM: String = "mighty_arm"
const WEAK_ARM: String = "weak_arm"
const NIMBLE_STEP: String = "nimble_step"
const CLUMSY_FOOT: String = "clumsy_foot"
const IRON_CONSTITUTION: String = "iron_constitution"
const FRAIL_CONSTITUTION: String = "frail_constitution"
const PRUDENT: String = "prudent"
const NAIVE: String = "naive"
const SHARP_EYE: String = "sharp_eye"
const NEARSIGHTED: String = "nearsighted"
const REASSURING: String = "reassuring"
const OFF_PUTTING: String = "off_putting"

static var _traits: Array[Trait] = []
static var _trait_by_id: Dictionary = {}

static func get_traits() -> Array[Trait]:
	_ensure_built()
	return _traits

static func get_trait(trait_id: String) -> Trait:
	_ensure_built()
	return _trait_by_id.get(trait_id)

## Statlarla orantılı, ağırlıklı rastgele seçim: bir stat taban üstündeyse
## o statın olumlu huyu, altındaysa olumsuzu ağırlık kazanır. Hiçbir stat
## öne çıkmıyorsa (hepsi taban) on iki huy eşit ihtimalli kalır - "basic
## seviye" burada kendini gösteriyor, aşırı statlar aşırı huy demek değil.
static func roll_seed_trait(stats: CharacterStats, rng: RandomNumberGenerator) -> String:
	_ensure_built()
	if _traits.is_empty():
		return ""

	var weights: Array[float] = []
	var total := 0.0
	for candidate in _traits:
		var effective := stats.get_effective_value(candidate.affinity_stat)
		var lean := effective if candidate.is_positive else -effective
		var weight := maxf(0.5, 1.0 + lean)
		weights.append(weight)
		total += weight

	var roll := rng.randf() * total
	var cursor := 0.0
	for i in _traits.size():
		cursor += weights[i]
		if roll <= cursor:
			return _traits[i].trait_id
	return _traits[_traits.size() - 1].trait_id

static func _ensure_built() -> void:
	if not _traits.is_empty():
		return

	_traits.append(_make(
		MIGHTY_ARM, "Pazı Gücü", "Kolundaki güç vuruşlarına yansır.",
		true, CharacterStats.Kind.STRENGTH, {"damage_bonus": 2}
	))
	_traits.append(_make(
		WEAK_ARM, "Cılız Kol", "Vuruşlarında beklenen ağırlık yok.",
		false, CharacterStats.Kind.STRENGTH, {"damage_bonus": -2}
	))
	_traits.append(_make(
		NIMBLE_STEP, "Çevik Adım", "Ayakları hep bir adım önde.",
		true, CharacterStats.Kind.AGILITY, {"dodge_bonus": 3}
	))
	_traits.append(_make(
		CLUMSY_FOOT, "Beceriksiz Ayak", "Kaçınması gereken yerde tökezler.",
		false, CharacterStats.Kind.AGILITY, {"dodge_bonus": -3}
	))
	_traits.append(_make(
		IRON_CONSTITUTION, "Demir Bünye", "Yaraya da açlığa da dayanıklı.",
		true, CharacterStats.Kind.ENDURANCE, {"hp_bonus": 4}
	))
	_traits.append(_make(
		FRAIL_CONSTITUTION, "Zayıf Bünye", "Küçük bir darbe bile ağır geçer.",
		false, CharacterStats.Kind.ENDURANCE, {"hp_bonus": -4}
	))
	_traits.append(_make(
		PRUDENT, "Basiretli", "Vurmadan önce düşünür, isabeti artar.",
		true, CharacterStats.Kind.INTELLECT, {"accuracy_bonus": 2}
	))
	_traits.append(_make(
		NAIVE, "Saf", "Sırası gelince kararsız kalır.",
		false, CharacterStats.Kind.INTELLECT, {"accuracy_bonus": -2}
	))
	_traits.append(_make(
		SHARP_EYE, "Keskin Göz", "Zayıf noktayı hep bulur.",
		true, CharacterStats.Kind.PERCEPTION, {"accuracy_bonus": 3, "crit_bonus": 1}
	))
	_traits.append(_make(
		NEARSIGHTED, "Miyop", "Uzaktaki hedefi hep ıskalar.",
		false, CharacterStats.Kind.PERCEPTION, {"accuracy_bonus": -3}
	))
	_traits.append(_make(
		REASSURING, "Güven Verici", "Yanındakiler onunla daha rahat savaşır.",
		true, CharacterStats.Kind.CHARISMA, {"dodge_bonus": 2}
	))
	_traits.append(_make(
		OFF_PUTTING, "İtici", "Yanındakiler tedirgin, saf biraz bozuk.",
		false, CharacterStats.Kind.CHARISMA, {"dodge_bonus": -2}
	))

	for trait_resource in _traits:
		_trait_by_id[trait_resource.trait_id] = trait_resource

static func _make(
	trait_id: String, display_name: String, description: String,
	is_positive: bool, affinity_stat: CharacterStats.Kind, bonuses: Dictionary
) -> Trait:
	var trait_resource := Trait.new()
	trait_resource.trait_id = trait_id
	trait_resource.display_name = display_name
	trait_resource.description = description
	trait_resource.is_positive = is_positive
	trait_resource.affinity_stat = affinity_stat
	trait_resource.hp_bonus = int(bonuses.get("hp_bonus", 0))
	trait_resource.dodge_bonus = int(bonuses.get("dodge_bonus", 0))
	trait_resource.accuracy_bonus = int(bonuses.get("accuracy_bonus", 0))
	trait_resource.crit_bonus = int(bonuses.get("crit_bonus", 0))
	trait_resource.damage_bonus = int(bonuses.get("damage_bonus", 0))
	return trait_resource
