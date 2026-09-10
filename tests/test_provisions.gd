extends RefCounted

## Erzak testleri. Buradaki iki kural birlikte tutulmazsa oyun oyuncuya
## yalan söyler:
##
## 1. Planlayıcının "gereken erzak" dediği miktar, yolun gerçekten yiyeceği
##    miktar olmalı. Üç ayrı kopya vardı (plan, yol, simülatör) ve üçü de
##    farklı hesaplıyordu.
## 2. Açlık "kese sıfırlandı" değil "bugün besleyemedik" demeli. Eski koşul
##    `get_provisions() <= 0` idi: doğru stoklayan oyuncu son gün tam sıfıra
##    iniyor ve cezayı yiyordu - her seferde.

const JOURNEY_LENGTHS: Array[int] = [1, 2, 3, 5, 8, 13]

func suite_name() -> String:
	return "Provisions"

func run(t) -> void:
	_test_plan_and_road_agree(t)
	_test_correct_stocking_never_starves(t)
	_test_empty_stores_do_starve(t)
	_test_mouths_scale_with_the_caravan(t)
	_test_perks_reach_the_planner(t)
	_test_consumption_never_free(t)

## Planın istediği = yolun yediği. İkisi ayrı formüllerken planlayıcı
## yalnızca tüccarları sayıyor, yol levazımcıyı da düşüyordu.
func _test_plan_and_road_agree(t) -> void:
	for party_size in [1, 2, 4]:
		for wagons in [1, 3, 6]:
			for merchants in [0, 2]:
				var session := _session(party_size, wagons, merchants)
				var plan := _plan(session, 4, merchants)
				t.eq(
					plan.get_daily_consumption(),
					session.get_daily_provision_consumption(),
					"plan ve yol aynı günlük tüketimi söyler (%d kişi, %d vagon, %d tüccar)" % [
						party_size, wagons, merchants
					]
				)

## Asıl hata: gereken kadar erzak alan oyuncu son gün açlık cezası yiyordu.
func _test_correct_stocking_never_starves(t) -> void:
	for days in JOURNEY_LENGTHS:
		for merchants in [0, 1, 3]:
			var session := _session(2, 2, merchants)
			var plan := _plan(session, days, merchants)

			session.change_provisions(-session.get_provisions())
			session.change_provisions(plan.get_required_provisions())

			var starved_days := _walk(session, days)
			t.eq(
				starved_days, 0,
				"tam stoklanan %d günlük sefer aç kalmaz (%d tüccar)" % [days, merchants]
			)

## Ama gerçekten bittiğinde açlık işlemeli - yoksa bu sefer de ceza ölürdü.
func _test_empty_stores_do_starve(t) -> void:
	var session := _session(2, 2, 1)
	var daily := session.get_daily_provision_consumption()

	# Tam iki günlük erzakla beş günlük yola çık: üç gün aç kalınmalı.
	session.change_provisions(-session.get_provisions())
	session.change_provisions(daily * 2)
	t.eq(_walk(session, 5), 3, "erzak bitince kalan her gün açlık sayılır")

	# Bir günlük eksik stok da açlıktır: kimse yarım karınla beslenmez.
	var tight := _session(2, 2, 1)
	tight.change_provisions(-tight.get_provisions())
	tight.change_provisions(tight.get_daily_provision_consumption() - 1)
	t.eq(_walk(tight, 1), 1, "bir birim eksik stok bile açlıktır")

