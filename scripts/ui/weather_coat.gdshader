// Kervanın üstündeki hava: kar ve ıslaklık (Weather on the Body Rules).
//
// Kervanın bütün figürleri ve vagonları tek bir `CanvasGroup`'ta birleşiyor;
// bu gölgelendirici o birleşik resmin üstünde çalışıyor. Neden birleşik:
// figürler katman katman (arka kol, arka bacak, gövde, ön bacak, ön kol)
// atlas sayfalarından çiziliyor, yani bir parçanın kendi resmindeki "üst
// kenar" çoğu zaman gövdenin altında kalan bir kesik. Ekranda görünen
// siluetin üstü ise gerçekten gökyüzüne bakan yüzey: omuz, sırt, kol, at
// sağrısı, öküzün böğrü, branda, tekerlek.
//
// Kar üç yoldan:
//  1. Üste bakan her kenarda bir kabuk. Kalınlığı x boyunca değişir
//     (gürültü), bir kısmı siluetin içine, bir kısmı üstüne biner; yani
//     yüzeyin kendi eğrisini izler. Eski çizim tek bir tümsekti ve atta düz
//     bir tahtanın üstünde duruyordu (kullanıcı, 2026-11-13).
//  2. Yere yakın bantta (bacak, çizme, toynak, tekerlek) yürürken bulaşan
//     serpinti.
//  3. Her yüzeyde hafif bir kırağı.
// Islaklık: kumaş koyulaşır, üst kenarda soğuk gök parıltısı toplanır,
// yüzeyde dikey su yolları parlar.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;
uniform float snow : hint_range(0.0, 1.0) = 0.0;
uniform float wet : hint_range(0.0, 1.0) = 0.0;
// Kabuğun en kalın yeri, ekran pikseli (kar 1'de).
uniform float rim_px = 3.0;
// Zemin çizgisi grubun kendi uzayında: y = ground_a + ground_b * x.
uniform float ground_a = 0.0;
uniform float ground_b = 0.0;
// Zeminden bu kadar yukarısına kadar bulaşma serpintisi.
uniform float cake_h = 30.0;
// Gürültünün ölçeği (figür boyundan): aynı kervan her çözünürlükte aynı lekeleri taşısın.
uniform float unit_px = 60.0;
uniform vec4 snow_col : source_color = vec4(0.86, 0.89, 0.93, 1.0);
uniform vec4 sheen_col : source_color = vec4(0.70, 0.78, 0.88, 1.0);

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float alpha_at(vec2 uv) {
	return textureLod(screen_tex, uv, 0.0).a;
}

// Ateş, fener, ten: sıcak ve parlak olan yüzeye kar konmaz (tek sıcak
// kaynak kuralının tersi: ışığın kendisi karlanmaz).
bool is_warm_light(vec3 c) {
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	return lum > 0.55 && c.r > c.b * 1.35;
}

