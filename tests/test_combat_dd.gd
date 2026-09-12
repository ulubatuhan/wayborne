extends RefCounted

## Darkest Dungeon hattının motor tarafı: zırh (PROT), her round yeniden
## atılan hız zarı, Ölümün Kıyısı ve liderliğin devri.
##
## Buradaki doğrulamaların çoğu formül değil **kural** kilitliyor: "yalnızca
## lider ölebilir", "kıyıdaki karakter saftan düşmez", "zırh hasarı tamamen
## kesemez". Formül sayıları ayarlanacak, kurallar ayarlanmayacak - ve bir
## kural sessizce bozulursa oyunun kimliği bozulur (bkz. CLAUDE.md'nin
## "sömürüyü doğrula, formülü değil" maddesi).

func suite_name() -> String:
	return "CombatDD"

func run(t) -> void:
	_test_protection_reduces_but_never_erases(t)
	_test_fresh_character_has_no_protection(t)
	_test_turn_order_is_rerolled_each_round(t)
	_test_only_the_leader_reaches_deaths_door(t)
	_test_deaths_door_keeps_the_leader_standing(t)
	_test_healing_leaves_deaths_door(t)
	_test_deathblow_can_kill_and_resist_can_save(t)
	_test_dead_leader_is_not_stood_back_up(t)
	_test_succession_promotes_the_most_senior(t)
	_test_run_ends_only_when_nobody_can_succeed(t)

func _leader(name_text: String = "Lider") -> CharacterData:
	var character := CharacterData.create(
		name_text, CultureCatalog.get_cultures()[0].culture_id, CharacterStats.new()
	)
	character.is_player = true
	return character

func _companion(name_text: String = "Yoldaş") -> CharacterData:
	return CharacterData.create(
		name_text, CultureCatalog.get_cultures()[0].culture_id, CharacterStats.new()
	)

# --- Zırh ---

func _test_protection_reduces_but_never_erases(t) -> void:
	var unit := CombatUnit.new()
	unit.protection = 50
	t.eq(unit.reduce_by_protection(10), 5, "zırh %50 iken hasar yarıya iner")

	# Tavanın üstü kenetlenir ve taban korunur: hasarı tamamen kesen bir
	# zırh savaşı silerdi.
	unit.protection = 999
	t.eq(
		unit.reduce_by_protection(100),
		int(round(100.0 * (1.0 - float(CombatUnit.MAX_PROT) / 100.0))),
		"zırh MAX_PROT'ta kenetlenir"
	)
	t.ge(
		float(unit.reduce_by_protection(1)),
		float(CombatUnit.MIN_DAMAGE_THROUGH_PROT),
		"en yüksek zırhta bile vuruş bir şey götürür"
	)

func _test_fresh_character_has_no_protection(t) -> void:
	# Bütün türetilmiş formüllerin kuralı: statı 5'te duran karakter bu
	# sistem yokmuş gibi davranır. Ölçülmüş kazanma oranı tablolarının
	# geçerli kalmasının tek sebebi bu.
	t.eq(CharacterStats.new().get_protection(), 0, "taze karakterin zırhı yok")
	var strong := CharacterStats.new()
	strong.endurance = CharacterStats.MAX_VALUE
	t.ok(strong.get_protection() > 0, "Dayanıklılık yatırımı zırh kazandırır")
	t.ok(
		strong.get_protection() < CombatUnit.MAX_PROT,
		"maxlanmış Dayanıklılık bile zırh tavanının altında kalır"
	)

# --- Hız zarı ---

func _test_turn_order_is_rerolled_each_round(t) -> void:
	# Aynı seed aynı diziyi vermeli (tekrarlanabilirlik), ama sıra
	# round'lar arasında değişebilmeli - eskiden savaş başında bir kez
	# hesaplanıp hiç değişmiyordu.
	var orders := _collect_turn_orders(4242)
	t.ok(orders.size() >= 2, "en az iki round'un sırası toplandı")

	var changed := false
	for index in range(1, orders.size()):
		if orders[index] != orders[0]:
			changed = true
			break
	t.ok(changed, "tur sırası round'lar arasında değişiyor (hız zarı çalışıyor)")

	var repeat := _collect_turn_orders(4242)
	t.eq(repeat, orders, "aynı seed aynı sırayı üretiyor (tekrarlanabilir)")

