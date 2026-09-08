extends RefCounted

## Pazarlık, oyunun para basma noktasına en yakın yeri: taban fiyat ile satış
## fiyatı arasındaki farkı oyuncunun elinde büyütüyor. Eski tasarımda tüccarı
## çileden çıkarmak ödüllendiriliyordu (kabul eşiği sabırla birlikte dibe
## iniyordu), yani "dip teklifi spam'le" baskın stratejiydi ve pazarlıkta
## karar diye bir şey kalmıyordu.
##
## Bu paket o açığı kapalı tutar. En kritik iddia sonunda tek cümle:
## **öfkelendirerek elde edilen fiyat, sabırla pazarlık edilmiş fiyattan asla
## daha iyi olamaz.** Geri kalan testler bu iddianın dayandığı mekanikleri
## (sertleşen taban, tabanın altına inmeyen eşik, kopuşun itibar bedeli)
## tek tek kilitler.

const BASE_PRICE: float = 100.0
const GREED: float = 0.5
const REPUTATION: float = 0.3
const DRAIN: float = 25.0

func suite_name() -> String:
	return "Haggling"

func run(t) -> void:
	_test_opening_state(t)
	_test_paying_the_asking_price_always_works(t)
	_test_threshold_never_drops_below_floor(t)
	_test_floor_only_hardens(t)
	_test_insult_costs_more_than_a_plain_lowball(t)
	_test_skill_and_reputation_open_the_floor(t)
	_test_rage_quit_ends_the_deal(t)
	_test_rage_quit_is_never_the_best_price(t)
	_test_walkout_costs_reputation(t)
	_test_finished_session_is_inert(t)

func _new_session(
	speech: float = 0.0, charisma: float = 0.0, perk: bool = false, reputation: float = REPUTATION
) -> HagglingSession:
	return HagglingSession.new(BASE_PRICE, GREED, reputation, speech, charisma, DRAIN, perk)

## Aynı teklifi kabul edilene ya da masa devrilene kadar tekrarlayan bir
## oyuncu. Dönen değer anlaşılan fiyat, anlaşma olmazsa -1.
func _grind(offer: float, speech: float = 0.0, charisma: float = 0.0) -> float:
	var session := _new_session(speech, charisma)
	# Tur sayısı sabırla sınırlı; bu tavan yalnızca sonsuz döngü emniyeti.
	for _round in 64:
		session.submit_offer(offer)
		if session.state == HagglingSession.State.SUCCESS_DEAL:
			return session.final_price
		if session.state != HagglingSession.State.IN_PROGRESS:
			return -1.0
	return -1.0

## Sabırlı oyuncunun ulaşabileceği en iyi fiyat: teklif aralığını tarayıp
## anlaşmayla biten en düşük teklifi bulur. "İyi oynanan pazarlık" derken
## kastedilen bu.
func _best_patient_price(speech: float = 0.0, charisma: float = 0.0) -> float:
	var probe := _new_session(speech, charisma)
	var slider := probe.get_slider_range()
	var best := -1.0
	var steps := 200
	for index in steps + 1:
		var offer: float = slider.x + (slider.y - slider.x) * (float(index) / float(steps))
		var achieved := _grind(offer, speech, charisma)
		if achieved >= 0.0 and (best < 0.0 or achieved < best):
			best = achieved
	return best

func _test_opening_state(t) -> void:
	var session := _new_session()
	t.eq(session.state, HagglingSession.State.IN_PROGRESS, "pazarlık açık başlar")
	t.ok(
		is_equal_approx(session.p_start, BASE_PRICE * (1.0 + GREED * (1.0 - REPUTATION))),
		"açılış fiyatı açgözlülük ve itibardan türer"
	)
	t.ok(session.get_floor() < session.p_start, "tabanın üstünde pazarlık payı var")
	t.ok(session.get_floor() > 0.0, "taban asla bedavaya inmez")
	t.eq(session.rounds_used, 0, "henüz tur harcanmadı")

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

