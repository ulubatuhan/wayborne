class_name EventOutcome
extends Resource

## Bir seçeneğin olası sonuçlarından biri. Tek sonuçlu bir seçenek
## EU4'teki gibi deterministiktir; birden fazla sonuç verilirse
## koşulu sağlayanlar arasından ağırlıklı rastgele seçilir.

@export var text_key: String = ""
@export var weight: float = 1.0
@export var conditions: Array[EventCondition] = []
@export var effects: Array[EventEffect] = []

func is_available(context: Dictionary) -> bool:
	return EventCondition.are_all_met(conditions, context)

static func make(text_key: String, effects: Array[EventEffect], weight: float = 1.0) -> EventOutcome:
	var outcome := EventOutcome.new()
	outcome.text_key = text_key
	outcome.effects = effects
	outcome.weight = weight
	return outcome
