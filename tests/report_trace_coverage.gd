extends SceneTree

## İz kapsamı raporu (Y-R01). Test değil: kataloğun hangi kartı hangi
## seçeneğinde iz bırakıyor (IZ_BIRAK), hangisi hiç bırakmıyor, onu yazar.
##   godot --headless --script res://tests/report_trace_coverage.gd

func _initialize() -> void:
	var events := EventCatalog.get_road_events()
	var with_trace := 0
	var bare: Array[String] = []
	for event in events:
		var marks: Array[String] = []
		for choice in event.choices:
			var found := _traces(choice.effects)
			for outcome in choice.outcomes:
				found.append_array(_traces(outcome.effects))
			if not found.is_empty():
				marks.append("%s[%s]" % [choice.text_key.trim_prefix("EVT_"), ",".join(found)])
		if marks.is_empty():
			bare.append(event.event_id + ("*" if event.triggered_only else ""))
		else:
			with_trace += 1
			print("  İZ  %-32s %s" % [event.event_id, " ".join(marks)])
	print("── iz bırakan: %d / %d" % [with_trace, events.size()])
	print("── izsiz (* = yalnız zincirle gelir): ", ", ".join(bare))
	quit()

func _traces(effects: Array[EventEffect]) -> Array[String]:
	var out: Array[String] = []
	for effect in effects:
		if effect.type == EventEffect.Type.IZ_BIRAK:
			out.append(effect.text_value.get_slice("|", 0) + "/" + effect.text_value.get_slice("|", 3))
	return out