void fragment() {
	vec4 c = textureLod(screen_tex, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	vec2 px = SCREEN_PIXEL_SIZE;
	float n_scale = 6.0 / max(unit_px, 1.0);
	bool solid = c.a > 0.85;

	if (snow > 0.01) {
		// Kabuğun bu sütundaki kalınlığı: kesik kesik, eşit değil.
		float lumpy = vnoise(vec2(local_pos.x * n_scale * 1.7, 3.1));
		float thick = rim_px * snow * (0.25 + 0.95 * lumpy);
		float gap = step(0.30, vnoise(vec2(local_pos.x * n_scale * 0.8, 9.7)));
		thick *= gap;
		if (solid && !is_warm_light(c.rgb)) {
			// Üstteki boşluğa uzaklık: o kadar içerideyse kabuğun içindeyiz.
			float dist = 99.0;
			float reach = max(thick, 0.5);
			for (int i = 1; i <= 10; i++) {
				// İlk dördü kabuğun içinde ince adım, sonrakiler kırıntı için uzak.
				float d = i <= 4 ? float(i) * reach / 4.0 : reach + float(i - 4) * (reach * 5.0 + 4.0) / 6.0;
				if (dist > 98.0 && alpha_at(SCREEN_UV - vec2(0.0, d * px.y)) < 0.3) {
					dist = d;
				}
			}
			if (dist <= thick * 0.6 + 0.5) {
				c.rgb = mix(c.rgb, snow_col.rgb, 0.92);
			}
			// Yere yakın bulaşma: bacak, toynak, tekerlek.
			float ground_y = ground_a + ground_b * local_pos.x;
			float near_ground = smoothstep(ground_y - cake_h, ground_y, local_pos.y);
			float fleck = vnoise(local_pos * n_scale * 2.6);
			if (fleck > 1.0 - near_ground * snow * 0.42) {
				c.rgb = mix(c.rgb, snow_col.rgb, 0.8);
			}
			// Yapışan kar: kolda, gövdede, pantolonda, böğürde küçük lekeler.
			// Üst kenara yakın daha sık (kar oraya düşüp kayar), aşağıda seyrek.
			float clump = vnoise(local_pos * n_scale * 3.4);
			float near_top = 1.0 - smoothstep(thick, thick * 6.0 + 4.0, dist);
			if (clump > 1.0 - snow * (0.10 + 0.22 * near_top)) {
				c.rgb = mix(c.rgb, snow_col.rgb, 0.78);
			}
			// Kırağı: her yüzey biraz ağarır.
			c.rgb = mix(c.rgb, snow_col.rgb, snow * 0.10);
		} else if (c.a < 0.3 && thick > 0.5) {
			// Kabuğun siluetin üstüne taşan payı: altta katı bir yüzey varsa.
			float below = 99.0;
			for (int i = 1; i <= 4; i++) {
				float d = float(i) * thick * 0.45 / 4.0;
				vec4 b = textureLod(screen_tex, SCREEN_UV + vec2(0.0, d * px.y), 0.0);
				if (b.a > 0.85 && !is_warm_light(b.rgb / max(b.a, 0.0001))) {
					below = min(below, d);
				}
			}
			if (below < 99.0) {
				float a = 0.95 * (1.0 - below / (thick * 0.45 + 0.001));
				c = vec4(snow_col.rgb, max(c.a, a));
			}
		}
	}

	if (wet > 0.01 && solid) {
		// Islak kumaş ve post koyulaşır, renk biraz derinleşir.
		float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		c.rgb = mix(c.rgb, mix(vec3(lum), c.rgb, 1.2), wet) * (1.0 - 0.26 * wet);
		// Üst kenarda gök parıltısı: ince, soğuk bir çizgi.
		if (alpha_at(SCREEN_UV - vec2(0.0, 1.5 * px.y)) < 0.3 && !is_warm_light(c.rgb)) {
			c.rgb = mix(c.rgb, sheen_col.rgb, 0.78 * wet);
		}
		// Yüzeyden süzülen su: dikey, seyrek parlak çizgiler.
		// Kısa ve kesik: uzun tek bir çizgi boyanın üstünde bir yırtık gibi duruyordu.
		float streak = vnoise(vec2(local_pos.x * n_scale * 4.0, local_pos.y * n_scale * 0.5));
		float run = vnoise(vec2(local_pos.x * n_scale * 4.0 + 7.0, local_pos.y * n_scale * 1.6));
		if (streak > 0.80 && run > 0.55) {
			c.rgb = mix(c.rgb, sheen_col.rgb, 0.45 * wet * (streak - 0.80) / 0.20);
		}
		// Kumaşta tutunan damlalar: seyrek, küçük, parlak noktalar.
		float drop = vnoise(local_pos * n_scale * 5.5 + vec2(17.0, 3.0));
		if (drop > 1.0 - 0.04 * wet && !is_warm_light(c.rgb)) {
			c.rgb = mix(c.rgb, sheen_col.rgb, 0.85);
		}
	}

	COLOR *= c;
}
