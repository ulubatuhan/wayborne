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

func _init(starting_gold: int = 250, starting_provisions: int = 20) -> void:
	wallet = Wallet.new(starting_gold)
	inventory = Inventory.new()
	caravan = CaravanState.new()

	_provisions_item = Item.new()
	_provisions_item.item_id = PROVISIONS_ITEM_ID
	_provisions_item.item_name = PROVISIONS_ITEM_NAME
	_provisions_item.base_price = PROVISIONS_UNIT_PRICE

	if starting_provisions > 0:
		inventory.add_item(_provisions_item, starting_provisions)

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

## Hedefe varıldığında çağrılır: escort ücretini öder, konumu günceller,
## kervanı oyuncunun tek vagonuna indirger (escort ettiği tüccarlar
## hedefe ulaşıp ayrılmıştır) ve seferi temizler. Ödeme dökümünü döner.
func finish_journey() -> Dictionary:
	var payout := _calculate_arrival_payout()
	wallet.earn(payout.net)

	if not journey_destination_id.is_empty():
		current_location_id = journey_destination_id
	journey_origin_id = ""
	journey_destination_id = ""
	journey_total_days = 0
	journey_days_remaining = 0
	danger_level = 0.0
	caravan = CaravanState.new()

	return payout

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
func get_cargo_capacity() -> float:
	return caravan.wagon_count * CARGO_PER_WAGON

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
		"flags": _flags,
	}
