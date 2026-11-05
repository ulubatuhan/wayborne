extends RefCounted

## Pazarlık, oyunun para basma noktasına en yakın yeriydi. Üç kez yeniden
## yazıldı (gerekçeler `HagglingSession`'ın başlığında); bu paket dördüncü
## tasarımın kapattığı şeyleri kapalı tutar.
##
## Paketin merkezi iki cümle:
##   1. **Pazarlık bir gelir kaynağı olamaz.** En iyi oyuncunun en iyi
##      hamlesinde bile kazanç `DISCOUNT_MAX` ile sınırlı; eski tasarımda
##      %45'e çıkıyordu.
##   2. **Tek karar, tek hak.** Direnmek bir kez atılır; kaybedince fiyat
##      *artar*. Tekrar deneyerek, bekleyerek ya da dip teklif vererek
##      daha iyi bir sayıya varılamaz, çünkü ikinci bir hamle yok.

const BASE_PRICE: float = 100.0
const GREED: float = 0.5
const REPUTATION: float = 0.3

func suite_name() -> String:
	return "Haggling"

func run(t) -> void:
	_test_opening_state(t)
	_test_accepting_pays_the_list_price(t)
	_test_discount_is_capped(t)
	_test_discount_comes_off_the_visible_price(t)
	_test_losing_the_push_raises_the_price(t)
	_test_push_is_a_single_right(t)
	_test_push_odds_are_bounded_and_shown(t)
	_test_reputation_lowers_the_list_price(t)
	_test_walkout_ends_the_session(t)
	_test_conscience_branch_only_under_scarcity(t)
	_test_no_sequence_beats_the_single_discount(t)

func _new_session(
	charisma: float = 0.0,
	reputation: float = REPUTATION,
	scarcity: float = 0.0
) -> HagglingSession:
	return HagglingSession.new(BASE_PRICE, GREED, reputation, charisma, scarcity)

## Zarı sabitlemenin tek yolu: tohumu çağıran veriyor (bkz. `push`).
func _rng_that_wins() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return _find_seed(rng, true)

func _rng_that_loses() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return _find_seed(rng, false)

## İlk sayısı eşiğin altında/üstünde kalan bir tohum bul. Kör sabit tohum
## yazmak yerine aranıyor: eşik değiştiğinde test kendiliğinden uyar.
func _find_seed(rng: RandomNumberGenerator, want_low: bool) -> RandomNumberGenerator:
	var threshold := 0.15
	for candidate in range(1, 500):
		rng.seed = candidate
		var roll := rng.randf()
		if want_low and roll < threshold:
			rng.seed = candidate
			return rng
		if not want_low and roll > 0.9:
			rng.seed = candidate
			return rng
	return rng

func _test_opening_state(t) -> void:
	var s := _new_session()
	t.eq(s.state, HagglingSession.State.OFFERED, "pazarlık teklif durumunda başlar")
	t.ok(s.can_push(), "açılışta direnme hakkı var")
	t.not_ok(s.pushed, "açılışta henüz direnilmemiş")
	t.ge(s.list_price, BASE_PRICE, "tüccar taban fiyatın altını istemez")
	t.almost(s.current_price(), s.list_price, "direnilmeden ödenecek fiyat liste fiyatı")

func _test_accepting_pays_the_list_price(t) -> void:
	var s := _new_session()
	var listed := s.list_price
	s.accept()
	t.eq(s.state, HagglingSession.State.SUCCESS_DEAL, "kabul etmek anlaşmayı bitirir")
	t.almost(s.final_price, listed, "kabul edilen fiyat ekrandaki fiyattır")
	t.not_ok(s.can_push(), "anlaşmadan sonra direnme hakkı kalmaz")
	# Pazarlığa hiç girmeyen oyuncu cezalandırılmıyor: istenen fiyatı ödemek
	# her zaman geçerli bir hamle.
	s.accept()
	t.eq(s.state, HagglingSession.State.SUCCESS_DEAL, "ikinci kabul durumu bozmaz")

