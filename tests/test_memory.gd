extends RefCounted

## Faz 18 ("Hafıza ve bedel"): kaydın bütünlüğü, kişilerin kimliği, defterin
## sebebi ve yeri, kırgınlıklar, açlığın öldürebilmesi, liderlik seçimi,
## isimli tayfa, krizden kâr etmenin hafızası, yeni yol kartları, tek çözüm
## yolu (EventResolver), seferin görsel olmayan çekirdeği (JourneyController)
## ve sefer ortası kaydı.
##
## Bu paketin koruduğu ortak iddia: **bir kayıt dünyayı yeniden zar
## atmaz ve kimseyi klonlamaz, bir kayıp da iz bırakmadan kaybolmaz.**

func suite_name() -> String:
	return "Memory"

func run(t) -> void:
	_test_save_writes_are_atomic_with_backup(t)
	_test_hired_recruit_does_not_return_after_reload(t)
	_test_market_stock_survives_reload(t)
	_test_every_persistent_field_is_saved(t)
	_test_character_ids_are_unique_and_saved(t)
	_test_ledger_records_cause_place_and_id(t)
	_test_founder_line_is_struck_but_not_counted(t)
	_test_event_context_reads_the_ledger(t)
	_test_session_phase(t)
	_test_check_names_the_roller(t)
	_test_grievances_from_deliberate_choices(t)
	_test_starvation_can_kill(t)
	_test_heir_is_chosen_and_passing_over_costs(t)
	_test_named_crew_die_with_their_wagon(t)
	_test_profiteering_is_remembered(t)
	_test_leave_behind_and_party_hp(t)
	_test_stop_events_follow_their_stop(t)
	_test_finale_needs_struck_names(t)
	_test_event_resolver_is_the_single_path(t)
	_test_journey_controller_walk_and_arrival(t)
	_test_journey_controller_round_trip_keeps_the_dice(t)
	_test_mid_journey_save_round_trip(t)
	_test_city_brief_model_without_a_scene(t)

# --- Yardımcılar ---

func _session() -> GameSession:
	var session := GameSession.new(500, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	session.start_playthrough(
		CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng
	)
	return session

func _reload(session: GameSession) -> GameSession:
	var fresh := GameSession.new(0, 0)
	# JSON'dan geçir: kayıt dosyasının gerçekten taşıdığı şey bu.
	var parsed = JSON.parse_string(JSON.stringify(session.to_save_dict()))
	fresh.load_from_dict(parsed)
	return fresh

## Godot 4.2'nin Dictionary'sinde merged() yok.
func _with(base: Dictionary, extra: Dictionary) -> Dictionary:
	var result := base.duplicate()
	result.merge(extra, true)
	return result

func _companion(session: GameSession) -> CharacterData:
	for character in session.get_party():
		if not character.is_player:
			return character
	return null

# --- S1: atomik kayıt ---

func _test_save_writes_are_atomic_with_backup(t) -> void:
	var manager = load("res://scripts/autoload/save_manager.gd").new()
	var slot := 97
	manager.delete_save(slot)
	var session := _session()
	t.ok(manager.save_session(session, slot), "ilk kayıt yazılır")
	t.ok(manager.save_session(session, slot), "ikinci kayıt yazılır, önceki .bak olur")
	var path: String = manager._slot_path(slot)
	t.ok(FileAccess.file_exists(path + ".bak"), "önceki kayıt yedekte duruyor")
	t.not_ok(FileAccess.file_exists(path + ".tmp"), "geçici dosya geride kalmıyor")

	# Yarım yazılmış bir dosya: yükleme yedeğe düşmeli.
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\"gold\": 12")
	file.close()
	var loaded = manager.load_session(slot)
	t.ok(loaded != null, "bozuk kayıt yedekten açılır")
	if loaded != null:
		t.eq(loaded.get_caravan_name(), "Kurucu", "yedek doğru kervanı taşıyor")

	manager.delete_save(slot)
	t.not_ok(manager.has_save(slot), "silme yedeği de siliyor")
	manager.free()

# --- S2: tutulmuş aday klonlanmaz ---

