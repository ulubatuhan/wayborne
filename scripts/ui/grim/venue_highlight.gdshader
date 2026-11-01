shader_type canvas_item;

// Kasaba resminin üstünde mekân vurgusu. Maske her pikselde mekânın
// numarasını taşıyor (0 = hiçbiri); seçilen mekân yalnızca dış hattında kehribar
// bir kontur alır, kalanı karanlığa çekilir. Hat `outline` dokusunda (R deliksiz
// şekil, G dış hat, B gücü; tools/ui_scenes/venue_outline.py): mask.png'nin
// kendi kenarı açık yapılarda (tezgâh, iskele) her deliğe kontur çiziyordu
// (kullanıcı, 2026-11-01: "iç dış her tarafından glow gelmemeli").

uniform sampler2D outline : filter_nearest;
uniform int hovered = 0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform vec3 glow_colour = vec3(0.93, 0.66, 0.32);
// Şehrin hâli (görev 9.3, taslak y_93_sehir_varyant): 0 olağan, 1 gri (kapalı
// hava), 2 kriz (savaş, veba). Pikseller yerinden oynamıyor, yalnızca renk
// ve ışık - maske hizalı kalıyor, tıklama eşlemesi değişmiyor.
uniform int mood = 0;
// Tek sıcak kaynak (Y-G17): akşam ve gece resimlerinde sıcaklık göğe ve
// duvara yayılmış. 1'de turuncu söner, soğuk griye kayar; parlak ve sıcak
// pikseller (pencere, meşale, fener) ışık kaynağıdır, sıcak kalır.
uniform float cool : hint_range(0.0, 1.0) = 0.0;

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

// Işık kaynağı yalnızca yerde sayılır (pencere, ateş, fener); göktekiler,
// güneş ve halesi dahil, soğur (kullanıcı kararı: akşam güneşi soğuktur).
vec3 cool_grade(vec3 c, float y) {
	float l = luma(c);
	float warm = clamp(c.r - c.b, 0.0, 1.0);
	float lamp = smoothstep(0.55, 0.75, l) * smoothstep(0.12, 0.30, warm) * smoothstep(0.60, 0.66, y);
	vec3 cold = vec3(l) * vec3(0.92, 0.96, 1.05);
	return mix(c, cold, cool * smoothstep(0.02, 0.25, warm) * (1.0 - lamp));
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb = cool_grade(c.rgb, UV.y);
	if (mood == 1) {
		c.rgb = grey_day(c.rgb);
	} else if (mood == 2) {
		c.rgb = crisis(c.rgb, UV);
	}
	if (hovered > 0 && strength > 0.0) {
		vec4 o = texture(outline, UV);
		bool me = int(round(o.r * 255.0)) == hovered;
		float edge = int(round(o.g * 255.0)) == hovered ? o.b : 0.0;
		vec3 base = me ? c.rgb : c.rgb * 0.62;
		base = mix(base, glow_colour, edge * 0.95);
		c.rgb = mix(c.rgb, base, strength);
	}
	COLOR = c;
}
