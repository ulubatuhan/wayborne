extends SceneTree

## Oyun günlüğü tutan altı oyuncu profili (kullanıcı isteği, 2026-11-05).
##
## Birinci tur (`simulate_personas.gd`) **yolu** oynadı ve tek soru sordu:
## kim hayatta kalıyor. Bu tur farklı: altı profil şehrin ve yolun
## elinden geleni dener, ve her biri **bir oyun testçisi gibi günlük
## tutar.**
##
## GÜNLÜĞÜN OMURGASI: OYUNUN KENDİ "NEDEN OLMUYOR"LARI
##
## Wayborne'da kapalı her düğme sebebini kendi yazısında söylüyor
## ("disabled with reason" kuralı): `get_advance_block_reason`,
## `get_day_labour_block_reason`, `get_doctor_block_reason`,
## `convoy_block_reason`, `get_wagon_sale_block_reason`,
## `get_cargo_move_block_reason`... otuz küsur kapı. Her biri tam olarak
## **"yapmak istedim ama olmadı"** demek. Profil o kapıya her çarptığında
## günlüğe bir satır düşüyor; turun sonunda en çok çarpılan kapı,
## oyuncunun en çok engellendiği yer oluyor.
##
## Üç tür kayıt:
##   · `istedim`  - bir şeyi denedi, oyun izin vermedi (sebebiyle)
##   · `keyif`    - profilin aradığı şey gerçekleşti (her profilin kendi listesi)
##   · `anladım`  - bir şeyi deneyip öğrendi: kararın sonucu
##
## Yöntemin zemini birinci turun raporunda (`oyuncu_profilleri.md` §1):
## prosedürel persona (Holmgård ve ark.), gelişen persona (Ariyurek ve
## ark.), ÖBK/PENS, QF güdü kümeleri - ve hepsinin sınırları.
##
## **Kullanıcının bu tur koyduğu tasarım çerçevesi:**
##   - Sürekli ölmek keyifsiz; az sayıda ölümle **mücadele ederek** devam
##     edebilmek bir deneyim olmalı.
##   - Herkes ölünce baştan başlamak canı yakmamalı: amaç sonuçtan değil
##     **süreçten** keyif.
## Bu yüzden ölçülen şey "kaç sefer dayandı" değil, **"kaç ölümle kaç
## sefer yaşadı ve yolda ne denedi"**.
##
## Koşturmak:
##   godot --headless --script res://tests/simulate_player_diaries.gd
##   godot --headless --script res://tests/simulate_player_diaries.gd -- --gunluk tuccar
##
## Test değil - tablo basar, günlükleri `user://oyuncu_gunlukleri/` altına yazar.

const LEGS: int = 20
const RUNS_PER_PERSONA: int = 2
const BASE_SEED: int = 770000
const STARTING_GOLD: int = 250
const STARTING_PROVISIONS: int = 20
const DIARY_DIR: String = "user://oyuncu_gunlukleri"
## Yola çıkmadan önce en çok kaç gün çalışılır; yolda en çok kaç gün aranır.
const LABOUR_DAY_CAP: int = 3
const FORAGE_DAY_CAP: int = 4
## Savaş sonrası stres - `simulate_journeys.gd`'nin aynı sayıları.
const COMBAT_STRESS_BASE: int = 8
const COMBAT_STRESS_PER_DOWN: int = 6
const COMBAT_WIN_RELIEF: int = 4
const COMBAT_LOSS_STRESS: int = 15

# --- Altı profil -------------------------------------------------------
#
# Birinci turun beşi yeniden kullanılmadı: o profiller yalnız yolu
# oynuyordu. Bunlar şehrin fiillerini de taşıyor ve her biri **neyden
# keyif aldığını** kendi sözleriyle söylüyor (`keyif_yerleri`).

