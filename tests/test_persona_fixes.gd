extends RefCounted

## Oyuncu profili çalışmasının (bölüm 18) yedi önerisinin kilitleri.
## Her test bir ölçüme dayanıyor; gerekçeler
## `docs/design_notes/oyuncu_profilleri.md`.

func suite_name() -> String:
	return "Persona Fixes"

func run(t) -> void:
	_test_meal_modes_cost_different_amounts(t)
	_test_day_labour_pays_time_not_money(t)
	_test_day_labour_is_only_for_the_hungry(t)
	_test_seen_cards_are_counted(t)
	_test_last_decisions_are_remembered(t)
	_test_standing_milestone_is_written_once(t)
	_test_foraging_is_the_hungry_road_answer(t)
	_test_lineage_carries_knowledge_not_power(t)
	_test_delay_lengthens_the_road_not_the_progress(t)
	_test_more_hands_find_more_food(t)
	_test_closed_doors_say_why(t)
	_test_delivery_says_how_many_are_missing(t)
	_test_a_hungry_crew_breaks_up(t)
	_test_an_idle_wagon_cannot_be_loaded(t)
	_test_hands_are_hired_back_in_the_city_for_gold(t)
	_test_a_downed_fighter_never_gets_up_for_free(t)
	_test_a_lost_fight_costs_cargo(t)
	_test_a_longer_column_is_slower_and_louder(t)

