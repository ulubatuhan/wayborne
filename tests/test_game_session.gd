extends RefCounted

## GameSession bilerek RefCounted: autoload olmadan örneklenebiliyor,
## bu yüzden burada doğrudan test ediliyor. En kritik iki şey parti
## kapasitesinin vagona bağlı olması ve kaydın hiçbir şeyi düşürmemesi.

func suite_name() -> String:
	return "GameSession"

func run(t) -> void:
	_test_party_capacity_follows_wagons(t)
	_test_recruiting_rules(t)
	_test_player_cannot_be_dismissed(t)
	_test_cargo_capacity(t)
	_test_save_round_trip(t)
	_test_event_context(t)
	_test_equipment_locker_and_equip(t)

func _make_recruit(recruit_name: String, cost: int) -> CharacterData:
	var candidate := CharacterData.create(recruit_name, CultureCatalog.NOMAD, CharacterStats.new())
	candidate.hire_cost = cost
	return candidate

func _test_party_capacity_follows_wagons(t) -> void:
	# Her vagonda iki kişi yatar; tavan savaş alanının dört mevkisi.
	t.eq(GameSession.new(100, 0, 1).get_party_capacity(), 2, "tek vagon iki kişi taşır")
	t.eq(GameSession.new(100, 0, 2).get_party_capacity(), 4, "iki vagon dört kişi taşır")
	t.eq(
		GameSession.new(100, 0, 4).get_party_capacity(),
		GameSession.MAX_PARTY_SIZE,
		"kapasite savaş alanının tavanını aşmaz"
	)

	var session := GameSession.new(100, 0, 1)
	t.eq(session.get_party().size(), 1, "oyuncu yola tek başına çıkar")
	t.ne(session.get_player_character(), null, "kayıtsız oturumda bile bir karakter var")

func _test_recruiting_rules(t) -> void:
	var session := GameSession.new(200, 0, 1)

	t.ok(session.can_recruit(), "tek vagonla bir kişilik yer var")
	t.ok(session.recruit(_make_recruit("Ucuz", 50)), "kese yetince katılır")
	t.eq(session.wallet.balance, 150, "ücret keseden düşer")
	t.eq(session.get_party().size(), 2, "parti büyür")
	t.not_ok(session.can_recruit(), "tek vagonun yeri doldu")
	t.not_ok(session.recruit(_make_recruit("Fazla", 10)), "yer yokken katılamaz")

	session.owned_wagon_count = 2
	t.ok(session.can_recruit(), "vagon alınca yer açılır")
	t.not_ok(session.recruit(_make_recruit("Pahalı", 9999)), "kese yetmezse katılmaz")
	t.eq(session.wallet.balance, 150, "başarısız alımda para gitmez")
	t.eq(session.get_party().size(), 2, "başarısız alımda parti değişmez")

func _test_player_cannot_be_dismissed(t) -> void:
	var session := GameSession.new(500, 0, 2)
	var leader := session.get_player_character()
	t.ok(session.recruit(_make_recruit("Yoldaş", 0)), "yoldaş katılır")

	t.not_ok(session.dismiss(leader), "oyuncu partiden çıkarılamaz")
	t.eq(session.get_party().size(), 2, "başarısız çıkarma partiyi bozmaz")

	t.ok(session.swap_party_positions(0, 1), "mevkiler değiştirilebilir")
	t.eq(session.get_party()[1], leader, "oyuncu arkaya geçebilir")
	t.not_ok(session.swap_party_positions(0, 5), "liste dışı mevki reddedilir")

	# Arkaya geçmek kimliği değiştirmemeli: bir zamanlar kontrol sıraya
	# bakıyordu, dolayısıyla oyuncu kendini atabiliyor, yoldaşını
	# atamıyor ve kültür perki yoldaşınkine kayıyordu.
	t.eq(session.get_player_character(), leader, "arkaya geçen oyuncu hâlâ oyuncu")
	t.eq(
		session.get_player_culture().culture_id,
		leader.culture_id,
		"perkler mevki değişince başkasına geçmez"
	)
	t.not_ok(session.dismiss(leader), "arkadaki oyuncu da çıkarılamaz")

	t.ok(session.dismiss(session.get_party()[0]), "öndeki yoldaşa yol verilebilir")
	t.eq(session.get_party().size(), 1, "parti küçülür")
	t.eq(session.get_party()[0], leader, "geriye oyuncu kalır")

func _test_cargo_capacity(t) -> void:
	var session := GameSession.new(100, 0, 3)
	t.almost(
		session.get_cargo_capacity(),
		3.0 * GameSession.CARGO_PER_WAGON,
		"kargo kapasitesi vagon başına sabit"
	)
	t.almost(
		session.get_cargo_space_remaining(),
		session.get_cargo_capacity(),
		"boş kervanda tüm kapasite serbest"
	)

