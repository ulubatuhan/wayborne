class_name EventCatalog
extends RefCounted

## Placeholder yol olayları. Tasarım kuralı: her seçenek bir kaynağı
## başka bir kaynakla takas eder, bedava çıkış yoktur. Kilitli seçenekler
## gizlenmez; oyuncu neye hazırlıksız yakalandığını görür.
##
## Şema oturduğunda bu tablo .tres kaynak dosyalarına taşınacak.
##
## Olaylar bir kez kurulup statik önbelleğe alınıyor: EventEngine bunları
## yalnızca okuyor (event_id/koşul/ağırlık), hiçbir yerde mutate etmiyor -
## bir-kez/bekleme takibi EventEngine örneğinin kendi sözlüklerinde,
## event_id string'iyle tutuluyor. Bu yüzden aynı GameEvent nesnelerini
## her sefer ekranı girişinde paylaşmak güvenli ve gereksiz yeniden
## inşayı önlüyor.

static var _road_events: Array[GameEvent] = []

static func get_road_events() -> Array[GameEvent]:
	if not _road_events.is_empty():
		return _road_events

	_road_events.append(_bandit_ambush())
	_road_events.append(_customs_checkpoint())
	_road_events.append(_broken_axle())
	_road_events.append(_storm())
	_road_events.append(_spoiled_provisions())
	_road_events.append(_stowaway())
	_road_events.append(_stowaway_repay())
	_road_events.append(_sick_merchant())
	_road_events.append(_mutiny())
	_road_events.append(_abandoned_wagon())
	_road_events.append(_road_wanderer())
	return _road_events

## Yolda partiye katılabilecek biri. Şehirdeki tayfa ekranlarının yol
## karşılığı: kadro yalnızca şehirde değil, yolda da büyüyebilsin diye.
static func _road_wanderer() -> GameEvent:
	var event := _event("evt_road_wanderer", "EVT_WANDERER", 0.9)
	event.cooldown_days = 6
	event.choices = _choices([
		_gated_choice(
			"EVT_WANDERER_OPT_HIRE", "EVT_WANDERER_OPT_HIRE_LOCKED",
			_conditions([
				EventCondition.make("party_size", EventCondition.Op.LESS_EQUAL, GameSession.MAX_PARTY_SIZE - 1),
			]),
			_effects([EventEffect.make(EventEffect.Type.TRIGGER_RECRUIT, 0)])
		),
		_choice("EVT_WANDERER_OPT_FEED", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -3),
			EventEffect.make(EventEffect.Type.MORALE, 5),
		])),
		_choice("EVT_WANDERER_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -2),
		])),
	])
	return event

static func _bandit_ambush() -> GameEvent:
	var event := _event("evt_bandit_ambush", "EVT_AMBUSH", 1.4)
	event.cooldown_days = 2
	# Tehlikeli yollarda ve morali düşük kervanlarda daha sık.
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("danger", EventCondition.Op.GREATER_EQUAL, 0.5),
		]), 2.0),
	])
	event.choices = _choices([
		_gated_choice(
			"EVT_AMBUSH_OPT_PAY", "EVT_AMBUSH_OPT_PAY_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 120)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -120),
				EventEffect.make(EventEffect.Type.MORALE, -5),
			])
		),
		# Zar atılmıyor: gerçek savaş paneli açılıyor, sonucun etkilerini
		# road_journey.gd uyguluyor (bkz. _on_combat_finished).
		_choice("EVT_AMBUSH_OPT_FIGHT", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0),
		])),
		_choice("EVT_AMBUSH_OPT_HAGGLE", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_HAGGLING, 200),
		])),
	])
	return event

static func _customs_checkpoint() -> GameEvent:
	var event := _event("evt_customs_checkpoint", "EVT_CUSTOMS", 1.2)
	event.choices = _choices([
		_gated_choice(
			"EVT_CUSTOMS_OPT_PAPERS", "EVT_CUSTOMS_OPT_PAPERS_LOCKED",
			_conditions([EventCondition.make("documents", EventCondition.Op.GREATER_EQUAL, 1)]),
			_effects([
				EventEffect.make(EventEffect.Type.REPUTATION, 3),
				EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
			])
		),
		_gated_choice(
			"EVT_CUSTOMS_OPT_BRIBE", "EVT_CUSTOMS_OPT_BRIBE_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 80)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -80),
				EventEffect.make(EventEffect.Type.REPUTATION, -2),
			])
		),
		_choice_with_outcomes("EVT_CUSTOMS_OPT_RUN", _outcomes([
			EventOutcome.make("EVT_CUSTOMS_RUN_ESCAPE", _effects([
				EventEffect.make(EventEffect.Type.DANGER, 15),
				EventEffect.make(EventEffect.Type.MORALE, 5),
			]), 1.0),
			EventOutcome.make("EVT_CUSTOMS_RUN_CAUGHT", _effects([
				EventEffect.make(EventEffect.Type.DOCUMENT_LOSE, 2),
				EventEffect.make(EventEffect.Type.GOLD, -150),
				EventEffect.make(EventEffect.Type.REPUTATION, -8),
			]), 1.4),
		])),
	])
	return event

