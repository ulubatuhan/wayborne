extends RefCounted

## U3-U7 (uzman raporu, 2026-11-07): son, boş tur, imza, ustalık, sayı-only.

func suite_name() -> String:
	return "Retention"

func run(t) -> void:
	_test_raid_patience_runs_out(t)
	_test_arrival_reports_mastery(t)
	_test_city_never_offers_nothing(t)
	_test_promised_effects_are_kept(t)
	_test_famine_deepens_with_the_years(t)

func _session() -> GameSession:
	var session := GameSession.new(900, 60, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	return session

## U5: üst üste ödeyenle pazarlık biter; gerçek bir dövüş sayacı sıfırlar.
func _test_raid_patience_runs_out(t) -> void:
	var session := _session()
	var ambush := EventCatalog.get_event("evt_bandit_ambush")
	t.ok(ambush != null, "pusu kartı var")
	if ambush == null:
		return
	var pay: EventChoice = ambush.choices[0]
	t.ok(pay.is_available(session.build_event_context()), "ilk kesilmede fidye açık")
	for i in GameSession.RAID_PATIENCE:
		session.note_raid_faced(ambush)
	t.eq(session.raids_bought_off, GameSession.RAID_PATIENCE, "ödeyerek sıyrılmalar sayılıyor")
	t.not_ok(pay.is_available(session.build_event_context()), "eşikte fidye kapanır")
	t.ne(pay.unavailable_text_key, "", "kapalı seçenek sebebini yazar")
	session.note_combat_triggered()
	t.eq(session.raids_bought_off, 0, "gerçek dövüş sabrı tazeler")
	t.ok(pay.is_available(session.build_event_context()), "dövüşenle yine pazarlık edilir")
	# Kayıtta: yükleyip sabrı tazelemek bir sömürü kapısı olmasın.
	session.note_raid_faced(ambush)
	var reloaded := GameSession.new(0, 0, 1)
	reloaded.load_from_dict(session.to_save_dict())
	t.eq(reloaded.raids_bought_off, session.raids_bought_off, "sayaç kayda yazılır")

## U6: varış ustalığı sayıyla söyler.
func _test_arrival_reports_mastery(t) -> void:
	var session := _session()
	var routes := WorldMapData.get_routes_from(session.current_location_id)
	if routes.is_empty():
		return
	var destination := WorldMapData.get_location_by_id(routes[0].to_location_id)
	session.start_journey(destination.location_id, 4, 0.3, CaravanPlan.new(destination, 4))
	t.eq(session.journey_hungry_days, 0, "sefer başında aç gün yok")
	session.journey_hungry_days = 2
	var payout := session.finish_journey()
	t.eq(int(payout.get("hungry_days", -1)), 2, "aç gün varışta bildirilir")
	t.eq(int(payout.get("journey_days", 0)), 4, "yolun boyu bildirilir")
	t.ge(float(payout.get("spare_days", -1)), 0.0, "kilerin kaç gün yeteceği bildirilir")

## U4: şehir hiçbir zaman "yapacak bir şey yok" demez; ama acil olmayan
## bir öneri acil görünmez.
func _test_city_never_offers_nothing(t) -> void:
	var session := _session()
	session.change_provisions(400)
	var offers := WorldMapData.get_offers_from_origin(session.current_location_id)
	if not offers.is_empty():
		session.accept_contract(offers[0])
	var needs := CityBriefModel.build_needs(session)
	t.ok(not needs.is_empty(), "hazır kervana da bir şey önerilir")
	for need in needs:
		t.ok(not String(need.text).strip_edges().is_empty(), "önerinin metni var")
		t.ok(not String(need.action).strip_edges().is_empty(), "önerinin düğmesi var")

## U7: metnin söz verdiği somut şey artık gerçekten oluyor.
func _test_promised_effects_are_kept(t) -> void:
	var found := {}
	for event in EventCatalog.get_road_events():
		for choice in event.choices:
			for outcome in choice.outcomes:
				if not EventCatalog.PROMISED_EFFECTS.has(outcome.text_key):
					continue
				found[outcome.text_key] = true
				var rows: Array = EventCatalog.PROMISED_EFFECTS[outcome.text_key]
				for row in rows:
					var spec: Array = row
					var has_it := false
					for effect in outcome.effects:
						if effect.type == spec[0] and effect.text_value == String(spec[2]):
							has_it = true
					t.ok(has_it, "%s sözünü tutuyor" % outcome.text_key)
	t.eq(found.size(), EventCatalog.PROMISED_EFFECTS.size(), "tabloda ölü satır yok")

## U3: kıtlık yıllarla derinleşir ve tavanı eski tavandan yüksektir.
func _test_famine_deepens_with_the_years(t) -> void:
	var first := Scarcity.degree("vadi", 30)
	var third := Scarcity.degree("vadi", 30 + 2 * Scarcity.YEAR_DAYS)
	t.ok(third > first, "üçüncü yıl birinci yıldan ağır: %.2f > %.2f" % [third, first])
	t.ge(Scarcity.DRIFT_CAP, 0.4, "kaymanın tavanı yetkin oyuncuyu da sıkacak kadar yüksek")
	# Mevsim hâlâ işliyor: kıtlık tek yönlü bir sayaç değil.
	t.ne(Scarcity.degree("vadi", 100), Scarcity.degree("vadi", 100 + Scarcity.YEAR_DAYS / 2),
		"mevsim salınımı kaymanın altında kaybolmadı")
