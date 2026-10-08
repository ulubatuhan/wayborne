## Faz 0 olcumu: gercek FigureRig.pose() uzerinden, bir yurume dongusunde 5 katmanin
## (back_arm, back_leg, torso_head, front_leg, front_arm) kirpilmis kutu boyutu (h birimi).
## Render YOK - eklem konumlarindan hesap; kalinlik payi limb_pad*h.
extends SceneTree
const FRAMES := 48
const LIMB_PAD := 0.055   # uzuv yaricapi payi (h'nin orani) - tahmin, olculmus degil
const HEAD_PAD := 0.11
func _init() -> void:
	var h := 1000.0
	var layers := {
		"back_arm": ["shoulder", "elbow_back", "hand_back", "fingers_back"],
		"front_arm": ["shoulder", "elbow_front", "hand_front", "fingers_front"],
		"back_leg": ["hip", "knee_back", "ankle_back", "toe_back"],
		"front_leg": ["hip", "knee_front", "ankle_front", "toe_front"],
		"torso_head": ["hip", "shoulder", "head"],
	}
	var sums := {}; var maxes := {}
	for k in layers: sums[k] = Vector2.ZERO; maxes[k] = Vector2.ZERO
	var union_max := Vector2.ZERO
	for f in FRAMES:
		var ph := TAU * float(f) / FRAMES
		var j := FigureRig.pose(Vector2.ZERO, h, ph, 1.0, 1.0)
		var all_min := Vector2(1e9, 1e9); var all_max := Vector2(-1e9, -1e9)
		for k in layers:
			var mn := Vector2(1e9, 1e9); var mx := Vector2(-1e9, -1e9)
			for jn in layers[k]:
				var p: Vector2 = j[jn]
				mn = _vmin(mn, p); mx = _vmax(mx, p)
			var pad := HEAD_PAD if k == "torso_head" else LIMB_PAD
			mn -= Vector2(pad, pad) * h; mx += Vector2(pad, pad) * h
			var sz := (mx - mn) / h
			sums[k] += sz; maxes[k] = _vmax(maxes[k], sz)
			all_min = _vmin(all_min, mn); all_max = _vmax(all_max, mx)
		union_max = _vmax(union_max, (all_max - all_min) / h)
	var area_avg := 0.0; var area_max := 0.0
	for k in layers:
		var avg: Vector2 = sums[k] / FRAMES
		print("%-10s avg bbox = %.3f x %.3f h   max = %.3f x %.3f h" % [k, avg.x, avg.y, maxes[k].x, maxes[k].y])
		area_avg += avg.x * avg.y
		area_max += maxes[k].x * maxes[k].y
	print("5 katman toplam alan: ortalama-kare %.4f h^2, sabit-max-kutu %.4f h^2" % [area_avg, area_max])
	print("tum figur birlesik kutu (max kare): %.3f x %.3f h" % [union_max.x, union_max.y])
	quit()

func _vmin(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(minf(a.x, b.x), minf(a.y, b.y))
func _vmax(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(maxf(a.x, b.x), maxf(a.y, b.y))
