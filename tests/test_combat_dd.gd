extends RefCounted

## Darkest Dungeon hattının motor tarafı: zırh (PROT), her round yeniden
## atılan hız zarı, Ölümün Kıyısı ve liderliğin devri.
##
## Buradaki doğrulamaların çoğu formül değil **kural** kilitliyor: "Ölümün
## Kıyısı'na oyuncu tarafındaki herkes girer" (Faz 14'te tersine çevrildi -
## eskiden yalnızca lider girebiliyordu), "kıyıdaki karakter saftan düşmez",
## "zırh hasarı tamamen kesemez". Formül sayıları ayarlanacak, kurallar
## ayarlanmayacak - ve bir kural sessizce bozulursa oyunun kimliği bozulur
## (bkz. CLAUDE.md'nin "sömürüyü doğrula, formülü değil" maddesi).

func suite_name() -> String:
	return "CombatDD"

func run(t) -> void:
	_test_protection_reduces_but_never_erases(t)
	_test_fresh_character_has_no_protection(t)
	_test_turn_order_is_rerolled_each_round(t)
	_test_deaths_door_is_open_to_the_whole_party(t)
	_test_deaths_door_keeps_the_leader_standing(t)
	_test_healing_leaves_deaths_door(t)
	_test_deathblow_can_kill_and_resist_can_save(t)
	_test_dead_characters_are_not_stood_back_up(t)
	_test_succession_promotes_the_most_senior(t)
	_test_run_ends_only_when_nobody_can_succeed(t)
	_test_battlefield_is_a_field_not_a_list(t)
	_test_bark_drives_flash_and_lunge(t)
	_test_status_resist_never_certain_never_impossible(t)
	_test_stun_cannot_be_chained(t)
	_test_dot_does_not_stack_with_itself(t)
	_test_dot_goes_through_the_one_damage_door(t)
	_test_dot_ticks_at_the_start_of_the_turn(t)
	_test_endurance_buys_status_resistance(t)
	_test_every_status_a_skill_can_apply_is_handled(t)
	_test_every_modifier_stat_is_handled(t)
	_test_each_class_owns_its_axes(t)
	_test_prot_modifier_bends_the_damage_door(t)
	_test_area_skills_never_beat_single_target(t)
	_test_adjacent_hits_only_neighbours(t)
	_test_random_targeting_never_wastes_a_turn(t)
	_test_shift_keeps_ranks_contiguous(t)
	_test_shift_cannot_remove_a_unit_from_the_field(t)
	_test_self_shift_moves_the_user(t)

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

## Kural tersine çevrildi: kıyıya artık oyuncu tarafındaki herkes girer,
## yalnızca düşman tarafı hâlâ dışarıda - `can_enter_deaths_door()`
## `is_player_side` okuyor, `is_player_character` diye ayrı bir bayrak
## yok artık.
func _test_deaths_door_is_open_to_the_whole_party(t) -> void:
	var leader := CombatUnit.from_character(_leader(), 1)
	var companion := CombatUnit.from_character(_companion(), 2)

	t.ok(leader.can_enter_deaths_door(), "lider kıyıya girebilir")
	t.ok(companion.can_enter_deaths_door(), "yoldaş da artık kıyıya girebilir")

	t.eq(companion.apply_damage(9999), "deaths_door", "yoldaş da önce kıyıya girer")
	t.ok(companion.on_deaths_door, "yoldaş kıyıda")
	t.not_ok(companion.is_dead, "zar atılmadan ölüm yok")

	var enemy := CombatUnit.new()
	t.eq(enemy.apply_damage(9999), "downed", "düşman hâlâ doğrudan düşer, kıyıya girmez")

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

