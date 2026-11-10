extends RefCounted

## Şehirde verilen kararlar: vagon satmak, loncadan borç almak ve şehrin
## karar paneli (`CityBriefPanel`). İlk ikisi kervanın kalıcı durumunu
## değiştiriyor, yani ikisi de sömürüye açık - o yüzden orada formülden çok
## **sömürünün kapalı olduğu** doğrulanıyor (bkz. test_haggling.gd'nin aynı
## yaklaşımı). Panel tarafında doğrulanan şey farklı: her uyarının onu
## çözen ekranı gösterdiği, ve hiçbir uyarının ölü bir düğmeye bağlanmadığı.
##
## Kapatılan üç kaçamak:
##   1. Al-sat döngüsü: vagon alıp satmak para kazandırmamalı.
##   2. Sat-yeniden-al onarımı: enkazı satıp yenisini almak, onarmaktan
##      ucuza gelmemeli.
##   3. Bedava yapılandırma: borç alıp açık hesabı kapatmak, açık hesabın
##      vadesini ücretsiz sıfırlayan bir yapılandırma olmamalı.

func suite_name() -> String:
	return "CityCommerce"

func run(t) -> void:
	_test_ban_survives_save(t)
	_test_convoy_and_driver(t)
	_test_scarcity_and_city_morale(t)
	_test_plague_is_a_world_state(t)
	_test_gokyurt_hospitality(t)
	_test_caravanserai_rumor_bonus(t)
	_test_wagon_sale_never_returns_its_cost(t)
	_test_selling_never_takes_the_last_wagon(t)
	_test_repair_always_beats_sell_and_rebuy(t)
	_test_sale_blocked_with_a_reason_not_hidden(t)
	_test_damaged_wagon_goes_first(t)
	_test_credit_line_scales_with_reputation(t)
	_test_debt_consumes_the_credit_line(t)
	_test_advance_gives_cargo_not_coin(t)
	_test_advance_cannot_clear_an_overdraft(t)
	_test_advance_costs_more_than_it_carries(t)
	_test_loan_fee_scales_with_reputation(t)
	_test_loan_closed_on_the_road_and_without_trust(t)
	_test_brief_flags_what_the_caravan_lacks(t)
	_test_brief_needs_point_at_real_screens(t)
	_test_brief_shows_debt_even_when_the_term_is_far_off(t)
	_test_brief_offers_every_open_route(t)
	_test_brief_says_someone_is_waiting(t)
	_test_price_book(t)
	_test_goods_variety(t)
	_test_buy_then_sell_back_never_profits(t)
	_test_unrequired_contracts_stay_open_at_bad_reputation(t)

func _session(gold: int = 500, wagons: int = 1) -> GameSession:
	return GameSession.new(gold, 10, wagons)

# --- Vagon satışı ---

## Alıp satmak kervana para kazandırırsa, kapasiteyi sefer başına açıp
## kapatan bedava bir düğme doğardı.
func _test_wagon_sale_never_returns_its_cost(t) -> void:
	var session := _session(2000, 1)
	for _step in 3:
		var before := session.wallet.balance
		if not session.buy_wagon():
			break
		var spent := before - session.wallet.balance
		var mid := session.wallet.balance
		t.ok(session.sell_wagon(), "alınan vagon geri satılabilir")
		var returned := session.wallet.balance - mid
		t.ok(
			returned < spent,
			"vagon aldığı parayı geri getirmez (%d ödendi, %d döndü)" % [spent, returned]
		)
		t.ok(session.buy_wagon(), "döngüyü sürdürmek için tekrar alınır")

func _test_selling_never_takes_the_last_wagon(t) -> void:
	var session := _session(500, 1)
	t.eq(session.owned_wagon_count, CaravanState.MIN_WAGONS, "tek vagonla başlanır")
	t.not_ok(session.can_sell_wagon(), "son vagon satılamaz")
	t.not_ok(session.sell_wagon(), "satış denemesi başarısız")
	t.eq(session.owned_wagon_count, CaravanState.MIN_WAGONS, "vagon sayısı değişmedi")
	t.eq(session.get_wagon_sale_value(), 0, "satılamayan vagonun fiyatı yok")

## Enkazı satıp yenisini almak onarımdan ucuza gelirse, onarım ölü bir
## mekanik olurdu.
func _test_repair_always_beats_sell_and_rebuy(t) -> void:
	var session := _session(3000, 1)
	t.ok(session.buy_wagon(), "ikinci vagon alınır")
	session.owned_wagon_damaged = 1

	var repair_cost := session.get_repair_cost()
	var sale_value := session.get_wagon_sale_value()
	var rebuy_cost := session.get_next_wagon_cost()
	var churn_cost := rebuy_cost - sale_value

	t.ok(
		repair_cost < churn_cost,
		"onarım (%d) sat-yeniden-al'dan (%d) ucuz" % [repair_cost, churn_cost]
	)

