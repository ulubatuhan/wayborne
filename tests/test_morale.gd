extends RefCounted

## Moral, uzun süre ölü bir stattı: her seferde 100'den başlıyor, yalnızca
## kesikli olay darbeleriyle düşüyor ve isyan eşiğine (evt_mutiny) hiç
## inmiyordu. Üstelik bu fark edilmedi çünkü simülatör morali
## finish_journey()'den *sonra* okuyordu - kervan o sırada zaten
## sıfırlanmış oluyordu (bkz. CLAUDE.md Morale Rules).
##
## Bu paket üç şeyi kilitliyor: yolun kendisi yıpratır, çıkış morali
## dünyanın haline bağlıdır, ve ikisi birden isyan eşiğini *ulaşılabilir*
## kılar - ama yalnızca yürümekle değil.

func suite_name() -> String:
	return "Morale"

func run(t) -> void:
	_test_daily_drift(t)
	_test_drift_only_on_the_road(t)
	_test_departure_morale_reflects_the_world(t)
	_test_departure_morale_has_a_floor(t)
	_test_breakdown_explains_the_number(t)
	_test_mutiny_threshold_is_reachable(t)
	_test_start_journey_uses_departure_morale(t)

func _plan() -> CaravanPlan:
	return CaravanPlan.new(WorldMapData.get_location_by_id("test_loc_b"), 5)

## Yolda geçen her günün bedeli var - ama yalnızca yürümek kervanı isyana
## sürüklemesin diye bir tabanda duruyor.
func _test_daily_drift(t) -> void:
	var caravan := CaravanState.new()
	t.eq(caravan.morale, CaravanState.MAX_MORALE, "kervan dolu moralle kurulur")

	caravan.apply_daily_drift()
	t.eq(
		caravan.morale, CaravanState.MAX_MORALE - CaravanState.MORALE_DRAIN_PER_DAY,
		"her gün moralden bir parça götürür"
	)

	for _day in 200:
		caravan.apply_daily_drift()
	t.eq(
		caravan.morale, CaravanState.MORALE_DRIFT_FLOOR,
		"aşınma tabanda durur - yürümek tek başına isyan çıkarmaz"
	)

	# Tabanın altındaki bir morali aşınma daha da düşürmemeli.
	caravan.morale = 10
	caravan.apply_daily_drift()
	t.eq(caravan.morale, 10, "taban altındaki morale aşınma dokunmaz")

func _test_drift_only_on_the_road(t) -> void:
	var session := GameSession.new(300, 60)
	var before := session.caravan.morale
	session.advance_day()
	t.eq(session.caravan.morale, before, "şehirdeyken gün geçmesi morali yemez")

	session.start_journey("test_loc_b", 5, 0.2, _plan())
	var on_the_road := session.caravan.morale
	session.advance_day()
	t.ok(session.caravan.morale < on_the_road, "yoldayken her gün moral aşınır")

## "Sefere hangi ruh haliyle çıkıyoruz" sorusu artık dünyaya bağlı: bolluk
## ve darlık, kadronun yorgunluğu, alacaklılar ve kervanın itibarı.
func _test_departure_morale_reflects_the_world(t) -> void:
	var calm := GameSession.new(500, 60)
	var calm_morale := calm.get_departure_morale()
	t.eq(
		calm_morale, CaravanState.MAX_MORALE,
		"iyi bir günde, borçsuz ve dinç kadro dolu moralle yola çıkar"
	)

	# Darlık: şehirde fiyatları uçuran bir şok (kıtlık/ambargo/grev).
	var famine := GameSession.new(500, 60)
	famine.market.add_shock(famine.current_location_id, "", 2.0, 60)
	t.ok(
		famine.get_departure_morale() < calm_morale,
		"kıtlık kol gezen bir şehirde kadro daha kötü moralle çıkar"
	)

	# Yorgunluk: kalıcı stres çıkış moralini indirir ama stres ayrı stat
	# olmaya devam eder (bkz. CLAUDE.md Stress Rules).
	var tired := GameSession.new(500, 60)
	tired.change_stress(GameSession.MAX_STRESS)
	t.ok(tired.get_departure_morale() < calm_morale, "yorgun kadro düşük moralle çıkar")
	t.eq(tired.party_stress, GameSession.MAX_STRESS, "çıkış morali stresi tüketmez")

	# Alacaklılar: vadesi geçmiş borç moralı yer.
	var indebted := GameSession.new(500, 60)
	indebted.total_days_elapsed = 200
	indebted.debts.add_debt(Debt.create(
		"test_creditor", "CREDITOR_TEST", 300, 10, Debt.SOURCE_LOAN
	))
	t.ok(
		indebted.get_departure_morale() < calm_morale,
		"vadesi geçmiş borç kadroyu tedirgin eder"
	)

	# İtibar tersine çalışır - ama tavanı aşamaz.
	var famous := GameSession.new(500, 60)
	famous.reputation = 100
	famous.change_stress(GameSession.MAX_STRESS)
	var unknown := GameSession.new(500, 60)
	unknown.change_stress(GameSession.MAX_STRESS)
	t.ok(
		famous.get_departure_morale() > unknown.get_departure_morale(),
		"tanınan bir kervanın kadrosu aynı yorgunlukta bile daha diri"
	)
	t.le(
		famous.get_departure_morale(), CaravanState.MAX_MORALE,
		"itibar tavanı aşamaz"
	)

