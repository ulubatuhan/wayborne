extends RefCounted

## Pazarlık, oyunun para basma noktasına en yakın yeri. İki kez aynı tuzağa
## düşüldü (bkz. HagglingSession başlığı); bu paket ikisini birden kapalı
## tutar.
##
## Paketin merkezi tek bir cümle: **aynı dip teklifi tekrar tekrar vererek
## iyi bir fiyata varılamaz.** Eski tasarımlarda varılabiliyordu - önce eşik
## sabırla dibe indiği için, sonra eşik de taban da yalnızca geçen turun
## fonksiyonu olduğu için. Şimdi tüccar ancak *ciddiye aldığı* bir teklifin
## ardından geri çekiliyor, yani yol önemli.

const BASE_PRICE: float = 100.0
const GREED: float = 0.5
const REPUTATION: float = 0.3

func suite_name() -> String:
	return "Haggling"

func run(t) -> void:
	_test_opening_state(t)
	_test_paying_the_asking_price_always_works(t)
	_test_first_round_already_offers_a_discount(t)
	_test_threshold_never_drops_below_floor(t)
	_test_only_credible_offers_move_the_merchant(t)
	_test_lowball_spam_never_reaches_a_good_price(t)
	_test_insult_burns_two_rounds(t)
	_test_ultimatum_is_the_list_price(t)
	_test_final_offer_perk_is_not_a_shortcut(t)
	_test_skill_and_reputation_open_the_floor(t)
	_test_walkout_costs_a_little_reputation(t)
	_test_finished_session_is_inert(t)

func _new_session(
	speech: float = 0.0, charisma: float = 0.0, perk: bool = false, reputation: float = REPUTATION
) -> HagglingSession:
	return HagglingSession.new(BASE_PRICE, GREED, reputation, speech, charisma, perk)

## Aynı teklifi hakları bitene kadar tekrarlayan oyuncu. Dönen değer anlaşılan
## fiyat; ültimatoma düşülürse -1 (ültimatomu kabul etmek ayrı bir karar).
func _repeat_offer(offer: float, speech: float = 0.0, charisma: float = 0.0) -> float:
	var session := _new_session(speech, charisma)
	while session.state == HagglingSession.State.IN_PROGRESS:
		session.submit_offer(offer)
	if session.state == HagglingSession.State.SUCCESS_DEAL:
		return session.final_price
	return -1.0

## Nişan alan oyuncu: elinde hak varken tüccarı yaklaştıracak en düşük ciddi
## teklifi veriyor, son hakkında ise eldeki en iyi fiyatı alıp masadan
## kalkıyor. "İyi oynanan pazarlık" derken kastedilen bu.
func _best_skilled_price(speech: float = 0.0, charisma: float = 0.0) -> float:
	var session := _new_session(speech, charisma)
	while session.state == HagglingSession.State.IN_PROGRESS:
		if session.get_rounds_left() <= 1:
			session.submit_offer(session.get_acceptable_threshold())
			continue
		# Ciddiyet sınırının hemen üstü: tüccarı yaklaştıran en düşük teklif.
		# Kıl payı üstü, çünkü sınırın tam üstünde kayan nokta yuvarlaması
		# testi tesadüfe bağlardı.
		session.submit_offer(
			session.get_acceptable_threshold() * HagglingSession.CREDIBLE_MARGIN * 1.001
		)
	if session.state == HagglingSession.State.SUCCESS_DEAL:
		return session.final_price
	return -1.0

func _test_opening_state(t) -> void:
	var session := _new_session()
	t.eq(session.state, HagglingSession.State.IN_PROGRESS, "pazarlık açık başlar")
	t.eq(session.get_rounds_left(), HagglingSession.MAX_ROUNDS, "haklar dolu başlar")
	t.eq(session.concessions, 0, "tüccar henüz geri çekilmedi")
	t.ok(
		is_equal_approx(session.p_start, BASE_PRICE * (1.0 + GREED * (1.0 - REPUTATION))),
		"açılış fiyatı açgözlülük ve itibardan türer"
	)
	t.ok(session.get_floor() < session.p_start, "tabanın üstünde pazarlık payı var")
	t.ok(session.get_floor() > 0.0, "taban asla bedavaya inmez")

	var slider := session.get_slider_range()
	t.ok(slider.x < slider.y, "teklif aralığı geçerli")
	t.ok(slider.y > session.p_start, "istenenden fazlasını teklif etmek mümkün")

## Pazarlık isteğe bağlı bir kazanç yolu: istediğini ödeyen oyuncu her zaman
## anlaşabilmeli, yoksa mekanik zorunlu bir engele dönerdi.
func _test_paying_the_asking_price_always_works(t) -> void:
	var session := _new_session()
	session.submit_offer(session.p_start)
	t.eq(session.state, HagglingSession.State.SUCCESS_DEAL, "istenen fiyat anında kabul edilir")
	t.ok(is_equal_approx(session.final_price, session.p_start), "ödenen fiyat teklif edilendir")
	t.eq(session.get_rounds_left(), HagglingSession.MAX_ROUNDS, "kabul edilen teklif hak yakmaz")

