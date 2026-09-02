class_name RecruitCatalog
extends RefCounted

## Şehirde partiye katılabilecek adayları üretir. Her mekân farklı insan
## çıkarır: meydan ucuz ve acemi, taverna dengeli, lonca pahalı ve
## itibar ister.
##
## Adaylar her şehir varışında bir kez üretilir (bkz. GameSession
## _restock_recruits); ekran her açıldığında yeniden atılmaz, yoksa
## oyuncu istediğini bulana kadar ekranı açıp kapatırdı.

const VENUE_MARKET: String = "market"
const VENUE_TAVERN: String = "tavern"
const VENUE_GUILD: String = "guild"

const EPITHETS: Array[String] = [
	"Yolcu", "Tozlu", "Sessiz", "Kırık Mızrak", "Tuzlu",
	"Kara", "Demirci", "Tek Göz", "Uzun Adım", "Çakmaktaşı",
]

## Mekân başına: [aday sayısı, dağıtılan ekstra stat puanı, taban ücret,
## puan başına ücret, gereken itibar]
const VENUE_MARKET_PROFILE: Array[int] = [2, 2, 40, 12, 0]
const VENUE_TAVERN_PROFILE: Array[int] = [3, 5, 70, 15, 0]
const VENUE_GUILD_PROFILE: Array[int] = [2, 9, 140, 20, 5]

## Mekân başına aday seviyesinin oyuncu seviyesine göre sapması
## [min_delta, max_delta] - meydan hep acemi çıkarır, lonca hep en az
## oyuncu kadar tecrübeli (bkz. "daha tecrübeli yoldaşlar da edinebiliriz").
const VENUE_MARKET_LEVEL_SPREAD: Array[int] = [-3, -1]
const VENUE_TAVERN_LEVEL_SPREAD: Array[int] = [-1, 1]
const VENUE_GUILD_LEVEL_SPREAD: Array[int] = [0, 3]

## Seviye başına ek ücret - stat fazlası zaten _stat_surplus()'a yansıyor,
## bu yalnızca "daha tecrübeli" olmanın kendi payı.
const HIRE_COST_PER_LEVEL: int = 10

static func get_venue_profile(venue: String) -> Array[int]:
	match venue:
		VENUE_GUILD:
			return VENUE_GUILD_PROFILE
		VENUE_TAVERN:
			return VENUE_TAVERN_PROFILE
		_:
			return VENUE_MARKET_PROFILE

static func get_venue_level_spread(venue: String) -> Array[int]:
	match venue:
		VENUE_GUILD:
			return VENUE_GUILD_LEVEL_SPREAD
		VENUE_TAVERN:
			return VENUE_TAVERN_LEVEL_SPREAD
		_:
			return VENUE_MARKET_LEVEL_SPREAD

static func get_venue_required_reputation(venue: String) -> int:
	return get_venue_profile(venue)[4]

static func build_candidates(
	venue: String, rng: RandomNumberGenerator, player_level: int = 1
) -> Array[CharacterData]:
	var profile := get_venue_profile(venue)
	var spread := get_venue_level_spread(venue)
	var candidates: Array[CharacterData] = []
	for _index in profile[0]:
		var level := clampi(
			player_level + rng.randi_range(spread[0], spread[1]), 1, CharacterData.MAX_LEVEL
		)
		candidates.append(_make_candidate(profile, rng, level))
	return candidates

static func _make_candidate(profile: Array[int], rng: RandomNumberGenerator, level: int) -> CharacterData:
	var cultures := CultureCatalog.get_cultures()
	var culture := cultures[rng.randi_range(0, cultures.size() - 1)]

	var base_stats := CharacterStats.new()
	for _point in profile[1]:
		var kind: CharacterStats.Kind = CharacterStats.KIND_ORDER[
			rng.randi_range(0, CharacterStats.KIND_ORDER.size() - 1)
		]
		base_stats.add_value(kind, 1)

	var classes := ClassCatalog.get_classes()
	var class_id: String = classes[rng.randi_range(0, classes.size() - 1)].class_id

	var first_name := culture.name_pool[rng.randi_range(0, culture.name_pool.size() - 1)]
	var epithet := EPITHETS[rng.randi_range(0, EPITHETS.size() - 1)]

	var candidate := CharacterData.create(
		"%s %s" % [first_name, epithet],
		culture.culture_id,
		base_stats,
		rng.randi_range(CharacterData.MIN_HEIGHT_CM, CharacterData.MAX_HEIGHT_CM),
		rng.randi_range(0, CharacterData.SKIN_TONE_NAMES.size() - 1),
		class_id
	)
	_grant_levels(candidate, level)
	candidate.hire_cost = (
		profile[2] + _stat_surplus(candidate) * profile[3] + (level - 1) * HIRE_COST_PER_LEVEL
	)
	return candidate

## auto_allocate açık geldiği için (CharacterData varsayılanı) puanlar
## kendi sınıfının yatkın olduğu statlara ve yeteneklerine gider - elle
## dağıtım burada taklit edilmiyor.
static func _grant_levels(candidate: CharacterData, level: int) -> void:
	var total_xp := 0
	for from_level in range(1, level):
		total_xp += CharacterData.xp_required_for_level(from_level)
	if total_xp > 0:
		candidate.gain_xp(total_xp)
	candidate.heal_full()

## Ücret adayın taban üstü toplam statından çıkar - iyi adam pahalıdır.
static func _stat_surplus(candidate: CharacterData) -> int:
	var surplus := 0
	for kind in CharacterStats.KIND_ORDER:
		surplus += maxi(0, candidate.stats.get_value(kind) - CharacterStats.BASE_VALUE)
	return surplus
