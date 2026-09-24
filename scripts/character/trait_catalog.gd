class_name TraitCatalog
extends RefCounted

## Huy tablosu: sekiz stata karşılık gelen bir olumlu, bir olumsuz huy -
## on altı huy (Faz 17: Bilgelik/İnanç eklenince altı stat sekize çıktı,
## huy tablosu da aynı oranda büyüdü - "mevcut kefeyi genişlet" kuralı).
## Seed dağıtımı (roll_seed_trait) karakterin statlarıyla orantılı
## ağırlıklanır; olay sonuçları (GRANT_TRAIT) belirli bir huyu doğrudan
## verir.
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
const KEEN_MIND: String = "keen_mind"
const DULL_WIT: String = "dull_wit"
const STEADFAST_FAITH: String = "steadfast_faith"
const WAVERING_FAITH: String = "wavering_faith"

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
	return _weighted_pick(_traits, stats, rng)

## Stres kırılması: kutup (olumlu/olumsuz) zaten zar atılarak belirlenmiş
## oluyor (bkz. GameSession.resolve_stress_breaks) - burada yalnızca o
## kutuptaki huylar arasında, yine statlarla orantılı seçim yapılır.
static func roll_break_trait(stats: CharacterStats, rng: RandomNumberGenerator, want_positive: bool) -> String:
	_ensure_built()
	var pool: Array[Trait] = []
	for candidate in _traits:
		if candidate.is_positive == want_positive:
			pool.append(candidate)
	return _weighted_pick(pool, stats, rng)

static func _weighted_pick(pool: Array[Trait], stats: CharacterStats, rng: RandomNumberGenerator) -> String:
	if pool.is_empty():
		return ""

	var weights: Array[float] = []
	var total := 0.0
	for candidate in pool:
		var effective := stats.get_effective_value(candidate.affinity_stat)
		var lean := effective if candidate.is_positive else -effective
		var weight := maxf(0.5, 1.0 + lean)
		weights.append(weight)
		total += weight

	var roll := rng.randf() * total
	var cursor := 0.0
	for i in pool.size():
		cursor += weights[i]
		if roll <= cursor:
			return pool[i].trait_id
	return pool[pool.size() - 1].trait_id

static func _ensure_built() -> void:
	if not _traits.is_empty():
		return

	_traits.append(_make(
		MIGHTY_ARM, "TRAIT_MIGHTY_ARM_NAME", "TRAIT_MIGHTY_ARM_DESC",
		true, CharacterStats.Kind.STRENGTH, {"damage_bonus": 2}
	))
	_traits.append(_make(
		WEAK_ARM, "TRAIT_WEAK_ARM_NAME", "TRAIT_WEAK_ARM_DESC",
		false, CharacterStats.Kind.STRENGTH, {"damage_bonus": -2}
	))
	_traits.append(_make(
		NIMBLE_STEP, "TRAIT_NIMBLE_STEP_NAME", "TRAIT_NIMBLE_STEP_DESC",
		true, CharacterStats.Kind.AGILITY, {"dodge_bonus": 3}
	))
	_traits.append(_make(
		CLUMSY_FOOT, "TRAIT_CLUMSY_FOOT_NAME", "TRAIT_CLUMSY_FOOT_DESC",
		false, CharacterStats.Kind.AGILITY, {"dodge_bonus": -3}
	))
	# Dayanıklılık zaten get_stress_resistance()'ı doğrudan türetiyor - Iron/
	# Frail Constitution'ın kendi payı o formülün üstüne biniyor, aynı stat
	# iki sistemde de tutarlı bir dayanıklılık anlatıyor.
	_traits.append(_make(
		IRON_CONSTITUTION, "TRAIT_IRON_CONSTITUTION_NAME", "TRAIT_IRON_CONSTITUTION_DESC",
		true, CharacterStats.Kind.ENDURANCE, {"hp_bonus": 4, "stress_resistance_bonus": 5}
	))
	_traits.append(_make(
		FRAIL_CONSTITUTION, "TRAIT_FRAIL_CONSTITUTION_NAME", "TRAIT_FRAIL_CONSTITUTION_DESC",
		false, CharacterStats.Kind.ENDURANCE, {"hp_bonus": -4, "stress_resistance_bonus": -5}
	))
	# price_discount_percent: PR-3'ün üçüncü kancası - Basiretli pazarda da
	# keskin, Saf orada da kolay kandırılır (bkz. GameSession.
	# get_trait_price_multiplier()).
	_traits.append(_make(
		PRUDENT, "TRAIT_PRUDENT_NAME", "TRAIT_PRUDENT_DESC",
		true, CharacterStats.Kind.INTELLECT, {"accuracy_bonus": 2, "price_discount_percent": 3}
	))
	_traits.append(_make(
		NAIVE, "TRAIT_NAIVE_NAME", "TRAIT_NAIVE_DESC",
		false, CharacterStats.Kind.INTELLECT, {"accuracy_bonus": -2, "price_discount_percent": -3}
	))
	_traits.append(_make(
		SHARP_EYE, "TRAIT_SHARP_EYE_NAME", "TRAIT_SHARP_EYE_DESC",
		true, CharacterStats.Kind.PERCEPTION, {"accuracy_bonus": 3, "crit_bonus": 1}
	))
	_traits.append(_make(
		NEARSIGHTED, "TRAIT_NEARSIGHTED_NAME", "TRAIT_NEARSIGHTED_DESC",
		false, CharacterStats.Kind.PERCEPTION, {"accuracy_bonus": -3}
	))
	# morale_bonus: PR-3'ün ikinci kancası - "Güven Verici" adının kendisi
	# zaten bir moral vaadiydi, GameSession.get_departure_temperament_bonus()
	# artık bunu çıkış moraline de taşıyor.
	_traits.append(_make(
		REASSURING, "TRAIT_REASSURING_NAME", "TRAIT_REASSURING_DESC",
		true, CharacterStats.Kind.CHARISMA, {"dodge_bonus": 2, "morale_bonus": 3}
	))
	_traits.append(_make(
		OFF_PUTTING, "TRAIT_OFF_PUTTING_NAME", "TRAIT_OFF_PUTTING_DESC",
		false, CharacterStats.Kind.CHARISMA, {"dodge_bonus": -2, "morale_bonus": -3}
	))
	# Faz 17: Bilgelik'in huyu - tecrübeden çıkarılan ders kalıcılaşıyor,
	# CharacterData.get_xp_bonus_percent()'in stat payının üstüne biniyor.
	_traits.append(_make(
		KEEN_MIND, "TRAIT_KEEN_MIND_NAME", "TRAIT_KEEN_MIND_DESC",
		true, CharacterStats.Kind.WISDOM, {"xp_gain_bonus_percent": 8}
	))
	_traits.append(_make(
		DULL_WIT, "TRAIT_DULL_WIT_NAME", "TRAIT_DULL_WIT_DESC",
		false, CharacterStats.Kind.WISDOM, {"xp_gain_bonus_percent": -8}
	))
	# Faz 17: İnanç'ın huyu - Ölümün Kıyısı'nda hayata tutunma zarına ek pay,
	# CharacterData.get_deathblow_resist_bonus()'un stat payının üstüne biniyor.
	_traits.append(_make(
		STEADFAST_FAITH, "TRAIT_STEADFAST_FAITH_NAME", "TRAIT_STEADFAST_FAITH_DESC",
		true, CharacterStats.Kind.FAITH, {"deathblow_resist_bonus": 5}
	))
	_traits.append(_make(
		WAVERING_FAITH, "TRAIT_WAVERING_FAITH_NAME", "TRAIT_WAVERING_FAITH_DESC",
		false, CharacterStats.Kind.FAITH, {"deathblow_resist_bonus": -5}
	))

	for trait_resource in _traits:
		_trait_by_id[trait_resource.trait_id] = trait_resource

