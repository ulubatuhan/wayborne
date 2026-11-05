extends SceneTree

## Oyuncu profili simülatörü (kullanıcı isteği, 2026-11-05).
##
## `simulate_career.gd` **bir politikanın** kariyer yayını ölçer: para nereye
## yatırılır, kontrat alınır mı. Bu araç farklı bir soruyu soruyor:
## **kim oynuyor ve o kişi keyif alıyor mu?**
##
## YÖNTEM VE KAYNAKLARI (ayrıntı + sınırları `docs/design_notes/oyuncu_profilleri.md`)
##
## 1. **Prosedürel persona** (Holmgård, Green, Liapis, Togelius; "Automated
##    Playtesting with Procedural Personas"): bir persona, tasarımcının
##    tarifinden çıkarılıp **fayda fonksiyonu** olarak yazılır ve oyunda
##    davranan bir etmene dönüşür. Buradaki her profil tam olarak budur:
##    olay kartının seçeneklerini kendi ağırlık tablosuyla puanlar.
## 2. **Gelişen persona** (Ariyurek, Surer, Betin-Can; "Playtesting: What is
##    Beyond Personas"): sabit persona oyuncunun zamanla değişmesini
##    kaçırır. Bu yüzden her profilin bir `adapt` alanı var: vagon
##    kaybedince, biri ölünce ya da kese dibe vurunca ağırlıklar kayıyor.
##    Ölçüm hem sabit hem gelişen hâli koşuyor ki fark görülebilsin.
## 3. **Güdü kümeleri** (Quantic Foundry'nin 12 güdüsü; altı küme:
##    Eylem, Sosyal, Ustalık, Başarı, Dalma, Yaratıcılık): profillerin
##    hangi memnuniyet ölçütüne ne kadar değer verdiğini bu kümeler
##    belirliyor. **Sınır:** model büyük örneklemli ama bağımsız hakemli
##    doğrulaması yok; burada bir ölçek olarak değil, ağırlıkları
##    gerekçelendiren bir çerçeve olarak kullanılıyor.
## 4. **Öz-belirleme kuramı / PENS** (Ryan, Rigby, Przybylski 2006;
##    Johnson, Gardner, Perry 2018'in kısmi doğrulaması): yetkinlik,
##    özerklik, ilişkililik. Üçü de burada **gözlemlenebilir** sayılara
##    bağlandı - özellikle özerklik: bir kartta oyuncunun kaç seçeneği
##    *gerçekten açıktı*. Bu, anket sormadan ölçülebilen en dürüst
##    özerklik göstergesi.
## 5. **Oyuncu tipi modellerinin sınırı** (Tondello ve ark.): BrainHex'in
##    yedi arketipi veriye bakınca üçe iniyor (eylem / estetik / hedef) ve
##    Bartle'ın dört tipi tip kuramından geliyor. Bu yüzden burada "tip"
##    iddiası yok: beş profil, Wayborne'un kendi karar noktalarına göre
##    seçilmiş **tasarım araçları**, bir sınıflandırma değil.
##
## Koşturmak:
##   godot --headless --script res://tests/simulate_personas.gd
##
## Test değil - hiç kırmızı dönmez, tablolar basar.

const LEGS: int = 24
const RUNS_PER_PERSONA: int = 3
const BASE_SEED: int = 515000
const STARTING_GOLD: int = 250
const STARTING_PROVISIONS: int = 20
const CASH_BUFFER: int = 180
## Yola çıkmadan önce en çok kaç gün çalışılır. Sınırsız olsaydı gündelik
## iş bir "bekle ve zengin ol" düğmesine dönerdi; kıtlıkta gün geçirmek
## zaten pahalı ama oyuncu da sonsuza kadar beklemez.
const LABOUR_DAY_CAP: int = 3

# --- Profiller ---------------------------------------------------------
#
# `weights`: olay seçeneğinin etkilerini puanlarken kullanılan katsayılar.
#   Pozitif = bu profil bunu ister, negatif = kaçınır.
# `motiv`: memnuniyet bileşkesini kurarken ölçütlerin ağırlığı (QF kümeleri).
# Her profilin gerekçesi `docs/design_notes/oyuncu_profilleri.md`'de.

const W_GOLD: String = "gold"
const W_PROVISIONS: String = "provisions"
const W_MORALE: String = "morale"
const W_STRESS: String = "stress"
const W_REPUTATION: String = "reputation"
const W_COMBAT: String = "combat"
const W_RISK: String = "risk"
const W_PEOPLE: String = "people"
const W_TIME: String = "time"

