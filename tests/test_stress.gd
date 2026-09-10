extends RefCounted

## Parti stresi: kırılma zarı, emir reddi, kamp ve STRESS olay etkisi.
## Moral (CaravanState.morale) sefer başına sıfırlanır; stres tam tersi -
## GameSession'da kalıcıdır, yalnızca şehir dinlenmesi ya da kamp azaltır.

func suite_name() -> String:
	return "Stress"

func run(t) -> void:
	_test_change_stress_clamps(t)
	_test_stress_resistance_scales_with_endurance(t)
	_test_resolve_stress_breaks(t)
	_test_resolve_stress_breaks_skips_calm_party(t)
	_test_make_camp(t)
	_test_stress_event_effect(t)
	_test_stressed_unit_sometimes_refuses(t)
	_test_calm_unit_never_refuses(t)
	_test_city_rest_no_longer_erases_a_journey(t)
	_test_newcomer_dilutes_party_stress(t)
	_test_feast_costs_gold_and_relieves(t)
	_test_brawl_threshold_is_reachable(t)
	_test_composure(t)

func _test_change_stress_clamps(t) -> void:
	var session := GameSession.new(100, 0, 1)
	t.eq(session.party_stress, 0, "sefer başlamadan stres sıfır")

	session.change_stress(150)
	t.eq(session.party_stress, GameSession.MAX_STRESS, "stres tavanı aşmaz")

	session.change_stress(-500)
	t.eq(session.party_stress, 0, "stres negatife düşmez")

func _test_stress_resistance_scales_with_endurance(t) -> void:
	var low := CharacterData.new()
	low.stats = CharacterStats.new()
	low.stats.endurance = 1

	var baseline := CharacterData.new()
	baseline.stats = CharacterStats.new()

	var high := CharacterData.new()
	high.stats = CharacterStats.new()
	high.stats.endurance = CharacterStats.MAX_VALUE

	t.ok(low.get_stress_resistance() < baseline.get_stress_resistance(), "düşük dayanıklılık direnci düşürür")
	t.ok(high.get_stress_resistance() > baseline.get_stress_resistance(), "yüksek dayanıklılık direnci artırır")

	t.not_ok(baseline.is_stressed(0), "stressiz kervan kimseyi kırmaz")
	t.ok(baseline.is_stressed(GameSession.MAX_STRESS), "tavan stres herkesi kırar")

func _test_resolve_stress_breaks(t) -> void:
	var session := GameSession.new(200, 0, 2)
	var leader := session.get_player_character()
	leader.stats = CharacterStats.new()
	leader.stats.endurance = 1  # düşük direnç: kolay kırılsın

	var companion := CharacterData.new()
	companion.character_name = "Yoldaş"
	companion.class_id = ClassCatalog.GUARD
	companion.stats = CharacterStats.new()
	companion.stats.endurance = 1
	session.party.append(companion)

	session.party_stress = GameSession.MAX_STRESS
	session.total_days_elapsed = 20

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var results := session.resolve_stress_breaks(rng)

	t.eq(results.size(), 2, "tavan streste herkes kırılır")
	for entry in results:
		var data: Dictionary = entry
		t.ok(data.has("affliction"), "sonuç kutbu bildiriyor")
		if not String(data.trait_id).is_empty():
			var granted_trait := TraitCatalog.get_trait(data.trait_id)
			t.eq(granted_trait.is_positive, not bool(data.affliction), "verilen huyun kutbu zar sonucuyla eşleşir")

	# Oyuncu hiçbir zaman ayrılmaz.
	var leader_entry: Dictionary = {}
	for entry in results:
		if String((entry as Dictionary).character_name) == leader.character_name:
			leader_entry = entry
	t.not_ok(bool(leader_entry.get("departed", false)), "oyuncu kırılsa da kervanı terk etmez")

func _test_resolve_stress_breaks_skips_calm_party(t) -> void:
	var session := GameSession.new(100, 0, 1)
	session.party_stress = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var results := session.resolve_stress_breaks(rng)
	t.eq(results.size(), 0, "stres sıfırken kimse kırılmaz")

func _test_make_camp(t) -> void:
	var session := GameSession.new(100, 5, 1)
	session.party_stress = 50

	var result := session.make_camp()
	t.eq(result.provisions_spent, GameSession.CAMP_PROVISIONS_COST, "kamp erzak yer")
	t.eq(session.get_provisions(), 5 - GameSession.CAMP_PROVISIONS_COST, "erzak düşer")
	t.eq(session.party_stress, 50 - GameSession.CAMP_STRESS_RELIEF, "stres belirgin azalır")

	var poor_session := GameSession.new(100, 1, 1)
	var poor_result := poor_session.make_camp()
	t.eq(poor_result.provisions_spent, 1, "erzak yetmezse olanın hepsi harcanır, borca girilmez")
	t.eq(poor_session.get_provisions(), 0, "erzak negatife düşmez")

