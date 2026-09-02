class_name SkillCatalog
extends RefCounted

## Yetenek tablosu. Hem oyuncu sınıfları hem düşmanlar buradan okur, böylece
## bir yeteneğin sayıları tek yerde durur.
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. ItemCatalog deseni).

# Oyuncu yetenekleri - Sıra Neferi
const SHIELD_BASH: String = "shield_bash"
const SPEAR_THRUST: String = "spear_thrust"
const SLING_SHOT: String = "sling_shot"
const RALLY: String = "rally"
const TAKE_COVER: String = "take_cover"

# Oyuncu yetenekleri - Sekban
const ARROW_SHOT: String = "arrow_shot"
const LEG_TIE: String = "leg_tie"
const AIMED_SHOT: String = "aimed_shot"
const STEP_BACK: String = "step_back"

# Oyuncu yetenekleri - Kırıkçı
const SLEDGE_STRIKE: String = "sledge_strike"
const SHIELD_BREAK: String = "shield_break"
const RAGE: String = "rage"
const SWEEPING_BLOW: String = "sweeping_blow"

# Oyuncu yetenekleri - Kalem Efendisi
const ROUSING_SPEECH: String = "rousing_speech"
const TALLY_RECKON: String = "tally_reckon"
const CUTTING_WORD: String = "cutting_word"
const KEEP_LEDGER: String = "keep_ledger"

# Düşman yetenekleri
const CLEAVER: String = "bandit_cleave"
const BANDIT_ARROW: String = "bandit_arrow"
const BANDIT_ORDER: String = "bandit_order"

static var _skills: Array[CombatSkill] = []
static var _skill_by_id: Dictionary = {}

static func get_skill(skill_id: String) -> CombatSkill:
	_ensure_built()
	return _skill_by_id.get(skill_id)

## Kimliklerden yetenek listesi kurar; bilinmeyen kimlikleri sessizce atlar.
static func get_skills(skill_ids: Array[String]) -> Array[CombatSkill]:
	var skills: Array[CombatSkill] = []
	for skill_id in skill_ids:
		var skill := get_skill(skill_id)
		if skill != null:
			skills.append(skill)
	return skills