## Üç durum bir arada: gerçekten ölen lider, gerçekten ölen bir yoldaş
## (kural artık ikisi için de aynı) ve sadece düşüp zar tutan bir başka
## yoldaş - üçü de aynı `write_back_party()` çağrısından geçiyor.
func _test_dead_characters_are_not_stood_back_up(t) -> void:
	var leader_data := _leader()
	var dead_companion_data := _companion("Ölen")
	var survivor_data := _companion("Hayatta Kalan")
	var leader := CombatUnit.from_character(leader_data, 1)
	var dead_companion := CombatUnit.from_character(dead_companion_data, 2)
	var survivor := CombatUnit.from_character(survivor_data, 3)

	var rng := RandomNumberGenerator.new()
	rng.seed = 11

	leader.deathblow_resist = 0
	leader.apply_damage(9999)
	leader.apply_damage(1, rng)

	dead_companion.deathblow_resist = 0
	dead_companion.apply_damage(9999)
	dead_companion.apply_damage(1, rng)

	survivor.deathblow_resist = 100
	survivor.apply_damage(9999)
	survivor.apply_damage(1, rng)

	var units: Array[CombatUnit] = [leader, dead_companion, survivor]
	var encounter := CombatEncounter.new(units, [] as Array[CombatUnit], rng)
	encounter.write_back_party()

	t.eq(leader_data.current_hp, 0, "ölen lider ayağa kaldırılmaz")
	t.eq(dead_companion_data.current_hp, 0, "ölen yoldaş da ayağa kaldırılmaz - kural artık ikisi için de aynı")
	t.eq(survivor_data.current_hp, 1, "zar tutan yoldaş 1 canla kalkar - kural değişmedi")

	var dead := encounter.get_dead_characters()
	t.eq(dead.size(), 2, "motor gerçekten ölen herkesi bildirir, sadece lideri değil")
	t.ok(dead.has(leader_data), "lider bildirilenler arasında")
	t.ok(dead.has(dead_companion_data), "yoldaş da bildirilenler arasında")
	t.not_ok(dead.has(survivor_data), "hayatta kalan bildirilmez")

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


# --- Savaş alanı görünümü ---

## Panel sahnesiz olduğu için test onu gerçekten kurabiliyor - ve kurması
## gerekiyor: **test paketi ekran betiklerini hiç yüklemiyordu**, yani
## combat_panel.gd'deki bir ayrıştırma hatası oyuncu savaşa girene kadar
## gizli kalıyordu (yerelde `--headless --import` ve CI'ın log taraması
## dışında hiçbir şey görmüyordu).
##
## Doğrulananlar yapısal: iki karşılıklı saf var, oyuncu safı ters dizili
## (1. mevki ortada), hedef *sahnede* işaretleniyor. Bunlar "savaş bir
## liste değil mekân" iddiasının kendisi; renk ve boşluk ayarlanacak,
## bunlar ayarlanmayacak.
const PANEL_PATH: String = "res://scripts/ui/combat_panel.gd"

func _test_battlefield_is_a_field_not_a_list(t) -> void:
	var script = load(PANEL_PATH)
	t.ok(script != null, "savaş paneli yüklenebiliyor (ayrıştırma hatası yok)")
	if script == null:
		return

	var panel = script.new()
	panel._ready()

	var party: Array[CharacterData] = []
	for index in 3:
		var character := _companion("K%d" % index)
		if index == 0:
			character.is_player = true
		party.append(character)

	var rng := RandomNumberGenerator.new()
	rng.seed = 9091
	panel.start_combat(party, 0.4, rng, "bandit", "")

	t.eq(panel._player_row.get_child_count(), 3, "oyuncu safı üç mevki kurdu")
	t.ok(panel._enemy_row.get_child_count() > 0, "düşman safı kuruldu")
	t.ok(panel._skill_row.get_child_count() > 0, "yetenek kartları kuruldu")
	t.ok(panel._order_strip.get_child_count() > 0, "tur sırası şeridi dolu")

	# Oyuncu safı ters: 1. mevki en sağda, yani düşmanın 1. mevkisinin
	# karşısında. "Ön saf" ancak karşı karşıya durunca anlam taşır.
	var player_ranks: Array = []
	for slot in panel._player_row.get_children():
		var bound: CombatUnit = slot.unit
		player_ranks.append(bound.position)
	t.eq(player_ranks, [3, 2, 1], "oyuncu safı ters dizili (1. mevki ortaya bakıyor)")

	var enemy_ranks: Array = []
	for slot in panel._enemy_row.get_children():
		var bound: CombatUnit = slot.unit
		enemy_ranks.append(bound.position)
	var expected_enemy: Array = []
	for index in enemy_ranks.size():
		expected_enemy.append(index + 1)
	t.eq(enemy_ranks, expected_enemy, "düşman safı düz dizili")

	# Hedefleme sahnede: yetenek seçilmeden hiçbir mevki seçilebilir
	# değil, seçildikten sonra menzildeki mevkiler seçilebilir oluyor.
	t.eq(_selectable_count(panel), 0, "yetenek seçilmemişken hiçbir hedef tıklanabilir değil")

	var usable: CombatSkill = null
	var active: CombatUnit = panel._encounter.get_active_unit()
	for skill in active.skills:
		if active.can_use_skill(skill) and not panel._encounter.get_valid_targets(active, skill).is_empty():
			usable = skill
			break
	t.ok(usable != null, "sırası gelen savaşçının kullanılabilir bir yeteneği var")
	if usable == null:
		panel.free()
		return

	panel._on_skill_pressed(usable)
	t.ok(_selectable_count(panel) > 0, "yetenek seçilince hedefler sahnede işaretleniyor")

	# Aynı yeteneğe ikinci basış vazgeçmek: hedef seçmekten dönüş yolu olmalı.
	panel._on_skill_pressed(usable)
	t.eq(_selectable_count(panel), 0, "yeteneğe tekrar basmak seçimi kaldırıyor")

	panel.free()

