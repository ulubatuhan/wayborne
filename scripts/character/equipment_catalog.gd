class_name EquipmentCatalog
extends RefCounted

## Ekipman tablosu: dört slot, üçer parça - Silah/Zırh üç tier'lik kalıcı
## yükseltme (Kervan Avlusu'nda parayla, bkz. Equipment.price), Yüzük/Kolye
## üçer ödünlü tılsım (yolda EventEffect.Type.GRANT_EQUIPMENT ile bulunur,
## pazarda satılmaz - price 0).
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. TraitCatalog deseni).

const SLOT_WEAPON: String = "weapon"
const SLOT_ARMOR: String = "armor"
const SLOT_RING: String = "ring"
const SLOT_AMULET: String = "amulet"

const ALL_SLOTS: Array[String] = [SLOT_WEAPON, SLOT_ARMOR, SLOT_RING, SLOT_AMULET]

const WEAPON_TIER_1: String = "weapon_tier_1"
const WEAPON_TIER_2: String = "weapon_tier_2"
const WEAPON_TIER_3: String = "weapon_tier_3"
const ARMOR_TIER_1: String = "armor_tier_1"
const ARMOR_TIER_2: String = "armor_tier_2"
const ARMOR_TIER_3: String = "armor_tier_3"
const RING_MARKSMAN: String = "ring_marksman"
const RING_GAMBLER: String = "ring_gambler"
const RING_CHARMED: String = "ring_charmed"
const AMULET_WARD: String = "amulet_ward"
const AMULET_WOLF_FANG: String = "amulet_wolf_fang"
const AMULET_COURAGE: String = "amulet_courage"

static var _equipment: Array[Equipment] = []
static var _by_id: Dictionary = {}

static func get_all_equipment() -> Array[Equipment]:
	_ensure_built()
	return _equipment

static func get_equipment(equipment_id: String) -> Equipment:
	_ensure_built()
	return _by_id.get(equipment_id)

static func get_equipment_for_slot(slot: String) -> Array[Equipment]:
	_ensure_built()
	var result: Array[Equipment] = []
	for equipment_resource in _equipment:
		if equipment_resource.slot == slot:
			result.append(equipment_resource)
	return result

static func get_slot_display_name(slot: String) -> String:
	match slot:
		SLOT_WEAPON:
			return "Silah"
		SLOT_ARMOR:
			return "Zırh"
		SLOT_RING:
			return "Yüzük"
		SLOT_AMULET:
			return "Kolye"
		_:
			return slot

static func _ensure_built() -> void:
	if not _equipment.is_empty():
		return

	_equipment.append(_make(
		WEAPON_TIER_1, "Kervan Kılıcı", "Yolda taşınan, sıradan ama keskin bir kılıç.",
		SLOT_WEAPON, 1, 150, {"damage_bonus": 2}
	))
	_equipment.append(_make(
		WEAPON_TIER_2, "Ustalık Kılıcı", "Usta bir demircinin elinden çıkma.",
		SLOT_WEAPON, 2, 350, {"damage_bonus": 4}
	))
	_equipment.append(_make(
		WEAPON_TIER_3, "Şahin Kılıcı", "Nadir bulunan çelikten dövülmüş.",
		SLOT_WEAPON, 3, 650, {"damage_bonus": 6}
	))

	_equipment.append(_make(
		ARMOR_TIER_1, "Deri Zırh", "Hafif ama işe yarar bir koruma.",
		SLOT_ARMOR, 1, 150, {"hp_bonus": 4}
	))
	_equipment.append(_make(
		ARMOR_TIER_2, "Zincir Gömlek", "Ağır darbeleri de savar.",
		SLOT_ARMOR, 2, 350, {"hp_bonus": 8}
	))
	_equipment.append(_make(
		ARMOR_TIER_3, "Plaka Zırh", "Kervan yolunda nadir görülen tam donanım.",
		SLOT_ARMOR, 3, 700, {"hp_bonus": 14}
	))

	_equipment.append(_make(
		RING_MARKSMAN, "Nişancı Yüzüğü", "El daha kararlı nişan alır, ama ayak yavaşlar.",
		SLOT_RING, 1, 0, {"accuracy_bonus": 5, "dodge_bonus": -2}
	))
	_equipment.append(_make(
		RING_GAMBLER, "Kumarbaz Yüzüğü", "Ya tam vurur ya hiç isabet etmez.",
		SLOT_RING, 1, 0, {"crit_bonus": 3, "accuracy_bonus": -3}
	))
	_equipment.append(_make(
		RING_CHARMED, "Tılsımlı Yüzük", "Vuruşu ağırlaştırır, bedeni yorar.",
		SLOT_RING, 1, 0, {"damage_bonus": 2, "hp_bonus": -3}
	))

	_equipment.append(_make(
		AMULET_WARD, "Muska", "Kötü niyeti savar ama kolu hafifletir.",
		SLOT_AMULET, 1, 0, {"dodge_bonus": 3, "damage_bonus": -1}
	))
	_equipment.append(_make(
		AMULET_WOLF_FANG, "Kurt Dişi Kolye", "Bünyeyi güçlendirir, ayağı ağırlaştırır.",
		SLOT_AMULET, 1, 0, {"hp_bonus": 3, "dodge_bonus": -2}
	))
	_equipment.append(_make(
		AMULET_COURAGE, "Cesaret Muskası", "Vuruşu keskinleştirir, bedeni yorar.",
		SLOT_AMULET, 1, 0, {"crit_bonus": 2, "hp_bonus": -2}
	))

	for equipment_resource in _equipment:
		_by_id[equipment_resource.equipment_id] = equipment_resource

static func _make(
	equipment_id: String, display_name: String, description: String,
	slot: String, tier: int, price: int, bonuses: Dictionary
) -> Equipment:
	var equipment_resource := Equipment.new()
	equipment_resource.equipment_id = equipment_id
	equipment_resource.display_name = display_name
	equipment_resource.description = description
	equipment_resource.slot = slot
	equipment_resource.tier = tier
	equipment_resource.price = price
	equipment_resource.hp_bonus = int(bonuses.get("hp_bonus", 0))
	equipment_resource.dodge_bonus = int(bonuses.get("dodge_bonus", 0))
	equipment_resource.accuracy_bonus = int(bonuses.get("accuracy_bonus", 0))
	equipment_resource.crit_bonus = int(bonuses.get("crit_bonus", 0))
	equipment_resource.damage_bonus = int(bonuses.get("damage_bonus", 0))
	return equipment_resource
