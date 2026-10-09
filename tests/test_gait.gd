extends RefCounted

## Yürüyüşün yönü ve kol-bacak uyumu (`FigureRig.pose`).
##
## Oyun figürü yerinde tutup dünyayı altından kaydırıyor, faz zamanla ARTIYOR
## (`WalkFigure.advance`). O yüzden yere basan ayak kalçaya göre yürüyüşün
## tersine gitmeli, havadaki ayak yürüyüş yönüne. Uzun süre tam tersiydi: yere
## basan ayak öne kayıyordu (ay yürüyüşü). Hiçbir test bunu görmedi, çünkü
## yürüyüş ancak zamana yayıldığında okunuyor; tek kare bunu gösteremez.
## Fark, 3B figür hattında kareler yan yana basılınca ölçüldü.

const H: float = 200.0
const STEPS: int = 96
const EPS: float = 1e-4

func suite_name() -> String:
	return "Gait"

func run(t) -> void:
	_test_planted_foot_moves_back(t)
	_test_arms_oppose_legs(t)

func _rel(joints: Dictionary, joint: String, origin: String, facing: float) -> Vector2:
	var d: Vector2 = joints[joint] - joints[origin]
	return Vector2(d.x * facing, d.y)

## Yerdeki ayak geriye, havadaki öne. Her iki yön, her iki bacak.
func _test_planted_foot_moves_back(t) -> void:
	for facing in [1.0, -1.0]:
		for side in ["front", "back"]:
			var wrong_planted := 0
			var wrong_swing := 0
			var planted := 0
			var swing := 0
			for i in STEPS:
				var p0 := TAU * i / STEPS
				var p1 := TAU * (i + 1) / STEPS
				var a := FigureRig.pose(Vector2.ZERO, H, p0, 1.0, facing)
				var b := FigureRig.pose(Vector2.ZERO, H, p1, 1.0, facing)
				var dx := _rel(b, "ankle_" + side, "hip", facing).x - _rel(a, "ankle_" + side, "hip", facing).x
				var a_down: bool = absf((a["ankle_" + side] as Vector2).y) < EPS
				var b_down: bool = absf((b["ankle_" + side] as Vector2).y) < EPS
				# Basıştan salınıma (ya da tersine) geçen adım ikisi de değil:
				# itişin son anında ayak hâlâ geri gidiyor, bu doğru.
				if a_down and b_down:
					planted += 1
					if dx > EPS:
						wrong_planted += 1
				elif not a_down and not b_down:
					swing += 1
					if dx < -EPS:
						wrong_swing += 1
			t.ok(planted > 0 and swing > 0, "%s ayak hem basıyor hem kalkıyor (facing %d)" % [side, int(facing)])
			t.eq(wrong_planted, 0, "yere basan %s ayak geriye gidiyor, öne kaymıyor (facing %d)" % [side, int(facing)])
			t.eq(wrong_swing, 0, "havadaki %s ayak öne gidiyor (facing %d)" % [side, int(facing)])

## Kol karşı bacakla aynı anda öne, aynı taraftaki bacakla zıt; ve en açık
## anları adım anına (iki ayak yerde) denk geliyor, geçişe değil.
func _test_arms_oppose_legs(t) -> void:
	for facing in [1.0, -1.0]:
		for side in ["front", "back"]:
			var other := "back" if side == "front" else "front"
			var arm: Array[float] = []
			var same_leg: Array[float] = []
			var opposite_leg: Array[float] = []
			for i in STEPS:
				var j := FigureRig.pose(Vector2.ZERO, H, TAU * i / STEPS, 1.0, facing)
				arm.append(_rel(j, "hand_" + side, "shoulder", facing).x)
				same_leg.append(_rel(j, "ankle_" + side, "hip", facing).x)
				opposite_leg.append(_rel(j, "ankle_" + other, "hip", facing).x)
			t.le(_corr(arm, same_leg), -0.9, "%s kol aynı taraf bacakla zıt salınıyor (facing %d)" % [side, int(facing)])
			t.ge(_corr(arm, opposite_leg), 0.9, "%s kol karşı bacakla birlikte salınıyor (facing %d)" % [side, int(facing)])

func _corr(a: Array[float], b: Array[float]) -> float:
	var ma := 0.0
	var mb := 0.0
	for i in a.size():
		ma += a[i]
		mb += b[i]
	ma /= a.size()
	mb /= b.size()
	var sab := 0.0
	var saa := 0.0
	var sbb := 0.0
	for i in a.size():
		sab += (a[i] - ma) * (b[i] - mb)
		saa += (a[i] - ma) * (a[i] - ma)
		sbb += (b[i] - mb) * (b[i] - mb)
	return sab / sqrt(maxf(saa * sbb, 1e-12))