## Faz 17 PR-7: savaş animasyon katmanı. Bark sinyalinin üçüncü argümanı
## (`kind`) artık bir parlama rengi ve - isabet/kritikte - saldıranın
## kendi tarafına işaretli bir kayma üretiyor. Motoru koşturmaya gerek
## yok: `_on_unit_barked` saf bir eşleme, doğrudan çağrılabiliyor - tıpkı
## `_flash_for_kind`'ın kendisi gibi.
func _test_bark_drives_flash_and_lunge(t) -> void:
	var script = load(PANEL_PATH)
	var panel = script.new()
	panel._ready()

	var party: Array[CharacterData] = []
	for index in 3:
		var character := _companion("K%d" % index)
		if index == 0:
			character.is_player = true
		party.append(character)

	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	panel.start_combat(party, 0.4, rng, "bandit", "")

	var attacker: CombatUnit = panel._encounter.get_active_unit()
	var opposing: Array = (
		panel._encounter.enemy_units if attacker.is_player_side else panel._encounter.player_units
	)
	var target: CombatUnit = opposing[0]

	# Renk eşlemesi: her tanınan tür kendi rengini döner, tanınmayan bir
	# tür (ör. gelecekte eklenecek bir bark) nötre düşer, hiç kırılmaz.
	t.eq(panel._flash_for_kind(CombatEncounter.BARK_CRIT), CombatPanel.FLASH_CRIT, "kritik kendi rengini döner")
	t.eq(panel._flash_for_kind(CombatEncounter.BARK_HIT), CombatPanel.FLASH_HIT, "isabet kendi rengini döner")
	t.eq(panel._flash_for_kind(CombatEncounter.BARK_MISS), CombatPanel.FLASH_MISS, "kaçırma kendi rengini döner")
	t.eq(panel._flash_for_kind(CombatEncounter.BARK_REFUSE), CombatPanel.FLASH_REFUSE, "red kendi rengini döner")
	t.eq(panel._flash_for_kind("bilinmeyen"), CombatPanel.FLASH_NEUTRAL, "tanınmayan tür nötr kalır")

	# İsabet: hedef kendi rengiyle parlar, saldıran kendi tarafına işaretli
	# bir kayma kazanır (oyuncu ileri/pozitif, düşman ileri/negatif).
	panel._on_unit_barked(target, "vur", CombatEncounter.BARK_HIT)
	t.ok(panel._flash_states.has(target), "isabet hedefte parlama kaydı bırakır")
	t.ok(panel._lunge_states.has(attacker), "isabet saldıranda kayma kaydı bırakır")
	var lunge_offset: float = panel._lunge_states[attacker]["offset"]
	if attacker.is_player_side:
		t.ok(lunge_offset > 0.0, "oyuncu tarafı hedefe doğru pozitif kayar")
	else:
		t.ok(lunge_offset < 0.0, "düşman tarafı hedefe doğru negatif kayar")

	# Kaçırma: taze bir hamle olduğu için isabet/kritikle aynı ailede -
	# hedef kendi (soğuk) rengiyle parlar, saldıran yine kayar. HIT'ten tek
	# farkı rengi, mekaniği aynı.
	panel._flash_states.clear()
	panel._lunge_states.clear()
	panel._on_unit_barked(target, "ıska", CombatEncounter.BARK_MISS)
	t.ok(panel._flash_states.has(target), "kaçırma hedefte parlama kaydı bırakır")
	t.eq(panel._flash_states[target]["color"], CombatPanel.FLASH_MISS, "kaçırma kendi rengini taşır")
	t.ok(panel._lunge_states.has(attacker), "kaçırma da saldıranda kayma kaydı bırakır - hamle taze")

	# Red: yalnızca soluk bir parlama - reddin kendisi bir hamle değil,
	# kimse kaymaz.
	panel._flash_states.clear()
	panel._lunge_states.clear()
	panel._on_unit_barked(attacker, "reddet", CombatEncounter.BARK_REFUSE)
	t.ok(panel._flash_states.has(attacker), "red kendi rengiyle parlar")
	t.not_ok(panel._lunge_states.has(attacker), "red kayma üretmez")

	# Süresi geçmiş bir kayıt uygulanınca nötre döner ve kendini siler -
	# `_apply_pending_bark`'ın süre dolunca unutma kuralının aynısı.
	panel._flash_states[target] = {"color": CombatPanel.FLASH_CRIT, "expires_at": 0}
	panel._lunge_states[attacker] = {"offset": CombatPanel.LUNGE_DISTANCE, "expires_at": 0}
	var probe := CombatUnitSlot.new()
	panel._apply_pending_animation(probe, target)
	t.not_ok(panel._flash_states.has(target), "süresi geçen parlama kaydı silinir")
	panel._apply_pending_animation(probe, attacker)
	t.not_ok(panel._lunge_states.has(attacker), "süresi geçen kayma kaydı silinir")
	probe.free()

	panel.free()

