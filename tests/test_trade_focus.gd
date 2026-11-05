extends RefCounted

## Ticaretin odağı turu: P7 (görünür katman 7'den 3'e), P14 (defter sattığını
## hatırlar), P17 (sessiz güne izin). Üçü de "ne kesildi" değil "ne değişti"
## testleri: kesilen hiçbir sistem yok, kipleri değişti.

func suite_name() -> String:
	return "Trade Focus"

func run(t) -> void:
	_test_price_marks_have_no_multipliers(t)
	_test_price_marks_are_capped(t)
	_test_scarcity_speaks_first(t)
	_test_ordinary_sale_is_not_remembered(t)
	_test_mercy_sale_is_remembered(t)
	_test_profiteering_sale_is_remembered(t)
	_test_quiet_days_are_allowed_under_scarcity(t)
	_test_quiet_ramp_is_unchanged_when_fed(t)

# --- P7: fiyatın nedeni, sayısı değil ---

func _sample_marks(scarcity: float = 0.0, item_id: String = "provisions") -> Array[String]:
	var location := WorldMapData.get_locations()[0]
	var item := ItemCatalog.get_item(item_id)
	return PriceLayerText.marks(item, location, MarketConditions.new(), 120, scarcity)

func _test_price_marks_have_no_multipliers(t) -> void:
	# Asıl iddia: oyuncunun gördüğü metinde çarpan yok. Eskiden her satırın
	# sonunda "(×1.24)" vardı ve yüzey eksik bir elektronik tabloydu -
	# oyuncu çarpanları toplayıp doğru sayıya varamıyordu, varabileceğini
	# sanıyordu.
	for place in WorldMapData.get_locations():
		for item in ItemCatalog.get_trade_goods():
			var out := PriceLayerText.marks(item, place, MarketConditions.new(), 120, 0.0)
			t.not_ok(out[1].contains("×"), "ipucunda çarpan işareti yok")
			t.not_ok(out[1].contains("x1."), "ipucunda çarpan sayısı yok")
			break
		break
	var marks := _sample_marks()
	t.eq(marks.size(), 2, "marks hâlâ [etiketler, ipucu] döner")

func _test_price_marks_are_capped(t) -> void:
	for place in WorldMapData.get_locations():
		for item in ItemCatalog.get_trade_goods():
			var out := PriceLayerText.marks(item, place, MarketConditions.new(), 200, 0.0)
			var tags := String(out[0])
			var count := 0 if tags.is_empty() else tags.split(" · ").size()
			t.le(
				float(count),
				float(PriceLayerText.MAX_MARKS),
				"satır notunda en çok %d neden" % PriceLayerText.MAX_MARKS
			)
			var lines := 0 if String(out[1]).is_empty() else String(out[1]).split("\n").size()
			t.le(float(lines), float(PriceLayerText.MAX_MARKS), "ipucunda da en çok o kadar satır")

func _test_scarcity_speaks_first(t) -> void:
	var hungry := _sample_marks(0.9)
	var fed := _sample_marks(0.0)
	var scarcity_word := String(TranslationServer.translate("UI_PRICE_TAG_SCARCITY"))
	t.ok(String(hungry[0]).begins_with(scarcity_word), "kıtlıkta ilk neden kıtlıktır")
	t.not_ok(String(fed[0]).contains(scarcity_word), "bollukta kıtlık yazmaz")
	# Yalnız yiyecekte. Her malın altında yazan bir söz hiçbir şey söylemez -
	# bu, 0.35 eşiğiyle çekilen ekran görüntüsünde düştü.
	t.not_ok(
		String(_sample_marks(0.9, "jewelry")[0]).contains(scarcity_word),
		"kıtlık mücevherin altına yazılmaz"
	)
	t.almost(
		PriceLayerText.SCARCITY_SPEAKS_FROM,
		Scarcity.HUNGRY_CITY_FROM,
		"\"aç şehir\" oyunun her yerinde aynı eşik"
	)
	# Kıtlık bir fiyat çarpanı değil (arzı kesiyor) ama oyuncunun gördüğü
	# sayıyı en çok o açıklıyor; bu yüzden sözle söyleniyor.
	t.le(
		float(String(hungry[0]).split(" · ").size()),
		float(PriceLayerText.MAX_MARKS),
		"kıtlık eklenince de tavan aşılmaz"
	)

# --- P14: defter sattığını hatırlar ---

func _session_at(location_id: String, day: int) -> GameSession:
	var session: GameSession = load("res://scripts/autoload/game_session.gd").new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.current_location_id = location_id
	session.total_days_elapsed = day
	session.people.ensure_city(location_id, day)
	return session

func _hungry_city() -> Location:
	var best: Location = null
	var best_degree := -1.0
	for place in WorldMapData.get_locations():
		var degree := Scarcity.degree(place.region, 320)
		if degree > best_degree:
			best_degree = degree
			best = place
	return best

func _trade_lines(session: GameSession) -> int:
	var count := 0
	for entry in session.ledger.entries:
		if String(entry.get("kind", "")) == CaravanLedger.KIND_TRADE:
			count += 1
	return count

