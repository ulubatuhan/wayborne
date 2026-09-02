class_name GameSession
extends RefCounted

## Oyunun tüm değişken durumu tek yerde. RefCounted olduğu için
## autoload olmadan da örneklenip test edilebilir; GameState autoload'u
## yalnızca kalıcı bir örneği tutar.

const PROVISIONS_ITEM_ID: String = "provisions"
const PROVISIONS_ITEM_NAME: String = "Erzak"
const PROVISIONS_UNIT_PRICE: int = 4

var wallet: Wallet
var inventory: Inventory
var caravan: CaravanState

## Kervanın şu an bulunduğu şehir.
var current_location_id: String = WorldMapData.START_LOCATION_ID

## Aktif sefer. journey_destination_id boşsa yolda değiliz.
var journey_origin_id: String = ""
var journey_destination_id: String = ""
var journey_total_days: int = 0
var journey_days_remaining: int = 0

var danger_level: float = 0.0
var reputation: int = 0

## Taverna'da ödeyip öğrenilmedikçe bir rotanın tam tehlike yüzdesi
## bilinmez (bkz. tavern.gd, world_map.gd - kaba bir bant gösterirler).
## "from|to" anahtarlanır; rota simetrik olduğu için öğrenince iki yön
## de kaydedilir.
var known_routes: Dictionary = {}

func is_route_known(from_location_id: String, to_location_id: String) -> bool:
	return known_routes.has(_route_key(from_location_id, to_location_id))

func learn_route(from_location_id: String, to_location_id: String) -> void:
	known_routes[_route_key(from_location_id, to_location_id)] = true
	known_routes[_route_key(to_location_id, from_location_id)] = true

func _route_key(from_location_id: String, to_location_id: String) -> String:
	return "%s|%s" % [from_location_id, to_location_id]

## Savaş partisi. Oyuncunun kendi karakteri partiden çıkarılamaz -
## kim olduğu CharacterData.is_player'dan okunur, sırasından değil;
## sıralama savaştaki mevki sırasıdır ve oyuncu arkaya geçebilir.
## Bu, vagonların taşıdığı isimsiz tayfadan ayrı bir kavramdır: tayfa
## kargo kapasitesini belirler, parti ise savaşa giren adı olan kişilerdir.
##
## Kaç kişi taşıyabildiğin vagon sayısına bağlı (her vagonda iki kişi
## yatar), ama savaş alanı dört mevkiden ibaret olduğu için tavan
## MAX_PARTY_SIZE. Yani vagon almak partiye yer açar - kervansaraydaki
## vagon alımı böylece savaşa da dokunuyor.
const MAX_PARTY_SIZE: int = 4
const PEOPLE_PER_WAGON: int = 2

var party: Array[CharacterData] = []

func get_party_capacity() -> int:
	return clampi(owned_wagon_count * PEOPLE_PER_WAGON, 1, MAX_PARTY_SIZE)

func get_party() -> Array[CharacterData]:
	_ensure_party()
	return party

## Oyuncu partide arkaya geçebildiği için sıraya değil bayrağa bakılır.
func get_player_character() -> CharacterData:
	_ensure_party()
	for character in party:
		if character.is_player:
			return character
	return party[0]

## Karakter oluşturma ekranı çağırır; mevcut parti sıfırlanır.
func set_player_character(character: CharacterData) -> void:
	character.is_player = true
	party = [character]

func can_recruit() -> bool:
	_ensure_party()
	return party.size() < get_party_capacity()

## Ücreti keseden düşüp partiye katar. Kese yetmezse ya da parti doluysa
## false döner, hiçbir şey değişmez.
func recruit(character: CharacterData) -> bool:
	if not can_recruit():
		return false
	if not wallet.can_afford(character.hire_cost):
		return false
	wallet.spend(character.hire_cost)
	character.is_player = false
	character.heal_full()
	party.append(character)
	return true