func _session_in_city(gold: int = 250) -> GameSession:
	var session := GameSession.new(gold, 20, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	return session

# --- Ö2: sofra kipinin bedeli görünür ---

func _test_meal_modes_cost_different_amounts(t) -> void:
	# Ablasyonun en sert bulgusu: tayfayı beslemek dayanıklılığı üç
	# seferden on bire değiştiriyor. Bu ağırlıkta bir kararın bedeli
	# ekranda yazılı olmalı - ve aritmetiği dağıtımla aynı yerden gelmeli.
	var session := _session_in_city()
	var all_mode := session.daily_provisions_for_mode(GameSession.MEAL_MODE_ALL)
	var party := session.daily_provisions_for_mode(GameSession.MEAL_MODE_PARTY_ONLY)
	var crew := session.daily_provisions_for_mode(GameSession.MEAL_MODE_CREW_ONLY)
	t.eq(all_mode, session.get_daily_provision_consumption(), "herkes kipi günlük tüketimin tamamı")
	t.eq(party + crew, all_mode, "parti ve tayfa payları tamamı eder")
	t.ok(party < all_mode, "yalnız partiyi beslemek daha ucuz")
	t.ge(float(session.daily_provisions_for_mode(GameSession.MEAL_MODE_SELF_ONLY)), 0.0,
		"lider kipi de bir sayı döndürür")

# --- Ö3: gündelik iş ---

func _test_day_labour_pays_time_not_money(t) -> void:
	var session := _session_in_city()
	session.change_provisions(-session.get_provisions())
	var purse := session.wallet.balance
	var day := session.total_days_elapsed
	t.ok(session.can_work_a_day(), "aç kervan bir gün çalışabilir")
	var earned := session.work_a_day()
	t.ok(earned > 0, "çalışmak erzak kazandırır")
	t.eq(session.wallet.balance, purse, "ama tek kuruş para vermez")
	t.eq(session.total_days_elapsed, day + 1, "bir gün geçer: ödenen zamandır")
	# Zenginleşmeye yol yok: kazanç bir günlük tüketimin biraz üstü.
	t.le(
		float(earned),
		float(session.get_daily_provision_consumption()) * GameSession.DAY_LABOUR_PROVISION_FACTOR + 1.0,
		"kazanç bir günlük ekmeğin biraz üstünde kalır"
	)

func _test_day_labour_is_only_for_the_hungry(t) -> void:
	# İhtiyacı **sefer** belirler, bugünkü depo değil: 20 erzakla duran bir
	# kervan 111 erzaklık yola bakarken düğme gizleniyordu - tam gerektiği
	# anda. Ekran görüntüsü yakaladı.
	var fed := _session_in_city()
	fed.change_provisions(fed.get_daily_provision_consumption() * 5)
	t.not_ok(fed.should_offer_day_labour(0), "eksiği olmayan kervana sunulmaz")
	t.ok(fed.should_offer_day_labour(40), "ama uzun yolda eksiği varsa sunulur")
	var on_road := _session_in_city()
	on_road.change_provisions(-on_road.get_provisions())
	var plan := CaravanPlan.new(WorldMapData.get_locations()[0], 5, 6, 1)
	on_road.start_journey(WorldMapData.get_locations()[0].location_id, 5, 0.1, plan)
	t.not_ok(on_road.can_work_a_day(), "yolda gündelik iş yok")
	t.not_ok(on_road.should_offer_day_labour(40), "yolda eksik de olsa sunulmaz")
	t.eq(on_road.get_day_labour_block_reason(), "UI_LABOUR_ON_ROAD", "sebebi söylenir")

# --- Ö4, Ö5: sayılabilirlik ve ölümün nedeni ---

func _test_seen_cards_are_counted(t) -> void:
	var session := _session_in_city()
	t.eq(session.get_seen_event_count(), 0, "yeni kervan hiç kart görmemiştir")
	session.note_event_seen("evt_a")
	session.note_event_seen("evt_b")
	session.note_event_seen("evt_a")
	t.eq(session.get_seen_event_count(), 2, "aynı kart iki kez sayılmaz")
	session.note_event_seen("")
	t.eq(session.get_seen_event_count(), 2, "boş kimlik sayılmaz")
	# Kayıttan döner: sayaç soy boyunca birikiyor.
	var restored := GameSession.new(0, 0, 1)
	restored.load_from_dict(session.to_save_dict())
	t.eq(restored.get_seen_event_count(), 2, "sayaç kayıttan döner")

func _test_last_decisions_are_remembered(t) -> void:
	var session := _session_in_city()
	for index in 5:
		session.note_decision("evt_%d" % index, "CHOICE_%d" % index)
	t.eq(
		session.recent_decisions.size(), GameSession.RECENT_DECISION_COUNT,
		"yalnız son üç karar tutulur"
	)
	t.eq(
		String((session.recent_decisions[2] as Dictionary).get("choice", "")), "CHOICE_4",
		"en yenisi sonda"
	)
	var restored := GameSession.new(0, 0, 1)
	restored.load_from_dict(session.to_save_dict())
	t.eq(restored.recent_decisions.size(), GameSession.RECENT_DECISION_COUNT,
		"son kararlar kayıttan döner")

# --- Ö7: ad ile ödül ---

func _test_standing_milestone_is_written_once(t) -> void:
	# Tüccar profili emeğinin karşılığını göremiyordu: kese yatay
	# (P8'in kasıtlı sonucu). Verilen şey para değil tanınma.
	var session := _session_in_city()
	var before := _milestone_lines(session)
	session.change_reputation(GameSession.STANDING_MILESTONES[0] + 2)
	var after := _milestone_lines(session)
	t.ok(after > before, "eşik geçilince deftere satır düşer")
	# Bir daha düşmez: aynı eşik her itibar hareketinde tekrar yazılmaz.
	session.change_reputation(1)
	t.eq(_milestone_lines(session), after, "aynı eşik ikinci kez yazılmaz")
	# Kese bu işte hiç değişmiyor - kâr tavanı korunuyor.
	var purse := session.wallet.balance
	session.change_reputation(GameSession.STANDING_MILESTONES[1])
	t.eq(session.wallet.balance, purse, "tanınma para getirmez")
	t.ok(_milestone_lines(session) > after, "sonraki eşik de yazılır")

func _milestone_lines(session: GameSession) -> int:
	var count := 0
	for entry in session.ledger.entries:
		if String(entry.get("cause", "")) == "LEDGER_CAUSE_STANDING_MILESTONE":
			count += 1
	return count

# --- Profil turu 2: yolda çaba, soyda bilgi ---

func _test_foraging_is_the_hungry_road_answer(t) -> void:
	# **Bulunan kusur:** yolda erzak biterse oyuncunun yapabileceği hiçbir
	# şey yoktu - yiyecek yalnız kart çekişinden geliyordu, yani açlıktan
	# ölmek bir karar değil bir şanssızlıktı. Kullanıcının istediği şey
	# açıktı: mücadele ederek devam edebilmek bir deneyim olmalı.
	var session := _session_in_city()
	t.ne(session.get_forage_block_reason(), "", "şehirde aranmaz")
	var plan := CaravanPlan.new(WorldMapData.get_locations()[0], 8, 6, 1)
	session.start_journey(WorldMapData.get_locations()[0].location_id, 8, 0.1, plan)
	t.eq(session.get_forage_block_reason(), "", "yolda aranır")

	var before := session.get_provisions()
	var days_before := session.journey_days_remaining
	var found := session.forage_a_day("forest")
	t.ok(found > 0, "arama bir şey bulur")
	t.eq(session.get_provisions(), before + found, "bulunan erzak kargoya girer")
	t.eq(session.journey_days_remaining, days_before + 1, "bedeli zaman: yol bir gün uzar")

	# Biyom ve mevsim farkı: her yer aynı vermez, yoksa bu bir düğme olur.
	t.ok(
		session.get_forage_yield("forest") > session.get_forage_yield("desert"),
		"orman çölden çok verir"
	)
	# Ve bolluk yolu değil: bir günün aramasıyla kervan doymaz.
	t.le(
		float(session.get_forage_yield("forest")),
		float(session.get_daily_provision_consumption()) * 6.0,
		"arama bolluk getirmez, ölmemeye yeter"
	)

func _test_lineage_carries_knowledge_not_power(t) -> void:
	# *"Sonuçtan değil süreçten keyif"*: yeni kervan daha güçlü değil daha
	# **bilgili** başlar. Kıtlık aynı sertlikte kalır.
	var old := _session_in_city()
	old.note_event_seen("evt_a")
	old.note_event_seen("evt_b")
	var place := WorldMapData.get_locations()[0].location_id
	old.record_seen_prices(place)
	var record := LineageArchive.build_record(old)
	t.eq((record.get("seen_events", []) as Array).size(), 2, "görülen kartlar arşive yazılır")
	t.ok((record.get("price_book", {}) as Dictionary).has(place), "fiyat defteri de")

	var fresh := GameSession.new(250, 20, 1)
	LineageArchive.apply_to(fresh, record)
	t.eq(fresh.get_seen_event_count(), 2, "yeni soy gördüklerini hatırlar")
	t.ok(fresh.price_book.has(place), "ve nereye bakacağını bilir")
	# Ama bilgi **eskimiş** geliyor: ne bulacağını bilmez.
	t.ok(fresh.is_price_stale(place), "devralınan fiyat eskimiş sayılır")
	t.eq(
		String((fresh.price_book[place] as Dictionary).get("source", "")),
		GameSession.PRICE_SOURCE_RUMOR,
		"görgü değil, kulaktan dolma olarak devralınır"
	)

# --- Oyun günlüğü turunun bulduğu kusurlar (2026-11-05) ---

func _test_delay_lengthens_the_road_not_the_progress(t) -> void:
	# **Bulunan kusur:** gecikme kartı yalnız `journey_days_remaining`'i
	# artırıyordu, `journey_total_days` yerinde kalıyordu. Kat edilen yol
	# `total - remaining` olduğu için negatife düşüp sıfıra kırpılıyordu:
	# on gün yürüyen kervan bir gecikme kartı çekince yol ekranında
	# **başlangıca** dönmüş görünüyordu. Günlükte 4 günlük bir yolun 40
	# güne çıktığı ve ilerlemenin hiç görünmediği koşu bunu açığa çıkardı.
	var session := _session_in_city()
	var place := WorldMapData.get_locations()[0]
	session.start_journey(place.location_id, 6, 0.1, CaravanPlan.new(place, 6, 6, 1))
	session.journey_days_remaining -= 4
	t.eq(session.get_days_travelled(), 4, "dört gün yürüdü")

	EventEffectApplier.apply([EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 5)], session)
	t.eq(session.get_days_travelled(), 4, "gecikme yürüneni silmez")
	t.eq(session.journey_days_remaining, 7, "kalan gün uzar")
	t.eq(session.journey_total_days, 11, "ve yolun kendisi uzar")

	# Kestirme de aynı muhasebeyi tutar: yol kısalır, geçmiş geri alınmaz.
	EventEffectApplier.apply([EventEffect.make(EventEffect.Type.TRAVEL_DAYS, -3)], session)
	t.eq(session.get_days_travelled(), 4, "kısalma da yürüneni silmez")
	t.eq(session.journey_total_days, 8, "yol kısaldı")

