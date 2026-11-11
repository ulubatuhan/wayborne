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
	_test_rumor_takes_twelve_days_per_hop(t)
	_test_closed_and_gated_regions(t)
	_test_open_gate_and_closed_gate(t)
	_test_volunteer_costs_nothing_and_comes_cracked(t)
	_test_refusal_closes_one_service_with_a_reason(t)
	_test_deserted_hand_waits_on_the_road(t)
	_test_promise_has_a_term_a_witness_and_a_price(t)
	_test_three_promises_is_the_ceiling(t)
	_test_hardship_costs_more_but_closes_nothing(t)

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

# --- §D-İ2: söz yol alır ---

func _neighbours(place_id: String) -> Array[String]:
	var out: Array[String] = []
	for route in WorldMapData.get_routes_from(place_id):
		out.append(route.to_location_id)
	return out

func _region_of(place_id: String) -> String:
	var location := WorldMapData.get_location_by_id(place_id)
	return location.region if location != null else ""

func _test_rumor_takes_twelve_days_per_hop(t) -> void:
	var session := _session()
	var trace := _leave(session, Trace.TYPE_RUMOR, Trace.RETURN_PRICE, -1)
	var known_before: int = trace.bilenler.size()
	session.traces.spread_day(session.total_days_elapsed + 1, _neighbours, _region_of)
	t.eq(trace.bilenler.size(), known_before, "söz ertesi gün komşu şehre varmıyor")
	var strength_before: float = trace.siddet
	session.traces.spread_day(
		trace.dogum_gunu + TraceLedger.SPREAD_DAYS, _neighbours, _region_of)
	t.eq(trace.bilenler.size(), known_before + 1, "on iki günde bir komşu duydu")
	t.ok(trace.siddet < strength_before, "her atlamada söz zayıflıyor")

## Tanınma mesafelidir: ahit toprağı dışarıdan söylenti almaz, göçebe
## toprağına yalnız Orbeyan üzerinden haber ulaşır.
func _test_closed_and_gated_regions(t) -> void:
	var session := _session()
	var trace := _leave(session, Trace.TYPE_RUMOR, Trace.RETURN_PRICE, -1)
	trace.bilenler.clear()
	# Ahit'in komşusundan Ahit'e: kapı kapalı.
	var outside := ""
	for route in WorldMapData.get_routes_from("orvahel"):
		outside = route.to_location_id
		break
	t.ok(not outside.is_empty(), "Orvahel'in komşusu var")
	trace.add_knower(outside)
	trace.son_yayilma_gunu = 0
	session.traces.spread_day(TraceLedger.SPREAD_DAYS, _neighbours, _region_of)
	t.not_ok(trace.knows("orvahel"), "ahit toprağına dışarıdan söylenti girmiyor")
	# Göçebe toprağına yalnız Orbeyan üzerinden.
	t.ok(TraceLedger.GATE_PLACE == "serai_orbeyan", "göçebe kapısı Orbeyan")

# --- §D-İ3: kalan dönüş biçimleri ---

func _ripe(session: GameSession, donus: String, yon: int = 1) -> Trace:
	var trace := _leave(session, Trace.TYPE_GRATITUDE if yon > 0 else Trace.TYPE_GRUDGE, donus, yon)
	trace.olgunluk_gunu = session.total_days_elapsed
	return trace

func _test_open_gate_and_closed_gate(t) -> void:
	var session := _session()
	var cost_before: int = session.get_lodging_cost()
	t.ok(cost_before > 0, "konaklamanın bir bedeli var")
	_ripe(session, Trace.RETURN_GATE, 1)
	t.eq(String(session.resolve_trace_return().get("bicim", "")), Trace.RETURN_GATE, "kapı döndü")
	t.eq(session.get_lodging_cost(), 0, "açılan kapı bir geceyi bedava kılıyor")

	var hard := _session()
	hard.total_days_elapsed = 30
	_ripe(hard, Trace.RETURN_GATE, -1)
	var day_before: int = hard.total_days_elapsed
	hard.resolve_trace_return()
	t.eq(hard.total_days_elapsed, day_before + 1, "kapanan kapı bir gün yiyor")

func _test_volunteer_costs_nothing_and_comes_cracked(t) -> void:
	var session := _session()
	_ripe(session, Trace.RETURN_CANDIDATE, 1)
	var note := session.resolve_trace_return()
	t.eq(String(note.get("bicim", "")), Trace.RETURN_CANDIDATE, "aday döndü")
	var found: CharacterData = null
	for candidate in session.get_recruit_candidates(RecruitCatalog.VENUE_TAVERN):
		if candidate.character_name == session.volunteer_name:
			found = candidate
	t.ok(found != null, "gönüllü panoda")
	t.eq(found.hire_cost, 0, "gönüllü ücret istemiyor")
	t.ok(found.catlak > 0.0, "gönüllü çatlağıyla geliyor")

