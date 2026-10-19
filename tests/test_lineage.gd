extends RefCounted

## Soy omurgası: kervanın adı liderden uzun yaşar.
##
## Bu paketin koruduğu asıl iddia şu: **lider ölmek oyunu bitirmez, adı
## taşıyacak kimse kalmaması bitirir.** Oyunun kazanma koşulu bir süre
## `GOAL_GOLD` idi ve o, oyunu kendi tezine rağmen bir ticaret
## simülasyonu olarak çerçeveliyordu; kaldırıldı.
##
## Defterin de tek bir kuralı var ve testin yarısı onu koruyor: hiçbir
## satır silinmez. Ayrılan biri listeden çıkmaz, üstü çizilir.

func suite_name() -> String:
	return "Lineage"

func run(t) -> void:
	_test_founder_is_recorded(t)
	_test_succession_keeps_the_name(t)
	_test_run_ends_only_without_an_heir(t)
	_test_ledger_never_deletes(t)
	_test_lineage_survives_a_save(t)
	_test_inherited_from_father(t)
	_test_road_memory(t)

func _session() -> GameSession:
	var session := GameSession.new(500, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	session.start_playthrough(
		CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng
	)
	return session

func _companion(name_text: String, level: int = 1) -> CharacterData:
	var companion := CharacterData.create(name_text, CultureCatalog.VALLEY, CharacterStats.new())
	companion.level = level
	return companion

func _test_founder_is_recorded(t) -> void:
	var session := _session()
	t.eq(session.get_caravan_name(), "Kurucu", "kervan kurucusunun adını taşır")
	t.eq(session.lineage_generation, 1, "ilk lider birinci kuşaktır")
	t.eq(
		session.ledger.count_of(CaravanLedger.KIND_LED), 1,
		"kurucunun devralışı deftere yazılır"
	)

func _test_succession_keeps_the_name(t) -> void:
	var session := _session()
	var leader := session.get_player_character()
	var heir := _companion("Varis", 5)
	session.add_to_party(heir)
	session.add_to_party(_companion("Çırak", 1))

	var outcome := session.resolve_combat_deaths([leader] as Array[CharacterData])

	t.eq(outcome["new_leader"], heir, "en kıdemli yoldaş liderliği alır")
	t.not_ok(outcome["run_over"], "varis varken oyun bitmez")
	t.eq(session.lineage_generation, 2, "kuşak ilerler")
	t.eq(session.get_caravan_name(), "Kurucu", "ad liderle birlikte değişmez")
	t.ok(heir.is_player, "varis artık oyuncu karakteridir")
	t.eq(
		session.ledger.count_of(CaravanLedger.KIND_DIED), 1,
		"ölüm deftere yazılır"
	)
	t.eq(
		session.ledger.count_of(CaravanLedger.KIND_LED), 2,
		"devir deftere yazılır"
	)

	# Dönem sayacı sıfırlanır: kampanya "bu liderin dönemi" diye sorabilsin.
	session.total_days_elapsed = session.leader_since_day + 12
	t.eq(session.get_days_as_leader(), 12, "dönem yeni liderle sıfırdan sayılır")

func _test_run_ends_only_without_an_heir(t) -> void:
	var session := _session()
	# start_playthrough bir yoldaş veriyor; onu da çıkarıp lideri yalnız
	# bırakıyoruz, yoksa sınanan şey "varis yok" değil olurdu.
	while session.party.size() > 1:
		session.dismiss(session.party[session.party.size() - 1])

	var leader := session.get_player_character()
	var outcome := session.resolve_combat_deaths([leader] as Array[CharacterData])

	t.ok(outcome["run_over"], "yerine geçecek kimse yoksa oyun biter")
	t.ok(session.is_run_over(), "bayrak kurulur - Devam Et kapalı seferi yüklemesin")
	t.eq(session.lineage_generation, 1, "devredilemeyen liderlik kuşağı ilerletmez")

func _test_ledger_never_deletes(t) -> void:
	var session := _session()
	var companion := _companion("Geçici")
	session.add_to_party(companion)
	var joined := session.ledger.count_of(CaravanLedger.KIND_JOINED)

	session.dismiss(companion)

	t.eq(
		session.ledger.count_of(CaravanLedger.KIND_JOINED), joined,
		"ayrılmak katılma satırını silmez"
	)
	t.eq(
		session.ledger.count_of(CaravanLedger.KIND_DEPARTED), 1,
		"ayrılık kendi satırını yazar"
	)

	var story := session.ledger.entries_for("Geçici")
	t.eq(story.size(), 2, "bir kişinin bütün hikâyesi defterde durur")
	t.ok(
		session.ledger.is_struck(story[1]),
		"ayrılmış bir satırın üstü çizilidir - kayıt silinmez"
	)
	t.not_ok(session.ledger.is_struck(story[0]), "katılma satırı çizili değildir")

	# En yeni önce: defteri açan oyuncunun sorusu "en son ne oldu".
	var recent := session.ledger.recent(1)
	t.eq(recent.size(), 1, "sınır uygulanır")
	t.eq(String(recent[0]["kind"]), CaravanLedger.KIND_DEPARTED, "en yeni satır önce gelir")

func _test_lineage_survives_a_save(t) -> void:
	var session := _session()
	session.add_to_party(_companion("Yoldaş"))
	session.total_days_elapsed = 40
	session.lineage_generation = 3
	session.leader_since_day = 25

	var restored := GameSession.new(0, 0, 1)
	restored.load_from_dict(session.to_save_dict())

	t.eq(restored.get_caravan_name(), "Kurucu", "ad kayıtta yaşar")
	t.eq(restored.lineage_generation, 3, "kuşak kayıtta yaşar")
	t.eq(restored.get_days_as_leader(), 15, "dönem kayıttan doğru hesaplanır")
	t.eq(
		restored.ledger.entries.size(), session.ledger.entries.size(),
		"defterin tamamı kayıtta yaşar"
	)

## Babadan borçlu kervan (görev Y-C14): devir borcu, vadesi ve kurucu satırı.
func _test_inherited_from_father(t) -> void:
	var session := GameSession.new(250, 20, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var hero := CharacterData.create("Varis", CultureCatalog.VALLEY, CharacterStats.new())
	session.start_playthrough(hero, rng)
	t.eq(session.get_total_debt(), 0, "devirden önce borç yok")
	session.inherit_father_caravan()
	var debt := session.debts.get_debt(GameSession.FATHER_DEBT_ID)
	t.ok(debt != null, "babanın borcu deftere yazılı")
	t.eq(debt.principal, GameSession.FATHER_DEBT_PRINCIPAL, "borcun tutarı sabit")
	t.eq(debt.due_day, GameSession.FATHER_DEBT_TERM_DAYS, "vade ilk dönemin sonu")
	t.eq(debt.creditor_name, GameSession.FATHER_CREDITOR_KEY, "alacaklı babanın alacaklısı")
	var founder: Dictionary = session.ledger.entries[0]
	t.eq(String(founder["kind"]), CaravanLedger.KIND_FOUNDER, "defterin ilk satırı kurucu")
	t.eq(String(founder["cause"]), GameSession.FATHER_CAUSE_KEY, "kurucu satırı babayı söylüyor")
	t.ok(not session.get_father_name().is_empty() and session.get_father_name() != hero.character_name, "babanın adı oyuncununkinden ayrı")
	t.ok(InheritancePanel.text_for(session).contains(session.get_father_name()), "devir sahnesi babayı adıyla anar")
	t.ok(InheritancePanel.text_for(session).contains(str(GameSession.FATHER_DEBT_PRINCIPAL)), "devir sahnesi borcu söyler")
	session.inherit_father_caravan()
	t.eq(session.get_total_debt(), GameSession.FATHER_DEBT_PRINCIPAL, "ikinci çağrı borcu ikilemez")
	t.eq(session.get_companions_lost(), 0, "baba kayıp sayılmaz (finalin kayıp kapısı satın alınmaz)")
	var copy := GameSession.new(0, 0)
	copy.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	var loaded := copy.debts.get_debt(GameSession.FATHER_DEBT_ID)
	t.ok(loaded != null and loaded.due_day == GameSession.FATHER_DEBT_TERM_DAYS, "borç ve vadesi kayıttan döner")

## Yolun hafızası (Y-B11, R2): yolda ölen mezar, düşen lider taş, kaybedilen
## vagon enkaz, kamp kül bırakır; konum yönsüzdür (öbür yönden aynı yer),
## yol başına sınırlıdır, kayıttan döner; yol kaç kez yüründüğünü hatırlar.
func _test_road_memory(t) -> void:
	var session := GameSession.new(400, 60, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	var origin := session.current_location_id
	var destination := WorldMapData.get_routes_from(origin)[0].to_location_id
	var key := RouteConditions.route_key(origin, destination)
	t.not_ok(session.add_memorial(GameSession.MEMORIAL_ASH), "yolda değilken anıt olmaz")
	session.start_journey(destination, 10, 0.2, CaravanPlan.new(WorldMapData.get_location_by_id(destination), 10))
	session.set_road_position(key, origin, 3.0, 10)
	var companion: CharacterData = null
	for c in session.get_party():
		if not c.is_player:
			companion = c
	var dead: Array[CharacterData] = [companion]
	session.resolve_deaths(dead, "LEDGER_CAUSE_STARVED")
	var graves := session.memorials_on(key)
	t.eq(graves.size(), 1, "yolda ölen yolda kalır")
	t.eq(String(graves[0]["kind"]), GameSession.MEMORIAL_GRAVE, "mezar")
	var share := float(graves[0]["share"])
	t.almost(GameSession.day_for_share(key, origin, share, 10), 3.0, "gidiş yönünde aynı gün")
	t.almost(GameSession.day_for_share(key, destination, share, 10), 7.0, "dönüş yönünde aynı yer, öbür uçtan sayılır")
	session.caravan.wagon_count = 3
	var lose: Array[EventEffect] = [EventEffect.make(EventEffect.Type.WAGON_LOSE, 1)]
	EventEffectApplier.apply(lose, session)
	t.eq(session.memorials_on(key).size(), 2, "kaybedilen vagon enkaz bırakır")
	for i in GameSession.MEMORIALS_PER_ROUTE + 4:
		session.add_memorial(GameSession.MEMORIAL_ASH)
	t.eq(session.memorials_on(key).size(), GameSession.MEMORIALS_PER_ROUTE, "yol başına sınırlı")
	var kinds := {}
	for m in session.memorials_on(key):
		kinds[String(m["kind"])] = true
	t.ok(kinds.has(GameSession.MEMORIAL_GRAVE), "taşınca önce kül düşer, mezar kalır")
	var copy := GameSession.new(0, 0)
	copy.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	t.eq(copy.memorials_on(key).size(), session.memorials_on(key).size(), "anıtlar kayıttan döner")
	session.finish_journey()
	t.eq(int(session.route_memory[key]["trips"]), 1, "yol kaç kez yüründüğünü hatırlar")
	t.eq(int(session.route_memory[key]["deaths"]), 1, "yol ölümü hatırlar")
	t.ok(session.road_position.is_empty(), "varışta kervan yoldan çıkar")