func _selectable_count(panel) -> int:
	var count := 0
	for row in [panel._player_row, panel._enemy_row]:
		for slot in row.get_children():
			if slot.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND:
				count += 1
	return count

# --- Durum efektleri ---

## Direnç şansı büker ama hiçbir yönde kapatmaz - aynı kural isabet
## şansında da var (MIN/MAX_HIT_CHANCE). Bir statı yeterince yükselterek
## bir sistemi tamamen kapatabilmek, o sistemi silmek demektir.
func _test_status_resist_never_certain_never_impossible(t) -> void:
	var unit := CombatUnit.new()
	unit.bleed_resist = 999
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var landed := 0
	for _attempt in 600:
		if unit.roll_status(CombatUnit.STATUS_BLEED, 100, rng):
			landed += 1
	t.ge(float(landed), 1.0, "sınırsız direnç bile kanamayı imkânsız kılmamalı")
	t.le(float(landed), 120.0, "yüksek direnç kanamayı belirgin şekilde azaltmalı")

	var fragile := CombatUnit.new()
	fragile.bleed_resist = -999
	var missed := 0
	for _attempt in 600:
		if not fragile.roll_status(CombatUnit.STATUS_BLEED, 10, rng):
			missed += 1
	t.ge(float(missed), 1.0, "sıfır direnç bile kanamayı garanti kılmamalı")

## Buradaki asıl iddia: **sersemletme zincirlenemez.** Zincirlenebilseydi
## tek doğru strateji her turda aynı hedefi sersemletmek olurdu ve
## savaşın geri kalanı silinirdi (aynı gerekçe pazarlıkta "aynı düşük
## teklifi üç kez yapmak" kapatılırken de vardı).
func _test_stun_cannot_be_chained(t) -> void:
	var unit := CombatUnit.new()
	var before := unit.get_status_resist(CombatUnit.STATUS_STUN)

	unit.apply_status(CombatUnit.STATUS_STUN, 0, 1)
	t.ok(unit.is_stunned, "sersemletme uygulanmalı")
	unit.consume_stun()
	t.not_ok(unit.is_stunned, "sersemlik bir tur sonra kalkmalı")
	# İddia **kesin olarak daha yüksek** olmak zorunda. İlk yazışta
	# `before + STUN_RECOVERY_RESIST` ile karşılaştırıyordum, yani
	# korumak istediği sabitin kendisini kullanıyordu: sabit sıfıra
	# çekilince iddia sessizce geçiyordu. Mutasyonla yakalandı - ve bu
	# tam olarak CLAUDE.md'nin "formülü değil sömürüyü doğrula"
	# maddesinin anlattığı hata.
	t.ok(
		unit.get_status_resist(CombatUnit.STATUS_STUN) > before,
		"sersemlikten çıkan savaşçı bir süre daha dirençli olmalı"
	)
	t.ge(
		float(CombatUnit.STUN_RECOVERY_RESIST), 20.0,
		"koruma anlamlı olacak kadar büyük olmalı, yoksa zincirleme açık kalır"
	)
	t.ge(
		float(CombatUnit.STUN_RECOVERY_ROUNDS), 1.0,
		"koruma en az bir tur sürmeli"
	)

	# Direnç kalıcı değil: iki tur sonra normale dönüyor, yoksa
	# sersemletme bir kez kullanılıp bir daha işe yaramayan bir yetenek
	# olurdu.
	for _round in CombatUnit.STUN_RECOVERY_ROUNDS:
		unit.tick_statuses()
	t.eq(
		unit.get_status_resist(CombatUnit.STATUS_STUN), before,
		"koruma süresi bitince direnç normale dönmeli"
	)

