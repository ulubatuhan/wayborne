extends RefCounted

## Görevler (Duty): DutyCatalog.get_duty_power() sınıf eşleşmesini ve
## etkin statı nasıl birleştiriyor, GameSession bunu somut indirim/azaltma
## sayılarına nasıl çeviriyor.

func suite_name() -> String:
	return "Duties"

func run(t) -> void:
	_test_duty_power_scales_with_class_match(t)
	_test_session_duty_assignment(t)
	_test_discount_and_flat_reduction_formulas(t)

## Kültür statları bulanıklaştırmasın diye taban CharacterStats ile,
## doğrudan alan atamasıyla kurulur - CharacterData.create() kültür
## bonusu uyguluyor, burada tam kontrol gerekiyor.
func _make_plain(class_id: String) -> CharacterData:
	var character := CharacterData.new()
	character.character_name = "Deneme"
	character.class_id = class_id
	character.stats = CharacterStats.new()
	character.current_hp = character.get_max_hp()
	return character

func _test_duty_power_scales_with_class_match(t) -> void:
	var guard := _make_plain(ClassCatalog.GUARD)

	t.almost(DutyCatalog.get_duty_power(guard, DutyCatalog.MUHAFIZ), 1.5, "ana sınıf eşleşince 1.5 çarpan")
	t.almost(DutyCatalog.get_duty_power(guard, DutyCatalog.TELLAL), 1.0, "eşleşme yoksa çarpan nötr kalır")

	guard.level = CharacterData.MULTICLASS_UNLOCK_LEVEL
	t.ok(guard.set_second_class(ClassCatalog.CLERK), "ikinci sınıf kabul edilir")
	t.almost(DutyCatalog.get_duty_power(guard, DutyCatalog.LEVAZIMCI), 1.25, "ikinci sınıf eşleşince 1.25 çarpan")

	guard.stats.endurance = 10
	t.almost(DutyCatalog.get_duty_power(guard, DutyCatalog.MUHAFIZ), 1.875, "etkin stat gücü büyütür (1.5 * 1.25)")

func _test_session_duty_assignment(t) -> void:
	var session := GameSession.new(200, 0, 2)
	var leader := session.get_player_character()
	leader.class_id = ClassCatalog.GUARD
	leader.stats = CharacterStats.new()

	t.eq(session.get_duty_holder(DutyCatalog.MUHAFIZ), null, "başlangıçta kimse görevli değil")
	t.almost(session.get_duty_multiplier(DutyCatalog.MUHAFIZ), 1.0, "sahipsiz görev nötrdür")

	session.assign_duty(leader, DutyCatalog.MUHAFIZ)
	t.eq(session.get_duty_holder(DutyCatalog.MUHAFIZ), leader, "atama sahibini döner")
	t.almost(session.get_duty_multiplier(DutyCatalog.MUHAFIZ), 1.5, "ana sınıf eşleşince güç artar")

	var companion := _make_plain(ClassCatalog.GUARD)
	session.party.append(companion)
	session.assign_duty(companion, DutyCatalog.MUHAFIZ)

	t.eq(session.get_duty_holder(DutyCatalog.MUHAFIZ), companion, "görev el değiştirir")
	t.eq(leader.duty_id, "", "eski sahibin görevi boşa çıkar - bir görevin tek sahibi olur")

func _test_discount_and_flat_reduction_formulas(t) -> void:
	var session := GameSession.new(100, 0, 1)
	var leader := session.get_player_character()
	leader.class_id = ClassCatalog.BREAKER
	leader.stats = CharacterStats.new()
	leader.stats.strength = CharacterStats.MAX_VALUE
	session.assign_duty(leader, DutyCatalog.ARABACI)

	t.almost(session.get_duty_discount(DutyCatalog.ARABACI), 0.2, "güçlü eşleşme indirim tavanına çarpar")
	t.eq(session.get_duty_flat_reduction(DutyCatalog.ARABACI), 5, "güçlü Arabacı hasarı belirgin azaltır")
	t.le(session.get_duty_discount(DutyCatalog.TELLAL), 0.001, "sahipsiz görevde indirim yoktur")
	t.eq(session.get_duty_flat_reduction(DutyCatalog.TELLAL), 0, "sahipsiz görevde azaltma yoktur")
