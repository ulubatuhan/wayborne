extends RefCounted

## Testlerin sonucunu toplayan küçük raportör. Bilerek class_name yok:
## tests/ altındaki hiçbir betik global sınıf önbelleğini kirletmesin.

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []

var _suite: String = ""
var _suite_passed: int = 0
var _suite_failed: int = 0

func begin_suite(suite_name: String) -> void:
	_suite = suite_name
	_suite_passed = 0
	_suite_failed = 0

func end_suite() -> String:
	if _suite_failed > 0:
		return "  ✗ %-22s %d geçti, %d kaldı" % [_suite, _suite_passed, _suite_failed]
	return "  ✓ %-22s %d geçti" % [_suite, _suite_passed]

func ok(condition: bool, message: String) -> void:
	if condition:
		_record_pass()
	else:
		_record_fail(message)

func not_ok(condition: bool, message: String) -> void:
	ok(not condition, message)

func eq(actual, expected, message: String) -> void:
	if actual == expected:
		_record_pass()
	else:
		_record_fail("%s — beklenen <%s>, gelen <%s>" % [message, str(expected), str(actual)])

func ne(actual, unexpected, message: String) -> void:
	if actual != unexpected:
		_record_pass()
	else:
		_record_fail("%s — <%s> olmamalıydı" % [message, str(unexpected)])

func ge(actual: float, floor_value: float, message: String) -> void:
	if actual >= floor_value:
		_record_pass()
	else:
		_record_fail("%s — <%s> en az <%s> olmalıydı" % [message, str(actual), str(floor_value)])

func le(actual: float, ceiling: float, message: String) -> void:
	if actual <= ceiling:
		_record_pass()
	else:
		_record_fail("%s — <%s> en fazla <%s> olmalıydı" % [message, str(actual), str(ceiling)])

func almost(actual: float, expected: float, message: String, epsilon: float = 0.001) -> void:
	if absf(actual - expected) <= epsilon:
		_record_pass()
	else:
		_record_fail("%s — beklenen <%s>, gelen <%s>" % [message, str(expected), str(actual)])

func _record_pass() -> void:
	passed += 1
	_suite_passed += 1

func _record_fail(message: String) -> void:
	failed += 1
	_suite_failed += 1
	failures.append("%s › %s" % [_suite, message])
