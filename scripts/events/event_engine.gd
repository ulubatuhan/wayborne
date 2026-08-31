class_name EventEngine
extends RefCounted

## Yol olaylarının havuzunu yönetir: uygunluk filtresi, ağırlıklı çekim,
## bir-kez/bekleme takibi ve seçim çözümü. Sahne ağacına bağlı değildir,
## seed verilerek birebir tekrarlanabilir.

const DEFAULT_DAILY_EVENT_CHANCE: float = 0.35
const MAX_DAILY_EVENT_CHANCE: float = 0.95

var daily_event_chance: float = DEFAULT_DAILY_EVENT_CHANCE

var _events: Array[GameEvent] = []
var _rng := RandomNumberGenerator.new()
var _fired_once: Dictionary = {}
var _available_after_day: Dictionary = {}
var _unlocked: Dictionary = {}

func _init(events: Array[GameEvent], seed_value: int = 0) -> void:
	_events = events
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

## Tehlike arttıkça günlük olay ihtimali yükselir.
func get_daily_chance(context: Dictionary) -> float:
	var danger: float = float(context.get("danger", 0.0))
	return clampf(daily_event_chance * (0.5 + danger), 0.0, MAX_DAILY_EVENT_CHANCE)

## Bir yolculuk günü ilerletir. Olay çıkmazsa null döner.
func roll_for_day(current_day: int, context: Dictionary) -> GameEvent:
	if _rng.randf() > get_daily_chance(context):
		return null
	return draw_event(current_day, context)

## Havuzdan koşulu sağlayan bir olayı ağırlıklı olarak çeker.
func draw_event(current_day: int, context: Dictionary) -> GameEvent:
	var eligible := get_eligible_events(current_day, context)
	if eligible.is_empty():
		return null

	var total_weight := 0.0
	for event in eligible:
		total_weight += event.get_weight(context)

	if total_weight <= 0.0:
		return null

	var roll := _rng.randf() * total_weight
	var cursor := 0.0
	for event in eligible:
		cursor += event.get_weight(context)
		if roll <= cursor:
			return event

	return eligible[eligible.size() - 1]

func get_eligible_events(current_day: int, context: Dictionary) -> Array[GameEvent]:
	var eligible: Array[GameEvent] = []
	for event in _events:
		if _is_eligible(event, current_day, context):
			eligible.append(event)
	return eligible

func _is_eligible(event: GameEvent, current_day: int, context: Dictionary) -> bool:
	if event.triggered_only and not _unlocked.has(event.event_id):
		return false
	if event.fire_only_once and _fired_once.has(event.event_id):
		return false
	if _available_after_day.has(event.event_id) and current_day < int(_available_after_day[event.event_id]):
		return false
	return event.is_eligible(context)

## Olay gösterildikten sonra çağrılır: bir-kez ve bekleme kayıtlarını işler.
func mark_fired(event: GameEvent, current_day: int) -> void:
	if event.fire_only_once:
		_fired_once[event.event_id] = true
	if event.cooldown_days > 0:
		_available_after_day[event.event_id] = current_day + event.cooldown_days
	_unlocked.erase(event.event_id)

func unlock_event(event_id: String) -> void:
	_unlocked[event_id] = true

## Seçeneğin sonuçlarından koşulu sağlayan birini ağırlıklı seçer.
## Sonuç listesi boşsa null döner: seçeneğin yalnızca garantili etkileri vardır.
func resolve_outcome(choice: EventChoice, context: Dictionary) -> EventOutcome:
	var available: Array[EventOutcome] = []
	var total_weight := 0.0
	for outcome in choice.outcomes:
		if outcome.is_available(context):
			available.append(outcome)
			total_weight += outcome.weight

	if available.is_empty() or total_weight <= 0.0:
		return null

	var roll := _rng.randf() * total_weight
	var cursor := 0.0
	for outcome in available:
		cursor += outcome.weight
		if roll <= cursor:
			return outcome

	return available[available.size() - 1]