const PERSONAS: Array[Dictionary] = [
	{
		"id": "tuccar",
		"name": "Kâğıt Üstünde Tüccar",
		"blurb": "Her seferi bir hesap olarak görür. Fiyat defterini okur, takası sever, riski fiyatlar.",
		"keyif_yerleri": [
			"ucuz aldığı malı pahalı satmak",
			"fiyat defterinde bir şehri doğru hatırlamak",
			"kıtlıkta takasın altından iyi çıktığını görmek",
			"kontratı zamanında teslim etmek",
		],
		"weights": {"gold": 1.0, "provisions": 0.5, "morale": 0.2, "stress": -0.2,
			"reputation": 0.6, "combat": -0.8, "risk": -0.6, "people": 0.1, "time": -0.5},
		"motiv": {"ustalik": 1.0, "basari": 0.8, "yetkinlik": 0.9, "ozerklik": 0.6, "anlati": 0.2},
		"feed_all": false, "reads_planner": true, "haggle": true, "barter": true,
		"advance": true, "expand": true, "tavern": false, "recruit": true,
		"church": false, "doctor": true, "craft": true, "chains": true, "forage": true,
	},
	{
		"id": "hikayeci",
		"name": "Defter Tutan",
		"blurb": "Sayıya değil ize bakar. Tavernada oturur, kişileri tanır, deftere ne yazıldığını merak eder.",
		"keyif_yerleri": [
			"tavernada bir gece kalıp odadakileri dinlemek",
			"adı olan birinin kervanı hatırlaması",
			"defterde yeni bir satır görmek",
			"daha önce görmediği bir kart çekmek",
			"yolda bir mezarın yanından geçmek",
		],
		"weights": {"gold": 0.1, "provisions": 0.4, "morale": 0.7, "stress": -0.5,
			"reputation": 0.3, "combat": -0.2, "risk": 0.3, "people": 1.0, "time": 0.2},
		"motiv": {"ustalik": 0.2, "basari": 0.3, "yetkinlik": 0.4, "ozerklik": 0.9, "anlati": 1.0},
		"feed_all": true, "reads_planner": false, "haggle": false, "barter": true,
		"advance": false, "expand": false, "tavern": true, "recruit": true,
		"church": true, "doctor": true, "craft": false, "chains": true, "forage": true,
	},
	{
		"id": "hayatta_kalan",
		"name": "Ucunda Yürüyen",
		"blurb": "Zorluğu arar. Erzağı sayar, hava raporunu okur, yolda yiyecek arar.",
		"keyif_yerleri": [
			"bitmek üzereyken yiyecek bulmak",
			"kimseyi kaybetmeden zor bir yolu bitirmek",
			"soğuk bir geceyi ateşle atlatmak",
			"yaban hayvanını yenip et getirmek",
		],
		"weights": {"gold": 0.3, "provisions": 0.9, "morale": 0.3, "stress": -0.1,
			"reputation": 0.1, "combat": 0.6, "risk": 0.8, "people": 0.2, "time": -0.3},
		"motiv": {"ustalik": 1.0, "basari": 0.5, "yetkinlik": 1.0, "ozerklik": 0.7, "anlati": 0.4},
		"feed_all": false, "reads_planner": true, "haggle": true, "barter": true,
		"advance": true, "expand": false, "tavern": false, "recruit": false,
		"church": false, "doctor": true, "craft": true, "chains": false, "forage": true,
	},
	{
		"id": "tamamlayici",
		"name": "Listeyi Kapatan",
		"blurb": "Her kontratı, her şehri, her kartı ister. Defterdeki sayaçlara bakar.",
		"keyif_yerleri": [
			"görülmemiş bir şehre ilk kez girmek",
			"defterdeki sayacın bir artması",
			"panodaki bütün ilanları almak",
			"vagon alıp kervanı büyütmek",
		],
		"weights": {"gold": 0.6, "provisions": 0.5, "morale": 0.3, "stress": -0.2,
			"reputation": 1.0, "combat": 0.1, "risk": 0.2, "people": 0.4, "time": -0.6},
		"motiv": {"ustalik": 0.6, "basari": 1.0, "yetkinlik": 0.7, "ozerklik": 0.5, "anlati": 0.5},
		"feed_all": false, "reads_planner": true, "haggle": true, "barter": true,
		"advance": true, "expand": true, "tavern": true, "recruit": true,
		"church": true, "doctor": true, "craft": true, "chains": true, "forage": true,
	},
	{
		"id": "merhametli",
		"name": "Bedeli Soran",
		"blurb": "Kim ödüyor diye sorar. Herkesi besler, hastayı hekime götürür, kiliseye verir.",
		"keyif_yerleri": [
			"herkesin karnını doyurabilmek",
			"hasta birini iyileştirmek",
			"aç bir şehre yiyecek götürmek",
			"kimseyi geride bırakmadan varmak",
		],
		"weights": {"gold": -0.1, "provisions": 0.3, "morale": 0.9, "stress": -0.8,
			"reputation": 0.4, "combat": -0.9, "risk": -0.2, "people": 1.2, "time": 0.3},
		"motiv": {"ustalik": 0.2, "basari": 0.3, "yetkinlik": 0.5, "ozerklik": 1.0, "anlati": 0.9},
		"feed_all": true, "reads_planner": false, "haggle": false, "barter": true,
		"advance": false, "expand": false, "tavern": true, "recruit": true,
		"church": true, "doctor": true, "craft": false, "chains": true, "forage": true,
	},
	{
		"id": "zanaatkar",
		"name": "Vagonu Kuran",
		"blurb": "Yeni profil: kervanı bir atölye gibi görür. Vagon düzenler, üretir, ekipman takar.",
		"keyif_yerleri": [
			"vagonda bir şey üretmek",
			"kargoyu düzenleyip yer kazanmak",
			"bir yoldaşa doğru ekipmanı takmak",
			"eşek ya da yarım vagon alıp kapasiteyi büyütmek",
		],
		"weights": {"gold": 0.7, "provisions": 0.6, "morale": 0.4, "stress": -0.3,
			"reputation": 0.3, "combat": -0.3, "risk": -0.3, "people": 0.5, "time": -0.2},
		"motiv": {"ustalik": 0.9, "basari": 0.7, "yetkinlik": 0.8, "ozerklik": 0.8, "anlati": 0.4},
		"feed_all": false, "reads_planner": true, "haggle": true, "barter": true,
		"advance": true, "expand": true, "tavern": false, "recruit": true,
		"church": false, "doctor": true, "craft": true, "chains": false, "forage": true,
	},
]

var _catalog_events: Array[GameEvent] = []
var _diary_id: String = ""

func _initialize() -> void:
	TranslationServer.set_locale("tr")
	_catalog_events = EventCatalog.get_road_events()
	DirAccess.make_dir_recursive_absolute(DIARY_DIR)
	var args := OS.get_cmdline_user_args()
	for index in args.size():
		if String(args[index]) == "--gunluk" and index + 1 < args.size():
			_diary_id = String(args[index + 1])

	print("── Wayborne oyun günlükleri (%d profil × %d koşu × %d sefer)"
		% [PERSONAS.size(), RUNS_PER_PERSONA, LEGS])
	print("   Her profil şehrin ve yolun fiillerini dener ve bir testçi gibi")
	print("   günlük tutar: istedim-olmadı · keyif aldım · anladım.")

	var rows: Array[Dictionary] = []
	var blocked_all: Dictionary = {}
	for persona in PERSONAS:
		var runs: Array[Dictionary] = []
		for index in RUNS_PER_PERSONA:
			runs.append(_run(persona, BASE_SEED + index * 1013))
		var row := _average(persona, runs)
		rows.append(row)
		for key in (row["blocked"] as Dictionary):
			blocked_all[key] = int(blocked_all.get(key, 0)) + int((row["blocked"] as Dictionary)[key])
		_write_diary(persona, runs)
	_report(rows, blocked_all)
	quit()

# --- Bir koşu ----------------------------------------------------------

