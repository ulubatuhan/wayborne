class_name ArtPalette
extends RefCounted

## Oyunun **tek** rengi ve tek çizim dili. Her ekran buradan besleniyor.
##
## Var olma sebebi doğrudan bir şikâyet: her ekran kendi renklerini
## uyduruyordu (savaş kendi paletini, yol kendi `PHASE_PALETTE`'ini, şehir
## varsayılan temayı), o yüzden oyun tek bir yapımın parçası gibi
## durmuyordu. Renk bir ekranın değil oyunun kararı.
##
## Stil: piksel değil, **yassı-resimsel**. Silüet katmanları, yumuşak
## gradyanlar, koyu kontur, tek yönden ışık. Hepsi `_draw()` ile çiziliyor;
## elle çizilmiş varlık geldiğinde bu dosya palet olarak kalır, çizim
## fonksiyonları yerini dokuya bırakır.

# --- Mürekkep ve kâğıt ---
const INK: Color = Color(0.055, 0.050, 0.058)
const INK_SOFT: Color = Color(0.115, 0.105, 0.115)
const BONE: Color = Color(0.88, 0.85, 0.78)
const BONE_DIM: Color = Color(0.62, 0.59, 0.54)

# --- Vurgular ---
const GOLD: Color = Color(0.86, 0.70, 0.34)
const GOLD_DIM: Color = Color(0.52, 0.42, 0.22)
const BLOOD: Color = Color(0.66, 0.19, 0.17)
const MOSS: Color = Color(0.34, 0.46, 0.30)
const STEEL: Color = Color(0.62, 0.65, 0.68)
const TORCH: Color = Color(0.96, 0.68, 0.34)

# --- Arayüz rolleri (Waybook) ---
## Paneller ve düğmeler dokudan geliyor (bkz. WaybookTheme), ama doku
## renk kararı vermiyor: bir panelin iç zemini, yazının rengi, bir düğmenin
## üstüne gelinince ne kadar aydınlandığı burada. Dokunun kendi deri/pirinç
## tonu boyanmış bir malzeme; bu roller onun *üstüne* biniyor.
## Panelin cilt çerçevesinin içindeki zemin: lamba isi değmiş kâğıt.
const UI_PANEL_FILL: Color = Color(0.085, 0.074, 0.066, 0.97)
## Yol HUD şeritleri - dünyayı tamamen örtmeyen yarı saydam kuşak.
const UI_HUD_BAR: Color = Color(0.06, 0.058, 0.065, 0.82)
## Tam ekran bir kararın arkasındaki karartma.
const UI_BACKDROP: Color = Color(0.0, 0.0, 0.0, 0.72)
## Liderlik devri gibi geri alınamaz anların daha koyu karartması.
const UI_BACKDROP_SOLEMN: Color = Color(0.0, 0.0, 0.0, 0.85)
const UI_TEXT: Color = BONE
const UI_TEXT_DIM: Color = BONE_DIM
## Açık kâğıt (ipucu fişi, sayfa) üstündeki yazı.
const UI_TEXT_ON_PAGE: Color = INK
const UI_ACCENT: Color = GOLD
## Düğme durumları dokuyu yeniden boyamıyor, çarpıyor: üstüne gelince
## deri ışığa döner, basılınca gölgeye çekilir, kilitliyken solar.
const UI_TINT_HOVER: Color = Color(1.18, 1.10, 0.98)
const UI_TINT_PRESSED: Color = Color(0.78, 0.74, 0.70)
const UI_TINT_DISABLED: Color = Color(0.62, 0.60, 0.58)
const UI_FOCUS: Color = Color(0.86, 0.70, 0.34, 0.85)
## Mürekkep işaretleri (kilitli düğmenin üstünü çizen kalem, ayırıcı
## çizgi) koyu deri ve koyu kâğıt üstünde siyah mürekkeple görünmüyordu;
## oyunun zemini koyu olduğu için "mürekkep" burada solgun kemik rengi.
const UI_INK_MARK: Color = Color(0.80, 0.74, 0.64, 0.85)
const UI_RULE: Color = Color(0.52, 0.42, 0.22, 0.7)
## Kemik rengi yazının koyu halesi/gölgesi.
const UI_TEXT_HALO: Color = Color(0.03, 0.025, 0.03, 0.9)
## Kilitli düğmenin kulağındaki karalama: kan mürekkebi, yazıdan uzakta.
const UI_LOCK_MARK: Color = Color(0.78, 0.30, 0.24, 0.95)
## Harita parşömenindeki şehir yazısı: kapalı yolun şehri soluk mürekkep,
## hepsinin çevresinde kâğıt renginde bir hale (tarama üstünde okunsun).
const UI_MAP_INK_FADED: Color = Color(0.055, 0.050, 0.058, 0.72)
const UI_MAP_HALO: Color = Color(0.90, 0.85, 0.74, 0.85)
## Şişe göstergelerinin (moral/stres/tehlike/takat) sıvısı. Şişe camı
## dokudan geliyor, içindeki renk burada - iki ekran (yol, dünya hub'ı)
## aynı sıvıyı okusun.
const UI_GAUGE_MORALE: Color = Color(0.52, 0.70, 0.44)
const UI_GAUGE_STRESS: Color = Color(0.78, 0.36, 0.30)
const UI_GAUGE_DANGER: Color = Color(0.88, 0.60, 0.26)
const UI_GAUGE_STAMINA: Color = Color(0.50, 0.66, 0.84)
const UI_GAUGE_EMPTY: Color = Color(0.10, 0.09, 0.09, 0.85)
## Yol şeridindeki ikincil satırlar (koşullar, dikkat, son kayıt).
const UI_HUD_NOTE: Color = Color(0.82, 0.80, 0.72)
## Bir yol işareti büyüdüğünde ve oyuncu ona yetiştiğinde ikonun tonu.
## İkonun kendi mürekkebiyle çarpıldığı için kan/yosunun açık hâli - koyu
## hâli koyu şeritte görünmüyordu (ölçüldü).
const UI_SIGNAL_ESCALATED: Color = Color(1.0, 0.46, 0.40)
const UI_SIGNAL_RESOLVED: Color = Color(0.66, 0.95, 0.58)
## Yolun kenar lekeleri (g11 maskeleri beyaz; renk burada): stres kanlı bir
## mürekkep, açlık kavrulmuş bir kahve.
const UI_EDGE_STRESS: Color = Color(0.16, 0.04, 0.05)
const UI_EDGE_HUNGER: Color = Color(0.20, 0.12, 0.05)

