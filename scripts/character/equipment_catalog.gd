class_name EquipmentCatalog
extends RefCounted

## Ekipman tablosu: dört slot, üçer parça - Silah/Zırh üç tier'lik kalıcı
## yükseltme (Kervan Avlusu'nda parayla, bkz. Equipment.price), Yüzük/Kolye
## üçer ödünlü tılsım (yolda EventEffect.Type.GRANT_EQUIPMENT ile bulunur,
## pazarda satılmaz - price 0).
##
## Görev Y-C06 tabloyu 36 parçaya çıkardı. Ağırlık takılarda: huyla sinerji
## kuran (`synergy_trait`), bedeli olan (`daily_stress`) ve lanetli (`cursed`)
## parçalar. Silah ve zırhta aynı kademede farklı profiller (mızrak isabet,
## balta kritik, kapitone kaçınma, pul can). Lanetli ve bedelli parçalar
## satılmaz; yalnız bulunur (ganimet, olay).
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. TraitCatalog deseni).

const SLOT_WEAPON: String = "weapon"
const SLOT_ARMOR: String = "armor"
const SLOT_RING: String = "ring"
const SLOT_AMULET: String = "amulet"

const ALL_SLOTS: Array[String] = [SLOT_WEAPON, SLOT_ARMOR, SLOT_RING, SLOT_AMULET]

## Tier'lerin seviye eşikleri. Üç teçhizat kademesi karakter seviyesine
## bağlı açılır; buradaki üçüncü eşik multiclass kilidiyle (7) aynı bölgede
## duruyor ki oyuncunun "artık kıdemliyim" hissi tek yerden gelsin.
const TIER_2_LEVEL: int = 3
const TIER_3_LEVEL: int = 6

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
const WEAPON_SPEAR: String = "weapon_spear"
const WEAPON_AXE: String = "weapon_axe"
const WEAPON_OLD_BLADE: String = "weapon_old_blade"
const ARMOR_GAMBESON: String = "armor_gambeson"
const ARMOR_SCALE: String = "armor_scale"
const ARMOR_LAMELLAR: String = "armor_lamellar"
const RING_IRON_BAND: String = "ring_iron_band"
const RING_HAWK: String = "ring_hawk"
const RING_STEADY_HAND: String = "ring_steady_hand"
const RING_BLOODSTONE: String = "ring_bloodstone"
const RING_DEBTOR: String = "ring_debtor"
const RING_SILENT: String = "ring_silent"
const RING_SALT_SEAL: String = "ring_salt_seal"
const RING_WIDOW: String = "ring_widow"
const RING_DROWNED: String = "ring_drowned"
const AMULET_BEAR_CLAW: String = "amulet_bear_claw"
const AMULET_WAYFARER_STONE: String = "amulet_wayfarer_stone"
const AMULET_RAVEN_FEATHER: String = "amulet_raven_feather"
const AMULET_ASH_LOCKET: String = "amulet_ash_locket"
const AMULET_ANCIENT_EYE: String = "amulet_ancient_eye"
const AMULET_SALT_CHARM: String = "amulet_salt_charm"
const AMULET_HORSE_HAIR: String = "amulet_horse_hair"
const AMULET_WOLF_SKULL: String = "amulet_wolf_skull"
const AMULET_COPPER_COIN: String = "amulet_copper_coin"