const PERSONAS: Array[Dictionary] = [
	{
		"id": "tuccar",
		"name": "Tüccar",
		"blurb": "Ustalık-Strateji. Her seferi bir hesap olarak görür; riski fiyatlandırır.",
		"weights": {
			W_GOLD: 1.0, W_PROVISIONS: 0.5, W_MORALE: 0.2, W_STRESS: -0.2,
			W_REPUTATION: 0.6, W_COMBAT: -0.8, W_RISK: -0.6, W_PEOPLE: 0.1, W_TIME: -0.5,
		},
		"motiv": {"ustalik": 1.0, "basari": 0.8, "yetkinlik": 0.9, "ozerklik": 0.6, "anlati": 0.2},
		"pace": 1.0, "haggle": true, "barter": true, "advance": true, "expand": true,
		"feed_all": false, "reads_planner": true,
	},
	{
		"id": "hikayeci",
		"name": "Hikâyeci",
		"blurb": "Dalma-Hikâye. Deftere ne yazıldığıyla ilgilenir; sayıya değil ize bakar.",
		"weights": {
			W_GOLD: 0.1, W_PROVISIONS: 0.4, W_MORALE: 0.7, W_STRESS: -0.5,
			W_REPUTATION: 0.3, W_COMBAT: -0.2, W_RISK: 0.3, W_PEOPLE: 1.0, W_TIME: 0.2,
		},
		"motiv": {"ustalik": 0.2, "basari": 0.3, "yetkinlik": 0.4, "ozerklik": 0.9, "anlati": 1.0},
		"pace": 0.85, "haggle": false, "barter": true, "advance": false, "expand": false,
		"feed_all": true, "reads_planner": false,
	},
	{
		"id": "hayatta_kalan",
		"name": "Hayatta Kalan",
		"blurb": "Ustalık-Meydan okuma. Zorluğu arar; kıtlığı bir bulmaca değil bir sınav sayar.",
		"weights": {
			W_GOLD: 0.3, W_PROVISIONS: 0.9, W_MORALE: 0.3, W_STRESS: -0.1,
			W_REPUTATION: 0.1, W_COMBAT: 0.6, W_RISK: 0.8, W_PEOPLE: 0.2, W_TIME: -0.3,
		},
		"motiv": {"ustalik": 1.0, "basari": 0.5, "yetkinlik": 1.0, "ozerklik": 0.7, "anlati": 0.4},
		"pace": 1.15, "haggle": true, "barter": true, "advance": true, "expand": false,
		"feed_all": false, "reads_planner": true,
	},
	{
		"id": "tamamlayici",
		"name": "Tamamlayıcı",
		"blurb": "Başarı-Tamamlama. Listeyi kapatmak ister: her kontrat, her şehir, her kart.",
		"weights": {
			W_GOLD: 0.6, W_PROVISIONS: 0.5, W_MORALE: 0.3, W_STRESS: -0.2,
			W_REPUTATION: 1.0, W_COMBAT: 0.1, W_RISK: 0.2, W_PEOPLE: 0.4, W_TIME: -0.6,
		},
		"motiv": {"ustalik": 0.6, "basari": 1.0, "yetkinlik": 0.7, "ozerklik": 0.5, "anlati": 0.5},
		"pace": 1.1, "haggle": true, "barter": true, "advance": true, "expand": true,
		"feed_all": false, "reads_planner": true,
	},
	{
		"id": "merhametli",
		"name": "Merhametli",
		"blurb": "İlişkililik. Bedeli kim ödüyor diye sorar; ucuz çözümü seçmez.",
		"weights": {
			W_GOLD: -0.1, W_PROVISIONS: 0.3, W_MORALE: 0.9, W_STRESS: -0.8,
			W_REPUTATION: 0.4, W_COMBAT: -0.9, W_RISK: -0.2, W_PEOPLE: 1.2, W_TIME: 0.3,
		},
		"motiv": {"ustalik": 0.2, "basari": 0.3, "yetkinlik": 0.5, "ozerklik": 1.0, "anlati": 0.9},
		"pace": 0.9, "haggle": false, "barter": true, "advance": false, "expand": false,
		"feed_all": true, "reads_planner": false,
	},
]

# --- Koşu ---------------------------------------------------------------

var _catalog_events: Array[GameEvent] = []

## `--iz <profil>`: tek bir koşuyu sefer sefer basar. Bir rapor şaşırtıcıysa
## önce ölçüm aracından şüphelen - bu kip o şüpheyi ucuzlatıyor.
var _trace_id: String = ""
## `--ablasyon`: bir profilin üç davranışını tek tek çevirip hangisinin
## kervanı öldürdüğünü ayırır. Profil tablosu "Hikâyeci üçüncü seferde
## ölüyor" diyor ama **neden** demiyor; üç aday birlikte değişiyor
## (planlayıcıyı okumamak, herkesi beslemek, pazarlık etmemek). Bu kip
## üçünü ayırıyor - tek değişkenli karşılaştırma, kendi küçük çalışmamız.
var _ablation: bool = false

const ABLATION_FLAGS: Array[String] = ["reads_planner", "feed_all", "haggle"]
const ABLATION_RUNS: int = 4

func _initialize() -> void:
	TranslationServer.set_locale("tr")
	_catalog_events = EventCatalog.get_road_events()
	var args := OS.get_cmdline_user_args()
	for index in args.size():
		if String(args[index]) == "--iz" and index + 1 < args.size():
			_trace_id = String(args[index + 1])
		if String(args[index]) == "--ablasyon":
			_ablation = true
	print("── Wayborne oyuncu profili simülasyonu (%d profil × %d koşu × %d sefer)"
		% [PERSONAS.size(), RUNS_PER_PERSONA, LEGS])
	print("   Yöntem: prosedürel persona (fayda fonksiyonu) + gelişen persona;")
	print("   memnuniyet ölçütleri ÖBK/PENS ve QF güdü kümelerine bağlandı.")

	if _ablation:
		_run_ablation()
		quit()
		return
	var rows: Array[Dictionary] = []
	for persona in PERSONAS:
		for adaptive in [false, true]:
			var runs: Array[Dictionary] = []
			for index in RUNS_PER_PERSONA:
				runs.append(_run_persona(persona, BASE_SEED + index * 1013, adaptive))
			rows.append(_average(persona, runs, adaptive))
	_report(rows)
	quit()