## Kilitli seçenek sebebiyle birlikte gösterilir, gizlenmez - oyunun her
## yerindeki kural (kilitli olay seçimi, kilitli yetenek, kilitli ekipman).
func _test_sale_blocked_with_a_reason_not_hidden(t) -> void:
	var session := _session(3000, 1)
	t.ne(session.get_wagon_sale_block_reason(), "", "tek vagonda satışın bir sebebi var")

	t.ok(session.buy_wagon(), "ikinci vagon alınır")
	t.eq(session.get_wagon_sale_block_reason(), "", "iki vagonda satış açık")

	# Kadro kapasitenin üstünde kalacaksa satış kapanır: kervandan kimse
	# atılmaz (bkz. Ruin Rules), o yüzden gönüllü satış en baştan engellenir.
	while session.party.size() < session.get_party_capacity():
		session.add_to_party(_companion())
	t.ne(
		session.get_wagon_sale_block_reason(), "",
		"kadro sığmayacaksa satış sebebiyle birlikte kapanır"
	)
	t.not_ok(session.sell_wagon(), "engelli satış hiçbir şeyi değiştirmez")
	t.eq(session.owned_wagon_count, 2, "vagon sayısı korunur")

func _test_damaged_wagon_goes_first(t) -> void:
	var session := _session(3000, 1)
	t.ok(session.buy_wagon(), "ikinci vagon alınır")
	session.owned_wagon_damaged = 1

	var healthy_value := 0
	var damaged_value := session.get_wagon_sale_value()
	session.owned_wagon_damaged = 0
	healthy_value = session.get_wagon_sale_value()
	t.ok(
		damaged_value < healthy_value,
		"hasarlı vagon daha az eder (%d < %d)" % [damaged_value, healthy_value]
	)

	session.owned_wagon_damaged = 1
	t.ok(session.sell_wagon(), "hasarlı vagon satılır")
	t.eq(session.owned_wagon_damaged, 0, "giden vagon hasarlı olandı")

func _companion() -> CharacterData:
	return CharacterData.create("Yoldaş", "gocebe", CharacterStats.new())

# --- Lonca kredisi ---

func _test_credit_line_scales_with_reputation(t) -> void:
	var session := _session(100, 1)
	var base_limit := session.get_credit_limit()
	session.reputation = 10
	t.ok(
		session.get_credit_limit() > base_limit,
		"itibar arttıkça kredi hattı büyür"
	)
	session.reputation = 10000
	t.le(
		float(session.get_credit_limit()), float(GameSession.LOAN_MAX_LIMIT),
		"hat bir tavanda durur"
	)

## Hattı borcun kendisi tüketmezse, borç alıp borcu kapatmak sonsuz bir
## döngü olurdu.
func _test_debt_consumes_the_credit_line(t) -> void:
	var session := _advance_session()
	var limit := session.get_credit_limit()
	t.eq(session.get_available_credit(), limit, "borçsuzken hattın tamamı açık")

	var item := _advance_item(session)
	t.ne(item, null, "şehrin ürettiği bir mal var")
	t.ok(session.take_goods_advance(item, 5), "hattan bir dilim mal avansı alınır")
	t.eq(
		session.get_available_credit(),
		maxi(0, limit - session.get_total_debt()),
		"kalan hat borcun tamamını düşer"
	)

	# Hat ya da kargo dolana kadar al; sonrası kapalı olmalı.
	var guard := 0
	while session.can_take_advance(item, 5) and guard < 200:
		session.take_goods_advance(item, 5)
		guard += 1
	t.ok(guard < 200, "avans sonsuz değil")
	t.not_ok(session.can_take_advance(item, 5), "dolu hattan (ya da dolu kargodan) avans alınmaz")

## P13: **nakit kredi kaldırıldı**, çünkü tam olarak bir kaçış kapağıydı -
## para sıkışınca para alabilen oyuncu kıvranmaz ve P5'in erzak stoğu ile
## P9'un sözü anlamını kaybederdi. Yerine lonca **yük** veriyor.
func _test_advance_gives_cargo_not_coin(t) -> void:
	var session := _advance_session()
	var item := _advance_item(session)
	var purse := session.wallet.balance
	var held := session.get_total_quantity(item.item_id)
	var value := session.get_advance_value(item, 10)

	t.ok(session.take_goods_advance(item, 10), "avans alınır")
	t.eq(session.wallet.balance, purse, "keseye tek kuruş girmez")
	t.eq(session.get_total_quantity(item.item_id), held + 10, "mal kargoya girer")
	t.eq(session.get_total_debt(), value, "borç ilan edilen değerle yazılır")

	# Ve borç bir **teslimata** bağlı (P11): parasını ödesen de malı
	# kaybedersen borç kapanmaz.
	var debt: Debt = session.debts.get_debts()[0]
	t.ok(debt.is_delivery(), "avans borcu bir yük borcudur")
	t.eq(debt.delivery_item_id, item.item_id, "yük tam olarak alınan mal")
	t.eq(debt.source, Debt.SOURCE_ADVANCE, "kaynağı avans olarak yazılır")

## En keskin kaçamak kapandı: avans para vermediği için açık hesabı
## kapatamıyor. Eskiden borç alıp açığı kapatmak bedava bir yapılandırmaya
## dönüşebiliyordu; şimdi öyle bir kapı yok.
func _test_advance_cannot_clear_an_overdraft(t) -> void:
	var session := _advance_session()
	session.spend_or_owe(session.wallet.balance + 100)
	t.ok(session.wallet.balance < 0, "kese eksiye düştü")
	var before := session.get_total_debt()

	var item := _advance_item(session)
	if session.can_take_advance(item, 5):
		session.take_goods_advance(item, 5)
	t.ok(session.wallet.balance < 0, "avans keseyi kurtarmaz")
	t.ok(session.get_total_debt() >= before, "borç azalmaz, olsa olsa artar")

