class_name MarketMeter
extends Control

## Bir malın pazardaki hâli tek satırda: stok (kıtlık çentikleri) ve fiyat
## baskısı (enflasyon oku). Veri MarketConditions'ın zaten tuttuğu sayılar -
## stok/doluluk ve fiyat çarpanı; bu bileşen yeni bir ekonomi icat etmiyor.

const NOTCHES: int = 8
## Bu kadar sapma okun tam boyu.
const FULL_PRESSURE: float = 0.5

var stock_share: float = 0.5
var price_multiplier: float = 1.0
var shocked: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(150, 26)
	mouse_filter = Control.MOUSE_FILTER_PASS

func set_state(stock: float, multiplier: float, is_shocked: bool = false) -> void:
	stock_share = clampf(stock, 0.0, 1.0)
	price_multiplier = multiplier
	shocked = is_shocked
	tooltip_text = "%s · %s" % [tr(scarcity_key(stock_share)), "x%.2f" % price_multiplier]
	queue_redraw()

static func filled_notches(stock: float) -> int:
	return clampi(roundi(clampf(stock, 0.0, 1.0) * NOTCHES), 0, NOTCHES)

## -1..1: aşağı ucuzluk, yukarı pahalılık.
static func pressure(multiplier: float) -> float:
	return clampf((multiplier - 1.0) / FULL_PRESSURE, -1.0, 1.0)

static func scarcity_key(stock: float) -> String:
	if stock < 0.2:
		return "UI_GRIM_SCARCE"
	if stock < 0.5:
		return "UI_GRIM_THIN"
	return "UI_GRIM_PLENTY"

func _draw() -> void:
	var filled := filled_notches(stock_share)
	var nw := 9.0
	for i in NOTCHES:
		var r := Rect2(Vector2(i * (nw + 3), 6), Vector2(nw, 14))
		var on := i < filled
		var col := ArtPalette.GRIM_PARCHMENT_DIM if on else Color(ArtPalette.GRIM_IRON, 0.6)
		if on and filled <= 2:
			col = ArtPalette.GRIM_CRIMSON.lightened(0.1)
		draw_rect(r, col)
	var x := NOTCHES * (nw + 3) + 12
	var p := pressure(price_multiplier)
	var col := ArtPalette.GRIM_CRIMSON.lightened(0.2) if p > 0.05 else (
		ArtPalette.MOSS.lightened(0.2) if p < -0.05 else ArtPalette.GRIM_PARCHMENT_DIM)
	var mid := Vector2(x + 8, 13)
	var len := 4.0 + absf(p) * 8.0
	var up := -signf(p) if absf(p) > 0.05 else 0.0
	if up == 0.0:
		draw_line(mid + Vector2(-6, 0), mid + Vector2(6, 0), col, 2.0)
	else:
		draw_line(mid + Vector2(0, -up * len), mid + Vector2(0, up * len), col, 2.0)
		draw_colored_polygon(PackedVector2Array([
			mid + Vector2(0, up * len), mid + Vector2(-5, up * (len - 6)), mid + Vector2(5, up * (len - 6))]), col)
	if shocked:
		draw_circle(Vector2(x + 26, 13), 4.0, ArtPalette.GRIM_CRIMSON)
