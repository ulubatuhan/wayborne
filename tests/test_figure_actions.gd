extends RefCounted

## Yürüme dışı pozların sözleşmesi (`FigureActions`): kemik boyları her
## karede sabit (3B hattı yalnız döndürüyor, bir kemik uzarsa render onu
## göstermez ve eklem oynar), ayakta duran kliplerde ayaklar zeminde, yatan
## pozlar gerçekten yerde, yerde dayanılan el zeminin altına girmiyor, yay
## gerilince kiriş eli çeneye yakın, botta bilek yalın ayaktan az oynuyor.

const H: float = 200.0
const LEN_EPS: float = 0.01
const GROUND_EPS: float = 0.5

func suite_name() -> String:
	return "FigureActions"

func run(t) -> void:
	_test_bone_lengths_constant(t)
	_test_standing_clips_stand(t)
	_test_lying_poses_lie(t)
	_test_bow_draw(t)
	_test_weapon_families(t)
	_test_boot_limits_ankle(t)
	_test_laden_walk_holds_strap(t)

func _length(j: Dictionary, a: String, b: String) -> float:
	return (Vector2(j[b]) - Vector2(j[a])).length()

func _test_bone_lengths_constant(t) -> void:
	var ref := FigureActions.pose_from(FigureActions.NEUTRAL, Vector2.ZERO, H, 1.0)
	for clip in FigureActions.CLIPS:
		for i in FigureActions.frame_count(clip):
			for facing in [1.0, -1.0]:
				var j := FigureActions.pose(clip, i, Vector2(300, 400), H, facing)
				for pair in [["shoulder", "elbow_front"], ["elbow_front", "hand_front"],
						["shoulder", "elbow_back"], ["elbow_back", "hand_back"],
						["hip", "shoulder"], ["ankle_front", "toe_front"], ["ankle_back", "toe_back"],
						["hand_front", "weapon_tip"]]:
					t.almost(_length(j, pair[0], pair[1]), _length(ref, pair[0], pair[1]),
						"%s/%d %s-%s boyu sabit" % [clip, i, pair[0], pair[1]], LEN_EPS * H)
				for side in ["front", "back"]:
					var leg := _length(j, "hip", "knee_" + side) + _length(j, "knee_" + side, "ankle_" + side)
					t.almost(_length(j, "hip", "knee_" + side), H * FigureRig.HIP_RATIO * FigureRig.THIGH_SHARE,
						"%s/%d %s uyluk boyu" % [clip, i, side], LEN_EPS * H)
					t.le(leg, H * FigureRig.HIP_RATIO * (FigureRig.THIGH_SHARE + FigureRig.SHIN_SHARE) + LEN_EPS * H,
						"%s/%d %s bacak uzamıyor" % [clip, i, side])

func _lowest(j: Dictionary) -> float:
	var y := -INF
	for k in j:
		if k != "draw":
			y = maxf(y, j[k].y)
	return y

func _test_standing_clips_stand(t) -> void:
	var ground := Vector2(0, 500)
	for clip in FigureActions.CLIPS:
		if clip in ["dead", "downed"]:
			continue
		for i in FigureActions.frame_count(clip):
			var j := FigureActions.pose(clip, i, ground, H, 1.0)
			var feet := maxf(j["ankle_front"].y, j["ankle_back"].y)
			t.almost(feet, ground.y, "%s/%d bir ayak zeminde" % [clip, i], GROUND_EPS)
			t.le(_lowest(j), ground.y + GROUND_EPS, "%s/%d hiçbir eklem zeminin altında değil" % [clip, i])
			t.le(j["hip"].y, ground.y - H * 0.3, "%s/%d kalça ayakta yüksekliğinde" % [clip, i])