func _test_more_hands_find_more_food(t) -> void:
	# **Bulunan kusur:** verim yalnızca en iyi sezgiye bakıyordu, yani altı
	# kişilik kervan bir kişilik kadar buluyordu. Bir arama günü bir yol
	# günü yiyor; getirisi o günün erzağını aşmazsa aramak durumu
	# kötüleştiriyordu - "arama" yalnız zaten kurtulacak olanı kurtarıyordu.
	var lone := _session_in_city()
	var crowd := _session_in_city()
	# Vagon başına iki kişi yatar: parti yeri vagonla açılır.
	crowd.owned_wagon_count = 2
	for index in 3:
		var extra := CharacterData.create(
			"Yoldaş %d" % index, CultureCatalog.NOMAD, CharacterStats.new()
		)
		if not crowd.recruit(extra):
			break
	t.ok(crowd.get_party().size() > lone.get_party().size(), "kalabalık kervan kuruldu")
	t.ok(
		crowd.get_forage_yield("forest", 100) > lone.get_forage_yield("forest", 100),
		"çok el çok bulur"
	)

func _test_closed_doors_say_why(t) -> void:
	# Oyunun kendi kuralı: kapalı düğme sebebini söyler. Günlükler üç
	# kapının bunu tutmadığını buldu - taverna konaklaması, şölen ve kilise
	# bağışı sebep söylemeden soluklaşıyordu.
	var broke := _session_in_city(0)
	t.eq(broke.get_lodging_block_reason(), "UI_NOT_ENOUGH_GOLD", "oda: kese yetmiyor")
	t.eq(broke.get_church_donation_block_reason(), "UI_NOT_ENOUGH_GOLD", "bağış: kese yetmiyor")
	t.eq(broke.get_feast_block_reason(), "UI_TAVERN_FEAST_NO_STRESS",
		"şölen: kimse yorgun değilken gerek yok")

	var tired := _session_in_city(0)
	tired.change_stress(30)
	t.eq(tired.get_feast_block_reason(), "UI_NOT_ENOUGH_GOLD",
		"yorgun ama parasız: sebep para olur")

	var place := WorldMapData.get_locations()[0]
	var travelling := _session_in_city()
	travelling.start_journey(place.location_id, 4, 0.1, CaravanPlan.new(place, 4, 6, 1))
	t.eq(travelling.get_lodging_block_reason(), "UI_TAVERN_LODGE_ON_ROAD", "yolda oda yok")
	t.eq(travelling.get_church_donation_block_reason(), "UI_CHURCH_DONATE_ON_ROAD",
		"yolda kutu yok")
	t.not_ok(travelling.can_afford_lodging(), "eski kapı da aynı cevabı verir")
	t.not_ok(travelling.can_donate_to_church(), "ve bağış kapalı kalır")

