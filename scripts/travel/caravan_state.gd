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

## Sefer sonunda ödenecek escort ücreti burada tutulur; bir tüccar
## kervandan ayrılırsa merchant_names'ten düşer ve ücreti ödenmez.
var merchant_profit_by_name: Dictionary = {}

## Sefer başındaki tüccar listesinin değişmez kopyası: finish_journey()
## bunu merchant_names ile karşılaştırıp yolda kimin kaybedildiğini
## (kontratın teslim edilemediğini) bulur ve itibar cezası uygular.
var original_merchant_names: Array[String] = []

## Sefer başındaki anlık görüntü: kayıp/hasarı GameSession.finish_journey()
## oyuncunun kalıcı sahipliğine adil paylaştırabilsin diye tutulur -
## escort vagonları önce gider, oyuncunun kendi vagonu en son.
var wagons_at_start: int = MIN_WAGONS
var player_wagon_count_at_start: int = MIN_WAGONS

static func from_plan(plan: CaravanPlan) -> CaravanState:
	var state := CaravanState.new()
	state.wagon_count = plan.get_total_wagon_count()
	state.wagons_at_start = state.wagon_count
	state.player_wagon_count_at_start = plan.player_wagon_count
	state.documents = plan.get_required_documents()
	for offer in plan.get_selected_offers():
		state.merchant_names.append(offer.merchant_name)
		state.merchant_profit_by_name[offer.merchant_name] = offer.potential_profit
	state.original_merchant_names = state.merchant_names.duplicate()
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
