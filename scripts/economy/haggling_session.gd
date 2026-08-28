class_name HagglingSession
extends RefCounted

## Kingdom Come: Deliverance tarzı sıra tabanlı pazarlık durum makinesi.
## UI'dan bağımsız: sahne ağacı gerektirmez, doğrudan örneklenip test edilebilir.

enum State {
	IN_PROGRESS,
	FINAL_CHANCE,
	SUCCESS_DEAL,
	ANGER_QUIT,
}

const DEFAULT_STARTING_PATIENCE: float = 100.0
const PATIENCE_QUIT_THRESHOLD: float = 0.0

signal patience_changed(new_patience: float)
signal counter_offer_made(npc_offer: float)
signal final_chance_offered(locked_offer: float)
signal state_changed(new_state: State)

var base_price: float
var merchant_greed: float
var reputation: float
var player_speech: int
var player_charisma: int
var patience_drain_rate: float
var has_final_offer_perk: bool

var state: State = State.IN_PROGRESS
var current_patience: float = DEFAULT_STARTING_PATIENCE
var p_start: float
var p_min: float
var final_price: float = 0.0

var _final_chance_used: bool = false
var _locked_offer: float = 0.0

func _init(
	p_base_price: float,
	p_merchant_greed: float,
	p_reputation: float,
	p_player_speech: int,
	p_player_charisma: int,
	p_patience_drain_rate: float = 1.0,
	p_has_final_offer_perk: bool = false
) -> void:
	base_price = p_base_price
	merchant_greed = clampf(p_merchant_greed, 0.0, 1.0)
	reputation = clampf(p_reputation, 0.0, 1.0)
	player_speech = p_player_speech
	player_charisma = p_player_charisma
	patience_drain_rate = p_patience_drain_rate
	has_final_offer_perk = p_has_final_offer_perk

	p_start = base_price * (1.0 + (merchant_greed * (1.0 - reputation)))
	p_min = base_price * (0.70 - (player_speech * 0.01) - (player_charisma * 0.005))
	p_min = clampf(p_min, 0.0, p_start * 0.99)
	current_patience = DEFAULT_STARTING_PATIENCE

func get_slider_range() -> Vector2:
	return Vector2(p_min, p_start * 1.2)

func get_acceptable_threshold() -> float:
	return lerpf(p_min, p_start, current_patience / 100.0)

func submit_offer(player_offer: float) -> void:
	if state != State.IN_PROGRESS:
		return

	current_patience -= _calculate_patience_drain(player_offer)
	patience_changed.emit(current_patience)

	if current_patience <= PATIENCE_QUIT_THRESHOLD:
		current_patience = 0.0
		_locked_offer = p_min

		if has_final_offer_perk and not _final_chance_used:
			_final_chance_used = true
			_set_state(State.FINAL_CHANCE)
			final_chance_offered.emit(_locked_offer)
		else:
			_set_state(State.ANGER_QUIT)
		return

	var threshold := get_acceptable_threshold()
	if player_offer >= threshold:
		final_price = player_offer
		_set_state(State.SUCCESS_DEAL)
	else:
		var npc_counter_offer := (player_offer + threshold) / 2.0
		counter_offer_made.emit(npc_counter_offer)

func respond_to_final_offer(accept: bool) -> void:
	if state != State.FINAL_CHANCE:
		return

	if accept:
		final_price = _locked_offer
		_set_state(State.SUCCESS_DEAL)
	else:
		_set_state(State.ANGER_QUIT)

func _calculate_patience_drain(player_offer: float) -> float:
	var price_range := p_start - p_min
	if price_range <= 0.0:
		return patience_drain_rate

	var delta_price := absf(p_start - player_offer)
	var normalized := delta_price / price_range
	return (normalized * normalized) * patience_drain_rate

func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(state)
