class_name StatusFx
extends Control

## Süren durumların bedenin üstündeki izi: kanama damlıyor, yanan alev
## alıyor, zehirlenenin başında yeşil bir duman, üşüyenin üstünde kırağı.
## Halka (`CombatFigure.set_ring`) bir durumun *uygulandığı anı* söylüyor;
## bu katman durum sürdükçe orada kalıyor - simgenin yanında, bedenin
## kendisinde. Figürün en üst çocuğu; konumları `WalkFigure.get_body_anchors`
## veriyor, hayvanlarda kutunun oranları.
##
## Parçacıklar Kenney Particle Pack'ten (CC0, `tools/fx_assets.py`), beyaz
## ve renksiz; renk `ArtPalette.FX_*`'tan çarpılıyor. Hareket saf bir zaman
## fonksiyonu (`_phase`), sahne durumu tutmuyor (Motion Rules).

const FX_DIR: String = "res://data/assets/fx/"

var _kinds: PackedStringArray = PackedStringArray()
var _anchors: Dictionary = {}
## Canlı kaynak: figür oynarken (darbe, çırpınma) eklemler her karede
## değişiyor; kaynak verilmişse konumlar her çizimde ondan okunuyor.
var _source: WalkFigure = null
var _h: float = 100.0
var _facing: float = 1.0
var _time: float = 0.0
var _reduce_motion: bool = false

static var _cache: Dictionary = {}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## `anchors` figürün uzayında (shoulder, hip, head, ankle_front...); boşsa
## kutudan türetiliyor.
func setup(kinds: PackedStringArray, anchors: Dictionary, h: float, facing: float) -> void:
	_kinds = kinds
	_anchors = anchors
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