func _test_refusal_closes_one_service_with_a_reason(t) -> void:
	var session := _session()
	_ripe(session, Trace.RETURN_REFUSAL, -1)
	session.resolve_trace_return()
	t.ok(GameSession.REFUSED_SERVICES.has(session.refused_service), "bir hizmet kapandı")
	if session.refused_service == GameSession.REFUSED_HIRE:
		session.crew_missing = 1
		t.eq(session.get_crew_hire_block_reason(), "UI_SERVICE_REFUSED_HIRE",
			"kapanma sebebiyle yazılıyor, sessizce değil")

func _test_deserted_hand_waits_on_the_road(t) -> void:
	var session := _session()
	var routes := WorldMapData.get_routes_from(session.current_location_id)
	if routes.is_empty():
		return
	var destination := WorldMapData.get_location_by_id(routes[0].to_location_id)
	session.start_journey(routes[0].to_location_id, 5, 0.3, CaravanPlan.new(destination, 5))
	session.note_trace_action("ac_birakma")
	var trace: Trace = session.leave_trace(
		Trace.TYPE_GRUDGE, Trace.BEARER_ROAD, session.current_route_id(), -1,
		Trace.DELAY_SHORT, Trace.RETURN_ENEMY, -1.0, "", false)
	trace.bedel_odeyen = "Dağılan El"
	trace.olgunluk_gunu = session.total_days_elapsed
	var note := session.resolve_trace_return()
	t.eq(String(note.get("bicim", "")), Trace.RETURN_ENEMY, "düşman dönüşü yolda işlendi")
	t.eq(session.waiting_enemy, "Dağılan El", "yolu kesen grupta tanıdık yüz var")
	t.eq(session.pending_trace_card, GameSession.DESERTER_FACE_EVENT, "kart açılmayı bekliyor")
	var filled := EventText.fill(tr("EVT_DESERTER_FACE_TEXT"), session)
	t.ok(filled.contains("Dağılan El"), "kart onun adını okuyor")

# --- §D-A5: söz, ve §D-A3: sertlik kapısı ---

func _test_promise_has_a_term_a_witness_and_a_price(t) -> void:
	var session := _session()
	session.note_trace_action("soz")
	var promise := session.give_promise(session.current_location_id, "erzak", 6, 20)
	t.ok(promise != null, "söz verildi")
	t.eq(promise.tur, Trace.TYPE_PROMISE, "söz bir izdir, bayrak değil")
	t.eq(promise.olgunluk_gunu, session.total_days_elapsed + 20, "vadesi var")
	t.ok(session.ledger.count_of(CaravanLedger.KIND_TRACE) > 0, "deftere yazıldı")

	# Tutulan söz minnete döner.
	session.keep_promise(promise)
	t.eq(promise.tur, Trace.TYPE_GRATITUDE, "tutulan söz minnet")
	t.eq(promise.yayilma, 1, "minnet yakına gider")

	# Bozulan söz yayılan kin olur.
	session.note_trace_action("soz2")
	var second := session.give_promise("ilsande", "altin", 40, 5)
	session.total_days_elapsed += 6
	session._check_promises()
	t.eq(second.tur, Trace.TYPE_GRUDGE, "vadesi dolan söz bozulur")
	t.eq(second.yayilma, 2, "bozulan söz uzağa gider")

func _test_three_promises_is_the_ceiling(t) -> void:
	var session := _session()
	for index in GameSession.MAX_OPEN_PROMISES:
		session.note_trace_action("soz%d" % index)
		t.ok(session.give_promise("ilsande", "donus", 0, 30) != null, "söz %d verildi" % index)
	session.note_trace_action("soz_fazla")
	t.not_ok(session.can_promise(), "üç sözden fazlası bir ağza sığmıyor")
	t.eq(session.give_promise("ilsande", "donus", 0, 30), null, "dördüncü söz açılmıyor")

## Kıtlık seçeneği kaldırmaz, pahalılaştırır (A1, A5).
func _test_hardship_costs_more_but_closes_nothing(t) -> void:
	t.eq(EventResolver.hardship_band(0.1), 0, "sakin bölgede bant 0")
	t.eq(EventResolver.hardship_band(0.75), 3, "kıtlıkta en sert bant")
	t.ok(EventResolver.HARDSHIP_COST[3] > EventResolver.HARDSHIP_COST[0], "bedel ağırlaşıyor")
	var hungry := {"scarcity_here": 0.8}
	t.eq(EventEngine.hardship_check_penalty(hungry), EventEngine.HARDSHIP_CHECK_PENALTY,
		"en sert bantta zar zorlaşıyor")
	t.eq(EventEngine.hardship_check_penalty({"scarcity_here": 0.2}), 0.0, "sakin bölgede pay yok")
	var choice := EventChoice.new()
	choice.effects = [EventEffect.make(EventEffect.Type.GOLD, -10)]
	t.ok(choice.is_available(hungry), "en sert bantta bile seçenek açık")
