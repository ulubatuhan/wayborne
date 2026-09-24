extends RefCounted

## Vagon-bazlı envanter (bkz. GameSession.wagon_inventories), kişisel çanta
## taşkını (bkz. CharacterData.personal_inventory) ve Atölye craftlaması
## (bkz. RecipeCatalog/GameSession.craft_in_wagon - yolda tıklanan vagonun
## kendi envanterinden okur/yazar, bkz. world_hub.gd) - CLAUDE.md #22
## tasarım notunun Faz 15'te uygulanan hâli.

func suite_name() -> String:
	return "WagonInventory"

func run(t) -> void:
	_test_each_wagon_has_its_own_inventory(t)
	_test_add_to_cargo_splits_across_wagons(t)
	_test_add_to_cargo_is_all_or_nothing(t)
	_test_selling_a_wagon_redistributes_its_cargo(t)
	_test_losing_a_wagon_can_lose_cargo_that_does_not_fit(t)
	_test_personal_bag_catches_overflow(t)
	_test_total_quantity_and_entries_sum_wagons_and_bags(t)
	_test_remove_drains_wagons_before_bags(t)
	_test_save_round_trip_preserves_wagon_split_and_bags(t)
	_test_legacy_single_inventory_save_still_loads(t)
	_test_craft_bandage(t)
	_test_craft_ignores_materials_in_other_wagons(t)
	_test_repair_wagon_canvas_recipe(t)
	_test_dismantle_recipe(t)
	_test_craft_block_reasons(t)
	_test_move_cargo_moves_the_full_stack(t)
	_test_move_cargo_blocked_when_destination_full(t)
	_test_move_cargo_invalid_requests(t)
	_test_move_cargo_partial_quantity(t)
	_test_move_cargo_partial_quantity_out_of_range_blocked(t)
	_test_move_cargo_partial_quantity_fits_when_full_stack_does_not(t)