## Avans bedava değil: tahsis ücreti defterdeki anaparaya biniyor, yani
## malı alıp aynı gün satsan bile zarardasın.
func _test_advance_costs_more_than_it_carries(t) -> void:
	var session := _advance_session()
	session.reputation = 20
	var item := _advance_item(session)
	var location := WorldMapData.get_location_by_id(session.current_location_id)
	var shelf := MarketPricing.get_buy_price(item, location, session.market, session.total_days_elapsed) * 10
	t.ok(session.take_goods_advance(item, 10), "avans alınır")
	t.ok(
		session.get_total_debt() > shelf,
		"deftere ücretiyle yazılır (%d > %d)" % [session.get_total_debt(), shelf]
	)
	t.eq(
		session.get_total_debt(), session.get_loan_principal(shelf),
		"anapara ilan edilen formülle aynı"
	)
	# Kayan nokta artığı kilitleniyor: `200 * 0.1` = 20.000000000000004 idi
	# ve tavana yuvarlanınca 200'lük avans 221 borç yazıyordu. Oyuncunun
	# gördüğü yüzde ile defterdeki tutar birebir tutmalı.
	t.eq(session.get_loan_principal(200), 220, "yüzde 10'luk ücret tam çıkar")
	t.eq(session.get_loan_principal(100), 110, "küçük tutarda da tam çıkar")
	t.eq(session.get_loan_principal(0), 0, "sıfırın ücreti yok")

func _test_loan_fee_scales_with_reputation(t) -> void:
	var untrusted := _session(0, 1)
	untrusted.reputation = 0
	t.eq(
		untrusted.get_loan_fee_percent(), GameSession.LOAN_ORIGINATION_PERCENT_UNTRUSTED,
		"itibarsız kervancı en yüksek ücreti öder"
	)

	var trusted := _session(0, 1)
	trusted.reputation = GameSession.LOAN_FEE_REPUTATION_CAP
	t.eq(
		trusted.get_loan_fee_percent(), GameSession.LOAN_ORIGINATION_PERCENT_TRUSTED,
		"tavan itibarda en düşük ücret"
	)

	var beyond_cap := _session(0, 1)
	beyond_cap.reputation = GameSession.LOAN_FEE_REPUTATION_CAP * 5
	t.eq(
		beyond_cap.get_loan_fee_percent(), trusted.get_loan_fee_percent(),
		"tavanın ötesinde ücret daha da düşmüyor"
	)

	var midpoint := _session(0, 1)
	midpoint.reputation = 20
	t.eq(midpoint.get_loan_fee_percent(), 10, "20 itibar tam eski sabit orana denk geliyor")

func _test_loan_closed_on_the_road_and_without_trust(t) -> void:
	var session := _advance_session()
	session.reputation = GameSession.LOAN_MIN_REPUTATION - 1
	var purse := session.wallet.balance
	t.ne(session.get_advance_block_reason(), "", "itibarsız kervana avans kapalı")
	var item := _advance_item(session)
	t.not_ok(session.take_goods_advance(item, 5), "kapalı avans mal vermez")
	t.eq(session.wallet.balance, purse, "kese değişmedi")

## Avans testlerinin ortak zemini: şehirde duran, kargosu boş bir kervan.
func _advance_session() -> GameSession:
	var session := _session(200, 2)
	for place in WorldMapData.get_locations():
		if not place.produces.is_empty():
			session.current_location_id = place.location_id
			break
	return session

func _advance_item(session: GameSession) -> Item:
	var location := WorldMapData.get_location_by_id(session.current_location_id)
	if location == null:
		return null
	for item_id in location.produces:
		var item := ItemCatalog.get_item(item_id)
		if item != null:
			return item
	return null

# --- Şehrin karar paneli ---
#
# Panel hiçbir mekanik icat etmiyor, oturumun yayımladığı değerleri
# gösteriyor. O yüzden burada sayı değil **bağlantı** doğrulanıyor: bir
# eksiklik varsa karşılığı olan satır çıkıyor mu, ve o satırın düğmesi
# gerçekten o eksikliği çözen ekrana mı gidiyor. Ölü bir uyarı - "erzağın
# az" deyip hiçbir yere götürmeyen bir düğme - kilitli menüyle aynı hayal
# kırıklığı.

