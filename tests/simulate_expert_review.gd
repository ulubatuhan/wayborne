extends SceneTree

## Üç uzman profili (kullanıcı isteği, 2026-11-06).
##
## Önceki iki tur oyuncuyu taklit etti: kim keyif alıyor, kim ölüyor. Bu tur
## oyunu **ürün olarak** sınıyor. Üç profil:
##
##   A · Tutundurma Analisti - ilk oturum hunisi, seans şekli, bırakma
##       noktaları, içerik pisti, geri dönme kancası.
##   B · Sistem Tasarımcısı - karar yoğunluğu, sahte seçim, baskın strateji,
##       ustalık eğrisi, ekonomi tıkanması.
##   C · Zanaat Denetçisi - oyun ne kadar "YZ dolgusu": metin tekrarı,
##       sözcük çeşitliliği, seçenek ve etki tekdüzeliği, adsız sonuç,
##       yapay zekâ yazım izleri.
##
## **Bu araç ne ölçemez, baştan söylenir.** Gerçek tutundurma (D1/D7/D30,
## iade oranı, inceleme dönüşümü) insan gerektirir; bir simülatörün
## üretebileceği D1 sayısı uydurmadır. Burada ölçülen şey **oyunun kendi
## durumundan hesaplanabilen vekil göstergeler**: huni kaç seferde
## tamamlanıyor, içerik kaç seferde tükeniyor, karar gerçekten karar mı.
## Her satır neyin vekili olduğunu söylüyor; rapor da öyle
## (`docs/design_notes/uzman_degerlendirme.md`).
##
## Koşturmak:
##   godot --headless --script res://tests/simulate_expert_review.gd

const RUNS: int = 6
## Yirmi sefer azmış: üç politika da yirmiyi bitirdi, yani hayatta kalma
## ölçütü doygunluğa ulaşıp beceri farkını gizledi (ölçüm kusuru, ilk koşu).
const LEGS: int = 40
const BASE_SEED: int = 990000
const STARTING_GOLD: int = 250
const STARTING_PROVISIONS: int = 20
## İlk oturum penceresi. Steam'in iade kuralı iki saat; bir seferin ~3-6
## dakika sürdüğü düşünülürse ilk üç sefer "ilk oturum" demek.
const FIRST_SESSION_LEGS: int = 3
## İçerik pisti: yeni kart oranı bunun altına inince katalog tükenmiş sayılır.
const RUNWAY_NEW_CARDS_PER_LEG: float = 0.5

var _catalog: Array[GameEvent] = []

func _initialize() -> void:
	TranslationServer.set_locale("tr")
	_catalog = EventCatalog.get_road_events()
	print("── Wayborne uzman değerlendirmesi (%d koşu × %d sefer)" % [RUNS, LEGS])
	print("   Ölçülen şey vekil göstergelerdir; gerçek D1/D7 insan ister.")
	_report_retention()
	_report_systems()
	_report_craft()
	quit()

# =====================================================================
# A · TUTUNDURMA ANALİSTİ
# =====================================================================

