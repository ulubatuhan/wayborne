extends RefCounted

## Şehirde yapılan iki yeni para hamlesi: vagon satmak ve loncadan borç
## almak. İkisi de kervanın kalıcı durumunu değiştiriyor, yani ikisi de
## sömürüye açık - o yüzden burada formülden çok **sömürünün kapalı
## olduğu** doğrulanıyor (bkz. test_haggling.gd'nin aynı yaklaşımı).
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
	_test_wagon_sale_never_returns_its_cost(t)
	_test_selling_never_takes_the_last_wagon(t)
	_test_repair_always_beats_sell_and_rebuy(t)
	_test_sale_blocked_with_a_reason_not_hidden(t)
	_test_damaged_wagon_goes_first(t)
	_test_credit_line_scales_with_reputation(t)
	_test_debt_consumes_the_credit_line(t)
	_test_borrowing_to_clear_an_overdraft_is_not_free(t)
	_test_loan_costs_more_than_it_pays(t)
	_test_loan_closed_on_the_road_and_without_trust(t)

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
	var session := _session(100, 1)
	var limit := session.get_credit_limit()
	t.eq(session.get_available_credit(), limit, "borçsuzken hattın tamamı açık")

	var taken := GameSession.LOAN_STEP * 2
	t.ok(session.borrow_from_guild(taken), "krediden bir dilim alınır")
	t.eq(
		session.get_available_credit(),
		maxi(0, limit - session.get_total_debt()),
		"kalan hat borcun tamamını düşer"
	)
	t.ok(
		session.get_available_credit() < limit - taken + 1,
		"tahsis ücreti de hattan yer"
	)

	# Hat dolana kadar al; sonrası kapalı olmalı.
	var guard := 0
	while session.can_borrow(GameSession.LOAN_MIN_AMOUNT) and guard < 200:
		session.borrow_from_guild(GameSession.LOAN_MIN_AMOUNT)
		guard += 1
	t.ok(guard < 200, "kredi hattı sonsuz değil")
	t.not_ok(session.can_borrow(GameSession.LOAN_MIN_AMOUNT), "dolu hattan borç alınamaz")

## En keskin kaçamak: açık hesabın vadesi ilk eksiye düşüşte kurulur.
## Borçla kapatmak onu bedava bir yapılandırmaya çevirirdi - oysa
## yapılandırmanın ücreti var ve her seferinde artıyor.
func _test_borrowing_to_clear_an_overdraft_is_not_free(t) -> void:
	var session := _session(0, 1)
	session.reputation = 20
	session.spend_or_owe(100)
	t.eq(session.get_total_debt(), 100, "açık hesap doğdu")

	var before := session.get_total_debt()
	t.ok(session.borrow_from_guild(100), "açığı kapatacak kadar borç alınır")
	t.eq(session.wallet.balance, 0, "kese sıfırlandı")
	t.ok(
		session.get_total_debt() > before,
		"borç azalmadı, ücret kadar arttı (%d → %d)" % [before, session.get_total_debt()]
	)

	# Ve hat da bu kadar tükendi: aynı numara tekrar tekrar çekilemez.
	t.le(
		float(session.get_available_credit()),
		float(session.get_credit_limit() - session.get_total_debt() + 1),
		"kapanan açık hesabın yerini kredi aldı, hat boşalmadı"
	)

func _test_loan_costs_more_than_it_pays(t) -> void:
	var session := _session(0, 1)
	session.reputation = 20
	var amount := GameSession.LOAN_STEP * 4
	t.ok(session.borrow_from_guild(amount), "borç alınır")
	t.eq(session.wallet.balance, amount, "keseye tam istenen tutar girer")
	t.ok(
		session.get_total_debt() > amount,
		"deftere ücretiyle birlikte yazılır (%d > %d)" % [session.get_total_debt(), amount]
	)
	t.eq(
		session.get_total_debt(), session.get_loan_principal(amount),
		"anapara ilan edilen formülle aynı"
	)

	# Kayan nokta artığı kilitleniyor: `200 * 0.1` = 20.000000000000004 idi
	# ve tavana yuvarlanınca 200'lük kredi 221 borç yazıyordu. Oyuncunun
	# gördüğü yüzde ile defterdeki tutar birebir tutmalı.
	t.eq(session.get_loan_principal(200), 220, "yüzde 10'luk ücret tam çıkar")
	t.eq(session.get_loan_principal(100), 110, "küçük tutarda da tam çıkar")
	t.eq(session.get_loan_principal(0), 0, "sıfırın ücreti yok")

func _test_loan_closed_on_the_road_and_without_trust(t) -> void:
	var session := _session(200, 1)
	session.reputation = GameSession.LOAN_MIN_REPUTATION - 1
	t.ne(session.get_loan_block_reason(), "", "itibarsız kervana kredi kapalı")
	t.not_ok(session.borrow_from_guild(GameSession.LOAN_MIN_AMOUNT), "kapalı kredi para vermez")
	t.eq(session.wallet.balance, 200, "kese değişmedi")