## Oyuncunun kendisi çıkarılamaz. Kontrol sıraya göre değil bayrağa göre:
## oyuncu arkaya geçtiğinde kendini atabilmesi bir hataydı.
func dismiss(character: CharacterData) -> bool:
	if character == null or character.is_player:
		return false
	var index := party.find(character)
	if index < 0:
		return false
	party.remove_at(index)
	return true

## Parti mevkilerini değiştirir; oyuncu da yer değiştirebilir - sırası
## savaştaki mevkisidir, kim olduğunu belirlemez.
func swap_party_positions(first_index: int, second_index: int) -> bool:
	if first_index == second_index:
		return false
	if first_index < 0 or second_index < 0:
		return false
	if first_index >= party.size() or second_index >= party.size():
		return false
	var temp := party[first_index]
	party[first_index] = party[second_index]
	party[second_index] = temp
	return true

# --- Görevler (Duty): kimin ne iş yaptığı, DutyCatalog.get_duty_power() ---

## Bir görevi bir karaktere verir; aynı görevi tutan başkası varsa
## boşa çıkar - bir görevin tek sahibi olabilir.
func assign_duty(character: CharacterData, duty_id: String) -> void:
	if character == null or not get_party().has(character):
		return
	for other in get_party():
		if other != character and other.duty_id == duty_id:
			other.duty_id = ""
	character.duty_id = duty_id

func get_duty_holder(duty_id: String) -> CharacterData:
	for character in get_party():
		if character.duty_id == duty_id:
			return character
	return null

## Görevin ham gücü: sahibi yoksa 1.0 (nötr - ne bonus ne ceza).
func get_duty_multiplier(duty_id: String) -> float:
	var holder := get_duty_holder(duty_id)
	if holder == null:
		return 1.0
	return DutyCatalog.get_duty_power(holder, duty_id)

## Yüzdesel indirimler için (pazar fiyatı, onarım bedeli gibi):
## 0.0 = indirim yok, tavan %20.
func get_duty_discount(duty_id: String) -> float:
	return clampf((get_duty_multiplier(duty_id) - 1.0) * 0.3, 0.0, 0.2)

## Tam sayı azaltmalar için (günlük erzak tüketimi, vagon hasarı gibi).
func get_duty_flat_reduction(duty_id: String) -> int:
	return int(floor((get_duty_multiplier(duty_id) - 1.0) / 0.2))

## Tüm partiye eşit XP dağıtır, kimin kaç seviye atladığını döner
## (isim -> seviye sayısı; hiç atlamayan kişi listede yer almaz).
func grant_party_xp(amount: int) -> Dictionary:
	var levels_gained: Dictionary = {}
	if amount <= 0:
		return levels_gained
	for character in get_party():
		var gained := character.gain_xp(amount)
		if gained > 0:
			levels_gained[character.character_name] = gained
	return levels_gained

func heal_party() -> void:
	for character in party:
		character.heal_full()

## Kayıtsız/eski bir oturumda bile savaşa sokacak birinin bulunması için
## varsayılan bir karakter kurar.
func _ensure_party() -> void:
	if party.is_empty():
		var culture := CultureCatalog.get_cultures()[0]
		var fallback := CharacterData.create(
			culture.name_pool[0], culture.culture_id, CharacterStats.new()
		)
		fallback.is_player = true
		party = [fallback]

# --- Kültür perkleri: tek yerden okunur, ekranlar formülü kopyalamaz ---

func get_player_culture() -> Culture:
	return get_player_character().get_culture()

func get_daily_provision_multiplier() -> float:
	return get_player_culture().daily_provision_multiplier

func get_provision_cost_multiplier() -> float:
	return get_player_culture().provision_cost_multiplier

func get_buy_price_multiplier() -> float:
	return get_player_culture().buy_price_multiplier

func get_rumor_cost_multiplier() -> float:
	return get_player_culture().rumor_cost_multiplier

## Tüm seferler boyunca ilerleyen gün sayacı (bkz. road_journey.gd
## _on_advance_day). journey_days_remaining bir seferin kalan gününü
## sayar, bu ise hiç sıfırlanmaz - kontrat panosunun süre takibi için.
var total_days_elapsed: int = 0