func _test_hired_recruit_does_not_return_after_reload(t) -> void:
	var session := _session()
	session.owned_wagon_count = 2
	session.wallet.earn(10000)
	var venue := RecruitCatalog.VENUE_MARKET
	var before := session.get_recruit_candidates(venue)
	t.ok(before.size() >= 2, "meydanda aday var")
	var hired := before[1]
	var hired_name := hired.character_name
	t.ok(session.hire_recruit(venue, hired), "aday tutuldu")
	var remaining_names: Array[String] = []
	for candidate in session.get_recruit_candidates(venue):
		remaining_names.append(candidate.character_name)

	var reloaded := _reload(session)
	var reloaded_names: Array[String] = []
	for candidate in reloaded.get_recruit_candidates(venue):
		reloaded_names.append(candidate.character_name)
	t.eq(reloaded_names, remaining_names, "yeniden yüklenen pano tutulmuş adayı geri getirmiyor")
	t.eq(reloaded.get_party().size(), session.get_party().size(), "parti aynı")

	# İkinci bir tutma, üretim sırası kaymadan doğru kişiyi düşürür.
	var second := reloaded.get_recruit_candidates(venue)[0]
	var second_name := second.character_name
	t.ok(reloaded.hire_recruit(venue, second), "ikinci aday tutuldu")
	var again := _reload(reloaded)
	for candidate in again.get_recruit_candidates(venue):
		t.ok(
			candidate.character_name != second_name or candidate.character_name == hired_name,
			"ikinci tutulan da geri dönmüyor"
		)
	t.eq(again.get_recruit_candidates(venue).size(), before.size() - 2, "iki kişi eksik")

# --- S6: pazar stoğu ---

func _test_market_stock_survives_reload(t) -> void:
	var session := _session()
	var item_id := String(session.market_stock.keys()[0])
	var full := session.get_market_stock(item_id)
	session.consume_stock(item_id, full)
	t.eq(session.get_market_stock(item_id), 0, "stok boşaldı")
	var reloaded := _reload(session)
	t.eq(reloaded.get_market_stock(item_id), 0, "kayıt boşaltılmış pazarı yeniden doldurmuyor")

	var legacy := session.to_save_dict()
	legacy.erase("market_stock")
	var old := GameSession.new(0, 0)
	old.load_from_dict(legacy)
	t.eq(old.get_market_stock(item_id), full, "stoğu bilmeyen eski kayıt tam stokla açılır")

# --- S7: her kalıcı alan kayıtta ---

## Kayda girmeyen, bilerek geçici alanlar. Her biri neden geçici olduğunu
## söylüyor - listeye yeni bir alan eklemek bir karar olmalı, unutkanlık değil.
const TRANSIENT_FIELDS: Dictionary = {
	"party_stress": "partinin ortalamasına bakan bir mercek, sahibi CharacterData.stress",
	"recruit_candidates": "tohumdan yeniden üretiliyor; tutulanlar hired_recruit_indices'te",
	"_provisions_item": "katalogdan okunan sabit kaynak",
}

## Kayıtta farklı bir anahtarla duran alanlar: alan -> anahtar.
const SAVE_KEY_ALIASES: Dictionary = {
	"wallet": "gold",
	"_flags": "flags",
	"_next_character_serial": "next_character_serial",
	"_delivered_wagon_quest_ids": "delivered_wagon_quest_ids",
	"_fulfilled_commission_starts": "fulfilled_commission_starts",
	"caravan": "journey",
	"journey_origin_id": "journey",
	"journey_destination_id": "journey",
	"journey_total_days": "journey",
	"journey_days_remaining": "journey",
	"danger_level": "journey",
	"journey_snapshot": "journey",
}

