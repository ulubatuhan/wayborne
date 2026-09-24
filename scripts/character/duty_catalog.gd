class_name DutyCatalog
extends RefCounted

## Altı kervan görevi. Sınıfların "ana görevi" (CharacterClass.duty_id)
## buradaki kimliklerden biriyle eşleşirse görev gücü katlanır - bir
## Sıra Neferi'ni Muhafız atamak, bir Kalem Efendisi'ni atamaktan daha
## güçlü bir Muhafız verir.
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. ItemCatalog deseni).

const MUHAFIZ: String = "muhafiz"
const IZCI: String = "izci"
const LEVAZIMCI: String = "levazimci"
const ARABACI: String = "arabaci"
const TELLAL: String = "tellal"
const OTACI: String = "otaci"

## Ana sınıf eşleşirse görev gücü bu kadar çarpılır.
const PRIMARY_MATCH_MULTIPLIER: float = 1.5
## Yalnızca ikinci sınıf (multiclass) eşleşirse bu kadar.
const SECONDARY_MATCH_MULTIPLIER: float = 1.25

## Kişisel kondisyon: kırılmış (bkz. CharacterData.is_stressed - kişinin
## kendi stresi, kadro ortalaması değil) ya da can yarısının altındaki bir
## görevli, göreve o kadar iyi bakamaz. `CombatUnit.is_stressed`'in savaşta
## zaten okuduğu veriyi görev formülüne taşıyor - yeni bir sistem değil.
## Sağlıklı ve dinç varsayılan (tam can, sıfır stres) çarpanı 1.0'da tutar,
## o yüzden mevcut hiçbir ölçüm/test etkilenmez.
const STRESSED_CONDITION_PENALTY: float = 0.85
const LOW_HP_CONDITION_PENALTY: float = 0.85
const LOW_HP_THRESHOLD_RATIO: float = 0.5

static var _duties: Array[Duty] = []
static var _duty_by_id: Dictionary = {}

static func get_duties() -> Array[Duty]:
	_ensure_built()
	return _duties

static func get_duty(duty_id: String) -> Duty:
	_ensure_built()
	return _duty_by_id.get(duty_id)

## Bir karakterin belirli bir görevdeki gücü: taban 1.0 + statın etkin
## değerinin %5'i, sınıfının ana ya da ikinci görevi eşleşirse çarpılır.
## Eşleşme yoksa çarpan 1.0 kalır - herkes her görevi üstlenebilir, sadece
## kendi sınıfının görevinde daha iyi olur.
static func get_duty_power(character: CharacterData, duty_id: String) -> float:
	var duty := get_duty(duty_id)
	if duty == null or character == null:
		return 1.0

	var effective := character.stats.get_effective_value(duty.primary_stat)
	var base := 1.0 + 0.05 * effective

	var multiplier := 1.0
	var primary_class := ClassCatalog.get_character_class(character.class_id)
	if primary_class != null and primary_class.duty_id == duty_id:
		multiplier = PRIMARY_MATCH_MULTIPLIER
	elif not character.second_class_id.is_empty():
		var second_class := ClassCatalog.get_character_class(character.second_class_id)
		if second_class != null and second_class.duty_id == duty_id:
			multiplier = SECONDARY_MATCH_MULTIPLIER

	return base * multiplier * get_condition_multiplier(character)

## Bkz. STRESSED_CONDITION_PENALTY'nin yorumu. Sahipsiz bir görev bu
## fonksiyona hiç girmez (get_duty_power sahipsizken 1.0'ı doğrudan döner),
## o yüzden bu her zaman *atanmış* birinin kendi kondisyonunu ölçer.
static func get_condition_multiplier(character: CharacterData) -> float:
	var multiplier := 1.0
	if character.is_stressed():
		multiplier *= STRESSED_CONDITION_PENALTY
	var max_hp := character.get_max_hp()
	if max_hp > 0 and float(character.current_hp) / float(max_hp) < LOW_HP_THRESHOLD_RATIO:
		multiplier *= LOW_HP_CONDITION_PENALTY
	return multiplier

static func _ensure_built() -> void:
	if not _duties.is_empty():
		return

	_duties.append(_make(MUHAFIZ, "DUTY_MUHAFIZ_NAME", "DUTY_MUHAFIZ_DESC", CharacterStats.Kind.ENDURANCE))
	_duties.append(_make(IZCI, "DUTY_IZCI_NAME", "DUTY_IZCI_DESC", CharacterStats.Kind.PERCEPTION))
	_duties.append(_make(LEVAZIMCI, "DUTY_LEVAZIMCI_NAME", "DUTY_LEVAZIMCI_DESC", CharacterStats.Kind.INTELLECT))
	_duties.append(_make(ARABACI, "DUTY_ARABACI_NAME", "DUTY_ARABACI_DESC", CharacterStats.Kind.STRENGTH))
	_duties.append(_make(TELLAL, "DUTY_TELLAL_NAME", "DUTY_TELLAL_DESC", CharacterStats.Kind.CHARISMA))
	_duties.append(_make(OTACI, "DUTY_OTACI_NAME", "DUTY_OTACI_DESC", CharacterStats.Kind.INTELLECT))

	for duty in _duties:
		_duty_by_id[duty.duty_id] = duty

static func _make(duty_id: String, name_key: String, description_key: String, primary_stat: CharacterStats.Kind) -> Duty:
	var duty := Duty.new()
	duty.duty_id = duty_id
	duty.display_name_key = name_key
	duty.description_key = description_key
	duty.primary_stat = primary_stat
	return duty