## Beslenen ağızlar kervanın gerçek halini yansıtmalı: eskiden 4 kişilik
## bir parti ve 12 tayfa, tek başına yürüyen bir adamla aynı erzağı yiyordu.
func _test_mouths_scale_with_the_caravan(t) -> void:
	var lone := _session(1, 1, 0)
	var full := _session(4, 6, 3)
	t.ok(
		full.get_daily_provision_consumption() > lone.get_daily_provision_consumption(),
		"büyük kervan küçük kervandan çok yer"
	)

	# Ağız sayımı ham formülden okunuyor: kültür çarpanı araya girdiğinde
	# fark yuvarlanmayla ezilir (Göçebe 0.7 yer), o yüzden çarpansız hâl.
	t.eq(
		CaravanPlan.daily_consumption(2, 2, 0) - CaravanPlan.daily_consumption(2, 1, 0),
		GameSession.PEOPLE_PER_WAGON,
		"her vagon PEOPLE_PER_WAGON kadar ağız getirir"
	)
	t.eq(
		CaravanPlan.daily_consumption(2, 2, 2) - CaravanPlan.daily_consumption(2, 2, 0),
		2,
		"her tüccar bir ağızdır"
	)
	t.eq(
		CaravanPlan.daily_consumption(4, 2, 0) - CaravanPlan.daily_consumption(2, 2, 0),
		2,
		"her parti üyesi bir ağızdır"
	)

## Kültür perki ve levazımcı indirimi planlayıcıya de ulaşmalı, yoksa
## planlayıcı yolda yenmeyecek bir sayı gösterir.
func _test_perks_reach_the_planner(t) -> void:
	var thrifty := CaravanPlan.daily_consumption(2, 2, 1, 0.5, 0)
	var normal := CaravanPlan.daily_consumption(2, 2, 1, 1.0, 0)
	t.ok(thrifty < normal, "az yiyen kültür planda da az yer")

	var with_quartermaster := CaravanPlan.daily_consumption(2, 2, 1, 1.0, 2)
	t.ok(with_quartermaster < normal, "levazımcı planda da tasarruf ettirir")

## Hiçbir kervan bedavaya yürümez - çarpan ve indirim ne olursa olsun.
func _test_consumption_never_free(t) -> void:
	t.ge(
		float(CaravanPlan.daily_consumption(1, 1, 0, 0.0, 99)), 1.0,
		"tüketim hiçbir zaman sıfıra inmez"
	)
	t.ge(
		float(CaravanPlan.daily_consumption(-5, -5, -5, -1.0, -1)), 1.0,
		"saçma girdiler bile en az bir birim yer"
	)

## Seferi gün gün yürütür ve kaç gün aç kalındığını döner - yol ekranının
## _advance_contracts_and_provisions()'ıyla aynı sıra.
func _walk(session: GameSession, days: int) -> int:
	var starved_days := 0
	for _day in days:
		var daily := session.get_daily_provision_consumption()
		var fed := -session.change_provisions(-daily)
		if fed < daily:
			starved_days += 1
	return starved_days

func _session(party_size: int, wagons: int, merchants: int) -> GameSession:
	var session := GameSession.new(500, 0, wagons)
	session.party.clear()
	for index in party_size:
		var character := CharacterData.create(
			"Yoldaş %d" % index, CultureCatalog.NOMAD, CharacterStats.new()
		)
		character.is_player = index == 0
		session.party.append(character)

	var names: Array[String] = []
	for index in merchants:
		names.append("Tüccar %d" % index)
	session.caravan.merchant_names = names
	return session

func _plan(session: GameSession, days: int, merchants: int) -> CaravanPlan:
	# Vagon tavanı kervanın kendi vagonları + tüccarlara yetecek kadar:
	# DEFAULT_MAX_WAGONS ile altı vagonlu bir kervanda tüccara hiç yer
	# kalmıyor ve plan ile oturum farklı tüccar sayısı taşıyor.
	var plan := CaravanPlan.new(
		null, days, session.owned_wagon_count + maxi(0, merchants), session.owned_wagon_count
	)
	plan.caravan_party_size = session.get_party().size()
	plan.provision_multiplier = session.get_daily_provision_multiplier()
	plan.provision_reduction = session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI)
	for index in merchants:
		var offer := MerchantOffer.new()
		offer.merchant_id = "sim_%d" % index
		offer.wagon_count = 1
		plan.toggle_merchant(offer)
	return plan
