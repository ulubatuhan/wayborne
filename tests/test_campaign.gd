extends RefCounted

## Kampanya omurgası. Oyunun sonu olan bir hikâyesi var ama son bölüm oyunu
## kapatmıyor - bu paketin asıl işi o iki iddiayı birden korumak:
##
##   1. Hikâye **ilerliyor**: bölümler sırayla, varışta, hedefleri
##      karşılandığında kapanıyor.
##   2. Hikâye **bitiriyor ama kapatmıyor**: son bölümden sonra kervan
##      eskisi gibi ticaret yapmaya devam edebiliyor.
##
## Bir de sessizce bozulabilecek üç şey: bölüm hedefleri kervanın
## *ömrünü* okumalı (yol bağlamını okusaydı her varışta sıfırlanırdı),
## kapanan bölüm bir daha açılmamalı (parayı harcamak hikâyeyi geri
## almamalı) ve ilerleme kayda yazılmalı (yoksa yeniden yükleyen oyuncu
## hikâyeyi baştan oynardı).

func suite_name() -> String:
	return "Campaign"

func run(t) -> void:
	_test_catalog_shape(t)
	_test_objectives_read_career_keys(t)
	_test_chapters_close_in_order(t)
	_test_one_arrival_can_close_several(t)
	_test_a_closed_chapter_never_reopens(t)
	_test_finale_does_not_end_the_game(t)
	_test_progress_reports_counts_not_just_done(t)
	_test_campaign_survives_a_save_round_trip(t)
	_test_old_saves_start_at_the_first_chapter(t)

func _session() -> GameSession:
	return GameSession.new(0, 10, 1)

# --- Katalog ---

func _test_catalog_shape(t) -> void:
	var chapters := CampaignCatalog.get_chapters()
	t.ok(chapters.size() >= 3, "kampanyada birden fazla bölüm var")
	t.eq(chapters.size(), CampaignCatalog.chapter_count(), "sayı kataloğun kendisiyle tutarlı")

	var ids := {}
	var flags := {}
	var finales := 0
	for chapter in chapters:
		t.ok(not chapter.chapter_id.is_empty(), "bölümün kimliği var")
		t.not_ok(ids.has(chapter.chapter_id), "bölüm kimlikleri benzersiz: %s" % chapter.chapter_id)
		ids[chapter.chapter_id] = true

		t.ok(not chapter.title_key.is_empty(), "%s: başlık anahtarı var" % chapter.chapter_id)
		t.ok(not chapter.summary_key.is_empty(), "%s: anlatı anahtarı var" % chapter.chapter_id)
		t.ok(not chapter.objective_key.is_empty(), "%s: hedef anahtarı var" % chapter.chapter_id)
		t.ok(not chapter.objectives.is_empty(), "%s: en az bir hedef taşıyor" % chapter.chapter_id)

		# Bayrak olay havuzuna açılan kapı; iki bölüm aynı bayrağı kurarsa
		# hangisinin açtığı belirsizleşir.
		t.ok(not chapter.completion_flag.is_empty(), "%s: bitiş bayrağı var" % chapter.chapter_id)
		t.not_ok(flags.has(chapter.completion_flag), "bitiş bayrakları benzersiz")
		flags[chapter.completion_flag] = true

		if chapter.is_finale:
			finales += 1

	t.eq(finales, 1, "tam olarak bir final bölümü var")
	t.ok(chapters[chapters.size() - 1].is_finale, "final en sonda")

## Hedefler kervanın ömrünü anlatan anahtarlara bakmalı. Yol bağlamının
## anahtarına (`danger`, `days_remaining`, `morale`...) bakan bir hedef her
## varışta kervan sıfırlandığı için tamamlanıp tamamlanmamaya dönerdi.
func _test_objectives_read_career_keys(t) -> void:
	var context := _session().build_campaign_context()
	for chapter in CampaignCatalog.get_chapters():
		for condition in chapter.objectives:
			t.ok(
				context.has(condition.key),
				"%s hedefi kampanya bağlamında var: %s" % [chapter.chapter_id, condition.key]
			)
			t.ok(
				CampaignCatalog.OBJECTIVE_LABEL_KEYS.has(condition.key),
				"%s hedefinin okunur adı var: %s" % [chapter.chapter_id, condition.key]
			)

# --- İlerleyiş ---

func _test_chapters_close_in_order(t) -> void:
	var session := _session()
	t.eq(session.campaign_chapter_index, 0, "ilk bölümden başlanır")
	t.eq(
		session.get_current_chapter().chapter_id, CampaignCatalog.CHAPTER_FIRST_ROAD,
		"açılış bölümü ilk yol"
	)

	# Hiçbir hedef karşılanmadan hiçbir şey kapanmaz.
	t.eq(session.advance_campaign().size(), 0, "hedefsiz varış bölüm kapatmaz")
	t.eq(session.campaign_chapter_index, 0, "sıra yerinde durur")

	session.journeys_completed = 1
	session.contracts_delivered = 1
	var closed := session.advance_campaign()
	t.eq(closed.size(), 1, "hedefler karşılanınca bölüm kapanır")
	t.eq(session.campaign_chapter_index, 1, "sıra ilerler")
	t.ok(
		session.has_flag(CampaignCatalog.FLAG_FIRST_ROAD),
		"bitiş bayrağı kuruldu - olaylar bunu okuyabilir"
	)

