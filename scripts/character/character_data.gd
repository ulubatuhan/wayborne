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

const MAX_LEVEL: int = 20
const XP_BASE: int = 50
const XP_GROWTH: float = 1.25
const STAT_POINTS_PER_LEVEL: int = 1
const SKILL_POINTS_PER_LEVEL: int = 2
const MULTICLASS_UNLOCK_LEVEL: int = 7
const MAX_SKILL_PROFICIENCY: int = 100

var character_name: String = ""
var culture_id: String = CultureCatalog.NOMAD
var class_id: String = ClassCatalog.GUARD
var height_cm: int = DEFAULT_HEIGHT_CM
var skin_tone: int = 1

## Kültür bonusları uygulanmış hâli - taban statlar saklanmaz, karakter
## kurulurken bir kez birleştirilir.
var stats: CharacterStats = CharacterStats.new()

var current_hp: int = 0

var level: int = 1
var xp: int = 0
var unspent_stat_points: int = 0
var unspent_skill_points: int = 0

## skill_id -> 0-100 arası yetkinlik. Metin2 tarzı: sabit kademeler yok,
## her puan aynı yeteneği biraz daha güçlendirir (bkz. CombatUnit).
var skill_proficiency: Dictionary = {}

## Seviye 7'den sonra ikinci bir sınıfın yeteneklerini de açar.
var second_class_id: String = ""

## DutyCatalog kimliklerinden biri ya da boş - GameSession.assign_duty()
## tarafından yönetilir.
var duty_id: String = ""

## Açıkken seviye atlayınca puanlar otomatik dağıtılır (yoldaşlar için
## varsayılan). Oyuncu kendi karakterinde bunu kapatıp elle dağıtabilir.
var auto_allocate: bool = true

## Tayfayı işe alma ücreti; oyuncunun kendisi için 0.
var hire_cost: int = 0

## Oyuncunun kendisi mi? Parti sırası aynı zamanda savaş mevki sırası
## olduğu için oyuncu arkaya geçebiliyor; kim olduğu bu yüzden sıradan
## değil bu bayraktan okunur (bkz. GameSession.dismiss).
var is_player: bool = false

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
	return ClassCatalog.get_character_class_or_default(class_id)

## Ana sınıfın yetenekleri, seviye 7'den sonra seçilmiş ikinci sınıfınkiyle
## birleşir (bkz. set_second_class). Aynı kimlik iki kez eklenmez.
func get_skills() -> Array[CombatSkill]:
	var skill_ids: Array[String] = get_character_class().skill_ids.duplicate()
	if not second_class_id.is_empty():
		var second_class := ClassCatalog.get_character_class(second_class_id)
		if second_class != null:
			for skill_id in second_class.skill_ids:
				if not skill_ids.has(skill_id):
					skill_ids.append(skill_id)
	return SkillCatalog.get_skills(skill_ids)

# --- Tecrübe, seviye, yetkinlik ---

## Bir sonraki seviyeye çıkmak için gereken XP - katlanarak büyür, tavan
## seviyede tanımsızdır (gain_xp orada zaten durur).
static func xp_required_for_level(current_level: int) -> int:
	return int(round(float(XP_BASE) * pow(XP_GROWTH, float(current_level - 1))))

## XP ekler, gerekirse birden çok seviye birden atlar. auto_allocate açıksa
## her seviyenin puanları hemen dağıtılır; kapalıysa unspent_* birikir ve
## karakter ekranında elle yatırılır. Kaç seviye atlandığını döner.
func gain_xp(amount: int) -> int:
	if amount <= 0 or level >= MAX_LEVEL:
		return 0
	xp += amount
	var levels_gained := 0
	while level < MAX_LEVEL and xp >= xp_required_for_level(level):
		xp -= xp_required_for_level(level)
		level += 1
		levels_gained += 1
		unspent_stat_points += STAT_POINTS_PER_LEVEL
		unspent_skill_points += SKILL_POINTS_PER_LEVEL
		if auto_allocate:
			_auto_allocate_level_up()
	if level >= MAX_LEVEL:
		xp = 0
	return levels_gained

func invest_stat_point(kind: CharacterStats.Kind) -> bool:
	if unspent_stat_points <= 0 or stats.get_value(kind) >= CharacterStats.MAX_VALUE:
		return false
	stats.add_value(kind, 1)
	unspent_stat_points -= 1
	return true

func get_skill_proficiency(skill_id: String) -> int:
	return int(skill_proficiency.get(skill_id, 0))

func invest_skill_point(skill_id: String) -> bool:
	if unspent_skill_points <= 0:
		return false
	var current := get_skill_proficiency(skill_id)
	if current >= MAX_SKILL_PROFICIENCY:
		return false
	skill_proficiency[skill_id] = mini(MAX_SKILL_PROFICIENCY, current + 1)
	unspent_skill_points -= 1
	return true

func can_multiclass() -> bool:
	return level >= MULTICLASS_UNLOCK_LEVEL

func set_second_class(new_class_id: String) -> bool:
	if not can_multiclass() or new_class_id == class_id:
		return false
	if ClassCatalog.get_character_class(new_class_id) == null:
		return false
	second_class_id = new_class_id
	return true

## Yoldaşlar için varsayılan yol: statı sınıfının yatkın olduğu alana,
## yetkinliği sınıfın kendi yeteneklerine sırayla yatırır. Yatkınlık
## dolmuşsa herhangi bir dolmamış stata geçer - puan asla boşa gitmez.
func _auto_allocate_level_up() -> void:
	_auto_allocate_stats()
	_auto_allocate_skills()

func _auto_allocate_stats() -> void:
	while unspent_stat_points > 0:
		var target := _pick_stat_to_invest()
		if target < 0 or not invest_stat_point(target):
			break

func _pick_stat_to_invest() -> int:
	for kind in get_character_class().stat_affinity:
		if stats.get_value(kind) < CharacterStats.MAX_VALUE:
			return kind
	for kind in CharacterStats.KIND_ORDER:
		if stats.get_value(kind) < CharacterStats.MAX_VALUE:
			return kind
	return -1

func _auto_allocate_skills() -> void:
	var skill_ids := get_character_class().skill_ids
	if skill_ids.is_empty():
		return
	var index := 0
	while unspent_skill_points > 0:
		var progressed := false
		for _attempt in skill_ids.size():
			var skill_id: String = skill_ids[index % skill_ids.size()]
			index += 1
			if invest_skill_point(skill_id):
				progressed = true
				break
		if not progressed:
			break

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
		"is_player": is_player,
		"level": level,
		"xp": xp,
		"unspent_stat_points": unspent_stat_points,
		"unspent_skill_points": unspent_skill_points,
		"skill_proficiency": skill_proficiency.duplicate(),
		"second_class_id": second_class_id,
		"duty_id": duty_id,
		"auto_allocate": auto_allocate,
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
	character.is_player = bool(data.get("is_player", false))
	character.level = maxi(1, int(data.get("level", 1)))
	character.xp = maxi(0, int(data.get("xp", 0)))
	character.unspent_stat_points = maxi(0, int(data.get("unspent_stat_points", 0)))
	character.unspent_skill_points = maxi(0, int(data.get("unspent_skill_points", 0)))
	character.skill_proficiency = (data.get("skill_proficiency", {}) as Dictionary).duplicate()
	character.second_class_id = str(data.get("second_class_id", ""))
	character.duty_id = str(data.get("duty_id", ""))
	character.auto_allocate = bool(data.get("auto_allocate", true))
	character.current_hp = int(data.get("current_hp", character.get_max_hp()))
	return character