func _report_retention() -> void:
	print("")
	print("── A · Tutundurma Analisti")
	var runs: Array[Dictionary] = []
	for index in RUNS:
		runs.append(_play(BASE_SEED + index * 601, _policy_balanced()))

	# İlk oturum hunisi: oyuncu ilk üç seferde neyi gördü.
	var saw_choice := 0
	var saw_loss := 0
	var saw_new_place := 0
	var saw_fight := 0
	var died_early := 0
	for run in runs:
		if int(run["first_choice_leg"]) >= 0 and int(run["first_choice_leg"]) < FIRST_SESSION_LEGS:
			saw_choice += 1
		if int(run["first_loss_leg"]) >= 0 and int(run["first_loss_leg"]) < FIRST_SESSION_LEGS:
			saw_loss += 1
		if int(run["first_new_place_leg"]) >= 0 and int(run["first_new_place_leg"]) < FIRST_SESSION_LEGS:
			saw_new_place += 1
		if int(run["first_fight_leg"]) >= 0 and int(run["first_fight_leg"]) < FIRST_SESSION_LEGS:
			saw_fight += 1
		if int(run["ended_leg"]) >= 0 and int(run["ended_leg"]) < FIRST_SESSION_LEGS:
			died_early += 1

	print("   İlk oturum hunisi (ilk %d sefer, %d koşu) - oyuncu neyi gördü:" % [FIRST_SESSION_LEGS, RUNS])
	print("     gerçek bir seçim          %d/%d koşu" % [saw_choice, RUNS])
	print("     görülmemiş bir yer        %d/%d koşu" % [saw_new_place, RUNS])
	print("     ilk gerçek kayıp          %d/%d koşu" % [saw_loss, RUNS])
	print("     ilk dövüş                 %d/%d koşu" % [saw_fight, RUNS])
	print("     ilk oturumda kervan bitti %d/%d koşu  (erken bırakma riski)" % [died_early, RUNS])

	var leg_days := _avg(runs, "days") / maxf(1.0, _avg(runs, "legs"))
	print("   Seans şekli: sefer başına %.1f oyun günü · koşu başına %.1f sefer"
		% [leg_days, _avg(runs, "legs")])

	# İçerik pisti: yeni kart oranı ne zaman düşüyor.
	var runway := 0.0
	var seen_share := 0.0
	for run in runs:
		runway += float(run["runway_leg"])
		seen_share += float(run["unique_cards"]) / float(maxi(1, _catalog.size()))
	print("   İçerik pisti: %.1f. seferde yeni kart oranı %.1f/sefer'in altına iniyor"
		% [runway / float(RUNS), RUNWAY_NEW_CARDS_PER_LEG])
	print("     %d seferde katalogun %%%.0f'i görülüyor (%d kart var)"
		% [LEGS, seen_share / float(RUNS) * 100.0, _catalog.size()])
	print("     çekilen kartların %%%.0f'i tekrar" % (_avg(runs, "repeat_share") * 100.0))

	# Bırakma noktaları.
	var ended := 0
	var ended_at := 0.0
	for run in runs:
		if int(run["ended_leg"]) >= 0:
			ended += 1
			ended_at += float(run["ended_leg"])
	if ended > 0:
		print("   Bırakma noktası: %d/%d koşu bitti, ortalama %.1f. seferde"
			% [ended, RUNS, ended_at / float(ended)])
	else:
		print("   Bırakma noktası: hiçbir koşu bitmedi (%d sefer sınırına kadar)" % LEGS)

	# Geri dönme kancası: koşu bittiğinde geride ne kaldı.
	print("   Geri dönme kancası (koşu bittiğinde açıkta kalan):")
	print("     görülmemiş yer %.1f · bitmemiş kişi işi %.1f · görülmemiş kart %.1f"
		% [_avg(runs, "unseen_places"), _avg(runs, "open_chains"),
			float(_catalog.size()) - _avg(runs, "unique_cards")])
	print("   Boş tur: şehir ziyaretlerinin %%%.0f'inde alacak/yapacak bir şey yok"
		% (_avg(runs, "dead_city_share") * 100.0))

# =====================================================================
# B · SİSTEM TASARIMCISI
# =====================================================================