func _brief_session(gold: int, provisions: int) -> GameSession:
	var session := GameSession.new(gold, provisions, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var player := CharacterData.create("Kervanbaşı", "gocebe", CharacterStats.new())
	player.is_player = true
	session.start_playthrough(player, rng)
	session.change_provisions(provisions - session.get_provisions())
	return session

## Brifingin ihtiyaç listesi - panel değil model üzerinden (bkz. CityBriefModel).
func _brief_needs(session: GameSession) -> Array[Dictionary]:
	# Model düğümsüz: sahne ağacı ya da Control kurmadan sınanıyor.
	return CityBriefModel.build_needs(session)

func _need_texts(needs: Array[Dictionary]) -> Array[String]:
	var scenes: Array[String] = []
	for need in needs:
		scenes.append(String(need.scene))
	return scenes

func _test_brief_flags_what_the_caravan_lacks(t) -> void:
	var stocked := _brief_session(900, 90)
	var offers := WorldMapData.get_offers_from_origin(stocked.current_location_id)
	if not offers.is_empty():
		stocked.accept_contract(offers[0])
	# U4 (2026-11-07): hazır kervanda liste artık boş değil - acil satır yok
	# ama şehir **bedelli** bir şey öneriyor (boş turu kapatmak için). Kural
	# değişen yer burası: "uyarı yok" demek "yapacak iş yok" demek değil.
	var ready_needs := _brief_needs(stocked)
	t.ok(not ready_needs.is_empty(), "hazır kervana da bir şey önerilir (U4)")
	for need in ready_needs:
		t.not_ok(bool(need.urgent), "hazır kervanda acil uyarı yok: %s" % String(need.text))

	var lacking := _brief_session(40, 2)
	lacking.owned_wagon_damaged = 1
	lacking.party_stress = GameSession.MAX_STRESS
	var scenes := _need_texts(_brief_needs(lacking))
	t.ok(scenes.has(Nav.ECONOMY), "az erzak pazarı gösterir")
	t.ok(scenes.has(Nav.CARAVAN_YARD), "hasarlı vagon avluyu gösterir")
	t.ok(scenes.has(Nav.GUILD), "kontratsızlık loncayı gösterir")
	t.ok(scenes.has(Nav.TAVERN), "yüksek stres tavernayı gösterir")

## Her uyarının düğmesi gerçek bir ekrana gitmeli; şehirden açılamayan bir
## sahneyi göstermek oyuncuyu tam da paneli çözmek için yazdığımız yere
## geri düşürürdü.
func _test_brief_needs_point_at_real_screens(t) -> void:
	var openable: Array[String] = [
		Nav.ECONOMY, Nav.GUILD, Nav.TAVERN, Nav.CARAVAN_YARD, Nav.CHURCH
	]
	var session := _brief_session(0, 0)
	session.owned_wagon_damaged = 1
	session.party_stress = GameSession.MAX_STRESS
	session.spend_or_owe(300)

	var needs := _brief_needs(session)
	t.ok(not needs.is_empty(), "boş kervan için uyarı üretilir")
	for need in needs:
		t.ok(
			openable.has(String(need.scene)),
			"uyarı şehirden açılabilen bir ekrana gider: %s" % String(need.scene)
		)
		t.ok(not String(need.action).strip_edges().is_empty(), "düğme yazısı boş değil")
		t.ok(not String(need.text).strip_edges().is_empty(), "uyarı metni boş değil")

## Vadesi bir ay sonra olan 350 altınlık açık, bu ekranda görünmeliydi ve
## görünmüyordu: yalnızca vade yaklaşınca uyarmak, oyuncuya battığını son
## hafta haber vermek olurdu.
func _test_brief_shows_debt_even_when_the_term_is_far_off(t) -> void:
	var session := _brief_session(900, 90)
	var offers := WorldMapData.get_offers_from_origin(session.current_location_id)
	if not offers.is_empty():
		session.accept_contract(offers[0])
	for need in _brief_needs(session):
		t.not_ok(bool(need.urgent), "borçsuz hazır kervanda acil uyarı yok")

	session.spend_or_owe(session.wallet.balance + 350)
	t.ge(float(session.get_total_debt()), 350.0, "açık hesap doğdu")
	t.ok(
		_need_texts(_brief_needs(session)).has(Nav.GUILD),
		"vadesi uzak olsa da borç panelde görünür"
	)

## Açık her yol için bir satır; kapalı yol gizlenmez, sebebiyle birlikte
## kapalı gösterilir (bkz. Route Rules - kapalı yol çıkmaz sokak değil).
func _test_brief_offers_every_open_route(t) -> void:
	var session := _brief_session(500, 40)
	var panel := CityBriefPanel.new()
	panel.setup(session)

	var routes := WorldMapData.get_routes_from(session.current_location_id)
	t.ok(routes.size() > 0, "başlangıç şehrinden çıkan yol var")

	var buttons := _collect_buttons(panel)
	var route_buttons := 0
	for button in buttons:
		if button.disabled:
			t.ok(not button.text.strip_edges().is_empty(), "kapalı yol sebebiyle yazılır")
		route_buttons += 1
	t.ge(
		float(route_buttons), float(routes.size()),
		"her komşu şehir için bir düğme var"
	)
	panel.free()

func _collect_buttons(node: Node) -> Array[Button]:
	var found: Array[Button] = []
	if node is Button:
		found.append(node)
	for child in node.get_children():
		for button in _collect_buttons(child):
			found.append(button)
	return found

## Fiyat defteri (görev Y-C10): görülen fiyat tarihli ve eskir, söylenti
## bazen yanlış ama aynı gün hep aynı, defter kayıttan döner.
func _test_price_book(t) -> void:
	var session := _brief_session(500, 20)
	var here := session.current_location_id
	t.ok(session.price_book.has(here), "başlangıç şehrinin fiyatı deftere yazılı")
	t.eq(session.get_price_age(here), 0, "bugün görülen fiyat taze")
	t.eq(String(session.price_book[here]["source"]), GameSession.PRICE_SOURCE_SEEN, "kaynak: göz")
	t.not_ok(session.is_price_stale(here), "taze bilgi eskimiş değil")
	var target := WorldMapData.get_routes_from(here)[0].to_location_id
	t.eq(session.get_price_age(target), -1, "komşunun fiyatı bilinmiyor")
	# Gün 0'da "birkaç gün eski" tarih 0'a kenetlenir; söylentinin yaşı ölçülsün diye ilerlet.
	session.total_days_elapsed = GameSession.PRICE_RUMOR_MAX_AGE + 4
	var gold := session.wallet.balance
	t.ok(session.hear_price_rumor(target), "söylenti sohbette duyulur")
	t.eq(session.wallet.balance, gold, "söylenti satılmaz (N34)")
	var age := session.get_price_age(target)
	t.ok(age >= GameSession.PRICE_RUMOR_MIN_AGE and age <= GameSession.PRICE_RUMOR_MAX_AGE, "söylenti birkaç gün eski gelir (%d)" % age)
	t.eq(session.get_price_rumor_block_reason(target), "UI_PRICE_RUMOR_FRESH", "taze bilgi varken yeniden anlatılmaz")
	t.eq(session.get_price_rumor_block_reason(here), "UI_PRICE_RUMOR_INVALID", "bulunulan şehrin söylentisi anlatılmaz")
	session.total_days_elapsed += GameSession.PRICE_STALE_DAYS + 1
	t.ok(session.is_price_stale(here), "%d günden eski bilgi eskimiş" % GameSession.PRICE_STALE_DAYS)
	var stale_line := false
	for line in PriceBookPanel.lines_for(session):
		if bool(line.get("stale", false)):
			stale_line = true
	t.ok(stale_line, "defter ekranı eskimiş satırı işaretler")
	# Yanlış söylenti: ölçülü bir pay, her mal en az %25 sapar; doğrusu birebir.
	var wrong := 0
	var total := 0
	var wrong_far := true
	var right_exact := true
	for day in range(0, 400, 3):
		session.total_days_elapsed = day
		var rumor := session.roll_price_rumor(target)
		var truth := session.current_price_sheet(target)
		total += 1
		if not bool(rumor["accurate"]):
			wrong += 1
		for side in ["buy", "sell"]:
			for item_id in truth[side]:
				var real := float(truth[side][item_id])
				var said := float(rumor[side][item_id])
				if bool(rumor["accurate"]) and int(said) != int(real):
					right_exact = false
				if not bool(rumor["accurate"]) and real >= 8.0 and absf(said - real) / real < 0.2:
					wrong_far = false
		if day == 0:
			t.eq(session.roll_price_rumor(target), rumor, "aynı gün aynı söylenti")
	var share := float(wrong) / float(total)
	t.ok(share > 0.12 and share < 0.40, "söylentilerin bir kısmı yanlış (%.2f)" % share)
	t.ok(wrong_far, "yanlış söylenti fark edilir ölçüde sapar")
	t.ok(right_exact, "doğru söylenti bugünkü fiyatı söyler")
	var copy := GameSession.new(0, 0)
	copy.load_from_dict(JSON.parse_string(JSON.stringify(session.to_save_dict())))
	t.eq(copy.price_book.size(), session.price_book.size(), "defter kayıttan döner")
	t.eq(copy.price_book[target]["source"], GameSession.PRICE_SOURCE_RUMOR, "kaynak kayıttan döner")

## Mal çeşitliliği (görev Y-C19): balık bozulur, kaçak yalnız kervansarayda
## alınır ve gümrükte el konur, nadir mal yalnız şehrin alıcısına, toplu alım
## indirimlidir.
func _first_of(type: String) -> Location:
	for location in WorldMapData.get_locations():
		if location.settlement_type == type:
			return location
	return null

func _test_goods_variety(t) -> void:
	var session := _brief_session(2000, 20)
	var fish := ItemCatalog.get_item("fish")
	t.ok(session.add_to_cargo(fish, 20), "balık yüklenir")
	for day in ItemCatalog.FISH_SHELF_DAYS:
		session.spoil_perishables()
	t.eq(session.get_total_quantity("fish"), 20, "raf ömrü içinde balık çürümez")
	var rotted := session.spoil_perishables()
	t.eq(int(rotted.get("fish", 0)), 5, "ömrü geçince dörtte biri çürür")
	t.eq(session.get_total_quantity("fish"), 15, "çürüyen kargodan düşer")
	session.add_to_cargo(fish, 15)
	session.note_purchase(fish, 15, 5)
	t.ok(float(session.perishable_days["fish"]) < float(ItemCatalog.FISH_SHELF_DAYS), "taze alım yaşı ortalamayla düşürür, sıfırlamaz")
	t.ok(float(session.perishable_days["fish"]) > 0.0, "eski stok tazelenmiş sayılmaz")
	# Tazelik satışa vurur: taze balık tam fiyat, raf ömrünün sonunda taban.
	t.almost(MarketPricing.freshness_multiplier(fish, 0.0), 1.0, "taze balık tam fiyat")
	t.almost(MarketPricing.freshness_multiplier(fish, float(ItemCatalog.FISH_SHELF_DAYS)), MarketPricing.FRESHNESS_FLOOR, "bayat balık tabanda")
	t.ok(MarketPricing.freshness_multiplier(fish, 3.0) < 1.0, "üç günlük balık tazesi gibi satılmaz")
	t.almost(MarketPricing.freshness_multiplier(ItemCatalog.get_item("test_furs"), 30.0), 1.0, "bozulmayan mal yaşlanmaz")
	session.perishable_days["fish"] = float(ItemCatalog.FISH_SHELF_DAYS)
	session.bought_here.erase("fish")
	t.eq(session.capped_sell_price("fish", 100), int(round(100.0 * MarketPricing.FRESHNESS_FLOOR)), "satış fiyatı stoğun yaşını okur")

	var salt := ItemCatalog.get_item(ItemCatalog.CONTRABAND_SALT)
	var city := _first_of(SettlementRules.CITY)
	var serai := _first_of(SettlementRules.CARAVANSERAI)
	t.eq(MarketPricing.buy_block_reason(salt, city), "UI_MARKET_CONTRABAND_NO_SELLER", "şehirde kaçak satılmaz")
	t.eq(MarketPricing.buy_block_reason(salt, serai), "", "kervansarayda kaçak alınır")
	t.eq(MarketPricing.sell_block_reason(salt, serai), "UI_MARKET_CONTRABAND_NO_BUYER", "kaçakçı geri almaz")
	t.ok(MarketPricing.get_sell_price(salt, city) > MarketPricing.get_buy_price(salt, serai) * 2, "kaçak kârı yüksek")
	session.add_to_cargo(salt, 12)
	t.eq(int(session.build_event_context()["contraband"]), 12, "gümrük kaçağı bağlamdan görür")
	var effects: Array[EventEffect] = [EventEffect.make(EventEffect.Type.ITEM_REMOVE, -1, ItemCatalog.CONTRABAND_SALT)]
	EventEffectApplier.apply(effects, session)
	t.eq(session.get_total_quantity(ItemCatalog.CONTRABAND_SALT), 0, "el koyma kaçağın hepsini alır")
	var customs := EventCatalog.get_event("evt_customs_checkpoint")
	var hides := false
	for choice in customs.choices:
		if choice.text_key == "EVT_CUSTOMS_OPT_HIDE":
			hides = not choice.requirements.is_empty()
	t.ok(hides, "gümrükte saklama seçeneği yalnız kaçak varken")

	var relic := ItemCatalog.get_item(ItemCatalog.RARE_RELIC)
	t.eq(MarketPricing.buy_block_reason(relic, city), "UI_MARKET_RARE_NO_SELLER", "nadir mal tezgâhta yok")
	t.eq(MarketPricing.sell_block_reason(relic, city), "", "şehrin koleksiyoncusu alır")
	t.eq(MarketPricing.sell_block_reason(relic, _first_of(SettlementRules.TOWN)), "UI_MARKET_RARE_NO_BUYER", "kasabada alıcısı yok")
	t.not_ok(ItemCatalog.get_trade_goods().has(relic), "nadir mal ticaret listesinde değil")

	t.eq(MarketPricing.bulk_total(10, MarketPricing.BULK_MIN_QUANTITY - 1), 10 * (MarketPricing.BULK_MIN_QUANTITY - 1), "eşiğin altında indirim yok")
	t.ok(MarketPricing.bulk_total(10, MarketPricing.BULK_MIN_QUANTITY) < 10 * MarketPricing.BULK_MIN_QUANTITY, "toplu alım indirimli")

## Sömürü kapısı: bir şehirden alıp aynı ziyarette aynı tezgâha geri satmak,
## her yerde, her malda, her miktarda (toplu indirim dahil) para kaybettirir.
func _test_buy_then_sell_back_never_profits(t) -> void:
	var session := _brief_session(100000, 0)
	var profitable := []
	for location in WorldMapData.get_locations():
		for item in ItemCatalog.get_trade_goods():
			if not MarketPricing.buy_block_reason(item, location).is_empty() or not MarketPricing.sell_block_reason(item, location).is_empty():
				continue
			for quantity in [1, 5, 20, 40]:
				session.market = MarketConditions.new()
				session.bought_here = {}
				session.current_location_id = location.location_id
				var unit := MarketPricing.get_buy_price(item, location, session.market, session.total_days_elapsed)
				var paid := MarketPricing.bulk_total(unit, quantity)
				session.consume_stock(item.item_id, quantity, paid)
				var back: int = session.capped_sell_price(item.item_id, MarketPricing.get_sell_price(item, location, session.market, session.total_days_elapsed)) * quantity
				if back > paid:
					profitable.append("%s/%s/%d" % [location.location_id, item.item_id, quantity])
	t.eq(profitable.size(), 0, "aynı ziyarette al-sat hiçbir yerde kâr etmez %s" % str(profitable.slice(0, 3)))

## En küçük ilanlar itibar eksiye düşse de açık kalır: kötü bir sefer panonun
## tamamını kilitlerse oyuncunun adını düzeltecek işi kalmaz (kariyer ölçümünde
## itibar -20'ye inen kervan bir daha tek kontrat alamadı).
func _test_unrequired_contracts_stay_open_at_bad_reputation(t) -> void:
	var small := MerchantOffer.new()
	small.required_reputation = 0
	t.ok(small.is_open_to(GameSession.MIN_REPUTATION), "eşiksiz ilan en düşük itibarda açık")
	var large := MerchantOffer.new()
	large.required_reputation = 5
	t.ok(not large.is_open_to(4), "eşikli ilan eşiğin altında kapalı")
	t.ok(large.is_open_to(5), "eşikli ilan eşikte açık")


# Y-C27: Gokyurt'ta konseyin sofrası; öbür kervansaraylarda yok.
func _test_gokyurt_hospitality(t) -> void:
	var session := _session()
	session.current_location_id = "serai_orbeyan"
	var before := session.get_provisions()
	var given: int = session._apply_hospitality()
	t.ok(given > 0, "Orbeyan'da misafirlik erzak verir")
	t.eq(session.get_provisions(), before + given, "erzak gerçekten eklendi")
	session.current_location_id = "serai_seyvan"
	t.eq(session._apply_hospitality(), 0, "Seyvan'da misafirlik kalktı")
	session.current_location_id = "vastrevar"
	t.eq(session._apply_hospitality(), 0, "şehirde misafirlik yok")

# Y-C28: kervansarayda söylenti şehirdekinden kolay.
func _test_caravanserai_rumor_bonus(t) -> void:
	var session := _session()
	session.current_location_id = "vastrevar"
	var city := session.get_news_chance_bonus()
	session.current_location_id = "serai_seyvan"
	t.ok(session.is_at_caravanserai(), "Seyvan kervansaray")
	t.ok(session.get_news_chance_bonus() > city, "kervansarayda söylenti payı yüksek")


# Y-C25 (kullanıcı düzeltmesi): veba kendiliğinden gelip gitmez. Nüfus,
# bulaşma ve yollar: tohumdan aynı, yollarla yayılır, ölü sayar, söndükten
# sonra bağışıklık sönünce geri dönebilir; Gokyurt Vadi'den az hastalanır;
# oyuncu yalnızca gördüğünü ve duyduğunu bilir.
func _test_plague_is_a_world_state(t) -> void:
	var a := PlagueWorld.new()
	var b := PlagueWorld.new()
	a.setup(77)
	b.setup(77)
	var sick_days := {}
	var region_days := {"gocebe": 0, "vadi": 0}
	var region_cities := {"gocebe": 0, "vadi": 0}
	for location in WorldMapData.get_locations():
		if region_cities.has(location.region):
			region_cities[location.region] = int(region_cities[location.region]) + 1
	var start_sick := 0
	for id in a.cities:
		if a.sick_share(id) > 0.0:
			start_sick += 1
	t.eq(start_sick, PlagueWorld.SEED_CITIES, "salgın iki şehirde başlıyor")
	for day in 720:
		a.step()
		b.step()
		for location in WorldMapData.get_locations():
			if a.is_sick(location.location_id):
				sick_days[location.location_id] = int(sick_days.get(location.location_id, 0)) + 1
				if region_days.has(location.region):
					region_days[location.region] = int(region_days[location.region]) + 1
	t.eq(a.to_dict(), b.to_dict(), "aynı tohum aynı salgın")
	t.ok(sick_days.size() > PlagueWorld.SEED_CITIES, "veba yollarla başka şehirlere yayıldı (%d şehir)" % sick_days.size())
	var gocebe := float(region_days["gocebe"]) / maxf(1.0, float(region_cities["gocebe"]))
	var vadi := float(region_days["vadi"]) / maxf(1.0, float(region_cities["vadi"]))
	t.ok(vadi > gocebe, "Vadi Gokyurt'tan sık vebalı (şehir başına %.0f / %.0f gün)" % [vadi, gocebe])
	var deaths := 0
	for id in a.cities:
		deaths += a.dead(id)
	t.ok(deaths > 0, "veba ölü sayıyor")
	print("    veba: 720 günde %d yerleşim vebalı oldu, %d ölü; Vadi %.0f, Gokyurt %.0f gün/şehir" % [sick_days.size(), deaths, vadi, gocebe])

	var session := _session()
	session.plague = PlagueWorld.new()
	session.plague.setup(5)
	var target := ""
	for id in session.plague.cities:
		if session.plague.sick_share(id) > 0.0:
			target = id
	session.plague.cities[target]["i"] = 0.2
	t.ok(session.has_plague(target), "vebalı şehir vebalı")
	t.ok(session.plague_news_for(target).is_empty(), "duyulmayan veba bilinmez")
	session.learn_plague(target)
	t.ok(bool(session.plague_news_for(target)["sick"]), "duyulunca bilinir")
	var clean := ""
	for id in session.plague.cities:
		if session.plague.sick_share(id) == 0.0:
			clean = id
			break
	session.plague.carry(target, clean)
	t.ok(session.plague.sick_share(clean) > 0.0, "kervan vebayı vardığı yere taşır")
	var copy := GameSession.new()
	copy.load_from_dict(session.to_save_dict())
	t.eq(copy.plague.to_dict(), session.plague.to_dict(), "salgın kayıttan döner")
	t.eq(copy.plague_news, session.plague_news, "haberler kayıttan döner")


# Y-C35: panodan kafileye yazılan bir sonraki o yöne seferde yavaş ve güvenli
# yürür; hacı kafilesi yalnızca Septisistleri alır; tutulan sürücü arabacı olur.
func _test_convoy_and_driver(t) -> void:
	var session := _session()
	session.wallet.earn(200)
	var dest := WorldMapData.get_routes_from(session.current_location_id)[0].to_location_id
	t.ok(session.join_convoy(dest), "kafileye yazıldı")
	var place := WorldMapData.get_location_by_id(dest)
	var days := 4
	var growth := session.growth_danger()
	session.start_journey(dest, days, 0.5, CaravanPlan.new(place, days))
	t.eq(session.journey_total_days, days + GameSession.CONVOY_EXTRA_DAYS, "kafile bir gün yavaş")
	t.ok(absf(session.danger_level - (0.5 + growth) * GameSession.CONVOY_DANGER) < 0.001, "kafile güvenli")
	t.ok(growth > 0.0, "dolu kese yola duyulur (Y-C24)")
	var pilgrim := _session()
	pilgrim.wallet.earn(200)
	pilgrim.get_player_character().creed = CharacterData.CREED_BAIKHAN
	t.eq(pilgrim.convoy_block_reason(GameSession.HOLY_CITY_ID), "UI_BOARD_CONVOY_SEPTISTS_ONLY", "hacı kafilesi Septisist ister")
	var before := pilgrim.get_duty_multiplier(DutyCatalog.ARABACI)
	t.ok(pilgrim.hire_driver(), "sürücü tutuldu")
	if pilgrim.get_duty_holder(DutyCatalog.ARABACI) == null:
		t.ok(pilgrim.get_duty_multiplier(DutyCatalog.ARABACI) > before, "tutulan sürücü arabacının işini görür")


# Y-C21: kıtlık bölgeye göre (Vadi en ağır, Gokyurt en hafif), kışın ağırlaşır,
# yıllarla artar; stok azalır, yiyecek pahalanır; şehrin morali kıtlıkla düşer,
# getirilen yiyecek ve teslimatla düzelir; aç şehir yiyeceğe çok verir.
func _test_scarcity_and_city_morale(t) -> void:
	t.ok(Scarcity.degree("vadi", 100) > Scarcity.degree("gocebe", 100) + 0.3, "Vadi Gokyurt'tan çok daha kıt")
	t.ok(Scarcity.degree("vadi", Scarcity.WINTER_PEAK_DAY) > Scarcity.degree("vadi", Scarcity.WINTER_PEAK_DAY - 180), "kış yazdan ağır")
	t.ok(Scarcity.degree("dag", 700) > Scarcity.degree("dag", 340), "kıtlık yıllarla ağırlaşır")
	t.ok(Scarcity.stock_left(20, 0.5) < 20, "kıtlıkta stok azalır")
	t.ok(Scarcity.buy_factor("test_grain", 0.5) > Scarcity.buy_factor("silk", 0.5), "yiyecek ötekinden çok pahalanır")
	var session := _session()
	var here := session.current_location_id
	for _d in 60:
		session.advance_day()
	t.ok(absf(session.morale_of(here) - session.morale_target(here)) < 2.5, "moral şehrin hâline doğru kayar")
	session.city_morale[here] = 10.0
	var hungry_price := session.capped_sell_price("test_grain", 100)
	session.city_morale[here] = 90.0
	t.ok(hungry_price > session.capped_sell_price("test_grain", 100), "aç şehir yiyeceğe çok verir")
	session.city_morale[here] = 10.0
	session.record_sale("test_grain", 20)
	t.ok(session.morale_of(here) > 10.0, "getirilen yiyecek şehrin hâlini düzeltir")
	var copy := GameSession.new()
	copy.load_from_dict(session.to_save_dict())
	t.eq(copy.morale_of(here), session.morale_of(here), "moral kayıttan döner")


# Y-C29: Duvenmor yasağı kayıtta durur.
func _test_ban_survives_save(t) -> void:
	var session := _session()
	session.ban_location("serai_duvenmor")
	var copy := GameSession.new()
	copy.load_from_dict(session.to_save_dict())
	t.ok(copy.is_banned("serai_duvenmor"), "yasak kayıttan döner")
	t.ok(not copy.is_banned("serai_seyvan"), "yasak yalnızca o yere")

## §H adım 4: bir iz `yuz` olarak döndüğünde şehir brifingi bunu söyler.
## Şehir, yolun bedelinin tahsil edildiği yer olmalı; "yapacak iş yok" turu
## (teşhis A5) geçmişin kendisiyle kapanıyor.
func _test_brief_says_someone_is_waiting(t) -> void:
	var session := _brief_session(900, 90)
	session.note_trace_action("sinama")
	var trace: Trace = session.leave_trace(
		Trace.TYPE_GRUDGE, Trace.BEARER_CITY, session.current_location_id, -1,
		Trace.DELAY_SHORT, Trace.RETURN_FACE)
	trace.olgunluk_gunu = session.total_days_elapsed
	t.ok(not session.resolve_trace_return().is_empty(), "yüz dönüşü işlendi")
	var person := session.people.person(String(session.waiting_face["kisi"]))
	var found := false
	for need in _brief_needs(session):
		if String(need.get("text", "")).contains(String(person.get("name", ""))):
			found = true
	t.ok(found, "şehir özeti bekleyeni adıyla söylüyor")

	# Açık hesaplar sayfası aynı hesabı yazıyor ve karşılığının geldiğini
	# yanına ekliyor - üstünü çizmeden.
	var rows := LedgerPage.account_rows(session)
	t.eq(rows.size(), 1, "açık hesaplar sayfasında bir satır var")
	t.ok(String(rows[0].get("note", "")).length() > 0, "satırın karşılığı yazılı")
	t.ok(bool(rows[0].get("bad", false)), "kin satırı kızıl okunur")