static func _ensure_built() -> void:
	if not _skills.is_empty():
		return

	_skills.append(CombatSkill.make_attack(
		SHIELD_BASH,
		"Kalkan Darbesi",
		"Öndeki düşmanı kalkanla iter; isabetli ama vuruşu hafiftir.",
		[1, 2], [1, 2],
		6, 2, 10, 0
	))

	_skills.append(CombatSkill.make_attack(
		SPEAR_THRUST,
		"Mızrak Saplaması",
		"Uzun mızrakla ikinci sıraya kadar uzanır.",
		[1, 2, 3], [1, 2, 3],
		9, 3, 0, 3
	))

	_skills.append(CombatSkill.make_attack(
		SLING_SHOT,
		"Sapan Atışı",
		"Arkadan atılan taş, düşmanın arka saflarını bulur.",
		[3, 4], [2, 3, 4],
		7, 4, -5, 5
	))

	var rally := CombatSkill.new()
	rally.skill_id = RALLY
	rally.display_name = "Toparlan"
	rally.description = "Bir yoldaşının yarasını sarar. İki turda bir kullanılabilir."
	rally.target_kind = CombatSkill.Target.ALLY
	rally.usable_positions = CombatSkill.to_position_array([2, 3, 4])
	rally.target_positions = CombatSkill.to_position_array([1, 2, 3, 4])
	rally.heal_amount = 8
	rally.damage_variance = 2
	rally.cooldown_rounds = 2
	rally.scales_with_support = true
	_skills.append(rally)

	_skills.append(CombatSkill.make_buff(
		TAKE_COVER, "Siper Al", "İki tur boyunca kaçınmasını artırır.",
		CombatSkill.Target.SELF, [1, 2, 3, 4], [],
		"dodge", 10, 2, 3
	))

	_skills.append(CombatSkill.make_attack(
		ARROW_SHOT,
		"Ok Atışı",
		"Arkadan atılan güvenilir bir ok.",
		[3, 4], [1, 2, 3, 4],
		8, 3, 8, 3
	))

	_skills.append(CombatSkill.make_attack(
		LEG_TIE,
		"Ayak Bağı",
		"Hafif bir ok, hedefin bacağına dolanıp iki tur kaçınmasını düşürür.",
		[2, 3, 4], [1, 2, 3],
		4, 1, 0, 0, 2,
		"dodge", -8, 2
	))

	_skills.append(CombatSkill.make_attack(
		AIMED_SHOT,
		"Nişan Al",
		"Uzun süre nişan alır, isabet ederse ağır vurur.",
		[3, 4], [2, 3, 4],
		10, 2, -5, 15, 3
	))

	_skills.append(CombatSkill.make_buff(
		STEP_BACK, "Sırtını Dön", "Bir tur boyunca kaçınmasını artırır.",
		CombatSkill.Target.SELF, [1, 2, 3, 4], [],
		"dodge", 6, 1, 2
	))

	_skills.append(CombatSkill.make_attack(
		SLEDGE_STRIKE,
		"Balyoz Darbesi",
		"Ağır bir savurma; isabeti düşük ama vurunca çok acıtır.",
		[1, 2], [1, 2],
		14, 5, -5, 0, 1
	))

	_skills.append(CombatSkill.make_attack(
		SHIELD_BREAK,
		"Kalkan Kırma",
		"Hedefin kalkanını zorlar, iki tur kaçınmasını düşürür.",
		[1, 2], [1, 2],
		6, 2, 0, 0, 2,
		"dodge", -6, 2
	))

	_skills.append(CombatSkill.make_buff(
		RAGE, "Öfke Nöbeti", "İki tur boyunca hasar bonusunu artırır.",
		CombatSkill.Target.SELF, [1, 2, 3, 4], [],
		"damage", 6, 2, 3
	))

	_skills.append(CombatSkill.make_attack(
		SWEEPING_BLOW,
		"Çevirme Darbesi",
		"Geniş bir savurma, öndeki iki mevkiyi de bulur.",
		[1], [1, 2],
		9, 3, 0, 0, 2
	))

	var rousing_speech := CombatSkill.new()
	rousing_speech.skill_id = ROUSING_SPEECH
	rousing_speech.display_name = "Moral Nutku"
	rousing_speech.description = "Bir yoldaşının yarasını sarar."
	rousing_speech.target_kind = CombatSkill.Target.ALLY
	rousing_speech.usable_positions = CombatSkill.to_position_array([3, 4])
	rousing_speech.target_positions = CombatSkill.to_position_array([1, 2, 3, 4])
	rousing_speech.heal_amount = 6
	rousing_speech.damage_variance = 2
	rousing_speech.cooldown_rounds = 2
	rousing_speech.scales_with_support = true
	_skills.append(rousing_speech)

	_skills.append(CombatSkill.make_buff(
		TALLY_RECKON, "Hesap Kitap", "İki tur boyunca isabetini artırır.",
		CombatSkill.Target.SELF, [2, 3, 4], [],
		"accuracy", 10, 2, 3
	))

	_skills.append(CombatSkill.make_attack(
		CUTTING_WORD,
		"Keskin Söz",
		"İğneleyici bir laf, hedefin iki tur isabetini düşürür.",
		[3, 4], [1, 2, 3, 4],
		3, 1, 0, 0, 2,
		"accuracy", -8, 2
	))

	_skills.append(CombatSkill.make_buff(
		KEEP_LEDGER, "Kayıt Tut", "Bir yoldaşın iki tur kaçınmasını artırır.",
		CombatSkill.Target.ALLY, [3, 4], [1, 2, 3, 4],
		"dodge", 8, 2, 3
	))

	_skills.append(CombatSkill.make_attack(
		CLEAVER,
		"Satır Savurması",
		"Haydut satırını öndeki hedefe indirir.",
		[1, 2], [1, 2],
		8, 3, 0, 3
	))

	_skills.append(CombatSkill.make_attack(
		BANDIT_ARROW,
		"Kısa Yay",
		"Arkadan atılan ok, en zayıf halkayı arar.",
		[2, 3, 4], [1, 2, 3, 4],
		6, 3, 5, 5
	))

	_skills.append(CombatSkill.make_attack(
		BANDIT_ORDER,
		"Reisin Emri",
		"Reis sopasını sallayarak öne saldırır.",
		[1, 2, 3], [1, 2],
		11, 4, 5, 5
	))

	for skill in _skills:
		_skill_by_id[skill.skill_id] = skill
