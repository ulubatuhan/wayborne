class_name CaravanState
extends RefCounted

## Sefer sırasındaki canlı kervan. CaravanPlan seferi planlar,
## CaravanState onu yolda taşır ve olayların hasar verdiği yerdir.

const MIN_WAGONS: int = 1
const MAX_MORALE: int = 100

var wagon_count: int = MIN_WAGONS
var damaged_wagons: int = 0
var merchant_names: Array[String] = []
var morale: int = MAX_MORALE
var documents: int = 0

static func from_plan(plan: CaravanPlan) -> CaravanState:
	var state := CaravanState.new()
	state.wagon_count = plan.get_total_wagon_count()
	state.documents = plan.get_required_documents()
	for offer in plan.get_selected_offers():
		state.merchant_names.append(offer.merchant_name)
	return state

func get_healthy_wagon_count() -> int:
	return maxi(0, wagon_count - damaged_wagons)

## Oyuncunun kendi vagonu asla kaybedilmez: kervan yıkılabilir ama yok olmaz.
func lose_wagons(count: int) -> int:
	var removable := maxi(0, wagon_count - MIN_WAGONS)
	var actually_lost := mini(count, removable)
	wagon_count -= actually_lost
	damaged_wagons = mini(damaged_wagons, wagon_count)
	return actually_lost

func damage_wagons(count: int) -> int:
	var damageable := maxi(0, wagon_count - damaged_wagons)
	var actually_damaged := mini(count, damageable)
	damaged_wagons += actually_damaged
	return actually_damaged

func remove_merchants(count: int) -> Array[String]:
	var removed: Array[String] = []
	for i in range(mini(count, merchant_names.size())):
		removed.append(merchant_names.pop_back())
	return removed

func change_morale(delta: int) -> void:
	morale = clampi(morale + delta, 0, MAX_MORALE)

func lose_documents(count: int) -> int:
	var actually_lost := mini(count, documents)
	documents -= actually_lost
	return actually_lost
