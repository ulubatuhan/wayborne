extends RefCounted

## Soy mirası (Y-D03): biten bir soyun izi arşive yazılır, yeni oyun onu okur -
## mezarlar yollara döner (soluk), ünün bir payı ve bir yadigâr gelir, defter
## eski soyu anar, miras kayıtta kalır. Arşiv testte geçici bir dosyaya yazılır.

const TEST_PATH: String = "user://test_lineage_archive.json"

func suite_name() -> String:
	return "LineageArchive"

func run(t) -> void:
	var saved_path := LineageArchive.path
	LineageArchive.path = TEST_PATH
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)
	_test_record_and_latest(t)
	_test_apply(t)
	_test_cap(t)
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)
	LineageArchive.path = saved_path

func _ended_session() -> GameSession:
	var session := GameSession.new(200, 20, 1)
	session.caravan_name = "Eski Kervan"
	session.lineage_generation = 3
	session.reputation = 40
	session.road_position = {"route": "a|b", "share": 0.4}
	session.add_memorial(GameSession.MEMORIAL_GRAVE, "Ayşe", "LEDGER_CAUSE_STARVED")
	session.add_memorial(GameSession.MEMORIAL_ASH)
	return session

func _test_record_and_latest(t) -> void:
	t.ok(LineageArchive.latest().is_empty(), "arşiv boşken eski soy yok")
	LineageArchive.record(_ended_session())
	var old := LineageArchive.latest()
	t.eq(String(old["caravan_name"]), "Eski Kervan", "soyun adı arşivde")
	t.eq(int(old["generations"]), 3, "kuşak sayısı arşivde")
	t.eq((old["graves"] as Array).size(), 1, "yalnızca mezarlar taşınır, kül değil")

func _test_apply(t) -> void:
	var fresh := GameSession.new(200, 20, 1)
	var rep_before := fresh.reputation
	var legacy := LineageArchive.apply_to(fresh, LineageArchive.latest())
	t.eq(String(legacy["from"]), "Eski Kervan", "miras kimden geldiğini söyler")
	t.eq(fresh.reputation - rep_before, mini(LineageArchive.MAX_REPUTATION_LEGACY, int(40 * LineageArchive.REPUTATION_SHARE)), "ünün payı tavanlı")
	t.eq(fresh.get_total_quantity(ItemCatalog.RARE_RELIC), 1, "yadigâr yüklü")
	var graves := fresh.map_graves()
	t.eq(graves.size(), 1, "eski mezar haritada")
	t.ok(bool(graves[0]["old"]), "eski soyun mezarı soluk işaretli")
	t.eq(String(fresh.ledger.entries[-1]["cause"]), "LEDGER_CAUSE_OLD_LINEAGE", "defter eski soyu anar")
	var reloaded := GameSession.new(0, 0, 1)
	reloaded.load_from_dict(fresh.to_save_dict())
	t.eq(String(reloaded.legacy.get("from", "")), "Eski Kervan", "miras kayıtta kalır")
	t.ok(LineageArchive.apply_to(GameSession.new(200, 20, 1), {}).is_empty(), "eski soy yoksa hiçbir şey değişmez")

func _test_cap(t) -> void:
	for i in LineageArchive.MAX_LINEAGES + 3:
		LineageArchive.record(_ended_session())
	t.eq(LineageArchive.load_all().size(), LineageArchive.MAX_LINEAGES, "arşiv tavanlı, en eski düşer")
