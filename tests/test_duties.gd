extends RefCounted

## Görevler (Duty): DutyCatalog.get_duty_power() sınıf eşleşmesini ve
## etkin statı nasıl birleştiriyor, GameSession bunu somut indirim/azaltma
## sayılarına nasıl çeviriyor.

func suite_name() -> String:
	return "Duties"

func run(t) -> void:
	_test_roles_cover_every_duty(t)
	_test_formation_and_camp_actions(t)
	_test_duty_power_scales_with_class_match(t)
	_test_session_duty_assignment(t)
	_test_discount_and_flat_reduction_formulas(t)

## Kültür statları bulanıklaştırmasın diye taban CharacterStats ile,
## doğrudan alan atamasıyla kurulur - CharacterData.create() kültür
## bonusu uyguluyor, burada tam kontrol gerekiyor.
func _make_plain(class_id: String) -> CharacterData:
	var character := CharacterData.new()
	character.character_name = "Deneme"
	character.class_id = class_id
	character.stats = CharacterStats.new()
	character.current_hp = character.get_max_hp()
	return character

## Görev Y-F09: sınıf rolden bağımsız - aynı statla her sınıf aynı güçte.
func _test_duty_power_scales_with_class_match(t) -> void:
	var guard := _make_plain(ClassCatalog.GUARD)
	var clerk := _make_plain(ClassCatalog.CLERK)
	t.almost(DutyCatalog.get_duty_power(guard, DutyCatalog.MUHAFIZ), 1.0, "taban statta güç nötr")
	t.almost(DutyCatalog.get_duty_power(clerk, DutyCatalog.MUHAFIZ), DutyCatalog.get_duty_power(guard, DutyCatalog.MUHAFIZ), "sınıf gücü değiştirmez")
	guard.stats.endurance = 10
	t.almost(DutyCatalog.get_duty_power(guard, DutyCatalog.MUHAFIZ), 1.25, "etkin stat gücü büyütür")

func _test_session_duty_assignment(t) -> void:
	var session := GameSession.new(200, 0, 2)
	var leader := session.get_player_character()
	leader.class_id = ClassCatalog.GUARD
	leader.stats = CharacterStats.new()

	t.eq(session.get_duty_holder(DutyCatalog.MUHAFIZ), null, "başlangıçta kimse görevli değil")
	t.almost(session.get_duty_multiplier(DutyCatalog.MUHAFIZ), 1.0, "sahipsiz görev nötrdür")

	session.assign_duty(leader, DutyCatalog.MUHAFIZ)
	t.eq(leader.duty_id, DutyCatalog.VANGUARD, "eski görev kimliği rolüne çevrilir")
	t.eq(session.get_duty_holder(DutyCatalog.MUHAFIZ), leader, "atama sahibini döner")
	t.eq(session.get_duty_holder(DutyCatalog.IZCI), leader, "öncü izciliği de kapsar")
	t.eq(session.get_duty_holder(DutyCatalog.TELLAL), leader, "öncü tellallığı da kapsar")
	t.eq(session.get_duty_holder(DutyCatalog.ARABACI), null, "ortancının işi öncüde değil")

	var companion := _make_plain(ClassCatalog.GUARD)
	session.party.append(companion)
	session.assign_duty(companion, DutyCatalog.MUHAFIZ)

	t.eq(session.get_duty_holder(DutyCatalog.MUHAFIZ), companion, "görev el değiştirir")
	t.eq(leader.duty_id, "", "eski sahibin görevi boşa çıkar - bir görevin tek sahibi olur")

func _test_discount_and_flat_reduction_formulas(t) -> void:
	var session := GameSession.new(100, 0, 1)
	var leader := session.get_player_character()
	leader.class_id = ClassCatalog.BREAKER
	leader.stats = CharacterStats.new()
	leader.stats.strength = CharacterStats.MAX_VALUE
	session.assign_duty(leader, DutyCatalog.ARABACI)

	t.almost(session.get_duty_discount(DutyCatalog.ARABACI), 0.1125, "güçlü ortancı indirim verir (sınıf çarpanı yok)")
	t.eq(session.get_duty_flat_reduction(DutyCatalog.ARABACI), 1, "güçlü ortancı hasarı azaltır")
	t.le(session.get_duty_discount(DutyCatalog.TELLAL), 0.001, "sahipsiz görevde indirim yoktur")
	t.eq(session.get_duty_flat_reduction(DutyCatalog.TELLAL), 0, "sahipsiz görevde azaltma yoktur")

	# Göçebe'nin INTELLECT -1 kültür bonusu, Levazımcı/Otacı gibi INTELLECT
	# gerektiren bir görevde get_duty_power'ı 1.0'ın altına düşürebiliyor
	# (bkz. DutyCatalog.get_duty_power) - ama bir görevi kimsesiz bırakmak
	# hiçbir zaman ceza olmamalı, o yüzden atanmış-ama-uygunsuz biri de en
	# kötü ihtimalle nötr kalmalı, sahipsizden daha kötü değil (bkz.
	# GameSession.get_duty_flat_reduction'daki taban).
	var mismatched := CharacterData.create("Uygunsuz", CultureCatalog.NOMAD, CharacterStats.new())
	session.party.append(mismatched)
	session.assign_duty(mismatched, DutyCatalog.LEVAZIMCI)
	t.le(DutyCatalog.get_duty_power(mismatched, DutyCatalog.LEVAZIMCI), 1.0, "eksi kültür bonusu gücü 1.0 altına düşürür")
	t.eq(session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI), 0, "azaltma yine de negatife düşmez")
	t.le(session.get_duty_discount(DutyCatalog.LEVAZIMCI), 0.001, "indirim de negatife düşmez")

