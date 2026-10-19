extends SceneTree

## Yolun doluluğu (görev Y-B09): 1x hızda gerçek dakika başına kaç karar ya da
## bilgi anı ("vuruş") düşüyor? Hedef: her 60-90 saniyede en az bir. Test değil,
## rapor. Kaynaklar: günün olay kartı (yönetmenle), yol işaretleri (gece
## katsayısıyla), havanın kararı (her gün bir), akşam kampı paneli (kalıcı
## emir açıkken her gün), kamp hikâyesi (bağ açıldıkça, ~%60).
##
##   godot --headless --script res://tests/simulate_road_beats.gd

const RUNS: int = 200
const DAYS: int = 8

func _initialize() -> void:
	var real_minutes := float(RUNS * DAYS) * JourneyClock.REAL_SECONDS_PER_DAY / 60.0
	for camp_order in [false, true]:
		var beats := {"kart": 0, "işaret": 0, "hava": 0, "kamp": 0, "hikâye": 0}
		for run in RUNS:
			var engine := EventEngine.new(EventCatalog.get_road_events(), hash("beats|%d" % run))
			engine.director = RoadDirector.new()
			var signals := RoadSignals.new()
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("beats_rng|%d" % run)
			for day in DAYS:
				var event := engine.roll_for_day(day, {"danger": 0.4, "stress": 20.0})
				if event != null:
					beats["kart"] += 1
					engine.mark_fired(event, day)
				beats["hava"] += 1
				if camp_order:
					beats["kamp"] += 1
					if rng.randf() < CampStory.TELL_CHANCE * 0.5:
						beats["hikâye"] += 1
				for hour in 24:
					var dark := JourneyClock.darkness_for_hour(float(hour)) >= 0.5
					var scale := 1.0 if (camp_order and dark) or not dark else 1.5
					var out := signals.tick(1.0, "front", rng, 0, {}, scale)
					beats["işaret"] += (out["appeared"] as Array).size()
		var total := 0
		for key in beats:
			total += int(beats[key])
		print("akşam kampı %s: dakikada %.2f vuruş (hedef >= 0.67) | %s" % [
			"açık" if camp_order else "kapalı", float(total) / real_minutes, str(beats)
		])
	quit()