static func _broken_axle() -> GameEvent:
	var event := _event("evt_broken_axle", "EVT_AXLE", 1.0)
	event.conditions = _conditions([
		EventCondition.make("wagons", EventCondition.Op.GREATER_EQUAL, 2),
	])
	event.choices = _choices([
		_gated_choice(
			"EVT_AXLE_OPT_REPAIR", "EVT_AXLE_OPT_REPAIR_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 60)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -60),
				EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
			])
		),
		_choice("EVT_AXLE_OPT_PUSH_ON", _effects([
			EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 1),
			EventEffect.make(EventEffect.Type.MORALE, -8),
		])),
		_choice("EVT_AXLE_OPT_DUMP", _effects([
			EventEffect.make(EventEffect.Type.ITEM_REMOVE, 3, "test_cloth"),
			EventEffect.make(EventEffect.Type.MORALE, -4),
		])),
	])
	return event

static func _storm() -> GameEvent:
	var event := _event("evt_storm", "EVT_STORM", 1.1)
	event.cooldown_days = 3
	event.choices = _choices([
		_choice("EVT_STORM_OPT_SHELTER", _effects([
			EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
			EventEffect.make(EventEffect.Type.PROVISIONS, -3),
		])),
		_choice_with_outcomes("EVT_STORM_OPT_PRESS_ON", _outcomes([
			EventOutcome.make("EVT_STORM_PRESS_OK", _effects([
				EventEffect.make(EventEffect.Type.MORALE, -5),
			]), 1.0),
			EventOutcome.make("EVT_STORM_PRESS_BAD", _effects([
				EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 1),
				EventEffect.make(EventEffect.Type.PROVISIONS, -4),
				EventEffect.make(EventEffect.Type.MORALE, -12),
			]), 1.0),
		])),
	])
	return event

static func _spoiled_provisions() -> GameEvent:
	var event := _event("evt_spoiled_provisions", "EVT_SPOILED", 0.9)
	event.conditions = _conditions([
		EventCondition.make("provisions", EventCondition.Op.GREATER_EQUAL, 5),
	])
	event.immediate_effects = _effects([
		EventEffect.make(EventEffect.Type.PROVISIONS, -4),
	])
	event.choices = _choices([
		_choice("EVT_SPOILED_OPT_SHARE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -5),
		])),
		_choice("EVT_SPOILED_OPT_RATION", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -15),
			EventEffect.make(EventEffect.Type.REPUTATION, -3),
			EventEffect.make(EventEffect.Type.PROVISIONS, 2),
		])),
	])
	return event

static func _stowaway() -> GameEvent:
	var event := _event("evt_stowaway", "EVT_STOWAWAY", 0.7)
	event.fire_only_once = true
	event.choices = _choices([
		_choice("EVT_STOWAWAY_OPT_SHELTER", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -2),
			EventEffect.make(EventEffect.Type.MORALE, 4),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "stowaway_helped"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_stowaway_repay"),
		])),
		_choice("EVT_STOWAWAY_OPT_TURN_IN", _effects([
			EventEffect.make(EventEffect.Type.GOLD, 30),
			EventEffect.make(EventEffect.Type.REPUTATION, -3),
			EventEffect.make(EventEffect.Type.MORALE, -6),
		])),
	])
	return event

static func _stowaway_repay() -> GameEvent:
	var event := _event("evt_stowaway_repay", "EVT_STOWAWAY_REPAY", 3.0)
	event.triggered_only = true
	event.fire_only_once = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("stowaway_helped", EventCondition.Op.HAS_FLAG),
	])
	event.choices = _choices([
		_choice("EVT_STOWAWAY_REPAY_OPT_ACCEPT", _effects([
			EventEffect.make(EventEffect.Type.GOLD, 200),
			EventEffect.make(EventEffect.Type.MORALE, 8),
		])),
		_choice("EVT_STOWAWAY_REPAY_OPT_REFUSE", _effects([
			EventEffect.make(EventEffect.Type.REPUTATION, 8),
			EventEffect.make(EventEffect.Type.MORALE, 12),
		])),
	])
	return event

