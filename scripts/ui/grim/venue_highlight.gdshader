shader_type canvas_item;

// Kasaba resminin üstünde mekân vurgusu. Maske her pikselde mekânın
// numarasını taşıyor (0 = hiçbiri); seçilen mekân fenerle aydınlanır ve
// kehribar bir kontur alır, kalanı karanlığa çekilir.

uniform sampler2D mask : filter_nearest;
uniform int hovered = 0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform vec3 glow_colour = vec3(0.93, 0.66, 0.32);

int id_at(vec2 uv) {
	return int(round(texture(mask, uv).r * 255.0));
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (hovered > 0 && strength > 0.0) {
		vec2 px = 1.0 / vec2(textureSize(mask, 0));
		bool me = id_at(UV) == hovered;
		float edge = 0.0;
		for (int i = 1; i <= 3; i++) {
			float r = float(i) * 1.5;
			bool a = id_at(UV + vec2(px.x * r, 0.0)) == hovered;
			bool b = id_at(UV - vec2(px.x * r, 0.0)) == hovered;
			bool d = id_at(UV + vec2(0.0, px.y * r)) == hovered;
			bool e = id_at(UV - vec2(0.0, px.y * r)) == hovered;
			if (me != a || me != b || me != d || me != e) {
				edge = max(edge, 1.0 - float(i - 1) / 3.0);
			}
		}
		vec3 lit = c.rgb * 1.5 + vec3(0.06, 0.035, 0.0);
		vec3 dim = c.rgb * 0.62;
		vec3 base = me ? lit : dim;
		base = mix(base, glow_colour, edge * (me ? 0.95 : 0.45));
		c.rgb = mix(c.rgb, base, strength);
	}
	COLOR = c;
}