## Hikâyeci'nin üç davranışı tek tek çevrilir; ölçülen şey kaç sefer
## dayandığı. Taban = profilin kendisi; her satır yalnız bir bayrak farklı.
func _run_ablation() -> void:
	print("")
	print("── Ablasyon: hangi davranış kervanı öldürüyor? (Hikâyeci, %d koşu)" % ABLATION_RUNS)
	print("   değişiklik                 sefer  açgün  ölüm  teslim  kese")
	var base: Dictionary = {}
	for persona in PERSONAS:
		if String(persona["id"]) == "hikayeci":
			base = persona
			break
	var variants: Array[Dictionary] = [{"label": "taban (Hikâyeci)", "flags": {}}]
	for flag in ABLATION_FLAGS:
		variants.append({
			"label": "%s = %s" % [flag, not bool(base[flag])],
			"flags": {flag: not bool(base[flag])},
		})
	variants.append({
		"label": "üçü birden (Tüccar gibi)",
		"flags": {"reads_planner": true, "feed_all": false, "haggle": true},
	})
	for variant in variants:
		var persona := base.duplicate(true)
		for key in (variant["flags"] as Dictionary):
			persona[key] = (variant["flags"] as Dictionary)[key]
		var runs: Array[Dictionary] = []
		for index in ABLATION_RUNS:
			runs.append(_run_persona(persona, BASE_SEED + index * 1013, false))
		var row := _average(persona, runs, false)
		print("   %-24s  %5.1f  %5.1f  %4.1f  %6.1f  %5.0f" % [
			variant["label"], row["sefer"], row["ac_gun"], row["olum"],
			row["teslimat"], row["kese"],
		])

