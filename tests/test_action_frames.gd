extends RefCounted

## Kare kümesinin oyunda hangi klibi oynattığı ve sırtta taşınanın nereye
## oturduğu. Saf fonksiyonlar (`WalkFigure.pick_clip`, `back_frame`,
## `slung_points`, `bow_points`, `CombatFigure.action_for`,
## `CombatFx.reaction_role`) - sahne gerektirmiyor.
##
## Sırttaki yay uzun süre omuzdan sabit bir ofsetle çiziliyordu ve sırtın
## arkasında havada asılı duruyordu (oyuncu ekran görüntüsüyle bildirdi).
## Artık render'ın kendi sırt yüzeyinden iki noktaya oturuyor; bu test yayın
## sırta değdiğini ve sırt boyunca uzandığını ölçüyor.

const H: float = 200.0

func suite_name() -> String:
	return "ActionFrames"

func run(t) -> void:
	_test_pick_clip(t)
	_test_slung_bow_touches_back(t)
	_test_slung_points_follow_lean(t)
	_test_bow_draw_points(t)
	_test_combat_action_roles(t)
	_test_packed_variants_carry_new_clips(t)
	_test_beast_clips(t)
	_test_beast_packs(t)

const ALL: PackedStringArray = ["walk", "idle", "ride", "walk_boots", "walk_laden",
	"stance_melee", "stance_bow", "aim_bow", "attack_swing", "attack_thrust", "attack_bow",
	"hit", "defend", "dead", "downed"]

func _test_pick_clip(t) -> void:
	t.eq(WalkFigure.pick_clip(ALL, false, 1.0, "", false, "sword", false, false), "walk", "yürüyüş")
	t.eq(WalkFigure.pick_clip(ALL, false, 0.0, "", false, "sword", false, false), "idle", "duruş")
	t.eq(WalkFigure.pick_clip(ALL, true, 1.0, "", false, "sword", false, false), "ride", "binici")
	t.eq(WalkFigure.pick_clip(ALL, false, 1.0, "", false, "sword", false, true), "walk_boots", "çizmeyle bilek kısık")
	t.eq(WalkFigure.pick_clip(ALL, false, 1.0, "", false, "sword", true, true), "walk_laden", "heybe çizmeden önce gelir")
	t.eq(WalkFigure.pick_clip(ALL, false, 0.0, "", true, "bow", false, false), "stance_bow", "okçu yayı aşağıda bekletir")
	t.eq(WalkFigure.pick_clip(ALL, false, 0.0, "", true, "sword", false, false), "stance_melee", "kılıç duruşu")
	t.eq(WalkFigure.pick_clip(ALL, false, 0.0, "attack_bow", true, "bow", false, false), "attack_bow", "aksiyon duruşu ezer")
	t.eq(WalkFigure.pick_clip(ALL, false, 1.0, "dead", false, "bow", false, false), "dead", "ölü yürümez")
	var old := PackedStringArray(["walk", "idle", "ride"])
	t.eq(WalkFigure.pick_clip(old, false, 0.0, "attack_swing", true, "sword", false, false), "idle", "eski paket duruşa düşer")
	t.eq(WalkFigure.pick_clip(old, false, 1.0, "", false, "sword", true, true), "walk", "eski paket yalın yürür")

## Sırttan dışarıya uzaklık (+ = sırtın arkasında, - = gövdenin içinde).
func _outward(p: Vector2, spine: Dictionary) -> float:
	return (p - Vector2(spine.lower)).dot(spine.out)

func _test_slung_bow_touches_back(t) -> void:
	for facing in [1.0, -1.0]:
		var upper := Vector2(100.0 - 4.0 * facing, 300.0)
		var lower := Vector2(100.0 - 3.0 * facing, 330.0)
		var spine := WalkFigure.back_frame(upper, lower, facing)
		t.ok(Vector2(spine.out).x * facing < 0.0, "dışa yönü figürün arkası (facing %d)" % int(facing))
		var bow := WalkFigure.slung_points("bow", spine, H)
		for k in ["top", "bottom"]:
			var d := _outward(bow[k], spine)
			t.ge(d, 0.0, "yay ucu (%s) gövdenin içine girmiyor" % k)
			t.le(d, H * 0.04, "yay ucu (%s) sırta değiyor, havada değil" % k)
		var along: Vector2 = Vector2(bow.top) - Vector2(bow.bottom)
		t.ge(absf(along.normalized().dot(spine.up)), 0.98, "yay sırt boyunca uzanıyor")
		t.le(_outward(bow.bulge, spine), H * 0.08, "yayın kavisi sırttan uzaklaşmıyor")
		var sword := WalkFigure.slung_points("sword", spine, H)
		t.ge(Vector2(sword.top).y, lower.y - 1.0, "kılıç belde")
		t.ge(_outward(sword.bottom, spine), 0.0, "kın arkaya sarkıyor")
		var pack := WalkFigure.pack_outline(spine, H)
		for p in pack:
			t.ge(_outward(p, spine), 0.0, "heybe gövdeye gömülmüyor")
			t.le(_outward(p, spine), H * 0.1, "heybe sırta yaslı")

