class_name ClassCatalog
extends RefCounted

## Sınıf tablosu. Şimdilik tek sınıf var (Kervan Muhafızı); tablo yine de
## katalog olarak duruyor ki ikinci sınıf eklenince UI'ın değişmesi
## gerekmesin.
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. ItemCatalog deseni).

const GUARD: String = "guard"

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
	guard.display_name = "Kervan Muhafızı"
	guard.description = "Vagonların yanında yürüyen, mızrak ve sapanla idare eden sıradan bir korucu."
	guard.bonus_max_hp = 6
	var guard_skills: Array[String] = [
		SkillCatalog.SHIELD_BASH,
		SkillCatalog.SPEAR_THRUST,
		SkillCatalog.SLING_SHOT,
		SkillCatalog.RALLY,
	]
	guard.skill_ids = guard_skills
	_classes.append(guard)

	for character_class in _classes:
		_class_by_id[character_class.class_id] = character_class