func _run(persona: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var session := GameSession.new(STARTING_GOLD, STARTING_PROVISIONS, 1)
	session.start_playthrough(
		CharacterData.create("Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new()), rng
	)
	session.inherit_father_caravan()
	if bool(persona["feed_all"]):
		session.set_meal_policy(GameSession.MEAL_MODE_ALL)
	else:
		session.set_meal_policy(GameSession.MEAL_MODE_PARTY_ONLY)

	var state := {
		"persona": persona, "rng": rng, "diary": [], "blocked": {},
		"cards": 0, "unique": {}, "options_open": 0, "forced": 0,
		"starved_days": 0, "deaths": 0, "legs": 0, "legs_ok": 0,
		"forage_days": 0, "labour_days": 0, "tavern_nights": 0,
		"crafted": 0, "treated": 0, "recruited": 0, "chains": 0,
		"run_over_at": -1, "seed": seed_value, "fights": 0, "fights_won": 0,
		"crew_hungry_days": 0, "planned_days": 0, "actual_days": 0,
	}

	for leg in LEGS:
		if session.is_run_over():
			state["run_over_at"] = leg
			_note(state, session, "anladım", "kervan bitti; defter kapandı ve yeni bir soy başlayacak")
			break
		_spend_a_day_in_town(session, state)
		var before := _snapshot(session)
		if not _run_leg(session, state):
			break
		state["legs"] = int(state["legs"]) + 1
		if _is_better(persona, before, _snapshot(session)):
			state["legs_ok"] = int(state["legs_ok"]) + 1
	return _measure(session, state)

## Günlüğe bir satır. `tur`: istedim · keyif · anladım.
func _note(state: Dictionary, session: GameSession, tur: String, ne: String) -> void:
	(state["diary"] as Array).append({
		"gun": session.total_days_elapsed,
		"yer": session.current_location_id,
		"tur": tur,
		"ne": ne,
	})

## Bir kapıya çarpıldı: "yapmak istedim ama olmadı".
##
## `reason` ya oyunun kendi çeviri anahtarıdır - yani oyuncunun ekranda
## okuduğu cümlenin ta kendisi - ya da düz bir cümle. Ayrım ölçümün
## kendisi: oyunda otuz küsur `*_block_reason` kapısı sebebini söylüyor,
## ama **bazı düğmeler sebep söylemeden ölü duruyor.** O kapılar günlükte
## `[sebep yazmıyor]` diye işaretlenir; turun sonundaki listede en çok
## çarpılanlar arasında çıkarlarsa, oyuncunun neden engellendiğini hiç
## öğrenemediği yerler bulunmuş olur.
func _blocked(
	state: Dictionary, session: GameSession, ne: String, reason: String,
	from_game: bool = false
) -> void:
	var spoken := tr(reason)
	var said := reason
	if spoken != reason:
		said = spoken
	elif from_game:
		# Oyunun kendi yazısı, zaten çevrilmiş olarak geldi.
		said = reason
	elif reason.begins_with("UI_"):
		said = "[çevirisi yok: %s]" % reason
	else:
		said = "[sebep yazmıyor] %s" % reason
	var counts: Dictionary = state["blocked"]
	var tally := "%s | %s" % [ne, said]
	counts[tally] = int(counts.get(tally, 0)) + 1
	_note(state, session, "istedim", "%s — %s" % [ne, said])

# --- Şehirde bir gün ---------------------------------------------------
#
# Profilin ilgilendiği her fiil sırayla denenir. **Denemenin kendisi
# ölçüm**: olmazsa sebebi günlüğe düşer.

func _spend_a_day_in_town(session: GameSession, state: Dictionary) -> void:
	var persona: Dictionary = state["persona"]
	session.people.ensure_city(session.current_location_id, session.total_days_elapsed)
	session.people.greet_city(session.current_location_id, session.total_days_elapsed)
	session.record_seen_prices(session.current_location_id)

	if bool(persona["tavern"]):
		_try_tavern(session, state)
	if bool(persona["chains"]):
		_try_chains(session, state)
	if bool(persona["doctor"]):
		_try_doctor(session, state)
	if bool(persona["church"]):
		_try_church(session, state)
	if bool(persona["recruit"]):
		_try_recruit(session, state)
	if bool(persona["craft"]):
		_try_craft(session, state)
	if bool(persona["expand"]):
		_try_grow(session, state)
	if bool(persona["advance"]):
		_try_advance(session, state)

func _try_tavern(session: GameSession, state: Dictionary) -> void:
	var reason := session.get_lodging_block_reason()
	if not reason.is_empty():
		_blocked(state, session, "tavernada kalmak", reason)
		return
	session.lodge_night()
	var feast_reason := session.get_feast_block_reason()
	if feast_reason.is_empty():
		session.throw_feast()
		_note(state, session, "keyif", "şölen kuruldu; yüzler güldü")
	else:
		_blocked(state, session, "şölen kurmak", feast_reason)
	state["tavern_nights"] = int(state["tavern_nights"]) + 1
	_note(state, session, "keyif", "tavernada bir gece kalındı; odadakiler dinlendi")

func _try_chains(session: GameSession, state: Dictionary) -> void:
	for person in session.people.city_people(session.current_location_id):
		var id := String(person.get("id", ""))
		if id.is_empty() or not bool(person.get("alive", false)):
			continue
		var chain := session.people.offer_chain(id, session.total_days_elapsed)
		if chain.is_empty():
			continue
		var chain_reason := session.get_chain_block_reason(id)
		if chain_reason.is_empty():
			session.deliver_chain(id)
			state["chains"] = int(state["chains"]) + 1
			_note(state, session, "keyif", "%s'in istediği getirildi; adımız onda" % String(person.get("name", id)))
		else:
			var missing := session.get_chain_missing_text(id)
			_blocked(state, session, "%s'in işini bitirmek" % String(person.get("name", id)),
				missing if not missing.is_empty() else chain_reason, not missing.is_empty())

func _try_doctor(session: GameSession, state: Dictionary) -> void:
	for character in session.get_party():
		for key in character.ailments.keys():
			var id := String(key)
			if id.is_empty():
				continue
			var reason := session.get_doctor_block_reason(character, id)
			if reason.is_empty():
				session.treat_ailment(character, id)
				state["treated"] = int(state["treated"]) + 1
				_note(state, session, "keyif", "%s hekime götürüldü" % character.character_name)
			else:
				_blocked(state, session, "%s'i iyileştirmek" % character.character_name, reason)

func _try_church(session: GameSession, state: Dictionary) -> void:
	var reason := session.get_church_donation_block_reason()
	if reason.is_empty():
		session.donate_to_church()
		_note(state, session, "keyif", "kiliseye verildi")
	else:
		_blocked(state, session, "kiliseye vermek", reason)

func _try_recruit(session: GameSession, state: Dictionary) -> void:
	if not session.can_recruit():
		# Panelin kendi iki ayrı yazısı (bkz. recruit_panel.gd).
		_blocked(state, session, "tayfaya biri katmak",
			"UI_RECRUIT_NO_WAGON_ROOM" if session.get_party_capacity() < GameSession.MAX_PARTY_SIZE
			else "UI_RECRUIT_PARTY_FULL")
		return
	var rng: RandomNumberGenerator = state["rng"]
	var candidates := RecruitCatalog.build_candidates(RecruitCatalog.VENUE_MARKET, rng, 1)
	if candidates.is_empty():
		return
	var candidate: CharacterData = candidates[0]
	candidate.hire_cost = RecruitCatalog.get_venue_profile(RecruitCatalog.VENUE_MARKET)[2]
	if session.wallet.balance < candidate.hire_cost:
		_blocked(state, session, "tayfaya biri katmak", "UI_NOT_ENOUGH_GOLD")
		return
	if session.recruit(candidate):
		state["recruited"] = int(state["recruited"]) + 1
		_note(state, session, "keyif", "%s kervana katıldı" % candidate.character_name)

func _try_craft(session: GameSession, state: Dictionary) -> void:
	var last_reason := "üretilecek bir tarif yok"
	for recipe in RecipeCatalog.get_recipes():
		var reason := session.get_craft_block_reason_in_wagon(0, recipe)
		if reason.is_empty():
			session.craft_in_wagon(0, recipe.recipe_id)
			state["crafted"] = int(state["crafted"]) + 1
			_note(state, session, "keyif", "vagonda bir şey üretildi")
			return
		last_reason = reason
	_blocked(state, session, "vagonda bir şey üretmek", last_reason)

func _try_grow(session: GameSession, state: Dictionary) -> void:
	if session.can_buy_wagon():
		session.buy_wagon()
		_note(state, session, "keyif", "yeni bir vagon alındı")
		return
	if session.can_buy_donkey():
		session.buy_donkey()
		_note(state, session, "keyif", "bir eşek alındı")
		return
	if session.can_buy_half_wagon():
		session.buy_half_wagon()
		_note(state, session, "keyif", "yarım vagon alındı")
		return
	_blocked(state, session, "kervanı büyütmek", "vagon da eşek de alınamıyor")

func _try_advance(session: GameSession, state: Dictionary) -> void:
	var reason := session.get_advance_block_reason()
	if not reason.is_empty():
		_blocked(state, session, "loncadan mal avansı almak", reason)
		return
	var location := WorldMapData.get_location_by_id(session.current_location_id)
	if location == null or location.produces.is_empty():
		return
	var item := ItemCatalog.get_item(String(location.produces[0]))
	if item == null:
		return
	if session.can_take_advance(item, 5):
		session.take_goods_advance(item, 5)
		_note(state, session, "anladım", "loncadan yük avansı alındı: para değil mal, ve taşımak zorundayız")

# --- Bir sefer ---------------------------------------------------------

func _run_leg(session: GameSession, state: Dictionary) -> bool:
	var persona: Dictionary = state["persona"]
	var rng: RandomNumberGenerator = state["rng"]
	var origin := WorldMapData.get_location_by_id(session.current_location_id)
	if origin == null:
		return false
	var open_routes: Array[TravelRoute] = []
	for candidate in WorldMapData.get_routes_from(session.current_location_id):
		if session.is_route_open(candidate):
			open_routes.append(candidate)
	if open_routes.is_empty():
		_blocked(state, session, "yola çıkmak", "buradan açık bir yol yok")
		return false

	var route := _pick_route(session, state, open_routes)
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	if destination == null:
		return false
	var unseen := not session.visited_location_ids.has(destination.location_id)

	_sell(session, state, origin)
	var travel_days := session.get_route_travel_days(route)
	var plan := _build_plan(session, state, destination, travel_days)
	_buy(session, state, origin, plan.get_contract_cargo_load())
	_stock(session, state, plan)

	session.depart_with_contracts(plan.get_selected_offers())
	session.start_journey(
		destination.location_id, travel_days, session.get_route_danger(route), plan
	)
	_travel(session, state, rng)
	# Yolun planlanandan ne kadar uzadığı. Günlükler 4 günlük bir yolun 40
	# güne çıktığını gösterdi; bunun ne kadarı gecikme kartı, ne kadarı
	# yiyecek arama, ölçülmeden söylenemez.
	state["planned_days"] = int(state["planned_days"]) + travel_days
	state["actual_days"] = int(state["actual_days"]) + session.journey_total_days
	session.finish_journey()
	if unseen:
		_note(state, session, "keyif", "görülmemiş bir yere varıldı: %s" % destination.location_id)
	return true

func _pick_route(
	session: GameSession, state: Dictionary, routes: Array[TravelRoute]
) -> TravelRoute:
	var persona: Dictionary = state["persona"]
	var rng: RandomNumberGenerator = state["rng"]
	var best: Array[TravelRoute] = []
	var best_score := -9999.0
	var board := session.get_contract_board()
	for candidate in routes:
		var score := 0.0
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
			"zanaatkar":
				score = float(contracts) * 1.2 - float(session.get_route_travel_days(candidate)) * 0.2
			_:
				score = float(contracts) + (1.0 if unseen else 0.0)
		if bool(persona["reads_planner"]):
			var need := _needed_for(session, candidate)
			var reachable := session.get_provisions() + _affordable(session)
			if need > reachable:
				score -= 100.0 * float(need - reachable) / float(maxi(1, need))
		if score > best_score:
			best_score = score
			best = [candidate]
		elif is_equal_approx(score, best_score):
			best.append(candidate)
	return best[rng.randi_range(0, best.size() - 1)]

func _needed_for(session: GameSession, route: TravelRoute) -> int:
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

func _affordable(session: GameSession) -> int:
	var by_purse := int(floor(float(maxi(0, session.wallet.balance)) / float(maxi(1, GameSession.PROVISIONS_UNIT_PRICE))))
	return mini(by_purse, maxi(0, session.get_provision_stock()))

func _build_plan(
	session: GameSession, state: Dictionary, destination: Location, travel_days: int
) -> CaravanPlan:
	var persona: Dictionary = state["persona"]
	var plan := CaravanPlan.new(
		destination, travel_days, session.get_wagon_capacity(), session.owned_wagon_count
	)
	plan.caravan_party_size = session.get_party().size()
	plan.provision_multiplier = session.get_daily_provision_multiplier()
	plan.provision_reduction = session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI)
	plan.cargo_room = session.get_cargo_space_remaining()
	var taken := 0
	var wanted := 0
	for offer in session.get_contract_board():
		if offer.destination_location_id != destination.location_id:
			continue
		wanted += 1
		if not offer.is_open_to(session.reputation):
			_blocked(state, session, "panodaki bir ilanı almak", "itibar yetmiyor")
			continue
		if not plan.can_add_offer(offer):
			_blocked(state, session, "panodaki bir ilanı almak", "yük yeri yok")
			continue
		if String(persona["id"]) != "tamamlayici" and taken >= 2:
			break
		session.accept_contract(offer)
		plan.toggle_merchant(offer)
		taken += 1
	if taken > 0:
		_note(state, session, "keyif", "panodan %d ilan alındı" % taken)
	return plan

func _stock(session: GameSession, state: Dictionary, plan: CaravanPlan) -> void:
	var persona: Dictionary = state["persona"]
	var margin := 1.2
	match String(persona["id"]):
		"hayatta_kalan":
			margin = 1.6
		"merhametli":
			margin = 1.3
		"tuccar":
			margin = 1.05
	var shortfall := plan.get_provisions_shortfall(session.get_provisions())
	if shortfall > 0:
		var before := session.get_provisions()
		session.buy_provisions(int(ceil(float(shortfall) * margin)))
		if session.get_provisions() == before:
			_blocked(state, session, "erzak almak", "şehrin erzak stoğu bitti")

	# Planlayıcının sunduğu iki çıkış (Ö2, Ö3).
	if plan.get_provisions_shortfall(session.get_provisions()) <= 0:
		return
	if session.meal_policy_mode == GameSession.MEAL_MODE_ALL:
		session.set_meal_policy(GameSession.MEAL_MODE_PARTY_ONLY)
		_note(state, session, "anladım", "herkesi besleyemiyoruz; sofra ekibe indirildi")
		session.buy_provisions(plan.get_provisions_shortfall(session.get_provisions()))
	var worked := 0
	while worked < LABOUR_DAY_CAP \
			and plan.get_provisions_shortfall(session.get_provisions()) > 0:
		var reason := session.get_day_labour_block_reason()
		if not reason.is_empty():
			_blocked(state, session, "şehirde bir gün çalışmak", reason)
			break
		if session.work_a_day() <= 0:
			break
		worked += 1
		state["labour_days"] = int(state["labour_days"]) + 1
		session.buy_provisions(plan.get_provisions_shortfall(session.get_provisions()))
	if worked > 0:
		_note(state, session, "keyif", "%d gün çalışılıp erzak çıkarıldı" % worked)
	if plan.get_provisions_shortfall(session.get_provisions()) > 0:
		_note(state, session, "anladım", "erzak eksik; yine de yola çıkılıyor")

# --- Pazar -------------------------------------------------------------

func _sell(session: GameSession, state: Dictionary, origin: Location) -> void:
	var persona: Dictionary = state["persona"]
	for entry in session.get_total_inventory_entries().duplicate():
		var item: Item = (entry as Dictionary).item
		if item == null or item.item_id == GameSession.PROVISIONS_ITEM_ID:
			continue
		if not origin.demands.has(item.item_id):
			continue
		var quantity := session.get_total_quantity(item.item_id)
		if quantity <= 0:
			continue
		var shut := session.debt_shut_out_reason()
		if not shut.is_empty():
			_blocked(state, session, "pazarda satmak", shut)
			return
		if not bool(persona["haggle"]) and session.is_profiteering_sale(item.item_id):
			_note(state, session, "anladım", "bu fiyat krizin fiyatı; satmaktan vazgeçildi")
			continue
		var unit := session.capped_sell_price(item.item_id, MarketPricing.get_sell_price(
			item, origin, session.market, session.total_days_elapsed
		))
		var affordable := int(floor(float(session.get_city_gold_reserve()) / float(maxi(1, unit))))
		if affordable < quantity:
			_blocked(state, session, "elimdekinin tamamını satmak", "şehrin kesesi bu kadarını alamıyor")
		quantity = mini(quantity, affordable)
		if quantity <= 0:
			continue
		session.remove_from_cargo_or_bags(item.item_id, quantity)
		session.wallet.earn(unit * quantity)
		session.record_sale(item.item_id, quantity, unit * quantity)
		if Scarcity.is_food(item.item_id) and session.scarcity_here() >= Scarcity.HUNGRY_CITY_FROM:
			_note(state, session, "keyif", "aç bir şehre yiyecek bırakıldı")

func _buy(session: GameSession, state: Dictionary, origin: Location, reserved: float) -> void:
	var persona: Dictionary = state["persona"]
	for item_id in origin.produces:
		var item := ItemCatalog.get_item(item_id)
		if item == null:
			continue
		var unit := maxi(1, int(round(float(MarketPricing.get_buy_price(
			item, origin, session.market, session.total_days_elapsed
		)) * Scarcity.buy_factor(item_id, session.scarcity_here()))))
		var share := 0.4 if bool(persona["haggle"]) else 0.25
		var affordable := int(floor(float(session.wallet.balance) * share / float(unit)))
		var by_space := int(floor(maxf(0.0, session.get_cargo_space_remaining() - reserved) / maxf(0.1, item.unit_weight)))
		var stock := session.get_market_stock(item_id)
		if affordable > 0 and by_space <= 0:
			_blocked(state, session, "mal almak", "vagonda yer kalmadı")
			continue
		if affordable > 0 and stock == 0:
			_blocked(state, session, "mal almak", "pazarda stok yok")
			continue
		var quantity := mini(mini(affordable, by_space), stock if stock >= 0 else affordable)
		if quantity <= 0:
			continue
		if session.add_to_cargo(item, quantity):
			session.consume_stock(item_id, quantity, unit * quantity)
			session.wallet.spend(unit * quantity)

# --- Yol ---------------------------------------------------------------

func _travel(session: GameSession, state: Dictionary, rng: RandomNumberGenerator) -> void:
	var persona: Dictionary = state["persona"]
	var engine := EventEngine.new(_catalog_events, rng.randi())
	var day := 0
	var foraged := 0
	while session.journey_days_remaining > 0:
		day += 1
		session.journey_days_remaining -= 1
		# Yolda yiyecek aramak: açlığın eşiğine yaklaşınca, en çok birkaç gün.
		if bool(persona["forage"]) and foraged < FORAGE_DAY_CAP \
				and session.get_provisions() < session.get_daily_provision_consumption() * 2:
			var reason := session.get_forage_block_reason()
			if reason.is_empty():
				var found := session.forage_a_day()
				if found > 0:
					foraged += 1
					state["forage_days"] = int(state["forage_days"]) + 1
					_note(state, session, "keyif", "bitmek üzereyken %d erzak bulundu" % found)
			else:
				_blocked(state, session, "yolda yiyecek aramak", reason)
		_eat(session, state)
		var event := engine.roll_for_day(day, session.build_event_context())
		if event == null:
			continue
		engine.mark_fired(event, day)
		_resolve(session, state, engine, event, rng)

func _eat(session: GameSession, state: Dictionary) -> void:
	var persona: Dictionary = state["persona"]
	session.advance_day()
	var mode := GameSession.MEAL_MODE_ALL if bool(persona["feed_all"]) else GameSession.MEAL_MODE_PARTY_ONLY
	var result := session.apply_meal_distribution(mode)
	if not (result.get("hungry_names", []) as Array).is_empty():
		state["starved_days"] = int(state["starved_days"]) + 1
	# Adı olanlar ile adı olmayanlar ayrı sayılır. PARTY_ONLY kipinde
	# `hungry_names` boş kalır ama `crew_hungry` doğrudur: isimsiz ekip
	# sürekli açtır ve bunu kimse fark etmez - ölçümün bunu ayırması
	# gerekiyor, yoksa "sıfır aç gün" diye yanlış bir rapor çıkar.
	if bool(result.get("crew_hungry", false)):
		state["crew_hungry_days"] = int(state["crew_hungry_days"]) + 1
	var dead: Array = (result.get("death_outcome", {}) as Dictionary).get("dead_names", [])
	if not dead.is_empty():
		state["deaths"] = int(state["deaths"]) + dead.size()
		_note(state, session, "anladım", "%s açlıktan öldü" % String(dead[0]))

func _resolve(
	session: GameSession, state: Dictionary, engine: EventEngine,
	event: GameEvent, rng: RandomNumberGenerator
) -> void:
	var persona: Dictionary = state["persona"]
	var context := session.build_event_context()
	var available: Array[EventChoice] = []
	var blocked := 0
	for choice in event.choices:
		if choice.is_available(context):
			available.append(choice)
		else:
			blocked += 1
	state["cards"] = int(state["cards"]) + 1
	var seen_before := (state["unique"] as Dictionary).has(event.event_id)
	(state["unique"] as Dictionary)[event.event_id] = true
	if not seen_before:
		_note(state, session, "keyif", "yeni bir kart görüldü: %s" % event.event_id)
	state["options_open"] = int(state["options_open"]) + available.size()
	if available.size() <= 1:
		state["forced"] = int(state["forced"]) + 1
		_note(state, session, "istedim", "kartta tek seçenek vardı: seçmek diye bir şey yoktu")
	for choice in event.choices:
		if choice.is_available(context):
			continue
		# Kartın kendi kilit yazısı okunuyor: ilk ölçümde burada benim
		# uydurduğum bir cümle vardı ve "148 kez sebep yazmıyor" diye
		# yanlış bir bulgu çıkmıştı. Oysa kilitli seçenek sebebini
		# ekranda söylüyor (bkz. road_journey.gd _build_choice_button).
		_blocked(state, session, "kartta kapalı bir seçeneği seçmek",
			choice.unavailable_text_key)
	if available.is_empty():
		return
	var best: EventChoice = available[0]
	var best_score := -99999.0
	for choice in available:
		var score := _score(choice, persona["weights"], rng)
		if score > best_score:
			best_score = score
			best = choice
	var resolution := EventResolver.resolve_choice(session, engine, event, best)
	_fight_if_asked(session, state, resolution, rng)

## Savaş kartı çıkınca savaşı gerçekten çöz.
##
## **Bu olmadan ölçüm yalan söylüyordu.** `TRIGGER_COMBAT` etkisini yalnızca
## `road_journey.gd` (ekran) savaşa çeviriyor; simülatörde kart çekiliyor,
## seçenek seçiliyor ve hiçbir şey olmuyordu. İlk koşuda dört profil 20
## seferi **sıfır ölümle** bitirdi - oyunun kolay olmasından değil,
## kimsenin bir kez bile dövüşmemesinden. `simulate_journeys.gd` yıllardır
## başka bir yerde aynı işi yapıyor; politikası (yaralıyı iyileştir, yoksa
## en zayıfa en sert vur) buraya taşındı.
func _fight_if_asked(
	session: GameSession, state: Dictionary,
	resolution: EventResolver.Resolution, rng: RandomNumberGenerator
) -> void:
	var requests: Array[int] = []
	for result in resolution.get_results():
		if result == null:
			continue
		for kind in result.combat_requests:
			requests.append(int(kind))
	if requests.is_empty():
		return
	var party := session.get_party()
	if party.is_empty():
		return
	var units: Array[CombatUnit] = []
	var position := 1
	for character in party:
		if position > CombatEncounter.MAX_SIDE_SIZE:
			break
		units.append(CombatUnit.from_character(character, position, character.is_stressed()))
		position += 1
	var enemies := EnemyCatalog.build_bandit_squad(
		session.danger_level, units.size(), rng, 1, session.journey_destination_id
	)
	var encounter := CombatEncounter.new(units, enemies, rng)
	encounter.start()
	var guard := 0
	while not encounter.is_over() and guard < 400:
		if not _take_greedy_action(encounter):
			break
		guard += 1
	var downed := encounter.get_downed_count()
	encounter.write_back_party()
	state["fights"] = int(state["fights"]) + 1
	var won := encounter.state == CombatEncounter.State.VICTORY
	session.change_stress(COMBAT_STRESS_BASE + downed * COMBAT_STRESS_PER_DOWN
		+ (-COMBAT_WIN_RELIEF if won else COMBAT_LOSS_STRESS))
	var aftermath: Array[EventEffect] = []
	if won:
		state["fights_won"] = int(state["fights_won"]) + 1
		aftermath.append(EventEffect.make(EventEffect.Type.GOLD, 25 + int(round(session.danger_level * 60.0))))
		aftermath.append(EventEffect.make(EventEffect.Type.MORALE, 12))
		aftermath.append(EventEffect.make(EventEffect.Type.REPUTATION, 4))
		if downed > 0:
			_note(state, session, "anladım", "dövüş kazanıldı ama %d kişi yere düştü" % downed)
		else:
			_note(state, session, "keyif", "dövüş kayıpsız kazanıldı")
	else:
		aftermath.append(EventEffect.make(EventEffect.Type.GOLD, -40))
		aftermath.append(EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 2))
		aftermath.append(EventEffect.make(EventEffect.Type.MORALE, -20))
		_note(state, session, "anladım", "dövüş kaybedildi; yük ve moral gitti")
	EventEffectApplier.apply(aftermath, session)