static func _sick_merchant() -> GameEvent:
	var event := _event("evt_sick_merchant", "EVT_SICK", 0.9)
	event.conditions = _conditions([
		EventCondition.make("merchants", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.choices = _choices([
		_gated_choice(
			"EVT_SICK_OPT_TREAT", "EVT_SICK_OPT_TREAT_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 90)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -90),
				EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
				EventEffect.make(EventEffect.Type.MORALE, 10),
				EventEffect.make(EventEffect.Type.REPUTATION, 5),
			])
		),
		_choice("EVT_SICK_OPT_LEAVE", _effects([
			EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, 1),
			EventEffect.make(EventEffect.Type.MORALE, -18),
			EventEffect.make(EventEffect.Type.REPUTATION, -6),
		])),
	])
	return event

static func _mutiny() -> GameEvent:
	var event := _event("evt_mutiny", "EVT_MUTINY", 2.0)
	event.conditions = _conditions([
		EventCondition.make("morale", EventCondition.Op.LESS_EQUAL, 25),
		EventCondition.make("merchants", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.cooldown_days = 4
	event.choices = _choices([
		_gated_choice(
			"EVT_MUTINY_OPT_PAY", "EVT_MUTINY_OPT_PAY_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 100)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -100),
				EventEffect.make(EventEffect.Type.MORALE, 30),
			])
		),
		_choice_with_outcomes("EVT_MUTINY_OPT_HARSH", _outcomes([
			EventOutcome.make("EVT_MUTINY_HARSH_OBEY", _effects([
				EventEffect.make(EventEffect.Type.MORALE, 10),
			]), 1.0),
			EventOutcome.make("EVT_MUTINY_HARSH_DESERT", _effects([
				EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, 2),
				EventEffect.make(EventEffect.Type.MORALE, -10),
				EventEffect.make(EventEffect.Type.REPUTATION, -5),
			]), 1.2),
		])),
	])
	return event

static func _abandoned_wagon() -> GameEvent:
	var event := _event("evt_abandoned_wagon", "EVT_ABANDONED", 0.8)
	event.choices = _choices([
		_choice("EVT_ABANDONED_OPT_LOOT", _effects([
			EventEffect.make(EventEffect.Type.ITEM_ADD, 3, "test_furs"),
			EventEffect.make(EventEffect.Type.DANGER, 10),
			EventEffect.make(EventEffect.Type.MORALE, -3),
		])),
		_choice("EVT_ABANDONED_OPT_LEAVE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 3),
		])),
	])
	return event

static func _event(event_id: String, key_prefix: String, base_weight: float) -> GameEvent:
	var event := GameEvent.new()
	event.event_id = event_id
	event.title_key = "%s_TITLE" % key_prefix
	event.text_key = "%s_TEXT" % key_prefix
	event.base_weight = base_weight
	return event

static func _choice(text_key: String, effects: Array[EventEffect]) -> EventChoice:
	return EventChoice.make(text_key, effects)

static func _gated_choice(
	text_key: String,
	locked_key: String,
	requirements: Array[EventCondition],
	effects: Array[EventEffect]
) -> EventChoice:
	var choice := EventChoice.make(text_key, effects)
	choice.requirements = requirements
	choice.unavailable_text_key = locked_key
	return choice

static func _choice_with_outcomes(text_key: String, outcomes: Array[EventOutcome]) -> EventChoice:
	var choice := EventChoice.new()
	choice.text_key = text_key
	choice.outcomes = outcomes
	return choice

static func _conditions(items: Array) -> Array[EventCondition]:
	var result: Array[EventCondition] = []
	for item in items:
		result.append(item)
	return result

static func _effects(items: Array) -> Array[EventEffect]:
	var result: Array[EventEffect] = []
	for item in items:
		result.append(item)
	return result

static func _outcomes(items: Array) -> Array[EventOutcome]:
	var result: Array[EventOutcome] = []
	for item in items:
		result.append(item)
	return result

static func _choices(items: Array) -> Array[EventChoice]:
	var result: Array[EventChoice] = []
	for item in items:
		result.append(item)
	return result

static func _modifiers(items: Array) -> Array[EventWeightModifier]:
	var result: Array[EventWeightModifier] = []
	for item in items:
		result.append(item)
	return result