## Tüccar Loncası'nda kabul edilen ama henüz sefere çıkılmamış kontratlar
## (merchant_id -> kabul edildiği gün). Sefere çıkılınca depart_with_
## contracts() ile kaldırılır - artık kervanın kendi mekanikleri
## (yolda ayrılma, varışta ödeme) geçerlidir. Süresi geçerse advance_day()
## itibar cezasıyla kaldırır.
var accepted_contracts: Dictionary = {}
const REPUTATION_PENALTY_PER_LOST_CONTRACT: int = 5

func accept_contract(offer: MerchantOffer) -> void:
	accepted_contracts[offer.merchant_id] = total_days_elapsed

func is_contract_accepted(merchant_id: String) -> bool:
	return accepted_contracts.has(merchant_id)

## Yalnızca oyuncunun şu an bulunduğu şehirde kabul edilmiş ve o şehirden
## çıkan kontratları döner - kontrat başka bir şehirde kabul edilmişse
## oyuncu oraya dönmeden onu yola çıkaramaz.
func get_accepted_offers_for_destination(destination_location_id: String) -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	for merchant_id in accepted_contracts:
		var offer := WorldMapData.get_offer_by_merchant_id(merchant_id)
		if offer == null:
			continue
		if offer.destination_location_id != destination_location_id:
			continue
		if offer.origin_location_id != current_location_id:
			continue
		offers.append(offer)
	return offers

## Yola çıkılan kontratlar panodan düşer - artık kervanın kendi
## mekanikleri geçerlidir (bkz. CaravanState.original_merchant_names).
func depart_with_contracts(offers: Array[MerchantOffer]) -> void:
	for offer in offers:
		accepted_contracts.erase(offer.merchant_id)

## Sefer gününü ilerletir, süresi geçen kontratları panodan düşürüp
## itibar cezası uygular. Süresi geçenlerin merchant_id listesini döner
## (bkz. road_journey.gd - günlüğe not düşer).
func advance_day() -> Array[String]:
	total_days_elapsed += 1
	var expired: Array[String] = []
	for merchant_id in accepted_contracts.keys():
		var offer := WorldMapData.get_offer_by_merchant_id(merchant_id)
		if offer == null:
			continue
		var accepted_at: int = accepted_contracts[merchant_id]
		if total_days_elapsed > accepted_at + offer.contract_deadline_days:
			expired.append(merchant_id)

	for merchant_id in expired:
		accepted_contracts.erase(merchant_id)
		reputation -= REPUTATION_PENALTY_PER_LOST_CONTRACT

	return expired

## Oyuncunun kalıcı olarak sahip olduğu vagon sayısı ve bunların kaç
## tanesinin hasarlı olduğu. Şehirdeyken geçerli olan bu; sefer sırasında
## CaravanState.wagon_count (escort dahil havuz) geçerli - sefer bitince
## kayıp/hasar buraya taşınır (bkz. _apply_wagon_losses_to_ownership).
var owned_wagon_count: int = 1
var owned_wagon_damaged: int = 0

## Kervansaray fiyatları: yeni vagon sahip olunan vagon sayısı arttıkça
## kademeli pahalanır, onarım hasarlı vagon başına sabit ücrettir.
const WAGON_PURCHASE_BASE_COST: int = 150
const WAGON_PURCHASE_COST_STEP: int = 60
const WAGON_REPAIR_COST_PER_WAGON: int = 30

func get_next_wagon_cost() -> int:
	return WAGON_PURCHASE_BASE_COST + (owned_wagon_count - CaravanState.MIN_WAGONS) * WAGON_PURCHASE_COST_STEP

func can_buy_wagon() -> bool:
	return owned_wagon_count < CaravanPlan.DEFAULT_MAX_WAGONS