## `simulate_journeys.gd`'nin politikası: yaralı yoldaş varken iyileştir,
## yoksa en zayıf hedefe en sert vuran yeteneği kullan.
func _take_greedy_action(encounter: CombatEncounter) -> bool:
	if not encounter.is_player_turn():
		return false
	var unit := encounter.get_active_unit()
	if unit == null:
		return false
	var wounded: CombatUnit = null
	for candidate in encounter.player_units:
		if not candidate.is_alive():
			continue
		if float(candidate.current_hp) > float(candidate.max_hp) * 0.5:
			continue
		if wounded == null or candidate.current_hp < wounded.current_hp:
			wounded = candidate
	if wounded != null:
		for skill in unit.skills:
			if not skill.is_heal():
				continue
			for candidate in encounter.get_valid_targets(unit, skill):
				if candidate == wounded:
					return encounter.use_skill(skill, candidate)
	var best_skill: CombatSkill = null
	var best_target: CombatUnit = null
	for skill in unit.skills:
		if skill.is_heal():
			continue
		var targets := encounter.get_valid_targets(unit, skill)
		if targets.is_empty():
			continue
		if best_skill == null or skill.base_damage > best_skill.base_damage:
			best_skill = skill
			best_target = targets[0]
			for candidate in targets:
				if candidate.current_hp < best_target.current_hp:
					best_target = candidate
	if best_skill != null:
		return encounter.use_skill(best_skill, best_target)
	var living: Array[CombatUnit] = []
	for candidate in encounter.player_units:
		if candidate.is_alive():
			living.append(candidate)
	if living.size() >= 2:
		return encounter.swap_player_positions(living[0], living[1])
	return false