## Bir savaşı kimse ölmeden birkaç round sürdürüp her round'un tur
## sırasını isim dizisi olarak toplar. Hasarsız bir yetenekle döndürüyoruz,
## yoksa birimler düşer ve sıranın değişmesi zardan mı ölümden mi geldiği
## ayırt edilemez.
func _collect_turn_orders(seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var encounter := _build_encounter(rng, 3, 3)

	var seen: Array = []
	var last_round := 0
	var guard := 0
	while not encounter.is_over() and seen.size() < 4 and guard < 200:
		guard += 1
		if encounter.round_number != last_round:
			last_round = encounter.round_number
			var names: Array = []
			for unit in encounter.get_turn_order():
				names.append(unit.display_name)
			seen.append(names)
		if not encounter.is_player_turn():
			break
		encounter.pass_turn()
	return seen

func _build_encounter(rng: RandomNumberGenerator, party_size: int, enemy_size: int) -> CombatEncounter:
	var party: Array[CombatUnit] = []
	for index in party_size:
		var unit := CombatUnit.new()
		unit.display_name = "P%d" % index
		unit.is_player_side = true
		unit.position = index + 1
		unit.max_hp = 200
		unit.current_hp = 200
		unit.initiative = 5 + index
		party.append(unit)

	var enemies: Array[CombatUnit] = []
	for index in enemy_size:
		var unit := CombatUnit.new()
		unit.display_name = "E%d" % index
		unit.position = index + 1
		unit.max_hp = 200
		unit.current_hp = 200
		unit.initiative = 6 + index
		enemies.append(unit)

	return CombatEncounter.new(party, enemies, rng)

# --- Ölümün Kıyısı ---

func _test_only_the_leader_reaches_deaths_door(t) -> void:
	var leader := CombatUnit.from_character(_leader(), 1)
	var companion := CombatUnit.from_character(_companion(), 2)

	t.ok(leader.can_enter_deaths_door(), "lider kıyıya girebilir")
	t.not_ok(companion.can_enter_deaths_door(), "yoldaş kıyıya girmez")

	t.eq(companion.apply_damage(9999), "downed", "yoldaş doğrudan saftan düşer")
	t.not_ok(companion.on_deaths_door, "yoldaş kıyıda değil")
	t.not_ok(companion.is_dead, "yoldaş ölmedi - kural korundu")

	var enemy := CombatUnit.new()
	t.eq(enemy.apply_damage(9999), "downed", "düşman da doğrudan düşer")

func _test_deaths_door_keeps_the_leader_standing(t) -> void:
	var leader := CombatUnit.from_character(_leader(), 1)
	t.eq(leader.apply_damage(9999), "deaths_door", "lider kıyıya girer")
	t.eq(leader.current_hp, 0, "canı sıfır")
	t.ok(leader.is_alive(), "ama hâlâ ayakta - yoksa savaş anında biterdi")
	t.ok(
		leader.get_effective_accuracy() < leader.accuracy,
		"kıyıdayken isabet düşer"
	)

func _test_healing_leaves_deaths_door(t) -> void:
	var leader := CombatUnit.from_character(_leader(), 1)
	leader.apply_damage(9999)
	t.ok(leader.on_deaths_door, "önce kıyıda")
	leader.apply_heal(1)
	t.not_ok(leader.on_deaths_door, "bir puan can bile kıyıdan çıkarır")
	t.eq(leader.get_effective_accuracy(), leader.accuracy, "isabet cezası kalkar")

func _test_deathblow_can_kill_and_resist_can_save(t) -> void:
	# Zar atılmadan (rng yok) kıyıdaki karakter asla ölmez - testler hasar
	# uygulayabilsin diye bilinçli.
	var safe := CombatUnit.from_character(_leader(), 1)
	safe.apply_damage(9999)
	t.eq(safe.apply_damage(5), "survived_deathblow", "zarsız çağrı öldürmez")
	t.not_ok(safe.is_dead, "zarsız çağrıda ölüm yok")

	# Direnç 0 -> zar her zaman tutmaz, yani kesin ölüm.
	var doomed := CombatUnit.from_character(_leader(), 1)
	doomed.deathblow_resist = 0
	doomed.apply_damage(9999)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	t.eq(doomed.apply_damage(1, rng), "killed", "direnç 0 iken vuruş öldürür")
	t.ok(doomed.is_dead, "kalıcı ölüm işaretlendi")
	t.not_ok(doomed.is_alive(), "ölü ayakta sayılmaz")

	# Direnç 100 -> zar her zaman tutar, ölüm yok.
	var tough := CombatUnit.from_character(_leader(), 1)
	tough.deathblow_resist = 100
	tough.apply_damage(9999)
	for _hit in 20:
		t.eq(tough.apply_damage(1, rng), "survived_deathblow", "direnç 100 iken ölüm yok")
	t.not_ok(tough.is_dead, "yirmi vuruş sonra hâlâ hayatta")

func _test_dead_leader_is_not_stood_back_up(t) -> void:
	var leader_data := _leader()
	var companion_data := _companion()
	var leader := CombatUnit.from_character(leader_data, 1)
	var companion := CombatUnit.from_character(companion_data, 2)

	leader.deathblow_resist = 0
	leader.apply_damage(9999)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	leader.apply_damage(1, rng)
	companion.apply_damage(9999)

	var encounter := CombatEncounter.new([leader, companion] as Array[CombatUnit], [] as Array[CombatUnit], rng)
	encounter.write_back_party()

	t.eq(companion_data.current_hp, 1, "düşen yoldaş 1 canla kalkar - kural değişmedi")
	t.eq(leader_data.current_hp, 0, "ölen lider ayağa kaldırılmaz")

	var dead := encounter.get_dead_characters()
	t.eq(dead.size(), 1, "motor yalnızca ölen lideri bildirir")
	t.eq(dead[0], leader_data, "bildirilen karakter doğru")

# --- Veraset ---

func _test_succession_promotes_the_most_senior(t) -> void:
	var session := GameSession.new()
	var leader_data := _leader("Lider")
	var green := _companion("Çaylak")
	var veteran := _companion("Kıdemli")
	veteran.level = 5
	session.party = [leader_data, green, veteran]

	var result := session.resolve_combat_deaths([leader_data] as Array[CharacterData])

	t.eq(result["dead_names"], ["Lider"], "ölen bildirildi")
	t.not_ok(result["run_over"], "yerine geçecek biri varken oyun bitmez")
	t.eq(result["new_leader"], veteran, "en kıdemli yoldaş lider olur (sıra değil, seviye)")
	t.ok(veteran.is_player, "yeni lider işaretlendi")
	t.not_ok(green.is_player, "çaylak lider olmadı")
	t.eq(session.get_player_character(), veteran, "oturum yeni lideri tanıyor")
	t.eq(session.party.size(), 2, "ölen partiden çıktı")
	t.not_ok(session.is_run_over(), "oyun sürüyor")

func _test_run_ends_only_when_nobody_can_succeed(t) -> void:
	var session := GameSession.new()
	var lone := _leader("Tek Başına")
	session.party = [lone]

	var result := session.resolve_combat_deaths([lone] as Array[CharacterData])

	t.ok(result["run_over"], "yerine geçecek kimse yoksa oyun biter")
	t.eq(result["new_leader"], null, "devredilecek lider yok")
	t.ok(session.is_run_over(), "bayrak kuruldu - kayda da girer")
	t.ok(session.party.is_empty(), "parti boşaldı")

	# Yoldaş ölümü hiçbir koşulda oyunu bitirmez: o yol zaten kapalı
	# (yoldaş kıyıya girmez), ama kural açıkça kilitlensin.
	var other := GameSession.new()
	var boss := _leader("Lider")
	var friend := _companion("Yoldaş")
	other.party = [boss, friend]
	var companion_result := other.resolve_combat_deaths([friend] as Array[CharacterData])
	t.not_ok(companion_result["run_over"], "yoldaş ölümü oyunu bitirmez")
	t.eq(companion_result["new_leader"], null, "liderlik devretmedi")
	t.ok(boss.is_player, "lider hâlâ lider")
