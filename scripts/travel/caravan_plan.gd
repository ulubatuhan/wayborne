class_name CaravanPlan
extends RefCounted

## Bir seyahat için kervan kompozisyonunu ve lojistik gereksinimlerini hesaplar.
## UI'dan bağımsız: sahne ağacı gerektirmez, doğrudan örneklenip test edilebilir.

const PROVISIONS_PER_PERSON_PER_DAY: int = 1
const DEFAULT_MAX_WAGONS: int = 6
const DEFAULT_PLAYER_WAGON_COUNT: int = 1

signal selection_changed()

var destination: Location
var travel_days: int
var max_wagons: int
var player_wagon_count: int

var _selected_offers: Array[MerchantOffer] = []

func _init(
	p_destination: Location,
	p_travel_days: int,
	p_max_wagons: int = DEFAULT_MAX_WAGONS,
	p_player_wagon_count: int = DEFAULT_PLAYER_WAGON_COUNT
) -> void:
	destination = p_destination
	travel_days = p_travel_days
	max_wagons = p_max_wagons
	player_wagon_count = p_player_wagon_count

## Tüccarlara açık vagon slotu: toplam limitten oyuncunun kendi vagonu düşülür.
func get_available_wagon_slots() -> int:
	return max_wagons - player_wagon_count

func get_used_wagon_count() -> int:
	var total := 0
	for offer in _selected_offers:
		total += offer.wagon_count
	return total

func get_total_wagon_count() -> int:
	return player_wagon_count + get_used_wagon_count()

func is_selected(offer: MerchantOffer) -> bool:
	return _selected_offers.has(offer)

func can_add_offer(offer: MerchantOffer) -> bool:
	if is_selected(offer):
		return false
	return get_used_wagon_count() + offer.wagon_count <= get_available_wagon_slots()

## Seçiliyse çıkarır, değilse (yer varsa) ekler. İşlem uygulandıysa true döner.
func toggle_merchant(offer: MerchantOffer) -> bool:
	if is_selected(offer):
		_selected_offers.erase(offer)
		selection_changed.emit()
		return true

	if not can_add_offer(offer):
		return false

	_selected_offers.append(offer)
	selection_changed.emit()
	return true

func get_selected_offers() -> Array[MerchantOffer]:
	return _selected_offers

## Oyuncu + her tüccar bir kişi sayılır (placeholder varsayım).
func get_party_size() -> int:
	return 1 + _selected_offers.size()

## Her vagon sınır/gümrük geçişinde ayrı evrak gerektirir.
func get_required_documents() -> int:
	return get_total_wagon_count()

func get_required_provisions() -> int:
	return get_party_size() * travel_days * PROVISIONS_PER_PERSON_PER_DAY

func get_provisions_shortfall(current_provisions: int) -> int:
	return maxi(0, get_required_provisions() - current_provisions)

func get_total_profit() -> int:
	var total := 0
	for offer in _selected_offers:
		total += offer.potential_profit
	return total
