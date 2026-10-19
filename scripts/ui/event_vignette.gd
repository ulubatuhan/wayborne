class_name EventVignette
extends Control

## Olay kartının içindeki görsel, olayın kendi resmi yoksa (kullanıcı notu
## 2026-10-19: "olay kartının arka planı olmamalı, kart sahnenin içinde, olaya
## ait görsel kartın içinde - EU4 gibi"): kervanın o an yürüdüğü yolun
## manzarası, aynı render katmanlarından (RoadStrips) küçük bir şerit. Olay
## nerede oluyorsa kartta o yer görünür.

const SKY_TOP: Color = Color(0.20, 0.22, 0.26)
const SKY_BOTTOM: Color = Color(0.62, 0.54, 0.44)
const FEET_LINE: float = 0.86
const BAND_SCALE: float = 1.7

var biome: String = ""
## Kartın ışığı günün saatine uysun: 0 gün ışığı, 1 gece.
var darkness: float = 0.0

static func available(biome_id: String) -> bool:
	return not biome_id.is_empty() and RoadStrips.has_biome(biome_id)

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _draw() -> void:
	if not available(biome) or size.x < 8.0:
		return
	var tint := Color(1, 1, 1).lerp(Color(0.32, 0.34, 0.45), clampf(darkness, 0.0, 1.0))
	var feet := size.y * FEET_LINE
	var steps := 24
	for i in steps:
		var u := float(i) / float(steps)
		var y0 := feet * u
		draw_rect(Rect2(0, y0, size.x, feet / float(steps) + 1.0), SKY_TOP.lerp(SKY_BOTTOM, u) * tint)
	var band := size.y * BAND_SCALE
	var cover := Rect2(Vector2.ZERO, size)
	RoadStrips.draw_layer(self, biome, RoadStrips.FAR, band, 0.0, cover, feet - size.y * 0.12, tint.darkened(0.1))
	RoadStrips.draw_layer(self, biome, RoadStrips.MID, band, 120.0, cover, feet - size.y * 0.05, tint)
	RoadStrips.draw_layer(self, biome, RoadStrips.GROUND, band, 60.0, cover, feet, tint)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.03, 0.9), false, 2.0)
