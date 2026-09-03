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
