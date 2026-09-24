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
	_test_effective_danger_and_goal(t)
	_test_change_provisions_reports_truth(t)
	_test_fixed_playthrough_start(t)
	_test_weight_limit_binds(t)
	_test_wagon_speed_factor(t)
	_test_party_condition_speed_factor(t)
	_test_merchant_dialogue(t)
	_test_merchant_cargo(t)
	_test_city_gold_reserve(t)
	_test_trait_price_multiplier(t)
	_test_guild_wagon_quest_rewards(t)

## change_provisions her iki yönde de gerçekten değişen miktarı dönmeli.
## Ekleme tarafı eskiden add_item'ın dönüşünü yok sayıyordu: envanter
## doluyken erzak eklenmiyor ama "eklendi" deniyordu, yani olay günlüğü
## "Erzak +N" yazarken kervan aç kalıyordu.
func _test_change_provisions_reports_truth(t) -> void:
	var session := GameSession.new(0, 10)
	t.eq(session.change_provisions(5), 5, "yer varken eklenen miktar aynen döner")
	t.eq(session.get_provisions(), 15, "erzak gerçekten arttı")

	t.eq(session.change_provisions(-4), -4, "düşülen miktar döner")
	t.eq(session.get_provisions(), 11, "erzak gerçekten azaldı")

	t.eq(session.change_provisions(-999), -11, "sıfırın altına inmez, düşen kadarını döner")
	t.eq(session.get_provisions(), 0, "erzak sıfırda durur")

	# Tek vagonun tek slotunu doldur: erzak girişi tükendiği için silinmiş
	# durumda, yeni bir slot açılamıyorsa ekleme başarısız olmalı ve bunu
	# söylemeli.
	var packed := GameSession.new(0, 0)
	packed.wagon_inventories = [Inventory.new(1)]
	var filler := ItemCatalog.get_item("test_grain")
	t.ok(packed.wagon_inventories[0].add_item(filler, 1), "tek slot dolduruldu")
	t.eq(packed.change_provisions(5), 0, "envanterde yer yoksa 0 döner, yalan söylemez")
	t.eq(packed.get_provisions(), 0, "gerçekten de erzak eklenmedi")

