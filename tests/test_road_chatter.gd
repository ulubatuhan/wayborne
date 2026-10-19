extends RefCounted

## Yolun sohbeti (görevler R0, R1 #1, Y-B01): konu önceliği, konu soğuması,
## tohumlu seçim, bağın günde bir artması ve sınırı, geçmişin kimlikten
## tohumlanması ve kayıttan dönmesi, defterin yeni türlerinin sayaçlara girmemesi.

func suite_name() -> String:
	return "RoadChatter"

func run(t) -> void:
	_test_priority(t)
	_test_cooldown_and_rapport(t)
	_test_backstory_is_seeded_and_saved(t)
	_test_new_ledger_kinds_count_for_nothing(t)
	_test_every_line_key_exists(t)

func _person() -> CharacterData:
	var c := CharacterData.create("Yoldaş", CultureCatalog.HIGHLAND, CharacterStats.new())
	c.character_id = "c0_7"
	c.backstory_id = CharacterData.BACKSTORY_EXILE
	return c

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func _test_priority(t) -> void:
	var c := _person()
	c.add_grievance(CharacterData.GRIEVANCE_UNFED)
	var picked := RoadChatter.pick(c, {"day": 5}, _rng(1))
	t.eq(String(picked["topic"]), "grievance_unfed", "en üst şikâyet önce konuşulur")
	t.ok(RoadChatter.GRIEVANCE_LINES["unfed"].has(String(picked["key"])), "şikâyetin kendi satırından")
	var calm := _person()
	t.eq(String(RoadChatter.pick(calm, {"day": 5}, _rng(1))["topic"]), "backstory", "derdi yoksa geçmişini anlatır")
	var again := RoadChatter.pick(c, {"day": 5}, _rng(1))
	t.eq(again, picked, "aynı tohum aynı söz")

func _test_cooldown_and_rapport(t) -> void:
	var c := _person()
	var first := RoadChatter.pick(c, {"day": 10}, _rng(2))
	t.ok(RoadChatter.apply(c, first, 10), "günün ilk sohbeti bağı artırır")
	t.eq(c.rapport, 1, "bağ bir arttı")
	t.not_ok(RoadChatter.apply(c, first, 10), "aynı gün ikinci sohbet bağı artırmaz")
	t.eq(c.rapport, 1, "bağ günde en fazla bir")
	var next := RoadChatter.pick(c, {"day": 11}, _rng(3))
	t.ok(String(next["topic"]) != String(first["topic"]), "aynı konu üç gün içinde tekrarlanmaz")
	var later := RoadChatter.pick(c, {"day": 10 + RoadChatter.TOPIC_COOLDOWN_DAYS}, _rng(3))
	t.eq(String(later["topic"]), String(first["topic"]), "soğuma bitince konu geri döner")
	for day in range(20, 40):
		RoadChatter.apply(c, RoadChatter.pick(c, {"day": day}, _rng(day)), day)
	t.eq(c.rapport, CharacterData.MAX_RAPPORT, "bağ tavanda durur")
	c.change_rapport(-99)
	t.eq(c.rapport, 0, "bağ sıfırın altına inmez")

func _test_backstory_is_seeded_and_saved(t) -> void:
	var session := GameSession.new(100, 10, 1)
	var rng := _rng(9)
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	var all_have := true
	for character in session.get_party():
		if not CharacterData.BACKSTORY_KEYS.has(character.backstory_id):
			all_have = false
	t.ok(all_have, "kadroya katılan herkesin geçmişi var")
	var someone := session.get_party()[0]
	t.eq(someone.backstory_id, CharacterData.backstory_for_id(someone.character_id), "geçmiş kimlikten tohumlu")
	someone.rapport = 3
	someone.last_chat_topic = "duty"
	var copy := CharacterData.from_dict(JSON.parse_string(JSON.stringify(someone.to_dict())))
	t.eq(copy.backstory_id, someone.backstory_id, "geçmiş kayıttan döner")
	t.eq(copy.rapport, 3, "bağ kayıttan döner")
	t.eq(copy.last_chat_topic, "duty", "son konu kayıttan döner")

func _test_new_ledger_kinds_count_for_nothing(t) -> void:
	var session := GameSession.new(100, 10, 1)
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), _rng(4))
	var lost := session.get_companions_lost()
	for kind in [CaravanLedger.KIND_STORY, CaravanLedger.KIND_DIARY, CaravanLedger.KIND_CODE, CaravanLedger.KIND_VERDICT, CaravanLedger.KIND_MEMORIAL]:
		session.ledger.record(kind, "Biri", 3)
		t.not_ok(session.ledger.is_struck(session.ledger.entries[-1]), "%s çizili değil" % kind)
		t.ok(CaravanLedger.KIND_LABEL_KEYS.has(kind), "%s adı var" % kind)
	t.eq(session.get_companions_lost(), lost, "yeni türler kayıp sayılmaz")

func _test_every_line_key_exists(t) -> void:
	var keys: Array = []
	for table in [RoadChatter.GRIEVANCE_LINES, RoadChatter.BACKSTORY_LINES, RoadChatter.DUTY_LINES, RoadChatter.CULTURE_LINES, RoadChatter.WEATHER_LINES]:
		for k in table:
			keys.append_array(table[k])
	keys.append_array(RoadChatter.STRESS_LINES)
	keys.append_array(RoadChatter.NIGHT_LINES)
	keys.append_array(RoadChatter.GENERIC_LINES)
	var missing: Array = []
	for key in keys:
		if String(TranslationServer.translate(String(key))) == String(key):
			missing.append(key)
	t.eq(missing.size(), 0, "her sohbet satırı çevrilmiş %s" % str(missing))
	for culture in CultureCatalog.get_cultures():
		t.ok(RoadChatter.CULTURE_LINES.has(culture.culture_id), "%s kültürünün satırı var" % culture.culture_id)