func _test_delivery_says_how_many_are_missing(t) -> void:
	# Günlüklerin en çok çarpılan ikinci kapısı: kişinin istediği ekranda
	# yazıyordu ama "Teslim et" sebep söylemeden ölüyordu.
	var session := _session_in_city()
	session.people.ensure_city(session.current_location_id, 0)
	var city := session.people.city_people(session.current_location_id)
	t.ok(not city.is_empty(), "şehirde adı olan biri var")
	var id := String((city[0] as Dictionary).get("id", ""))
	var chain := session.people.offer_chain(id, 0)
	t.ok(not chain.is_empty(), "bir iş teklif edildi")

	t.eq(session.get_chain_block_reason(id), "UI_PEOPLE_CHAIN_MISSING", "elde yokken kapalı")
	t.ne(session.get_chain_missing_text(id), "", "kaç tane eksik olduğu yazılır")
	t.not_ok(session.can_deliver_chain(id), "eski kapı da aynı cevabı verir")

	var item := ItemCatalog.get_item(String(chain["item"]))
	session.add_to_cargo_or_bag(item, int(chain["qty"]))
	t.eq(session.get_chain_block_reason(id), "", "mal gelince açılır")
	t.eq(session.get_chain_missing_text(id), "", "eksik kalmaz")
	t.ok(session.deliver_chain(id), "ve teslim edilir")

# --- G2: aç ekip dağılır (kullanıcı kararı 2026-11-06) ---