## Bir parçacığı merkezinden, `scale` boyunda (piksel), dönüklükle çizer.
func _sprite(name: String, centre: Vector2, size_px: float, color: Color, angle: float = 0.0) -> void:
	var tex := texture(name)
	if tex == null:
		return
	draw_set_transform(centre, angle, Vector2.ONE)
	draw_texture_rect(tex, Rect2(Vector2(-size_px, -size_px) * 0.5, Vector2(size_px, size_px)), false, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _anchor(name: String) -> Vector2:
	if _source != null and _source.visible:
		var live := _source.get_body_anchors()
		if live.has(name):
			return Vector2(live[name]) + _source.position
	if _anchors.has(name):
		return _anchors[name]
	# Hayvan ya da iskeletsiz figür: kutunun oranlarından.
	match name:
		"head": return Vector2(size.x * 0.5 + _facing * size.x * 0.12, size.y * 0.30)
		"shoulder": return Vector2(size.x * 0.5, size.y * 0.42)
		"hip": return Vector2(size.x * 0.5, size.y * 0.62)
		"ankle_front": return Vector2(size.x * 0.5 + _facing * size.x * 0.1, size.y * 0.93)
		"ankle_back": return Vector2(size.x * 0.5 - _facing * size.x * 0.1, size.y * 0.93)
	return size * 0.5

## Döngüdeki yer (0..1): her parçacık kendi kaydırmasıyla.
func _phase(period: float, offset: float) -> float:
	return fposmod(_time / period + offset, 1.0)

func _draw() -> void:
	for kind in _kinds:
		match kind:
			CombatUnit.STATUS_BLEED: _draw_bleed()
			CombatUnit.STATUS_BURN: _draw_burn()
			CombatUnit.STATUS_BLIGHT: _draw_poison()
			CombatUnit.STATUS_CHILL: _draw_chill()

# --- Kanama: yarada koyu leke, gövdeden yere düşen damlalar, ayakta gölcük.
func _draw_bleed() -> void:
	var wound := _anchor("shoulder").lerp(_anchor("hip"), 0.45) + Vector2(_facing * _h * 0.035, 0.0)
	var ground := maxf(_anchor("ankle_front").y, _anchor("ankle_back").y)
	_sprite("dirt_02", wound, _h * 0.15, Color(ArtPalette.FX_BLOOD, 0.95), 0.6)
	_sprite("dirt_03", wound + Vector2(0, _h * 0.06), _h * 0.09, Color(ArtPalette.FX_BLOOD, 0.8), 2.0)
	ArtDraw.ellipse(self, Vector2(wound.x, ground - _h * 0.004), Vector2(_h * 0.08, _h * 0.014), Color(ArtPalette.FX_BLOOD, 0.65))
	for i in 3:
		var u := _phase(0.9, float(i) / 3.0)
		var p := wound + Vector2(_facing * _h * (0.01 + 0.01 * i), lerpf(0.0, ground - wound.y, u * u))
		var r := _h * 0.014 * (1.0 - 0.3 * u)
		draw_circle(p, r, Color(ArtPalette.FX_BLOOD, 0.9 * (1.0 - u * 0.4)))
		draw_circle(p - Vector2(0, r * 0.9), r * 0.6, Color(ArtPalette.FX_BLOOD, 0.7 * (1.0 - u * 0.4)))

# --- Yanma: bacaklardan ve gövdeden yükselen alev dilleri, kıvılcım, duman.
func _draw_burn() -> void:
	var points := [
		_anchor("hip").lerp(_anchor("ankle_front"), 0.55), _anchor("hip"),
		_anchor("shoulder").lerp(_anchor("hip"), 0.4), _anchor("shoulder"),
		_anchor("hip").lerp(_anchor("ankle_back"), 0.5),
	]
	_sprite("light_01", _anchor("shoulder").lerp(_anchor("hip"), 0.6), _h * 0.7,
		Color(ArtPalette.FX_FIRE, 0.22 + 0.06 * sin(_time * 9.0)))
	var flames := ["flame_01", "flame_02", "flame_03", "flame_04", "flame_05", "flame_06"]
	for i in points.size():
		var flick := 0.85 + 0.15 * sin(_time * 13.0 + float(i) * 1.7)
		var base: Vector2 = points[i]
		var size_px := _h * (0.28 if i < 3 else 0.20) * flick
		var name: String = flames[(i + int(_time * 9.0)) % flames.size()]
		_sprite(name, base - Vector2(0, size_px * 0.30), size_px, Color(ArtPalette.FX_FIRE, 0.85))
		_sprite(name, base - Vector2(0, size_px * 0.22), size_px * 0.55, Color(ArtPalette.FX_FIRE_CORE, 0.8))
	for i in 5:
		var u := _phase(1.1, float(i) / 5.0)
		var p := _anchor("shoulder").lerp(_anchor("hip"), 0.5) + Vector2(sin(float(i) * 2.3 + _time * 3.0) * _h * 0.06, -u * _h * 0.45)
		_sprite("spark_05", p, _h * 0.035, Color(ArtPalette.FX_FIRE_CORE, 1.0 - u))
	var top := _anchor("head") - Vector2(0, _h * 0.10)
	for i in 2:
		var u := _phase(2.2, float(i) * 0.5)
		_sprite("smoke_03", top - Vector2(-_facing * u * _h * 0.08, u * _h * 0.22), _h * (0.10 + u * 0.14),
			Color(ArtPalette.FX_SMOKE, 0.45 * (1.0 - u)), u * 1.4)

# --- Zehir: başın çevresinde yeşil duman, ağızdan kabarcıklar.
func _draw_poison() -> void:
	var head := _anchor("head")
	for i in 3:
		var u := _phase(2.6, float(i) / 3.0)
		var p := head + Vector2(_facing * _h * 0.04 + sin(_time * 1.3 + i) * _h * 0.05, -u * _h * 0.25)
		_sprite("smoke_07", p, _h * (0.12 + u * 0.14), Color(ArtPalette.FX_POISON, 0.40 * (1.0 - u)), _time * 0.4 + i)
	var mouth := head + Vector2(_facing * _h * 0.05, _h * 0.03)
	for i in 4:
		var u := _phase(1.4, float(i) / 4.0)
		var p := mouth + Vector2(_facing * u * _h * 0.05 + sin(_time * 4.0 + i * 1.9) * _h * 0.01, -u * _h * 0.12)
		var r := _h * (0.008 + 0.010 * u)
		draw_arc(p, r, 0.0, TAU, 12, Color(ArtPalette.FX_POISON, 0.9 * (1.0 - u)), maxf(1.0, _h * 0.004))
	var drip_u := _phase(1.8, 0.3)
	draw_circle(mouth + Vector2(0, drip_u * _h * 0.10), _h * 0.008, Color(ArtPalette.FX_POISON.darkened(0.2), 0.8 * (1.0 - drip_u)))

# --- Üşüme: bedende kırağı kristalleri, ağızdan buhar.
func _draw_chill() -> void:
	var spots := [
		_anchor("shoulder"), _anchor("shoulder").lerp(_anchor("hip"), 0.5), _anchor("hip"),
		_anchor("hip").lerp(_anchor("ankle_front"), 0.6), _anchor("head") + Vector2(0, -_h * 0.04),
	]
	_sprite("light_03", _anchor("shoulder").lerp(_anchor("hip"), 0.5), _h * 0.75, Color(ArtPalette.FX_FROST, 0.20))
	for i in spots.size():
		var glint := 0.6 + 0.4 * sin(_time * 2.0 + float(i) * 1.3)
		_sprite("star_06" if i % 2 == 0 else "star_08", spots[i] + Vector2(_facing * _h * 0.03, 0),
			_h * 0.12, Color(ArtPalette.FX_FROST, 0.9 * glint), float(i))
	var mouth := _anchor("head") + Vector2(_facing * _h * 0.06, _h * 0.02)
	var u := _phase(1.6, 0.0)
	_sprite("smoke_02", mouth + Vector2(_facing * u * _h * 0.12, -u * _h * 0.03), _h * (0.08 + u * 0.10),
		Color(0.92, 0.96, 1.0, 0.55 * (1.0 - u)), u)
