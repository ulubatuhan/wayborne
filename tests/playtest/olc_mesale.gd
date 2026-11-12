extends SceneTree

## IP-002: gece ışığı neden hiç yakılamadı? Meşale oyunda erişilebilir mi, yoksa
## sürücü mü almıyor? Yerleşim yerleşim sayar ve tek bir cevap basar.
##
## godot --headless --script res://tests/playtest/olc_mesale.gd

func _initialize() -> void:
	var locations: Array[Location] = WorldMapData.get_locations()
	var torch: Item = ItemCatalog.get_item(ItemCatalog.TORCH)
	var lantern: Item = ItemCatalog.get_item(ItemCatalog.LANTERN)
	var oil: Item = ItemCatalog.get_item(ItemCatalog.LANTERN_OIL)
	var cloth: Item = ItemCatalog.get_item("test_cloth")

	var trade_ids: Array[String] = []
	for item in ItemCatalog.get_trade_goods():
		trade_ids.append(item.item_id)

	var torch_sellers := 0
	var cloth_sellers := 0
	var cloth_producers := 0
	var restricted := 0
	for location in locations:
		if location.sells(ItemCatalog.TORCH):
			torch_sellers += 1
		if location.sells("test_cloth"):
			cloth_sellers += 1
		if location.produces.has("test_cloth"):
			cloth_producers += 1
		if not location.available.is_empty():
			restricted += 1

	print("── IP-002 · meşale erişimi")
	print("yerleşim: %d (kısıtlı pazarı olan: %d)" % [locations.size(), restricted])
	print("meşale tezgâhta mı: %s · fiyat %d GG · gecede %d gerekiyor"
		% ["evet" if trade_ids.has(ItemCatalog.TORCH) else "HAYIR",
			0 if torch == null else torch.base_price, GameSession.TORCHES_PER_NIGHT])
	print("meşale satan yerleşim: %d / %d" % [torch_sellers, locations.size()])
	print("fener %d GG · yağ %d GG (fener yolu: fener + bir yağ)"
		% [0 if lantern == null else lantern.base_price, 0 if oil == null else oil.base_price])
	print("bez satan yerleşim: %d / %d (üreten: %d) · bez %d GG · tarif: 1 bez -> 2 meşale"
		% [cloth_sellers, locations.size(), cloth_producers,
			0 if cloth == null else cloth.base_price])

	var verdict := "OYUN HATASI: meşale hiçbir yerde alınamıyor"
	if torch_sellers == locations.size():
		verdict = "OYUNDA SORUN YOK: meşale her yerleşimde tezgâhta (Location.sells, LIGHT_SUPPLIES)"
	elif torch_sellers > 0:
		verdict = "KISMİ: meşale yalnız %d yerleşimde" % torch_sellers
	print("sonuç: %s" % verdict)
	print("not: sürücü `_mal_al` yalnız 'buranın ürettiği + gidilen yerin istediği' malı alıyordu;")
	print("     ışık malzemesi o süzgece hiç girmiyordu. Düzeltme sürücüde (IP-002).")
	quit()
