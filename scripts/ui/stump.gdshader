shader_type canvas_item;

// Kesik el (lore defter III, Ç14): uzak kolun katmanı işaretli bir alfa
// (WalkFigure.STUMP_MARK) ile çizilir; yalnızca o çizimde elin çevresindeki
// pikseller atılır. Gövdenin ve yakın kolun pikselleri olduğu gibi kalır.
uniform vec2 cut_center = vec2(0.0);
uniform float cut_radius = 0.0;
uniform float mark = 0.987;
uniform float outline_mark = 0.849;

varying vec2 local_pos;
varying float cut_here;

void vertex() {
	local_pos = VERTEX;
	cut_here = 0.0;
	if (abs(COLOR.a - mark) < 0.0015) {
		cut_here = 1.0;
		COLOR.a = 1.0;
	} else if (abs(COLOR.a - outline_mark) < 0.0015) {
		cut_here = 1.0;
		COLOR.a = 0.85;
	}
}

void fragment() {
	if (cut_here > 0.5 && cut_radius > 0.0 && distance(local_pos, cut_center) < cut_radius) {
		discard;
	}
}
