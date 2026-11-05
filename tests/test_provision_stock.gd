extends RefCounted

## Erzağın şehirdeki stoğu (P5) ve "doğru stoklayan asla aç kalmaz" sözünün
## yeni hâli (P9/B, kullanıcı kararı 2026-11-05).
##
## Değişen şey sözün kendisi değil **anlamı**: planlayıcı doğru sayıyı
## söylemeye devam ediyor (`test_route_terrain` o iddiayı koruyor - yeterli
## erzakla çıkan kervan hiç aç kalmıyor), ama o sayı artık her şehirde
## **bulunmayabilir**. Açlığın kapısı para değil arz.
##
## Bu paket üç şeyi tutuyor:
## 1. Raf hesaplanır, saklanmaz: aynı şehrin aynı günü hep aynı sayı.
## 2. Kıtlık rafı yer; bolluk bölgesinde raf, kıtlık bölgesinden dolu.
## 3. Oyuncunun o gün aldığı **kayda yazılır**: şehirde kaydedip yükleyerek
##    raf tazelenemez (kayıt zaten şehirde alınıyor).

func suite_name() -> String:
	return "ProvisionStock"

func run(t) -> void:
	_test_stock_is_deterministic(t)
	_test_scarcity_eats_the_shelf(t)
	_test_settlement_size_matters(t)
	_test_unknown_place_is_unlimited(t)
	_test_buying_is_capped_by_stock(t)
	_test_buying_is_capped_by_purse(t)
	_test_taken_today_survives_a_reload(t)

func _first_location() -> Location:
	return WorldMapData.get_locations()[0]

## Hesaplanır, saklanmaz: aynı şehrin aynı günü hep aynı raf. Olmasaydı
## şehirden çıkıp girerek raf tazelenirdi.
func _test_stock_is_deterministic(t) -> void:
	var place := _first_location()
	for day in [1, 40, 311]:
		var first := Scarcity.provision_stock(place, day)
		var second := Scarcity.provision_stock(place, day)
		t.eq(first, second, "%s %d. günde hep aynı rafı gösterir" % [place.location_id, day])
		t.ge(float(first), 0.0, "raf eksiye inmez")
	# Farklı günler farklı raflar (günlük dalga). En az bir fark yeter.
	var seen := {}
	for day in range(1, 40):
		seen[Scarcity.provision_stock(place, day)] = true
	t.ok(seen.size() > 1, "raf günden güne değişiyor (%d ayrı değer)" % seen.size())

## Kıtlık rafı yer. Vadi kıtada en çok kıtlık yaşayan bölge, Gokyurt en
## sağlıklısı (bkz. Scarcity.REGION_BASE) - raf da bunu söylemeli.
func _test_scarcity_eats_the_shelf(t) -> void:
	# Günlük dalga tek şehirde yanıltır; aynı **tür** yerleşimin iki
	# bölgedeki ortalamasına bakılıyor, yani karşılaştırılan tek değişken
	# kıtlık derecesi.
	var lean := _region_average("vadi")
	var plenty := _region_average("gocebe")
	if lean < 0.0 or plenty < 0.0:
		t.ok(true, "örnek bölge bulunamadı, atlandı")
		return
	t.ok(lean < plenty, "kıt bölgenin rafı daha boş (%.1f < %.1f)" % [lean, plenty])
	# Ve kıtlık derinleştikçe raf iniyor: aynı bölge, geç bir gün.
	t.ok(
		_region_average("vadi", 1, 30) > _region_average("vadi", 300, 330),
		"kıtlık derinleştikçe raf iniyor"
	)

## Bir bölgedeki **şehirlerin** gün ortalaması; tür sabit tutuluyor ki
## karşılaştırmada ticaret payı değil kıtlık konuşsun.
func _region_average(region: String, from_day: int = 1, to_day: int = 60) -> float:
	var total := 0.0
	var count := 0
	for place in WorldMapData.get_locations():
		if place.region != region or place.settlement_type != SettlementRules.CITY:
			continue
		for day in range(from_day, to_day):
			total += float(Scarcity.provision_stock(place, day))
			count += 1
	return total / float(count) if count > 0 else -1.0

## Büyük yerleşim daha çok satar: ticaret payı rafa giriyor.
func _test_settlement_size_matters(t) -> void:
	var city := 0
	var small := 0
	for place in WorldMapData.get_locations():
		var stock := Scarcity.provision_stock(place, 7)
		if place.settlement_type == SettlementRules.CITY:
			city = maxi(city, stock)
		else:
			small = maxi(small, stock)
	t.ok(city > 0, "şehirde erzak bulunur")
	t.ok(city >= small, "en dolu şehir en dolu küçük yerleşimden az değil")

## Bilinmeyen yer (test, F1 sentetik seferi) sınırsız: oyuncuyu hiç
## olmayan bir rafın arkasında kilitlemek yanlış olurdu.
func _test_unknown_place_is_unlimited(t) -> void:
	t.eq(Scarcity.provision_stock(null, 5), -1, "bilinmeyen yerde sınır yok")

func _fresh() -> GameSession:
	var session := GameSession.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	session.start_playthrough(
		CharacterData.create("K", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	return session

## Para yetse bile şehirde yoksa yok.
func _test_buying_is_capped_by_stock(t) -> void:
	var session := _fresh()
	session.current_location_id = _first_location().location_id
	session.wallet.add(100000)
	var stock := session.get_provision_stock()
	t.ge(float(stock), 0.0, "şehrin rafı okunuyor")
	var got := session.buy_provisions(stock + 500)
	t.eq(got, stock, "raftan fazlası alınamaz (%d istendi, %d alındı)" % [stock + 500, got])
	t.eq(session.get_provision_stock(), 0, "raf boşaldı")
	t.eq(session.buy_provisions(10), 0, "boş raftan alınamaz")

## Kesenin yettiği kadarı alınır - düğmenin hiç çalışmaması bir çıkmaz
## olurdu; eksik erzakla yola çıkmak ise bir karar.
func _test_buying_is_capped_by_purse(t) -> void:
	var session := _fresh()
	session.current_location_id = _first_location().location_id
	session.wallet.spend(session.wallet.balance)
	session.wallet.add(GameSession.PROVISIONS_UNIT_PRICE * 3)
	var before := session.get_provisions()
	var got := session.buy_provisions(50)
	t.eq(got, 3, "kesenin yettiği kadar alındı")
	t.eq(session.get_provisions() - before, 3, "erzak gerçekten geldi")
	t.eq(session.wallet.balance, 0, "para harcandı")

## Kayıt şehirde alınıyor; bugün alınan yazılmasaydı kaydedip yükleyerek
## raf tazelenirdi.
func _test_taken_today_survives_a_reload(t) -> void:
	var session := _fresh()
	session.current_location_id = _first_location().location_id
	session.wallet.add(100000)
	var took := session.buy_provisions(5)
	t.eq(took, 5, "beş erzak alındı")
	var left := session.get_provision_stock()

	var reloaded := GameSession.new()
	reloaded.load_from_dict(session.to_save_dict())
	t.eq(reloaded.provisions_bought_today, session.provisions_bought_today, "alınan kayda yazıldı")
	t.eq(reloaded.get_provision_stock(), left, "yükleme rafı tazelemiyor")
