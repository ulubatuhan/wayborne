shader_type canvas_item;

// Büst portresinin figürü (görev Y-G04): olay kartı illüstrasyonlarının dili,
// yani soluk bir sulu boya üstüne mürekkep tarama. Renk figürün kendisinden
// (ten, saç, kıyafet seçimi görünsün), ama doygunluk düşük; gölge tonları
// çapraz taramayla koyulaşıyor. Tarama ekran pikselinde, figürün ölçeğinden
// bağımsız aynı inceliktedir.

uniform vec4 ink : source_color = vec4(0.07, 0.06, 0.05, 1.0);
uniform float hatch_px = 4.0;
uniform float wash = 0.62;   // renk doygunluğu (1 = figürün kendi rengi)
uniform vec3 key_light = vec3(1.02, 0.97, 0.88);

float hatch(vec2 p, float angle) {
	float s = sin(angle), c = cos(angle);
	float v = fract((p.x * c + p.y * s) / hatch_px);
	return smoothstep(0.30, 0.42, v) * (1.0 - smoothstep(0.58, 0.70, v));
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grey = vec3(l);
	vec3 col = mix(grey, c.rgb, wash) * key_light;
	// Dört ton: sulu boyanın düz lekeleri; figür karanlık render edildiği için
	// biraz kaldırılıyor (portre okunur kalsın).
	float steps = floor(l * 4.0 + 0.5) / 4.0;
	col = col * mix(1.0, 1.22, steps) + vec3(0.025);
	// Tarama yalnız gerçek gölgede ve ince: yüz ve kumaş deseni boğulmasın.
	vec2 p = FRAGCOORD.xy;
	float h = 0.0;
	if (l < 0.26) h = max(h, hatch(p, 0.78) * 0.30);
	if (l < 0.14) h = max(h, hatch(p, -0.78) * 0.40);
	col = mix(col, ink.rgb, h);
	COLOR = vec4(col, c.a);
}
