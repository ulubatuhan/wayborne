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
	quit()