func _test_save_round_trip(t) -> void:
	var original := GameSession.new(300, 15, 2)
	original.reputation = 7
	original.total_days_elapsed = 12
	original.learn_route("test_loc_a", "test_loc_b")
	original.set_flag("deneme_bayragi")
	original.owned_wagon_damaged = 1
	original.add_equipment(EquipmentCatalog.RING_MARKSMAN, 2)
	original.set_player_character(
		CharacterData.create("Kayıtlı", CultureCatalog.FISHER, CharacterStats.new(), 188, 3)
	)
	t.ok(original.recruit(_make_recruit("Yoldaş", 0)), "kayıt öncesi yoldaş katılır")

	# Yükleme taze bir oturum üzerinde yapılır, yoksa erzak iki kez eklenir.
	var restored := GameSession.new(0, 0)
	restored.load_from_dict(original.to_save_dict())

	t.eq(restored.wallet.balance, original.wallet.balance, "altın korunur")
	t.eq(restored.get_provisions(), original.get_provisions(), "erzak korunur")
	t.eq(restored.current_location_id, original.current_location_id, "konum korunur")
	t.eq(restored.reputation, original.reputation, "itibar korunur")
	t.eq(restored.total_days_elapsed, original.total_days_elapsed, "gün sayacı korunur")
	t.eq(restored.owned_wagon_count, original.owned_wagon_count, "vagon sayısı korunur")
	t.eq(restored.owned_wagon_damaged, original.owned_wagon_damaged, "hasar korunur")
	t.ok(restored.is_route_known("test_loc_a", "test_loc_b"), "öğrenilen rota korunur")
	t.ok(restored.is_route_known("test_loc_b", "test_loc_a"), "rota iki yönlü kaydedilir")
	t.ok(restored.has_flag("deneme_bayragi"), "bayraklar korunur")
	t.eq(restored.get_equipment_count(EquipmentCatalog.RING_MARKSMAN), 2, "ekipman deposu korunur")

	t.eq(restored.get_party().size(), 2, "parti korunur")
	t.eq(restored.get_player_character().character_name, "Kayıtlı", "oyuncu ilk sırada kalır")
	t.eq(restored.get_player_character().height_cm, 188, "görünüş korunur")
	t.eq(restored.get_player_character().skin_tone, 3, "ten rengi korunur")
	t.eq(restored.get_party_capacity(), original.get_party_capacity(), "kapasite yeniden hesaplanır")

func _test_event_context(t) -> void:
	var session := GameSession.new(250, 20, 2)
	var context := session.build_event_context()

	t.eq(context.get("gold"), 250, "bağlamda altın var")
	t.eq(context.get("provisions"), 20, "bağlamda erzak var")
	t.eq(context.get("party_size"), 1, "bağlamda parti sayısı var")
	t.eq(
		context.get("party_slots_free"),
		session.get_party_capacity() - 1,
		"boş yer sayısı hazır veriliyor"
	)
	t.ok(context.has("flags"), "bağlamda bayrak sözlüğü var")

	# İzci ve kültür de aynı gerekçeyle (yalnızca sabitle karşılaştırma)
	# 0/1'e çevrilip hazır geliyor - bkz. evt_scouted_pass, evt_culture_*.
	t.eq(context.get("has_izci"), 0.0, "kimse İzci değilken bağlam 0 döner")
	session.assign_duty(session.get_player_character(), DutyCatalog.IZCI)
	t.eq(session.build_event_context().get("has_izci"), 1.0, "İzci atanınca bağlam 1 döner")

	session.get_player_character().culture_id = CultureCatalog.HIGHLAND
	var culture_context := session.build_event_context()
	t.eq(culture_context.get("is_highland_culture"), 1.0, "oyuncunun kültürü doğru bayrağı işaretler")
	t.eq(culture_context.get("is_nomad_culture"), 0.0, "eşleşmeyen kültür bayrağı sıfır kalır")

	# Koşullar bir anahtarı yalnızca sabitle karşılaştırabildiği için
	# boş yer sayısının hazır gelmesi şart (bkz. evt_road_wanderer).
	var condition := EventCondition.make(
		"party_slots_free", EventCondition.Op.GREATER_EQUAL, 1
	)
	t.ok(condition.is_met(context), "yer varken yolcu olayı açılabilir")

## Kervanın ortak equipment_inventory deposu ile CharacterData.equipped
## arasındaki alışveriş - bkz. GameSession.equip_to_character/
## unequip_from_character (character.gd'nin equip paneli bunu çağırır).
func _test_equipment_locker_and_equip(t) -> void:
	var session := GameSession.new(100, 0, 1)
	var character := session.get_player_character()

	t.not_ok(
		session.equip_to_character(character, EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_1),
		"depoda yokken takılamaz"
	)

	session.add_equipment(EquipmentCatalog.WEAPON_TIER_1, 1)
	t.eq(session.get_equipment_count(EquipmentCatalog.WEAPON_TIER_1), 1, "satın alınan parça depoya düşer")

	t.ok(
		session.equip_to_character(character, EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_1),
		"depodaki parça takılabilir"
	)
	t.eq(session.get_equipment_count(EquipmentCatalog.WEAPON_TIER_1), 0, "takılan parça depodan düşer")
	t.eq(character.get_equipped_id(EquipmentCatalog.SLOT_WEAPON), EquipmentCatalog.WEAPON_TIER_1, "karakter parçayı taşır")

	# Yükseltme: yeni parça depoda, eskisi takılıyken.
	session.add_equipment(EquipmentCatalog.WEAPON_TIER_2, 1)
	t.ok(
		session.equip_to_character(character, EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_2),
		"yükseltme takılabilir"
	)
	t.eq(character.get_equipped_id(EquipmentCatalog.SLOT_WEAPON), EquipmentCatalog.WEAPON_TIER_2, "yeni parça takılı")
	t.eq(session.get_equipment_count(EquipmentCatalog.WEAPON_TIER_1), 1, "eski parça depoya geri döner")

	t.ok(session.unequip_from_character(character, EquipmentCatalog.SLOT_WEAPON), "çıkarma başarılı")
	t.eq(character.get_equipped(EquipmentCatalog.SLOT_WEAPON), null, "slot boşaldı")
	t.eq(session.get_equipment_count(EquipmentCatalog.WEAPON_TIER_2), 1, "çıkarılan parça depoya döner")
	t.not_ok(session.unequip_from_character(character, EquipmentCatalog.SLOT_WEAPON), "boş slot tekrar çıkarılamaz")
