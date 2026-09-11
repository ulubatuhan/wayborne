extends SceneTree

## Kariyer yayı simülatörü. `simulate_journeys.gd` **bir** seferi tekrar
## tekrar ölçer (kazanç, moral, savaş oranı); bu ise **bir kervanın ömrünü**
## ölçer: kırk sefer boyunca kese, itibar, vagon, kadro ve teslimat nasıl
## büyüyor, ve kampanya bölümleri kaçıncı seferde kapanıyor.
##
##   godot --headless --script res://tests/simulate_career.gd
##
## Test değil - hiç kırmızı dönmez, bir tablo basar.
##
## **Neden yeni bir araç gerekti.** Kampanya eşikleri (bkz. CampaignCatalog)
## yazıldığında ölçülemedi, çünkü elde kariyer yayını gösteren hiçbir şey
## yoktu. O turda yazılan tek kullanımlık bir prob iki tuzağa birden düştü
## ve ikisi de burada kapatıldı - ikisi de oyunun değil düzeneğin hatasıydı:
##
##   1. **Yalnızca kontrat geliriyle koşmak.** Gerçek gelirin çoğu pazarda
##      alıp satmaktan gelir (bkz. Provision Rules'un son notu). Kontrat
##      geliri tek başınayken kervan sekizinci seferde batıyor ve bütün
##      eşikler ulaşılmaz görünüyordu. Burada `playthrough_demo.gd`'nin
##      alım-satım politikası kullanılıyor: vardığın şehirde talep edileni
##      sat, ürettiğini al.
##   2. **Gidilmeyecek şehre kontrat kabul etmek.** Teslim edilemeyen her
##      kontrat itibar yiyor; politika hedefi seçmeden kontrat aldığı için
##      itibar -44'e düşüyor ve `required_reputation` bütün panoyu
##      kapatıyordu. Rota **önce** seçiliyor, kontrat sonra.
##
## Yol ekranının saat döngüsü burada taklit edilmiyor (demo onu yapıyor):
## günlük mekanikler `journey_days_remaining` ile ilerliyor ve olay günde
## bir kez çekiliyor - saat yalnızca günün *hangi saatinde* olduğunu
## değiştirir, kaç gün geçtiğini değil. Kırk seferi kare kare beslemek
## ölçtüğümüz hiçbir şeyi değiştirmeden koşuyu dakikalara çıkarırdı.

const ARC_COUNT: int = 8
const LEGS_PER_ARC: int = 40
const BASE_SEED: int = 909100

const STARTING_GOLD: int = 250
const STARTING_PROVISIONS: int = 20

## Kervana yatırım yapmadan önce kesede bırakılan pay. Sıfır olsaydı
## politika son kuruşuna kadar vagona yatırıp bir sonraki seferin erzağını
## alamaz, açlıkla yola çıkardı - bu bir oyuncu davranışı değil.
const CASH_BUFFER: int = 220

## Kariyer eğrisinin basıldığı duraklar.
const CHECKPOINTS: Array[int] = [1, 5, 10, 20, 30, 40]

## **İki politika, çünkü biri tek başına yanıltıyor** - "iki knob" dersinin
## aynısı (bkz. Ruin Rules). İlk ölçüm yalnızca "parayı vagona yatır"
## politikasıyla koştu ve üçüncü bölüm sekiz kervanın yalnızca dördünde
## kapandı. Eşiği suçlamadan önce politikanın kendisini sınamak gerekti:
## `CaravanPlan.DEFAULT_MAX_WAGONS` kervanın **toplam** tavanı, yani
## oyuncunun kendi vagonları tüccar vagonlarının yerini yiyor. Beş vagon
## alan bir kervanda escort'a tek slot kalıyor, kontrat geliri ve onunla
## birlikte itibar duruyor. Tüccar için yer bırakan ikinci politika bunu
## ayırt ediyor.
## Üçüncü politika ikisinin de cevaplamadığı soruyu cevaplıyor: kampanya
## **tasarlandığı gibi** bitirilebiliyor mu? Dördüncü bölüm sekiz teslimat
## istiyor (az vagon ister), beşinci bölüm dört vagon istiyor (çok vagon
## ister) - sabit bir politika ikisini birden yapamaz, ama bir oyuncu
## yapar: önce yalın kervanla teslimat, sonra genişleme. Kampanyacı
## politika tam da bunu yapıyor.
const POLICY_EXPAND: String = "genişleyen"
const POLICY_CONTRACTS: String = "kontratçı"
const POLICY_CAMPAIGN: String = "kampanyacı"