func _run_persona(persona: Dictionary, seed_value: int, adaptive: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var session := GameSession.new(STARTING_GOLD, STARTING_PROVISIONS, 1)
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.inherit_father_caravan()

	var state := {
		"weights": (persona["weights"] as Dictionary).duplicate(),
		"adaptive": adaptive,
		# Ölçütler
		"cards": 0, "unique": {}, "options_open": 0, "forced": 0,
		"checks": 0, "checks_passed": 0,
		"starved_days": 0, "neglect_days": 0, "deaths": 0, "lost_wagons": 0,
		"morale_min": 100, "run_over_at": -1, "labour_days": 0,
		"legs": 0, "legs_improved": 0, "blocked_departures": 0,
		"purse_start": session.wallet.balance,
		"shocks": 0,
	}

	var tracing := _trace_id == String(persona["id"]) and not adaptive
	if tracing:
		print("")
		print("── iz: %s (tohum %d)" % [persona["name"], seed_value])
		print("   sefer  gün  yol                 gün  kontrat  kese  erzak  parti  kart")
	for leg in LEGS:
		# **Koşu bittiyse dur.** İlk sürüm bunu sormuyordu ve ölen bir
		# kervan on dokuz sefer daha "koşuyor", ortalamaları boş
		# seferlerle sulandırıyordu. İz kipi bunu tek bakışta gösterdi:
		# "start_journey: run is over" satırı art arda on dokuz kez.
		if session.is_run_over():
			state["run_over_at"] = leg
			break
		var before := _snapshot(session)
		var cards_before := int(state["cards"])
		var ran := _run_leg(session, persona, state, rng, tracing)
		if tracing and ran:
			print("   %5d  %3d  %-18s  %3d  %7d  %4d  %5d  %5d  %4d" % [
				leg + 1, session.total_days_elapsed, session.current_location_id,
				session.journeys_completed, session.contracts_delivered,
				session.wallet.balance, session.get_provisions(),
				session.get_party().size(), int(state["cards"]) - cards_before,
			])
		if not ran:
			state["blocked_departures"] = int(state["blocked_departures"]) + 1
			break
		state["legs"] = int(state["legs"]) + 1
		var after := _snapshot(session)
		if _is_better(persona, before, after):
			state["legs_improved"] = int(state["legs_improved"]) + 1
		if adaptive:
			_adapt(persona, state, before, after)

	return _measure(session, state)

## Personanın kendi gözünden "sefer iyi geçti mi": herkesin ölçütü farklı.
## Tüccar keseye, Hikâyeci deftere, Hayatta Kalan erzağa, Tamamlayıcı
## teslimata, Merhametli morale bakar.
func _is_better(persona: Dictionary, before: Dictionary, after: Dictionary) -> bool:
	match String(persona["id"]):
		"tuccar":
			return int(after["gold"]) > int(before["gold"])
		"hikayeci":
			return int(after["ledger"]) > int(before["ledger"])
		"hayatta_kalan":
			return int(after["provisions"]) >= int(before["provisions"]) and int(after["party"]) >= int(before["party"])
		"tamamlayici":
			return int(after["contracts"]) > int(before["contracts"]) or int(after["cities"]) > int(before["cities"])
		_:
			return int(after["morale"]) >= int(before["morale"]) and int(after["party"]) >= int(before["party"])

func _snapshot(session: GameSession) -> Dictionary:
	return {
		"gold": session.wallet.balance,
		"provisions": session.get_provisions(),
		"ledger": session.ledger.entries.size(),
		"contracts": session.contracts_delivered,
		"cities": session.visited_location_ids.size(),
		"morale": session.caravan.morale,
		"party": session.get_party().size(),
		"wagons": session.owned_wagon_count,
	}

## Gelişen persona (Ariyurek ve ark.): sert bir darbeden sonra ağırlıklar
## kayar. Sabit persona bunu kaçırır - gerçek oyuncu bir vagon kaybettikten
## sonra aynı oyuncu değildir.
const ADAPT_STEP: float = 0.35

func _adapt(persona: Dictionary, state: Dictionary, before: Dictionary, after: Dictionary) -> void:
	var weights: Dictionary = state["weights"]
	var hurt := int(after["party"]) < int(before["party"]) \
		or int(after["wagons"]) < int(before["wagons"]) \
		or int(after["gold"]) < 0
	if hurt:
		# Canı yanan oyuncu riskten kaçar ve erzağa sarılır - profil ne
		# olursa olsun. Ama kendi ekseninden vazgeçmez, yalnız eğilir.
		weights[W_RISK] = float(weights.get(W_RISK, 0.0)) - ADAPT_STEP
		weights[W_COMBAT] = float(weights.get(W_COMBAT, 0.0)) - ADAPT_STEP * 0.5
		weights[W_PROVISIONS] = float(weights.get(W_PROVISIONS, 0.0)) + ADAPT_STEP * 0.5
		return
	# Üst üste iyi giden oyuncu cesaretlenir.
	if int(after["gold"]) > int(before["gold"]) + 150:
		weights[W_RISK] = float(weights.get(W_RISK, 0.0)) + ADAPT_STEP * 0.4
		weights[W_GOLD] = float(weights.get(W_GOLD, 0.0)) + ADAPT_STEP * 0.2

# --- Bir sefer ----------------------------------------------------------

func _run_leg(
	session: GameSession, persona: Dictionary, state: Dictionary,
	rng: RandomNumberGenerator, tracing: bool = false
) -> bool:
	var origin := WorldMapData.get_location_by_id(session.current_location_id)
	if origin == null:
		return false
	var open_routes: Array[TravelRoute] = []
	for candidate in WorldMapData.get_routes_from(session.current_location_id):
		if session.is_route_open(candidate):
			open_routes.append(candidate)
	if open_routes.is_empty():
		return false

	var route := _pick_route(session, persona, open_routes, rng)
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	if destination == null:
		return false

	_sell(session, origin, persona, state)
	var travel_days := session.get_route_travel_days(route)
	var plan := _build_plan(session, persona, destination, travel_days)
	if tracing:
		print("          -> %s (%d gün, %d kontrat, erzak gereği %d, rafta %d, kese %d)" % [
			destination.location_id, travel_days, plan.get_selected_offers().size(),
			plan.get_provisions_shortfall(session.get_provisions()),
			session.get_provision_stock(), session.wallet.balance,
		])
	_buy(session, origin, persona, plan.get_contract_cargo_load())
	_stock_provisions(session, persona, plan, state)
	if bool(persona["expand"]):
		_spend_surplus(session)

	session.depart_with_contracts(plan.get_selected_offers())
	session.start_journey(
		destination.location_id, travel_days, session.get_route_danger(route), plan
	)
	_travel(session, persona, state, travel_days, rng)
	session.finish_journey()
	return true

## Yol seçimi profile göre: Tamamlayıcı görülmemiş şehre, Tüccar işin
## olduğu yere, Hayatta Kalan kısa ve güvenli olana, Hikâyeci merak ettiğine.
func _pick_route(
	session: GameSession, persona: Dictionary, routes: Array[TravelRoute], rng: RandomNumberGenerator
) -> TravelRoute:
	var best: Array[TravelRoute] = []
	var best_score := -9999.0
	var board := session.get_contract_board()
	for candidate in routes:
		var score := 0.0
		# **Planlayıcıyı okuyan oyuncu** uzun yolu erzak yetmiyorsa seçmez.
		# Okumayan oyuncu seçer - ve bu, ölçülmesi gereken şeyin ta
		# kendisi: oyun sayıya bakmayan oyuncuyu ilk seferde öldürüyor mu?
		if bool(persona.get("reads_planner", true)):
			var need := _provisions_needed_for(session, candidate)
			var reachable := session.get_provisions() + _affordable_provisions(session)
			if need > reachable:
				score -= 100.0 * float(need - reachable) / float(maxi(1, need))
		var contracts := 0
		for offer in board:
			if offer.destination_location_id == candidate.to_location_id and offer.is_open_to(session.reputation):
				contracts += 1
		var unseen := not session.visited_location_ids.has(candidate.to_location_id)
		match String(persona["id"]):
			"tuccar":
				score = float(contracts) * 2.0 - float(session.get_route_travel_days(candidate)) * 0.4
			"tamamlayici":
				score = float(contracts) * 1.5 + (3.0 if unseen else 0.0)
			"hayatta_kalan":
				score = -float(session.get_route_danger(candidate)) * 1.5 + float(contracts)
			"hikayeci":
				score = (2.5 if unseen else 0.0) + float(contracts) * 0.5
			_:
				score = float(contracts) + (1.0 if unseen else 0.0)
		if score > best_score:
			best_score = score
			best = [candidate]
		elif is_equal_approx(score, best_score):
			best.append(candidate)
	return best[rng.randi_range(0, best.size() - 1)]

## Bu yola çıkmak kaç erzak ister: planlayıcının gösterdiği sayı.
func _provisions_needed_for(session: GameSession, route: TravelRoute) -> int:
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	if destination == null:
		return 0
	var plan := CaravanPlan.new(
		destination, session.get_route_travel_days(route),
		session.get_wagon_capacity(), session.owned_wagon_count
	)
	plan.caravan_party_size = session.get_party().size()
	plan.provision_multiplier = session.get_daily_provision_multiplier()
	plan.provision_reduction = session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI)
	return plan.get_provisions_shortfall(0)

