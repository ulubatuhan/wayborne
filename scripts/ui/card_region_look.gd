class_name CardRegionLook
extends Control

## Olay kartının resminin bölgeye göre görünüşü (görev Y-G20). Kullanıcı notu:
## "Bölgeye göre farklılık olmalı, karta göre de farklılık olmasın." Kartın
## türü resmin dilini değiştirmez; kervanın bulunduğu bölge değiştirir: göğün
## rengi, resmin tonu, üstüne düşen örtü ve çerçevenin deseni. Veba o bölgede
## bir dünya hâliyse kart açılmadan resim zaten solmuş görünür (Y-C25).
##
## Renkler soğuk ve soluk (tek sıcak kaynak kuralı, kurallar-sanat): güneyin
## tozu bile doygun değil. Gokyurt kıtanın en sağlıklı yeri; resmi en açık o.
## Bu düğüm resmin üstüne serilen örtü ve çerçevedir; ton ve gök rengini
## resmi çizen (EventVignette, TextureRect) `look_for` ile okur.

enum Frame { DOUBLE, STITCH, NOTCH, BROKEN, DOT, DIAMOND, PLAIN }

const LOOKS: Dictionary = {
	"gocebe": {
		"sky_top": Color(0.27, 0.33, 0.42), "sky_bottom": Color(0.66, 0.69, 0.66),
		"tint": Color(1.03, 1.03, 1.0), "wash": Color(0.70, 0.76, 0.80), "wash_alpha": 0.04,
		"frame": Frame.STITCH,
	},
	"vadi": {
		"sky_top": Color(0.21, 0.22, 0.19), "sky_bottom": Color(0.50, 0.50, 0.40),
		"tint": Color(0.88, 0.90, 0.78), "wash": Color(0.40, 0.42, 0.29), "wash_alpha": 0.16,
		"frame": Frame.PLAIN,
	},
	"dag": {
		"sky_top": Color(0.16, 0.19, 0.25), "sky_bottom": Color(0.50, 0.55, 0.62),
		"tint": Color(0.84, 0.90, 1.0), "wash": Color(0.30, 0.36, 0.46), "wash_alpha": 0.14,
		"frame": Frame.NOTCH,
	},
	"dag_maden": {
		"sky_top": Color(0.13, 0.14, 0.17), "sky_bottom": Color(0.42, 0.44, 0.48),
		"tint": Color(0.78, 0.82, 0.90), "wash": Color(0.16, 0.17, 0.20), "wash_alpha": 0.20,
		"frame": Frame.NOTCH,
	},
	"sinir": {
		"sky_top": Color(0.15, 0.14, 0.14), "sky_bottom": Color(0.46, 0.42, 0.38),
		"tint": Color(0.82, 0.80, 0.78), "wash": Color(0.20, 0.18, 0.17), "wash_alpha": 0.20,
		"frame": Frame.BROKEN,
	},
	"imparatorluk": {
		"sky_top": Color(0.20, 0.21, 0.24), "sky_bottom": Color(0.56, 0.56, 0.57),
		"tint": Color(0.88, 0.88, 0.91), "wash": Color(0.46, 0.47, 0.50), "wash_alpha": 0.12,
		"frame": Frame.DOUBLE,
	},
	"guney": {
		"sky_top": Color(0.24, 0.24, 0.26), "sky_bottom": Color(0.64, 0.60, 0.53),
		"tint": Color(0.95, 0.92, 0.86), "wash": Color(0.55, 0.51, 0.43), "wash_alpha": 0.10,
		"frame": Frame.DOT,
	},
	"ahit": {
		"sky_top": Color(0.30, 0.31, 0.34), "sky_bottom": Color(0.72, 0.72, 0.70),
		"tint": Color(0.92, 0.92, 0.94), "wash": Color(0.80, 0.80, 0.80), "wash_alpha": 0.14,
		"frame": Frame.DIAMOND,
	},
}
const DEFAULT_REGION: String = "imparatorluk"
## Vebanın resme kattığı: ton yeşil-griye kayar, örtü kalınlaşır.
const PLAGUE_TINT: Color = Color(0.90, 0.92, 0.84)
const PLAGUE_WASH: Color = Color(0.36, 0.40, 0.30)
const PLAGUE_WASH_ALPHA: float = 0.14
const INK: Color = Color(0.05, 0.04, 0.03, 0.9)

var look: Dictionary = {}

## Bölgenin görünüşü; veba varsa solmuş hâli. Bilinmeyen bölge varsayılana düşer.
static func look_for(region: String, plague: bool) -> Dictionary:
	var base: Dictionary = (LOOKS.get(region, LOOKS[DEFAULT_REGION]) as Dictionary).duplicate()
	base["region"] = region if LOOKS.has(region) else DEFAULT_REGION
	base["plague"] = plague
	if plague:
		base["tint"] = Color(base.tint) * PLAGUE_TINT
		base["wash"] = Color(base.wash).lerp(PLAGUE_WASH, 0.6)
		base["wash_alpha"] = float(base.wash_alpha) + PLAGUE_WASH_ALPHA
	return base

## Örtü ve çerçeve düğümü: resmin üstüne, aynı boyda serilir.
static func overlay(look_data: Dictionary) -> CardRegionLook:
	var node := CardRegionLook.new()
	node.look = look_data
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	return node

func _draw() -> void:
	if look.is_empty() or size.x < 8.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(Color(look.wash), float(look.wash_alpha)))
	_draw_frame(int(look.frame))

func _draw_frame(frame: int) -> void:
	var r := Rect2(Vector2.ZERO, size)
	var corners: Array[Vector2] = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	match frame:
		Frame.DOUBLE:
			draw_rect(r, INK, false, 2.0)
			draw_rect(r.grow(-5.0), Color(INK, 0.6), false, 1.0)
		Frame.STITCH:
			draw_rect(r, INK, false, 2.0)
			_dashed_rect(r.grow(-5.0), 7.0, 5.0, Color(INK, 0.55), 1.2)
		Frame.NOTCH:
			draw_rect(r, INK, false, 2.0)
			for corner in corners:
				var inward: Vector2 = (r.get_center() - corner).sign()
				draw_line(corner + Vector2(inward.x * 12.0, 0), corner + inward * 12.0, INK, 2.0)
				draw_line(corner + Vector2(0, inward.y * 12.0), corner + inward * 12.0, INK, 2.0)
		Frame.BROKEN:
			_dashed_rect(r, 46.0, 9.0, INK, 2.0)
		Frame.DOT:
			draw_rect(r, INK, false, 2.0)
			_dashed_rect(r.grow(-5.0), 1.6, 6.0, Color(INK, 0.6), 1.6)
		Frame.DIAMOND:
			draw_rect(r, INK, false, 2.0)
			for corner in corners:
				var c: Vector2 = corner + (r.get_center() - corner).sign() * 10.0
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(0, -4), c + Vector2(4, 0), c + Vector2(0, 4), c + Vector2(-4, 0),
				]), Color(INK, 0.7))
		_:
			draw_rect(r, INK, false, 2.0)

func _dashed_rect(r: Rect2, dash: float, gap: float, color: Color, width: float) -> void:
	var corners: Array[Vector2] = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var length := a.distance_to(b)
		var dir := (b - a) / maxf(length, 0.001)
		var at := 0.0
		while at < length:
			draw_line(a + dir * at, a + dir * minf(at + dash, length), color, width)
			at += dash + gap
