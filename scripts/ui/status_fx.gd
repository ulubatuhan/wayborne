class_name StatusFx
extends Control

## Süren durumların bedenin *dışına* taşan kısmı: alev dilleri ve kıvılcım,
## yeşil hastalık sisi, buz kristalleri ve buhar, kan damlaları. Bedenin
## kendisindeki iz (kömürleşme, buz kabuğu, yeşil ten, kan izi)
## `condition.gdshader`'da - bu katman onu tamamlıyor.
##
## Kural: efekt bir merkezden yayılan bir ışıma değil, bedenin üstünden
## çıkıyor. Parçacıklar kolların, bacakların ve gövdenin boyunca örneklenen
## noktalara (`body_points`) oturuyor, figür oynadıkça onlarla oynuyor.
## Konumlar `WalkFigure.get_body_anchors`'tan; hayvanda kutunun içinde bir
## elips.
##
## İki örnek kullanılıyor: biri normal karışımla (sis, damla, kristal, duman),
## biri toplamalı karışımla (alev, köz, buzun parıltısı) - ışık gibi davranan
## şey ışık gibi toplanıyor. Parçacıklar Kenney Particle Pack (CC0,
## `tools/fx_assets.py`), beyaz; renk `ArtPalette.FX_*`'tan.

const FX_DIR: String = "res://data/assets/fx/"
const MODE_NORMAL: int = 0
const MODE_ADD: int = 1

## Kemik zincirleri: her biri iki eklem; noktalar aralarında örnekleniyor.
const BONES: Array = [
	["shoulder", "hip"], ["head", "shoulder"],
	["shoulder", "elbow_front"], ["elbow_front", "hand_front"],
	["shoulder", "elbow_back"], ["elbow_back", "hand_back"],
	["hip", "knee_front"], ["knee_front", "ankle_front"],
	["hip", "knee_back"], ["knee_back", "ankle_back"],
]

var mode: int = MODE_NORMAL
var _kinds: PackedStringArray = PackedStringArray()
var _h: float = 100.0
var _facing: float = 1.0
var _time: float = 0.0
var _source: WalkFigure = null

static var _cache: Dictionary = {}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_mode(value: int) -> void:
	mode = value
	if value == MODE_ADD:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

func setup(kinds: PackedStringArray, h: float, facing: float) -> void:
	_kinds = kinds
	_h = h
	_facing = facing
	visible = not kinds.is_empty()
	set_process(visible)
	queue_redraw()

func follow(source: WalkFigure) -> void:
	_source = source

func set_time(seconds: float) -> void:
	_time = seconds
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

static func texture(name: String) -> Texture2D:
	if not _cache.has(name):
		var path := FX_DIR + name + ".png"
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[name]

