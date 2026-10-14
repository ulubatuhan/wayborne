// Süren durumun bedenin kendisindeki izi: yalnız bedenin ve giysinin
// piksellerini boyuyor (figürün çizdiği her doku), dışına taşmıyor.
// Desen tuval uzayında (`local`), boyuna oranlı - atlastaki UV her karede
// başka bir yer olduğu için kullanılamazdı, kare dokularının kendi uzayı da
// her karede başka bir ölçek ve aynada (ölçüldü: yara izi bedenin dışına
// düşüyordu). Yara noktası da aynı uzayda veriliyor.
//   burn   kömürleşen yamalar, içlerinde nefes alan köz
//   frost  bölgesel buz kabuğu, çatlak ve pul
//   poison hastalıklı yeşil ten, irinli lekeler
//   bleed  yaradan aşağı akan kan, kumaşa işleyen leke
shader_type canvas_item;

uniform float burn : hint_range(0.0, 1.0) = 0.0;
uniform float frost : hint_range(0.0, 1.0) = 0.0;
uniform float poison : hint_range(0.0, 1.0) = 0.0;
uniform float bleed : hint_range(0.0, 1.0) = 0.0;
uniform vec2 wound = vec2(0.0);
uniform float figure_h = 100.0;
uniform float seed = 0.0;

varying vec2 local;

void vertex() {
	local = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.0) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec2 p = local / figure_h;

	if (frost > 0.0) {
		// Soğuk bütün bedeni morartıyor, buz ise yamalar hâlinde.
		c.rgb = mix(c.rgb, c.rgb * vec3(0.66, 0.84, 1.15), frost * 0.65);
		float n = fbm(p * 9.0);
		float ice = smoothstep(0.48, 0.62, n) * frost;
		vec3 icy = vec3(0.80, 0.92, 1.0) * (0.85 + 0.25 * fbm(p * 40.0));
		c.rgb = mix(c.rgb, icy, ice * 0.88);
		float crack = 1.0 - smoothstep(0.0, 0.025, abs(fbm(p * 18.0 + 3.0) - 0.5));
		c.rgb = mix(c.rgb, vec3(0.97, 1.0, 1.0), crack * ice * 0.7);
		float flake = step(0.93, hash(floor(p * 90.0))) * ice;
		c.rgb += vec3(0.5, 0.6, 0.7) * flake;
	}

	if (burn > 0.0) {
		// Kömür yamaları yavaşça yukarı kayıyor; közler titriyor.
		float n = fbm(p * 7.0 + vec2(0.0, TIME * 0.15));
		float charred = smoothstep(0.36, 0.62, n) * burn;
		c.rgb = mix(c.rgb, vec3(0.09, 0.05, 0.03), charred * 0.85);
		float e = fbm(p * 16.0 - vec2(0.0, TIME * 0.9));
		float ember = smoothstep(0.60, 0.78, e) * charred;
		float pulse = 0.65 + 0.35 * sin(TIME * 11.0 + p.x * 50.0 + p.y * 30.0);
		c.rgb += vec3(1.0, 0.42, 0.08) * ember * pulse * 1.3;
		c.rgb = mix(c.rgb, c.rgb * vec3(1.08, 0.86, 0.72), burn * 0.35);
	}

	if (poison > 0.0) {
		// Ten hastalıklı yeşile dönüyor; lekeler sarı kenarlı, nabız gibi.
		float pulse = 0.5 + 0.5 * sin(TIME * 2.2);
		c.rgb = mix(c.rgb, c.rgb * vec3(0.72, 0.92, 0.55), poison * 0.7);
		float n = fbm(p * 11.0 + 7.0);
		// Lekeler morumsu-koyu, içleri kabarcıklı; ten solgun yeşil.
		float lesion = smoothstep(0.58, 0.70, n) * poison;
		c.rgb = mix(c.rgb, vec3(0.20, 0.26, 0.10), lesion * 0.75);
		float pus = step(0.90, hash(floor(p * 70.0))) * lesion;
		c.rgb += vec3(0.30, 0.38, 0.06) * pus;
		c.rgb += vec3(0.06, 0.12, 0.01) * poison * pulse * 0.5;
	}

	if (bleed > 0.0) {
		// Yaranın etrafında koyu leke, altında ip ip aşağı akan kan.
		vec2 d = (local - wound) / figure_h;
		float around = 1.0 - smoothstep(0.04, 0.11, length(d * vec2(1.0, 1.3)));
		float below = step(-0.01, d.y) * (1.0 - smoothstep(0.10, 0.55, d.y));
		float lane = noise(vec2(d.x * 45.0, 0.0));
		float streak = smoothstep(0.45, 0.7, lane) * below * (1.0 - smoothstep(0.05, 0.11, abs(d.x)));
		float soak = smoothstep(0.42, 0.6, fbm(d * 22.0)) * (1.0 - smoothstep(0.06, 0.18, length(d)));
		float blood = clamp(around + streak + soak, 0.0, 1.0) * bleed;
		c.rgb = mix(c.rgb, vec3(0.40, 0.02, 0.03) * (0.8 + 0.4 * fbm(d * 60.0)), blood * 0.9);
	}

	COLOR = c;
}