func _score(choice: EventChoice, weights: Dictionary, rng: RandomNumberGenerator) -> float:
	var score := _score_effects(choice.effects, weights)
	var total := 0.0
	var outcome := 0.0
	for result in choice.outcomes:
		var w := maxf(0.01, result.weight)
		total += w
		outcome += w * _score_effects(result.effects, weights)
	if total > 0.0:
		score += outcome / total
		score += float(weights.get("risk", 0.0)) * minf(1.0, float(choice.outcomes.size()) * 0.5)
	return score + rng.randf() * 0.01

func _score_effects(effects: Array[EventEffect], weights: Dictionary) -> float:
	var score := 0.0
	for effect in effects:
		var amount := float(effect.amount)
		match effect.type:
			EventEffect.Type.GOLD:
				score += amount * 0.02 * float(weights.get("gold", 0.0))
			EventEffect.Type.PROVISIONS:
				score += amount * 0.25 * float(weights.get("provisions", 0.0))
			EventEffect.Type.MORALE:
				score += amount * 0.1 * float(weights.get("morale", 0.0))
			EventEffect.Type.STRESS:
				score += amount * 0.1 * float(weights.get("stress", 0.0))
			EventEffect.Type.REPUTATION:
				score += amount * 0.5 * float(weights.get("reputation", 0.0))
			EventEffect.Type.PARTY_HP:
				score += amount * 0.08 * float(weights.get("people", 0.0))
			EventEffect.Type.TRAVEL_DAYS:
				score += amount * -0.6 * float(weights.get("time", 0.0))
			EventEffect.Type.DANGER:
				score += amount * -0.8 * float(weights.get("risk", 0.0))
			EventEffect.Type.TRIGGER_COMBAT:
				score += 3.0 * float(weights.get("combat", 0.0))
			EventEffect.Type.WAGON_LOSE:
				score -= 6.0
			EventEffect.Type.WAGON_DAMAGE:
				score -= 1.5
			EventEffect.Type.LEAVE_BEHIND:
				score -= 4.0 * maxf(0.3, float(weights.get("people", 0.0)))
			EventEffect.Type.TRIGGER_RECRUIT:
				score += 1.5 * float(weights.get("people", 0.0))
			_:
				score += 0.0
	return score

