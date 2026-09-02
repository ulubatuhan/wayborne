class_name ClassCatalog
extends RefCounted

## Sınıf tablosu: dört sınıf, her biri kervanın bir görevine (Duty) yatkın
## ama hiçbiri o göreve kilitli değil - DutyCatalog.get_duty_power() sadece
## eşleşince bonus verir.
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. ItemCatalog deseni).

const GUARD: String = "guard"
const HUNTER: String = "hunter"
const BREAKER: String = "breaker"
const CLERK: String = "clerk"

static var _classes: Array[CharacterClass] = []
static var _class_by_id: Dictionary = {}

static func get_classes() -> Array[CharacterClass]:
	_ensure_built()
	return _classes

## Adı bilerek get_class() değil: get_class() Object'in kendi metodu,
## üzerine yazmak tüm betiği ayrıştırılamaz hale getiriyor.
static func get_character_class(class_id: String) -> CharacterClass:
	_ensure_built()
	return _class_by_id.get(class_id)

## Sınıf bulunamazsa oyunun çökmemesi için ilk sınıfa düşer.
static func get_character_class_or_default(class_id: String) -> CharacterClass:
	var found := get_character_class(class_id)
	if found != null:
		return found
	return get_classes()[0]

static func _ensure_built() -> void:
	if not _classes.is_empty():
		return

	var guard := CharacterClass.new()
	guard.class_id = GUARD
	guard.display_name = "Sıra Neferi"
	guard.description = "Vagonların yanında yürüyen, mızrak ve sapanla idare eden sıradan bir korucu."
	guard.bonus_max_hp = 6
	guard.stat_affinity = [CharacterStats.Kind.ENDURANCE, CharacterStats.Kind.STRENGTH]
	guard.duty_id = DutyCatalog.MUHAFIZ
	guard.skill_ids = [
		SkillCatalog.SHIELD_BASH,
		SkillCatalog.SPEAR_THRUST,
		SkillCatalog.SLING_SHOT,
		SkillCatalog.RALLY,
		SkillCatalog.TAKE_COVER,
	]
	_classes.append(guard)

	var hunter := CharacterClass.new()
	hunter.class_id = HUNTER
	hunter.display_name = "Sekban"
	hunter.description = "Rotayı önden tarayan, yayıyla arkadan vuran avcı."
	hunter.bonus_max_hp = 2
	hunter.stat_affinity = [CharacterStats.Kind.AGILITY, CharacterStats.Kind.PERCEPTION]
	hunter.duty_id = DutyCatalog.IZCI
	hunter.skill_ids = [
		SkillCatalog.ARROW_SHOT,
		SkillCatalog.LEG_TIE,
		SkillCatalog.AIMED_SHOT,
		SkillCatalog.STEP_BACK,
	]
	_classes.append(hunter)

	var breaker := CharacterClass.new()
	breaker.class_id = BREAKER
	breaker.display_name = "Kırıkçı"
	breaker.description = "Ağır silahla öne dalan, hem düşmanı hem vagon tekerini kırmaya alışkın."
	breaker.bonus_max_hp = 8
	breaker.stat_affinity = [CharacterStats.Kind.STRENGTH, CharacterStats.Kind.ENDURANCE]
	breaker.duty_id = DutyCatalog.ARABACI
	breaker.skill_ids = [
		SkillCatalog.SLEDGE_STRIKE,
		SkillCatalog.SHIELD_BREAK,
		SkillCatalog.RAGE,
		SkillCatalog.SWEEPING_BLOW,
	]
	_classes.append(breaker)

	var clerk := CharacterClass.new()
	clerk.class_id = CLERK
	clerk.display_name = "Kalem Efendisi"
	clerk.description = "Defteri elden düşürmeyen, sözüyle de kervanı toparlayan yazman."
	clerk.bonus_max_hp = 0
	clerk.stat_affinity = [CharacterStats.Kind.INTELLECT, CharacterStats.Kind.CHARISMA]
	clerk.duty_id = DutyCatalog.LEVAZIMCI
	clerk.skill_ids = [
		SkillCatalog.ROUSING_SPEECH,
		SkillCatalog.TALLY_RECKON,
		SkillCatalog.CUTTING_WORD,
		SkillCatalog.KEEP_LEDGER,
	]
	_classes.append(clerk)

	for character_class in _classes:
		_class_by_id[character_class.class_id] = character_class