## Başarısızsa (kese yetmez ya da limit dolu) false döner, hiçbir şey
## değişmez.
func buy_wagon() -> bool:
	if not can_buy_wagon():
		return false
	var cost := get_next_wagon_cost()
	if not wallet.can_afford(cost):
		return false
	wallet.spend(cost)
	owned_wagon_count += 1
	return true

func get_repair_cost() -> int:
	var base := owned_wagon_damaged * WAGON_REPAIR_COST_PER_WAGON
	return int(round(base * (1.0 - get_duty_discount(DutyCatalog.ARABACI))))

## Tüm hasarlı vagonları tek seferde onarır. Başarısızsa (hasar yok ya
## da kese yetmez) false döner.
func repair_wagons() -> bool:
	if owned_wagon_damaged <= 0:
		return false
	var cost := get_repair_cost()
	if not wallet.can_afford(cost):
		return false
	wallet.spend(cost)
	owned_wagon_damaged = 0
	return true

## Vagon başına taşınabilecek yük. Yalnızca pazardan alınan mallara
## uygulanır; erzak kendi sefer formülüyle sınırlı, kapasiteye dahil değil.
const CARGO_PER_WAGON: float = 50.0

## Sefer sonu ödemesi: moral ve hasar ne kadar düşükse ücret o kadar
## kısılır ama asla sıfırlanmaz - kervan ağır kayıp yaşayabilir, aç kalmaz.
const MIN_MORALE_PAYOUT_FACTOR: float = 0.5
const DAMAGE_PENALTY_PER_WAGON: float = 0.08
const MIN_DAMAGE_PAYOUT_FACTOR: float = 0.4

var _flags: Dictionary = {}
var _provisions_item: Item

func _init(starting_gold: int = 250, starting_provisions: int = 20, starting_wagon_count: int = 1) -> void:
	wallet = Wallet.new(starting_gold)
	inventory = Inventory.new()
	caravan = CaravanState.new()
	owned_wagon_count = clampi(starting_wagon_count, CaravanState.MIN_WAGONS, CaravanPlan.DEFAULT_MAX_WAGONS)

	_provisions_item = Item.new()
	_provisions_item.item_id = PROVISIONS_ITEM_ID
	_provisions_item.item_name = PROVISIONS_ITEM_NAME
	_provisions_item.base_price = PROVISIONS_UNIT_PRICE

	if starting_provisions > 0:
		inventory.add_item(_provisions_item, starting_provisions)

	_restock_current_location()

## Şehrin mevcut pazar stoğu (item_id -> kalan miktar). Yalnızca
## current_location_id şehri için geçerli; her varışta (finish_journey()
## ve ilk kuruluş) o şehrin Location.stock_per_item'ından tam dolu
## başlar - günlük bir ekonomi simülasyonu yok, placeholder için bu
## yeterli. Listede olmayan mallar sınırsız kabul edilir.
var market_stock: Dictionary = {}

## -1 = sınırsız.
func get_market_stock(item_id: String) -> int:
	return market_stock.get(item_id, -1)

func consume_stock(item_id: String, quantity: int) -> void:
	if market_stock.has(item_id):
		market_stock[item_id] = maxi(0, market_stock[item_id] - quantity)

func _restock_current_location() -> void:
	market_stock.clear()
	var location := WorldMapData.get_location_by_id(current_location_id)
	if location != null:
		for item_id in location.stock_per_item:
			market_stock[item_id] = location.stock_per_item[item_id]
	_restock_recruits()

## Şehirdeki partiye katılabilecek adaylar (mekân -> aday listesi).
## Pazar stoğuyla aynı ritimde, her varışta bir kez tazelenir; tohum
## şehir + gün olduğu için aynı varışta ekran kapatıp açmak listeyi
## değiştirmez.
var recruit_candidates: Dictionary = {}

func _restock_recruits() -> void:
	recruit_candidates.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d" % [current_location_id, total_days_elapsed])
	for venue in [
		RecruitCatalog.VENUE_MARKET, RecruitCatalog.VENUE_TAVERN, RecruitCatalog.VENUE_GUILD
	]:
		recruit_candidates[venue] = RecruitCatalog.build_candidates(venue, rng)