func _report_systems() -> void:
	print("")
	print("── B · Sistem Tasarımcısı")

	# Sahte seçim: bir kartın seçenekleri aynı etki ailesini mi veriyor.
	var fake := 0
	var single := 0
	var multi := 0
	var checked := 0
	for event in _catalog:
		if event.choices.size() <= 1:
			single += 1
			continue
		multi += 1
		var shapes: Dictionary = {}
		for choice in event.choices:
			shapes[_effect_shape(choice)] = true
		if shapes.size() <= 1:
			fake += 1
		for choice in event.choices:
			if choice.check != null:
				checked += 1
				break
	print("   Karar kalitesi (katalogun tamamı, %d kart):" % _catalog.size())
	print("     tek seçenekli kart            %d (%%%.0f) - seçim değil, bildirim"
		% [single, float(single) / float(maxi(1, _catalog.size())) * 100.0])
	print("     seçenekleri aynı etkiyi veren %d (%%%.0f) - sahte seçim"
		% [fake, float(fake) / float(maxi(1, multi)) * 100.0])
	print("     beceri kontrolü taşıyan       %d (%%%.0f)"
		% [checked, float(checked) / float(maxi(1, _catalog.size())) * 100.0])

	# Baskın strateji ve ustalık eğrisi: aynı tohum, üç politika.
	var policies := {
		"acemi (rastgele seçer)": _policy_naive(),
		"dengeli (plan okur)": _policy_balanced(),
		"açgözlü (altına koşar)": _policy_greedy(),
	}
	print("   Ustalık eğrisi ve baskın strateji (aynı tohumlar, %d koşu):" % RUNS)
	# İlk koşuda fark yalnız sefer sayısıyla aranmıştı ve üç politika da
	# tavana vurduğu için "ustalık yok" çıkmıştı: ölçüm kusuru. Hayatta kalma
	# doyduğunda beceri **kese ve teslimatta** görünür.
	var best_name := ""
	var best_legs := -1.0
	var worst_legs := 999.0
	var best_gold := -1.0
	var worst_gold := 1e9
	for name_text in policies:
		var runs: Array[Dictionary] = []
		for index in RUNS:
			runs.append(_play(BASE_SEED + index * 601, policies[name_text]))
		var legs := _avg(runs, "legs")
		var gold := _avg(runs, "gold")
		print("     %-24s %5.1f sefer · %4.1f ölüm · %6.0f GG · %4.1f teslimat · %%%.0f aç sefer"
			% [name_text, legs, _avg(runs, "deaths"), gold, _avg(runs, "delivered"),
				_avg(runs, "short_share") * 100.0])
		if legs > best_legs:
			best_legs = legs
			best_name = name_text
		worst_legs = minf(worst_legs, legs)
		best_gold = maxf(best_gold, gold)
		worst_gold = minf(worst_gold, gold)
	# Oran negatif keseyle anlamsız (ilk koşu ×264 yazdı): fark mutlak.
	print("     dayanıklılık farkı %.1f sefer (%s önde) · kese farkı %.0f GG"
		% [best_legs - worst_legs, best_name, best_gold - worst_gold])
	if best_legs - worst_legs < 2.0 and absf(best_gold - worst_gold) < 100.0:
		print("     → beceri hiçbir eksende ölçülemiyor: ustalık eğrisi yok sayılır")

	# Ekonomi tıkanması ve ödül aralığı.
	var runs_b: Array[Dictionary] = []
	for index in RUNS:
		runs_b.append(_play(BASE_SEED + index * 601, _policy_balanced()))
	print("   Ekonomi: seferlerin %%%.0f'inde gereken erzak alınamıyor · iyi bir şey arası %.1f gün"
		% [_avg(runs_b, "short_share") * 100.0, _avg(runs_b, "good_gap")])
	print("   Karar yoğunluğu: kart başına %.2f açık seçenek · zorunlu kart oranı %%%.0f"
		% [_avg(runs_b, "options_per_card"), _avg(runs_b, "forced_share") * 100.0])

# =====================================================================
# C · ZANAAT DENETÇİSİ (YZ dolgusu denetimi)
# =====================================================================

