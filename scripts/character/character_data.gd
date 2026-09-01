class_name CharacterData
extends RefCounted

## Bir kişi: kimlik (isim/kültür), görünüş (boy/ten), statlar, sınıf ve
## anlık can. Savaş motoru bunu sarmalar (CombatUnit), şehir ekranları
## doğrudan okur. Sahne ağacı gerektirmez, testte doğrudan örneklenebilir.

const MIN_HEIGHT_CM: int = 155
const MAX_HEIGHT_CM: int = 200
const DEFAULT_HEIGHT_CM: int = 172

## Boyun eşiği: bunun üstü "uzun", altı "kısa" sayılır.
const TALL_THRESHOLD_CM: int = 182
const SHORT_THRESHOLD_CM: int = 166

const SKIN_TONE_NAMES: Array[String] = [
	"Açık",
	"Buğday",
	"Zeytin",
	"Bakır",
	"Koyu",
]

static var _skin_tone_colors: Array[Color] = [
	Color(0.93, 0.80, 0.68),
	Color(0.85, 0.68, 0.52),
	Color(0.72, 0.56, 0.40),
	Color(0.58, 0.41, 0.28),
	Color(0.38, 0.26, 0.19),
]

var character_name: String = ""
var culture_id: String = CultureCatalog.NOMAD
var class_id: String = ClassCatalog.GUARD
var height_cm: int = DEFAULT_HEIGHT_CM
var skin_tone: int = 1

## Kültür bonusları uygulanmış hâli - taban statlar saklanmaz, karakter
## kurulurken bir kez birleştirilir.
var stats: CharacterStats = CharacterStats.new()

var current_hp: int = 0

## Tayfayı işe alma ücreti; oyuncunun kendisi için 0.
var hire_cost: int = 0

static func get_skin_tone_color(index: int) -> Color:
	return _skin_tone_colors[clampi(index, 0, _skin_tone_colors.size() - 1)]

static func get_skin_tone_name(index: int) -> String:
	return SKIN_TONE_NAMES[clampi(index, 0, SKIN_TONE_NAMES.size() - 1)]

## Kültür bonuslarını taban statlara uygulayıp canı dolduran fabrika.
static func create(
	character_name: String, culture_id: String, base_stats: CharacterStats,
	height_cm: int = DEFAULT_HEIGHT_CM, skin_tone: int = 1,
	class_id: String = ClassCatalog.GUARD
) -> CharacterData:
	var character := CharacterData.new()
	character.character_name = character_name
	character.culture_id = culture_id
	character.class_id = class_id
	character.height_cm = clampi(height_cm, MIN_HEIGHT_CM, MAX_HEIGHT_CM)
	character.skin_tone = skin_tone
	character.stats = CultureCatalog.get_culture_or_default(culture_id).apply_to(base_stats)
	character.heal_full()
	return character

func get_culture() -> Culture:
	return CultureCatalog.get_culture_or_default(culture_id)

func get_character_class() -> CharacterClass:
	return ClassCatalog.get_class_or_default(class_id)

func get_skills() -> Array[CombatSkill]:
	return SkillCatalog.get_skills(get_character_class().skill_ids)

# --- Boy: uzun daha çok can taşır, kısa daha iyi kaçınır ---

func get_height_hp_bonus() -> int:
	if height_cm >= TALL_THRESHOLD_CM:
		return 3
	if height_cm <= SHORT_THRESHOLD_CM:
		return -2
	return 0

func get_height_dodge_bonus() -> int:
	if height_cm <= SHORT_THRESHOLD_CM:
		return 4
	if height_cm >= TALL_THRESHOLD_CM:
		return -2
	return 0

func get_max_hp() -> int:
	return maxi(1, stats.get_max_hp() + get_character_class().bonus_max_hp + get_height_hp_bonus())

func get_dodge() -> int:
	return maxi(0, stats.get_dodge() + get_height_dodge_bonus())

func is_alive() -> bool:
	return current_hp > 0

func heal_full() -> void:
	current_hp = get_max_hp()

func apply_damage(amount: int) -> void:
	current_hp = clampi(current_hp - amount, 0, get_max_hp())

func apply_heal(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, get_max_hp())

## "Torgan · Dağ Kabilesi · Kervan Muhafızı" gibi tek satırlık kimlik.
func get_summary_line() -> String:
	return "%s · %s · %s" % [
		character_name,
		get_culture().culture_name,
		get_character_class().display_name,
	]

func get_appearance_line() -> String:
	return "%d cm · %s ten" % [height_cm, get_skin_tone_name(skin_tone)]

func to_dict() -> Dictionary:
	return {
		"name": character_name,
		"culture_id": culture_id,
		"class_id": class_id,
		"height_cm": height_cm,
		"skin_tone": skin_tone,
		"stats": stats.to_dict(),
		"current_hp": current_hp,
		"hire_cost": hire_cost,
	}

static func from_dict(data: Dictionary) -> CharacterData:
	var character := CharacterData.new()
	character.character_name = str(data.get("name", ""))
	character.culture_id = str(data.get("culture_id", CultureCatalog.NOMAD))
	character.class_id = str(data.get("class_id", ClassCatalog.GUARD))
	character.height_cm = clampi(int(data.get("height_cm", DEFAULT_HEIGHT_CM)), MIN_HEIGHT_CM, MAX_HEIGHT_CM)
	character.skin_tone = int(data.get("skin_tone", 1))
	character.stats = CharacterStats.from_dict(data.get("stats", {}))
	character.hire_cost = int(data.get("hire_cost", 0))
	character.current_hp = int(data.get("current_hp", character.get_max_hp()))
	return character
