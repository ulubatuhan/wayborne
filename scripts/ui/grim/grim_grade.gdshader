shader_type canvas_item;

// Kasvetli ton (kullanıcı, 2026-10-22: "tüm yapılar, tüm sahneler grim bir
// tonda olmalı"): ekranın dünya katmanı şehir resimlerinin rengine iner.
// Doygunluk yalnızca sıcak ışıkta (ateş, fener, gün batımı) kalır, açık tonlar
// sıkışır, gölgeler soğur. Ölçüm (öğlen yol / şehir resmi): doygunluk
// 0.17-0.20 / 0.15, parlaklık 0.38-0.45 / 0.37-0.42.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float desaturate : hint_range(0.0, 1.0) = 0.28;
uniform float highlight_squeeze : hint_range(0.0, 1.0) = 0.30;
uniform vec3 shadow_tint = vec3(0.90, 0.92, 1.0);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float warm = clamp((c.r - c.b) * 2.0, 0.0, 1.0) * smoothstep(0.3, 0.7, l);
	// Doygun gece mavisi de söner (stil kuralı: doygun mor ve mavi yok).
	float cool = clamp((c.b - c.r) * 2.5, 0.0, 1.0);
	c = mix(c, vec3(l), clamp(desaturate * (1.0 - 0.6 * warm) + 0.3 * cool, 0.0, 1.0));
	c -= vec3(max(l - 0.55, 0.0) * highlight_squeeze);
	c *= mix(shadow_tint, vec3(1.0), smoothstep(0.08, 0.45, l));
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