func _test_a_hungry_crew_breaks_up(t) -> void:
	# **Bulunan delik:** tayfa açlıktan ölüyordu ama `_sync_crew_names()`
	# yerini anında ve bedavaya dolduruyordu; tüketim ve kapasite vagondan
	# hesaplandığı için aç bırakmanın hiçbir mekanik bedeli yoktu. Günlükler
	# dört kervanın ekibini 60-98 gün aç bırakıp sıfır kayıpla yirmi seferi
	# bitirdiğini ölçtü.
	var session := _session_in_city()
	session.owned_wagon_count = 3
	session._sync_wagon_inventories()
	session.change_provisions(500)
	t.eq(session.get_crew_hands(), session.get_crew_need(), "başlangıçta eller tam")
	t.eq(session.get_driveable_wagon_count(), 3, "üç vagon da sürülüyor")
	var mouths_before := session.get_daily_provision_consumption()
	var capacity_before := session.get_cargo_capacity()

	# Üç aç gece: bir el ayrılır.
	for _night in GameSession.CREW_DESERT_FROM:
		session.apply_meal_distribution(GameSession.MEAL_MODE_PARTY_ONLY)
	t.eq(session.crew_missing, 1, "bir el eksildi")
	t.ok(
		session.get_daily_provision_consumption() < mouths_before,
		"ağız azaldı: kervan küçülerek yaşamayı sürdürebilir"
	)

	# İkinci el gidince bir vagon sürülemez olur.
	session.apply_meal_distribution(GameSession.MEAL_MODE_PARTY_ONLY)
	t.eq(session.crew_missing, 2, "iki el eksik")
	t.eq(session.get_driveable_wagon_count(), 2, "bir vagon boşta kaldı")
	t.eq(session.get_idle_wagon_count(), 1, "boşta vagon sayılıyor")
	t.ok(session.get_cargo_capacity() < capacity_before, "taşıma gücü düştü")

	# Yedinci geceden sonra artık ayrılmıyorlar, ölüyorlar.
	var died := 0
	while session.crew_hungry_nights < GameSession.CREW_STARVE_FROM:
		var result := session.apply_meal_distribution(GameSession.MEAL_MODE_PARTY_ONLY)
		died += (result["crew_starved_names"] as Array).size()
	t.ok(died > 0, "yürüyecek hâli kalmayan ölür")

func _test_an_idle_wagon_cannot_be_loaded(t) -> void:
	var session := _session_in_city()
	session.owned_wagon_count = 2
	session._sync_wagon_inventories()
	var item := ItemCatalog.get_item("test_cloth")
	t.ok(item != null, "deneme malı var")
	var full := int(floor(session.get_cargo_capacity() / maxf(0.1, item.unit_weight)))
	t.ok(session.add_to_cargo(item, full), "iki vagon doldu")

	# Bir el gidince ikinci vagon sürülemez: yükü taşınır, sığmayan kalır.
	session.crew_missing = 2
	session._sync_crew_names()
	t.eq(session.get_driveable_wagon_count(), 1, "tek vagon sürülüyor")
	var left := session.settle_idle_wagons()
	t.ok(not left.is_empty(), "sığmayan yük yolda kaldı")
	t.ok(
		session.get_total_quantity(item.item_id) < full,
		"kalan yük gerçekten eksildi"
	)
	t.not_ok(session.add_to_cargo(item, full), "boşta vagona yeni yük konmaz")

func _test_hands_are_hired_back_in_the_city_for_gold(t) -> void:
	var session := _session_in_city(400)
	session.owned_wagon_count = 2
	session._sync_wagon_inventories()
	session.crew_missing = 2
	session.crew_lost_to_hunger = 2
	session._sync_crew_names()
	var cheap := _session_in_city(400)
	t.ok(
		session.get_crew_hire_cost() > cheap.get_crew_hire_cost(),
		"aç bıraktığın her el fiyatı yükseltir: söz dolaşır"
	)

	var purse := session.wallet.balance
	t.eq(session.get_crew_hire_block_reason(), "", "şehirde el tutulur")
	t.ok(session.hire_crew_hand(), "bir el tutuldu")
	t.eq(session.crew_missing, 1, "eksik bir azaldı")
	t.ok(session.wallet.balance < purse, "parayla")
	t.ok(session.hire_crew_hand(), "ikinci el de tutuldu")
	t.eq(session.get_crew_hire_block_reason(), "UI_CREW_HIRE_FULL", "eksik kalmayınca kapalı")

	var place := WorldMapData.get_locations()[0]
	session.start_journey(place.location_id, 4, 0.1, CaravanPlan.new(place, 4, 6, 1))
	t.eq(session.get_crew_hire_block_reason(), "UI_CREW_HIRE_ON_ROAD", "yolda el tutulmaz")