func _test_lying_poses_lie(t) -> void:
	var ground := Vector2(0, 500)
	for clip in ["dead", "downed"]:
		var j := FigureActions.pose(clip, 0, ground, H, 1.0)
		t.le(_lowest(j), ground.y + GROUND_EPS, "%s hiçbir eklem zeminin altında değil" % clip)
		t.ge(j["hip"].y, ground.y - H * 0.08, "%s kalça yere yakın" % clip)
	var dead := FigureActions.pose("dead", 0, ground, H, 1.0)
	for k in ["shoulder", "head", "knee_front", "knee_back", "ankle_front", "ankle_back"]:
		t.ge(dead[k].y, ground.y - H * 0.12, "ölü: %s yerde (bir bacak havada değil)" % k)
	var downed := FigureActions.pose("downed", 0, ground, H, 1.0)
	t.almost(downed["fingers_back"].y, ground.y, "yerde: dayanan elin parmakları zeminde", H * 0.01)
	t.le(downed["shoulder"].y, downed["hip"].y - H * 0.04, "yerde: omuz kalçadan yüksek (yarı oturuyor)")

func _test_bow_draw(t) -> void:
	var j := FigureActions.pose("aim_bow", 0, Vector2(0, 500), H, 1.0)
	t.almost(float(j["draw"].x), 1.0, "nişan: kiriş tam çekili")
	t.le((Vector2(j["hand_back"]) - Vector2(j["head"])).length(), H * 0.09, "nişan: arka el yüzde")
	t.ge(j["hand_front"].x - j["shoulder"].x, H * 0.2, "nişan: yay kolu öne uzanık")
	t.almost(j["hand_front"].y, j["shoulder"].y, "nişan: yay kolu omuz hizasında", H * 0.04)
	var low := FigureActions.pose("stance_bow", 0, Vector2(0, 500), H, 1.0)
	t.almost(float(low["draw"].x), 0.0, "bekleme: kiriş gevşek")
	t.ge(low["hand_front"].y, low["hip"].y - H * 0.06, "bekleme: yay aşağıda, elde")
	var mirrored := FigureActions.pose("aim_bow", 0, Vector2(0, 500), H, -1.0)
	t.almost(mirrored["hand_front"].x, -j["hand_front"].x, "sola bakınca ayna")

func _test_weapon_families(t) -> void:
	for w in ["bow", "spear_shield", "sword", ""]:
		var c := FigureActions.clips_for_weapon(w)
		for k in ["stance", "attack", "aim"]:
			t.ok(FigureActions.has_clip(String(c[k])), "%s ailesi %s klibi var" % [w, k])
	t.eq(FigureActions.clips_for_weapon("bow")["attack"], "attack_bow", "yay gerer")
	t.eq(FigureActions.clips_for_weapon("spear_shield")["attack"], "attack_thrust", "mızrak saplar")
	t.eq(FigureActions.clips_for_weapon("sword")["attack"], "attack_swing", "kılıç savurur")

func _pitch_span(ankle_range: float) -> float:
	var lo := INF
	var hi := -INF
	for i in 48:
		var j := FigureActions.walk_pose(Vector2(0, 500), H, TAU * i / 48.0, 1.0, 1.0, ankle_range)
		var d: Vector2 = j["toe_front"] - j["ankle_front"]
		lo = minf(lo, d.angle())
		hi = maxf(hi, d.angle())
	return hi - lo

func _test_boot_limits_ankle(t) -> void:
	var bare := _pitch_span(1.0)
	var boot := _pitch_span(FigureRig.BOOT_ANKLE_RANGE)
	t.ge(bare, deg_to_rad(30.0), "yalın ayak bilek oynuyor")
	t.le(boot, bare * FigureRig.BOOT_ANKLE_RANGE + 0.01, "bot bileği kısıtlıyor")
	t.almost(_pitch_span(0.0), 0.0, "bileksiz eski yürüyüş düz", 0.001)

func _test_laden_walk_holds_strap(t) -> void:
	for i in 8:
		var phase := TAU * i / 8.0
		var free := FigureActions.walk_pose(Vector2(0, 500), H, phase, 1.0, 1.0)
		var laden := FigureActions.walk_pose(Vector2(0, 500), H, phase, 1.0, 1.0, 1.0, true)
		t.le(laden["hand_front"].y, laden["shoulder"].y + H * 0.1, "heybe: ön el askıda, göğüs hizasında")
		t.ge(laden["shoulder"].x - laden["hip"].x, free["shoulder"].x - free["hip"].x, "heybe: gövde öne eğik")
		t.almost(float(laden["draw"].x), 0.0, "yürüyüşte kiriş yok")
