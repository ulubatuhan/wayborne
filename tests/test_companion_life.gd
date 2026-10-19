extends RefCounted

## Yoldaşların bağı, kendi kararları ve kamp hikâyeleri (görevler R1 #2-#4,
## Y-C17): bağ kuralları ve sınırları, eşik notları, varis kavgası, günlük
## dostluk ve husumet, kendi kararının yalnız dertliye gelmesi, hikâye kapıları,
## bölüm ilerlemesi ve sır, kayıt.

func suite_name() -> String:
	return "CompanionLife"

func run(t) -> void:
	_test_bond_rules(t)
	_test_session_bonds(t)
	_test_own_actions(t)
	_test_camp_stories(t)

func _person(name: String, culture: String, id: String) -> CharacterData:
	var c := CharacterData.create(name, culture, CharacterStats.new())
	c.character_id = id
	c.backstory_id = CharacterData.backstory_for_id(id)
	return c

func _session() -> GameSession:
	var session := GameSession.new(300, 40, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	return session

func _test_bond_rules(t) -> void:
	var a := _person("A", CultureCatalog.NOMAD, "c0_1")
	var b := _person("B", CultureCatalog.NOMAD, "c0_2")
	var c := _person("C", CultureCatalog.PORT, "c0_3")
	var bonds := {}
	t.eq(CompanionLife.get_bond(bonds, a, b), 1.0, "aynı kültür +1 başlar")
	t.eq(CompanionLife.get_bond(bonds, a, c), 0.0, "farklı kültür 0 başlar")
	t.eq(CompanionLife.bond_key(a, b), CompanionLife.bond_key(b, a), "bağ simetrik")
	t.eq(CompanionLife.change_bond(bonds, a, b, 1.0), "friends", "eşik geçilince dostluk")
	t.eq(CompanionLife.change_bond(bonds, a, b, 5.0), "", "eşik bir kez söylenir")
	t.eq(CompanionLife.get_bond(bonds, a, b), CompanionLife.MAX_BOND, "bağ tavanda")
	t.eq(CompanionLife.change_bond(bonds, a, c, -2.0), "rivals", "eşik geçilince husumet")
	t.ok(CompanionLife.pair_gap_scale(2.0) < 1.0 and CompanionLife.pair_gap_scale(-2.0) > 1.0 and CompanionLife.pair_gap_scale(0.0) == 1.0, "dostlar sıkı, düşmanlar açık yürür")

func _test_session_bonds(t) -> void:
	var session := _session()
	var party := session.get_party()
	var player := session.get_player_character()
	var mate: CharacterData = party[1] if party[0] == player else party[0]
	var before := session.get_bond(player, mate)
	session.companion_notes = []
	session.bond_group(party, 3.0)
	t.ok(session.get_bond(player, mate) > before, "ortak iş bağı artırır")
	t.ok(not session.companion_notes.is_empty(), "dostluk eşiği günlüğe not düşer")
	var copy := GameSession.new(0, 0)
	copy.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	t.eq(copy.bonds, session.bonds, "bağlar kayıttan döner")
	mate.stress = 30
	session._companion_day()
	t.ok(mate.stress < 30, "dost yanında stres hafifler")
	var bond_before := session.get_bond(player, mate)
	session.appoint_heir(mate)
	t.ok(session.get_bond(player, mate) <= bond_before, "atlanan büyük ile varisin arası açılır (atlanan buysa)")

func _test_own_actions(t) -> void:
	var calm := _person("Sakin", CultureCatalog.VALLEY, "c0_9")
	var troubled := _person("Dertli", CultureCatalog.VALLEY, "c0_10")
	troubled.add_grievance(CharacterData.GRIEVANCE_UNFED, 2)
	t.not_ok(CompanionLife.is_troubled(calm), "derdi olmayan kendi kararını vermez")
	t.ok(CompanionLife.is_troubled(troubled), "iki şikâyetli dertlidir")
	var party: Array[CharacterData] = [calm, troubled]
	var acts := 0
	var calm_acted := false
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for day in 600:
		var acted := CompanionLife.roll_action(party, day, rng)
		if acted.is_empty():
			continue
		acts += 1
		if acted[0] == calm:
			calm_acted = true
		(acted[0] as CharacterData).last_action_day = day
	t.not_ok(calm_acted, "sakin kişi hiç kendi kararını vermez")
	t.ok(acts >= 10 and acts <= 600 / CompanionLife.ACTION_COOLDOWN_DAYS, "dertli ara sıra, soğumayla (%d)" % acts)

func _test_camp_stories(t) -> void:
	var c := _person("Anlatan", CultureCatalog.FISHER, "c0_12")
	t.not_ok(CampStory.can_tell(c), "tanışmadan hikâye yok")
	c.rapport = 1
	t.ok(CampStory.can_tell(c), "bağ 1: ilk bölüm açılır")
	var session := _session()
	session.party.append(c)
	var lines := session.ledger.entries.size()
	session.resolve_camp_story(c, CampStory.CHOICE_LISTEN)
	t.eq(c.story_chapter, 1, "dinlemek bölümü ilerletir")
	t.eq(c.rapport, 2, "dinlemek bağı artırır")
	t.eq(session.ledger.entries.size(), lines + 1, "deftere hikâye satırı")
	t.eq(String(session.ledger.entries[-1]["kind"]), CaravanLedger.KIND_STORY, "satır hikâye türünde")
	t.eq(session.roll_camp_story(), null, "günde bir hikâye")
	t.not_ok(CampStory.can_tell(c), "ikinci bölüm bağ 3 ister")
	c.rapport = 5
	c.story_chapter = 2
	c.add_grievance(CharacterData.GRIEVANCE_WITNESSED_DEATH, 3)
	c.stress = 40
	session.last_story_day = -99
	session.resolve_camp_story(c, CampStory.CHOICE_LISTEN)
	t.eq(c.story_chapter, 3, "sır bölümü anlatıldı")
	t.not_ok(c.grievances.has(CharacterData.GRIEVANCE_WITNESSED_DEATH), "sır en ağır şikâyeti siler")
	t.ok(c.stress < 40, "sırrını söyleyen hafifler")
	t.not_ok(CampStory.can_tell(c), "hikâye bitti")
	var copy := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())))
	t.eq(copy.story_chapter, 3, "bölüm kayıttan döner")
	var missing: Array = []
	for backstory in CharacterData.BACKSTORY_KEYS:
		t.eq((CampStory.STORY_KEYS[backstory] as Array).size(), 3, "%s üç bölüm" % backstory)
		t.ok(CampStory.GOAL_KEYS.has(backstory), "%s hedefi var" % backstory)
		for key in CampStory.STORY_KEYS[backstory] + [CampStory.GOAL_KEYS[backstory], CharacterData.BACKSTORY_LABEL_KEYS[backstory]]:
			if String(TranslationServer.translate(String(key))) == String(key):
				missing.append(key)
	t.eq(missing.size(), 0, "her hikâye ve hedef çevrilmiş %s" % str(missing))
