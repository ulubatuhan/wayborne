class_name SurvivalGauge
extends Control

## Hayati gösterge: bir sayı çubuğu değil, organik bir nesne. Üç biçim:
##
## - VIAL: cam şişede sıvı. Değer düştükçe sıvı çekilir, durum kötüleştikçe
##   sıvı çekilir ve çalkalanır (moral, açlık, yorgunluk). Cam çatlağı
##   kullanıcı isteğiyle kaldırıldı (görev 2.5): yıpranma sayıda ve sıvı
##   seviyesinde okunuyor.
## - FLAME: fitil. Değer düştükçe alev küçülür, mavileşir ve titrer
##   (sıcaklık/soğuk).
## - STAIN: kan lekesi. Değer büyüdükçe leke yayılır (tehlike).
## - PICTURE: parşömen kartta gravür bir resim, üç hâl (yüksek/orta/düşük):
##   moral meşale, stres dikenli sarmaşık, takat at, tehlike kuzgunlar. Yol
##   ekranı bunu kullanıyor; şişe ve leke kullanıcı kararıyla yoldan kalktı
##   (2026-10-22, "şişe istemiyorum"). Resim değerin kelimesiyle aynı eşikte
##   değişiyor (`Wording.band`), yani ipucundaki söz ile resim hep birlikte
##   döner. Mürekkep kuzgun koyu taşın üstünde kayboluyordu; eskimiş bronz bir
##   madalyon ona açık bir zemin veriyor (`tools/gauge_icons.py`; resim ve
##   madalyon aynı kare tuvalde, aynı dikdörtgene çiziliyor).
##
## **Sayı kaybolmuyor.** Bu proje sayısal şeffaflığı bilerek seçti (Waybook
## UI Rules: "HP gets a sifat next to the number, never in place of it");
## nesne aynı gerçeğin ikinci okuması, yerine geçen değil. Bütün eğriler
## statik ve saf (Motion Rules), test aynı sayıları okuyor.

enum Kind { VIAL, FLAME, STAIN, PICTURE }

const SIZE: Vector2 = Vector2(64, 92)
## Resimli göstergenin madalyonu kare; boyu öbürleriyle aynı, sayılar aynı hizada kalsın.
const PICTURE_SIZE: Vector2 = Vector2(92, 92)
const PICTURE_DIR: String = "res://data/assets/ui/gauges/"
const PICTURE_STATES: Array[String] = ["low", "mid", "high"]
## Kelimenin dört kademesinden resmin üç hâline (ortadaki iki kademe aynı resim).
const BAND_TO_PICTURE: Array[int] = [0, 1, 1, 2]
const PICTURE_FADE_SECONDS: float = 0.6
const NUMBER_HEIGHT: float = 18.0
const FLAME_MIN_SHARE: float = 0.12

var kind: Kind = Kind.VIAL
var colour: Color = ArtPalette.UI_GAUGE_MORALE
var label_text: String = ""
## true: düşük değer kötü (moral, sıcaklık). false: yüksek değer kötü (tehlike).
var bad_when_low: bool = true
var value: float = 100.0
## Doluluk yerine yazılacak sayı ("−4 °C" gibi). Boşsa değerin kendisi.
var number_text: String = ""
var max_value: float = 100.0
## Ortalamanın yanında tek bir kişinin değeri (bkz. Stress Rules: şişede en
## yıpranmış kişinin çentiği). Negatifse çentik yok.
var marker_value: float = -1.0
var _marker_note: String = ""
var _time: float = 0.0
var _redraw_wait: float = 0.0
var _seed: float = 0.0
## PICTURE: resmin kimliği ("morale" gibi), şimdiki ve önceki hâl, geçişin başı.
var picture_id: String = ""
var _picture_state: int = -1
var _prev_picture_state: int = -1
var _picture_switch_time: float = -100.0
static var _picture_cache: Dictionary = {}

func _init() -> void:
	custom_minimum_size = SIZE + Vector2(0, NUMBER_HEIGHT * 2.0)
	mouse_filter = Control.MOUSE_FILTER_PASS

func setup(gauge_kind: Kind, fill: Color, text: String, low_is_bad: bool = true) -> SurvivalGauge:
	kind = gauge_kind
	colour = fill
	label_text = text
	bad_when_low = low_is_bad
	_seed = float(hash(text) % 1000) / 97.0
	tooltip_text = text
	return self

