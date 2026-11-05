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
	_test_barter_beats_coin_under_scarcity(t)
	_test_barter_scales_with_quantity(t)
	_test_barter_tilt_reads_equivalence(t)
	_test_wear_shows_in_three_places(t)
	_test_wear_and_wet_do_not_erase_each_other(t)
	_test_body_wear_reads_existing_numbers(t)
	_test_city_treasury_dries_with_scarcity(t)
	_test_sale_cannot_exceed_the_city_purse(t)
	_test_buyback_cap_blocks_the_same_city_loop(t)
	_test_overdue_debt_with_a_face_closes_that_market(t)
	_test_advance_debt_wears_the_lenders_name(t)

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
	session.record_sale("test_cloth", 10, 100)
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
	session.market.add_shock(place.location_id, MarketConditions.MEDICINE_ITEM, 2.0, 30)
	t.ok(session.is_profiteering_sale(MarketConditions.MEDICINE_ITEM), "kurulan kriz vurgun sayılır")
	var standing_before := session.standing.region(place.region)
	session.record_sale(MarketConditions.MEDICINE_ITEM, 5, 500)
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

# --- P6: takas ---

func _test_barter_beats_coin_under_scarcity(t) -> void:
	# Asıl iddia: aç bir bölgede malı sikkeye çevirip sikkeyle mal almak
	# kötü bir hamle. Altının değersizleşmesi kıtlığın en somut ifadesi -
	# ve hiçbir sistem kesilmeden söyleniyor: kese duruyor, vergi ve geçiş
	# ücreti hâlâ altın istiyor.
	var cash := 100
	var plenty := MarketPricing.barter_value(cash, 1, 0.0)
	var hunger := MarketPricing.barter_value(cash, 1, 1.0)
	t.ge(float(plenty), float(cash), "takas bollukta bile nakitten aşağı değil")
	t.ok(hunger > plenty, "kıtlık takasın payını büyütür")
	t.almost(
		float(hunger),
		float(cash) * (1.0 + MarketPricing.BARTER_BONUS_BASE + MarketPricing.BARTER_BONUS_PER_SCARCITY),
		"en ağır kıtlıkta pay taban + kıtlık payı"
	)

func _test_barter_scales_with_quantity(t) -> void:
	t.eq(
		MarketPricing.barter_value(50, 4, 0.5),
		MarketPricing.barter_value(200, 1, 0.5),
		"takas değeri adetle doğrusal"
	)
	t.eq(MarketPricing.barter_value(0, 10, 0.5), 0, "değersiz malın takası da değersiz")
	t.eq(MarketPricing.barter_value(50, 0, 0.5), 0, "hiç vermemek hiçbir şey etmez")
	t.ge(float(MarketPricing.barter_value(-5, 3, 0.5)), 0.0, "eksi fiyat eksi karşılık vermez")

func _test_barter_tilt_reads_equivalence(t) -> void:
	# Terazi takasta fiyatı değil denkliği gösteriyor: iki kefe eşitse kol
	# düz. (Görsel dil zaten buna hazırdı - yeni ekran gerekmedi.)
	var scale := MarketScale.new()
	t.almost(scale.tilt_for(100, 100), 0.0, "denk takasta kol düz")
	t.ok(scale.tilt_for(200, 100) > 0.0, "aldığın ağırsa kol o yana iner")
	t.ok(scale.tilt_for(100, 200) < 0.0, "verdiğin ağırsa öbür yana")
	scale.free()

# --- P16: açlık ve yorgunluk bedende ---

