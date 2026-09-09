extends RefCounted

## Borç, oyunun "kervan yok olmaz ama sürünür" kuralının parasal ayağı.
## En kritik iki şey: açık hesap ile kesenin eksi bakiyesi asla ayrışmamalı
## (aynı para iki kez sayılırsa oyuncu olmayan bir borç görür) ve gecikme
## faizi aynı dönem için iki kez işlememeli.

func suite_name() -> String:
	return "Debt"

func run(t) -> void:
	_test_overdraft_mirrors_wallet(t)
	_test_optional_purchases_never_create_debt(t)
	_test_borrowing_has_a_month_term(t)
	_test_overdue_interest_applies_once_per_period(t)
	_test_overdue_costs_reputation_through_advance_day(t)
	_test_restructure_extends_and_costs_more_each_time(t)
	_test_repay_only_spends_what_you_have(t)
	_test_save_round_trip(t)

func _session(gold: int = 100) -> GameSession:
	return GameSession.new(gold, 10, 1)

func _test_overdraft_mirrors_wallet(t) -> void:
	var session := _session(100)
	t.not_ok(session.debts.has_debt(), "borçsuz başlanır")

	session.spend_or_owe(250)
	t.eq(session.wallet.balance, -150, "zorunlu ödeme keseyi eksiye düşürür")
	t.eq(session.get_total_debt(), 150, "eksi bakiye borç olarak görünür")

	# Daha da batmak açık hesabı büyütür, ikinci bir hesap açmaz.
	session.spend_or_owe(100)
	t.eq(session.wallet.balance, -250, "borç üstüne borç kesede birikir")
	t.eq(session.debts.get_debts().size(), 1, "tek açık hesap tutulur")
	t.eq(session.get_total_debt(), 250, "borç kesenin eksisiyle aynı")

	# Kısmi ödeme: kese hâlâ eksi ama borç küçüldü.
	session.wallet.earn(100)
	t.eq(session.wallet.balance, -150, "kazanç eksiyi azaltır")
	t.eq(session.get_total_debt(), 150, "açık hesap keseyle birlikte küçülür")

	# Artıya geçince açık hesap tamamen kapanmalı - burada ayrışsalardı
	# oyuncu ödediği borcu defterde görmeye devam ederdi.
	session.wallet.earn(400)
	t.eq(session.wallet.balance, 250, "kese artıya geçer")
	t.eq(session.get_total_debt(), 0, "artıya geçince açık hesap kapanır")
	t.not_ok(session.debts.has_debt(), "defterde kapanmış borç durmaz")

## İsteğe bağlı alışveriş borç yaratmaz: oyuncu kendi isteğiyle batmaz,
## onu olaylar batırır (bkz. Wallet.spend / force_spend ayrımı).
func _test_optional_purchases_never_create_debt(t) -> void:
	var session := _session(50)
	t.not_ok(session.wallet.spend(200), "parası yetmeyen alışveriş gerçekleşmez")
	t.eq(session.wallet.balance, 50, "başarısız alışveriş keseye dokunmaz")
	t.eq(session.get_total_debt(), 0, "isteğe bağlı alışveriş borç açmaz")

func _test_borrowing_has_a_month_term(t) -> void:
	var session := _session(0)
	var debt := session.debts.borrow("Tefeci", 500, session.total_days_elapsed)

	t.ok(debt != null, "borç alınabilir")
	t.eq(debt.principal, 500, "anapara alınan tutar")
	t.eq(debt.due_day, Debt.DEFAULT_TERM_DAYS, "vade bir ay")
	t.eq(session.get_total_debt(), 500, "alınan borç deftere girer")
	t.eq(
		session.debts.get_soonest_due_in_days(0), Debt.DEFAULT_TERM_DAYS,
		"en yakın vade doğru hesaplanır"
	)
	t.not_ok(debt.is_overdue(Debt.DEFAULT_TERM_DAYS), "vade günü henüz gecikme değil")
	t.ok(debt.is_overdue(Debt.DEFAULT_TERM_DAYS + 1), "vadeden sonrası gecikme")

	t.eq(session.debts.borrow("Tefeci", 0, 0), null, "sıfır tutarlı borç açılmaz")

func _test_overdue_interest_applies_once_per_period(t) -> void:
	var debt := Debt.create("d1", "Tefeci", 1000, 30)

	t.eq(debt.apply_overdue_interest(30), 0, "vadesi gelmemiş borca faiz işlemez")
	t.eq(debt.principal, 1000, "anapara değişmedi")

	# İlk gecikme dönemi
	t.eq(debt.apply_overdue_interest(31), 1, "gecikmenin ilk dönemi işler")
	t.eq(debt.principal, 1150, "anaparaya %15 faiz bindi")

	# Aynı dönemde tekrar çağırmak ikinci kez faiz bindirmemeli - günlük
	# döngü her gün çağırıyor, burası kaçarsa borç günde bir katlanırdı.
	t.eq(debt.apply_overdue_interest(35), 0, "aynı dönem ikinci kez işlemez")
	t.eq(debt.principal, 1150, "anapara aynı kaldı")

	# Bir sonraki dönem
	t.eq(debt.apply_overdue_interest(41), 1, "sonraki dönem işler")
	t.ok(debt.principal > 1150, "anapara yine büyüdü")

	# Uzun süre bakılmazsa atlanan dönemlerin hepsi işlemeli.
	var neglected := Debt.create("d2", "Tefeci", 1000, 30)
	t.eq(neglected.apply_overdue_interest(61), 4, "atlanan dönemlerin hepsi işler")