# --- Ölçüm ve rapor ----------------------------------------------------

func _snapshot(session: GameSession) -> Dictionary:
	return {
		"gold": session.wallet.balance, "ledger": session.ledger.entries.size(),
		"contracts": session.contracts_delivered, "cities": session.visited_location_ids.size(),
		"morale": session.caravan.morale, "party": session.get_party().size(),
		"provisions": session.get_provisions(),
	}

func _is_better(persona: Dictionary, before: Dictionary, after: Dictionary) -> bool:
	match String(persona["id"]):
		"tuccar", "zanaatkar":
			return int(after["gold"]) > int(before["gold"])
		"hikayeci":
			return int(after["ledger"]) > int(before["ledger"])
		"hayatta_kalan":
			return int(after["party"]) >= int(before["party"])
		"tamamlayici":
			return int(after["contracts"]) > int(before["contracts"]) or int(after["cities"]) > int(before["cities"])
		_:
			return int(after["party"]) >= int(before["party"])

func _measure(session: GameSession, state: Dictionary) -> Dictionary:
	var cards := maxi(1, int(state["cards"]))
	var legs := maxi(1, int(state["legs"]))
	return {
		"sefer": float(state["legs"]), "bitti": float(state["run_over_at"]),
		"olum": float(state["deaths"]), "ac_gun": float(state["starved_days"]),
		"ozerklik": float(state["options_open"]) / float(cards),
		"zorunlu": float(state["forced"]) / float(cards),
		"yetkin": float(state["legs_ok"]) / float(legs),
		"teslimat": float(session.contracts_delivered),
		"sehir": float(session.visited_location_ids.size()),
		"kart": float((state["unique"] as Dictionary).keys().size()),
		"arama": float(state["forage_days"]), "isgunu": float(state["labour_days"]),
		"taverna": float(state["tavern_nights"]), "uretim": float(state["crafted"]),
		"hekim": float(state["treated"]), "katilan": float(state["recruited"]),
		"zincir": float(state["chains"]),
		"dovus": float(state["fights"]), "kazanc": float(state["fights_won"]),
		"ekip_ac": float(state["crew_hungry_days"]),
		"uzama": float(state["actual_days"]) / float(maxi(1, int(state["planned_days"]))),
		"kese": float(session.wallet.balance), "itibar": float(session.reputation),
		"diary": state["diary"], "blocked": state["blocked"], "seed": state["seed"],
	}

