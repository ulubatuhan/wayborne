extends Control

## Karakter ekranının ince çubuğu (görev 9.6): koyu bir oluk, üstünde dolu
## kısım ve eşit aralıklı dilim çentikleri. Stat çubuğu üç dilimli (beşer
## puan, tavan `CharacterStats.MAX_VALUE`), yetkinlik çubuğu dilimsiz. Yalnızca
## resim: sayı her zaman yanında canlı metin olarak duruyor.

const BAR_HEIGHT: float = 8.0
const NOTCH_WIDTH: float = 3.0

var value: float = 0.0
var max_value: float = 1.0
var segments: int = 1
var fill_color: Color = ArtPalette.GOLD
var track_color: Color = Color(ArtPalette.GRIM_CHARCOAL_SOFT.lightened(0.08), 0.95)
var notch_color: Color = ArtPalette.GRIM_CHARCOAL

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(80.0, BAR_HEIGHT + 4.0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

func setup(new_value: float, new_max: float, new_segments: int, color: Color) -> Control:
	value = new_value
	max_value = new_max
	segments = maxi(1, new_segments)
	fill_color = color
	queue_redraw()
	return self

func _draw() -> void:
	var top := (size.y - BAR_HEIGHT) * 0.5
	draw_rect(Rect2(0.0, top, size.x, BAR_HEIGHT), track_color)
	var ratio := clampf(value / maxf(max_value, 0.001), 0.0, 1.0)
	if ratio > 0.0:
		draw_rect(Rect2(0.0, top, size.x * ratio, BAR_HEIGHT), fill_color)
	for i in range(1, segments):
		var x := size.x * float(i) / float(segments)
		draw_rect(Rect2(x - NOTCH_WIDTH * 0.5, top, NOTCH_WIDTH, BAR_HEIGHT), notch_color)
