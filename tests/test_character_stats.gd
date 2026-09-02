extends RefCounted

## Türetilmiş değerlerin formülleri yalnızca CharacterStats'ta duruyor;
## karakter ekranı da savaş motoru da oradan okuyor. Bu paket o
## formülleri sabitler - biri değişirse iki ekranı birden bozar.

func suite_name() -> String:
	return "CharacterStats"

func run(t) -> void:
	_test_derived_values(t)
	_test_clamping(t)
	_test_copy_is_independent(t)
	_test_dict_round_trip(t)

func _test_derived_values(t) -> void:
	var stats := CharacterStats.new()

	t.eq(stats.get_max_hp(), 40, "taban dayanıklılık 5 -> 40 can")
	t.eq(stats.get_initiative(), 10, "taban çeviklik 5 -> 10 inisiyatif")
	t.eq(stats.get_accuracy(), 80, "taban sezgi 5 -> %80 isabet")
	t.eq(stats.get_dodge(), 10, "taban çeviklik 5 -> 10 kaçınma")
	t.eq(stats.get_crit_chance(), 7, "taban sezgi 5 -> %7 kritik")
	t.eq(stats.get_damage_bonus(), 5, "hasar bonusu güçten gelir")
	t.eq(stats.get_support_power(), 5, "yardım gücü zekadan gelir")

	stats.endurance = 10
	t.eq(stats.get_max_hp(), 60, "dayanıklılık 10 -> 60 can")

func _test_clamping(t) -> void:
	var stats := CharacterStats.new()

	stats.set_value(CharacterStats.Kind.STRENGTH, 99)
	t.eq(stats.strength, CharacterStats.MAX_VALUE, "tavanın üstü kırpılır")

	stats.set_value(CharacterStats.Kind.STRENGTH, -5)
	t.eq(stats.strength, CharacterStats.MIN_VALUE, "tabanın altı kırpılır")

	stats.set_value(CharacterStats.Kind.AGILITY, 9)
	stats.add_value(CharacterStats.Kind.AGILITY, 5)
	t.eq(stats.agility, CharacterStats.MAX_VALUE, "add_value da kırpar")

	t.eq(CharacterStats.KIND_ORDER.size(), 6, "altı temel stat var")

func _test_copy_is_independent(t) -> void:
	var original := CharacterStats.new()
	original.strength = 8

	var copied := original.copy()
	copied.strength = 3

	t.eq(original.strength, 8, "kopya değişince aslı bozulmaz")
	t.eq(copied.strength, 3, "kopya kendi değerini tutar")

func _test_dict_round_trip(t) -> void:
	var original := CharacterStats.new()
	original.strength = 7
	original.agility = 3
	original.endurance = 9
	original.intellect = 2
	original.perception = 6
	original.charisma = 4

	var restored := CharacterStats.from_dict(original.to_dict())

	for kind in CharacterStats.KIND_ORDER:
		t.eq(
			restored.get_value(kind),
			original.get_value(kind),
			"%s gidiş-dönüşte korunur" % CharacterStats.kind_name(kind)
		)

	var defaulted := CharacterStats.from_dict({})
	t.eq(defaulted.strength, CharacterStats.BASE_VALUE, "eksik kayıt tabana düşer")