func _sprite(name: String, centre: Vector2, size_px: float, color: Color, angle: float = 0.0, stretch: Vector2 = Vector2.ONE) -> void:
	var tex := texture(name)
	if tex == null:
		return
	draw_set_transform(centre, angle, stretch)
	draw_texture_rect(tex, Rect2(Vector2(-size_px, -size_px) * 0.5, Vector2(size_px, size_px)), false, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _anchors() -> Dictionary:
	if _source != null and _source.visible:
		var live := _source.get_body_anchors()
		if not live.is_empty():
			var out := {}
			for k in live:
				out[k] = Vector2(live[k]) + _source.position
			return out
	return {}

## Bedenin üstünde örneklenmiş noktalar: her kemikte `per_bone` nokta, her
## biri {pos, up (0 ayak..1 baş), limb}. İskelet yoksa (hayvan) kutunun
## içinde bir elips. Saf: aynı eklemler hep aynı noktaları verir.
static func body_points(anchors: Dictionary, box: Vector2, per_bone: int) -> Array:
	var out: Array = []
	if anchors.has("shoulder") and anchors.has("hip"):
		var top: float = Vector2(anchors.get("head", anchors.shoulder)).y
		var bottom: float = maxf(Vector2(anchors.get("ankle_front", anchors.hip)).y, Vector2(anchors.get("ankle_back", anchors.hip)).y)
		var span := maxf(1.0, bottom - top)
		for bone in BONES:
			if not anchors.has(bone[0]) or not anchors.has(bone[1]):
				continue
			for i in per_bone:
				var t := (float(i) + 0.5) / float(per_bone)
				var p: Vector2 = Vector2(anchors[bone[0]]).lerp(anchors[bone[1]], t)
				out.append({"pos": p, "up": clampf((bottom - p.y) / span, 0.0, 1.0), "limb": String(bone[1])})
		return out
	var n := per_bone * 8
	for i in n:
		var a := TAU * float(i) / float(n)
		var p := Vector2(box.x * 0.5 + cos(a) * box.x * 0.26, box.y * 0.62 + sin(a) * box.y * 0.18)
		out.append({"pos": p, "up": clampf(1.0 - p.y / maxf(1.0, box.y), 0.0, 1.0), "limb": "body"})
	return out

## Noktaya özgü sabit sayı (0..1): her alevin ve sis bulutunun kendi
## fazı, boyu, kayması olsun - zar değil, sıra.
static func jitter(i: int, salt: float) -> float:
	return fposmod(sin(float(i) * 12.9898 + salt * 78.233) * 43758.5453, 1.0)

func _phase(period: float, offset: float) -> float:
	return fposmod(_time / period + offset, 1.0)

func _draw() -> void:
	var anchors := _anchors()
	var pts := body_points(anchors, size, 2)
	for kind in _kinds:
		match kind:
			CombatUnit.STATUS_BURN:
				if mode == MODE_ADD:
					_draw_flames(pts)
				else:
					_draw_smoke(anchors)
			CombatUnit.STATUS_BLIGHT:
				if mode == MODE_NORMAL:
					_draw_sickness(pts, anchors)
			CombatUnit.STATUS_CHILL:
				if mode == MODE_NORMAL:
					_draw_ice(pts, anchors)
				else:
					_draw_glints(pts)
			CombatUnit.STATUS_BLEED:
				if mode == MODE_NORMAL:
					_draw_blood(anchors)

func _head(anchors: Dictionary) -> Vector2:
	return Vector2(anchors.get("head", Vector2(size.x * 0.5, size.y * 0.3)))

# --- Yanma: bedenin her yerinden yükselen alev dilleri, uçuşan köz.
func _draw_flames(pts: Array) -> void:
	var flames := ["flame_01", "flame_02", "flame_03", "flame_04", "flame_05", "flame_06"]
	for i in pts.size():
		var p: Vector2 = pts[i].pos
		var j := jitter(i, 1.0)
		var flick := 0.75 + 0.25 * sin(_time * (10.0 + 6.0 * j) + j * 9.0)
		var size_px := _h * (0.09 + 0.07 * j) * flick
		var name: String = flames[(i + int(_time * (8.0 + 4.0 * j))) % flames.size()]
		var lean := sin(_time * 3.0 + j * 6.0) * 0.18
		var base := p - Vector2(0.0, size_px * 0.35)
		_sprite(name, base, size_px, Color(ArtPalette.FX_FIRE, 0.9), lean, Vector2(0.7, 1.0))
		_sprite(name, base + Vector2(0.0, size_px * 0.12), size_px * 0.6, Color(ArtPalette.FX_FIRE_CORE, 0.85), lean, Vector2(0.6, 1.0))
	for i in 10:
		var j := jitter(i, 4.0)
		var src: Vector2 = pts[(i * 3) % pts.size()].pos if not pts.is_empty() else size * 0.5
		var u := _phase(0.9 + j * 0.6, j)
		var drift := Vector2(sin(_time * 2.0 + j * 7.0) * _h * 0.04, -u * _h * (0.25 + 0.2 * j))
		_sprite("spark_05", src + drift, _h * 0.025, Color(ArtPalette.FX_FIRE_CORE, 1.0 - u))

func _draw_smoke(anchors: Dictionary) -> void:
	var top := _head(anchors) - Vector2(0.0, _h * 0.06)
	for i in 3:
		var u := _phase(2.4, float(i) / 3.0)
		_sprite("smoke_03", top + Vector2(-_facing * u * _h * 0.10, -u * _h * 0.28), _h * (0.10 + u * 0.16),
			Color(ArtPalette.FX_SMOKE, 0.40 * (1.0 - u)), u * 1.4 + i)

# --- Zehir: bedeni saran, yavaşça kalkan yeşil hastalık sisi; ağızda köpük.
func _draw_sickness(pts: Array, anchors: Dictionary) -> void:
	var sick := Color(0.42, 0.62, 0.16)
	for i in pts.size():
		var j := jitter(i, 2.0)
		var u := _phase(3.0 + 2.0 * j, j)
		var p: Vector2 = pts[i].pos + Vector2(sin(_time * 0.8 + j * 6.0) * _h * 0.02, -u * _h * 0.10)
		var a := 0.30 * sin(u * PI)
		_sprite("smoke_0%d" % (4 + i % 5), p, _h * (0.10 + 0.06 * j), Color(sick, a), j * 6.0 + _time * 0.3)
	var mouth := _head(anchors) + Vector2(_facing * _h * 0.05, _h * 0.03)
	for i in 4:
		var u := _phase(1.4, float(i) / 4.0)
		var p := mouth + Vector2(_facing * u * _h * 0.05 + sin(_time * 4.0 + i * 1.9) * _h * 0.01, -u * _h * 0.10)
		draw_arc(p, _h * (0.007 + 0.009 * u), 0.0, TAU, 12, Color(ArtPalette.FX_POISON, 0.9 * (1.0 - u)), maxf(1.0, _h * 0.004))
	var drip := _phase(1.8, 0.3)
	draw_circle(mouth + Vector2(0, drip * _h * 0.10), _h * 0.008, Color(ArtPalette.FX_POISON.darkened(0.3), 0.85 * (1.0 - drip)))

# --- Üşüme: uzuvlarda buz pulları ve sarkıtlar, ağızdan buhar.
func _draw_ice(pts: Array, anchors: Dictionary) -> void:
	var ice := Color(0.82, 0.93, 1.0, 0.85)
	var edge := Color(0.55, 0.72, 0.88, 0.9)
	for i in pts.size():
		var j := jitter(i, 3.0)
		if j < 0.35:
			continue
		var p: Vector2 = pts[i].pos + Vector2(_facing * _h * 0.02 * (j - 0.5), 0.0)
		var r := _h * (0.012 + 0.016 * j)
		# Küçük bir kristal kümesi: üç uzun sivri parça, kenarı koyu.
		for k in 3:
			var a := j * TAU + float(k) * TAU / 3.0
			var dir := Vector2.RIGHT.rotated(a)
			var side := Vector2(-dir.y, dir.x) * r * 0.35
			var shard := PackedVector2Array([p - side, p + dir * r * 1.8, p + side])
			draw_colored_polygon(shard, ice)
			draw_polyline(shard, edge, 1.0)
		# Kolların ve dizlerin altından sarkıt.
		if String(pts[i].limb) in ["hand_front", "hand_back", "elbow_front", "knee_front", "knee_back"]:
			var tip := p + Vector2(0.0, _h * (0.03 + 0.03 * j))
			draw_colored_polygon(PackedVector2Array([p - Vector2(r * 0.4, 0), p + Vector2(r * 0.4, 0), tip]), ice)
	var mouth := _head(anchors) + Vector2(_facing * _h * 0.06, _h * 0.02)
	var u := _phase(1.6, 0.0)
	_sprite("smoke_02", mouth + Vector2(_facing * u * _h * 0.12, -u * _h * 0.03), _h * (0.07 + u * 0.10),
		Color(0.92, 0.96, 1.0, 0.55 * (1.0 - u)), u)

func _draw_glints(pts: Array) -> void:
	for i in pts.size():
		var j := jitter(i, 5.0)
		var tw := maxf(0.0, sin(_time * (2.0 + 2.0 * j) + j * 20.0))
		if tw < 0.6:
			continue
		_sprite("star_06", pts[i].pos, _h * 0.05, Color(ArtPalette.FX_FROST, (tw - 0.6) * 2.2), j * 3.0)

# --- Kanama: yaradan ritimle düşen damlalar, ayakta büyüyen gölcük. Kumaşa
# işleyen iz shader'da.
func _draw_blood(anchors: Dictionary) -> void:
	if not anchors.has("shoulder") or not anchors.has("hip"):
		return
	var wound: Vector2 = wound_point(anchors, _h, _facing)
	var ground := maxf(Vector2(anchors.get("ankle_front", anchors.hip)).y, Vector2(anchors.get("ankle_back", anchors.hip)).y)
	var pool := 0.6 + 0.4 * minf(1.0, _time / 4.0)
	ArtDraw.ellipse(self, Vector2(wound.x, ground - _h * 0.004), Vector2(_h * 0.09 * pool, _h * 0.014 * pool), Color(0.30, 0.02, 0.03, 0.85))
	ArtDraw.ellipse(self, Vector2(wound.x - _h * 0.02, ground - _h * 0.006), Vector2(_h * 0.03, _h * 0.006), Color(0.55, 0.10, 0.10, 0.6))
	for i in 3:
		var u := _phase(1.1, float(i) / 3.0)
		var start := wound + Vector2(_facing * _h * (0.005 + 0.008 * i), _h * 0.12)
		var p := start + Vector2(0.0, (ground - start.y) * u * u)
		var r := _h * 0.009
		draw_circle(p, r, Color(0.45, 0.03, 0.04, 0.95))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.7, 0), p + Vector2(r * 0.7, 0), p - Vector2(0, r * 2.4)]), Color(0.45, 0.03, 0.04, 0.95))

## Yaranın yeri: gövdenin ön yüzünde, göğüs ile bel arası. Shader'ın kan
## izi de buradan başlıyor - iki yerde iki ayrı yara olmasın.
static func wound_point(anchors: Dictionary, h: float, facing: float) -> Vector2:
	return Vector2(anchors.shoulder).lerp(anchors.hip, 0.40) + Vector2(facing * h * 0.035, 0.0)