## Resimli gösterge: `id` resim dosyalarının adı (`<id>_<low|mid|high>.png`).
func setup_picture(id: String, text: String, low_is_bad: bool = true) -> SurvivalGauge:
	setup(Kind.PICTURE, ArtPalette.GRIM_PARCHMENT, text, low_is_bad)
	picture_id = id
	custom_minimum_size = PICTURE_SIZE + Vector2(0, NUMBER_HEIGHT * 2.0)
	_picture_state = picture_state(value, max_value)
	return self

func set_value(new_value: float, new_max: float = 100.0) -> void:
	value = new_value
	max_value = new_max
	if kind == Kind.PICTURE:
		var state := picture_state(value, max_value)
		if state != _picture_state:
			_prev_picture_state = _picture_state
			_picture_state = state
			_picture_switch_time = _time
	queue_redraw()

## Değerin resmi: 0 düşük, 1 orta, 2 yüksek - değerin kendisi, iyi ya da kötü
## olması değil (yüksek stres en sıkı düğüm, yüksek tehlike üç kuzgun).
static func picture_state(v: float, max_v: float) -> int:
	return BAND_TO_PICTURE[Wording.band(v, max_v)]

static func picture_path(id: String, state: int) -> String:
	return PICTURE_DIR + "%s_%s.png" % [id, PICTURE_STATES[clampi(state, 0, 2)]]

static func picture_texture(file_path: String) -> Texture2D:
	if not _picture_cache.has(file_path):
		_picture_cache[file_path] = TextureLoader.load_any(file_path)
	return _picture_cache[file_path]

## Geçişte yeni resmin görünürlüğü: 0'dan 1'e, uçlarda tam (Motion Rules).
static func picture_fade(since_switch: float) -> float:
	return clampf(since_switch / PICTURE_FADE_SECONDS, 0.0, 1.0)

func set_marker(new_value: float, note: String = "") -> void:
	marker_value = new_value
	_marker_note = note if new_value >= 0.0 else ""
	_refresh_tooltip()
	queue_redraw()

## Y-H03: ipucu sözle başlar ("Moral düşük: 2 gündür aç"), sayı ikinci satırda.
var _reason: String = ""

func set_reason(text: String) -> void:
	_reason = text
	_refresh_tooltip()

func _refresh_tooltip() -> void:
	var head := label_text if _reason.is_empty() else _reason
	tooltip_text = head if _marker_note.is_empty() else head + "\n" + _marker_note

func is_marker_visible() -> bool:
	return marker_value >= 0.0

## Ekran görüntüsü ve test için zamanı elle sürmek.
func set_time(t: float) -> void:
	_time = t
	queue_redraw()

## Ortam animasyonu: zaman hep akar, ama görünmezken çizilmez ve en çok
## `NodeUtil.AMBIENT_REDRAW_HZ` kez çizilir (görev 5.1, O-8).
func _process(delta: float) -> void:
	_time += delta
	_redraw_wait = NodeUtil.ambient_redraw(self, _redraw_wait, delta)

## Sıcaklık göstergesi Celsius okur: alev −25 °C'de sönmeye yakın, 30 °C'de
## tam. Sayı derecenin kendisi (Ana Hedefler: sıcaklık mekaniği).
const CELSIUS_MIN: float = -25.0
const CELSIUS_MAX: float = 30.0

static func celsius_fraction(c: float) -> float:
	return clampf((c - CELSIUS_MIN) / (CELSIUS_MAX - CELSIUS_MIN), 0.0, 1.0)

static func celsius_text(c: float) -> String:
	return Temperature.round_text(c)

func set_celsius(c: float) -> void:
	value = celsius_fraction(c) * 100.0
	max_value = 100.0
	number_text = celsius_text(c)
	queue_redraw()

static func fill_fraction(v: float, max_v: float) -> float:
	return clampf(v / maxf(max_v, 0.001), 0.0, 1.0)

## 0 = iyi, 1 = en kötü.
static func severity(fraction: float, low_is_bad: bool) -> float:
	return 1.0 - fraction if low_is_bad else fraction

## Sıvı yüzeyinin dalgası: dolu şişe sakin, boşalan şişe çalkalanır.
static func meniscus(x_share: float, t: float, sev: float) -> float:
	return sin(x_share * TAU * 1.5 + t * 2.4) * (0.8 + 2.4 * sev)

## Alevin boyu, kısa bir titremeyle. Değer sıfırdayken bile köz kalır.
static func flame_height(fraction: float, t: float, seed_value: float = 0.0) -> float:
	var flicker := 0.08 * sin(t * 11.0 + seed_value) + 0.05 * sin(t * 23.0 + seed_value * 2.0)
	var base := lerpf(FLAME_MIN_SHARE, 1.0, fraction)
	return clampf(base * (1.0 + flicker * (1.6 - fraction)), 0.05, 1.1)

