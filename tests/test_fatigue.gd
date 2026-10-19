extends RefCounted

## Yorgunluk (görev Y-F01): kişinin bedeni ve kervanın takati. Takat en
## yorgun kişiye bağlı; normal tempoda yorgunluk yürüyüşü yavaşlatmaz
## (planlayıcının erzak sözü), yalnızca hızlı tempoyu kilitler.

func suite_name() -> String:
	return "Fatigue"

func run(t) -> void:
	_test_save_round_trip(t)
	_test_sources_raise(t)
	_test_sources_lower(t)
	_test_city_arrival_rests(t)
	_test_caravan_stamina_bound_by_most_tired(t)
	_test_steady_pace_never_slowed(t)
	_test_combat_penalty_small_and_thresholded(t)

func _session() -> GameSession:
	var session := GameSession.new(500, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	session.start_playthrough(
		CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng
	)
	return session

func _member(name: String, weight: int = CharacterData.BODY_WEIGHT_AVERAGE) -> CharacterData:
	return CharacterData.create(
		name, CultureCatalog.VALLEY, CharacterStats.new(), CharacterData.DEFAULT_HEIGHT_CM, 1,
		ClassCatalog.GUARD, CharacterData.GENDER_FEMALE, weight
	)

func _test_save_round_trip(t) -> void:
	var character := _member("Ayşe")
	character.fatigue = 37
	var copy := CharacterData.from_dict(JSON.parse_string(JSON.stringify(character.to_dict())))
	t.eq(copy.fatigue, 37, "yorgunluk kayıtta kalır")

	var old := character.to_dict()
	old.erase("fatigue")
	t.eq(CharacterData.from_dict(old).fatigue, 0, "eski kayıt dinlenmiş yüklenir")
	old["fatigue"] = 250
	t.eq(CharacterData.from_dict(old).fatigue, CharacterData.MAX_FATIGUE, "elle şişirilmiş kayıt tavana kenetlenir")

	var session := _session()
	session.get_party()[0].fatigue = 44
	var fresh := GameSession.new(0, 0)
	fresh.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	t.eq(fresh.get_party()[0].fatigue, 44, "oturum kaydı kişinin yorgunluğunu taşır")

func _test_sources_raise(t) -> void:
	var session := _session()
	var lean := _member("Ince", CharacterData.BODY_WEIGHT_LEAN)
	var heavy := _member("Iri", CharacterData.BODY_WEIGHT_HEAVY)
	session.add_to_party(lean)
	session.add_to_party(heavy)

	session.apply_pace_fatigue_day(false)
	t.eq(lean.fatigue, 0, "zorlanmayan gün kimseyi yormaz")
	session.apply_pace_fatigue_day(true)
	t.eq(lean.fatigue, GameSession.FATIGUE_PUSH_PER_DAY, "hızlı tempo günü herkesi yorar")
	t.eq(heavy.fatigue, 10, "iri beden biraz daha yorulur (8 -> 10)")

	lean.fatigue = 0
	heavy.fatigue = 0
	var rest := session.accrue_night_fatigue(3.0)
	t.eq(lean.fatigue, 0, "dilim dolmadan gece payı yazılmaz")
	t.almost(rest, 3.0, "küsur bir sonraki saate taşınır")
	rest = session.accrue_night_fatigue(9.0)
	t.eq(lean.fatigue, 2 * GameSession.FATIGUE_NIGHT_CHUNK, "ışıksız gece dilimlerle yorar")
	t.almost(rest, 1.0, "gece küsuru korunur")

	lean.fatigue = 0
	heavy.fatigue = 0
	var fighters: Array[CharacterData] = [lean]
	session.apply_combat_fatigue(fighters)
	t.eq(lean.fatigue, GameSession.FATIGUE_COMBAT, "savaşa giren yorulur")
	t.eq(heavy.fatigue, 0, "dışarıda tutulan yorulmaz")

	# Öncü her yol günü yorulur, ortancı dinlenir (diziliş, Y-B12).
	lean.fatigue = 0
	heavy.fatigue = 20
	session.set_formation(lean, heavy, null)
	session.journey_destination_id = "rivecande"
	session.advance_day()
	t.eq(lean.fatigue, GameSession.FATIGUE_VANGUARD_PER_DAY, "öncülük günde yorar")
	t.eq(heavy.fatigue, 20 - GameSession.FATIGUE_MIDDLE_RELIEF_PER_DAY, "kervanın ortasında yürüyen dinlenir")

func _test_sources_lower(t) -> void:
	var session := _session()
	var tired := _member("Yorgun")
	session.add_to_party(tired)
	tired.fatigue = 50
	session.change_provisions(50)
	var result := session.make_camp()
	t.eq(tired.fatigue, 50 - GameSession.FATIGUE_CAMP_RELIEF, "kamp ateşi yorgunluğu indirir")
	t.eq(int(result.get("fatigue_relief", 0)), GameSession.FATIGUE_CAMP_RELIEF, "kampın sonucu dinlenmeyi söyler")
	tired.fatigue = 5
	session.make_camp()
	t.eq(tired.fatigue, 0, "yorgunluk sıfırın altına inmez")

func _test_city_arrival_rests(t) -> void:
	var session := _session()
	session.current_location_id = "rivecande"
	var destination := WorldMapData.get_location_by_id(WorldMapData.START_LOCATION_ID)
	var days := WorldMapData.get_route("rivecande", WorldMapData.START_LOCATION_ID).travel_days
	session.start_journey(WorldMapData.START_LOCATION_ID, days, 0.2, CaravanPlan.new(destination, days))
	var leader := session.get_party()[0]
	leader.fatigue = 90
	session.finish_journey()
	t.eq(leader.fatigue, 90 - GameSession.FATIGUE_CITY_RELIEF, "şehirde bir gece yorgunluğun çoğunu alır")

func _test_caravan_stamina_bound_by_most_tired(t) -> void:
	var session := _session()
	var ayse := _member("Ayşe")
	session.add_to_party(ayse)
	t.eq(session.get_caravan_stamina(), CaravanState.MAX_STAMINA, "dinç kervan tam takatli")
	t.eq(session.get_stamina_binder(), null, "kimse takati bağlamıyor")

	ayse.fatigue = 70
	t.eq(session.get_caravan_stamina(), 30, "takat en yorgun kişinin bıraktığı kadar")
	t.eq(session.get_stamina_binder(), ayse, "takati bağlayan adıyla bilinir")
	t.eq(session.get_most_fatigued_character(), ayse, "en yorgun kişi")

	session.caravan.stamina = 20
	t.eq(session.get_caravan_stamina(), 20, "sayaç daha düşükse o okunur")
	t.eq(session.get_stamina_binder(), null, "o zaman bağlayan beden değil tempo")

	session.caravan.stamina = CaravanState.MAX_STAMINA
	ayse.fatigue = 95
	t.ok(session.caravan.can_push(), "sayaç kendi başına zorlamaya izin verir")
	t.not_ok(session.can_push_pace(), "ama en yorgun kişi hızlı tempoyu kilitler")
	ayse.fatigue = CaravanState.MAX_STAMINA - CaravanState.STAMINA_PUSH_FLOOR
	t.ok(session.can_push_pace(), "eşikte hızlı tempo hâlâ açık")

func _test_steady_pace_never_slowed(t) -> void:
	# Planlayıcı sözü: normal tempoda yorgunluk yürüyüşü yavaşlatmaz.
	var session := _session()
	var ayse := _member("Ayşe", CharacterData.BODY_WEIGHT_HEAVY)
	session.add_to_party(ayse)
	var speed_rested := session.get_caravan_theoretical_speed()
	var rate_rested := JourneyController.effective_rate(
		JourneyController.PACE_STEADY, 1.0, speed_rested, 1.0, false
	)
	var walk_rested := JourneyController.new()
	walk_rested.start_leg(10)
	walk_rested.walk(rate_rested, JourneyClock.HOURS_PER_DAY)
	var provisions_rested := session.get_daily_provision_consumption()

	for character in session.get_party():
		character.fatigue = CharacterData.MAX_FATIGUE
	t.eq(session.get_caravan_stamina(), 0, "herkes bitkin: takat sıfır")
	var speed_tired := session.get_caravan_theoretical_speed()
	t.almost(speed_tired, speed_rested, "yorgunluk kervanın hızına girmez")
	var rate_tired := JourneyController.effective_rate(
		JourneyController.PACE_STEADY, 1.0, speed_tired, 1.0, false
	)
	t.almost(rate_tired, rate_rested, "normal tempo yorgunlukla yavaşlamaz")
	var walk_tired := JourneyController.new()
	walk_tired.start_leg(10)
	walk_tired.walk(rate_tired, JourneyClock.HOURS_PER_DAY)
	t.almost(walk_tired.days_covered, walk_rested.days_covered, "bir günlük yürüyüş aynı yolu alır")
	t.not_ok(session.can_push_pace(), "yalnızca gönüllü hızlı tempo kilitlenir")
	t.eq(session.get_daily_provision_consumption(), provisions_rested, "erzak formülü yorgunluğu okumaz")

func _test_combat_penalty_small_and_thresholded(t) -> void:
	var character := _member("Savaşçı")
	var accuracy := character.get_accuracy()
	var dodge := character.get_dodge()
	var damage := character.get_damage_bonus()
	character.fatigue = CharacterData.FATIGUE_COMBAT_THRESHOLD - 1
	t.eq(character.get_accuracy(), accuracy, "eşiğin altında isabet cezası yok")
	t.eq(character.get_dodge(), dodge, "eşiğin altında kaçınma cezası yok")

	character.fatigue = CharacterData.FATIGUE_COMBAT_THRESHOLD
	t.eq(character.get_accuracy(), accuracy - CharacterData.FATIGUE_COMBAT_PENALTY, "yorgun: isabet biraz düşer")
	t.eq(character.get_dodge(), dodge - CharacterData.FATIGUE_COMBAT_PENALTY, "yorgun: kaçınma biraz düşer")
	t.eq(character.get_damage_bonus(), damage, "hasar yorgunluktan etkilenmez")

	character.fatigue = CharacterData.MAX_FATIGUE
	var penalty := accuracy - character.get_accuracy()
	t.eq(penalty, 2 * CharacterData.FATIGUE_COMBAT_PENALTY, "bitkin: ceza iki adım")
	t.le(penalty, 5.0, "ceza küçük kalır (birkaç puan)")

	var unit := CombatUnit.from_character(character, 0)
	t.eq(unit.accuracy, character.get_accuracy(), "savaş birimi cezayı sarmalayıcıdan görür")
	t.eq(unit.dodge, character.get_dodge(), "savaş birimi kaçınma cezasını görür")