# --- Savaş ve yol efektleri (FX) ---
# Parlama değerleri bir `modulate` çarpanı: 1.0'ın üstü "parlama" demek,
# Godot bunu kenetlemiyor. Eskiden CombatPanel'in kendi sabitleriydi -
# "renk tek yerden gelir" kuralı efektler için de geçerli.
const FX_FLASH_CRIT: Color = Color(2.0, 1.7, 0.65)
const FX_FLASH_HIT: Color = Color(1.7, 0.6, 0.55)
# Kaçırma soğuk ve berrak: isabetin sıcak kırmızısının tersi, "değmedi".
const FX_FLASH_MISS: Color = Color(1.3, 1.5, 1.7)
const FX_FLASH_REFUSE: Color = Color(0.55, 0.55, 0.6, 0.75)
const FX_FLASH_DEATHS_DOOR: Color = Color(1.4, 0.25, 0.25)
const FX_FLASH_SURVIVED: Color = Color(1.5, 1.4, 0.85)
const FX_FLASH_KILLED: Color = Color(0.35, 0.32, 0.34)
const FX_FLASH_DOWNED: Color = Color(0.5, 0.48, 0.5)
const FX_FLASH_NEUTRAL: Color = Color(1, 1, 1, 1)
# Durum efektleri: kanama isabetten koyu ve daha doygun (atardamar), zehir
# hastalıklı yeşil, sersemletme soluk altın. Hepsi hem parlama çarpanı hem
# halka/işaret rengi olarak okunur.
const FX_BLEED: Color = Color(1.35, 0.25, 0.30)
const FX_BLIGHT: Color = Color(0.85, 1.35, 0.45)
const FX_STUN: Color = Color(0.95, 0.85, 0.45)
# Savaş sayıları: hasar, kritik, şifa.
const FX_DAMAGE: Color = Color(0.93, 0.86, 0.74)
const FX_CRIT: Color = Color(1.0, 0.78, 0.30)
const FX_HEAL: Color = Color(0.62, 0.90, 0.56)
# Düşmüş ve ölü bir birimin sahadaki soluklaşması - ikisi ayrı: ölü daha da
# silik, düşen hâlâ saftaki bir boşluk.
const UI_FALLEN_ALPHA: float = 0.55
const UI_DEAD_ALPHA: float = 0.35
# Savaş açabilen olay seçeneğinin kenar çizgisi - tehlike çubuğunun
# kehribarından (UI_GAUGE_DANGER) bilerek ayrı: kan.
const UI_CHOICE_COMBAT: Color = Color(0.66, 0.19, 0.17)

# --- Gün evreleri: gökyüzü üstü/altı ve ışığın rengi ---
## Yol ve şehir aynı tabloyu okuyor, o yüzden bir sefer akşamüstü
## çıkıldığında şehir de aynı akşamüstünde görünüyor.
const PHASE_DAWN: String = "dawn"
const PHASE_DAY: String = "day"
const PHASE_DUSK: String = "dusk"
const PHASE_NIGHT: String = "night"

const SKIES: Dictionary = {
	PHASE_DAWN: {
		"top": Color(0.20, 0.24, 0.38), "bottom": Color(0.78, 0.55, 0.42),
		"light": Color(1.00, 0.86, 0.74), "haze": Color(0.72, 0.58, 0.52),
	},
	PHASE_DAY: {
		"top": Color(0.38, 0.55, 0.72), "bottom": Color(0.74, 0.81, 0.84),
		"light": Color(1.00, 0.98, 0.92), "haze": Color(0.70, 0.76, 0.80),
	},
	PHASE_DUSK: {
		"top": Color(0.17, 0.17, 0.30), "bottom": Color(0.68, 0.40, 0.32),
		"light": Color(0.96, 0.72, 0.54), "haze": Color(0.52, 0.40, 0.42),
	},
	PHASE_NIGHT: {
		"top": Color(0.045, 0.055, 0.095), "bottom": Color(0.13, 0.15, 0.22),
		"light": Color(0.58, 0.66, 0.86), "haze": Color(0.18, 0.21, 0.30),
	},
}