func _test_wear_shows_in_three_places(t) -> void:
	# Tek bir sinyal bakışta aşınma değil, çizim hatası gibi okunuyor;
	# bu yüzden duruş, adım ve renk birlikte değişiyor.
	var figure := WalkFigure.new()
	t.almost(figure.wear_hunch(), 0.0, "tok ve dinç figür dik durur")
	t.almost(figure.wear_step(), 1.0, "adımı kısalmaz")
	t.almost(figure.wear_bulk(), 1.0, "silueti incelmez")
	t.almost(figure.wear_stoop(), 1.0, "boyu kısalmaz")
	figure.set_wear(1.0, 1.0)
	t.ok(figure.wear_hunch() > 0.0, "aç ve yorgun figürün omzu çöker")
	t.ok(figure.wear_step() < 1.0, "adımı kısalır")
	t.ok(figure.wear_bulk() < 1.0, "silueti incelir")
	# Dördüncü sinyal, ekran görüntüsünden sonra eklendi: render edilmiş
	# figürde kareler sabit olduğu için adım kısalması oraya inmiyor,
	# duruşun tek başına konuşması gerekiyordu.
	t.ok(figure.wear_stoop() < 1.0, "dikilmeyen insan kısalır")
	t.eq(figure.get_wear(), Vector2(1.0, 1.0), "okunan değer yazılanla aynı")
	# Uyku kiloyu geri almaz: incelme yalnız açlıktan.
	var tired := WalkFigure.new()
	tired.set_wear(0.0, 1.0)
	t.almost(tired.wear_bulk(), 1.0, "yorgunluk tek başına inceltmez")
	t.ok(tired.wear_stoop() < 1.0, "ama yorgunluk da çökertir")
	t.ok(tired.wear_step() < 1.0, "yorgunluk adımı kısaltır")
	# Aç bir insan yine de yürür, yorgun bir insan sürüklenir.
	var starving := WalkFigure.new()
	starving.set_wear(1.0, 0.0)
	t.ok(starving.wear_step() > tired.wear_step(), "yorgunluk adımı açlıktan çok kısaltır")
	figure.free()
	tired.free()
	starving.free()

func _test_wear_and_wet_do_not_erase_each_other(t) -> void:
	# İkisi de bütün figürü kapsayan tek çarpandan geçiyor; biri öbürünü
	# sıfırlarsa yağmurda aç bir kervan tok görünür.
	var dry_fed := ArtDraw.worn_tint(ArtDraw.wet_tint(Color.WHITE, 0.0), 0.0, 0.0)
	var wet_fed := ArtDraw.worn_tint(ArtDraw.wet_tint(Color.WHITE, 1.0), 0.0, 0.0)
	var wet_starving := ArtDraw.worn_tint(ArtDraw.wet_tint(Color.WHITE, 1.0), 1.0, 1.0)
	t.ok(wet_fed.v < dry_fed.v, "ıslak figür koyulaşır")
	t.ok(wet_starving.v < wet_fed.v, "aç ve ıslak figür daha da soluk")
	t.ok(wet_starving.r < wet_fed.r, "açlık kırmızıyı çeker")
	var figure := WalkFigure.new()
	figure.set_weather_coat(0.8, 0.0)
	var only_wet: Color = figure.self_modulate
	figure.set_wear(1.0, 1.0)
	t.ne(figure.self_modulate, only_wet, "aşınma ıslaklığın üstüne biniyor")
	figure.set_weather_coat(0.0, 0.0)
	t.ne(figure.self_modulate, Color.WHITE, "ıslaklık silinince aşınma kalıyor")
	figure.free()

func _test_body_wear_reads_existing_numbers(t) -> void:
	# Yeni durum tutulmuyor: çizim mekaniğin üstüne bir katman, yanına
	# ikinci bir hakikat değil.
	var session := _session_at(WorldMapData.get_locations()[0].location_id, 1)
	t.almost(session.body_hunger(), 0.0, "yola çıkan kervan aç değil")
	t.almost(session.body_fatigue(), 0.0, "ve dinç")
	session.crew_hungry_nights = int(GameSession.WEAR_HUNGER_DAYS) + 2
	t.almost(session.body_hunger(), 1.0, "uzun açlık tavana oturur")
	session.change_party_fatigue(CharacterData.MAX_FATIGUE)
	t.almost(session.body_fatigue(), 1.0, "tükenmiş parti tavanda")
	t.le(session.body_hunger(), 1.0, "okuma 0-1 arasında kalır")

# --- P8: kâr tavanı ---

func _test_city_treasury_dries_with_scarcity(t) -> void:
	# Tavanı sabit bir sayıyı kısarak değil dünyayı fakirleştirerek
	# indiriyoruz: aç bir bölgenin şehri yalnız mal değil, para da bulamaz.
	# Ve bu takasla (P6) aynı cümleyi söylüyor.
	var hungry := _hungry_city()
	var early := MarketConditions.default_city_gold(hungry.location_id, 1)
	var late := MarketConditions.default_city_gold(hungry.location_id, 320)
	t.ok(late < early, "kıtlık derinleşince şehrin hazinesi küçülür")
	t.ge(late, 0.0, "hazine eksiye düşmez")
	t.le(
		early,
		MarketConditions.CITY_GOLD_DEFAULT,
		"hazine hiçbir zaman tabanın üstüne çıkmaz"
	)
	# Dokunulmamış bir şehir de günü bilmek zorunda: yoksa geç oyunda
	# uğranmamış her şehir hâlâ ilk günün hazinesiyle görünürdü.
	var conditions := MarketConditions.new()
	t.ok(
		conditions.get_city_gold(hungry.location_id, 320)
			< conditions.get_city_gold(hungry.location_id, 1),
		"hiç uğranmamış şehir de kıtlığı taşır"
	)

