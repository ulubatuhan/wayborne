class_name EnemyCatalog
extends RefCounted

## Düşman tablosu ve pusu kadrosu kurucusu.
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. ItemCatalog deseni).

const CUTTER: String = "bandit_cutter"
const ARCHER: String = "bandit_archer"
const LEADER: String = "bandit_leader"

## Bölgesel haydut reskin'leri (bkz. build_bandit_squad) - yalnızca
## görünüm/sayı değişir, pusunun genel yapısı aynı kalır.
const MOUNTAIN_BANDIT: String = "mountain_bandit"
const ARMED_BRIGAND: String = "armed_brigand"

## Vahşi hayvanlar (bkz. build_wildlife_squad, evt_wild_animal).
const WOLF: String = "wolf"
const BEAR: String = "bear"
const BOAR: String = "boar"

## Şehir muhafızları (bkz. build_guard_squad, evt_guard_patrol).
const CITY_GUARD: String = "city_guard"
const GUARD_SERGEANT: String = "guard_sergeant"

## Bölge kimlikleri WorldMapData'nın location_id'leriyle eşleşir. Id'ler
## kalıcı kayıt uyumluluğu için "test_loc_x" kalsa da isimler artık
## Kurtboğazı/Demirkapı (bkz. Faz 7 PR-D).
const MOUNTAIN_REGION_ID: String = "test_loc_b"  # Kurtboğazı
const GARRISON_REGION_ID: String = "test_loc_d"  # Demirkapı

## Pusu kadrosu bu kadar savaşçıyı geçemez (savaş alanı 4 mevki).
const MAX_SQUAD_SIZE: int = 4

static var _enemies: Array[EnemyTemplate] = []
static var _enemy_by_id: Dictionary = {}

static func get_enemy(enemy_id: String) -> EnemyTemplate:
	_ensure_built()
	return _enemy_by_id.get(enemy_id)

## Tek giriş noktası: road_journey.gd/combat_panel.gd bu üçünden hangisini
## çağıracağını bilmek zorunda kalmaz. enemy_kind EventEffect.Type.
## TRIGGER_COMBAT'in text_value'sundan gelir ("bandit"/"wildlife"/"guard"),
## region_id yalnızca "bandit" kadrosunu etkiler (bkz. build_bandit_squad).
static func build_squad(
	enemy_kind: String, region_id: String, danger_level: float,
	party_size: int, rng: RandomNumberGenerator, average_level: int = 1
) -> Array[CombatUnit]:
	match enemy_kind:
		"wildlife":
			return build_wildlife_squad(danger_level, party_size, rng, average_level)
		"guard":
			return build_guard_squad(danger_level, party_size, rng, average_level)
		_:
			return build_bandit_squad(danger_level, party_size, rng, average_level, region_id)

## Tehlike seviyesine göre bir haydut kadrosu kurar (danger_level 0..1,
## GameSession ile aynı ölçek). Düşük tehlikede iki kesici, yükseldikçe
## okçu ve reis eklenir - yolun tehlikesi savaşta da hissedilsin diye.
##
## region_id sefer hedefinin location_id'si (bkz. road_journey.gd
## _open_combat): Kurtboğazı çevresinde kesici yerine ağır vuran Dağ
## Haydutu, Demirkapı çevresinde okçu yerine daha isabetli/kritikli
## Silahlı Eşkıya çıkar - aynı pusu iskeleti, farklı yöre teçhizatı.
##
## Kadro ayrıca partiden en fazla bir kişi fazla olabilir: tek başına yola
## çıkan bir oyuncu dört haydutla karşılaşmaz, ama hep de rahat etmez.
##
## average_level partinin ortalama seviyesidir; seviye arttıkça haydutların
## canı/hasarı da hafifçe büyür ki üst seviye bir parti hep ezici galip
## gelmesin - EnemyTemplate'in kendisi sabit kalır, ölçek yalnızca
## CombatUnit.from_enemy()'e power_scale olarak geçer.
static func build_bandit_squad(
	danger_level: float, party_size: int, rng: RandomNumberGenerator,
	average_level: int = 1, region_id: String = ""
) -> Array[CombatUnit]:
	_ensure_built()

	var melee_id := CUTTER
	var ranged_id := ARCHER
	if region_id == MOUNTAIN_REGION_ID:
		melee_id = MOUNTAIN_BANDIT
	elif region_id == GARRISON_REGION_ID:
		ranged_id = ARMED_BRIGAND

	var ids: Array[String] = [melee_id, melee_id]
	if danger_level >= 0.25:
		ids.append(ranged_id)
	if danger_level >= 0.55:
		ids.append(LEADER)
	elif danger_level >= 0.40 and rng.randf() < 0.5:
		ids.append(melee_id)

	return _build_units(ids, party_size, average_level)

## Doğada karşılaşılan hayvanlar (bkz. evt_wild_animal). Düşük tehlikede
## bir kurt sürüsü, ortada yaban domuzu katılır, yüksek tehlikede nadiren
## (%35) sürü yerine tek başına gezen bir ayı çıkar - sayıca az ama tek
## başına çok daha tehlikeli, DD'nin "curio canavarı" mantığına yakın.
static func build_wildlife_squad(
	danger_level: float, party_size: int, rng: RandomNumberGenerator, average_level: int = 1
) -> Array[CombatUnit]:
	_ensure_built()

	var ids: Array[String] = [WOLF, WOLF]
	if danger_level >= 0.3:
		ids.append(BOAR)
	if danger_level >= 0.55 and rng.randf() < 0.35:
		ids = [BEAR]
		if party_size >= 2:
			ids.append(WOLF)

	return _build_units(ids, party_size, average_level)