func _test_stress_event_effect(t) -> void:
	var session := GameSession.new(100, 0, 1)
	session.party_stress = 40

	var relief: Array[EventEffect] = [EventEffect.make(EventEffect.Type.STRESS, -15)]
	EventEffectApplier.apply(relief, session)
	t.eq(session.party_stress, 25, "olumlu STRESS etkisi azaltır")

	var strain: Array[EventEffect] = [EventEffect.make(EventEffect.Type.STRESS, 30)]
	EventEffectApplier.apply(strain, session)
	t.eq(session.party_stress, 55, "olumsuz STRESS etkisi artırır")

func _make_hero(hero_name: String) -> CharacterData:
	return CharacterData.create(hero_name, CultureCatalog.VALLEY, CharacterStats.new())

func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

## Tek çekiliş yerine kırk bağımsız tohumda ezici marj kullanılıyor - aynı
## gerekçe test_event_engine.gd'nin tohum-tekrarlanabilirlik testinde ve
## test_traits.gd'nin seed dağıtım testinde de geçerli.
func _test_stressed_unit_sometimes_refuses(t) -> void:
	var refusal_seen := false
	for seed_value in 40:
		var unit := CombatUnit.from_character(_make_hero("Gergin"), 1, true)
		var enemy := CombatUnit.from_enemy(EnemyCatalog.get_enemy(EnemyCatalog.CUTTER), 1)
		var rng := _seeded_rng(9500 + seed_value)
		var encounter := CombatEncounter.new([unit], [enemy], rng)

		# Lambda'lar dış yerel değişkeni değere göre yakalar, referansa göre
		# değil - içeride atama dıştaki değişkeni değiştirmez. Tek elemanlı
		# bir Array paylaşılan bir kutu gibi davranır, bu yüzden çalışır.
		var refused := [false]
		encounter.log_added.connect(func(line): refused[0] = refused[0] or ("kulak asmıyor" in line))
		encounter.start()

		if refused[0]:
			refusal_seen = true
			break
	t.ok(refusal_seen, "kırk denemede stresli birim en az bir kez emir dinlemiyor")

func _test_calm_unit_never_refuses(t) -> void:
	for seed_value in 15:
		var unit := CombatUnit.from_character(_make_hero("Sakin"), 1, false)
		var enemy := CombatUnit.from_enemy(EnemyCatalog.get_enemy(EnemyCatalog.CUTTER), 1)
		var rng := _seeded_rng(9700 + seed_value)
		var encounter := CombatEncounter.new([unit], [enemy], rng)

		var refused := [false]
		encounter.log_added.connect(func(line): refused[0] = refused[0] or ("kulak asmıyor" in line))
		encounter.start()

		t.not_ok(refused[0], "stressiz birim hiç emir reddetmez (tohum %d)" % seed_value)

## --- Stresin seferler arası birikmesi (Faz 9 sonrası) ---
## Eskiden şehir varışı 35 puan götürüyordu ve tipik bir sefer ~25-30
## biriktiriyordu, yani stres hiç birikmiyor, evt_stress_brawl hiç
## ateşlenmiyordu. Aşağıdakiler o düzeltmenin kilitleri.

func _test_city_rest_no_longer_erases_a_journey(t) -> void:
	var session := GameSession.new(300, 0, 1)
	t.ok(
		session.get_city_rest_relief() < 30,
		"şehirde dinlenmek bir seferin getirdiğini tek başına silmiyor"
	)

	# Rahatlama günlerle eriyor: aynı han odası geç oyunda daha az iyi geliyor.
	var seasoned := GameSession.new(300, 0, 1)
	seasoned.total_days_elapsed = 300
	t.ok(
		seasoned.get_city_rest_relief() < session.get_city_rest_relief(),
		"birikme gittikçe artar - rahatlama günlerle erir"
	)
	t.ok(
		seasoned.get_city_rest_relief() >= GameSession.CITY_REST_RELIEF_MIN,
		"ama dinlenmek hiçbir zaman tamamen işe yaramaz hale gelmez"
	)