func _test_discount_is_capped(t) -> void:
	# Sömürünün kapandığı yer: beceri ve itibar sonsuz olsa da indirim tavanlı.
	var monster := HagglingSession.new(BASE_PRICE, GREED, 1.0, 999.0, 0.0)
	t.le(
		monster.discount(),
		HagglingSession.DISCOUNT_MAX,
		"indirim hiçbir beceriyle tavanı geçmez"
	)
	t.almost(
		monster.discount(),
		HagglingSession.DISCOUNT_MAX,
		"beceri sonsuzken indirim tavana oturur"
	)
	# Taban kazanç: becerisiz bir kervanda bile direnip kazanmak fiyatı
	# *görünür* biçimde indirmeli. Sıfırken "%39 ihtimalle 19 GG, yoksa
	# 21 GG" yazıyordu - kazanmanın karşılığı olmayan bir risk düğmesi.
	var novice := _new_session(0.0, 0.0)
	t.almost(novice.discount(), HagglingSession.DISCOUNT_BASE, "taban indirim herkese açık")
	t.ok(novice.push_price() < novice.list_price, "becerisiz kervan da direnince kazanır")
	var pricey := HagglingSession.new(500.0, GREED, 0.0, 0.0, 0.0)
	t.ok(
		int(round(pricey.push_price())) < int(round(pricey.list_price)),
		"kazanç ekrandaki sayıda görünür, yuvarlamada kaybolmaz"
	)
	t.ok(pricey.can_push(), "kazancı görünen bir masada direnme düğmesi açıktır")
	# Ve kazancı yuvarlamada kaybolan ufak bir alışverişte düğme hiç çıkmaz:
	# saf zarar olan bir karar sunulmaz.
	var trivial := HagglingSession.new(1.0, 0.0, 0.0, 0.0, 0.0)
	t.not_ok(trivial.push_is_worth_it(), "kazancı görünmeyen masada direnmeye değmez")
	t.not_ok(trivial.can_push(), "değmeyen masada düğme kapalı")
	t.le(
		HagglingSession.DISCOUNT_MAX,
		0.2,
		"pazarlık bir gelir kaynağı olmayacak kadar küçük kalmalı"
	)

func _test_discount_comes_off_the_visible_price(t) -> void:
	var s := _new_session(50.0)
	t.almost(
		s.push_price(),
		s.list_price * (1.0 - s.discount()),
		"indirim ekranda yazan fiyattan iner, gizli bir tabandan değil"
	)
	t.le(s.push_price(), s.list_price, "direnip kazanmak fiyatı yükseltmez")

func _test_losing_the_push_raises_the_price(t) -> void:
	var s := _new_session(50.0)
	var listed := s.list_price
	var won := s.push(_rng_that_loses())
	t.not_ok(won, "kaybeden zar direnmeyi kaybettirir")
	t.ok(s.pushed, "direnme kullanıldı olarak işaretlenir")
	t.ge(s.current_price(), listed, "kaybedince fiyat liste fiyatının üstüne çıkar")
	t.almost(
		s.current_price(),
		listed * (1.0 + HagglingSession.PUSH_FAIL_RAISE),
		"artış sabitin kendisi kadar"
	)
	t.ge(
		float(s.get_push_reputation_penalty()),
		1.0,
		"direnip kaybetmek itibara da dokunur: bedava kura değil"
	)
	# Kaybetmek pazarlığı bitirmiyor: artmış fiyatı kabul etmek ya da masadan
	# kalkmak hâlâ oyuncunun kararı.
	t.eq(s.state, HagglingSession.State.OFFERED, "kaybedince masa devam eder")
	s.accept()
	t.almost(s.final_price, listed * (1.0 + HagglingSession.PUSH_FAIL_RAISE),
		"kabul edilen fiyat artmış fiyattır")

func _test_push_is_a_single_right(t) -> void:
	var s := _new_session(50.0)
	s.push(_rng_that_loses())
	t.not_ok(s.can_push(), "direnme hakkı bir kez")
	var after := s.current_price()
	var again := s.push(_rng_that_wins())
	t.not_ok(again, "ikinci direnme hiç atılmaz")
	t.almost(s.current_price(), after, "ikinci deneme fiyatı değiştirmez")
	# Eski tasarımların sömürüsü buradaydı: tekrar deneyerek iyi fiyata
	# varmak. İkinci hamle olmadığı için artık imkânsız.

func _test_push_odds_are_bounded_and_shown(t) -> void:
	var weak := HagglingSession.new(BASE_PRICE, GREED, 0.0, -99.0, 0.0)
	var strong := HagglingSession.new(BASE_PRICE, GREED, 1.0, 999.0, 0.0)
	t.ge(weak.push_odds(), HagglingSession.PUSH_ODDS_MIN, "şans tabanın altına inmez")
	t.le(strong.push_odds(), HagglingSession.PUSH_ODDS_MAX, "şans tavanın üstüne çıkmaz")
	t.ok(
		strong.push_odds() > weak.push_odds(),
		"karizma ve itibar direnme şansını artırır"
	)
	# Şans ekranda yazılı olmak zorunda: tek hak varsa kör zar atılmamalı.
	t.ok(
		HagglingSession.PUSH_ODDS_MAX < 1.0,
		"direnmek hiçbir zaman garantiye dönüşmez"
	)