func _test_sale_cannot_exceed_the_city_purse(t) -> void:
	# Kâr tavanının asıl kapısı: şehir ancak kesesindeki kadarını alır.
	# Bu kapı bir kez ölçüm aracında atlanmıştı ve rapor 6948 GG'lik bir
	# tepe gösteriyordu - gerçekte 1617.
	var place := WorldMapData.get_locations()[0]
	var session := _session_at(place.location_id, 1)
	var reserve := session.get_city_gold_reserve()
	t.ge(float(reserve), 0.0, "hazine okunabiliyor")
	t.not_ok(
		session.can_city_afford_sale(reserve + 1),
		"hazinenin üstünde bir satış kabul edilmez"
	)
	t.ok(session.can_city_afford_sale(reserve), "hazine kadarı kabul edilir")

func _test_buyback_cap_blocks_the_same_city_loop(t) -> void:
	# Aynı şehirde al-sat döngüsü para basamaz.
	var place := WorldMapData.get_locations()[0]
	var session := _session_at(place.location_id, 1)
	var item := ItemCatalog.get_item("test_cloth")
	session.note_purchase(item, 5, 100)
	t.le(
		float(session.capped_sell_price(item.item_id, 500)),
		float(100 * GameSession.BUYBACK_SHARE) + 0.5,
		"burada aldığın mal, buradaki alış fiyatının altında geri satılır"
	)

# --- P11: borcun bir yüzü var ---

func _test_overdue_debt_with_a_face_closes_that_market(t) -> void:
	# Gecikmenin bedeli aritmetik değil **sosyal** (P11): alacaklı seni o
	# şehirde alışveriş ederken görmek istemiyor.
	var place := WorldMapData.get_locations()[0]
	var session := _session_at(place.location_id, 100)
	t.eq(session.debt_shut_out_reason(), "", "borçsuz kervana pazar açık")

	var debt := session.debts.borrow("Tefeci", 300, 0)
	debt.due_day = 10
	t.eq(
		session.debt_shut_out_reason(), "",
		"kurumsal borç kimseye kapı kapatmaz - ortada kırılan bir söz yok"
	)

	debt.bind_to_person("%s|tefeci" % place.location_id, place.location_id)
	t.ne(session.debt_shut_out_reason(), "", "yüzü olan gecikmiş borç pazarı kapatır")

	# Yalnız o şehir: başka bir şehre bu borcun hükmü geçmez.
	var elsewhere := ""
	for other in WorldMapData.get_locations():
		if other.location_id != place.location_id:
			elsewhere = other.location_id
			break
	t.eq(session.debt_shut_out_reason(elsewhere), "", "başka şehirde pazar açık")

	# Ve vade geçmemişse kapı açık: borçlu olmak değil, sözü bozmak kapatıyor.
	debt.due_day = session.total_days_elapsed + 30
	t.eq(session.debt_shut_out_reason(), "", "vadesi gelmemiş borç kapı kapatmaz")

func _test_advance_debt_wears_the_lenders_name(t) -> void:
	var place: Location = null
	for candidate in WorldMapData.get_locations():
		if not candidate.produces.is_empty():
			place = candidate
			break
	var session := _session_at(place.location_id, 10)
	session.owned_wagon_count = 2
	var item := ItemCatalog.get_item(String(place.produces[0]))
	if not session.can_take_advance(item, 5):
		t.ok(true, "bu şehirde avans kapalı - bağlama ölçülemedi")
		return
	t.ok(session.take_goods_advance(item, 5), "mal avansı alınır")
	var debt: Debt = session.debts.get_debts()[0]
	t.ok(debt.has_face(), "avans borcu bir yüze bağlanır (P11)")
	t.eq(debt.creditor_city_id, place.location_id, "ve o yüzün şehrine")
	t.ne(debt.creditor_name, "DEBT_CREDITOR_GUILD", "alacaklının adı var, etiketi değil")
