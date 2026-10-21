shader_type canvas_item;

// Kasaba resminin üstünde mekân vurgusu. Maske her pikselde mekânın
// numarasını taşıyor (0 = hiçbiri); seçilen mekân fenerle aydınlanır ve
// kehribar bir kontur alır, kalanı karanlığa çekilir.

uniform sampler2D mask : filter_nearest;
uniform int hovered = 0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform vec3 glow_colour = vec3(0.93, 0.66, 0.32);
// Şehrin hâli (görev 9.3, taslak y_93_sehir_varyant): 0 olağan, 1 gri (kapalı
// hava), 2 kriz (savaş, veba). Pikseller yerinden oynamıyor, yalnızca renk
// ve ışık - maske hizalı kalıyor, tıklama eşlemesi değişmiyor.
uniform int mood = 0;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 grey_day(vec3 c) {
	vec3 out_c = c * 0.35 + vec3(luma(c)) * 0.65;
	out_c = 0.10 + out_c * 0.82;
	return out_c * vec3(0.95, 0.98, 1.03);
}

// Ufukta kızıl bir bant ve şehrin üstünden yükselen üç duman sütunu.
vec3 crisis(vec3 c, vec2 uv) {
	vec3 out_c = (c * 0.25 + vec3(luma(c)) * 0.75) * 0.78;
	vec3 sky = mix(vec3(0.55, 0.16, 0.10), vec3(0.0), uv.y);
	float band = exp(-pow((uv.y - 0.42) / 0.12, 2.0));
	out_c += sky * band * 0.55;
	float smoke = 0.0;
	vec3 columns = vec3(0.24, 0.52, 0.79);
	for (int k = 0; k < 3; k++) {
		float rise = clamp((0.42 - uv.y) / 0.42, 0.0, 1.0);
		float centre = columns[k] + rise * 0.10;
		float width = 0.025 + rise * 0.06;
		float column = exp(-pow((uv.x - centre) / width, 2.0));
		smoke = max(smoke, column * (1.0 - rise * 0.55) * step(uv.y, 0.44));
	}
	return out_c * (1.0 - smoke * 0.6) + vec3(0.40, 0.36, 0.34) * smoke * 0.6;
}

int id_at(vec2 uv) {
	return int(round(texture(mask, uv).r * 255.0));
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (mood == 1) {
		c.rgb = grey_day(c.rgb);
	} else if (mood == 2) {
		c.rgb = crisis(c.rgb, UV);
	}
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
