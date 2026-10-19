extends RefCounted

## Havaya karşı küçük kararlar (Y-B05) ve gece ışığı (Y-C20): her havanın en az
## bir kararı var, açık hava artık nötr değil, riskli kararın zarı günden
## tohumlu ve ölçülü; fener yağ, meşale iki meşale harcar, yokluğu sebebiyle
## kilitler.

func suite_name() -> String:
	return "WeatherCalls"

func run(t) -> void:
	_test_every_weather_has_a_call(t)
	_test_risky_calls(t)
	_test_lights(t)

func _test_every_weather_has_a_call(t) -> void:
	for weather in [RouteWeather.CLEAR, RouteWeather.OVERCAST, RouteWeather.RAIN, RouteWeather.FOG, RouteWeather.STORM]:
		var calls := WeatherCalls.options_for(weather)
		t.ok(not calls.is_empty(), "%s havasında bir karar var" % weather)
		for call in calls:
			t.ok(String(TranslationServer.translate(String(WeatherCalls.LABEL_KEYS[call]))) != String(WeatherCalls.LABEL_KEYS[call]), "%s yazılı" % call)
	var clear := WeatherCalls.options_for(RouteWeather.CLEAR)
	t.ok(WeatherCalls.rate_multiplier(clear[0]) > 1.0, "açık hava artık nötr değil: erken yola düşmek hızlandırır")
	t.ok(WeatherCalls.rate_multiplier(WeatherCalls.SLOW_IN_FOG) < 1.0, "siste yavaşlamak yavaşlatır")

func _test_risky_calls(t) -> void:
	var hurt := 0
	for day in 400:
		if WeatherCalls.damages_wagon(WeatherCalls.MUD_SHORTCUT, day, "a|b"):
			hurt += 1
	t.ok(hurt > 60 and hurt < 140, "çamurlu kestirme dörtte bir civarı hırpalar (%d/400)" % hurt)
	t.eq(WeatherCalls.damages_wagon(WeatherCalls.MUD_SHORTCUT, 7, "a|b"), WeatherCalls.damages_wagon(WeatherCalls.MUD_SHORTCUT, 7, "a|b"), "aynı gün aynı zar")
	t.not_ok(WeatherCalls.damages_wagon(WeatherCalls.SHELTER, 7, "a|b"), "sığınmak vagonu hırpalamaz")

func _test_lights(t) -> void:
	var session := GameSession.new(200, 20, 1)
	t.eq(session.get_light_block_reason(GameSession.LIGHT_LANTERN), "UI_LIGHT_NO_LANTERN", "fener yoksa yanmaz")
	t.eq(session.get_light_block_reason(GameSession.LIGHT_TORCH), "UI_LIGHT_NO_TORCH", "meşale yoksa yanmaz")
	session.add_to_cargo(ItemCatalog.get_item(ItemCatalog.LANTERN), 1)
	t.eq(session.get_light_block_reason(GameSession.LIGHT_LANTERN), "UI_LIGHT_NO_OIL", "yağsız fener yanmaz")
	session.add_to_cargo(ItemCatalog.get_item(ItemCatalog.LANTERN_OIL), 2)
	t.ok(session.light_for_night(GameSession.LIGHT_LANTERN), "fener yandı")
	t.eq(session.get_total_quantity(ItemCatalog.LANTERN_OIL), 1, "bir gece bir yağ")
	t.eq(session.get_total_quantity(ItemCatalog.LANTERN), 1, "fener harcanmaz")
	session.add_to_cargo(ItemCatalog.get_item(ItemCatalog.TORCH), 3)
	t.ok(session.light_for_night(GameSession.LIGHT_TORCH), "meşale yandı")
	t.eq(session.get_total_quantity(ItemCatalog.TORCH), 1, "bir gece iki meşale")
	t.eq(session.get_light_block_reason(GameSession.LIGHT_TORCH), "UI_LIGHT_NO_TORCH", "tek meşale bir geceye yetmez")
	for id in ItemCatalog.LIGHT_SUPPLIES:
		t.ok(WorldMapData.get_locations()[0].sells(id), "%s pazarda bulunur" % id)
