shader_type canvas_item;

// Büst portresinin arka planı: olay kartlarının alacakaranlık yıkaması.
// Soğuk koyu bir zemin, bir yandan sıcak ışık, seyrek çapraz mürekkep tarama,
// kenarlara doğru koyulaşan vinyet ve kâğıt lekesi.

uniform vec4 cold : source_color = vec4(0.16, 0.21, 0.22, 1.0);
uniform vec4 warm : source_color = vec4(0.62, 0.40, 0.22, 1.0);
uniform vec4 ink : source_color = vec4(0.06, 0.05, 0.05, 1.0);
uniform float warm_side = 0.0;   // 0: ışık solda, 1: sağda
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	float side = mix(uv.x, 1.0 - uv.x, warm_side);
	float glow = smoothstep(0.85, 0.0, side) * smoothstep(1.1, 0.25, uv.y);
	vec3 col = mix(cold.rgb, warm.rgb, glow * 0.55);
	col *= 0.85 + 0.3 * noise(uv * 9.0);
	float v = length((uv - vec2(0.5, 0.45)) * vec2(1.0, 1.15));
	col *= 1.0 - smoothstep(0.35, 0.85, v) * 0.6;
	vec2 p = FRAGCOORD.xy;
	float h = fract((p.x - p.y) / 5.0);
	float line = smoothstep(0.35, 0.45, h) * (1.0 - smoothstep(0.55, 0.65, h));
	col = mix(col, ink.rgb, line * 0.18 * (1.0 - glow));
	COLOR = vec4(col, 1.0);
}