## Şüpheli/itibarsız bir kervanı durduran devriye (bkz. evt_guard_patrol).
## Danger_level burada road danger'ı taşır - yalnızca çavuşun katılıp
## katılmayacağını belirler, haydut kadrosuyla aynı ölçek kullanılır.
static func build_guard_squad(
	danger_level: float, party_size: int, rng: RandomNumberGenerator, average_level: int = 1
) -> Array[CombatUnit]:
	_ensure_built()

	var ids: Array[String] = [CITY_GUARD, CITY_GUARD]
	if danger_level >= 0.4 or party_size >= 3:
		ids.append(GUARD_SERGEANT)

	return _build_units(ids, party_size, average_level)

static func _build_units(
	ids: Array[String], party_size: int, average_level: int
) -> Array[CombatUnit]:
	var templates: Array[EnemyTemplate] = []
	for enemy_id in ids:
		var template := get_enemy(enemy_id)
		if template != null:
			templates.append(template)
	templates.sort_custom(func(a, b): return a.preferred_position < b.preferred_position)

	var squad_size := mini(templates.size(), MAX_SQUAD_SIZE)
	squad_size = mini(squad_size, maxi(2, party_size + 1))

	var power_scale := get_power_scale(average_level)
	var units: Array[CombatUnit] = []
	for index in squad_size:
		units.append(CombatUnit.from_enemy(templates[index], index + 1, power_scale))
	return units

## Seviye 1'de 1.0; her seviye canı/hasarı %8 büyütür, üst sınır seviye
## 15'te ~%12'lik zafer oranına denk düşecek şekilde yumuşak tutulur.
static func get_power_scale(average_level: int) -> float:
	return 1.0 + 0.08 * float(maxi(0, average_level - 1))

static func _ensure_built() -> void:
	if not _enemies.is_empty():
		return

	_enemies.append(_make(CUTTER, "Haydut Kesicisi", 24, 76, 5, 4, 3, 8, [SkillCatalog.CLEAVER], 1, 10))
	_enemies.append(_make(ARCHER, "Haydut Okçusu", 18, 80, 8, 6, 2, 11, [SkillCatalog.BANDIT_ARROW], 3, 12))
	_enemies.append(_make(
		LEADER, "Haydut Reisi", 34, 82, 6, 8, 5, 10,
		[SkillCatalog.BANDIT_ORDER, SkillCatalog.CLEAVER], 2, 25
	))

	# Bölgesel reskin'ler: Kesici/Okçu'nun aynı mevki tercihiyle ama farklı
	# yöre teçhizatıyla çıkan versiyonları (bkz. build_bandit_squad).
	_enemies.append(_make(MOUNTAIN_BANDIT, "Dağ Haydutu", 28, 74, 4, 4, 6, 7, [SkillCatalog.CLEAVER], 1, 12))
	_enemies.append(_make(ARMED_BRIGAND, "Silahlı Eşkıya", 20, 86, 7, 9, 3, 11, [SkillCatalog.BANDIT_ARROW], 3, 14))

	# Vahşi hayvanlar - kurt sürü halinde hızlı/hafif, ayı nadir/tekil ve
	# ezici, domuz ortada saldırgan bir tekil tehdit (bkz. build_wildlife_squad).
	_enemies.append(_make(WOLF, "Kurt", 16, 78, 12, 5, 2, 14, [SkillCatalog.WOLF_BITE], 1, 8))
	_enemies.append(_make(BEAR, "Ayı", 55, 70, 2, 2, 8, 5, [SkillCatalog.BEAR_CLAW], 1, 30))
	_enemies.append(_make(BOAR, "Yaban Domuzu", 28, 74, 5, 3, 5, 10, [SkillCatalog.BOAR_CHARGE], 1, 14))

	# Şehir muhafızları - talimli ve isabetli ama haydutlar kadar sert
	# vurmuyor, çavuş komuta eder (bkz. build_guard_squad, evt_guard_patrol).
	_enemies.append(_make(CITY_GUARD, "Şehir Muhafızı", 26, 80, 6, 3, 4, 9, [SkillCatalog.GUARD_STRIKE], 1, 12))
	_enemies.append(_make(
		GUARD_SERGEANT, "Muhafız Çavuşu", 36, 82, 7, 5, 6, 10,
		[SkillCatalog.GUARD_ORDER, SkillCatalog.GUARD_STRIKE], 2, 26
	))

	for enemy in _enemies:
		_enemy_by_id[enemy.enemy_id] = enemy

static func _make(
	enemy_id: String, display_name: String, max_hp: int, accuracy: int,
	dodge: int, crit_chance: int, damage_bonus: int, initiative: int,
	skill_ids: Array, preferred_position: int, xp_value: int = 10
) -> EnemyTemplate:
	var enemy := EnemyTemplate.new()
	enemy.enemy_id = enemy_id
	enemy.display_name = display_name
	enemy.max_hp = max_hp
	enemy.accuracy = accuracy
	enemy.dodge = dodge
	enemy.crit_chance = crit_chance
	enemy.damage_bonus = damage_bonus
	enemy.initiative = initiative
	var typed_skill_ids: Array[String] = []
	for skill_id in skill_ids:
		typed_skill_ids.append(skill_id)
	enemy.skill_ids = typed_skill_ids
	enemy.preferred_position = preferred_position
	enemy.xp_value = xp_value
	return enemy