## Bu şehirde kese ve raf birlikte kaç erzak veriyor (P5'ten sonra ikisi de
## sınır).
func _affordable_provisions(session: GameSession) -> int:
	var by_purse := int(floor(float(maxi(0, session.wallet.balance)) / float(maxi(1, GameSession.PROVISIONS_UNIT_PRICE))))
	return mini(by_purse, maxi(0, session.get_provision_stock()))

func _build_plan(
	session: GameSession, persona: Dictionary, destination: Location, travel_days: int
) -> CaravanPlan:
	var plan := CaravanPlan.new(
		destination, travel_days, session.get_wagon_capacity(), session.owned_wagon_count
	)
	plan.caravan_party_size = session.get_party().size()
	plan.provision_multiplier = session.get_daily_provision_multiplier()
	plan.provision_reduction = session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI)
	plan.cargo_room = session.get_cargo_space_remaining()
	var taken := 0
	for offer in session.get_contract_board():
		if offer.destination_location_id != destination.location_id:
			continue
		if not offer.is_open_to(session.reputation):
			continue
		if not plan.can_add_offer(offer):
			continue
		# Tamamlayıcı panoyu boşaltır; öbürleri taşıyabildiğini alır.
		if String(persona["id"]) != "tamamlayici" and taken >= 2:
			break
		session.accept_contract(offer)
		plan.toggle_merchant(offer)
		taken += 1
	return plan

func _stock_provisions(
	session: GameSession, persona: Dictionary, plan: CaravanPlan, state: Dictionary
) -> void:
	# Profil başına güvenlik payı: Hayatta Kalan fazla alır, Tüccar ucu ucuna.
	var margin := 1.0
	match String(persona["id"]):
		"hayatta_kalan":
			margin = 1.6
		"merhametli":
			margin = 1.3
		"tuccar":
			margin = 1.05
		_:
			margin = 1.2
	var shortfall := plan.get_provisions_shortfall(session.get_provisions())
	# Güvenlik payı profilin: Hayatta Kalan fazla alır, Tüccar ucu ucuna.
	var wanted := int(ceil(float(maxi(0, shortfall)) * margin))
	if wanted <= 0:
		return
	# **Pazarın kapısından**: erzak artık şehirde tükeniyor (P5), kese
	# yetse bile raf yetmeyebilir.
	session.buy_provisions(wanted)

	# --- Planlayıcının yeni sunduğu iki seçenek (Ö2, Ö3) ---
	#
	# Bunlar persona "zekâsı" değil, **ekranın sunduğu şey**: ikisi de
	# yalnız erzak eksikken, tam o ekranda, gözün gittiği yerde duruyor.
	# Etmen yalnız oradakini kullanıyor.
	if plan.get_provisions_shortfall(session.get_provisions()) <= 0:
		return

	# Ö2: sofra kipinin günlük bedeli artık yan yana yazılı. Hâlâ açsa ve
	# herkesi besliyorsa, oyuncu o satırı görüp kipi kısar.
	if session.meal_policy_mode == GameSession.MEAL_MODE_ALL:
		session.set_meal_policy(GameSession.MEAL_MODE_PARTY_ONLY)
		var left := plan.get_provisions_shortfall(session.get_provisions())
		if left > 0:
			session.buy_provisions(left)

	# Ö3: "Bir gün çalış" düğmesi. Zaman öder, para değil; gün geçtiği
	# için bedava değil - en fazla birkaç gün, sonra yola çıkılır.
	var worked := 0
	while worked < LABOUR_DAY_CAP \
			and plan.get_provisions_shortfall(session.get_provisions()) > 0 \
			and session.can_work_a_day():
		if session.work_a_day() <= 0:
			break
		worked += 1
		state["labour_days"] = int(state["labour_days"]) + 1
		session.buy_provisions(plan.get_provisions_shortfall(session.get_provisions()))

func _spend_surplus(session: GameSession) -> void:
	if session.wallet.balance > CASH_BUFFER and session.can_buy_wagon():
		session.buy_wagon()

# --- Şehirdeki alışveriş (pazar ekranının kapılarından) -----------------

