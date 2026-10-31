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
// Yorgunluk (görev Y-G19, kullanıcı notu: "karakter portreleri direkt bu
// şekilde çizilmeli, zaten aşınmış, yorgun olmalı"). Bir duruma göre değil,
// baştan: renk daha da solar, ışık soğur (tek sıcak kaynak kuralı: portrenin
// ışığı bir ateş değil), gölgeler derinleşir ve tarama daha erken başlar.
// 0 eski portre, 1 yorgun portre.
uniform float weariness = 1.0;
const vec3 WEARY_LIGHT = vec3(0.92, 0.95, 1.0);

float hatch(vec2 p, float angle) {
	float s = sin(angle), c = cos(angle);
	float v = fract((p.x * c + p.y * s) / hatch_px);
	return smoothstep(0.30, 0.42, v) * (1.0 - smoothstep(0.58, 0.70, v));
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grey = vec3(l);
	vec3 col = mix(grey, c.rgb, wash * mix(1.0, 0.68, weariness)) * mix(key_light, WEARY_LIGHT, weariness);
	// Dört ton: sulu boyanın düz lekeleri; figür karanlık render edildiği için
	// biraz kaldırılıyor (portre okunur kalsın).
	float steps = floor(l * 4.0 + 0.5) / 4.0;
	col = col * mix(1.0, mix(1.22, 1.12, weariness), steps) + vec3(mix(0.025, 0.012, weariness));
	// Gölgede bir ton daha çöküş: yanak ve göz çukuru içe göçer.
	col *= mix(1.0, smoothstep(0.0, 0.35, l) * 0.25 + 0.75, weariness);
	// Tarama yalnız gerçek gölgede ve ince: yüz ve kumaş deseni boğulmasın.
	vec2 p = FRAGCOORD.xy;
	float h = 0.0;
	float shade_edge = mix(0.26, 0.32, weariness);
	if (l < shade_edge) h = max(h, hatch(p, 0.78) * mix(0.30, 0.38, weariness));
	if (l < shade_edge * 0.55) h = max(h, hatch(p, -0.78) * 0.40);
	col = mix(col, ink.rgb, h);
	COLOR = vec4(col, c.a);
}
