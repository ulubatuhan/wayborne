class_name CampFlame
extends Control

## Ana menü kampının alevi (T16-04): render'ın köşeli konileri arka plandan
## silindi (`tools/ui_scenes/camp_fire_front.py`); yerine yoldaki kamp ateşi ve
## tavernanın ocağıyla aynı dalgalanan, katmanlı diller (`TavernRoom._flame_shape`,
## `TavernRoom.flicker`). Düğüm ateşin dibine oturur: `base` alevin kökü
## (odunların üstü), `unit` ateşin genişliği; ikisi de `GrimDrafts._place_flame`
## tarafından ekran boyuna göre yazılır.

const TONGUES: int = 5
## Alevin boyu ateşin genişliğine oranla (render'ın konisi ~1.2 katıydı).
const HEIGHT_SHARE: float = 1.05
const GLOW_RINGS: int = 6

var base: Vector2 = Vector2.ZERO
var unit: float = 100.0
var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var flame_h := unit * HEIGHT_SHARE
	# Közün ve alevin ışığı: yumuşak, katman katman sönen bir hale (tek bir
	# opak daire kaba duruyordu, T16-04 denetimi).
	var glow := base + Vector2(0.0, -flame_h * 0.25)
	for ring in GLOW_RINGS:
		var k := float(ring + 1) / float(GLOW_RINGS)
		draw_circle(glow, unit * (0.25 + 0.75 * k), Color(1.0, 0.55, 0.2, 0.05 * (1.0 - k * 0.6)))
	for tongue_i in TONGUES:
		var seed_offset := float(tongue_i) * 1.9
		var middle := float(TONGUES - 1) * 0.5
		var tongue := flame_h * (0.62 + 0.38 * TavernRoom.flicker(_time, seed_offset)) * (1.0 - 0.3 * absf(float(tongue_i) - middle) / middle)
		var half_w := unit * (0.11 + 0.03 * float(tongue_i % 2))
		var x := base.x + (float(tongue_i) - middle) * unit * 0.1
		var sway := sin(_time * 3.1 + seed_offset) * unit * 0.04
		var root := Vector2(x, base.y + unit * 0.03)
		# Kenar yumuşatma: her dilin biraz büyüğü çok soluk, altında. Çokgenler
		# kenar yumuşatmasız çiziliyor; basamaklı kenar bu halede eriyor.
		draw_colored_polygon(TavernRoom._flame_shape(root, half_w * 1.25, tongue * 1.08, sway), Color(0.95, 0.35, 0.08, 0.18))
		draw_colored_polygon(TavernRoom._flame_shape(root, half_w, tongue, sway), Color(0.95, 0.40, 0.10, 0.72))
		draw_colored_polygon(TavernRoom._flame_shape(root, half_w * 0.62, tongue * 0.72, sway * 0.7), Color(1.0, 0.68, 0.24, 0.78))
		draw_colored_polygon(TavernRoom._flame_shape(root, half_w * 0.3, tongue * 0.42, sway * 0.4), Color(1.0, 0.92, 0.62, 0.85))