## Alevin rengi: ılık kehribar, soğudukça buz mavisi.
static func flame_colour(fraction: float) -> Color:
	return ArtPalette.GRIM_FROST.lerp(ArtPalette.GRIM_AMBER, clampf(fraction * 1.3, 0.0, 1.0))

func _draw() -> void:
	var frac := fill_fraction(value, max_value)
	var sev := severity(frac, bad_when_low)
	var box_size := PICTURE_SIZE if kind == Kind.PICTURE else SIZE
	var box := Rect2(Vector2((size.x - box_size.x) * 0.5, 0), box_size)
	match kind:
		Kind.VIAL:
			_draw_vial(box, frac, sev)
		Kind.FLAME:
			_draw_flame(box, frac)
		Kind.STAIN:
			_draw_stain(box, frac)
		Kind.PICTURE:
			_draw_picture(box, frac)
	_draw_number(box, sev)

func _vial_shape(box: Rect2) -> PackedVector2Array:
	var c := box.get_center()
	var body := Rect2(box.position + Vector2(box.size.x * 0.18, box.size.y * 0.30),
		Vector2(box.size.x * 0.64, box.size.y * 0.66))
	var neck_w := box.size.x * 0.22
	var pts := PackedVector2Array()
	pts.append(Vector2(c.x - neck_w * 0.5, box.position.y + box.size.y * 0.06))
	pts.append(Vector2(c.x + neck_w * 0.5, box.position.y + box.size.y * 0.06))
	pts.append(Vector2(c.x + neck_w * 0.5, body.position.y))
	pts.append(Vector2(body.end.x, body.position.y + body.size.y * 0.16))
	pts.append(Vector2(body.end.x, body.end.y - 6))
	pts.append(Vector2(body.end.x - 6, body.end.y))
	pts.append(Vector2(body.position.x + 6, body.end.y))
	pts.append(Vector2(body.position.x, body.end.y - 6))
	pts.append(Vector2(body.position.x, body.position.y + body.size.y * 0.16))
	pts.append(Vector2(c.x - neck_w * 0.5, body.position.y))
	return pts

func _draw_vial(box: Rect2, frac: float, sev: float) -> void:
	var shape := _vial_shape(box)
	draw_colored_polygon(shape, Color(ArtPalette.GRIM_CHARCOAL, 0.9))
	var top := box.position.y + box.size.y * 0.30
	var bottom := box.end.y
	var level := lerpf(bottom, top, frac)
	var fluid := PackedVector2Array()
	var left := box.position.x + box.size.x * 0.18 + 2
	var right := box.end.x - box.size.x * 0.18 - 2
	var steps := 10
	for i in steps + 1:
		var share := float(i) / steps
		fluid.append(Vector2(lerpf(left, right, share), level + meniscus(share, _time + _seed, sev)))
	fluid.append(Vector2(right, bottom - 2))
	fluid.append(Vector2(left, bottom - 2))
	if frac > 0.01:
		var clipped := Geometry2D.intersect_polygons(fluid, shape)
		for poly in clipped:
			draw_colored_polygon(poly, Color(colour.darkened(0.25), 0.92))
		# Sıvının üst kenarındaki parlaklık.
		draw_line(fluid[0], fluid[steps], Color(colour.lightened(0.35), 0.7), 1.5)
	var glass := shape.duplicate()
	glass.append(shape[0])
	draw_polyline(glass, Color(ArtPalette.GRIM_SLATE_LIGHT, 0.85), 1.6, true)
	draw_line(Vector2(left + 3, top + 10), Vector2(left + 3, bottom - 10), Color(1, 1, 1, 0.12), 2.0)
	if marker_value >= 0.0:
		var mark_y := lerpf(bottom, top, fill_fraction(marker_value, max_value))
		draw_line(Vector2(left - 5, mark_y), Vector2(right + 5, mark_y), ArtPalette.UI_SIGNAL_ESCALATED, 2.0)