func _test_slung_points_follow_lean(t) -> void:
	# Heybeli yürüyüşte gövde öne eğik: sırttaki yay da onunla eğilmeli.
	var spine := WalkFigure.back_frame(Vector2(110, 300), Vector2(100, 330), 1.0)
	var bow := WalkFigure.slung_points("bow", spine, H)
	var dir: Vector2 = (Vector2(bow.top) - Vector2(bow.bottom)).normalized()
	t.ge(dir.dot(Vector2(spine.up)), 0.98, "eğik sırtta yay da eğik")
	t.ge(dir.x, 0.2, "üst uç öne eğilmiş")

func _test_bow_draw_points(t) -> void:
	var hand := Vector2(200, 300)
	var back_hand := Vector2(150, 290)
	var up := Vector2(0, -1)
	var loose := WalkFigure.bow_points(hand, up, H, 1.0, back_hand, 0.0)
	var drawn := WalkFigure.bow_points(hand, up, H, 1.0, back_hand, 1.0)
	t.almost(Vector2(loose.nock).distance_to((Vector2(loose.top) + Vector2(loose.bottom)) * 0.5), 0.0, "gevşek kiriş düz")
	t.almost(Vector2(drawn.nock).distance_to(back_hand), 0.0, "gerili kiriş arka elde")
	t.ge(Vector2(loose.bulge).x, hand.x, "yay hedefe doğru kavisli")
	var left := WalkFigure.bow_points(hand, up, H, -1.0, back_hand, 0.0)
	t.le(Vector2(left.bulge).x, hand.x, "sola bakınca kavis sola")

func _test_combat_action_roles(t) -> void:
	t.eq(CombatFx.reaction_role(CombatEncounter.BARK_HIT), "hit", "isabet: darbe klibi")
	t.eq(CombatFx.reaction_role(CombatEncounter.BARK_CRIT), "hit", "kritik: darbe klibi")
	t.eq(CombatFx.reaction_role(CombatEncounter.BARK_MISS), "defend", "kaçırma: savunma klibi")
	t.eq(CombatFx.reaction_role(CombatEncounter.BARK_KILLED), "", "ölüm bir rol değil, düşüş")
	var a := CombatFigure.action_for("ok", 1.0, CombatFigure.ROLE_ATTACK, 0.4, "bow")
	t.eq(a.clip, "attack_bow", "okçu saldırıda yay gerer")
	t.eq(CombatFigure.action_for("ok", 1.0, CombatFigure.ROLE_ATTACK, 0.4, "spear_shield").clip, "attack_thrust", "mızrak saplar")
	t.eq(CombatFigure.action_for("ok", 1.0, CombatFigure.ROLE_ATTACK, 0.4, "cleaver").clip, "attack_swing", "satır savurur")
	t.eq(CombatFigure.action_for("ok", 1.0, "", 0.0, "bow").clip, "", "rol yoksa duruş")
	t.eq(CombatFigure.action_for("dead", 1.0, "", 0.0, "sword").clip, "dead", "ölü yatıyor")
	t.eq(CombatFigure.action_for("downed", 1.0, CombatFigure.ROLE_HIT, 0.5, "sword").clip, "downed", "yerdeki rol oynamaz")
	var falling := CombatFigure.action_for("dead", 0.4, "", 0.0, "sword")
	t.eq(falling.clip, "hit", "düşerken darbe klibi")
	t.almost(float(falling.u), 0.4, "düşüşün ilerlemesi klibin zamanı")