## Kadroya katılan biri ortalamayı aşağı çeker - `party_stress` kadronun
## ortalaması, tek bir kişinin sayacı değil.
func _test_newcomer_dilutes_party_stress(t) -> void:
	var session := GameSession.new(500, 0, 2)
	session.set_player_character(CharacterData.create("Lider", CultureCatalog.VALLEY, CharacterStats.new()))
	session.change_stress(80)
	var before := session.party_stress

	var newcomer := CharacterData.create("Taze", CultureCatalog.VALLEY, CharacterStats.new())
	session.add_to_party(newcomer)
	t.ok(session.party_stress < before, "katılan biri ortalamayı seyreltir")
	t.ok(
		session.party_stress > 0,
		"ama sıfırlamaz - batmış bir kervana katılan anlatılanları duyar"
	)

	# Kadro yenilendikçe birikme azalır, ama her tur daha az kazandırır ve
	# hiçbir zaman sıfıra inmez: "gönder-yenisini tut" bedava bir sıfırlama
	# düğmesi olmamalı.
	var cycles: Array[int] = []
	for _cycle in 4:
		var companion := session.party[session.party.size() - 1]
		session.dismiss(companion)
		session.add_to_party(CharacterData.create("Yeni", CultureCatalog.VALLEY, CharacterStats.new()))
		cycles.append(session.party_stress)
	for index in range(1, cycles.size()):
		t.ok(cycles[index] <= cycles[index - 1], "her yenileme turu stresi düşürür ya da sabit tutar")
	t.ok(cycles[cycles.size() - 1] > 0, "sonsuz yenileme stresi sıfırlamaz")

	# Boş partiye katılan ilk kişi seyreltme yapmaz - bölecek bir ortalama yok.
	# Gerçek oyunda parti hiç boş kalmıyor (GameSession.new zaten bir oyuncu
	# karakteri kuruyor), bu yüzden koruma elle boşaltılarak sınanıyor.
	var empty := GameSession.new(100, 0, 1)
	empty.party.clear()
	empty.change_stress(50)
	empty.add_to_party(CharacterData.create("İlk", CultureCatalog.VALLEY, CharacterStats.new()))
	t.eq(empty.party_stress, 50, "ilk üye ortalamayı değiştirmez")

	# Aynı kişiyi iki kez eklemek seyreltmemeli.
	var guarded := GameSession.new(100, 0, 1)
	guarded.set_player_character(CharacterData.create("Lider", CultureCatalog.VALLEY, CharacterStats.new()))
	guarded.change_stress(60)
	var twice := CharacterData.create("Tek", CultureCatalog.VALLEY, CharacterStats.new())
	guarded.add_to_party(twice)
	var after_first := guarded.party_stress
	guarded.add_to_party(twice)
	t.eq(guarded.party_stress, after_first, "aynı kişi iki kez eklenip stres sömürülemez")