func get_recruit_candidates(venue: String) -> Array[CharacterData]:
	var candidates: Array[CharacterData] = []
	for candidate in recruit_candidates.get(venue, []):
		candidates.append(candidate)
	return candidates

## Adayı partiye katar ve mekânın listesinden düşürür. İtibar, kese ya da
## parti sınırı yetmezse false döner, hiçbir şey değişmez.
func hire_recruit(venue: String, candidate: CharacterData) -> bool:
	if reputation < RecruitCatalog.get_venue_required_reputation(venue):
		return false
	if not recruit_candidates.get(venue, []).has(candidate):
		return false
	if not recruit(candidate):
		return false
	recruit_candidates[venue].erase(candidate)
	return true

func get_provisions() -> int:
	return inventory.get_quantity(PROVISIONS_ITEM_ID)

## Negatif miktarlarda sıfırın altına inmez; gerçekten düşen miktarı döner.
func change_provisions(delta: int) -> int:
	if delta > 0:
		inventory.add_item(_provisions_item, delta)
		return delta

	var removable := mini(-delta, get_provisions())
	if removable > 0:
		inventory.remove_item(PROVISIONS_ITEM_ID, removable)
	return -removable

func has_flag(flag: String) -> bool:
	return _flags.has(flag)

func set_flag(flag: String) -> void:
	_flags[flag] = true

func clear_flag(flag: String) -> void:
	_flags.erase(flag)

# --- Sefer ---

func is_journey_active() -> bool:
	return not journey_destination_id.is_empty()

## Planlayıcıda onaylanan kervanı yola çıkarır.
func start_journey(destination_id: String, days: int, danger: float, plan: CaravanPlan) -> void:
	journey_origin_id = current_location_id
	journey_destination_id = destination_id
	journey_total_days = maxi(1, days)
	journey_days_remaining = journey_total_days
	danger_level = danger
	caravan = CaravanState.from_plan(plan)

## Hedefe varıldığında çağrılır: escort ücretini öder, sefer sırasındaki
## kayıp/hasarı oyuncunun kalıcı vagon sahipliğine taşır, konumu günceller
## ve seferi temizler (escort ettiği tüccarlar hedefe ulaşıp ayrılmıştır).
## Ödeme dökümünü döner.
func finish_journey() -> Dictionary:
	var payout := _calculate_arrival_payout()
	wallet.earn(payout.net)
	_apply_wagon_losses_to_ownership()
	payout["lost_contracts"] = _apply_undelivered_contract_penalty()

	# XP hesabı sıfırlanmadan önce yapılmalı: moral ve kontrat kaybı seferin
	# "başarılı" mı "başarısız" mı sayıldığını belirliyor (bkz. _calculate_journey_xp).
	var journey_xp := _calculate_journey_xp(
		journey_total_days, danger_level,
		caravan.morale / float(CaravanState.MAX_MORALE),
		payout["lost_contracts"]
	)
	payout["xp_awarded"] = journey_xp
	payout["levels_gained"] = grant_party_xp(journey_xp)

	if not journey_destination_id.is_empty():
		current_location_id = journey_destination_id
	journey_origin_id = ""
	journey_destination_id = ""
	journey_total_days = 0
	journey_days_remaining = 0
	danger_level = 0.0
	caravan = CaravanState.new()
	_restock_current_location()
	heal_party()

	return payout

## Yolda kervandan ayrılan (teslim edilemeyen) her kontrat için itibar
## cezası uygular. Kaç kontratın kaybedildiğini döner.
func _apply_undelivered_contract_penalty() -> int:
	var lost := 0
	for merchant_name in caravan.original_merchant_names:
		if not caravan.merchant_names.has(merchant_name):
			lost += 1
	reputation -= lost * REPUTATION_PENALTY_PER_LOST_CONTRACT
	return lost

