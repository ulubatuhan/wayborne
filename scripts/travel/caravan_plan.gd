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

## Erzak hesabının kervana bağlı parçaları. Plan sahne ağacından bağımsız
## kalsın diye oturumu tanımıyor; bunları planı kuran ekran doldurur
## (bkz. caravan_planner.gd). Doldurulmazsa eski, tek kişilik davranış.
var caravan_party_size: int = 1
var provision_multiplier: float = 1.0
var provision_reduction: int = 0

## Kötü havanın yola kattığı gün - planı kuran ekran
## `RouteWeather.forecast_extra_days()` ile dolduruyor.
##
## Bu alan bir denge yamasından çok bir sözün bedeli: hava yolu
## yavaşlatıyor (yağmurda çamur, fırtınada durma), o yüzden aynı rota daha
## çok gün yiyor. Erzak payı buraya yazılmasa "doğru stokladım ve yine aç
## kaldım" olurdu - ki tam olarak kıtlık hatasının yaptığı şeydi
## (bkz. Provision Rules). Sıfırsa davranış hava eklenmeden önceki gibi.
var weather_reserve_days: int = 0

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

## Kervanın bir günde yediği erzak. Beslenen ağızlar: isimli parti üyeleri,
## vagon başına tayfa (GameSession.PEOPLE_PER_WAGON) ve kervana katılan
## tüccarlar - yani vagon almak artık yalnızca kapasite kazandırmıyor,
## beslenecek iki ağız daha getiriyor.
##
## Bu formülün tek yerde durması şart. Üç ayrı kopyası vardı - planlayıcı
## "şu kadar gerekli" derken yalnızca tüccarları sayıyor, yol tüketirken
## levazımcıyı da düşüyor, simülatör üçüncü bir hesap yapıyordu. Kopyalar
## birbirinden kaydığı an planlayıcı yalan söyler ve oyuncu yolda aç kalır.
static func daily_consumption(
	party_size: int, owned_wagons: int, merchant_count: int,
	multiplier: float = 1.0, flat_reduction: int = 0
) -> int:
	var mouths := (
		maxi(1, party_size)
		+ maxi(0, owned_wagons) * GameSession.PEOPLE_PER_WAGON
		+ maxi(0, merchant_count)
	)
	var eaten := int(round(float(mouths * PROVISIONS_PER_PERSON_PER_DAY) * maxf(0.0, multiplier)))
	return maxi(1, eaten - maxi(0, flat_reduction))

func get_daily_consumption() -> int:
	return daily_consumption(
		caravan_party_size,
		player_wagon_count,
		_selected_offers.size(),
		provision_multiplier,
		provision_reduction
	)

## Yolun *gerçekte* kaç gün süreceği: taban süre + kötü hava payı.
func get_provisioned_days() -> int:
	return maxi(0, travel_days) + maxi(0, weather_reserve_days)

func get_required_provisions() -> int:
	return get_daily_consumption() * get_provisioned_days()

func get_provisions_shortfall(current_provisions: int) -> int:
	return maxi(0, get_required_provisions() - current_provisions)

func get_total_profit() -> int:
	var total := 0
	for offer in _selected_offers:
		total += offer.potential_profit
	return total