## Sömürünün kaynağı buydu: eşik sabırla birlikte tabanın *altına* iniyordu.
func _test_threshold_never_drops_below_floor(t) -> void:
	var session := _new_session()
	for patience in [100.0, 75.0, 50.0, 25.0, 10.0, 1.0, 0.0]:
		session.current_patience = patience
		t.ok(
			session.get_acceptable_threshold() >= session.get_floor() - 0.001,
			"sabır %d iken eşik tabanın altına inmez" % int(patience)
		)
		t.ok(
			session.get_acceptable_threshold() <= session.p_start + 0.001,
			"sabır %d iken eşik açılış fiyatını aşmaz" % int(patience)
		)

	session.current_patience = HagglingSession.DEFAULT_STARTING_PATIENCE
	t.ok(
		is_equal_approx(session.get_acceptable_threshold(), session.p_start),
		"sabır tamken tüccar hiçbir indirimi kabul etmez"
	)

## Uzatmanın bedeli: reddedilen her teklif pazarlık payını kapatır. Taban
## hiçbir koşulda yumuşamamalı - yumuşasaydı tur atmak bedava olurdu.
func _test_floor_only_hardens(t) -> void:
	var session := _new_session()
	var previous := session.get_floor()
	var lowball := session.get_floor() * 0.95

	for _round in 4:
		if session.state != HagglingSession.State.IN_PROGRESS:
			break
		session.submit_offer(lowball)
		var now := session.get_floor()
		t.ok(now >= previous - 0.001, "taban reddedilen teklifle sertleşir, yumuşamaz")
		previous = now

	t.ok(session.rounds_used > 0, "reddedilen teklifler tur olarak sayılır")
	t.ok(
		session.get_floor() > _new_session().get_floor(),
		"diretmek pazarlık payını gerçekten daraltır"
	)

	# Sertleşme sınırsız değil: taban açılış fiyatını geçemez, yoksa
	# pazarlık kendi kendini imkânsız hale getirirdi.
	var stubborn := _new_session()
	stubborn.rounds_used = 500
	t.ok(stubborn.get_floor() <= stubborn.p_start + 0.001, "taban açılış fiyatını aşamaz")

func _test_insult_costs_more_than_a_plain_lowball(t) -> void:
	var session := _new_session()
	var floor_now := session.get_floor()
	t.ok(session.is_insulting(floor_now * 0.5), "tabanın çok altı hakarettir")
	t.ok(not session.is_insulting(floor_now), "tabanın kendisi hakaret değildir")
	t.ok(not session.is_insulting(session.p_start), "istenen fiyat hakaret değildir")

	var insulting := _new_session()
	insulting.submit_offer(insulting.get_floor() * 0.5)
	var polite := _new_session()
	polite.submit_offer(polite.get_floor() * 1.05)

	t.ok(
		insulting.current_patience < polite.current_patience,
		"hakaret sabrı daha hızlı bitirir"
	)
	t.ok(
		insulting.rounds_used > polite.rounds_used,
		"hakaret tüccarı fazladan sertleştirir"
	)

func _test_skill_and_reputation_open_the_floor(t) -> void:
	var plain := _new_session()
	var talker := _new_session(8.0, 8.0)
	t.ok(talker.get_floor() < plain.get_floor(), "dili kuvvetli parti daha iyi taban açar")

	# İtibar iki yerden birden çalışır: hem açılış fiyatını hem tabanı
	# indirir. Ölçülen şey mutlak fiyat - orana bakmak yanıltıcı olurdu,
	# çünkü yabancıya kesilen şişkin açılış fiyatı oranı kendiliğinden
	# küçültür.
	var known := _new_session(0.0, 0.0, false, 1.0)
	var stranger := _new_session(0.0, 0.0, false, 0.0)
	t.ok(known.p_start < stranger.p_start, "tanınan kervana açılış fiyatı daha düşük çıkar")
	t.ok(known.get_floor() < stranger.get_floor(), "tanınan kervan daha ucuza anlaşabilir")

	# Beceri sınırsız indirim değil: taban oranının kendi dibi var.
	var master := HagglingSession.new(BASE_PRICE, GREED, 1.0, 1000.0, 1000.0, DRAIN, false)
	t.ok(
		master.get_floor() >= BASE_PRICE * HagglingSession.FLOOR_MIN_RATIO - 0.001,
		"beceri tabanı taban oranının altına indiremez"
	)

	var skilled_best := _best_patient_price(8.0, 8.0)
	var plain_best := _best_patient_price()
	t.ok(skilled_best > 0.0 and plain_best > 0.0, "iki oyuncu da anlaşabiliyor")
	t.ok(skilled_best < plain_best, "beceri somut para kazandırır")