## Kontratçı politikanın kendine aldığı azami vagon: geri kalanı tüccara
## bırakır.
const CONTRACT_POLICY_WAGON_CAP: int = 2

## Kampanyacı politika bu bölüm kapanana kadar yalın kalır, sonra büyür.
## (Dördüncü bölüm "Temiz Defter"in indeksi.) 3 de denendi - yani "ağı
## kurunca genişlemeye başla" - ve sonuç **birebir aynı** çıktı: final
## yine 5/8, ortanca yine 30. Yani finalin 5/8'i politikanın değil,
## gerçek zorluğun ölçüsü.
const CAMPAIGN_EXPAND_AFTER_CHAPTER: int = 4

var _catalog_events: Array[GameEvent] = []

func _initialize() -> void:
	TranslationServer.set_locale("tr")
	_catalog_events = EventCatalog.get_road_events()

	print("── Wayborne kariyer simülasyonu (%d kervan × %d sefer)" % [ARC_COUNT, LEGS_PER_ARC])
	print("   Politika: pazarda al-sat, yalnızca gidilen hedefe kontrat,")
	print("   fazla parayı vagona ve kadroya yatır.")

	for policy in [POLICY_EXPAND, POLICY_CONTRACTS, POLICY_CAMPAIGN]:
		var arcs: Array[Dictionary] = []
		for arc_index in ARC_COUNT:
			arcs.append(_run_arc(BASE_SEED + arc_index * 977, policy))
		_report_curve(arcs, policy)
		_report_chapters(arcs, policy)
	quit()

# --- Bir kervanın ömrü ---

