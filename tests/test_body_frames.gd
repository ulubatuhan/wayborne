extends RefCounted

## Önceden render edilmiş beden kareleri (`BodyFrames`) ve onları çizen
## `WalkFigure` yolu. Resmin kendisini değil, oyunun ona güvendiği sözleşmeyi
## sınıyor: her varyant var, kayıt sayıları tutarlı, ayak yere basıyor,
## giysi bedenin dışına taşmıyor, ölçek eski figürün boyunu koruyor.

const GROUND_TOLERANCE_PX: float = 8.0
## Zayıf/orta/kilolu yan görünüşte en az bu oranda ayrışmalı. MPFB'nin kilo
## makrosu tek başına +%3 veriyordu; o paket bu testten kalır.
const WEIGHT_AREA_STEP: float = 0.08

func suite_name() -> String:
	return "BodyFrames"

func run(t) -> void:
	_test_missing_variant_falls_back(t)
	_test_frame_for_phase(t)
	_test_frame_tones(t)
	for g in Wardrobe.GENDER_KEYS:
		for w in Wardrobe.BODY_WEIGHT_KEYS:
			_test_variant(t, "body_%s_%s" % [g, w])
		_test_weights_read_apart(t, g)

func _test_missing_variant_falls_back(t) -> void:
	t.eq(BodyFrames.for_body("body_yok_boyle_biri"), null, "olmayan varyant null döner (eski mankene düşülür)")

func _fake() -> BodyFrames:
	var f := BodyFrames.new()
	f.clip_names = PackedStringArray(["walk", "idle"])
	f.clip_frames = PackedInt32Array([24, 1])
	return f

func _test_frame_for_phase(t) -> void:
	var f := _fake()
	t.eq(f.frame_for_phase("walk", 0.0), 0, "faz 0 -> kare 0")
	t.eq(f.frame_for_phase("walk", TAU * 6.0 / 24.0), 6, "faz TAU*6/24 -> kare 6")
	t.eq(f.frame_for_phase("walk", TAU), 0, "tam tur başa sarar")
	t.eq(f.frame_for_phase("walk", TAU * 3.0 + TAU * 0.5), 12, "birikmiş faz da sarar")
	t.eq(f.frame_for_phase("idle", 1.7), 0, "tek kareli klip hep 0")
	t.eq(f.frame_count("ride"), 0, "olmayan klip 0 kare")

func _test_frame_tones(t) -> void:
	var skin := Color(0.6, 0.45, 0.35)
	var plain := WalkFigure.frame_tones(skin, {}, Color.WHITE)
	t.eq(plain[BodyFrames.KIND_BODY], skin, "beden ten rengini taşır")
	t.eq(plain[BodyFrames.KIND_TOP], WalkFigure.UNDERSHIRT_COLOR, "kıyafetsiz üst = temel atlet/bra")
	t.eq(plain[BodyFrames.KIND_BOTTOM], WalkFigure.SHORTS_COLOR, "kıyafetsiz alt = temel şort")

func _test_variant(t, body_id: String) -> void:
	var f := BodyFrames.for_body(body_id)
	t.ok(f != null, "%s kare kümesi var" % body_id)
	if f == null:
		return
	var total := 0
	for n in f.clip_frames:
		total += n
	var entries := total * BodyFrames.LAYERS.size() * BodyFrames.KINDS
	t.eq(f.rects.size(), entries * 5, "%s: kayıt başına 5 rect alanı" % body_id)
	t.eq(f.offsets.size(), entries, "%s: kayıt başına bir ofset" % body_id)
	t.eq(f.joints.size(), total * f.joint_names.size(), "%s: kare başına eklem seti" % body_id)
	t.ok(f.shoulder_px > 0.0, "%s: omuz yüksekliği ölçülmüş" % body_id)
	t.almost(f.scale_for(100.0) * f.shoulder_px, BodyFrames.SHOULDER_SHARE * 100.0,
		"%s: ölçek omzu FigureRig'deki yerine koyuyor" % body_id)
	for p in f.pages.size():
		t.ok(f.texture(p) != null, "%s: sayfa %d yükleniyor" % [body_id, p])
	for clip in ["walk", "idle"]:
		_test_clip_grounded(t, f, body_id, clip)
	_test_garments_inside_body(t, f, body_id)

## Yürüme ve duruşta en alttaki bacak pikseli çapanın (zemin) üstünde biter:
## figür ne havada ne gömülü.
func _test_clip_grounded(t, f: BodyFrames, body_id: String, clip: String) -> void:
	var worst := 0.0
	for frame in f.frame_count(clip):
		var lowest := -INF
		for layer in [1, 3]:  # back_leg, front_leg
			var e := f.entry(clip, frame, layer, BodyFrames.KIND_BODY)
			if e.is_empty():
				continue
			lowest = maxf(lowest, Vector2(e.offset).y + Rect2(e.region).size.y)
		worst = maxf(worst, absf(lowest))
	t.le(worst, GROUND_TOLERANCE_PX, "%s/%s: ayak zemine basıyor (en kötü %.1f px)" % [body_id, clip, worst])

## Atlet/bra ve şort resmi, aynı katmanın beden resminin kutusu içinde.
func _test_garments_inside_body(t, f: BodyFrames, body_id: String) -> void:
	var outside := 0
	for clip in f.clip_names:
		for frame in f.frame_count(clip):
			for layer in BodyFrames.LAYERS.size():
				var body := f.entry(clip, frame, layer, BodyFrames.KIND_BODY)
				if body.is_empty():
					continue
				var box := Rect2(body.offset, Rect2(body.region).size).grow(0.5)
				for kind in [BodyFrames.KIND_TOP, BodyFrames.KIND_BOTTOM]:
					var g := f.entry(clip, frame, layer, kind)
					if g.is_empty():
						continue
					if not box.encloses(Rect2(g.offset, Rect2(g.region).size)):
						outside += 1
	t.eq(outside, 0, "%s: giysi resmi bedenin dışına taşmıyor" % body_id)

## Duruş karesinde beden alanı (beş katmanın beden resmi): zayıf < orta < kilolu.
func _idle_area(f: BodyFrames) -> int:
	var area := 0
	for layer in BodyFrames.LAYERS.size():
		var e := f.entry("idle", 0, layer, BodyFrames.KIND_BODY)
		if e.is_empty():
			continue
		var img: Image = (e.texture as Texture2D).get_image().get_region(Rect2i(e.region))
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.5:
					area += 1
	return area

func _test_weights_read_apart(t, gender: String) -> void:
	var areas: Array[int] = []
	for w in Wardrobe.BODY_WEIGHT_KEYS:
		var f := BodyFrames.for_body("body_%s_%s" % [gender, w])
		if f == null:
			return
		areas.append(_idle_area(f))
	t.ge(float(areas[1]) / float(areas[0]), 1.0 + WEIGHT_AREA_STEP, "%s: orta zayıftan belirgin geniş" % gender)
	t.ge(float(areas[2]) / float(areas[1]), 1.0 + WEIGHT_AREA_STEP, "%s: kilolu ortadan belirgin geniş" % gender)