## Arazi paletleri. Her biyom aynı üç rolü doldurur - yakın zemin, uzak
## zemin ve bitki örtüsü - böylece yolun bir biyomdan ötekine geçmesi
## renk karışımı (lerp) ile yapılabiliyor, ani bir kesme olmuyor.
const BIOME_STEPPE: String = "steppe"
const BIOME_FOREST: String = "forest"
const BIOME_LAKE: String = "lake"
const BIOME_MOUNTAIN: String = "mountain"
const BIOME_MARSH: String = "marsh"

const TERRAIN: Dictionary = {
	BIOME_STEPPE: {
		"near": Color(0.42, 0.37, 0.24), "far": Color(0.30, 0.28, 0.20),
		"flora": Color(0.46, 0.44, 0.26), "accent": Color(0.56, 0.50, 0.32),
	},
	BIOME_FOREST: {
		"near": Color(0.26, 0.30, 0.20), "far": Color(0.17, 0.22, 0.17),
		"flora": Color(0.22, 0.38, 0.24), "accent": Color(0.32, 0.46, 0.28),
	},
	BIOME_LAKE: {
		"near": Color(0.28, 0.33, 0.34), "far": Color(0.20, 0.27, 0.31),
		"flora": Color(0.28, 0.42, 0.34), "accent": Color(0.44, 0.58, 0.60),
	},
	BIOME_MOUNTAIN: {
		"near": Color(0.34, 0.33, 0.34), "far": Color(0.24, 0.24, 0.27),
		"flora": Color(0.30, 0.34, 0.30), "accent": Color(0.58, 0.60, 0.64),
	},
	BIOME_MARSH: {
		"near": Color(0.26, 0.27, 0.21), "far": Color(0.18, 0.20, 0.18),
		"flora": Color(0.30, 0.36, 0.22), "accent": Color(0.40, 0.42, 0.30),
	},
}

## Kervan vagonunun paleti. Burada duruyor çünkü vagon iki ayrı ekranda
## çiziliyor (yol şeridi ve şehir dışı yürüyüş alanı) ve iki ayrı tabloda
## tutulunca ikisi farklı renkte bir vagon gösteriyordu.
const WAGON_BODY: Color = Color(0.40, 0.28, 0.18)
const WAGON_BODY_DARK: Color = Color(0.27, 0.19, 0.13)
const WAGON_CANVAS: Color = Color(0.80, 0.75, 0.63)
const WAGON_WHEEL: Color = Color(0.24, 0.18, 0.13)
const WAGON_LOAD: Color = Color(0.46, 0.38, 0.26)

const FALLBACK_BIOME: String = BIOME_STEPPE
const FALLBACK_PHASE: String = PHASE_DAY

static func sky(phase: String) -> Dictionary:
	return SKIES.get(phase, SKIES[FALLBACK_PHASE])

static func terrain(biome: String) -> Dictionary:
	return TERRAIN.get(biome, TERRAIN[FALLBACK_BIOME])

## İki gökyüzünü karıştırır - gün evreleri arasında ani geçiş olmasın diye
## (bkz. JourneyClock.get_phase_progress). Yol ekranı bunu her karede
## çağırıyor, o yüzden sözlük döndürüyor, nesne kurmuyor.
static func blend_sky(from_phase: String, to_phase: String, ratio: float) -> Dictionary:
	var a := sky(from_phase)
	var b := sky(to_phase)
	var t := clampf(ratio, 0.0, 1.0)
	return {
		"top": Color(a.top).lerp(b.top, t),
		"bottom": Color(a.bottom).lerp(b.bottom, t),
		"light": Color(a.light).lerp(b.light, t),
		"haze": Color(a.haze).lerp(b.haze, t),
	}

## İki araziyi karıştırır. Yol bir biyomdan ötekine geçerken renk
## kademeli değişiyor: "iki günlük orman, sonra göl" sınırı bir duvar
## değil bir geçiş olmalı.
static func blend_terrain(from_biome: String, to_biome: String, ratio: float) -> Dictionary:
	var a := terrain(from_biome)
	var b := terrain(to_biome)
	var t := clampf(ratio, 0.0, 1.0)
	return {
		"near": Color(a.near).lerp(b.near, t),
		"far": Color(a.far).lerp(b.far, t),
		"flora": Color(a.flora).lerp(b.flora, t),
		"accent": Color(a.accent).lerp(b.accent, t),
	}

## Uzaktaki her şey gökyüzünün pusuna doğru soluyor - derinlik hissinin
## tek en önemli kuralı bu (hava perspektifi). `distance` 0 yakın, 1 ufuk.
static func fade_to_haze(color: Color, haze: Color, distance: float) -> Color:
	return color.lerp(haze, clampf(distance, 0.0, 1.0) * 0.82)
