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
