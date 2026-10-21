shader_type canvas_item;

// Ateşin başındaki figür ve sandığı (ana menü kampı, taslak y_g16_menu_kamp):
// ışık yalnızca ateşten gelir. Ateşe yakın yan sıcak ve aydınlık, uzak yan
// karanlık. Konum tuval koordinatında: figür kareleri kendi dönüşümleriyle
// çiziliyor, yerel koordinat karenin dokusununki olurdu.
uniform vec2 fire = vec2(0.0);
uniform float radius = 300.0;
uniform float strength = 1.0;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float near = clamp(1.0 - distance(world, fire) / radius, 0.0, 1.0);
	float light = 0.16 + near * near * 1.1 * strength;
	vec3 warm = vec3(1.0, 0.62, 0.34);
	COLOR.rgb *= light * (0.55 + 0.45 * warm);
}
