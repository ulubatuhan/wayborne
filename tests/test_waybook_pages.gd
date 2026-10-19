extends RefCounted

## Defterin "Düşenler" açılımı (görev 9.11): kim düşmüş sayılır, mezar
## işaretinin rütbesi, düşenin rolü kayda geçiyor mu, hikâye satırları kısa
## özetle yazılıyor mu. Sayfanın görünüşü screenshot_waybook.gd'de.

func suite_name() -> String:
	return "WaybookPages"

func run(t) -> void:
	TranslationServer.set_locale("tr")
	_test_fallen_lists_founder_and_dead_only(t)
	_test_ranks(t)
	_test_role_recorded_and_saved(t)
	_test_story_summaries_exist(t)
	_test_story_text_uses_summary(t)

func _session() -> GameSession:
	var session := GameSession.new(250, 20)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	session.start_playthrough(CharacterData.create("Ahmet", CultureCatalog.NOMAD, CharacterStats.new()), rng)
	return session

func _test_fallen_lists_founder_and_dead_only(t) -> void:
	var session := _session()
	var companion := CharacterData.create("Elif", CultureCatalog.NOMAD, CharacterStats.new())
	session.add_to_party(companion)
	var leaving := CharacterData.create("Mert", CultureCatalog.NOMAD, CharacterStats.new())
	session.add_to_party(leaving)
	session.dismiss(leaving)
	var dead: Array[CharacterData] = [companion]
	session.resolve_deaths(dead, "LEDGER_CAUSE_STARVED", WorldMapData.START_LOCATION_ID)
	var names: Array[String] = []
	for entry in session.ledger.fallen():
		names.append(String(entry.get("name", "")))
	t.ok(names.has("Elif"), "ölen düşenlerde")
	t.ok(not names.has("Mert"), "ayrılan düşenlerde değil")
	t.ok(String(session.ledger.fallen()[0].get("kind", "")) == CaravanLedger.KIND_FOUNDER, "kurucu ilk satır")

func _test_ranks(t) -> void:
	var ledger := CaravanLedger.new()
	ledger.record(CaravanLedger.KIND_FOUNDER, "Baba", 0, 0)
	ledger.record(CaravanLedger.KIND_LED, "Ahmet", 0, 1, "c1")
	ledger.record(CaravanLedger.KIND_DIED, "Ahmet", 40, 1, "c1", "LEDGER_CAUSE_STARVED")
	ledger.record(CaravanLedger.KIND_DIED, "Elif", 20, 1, "c2", "LEDGER_CAUSE_STARVED")
	ledger.record(CaravanLedger.KIND_DIED, "Tayfa", 30, 1, "", "LEDGER_CAUSE_STARVED")
	var leaders := ledger.leader_generations()
	var fallen := ledger.fallen()
	t.eq(fallen.size(), 4, "kurucu ve üç ölü")
	t.eq(GraveMark.rank_for(fallen[0], leaders), GraveMark.Rank.FOUNDER, "kurucu rütbesi")
	t.eq(GraveMark.rank_for(fallen[1], leaders), GraveMark.Rank.LEADER, "adı taşıyan lider rütbesinde")
	t.eq(GraveMark.rank_for(fallen[2], leaders), GraveMark.Rank.COMPANION, "kimlikli ölü yoldaş")
	t.eq(GraveMark.rank_for(fallen[3], leaders), GraveMark.Rank.CREW, "kimliksiz ölü tayfa")
	t.eq(int(leaders.get("c1", 0)), 1, "liderin kuşağı")

func _test_role_recorded_and_saved(t) -> void:
	var session := _session()
	var companion := CharacterData.create("Elif", CultureCatalog.NOMAD, CharacterStats.new())
	session.add_to_party(companion)
	var dead: Array[CharacterData] = [companion]
	session.resolve_deaths(dead, "LEDGER_CAUSE_STARVED", WorldMapData.START_LOCATION_ID)
	var entry: Dictionary = session.ledger.fallen().back()
	t.eq(String(entry.get("role", "")), companion.class_id, "düşenin sınıfı kayda geçiyor")
	var copy := CaravanLedger.new()
	copy.load_from_array(session.ledger.to_array())
	t.eq(String(copy.fallen().back().get("role", "")), companion.class_id, "rol kayıttan geri geliyor")
	var old := CaravanLedger.new()
	old.load_from_array([{"kind": "died", "name": "Eski", "day": 3}])
	t.eq(String(old.entries[0].get("role", "?")), "", "eski kayıtta rol boş")
	t.ok(CaravanLedger.describe_cause(entry).contains(String(TranslationServer.translate("LEDGER_CAUSE_STARVED"))),
		"sebep metni adsız yazılıyor")

func _test_story_summaries_exist(t) -> void:
	for backstory in CampStory.STORY_KEYS:
		for key in CampStory.STORY_KEYS[backstory]:
			var line_key := String(key) + "_LINE"
			t.ok(String(TranslationServer.translate(line_key)) != line_key, "%s özeti var" % key)

func _test_story_text_uses_summary(t) -> void:
	var entry := {"kind": CaravanLedger.KIND_STORY, "name": "Selin", "day": 12, "cause": "STORY_DEBTOR_1"}
	var text := WaybookPanel.story_text(entry)
	t.ok(text.begins_with("Gün 12: Selin"), "hikâye satırı gün ve adla başlıyor: %s" % text)
	t.ok(not text.contains("Babamın"), "tam paragraf değil, özet")
	var ledger_line := WaybookPanel.ledger_text(entry)
	t.ok(ledger_line.contains("(gün 12)") and ledger_line.begins_with("Selin"), "defter satırı özet ve gün")
	var memorial := {"kind": CaravanLedger.KIND_MEMORIAL, "name": "Eski Soy", "day": 0, "cause": ""}
	t.eq(WaybookPanel.story_text(memorial), CaravanLedger.describe(memorial), "özeti olmayan satır defter biçiminde")
