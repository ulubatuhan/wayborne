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
	_test_battlefield_is_a_field_not_a_list(t)
	_test_status_resist_never_certain_never_impossible(t)
	_test_stun_cannot_be_chained(t)
	_test_dot_does_not_stack_with_itself(t)
	_test_dot_goes_through_the_one_damage_door(t)
	_test_dot_ticks_at_the_start_of_the_turn(t)
	_test_endurance_buys_status_resistance(t)
	_test_every_status_a_skill_can_apply_is_handled(t)

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
	panel.start_combat(party, 0.4, rng, 0, "bandit", "")

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

	# Yoldaş (lider değil) kanamadan ölmez, düşer: "yalnızca lider
	# ölebilir" kuralı durum efektleri için de geçerli.
	armoured.current_hp = 2
	var outcome := armoured.apply_damage(999, null)
	t.eq(outcome, "downed", "yoldaş kanamadan ölmemeli, düşmeli")
	t.not_ok(armoured.is_dead, "yoldaş ölü işaretlenmemeli")

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