## Sefer sırasındaki kayıp/hasar kervanın havuzundan (oyuncu + escort
## tüccarların vagonları birlikte) uygulanıyor. Buradan oyuncunun payına
## düşeni çıkarır: escort vagonları önce kaybedilir/hasar alır, oyuncunun
## kendi vagonu yalnızca escort tükendikten sonra etkilenir.
func _apply_wagon_losses_to_ownership() -> void:
	var escort_at_start := maxi(0, caravan.wagons_at_start - caravan.player_wagon_count_at_start)
	var total_lost := maxi(0, caravan.wagons_at_start - caravan.wagon_count)
	var escort_lost := mini(total_lost, escort_at_start)
	var player_lost := total_lost - escort_lost

	var escort_remaining := escort_at_start - escort_lost
	var escort_damaged := mini(caravan.damaged_wagons, escort_remaining)
	var player_damaged := caravan.damaged_wagons - escort_damaged

	owned_wagon_count = maxi(CaravanState.MIN_WAGONS, owned_wagon_count - player_lost)
	owned_wagon_damaged = clampi(owned_wagon_damaged + player_damaged, 0, owned_wagon_count)

const JOURNEY_XP_BASE: int = 15
const JOURNEY_XP_PER_DAY: float = 4.0
const JOURNEY_XP_DANGER_BONUS: float = 40.0
const JOURNEY_XP_FAILURE_FACTOR: float = 0.25
const JOURNEY_SUCCESS_MORALE_RATIO: float = 0.5

## Başarı ölçütü kervanın hiç yok olmaması değil (o zaten garanti) - moral
## yarının altına düşmeden ve hiç kontrat kaybetmeden varmak. Tutmazsa
## sefer yine tamamlanmış sayılır ama XP'nin yalnızca çeyreği kazanılır.
func _calculate_journey_xp(days: int, danger: float, morale_ratio: float, lost_contracts: int) -> int:
	var base := float(JOURNEY_XP_BASE) + float(days) * JOURNEY_XP_PER_DAY + danger * JOURNEY_XP_DANGER_BONUS
	var succeeded := morale_ratio >= JOURNEY_SUCCESS_MORALE_RATIO and lost_contracts == 0
	var factor := 1.0 if succeeded else JOURNEY_XP_FAILURE_FACTOR
	return maxi(0, int(round(base * factor)))

func _calculate_arrival_payout() -> Dictionary:
	var gross := 0
	for merchant_name in caravan.merchant_names:
		gross += caravan.merchant_profit_by_name.get(merchant_name, 0)

	var morale_factor := lerpf(
		MIN_MORALE_PAYOUT_FACTOR, 1.0, caravan.morale / float(CaravanState.MAX_MORALE)
	)
	var damage_factor := maxf(
		MIN_DAMAGE_PAYOUT_FACTOR, 1.0 - caravan.damaged_wagons * DAMAGE_PENALTY_PER_WAGON
	)
	var net := int(round(gross * morale_factor * damage_factor))

	return {
		"gross": gross,
		"morale_factor": morale_factor,
		"damage_factor": damage_factor,
		"net": net,
	}

## Yalnızca pazardan alınan mallara uygulanır (bkz. CARGO_PER_WAGON).
## Şehirdeyken geçerli olan sahiplik sayısını kullanır - sefer sırasında
## kargo alışverişi zaten mümkün değil (market yalnızca şehirde açılır).
func get_cargo_capacity() -> float:
	return owned_wagon_count * CARGO_PER_WAGON

func get_cargo_weight() -> float:
	var total := 0.0
	for entry in inventory.get_all_entries():
		var item: Item = entry.item
		if item.item_id == PROVISIONS_ITEM_ID:
			continue
		total += item.unit_weight * entry.quantity
	return total

func get_cargo_space_remaining() -> float:
	return maxf(0.0, get_cargo_capacity() - get_cargo_weight())