func _sell(session: GameSession, origin: Location, persona: Dictionary, state: Dictionary) -> void:
	for entry in session.get_total_inventory_entries().duplicate():
		var item: Item = (entry as Dictionary).item
		if item == null or item.item_id == GameSession.PROVISIONS_ITEM_ID:
			continue
		if not origin.demands.has(item.item_id):
			continue
		var quantity := session.get_total_quantity(item.item_id)
		if quantity <= 0:
			continue
		# Merhametli ve Hikâyeci krizden kâr etmez: vurgun olacak satışı
		# hiç yapmaz (P14'ün ölçtüğü şeyin oyuncu tarafı).
		if not bool(persona["haggle"]) and session.is_profiteering_sale(item.item_id):
			continue
		var unit := session.capped_sell_price(item.item_id, MarketPricing.get_sell_price(
			item, origin, session.market, session.total_days_elapsed
		))
		var affordable := int(floor(float(session.get_city_gold_reserve()) / float(maxi(1, unit))))
		quantity = mini(quantity, affordable)
		if quantity <= 0:
			continue
		session.remove_from_cargo_or_bags(item.item_id, quantity)
		session.wallet.earn(unit * quantity)
		session.record_sale(item.item_id, quantity, unit * quantity)

func _buy(session: GameSession, origin: Location, persona: Dictionary, reserved_room: float) -> void:
	for item_id in origin.produces:
		var item := ItemCatalog.get_item(item_id)
		if item == null:
			continue
		var unit := maxi(1, int(round(float(MarketPricing.get_buy_price(
			item, origin, session.market, session.total_days_elapsed
		)) * Scarcity.buy_factor(item_id, session.scarcity_here()))))
		var share := 0.4 if bool(persona["haggle"]) else 0.25
		var affordable := int(floor(float(session.wallet.balance) * share / float(unit)))
		var by_space := int(floor(maxf(0.0, session.get_cargo_space_remaining() - reserved_room) / maxf(0.1, item.unit_weight)))
		var quantity := mini(mini(affordable, by_space), session.get_market_stock(item_id))
		if quantity <= 0:
			continue
		if session.add_to_cargo(item, quantity):
			session.consume_stock(item_id, quantity, unit * quantity)
			session.wallet.spend(unit * quantity)

# --- Yol ----------------------------------------------------------------

func _travel(
	session: GameSession, persona: Dictionary, state: Dictionary,
	total_days: int, rng: RandomNumberGenerator
) -> void:
	var engine := EventEngine.new(_catalog_events, rng.randi())
	var day := 0
	while session.journey_days_remaining > 0:
		day += 1
		session.journey_days_remaining -= 1
		_consume_daily(session, persona, state)
		var event := engine.roll_for_day(day, session.build_event_context())
		if event == null:
			continue
		engine.mark_fired(event, day)
		_resolve(session, engine, event, persona, state, rng)

## Günün geçişi **oyunun kendi sofrasından**. İlk sürüm `change_provisions`
## ile elle besliyordu ve 24 seferde 292 aç gün + moral 100 çıkıyordu -
## imkânsız bir çift. Sebep oyunda değil araçtaydı: açlığın bedelini,
## ölümü ve moral düşüşünü `apply_meal_distribution` uyguluyor; elle
## beslemek o kapıyı atlıyordu. (Aynı ders P8'de de öğrenildi: ekranın
## kapılarından geçmeyen bir simülatör var olmayan bir oyunu ölçer.)
func _consume_daily(session: GameSession, persona: Dictionary, state: Dictionary) -> void:
	session.advance_day()
	var mode := GameSession.MEAL_MODE_ALL if bool(persona["feed_all"]) else GameSession.MEAL_MODE_PARTY_ONLY
	var result := session.apply_meal_distribution(mode)
	# **İki ayrı şey, ilk sürümde birbirine karışmıştı.** `crew_hungry`
	# PARTY_ONLY kipinde her gün doğrudur - tayfayı beslememek bir
	# başarısızlık değil bir *karar*. Onu acı sayınca Hayatta Kalan 300
	# günün 249'unda "aç" görünüyordu. Gerçek açlık, beslemeyi seçtiğin
	# birinin yiyecek bulamaması: `hungry_names`.
	if not (result.get("hungry_names", []) as Array).is_empty():
		state["starved_days"] = int(state["starved_days"]) + 1
	if bool(result.get("crew_hungry", false)):
		state["neglect_days"] = int(state["neglect_days"]) + 1
	state["morale_min"] = mini(int(state["morale_min"]), session.caravan.morale)
	var death_outcome: Dictionary = result.get("death_outcome", {})
	var dead: Array = death_outcome.get("dead_names", [])
	if not dead.is_empty():
		state["deaths"] = int(state["deaths"]) + dead.size()

