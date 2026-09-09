class_name CaravanState
extends RefCounted

## Sefer sırasındaki canlı kervan. CaravanPlan seferi planlar,
## CaravanState onu yolda taşır ve olayların hasar verdiği yerdir.

const MIN_WAGONS: int = 1
const MAX_MORALE: int = 100

## Yolun kendisi yıpratır. Moral eskiden yalnızca kesikli olay darbeleriyle
## düşüyordu, o yüzden uzun bir sefer kısa bir seferden daha yorucu
## değildi ve moral tabanı hiç görülmüyordu (bkz. CLAUDE.md Morale Rules).
## Küçük tutuluyor: bir günü tek başına belirlemesin, ama on beş gün
## sonunda kendini göstersin.
const MORALE_DRAIN_PER_DAY: int = 1

## Aşınmanın altına inemeyeceği taban. Kervan yorulur ama yalnızca yürüdüğü
## için isyan etmez - dibe vurmak için gerçekten kötü şeyler olmalı.
const MORALE_DRIFT_FLOOR: int = 35

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

## departure_morale, kervanın yola hangi ruh haliyle çıktığı: dünyanın o
## günkü hali belirliyor (bkz. GameSession.get_departure_morale). Verilmezse
## eski davranış - dolu moralle çıkış - korunuyor, yani bu katmanı bilmeyen
## bir çağıran (testler, F1 sahte seferi) etkilenmiyor.
static func from_plan(plan: CaravanPlan, departure_morale: int = MAX_MORALE) -> CaravanState:
	var state := CaravanState.new()
	state.morale = clampi(departure_morale, 0, MAX_MORALE)
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

## Yolda onarım (bkz. evt_traveling_tinker): şehirdeki kervansaray
## onarımının yol karşılığı. Gerçekten onarılan vagon sayısını döner -
## hasarlıdan fazlası onarılamaz.
func repair_wagons(count: int) -> int:
	var repaired := mini(maxi(0, count), damaged_wagons)
	damaged_wagons -= repaired
	return repaired

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

## Yolda geçen her günün kendi bedeli. Yalnızca tabanın üstündeyken işler:
## yürümenin tek başına kervanı isyana sürüklememesi gerekiyor, oraya
## inmek için olayların da kötü gitmesi lazım.
func apply_daily_drift() -> void:
	if morale <= MORALE_DRIFT_FLOOR:
		return
	morale = maxi(MORALE_DRIFT_FLOOR, morale - MORALE_DRAIN_PER_DAY)

func lose_documents(count: int) -> int:
	var actually_lost := mini(count, documents)
	documents -= actually_lost
	return actually_lost