## Oyunun açılışı artık seçime bırakılmıyor: her yeni oyun iki kişi ve bir
## vagonla, rastgele bir şehirde başlıyor. Bir vagon tam iki kişilik yer
## açtığı için kadro baştan dolu olmalı - üçüncü kişi ancak vagon alınınca
## gelebilir.
func _test_fixed_playthrough_start(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	var session := GameSession.new(250, 20, 1)
	var hero := CharacterData.create("Oyuncu", CultureCatalog.NOMAD, CharacterStats.new())
	session.start_playthrough(hero, rng)

	t.eq(session.get_party().size(), GameSession.STARTING_PARTY_SIZE, "parti iki kişi başlar")
	t.eq(session.owned_wagon_count, GameSession.STARTING_WAGONS, "tek vagonla başlanır")
	t.eq(session.get_party_capacity(), 2, "bir vagon iki kişilik yer açar")
	t.not_ok(session.can_recruit(), "kadro baştan dolu, vagon almadan tayfa alınamaz")

	t.ok(session.get_player_character().is_player, "oyuncu bayrağı doğru kişide")
	var companion := session.get_party()[1]
	t.not_ok(companion.is_player, "yoldaş oyuncu değil")
	t.eq(companion.hire_cost, 0, "yoldaş işe alınmıyor, ücreti yok")
	t.ok(companion.is_alive(), "yoldaş tam canla başlar")
	t.ok(
		ClassCatalog.get_character_class(companion.class_id) != null,
		"yoldaşın sınıfı katalogda geçerli"
	)

	t.ok(
		WorldMapData.get_location_by_id(session.current_location_id) != null,
		"başlangıç şehri gerçek bir şehir"
	)

	# Aynı tohum aynı açılışı vermeli - hata ayıklanabilir olsun diye.
	var repeat_rng := RandomNumberGenerator.new()
	repeat_rng.seed = 12345
	var twin := GameSession.new(250, 20, 1)
	twin.start_playthrough(
		CharacterData.create("Oyuncu", CultureCatalog.NOMAD, CharacterStats.new()), repeat_rng
	)
	t.eq(twin.current_location_id, session.current_location_id, "aynı tohum aynı şehri verir")
	t.eq(
		twin.get_party()[1].character_name, companion.character_name,
		"aynı tohum aynı yoldaşı verir"
	)

	# Farklı tohumlar gerçekten farklı yoldaş üretmeli (aksi halde
	# "rastgele" iddiası boş olurdu).
	var names: Dictionary = {}
	for seed_value in range(20):
		var other_rng := RandomNumberGenerator.new()
		other_rng.seed = seed_value
		var other := GameSession.new(250, 20, 1)
		other.start_playthrough(
			CharacterData.create("Oyuncu", CultureCatalog.NOMAD, CharacterStats.new()), other_rng
		)
		names[other.get_party()[1].character_name] = true
	t.ok(names.size() > 1, "farklı tohumlar farklı yoldaşlar üretir")

## Slot sayısı tek kısıt değil: bir vagon çok *çeşit* değil çok *yük*
## taşıyamaz. Ağırlık eskiden yalnızca pazar ekranında kontrol ediliyordu,
## yani olay ödülü gibi başka yollardan gelen mal kapasiteyi deliyordu -
## kısıt artık Inventory.add_item'ın kendisinde, vagon başına.
func _test_weight_limit_binds(t) -> void:
	var session := GameSession.new(1000, 10, 1)
	var capacity := session.get_cargo_capacity()
	t.ok(capacity > 0.0, "tek vagonun bir kargo kapasitesi var")
	t.eq(session.wagon_inventories.size(), 1, "bir vagon, bir envanter")
	t.ok(
		is_equal_approx(session.wagon_inventories[0].weight_limit, capacity),
		"tek vagonun ağırlık tavanı toplam kargo kapasitesiyle aynı"
	)

	var heavy := ItemCatalog.get_item("test_weapon")
	var fits := session.wagon_inventories[0].get_addable_quantity(heavy)
	t.ok(fits > 0, "boş vagona en az bir ağır mal sığar")

	t.ok(session.add_to_cargo(heavy, fits), "sığdığı kadarı eklenebilir")
	t.not_ok(session.add_to_cargo(heavy, 1), "kapasite aşan ekleme reddedilir")

	# Kritik nokta: olay ödülü de aynı kapıdan geçmeli, yoksa kapasite
	# yalnızca pazarda geçerli bir öneri olurdu. Vagon doluyken bile
	# kişisel çantalara sığmıyor - küçük bir ağır silah çantaya girmez.
	var reward := EventEffectApplier.apply(
		[EventEffect.make(EventEffect.Type.ITEM_ADD, 5, "test_weapon")] as Array[EventEffect],
		session
	)
	t.eq(reward.lines.size(), 0, "yer yokken olay ödülü de eklenemez")

	# Erzak muaf: kendi sefer formülüyle sınırlı, kargo yerinden çalmamalı.
	t.eq(
		session.change_provisions(50), 50,
		"kargo dolu olsa da erzak alınabilir (ağırlıktan muaf)"
	)

	# Vagon almak yeni, boş bir vagon envanteri açar - kapasite büyür.
	session.wallet.earn(5000)
	t.ok(session.buy_wagon(), "vagon alınabilir")
	t.eq(session.wagon_inventories.size(), 2, "ikinci vagonun kendi envanteri var")
	t.ok(
		session.get_cargo_capacity() > capacity,
		"vagon alınca toplam kargo kapasitesi büyür"
	)
	t.ok(session.add_to_cargo(heavy, 1), "yeni vagon yer açar")

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

	# Yükseltme: yeni parça depoda, eskisi takılıyken. Ama tier 2 artık
	# seviye istiyor (bkz. Equipment.required_level) - önce reddedilmeli.
	session.add_equipment(EquipmentCatalog.WEAPON_TIER_2, 1)
	t.not_ok(
		session.equip_to_character(character, EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_2),
		"seviyesi yetmeyen karakter üst tier'i kuşanamaz"
	)
	t.eq(
		session.get_equipment_count(EquipmentCatalog.WEAPON_TIER_2), 1,
		"reddedilen parça depoda kalır, kaybolmaz"
	)

	character.level = EquipmentCatalog.TIER_2_LEVEL
	t.ok(
		session.equip_to_character(character, EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_2),
		"seviye yetince yükseltme takılabilir"
	)
	t.eq(character.get_equipped_id(EquipmentCatalog.SLOT_WEAPON), EquipmentCatalog.WEAPON_TIER_2, "yeni parça takılı")
	t.eq(session.get_equipment_count(EquipmentCatalog.WEAPON_TIER_1), 1, "eski parça depoya geri döner")

	t.ok(session.unequip_from_character(character, EquipmentCatalog.SLOT_WEAPON), "çıkarma başarılı")
	t.eq(character.get_equipped(EquipmentCatalog.SLOT_WEAPON), null, "slot boşaldı")
	t.eq(session.get_equipment_count(EquipmentCatalog.WEAPON_TIER_2), 1, "çıkarılan parça depoya döner")
	t.not_ok(session.unequip_from_character(character, EquipmentCatalog.SLOT_WEAPON), "boş slot tekrar çıkarılamaz")

## Yollar günler geçtikçe tehlikelenir (get_effective_danger). Buradaki
## "zenginlik hedefi" bölümü kaldırıldı: oyunun hedefi kesenin dolması
## değil (bkz. GameSession'ın soy bölümü), o yüzden yerini soyun
## sürekliliği aldı.
func _test_effective_danger_and_goal(t) -> void:
	var fresh := GameSession.new(100, 0, 1)
	t.almost(fresh.get_effective_danger(0.5), 0.5, "sıfırıncı günde ham tehlike değişmez")

	var seasoned := GameSession.new(100, 0, 1)
	seasoned.total_days_elapsed = 100
	t.ok(
		seasoned.get_effective_danger(0.5) > fresh.get_effective_danger(0.5),
		"gün ilerledikçe aynı rota daha tehlikeli olur"
	)
	t.le(seasoned.get_effective_danger(0.5), 1.0, "etkin tehlike 1.0'ı aşmaz")

	var maxed_out := GameSession.new(100, 0, 1)
	maxed_out.total_days_elapsed = 100000
	t.le(maxed_out.get_effective_danger(0.9), 1.0, "aşırı uzun oyunlarda bile tavan aşılmaz")

	# Kese ne kadar dolarsa dolsun oyunu bitiren bir eşik yok.
	var rich := GameSession.new(0, 0, 1)
	rich.wallet.earn(100000)
	t.not_ok(rich.is_run_over(), "zenginlik oyunu bitirmez")

## Bir vagon en yavaş tekerleğinden hızlı gidemez: kervanın "teorik hızı"
## vagonların en düşük yük faktörü. Bugün yalnızca bilgilendirici (bkz.
## GameSession.WAGON_LOAD_SPEED_PENALTY'nin yanındaki not) - yolun gerçek
## tempusuna henüz bağlı değil, o ayrı bir denge kararı.
func _test_wagon_speed_factor(t) -> void:
	var session := GameSession.new(1000, 0, 2)
	t.almost(
		session.get_wagon_speed_factor(0), 1.0, "boş bir vagon tam hızda"
	)
	t.almost(
		session.get_caravan_theoretical_speed(), 1.0, "iki vagon da boşken kervan tam hızda"
	)

	# Vagon aşırı yüklenemez (bkz. Inventory.add_item'ın kendi kapasite
	# kısıtı) - tavana yakın, sığan en fazla miktarı ekliyoruz.
	var cloth := ItemCatalog.get_item("test_cloth")
	var near_full := session.wagon_inventories[0].get_addable_quantity(cloth)
	t.ok(session.wagon_inventories[0].add_item(cloth, near_full), "tavana yakın miktar sığar")
	var loaded_factor := session.get_wagon_speed_factor(0)
	t.ok(loaded_factor < 1.0, "dolu bir vagon tam hızdan yavaş")
	t.ge(loaded_factor, GameSession.WAGON_MIN_SPEED_FACTOR, "hiçbir vagon taban hızın altına inmez")
	t.almost(
		session.get_wagon_speed_factor(1), 1.0, "ikinci vagon hâlâ boş, hâlâ tam hızda"
	)
	t.almost(
		session.get_caravan_theoretical_speed(), loaded_factor,
		"kervanın teorik hızı en yavaş (en yüklü) vagona eşit"
	)

## Vagon boş olsa da kırılmış ya da yaralı bir yolcu kervanı yavaşlatır -
## `DutyCatalog.get_condition_multiplier()`'ın aynı formülü, burada görev
## gücüne değil yürüyüş hızına uygulanmış (bkz. GameSession.
## get_party_condition_speed_factor). Teorik hız artık ikisinin en yavaşı.
func _test_party_condition_speed_factor(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	var calm := CharacterData.create("Dinç", CultureCatalog.NOMAD, CharacterStats.new())
	session.party.append(calm)
	t.almost(
		session.get_party_condition_speed_factor(), 1.0, "dinç ve sağlıklı bir parti tam hızda"
	)
	t.almost(
		session.get_caravan_theoretical_speed(), 1.0, "boş vagon + dinç parti tam hızda"
	)

	var weary := CharacterData.create("Yorgun", CultureCatalog.NOMAD, CharacterStats.new())
	weary.stress = CharacterData.MAX_STRESS
	session.party.append(weary)
	var weary_factor := DutyCatalog.get_condition_multiplier(weary)
	t.ok(weary_factor < 1.0, "kırılmış biri tam hızın altında")
	t.almost(
		session.get_party_condition_speed_factor(), weary_factor,
		"parti hızı en yorgun üyeye eşit"
	)
	t.almost(
		session.get_caravan_theoretical_speed(), weary_factor,
		"vagon boşken kervanın teorik hızı en yorgun üyeye eşit"
	)

	# Vagon yükü de devrede: ikisinin en yavaşı kazanmalı.
	var cloth := ItemCatalog.get_item("test_cloth")
	var near_full := session.wagon_inventories[0].get_addable_quantity(cloth)
	session.wagon_inventories[0].add_item(cloth, near_full)
	var wagon_factor := session.get_wagon_speed_factor(0)
	t.almost(
		session.get_caravan_theoretical_speed(), minf(wagon_factor, weary_factor),
		"kervanın teorik hızı vagon ve parti faktörlerinin en düşüğü"
	)

## Yabancı tüccarın vagonuna diyalog yoluyla bakış (bkz. CLAUDE.md Ana
## Hedefler'in "#11" notu): izin/zorla bak/tekrar ikna et/vazgeç.
func _test_merchant_dialogue(t) -> void:
	var destination := WorldMapData.get_locations()[0]
	var plan := CaravanPlan.new(destination, 5)
	var offer := MerchantOffer.new()
	offer.merchant_name = "Test Tüccarı"
	offer.wagon_count = 1
	offer.potential_profit = 10
	t.ok(plan.toggle_merchant(offer), "eskort teklifi eklenebiliyor")

	var session := GameSession.new(1000, 0, 1)
	session.caravan = CaravanState.from_plan(plan)

	# from_plan her tüccar için geçerli, tekrarlanabilir bir mizaç atıyor.
	var disposition := String(session.caravan.merchant_disposition_by_name.get(offer.merchant_name, ""))
	t.ok(NpcDisposition.ALL.has(disposition), "atanan mizaç katalogda tanımlı")
	var repeat_state := CaravanState.from_plan(plan)
	t.eq(
		String(repeat_state.merchant_disposition_by_name.get(offer.merchant_name, "")), disposition,
		"aynı isim aynı mizacı verir - kalıcı bir kimlik, sefer başına yeniden zar değil"
	)

	t.not_ok(session.is_merchant_known(offer.merchant_name), "bakılmadan önce mizaç bilinmiyor")
	t.eq(
		session.get_merchant_disposition_label(offer.merchant_name), "",
		"bilinmeyen bir mizaç hiç gösterilmez"
	)

	# İzin mizaca göre: LOYAL/DESPERATE her zaman izin verir, THIEF/VENGEFUL vermez.
	session.caravan.merchant_disposition_by_name[offer.merchant_name] = NpcDisposition.LOYAL
	t.ok(session.merchant_grants_permission(offer.merchant_name), "LOYAL izin verir")
	session.caravan.merchant_disposition_by_name[offer.merchant_name] = NpcDisposition.DESPERATE
	t.ok(session.merchant_grants_permission(offer.merchant_name), "DESPERATE izin verir")
	session.caravan.merchant_disposition_by_name[offer.merchant_name] = NpcDisposition.THIEF
	t.not_ok(session.merchant_grants_permission(offer.merchant_name), "THIEF izin vermez")
	session.caravan.merchant_disposition_by_name[offer.merchant_name] = NpcDisposition.VENGEFUL
	t.not_ok(session.merchant_grants_permission(offer.merchant_name), "VENGEFUL izin vermez")

	# Zorla bakmak izin gerektirmiyor ama itibar bedeli var.
	var reputation_before := session.reputation
	session.force_look_merchant_wagon(offer.merchant_name)
	t.ok(session.is_merchant_known(offer.merchant_name), "zorla bakış mizacı öğretir")
	t.eq(
		session.reputation, reputation_before - GameSession.FORCE_LOOK_MERCHANT_REPUTATION_PENALTY,
		"zorla bakmak itibara mal olur"
	)

	# Sezgi eşiğinin altında mizaç hâlâ bilinse de gösterilmez (bkz.
	# Event Character Rules'un "oyuncuya söylenmez, yalnızca ipucu" kuralı).
	t.eq(
		session.get_merchant_disposition_label(offer.merchant_name), "",
		"düşük Sezgiyle bilinen bir mizaç bile gösterilmez"
	)

	# Tekrar ikna etme - get_effective_manipulation'a göre bir şans; çok
	# tekrarda hem başarı hem başarısızlık görülmeli (aşırı marj deseni,
	# bkz. test_traits.gd'nin roll_seed_trait sınaması).
	var persuade_rng := RandomNumberGenerator.new()
	persuade_rng.seed = 77
	var successes := 0
	var attempts := 400
	for _i in attempts:
		if session.attempt_merchant_persuasion(persuade_rng):
			successes += 1
	var rate := float(successes) / float(attempts)
	t.ge(rate, GameSession.MERCHANT_PERSUASION_MIN_CHANCE - 0.05, "ikna şansı taban altına inmez")
	t.le(rate, GameSession.MERCHANT_PERSUASION_MAX_CHANCE + 0.05, "ikna şansı tavanı aşmaz")
	t.ok(successes > 0 and successes < attempts, "ikna hem başarabilir hem başarısız olabilir")

## Yabancı tüccarın vagonuna bakış artık gerçek bir kargo listesi de
## açıyor (bkz. CaravanState.merchant_cargo_by_name,
## GameSession.get_merchant_cargo_entries) - #22'nin orijinal notunun
## istediği "gerçek envanter", mizaç etiketinin ötesinde. İzin/mizaç
## kapısıyla aynı kapıdan geçer, aynı gün aynı tüccar için tekrarlanabilir,
## farklı bir günde (farklı bir sefer) değişebilir - erzak hiçbir zaman
## bu listede yer almaz.
func _test_merchant_cargo(t) -> void:
	var destination := WorldMapData.get_locations()[0]
	var plan := CaravanPlan.new(destination, 5)
	var offer := MerchantOffer.new()
	offer.merchant_name = "Kargo Testi Tüccarı"
	offer.wagon_count = 2
	offer.potential_profit = 10
	t.ok(plan.toggle_merchant(offer), "eskort teklifi eklenebiliyor")

	var session := GameSession.new(1000, 0, 1)
	session.caravan = CaravanState.from_plan(plan, CaravanState.MAX_MORALE, 12)

	t.eq(
		session.get_merchant_cargo_entries(offer.merchant_name), [],
		"bakılmadan önce kargo listesi boş döner"
	)

	session.force_look_merchant_wagon(offer.merchant_name)
	var entries := session.get_merchant_cargo_entries(offer.merchant_name)
	t.ok(entries.size() > 0, "bakınca en az bir mal türü görünür")
	t.le(entries.size(), CaravanState.MERCHANT_CARGO_ITEM_TYPES, "en fazla tanımlı tür sayısı kadar mal var")
	for entry in entries:
		var item: Item = entry.item
		t.ne(item.item_id, GameSession.PROVISIONS_ITEM_ID, "erzak yabancı tüccarın kargosunda hiç yer almaz")
		t.ok(int(entry.quantity) > 0, "her kalemin miktarı pozitif")

	# Aynı sefer (aynı tohum günü) içinde tekrar sorulunca aynı liste
	# gelir - panel her açıldığında farklı bir yük görmemeli.
	var repeat_state := CaravanState.from_plan(plan, CaravanState.MAX_MORALE, 12)
	var repeat_cargo: Inventory = repeat_state.merchant_cargo_by_name[offer.merchant_name]
	var repeat_entries := repeat_cargo.get_all_entries()
	t.eq(repeat_entries.size(), entries.size(), "aynı gün aynı sayıda mal türü verir")
	for i in entries.size():
		var original: Dictionary = entries[i]
		var repeated: Dictionary = repeat_entries[i]
		var original_item: Item = original.item
		var repeated_item: Item = repeated.item
		t.eq(repeated_item.item_id, original_item.item_id, "aynı gün aynı sırayla aynı malı verir")
		t.eq(int(repeated.quantity), int(original.quantity), "aynı gün aynı miktarı verir")

	# Erzak hariç her ticaret malı havuzda - hiçbiri hiçbir zaman erzak
	# döndürmemeli, kaç kez denenirse denensin (aşırı marj deseni).
	for seed_day in range(30):
		var seeded_state := CaravanState.from_plan(plan, CaravanState.MAX_MORALE, seed_day)
		var cargo: Inventory = seeded_state.merchant_cargo_by_name[offer.merchant_name]
		t.eq(cargo.get_quantity(GameSession.PROVISIONS_ITEM_ID), 0, "erzak hiçbir tohumda kargoya girmez")

## Faz 17 PR-5: şehrin kendi hazinesi. consume_stock alımı şehre para
## akıtır, record_sale şehrin hazinesinden çeker; can_city_afford_sale
## satış öncesi UI'ın soracağı soru. Buradaki testler yalnızca GameSession
## kapısını sınıyor - MarketConditions'ın kendi kenetleme/toparlanma
## mekaniği test_market_conditions.gd'de.
func _test_city_gold_reserve(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	var starting := session.get_city_gold_reserve()
	t.ok(starting > 0, "şehrin başlangıç hazinesi var")

	session.consume_stock("test_grain", 5, 100)
	t.ok(session.get_city_gold_reserve() > starting, "alım şehri zenginleştirir")

	var after_buy := session.get_city_gold_reserve()
	t.ok(session.can_city_afford_sale(after_buy), "hazine kendi büyüklüğünü karşılayabilir")
	t.not_ok(session.can_city_afford_sale(after_buy + 100000), "hazine sınırsız değil")

	session.record_sale("test_grain", 5, after_buy)
	t.eq(session.get_city_gold_reserve(), 0, "satış hazineyi tam kadar boşaltır")
	t.ok(session.get_city_gold_reserve() >= 0, "hazine asla eksiye düşmez")

	# total_price verilmezse (varsayılan 0) hazineye hiç dokunulmaz - arz-talep
	# baskısı gibi diğer davranışlar total_price'sız çağrılara duyarsız kalmalı.
	var untouched := GameSession.new(1000, 0, 1)
	var untouched_start := untouched.get_city_gold_reserve()
	untouched.consume_stock("test_grain", 5)
	t.eq(untouched.get_city_gold_reserve(), untouched_start, "total_price'sız alım hazineyi değiştirmez")

## Faz 17 PR-3'ün tamamlanan üçüncü kancası: Basiretli/Saf artık pazarda
## da hissediliyor - kültür perkinin tek çarpan olduğu tek kapı
## (get_buy_price_multiplier) şimdi bir de partinin İnanç... hayır, Zeka
## huylarını okuyor. Taban (huysuz kervan) tam kültür değerinde kalmalı.
func _test_trait_price_multiplier(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	var base_multiplier := session.get_buy_price_multiplier()
	t.almost(
		session.get_trait_price_multiplier(), 1.0,
		"huysuz kervanda pazarlık çarpanı tam 1.0"
	)

	var shrewd := CharacterData.create("Basiretli Tellal", CultureCatalog.VALLEY, CharacterStats.new())
	shrewd.grant_trait(TraitCatalog.PRUDENT, 0)
	session.party.append(shrewd)
	t.ok(
		session.get_buy_price_multiplier() < base_multiplier,
		"Basiretli bir yoldaş alım fiyatını düşürür"
	)

	var gullible_session := GameSession.new(1000, 0, 1)
	var gullible_base := gullible_session.get_buy_price_multiplier()
	var gullible := CharacterData.create("Saf Tellal", CultureCatalog.VALLEY, CharacterStats.new())
	gullible.grant_trait(TraitCatalog.NAIVE, 0)
	gullible_session.party.append(gullible)
	t.ok(
		gullible_session.get_buy_price_multiplier() > gullible_base,
		"Saf bir yoldaş alım fiyatını artırır"
	)

	# Bir sistemi hiçbir huy tek başına kapatamaz - tavan/taban var.
	t.ge(
		session.get_trait_price_multiplier(), GameSession.MIN_TRAIT_PRICE_MULTIPLIER,
		"pazarlık çarpanı tabanın altına inmez"
	)

## Faz 17 PR-4: loncanın iki özel vagon görevi - sıradan kontrat
## akışını (accept_contract → CaravanPlan.toggle_merchant → start_journey
## → depart_with_contracts → finish_journey) aynen kullanır, yalnızca
## teslimatta altın yerine ayni ödül verir. İki aile, iki farklı iddia:
## vagon bağışları teslim edince ödül gelir ve bir daha asla gelmez;
## kargo görevleri de ödül verir ama sıradan bir kontrat gibi tekrar tekrar
## teslim edilebilir (bkz. WorldMapData'nın kendi notu). Yolda kaybedilirse
## (her iki aile için de) hiçbir ödül gelmez.
func _test_guild_wagon_quest_rewards(t) -> void:
	var grant: MerchantOffer = WorldMapData.get_offer_by_merchant_id(WorldMapData.GUILD_WAGON_GRANT_QUEST_ID)
	var grant2: MerchantOffer = WorldMapData.get_offer_by_merchant_id(WorldMapData.GUILD_WAGON_GRANT_2_QUEST_ID)
	var freight: MerchantOffer = WorldMapData.get_offer_by_merchant_id(WorldMapData.GUILD_WAGON_FREIGHT_QUEST_ID)
	t.ne(grant, null, "vagon bağışı görevi bulundu")
	t.ne(grant2, null, "ikinci vagon bağışı görevi bulundu")
	t.ne(freight, null, "fazla yük sevkiyatı görevi bulundu")

	# _deliver_wagon_quest bir vagonla (GameSession.new(..., 1)) başlıyor -
	# teslimat kalıcı ikinci bir vagon eklemeli.
	var session := _deliver_wagon_quest(grant, 50)
	t.eq(session.owned_wagon_count, 2, "vagon bağışı teslim edilince kalıcı bir vagon kazandırır")
	t.ok(session.is_guild_wagon_quest_delivered(grant.merchant_id), "görev teslim edildi diye işaretlenir")

	# İkinci vagon bağışı da aynı şekilde çalışır - havuzun tek bir göreve
	# sıkışmadığını doğrular.
	var session2 := _deliver_wagon_quest(grant2, 40)
	t.eq(session2.owned_wagon_count, 2, "ikinci vagon bağışı da kalıcı bir vagon kazandırır")
	t.ok(session2.is_guild_wagon_quest_delivered(grant2.merchant_id), "ikinci görev de teslim edildi diye işaretlenir")

	# Kayıt round-trip: teslim edilmiş bir vagon bağışı bir daha hiç açılmaz.
	var reloaded := GameSession.new()
	reloaded.load_from_dict(session.to_save_dict())
	t.ok(
		reloaded.is_guild_wagon_quest_delivered(grant.merchant_id),
		"teslim edilmiş vagon bağışı kayıttan sonra da kilitli kalır"
	)

	# Aynı vagon bağışı bir daha teslim edilse bile (guild.gd panodan zaten
	# düşürür, ama fonksiyonun kendisi de sömürüye kapalı olmalı) ikinci
	# bir ödül vermemeli - fulfill_commission'ın Faz 17 PR-8'de kapattığı
	# sömürüyle aynı sınıf.
	var wagons_after_first := session.owned_wagon_count
	session.current_location_id = grant.origin_location_id
	session.accept_contract(grant)
	var repeat_plan := CaravanPlan.new(
		WorldMapData.get_location_by_id(grant.destination_location_id),
		grant.contract_deadline_days, CaravanPlan.DEFAULT_MAX_WAGONS, session.owned_wagon_count
	)
	repeat_plan.toggle_merchant(grant)
	session.start_journey(grant.destination_location_id, 8, 0.65, repeat_plan)
	session.depart_with_contracts([grant])
	session.finish_journey()
	t.eq(session.owned_wagon_count, wagons_after_first, "aynı vagon bağışı ikinci kez ödül vermez")

	# Fazla Yük Sevkiyatı: teslim edilince ödül malı kervana (ya da
	# çantaya) geçer, ve bir kargo görevi hiçbir zaman kalıcı olarak
	# kilitlenmez (vagon bağışlarının aksine).
	var freight_session := _deliver_wagon_quest(freight, 30)
	t.eq(
		freight_session.get_total_quantity(freight.cargo_reward_item_id), freight.cargo_reward_quantity,
		"fazla yük sevkiyatı teslim edilince ödül malı kervana geçer"
	)
	t.not_ok(
		freight_session.is_guild_wagon_quest_delivered(freight.merchant_id),
		"bir kargo görevi hiçbir zaman kalıcı olarak kilitlenmez"
	)

	# Kargo görevleri sıradan bir kontrat gibi tekrar tekrar teslim
	# edilebilir - aynı oturumda aynı görevi ikinci kez kabul edip teslim
	# etmek ödülü ikinci kez de vermeli.
	freight_session.current_location_id = freight.origin_location_id
	freight_session.accept_contract(freight)
	var repeat_freight_plan := CaravanPlan.new(
		WorldMapData.get_location_by_id(freight.destination_location_id),
		freight.contract_deadline_days, CaravanPlan.DEFAULT_MAX_WAGONS, freight_session.owned_wagon_count
	)
	repeat_freight_plan.toggle_merchant(freight)
	freight_session.start_journey(freight.destination_location_id, 3, 0.25, repeat_freight_plan)
	freight_session.depart_with_contracts([freight])
	freight_session.finish_journey()
	t.eq(
		freight_session.get_total_quantity(freight.cargo_reward_item_id), freight.cargo_reward_quantity * 2,
		"aynı kargo görevi ikinci kez teslim edilince ödül tekrar gelir"
	)

	# Yolda kaybedilirse (merchant_names'ten düşerse) hiçbir ödül gelmez -
	# sıradan bir kontrat gibi yalnızca itibar cezası alır.
	var lost_session := GameSession.new(500, 60, 1)
	lost_session.reputation = 50
	lost_session.current_location_id = grant.origin_location_id
	lost_session.accept_contract(grant)
	var lost_plan := CaravanPlan.new(
		WorldMapData.get_location_by_id(grant.destination_location_id),
		grant.contract_deadline_days, CaravanPlan.DEFAULT_MAX_WAGONS, lost_session.owned_wagon_count
	)
	lost_plan.toggle_merchant(grant)
	lost_session.start_journey(grant.destination_location_id, 8, 0.65, lost_plan)
	lost_session.depart_with_contracts([grant])
	lost_session.caravan.merchant_names.erase(grant.merchant_name)
	var wagons_before_loss := lost_session.owned_wagon_count
	lost_session.finish_journey()
	t.eq(lost_session.owned_wagon_count, wagons_before_loss, "yolda kaybedilen görev ödül vermez")
	t.not_ok(
		lost_session.is_guild_wagon_quest_delivered(grant.merchant_id),
		"kaybedilen görev teslim edilmiş sayılmaz"
	)

## Bir loncanın vagon görevini gerçek akıştan (kabul → planla → yola çık →
## teslim et) geçirip varan oturumu döner.
func _deliver_wagon_quest(offer: MerchantOffer, reputation: int) -> GameSession:
	var session := GameSession.new(500, 60, 1)
	session.reputation = reputation
	session.current_location_id = offer.origin_location_id
	session.accept_contract(offer)
	var plan := CaravanPlan.new(
		WorldMapData.get_location_by_id(offer.destination_location_id),
		offer.contract_deadline_days, CaravanPlan.DEFAULT_MAX_WAGONS, session.owned_wagon_count
	)
	plan.toggle_merchant(offer)
	session.start_journey(offer.destination_location_id, 8, 0.5, plan)
	session.depart_with_contracts([offer])
	session.finish_journey()
	return session