func _draw_flame(box: Rect2, frac: float) -> void:
	var base := Vector2(box.get_center().x, box.end.y - 10)
	var glow := GrimTheme.texture("lantern_glow.png")
	if glow != null and frac > 0.02:
		var r := box.size.x * (0.6 + 0.7 * frac)
		draw_texture_rect(glow, Rect2(base - Vector2(r, r * 1.3), Vector2(r * 2, r * 2)), false,
			Color(1, 1, 1, 0.25 + 0.5 * frac))
	# Mum gövdesi ve tabak (demir).
	draw_rect(Rect2(base + Vector2(-9, 0), Vector2(18, 10)), ArtPalette.GRIM_PARCHMENT_DIM)
	draw_rect(Rect2(base + Vector2(-16, 8), Vector2(32, 4)), ArtPalette.GRIM_IRON)
	var h := flame_height(frac, _time, _seed) * box.size.y * 0.62
	var w := 10.0 + 6.0 * frac
	var sway := sin(_time * 3.1 + _seed) * 2.5 * (1.2 - frac)
	var outer := PackedVector2Array([
		base, base + Vector2(-w, -h * 0.35), base + Vector2(-w * 0.45 + sway, -h * 0.8),
		base + Vector2(sway * 1.6, -h), base + Vector2(w * 0.45 + sway, -h * 0.8),
		base + Vector2(w, -h * 0.35),
	])
	var col := flame_colour(frac)
	draw_colored_polygon(outer, Color(col, 0.9))
	var inner := PackedVector2Array()
	for p in outer:
		inner.append(base + (p - base) * Vector2(0.5, 0.62))
	draw_colored_polygon(inner, Color(col.lightened(0.5), 0.95))
	draw_line(base, base + Vector2(0, -4), ArtPalette.INK, 2.0)

func _draw_stain(box: Rect2, frac: float) -> void:
	var c := box.get_center() + Vector2(0, 6)
	draw_circle(c, box.size.x * 0.44, Color(ArtPalette.GRIM_CHARCOAL, 0.85))
	draw_arc(c, box.size.x * 0.44, 0, TAU, 32, Color(ArtPalette.GRIM_RUST, 0.8), 1.2)
	var r := box.size.x * 0.40 * sqrt(frac)
	var blood := Color(ArtPalette.GRIM_CRIMSON, 0.92)
	for i in 7:
		var ang := float(i) / 7.0 * TAU + _seed
		var off := Vector2(cos(ang), sin(ang)) * r * 0.45
		draw_circle(c + off, r * (0.45 + 0.15 * sin(ang * 3.0)), blood)
	draw_circle(c, r * 0.7, blood.darkened(0.2))
	# Dışarı sızan damlalar, yalnızca tehlike yüksekken.
	if frac > 0.55:
		for i in 3:
			var ang := _seed * 2.0 + float(i) * 2.1
			draw_circle(c + Vector2(cos(ang), sin(ang)) * (r + 6.0), 2.5, blood)

func _draw_picture(box: Rect2, _frac: float) -> void:
	var medallion := picture_texture(PICTURE_DIR + "medallion.png")
	if medallion != null:
		draw_texture_rect(medallion, box, false)
	else:
		draw_circle(box.get_center(), box.size.x * 0.5, ArtPalette.GRIM_PARCHMENT_DIM)
	var fade := picture_fade(_time - _picture_switch_time)
	if fade < 1.0 and _prev_picture_state >= 0:
		_draw_picture_state(box, _prev_picture_state, 1.0 - fade)
	_draw_picture_state(box, _picture_state, fade if _prev_picture_state >= 0 else 1.0)
	if marker_value >= 0.0:
		# Ortalamadan ayrışan kişinin değeri: madalyonun sağında kızıl bir çivi,
		# yüksekliği değeri.
		var y := lerpf(box.end.y - 6.0, box.position.y + 6.0, fill_fraction(marker_value, max_value))
		var x := box.end.x + 1.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 8, y), Vector2(x + 3, y - 5), Vector2(x + 3, y + 5)]),
			ArtPalette.UI_SIGNAL_ESCALATED)
	if fade < 1.0:
		queue_redraw()

func _draw_picture_state(box: Rect2, state: int, alpha: float) -> void:
	if alpha <= 0.0 or picture_id.is_empty():
		return
	var tex := picture_texture(picture_path(picture_id, state))
	if tex != null:
		draw_texture_rect(tex, box, false, Color(1, 1, 1, alpha))

func _draw_number(box: Rect2, sev: float) -> void:
	var font := WaybookTheme.get_font()
	var y := box.end.y + NUMBER_HEIGHT - 2
	var col := ArtPalette.GRIM_PARCHMENT if sev < 0.6 else ArtPalette.GRIM_CRIMSON.lightened(0.25)
	var number := number_text if number_text != "" else "%d" % roundi(value)
	var nw := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(font, Vector2(box.get_center().x - nw * 0.5, y), number,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
	var tw := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, Vector2(box.get_center().x - tw * 0.5, y + NUMBER_HEIGHT - 2), label_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ArtPalette.GRIM_PARCHMENT_DIM)
