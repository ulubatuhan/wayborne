class_name JourneyController
extends RefCounted

## Bir seferin görsel olmayan yarısı: kat edilen mesafe, takvim günü, tempo,
## kamp, yolda bekleyen karşılaşma, saat ve olay motoru. Yol ekranı
## (`road_journey.gd`) eskiden bunların hepsini kendi alanlarında tutuyordu,
## o yüzden seferin çekirdek döngüsü yalnızca sahne içinde koşabiliyor ve
## hiçbir şekilde kaydedilemiyordu. Şimdi durum burada, ekran yalnızca
## çiziyor ve girdiyi okuyor.
##
## İki şey kazandırıyor:
## 1. **Sınanabilirlik** - yürüyüş formülü, varış ve karşılaşmaya ulaşma
##    kontrolü sahne ağacı olmadan test edilebiliyor.
## 2. **Sefer ortası kaydı** - `to_dict()`/`load_from_dict()` seferi
##    kaldığı yerden devam ettirecek her şeyi taşıyor (bkz. Save & Menu
##    Rules). Arazi ve hava yazılmıyor: ikisi de tohumdan yeniden hesaplanıyor.

const PACE_STEADY: float = 1.0
const HUNGRY_PACE_MULTIPLIER: float = 0.85
const ENCOUNTER_TRIGGER_EPSILON: float = 0.01

var clock: JourneyClock = null
var engine: EventEngine = null
## Seferin toplam gün uzunluğu - ilerleme çubuğu ve varış bunu okur.
var journey_length_days: int = 1
## Kat edilen yol, "gün" cinsinden. Konumun tek doğruluk kaynağı:
## `journey_days_remaining` bundan türetilir (bkz. sync_days_remaining).
var days_covered: float = 0.0
## Takvim günü (seferin kaçıncı günü) - mesafeden bağımsız.
var current_day: int = 0
var hungry: bool = false
var pace: float = PACE_STEADY
var pace_key: String = "UI_ROAD_PACE_STEADY"
## Görmezden gelinen dumanın yolun tehlikesine eklediği pay.
var signal_danger_bonus: float = 0.0
var signal_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var camping: bool = false
var camp_ends_at_hours: float = 0.0
## Yolda görünüp kartı henüz açılmamış olay ve yolda durduğu gün konumu.
var pending_event: GameEvent = null
var pending_event_day_position: float = 0.0

## Tempo, hava, kervanın kondisyonu, eğim ve açlık bir yürüyüş adımında
## **aynı yerde** çarpılıyor - iki yerde çarpılırsa biri güncellenmeyi
## unutur (bkz. road_journey.gd `_walk_at`, RouteWeather.forecast_extra_days).
static func effective_rate(
	rate: float, weather_multiplier: float, caravan_speed: float,
	terrain_factor: float, is_hungry: bool
) -> float:
	var effective := rate * weather_multiplier * caravan_speed * terrain_factor
	if is_hungry:
		effective *= HUNGRY_PACE_MULTIPLIER
	return effective

## Mesafeyi ilerletir; yolun başı ile sonu arasında kenetlenir.
func walk(effective: float, hours: float) -> void:
	days_covered = clampf(
		days_covered + effective * hours / JourneyClock.HOURS_PER_DAY,
		0.0, float(journey_length_days)
	)

## `journey_days_remaining` bir sayaç değil, kat edilen yoldan türetilen bir
## gösterge - HUD, sapma maliyeti ve varış hep aynı mesafeyi okusun diye.
func sync_days_remaining(session: GameSession) -> void:
	session.journey_days_remaining = maxi(0, ceili(float(journey_length_days) - days_covered))

## Varış "gün bitti" değil "mesafe kapandı" demek.
func has_arrived() -> bool:
	return days_covered >= float(journey_length_days)

## Kervanın burnu bekleyen karşılaşmaya değdi mi. `front_offset_days`,
## kervanın önünün çapaya olan uzaklığı (gün cinsinden).
func has_reached_pending(front_offset_days: float) -> bool:
	if pending_event == null:
		return false
	return days_covered + ENCOUNTER_TRIGGER_EPSILON >= pending_event_day_position - front_offset_days

## Yeni bir bacak (geri dönüş, sapma): mesafe sıfırdan, eski yolda bekleyen
## karşılaşma o yolla birlikte geride kalır.
func start_leg(length_days: int) -> void:
	journey_length_days = maxi(1, length_days)
	days_covered = 0.0
	pending_event = null

func to_dict() -> Dictionary:
	return {
		"journey_length_days": journey_length_days,
		"days_covered": days_covered,
		"current_day": current_day,
		"hungry": hungry,
		"pace": pace,
		"pace_key": pace_key,
		"signal_danger_bonus": signal_danger_bonus,
		"signal_rng_state": str(signal_rng.state),
		"signal_rng_seed": str(signal_rng.seed),
		"camping": camping,
		"camp_ends_at_hours": camp_ends_at_hours,
		"pending_event_id": "" if pending_event == null else pending_event.event_id,
		"pending_event_day_position": pending_event_day_position,
		"clock": {} if clock == null else clock.to_dict(),
		"engine": {} if engine == null else engine.to_dict(),
	}

## Motoru kuracak olay listesini çağıran verir (katalog); motorun kendi
## durumu (bir-kez, bekleme, zar konumu) kayıttan okunur.
func load_from_dict(data: Dictionary, events: Array[GameEvent]) -> void:
	journey_length_days = maxi(1, int(data.get("journey_length_days", 1)))
	days_covered = clampf(float(data.get("days_covered", 0.0)), 0.0, float(journey_length_days))
	current_day = maxi(0, int(data.get("current_day", 0)))
	hungry = bool(data.get("hungry", false))
	pace = float(data.get("pace", PACE_STEADY))
	pace_key = String(data.get("pace_key", "UI_ROAD_PACE_STEADY"))
	signal_danger_bonus = maxf(0.0, float(data.get("signal_danger_bonus", 0.0)))
	if data.has("signal_rng_seed"):
		signal_rng.seed = String(data["signal_rng_seed"]).to_int()
	if data.has("signal_rng_state"):
		signal_rng.state = String(data["signal_rng_state"]).to_int()
	camping = bool(data.get("camping", false))
	camp_ends_at_hours = float(data.get("camp_ends_at_hours", 0.0))
	var pending_id := String(data.get("pending_event_id", ""))
	pending_event = EventCatalog.get_event(pending_id) if not pending_id.is_empty() else null
	pending_event_day_position = float(data.get("pending_event_day_position", 0.0))
	clock = JourneyClock.new()
	clock.load_from_dict(data.get("clock", {}) as Dictionary)
	engine = EventEngine.new(events, 1)
	engine.load_from_dict(data.get("engine", {}) as Dictionary)
