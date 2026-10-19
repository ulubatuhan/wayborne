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
	_test_origins(t)
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

## Y-D05: en az beş açılabilir köken, açılımlar meta kayıtta, her köken bir
## takas (borçsuz olan yoksul, ünlü olan daha borçlu).
func _origin_session(origin: String) -> GameSession:
	var session := GameSession.new(200, 20, 1)
	session.inherit_father_caravan()
	StartOrigins.apply(session, origin)
	return session

func _test_origins(t) -> void:
	t.ok(StartOrigins.ORDER.size() - 1 >= 5, "en az beş açılabilir köken")
	var unlocked := LineageArchive.unlocked_origins()
	t.ok(unlocked.has(StartOrigins.EXILE), "bir soy bitince sürgün açılır")
	t.not_ok(unlocked.has(StartOrigins.GUILD_WARD), "on sefer yapmayan soy lonca kökenini açmaz")
	var long_lineage := {"journeys": 12, "graves": [1, 2, 3], "days": 130, "generations": 3}
	t.eq(StartOrigins.unlocks_for(long_lineage).size(), 5, "uzun bir soy beşini de açar")
	t.ok(StartOrigins.is_unlocked(StartOrigins.FATHER, []), "babanın kervanı her zaman açık")
	var father := _origin_session(StartOrigins.FATHER)
	var father_debt := father.debts.get_total_owed()
	var exile := _origin_session(StartOrigins.EXILE)
	t.eq(exile.debts.get_total_owed(), 0, "sürgün borçsuz")
	t.ok(exile.wallet.balance < father.wallet.balance, "sürgünün kesesi hafif")
	t.ok(exile.reputation < father.reputation, "sürgünün adı kötü")
	var ward := _origin_session(StartOrigins.GUILD_WARD)
	t.ok(ward.reputation > father.reputation and ward.debts.get_total_owed() > father_debt, "lonca yetiştirmesi: ünlü ama daha borçlu")
	var salt := _origin_session(StartOrigins.SALT_RUNNER)
	t.eq(salt.get_total_quantity(ItemCatalog.CONTRABAND_SALT), StartOrigins.SALT_RUNNER_SALT, "kaçakçı tuzla başlar")
	t.ok(salt.debts.get_debt(GameSession.FATHER_DEBT_ID).due_day < father.debts.get_debt(GameSession.FATHER_DEBT_ID).due_day, "kaçakçının alacaklısı sabırsız")
	var drovers := _origin_session(StartOrigins.DROVERS)
	t.ok(drovers.get_provisions() > father.get_provisions() and drovers.wallet.balance < father.wallet.balance, "sürücüler: azık bol, altın az")
	var widow := _origin_session(StartOrigins.WIDOW_LEDGER)
	t.ok(widow.debts.get_total_owed() < father_debt, "dulun defteri borcu yarıya indirir")
	var reloaded := GameSession.new(0, 0, 1)
	reloaded.load_from_dict(widow.to_save_dict())
	t.eq(reloaded.origin_id, StartOrigins.WIDOW_LEDGER, "köken kayıtta")