func _report_craft() -> void:
	print("")
	print("── C · Zanaat Denetçisi: \"bu oyun ne kadar dolgu?\"")
	var bodies: Array[String] = []
	var option_counts: Dictionary = {}
	var effect_types: Dictionary = {}
	var outcome_total := 0
	var outcome_numeric := 0
	var outcome_named := 0
	var outcome_silent := 0
	var outcome_untranslated := 0
	var empty_outcomes := 0
	for event in _catalog:
		bodies.append(tr(event.text_key))
		option_counts[event.choices.size()] = int(option_counts.get(event.choices.size(), 0)) + 1
		for choice in event.choices:
			for outcome in choice.outcomes:
				outcome_total += 1
				var only_numbers := not outcome.effects.is_empty()
				for effect in outcome.effects:
					effect_types[effect.type] = int(effect_types.get(effect.type, 0)) + 1
					if not (effect.type in [
						EventEffect.Type.GOLD, EventEffect.Type.MORALE,
						EventEffect.Type.STRESS, EventEffect.Type.REPUTATION,
					]):
						only_numbers = false
				if outcome.effects.is_empty():
					empty_outcomes += 1
				elif only_numbers:
					outcome_numeric += 1
				var line := tr(outcome.text_key)
				if outcome.text_key.is_empty():
					outcome_silent += 1
				elif line == outcome.text_key:
					outcome_untranslated += 1
				if line.contains("{") or line.contains("%s"):
					outcome_named += 1

	# Metin tekrarı ve sözcük çeşitliliği.
	var unique_bodies: Dictionary = {}
	var words: Array[String] = []
	var vocabulary: Dictionary = {}
	for body in bodies:
		unique_bodies[body] = true
		for word in body.to_lower().split(" ", false):
			var clean := word.strip_edges().trim_suffix(".").trim_suffix(",").trim_suffix(";")
			if clean.length() < 3:
				continue
			words.append(clean)
			vocabulary[clean] = int(vocabulary.get(clean, 0)) + 1
	var ttr := float(vocabulary.size()) / float(maxi(1, words.size()))
	print("   Metin: %d kart gövdesi, %d'i benzersiz (%%%.0f) · %d sözcük, %d farklı (çeşitlilik %.2f)"
		% [bodies.size(), unique_bodies.size(),
			float(unique_bodies.size()) / float(maxi(1, bodies.size())) * 100.0,
			words.size(), vocabulary.size(), ttr])

	# Seçenek biçimi tekdüzeliği.
	var shape_line: Array[String] = []
	var counts: Array = option_counts.keys()
	counts.sort()
	for count in counts:
		shape_line.append("%d seçenek: %d kart" % [int(count), int(option_counts[count])])
	print("   Seçenek biçimi: %s" % " · ".join(shape_line))

	# Etki çeşitliliği: kaç farklı etki türü gerçekten kullanılıyor.
	print("   Etki dili: %d farklı etki türü kullanılıyor · %d sonuçtan %%%.0f'i yalnız sayı oynatıyor"
		% [effect_types.size(), outcome_total,
			float(outcome_numeric) / float(maxi(1, outcome_total)) * 100.0])
	print("     etkisiz sonuç (hiçbir şey olmaz) %d (%%%.0f)"
		% [empty_outcomes, float(empty_outcomes) / float(maxi(1, outcome_total)) * 100.0])
	print("     adı/yeri anan sonuç %d (%%%.0f) · yazısı olmayan %d · çevrilmemiş %d"
		% [outcome_named, float(outcome_named) / float(maxi(1, outcome_total)) * 100.0,
			outcome_silent, outcome_untranslated])

	# Yapay zekâ yazım izleri (Türkçe metinde).
	var tells := {
		"üç'leme (a, b ve c)": 0,
		"\"sadece ... değil\"": 0,
		"\"bir yandan ... öte yandan\"": 0,
		"uzun tire yığılması": 0,
	}
	for body in bodies:
		var lower := body.to_lower()
		if lower.count(",") >= 2 and lower.contains(" ve "):
			tells["üç'leme (a, b ve c)"] += 1
		if lower.contains("sadece") and lower.contains("değil"):
			tells["\"sadece ... değil\""] += 1
		if lower.contains("bir yandan") and lower.contains("öte yandan"):
			tells["\"bir yandan ... öte yandan\""] += 1
		if body.count("—") + body.count(" - ") >= 2:
			tells["uzun tire yığılması"] += 1
	var tell_line: Array[String] = []
	for key in tells:
		tell_line.append("%s %d" % [key, int(tells[key])])
	print("   Yazım izleri (%d kartta): %s" % [bodies.size(), " · ".join(tell_line)])

	# En çok tekrarlanan cümle başlangıçları: kalıp var mı.
	var openings: Dictionary = {}
	for body in bodies:
		var head := " ".join(Array(body.split(" ", false)).slice(0, 2))
		openings[head] = int(openings.get(head, 0)) + 1
	var heads: Array = openings.keys()
	heads.sort_custom(func(a, b): return int(openings[a]) > int(openings[b]))
	var top: Array[String] = []
	for head in heads.slice(0, 3):
		top.append("\"%s\" ×%d" % [String(head), int(openings[head])])
	print("   En sık açılış: %s" % " · ".join(top))

# =====================================================================
# Oynatıcı
# =====================================================================

## Politika: kart seçeneklerini puanlayan ağırlıklar + plan okuma.
func _policy_balanced() -> Dictionary:
	return {"gold": 0.6, "risk": -0.3, "people": 0.6, "reads_plan": true, "random": false}

func _policy_greedy() -> Dictionary:
	return {"gold": 1.4, "risk": 0.4, "people": -0.2, "reads_plan": false, "random": false}

func _policy_naive() -> Dictionary:
	return {"gold": 0.0, "risk": 0.0, "people": 0.0, "reads_plan": false, "random": true}