func _average(persona: Dictionary, runs: Array[Dictionary]) -> Dictionary:
	var out := {"id": persona["id"], "name": persona["name"], "persona": persona}
	var blocked: Dictionary = {}
	var ended := 0
	for run in runs:
		for key in (run["blocked"] as Dictionary):
			blocked[key] = int(blocked.get(key, 0)) + int((run["blocked"] as Dictionary)[key])
		if float(run["bitti"]) >= 0.0:
			ended += 1
	for key in runs[0].keys():
		if key in ["diary", "blocked", "seed"]:
			continue
		var total := 0.0
		for run in runs:
			total += float(run[key])
		out[key] = total / float(runs.size())
	out["blocked"] = blocked
	out["biten"] = float(ended)
	return out

func _write_diary(persona: Dictionary, runs: Array[Dictionary]) -> void:
	var lines: Array[String] = []
	lines.append("# %s — oyun günlüğü" % String(persona["name"]))
	lines.append("")
	lines.append(String(persona["blurb"]))
	lines.append("")
	lines.append("## Keyif aldığım yerler (profilin kendi sözleri)")
	for item in (persona["keyif_yerleri"] as Array):
		lines.append("- %s" % String(item))
	for index in runs.size():
		var run: Dictionary = runs[index]
		lines.append("")
		lines.append("## %d. koşu (tohum %d) — %d sefer, %d ölüm" % [
			index + 1, int(run["seed"]), int(run["sefer"]), int(run["olum"])
		])
		for entry in (run["diary"] as Array):
			var e: Dictionary = entry
			lines.append("- **%d. gün · %s · %s** — %s" % [
				int(e["gun"]), String(e["yer"]), String(e["tur"]), String(e["ne"])
			])
	var path := "%s/%s.md" % [DIARY_DIR, String(persona["id"])]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(lines))
		print("   günlük: %s (%d satır)" % [path, lines.size()])