## Görev Y-C06 parçalarının çeviri anahtarları, tam yazılı (Localization Rules).
const EXPANSION_KEYS: Dictionary = {
	WEAPON_SPEAR: ["EQUIP_WEAPON_SPEAR_NAME", "EQUIP_WEAPON_SPEAR_DESC"],
	WEAPON_AXE: ["EQUIP_WEAPON_AXE_NAME", "EQUIP_WEAPON_AXE_DESC"],
	WEAPON_OLD_BLADE: ["EQUIP_WEAPON_OLD_BLADE_NAME", "EQUIP_WEAPON_OLD_BLADE_DESC"],
	ARMOR_GAMBESON: ["EQUIP_ARMOR_GAMBESON_NAME", "EQUIP_ARMOR_GAMBESON_DESC"],
	ARMOR_SCALE: ["EQUIP_ARMOR_SCALE_NAME", "EQUIP_ARMOR_SCALE_DESC"],
	ARMOR_LAMELLAR: ["EQUIP_ARMOR_LAMELLAR_NAME", "EQUIP_ARMOR_LAMELLAR_DESC"],
	RING_IRON_BAND: ["EQUIP_RING_IRON_BAND_NAME", "EQUIP_RING_IRON_BAND_DESC"],
	RING_HAWK: ["EQUIP_RING_HAWK_NAME", "EQUIP_RING_HAWK_DESC"],
	RING_STEADY_HAND: ["EQUIP_RING_STEADY_HAND_NAME", "EQUIP_RING_STEADY_HAND_DESC"],
	RING_BLOODSTONE: ["EQUIP_RING_BLOODSTONE_NAME", "EQUIP_RING_BLOODSTONE_DESC"],
	RING_DEBTOR: ["EQUIP_RING_DEBTOR_NAME", "EQUIP_RING_DEBTOR_DESC"],
	RING_SILENT: ["EQUIP_RING_SILENT_NAME", "EQUIP_RING_SILENT_DESC"],
	RING_SALT_SEAL: ["EQUIP_RING_SALT_SEAL_NAME", "EQUIP_RING_SALT_SEAL_DESC"],
	RING_WIDOW: ["EQUIP_RING_WIDOW_NAME", "EQUIP_RING_WIDOW_DESC"],
	RING_DROWNED: ["EQUIP_RING_DROWNED_NAME", "EQUIP_RING_DROWNED_DESC"],
	AMULET_BEAR_CLAW: ["EQUIP_AMULET_BEAR_CLAW_NAME", "EQUIP_AMULET_BEAR_CLAW_DESC"],
	AMULET_WAYFARER_STONE: ["EQUIP_AMULET_WAYFARER_STONE_NAME", "EQUIP_AMULET_WAYFARER_STONE_DESC"],
	AMULET_RAVEN_FEATHER: ["EQUIP_AMULET_RAVEN_FEATHER_NAME", "EQUIP_AMULET_RAVEN_FEATHER_DESC"],
	AMULET_ASH_LOCKET: ["EQUIP_AMULET_ASH_LOCKET_NAME", "EQUIP_AMULET_ASH_LOCKET_DESC"],
	AMULET_ANCIENT_EYE: ["EQUIP_AMULET_ANCIENT_EYE_NAME", "EQUIP_AMULET_ANCIENT_EYE_DESC"],
	AMULET_SALT_CHARM: ["EQUIP_AMULET_SALT_CHARM_NAME", "EQUIP_AMULET_SALT_CHARM_DESC"],
	AMULET_HORSE_HAIR: ["EQUIP_AMULET_HORSE_HAIR_NAME", "EQUIP_AMULET_HORSE_HAIR_DESC"],
	AMULET_WOLF_SKULL: ["EQUIP_AMULET_WOLF_SKULL_NAME", "EQUIP_AMULET_WOLF_SKULL_DESC"],
	AMULET_COPPER_COIN: ["EQUIP_AMULET_COPPER_COIN_NAME", "EQUIP_AMULET_COPPER_COIN_DESC"],
}

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
			return String(TranslationServer.translate("EQUIP_SLOT_WEAPON"))
		SLOT_ARMOR:
			return String(TranslationServer.translate("EQUIP_SLOT_ARMOR"))
		SLOT_RING:
			return String(TranslationServer.translate("EQUIP_SLOT_RING"))
		SLOT_AMULET:
			return String(TranslationServer.translate("EQUIP_SLOT_AMULET"))
		_:
			return slot

## Bir parçanın ekranda okunan satırı: beş stat, sonra (varsa) huy
## sinerjisi, günlük bedel ve lanet. Karakter ekranı ve dolap aynı satırı okur.
static func bonus_line(piece: Equipment) -> String:
	var parts: Array[String] = _stat_parts(piece, {})
	if not piece.synergy_trait.is_empty():
		var trait_resource := TraitCatalog.get_trait(piece.synergy_trait)
		var trait_name := trait_resource.display_name if trait_resource != null else piece.synergy_trait
		parts.append(_t("UI_EQUIP_SYNERGY") % [trait_name, ", ".join(_stat_parts(null, piece.synergy_bonuses))])
	if piece.daily_stress > 0:
		parts.append(_t("UI_EQUIP_DAILY_STRESS") % piece.daily_stress)
	if piece.cursed:
		parts.append(_t("UI_EQUIP_CURSED"))
	return ", ".join(parts)