## Aynı türden ikinci bir efekt üst üste binmiyor, yeniliyor. Binse iki
## kanama tek kanamanın iki katı hasar verirdi ve doğru strateji yine
## "hep aynı şeyi yap" olurdu.
func _test_dot_does_not_stack_with_itself(t) -> void:
	var unit := CombatUnit.new()
	unit.apply_status(CombatUnit.STATUS_BLEED, 3, 2)
	unit.apply_status(CombatUnit.STATUS_BLEED, 2, 4)
	t.eq(unit.drain_status_damage(), 3, "kanama üst üste binmemeli, en güçlüsü kalmalı")
	t.eq(
		unit.get_status_rounds(CombatUnit.STATUS_BLEED), 4,
		"süre uzayabilmeli - yenilemek bunun için var"
	)

	# Kanama ve zehir *birlikte* binebiliyor: ikisi ayrı sistem, ikisini
	# de açmak gerçek bir taktik.
	unit.apply_status(CombatUnit.STATUS_BLIGHT, 4, 2)
	t.eq(unit.drain_status_damage(), 7, "kanama ve zehir ayrı ayrı işlemeli")

## Kanama hasarı `apply_damage`tan geçmeli: zırh, Ölümün Kıyısı ve
## ölümcül vuruş zarı orada. İkinci bir hasar kapısı, kanamanın zırhı
## bilmemesi demekti.
func _test_dot_goes_through_the_one_damage_door(t) -> void:
	var armoured := CombatUnit.from_character(_companion(), 1)
	armoured.protection = 50
	armoured.max_hp = 100
	armoured.current_hp = 100
	armoured.apply_status(CombatUnit.STATUS_BLEED, 10, 3)

	var drained := armoured.drain_status_damage()
	t.eq(drained, 10, "kanama kendi ham hasarını bildirmeli")
	t.eq(
		armoured.reduce_by_protection(drained), 5,
		"zırh kanamayı da kesmeli - hasarın tek kapısı olmasının sebebi bu"
	)

	# Kanama da tek hasar kapısından geçtiği için yoldaşı da kıyıya
	# sokabilir, zar atılmadan öldüremez: aynı kapı, aynı kural.
	armoured.current_hp = 2
	var outcome := armoured.apply_damage(999, null)
	t.eq(outcome, "deaths_door", "kanama da yoldaşı kıyıya sokabilir")
	t.not_ok(armoured.is_dead, "zarsız çağrıda ölüm yok")

	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	armoured.deathblow_resist = 0
	t.eq(armoured.apply_damage(1, rng), "killed", "kıyıdayken gelen kanama da öldürebilir")
	t.ok(armoured.is_dead, "yoldaş da kalıcı ölebilir - kural artık lidere özel değil")

