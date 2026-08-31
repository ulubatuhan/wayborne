class_name EventWeightModifier
extends Resource

## EU4'ün MTTH modifier bloğu: koşul sağlanırsa olayın çekilme
## ağırlığı çarpanla ölçeklenir. 1'in üstü olayı yaklaştırır,
## altı uzaklaştırır.

@export var conditions: Array[EventCondition] = []
@export var multiplier: float = 1.0

func applies(context: Dictionary) -> bool:
	return EventCondition.are_all_met(conditions, context)

static func make(conditions: Array[EventCondition], multiplier: float) -> EventWeightModifier:
	var modifier := EventWeightModifier.new()
	modifier.conditions = conditions
	modifier.multiplier = multiplier
	return modifier