static func _stat_parts(piece: Equipment, bonuses: Dictionary) -> Array[String]:
	var parts: Array[String] = []
	var keys := {"hp_bonus": "UI_BONUS_HP", "dodge_bonus": "UI_BONUS_DODGE", "accuracy_bonus": "UI_BONUS_ACCURACY",
		"crit_bonus": "UI_BONUS_CRIT", "damage_bonus": "UI_BONUS_DAMAGE"}
	for field in keys:
		var value := int(piece.get(field)) if piece != null else int(bonuses.get(field, 0))
		if value != 0:
			parts.append(_t(String(keys[field])) % value)
	return parts

static func _t(key: String) -> String:
	return String(TranslationServer.translate(key))

static func _ensure_built() -> void:
	if not _equipment.is_empty():
		return

	_equipment.append(_make(
		WEAPON_TIER_1, "EQUIP_WEAPON_TIER_1_NAME", "EQUIP_WEAPON_TIER_1_DESC",
		SLOT_WEAPON, 1, 150, {"damage_bonus": 2}
	))
	_equipment.append(_make(
		WEAPON_TIER_2, "EQUIP_WEAPON_TIER_2_NAME", "EQUIP_WEAPON_TIER_2_DESC",
		SLOT_WEAPON, 2, 350, {"damage_bonus": 4}, TIER_2_LEVEL
	))
	_equipment.append(_make(
		WEAPON_TIER_3, "EQUIP_WEAPON_TIER_3_NAME", "EQUIP_WEAPON_TIER_3_DESC",
		SLOT_WEAPON, 3, 650, {"damage_bonus": 6}, TIER_3_LEVEL
	))

	_equipment.append(_make(
		ARMOR_TIER_1, "EQUIP_ARMOR_TIER_1_NAME", "EQUIP_ARMOR_TIER_1_DESC",
		SLOT_ARMOR, 1, 150, {"hp_bonus": 4}
	))
	_equipment.append(_make(
		ARMOR_TIER_2, "EQUIP_ARMOR_TIER_2_NAME", "EQUIP_ARMOR_TIER_2_DESC",
		SLOT_ARMOR, 2, 350, {"hp_bonus": 8}, TIER_2_LEVEL
	))
	_equipment.append(_make(
		ARMOR_TIER_3, "EQUIP_ARMOR_TIER_3_NAME", "EQUIP_ARMOR_TIER_3_DESC",
		SLOT_ARMOR, 3, 700, {"hp_bonus": 14}, TIER_3_LEVEL
	))

	_equipment.append(_make(
		RING_MARKSMAN, "EQUIP_RING_MARKSMAN_NAME", "EQUIP_RING_MARKSMAN_DESC",
		SLOT_RING, 1, 0, {"accuracy_bonus": 5, "dodge_bonus": -2}
	))
	_equipment.append(_make(
		RING_GAMBLER, "EQUIP_RING_GAMBLER_NAME", "EQUIP_RING_GAMBLER_DESC",
		SLOT_RING, 1, 0, {"crit_bonus": 3, "accuracy_bonus": -3}
	))
	_equipment.append(_make(
		RING_CHARMED, "EQUIP_RING_CHARMED_NAME", "EQUIP_RING_CHARMED_DESC",
		SLOT_RING, 1, 0, {"damage_bonus": 2, "hp_bonus": -3}
	))

	_equipment.append(_make(
		AMULET_WARD, "EQUIP_AMULET_WARD_NAME", "EQUIP_AMULET_WARD_DESC",
		SLOT_AMULET, 1, 0, {"dodge_bonus": 3, "damage_bonus": -1}
	))
	_equipment.append(_make(
		AMULET_WOLF_FANG, "EQUIP_AMULET_WOLF_FANG_NAME", "EQUIP_AMULET_WOLF_FANG_DESC",
		SLOT_AMULET, 1, 0, {"hp_bonus": 3, "dodge_bonus": -2}
	))
	_equipment.append(_make(
		AMULET_COURAGE, "EQUIP_AMULET_COURAGE_NAME", "EQUIP_AMULET_COURAGE_DESC",
		SLOT_AMULET, 1, 0, {"crit_bonus": 2, "hp_bonus": -2}
	))

	_build_expansion()
	for equipment_resource in _equipment:
		_by_id[equipment_resource.equipment_id] = equipment_resource

