extends RefCounted

## Dünya verisi (WorldMapData): şehir/rota/teklif tablosunun tutarlılığı
## ve Faz 7 PR-D'nin isim geçişinin kalıcılığı - location_id'ler ("test_loc_a"
## vb.) kayıt uyumluluğu için sabit kalırken location_name/tüccar isimleri
## artık gerçek lore, "Test Şehir"/"Tüccar 12" gibi çıplak placeholder değil.

func suite_name() -> String:
	return "WorldMapData"

func run(t) -> void:
	_test_locations_have_real_names(t)
	_test_produces_and_demands_reference_real_items(t)
	_test_merchant_offers_have_real_names(t)
	_test_routes_are_symmetric(t)
	_test_trade_goods_have_real_names(t)
	_test_second_trade_loop_is_closed(t)
	_test_guild_wagon_quests(t)

func _test_locations_have_real_names(t) -> void:
	var locations := WorldMapData.get_locations()
	t.eq(locations.size(), 5, "beş şehir var")

	var seen_ids: Dictionary = {}
	for location in locations:
		t.not_ok(seen_ids.has(location.location_id), "şehir kimliği tekil: %s" % location.location_id)
		seen_ids[location.location_id] = true
		t.not_ok(location.location_name.begins_with("Test"), "%s artık placeholder isim taşımıyor" % location.location_id)

	t.ne(WorldMapData.get_location_by_id(WorldMapData.START_LOCATION_ID), null, "başlangıç şehri katalogda var")

func _test_produces_and_demands_reference_real_items(t) -> void:
	for location in WorldMapData.get_locations():
		for item_id in location.produces:
			t.ne(ItemCatalog.get_item(item_id), null, "%s'nin ürettiği %s katalogda var" % [location.location_id, item_id])
		for item_id in location.demands:
			t.ne(ItemCatalog.get_item(item_id), null, "%s'nin aradığı %s katalogda var" % [location.location_id, item_id])

func _test_merchant_offers_have_real_names(t) -> void:
	var offers := WorldMapData.get_offers_from_origin(WorldMapData.START_LOCATION_ID)
	t.ok(offers.size() > 0, "başlangıç şehrinden en az bir teklif var")
	for offer in offers:
		t.not_ok(offer.merchant_name.is_empty(), "tüccar ismi boş değil")
		t.not_ok(offer.merchant_name.begins_with("Tüccar "), "%s artık numaralı placeholder değil" % offer.merchant_id)

func _test_routes_are_symmetric(t) -> void:
	for location in WorldMapData.get_locations():
		for route in WorldMapData.get_routes_from(location.location_id):
			var reverse := WorldMapData.get_route(route.to_location_id, route.from_location_id)
			t.ne(reverse, null, "her rotanın ters yönü de var")
			t.eq(reverse.travel_days, route.travel_days, "gidiş-dönüş süresi eşit")
			t.almost(reverse.danger_level, route.danger_level, "gidiş-dönüş tehlikesi eşit")

## item_id'ler ("test_grain" vb.) kayıt uyumluluğu için sabit, ama
## item_name artık gerçek lore (bkz. ItemCatalog, Faz 7 PR-D).
func _test_trade_goods_have_real_names(t) -> void:
	var goods := ItemCatalog.get_trade_goods()
	t.ok(goods.size() >= 5, "en az beş ticaret malı var")
	for item in goods:
		t.not_ok(item.item_name.begins_with("Test "), "%s artık placeholder isim taşımıyor" % item.item_id)

## Faz 17 PR-5: ikinci ticaret katmanı - altı yeni mal beş şehri bir
## beşgen halkada birbirine bağlıyor. Her yeni mal tam olarak bir şehir
## tarafından üretilmeli ve en az bir başka şehir tarafından aranmalı,
## yoksa "ikinci döngü" yalnızca isim - hiçbir kervan o malı taşımaya
## teşvik edilmez.
func _test_second_trade_loop_is_closed(t) -> void:
	var new_goods := ["spice", "honey", "silk", "jewelry", "fish", "wine"]
	var producer_count: Dictionary = {}
	var demander_count: Dictionary = {}
	for item_id in new_goods:
		producer_count[item_id] = 0
		demander_count[item_id] = 0

	for location in WorldMapData.get_locations():
		for item_id in location.produces:
			if producer_count.has(item_id):
				producer_count[item_id] += 1
				t.not_ok(
					location.demands.has(item_id),
					"%s hem üretip hem aramaz: %s" % [location.location_id, item_id]
				)
		for item_id in location.demands:
			if demander_count.has(item_id):
				demander_count[item_id] += 1

	for item_id in new_goods:
		t.eq(producer_count[item_id], 1, "%s tam olarak bir şehir tarafından üretilir" % item_id)
		t.ok(demander_count[item_id] >= 1, "%s en az bir şehir tarafından aranır" % item_id)