func _run_arc(seed_value: int, policy: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var session := GameSession.new(STARTING_GOLD, STARTING_PROVISIONS, 1)
	var cultures := CultureCatalog.get_cultures()
	# Kültür ile olay motoru aynı tohumdan türerse ikisi ilişkili olur ve
	# rapor sistematik olarak yanılır - bu hata bir kez yapıldı (bkz.
	# CLAUDE.md Testing). Kültür tohumun başka bir fonksiyonundan geliyor.
	var player := CharacterData.create(
		"Kervancı", cultures[(seed_value * 7 + 3) % cultures.size()].culture_id,
		CharacterStats.new()
	)
	session.start_playthrough(player, rng)

	## Bölüm kimliği -> kapandığı sefer numarası.
	var chapter_legs: Dictionary = {}
	var samples: Dictionary = {}

	for leg_index in LEGS_PER_ARC:
		var leg_number := leg_index + 1
		_invest(session, rng, policy)
		var payout := _run_leg(session, rng)
		if payout.is_empty():
			break
		# Kapanan bölümler varışın kendi sonucundan okunuyor (bkz.
		# GameSession.finish_journey) - simülatör için ayrı bir API açmak,
		# ölçtüğü şeyin oyunun yaptığı şey olmadığı anlamına gelirdi.
		for chapter in (payout.get("campaign_chapters", []) as Array):
			var closed: CampaignChapter = chapter
			if not chapter_legs.has(closed.chapter_id):
				chapter_legs[closed.chapter_id] = leg_number
		if CHECKPOINTS.has(leg_number):
			samples[leg_number] = _snapshot(session)

	samples["final"] = _snapshot(session)
	return {"chapters": chapter_legs, "samples": samples}

func _snapshot(session: GameSession) -> Dictionary:
	return {
		"gold": session.wallet.balance,
		"reputation": session.reputation,
		"wagons": session.owned_wagon_count,
		"party": session.get_party().size(),
		"contracts": session.contracts_delivered,
		"cities": session.visited_location_ids.size(),
		"debt": session.get_total_debt(),
		"days": session.total_days_elapsed,
		"chapter": session.campaign_chapter_index,
	}

## Fazla parayı kervana yatır. Kampanyanın ikinci ve beşinci bölümü tam da
## bunu istiyor, ve bir oyuncu da bunu yapar - biriken parayı kesede
## tutmak hiçbir şeye yaramaz.
func _invest(session: GameSession, rng: RandomNumberGenerator, policy: String) -> void:
	var wagon_cap := CaravanPlan.DEFAULT_MAX_WAGONS
	if policy == POLICY_CONTRACTS:
		wagon_cap = CONTRACT_POLICY_WAGON_CAP
	elif policy == POLICY_CAMPAIGN and session.campaign_chapter_index < CAMPAIGN_EXPAND_AFTER_CHAPTER:
		wagon_cap = CONTRACT_POLICY_WAGON_CAP
	if (
		session.owned_wagon_count < wagon_cap
		and session.can_buy_wagon()
		and session.wallet.balance > session.get_next_wagon_cost() + CASH_BUFFER
	):
		session.buy_wagon()

	while session.can_recruit():
		var candidate := RecruitCatalog.build_starting_companion(rng)
		# build_starting_companion ücretsiz gelir; meydan fiyatını elle
		# koyuyoruz ki kadro büyütmek gerçekten paraya mal olsun.
		candidate.hire_cost = RecruitCatalog.get_venue_profile(
			RecruitCatalog.VENUE_MARKET
		)[2]
		if session.wallet.balance <= candidate.hire_cost + CASH_BUFFER:
			break
		if not session.recruit(candidate):
			break

## Bir bacak koşar ve varışın sonucunu döner; yola çıkılamadıysa boş sözlük.
func _run_leg(session: GameSession, rng: RandomNumberGenerator) -> Dictionary:
	var origin := WorldMapData.get_location_by_id(session.current_location_id)
	if origin == null:
		return {}

	var open_routes: Array[TravelRoute] = []
	for candidate in WorldMapData.get_routes_from(session.current_location_id):
		if session.is_route_open(candidate):
			open_routes.append(candidate)
	if open_routes.is_empty():
		return {}

	var route: TravelRoute = open_routes[rng.randi_range(0, open_routes.size() - 1)]
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	if destination == null:
		return {}

	_sell_trade_goods(session, origin)
	_buy_trade_goods(session, origin)

	var travel_days := session.get_route_travel_days(route)
	var plan := _build_plan(session, destination, travel_days)
	_stock_provisions(session, plan)

	session.depart_with_contracts(plan.get_selected_offers())
	session.start_journey(
		destination.location_id, travel_days, session.get_route_danger(route), plan
	)
	_travel(session, travel_days, rng)
	return session.finish_journey()

# --- Şehirdeki para akışı (playthrough_demo.gd ile aynı politika) ---

func _sell_trade_goods(session: GameSession, origin: Location) -> void:
	var entries: Array = session.inventory.get_all_entries().duplicate()
	for entry in entries:
		var item: Item = (entry as Dictionary).item
		if item == null or item.item_id == GameSession.PROVISIONS_ITEM_ID:
			continue
		if not origin.demands.has(item.item_id):
			continue
		var quantity := session.inventory.get_quantity(item.item_id)
		if quantity <= 0:
			continue
		var unit_price := MarketPricing.get_sell_price(
			item, origin, session.market, session.total_days_elapsed
		)
		session.inventory.remove_item(item.item_id, quantity)
		session.wallet.earn(unit_price * quantity)
		session.record_sale(item.item_id, quantity)

func _buy_trade_goods(session: GameSession, origin: Location) -> void:
	for item_id in origin.produces:
		var item := ItemCatalog.get_item(item_id)
		if item == null:
			continue
		var unit_price := MarketPricing.get_buy_price(item, origin)
		var affordable := int(floor(float(session.wallet.balance) * 0.4 / float(maxi(1, unit_price))))
		var by_space := int(floor(session.get_cargo_space_remaining() / maxf(0.1, item.unit_weight)))
		var quantity := mini(mini(affordable, by_space), session.get_market_stock(item_id))
		if quantity <= 0:
			continue
		if session.inventory.add_item(item, quantity):
			session.consume_stock(item_id, quantity)
			session.wallet.spend(unit_price * quantity)

## Kontrat yalnızca **gidilecek** hedefe kabul edilir. Aksi halde teslim
## edilemeyen her kontrat itibar yer ve pano `required_reputation` ile
## kapanır - ölçüm düzeneğinin ilk denemede düştüğü tuzak buydu.
func _build_plan(session: GameSession, destination: Location, travel_days: int) -> CaravanPlan:
	var plan := CaravanPlan.new(
		destination, travel_days, CaravanPlan.DEFAULT_MAX_WAGONS, session.owned_wagon_count
	)
	plan.caravan_party_size = session.get_party().size()
	plan.provision_multiplier = session.get_daily_provision_multiplier()
	plan.provision_reduction = session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI)

	for offer in WorldMapData.get_offers_from_origin(session.current_location_id):
		if offer.destination_location_id != destination.location_id:
			continue
		if session.reputation < offer.required_reputation:
			continue
		if not plan.can_add_offer(offer):
			continue
		session.accept_contract(offer)
		plan.toggle_merchant(offer)
	return plan