## Görev Y-C06'nın parçaları. Sayılar mevcut tılsımların ölçeğinde: bir
## takı en çok iki stat oynatır, sinerji en çok +2, lanetli parça bir tier
## silahı kadar güçlü ama bir bedel taşır ve çıkmaz.
static func _build_expansion() -> void:
	# --- silahlar: aynı kademede başka profil ---
	_add(WEAPON_SPEAR, SLOT_WEAPON, 1, 220, {"accuracy_bonus": 4, "damage_bonus": 1})
	_add(WEAPON_AXE, SLOT_WEAPON, 2, 400, {"damage_bonus": 3, "crit_bonus": 2, "dodge_bonus": -2}, TIER_2_LEVEL)
	_add(WEAPON_OLD_BLADE, SLOT_WEAPON, 3, 0, {"damage_bonus": 5, "crit_bonus": 2}, 1,
		{"daily_stress": 2, "cursed": true})
	# --- zırhlar ---
	_add(ARMOR_GAMBESON, SLOT_ARMOR, 1, 120, {"hp_bonus": 3, "dodge_bonus": 1})
	_add(ARMOR_SCALE, SLOT_ARMOR, 2, 480, {"hp_bonus": 10, "dodge_bonus": -3}, TIER_2_LEVEL)
	_add(ARMOR_LAMELLAR, SLOT_ARMOR, 2, 0, {"hp_bonus": 6, "dodge_bonus": 1}, TIER_2_LEVEL,
		{"synergy_trait": TraitCatalog.NIMBLE_STEP, "synergy_bonuses": {"dodge_bonus": 2}})
	# --- yüzükler ---
	_add(RING_IRON_BAND, SLOT_RING, 1, 0, {"hp_bonus": 2}, 1,
		{"synergy_trait": TraitCatalog.IRON_CONSTITUTION, "synergy_bonuses": {"hp_bonus": 2}})
	_add(RING_HAWK, SLOT_RING, 1, 0, {"accuracy_bonus": 3, "crit_bonus": 1, "hp_bonus": -2}, 1,
		{"synergy_trait": TraitCatalog.SHARP_EYE, "synergy_bonuses": {"accuracy_bonus": 2}})
	_add(RING_STEADY_HAND, SLOT_RING, 1, 0, {"accuracy_bonus": 2}, 1,
		{"synergy_trait": TraitCatalog.PRUDENT, "synergy_bonuses": {"crit_bonus": 2}})
	_add(RING_BLOODSTONE, SLOT_RING, 1, 0, {"damage_bonus": 3}, 1, {"daily_stress": 1})
	_add(RING_DEBTOR, SLOT_RING, 1, 0, {"crit_bonus": 4}, 1, {"cursed": true})
	_add(RING_SILENT, SLOT_RING, 1, 0, {"dodge_bonus": 4, "accuracy_bonus": -2}, 1,
		{"synergy_trait": TraitCatalog.NIMBLE_STEP, "synergy_bonuses": {"dodge_bonus": 2}})
	_add(RING_SALT_SEAL, SLOT_RING, 1, 0, {"hp_bonus": 3, "dodge_bonus": -1}, 1,
		{"synergy_trait": TraitCatalog.STEADFAST_FAITH, "synergy_bonuses": {"hp_bonus": 2}})
	_add(RING_WIDOW, SLOT_RING, 1, 0, {"damage_bonus": 2, "accuracy_bonus": 2}, 1, {"daily_stress": 2})
	_add(RING_DROWNED, SLOT_RING, 1, 0, {"dodge_bonus": 3, "crit_bonus": 2}, 1,
		{"daily_stress": 1, "cursed": true})
	# --- kolyeler ---
	_add(AMULET_BEAR_CLAW, SLOT_AMULET, 1, 0, {"damage_bonus": 2, "hp_bonus": 2, "dodge_bonus": -3}, 1,
		{"synergy_trait": TraitCatalog.MIGHTY_ARM, "synergy_bonuses": {"damage_bonus": 1}})
	_add(AMULET_WAYFARER_STONE, SLOT_AMULET, 1, 0, {"hp_bonus": 2, "dodge_bonus": 1}, 1,
		{"synergy_trait": TraitCatalog.STEADFAST_FAITH, "synergy_bonuses": {"hp_bonus": 1, "dodge_bonus": 1}})
	_add(AMULET_RAVEN_FEATHER, SLOT_AMULET, 1, 0, {"crit_bonus": 3, "hp_bonus": -2}, 1,
		{"synergy_trait": TraitCatalog.KEEN_MIND, "synergy_bonuses": {"crit_bonus": 2}})
	_add(AMULET_ASH_LOCKET, SLOT_AMULET, 1, 0, {"hp_bonus": 4}, 1, {"daily_stress": 1})
	_add(AMULET_ANCIENT_EYE, SLOT_AMULET, 1, 0, {"accuracy_bonus": 4, "crit_bonus": 2}, 1,
		{"daily_stress": 2, "cursed": true})
	_add(AMULET_SALT_CHARM, SLOT_AMULET, 1, 0, {"dodge_bonus": 2}, 1,
		{"synergy_trait": TraitCatalog.REASSURING, "synergy_bonuses": {"accuracy_bonus": 2}})
	_add(AMULET_HORSE_HAIR, SLOT_AMULET, 1, 0, {"dodge_bonus": 2, "accuracy_bonus": 1}, 1,
		{"synergy_trait": TraitCatalog.NIMBLE_STEP, "synergy_bonuses": {"crit_bonus": 1}})
	_add(AMULET_WOLF_SKULL, SLOT_AMULET, 1, 0, {"damage_bonus": 3, "hp_bonus": -2}, 1, {"cursed": true})
	# Bir kusurla sinerji: saf olan şansına inanır, şans da ona gülümser.
	_add(AMULET_COPPER_COIN, SLOT_AMULET, 1, 0, {"crit_bonus": 1, "accuracy_bonus": 1}, 1,
		{"synergy_trait": TraitCatalog.NAIVE, "synergy_bonuses": {"crit_bonus": 3}})