func _report(rows: Array[Dictionary], blocked_all: Dictionary) -> void:
	print("")
	print("── Profil tablosu (ortalama, %d koşu)" % RUNS_PER_PERSONA)
	print("   profil                  sefer  ölen  ölüm  açgün  ekipaç  arama  işgün  dövüş  kazan  uzama  teslim  şehir  kart  tavrn  üretm  hekim  katıl")
	for row in rows:
		print("   %-22s  %5.1f  %4s  %4.1f  %5.1f  %6.1f  %5.1f  %5.1f  %5.1f  %5.1f  %5.2f  %6.1f  %5.1f  %4.1f  %5.1f  %5.1f  %5.1f  %5.1f" % [
			row["name"], row["sefer"], "%d/%d" % [int(row["biten"]), RUNS_PER_PERSONA],
			row["olum"], row["ac_gun"], row["ekip_ac"], row["arama"], row["isgunu"],
			row["dovus"], row["kazanc"], row["uzama"],
			row["teslimat"], row["sehir"], row["kart"], row["taverna"],
			row["uretim"], row["hekim"], row["katilan"],
		])
	print("")
	print("── En çok çarpılan kapılar (bütün profiller, \"yapmak istedim ama olmadı\")")
	var keys: Array = blocked_all.keys()
	keys.sort_custom(func(a, b): return int(blocked_all[a]) > int(blocked_all[b]))
	for key in keys.slice(0, 14):
		print("   %5d × %s" % [int(blocked_all[key]), String(key)])
	for row in rows:
		print("OLCUM_GUNLUK %s" % JSON.stringify({
			"id": row["id"], "sefer": row["sefer"], "olum": row["olum"],
			"biten": row["biten"], "ac_gun": row["ac_gun"], "ekip_ac": row["ekip_ac"],
			"arama": row["arama"], "dovus": row["dovus"], "kazanc": row["kazanc"], "uzama": row["uzama"],
			"teslimat": row["teslimat"], "kart": row["kart"],
		}))