## Kararın kendisi: personanın fayda fonksiyonu seçenekleri puanlar.
## **Özerklik ölçümü burada:** kaç seçenek gerçekten açıktı.
func _resolve(
	session: GameSession, engine: EventEngine, event: GameEvent,
	persona: Dictionary, state: Dictionary, rng: RandomNumberGenerator
) -> void:
	var context := session.build_event_context()
	var available: Array[EventChoice] = []
	for choice in event.choices:
		if choice.is_available(context):
			available.append(choice)
	state["cards"] = int(state["cards"]) + 1
	(state["unique"] as Dictionary)[event.event_id] = true
	state["options_open"] = int(state["options_open"]) + available.size()
	if available.size() <= 1:
		state["forced"] = int(state["forced"]) + 1
	if available.is_empty():
		return

	var best: EventChoice = available[0]
	var best_score := -99999.0
	for choice in available:
		var score := _score(choice, state["weights"], rng)
		if score > best_score:
			best_score = score
			best = choice
	if best.check != null:
		state["checks"] = int(state["checks"]) + 1
	var before_party := session.get_party().size()
	var before_wagons := session.owned_wagon_count
	EventResolver.resolve_choice(session, engine, event, best)
	if best.check != null and session.get_party().size() >= before_party:
		state["checks_passed"] = int(state["checks_passed"]) + 1
	if session.get_party().size() < before_party:
		state["deaths"] = int(state["deaths"]) + (before_party - session.get_party().size())
	if session.owned_wagon_count < before_wagons:
		state["lost_wagons"] = int(state["lost_wagons"]) + (before_wagons - session.owned_wagon_count)

## Bir seçeneğin personaya göre değeri. Garanti etkiler tam, olasılıklı
## sonuçlar ağırlıklarıyla sayılır - oyuncu da kartı okurken böyle yapar.
func _score(choice: EventChoice, weights: Dictionary, rng: RandomNumberGenerator) -> float:
	var score := _score_effects(choice.effects, weights)
	var total_weight := 0.0
	var outcome_score := 0.0
	for outcome in choice.outcomes:
		var w := maxf(0.01, outcome.weight)
		total_weight += w
		outcome_score += w * _score_effects(outcome.effects, weights)
	if total_weight > 0.0:
		score += outcome_score / total_weight
		# Belirsizliğin kendisi bir maliyet ya da çekim: riske bakış profilin.
		score += float(weights.get(W_RISK, 0.0)) * minf(1.0, float(choice.outcomes.size()) * 0.5)
	# Eşitlikte kura: aynı puanlı iki seçenek arasında donup kalmasın.
	return score + rng.randf() * 0.01

func _score_effects(effects: Array[EventEffect], weights: Dictionary) -> float:
	var score := 0.0
	for effect in effects:
		var amount := float(effect.amount)
		match effect.type:
			EventEffect.Type.GOLD:
				score += amount * 0.02 * float(weights.get(W_GOLD, 0.0))
			EventEffect.Type.PROVISIONS:
				score += amount * 0.25 * float(weights.get(W_PROVISIONS, 0.0))
			EventEffect.Type.MORALE:
				score += amount * 0.1 * float(weights.get(W_MORALE, 0.0))
			EventEffect.Type.STRESS:
				score += amount * 0.1 * float(weights.get(W_STRESS, 0.0))
			EventEffect.Type.REPUTATION:
				score += amount * 0.5 * float(weights.get(W_REPUTATION, 0.0))
			EventEffect.Type.PARTY_HP:
				score += amount * 0.08 * float(weights.get(W_PEOPLE, 0.0))
			EventEffect.Type.TRAVEL_DAYS:
				score += amount * -0.6 * float(weights.get(W_TIME, 0.0))
			EventEffect.Type.DANGER:
				score += amount * -0.8 * float(weights.get(W_RISK, 0.0))
			EventEffect.Type.TRIGGER_COMBAT:
				score += 3.0 * float(weights.get(W_COMBAT, 0.0))
			EventEffect.Type.WAGON_DAMAGE:
				score -= 1.5
			EventEffect.Type.WAGON_LOSE:
				score -= 6.0
			EventEffect.Type.LEAVE_BEHIND:
				score -= 4.0 * maxf(0.3, float(weights.get(W_PEOPLE, 0.0)))
			EventEffect.Type.MERCHANT_LEAVE:
				score -= 2.0
			EventEffect.Type.TRIGGER_RECRUIT:
				score += 1.5 * float(weights.get(W_PEOPLE, 0.0))
			EventEffect.Type.GRANT_EQUIPMENT:
				score += 1.0
			EventEffect.Type.ITEM_ADD:
				score += 0.8 * float(weights.get(W_GOLD, 0.0))
			EventEffect.Type.ITEM_REMOVE:
				score -= 0.8 * float(weights.get(W_GOLD, 0.0))
			_:
				score += 0.0
	return score

# --- Ölçüm --------------------------------------------------------------

func _measure(session: GameSession, state: Dictionary) -> Dictionary:
	var cards := maxi(1, int(state["cards"]))
	var legs := maxi(1, int(state["legs"]))
	var regard := 0
	for id in session.people.persons:
		regard += People.regard(session.people.persons[id])
	return {
		# ÖBK/PENS: özerklik = kartta gerçekten açık olan seçenek sayısı.
		"ozerklik": float(state["options_open"]) / float(cards),
		"zorunlu": float(state["forced"]) / float(cards),
		# ÖBK/PENS: yetkinlik = kendi ölçütüne göre iyi biten sefer payı.
		"yetkinlik": float(state["legs_improved"]) / float(legs),
		# QF Dalma-Hikâye: deftere düşen satır ve adı olan kişilerle bağ.
		"anlati": float(session.ledger.entries.size()) / float(legs),
		"baglar": float(regard),
		# QF Başarı-Tamamlama.
		"teslimat": float(session.contracts_delivered),
		"sehir": float(session.visited_location_ids.size()),
		"farkli_kart": float((state["unique"] as Dictionary).keys().size()),
		# Hüsran göstergeleri.
		"ac_gun": float(state["starved_days"]),
		"ihmal": float(state["neglect_days"]),
		"isgunu": float(state["labour_days"]),
		"moral_dip": float(state["morale_min"]),
		"olum": float(state["deaths"]),
		"vagon_kaybi": float(state["lost_wagons"]),
		"kapali_cikis": float(state["blocked_departures"]),
		# Kervanın bittiği sefer (-1: bitmedi). Bir profilin oyunu
		# *tamamlayıp tamamlayamadığı* en ham memnuniyet göstergesi.
		"bitti": float(state["run_over_at"]),
		# Bağlam.
		"sefer": float(state["legs"]),
		"kart": float(state["cards"]),
		"kese": float(session.wallet.balance),
		"borc": float(session.get_total_debt()),
		"itibar": float(session.reputation),
		"moral": float(state["morale_min"]),
	}

