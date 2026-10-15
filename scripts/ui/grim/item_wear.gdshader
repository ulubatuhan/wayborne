shader_type canvas_item;

// Bir eşyanın ikonu üstünde yıpranma: yırtık (maske eşiği), kırağı (kenardan
// gelen soğuk), kir (çarpımsal is). Üçü de 0'da tam etkisiz, yani yeni bir
// eşya hiç değişmeden çiziliyor.

uniform sampler2D tatter_mask : filter_linear, repeat_enable;
uniform sampler2D frost_tex : filter_linear;
uniform sampler2D grime_tex : filter_linear, repeat_enable;
uniform float tatter : hint_range(0.0, 1.0) = 0.0;
uniform float frost : hint_range(0.0, 1.0) = 0.0;
uniform float grime : hint_range(0.0, 1.0) = 0.0;
uniform vec4 frost_colour : source_color = vec4(0.80, 0.88, 0.93, 1.0);
uniform vec4 burn_colour : source_color = vec4(0.18, 0.10, 0.05, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float m = texture(tatter_mask, UV).r;
	// Eşik: yıpranma büyüdükçe maskenin daha büyük kısmı kesilir.
	float cut = tatter * 0.85;
	float edge = smoothstep(cut, cut + 0.06, m);
	// Yırtığın kenarı kavrulmuş görünür, keskin kesik değil.
	float rim = (1.0 - smoothstep(cut + 0.02, cut + 0.12, m)) * step(0.001, tatter);
	c.rgb = mix(c.rgb, burn_colour.rgb, rim * 0.7);
	c.a *= edge;
	vec4 g = texture(grime_tex, UV * 1.5);
	c.rgb = mix(c.rgb, c.rgb * g.rgb * 1.6, g.a * grime);
	c.rgb *= 1.0 - 0.35 * grime;
	vec4 f = texture(frost_tex, UV);
	c.rgb = mix(c.rgb, frost_colour.rgb, clamp(f.a * frost * 1.4, 0.0, 0.9));
	COLOR = c;
}