## Ziyafet: stresin paralı kolu. Birikme artık şehir varışının tek başına
## eritemeyeceği kadar hızlı, o yüzden kesenin bir müdahale yolu olmalı.
func _test_feast_costs_gold_and_relieves(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.set_player_character(CharacterData.create("Lider", CultureCatalog.VALLEY, CharacterStats.new()))
	session.change_stress(60)

	var cost := session.get_feast_cost()
	t.ok(cost > 0, "ziyafetin bir bedeli var")
	t.ok(session.can_afford_feast(), "kese yetiyorsa ziyafet verilebilir")

	var gold_before := session.wallet.balance
	t.ok(session.throw_feast(), "ziyafet uygulanır")
	t.eq(session.wallet.balance, gold_before - cost, "bedeli keseden düşer")
	t.eq(
		session.party_stress, 60 - GameSession.FEAST_STRESS_RELIEF,
		"ziyafet stresi düşürür"
	)

	# Kalabalık kadroyu doyurmak pahalı.
	session.add_to_party(CharacterData.create("Yoldaş", CultureCatalog.VALLEY, CharacterStats.new()))
	t.ok(session.get_feast_cost() > cost, "kadro büyüdükçe ziyafet pahalanır")

	# Günde bir: sınırsız bırakıldığında beş ziyafet 225 GG'ye stresi
	# sıfırlıyordu - bir seferin net kazancının altında bir bedelle.
	t.ok(session.has_feasted_today(), "ziyafet günü işaretlenir")
	t.not_ok(session.can_afford_feast(), "aynı gün ikinci ziyafet verilemez")
	t.not_ok(session.throw_feast(), "aynı gün ikinci ziyafet uygulanmaz")
	session.total_days_elapsed += 1
	t.ok(session.can_afford_feast(), "ertesi gün yeniden ziyafet verilebilir")

	# Kayda yazılmalı: yeniden yükleyip aynı gün tekrar ziyafet vermek
	# sayacı sıfırlayan bir sömürü olurdu.
	var reloaded := GameSession.new(0, 0, 1)
	reloaded.load_from_dict(session.to_save_dict())
	t.eq(
		reloaded.last_feast_day, session.last_feast_day,
		"son ziyafet günü kayıttan döner"
	)

	# Parası olmayan ziyafet veremez; stresi olmayanın da ziyafete ihtiyacı yok.
	var broke := GameSession.new(0, 0, 1)
	broke.change_stress(50)
	t.not_ok(broke.can_afford_feast(), "parasızken ziyafet verilemez")
	t.not_ok(broke.throw_feast(), "parasız ziyafet uygulanmaz")

	var calm := GameSession.new(1000, 0, 1)
	t.not_ok(calm.can_afford_feast(), "stresi olmayan kadroya ziyafet gerekmez")

## Eşik gerçekten görülebilir olmalı - moraldeki isyanla aynı ders.
func _test_brawl_threshold_is_reachable(t) -> void:
	t.ok(
		EventCatalog.STRESS_BRAWL_THRESHOLD < GameSession.MAX_STRESS,
		"eşik tavanın altında"
	)

	# Asıl iddia: stres seferler arası **birikiyor**. Sefer başına ~25 stres
	# (simülatörün ölçtüğü ortalama) biriktiren bir kervanda her sefer sonrası
	# değer bir öncekinden yüksek olmalı, ve birkaç sefer içinde eşik görülmeli.
	var session := GameSession.new(500, 0, 1)
	var after_each: Array[int] = []
	for _journey in 5:
		session.change_stress(25)
		session.change_stress(-session.get_city_rest_relief())
		after_each.append(session.party_stress)

	for index in range(1, after_each.size()):
		t.ok(
			after_each[index] > after_each[index - 1],
			"stres seferden sefere birikiyor - şehir varışı onu silmiyor"
		)
	t.ok(
		after_each[after_each.size() - 1] >= EventCatalog.STRESS_BRAWL_THRESHOLD,
		"birkaç sefer sonra stres kavga eşiğine ulaşır"
	)

	# Ziyafet ve kamp birikmeyi geri çevirebilmeli - yoksa stres kaçınılmaz
	# bir sayaç olurdu.
	var relieved := GameSession.new(2000, 0, 1)
	relieved.change_stress(70)
	relieved.throw_feast()
	t.ok(relieved.party_stress < 70, "ziyafet birikmeyi geri çevirir")

## Karizma'nın savaştaki tek karşılığı: kırılmış bir savaşçının emri
## reddetme ihtimalini düşürmesi.
##
## Karizma altı stat içinde savaşa hiçbir şey vermeyen tekiydi ve Kalem
## Efendisi'nin afinitesinin yarısıydı - o sınıfın seviye puanlarının yarısı
## savaşta ölü harcamaydı. Çözümün şekli Wartales'in Willpower'ından:
## seviyeyle büyümesi şart değil, ama bir karşılığı olmak zorunda.
func _test_composure(t) -> void:
	var plain := CharacterStats.new()
	t.eq(plain.get_composure(), 0, "taban Karizma'da sükûnet nötr")

	var talker := CharacterStats.new()
	talker.set_value(CharacterStats.Kind.CHARISMA, 10)
	t.ok(talker.get_composure() > 0, "Karizma sükûneti yükseltir")

	var shy := CharacterStats.new()
	shy.set_value(CharacterStats.Kind.CHARISMA, 1)
	t.ok(shy.get_composure() < 0, "düşük Karizma sükûneti düşürür")

	# Savaş CharacterData sarmalayıcısını okumalı, stats'ı doğrudan değil.
	var character := CharacterData.create("Tellal", CultureCatalog.VALLEY, talker)
	t.eq(
		character.get_composure(), talker.get_composure(),
		"CharacterData sükûneti aynen taşır"
	)
	var unit := CombatUnit.from_character(character, 1, true)
	t.eq(unit.composure, character.get_composure(), "CombatUnit sükûneti karakterden alır")

	# Düşmanların sükûneti yok - stres yalnızca oyuncu tarafında anlamlı.
	var enemy := CombatUnit.from_enemy(EnemyCatalog.get_enemy(EnemyCatalog.CUTTER), 1)
	t.eq(enemy.composure, 0, "düşmanlarda sükûnet nötr")

	# Ve stres asla bedavaya gelmemeli: sükûnet ne kadar yüksek olursa olsun
	# reddetme ihtimali tabanın altına inmez, yoksa tek stat bütün bir
	# sistemi kapatırdı.
	var saintly := CharacterStats.new()
	saintly.set_value(CharacterStats.Kind.CHARISMA, CharacterStats.MAX_VALUE)
	t.ok(
		saintly.get_composure() < CombatEncounter.STRESS_REFUSAL_CHANCE,
		"en yüksek Karizma bile reddetme ihtimalini sıfırlamaz"
	)
	t.ge(
		float(CombatEncounter.MIN_STRESS_REFUSAL_CHANCE), 1.0,
		"reddetme ihtimalinin tabanı sıfır değil"
	)