func _average(persona: Dictionary, runs: Array[Dictionary], adaptive: bool) -> Dictionary:
	var out := {"id": persona["id"], "name": persona["name"], "adaptive": adaptive}
	# `bitti`nin ortalaması yanıltıcıydı: bitmeyen koşu -1 taşıyor ve
	# ortalamada gerçek bir sefer numarasıymış gibi görünüyordu. Doğru
	# soru "kaç koşu bitti".
	var ended := 0
	for run in runs:
		if float(run["bitti"]) >= 0.0:
			ended += 1
	out["biten_kosu"] = float(ended)
	var keys: Array = runs[0].keys()
	for key in keys:
		var total := 0.0
		for run in runs:
			total += float(run[key])
		out[key] = total / float(runs.size())
	out["keyif"] = _enjoyment(persona, out)
	return out

## Memnuniyet bileşkesi: profilin güdü ağırlıklarıyla ölçütlerin çarpımı,
## 0-100'e ölçeklenmiş. **Bu bir anket puanı değil**, profilin kendi
## değer verdiği şeylerin ne kadar gerçekleştiğinin özeti; karşılaştırma
## için anlamlı, mutlak bir "oyun şu kadar eğlenceli" iddiası için değil.
func _enjoyment(persona: Dictionary, row: Dictionary) -> float:
	var motiv: Dictionary = persona["motiv"]
	var parts := {
		"ustalik": clampf(float(row["yetkinlik"]), 0.0, 1.0),
		"basari": clampf(float(row["teslimat"]) / 24.0, 0.0, 1.0) * 0.6
			+ clampf(float(row["sehir"]) / 14.0, 0.0, 1.0) * 0.4,
		"yetkinlik": clampf(float(row["yetkinlik"]), 0.0, 1.0),
		"ozerklik": clampf((float(row["ozerklik"]) - 1.0) / 2.0, 0.0, 1.0),
		"anlati": clampf(float(row["anlati"]) / 6.0, 0.0, 1.0) * 0.7
			+ clampf(float(row["farkli_kart"]) / 40.0, 0.0, 1.0) * 0.3,
	}
	var score := 0.0
	var total := 0.0
	for key in motiv:
		score += float(motiv[key]) * float(parts.get(key, 0.0))
		total += float(motiv[key])
	var base := 100.0 * score / maxf(0.001, total)
	# Hüsran doğrudan düşer: aç geçen gün ve kaybedilen vagon her profili
	# yorar, ama Merhametli ölümden, Tüccar vagondan daha çok etkilenir.
	var pain := float(row["ac_gun"]) * 0.8 + float(row["vagon_kaybi"]) * 2.0
	pain += float(row["olum"]) * (6.0 if String(persona["id"]) == "merhametli" else 3.0)
	pain += float(row["kapali_cikis"]) * 10.0
	return maxf(0.0, base - pain)

func _report(rows: Array[Dictionary]) -> void:
	print("")
	print("── Profil tablosu (ortalama, %d koşu)" % RUNS_PER_PERSONA)
	print("   profil            kip     keyif  sefer  ölen  özerk  yetkin  teslim  şehir  kart  açgün  işgün  ölüm")
	for row in rows:
		print("   %-16s  %-6s  %5.1f  %5.1f  %5s  %5.2f  %6.2f  %6.1f  %5.1f  %4.1f  %5.1f  %5.1f  %4.1f" % [
			row["name"], "gelişen" if bool(row["adaptive"]) else "sabit",
			row["keyif"], row["sefer"],
			"%d/%d" % [int(row["biten_kosu"]), RUNS_PER_PERSONA],
			row["ozerklik"], row["yetkinlik"], row["teslimat"], row["sehir"],
			row["farkli_kart"], row["ac_gun"], row["isgunu"], row["olum"],
		])
	print("")
	print("── Sefer sonu durumu")
	print("   profil            kip     sefer   kese   borç  itibar  moral")
	for row in rows:
		print("   %-16s  %-6s  %5.1f  %5.0f  %5.0f  %6.1f  %5.1f" % [
			row["name"], "gelişen" if bool(row["adaptive"]) else "sabit",
			row["sefer"], row["kese"], row["borc"], row["itibar"], row["moral"],
		])
	for row in rows:
		print("OLCUM_PERSONA %s" % JSON.stringify(row))