## İlk tur da bir şey kazandırmalı: temkinli oyuncu hiç risk almadan küçük bir
## indirim alabilmeli, yoksa pazarlık "ya hep ya hiç"e dönerdi.
func _test_first_round_already_offers_a_discount(t) -> void:
	var session := _new_session()
	t.ok(
		session.get_acceptable_threshold() < session.p_start,
		"ilk turda bile liste fiyatının altı kabul edilir"
	)
	t.ok(
		session.get_acceptable_threshold() > session.get_floor(),
		"ama ilk turda taban verilmez - indirim kazanılır"
	)

func _test_threshold_never_drops_below_floor(t) -> void:
	var session := _new_session()
	for _step in HagglingSession.MAX_ROUNDS + 2:
		t.ok(
			session.get_acceptable_threshold() >= session.get_floor() - 0.001,
			"eşik tabanın altına inmez"
		)
		t.ok(
			session.get_acceptable_threshold() <= session.p_start + 0.001,
			"eşik açılış fiyatını aşmaz"
		)
		session.concessions += 1

## Tasarımın kalbi: tüccarı yaklaştıran şey turun geçmesi değil, ciddi bir
## teklif. Bu ayrım olmadan "aynı teklifi üç kez ver" yine kazanırdı.
func _test_only_credible_offers_move_the_merchant(t) -> void:
	var serious := _new_session()
	var credible_offer := serious.get_acceptable_threshold() * HagglingSession.CREDIBLE_MARGIN
	var threshold_before := serious.get_acceptable_threshold()
	serious.submit_offer(credible_offer)
	t.eq(serious.concessions, 1, "ciddi teklif tüccarı bir adım geri çeker")
	t.ok(
		serious.get_acceptable_threshold() < threshold_before,
		"geri çekilme eşiğe yansır"
	)

	var lowballer := _new_session()
	var lowball := lowballer.get_acceptable_threshold() * (HagglingSession.CREDIBLE_MARGIN - 0.1)
	var lowball_threshold_before := lowballer.get_acceptable_threshold()
	lowballer.submit_offer(lowball)
	t.eq(lowballer.concessions, 0, "ciddiye alınmayan teklif tüccarı yaklaştırmaz")
	t.eq(lowballer.get_rounds_left(), HagglingSession.MAX_ROUNDS - 1, "ama hakkı yakar")
	t.ok(
		lowballer.get_acceptable_threshold() > lowball_threshold_before,
		"üstüne taban sertleştiği için eşik yükselir - uzatmanın bedeli"
	)

## Paketin asıl iddiası, doğrudan senin sorduğun biçimde: sliderın solunu
## zorlayarak buluşma noktasına varılamaz.
func _test_lowball_spam_never_reaches_a_good_price(t) -> void:
	var skilled := _best_skilled_price()
	t.ok(skilled > 0.0, "nişan alan oyuncu anlaşabiliyor")
	t.ok(skilled < _new_session().p_start, "iyi oynanan pazarlık gerçekten kazandırır")

	# Nişan alan oyuncunun vardığı fiyatı doğrudan spam'lemeyi dene: her turda
	# reddedilmeli ve ültimatoma çıkmalı.
	var probe := _new_session()
	var spam_result := _repeat_offer(skilled)
	t.eq(
		spam_result, -1.0,
		"iyi fiyatı baştan spam'lemek anlaşma değil ültimatom getirir"
	)

	# Aralığın tamamını tara: hiçbir sabit teklif, nişan alarak varılan
	# fiyattan daha iyisini getirmemeli.
	var slider := probe.get_slider_range()
	var steps := 200
	var best_spam := -1.0
	for index in steps + 1:
		var offer: float = slider.x + (slider.y - slider.x) * (float(index) / float(steps))
		var achieved := _repeat_offer(offer)
		if achieved >= 0.0 and (best_spam < 0.0 or achieved < best_spam):
			best_spam = achieved
	t.ok(best_spam > 0.0, "bazı sabit teklifler tutuyor - mekanik ölü değil")
	t.ok(
		best_spam > skilled,
		"tek bir fiyatı tekrarlamak, tura göre nişan almaktan daha iyi sonuç vermez"
	)

func _test_insult_burns_two_rounds(t) -> void:
	var session := _new_session()
	var floor_now := session.get_floor()
	t.ok(session.is_insulting(floor_now * 0.5), "tabanın çok altı hakarettir")
	t.ok(not session.is_insulting(floor_now), "tabanın kendisi hakaret değildir")
	t.ok(not session.is_insulting(session.p_start), "istenen fiyat hakaret değildir")

	session.submit_offer(floor_now * 0.5)
	t.eq(
		session.get_rounds_left(), HagglingSession.MAX_ROUNDS - HagglingSession.INSULT_ROUND_COST,
		"hakaret tek hamlede iki hak yakar"
	)
	t.eq(session.concessions, 0, "hakaret tüccarı yaklaştırmaz")

	# İki hakaret pazarlığı bitirir.
	var quick := _new_session()
	quick.submit_offer(quick.get_floor() * 0.5)
	quick.submit_offer(quick.get_floor() * 0.5)
	t.eq(quick.state, HagglingSession.State.FINAL_CHANCE, "iki hakaret ültimatoma çıkarır")

