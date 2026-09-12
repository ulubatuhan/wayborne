class_name CombatUnit
extends RefCounted

## Savaş alanındaki tek bir savaşçı. Oyuncu tarafında bir CharacterData'yı
## sarmalar (can savaş bitince ona geri yazılır), düşman tarafında
## EnemyTemplate'ten kurulur. Savaş motoru yalnızca bu tipi tanır.

var display_name: String = ""
var is_player_side: bool = false
## 1 en önde, 4 en arkada.
var position: int = 1

var max_hp: int = 10
var current_hp: int = 10

var accuracy: int = 70
var dodge: int = 0
var crit_chance: int = 5
var damage_bonus: int = 0
var support_power: int = 0
## Taban hız. Tur sırası artık buna her round bir zar eklenerek kuruluyor
## (bkz. CombatEncounter.roll_turn_speeds) - eskiden savaş başında bir kez
## okunup bütün savaş boyunca sabit kalıyordu, yani sıra hiç değişmiyordu.
var initiative: int = 5
## O round için atılmış hız (taban + zar). Sıralama bunu okur.
var turn_speed: int = 0
var damage_multiplier: float = 1.0

## Zırh: gelen hasarı yüzde olarak düşürür. 0 = azaltma yok.
var protection: int = 0

var skills: Array[CombatSkill] = []

## skill_id -> kaç tur daha bekleyeceği.
var _cooldowns: Dictionary = {}

## skill_id -> 0-100 arası yetkinlik. Yalnızca oyuncu tarafında anlamlı;
## hasar/iyileştirmeyi ve bekleme süresini kademeli iyileştirir.
var skill_proficiency: Dictionary = {}

## Süreli stat değiştiriciler: her biri {"stat": "accuracy"/"dodge"/"damage",
## "amount": int, "rounds_left": int}. Tek yeni mekanik burada yaşıyor.
var _timed_modifiers: Array = []

## Yalnızca düşman tarafında anlamlı: yenilince oyuncuya verilen XP.
var xp_value: int = 0

## Hangi silüetle çizileceği (bkz. CombatFigure.ARCHETYPES): oyuncu
## tarafında sınıf kimliği, düşman tarafında düşman kimliği. Motorun
## çizimle ilgisi yok, yalnızca kimliği taşıyor - ekran ondan silüeti
## seçiyor. Tanınmayan bir kimlik haydut silüetine düşer, yani yeni bir
## düşman hiçbir zaman çizimsiz kalmaz.
var figure_kind: String = "bandit"

## Parti stresi bu karakterin direncini aştıysa true - CombatEncounter
## her turunda emirlere kulak asmama ihtimali doğurur (bkz.
## _try_refuse_order). Yalnızca oyuncu tarafında anlamlı.
var is_stressed: bool = false

## Ateş altında sükûnet: emir reddetme ihtimalinden düşülen puan
## (bkz. CharacterStats.get_composure). Düşmanlarda her zaman 0.
var composure: int = 0

## Yalnızca oyuncu tarafında dolu; savaş sonunda canı buraya yazarız.
var source_character: CharacterData = null

## --- Ölümün Kıyısı ---
## Zırh hiçbir zaman hasarı tamamen kesmez: bir statın bütün bir sistemi
## kapatması o sistemi silmek demektir (aynı gerekçe pazarlığın tabanında
## ve "sahipsiz görev asla ceza değildir" kuralında da var).
const MAX_PROT: int = 80
## Zırh ne olursa olsun vuran bir hamle en az bunu götürür.
const MIN_DAMAGE_THROUGH_PROT: int = 1

## Ölümcül vuruş direnci: Ölümün Kıyısı'ndayken gelen her hasarda bu
## yüzdeyle bir zar atılır, zar tutmazsa karakter kalıcı olarak ölür.
const DEFAULT_DEATHBLOW_RESIST: int = 67
## Kıyıdayken savaşmak kolay değil - isabet ve hasar düşer.
const DEATHS_DOOR_ACCURACY_PENALTY: int = 15
const DEATHS_DOOR_DAMAGE_PENALTY: int = 3

## Ölümün Kıyısı **yalnızca ana karaktere** ait. Yoldaşlar ve düşmanlar canı
## sıfırlanınca eskisi gibi saftan düşer; yoldaşlar savaş sonunda 1 canla
## ayağa kalkar (bkz. CombatEncounter.write_back_party). Oyunun kuralı
## "kervan mahvolabilir ama yok olamaz"dı ve yoldaş kalıcı ölümü seviye/huy/
## ekipman kaybı demek olduğu için stres-kadro dengesini de değiştirirdi;
## riski taşıyan lider olunca gerilim geliyor, denge duruyor.
var is_player_character: bool = false
var on_deaths_door: bool = false
var deathblow_resist: int = DEFAULT_DEATHBLOW_RESIST
## Kalıcı ölüm. `is_alive()` bunu okur, `current_hp` değil - Kıyıdaki bir
## karakter 0 canla hâlâ ayaktadır.
var is_dead: bool = false