func _play(seed_value: int, policy: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var session := GameSession.new(STARTING_GOLD, STARTING_PROVISIONS, 1)
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.inherit_father_caravan()
	session.set_meal_policy(GameSession.MEAL_MODE_PARTY_ONLY)
	var engine := EventEngine.new(_catalog, rng.randi())

	var state := {
		"legs": 0, "days": 0, "cards": 0, "repeats": 0, "options": 0, "forced": 0,
		"deaths": 0, "fights": 0, "short_legs": 0, "dead_cities": 0, "cities": 0,
		"first_choice_leg": -1, "first_loss_leg": -1, "first_new_place_leg": -1,
		"first_fight_leg": -1, "ended_leg": -1, "runway_leg": float(LEGS),
		"seen": {}, "new_by_leg": [], "last_good_day": 0, "good_gaps": [],
	}

	for leg in LEGS:
		if session.is_run_over():
			state["ended_leg"] = leg
			break
		state["cities"] = int(state["cities"]) + 1
		if not _city_turn(session, state):
			state["dead_cities"] = int(state["dead_cities"]) + 1
		var before_unique := (state["seen"] as Dictionary).size()
		if not _leg(session, state, engine, rng, policy, leg):
			break
		state["legs"] = int(state["legs"]) + 1
		(state["new_by_leg"] as Array).append((state["seen"] as Dictionary).size() - before_unique)
	if state["ended_leg"] == -1 and session.is_run_over():
		state["ended_leg"] = state["legs"]

	# İçerik pisti: yeni kart oranının eşiğin altına indiği ilk sefer.
	var by_leg: Array = state["new_by_leg"]
	for index in by_leg.size():
		if float(by_leg[index]) < RUNWAY_NEW_CARDS_PER_LEG:
			state["runway_leg"] = float(index + 1)
			break

	var cards := maxi(1, int(state["cards"]))
	var legs := maxi(1, int(state["legs"]))
	var open_chains := 0
	for person in session.people.open_requests():
		open_chains += 1
	var gaps: Array = state["good_gaps"]
	var gap_total := 0.0
	for gap in gaps:
		gap_total += float(gap)
	return {
		"legs": float(state["legs"]), "days": float(session.total_days_elapsed),
		"cards": float(cards), "unique_cards": float((state["seen"] as Dictionary).size()),
		"repeat_share": float(state["repeats"]) / float(cards),
		"options_per_card": float(state["options"]) / float(cards),
		"forced_share": float(state["forced"]) / float(cards),
		"deaths": float(state["deaths"]), "fights": float(state["fights"]),
		"short_share": float(state["short_legs"]) / float(legs),
		"dead_city_share": float(state["dead_cities"]) / float(maxi(1, int(state["cities"]))),
		"first_choice_leg": state["first_choice_leg"], "first_loss_leg": state["first_loss_leg"],
		"first_new_place_leg": state["first_new_place_leg"],
		"first_fight_leg": state["first_fight_leg"],
		"ended_leg": state["ended_leg"], "runway_leg": state["runway_leg"],
		"gold": float(session.wallet.balance), "delivered": float(session.contracts_delivered),
		"unseen_places": float(WorldMapData.get_locations().size() - session.visited_location_ids.size()),
		"open_chains": float(open_chains),
		"good_gap": gap_total / float(maxi(1, gaps.size())),
	}

## Şehirde bir tur. Bir şey yapılabildiyse true - yapılamadıysa "boş tur".
## Kiler bu kadar günün altına inince boş turda gündelik işe gidilir.
const IDLE_LABOUR_DAYS: int = 3

func _city_turn(session: GameSession, state: Dictionary) -> bool:
	session.people.ensure_city(session.current_location_id, session.total_days_elapsed)
	# Kişilerin işi teklif edilmezse "açıkta kalan iş" hep sıfır çıkar ve
	# geri dönme kancası yanlış okunur (ölçüm kusuru, ilk koşu).
	for person in session.people.city_people(session.current_location_id):
		session.people.offer_chain(String((person as Dictionary).get("id", "")), session.total_days_elapsed)
	var acted := false
	var origin := WorldMapData.get_location_by_id(session.current_location_id)
	if origin == null:
		return false
	for entry in session.get_total_inventory_entries().duplicate():
		var item: Item = (entry as Dictionary).item
		if item == null or item.item_id == GameSession.PROVISIONS_ITEM_ID:
			continue
		if not origin.demands.has(item.item_id):
			continue
		var quantity := session.get_total_quantity(item.item_id)
		var unit := session.capped_sell_price(item.item_id, MarketPricing.get_sell_price(
			item, origin, session.market, session.total_days_elapsed
		))
		quantity = mini(quantity, int(floor(float(session.get_city_gold_reserve()) / float(maxi(1, unit)))))
		if quantity <= 0:
			continue
		session.remove_from_cargo_or_bags(item.item_id, quantity)
		session.wallet.earn(unit * quantity)
		session.record_sale(item.item_id, quantity, unit * quantity)
		acted = true
	for item_id in origin.produces:
		var item := ItemCatalog.get_item(item_id)
		if item == null:
			continue
		var unit := maxi(1, int(round(float(MarketPricing.get_buy_price(
			item, origin, session.market, session.total_days_elapsed
		)) * Scarcity.buy_factor(item_id, session.scarcity_here()))))
		var affordable := int(floor(float(session.wallet.balance) * 0.35 / float(unit)))
		var by_space := int(floor(session.get_cargo_space_remaining() / maxf(0.1, item.unit_weight)))
		var stock := session.get_market_stock(item_id)
		var quantity := mini(mini(affordable, by_space), stock if stock >= 0 else affordable)
		if quantity > 0 and session.add_to_cargo(item, quantity):
			session.consume_stock(item_id, quantity, unit * quantity)
			session.wallet.spend(unit * quantity)
			acted = true
	# U4 (2026-11-07): ticaret yapılamadıysa şehrin önerdiği bedelli işe
	# bakılır. Politika gerçekçi tutuluyor - bir oyuncu her boş turda
	# çalışmaz, **kiler daraldığında** çalışır; yoksa ölçü anlamını yitirir.
	if not acted and session.can_work_a_day():
		var daily := maxi(1, session.get_daily_provision_consumption())
		if session.get_provisions() < daily * IDLE_LABOUR_DAYS:
			session.work_a_day()
			acted = true
	return acted

func _leg(
	session: GameSession, state: Dictionary, engine: EventEngine,
	rng: RandomNumberGenerator, policy: Dictionary, leg: int
) -> bool:
	var open_routes: Array[TravelRoute] = []
	for candidate in WorldMapData.get_routes_from(session.current_location_id):
		if session.is_route_open(candidate):
			open_routes.append(candidate)
	if open_routes.is_empty():
		return false
	var route: TravelRoute = open_routes[rng.randi_range(0, open_routes.size() - 1)]
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	if destination == null:
		return false
	var unseen := not session.visited_location_ids.has(destination.location_id)
	var days := session.get_route_travel_days(route)
	var plan := CaravanPlan.new(destination, days, session.get_wagon_capacity(), session.owned_wagon_count)
	plan.caravan_party_size = session.get_party().size()
	plan.provision_multiplier = session.get_daily_provision_multiplier()
	plan.provision_reduction = session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI)
	plan.crew_hands = session.get_crew_hands()
	for offer in session.get_contract_board():
		if offer.destination_location_id == destination.location_id and plan.can_add_offer(offer):
			session.accept_contract(offer)
			plan.toggle_merchant(offer)

	var shortfall := plan.get_provisions_shortfall(session.get_provisions())
	if shortfall > 0:
		var margin := 1.25 if bool(policy["reads_plan"]) else 1.0
		session.buy_provisions(int(ceil(float(shortfall) * margin)))
	if plan.get_provisions_shortfall(session.get_provisions()) > 0:
		state["short_legs"] = int(state["short_legs"]) + 1

	session.depart_with_contracts(plan.get_selected_offers())
	session.start_journey(destination.location_id, days, session.get_route_danger(route), plan)
	var day := 0
	while session.journey_days_remaining > 0:
		day += 1
		session.journey_days_remaining -= 1
		session.advance_day()
		var meal := session.apply_meal_distribution(GameSession.MEAL_MODE_PARTY_ONLY)
		var dead: Array = (meal.get("death_outcome", {}) as Dictionary).get("dead_names", [])
		if not dead.is_empty():
			state["deaths"] = int(state["deaths"]) + dead.size()
			if int(state["first_loss_leg"]) < 0:
				state["first_loss_leg"] = leg
		if not (meal.get("crew_deserted_names", []) as Array).is_empty() and int(state["first_loss_leg"]) < 0:
			state["first_loss_leg"] = leg
		var event := engine.roll_for_day(day, session.build_event_context())
		if event == null:
			continue
		engine.mark_fired(event, day)
		_resolve(session, state, engine, event, rng, policy, leg)
	session.finish_journey()
	if unseen and int(state["first_new_place_leg"]) < 0:
		state["first_new_place_leg"] = leg
	return true

