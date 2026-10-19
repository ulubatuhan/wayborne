class_name TavernLayout
extends RefCounted

## tools/ui_scenes/tavern_scene.py yazar, elle değiştirme. Ekran payı (0-1) ve boy payı.

const ANCHORS: Dictionary = {
	"bartender": {"x": 0.0655, "y": 0.6635, "person_h": 0.1502},
	"waitress_left": {"x": 0.2966, "y": 0.6525, "person_h": 0.1406},
	"waitress_right": {"x": 0.8203, "y": 0.6437, "person_h": 0.1329},
	"bard": {"x": 0.3631, "y": 0.6351, "person_h": 0.1253},
	"seat_a1": {"x": 0.2604, "y": 0.7221, "person_h": 0.2014},
	"seat_a2": {"x": 0.4029, "y": 0.7221, "person_h": 0.2014},
	"seat_b1": {"x": 0.7113, "y": 0.7342, "person_h": 0.212},
	"seat_b2": {"x": 0.8612, "y": 0.7342, "person_h": 0.212},
	"seat_c1": {"x": 0.8649, "y": 0.6604, "person_h": 0.1474},
	"seat_c2": {"x": 0.9502, "y": 0.6604, "person_h": 0.1474},
	"table_a": {"x": 0.3316, "y": 0.5955, "person_h": 0.2016},
	"table_b": {"x": 0.7864, "y": 0.601, "person_h": 0.2123},
	"table_c": {"x": 0.9077, "y": 0.5677, "person_h": 0.1475},
	"counter_top": {"x": 0.0335, "y": 0.561, "person_h": 0.1613},
	"fire": {"x": 0.5, "y": 0.5791, "person_h": 0.1174},
	"lantern_l": {"x": 0.1997, "y": 0.2744, "person_h": 0.1733},
	"lantern_r": {"x": 0.8003, "y": 0.2744, "person_h": 0.1733},
	"candle_a": {"x": 0.3315, "y": 0.584, "person_h": 0.2017},
	"candle_b": {"x": 0.7864, "y": 0.5889, "person_h": 0.2123},
	"candle_c": {"x": 0.9077, "y": 0.5593, "person_h": 0.1476},
}
