extends RefCounted

## Kültür kuralı: her kültürün tek bir mekanik perki var ve o perk
## mevcut bir sisteme bağlanıyor. Bu paket hem tablonun bütünlüğünü hem
## de "perk çarpanı 1.0'dan farklı olmalı" kuralını bekçiliyor.

func suite_name() -> String:
	return "Culture"

func run(t) -> void:
	_test_catalog_shape(t)
	_test_every_culture_has_one_perk(t)
	_test_apply_to_does_not_mutate(t)
	_test_fallback(t)

func _test_catalog_shape(t) -> void:
	var cultures := CultureCatalog.get_cultures()
	t.eq(cultures.size(), 5, "beş kültür var")

	var seen_ids: Dictionary = {}
	for culture in cultures:
		t.not_ok(seen_ids.has(culture.culture_id), "kültür kimliği tekil: %s" % culture.culture_id)
		seen_ids[culture.culture_id] = true
		t.not_ok(culture.culture_name.is_empty(), "%s adı var" % culture.culture_id)
		t.not_ok(culture.perk_text.is_empty(), "%s perk metni var" % culture.culture_id)
		t.ge(culture.name_pool.size(), 4.0, "%s isim havuzu dolu" % culture.culture_id)

func _test_every_culture_has_one_perk(t) -> void:
	for culture in CultureCatalog.get_cultures():
		var multipliers := [
			culture.daily_provision_multiplier,
			culture.provision_cost_multiplier,
			culture.buy_price_multiplier,
			culture.combat_damage_multiplier,
			culture.rumor_cost_multiplier,
		]
		var changed := 0
		for multiplier in multipliers:
			if not is_equal_approx(multiplier, 1.0):
				changed += 1
		t.eq(changed, 1, "%s tam olarak bir perk taşır" % culture.culture_id)

func _test_apply_to_does_not_mutate(t) -> void:
	var nomad := CultureCatalog.get_culture(CultureCatalog.NOMAD)
	var base := CharacterStats.new()
	var leaned := nomad.apply_to(base)

	t.eq(base.agility, CharacterStats.BASE_VALUE, "taban statlar değişmez")
	t.eq(leaned.agility, CharacterStats.BASE_VALUE + 2, "göçebe çevikliği +2")
	t.eq(leaned.endurance, CharacterStats.BASE_VALUE + 1, "göçebe dayanıklılığı +1")
	t.eq(leaned.intellect, CharacterStats.BASE_VALUE - 1, "göçebe zekası -1")
	t.eq(leaned.charisma, CharacterStats.BASE_VALUE, "dokunulmayan stat aynı kalır")

	t.not_ok(nomad.get_bonus_summary().is_empty(), "bonus özeti üretilir")

func _test_fallback(t) -> void:
	t.eq(CultureCatalog.get_culture("olmayan_kultur"), null, "bilinmeyen kimlik null döner")
	t.ne(
		CultureCatalog.get_culture_or_default("olmayan_kultur"),
		null,
		"varsayılan çözümleme asla null dönmez"
	)