## Uzun bir sefer iki hedefi birden karşılayabilir; oyuncuyu "bir varış =
## bir bölüm" diye bekletmenin bir sebebi yok.
func _test_one_arrival_can_close_several(t) -> void:
	var session := _session()
	session.journeys_completed = 20
	session.contracts_delivered = 20
	session.reputation = 30
	session.visited_location_ids = {"a": true, "b": true, "c": true, "d": true, "e": true}
	session.owned_wagon_count = 4
	session.wallet.earn(5000)
	while session.party.size() < 3:
		session.add_to_party(_companion())

	var closed := session.advance_campaign()
	t.eq(
		closed.size(), CampaignCatalog.chapter_count(),
		"her şeyi karşılayan bir varış bütün bölümleri kapatır"
	)
	t.ok(session.is_campaign_finished(), "kampanya bitti")
	t.eq(session.get_current_chapter(), null, "bitmiş kampanyanın açık bölümü yok")

## Hedef "2500 altın" ise, parayı sonra harcamak hikâyeyi geri almamalı.
func _test_a_closed_chapter_never_reopens(t) -> void:
	var session := _session()
	session.journeys_completed = 1
	session.contracts_delivered = 1
	t.eq(session.advance_campaign().size(), 1, "ilk bölüm kapandı")

	session.journeys_completed = 0
	session.contracts_delivered = 0
	t.eq(session.campaign_chapter_index, 1, "sayaç geri düşse de sıra geri gitmez")
	t.ok(session.has_flag(CampaignCatalog.FLAG_FIRST_ROAD), "bayrak da kalıcı")

## "Sonu olan hikâye" oyunun sonu değil: kese, yol ve pazar olduğu gibi
## durur. Son bölüm kapandıktan sonra bir sefer daha tamamlanabilmeli.
func _test_finale_does_not_end_the_game(t) -> void:
	var session := _session()
	session.campaign_chapter_index = CampaignCatalog.chapter_count()
	t.ok(session.is_campaign_finished(), "hikâye bitmiş sayılır")

	var before := session.wallet.balance
	session.wallet.earn(100)
	t.eq(session.wallet.balance, before + 100, "bitiş sonrası kese hâlâ çalışıyor")
	t.eq(session.advance_campaign().size(), 0, "kapanacak bölüm kalmadı, hata da yok")
	t.ok(session.can_recruit() or session.party.size() > 0, "kervan hâlâ ayakta")

	# Ve varış akışı bitmiş kampanyada da sorunsuz dönmeli.
	t.eq(session.advance_campaign().size(), 0, "tekrar çağırmak da güvenli")

func _test_progress_reports_counts_not_just_done(t) -> void:
	var session := _session()
	session.contracts_delivered = 1
	var chapter := CampaignCatalog.get_chapter(0)
	var rows := chapter.describe_progress(session.build_campaign_context())
	t.eq(rows.size(), chapter.objectives.size(), "her hedef için bir satır")

	var numeric := 0
	for row in rows:
		if bool(row.numeric):
			numeric += 1
			t.ge(float(row.target), 0.0, "hedefin sayısal karşılığı taşınıyor")
	t.ok(numeric > 0, "sayaç hedefleri mevcut değeriyle birlikte bildiriliyor")

	var met := 0
	for row in rows:
		if bool(row.met):
			met += 1
	t.eq(met, 1, "yalnızca karşılanan hedef tamam görünür")

# --- Kalıcılık ---

## İlerleme kayda yazılmazsa yeniden yükleyen oyuncu hikâyeyi baştan
## oynar - kampanya için bu, stres sayacının sıfırlanmasıyla aynı hata.
func _test_campaign_survives_a_save_round_trip(t) -> void:
	var session := _session()
	session.journeys_completed = 3
	session.contracts_delivered = 5
	session.visited_location_ids = {"a": true, "b": true}
	session.advance_campaign()
	var index_before := session.campaign_chapter_index

	var restored := GameSession.new(0, 0, 1)
	restored.load_from_dict(session.to_save_dict())

	t.eq(restored.campaign_chapter_index, index_before, "bölüm sırası kayıttan döner")
	t.eq(restored.journeys_completed, 3, "sefer sayacı kayıttan döner")
	t.eq(restored.contracts_delivered, 5, "teslimat sayacı kayıttan döner")
	t.ge(
		float(restored.build_campaign_context()["cities_visited"]), 2.0,
		"görülen şehirler kayıttan döner"
	)

## Kampanyayı bilmeyen eski bir kayıt ilk bölümden başlar ve çökmez.
func _test_old_saves_start_at_the_first_chapter(t) -> void:
	var session := _session()
	var data := session.to_save_dict()
	data.erase("campaign_chapter_index")
	data.erase("journeys_completed")
	data.erase("contracts_delivered")
	data.erase("visited_location_ids")

	var restored := GameSession.new(0, 0, 1)
	restored.load_from_dict(data)
	t.eq(restored.campaign_chapter_index, 0, "eski kayıt ilk bölümden başlar")
	t.eq(restored.journeys_completed, 0, "sayaçlar sıfırdan")
	t.eq(
		restored.build_campaign_context()["cities_visited"], 1,
		"bulunduğun şehir görülmüş sayılır"
	)

func _companion() -> CharacterData:
	return CharacterData.create("Yoldaş", "gocebe", CharacterStats.new())