## Paketlenmiş her varyant yeni klipleri ve sırt/silah verisini taşımalı.
func _test_packed_variants_carry_new_clips(t) -> void:
	for v in ["male_average", "female_average", "male_lean", "male_heavy", "female_lean", "female_heavy"]:
		var frames := BodyFrames.for_body("body_" + v)
		t.ok(frames != null, "%s paketi var" % v)
		if frames == null:
			continue
		for clip in ALL:
			t.ok(frames.has_clip(clip), "%s: %s klibi" % [v, clip])
			if not frames.has_clip(clip):
				continue
			t.eq(frames.frame_count(clip), _expected_frames(clip), "%s: %s kare sayısı" % [v, clip])
		var j := frames.frame_joints("idle", 0)
		t.ok(j.has("back_upper") and j.has("back_lower"), "%s: sırt işaretleri" % v)
		if j.has("back_upper"):
			t.le(Vector2(j.back_upper).x, Vector2(j.shoulder).x, "%s: sırt omzun arkasında" % v)
			t.le(Vector2(j.back_upper).y, Vector2(j.back_lower).y, "%s: kürek belden yüksek" % v)
		if frames.has_clip("aim_bow"):
			var aim := frames.frame_weapon("aim_bow", 0)
			t.almost(float(aim.draw), 1.0, "%s: nişanda kiriş çekili" % v)
			t.almost(float(aim.angle), -PI * 0.5, "%s: nişanda yay dik" % v, 0.05)
		var dead := frames.frame_joints("dead", 0)
		if dead.has("neck"):
			t.ge(Vector2(dead.neck).y, -frames.shoulder_px * 0.35, "%s: ölünün boynu yerde" % v)

func _expected_frames(clip: String) -> int:
	if FigureActions.has_clip(clip):
		return FigureActions.frame_count(clip)
	if clip in ["walk_boots", "walk_laden"]:
		return 12  # tools/figure_pipeline/config/build.json: yarim cozunurluklu dongu
	return 1 if clip == "idle" else 24

func _test_beast_clips(t) -> void:
	t.eq(BodyFrames.beast_clip("ok", 1.0, "", 1.0), "walk", "hayvan yürür")
	t.eq(BodyFrames.beast_clip("ok", 1.0, "", 0.0), "idle", "hayvan durur")
	t.eq(BodyFrames.beast_clip("ok", 1.0, "attack", 0.0), "attack", "hayvan saldırır")
	t.eq(BodyFrames.beast_clip("ok", 1.0, "defend", 0.0), "hit", "hayvanın savunması darbe klibi")
	t.eq(BodyFrames.beast_clip("dead", 1.0, "attack", 0.0), "dead", "ölü hayvan yatar")
	t.eq(BodyFrames.beast_clip("downed", 0.3, "", 0.0), "hit", "düşerken darbe")
	var frames := BodyFrames.new()
	frames.shoulder_px = 157.0
	frames.ref_share = 0.66
	t.almost(frames.scale_for(100.0) * 157.0, 66.0, "hayvanın cidağosu oyunda back * h")
	frames.ref_share = 0.0
	t.almost(frames.scale_for(100.0) * 157.0, BodyFrames.SHOULDER_SHARE * 100.0, "insan omuz payı")

const BEASTS: Array[String] = ["horse", "horse_white", "ox", "donkey", "stag", "deer", "wolf", "husky", "bear", "boar"]
## Ölüyken sırtın ayaktaki hâline oranı en fazla bu. Ayı ve domuzun
## animasyonu yok, ölü pozları kemik döndürerek üretiliyor ve gövde yeterince
## yere inmiyor (ölçülen 0.92 / 0.96) - eşik bu iki tür için, kullanıcı
## kararıyla gevşetildi (QUESTIONS #16, seçenek c). Diğerleri 0.9'da kalıyor.
const DEAD_BACK_SHARE: Dictionary = {"bear": 0.94, "boar": 0.97}
const BEAST_CLIPS: Dictionary = {"walk": 16, "idle": 1, "attack": 8, "hit": 4, "dead": 1, "downed": 1}

## Her tür paketlenmiş olmalı: altı klip, eyer işareti, yatan pozlar yerde.
func _test_beast_packs(t) -> void:
	for sp in BEASTS:
		var frames := BodyFrames.for_beast(sp)
		t.ok(frames != null, "%s kare kümesi var" % sp)
		if frames == null:
			continue
		t.ge(frames.ref_share, 0.3, "%s cidağo payı" % sp)
		for clip in BEAST_CLIPS:
			t.eq(frames.frame_count(clip), int(BEAST_CLIPS[clip]), "%s: %s kare sayısı" % [sp, clip])
		var idle := frames.frame_joints("idle", 0)
		t.almost(-Vector2(idle.saddle).y, frames.shoulder_px, "%s: eyer cidağo hizasında" % sp, frames.shoulder_px * 0.2)
		var dead := frames.frame_joints("dead", 0)
		t.le(-Vector2(dead.saddle).y, -Vector2(idle.saddle).y * float(DEAD_BACK_SHARE.get(sp, 0.9)),
			"%s: ölüyken sırt ayaktakinden alçak" % sp)
		t.le(-Vector2(dead.head).y, -Vector2(idle.head).y * 0.75, "%s: ölüyken baş yere inmiş" % sp)
		var e := frames.entry("dead", 0, 2, BodyFrames.KIND_BODY)
		t.ok(not e.is_empty(), "%s: ölü gövde katmanı çizili" % sp)