## Efekt hedefin *kendi turu başında* işliyor. Tur sonunda işlemek aynı
## şey değil: o zaman kanayan biri kanamadan önce vuruyor ve hasar bir
## tur geç geliyor.
func _test_dot_ticks_at_the_start_of_the_turn(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	var encounter := _build_encounter(rng, 2, 2)
	# `start()` şart: çağrılmadan aktif birim bir düşman olabiliyor ve
	# `pass_turn()` düşman için false dönüyor - döngü hiç ilerlemiyor.
	# İlk yazışta bu atlanmıştı ve test "kanama işlemiyor" diyordu, oysa
	# kanama işliyordu. Harnesse güvenmeden önce harnessi kontrol et.
	encounter.start()

	var victim := encounter.get_active_unit()
	t.ok(victim != null, "sıradaki birim olmalı")
	victim.apply_status(CombatUnit.STATUS_BLEED, 7, 2)
	var hp_before: int = victim.current_hp

	# Sırayı bir tam tur döndürüyoruz; kurbanın sırası tekrar gelince
	# kanaması işlemiş olmalı.
	var guard := 0
	while encounter.get_active_unit() == victim and guard < 40:
		guard += 1
		encounter.pass_turn()
	guard = 0
	while encounter.get_active_unit() != victim and guard < 40 and not encounter.is_over():
		guard += 1
		encounter.pass_turn()

	t.le(
		float(victim.current_hp), float(hp_before - 1),
		"sırası gelen birim kanamasını turun başında yemiş olmalı"
	)

## Dayanıklılık dirence dönüşüyor ve taban sıfır değil: sıfır olsa taze
## bir karakter her vuruşta kanardı, yani kanama bir seçenek olmaktan
## çıkıp her saldırıya binen bir ek hasar olurdu.
func _test_endurance_buys_status_resistance(t) -> void:
	var fresh := CharacterStats.new()
	t.ge(float(fresh.get_bleed_resist()), 1.0, "taze karakterin de bir direnci olmalı")

	var tough := CharacterStats.new()
	tough.endurance = 15
	t.ge(
		float(tough.get_bleed_resist()), float(fresh.get_bleed_resist() + 10),
		"Dayanıklılık kanama direncini belirgin şekilde artırmalı"
	)
	t.ge(
		float(tough.get_blight_resist()), float(fresh.get_blight_resist()),
		"zehir direnci de Dayanıklılıkla artmalı"
	)
	t.ge(
		float(tough.get_stun_resist()), float(fresh.get_stun_resist()),
		"sersemletme direnci de Dayanıklılıkla artmalı"
	)
	# Zehre direnmek kanamaya direnmekten daha zor - iki katsayının
	# farklı olması bilinçli, aynı olsa iki durum aynı şey olurdu.
	t.le(
		float(tough.get_blight_resist()), float(tough.get_bleed_resist()),
		"zehir kanamadan daha zor dirençlenmeli"
	)

## Katalogdaki her durum efekti motorun tanıdığı üçünden biri olmalı.
## Tanımadığı bir ad sessizce hiçbir şey yapar - `EventEffect.Type`'ın
## ölü tipiyle aynı tuzak, ve o tuzak bu depoda bir kez kapandı
## (WAGON_LOSE hiç kullanılmıyordu).
func _test_every_status_a_skill_can_apply_is_handled(t) -> void:
	var known := [
		CombatUnit.STATUS_BLEED, CombatUnit.STATUS_BLIGHT, CombatUnit.STATUS_STUN
	]
	var used := {}
	for skill in SkillCatalog.get_all_skills():
		if not skill.has_status():
			continue
		t.ok(
			known.has(skill.status_kind),
			"%s tanınmayan bir durum yazıyor: %s" % [skill.skill_id, skill.status_kind]
		)
		t.ok(skill.status_chance > 0, "%s: durum şansı sıfır olamaz" % skill.skill_id)
		if skill.status_kind != CombatUnit.STATUS_STUN:
			t.ok(
				skill.status_amount > 0,
				"%s: hasar veren durumun miktarı sıfır olamaz" % skill.skill_id
			)
		used[skill.status_kind] = true
	# Üçünün de en az bir kaynağı olmalı: kullanılmayan bir durum, ölü
	# bir efekt tipinden farksızdır.
	for kind in known:
		t.ok(used.has(kind), "hiçbir yetenek '%s' uygulamıyor - ölü sistem" % kind)

## Süreli değiştiricinin adı bilinmeyen bir sayıysa `_modifier_sum` onu hiç
## okumaz - yetenek kullanılır, kayıtta görünür, hiçbir şey olmaz.
func _test_every_modifier_stat_is_handled(t) -> void:
	for skill in SkillCatalog.get_all_skills():
		if not skill.has_modifier():
			continue
		t.ok(
			CombatUnit.MODIFIER_STATS.has(skill.modifier_stat),
			"%s tanınmayan bir değiştirici yazıyor: %s" % [skill.skill_id, skill.modifier_stat]
		)

## Sınıf kimliği: yalnızca Kalem Efendisi iyileştirir ve iki sınıf aynı
## sayıyı aynı yönde bükmez (biri zırh verir, biri kaçınma, biri hasar, biri
## isabet; bozanlar da ayrı). Üç sınıfın aynı kaçınma buff'ını taşıdığı ve
## muhafızın şifacıdan iyi sardığı hâle geri dönülmesin diye.
func _test_each_class_owns_its_axes(t) -> void:
	var buff_owner := {}
	var debuff_owner := {}
	for character_class in ClassCatalog.get_classes():
		for skill in SkillCatalog.get_skills(character_class.skill_ids):
			if skill.is_heal():
				t.eq(
					character_class.class_id, ClassCatalog.CLERK,
					"%s iyileştiriyor - iyileştirme Kalem Efendisi'nin" % skill.skill_id
				)
			if not skill.has_modifier():
				continue
			var owners: Dictionary = buff_owner if skill.modifier_amount > 0 else debuff_owner
			var stat := skill.modifier_stat
			if owners.has(stat):
				t.eq(
					owners[stat], character_class.class_id,
					"'%s' iki sınıfta birden: %s ve %s" % [stat, owners[stat], character_class.class_id]
				)
			else:
				owners[stat] = character_class.class_id

## Zırh değiştiricisi tek hasar kapısından geçiyor ve zırhı hiçbir yönde
## tavanın dışına itemiyor.
func _test_prot_modifier_bends_the_damage_door(t) -> void:
	var unit := CombatUnit.new()
	unit.max_hp = 100
	unit.current_hp = 100
	unit.protection = 20
	var base := unit.reduce_by_protection(20)
	unit.apply_modifier("prot", -25, 2)
	t.eq(unit.get_effective_protection(), 0, "kırılan zırh sıfırın altına inmez")
	t.ok(unit.reduce_by_protection(20) > base, "kırılan zırhtan daha çok hasar geçer")
	unit.apply_modifier("prot", 500, 2)
	t.eq(unit.get_effective_protection(), CombatUnit.MAX_PROT, "zırh tavanı aşamaz")
	unit.tick_modifiers()
	unit.tick_modifiers()
	t.eq(unit.get_effective_protection(), 20, "süre dolunca zırh eski hâline döner")

# --- Alan hedefleme ve mevki kaydırma ---

## Alan yeteneği tek hedefe vurandan **zayıf** olmalı. Güçlü olsaydı tek
## doğru seçim o olur, mevki tasarımı ve hedef seçimi silinirdi - aynı
## gerekçe pazarlıkta "hep aynı teklifi yap" kapatılırken de vardı.
##
## Motora genel bir "alan yetenekleri %60 hasar verir" çarpanı koymak
## yerine katalogda ayarlanıyor, o yüzden burada katalog taranıyor.
func _test_area_skills_never_beat_single_target(t) -> void:
	# Karşılaştırma **taraf içinde**: oyuncunun alan yeteneği oyuncunun
	# tek hedeflisiyle, düşmanın düşmanınkiyle. Hepsini tek havuzda
	# karşılaştırmak ilk yazışta yapılan hataydı ve testi ayı pençesi
	# üzerinden düşürdü - oysa oradaki soru "düşman çok mu vuruyor"
	# değil, "aynı tarafta bir seçim diğerini eziyor mu".
	var player_ids := {}
	for character_class in ClassCatalog.get_classes():
		for skill_id in character_class.skill_ids:
			player_ids[skill_id] = true

	var best_single := {true: 0, false: 0}
	var area_skills: Array[CombatSkill] = []
	for skill in SkillCatalog.get_all_skills():
		if skill.target_kind != CombatSkill.Target.ENEMY or skill.is_heal():
			continue
		var is_player: bool = player_ids.has(skill.skill_id)
		if skill.area == CombatSkill.Area.ADJACENT or skill.area == CombatSkill.Area.ALL:
			area_skills.append(skill)
		else:
			best_single[is_player] = maxi(int(best_single[is_player]), skill.base_damage)

	t.ge(float(area_skills.size()), 1.0, "en az bir alan yeteneği olmalı - yoksa sistem ölü")
	for skill in area_skills:
		var owner: bool = player_ids.has(skill.skill_id)
		t.ok(
			skill.base_damage < int(best_single[owner]),
			"%s alan yeteneği aynı taraftaki tek hedeflilerden güçlü olmamalı (%d vs %d)" % [
				skill.skill_id, skill.base_damage, int(best_single[owner])
			]
		)

## Komşuluk *mevkiye* göre: saf yeniden paketlendiğinde dizi sırası
## mevkiyle örtüşmeyebiliyor, o yüzden diziye göre komşuluk yanlış
## hedefleri toplardı.
func _test_adjacent_hits_only_neighbours(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var encounter := _build_encounter(rng, 1, 4)
	encounter.start()

	var sweep := SkillCatalog.get_skill(SkillCatalog.SWEEPING_BLOW)
	t.ok(sweep != null, "savuran darbe katalogda olmalı")
	t.eq(sweep.area, CombatSkill.Area.ADJACENT, "savuran darbe komşulara vurmalı")

	var attacker := encounter.player_units[0]
	attacker.skills = [sweep]
	var middle: CombatUnit = encounter.enemy_units[1]
	var affected := encounter._affected_targets(attacker, sweep, middle)

	t.ge(float(affected.size()), 2.0, "komşu mevkiler de etkilenmeli")
	for unit in affected:
		t.le(
			float(absi(unit.position - middle.position)), 1.0,
			"yalnızca komşu mevkiler etkilenmeli (%s)" % unit.display_name
		)
	# Menzil dışı bir mevki komşu olsa bile giremez: alan, yeteneğin
	# kendi menzilini genişletmiyor.
	for unit in affected:
		t.ok(sweep.can_reach(unit.position), "alan menzili aşmamalı")

## Rastgele hedefleme seçimi zara bırakıyor ama boşa harcanan bir tur
## üretmiyor: geçerli bir hedef varsa mutlaka birine vuruyor. Aksi hâlde
## zar atmanın kendisi ceza olurdu.
func _test_random_targeting_never_wastes_a_turn(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 606
	var encounter := _build_encounter(rng, 4, 1)
	encounter.start()

	var wild := SkillCatalog.get_skill(SkillCatalog.BANDIT_ORDER)
	t.eq(wild.area, CombatSkill.Area.RANDOM, "haydut reisinin sallaması rastgele olmalı")

	var attacker := encounter.enemy_units[0]
	attacker.skills = [wild]
	var hit_counts := {}
	for _attempt in 200:
		var affected := encounter._affected_targets(attacker, wild, null)
		t.eq(affected.size(), 1, "rastgele hedefleme tam bir hedef seçmeli")
		hit_counts[affected[0].display_name] = true
	t.ge(
		float(hit_counts.size()), 2.0,
		"rastgele hedefleme gerçekten farklı hedeflere düşmeli"
	)

## Kaydırmadan sonra mevkiler 1'den başlayan kesintisiz bir dizi
## kalmalı. Kalmazsa itilen bir düşman hiçbir yeteneğin menziline
## girmez ve savaş kilitlenir - aynı sınıf tehlike RouteConditions'ın
## "hiçbir şehir kapatılamaz" kuralında da vardı.
func _test_shift_keeps_ranks_contiguous(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var encounter := _build_encounter(rng, 1, 4)

	var push := CombatSkill.with_area(
		CombatSkill.make_attack("probe_push", "N", "D", [1], [1, 2, 3, 4], 1, 0),
		CombatSkill.Area.SINGLE, 1
	)
	var pull := CombatSkill.with_area(
		CombatSkill.make_attack("probe_pull", "N", "D", [1], [1, 2, 3, 4], 1, 0),
		CombatSkill.Area.SINGLE, -3
	)

	for skill in [push, pull, push, push, pull]:
		encounter._apply_skill_shift(skill, encounter.enemy_units[0])
		var seen := {}
		for unit in encounter.enemy_units:
			t.ok(
				unit.position >= 1 and unit.position <= CombatEncounter.MAX_SIDE_SIZE,
				"mevki sahada kalmalı: %d" % unit.position
			)
			t.not_ok(seen.has(unit.position), "iki birim aynı mevkide olamaz")
			seen[unit.position] = true
		t.eq(seen.size(), encounter.enemy_units.size(), "mevkiler kesintisiz olmalı")

## Kaydırma bir birimi sahadan çıkarmıyor: sonuna itilen de başa çekilen
## de hâlâ hedeflenebilir olmalı.
func _test_shift_cannot_remove_a_unit_from_the_field(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 88
	var encounter := _build_encounter(rng, 1, 3)
	var far_push := CombatSkill.with_area(
		CombatSkill.make_attack("probe_far", "N", "D", [1], [1, 2, 3, 4], 1, 0),
		CombatSkill.Area.SINGLE, 99
	)
	var target := encounter.enemy_units[0]
	encounter._apply_skill_shift(far_push, target)
	t.le(
		float(target.position), float(encounter.enemy_units.size()),
		"birim safın dışına itilmemeli"
	)
	t.ge(float(target.position), 1.0, "mevki bire eşit ya da büyük kalmalı")

	# Tek başına kalan bir düşman kaydırılamaz (kaydıracak yer yok) ama
	# bu bir hata değil, sessiz bir no-op olmalı.
	var lone := _build_encounter(rng, 1, 1)
	var only := lone.enemy_units[0]
	lone._apply_skill_shift(far_push, only)
	t.eq(only.position, 1, "tek düşman birinci mevkide kalmalı")

## Kendine yönelik bir kaydırma kullananı yerinden oynatıyor; saf yine
## kesintisiz kalıyor ve tek başına duran biri hiçbir yere gitmiyor.
func _test_self_shift_moves_the_user(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var encounter := _build_encounter(rng, 3, 1)
	var step := CombatSkill.with_area(CombatSkill.make_buff(
		"probe_step", "N", "D", CombatSkill.Target.SELF, [1, 2, 3, 4], [],
		"dodge", 5, 1
	), CombatSkill.Area.SINGLE, 1)
	var user := encounter.player_units[0]
	t.eq(user.position, 1, "başlangıçta önde")
	encounter._resolve_on_target(user, step, user)
	t.eq(user.position, 2, "geri adım kullananı bir mevki geriye alır")
	t.eq(user.get_effective_dodge(), 5, "değiştirici de uygulanır")
	var seen := {}
	for unit in encounter.player_units:
		seen[unit.position] = true
	t.eq(seen.size(), 3, "saf kesintisiz kalır")

	var lone := _build_encounter(rng, 1, 1)
	var alone := lone.player_units[0]
	lone._resolve_on_target(alone, step, alone)
	t.eq(alone.position, 1, "tek kişilik saf yer değiştirmez")