func _stock_provisions(session: GameSession, plan: CaravanPlan) -> void:
	var shortfall := plan.get_provisions_shortfall(session.get_provisions())
	if shortfall <= 0:
		return
	var cost := shortfall * GameSession.PROVISIONS_UNIT_PRICE
	if not session.wallet.can_afford(cost):
		return
	session.wallet.spend(cost)
	session.change_provisions(shortfall)

# --- Yol ---

func _travel(session: GameSession, total_days: int, rng: RandomNumberGenerator) -> void:
	var engine := EventEngine.new(_catalog_events, rng.randi())
	var day := 0
	while session.journey_days_remaining > 0:
		day += 1
		session.journey_days_remaining -= 1
		_consume_daily(session)
		var event := engine.roll_for_day(day, session.build_event_context())
		if event != null:
			engine.mark_fired(event, day)
			_resolve_event(session, engine, event)

func _consume_daily(session: GameSession) -> void:
	session.advance_day()
	var daily := session.get_daily_provision_consumption()
	var fed := session.change_provisions(-daily)
	# Açlık "depo sıfırlandı" değil "bugün besleyemedik" demek (bkz.
	# Provision Rules) - eşik yanlış yazılırsa doğru stoklanmış her sefer
	# aç kalır ve bütün kariyer eğrisi bunun ölçümüne dönerdi.
	if absi(fed) < daily:
		session.caravan.change_morale(-10)
		session.change_stress(6)

func _resolve_event(session: GameSession, engine: EventEngine, event: GameEvent) -> void:
	var context := session.build_event_context()
	var chosen: EventChoice = null
	for choice in event.choices:
		if choice.is_available(context):
			chosen = choice
			break
	if chosen == null:
		return

	var result := EventEffectApplier.apply(chosen.effects, session)
	for event_id in result.unlocked_event_ids:
		engine.unlock_event(event_id)

	var outcome := engine.resolve_outcome(chosen, session.build_event_context())
	if outcome != null:
		EventEffectApplier.apply(outcome.effects, session)

# --- Rapor ---

func _report_curve(arcs: Array[Dictionary], policy: String) -> void:
	print("")
	print("── Kariyer eğrisi · %s politika (%d kervanın ortalaması)" % [policy, arcs.size()])
	print("   sefer │   kese  itibar  vagon  kadro  teslimat  şehir   borç   gün")
	for checkpoint in CHECKPOINTS:
		var totals := {"gold": 0, "reputation": 0, "wagons": 0, "party": 0,
			"contracts": 0, "cities": 0, "debt": 0, "days": 0}
		var count := 0
		for arc in arcs:
			var samples: Dictionary = arc.samples
			if not samples.has(checkpoint):
				continue
			count += 1
			var sample: Dictionary = samples[checkpoint]
			for key in totals:
				totals[key] = int(totals[key]) + int(sample[key])
		if count == 0:
			continue
		print("   %5d │ %6d  %6d  %5d  %5d  %8d  %5d  %5d  %4d" % [
			checkpoint,
			int(totals.gold / count), int(totals.reputation / count),
			int(round(float(totals.wagons) / float(count))),
			int(round(float(totals.party) / float(count))),
			int(totals.contracts / count), int(totals.cities / count),
			int(totals.debt / count), int(totals.days / count),
		])

## Asıl soru: bölüm kaçıncı seferde kapanıyor, ve kapanıyor mu? Hiç
## kapanmayan bir bölüm "katalogda var, oyunda yok" demektir - evt_mutiny
## ile aynı hata (bkz. Morale Rules).
func _report_chapters(arcs: Array[Dictionary], policy: String) -> void:
	print("")
	print("── Kampanya bölümleri · %s politika (%d sefer içinde)" % [policy, LEGS_PER_ARC])
	print("   bölüm                     kapanan  en erken  ortanca  en geç")

	for chapter in CampaignCatalog.get_chapters():
		var legs: Array[int] = []
		for arc in arcs:
			var chapters: Dictionary = arc.chapters
			if chapters.has(chapter.chapter_id):
				legs.append(int(chapters[chapter.chapter_id]))
		legs.sort()

		var title := String(TranslationServer.translate(chapter.title_key))
		if legs.is_empty():
			print("   %-24s  %d/%d  —  hiç kapanmadı" % [title, 0, arcs.size()])
			continue
		print("   %-24s  %d/%d %9d %8d %7d" % [
			title, legs.size(), arcs.size(),
			legs[0], legs[legs.size() / 2], legs[legs.size() - 1],
		])