## `check_bonus`/`refusal_bonus` **her huyda**, `is_positive`'ten jenerik
## türetiliyor - Faz 17'nin skill-check'e (bkz. SkillCheck) ve emir reddine
## (bkz. CombatEncounter._try_refuse_order) bağladığı iki davranışsal kanca.
## Bir virtue kendi statının check'ini biraz kolaylaştırır ve zaten kırılmış
## bir karakteri biraz sakinleştirir; bir affliction tam tersini yapar - ikisi
## de küçük (bir huy tek başına hiçbir sistemi kazandırmaz/kapatmaz, aynı
## kural CharacterStats.get_composure()'ın MIN_STRESS_REFUSAL_CHANCE'ı hiç
## sıfırlamamasıyla aynı).
const CHECK_BONUS_MAGNITUDE: float = 0.5
const REFUSAL_BONUS_MAGNITUDE: int = 2

## Yalnızca Dayanıklılık'ın huyları `stress_resistance_bonus` dolduruyor -
## `bonuses` dict'inde yoksa iron_constitution/frail_constitution'ın
## kendi hp_bonus'unun yanına eklenir (bkz. aşağıdaki iki `_make` çağrısı).
static func _make(
	trait_id: String, display_name: String, description: String,
	is_positive: bool, affinity_stat: CharacterStats.Kind, bonuses: Dictionary
) -> Trait:
	var trait_resource := Trait.new()
	trait_resource.trait_id = trait_id
	trait_resource.display_name_key = display_name
	trait_resource.description_key = description
	trait_resource.is_positive = is_positive
	trait_resource.affinity_stat = affinity_stat
	trait_resource.hp_bonus = int(bonuses.get("hp_bonus", 0))
	trait_resource.dodge_bonus = int(bonuses.get("dodge_bonus", 0))
	trait_resource.accuracy_bonus = int(bonuses.get("accuracy_bonus", 0))
	trait_resource.crit_bonus = int(bonuses.get("crit_bonus", 0))
	trait_resource.damage_bonus = int(bonuses.get("damage_bonus", 0))
	trait_resource.xp_gain_bonus_percent = int(bonuses.get("xp_gain_bonus_percent", 0))
	trait_resource.deathblow_resist_bonus = int(bonuses.get("deathblow_resist_bonus", 0))
	trait_resource.stress_resistance_bonus = int(bonuses.get("stress_resistance_bonus", 0))
	trait_resource.morale_bonus = int(bonuses.get("morale_bonus", 0))
	trait_resource.price_discount_percent = int(bonuses.get("price_discount_percent", 0))
	trait_resource.check_bonus = CHECK_BONUS_MAGNITUDE if is_positive else -CHECK_BONUS_MAGNITUDE
	trait_resource.refusal_bonus = -REFUSAL_BONUS_MAGNITUDE if is_positive else REFUSAL_BONUS_MAGNITUDE
	return trait_resource