static func from_character(character: CharacterData, position: int, is_stressed: bool = false) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.display_name = character.character_name
	unit.is_player_side = true
	unit.position = position
	unit.is_stressed = is_stressed
	unit.max_hp = character.get_max_hp()
	unit.current_hp = clampi(character.current_hp, 0, unit.max_hp)
	unit.accuracy = character.get_accuracy()
	unit.dodge = character.get_dodge()
	unit.crit_chance = character.get_crit_chance()
	unit.damage_bonus = character.get_damage_bonus()
	unit.support_power = character.stats.get_support_power()
	unit.initiative = character.stats.get_initiative()
	unit.protection = character.stats.get_protection()
	# Riski taşıyan lider: Ölümün Kıyısı yalnızca onda işler.
	unit.is_player_character = character.is_player
	unit.figure_kind = character.class_id
	unit.damage_multiplier = character.get_culture().combat_damage_multiplier
	unit.skills = character.get_skills()
	unit.skill_proficiency = character.skill_proficiency.duplicate()
	unit.composure = character.get_composure()
	unit.source_character = character
	return unit

## power_scale düşman istatistiklerini toptan büyütür/küçültür - ortalama
## parti seviyesine göre ölçeklenir, EnemyTemplate'in kendisi hiç değişmez.
static func from_enemy(template: EnemyTemplate, position: int, power_scale: float = 1.0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.display_name = template.display_name
	unit.is_player_side = false
	unit.position = position
	unit.max_hp = maxi(1, int(round(template.max_hp * power_scale)))
	unit.current_hp = unit.max_hp
	unit.accuracy = template.accuracy
	unit.dodge = template.dodge
	unit.crit_chance = template.crit_chance
	unit.damage_bonus = maxi(0, int(round(template.damage_bonus * power_scale)))
	unit.initiative = template.initiative
	# Zırh yüzde olduğu için power_scale ile büyütülmüyor: %20 azaltma
	# zayıf da güçlü de olsa aynı oranı keser, ölçeklenince tavanı
	# zorlar ve savaşı kilitlerdi.
	unit.protection = template.protection
	unit.skills = SkillCatalog.get_skills(template.skill_ids)
	unit.figure_kind = template.enemy_id
	unit.xp_value = template.xp_value
	return unit

## Kıyıdaki bir karakter 0 canla hâlâ ayaktadır, o yüzden bu `current_hp`
## değil `is_dead` okur. Aksi halde ana karakter Kıyı'ya girdiği anda
## saftan düşer ve savaş yenilgiyle kapanırdı.
func is_alive() -> bool:
	return not is_dead and (current_hp > 0 or on_deaths_door)

## Zırhtan geçen hasar. `MIN_DAMAGE_THROUGH_PROT` tabanı, zırhın vuruşu
## tamamen yok saymasını engelliyor.
func reduce_by_protection(amount: int) -> int:
	if amount <= 0:
		return 0
	var prot := clampi(protection, 0, MAX_PROT)
	var through := int(round(float(amount) * (1.0 - float(prot) / 100.0)))
	return maxi(MIN_DAMAGE_THROUGH_PROT, through)

## Hasar uygular ve **ne olduğunu** döner, çünkü çağıranın (motor) bunu
## kayda geçirmesi gerekiyor: "hit" / "deaths_door" (Kıyı'ya girdi) /
## "survived_deathblow" (zar tuttu) / "killed" (kalıcı öldü) / "downed"
## (yoldaş/düşman saftan düştü).
##
## `rng` yalnızca ölümcül vuruş zarı için gerekli; verilmezse zar atılmaz ve
## Kıyıdaki karakter hayatta kalır - testlerin zar atmadan hasar
## uygulayabilmesi için.
func apply_damage(amount: int, rng: RandomNumberGenerator = null) -> String:
	var taken := reduce_by_protection(amount)
	current_hp = clampi(current_hp - taken, 0, max_hp)
	if current_hp > 0:
		return "hit"

	if on_deaths_door:
		# Kıyıdayken gelen her vuruş bir ölümcül vuruş zarı - DD'nin
		# asıl gerilimi bu tekrarlanan zarda.
		if rng != null and rng.randi_range(1, 100) > deathblow_resist:
			is_dead = true
			return "killed"
		return "survived_deathblow"

	if can_enter_deaths_door():
		on_deaths_door = true
		return "deaths_door"

	return "downed"

## Kıyı'ya yalnızca ana karakter girer; gerekçesi yukarıdaki alan yorumunda.
func can_enter_deaths_door() -> bool:
	return is_player_character and not is_dead

## İyileştirme Kıyı'dan çıkarır: bir puan can bile ayağa kaldırır, ki DD'de
## de böyle - Kıyı bir eşik, bir hapis değil.
func apply_heal(amount: int) -> void:
	if is_dead:
		return
	current_hp = clampi(current_hp + amount, 0, max_hp)
	if current_hp > 0:
		on_deaths_door = false

func get_cooldown(skill_id: String) -> int:
	return int(_cooldowns.get(skill_id, 0))

## Yetkinlik bekleme süresini kısaltır: her 25 puan bir tur düşürür,
## Metin2 tarzı sürekli yatırımın savaşta hissedilmesi için.
func start_cooldown(skill: CombatSkill) -> void:
	if skill.cooldown_rounds <= 0:
		return
	var reduction := int(get_skill_proficiency(skill.skill_id) / 25)
	var reduced := maxi(0, skill.cooldown_rounds - reduction)
	if reduced > 0:
		_cooldowns[skill.skill_id] = reduced

func tick_cooldowns() -> void:
	for skill_id in _cooldowns.keys():
		var remaining := int(_cooldowns[skill_id]) - 1
		if remaining <= 0:
			_cooldowns.erase(skill_id)
		else:
			_cooldowns[skill_id] = remaining

func get_skill_proficiency(skill_id: String) -> int:
	return int(skill_proficiency.get(skill_id, 0))

## 0-100 yetkinlik hasarı/iyileştirmeyi %0'dan %50'ye kadar büyütür.
func get_proficiency_multiplier(skill_id: String) -> float:
	return 1.0 + float(get_skill_proficiency(skill_id)) / 200.0

func apply_modifier(stat: String, amount: int, rounds: int) -> void:
	if rounds <= 0 or amount == 0:
		return
	_timed_modifiers.append({"stat": stat, "amount": amount, "rounds_left": rounds})

func tick_modifiers() -> void:
	var kept: Array = []
	for modifier in _timed_modifiers:
		var remaining: int = int(modifier.rounds_left) - 1
		if remaining > 0:
			kept.append({"stat": modifier.stat, "amount": modifier.amount, "rounds_left": remaining})
	_timed_modifiers = kept

func _modifier_sum(stat: String) -> int:
	var total := 0
	for modifier in _timed_modifiers:
		if modifier.stat == stat:
			total += int(modifier.amount)
	return total

## Kıyıdayken dövüşmek ayrı bir şey: isabet ve hasar düşer. Ceza buradan
## uygulanıyor, süreli değiştirici olarak değil - Kıyı bir süre değil bir
## *durum*, iyileşince kendiliğinden kalkması gerekiyor.
func get_effective_accuracy() -> int:
	var total := accuracy + _modifier_sum("accuracy")
	if on_deaths_door:
		total -= DEATHS_DOOR_ACCURACY_PENALTY
	return total

func get_effective_dodge() -> int:
	return maxi(0, dodge + _modifier_sum("dodge"))

func get_effective_damage_bonus() -> int:
	var total := damage_bonus + _modifier_sum("damage")
	if on_deaths_door:
		total -= DEATHS_DOOR_DAMAGE_PENALTY
	return total

## Yetenek şu an kullanılabilir mi; kullanılamıyorsa neden - UI kilitli
## butonu sebebiyle birlikte gösterir (bkz. olay ekranındaki kilitli
## seçenekler).
func get_skill_block_reason(skill: CombatSkill) -> String:
	if not skill.can_use_from(position):
		return tr("CBT_BLOCK_POSITION") % position
	var remaining := get_cooldown(skill.skill_id)
	if remaining > 0:
		return tr("CBT_BLOCK_COOLDOWN") % remaining
	return ""

func can_use_skill(skill: CombatSkill) -> bool:
	return get_skill_block_reason(skill).is_empty()

## Savaş bittiğinde canı asıl karaktere geri yazar. Kalıcı ölümü buraya
## yazmıyoruz: kimin öldüğüne ve verasete `GameSession` karar veriyor
## (bkz. CombatEncounter.get_dead_characters), çünkü partiden çıkarma ve
## liderliğin devri oturum işi, savaş motorunun işi değil.
func write_back() -> void:
	if source_character != null:
		source_character.current_hp = current_hp
