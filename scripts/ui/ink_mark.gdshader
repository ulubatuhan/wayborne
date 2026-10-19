shader_type canvas_item;

// Mürekkep işaretini koyu zeminde okunur kılar: resmin yalnızca saydamlığı
// kalır, rengi tek bir mürekkep tonu olur. Koyu mürekkep çarpmayla asla
// açılamaz (Waybook UI Rules: işaretler yeniden boyanır, çarpılmaz).
uniform vec4 ink : source_color = vec4(0.88, 0.85, 0.78, 1.0);

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(ink.rgb, a * ink.a * COLOR.a);
}