static func _add(id: String, slot: String, tier: int, price: int, bonuses: Dictionary,
		required_level: int = 1, extra: Dictionary = {}) -> void:
	var keys: Array = EXPANSION_KEYS[id]
	var piece := _make(id, String(keys[0]), String(keys[1]), slot, tier, price, bonuses, required_level)
	piece.synergy_trait = str(extra.get("synergy_trait", ""))
	piece.synergy_bonuses = (extra.get("synergy_bonuses", {}) as Dictionary).duplicate()
	piece.daily_stress = int(extra.get("daily_stress", 0))
	piece.cursed = bool(extra.get("cursed", false))
	_equipment.append(piece)

static func _make(
	equipment_id: String, display_name: String, description: String,
	slot: String, tier: int, price: int, bonuses: Dictionary, required_level: int = 1
) -> Equipment:
	var equipment_resource := Equipment.new()
	equipment_resource.equipment_id = equipment_id
	equipment_resource.display_name_key = display_name
	equipment_resource.description_key = description
	equipment_resource.slot = slot
	equipment_resource.tier = tier
	equipment_resource.price = price
	equipment_resource.required_level = required_level
	equipment_resource.hp_bonus = int(bonuses.get("hp_bonus", 0))
	equipment_resource.dodge_bonus = int(bonuses.get("dodge_bonus", 0))
	equipment_resource.accuracy_bonus = int(bonuses.get("accuracy_bonus", 0))
	equipment_resource.crit_bonus = int(bonuses.get("crit_bonus", 0))
	equipment_resource.damage_bonus = int(bonuses.get("damage_bonus", 0))
	return equipment_resource