func _test_every_persistent_field_is_saved(t) -> void:
	var session := _session()
	var saved := session.to_save_dict()
	for property in session.get_property_list():
		if not (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var name := String(property["name"])
		if TRANSIENT_FIELDS.has(name):
			continue
		var key := String(SAVE_KEY_ALIASES.get(name, name))
		t.ok(saved.has(key), "kalıcı alan kayda yazılıyor: %s" % name)

# --- S3: kalıcı kimlik ---

func _test_character_ids_are_unique_and_saved(t) -> void:
	var session := _session()
	var ids := {}
	for character in session.get_party():
		t.ok(not character.character_id.is_empty(), "partide herkesin kimliği var")
		ids[character.character_id] = true
	t.eq(ids.size(), session.get_party().size(), "kimlikler tekil")

	var twin := CharacterData.create(
		_companion(session).character_name, CultureCatalog.VALLEY, CharacterStats.new()
	)
	session.owned_wagon_count = 2
	session.add_to_party(twin)
	t.ne(twin.character_id, _companion(session).character_id, "aynı isim, farklı kişi")

	var reloaded := _reload(session)
	for index in session.get_party().size():
		t.eq(
			reloaded.get_party()[index].character_id, session.get_party()[index].character_id,
			"kimlik kayıttan aynen döner"
		)
	var newcomer := CharacterData.create("Yeni", CultureCatalog.VALLEY, CharacterStats.new())
	reloaded.owned_wagon_count = 3
	reloaded.add_to_party(newcomer)
	t.not_ok(ids.has(newcomer.character_id), "yüklenen oturum eski bir kimliği yeniden dağıtmaz")

	# Kimliği olmayan eski kayıt yüklenince kimlik alır.
	var legacy := session.to_save_dict()
	for entry in legacy["party"]:
		entry.erase("character_id")
	legacy.erase("next_character_serial")
	var old := GameSession.new(0, 0)
	old.load_from_dict(legacy)
	for character in old.get_party():
		t.ok(not character.character_id.is_empty(), "eski kayıttaki karakter kimlik alır")

# --- S8: defter satırı sebebi ve yeriyle ---

func _test_ledger_records_cause_place_and_id(t) -> void:
	var session := _session()
	var companion := _companion(session)
	var dead: Array[CharacterData] = [companion]
	session.resolve_deaths(dead, "LEDGER_CAUSE_COMBAT_WILDLIFE", WorldMapData.START_LOCATION_ID)
	var entry: Dictionary = session.ledger.recent(1)[0]
	t.eq(String(entry["kind"]), CaravanLedger.KIND_DIED, "ölüm satırı")
	t.eq(String(entry["cause"]), "LEDGER_CAUSE_COMBAT_WILDLIFE", "sebep yazıldı")
	t.eq(String(entry["location"]), WorldMapData.START_LOCATION_ID, "yer yazıldı")
	t.eq(String(entry["id"]), companion.character_id, "kimlik yazıldı")
	var line := CaravanLedger.describe(entry)
	t.ok(line.contains(companion.character_name), "okunur satır adı taşıyor")
	t.ok(line.contains(tr("LEDGER_CAUSE_COMBAT_WILDLIFE")), "okunur satır sebebi taşıyor")
	t.eq(
		session.ledger.entries_for_id(companion.character_id).size(), 2,
		"kimlikle katılma + ölüm satırı bulunur"
	)

	var reloaded := _reload(session)
	var reloaded_entry: Dictionary = reloaded.ledger.recent(1)[0]
	t.eq(String(reloaded_entry["cause"]), "LEDGER_CAUSE_COMBAT_WILDLIFE", "sebep kayıttan döner")

# --- S14: kurucu satırı ---

func _test_founder_line_is_struck_but_not_counted(t) -> void:
	var session := _session()
	var first: Dictionary = session.ledger.entries[0]
	t.eq(String(first["kind"]), CaravanLedger.KIND_FOUNDER, "defterin ilk satırı kurucu")
	t.ok(session.ledger.is_struck(first), "kurucunun adı üstü çizili")
	t.ne(String(first["name"]), "Kurucu", "kurucu oyuncunun kendisi değil")
	t.eq(int(session.build_campaign_context()["companions_lost"]), 0, "kurucu kayıp sayılmaz")
	t.eq(int(session.build_event_context()["companions_died"]), 0, "kurucu ölü sayılmaz")
	var memory := CityBriefModel.build_memory(session)
	t.ok(String(memory.get("text", "")).contains(String(first["name"])), "brifing kurucuyu anıyor")

# --- S4: olay bağlamı defteri okuyor ---

func _test_event_context_reads_the_ledger(t) -> void:
	var session := _session()
	var context := session.build_event_context()
	for key in ["companions_died", "companions_departed", "companions_lost",
			"lineage_generation", "days_as_leader", "profiteering_sales",
			"weakest_companion_hp_ratio"]:
		t.ok(context.has(key), "olay bağlamında: %s" % key)
	session.dismiss(_companion(session))
	t.eq(int(session.build_event_context()["companions_departed"]), 1, "ayrılan sayıldı")

# --- S15: evre ---

func _test_session_phase(t) -> void:
	var session := _session()
	t.eq(session.get_phase(), GameSession.Phase.CITY, "şehirde")
	session.journey_destination_id = WorldMapData.START_LOCATION_ID
	t.eq(session.get_phase(), GameSession.Phase.JOURNEY, "yolda")
	t.ok(session.is_journey_active(), "is_journey_active evreyi okuyor")
	session.set_flag(GameSession.RUN_OVER_FLAG)
	t.eq(session.get_phase(), GameSession.Phase.RUN_OVER, "soy tükendi")
	t.ok(session.is_run_over(), "is_run_over evreyi okuyor")

# --- S5: zarı atan kişi ---

func _test_check_names_the_roller(t) -> void:
	var session := _session()
	var companion := _companion(session)
	companion.stats.perception = 14
	var party_check := SkillCheck.make(CharacterStats.Kind.PERCEPTION, SkillCheck.Source.PARTY_BEST, 0.0)
	t.eq(session.get_check_roller(party_check), companion, "ortak çabada en iyisi atar")
	var leader_check := SkillCheck.make(CharacterStats.Kind.PERCEPTION, SkillCheck.Source.LEADER, 0.0)
	t.eq(session.get_check_roller(leader_check), session.get_player_character(), "lider check'inde lider atar")
	var choice := EventChoice.new()
	choice.check = party_check
	var preview := choice.get_check_preview(1.0, companion.character_name)
	t.ok(preview.begins_with(companion.character_name), "önizleme adla başlıyor")
	t.ne(choice.get_check_preview(1.0), preview, "adsız önizleme eski biçimde")

# --- S10: kırgınlık ---

func _test_grievances_from_deliberate_choices(t) -> void:
	var session := _session()
	session.change_provisions(200)
	var companion := _companion(session)
	session.apply_meal_distribution(GameSession.MEAL_MODE_SELF_ONLY)
	t.eq(companion.get_grievance(CharacterData.GRIEVANCE_UNFED), 1, "bilerek aç bırakılan kırgın")
	t.eq(companion.consecutive_hungry_days, 1, "açlık günü sayılıyor")
	session.apply_meal_distribution(GameSession.MEAL_MODE_ALL)
	t.eq(companion.consecutive_hungry_days, 0, "doyurulunca sayaç sıfırlanır")

	# Erzak gerçekten bittiyse kimse kimseyi aç bırakmadı.
	var starving := _session()
	starving.change_provisions(-starving.get_provisions())
	starving.apply_meal_distribution(GameSession.MEAL_MODE_ALL)
	t.eq(_companion(starving).get_grievance(CharacterData.GRIEVANCE_UNFED), 0, "kıtlık kırgınlık değil")

	var base := session.get_break_departure_chance(companion)
	companion.add_grievance(CharacterData.GRIEVANCE_UNFED, 4)
	t.ok(session.get_break_departure_chance(companion) > base, "kırgınlık ayrılma zarını büyütür")
	companion.add_grievance(CharacterData.GRIEVANCE_UNFED, 100)
	t.le(session.get_break_departure_chance(companion), GameSession.MAX_BREAK_DEPARTURE_CHANCE, "tavanlı")

	var reloaded := _reload(session)
	t.eq(
		_companion(reloaded).get_grievance(CharacterData.GRIEVANCE_UNFED),
		companion.get_grievance(CharacterData.GRIEVANCE_UNFED), "kırgınlık kayda giriyor"
	)
	t.ok(CaravanOverviewPanel.thought_for(companion).contains(companion.character_name), "düşünce kırgınlığı adıyla söylüyor")

# --- S12: açlık öldürebilir ---

func _test_starvation_can_kill(t) -> void:
	var session := _session()
	session.change_provisions(500)
	var companion := _companion(session)
	var companion_name := companion.character_name
	var died_on := -1
	for day in 60:
		var result := session.apply_meal_distribution(GameSession.MEAL_MODE_SELF_ONLY)
		if day < GameSession.STARVATION_HP_LOSS_START_DAY - 1:
			t.eq(companion.current_hp, companion.get_max_hp(), "ilk günler can yemiyor")
		var outcome: Dictionary = result["death_outcome"]
		if (outcome.get("dead_names", []) as Array).has(companion_name):
			died_on = day
			break
	t.ok(died_on > 0, "hep aç bırakılan yoldaş sonunda ölür")
	t.not_ok(session.get_party().has(companion), "ölen partiden çıktı")
	var entry: Dictionary = session.ledger.recent(1)[0]
	t.eq(String(entry["cause"]), "LEDGER_CAUSE_STARVED", "defter açlığı yazıyor")

	# Herkesi doyuran kervanda sayaç hiç artmaz (Provision Rules'un sözü).
	var fed := _session()
	fed.change_provisions(500)
	for _day in 20:
		fed.apply_meal_distribution(GameSession.MEAL_MODE_ALL)
	for character in fed.get_party():
		t.eq(character.consecutive_hungry_days, 0, "doğru doyurulan hiç aç kalmaz")

# --- S11: liderlik seçimi ---

func _test_heir_is_chosen_and_passing_over_costs(t) -> void:
	var session := _session()
	session.owned_wagon_count = 2
	var senior := CharacterData.create("Kıdemli", CultureCatalog.VALLEY, CharacterStats.new())
	senior.level = 5
	session.add_to_party(senior)
	var junior := _companion(session)
	var leader := session.get_player_character()
	var dead: Array[CharacterData] = [leader]
	var outcome := session.resolve_deaths(dead, "LEDGER_CAUSE_COMBAT")
	t.ok(bool(outcome["awaiting_heir"]), "lider öldü, varis bekleniyor")
	t.eq((outcome["heir_candidates"] as Array)[0], senior, "kıdemli ilk aday")
	t.eq(session.lineage_generation, 1, "seçilmeden kuşak ilerlemez")
	t.eq(junior.get_grievance(CharacterData.GRIEVANCE_WITNESSED_DEATH), 1, "hayatta kalan ölüme tanık")

	var stress_before := senior.stress
	session.appoint_heir(junior)
	t.ok(junior.is_player, "seçilen lider oldu")
	t.not_ok(senior.is_player, "kıdemli lider değil")
	t.eq(session.lineage_generation, 2, "kuşak ilerledi")
	t.eq(senior.get_grievance(CharacterData.GRIEVANCE_PASSED_OVER), 1, "geçilen kıdemli kırgın")
	t.ok(senior.stress > stress_before, "geçilmek stres bırakır")

	# Geriye dönük uyumlu yol hâlâ kıdemliyi kendiliğinden atar.
	var compat := _session()
	compat.owned_wagon_count = 2
	var compat_senior := CharacterData.create("Kıdemli", CultureCatalog.VALLEY, CharacterStats.new())
	compat_senior.level = 5
	compat.add_to_party(compat_senior)
	var compat_dead: Array[CharacterData] = [compat.get_player_character()]
	var compat_outcome := compat.resolve_combat_deaths(compat_dead)
	t.eq(compat_outcome["new_leader"], compat_senior, "eski yol kıdemliyi seçer")
	t.eq(compat_senior.get_grievance(CharacterData.GRIEVANCE_PASSED_OVER), 0, "kıdemli geçilmedi")

# --- S18: isimli tayfa ---

func _test_named_crew_die_with_their_wagon(t) -> void:
	var session := _session()
	t.eq(session.crew_names.size(), GameSession.PEOPLE_PER_WAGON, "bir vagon, iki isim")
	for crew_name in session.crew_names:
		t.ok(not crew_name.is_empty(), "tayfanın adı var")
	session.owned_wagon_count = 3
	session._sync_wagon_inventories()
	t.eq(session.crew_names.size(), 3 * GameSession.PEOPLE_PER_WAGON, "vagonla birlikte tayfa")
	t.eq(session.get_wagon_crew_names(2).size(), GameSession.PEOPLE_PER_WAGON, "her vagonun tayfası")
	var lost_names := session.get_wagon_crew_names(2)

	session.caravan.wagons_at_start = 3
	session.caravan.player_wagon_count_at_start = 3
	session.caravan.wagon_count = 2
	var died_before := session.ledger.count_of(CaravanLedger.KIND_DIED)
	session._apply_wagon_losses_to_ownership()
	t.eq(session.owned_wagon_count, 2, "vagon kaybedildi")
	t.eq(
		session.ledger.count_of(CaravanLedger.KIND_DIED), died_before + GameSession.PEOPLE_PER_WAGON,
		"tayfası deftere ölü olarak yazıldı"
	)
	t.eq(session.crew_names.size(), 2 * GameSession.PEOPLE_PER_WAGON, "kaybedilen vagonun tayfası listeden düştü")
	var recorded := session.ledger.recent(GameSession.PEOPLE_PER_WAGON)
	for crew_name in lost_names:
		var found := false
		for entry in recorded:
			found = found or String(entry["name"]) == crew_name
		t.ok(found, "kaybedilen tayfanın adı defterde: %s" % crew_name)
	t.eq(String(session.ledger.recent(1)[0]["cause"]), "LEDGER_CAUSE_WAGON_LOST", "sebep vagon kaybı")

	var reloaded := _reload(session)
	t.eq(reloaded.crew_names, session.crew_names, "tayfanın adları kayıttan aynen döner")

	var died_before_sale := session.ledger.count_of(CaravanLedger.KIND_DIED)
	session.sell_wagon()
	t.eq(session.ledger.count_of(CaravanLedger.KIND_DIED), died_before_sale, "satılan vagonun tayfası ölmez")
	t.eq(session.crew_names.size(), session.owned_wagon_count * GameSession.PEOPLE_PER_WAGON, "satışta tayfa ayrılır")

# --- S16: krizden kâr ---

func _test_profiteering_is_remembered(t) -> void:
	var session := _session()
	var item_id := String(session.market_stock.keys()[0])
	session.record_sale(item_id, 1)
	t.eq(session.profiteering_sales, 0, "sıradan bir satış kâr fırsatçılığı değil")

	session.world_events.add_event(
		WorldEvents.Kind.PLAGUE, session.current_location_id, session.total_days_elapsed, 10
	)
	session.market.add_shock(session.current_location_id, item_id, 1.5, session.total_days_elapsed + 10)
	t.ok(session.is_profiteering_sale(item_id), "vebalı şehre şişmiş fiyatla satış")
	session.record_sale(item_id, 1)
	t.eq(session.profiteering_sales, 1, "sayıldı")
	t.eq(_reload(session).profiteering_sales, 1, "kayda giriyor")

	var event := EventCatalog.get_event("evt_profiteer_recognized")
	var context := session.build_event_context()
	t.not_ok(event.is_eligible(context), "üç satıştan önce tanınmıyor")
	session.profiteering_sales = 3
	t.ok(event.is_eligible(session.build_event_context()), "üç satıştan sonra tanınıyor")

# --- S13: geride bırakmak ve isimli yara ---

func _test_leave_behind_and_party_hp(t) -> void:
	var session := _session()
	var companion := _companion(session)
	var event := EventCatalog.get_event("evt_leave_the_wounded")
	t.not_ok(event.is_eligible(session.build_event_context()), "yaralı yokken çıkmaz")
	companion.current_hp = 1
	t.ok(event.is_eligible(session.build_event_context()), "ağır yaralı yoldaş varken çıkar")
	t.ok(
		event.get_weight(_with(session.build_event_context(), {"near_hamlet": 1.0}))
			> event.get_weight(_with(session.build_event_context(), {"near_hamlet": 0.0})),
		"köyün önünde çok daha olası"
	)

	var heal := EventEffectApplier.apply([EventEffect.make(EventEffect.Type.PARTY_HP, 10, "weakest")], session)
	t.eq(companion.current_hp, 11, "en yaralı iyileşti")
	t.eq(heal.lines.size(), 1, "satırı var")
	var leader := session.get_player_character()
	EventEffectApplier.apply([EventEffect.make(EventEffect.Type.PARTY_HP, -999)], session)
	t.eq(leader.current_hp, 1, "olay öldürmez, can 1'de kenetlenir")

	EventEffectApplier.apply([EventEffect.make(EventEffect.Type.LEAVE_BEHIND)], session)
	t.not_ok(session.get_party().has(companion), "yaralı yoldaş bırakıldı")
	t.ok(session.get_party().has(leader), "lider asla bırakılmaz")
	var entry: Dictionary = session.ledger.recent(1)[0]
	t.eq(String(entry["kind"]), CaravanLedger.KIND_DEPARTED, "ayrıldı, ölmedi")
	t.eq(String(entry["cause"]), "LEDGER_CAUSE_LEFT_BEHIND", "sebebi geride bırakılmak")

	var lone := EventEffectApplier.apply([EventEffect.make(EventEffect.Type.LEAVE_BEHIND)], session)
	t.eq(session.get_party().size(), 1, "tek başına kalan lider bırakılmaz")
	t.eq(lone.lines.size(), 0, "bırakılacak kimse yoksa sessiz")

# --- S19: durak kartları ---

func _test_stop_events_follow_their_stop(t) -> void:
	var session := _session()
	var context := session.build_event_context()
	for pair in [
		["evt_frontier_outpost", RouteTerrain.STOP_OUTPOST],
		["evt_mine_collapse", RouteTerrain.STOP_MINE],
		["evt_failing_bridge", RouteTerrain.STOP_BRIDGE],
		["evt_roadside_shrine", RouteTerrain.STOP_SHRINE],
	]:
		var event := EventCatalog.get_event(String(pair[0]))
		t.ok(event != null, "katalogda: %s" % pair[0])
		var away := event.get_weight(_with(context, EventResolver.stop_context(RouteTerrain.STOP_NONE)))
		var near := event.get_weight(_with(context, EventResolver.stop_context(String(pair[1]))))
		t.ok(near >= away * 5.0, "%s kendi durağında çok daha olası" % pair[0])
	var stops := EventResolver.stop_context(RouteTerrain.STOP_MINE)
	t.eq(float(stops["near_mine"]), 1.0, "maden bayrağı")
	t.eq(float(stops["near_bridge"]), 0.0, "diğerleri kapalı")

# --- S17: finalin hafıza kapısı ---

func _test_finale_needs_struck_names(t) -> void:
	var finale: CampaignChapter = null
	for chapter in CampaignCatalog.get_chapters():
		if chapter.is_finale:
			finale = chapter
	t.ok(finale != null, "final var")
	var keys: Array[String] = []
	for condition in finale.objectives:
		keys.append(condition.key)
	t.ok(keys.has("companions_lost"), "final defterde üstü çizili ad istiyor")

# --- S9: tek çözüm yolu ---

func _test_event_resolver_is_the_single_path(t) -> void:
	var session := _session()
	session.change_provisions(50)
	var engine := EventEngine.new(EventCatalog.get_road_events(), 11)
	var event := EventCatalog.get_event("evt_pilgrim_encounter")
	var escort: EventChoice = event.choices[0]
	var xp_before := session.get_player_character().xp
	var resolution := EventResolver.resolve_choice(session, engine, event, escort)
	t.ok(resolution.choice_result != null, "seçeneğin etkileri uygulandı")
	t.ok(session.has_flag("pilgrim_escorted"), "bayrak kuruldu")
	var blessing := EventCatalog.get_event("evt_pilgrim_blessing")
	t.ok(
		engine.get_eligible_events(1, session.build_event_context()).has(blessing),
		"zincir motor üzerinde açıldı"
	)
	t.ok(session.get_player_character().xp > xp_before, "olayın XP'si verildi")
	t.eq(resolution.check_tier, -1, "check'siz seçenekte zar yok")

	var guide: EventChoice = event.choices[1]
	var checked := EventResolver.resolve_choice(_session(), EventEngine.new(EventCatalog.get_road_events(), 3), event, guide)
	t.ok(checked.check_tier >= 0, "check'li seçenekte zar atıldı")
	t.ok(checked.outcome != null, "sonuç çekildi")

	var hooked := [0]
	EventResolver.resolve_choice(
		_session(), EventEngine.new(EventCatalog.get_road_events(), 3), event, escort,
		func(effects: Array[EventEffect]) -> EventEffectApplier.Result:
			hooked[0] += 1
			return EventEffectApplier.apply(effects, session)
	)
	t.eq(hooked[0], 1, "etki kancası kullanıldı")

# --- S20: seferin çekirdeği ---

func _test_journey_controller_walk_and_arrival(t) -> void:
	var journey := JourneyController.new()
	journey.journey_length_days = 3
	t.almost(JourneyController.effective_rate(1.0, 1.0, 1.0, 1.0, false), 1.0, "tam kondisyonda çarpan 1")
	t.almost(
		JourneyController.effective_rate(1.0, 1.0, 1.0, 1.0, true),
		JourneyController.HUNGRY_PACE_MULTIPLIER, "aç kervan yavaş"
	)
	journey.walk(1.0, JourneyClock.HOURS_PER_DAY)
	t.almost(journey.days_covered, 1.0, "bir günlük yürüyüş bir gün")
	t.not_ok(journey.has_arrived(), "henüz varmadı")
	journey.walk(1.0, JourneyClock.HOURS_PER_DAY * 10.0)
	t.almost(journey.days_covered, 3.0, "yolun sonunda kenetlenir")
	t.ok(journey.has_arrived(), "vardı")
	journey.walk(-1.0, JourneyClock.HOURS_PER_DAY * 10.0)
	t.almost(journey.days_covered, 0.0, "başa kenetlenir")

	var session := _session()
	journey.journey_length_days = 5
	journey.days_covered = 1.2
	journey.sync_days_remaining(session)
	t.eq(session.journey_days_remaining, 4, "kalan gün mesafeden türetilir")

	journey.pending_event = EventCatalog.get_event("evt_wild_animal")
	journey.pending_event_day_position = 1.5
	t.not_ok(journey.has_reached_pending(0.0), "işarete daha varılmadı")
	t.ok(journey.has_reached_pending(0.4), "burnu işarete değdi")
	journey.start_leg(4)
	t.eq(journey.pending_event, null, "yeni bacak eski işareti bırakır")
	t.almost(journey.days_covered, 0.0, "yeni bacak sıfırdan")

func _test_journey_controller_round_trip_keeps_the_dice(t) -> void:
	var events := EventCatalog.get_road_events()
	var journey := JourneyController.new()
	journey.clock = JourneyClock.new()
	journey.engine = EventEngine.new(events, 12345)
	journey.journey_length_days = 6
	journey.days_covered = 2.4
	journey.current_day = 2
	journey.pace = 1.35
	journey.camping = true
	journey.camp_ends_at_hours = 40.0
	journey.pending_event = EventCatalog.get_event("evt_wild_animal")
	journey.pending_event_day_position = 2.7
	journey.clock.consume_hours(30.0)
	journey.signal_rng.seed = 99
	journey.signal_rng.randf()

	var session := _session()
	var context := session.build_event_context()
	context["danger"] = 0.9
	for day in 3:
		journey.engine.roll_for_day(day, context)

	var data = JSON.parse_string(JSON.stringify(journey.to_dict()))
	var restored := JourneyController.new()
	restored.load_from_dict(data, events)
	t.almost(restored.days_covered, 2.4, "mesafe")
	t.eq(restored.current_day, 2, "gün")
	t.almost(restored.pace, 1.35, "tempo")
	t.ok(restored.camping, "kamp")
	t.eq(restored.pending_event.event_id, "evt_wild_animal", "bekleyen karşılaşma")
	t.almost(restored.clock.total_hours, journey.clock.total_hours, "saat")
	t.almost(restored.signal_rng.randf(), journey.signal_rng.randf(), "işaret zarı kaldığı yerden")

	var original_draws: Array[String] = []
	var restored_draws: Array[String] = []
	for day in range(3, 13):
		var a := journey.engine.roll_for_day(day, context)
		var b := restored.engine.roll_for_day(day, context)
		original_draws.append("" if a == null else a.event_id)
		restored_draws.append("" if b == null else b.event_id)
	t.eq(restored_draws, original_draws, "yüklenen sefer aynı zarları atar - yeniden zar kapısı yok")

# --- S21: sefer ortası kaydı ---

func _test_mid_journey_save_round_trip(t) -> void:
	var session := _session()
	t.ok((session.to_save_dict()["journey"] as Dictionary).is_empty(), "şehirde alınan kayıt sefer taşımaz")
	t.eq(Nav.resume_scene(session), Nav.CITY_MAP, "şehir kaydı şehre döner")

	var destination := WorldMapData.get_routes_from(session.current_location_id)[0]
	session.journey_origin_id = session.current_location_id
	session.journey_destination_id = destination.to_location_id if destination.from_location_id == session.current_location_id else destination.from_location_id
	session.journey_total_days = 5
	session.journey_days_remaining = 3
	session.danger_level = 0.4
	session.caravan.merchant_names = ["Tüccar"]
	session.caravan.original_merchant_names = ["Tüccar"]
	session.caravan.morale = 61
	session.caravan.stamina = 40
	var journey := JourneyController.new()
	journey.clock = JourneyClock.new()
	journey.engine = EventEngine.new(EventCatalog.get_road_events(), 5)
	journey.journey_length_days = 5
	journey.days_covered = 2.0
	session.journey_snapshot = journey.to_dict()

	var reloaded := _reload(session)
	t.ok(reloaded.is_journey_active(), "sefer ortası kaydı seferi taşıyor")
	t.eq(reloaded.journey_destination_id, session.journey_destination_id, "hedef")
	t.eq(reloaded.journey_days_remaining, 3, "kalan gün")
	t.almost(reloaded.danger_level, 0.4, "tehlike")
	t.eq(reloaded.caravan.merchant_names, session.caravan.merchant_names, "taşınan tüccarlar")
	t.eq(reloaded.caravan.morale, 61, "moral")
	t.eq(reloaded.caravan.stamina, 40, "dayanıklılık")
	t.almost(float(reloaded.journey_snapshot["days_covered"]), 2.0, "yolun neresinde olduğu")
	t.eq(Nav.resume_scene(reloaded), Nav.JOURNEY, "sefer kaydı yola döner")

	reloaded.finish_journey()
	t.ok(reloaded.journey_snapshot.is_empty(), "varış anlık görüntüyü temizler")
	t.ok((reloaded.to_save_dict()["journey"] as Dictionary).is_empty(), "varıştan sonra kayıt sefer taşımaz")

# --- S22: brifing modeli ---

func _test_city_brief_model_without_a_scene(t) -> void:
	var session := _session()
	var needs := CityBriefModel.build_needs(session)
	for need in needs:
		t.ok(not String(need["scene"]).is_empty(), "her ihtiyaç bir ekrana gidiyor")
	var dead: Array[CharacterData] = [_companion(session)]
	session.resolve_deaths(dead, "LEDGER_CAUSE_STARVED", session.current_location_id)
	var memory := CityBriefModel.build_memory(session)
	t.ok(String(memory["text"]).contains(dead[0].character_name), "en son kayıp anılıyor")
	t.ok(String(memory["detail"]).contains(tr("LEDGER_CAUSE_STARVED")), "sebebiyle")
	t.ok(bool(memory["mourning"]), "yakın bir ölüm yas kurdelesi taşır")
	session.total_days_elapsed += CityBriefModel.MOURNING_DAYS + 1
	t.ok(not bool(CityBriefModel.build_memory(session)["mourning"]), "yas günlerce sürer, sonsuza dek değil")