func _test_rage_quit_ends_the_deal(t) -> void:
	var session := _new_session()
	var slider := session.get_slider_range()
	session.submit_offer(slider.x)
	t.eq(
		session.state, HagglingSession.State.ANGER_QUIT,
		"dip teklif tüccarı tek hamlede masadan kaldırır"
	)
	t.ok(is_zero_approx(session.final_price), "kopan pazarlıkta anlaşılan fiyat yok")

	# "Son teklif" hakkı bir kurtarma yolu: anlaşma sağlanır ama pahalıya.
	var perked := _new_session(0.0, 0.0, true)
	var perked_slider := perked.get_slider_range()
	perked.submit_offer(perked_slider.x)
	t.eq(perked.state, HagglingSession.State.FINAL_CHANCE, "son teklif hakkı devreye girer")

	perked.respond_to_final_offer(true)
	t.eq(perked.state, HagglingSession.State.SUCCESS_DEAL, "son teklif kabul edilebilir")
	t.ok(
		perked.final_price > perked.get_floor(),
		"öfkelenmiş tüccar tabanını değil şişirilmiş halini verir"
	)
	t.ok(perked.final_price <= perked.p_start + 0.001, "son teklif açılış fiyatını aşmaz")

	var refused := _new_session(0.0, 0.0, true)
	refused.submit_offer(refused.get_slider_range().x)
	refused.respond_to_final_offer(false)
	t.eq(refused.state, HagglingSession.State.ANGER_QUIT, "son teklif reddedilebilir")

## Paketin asıl iddiası. Öfkelendirerek alınan fiyat, sabırla pazarlık edilmiş
## en iyi fiyattan daha iyi olursa oyunun ekonomisi tek döngüde kırılır -
## eskiden tam olarak bu oluyordu.
func _test_rage_quit_is_never_the_best_price(t) -> void:
	var patient_best := _best_patient_price()
	t.ok(patient_best > 0.0, "sabırlı oyuncu anlaşabiliyor")
	t.ok(patient_best < _new_session().p_start, "sabırlı pazarlık gerçekten kazandırır")

	var rager := _new_session(0.0, 0.0, true)
	rager.submit_offer(rager.get_slider_range().x)
	rager.respond_to_final_offer(true)

	t.ok(
		rager.final_price > patient_best,
		"tüccarı çileden çıkarmak sabırla pazarlıktan daha iyi fiyat vermez"
	)

	# Perk'siz oyuncu için karşılaştırma daha da sert: hiç anlaşma yok.
	var bare := _new_session()
	bare.submit_offer(bare.get_slider_range().x)
	t.eq(bare.state, HagglingSession.State.ANGER_QUIT, "perk yoksa öfke anlaşmayı bitirir")

func _test_walkout_costs_reputation(t) -> void:
	var session := _new_session()
	t.ok(
		session.get_walkout_reputation_penalty() > 0,
		"masadan kalkmak bedava değil - yoksa kopana kadar denemek bedava bir döngü olurdu"
	)

func _test_finished_session_is_inert(t) -> void:
	var session := _new_session()
	session.submit_offer(session.p_start)
	var settled := session.final_price

	session.submit_offer(session.get_floor())
	t.ok(is_equal_approx(session.final_price, settled), "kapanmış pazarlık yeni teklif almaz")
	t.eq(session.state, HagglingSession.State.SUCCESS_DEAL, "kapanmış pazarlığın durumu değişmez")

	var quit_session := _new_session()
	quit_session.submit_offer(quit_session.get_slider_range().x)
	quit_session.respond_to_final_offer(true)
	t.eq(
		quit_session.state, HagglingSession.State.ANGER_QUIT,
		"son teklif hakkı olmayan oturumda cevap yok sayılır"
	)
