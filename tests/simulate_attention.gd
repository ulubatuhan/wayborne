extends SceneTree

## Dikkat stratejileri ölçümü (görev Y-B04): "hep önde dur" diğerlerinden
## belirgin biçimde üstün mü? Test değil, rapor (bkz. simulate_journeys.gd).
##
##   godot --headless --script res://tests/simulate_attention.gd
##
## Her strateji 200 sefer x 8 gün oynanır; işaret katmanı RoadSignals'ın
## kendisi, rol kapsaması yol ekranının formülü (ROLE_RESOLVE_PER_HOUR x güç).
## Raporlanan: sefer başına büyüyen (ihmal edilen) işaret ve zararlı büyüyen
## (gerçeği boş olmayan) işaret.

const RUNS: int = 200
const DAYS: int = 8
const HARMLESS: Array[String] = ["false_alarm", "herders", "empty_omen"]
const ZONES: Array[String] = ["front", "wagons", "rear"]

func _initialize() -> void:
	print("strateji | roller | büyüyen/sefer | zararlı büyüyen/sefer | çözülen/sefer")
	for strategy in ["hep_on", "hep_vagon", "dolasir", "isarete_yuru"]:
		for roles in [false, true]:
			var stats := _measure(strategy, roles)
			print("%s | %s | %.2f | %.2f | %.2f" % [strategy, "var" if roles else "yok", stats[0], stats[1], stats[2]])
	quit()

func _measure(strategy: String, roles: bool) -> Array:
	var escalated := 0
	var harmful := 0
	var resolved := 0
	for run in RUNS:
		var signals := RoadSignals.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("attention|%s|%d" % [strategy, run])
		var cover := {}
		if roles:
			for zone in ZONES:
				cover[zone] = RoadSignals.ROLE_RESOLVE_PER_HOUR
		for hour in DAYS * 24:
			var zone := _zone_for(strategy, hour, signals)
			var out := signals.tick(1.0, zone, rng, 0, cover)
			escalated += (out["escalated"] as Array).size()
			resolved += (out["resolved"] as Array).size()
			for truth in out["escalated_truths"]:
				if not HARMLESS.has(String(truth)):
					harmful += 1
	return [float(escalated) / RUNS, float(harmful) / RUNS, float(resolved) / RUNS]

func _zone_for(strategy: String, hour: int, signals: RoadSignals) -> String:
	match strategy:
		"hep_on":
			return "front"
		"hep_vagon":
			return "wagons"
		"dolasir":
			return ZONES[(hour / 8) % ZONES.size()]
		"isarete_yuru":
			var kinds := signals.get_open_kinds()
			if not kinds.is_empty():
				return RoadSignals.get_zone_for(kinds[0])
	return "front"
