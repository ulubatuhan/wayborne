extends SceneTree

## Kart kalite raporu (Y-E01). Test değil: hiçbir zaman başarısız olmaz, kataloğu
## EventQuality listesinden geçirip hangi kartın neyi eksik olduğunu ve
## çekilebilir kart sayısını 120 hedefine karşı yazar.
##   godot --headless --script res://tests/report_event_quality.gd

func _initialize() -> void:
	TranslationServer.set_locale("tr")
	var events := EventCatalog.get_road_events()
	var failing := 0
	var by_problem := {}
	for event in events:
		var found := EventQuality.problems(event)
		if found.is_empty():
			continue
		failing += 1
		for problem in found:
			by_problem[problem] = int(by_problem.get(problem, 0)) + 1
		print("  %-36s %s" % [event.event_id, ", ".join(found)])
	print("── Kart kalitesi: %d kart, %d tanesi listeden tam geçmiyor" % [events.size(), failing])
	for problem in by_problem:
		print("   %s: %d" % [problem, by_problem[problem]])
	print("── Çekilebilir kart: %d / hedef %d" % [EventQuality.drawable_count(events), EventQuality.TARGET_DRAWABLE])
	_report_dominant_choices(events)
	quit()

## Y-C22: baskın seçenek raporu. Kıtlık kartlarında doğru seçenek olmamalı:
## bir seçenek ölçülebilir her eksende (altın, erzak, moral, itibar, stres)
## öbüründen iyi ya da eşitse ve en az birinde iyiyse onu "baskın" sayar.
## Yalnızca zarsız, tek sonuçlu ve bu beş eksen dışında etkisi olmayan
## seçenekler karşılaştırılır; gerisi okunamaz, sayılmaz.
const AXES: Dictionary = {
	EventEffect.Type.GOLD: 1.0, EventEffect.Type.PROVISIONS: 1.0, EventEffect.Type.MORALE: 1.0,
	EventEffect.Type.REPUTATION: 1.0, EventEffect.Type.STRESS: -1.0,
}

func _report_dominant_choices(events: Array[GameEvent]) -> void:
	var found := 0
	for event in events:
		var vectors: Array = []
		for choice in event.choices:
			vectors.append(_vector(choice))
		for i in vectors.size():
			for j in vectors.size():
				if i != j and vectors[i] != null and vectors[j] != null and _dominates(vectors[i], vectors[j]):
					found += 1
					print("  baskın: %-34s %s > %s" % [event.event_id, event.choices[i].text_key, event.choices[j].text_key])
	print("── Baskın seçenek (Y-C22): %d çift" % found)

func _vector(choice: EventChoice):
	if not choice.outcomes.is_empty() or choice.check != null:
		return null
	var v := {}
	for axis in AXES:
		v[axis] = 0.0
	for effect in choice.effects:
		if not AXES.has(effect.type):
			return null
		v[effect.type] = float(v[effect.type]) + float(effect.amount) * float(AXES[effect.type])
	return v

func _dominates(a: Dictionary, b: Dictionary) -> bool:
	var better := false
	for axis in a:
		if float(a[axis]) < float(b[axis]):
			return false
		if float(a[axis]) > float(b[axis]):
			better = true
	return better