func _resolve(
	session: GameSession, state: Dictionary, engine: EventEngine, event: GameEvent,
	rng: RandomNumberGenerator, policy: Dictionary, leg: int
) -> void:
	var context := session.build_event_context()
	var available: Array[EventChoice] = []
	for choice in event.choices:
		if choice.is_available(context):
			available.append(choice)
	state["cards"] = int(state["cards"]) + 1
	var seen: Dictionary = state["seen"]
	if seen.has(event.event_id):
		state["repeats"] = int(state["repeats"]) + 1
	seen[event.event_id] = true
	state["options"] = int(state["options"]) + available.size()
	if available.size() <= 1:
		state["forced"] = int(state["forced"]) + 1
	elif int(state["first_choice_leg"]) < 0:
		state["first_choice_leg"] = leg
	if available.is_empty():
		return
	var picked: EventChoice = available[0]
	if bool(policy["random"]):
		picked = available[rng.randi_range(0, available.size() - 1)]
	else:
		var best := -99999.0
		for choice in available:
			var score := _score(choice, policy)
			if score > best:
				best = score
				picked = choice
	var purse := session.wallet.balance
	var larder := session.get_provisions()
	var resolution := EventResolver.resolve_choice(session, engine, event, picked)
	for result in resolution.get_results():
		if result == null:
			continue
		if not result.combat_requests.is_empty():
			state["fights"] = int(state["fights"]) + 1
			if int(state["first_fight_leg"]) < 0:
				state["first_fight_leg"] = leg
	# Ödül aralığı: "iyi bir şey" = kese ya da ambar büyüdü. İlk boşluk
	# sayılmıyor (oyunun başından ilk ödüle kadar geçen süre bir aralık
	# değil, bir gecikme - onu huni zaten ölçüyor).
	if session.wallet.balance > purse or session.get_provisions() > larder:
		if int(state["last_good_day"]) > 0:
			(state["good_gaps"] as Array).append(
				session.total_days_elapsed - int(state["last_good_day"])
			)
		state["last_good_day"] = session.total_days_elapsed