## Üç rol (Y-F09): her eski görev bir role bağlı, roller üç bölgeye dağılır,
## eski kayıttaki görev rolüne göçer.
func _test_roles_cover_every_duty(t) -> void:
	t.eq(DutyCatalog.get_duties().size(), 3, "atanabilir üç rol")
	var zones := {}
	for role in DutyCatalog.ROLES:
		zones[DutyCatalog.ROLE_ZONES[role]] = true
		t.ok(DutyCatalog.get_duty(role) != null, "%s rolü katalogda" % role)
	t.eq(zones.size(), 3, "roller üç ayrı bölgede")
	for duty in [DutyCatalog.MUHAFIZ, DutyCatalog.IZCI, DutyCatalog.LEVAZIMCI, DutyCatalog.ARABACI, DutyCatalog.TELLAL, DutyCatalog.OTACI]:
		t.ok(DutyCatalog.ROLES.has(DutyCatalog.role_of(duty)), "%s bir role bağlı (etkisi kaybolmadı)" % duty)
	var old := CharacterData.create("Eski", CultureCatalog.VALLEY, CharacterStats.new()).to_dict()
	old["duty_id"] = DutyCatalog.OTACI
	t.eq(CharacterData.from_dict(old).duty_id, DutyCatalog.REAR, "eski kayıttaki otacı artçıya göçer")

## Kampta diziliş ve akşam eylemleri (Y-B12): öncünün bedeli, iki eylem sınırı,
## eylemlerin etkisi; rol sahibi kendi bölgesinin işaretine bakar (Y-B04).
func _test_formation_and_camp_actions(t) -> void:
	var session := GameSession.new(300, 30, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	var party := session.get_party()
	var front: CharacterData = party[1]
	session.set_formation(front, party[0], null)
	t.eq(session.get_duty_holder(DutyCatalog.VANGUARD), front, "öncü seçildi")
	t.eq(session.get_duty_holder(DutyCatalog.MIDDLE), party[0], "ortancı seçildi")
	t.eq(session.get_duty_holder(DutyCatalog.REAR), null, "artçı boş kalabilir")
	var destination := WorldMapData.get_routes_from(session.current_location_id)[0].to_location_id
	session.start_journey(destination, 6, 0.2, CaravanPlan.new(WorldMapData.get_location_by_id(destination), 6))
	front.stress = 0
	session.advance_day()
	t.ok(front.stress >= GameSession.VANGUARD_DAILY_STRESS, "önde olmanın bedeli: öncünün stresi artar")
	party[0].current_hp = 1
	var done := session.apply_camp_actions([GameSession.CAMP_ACTION_WOUNDS, GameSession.CAMP_ACTION_HUNT, GameSession.CAMP_ACTION_TALES])
	t.eq(done.size(), GameSession.CAMP_ACTION_LIMIT, "akşam en fazla iki eylem")
	t.ok(party[0].current_hp > 1, "yaralı sarıldı")
	t.eq(session.apply_camp_actions(["uydurma"]).size(), 0, "bilinmeyen eylem uygulanmaz")
	var signals := RoadSignals.new()
	signals.open_signals = [{"kind": RoadSignals.KIND_SMOKE, "age_hours": 0.0, "truth": "herders"}]
	var outcome := signals.tick(30.0, RoadAttention.ZONE_REAR, RandomNumberGenerator.new(), 0, {RoadAttention.ZONE_FRONT: 1.0})
	t.eq(outcome["resolved_by_role"], [RoadAttention.ZONE_FRONT], "öncü kendi bölgesindeki işarete baktı")
