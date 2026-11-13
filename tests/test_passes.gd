extends RefCounted

## Geçiş belgeleri (Y-C31): belge yola bağlı, süreli, kayıtta; belgesizken
## kartı açılır ve bedel orada ödenir.

func suite_name() -> String:
	return "Geçiş belgesi"

func run(t) -> void:
	_test_required_on(t)
	_test_duration_and_expiry(t)
	_test_missing_pass_opens_its_card(t)
	_test_save(t)

func _test_required_on(t) -> void:
	t.ok(PassCatalog.required_on(PassCatalog.TAMGA, "rivecande", "serai_orbeyan"), "Orbeyan yolu tamga ister")
	t.ok(PassCatalog.required_on(PassCatalog.BOYNUZ_FIS, "ezmerak", "tolvarin"), "Ezmerak'tan çıkan fiş ister")
	t.not_ok(PassCatalog.required_on(PassCatalog.BOYNUZ_FIS, "tolvarin", "kirsavel"), "Çitler'in öbür yolu fiş istemez")
	t.ok(PassCatalog.required_on(PassCatalog.ZIL, "vorgat", "orvahel"), "Orvahel yolu zil ister")

func _journey(session: GameSession, destination_id: String) -> void:
	var destination := WorldMapData.get_location_by_id(destination_id)
	session.start_journey(destination_id, 4, 0.3, CaravanPlan.new(destination, 4))

func _test_duration_and_expiry(t) -> void:
	var session := GameSession.new(200, 20, 1)
	_journey(session, "orvahel")
	t.ok(session.pass_needed(PassCatalog.ZIL), "zilsiz kervana Orvahel yolunda zil gerekir")
	session.grant_pass(PassCatalog.ZIL, 360)
	t.not_ok(session.pass_needed(PassCatalog.ZIL), "zil alınınca gerekmez")
	session.total_days_elapsed += 360
	t.ok(session.pass_valid(PassCatalog.ZIL), "son gün hâlâ geçer")
	session.total_days_elapsed += 1
	t.not_ok(session.pass_valid(PassCatalog.ZIL), "süresi dolan belge geçmez")
	t.ok(session.pass_needed(PassCatalog.ZIL), "süresi dolunca yeniden istenir")
	var journal_has := false
	for entry in session.journal:
		if String(entry.get("text", "")).contains(TranslationServer.translate("PASS_ZIL")):
			journal_has = true
	t.ok(journal_has, "belge deftere yazıldı")

func _test_missing_pass_opens_its_card(t) -> void:
	var session := GameSession.new(200, 20, 1)
	_journey(session, "orvahel")
	var context := session.build_event_context()
	var bell := EventCatalog.get_event("evt_pass_bell")
	t.ok(bell != null and bell.is_eligible(context), "zilsiz yolda zil kartı çekilebilir")
	session.grant_pass(PassCatalog.ZIL, 360)
	t.not_ok(bell.is_eligible(session.build_event_context()), "zil varken kart gelmez")
	var effects: Array[EventEffect] = [EventEffect.make(EventEffect.Type.PASS_GRANT, 0, PassCatalog.BEDEL_TASI)]
	EventEffectApplier.apply(effects, session)
	t.eq(int(session.passes[PassCatalog.BEDEL_TASI]), session.total_days_elapsed + session.journey_days_remaining + 1,
		"gün 0: belge yalnız bu yolculuk için")

func _test_save(t) -> void:
	var session := GameSession.new(200, 20, 1)
	session.passes = {PassCatalog.TAMGA: 400}
	var loaded := GameSession.new(200, 20, 1)
	loaded.load_from_dict(session.to_save_dict())
	t.eq(int(loaded.passes.get(PassCatalog.TAMGA, 0)), 400, "belgeler kayıtta")