func _score(choice: EventChoice, policy: Dictionary) -> float:
	var score := 0.0
	for effect in choice.effects:
		score += _effect_score(effect, policy)
	var total := 0.0
	var outcome := 0.0
	for result in choice.outcomes:
		var w := maxf(0.01, result.weight)
		total += w
		for effect in result.effects:
			outcome += w * _effect_score(effect, policy)
	if total > 0.0:
		score += outcome / total
		score += float(policy["risk"]) * minf(1.0, float(choice.outcomes.size()) * 0.5)
	return score

func _effect_score(effect: EventEffect, policy: Dictionary) -> float:
	match effect.type:
		EventEffect.Type.GOLD:
			return float(effect.amount) * 0.02 * float(policy["gold"])
		EventEffect.Type.PROVISIONS:
			return float(effect.amount) * 0.25
		EventEffect.Type.PARTY_HP:
			return float(effect.amount) * 0.08 * float(policy["people"])
		EventEffect.Type.LEAVE_BEHIND:
			return -4.0 * maxf(0.3, float(policy["people"]))
		EventEffect.Type.WAGON_LOSE:
			return -6.0
		EventEffect.Type.TRIGGER_COMBAT:
			return 2.0 * float(policy["risk"])
		_:
			return 0.0

## Bir seçeneğin "etki parmak izi": hangi etki türlerini oynatıyor.
## İki seçenek aynı parmak izini taşıyorsa aralarındaki fark yalnız sayıdır.
func _effect_shape(choice: EventChoice) -> String:
	var kinds: Dictionary = {}
	for effect in choice.effects:
		kinds[effect.type] = true
	for outcome in choice.outcomes:
		for effect in outcome.effects:
			kinds[effect.type] = true
	var ordered: Array = kinds.keys()
	ordered.sort()
	var parts: Array[String] = []
	for kind in ordered:
		parts.append(str(kind))
	return ",".join(parts)

func _avg(runs: Array[Dictionary], key: String) -> float:
	var total := 0.0
	for run in runs:
		total += float(run[key])
	return total / float(maxi(1, runs.size()))
