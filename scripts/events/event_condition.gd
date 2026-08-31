class_name EventCondition
extends Resource

## EU4'ün "trigger" bloğunun karşılığı. Düz bir bağlam sözlüğüne bakar,
## böylece değerlendirme tahsisatsız ve ucuzdur.

enum Op {
	GREATER_EQUAL,
	LESS_EQUAL,
	EQUAL,
	NOT_EQUAL,
	HAS_FLAG,
	NOT_HAS_FLAG,
}

@export var key: String = ""
@export var op: Op = Op.GREATER_EQUAL
@export var value: float = 0.0

func is_met(context: Dictionary) -> bool:
	match op:
		Op.HAS_FLAG:
			return _has_flag(context)
		Op.NOT_HAS_FLAG:
			return not _has_flag(context)

	if not context.has(key):
		return false

	var actual: float = float(context[key])
	match op:
		Op.GREATER_EQUAL:
			return actual >= value
		Op.LESS_EQUAL:
			return actual <= value
		Op.EQUAL:
			return is_equal_approx(actual, value)
		Op.NOT_EQUAL:
			return not is_equal_approx(actual, value)

	return false

func _has_flag(context: Dictionary) -> bool:
	var flags: Dictionary = context.get("flags", {})
	return flags.has(key)

static func are_all_met(conditions: Array[EventCondition], context: Dictionary) -> bool:
	for condition in conditions:
		if not condition.is_met(context):
			return false
	return true

static func make(key: String, op: Op, value: float = 0.0) -> EventCondition:
	var condition := EventCondition.new()
	condition.key = key
	condition.op = op
	condition.value = value
	return condition