func _test_reputation_lowers_the_list_price(t) -> void:
	var unknown := _new_session(0.0, 0.0)
	var trusted := _new_session(0.0, 1.0)
	t.ok(
		trusted.list_price < unknown.list_price,
		"itibarlı kervandan daha az sıyrılır"
	)
	t.almost(trusted.list_price, BASE_PRICE, "tam itibarda liste fiyatı tabana oturur")

func _test_walkout_ends_the_session(t) -> void:
	var s := _new_session()
	s.walk_away()
	t.eq(s.state, HagglingSession.State.ANGER_QUIT, "masadan kalkmak pazarlığı bitirir")
	t.eq(s.final_price, 0.0, "kalkınca hiçbir şey ödenmez")
	t.not_ok(s.can_push(), "kalktıktan sonra direnilemez")
	t.ge(
		float(s.get_walkout_reputation_penalty()),
		1.0,
		"masadan kalkmanın bir bedeli var"
	)
	t.le(
		float(s.get_walkout_reputation_penalty()),
		2.0,
		"bedel caydırıcı olmalı, felaket değil"
	)

func _test_conscience_branch_only_under_scarcity(t) -> void:
	var plenty := _new_session(0.0, REPUTATION, 0.0)
	t.not_ok(plenty.is_conscience(), "bollukta pazarlığın konusu fiyattır")
	t.eq(plenty.conscience_standing_cost(), 0, "vicdan dalı kapalıyken bölgesel bedel yok")
	var hunger := _new_session(0.0, REPUTATION, 0.9)
	t.ok(hunger.is_conscience(), "kıtlıkta diren üstelemeye dönüşür")
	t.ge(
		float(hunger.conscience_standing_cost()),
		1.0,
		"üstelemenin bölgesel bir bedeli var"
	)
	# Kıtlık derslerinin kuralı: bedel adı olan birine düşer. Burada o
	# "biri" karşıdaki satıcı, bedeli de o bölgedeki itibar.
	t.ok(
		HagglingSession.CONSCIENCE_FROM > 0.0,
		"vicdan dalı her pazarlıkta açık değil"
	)
	t.ok(
		HagglingSession.CONSCIENCE_FROM < 1.0,
		"vicdan dalı oyunun içinde gerçekten görülebilir"
	)

func _test_no_sequence_beats_the_single_discount(t) -> void:
	# Paketin asıl sorusu: hangi hamle dizisi en iyi fiyatı verir? Cevap
	# "indirimli fiyat"tan iyi olamaz, çünkü başka hamle yok. Üç yolu da
	# ölç ve hiçbirinin tabanın altına inmediğini doğrula.
	var best := HagglingSession.new(BASE_PRICE, GREED, 1.0, 999.0, 0.0)
	var floor_price := best.list_price * (1.0 - HagglingSession.DISCOUNT_MAX)

	var straight := HagglingSession.new(BASE_PRICE, GREED, 1.0, 999.0, 0.0)
	straight.accept()
	t.ge(straight.final_price, floor_price, "doğrudan kabul tabanın altına inmez")

	var pushed_win := HagglingSession.new(BASE_PRICE, GREED, 1.0, 999.0, 0.0)
	pushed_win.push(_rng_that_wins())
	pushed_win.accept()
	t.ge(pushed_win.final_price, floor_price, "direnip kazanmak bile tabanın altına inmez")
	t.almost(pushed_win.final_price, floor_price, "en iyi sonuç tam olarak taban fiyattır")

	var pushed_loss := HagglingSession.new(BASE_PRICE, GREED, 1.0, 999.0, 0.0)
	pushed_loss.push(_rng_that_loses())
	pushed_loss.accept()
	t.ge(pushed_loss.final_price, straight.final_price,
		"kaybedilen direniş hiç direnmemekten pahalıdır")

	# Ve taban fiyat taban maliyetin çok altında olamaz: pazarlık para
	# basmıyor.
	t.ge(
		floor_price,
		BASE_PRICE * 0.8,
		"en iyi pazarlık bile taban fiyatın %20'sinden fazlasını silemez"
	)
