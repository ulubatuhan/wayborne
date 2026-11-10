extends RefCounted

## İz defteri (İz alt sistemi, tasarım notu §C.1 ve §D.3).
##
## Sınanan şey formül değil **hesap**: bir kararın vadesi gelince geri
## dönmesi, dönerken doğduğu yeri ya da kişiyi adıyla anması, dönmeyen izin
## sönmesi, defterin tavanda yalan söylememesi ve kaydın gidiş-dönüşte
## hiçbir alanını kaybetmemesi.

func suite_name() -> String:
	return "İz"

func run(t) -> void:
	_test_birth_and_source(t)
	_test_same_source_grows_instead_of_doubling(t)
	_test_cap_does_not_silently_drop_accounts(t)
	_test_fading_closes_the_account(t)
	_test_price_return_moves_the_market(t)
	_test_face_return_names_a_person(t)
	_test_one_return_per_arrival(t)
	_test_save_round_trip(t)
	_test_old_save_opens_with_empty_ledger(t)
	_test_profiteering_leaves_a_trace(t)
	_test_context_reads_open_accounts(t)

func _session() -> GameSession:
	var session := GameSession.new(400, 40, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	session.start_playthrough(
		CharacterData.create("Lider", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	return session

func _leave(session: GameSession, tur: String, donus: String, yon: int = 1) -> Trace:
	session.note_trace_action("sinama")
	return session.leave_trace(
		tur, Trace.BEARER_CITY, session.current_location_id, yon,
		Trace.DELAY_SHORT, donus)

func _test_birth_and_source(t) -> void:
	var session := _session()
	session.note_decision("evt_test", "EVT_TEST_OPT")
	var trace := session.leave_trace(
		Trace.TYPE_GRATITUDE, Trace.BEARER_CITY, session.current_location_id, 1,
		Trace.DELAY_SHORT, Trace.RETURN_PRICE)
	t.ok(trace != null, "iz doğdu")
	t.eq(trace.kaynak, "evt_test|EVT_TEST_OPT", "iz kaynağını taşıyor")
	t.eq(trace.dogum_yeri, session.current_location_id, "doğum yeri yazıldı")
	t.ok(trace.olgunluk_gunu >= session.total_days_elapsed + 15,
		"kısa vade en erken 15 gün sonra olgunlaşır")
	t.ok(trace.olgunluk_gunu <= session.total_days_elapsed + 70, "kısa vade 70 günü aşmaz")
	t.eq(trace.sonme, float(Trace.TYPE_TABLE[Trace.TYPE_GRATITUDE]["sonme"]), "sönme türden geliyor")

func _test_same_source_grows_instead_of_doubling(t) -> void:
	var session := _session()
	var first := _leave(session, Trace.TYPE_GRUDGE, Trace.RETURN_PRICE, -1)
	var before: float = first.siddet
	var second := _leave(session, Trace.TYPE_GRUDGE, Trace.RETURN_PRICE, -1)
	t.eq(second.id, first.id, "aynı kaynak ikinci izi açmıyor")
	t.ok(first.siddet > before, "tekrar eden davranış aynı hesabı büyütüyor")

func _test_cap_does_not_silently_drop_accounts(t) -> void:
	var session := _session()
	for index in 40:
		session.note_trace_action("sinama%d" % index)
		session.leave_trace(
			Trace.TYPE_GRUDGE, Trace.BEARER_CITY, "sehir%d" % index, -1,
			Trace.DELAY_SHORT, Trace.RETURN_PRICE)
	t.ok(session.traces.open_count() <= TraceLedger.MAX_OPEN,
		"açık iz tavanı aşılmıyor (%d)" % session.traces.open_count())
	var short_open := 0
	for trace in session.traces.open_traces():
		if trace.gecikme == Trace.DELAY_SHORT:
			short_open += 1
	t.ok(short_open <= int(TraceLedger.MAX_OPEN_BY_DELAY[Trace.DELAY_SHORT]),
		"gecikme başına tavan tutuyor")

func _test_fading_closes_the_account(t) -> void:
	var session := _session()
	var trace := _leave(session, Trace.TYPE_RUMOR, Trace.RETURN_PRICE)
	trace.siddet = 0.05
	session.traces.advance_day(session.total_days_elapsed)
	t.eq(trace.durum, Trace.STATE_FADED, "kimsenin hatırlamaması da bir sonuçtur")
	t.not_ok(trace.is_open(), "sönen iz artık açık değil")

func _test_price_return_moves_the_market(t) -> void:
	var session := _session()
	var where := session.current_location_id
	var trace := _leave(session, Trace.TYPE_GRUDGE, Trace.RETURN_PRICE, -1)
	trace.olgunluk_gunu = session.total_days_elapsed
	var note := session.resolve_trace_return()
	t.eq(String(note.get("bicim", "")), Trace.RETURN_PRICE, "fiyat dönüşü işlendi")
	t.eq(trace.durum, Trace.STATE_RETURNED, "dönen iz kapandı")
	t.ok(session.market.is_shocked(where, ItemCatalog.get_trade_goods()[0].item_id,
		session.total_days_elapsed), "tezgâh kervanı tanıdı")
	# Nedensellik denetimi (§G.4): dönüş doğduğu yeri adıyla anar.
	var location := WorldMapData.get_location_by_id(where)
	var last_line := String(session.journal[session.journal.size() - 1]["text"])
	t.ok(last_line.contains(location.location_name), "dönüşün cümlesi yeri adıyla anıyor")

func _test_face_return_names_a_person(t) -> void:
	var session := _session()
	var trace := _leave(session, Trace.TYPE_GRATITUDE, Trace.RETURN_FACE)
	trace.olgunluk_gunu = session.total_days_elapsed
	var note := session.resolve_trace_return()
	t.eq(String(note.get("bicim", "")), Trace.RETURN_FACE, "yüz dönüşü işlendi")
	t.ok(not String(session.waiting_face.get("kisi", "")).is_empty(), "kapıda bekleyen biri var")
	var person := session.people.person(String(session.waiting_face["kisi"]))
	var last_line := String(session.journal[session.journal.size() - 1]["text"])
	t.ok(last_line.contains(String(person.get("name", ""))), "dönüşün cümlesi kişiyi adıyla anıyor")

func _test_one_return_per_arrival(t) -> void:
	var session := _session()
	for index in 3:
		session.note_trace_action("sinama%d" % index)
		var trace := session.leave_trace(
			Trace.TYPE_GRUDGE, Trace.BEARER_CITY, session.current_location_id, -1,
			Trace.DELAY_SHORT, Trace.RETURN_PRICE)
		trace.olgunluk_gunu = session.total_days_elapsed
	t.ok(not session.resolve_trace_return().is_empty(), "ilk dönüş geldi")
	var returned := 0
	for trace in session.traces.traces:
		if trace.durum == Trace.STATE_RETURNED:
			returned += 1
	t.eq(returned, 1, "günde bir ağır an: ikinci iz sırasını bekliyor")

func _test_save_round_trip(t) -> void:
	var session := _session()
	var trace := _leave(session, Trace.TYPE_GRUDGE, Trace.RETURN_FACE, -1)
	trace.add_knower("baska_sehir")
	var data := session.to_save_dict()
	t.eq(int(data["version"]), GameSession.SAVE_VERSION, "kayıt sürümü güncel")
	var loaded := GameSession.new()
	loaded.load_from_dict(data)
	var copy := loaded.traces.get_trace(trace.id)
	t.ok(copy != null, "iz kayıttan döndü")
	t.eq(copy.kaynak, trace.kaynak, "kaynak korundu")
	t.eq(copy.olgunluk_gunu, trace.olgunluk_gunu, "vade korundu")
	t.ok(copy.knows("baska_sehir"), "bilenler korundu")
	t.eq(loaded.traces.serial, session.traces.serial, "seri korundu: kimlikler çakışmaz")

func _test_old_save_opens_with_empty_ledger(t) -> void:
	var session := _session()
	var data := session.to_save_dict()
	data.erase("izler")
	data["version"] = 4
	var loaded := GameSession.new()
	loaded.load_from_dict(data)
	t.eq(loaded.traces.open_count(), 0, "eski kayıt boş defterle açılıyor")
	t.eq(loaded.traces.serial, 0, "geriye dönük iz uydurulmuyor")

func _test_profiteering_leaves_a_trace(t) -> void:
	var session := _session()
	var before := session.traces.open_count()
	session._remember_trade(MarketConditions.MEDICINE_ITEM, 1, true)
	t.eq(session.traces.open_count(), before + 1, "vurgun bir hesap açıyor")
	var trace: Trace = session.traces.open_traces()[session.traces.open_count() - 1]
	t.eq(trace.tur, Trace.TYPE_GRUDGE, "vurgunun izi kindir")
	t.eq(trace.donus, Trace.RETURN_PRICE, "karşılığı tezgâhta gelir")
	t.eq(trace.yon, -1, "iz kervanın aleyhine")

func _test_context_reads_open_accounts(t) -> void:
	var session := _session()
	var trace := _leave(session, Trace.TYPE_GRUDGE, Trace.RETURN_PRICE, -1)
	var context := session.build_event_context()
	t.ok(context.has("iz_kin_burada"), "bağlamda kin izi var")
	t.eq(float(context["iz_kin_burada"]), trace.siddet, "burada bilinen kinin şiddeti okunuyor")
	t.eq(int(context["iz_acik"]), session.traces.open_count(), "açık hesap sayısı bağlamda")