## Loncanın vagon görev havuzu - normal kontrat panosuyla aynı akışı
## kullanan ama ayni ödül veren MerchantOffer'lar (bkz. GameSession.
## _apply_guild_wagon_quest_rewards). İki aile: vagon bağışları (kalıcı
## kapasite, bir kereye mahsus) ve kargo görevleri (piyasa malı, tekrar
## edilebilir - bkz. WorldMapData'nın kendi notu). Her birinin gerçek bir
## rotaya oturduğunu ve isimlerinin kültür havuzuyla asla çakışmayacağını
## (bkz. CaravanState'in isim eşleştirmesi) doğrular.
func _test_guild_wagon_quests(t) -> void:
	var quests := WorldMapData.get_guild_wagon_quests()
	t.eq(quests.size(), 6, "altı özel vagon görevi var - iki bağış, dört kargo")

	var grants: Array[MerchantOffer] = []
	var freights: Array[MerchantOffer] = []
	for quest in quests:
		if quest.grants_wagon_on_delivery:
			grants.append(quest)
		if quest.cargo_reward_quantity > 0:
			freights.append(quest)

	t.eq(grants.size(), 2, "iki vagon bağışı görevi var")
	t.eq(freights.size(), 4, "dört kargo görevi var")

	for grant in grants:
		t.not_ok(grant.cargo_reward_quantity > 0, "bir vagon bağışı aynı zamanda kargo ödülü taşımaz")
		t.ne(
			WorldMapData.get_route(grant.origin_location_id, grant.destination_location_id), null,
			"%s gerçek bir rotaya oturuyor" % grant.merchant_id
		)

	for freight in freights:
		t.not_ok(freight.grants_wagon_on_delivery, "bir kargo görevi aynı zamanda vagon vermez")
		t.ne(
			WorldMapData.get_route(freight.origin_location_id, freight.destination_location_id), null,
			"%s gerçek bir rotaya oturuyor" % freight.merchant_id
		)
		t.ne(ItemCatalog.get_item(freight.cargo_reward_item_id), null, "%s'nin ödül malı katalogda var" % freight.merchant_id)
		# Ödül malı, görevin çıkış şehrinin gerçekten ürettiği mal olmalı -
		# "lonca o şehrin kendi fazlasını taşıtıyor" kurgusunun tutarlılığı.
		var origin := WorldMapData.get_location_by_id(freight.origin_location_id)
		t.ok(
			origin != null and origin.produces.has(freight.cargo_reward_item_id),
			"%s'nin ödül malı çıkış şehrinin kendi ürettiği mal" % freight.merchant_id
		)

	# İsimleri kültür isim havuzuyla çakışmamalı - CaravanState.merchant_names
	# yalnızca isimle eşleştiriyor, bir çakışma yanlış kontrata ödül verirdi.
	for culture in CultureCatalog.get_cultures():
		for pool_name in culture.name_pool:
			for quest in quests:
				t.ne(pool_name, quest.merchant_name, "%s'nin adı bir kültür isminden farklı" % quest.merchant_id)

	# Hepsinin merchant_id'si diğer tüm tekliflerden tekil olmalı, yoksa
	# accept_contract/is_contract_accepted birbirine karışır.
	var seen_ids: Dictionary = {}
	for location in WorldMapData.get_locations():
		for offer in WorldMapData.get_offers_from_origin(location.location_id):
			t.not_ok(seen_ids.has(offer.merchant_id), "merchant_id tekil: %s" % offer.merchant_id)
			seen_ids[offer.merchant_id] = true
