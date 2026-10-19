extends RefCounted

## Sayı değil söz (Y-H03): değer dört kademeli kelimeye, nedenleri kısa
## cümlelere çevrilir; ipucu sözle başlar, sayı ikinci satırda; etki satırı
## yönü ve büyüklüğü kelimeyle söyler.

func suite_name() -> String:
	return "Wording"

func run(t) -> void:
	_test_bands(t)
	_test_every_key_is_written(t)
	_test_reasons(t)
	_test_lines(t)

func _test_bands(t) -> void:
	t.eq(Wording.band(10.0, 100.0), 0, "%10 en alt kademe")
	t.eq(Wording.band(60.0, 100.0), 2, "%60 üçüncü kademe")
	t.eq(Wording.band(100.0, 100.0), 3, "dolu en üst kademe")
	t.eq(Wording.level_key(Wording.MORALE, 30.0, 100.0), "WORD_MORALE_1", "moral %30 düşük")

func _test_every_key_is_written(t) -> void:
	var keys: Array[String] = ["WORD_REASON_HUNGRY", "WORD_REASON_DEATH", "WORD_REASON_DEBT", "WORD_REASON_NEAR_BREAK"]
	for kind in Wording.BAND_KEYS:
		for key in Wording.BAND_KEYS[kind]:
			keys.append(String(key))
	for kind in Wording.CHANGE_KEYS:
		for key in Wording.CHANGE_KEYS[kind]:
			keys.append(String(key))
	for key in keys:
		t.ok(String(TranslationServer.translate(key)) != key, "yazılı: %s" % key)

func _test_reasons(t) -> void:
	var session := GameSession.new(200, 20, 1)
	t.ok(Wording.reasons(session, Wording.MORALE).is_empty(), "sebep yokken liste boş")
	session.crew_hungry_nights = 2
	var why := Wording.reasons(session, Wording.MORALE)
	t.ok(not why.is_empty() and why[0].contains("2"), "açlık sebebi gün sayısıyla")
	var tip := Wording.gauge_tooltip("Moral", Wording.MORALE, 30.0, 100.0, why)
	var lines := tip.split("\n")
	t.ok(lines[0].begins_with(TranslationServer.translate("WORD_MORALE_1")), "ipucu sözle başlar")
	t.ok(lines.size() == 2 and lines[1].contains("30/100"), "sayı ikinci satırda")

func _test_lines(t) -> void:
	var big := Wording.change_line(Wording.MORALE, -10)
	t.ok(big.begins_with(TranslationServer.translate("WORD_MORALE_DOWN_BIG")) and big.ends_with("(-10)"), "büyük düşüş sözle, sayı parantezde")
	var small := Wording.change_line(Wording.STRESS, -3)
	t.ok(small.begins_with(TranslationServer.translate("WORD_STRESS_DOWN_SMALL")), "küçük stres düşüşü")
	var effects: Array[EventEffect] = [EventEffect.make(EventEffect.Type.MORALE, -10)]
	var result := EventEffectApplier.apply(effects, GameSession.new(200, 20, 1))
	t.ok(result.lines.size() > 0 and result.lines[0] == big, "olay etki satırı aynı dili kullanır")