## Kalıcı kayıt yalnızca şehir varışında alınır (bkz. SaveManager,
## scripts/ui/road_journey.gd), o noktada sefer hiç aktif değildir ve
## finish_journey() zaten kervanı temizleyip kayıp/hasarı sahiplik
## alanlarına taşımıştır. Bu yüzden journey_*/caravan hiç serileştirilmiyor
## - saklayacak anlamlı bir durumları yok; owned_wagon_* kalıcı olduğu
## için serileştiriliyor.
const SAVE_VERSION: int = 1

func to_save_dict() -> Dictionary:
	var inventory_data: Array = []
	for entry in inventory.get_all_entries():
		var item: Item = entry.item
		inventory_data.append({"item_id": item.item_id, "quantity": entry.quantity})

	var party_data: Array = []
	for character in party:
		party_data.append(character.to_dict())

	return {
		"version": SAVE_VERSION,
		"gold": wallet.balance,
		"inventory": inventory_data,
		"current_location_id": current_location_id,
		"reputation": reputation,
		"flags": _flags.duplicate(),
		"owned_wagon_count": owned_wagon_count,
		"owned_wagon_damaged": owned_wagon_damaged,
		"known_routes": known_routes.duplicate(),
		"total_days_elapsed": total_days_elapsed,
		"accepted_contracts": accepted_contracts.duplicate(),
		"party": party_data,
	}

## Çağıranın taze bir GameSession.new(0, 0) üzerinde çağırması beklenir -
## sıfır başlangıç erzağıyla, aksi halde erzak iki kere eklenir.
func load_from_dict(data: Dictionary) -> void:
	wallet.earn(int(data.get("gold", 0)))

	for entry in data.get("inventory", []):
		var item := ItemCatalog.get_item(String(entry.get("item_id", "")))
		var quantity := int(entry.get("quantity", 0))
		if item != null and quantity > 0:
			inventory.add_item(item, quantity)

	current_location_id = String(data.get("current_location_id", WorldMapData.START_LOCATION_ID))
	reputation = int(data.get("reputation", 0))
	_flags = (data.get("flags", {}) as Dictionary).duplicate()
	owned_wagon_count = clampi(
		int(data.get("owned_wagon_count", 1)), CaravanState.MIN_WAGONS, CaravanPlan.DEFAULT_MAX_WAGONS
	)
	owned_wagon_damaged = clampi(int(data.get("owned_wagon_damaged", 0)), 0, owned_wagon_count)
	known_routes = (data.get("known_routes", {}) as Dictionary).duplicate()
	total_days_elapsed = int(data.get("total_days_elapsed", 0))
	accepted_contracts = {}
	for merchant_id in (data.get("accepted_contracts", {}) as Dictionary):
		accepted_contracts[merchant_id] = int(data["accepted_contracts"][merchant_id])

	party.clear()
	for entry in data.get("party", []):
		party.append(CharacterData.from_dict(entry))
	_ensure_party()

	_restock_current_location()

## Koşulların baktığı düz sözlük. Her olay değerlendirmesinde bir kez
## kurulur, tek tek koşullar bunun üzerinde tahsisatsız çalışır.
func build_event_context() -> Dictionary:
	return {
		"gold": wallet.balance,
		"provisions": get_provisions(),
		"wagons": caravan.wagon_count,
		"healthy_wagons": caravan.get_healthy_wagon_count(),
		"damaged_wagons": caravan.damaged_wagons,
		"merchants": caravan.merchant_names.size(),
		"morale": caravan.morale,
		"documents": caravan.documents,
		"danger": danger_level,
		"days_remaining": journey_days_remaining,
		"reputation": reputation,
		# get_party(), partiyi henüz kimse okumadıysa kurar. Doğrudan
		# party.size() okumak taze bir oturumda 0 döndürüyordu, yani
		# koşullar olmayan bir boş yer görüyordu.
		"party_size": get_party().size(),
		# Koşullar başka bir anahtarla karşılaştırma yapamadığı için boş
		# yer sayısı hazır veriliyor (bkz. evt_road_wanderer).
		"party_slots_free": maxi(0, get_party_capacity() - get_party().size()),
		"flags": _flags,
	}