func _test_ordinary_sale_is_not_remembered(t) -> void:
	# Sınır: sıradan bir satış hiçbir şey yapmaz, yoksa defter alışveriş
	# fişine döner.
	var place := WorldMapData.get_locations()[0]
	var session := _session_at(place.location_id, 1)
	var before := _trade_lines(session)
	session.record_sale("bolt_of_cloth", 10, 100)
	t.eq(_trade_lines(session), before, "sıradan satış deftere girmez")

func _test_mercy_sale_is_remembered(t) -> void:
	var place := _hungry_city()
	var session := _session_at(place.location_id, 320)
	# Ölçüldü (2026-11-05): 320. günde en aç şehir akavan, derece 0.79,
	# eşik 0.50. Testin sessizce atlanmasına izin verilmiyor - dünya
	# kıtlığı kaybederse bu satır düşsün ve haber versin.
	t.ge(
		session.scarcity_here(),
		Scarcity.HUNGRY_CITY_FROM,
		"kıtlık dönemi gerçekten aç bir şehir üretiyor"
	)
	var standing_before := session.standing.region(place.region)
	var regard_before := _regard_sum(session, place.location_id)
	session.record_sale("provisions", 10, 200)
	t.eq(_trade_lines(session), 1, "aç şehre yiyecek getirmek deftere girer")
	t.ok(
		session.standing.region(place.region) > standing_before,
		"iyilik o bölgedeki itibarı yükseltir"
	)
	t.ok(
		_regard_sum(session, place.location_id) > regard_before,
		"şehrin adı olan kişileri bunu hatırlar"
	)
	# Tek çuvalla şehir kurtarmak ucuz olurdu.
	var stingy := _session_at(place.location_id, 320)
	stingy.record_sale("provisions", 1, 20)
	t.eq(_trade_lines(stingy), 0, "tek parça satış iyilik sayılmaz")

func _test_profiteering_sale_is_remembered(t) -> void:
	var place := WorldMapData.get_locations()[0]
	var session := _session_at(place.location_id, 1)
	# Krizi ve şoku elle kur: vurgunculuk tam olarak "krizin şişirdiği
	# fiyattan satmak". Dünyanın o gün kendiliğinden bir krizi olmasını
	# beklemek testi sessizce atlanır hâle getirirdi.
	session.plague._infect(place.location_id, 0.4)
	session.market.add_shock(place.location_id, "medicine", 2.0, 30)
	t.ok(session.is_profiteering_sale("medicine"), "kurulan kriz vurgun sayılır")
	var standing_before := session.standing.region(place.region)
	session.record_sale("medicine", 5, 500)
	t.eq(_trade_lines(session), 1, "vurgun deftere girer")
	t.ok(
		session.standing.region(place.region) < standing_before,
		"vurgun o bölgedeki itibarı düşürür"
	)

func _regard_sum(session: GameSession, location_id: String) -> int:
	var total := 0
	for p in session.people.city_people(location_id):
		total += People.regard(p)
	return total

# --- P17: sessiz güne izin ---

func _streak(director: RoadDirector, days: int) -> void:
	for _day in days:
		director.note_quiet()

func _test_quiet_days_are_allowed_under_scarcity(t) -> void:
	var director := RoadDirector.new()
	director.begin_day(50)
	_streak(director, 4)
	var fed := director.chance_multiplier({"scarcity_here": 0.0})
	var hungry := director.chance_multiplier({"scarcity_here": 0.95})
	t.ok(hungry < fed, "kıtlıkta sessizlik rampası kısılır")
	# Tavan da kıtlıkla birlikte kayıyor: en ağır günde tam tabanına iner.
	# (0.95'te henüz yolun ortasında - kısılma kademeli, anahtar değil.)
	_streak(director, 20)
	t.le(
		director.chance_multiplier({"scarcity_here": 1.0}),
		RoadDirector.SCARCITY_MAX_QUIET_BOOST,
		"en ağır kıtlıkta rampanın tavanı da tabanına iner"
	)
	t.ok(
		director.chance_multiplier({"scarcity_here": 0.95})
			< director.chance_multiplier({"scarcity_here": 0.0}),
		"kısılma kıtlık derecesiyle orantılı"
	)
	# Ama susmak yok olmak değil: yol büsbütün susmuyor, yalnız üç gün üst
	# üste susabiliyor.
	t.ge(hungry, 1.0, "kıtlık ihtimali nötrün altına indirmez")

func _test_quiet_ramp_is_unchanged_when_fed(t) -> void:
	var director := RoadDirector.new()
	director.begin_day(50)
	_streak(director, 3)
	t.almost(
		director.chance_multiplier({}),
		director.chance_multiplier({"scarcity_here": 0.0}),
		"bağlamsız çağrı eski davranışı korur"
	)
	t.almost(
		director.chance_multiplier(),
		1.0 + RoadDirector.QUIET_RAMP * 2.0,
		"bolluk rampası değişmedi"
	)