## "Ya listeden al ya çık." Açgözlü oyuncunun bütün kazancı burada geri alınıyor.
func _test_ultimatum_is_the_list_price(t) -> void:
	var session := _new_session()
	var lowball := session.get_floor()
	for _round in HagglingSession.MAX_ROUNDS:
		if session.state != HagglingSession.State.IN_PROGRESS:
			break
		session.submit_offer(lowball)

	t.eq(session.state, HagglingSession.State.FINAL_CHANCE, "haklar bitince ültimatom gelir")
	t.eq(session.get_rounds_left(), 0, "hak kalmadı")

	session.respond_to_final_offer(true)
	t.eq(session.state, HagglingSession.State.SUCCESS_DEAL, "ültimatom kabul edilebilir")
	t.ok(
		is_equal_approx(session.final_price, session.p_start),
		"yetenek yoksa ültimatom liste fiyatıdır"
	)

	var walker := _new_session()
	for _round in HagglingSession.MAX_ROUNDS:
		if walker.state != HagglingSession.State.IN_PROGRESS:
			break
		walker.submit_offer(walker.get_floor())
	walker.respond_to_final_offer(false)
	t.eq(walker.state, HagglingSession.State.ANGER_QUIT, "ültimatom reddedilebilir")
	t.ok(is_zero_approx(walker.final_price), "masadan kalkınca anlaşma yok")

## Yetenek ültimatomu yumuşatıyor ama hakları yakmayı kârlı hale getirmemeli.
func _test_final_offer_perk_is_not_a_shortcut(t) -> void:
	var perked := _new_session(0.0, 0.0, true)
	var lowball := perked.get_floor()
	for _round in HagglingSession.MAX_ROUNDS:
		if perked.state != HagglingSession.State.IN_PROGRESS:
			break
		perked.submit_offer(lowball)
	perked.respond_to_final_offer(true)

	t.eq(perked.state, HagglingSession.State.SUCCESS_DEAL, "yetenekli oyuncu anlaşır")
	t.ok(
		perked.final_price < _new_session().p_start,
		"yetenek ültimatomu liste fiyatından ucuza çeker"
	)
	t.ok(
		perked.final_price > _best_skilled_price(),
		"ama hakları yakmak, üç turu doğru kullanmaktan hâlâ pahalı"
	)

func _test_skill_and_reputation_open_the_floor(t) -> void:
	var plain := _new_session()
	var talker := _new_session(8.0, 8.0)
	t.ok(talker.get_floor() < plain.get_floor(), "dili kuvvetli parti daha iyi taban açar")

	# İtibar iki yerden birden çalışır: hem açılış fiyatını hem tabanı indirir.
	var known := _new_session(0.0, 0.0, false, 1.0)
	var stranger := _new_session(0.0, 0.0, false, 0.0)
	t.ok(known.p_start < stranger.p_start, "tanınan kervana açılış fiyatı daha düşük çıkar")
	t.ok(known.get_floor() < stranger.get_floor(), "tanınan kervan daha ucuza anlaşabilir")

	# Beceri sınırsız indirim değil: taban oranının kendi dibi var.
	var master := HagglingSession.new(BASE_PRICE, GREED, 1.0, 1000.0, 1000.0, false)
	t.ok(
		master.get_floor() >= BASE_PRICE * HagglingSession.FLOOR_MIN_RATIO - 0.001,
		"beceri tabanı taban oranının altına indiremez"
	)

	t.ok(
		_best_skilled_price(8.0, 8.0) < _best_skilled_price(),
		"beceri somut para kazandırır"
	)

## Caydırıcı olmalı, cezalandırıcı değil: pazarlık denemek riskli olsun ama
## bir kopuş kervanı itibarsız bırakmasın.
func _test_walkout_costs_a_little_reputation(t) -> void:
	var session := _new_session()
	var penalty := session.get_walkout_reputation_penalty()
	t.ok(penalty > 0, "masadan kalkmak bedava değil")
	t.le(penalty, 2, "ama ceza küçük kalır - kopuş bir felaket değil, bir bedel")

func _test_finished_session_is_inert(t) -> void:
	var session := _new_session()
	session.submit_offer(session.p_start)
	var settled := session.final_price

	session.submit_offer(session.get_floor())
	t.ok(is_equal_approx(session.final_price, settled), "kapanmış pazarlık yeni teklif almaz")
	t.eq(session.state, HagglingSession.State.SUCCESS_DEAL, "kapanmış pazarlığın durumu değişmez")

	var fresh := _new_session()
	fresh.respond_to_final_offer(true)
	t.eq(
		fresh.state, HagglingSession.State.IN_PROGRESS,
		"ültimatom gelmeden verilen cevap yok sayılır"
	)