## Kervan umutsuz başlamaz: dünya ne kadar kötü olursa olsun bir taban var.
func _test_departure_morale_has_a_floor(t) -> void:
	var wretched := GameSession.new(0, 0)
	wretched.total_days_elapsed = 9999
	wretched.change_stress(GameSession.MAX_STRESS)
	wretched.market.add_shock(wretched.current_location_id, "", MarketConditions.SHOCK_LIMIT, 99999)
	wretched.debts.add_debt(Debt.create(
		"test_creditor", "CREDITOR_TEST", 5000, 1, Debt.SOURCE_LOAN
	))
	var morale := wretched.get_departure_morale()
	t.ok(
		morale >= GameSession.DEPARTURE_MORALE_FLOOR,
		"en kötü dünyada bile çıkış morali tabanın altına inmez"
	)
	t.ok(morale < CaravanState.MAX_MORALE, "ama dolu da değil")

## Rakam görünüyorsa nedeni de görünmeli - yoksa mekanik sessiz bir ceza olur.
func _test_breakdown_explains_the_number(t) -> void:
	var calm := GameSession.new(500, 60)
	t.eq(
		calm.get_departure_morale_breakdown().size(), 0,
		"iyi bir günde gösterilecek gerekçe yok"
	)

	var strained := GameSession.new(500, 60)
	strained.change_stress(40)
	var breakdown := strained.get_departure_morale_breakdown()
	t.ok(breakdown.size() > 0, "moral düşükse gerekçesi listelenir")

	var total := 0
	for entry in breakdown:
		var line: Dictionary = entry
		t.ok(not String(line["key"]).is_empty(), "her gerekçenin çeviri anahtarı var")
		total += int(line["amount"])
	t.eq(
		strained.get_departure_morale(), CaravanState.MAX_MORALE + total,
		"gerekçelerin toplamı gösterilen rakamı verir"
	)

## Paketin asıl iddiası: isyan eşiği artık ulaşılabilir - ama yalnızca
## yürümekle değil, işler gerçekten kötü gittiğinde.
func _test_mutiny_threshold_is_reachable(t) -> void:
	t.ok(
		EventCatalog.MUTINY_MORALE_THRESHOLD > CaravanState.MORALE_DRIFT_FLOOR,
		"eşik aşınma tabanının üstünde - yoksa her uzun sefer isyanla biterdi"
	)

	# Kötü bir dünyadan çıkan kervan, uzun bir yolda eşiğe inebilmeli.
	var grim := GameSession.new(200, 200)
	grim.change_stress(GameSession.MAX_STRESS)
	grim.market.add_shock(grim.current_location_id, "", 2.0, 400)
	grim.start_journey("test_loc_b", 20, 0.6, _plan())
	for _day in 20:
		grim.advance_day()
	t.ok(
		grim.caravan.morale <= EventCatalog.MUTINY_MORALE_THRESHOLD,
		"kötü koşullarda uzun bir sefer isyan eşiğine iner"
	)

	# İyi bir dünyadan çıkan kısa sefer inmemeli.
	var good := GameSession.new(500, 200)
	good.start_journey("test_loc_b", 5, 0.2, _plan())
	for _day in 5:
		good.advance_day()
	t.ok(
		good.caravan.morale > EventCatalog.MUTINY_MORALE_THRESHOLD,
		"iyi koşullarda kısa bir sefer isyan eşiğine inmez"
	)

func _test_start_journey_uses_departure_morale(t) -> void:
	var session := GameSession.new(500, 60)
	session.change_stress(GameSession.MAX_STRESS)
	var expected := session.get_departure_morale()
	session.start_journey("test_loc_b", 5, 0.2, _plan())
	t.eq(session.caravan.morale, expected, "sefer hesaplanan moralle başlar")
	t.ok(session.caravan.morale < CaravanState.MAX_MORALE, "ve bu dolu moral değil")

	# Katmanı bilmeyen bir çağıran eski davranışı görmeli.
	var plain := CaravanState.from_plan(_plan())
	t.eq(
		plain.morale, CaravanState.MAX_MORALE,
		"moral verilmezse from_plan eski davranışı korur"
	)