# --- G5: kaybedilen dövüşün kalıcı bedeli ---

func _test_a_downed_fighter_never_gets_up_for_free(t) -> void:
	# Zorluğu arayan profil 8,5 dövüşün yarısını kaybetti ve kimse ölmedi,
	# kimse kalıcı bir şey kaybetmedi. Ölümün Kıyısı kuralı duruyor (ölüm
	# kurada değil), ama yere düşen artık mutlaka bir yara taşıyor.
	var session := _session_in_city()
	var fighter := session.get_party()[0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	t.eq(fighter.ailments.size(), 0, "sağlam başlıyor")
	var injury := session.roll_injury(fighter, rng)
	t.ne(injury, "", "yere düşen mutlaka bir yara alır")
	t.ok(fighter.ailments.has(injury), "yara üstünde kalır")

	# Üç yaranın üçünü de taşıyan biri dördüncüyü almaz - ama bu
	# "zaten yaralı olan bedava kurtulur" demek değil, taşıyacak yer yok.
	for id in CharacterData.INJURIES:
		fighter.add_ailment(id)
	t.eq(session.roll_injury(fighter, rng), "", "taşıyacak yara kalmayınca boş döner")

func _test_a_lost_fight_costs_cargo(t) -> void:
	var session := _session_in_city()
	var item := ItemCatalog.get_item("test_cloth")
	session.add_to_cargo(item, 12)
	var before := session.get_total_quantity(item.item_id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var taken := session.plunder_cargo(GameSession.DEFEAT_PLUNDER_SHARE, rng)
	t.ok(not taken.is_empty(), "haydut yükten alır")
	t.ok(session.get_total_quantity(item.item_id) < before, "yük gerçekten eksilir")

	# Erzağa dokunmuyor: açlık ayrı bir sistem, yenilgi onu tetiklemesin.
	var provisions := session.get_provisions()
	session.plunder_cargo(GameSession.DEFEAT_PLUNDER_SHARE, rng)
	t.eq(session.get_provisions(), provisions, "erzak yağmalanmaz")

# --- G6: büyümenin görünür bedeli ---

func _test_a_longer_column_is_slower_and_louder(t) -> void:
	# Bir profil on iki koşuda 120 vagon aldı ve 73 kez "Parti dolu" duydu:
	# sayaç artıyor, oyun değişmiyordu. Vagon hâlâ kapasite ve parti yeri
	# açıyor (sistem kesilmedi), ama artık bedeli de var.
	var small := _session_in_city()
	small.owned_wagon_count = 1
	small._sync_wagon_inventories()
	var big := _session_in_city()
	big.owned_wagon_count = 5
	big._sync_wagon_inventories()

	t.almost(small.get_convoy_speed_factor(), 1.0, "tek vagonlu kervan bu sistemi hissetmez")
	t.almost(small.get_convoy_danger_share(), 0.0, "ve dikkat de çekmez")
	t.ok(big.get_convoy_speed_factor() < small.get_convoy_speed_factor(), "uzun kolon yavaştır")
	t.ok(big.get_convoy_danger_share() > 0.0, "ve göze batar")
	t.ge(
		big.get_convoy_speed_factor(), GameSession.CONVOY_MIN_SPEED_FACTOR,
		"yavaşlamanın bir tabanı var: kervan durmaz"
	)
	t.le(
		big.get_convoy_danger_share(), GameSession.CONVOY_DANGER_MAX,
		"dikkatin de bir tavanı var"
	)

	# Tehlikenin dökümü bunu **yazıyor**: gizli bir ceza hatadan ayırt edilemez.
	var route := WorldMapData.get_routes_from(big.current_location_id)[0]
	var parts := big.get_route_danger_breakdown(route)
	var named := false
	for part in parts:
		if String((part as Dictionary).get("part", "")) == GameSession.DANGER_PART_CONVOY:
			named = true
	t.ok(named, "planlayıcı kolonun payını adıyla söyler")
	t.ok(
		big.get_route_danger(route) > small.get_route_danger(route),
		"ve aynı yol uzun kolon için daha tehlikeli"
	)