func _test_overdue_costs_reputation_through_advance_day(t) -> void:
	var session := _session(100)
	session.debts.borrow("Tefeci", 300, 0)
	var before := session.reputation

	for _day in Debt.DEFAULT_TERM_DAYS:
		session.advance_day()
	t.eq(session.reputation, before, "vade dolmadan itibar kaybı yok")

	session.advance_day()
	t.eq(
		session.reputation, before - Debt.OVERDUE_REPUTATION_PENALTY,
		"vade geçince itibar düşer"
	)

	# Ertesi gün aynı dönem için tekrar ceza kesilmemeli.
	session.advance_day()
	t.eq(
		session.reputation, before - Debt.OVERDUE_REPUTATION_PENALTY,
		"aynı gecikme dönemi iki kez cezalandırılmaz"
	)

func _test_restructure_extends_and_costs_more_each_time(t) -> void:
	var session := _session(0)
	var debt := session.debts.borrow("Tefeci", 1000, 0)

	var first_fee := debt.get_restructure_fee()
	t.ok(first_fee > 0, "yapılandırmanın bir bedeli var")
	t.ok(session.debts.restructure(debt.debt_id, 40), "vadesi geçmiş borç yapılandırılabilir")
	t.eq(debt.principal, 1000 + first_fee, "bedel anaparaya biner")
	t.eq(debt.due_day, 40 + Debt.RESTRUCTURE_TERM_DAYS, "vade uzar")
	t.not_ok(debt.is_overdue(41), "yapılandırılan borç artık gecikmiş değil")

	# İkinci yapılandırma daha pahalı olmalı - sonsuza kadar ertelemek
	# ucuz bir kaçış yolu olmamalı.
	var second_fee := debt.get_restructure_fee()
	t.ok(
		float(second_fee) / float(debt.principal) > float(first_fee) / 1000.0,
		"her yapılandırmada oran artar"
	)

	t.not_ok(session.debts.restructure("yok_boyle_borc", 10), "olmayan borç yapılandırılamaz")

func _test_repay_only_spends_what_you_have(t) -> void:
	var session := _session(200)
	var debt := session.debts.borrow("Tefeci", 500, 0)

	# Kesede olandan fazlası ödenemez.
	t.eq(session.repay_debt(debt.debt_id, 500), 200, "yalnızca kesedeki kadarı ödenir")
	t.eq(session.wallet.balance, 0, "ödenen para keseden çıkar")
	t.eq(session.get_total_debt(), 300, "borç ödenen kadar azalır")

	# Parasızken ödeme denemesi hiçbir şeyi değiştirmemeli.
	t.eq(session.repay_debt(debt.debt_id, 100), 0, "parasızken ödeme yapılamaz")
	t.eq(session.get_total_debt(), 300, "borç olduğu gibi kalır")

	# Borçtan fazlası istenmez.
	session.wallet.earn(1000)
	t.eq(session.repay_debt(debt.debt_id, 999), 300, "borçtan fazlası tahsil edilmez")
	t.eq(session.get_total_debt(), 0, "borç kapandı")
	t.not_ok(session.debts.has_debt(), "kapanan borç defterden düşer")

func _test_save_round_trip(t) -> void:
	var session := _session(100)
	session.debts.borrow("Tefeci", 400, 0)
	session.debts.borrow("Lonca", 250, 0)
	session.spend_or_owe(300)

	var saved := session.to_save_dict()
	t.eq(int(saved["gold"]), -200, "eksi kese kaydedilir")

	var restored := GameSession.new(0, 0, 1)
	restored.load_from_dict(saved)

	t.eq(restored.wallet.balance, -200, "eksi kese kayıttan aynen döner")
	t.eq(restored.get_total_debt(), session.get_total_debt(), "toplam borç korunur")
	t.eq(restored.debts.get_debts().size(), 3, "üç borç da döner (açık hesap dahil)")

	var loan := restored.debts.get_debt("loan_1")
	t.ok(loan != null, "alınan borç kimliğiyle döner")
	t.eq(loan.creditor_name, "Tefeci", "alacaklı korunur")

	# Kayıttan dönen defter, var olan kimliklerin üstüne yazmamalı.
	var fresh := restored.debts.borrow("Yeni", 100, 0)
	t.ok(
		restored.debts.get_debt("loan_1").principal == 400,
		"yeni borç eskisinin üstüne yazmaz"
	)
	t.ok(fresh.debt_id != "loan_1", "yeni borç yeni bir kimlik alır")
