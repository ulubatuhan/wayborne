class_name TavernLayout
extends RefCounted

## tools/ui_scenes/tavern_scene.py yazar, elle değiştirme. Ekran payı (0-1) ve boy payı.

const ANCHORS: Dictionary = {
	"bartender": {"x": 0.0403, "y": 0.7011, "person_h": 0.2271},
	"bar_pour": {"x": 0.1497, "y": 0.7011, "person_h": 0.2271},
	"waitress_left": {"x": 0.2418, "y": 0.7036, "person_h": 0.2296},
	"waitress_right": {"x": 0.8556, "y": 0.7199, "person_h": 0.2459},
	"pickup": {"x": 0.2188, "y": 0.717, "person_h": 0.243},
	"serve_a": {"x": 0.3363, "y": 0.7422, "person_h": 0.2682},
	"serve_b": {"x": 0.7708, "y": 0.7549, "person_h": 0.2809},
	"bard": {"x": 0.3545, "y": 0.6709, "person_h": 0.1969},
	"bard_right": {"x": 0.6455, "y": 0.6709, "person_h": 0.1969},
	"seat_a1": {"x": 0.2615, "y": 0.7709, "person_h": 0.2969},
	"seat_a2": {"x": 0.376, "y": 0.7709, "person_h": 0.2969},
	"seat_b1": {"x": 0.7429, "y": 0.789, "person_h": 0.315},
	"seat_b2": {"x": 0.8644, "y": 0.789, "person_h": 0.315},
	"seat_c1": {"x": 0.8439, "y": 0.6839, "person_h": 0.2098},
	"seat_c2": {"x": 0.9114, "y": 0.6839, "person_h": 0.2098},
	"aisle_a1": {"x": 0.2926, "y": 0.7322, "person_h": 0.2581},
	"aisle_a2": {"x": 0.3922, "y": 0.7322, "person_h": 0.2581},
	"aisle_b1": {"x": 0.7068, "y": 0.7422, "person_h": 0.2682},
	"aisle_b2": {"x": 0.8102, "y": 0.7422, "person_h": 0.2682},
	"door": {"x": 1.2798, "y": 0.7322, "person_h": 0.2581},
	"table_a": {"x": 0.3113, "y": 0.5906, "person_h": 0.3102},
	"table_b": {"x": 0.8168, "y": 0.5979, "person_h": 0.3299},
	"table_c": {"x": 0.8864, "y": 0.555, "person_h": 0.2152},
	"counter_top": {"x": 0.0407, "y": 0.5461, "person_h": 0.2389},
	"fire": {"x": 0.5, "y": 0.6077, "person_h": 0.1801},
	"lantern_l": {"x": 0.1601, "y": 0.2063, "person_h": 0.3054},
	"lantern_r": {"x": 0.8399, "y": 0.2063, "person_h": 0.3054},
	"candle_a": {"x": 0.296, "y": 0.579, "person_h": 0.3355},
	"candle_b": {"x": 0.8442, "y": 0.5862, "person_h": 0.3587},
	"candle_c": {"x": 0.9054, "y": 0.5448, "person_h": 0.2259},
}

## Zemindeki kişinin boyu: h0 + (ayak_y - y0) * slope (ekran payı).
const DEPTH: Dictionary = {"y0": 0.7544, "h0": 0.2804, "slope": 1.0}