func _test_each_wagon_has_its_own_inventory(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	t.eq(session.wagon_inventories.size(), 1, "bir vagonla bir envanter")
	session.wallet.earn(5000)
	session.buy_wagon()
	t.eq(session.wagon_inventories.size(), 2, "ikinci vagon kendi envanterini açar")

	var cloth := ItemCatalog.get_item("test_cloth")
	session.wagon_inventories[0].add_item(cloth, 3)
	t.eq(session.wagon_inventories[0].get_quantity("test_cloth"), 3, "birinci vagon kendi malını taşır")
	t.eq(session.wagon_inventories[1].get_quantity("test_cloth"), 0, "ikinci vagon boş kalır")

## Bir yığın tek bir vagona sığmak zorunda değil - toplam kapasiteye sığmalı.
func _test_add_to_cargo_splits_across_wagons(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()  # iki vagon, her biri CARGO_PER_WAGON taşır

	var cloth := ItemCatalog.get_item("test_cloth")
	# Bir vagonun taşıyabileceğinden fazlasını, ikisinin toplamına sığacak
	# kadar iste - tek vagona sığmıyor ama toplam kapasiteye sığıyor.
	var per_wagon_max := session.wagon_inventories[0].get_addable_quantity(cloth)
	var quantity := per_wagon_max + 1
	t.ok(quantity <= int(session.get_cargo_capacity() / cloth.unit_weight), "istek toplam kapasiteyi aşmıyor")

	t.ok(session.add_to_cargo(cloth, quantity), "iki vagona bölünerek sığar")
	t.eq(session.get_total_quantity("test_cloth"), quantity, "toplam miktar doğru")
	t.ok(session.wagon_inventories[0].get_quantity("test_cloth") > 0, "birinci vagon pay aldı")
	t.ok(session.wagon_inventories[1].get_quantity("test_cloth") > 0, "ikinci vagon pay aldı")

## Toplam kapasiteyi de aşan bir istek hiçbir vagona dokunmamalı - yarım
## yamalak bir ekleme kafa karıştırır.
func _test_add_to_cargo_is_all_or_nothing(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	var cloth := ItemCatalog.get_item("test_cloth")
	var too_much := int(session.get_cargo_capacity() / cloth.unit_weight) + 50
	t.not_ok(session.add_to_cargo(cloth, too_much), "toplam kapasiteyi aşan istek reddedilir")
	t.eq(session.get_total_quantity("test_cloth"), 0, "reddedilen ekleme hiçbir vagona yazılmaz")

## Satış her zaman kalan vagonların toplam kapasitesine sığacak şekilde
## kilitli (bkz. get_wagon_sale_block_reason), o yüzden kargo tam olarak
## dağıtılabilmeli.
func _test_selling_a_wagon_redistributes_its_cargo(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()  # iki vagon

	var cloth := ItemCatalog.get_item("test_cloth")
	var light_quantity := int(session.wagon_inventories[1].get_addable_quantity(cloth) / 2)
	session.wagon_inventories[1].add_item(cloth, light_quantity)

	t.ok(session.can_sell_wagon(), "hafif kargoyla satış açık")
	t.ok(session.sell_wagon(), "vagon satılabilir")
	t.eq(session.wagon_inventories.size(), 1, "bir vagon kaldı")
	t.eq(
		session.get_total_quantity("test_cloth"), light_quantity,
		"satılan vagonun kargosu kalan vagona taşındı, kaybolmadı"
	)

## Bir vagon *satılmadan* kaybedilirse (savaş/olay) böyle bir garanti yok -
## kaybedilen kargo gerçekten kaybolabilir (bkz. CLAUDE.md Ruin Rules).
func _test_losing_a_wagon_can_lose_cargo_that_does_not_fit(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()  # iki vagon, ikisi de dolu olabilir

	var cloth := ItemCatalog.get_item("test_cloth")
	var full_quantity := session.wagon_inventories[1].get_addable_quantity(cloth)
	session.wagon_inventories[1].add_item(cloth, full_quantity)
	# Birinci vagon da doldurulursa ikinci vagonun kargosunu yutacak yer kalmaz.
	session.wagon_inventories[0].add_item(cloth, session.wagon_inventories[0].get_addable_quantity(cloth))

	session.owned_wagon_count = 1
	session._sync_wagon_inventories()

	t.eq(session.wagon_inventories.size(), 1, "bir vagon kaldı")
	t.ok(
		session.get_total_quantity("test_cloth") < full_quantity * 2,
		"sığmayan kargo vagonla birlikte gerçekten kayboldu"
	)

## Bir ödül vagonlara sığmayacak kadar küçükse (bkz. add_to_cargo_or_bag)
## kişisel çantaya taşar - tamamen kaybolmaz.
func _test_personal_bag_catches_overflow(t) -> void:
	var session := GameSession.new(0, 0, 1)
	session.add_to_party(CharacterData.create("Yoldaş", CultureCatalog.NOMAD, CharacterStats.new()))

	var cloth := ItemCatalog.get_item("test_cloth")
	var full_quantity := session.wagon_inventories[0].get_addable_quantity(cloth)
	session.wagon_inventories[0].add_item(cloth, full_quantity)

	t.not_ok(session.add_to_cargo(cloth, 1), "vagon doluyken kargoya eklenemez")
	t.ok(session.add_to_cargo_or_bag(cloth, 1), "vagon doluyken çantaya sığar")

	var carried_in_bag := false
	for character in session.get_party():
		if character.personal_inventory.get_quantity("test_cloth") > 0:
			carried_in_bag = true
	t.ok(carried_in_bag, "taşan mal bir partili tarafından çantada taşınıyor")

func _test_total_quantity_and_entries_sum_wagons_and_bags(t) -> void:
	var session := GameSession.new(0, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()
	var leader := session.get_party()[0]
	var companion := CharacterData.create("Yoldaş", CultureCatalog.NOMAD, CharacterStats.new())
	session.add_to_party(companion)

	var cloth := ItemCatalog.get_item("test_cloth")
	session.wagon_inventories[0].add_item(cloth, 2)
	session.wagon_inventories[1].add_item(cloth, 3)
	leader.personal_inventory.add_item(cloth, 1)
	companion.personal_inventory.add_item(cloth, 1)

	t.eq(session.get_total_quantity("test_cloth"), 7, "iki vagon + iki çanta toplanır")

	var entries := session.get_total_inventory_entries()
	var found := false
	for entry in entries:
		if entry.item.item_id == "test_cloth":
			t.eq(int(entry.quantity), 7, "toplam dökümde de aynı sayı")
			found = true
	t.ok(found, "toplam dökümde mal görünüyor")

## Satış/craft önce vagonlardan düşer, yeterli değilse çantalardan
## tamamlanır - tek bir "hepsi ya da hiçbiri" garanti eder.
func _test_remove_drains_wagons_before_bags(t) -> void:
	var session := GameSession.new(0, 0, 1)
	var leader := session.get_party()[0]
	var cloth := ItemCatalog.get_item("test_cloth")
	session.wagon_inventories[0].add_item(cloth, 2)
	leader.personal_inventory.add_item(cloth, 3)

	t.not_ok(session.remove_from_cargo_or_bags("test_cloth", 10), "yetersizken hiçbir şey silinmez")
	t.eq(session.get_total_quantity("test_cloth"), 5, "başarısız istek envanteri bozmaz")

	t.ok(session.remove_from_cargo_or_bags("test_cloth", 4), "vagon + çantadan tamamlanır")
	t.eq(session.wagon_inventories[0].get_quantity("test_cloth"), 0, "vagon önce boşalır")
	t.eq(leader.personal_inventory.get_quantity("test_cloth"), 1, "çantadan kalan kadarı düşer")

func _test_save_round_trip_preserves_wagon_split_and_bags(t) -> void:
	var session := GameSession.new(500, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()
	var leader := session.get_party()[0]

	var cloth := ItemCatalog.get_item("test_cloth")
	var furs := ItemCatalog.get_item("test_furs")
	session.wagon_inventories[0].add_item(cloth, 2)
	session.wagon_inventories[1].add_item(furs, 1)
	leader.personal_inventory.add_item(cloth, 1)

	var saved := session.to_save_dict()
	var loaded := GameSession.new(0, 0)
	loaded.load_from_dict(saved)

	t.eq(loaded.wagon_inventories.size(), 2, "vagon sayısı korunur")
	t.eq(loaded.wagon_inventories[0].get_quantity("test_cloth"), 2, "birinci vagonun içeriği korunur")
	t.eq(loaded.wagon_inventories[1].get_quantity("test_furs"), 1, "ikinci vagonun içeriği korunur")
	t.eq(
		loaded.get_player_character().personal_inventory.get_quantity("test_cloth"), 1,
		"liderin çantası da kaydedilip yükleniyor"
	)

## Eski (v2 ve öncesi) kayıtların tek paylaşılan "inventory" listesi hâlâ
## okunabilmeli - `add_to_cargo` onu vagonlara kendiliğinden dağıtır.
func _test_legacy_single_inventory_save_still_loads(t) -> void:
	var session := GameSession.new(0, 0)
	session.load_from_dict({
		"version": 2,
		"gold": 0,
		"inventory": [{"item_id": "test_cloth", "quantity": 4}],
		"current_location_id": WorldMapData.START_LOCATION_ID,
		"owned_wagon_count": 1,
		"party": [],
	})
	t.eq(session.get_total_quantity("test_cloth"), 4, "eski tek liste vagona dağıtılarak yükleniyor")

## Atölye o vagonun kendisi (bkz. world_hub.gd'nin vagon etkileşim
## noktaları) - tarifler kervanın toplamından değil, yalnızca tıklanan
## vagonun kendi envanterinden okur/yazar.
func _test_craft_bandage(t) -> void:
	var session := GameSession.new(0, 0, 1)
	var recipe := RecipeCatalog.get_recipe(RecipeCatalog.CRAFT_BANDAGE)
	t.not_ok(session.can_craft_in_wagon(0, recipe), "malzemesiz craftlanamaz")
	t.eq(
		session.get_craft_block_reason_in_wagon(0, recipe), "UI_CRAFT_MISSING_MATERIAL",
		"sebep malzeme eksikliği"
	)

	session.wagon_inventories[0].add_item(ItemCatalog.get_item("test_cloth"), 2)
	t.ok(session.can_craft_in_wagon(0, recipe), "iki kumaşla craftlanabilir")
	t.ok(session.craft_in_wagon(0, RecipeCatalog.CRAFT_BANDAGE), "craft başarılı")
	t.eq(session.wagon_inventories[0].get_quantity("test_cloth"), 0, "malzeme tüketildi")
	t.eq(session.wagon_inventories[0].get_quantity("test_bandage"), 1, "bandaj aynı vagona yazıldı")

## Asıl mesele bu: malzeme *başka* bir vagondaysa, bu vagonda craftlanamaz.
## "Hangi vagonda ne var" ilk kez gerçekten anlam taşıyor.
func _test_craft_ignores_materials_in_other_wagons(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()  # iki vagon

	var recipe := RecipeCatalog.get_recipe(RecipeCatalog.CRAFT_BANDAGE)
	session.wagon_inventories[1].add_item(ItemCatalog.get_item("test_cloth"), 2)

	t.not_ok(
		session.can_craft_in_wagon(0, recipe),
		"kumaş ikinci vagondayken birinci vagonda craftlanamaz"
	)
	t.ok(session.can_craft_in_wagon(1, recipe), "kumaşın olduğu vagonda craftlanabilir")

func _test_repair_wagon_canvas_recipe(t) -> void:
	var session := GameSession.new(0, 0, 1)
	var recipe := RecipeCatalog.get_recipe(RecipeCatalog.REPAIR_WAGON_CANVAS)
	session.wagon_inventories[0].add_item(ItemCatalog.get_item("test_cloth"), 3)

	t.not_ok(session.can_craft_in_wagon(0, recipe), "hasar yokken onarım tarifi kapalı")
	t.eq(
		session.get_craft_block_reason_in_wagon(0, recipe), "UI_CRAFT_NO_DAMAGE",
		"sebep hasarsızlık"
	)

	session.owned_wagon_damaged = 1
	t.ok(session.can_craft_in_wagon(0, recipe), "hasar varken malzemeyle onarılabilir")
	t.ok(session.craft_in_wagon(0, RecipeCatalog.REPAIR_WAGON_CANVAS), "onarım başarılı")
	t.eq(session.owned_wagon_damaged, 0, "hasar malzemeyle düştü")
	t.eq(session.wagon_inventories[0].get_quantity("test_cloth"), 0, "malzeme tüketildi")

func _test_dismantle_recipe(t) -> void:
	var session := GameSession.new(0, 0, 1)
	session.wagon_inventories[0].add_item(ItemCatalog.get_item("test_furs"), 1)
	t.ok(session.craft_in_wagon(0, RecipeCatalog.DISMANTLE_TO_BANDAGE), "sökme başarılı")
	t.eq(session.wagon_inventories[0].get_quantity("test_furs"), 0, "kürk tüketildi")
	t.eq(session.wagon_inventories[0].get_quantity("test_bandage"), 2, "iki bandaj aynı vagona çıktı")

## Kilitli bir tarif *sebebiyle birlikte* gösterilir - hem craft_in_wagon()
## hem get_craft_block_reason_in_wagon() aynı kilide bakmalı.
func _test_craft_block_reasons(t) -> void:
	var session := GameSession.new(0, 0, 1)
	t.not_ok(session.craft_in_wagon(0, "bilinmeyen_tarif"), "olmayan tarif craftlanamaz")
	t.not_ok(
		session.craft_in_wagon(0, RecipeCatalog.CRAFT_BANDAGE),
		"malzemesiz craft_in_wagon() de başarısız olur, get_craft_block_reason_in_wagon'la tutarlı"
	)
	t.not_ok(
		session.can_craft_in_wagon(99, RecipeCatalog.get_recipe(RecipeCatalog.CRAFT_BANDAGE)),
		"var olmayan bir vagon indeksi de kapalı sayılır"
	)

## Kervan Envanteri Rules'un kalan parçası: "Kervan Yükü" ekranının okuduğu
## GameSession.move_cargo_between_wagons - `quantity` verilmezse (-1,
## varsayılan) bir malın **tam** mevcut miktarını taşır. Kısmi miktar için
## bkz. _test_move_cargo_partial_quantity - o durumda da işlem yine hep ya
## da hiçtir (`add_to_cargo`'nun aynı "hepsi ya da hiçbiri" kuralı),
## yalnızca "hepsi"nin büyüklüğünü artık oyuncu seçebiliyor.
func _test_move_cargo_moves_the_full_stack(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()  # iki vagon

	var cloth := ItemCatalog.get_item("test_cloth")
	session.wagon_inventories[0].add_item(cloth, 5)

	t.ok(session.can_move_cargo_between_wagons(0, "test_cloth", 1), "taşıma önceden mümkün görünür")
	t.ok(session.move_cargo_between_wagons(0, "test_cloth", 1), "taşıma başarılı")
	t.eq(session.wagon_inventories[0].get_quantity("test_cloth"), 0, "kaynak vagon boşaldı")
	t.eq(session.wagon_inventories[1].get_quantity("test_cloth"), 5, "hedef vagon tam yığını aldı")

## Hedef vagonda yer yoksa hiçbir şey taşınmaz - kısmi bir taşıma iki
## farklı sayıyı iki kez göstermek zorunda kalırdı.
func _test_move_cargo_blocked_when_destination_full(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()  # iki vagon, her biri CARGO_PER_WAGON taşır

	var cloth := ItemCatalog.get_item("test_cloth")  # unit_weight 1.5
	session.wagon_inventories[0].add_item(cloth, 5)
	# Hedef vagonu neredeyse doldur - beş birim cloth (7.5 ağırlık) için
	# artık yer kalmasın.
	var filler_capacity := int(GameSession.CARGO_PER_WAGON / cloth.unit_weight) - 2
	session.wagon_inventories[1].add_item(cloth, filler_capacity)

	t.eq(
		session.get_cargo_move_block_reason(0, "test_cloth", 1), "UI_CARGO_MOVE_NO_ROOM",
		"sebep yer yokluğu"
	)
	t.not_ok(session.move_cargo_between_wagons(0, "test_cloth", 1), "taşıma başarısız")
	t.eq(session.wagon_inventories[0].get_quantity("test_cloth"), 5, "kaynak vagon dokunulmadan kalır")

## Geçersiz istekler (aynı vagon, aralık dışı indeks, olmayan mal) sessizce
## reddedilir, çökme yok.
func _test_move_cargo_invalid_requests(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()
	session.wagon_inventories[0].add_item(ItemCatalog.get_item("test_cloth"), 3)

	t.eq(
		session.get_cargo_move_block_reason(0, "test_cloth", 0), "UI_CARGO_MOVE_INVALID",
		"aynı vagona taşıma geçersiz"
	)
	t.eq(
		session.get_cargo_move_block_reason(0, "test_cloth", 99), "UI_CARGO_MOVE_INVALID",
		"aralık dışı hedef geçersiz"
	)
	t.eq(
		session.get_cargo_move_block_reason(0, "test_grain", 1), "UI_CARGO_MOVE_INVALID",
		"o vagonda hiç olmayan bir mal geçersiz"
	)
	t.not_ok(session.move_cargo_between_wagons(0, "test_cloth", 0), "geçersiz istek hiçbir şey taşımaz")

## Kısmi miktar - CaravanCargoPanel'in SpinBox'ı burada okunuyor. Elindeki
## 5'ten yalnızca 2'sini taşımak kaynakta 3, hedefte 2 bırakmalı.
func _test_move_cargo_partial_quantity(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()

	var cloth := ItemCatalog.get_item("test_cloth")
	session.wagon_inventories[0].add_item(cloth, 5)

	t.ok(session.can_move_cargo_between_wagons(0, "test_cloth", 1, 2), "kısmi miktar önceden mümkün görünür")
	t.ok(session.move_cargo_between_wagons(0, "test_cloth", 1, 2), "kısmi taşıma başarılı")
	t.eq(session.wagon_inventories[0].get_quantity("test_cloth"), 3, "kaynakta kalan miktar doğru")
	t.eq(session.wagon_inventories[1].get_quantity("test_cloth"), 2, "hedefe yalnızca istenen miktar geçti")

## Elindekinden fazlası ya da sıfır/negatif istenirse geçersiz sayılır -
## SpinBox'ın kendi min/max'ı bunu zaten engeller ama GameSession kapısı
## da bağımsız olarak korumalı.
func _test_move_cargo_partial_quantity_out_of_range_blocked(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()
	session.wagon_inventories[0].add_item(ItemCatalog.get_item("test_cloth"), 5)

	t.eq(
		session.get_cargo_move_block_reason(0, "test_cloth", 1, 6), "UI_CARGO_MOVE_INVALID",
		"elindekinden fazlası istenemez"
	)
	t.eq(
		session.get_cargo_move_block_reason(0, "test_cloth", 1, 0), "UI_CARGO_MOVE_INVALID",
		"sıfır miktar geçersiz"
	)
	t.not_ok(session.move_cargo_between_wagons(0, "test_cloth", 1, 6), "aralık dışı istek hiçbir şey taşımaz")
	t.eq(session.wagon_inventories[0].get_quantity("test_cloth"), 5, "kaynak dokunulmadan kalır")

## Kısmi miktar, tam yığının hiç sığmadığı bir vagona da sığabilir -
## SpinBox'ın asıl kazandırdığı esneklik bu: engel artık istenen miktara
## göre değişiyor, sabit "tam yığın sığar mı" sorusuna değil.
func _test_move_cargo_partial_quantity_fits_when_full_stack_does_not(t) -> void:
	var session := GameSession.new(1000, 0, 1)
	session.wallet.earn(5000)
	session.buy_wagon()

	var cloth := ItemCatalog.get_item("test_cloth")  # unit_weight 1.5
	session.wagon_inventories[0].add_item(cloth, 5)
	# Hedef vagonu yalnızca 2 birime yer kalacak kadar doldur - tam yığın
	# (5) sığmaz ama 2'si sığar.
	var filler_capacity := int(GameSession.CARGO_PER_WAGON / cloth.unit_weight) - 2
	session.wagon_inventories[1].add_item(cloth, filler_capacity)

	t.eq(
		session.get_cargo_move_block_reason(0, "test_cloth", 1), "UI_CARGO_MOVE_NO_ROOM",
		"varsayılan (tam yığın) hâlâ engelli"
	)
	t.eq(
		session.get_cargo_move_block_reason(0, "test_cloth", 1, 2), "",
		"küçültülmüş miktar engelli değil"
	)
	t.ok(session.move_cargo_between_wagons(0, "test_cloth", 1, 2), "küçültülmüş miktar taşınabilir")
	t.eq(session.wagon_inventories[0].get_quantity("test_cloth"), 3, "kaynakta kalan miktar doğru")
