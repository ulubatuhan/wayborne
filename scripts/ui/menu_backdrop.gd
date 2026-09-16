class_name MenuBackdrop
extends Control

## Ana menünün arkasındaki manzara: alçak bir güneş, sırtlar, uzakta bir
## şehir ve ufka doğru yürüyen bir kervan silueti.
##
## Oyunun **ilk gördüğü ekran** buydu ve hiç çizilmemişti: düz gri bir
## zemin üstünde dört buton. Yol sahnesi, savaş ve şehir çizilmişken
## menünün boş kalması, oyunun kendini tanıttığı yerde hiçbir şey
## söylememesi demek.
##
## Şerit (`TravelBand`) burada kullanılmıyor, çünkü o bir *sefere* bağlı -
## arazi, hava, ilerleme, zemin çizgisi, kervan düğümü. Menüde bunların
## hiçbiri yok. Ortak olan şey palet ve fırçalar: renkler `ArtPalette`'ten,
## şekiller `ArtDraw`'dan geliyor, yani menü yolun devamı gibi duruyor
## ama onun makinesini taşımıyor.
##
## Kervan burada **siluet**: `WalkFigure`/`RoadCaravan` kurmak, yürüyen
## eklemli figürler ve gerçek bir oturum ister. Menüde kervan bir anı,
## bir sahne değil - konsept görselin de yaptığı gibi tek renk, karşı
## ışıkta.

## Gökyüzü akşam paletinden: menü günün sonunda, yola çıkmadan önceki an.
const SKY_PHASE: String = ArtPalette.PHASE_DUSK

const HORIZON_RATIO: float = 0.72
const SUN_Y_RATIO: float = 0.60
const SUN_X_RATIO: float = 0.70
const SUN_RADIUS_RATIO: float = 0.048
## Alçak güneşin halesi geniş, o yüzden halka sayısı da yüksek: 16 halka
## bu yarıçapta iç içe daireler olarak görünüyordu.
const SUN_GLOW_RINGS: int = 64

## Sırt katmanları: uzaktan yakına taban y'si, genlik, dalga boyu ve
## pusa karışma payı. Üçü birden bir `depth` gibi davranıyor (bkz. Art
## Rules: boy, pus ve taban tek bir derinlikten gelir).
##
## **Taban ufkun üstünde olmalı.** İlk ölçüde 0.70/0.78/0.86 yazıyordu,
## yani üçü de ufkun (0.72) altındaydı ve zemin dolgusu hepsini
## boyuyordu - ekranda yalnızca bir tepenin ucu görünüyordu. Zemin
## sırtlardan *sonra* çiziliyor, çünkü ufkun altı ufkun üstünün önünde.
const RIDGES: Array = [
	[0.715, 0.088, 0.66, 0.70],
	[0.722, 0.058, 0.43, 0.44],
	[0.728, 0.034, 0.29, 0.18],
]

## Uzaktaki şehir: ufuk çizgisinin üstünde durur, yoksa zemin onu da
## boyar - sırtlarla aynı sebep.
const CITY_X_RATIO: float = 0.22
const CITY_HEIGHT_RATIO: float = 0.060

## Kervan silueti: ufkun hemen altında, sağa doğru yürüyor. **Küçük**:
## ilk ölçüde 0.088 idi ve karenin alt üçte birini kaplayan lekelere
## dönüşüyordu - menüde kervan bir hatıra, sahnenin kendisi değil.
const CARAVAN_GROUND_RATIO: float = 0.80
const CARAVAN_START_RATIO: float = 0.10
const CARAVAN_SCALE: float = 0.042

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Çapa ön ayarı boyutu ancak ebeveyn *yeniden boyutlanınca* veriyor -
	# bu tuzak bu depoda dört kez çıktı (bkz. Art Rules). Ebeveynin boyunu
	# açıkça alıyoruz.
	resized.connect(queue_redraw)
	var host := get_parent_control()
	if host != null:
		size = host.size

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var host := get_parent_control()
	if host != null and host.size != size:
		size = host.size

	var area := Rect2(Vector2.ZERO, size)
	var sky := ArtPalette.sky(SKY_PHASE)
	var horizon := size.y * HORIZON_RATIO

	ArtDraw.gradient_band(
		self, Rect2(Vector2.ZERO, Vector2(size.x, horizon + 2.0)),
		Color(sky.top), Color(sky.bottom)
	)
	_draw_sun(horizon)
	_draw_ridges(area, horizon, Color(sky.haze))
	_draw_ground(area, horizon, Color(sky.haze))
	_draw_caravan(area)
	ArtDraw.vignette(self, area, 0.14)

## Alçak güneş ve etrafındaki halka. Konsept görselin bütün kompozisyonu
## buna dayanıyor: ufka yakın tek bir sıcak nokta, gerisi siluet.
func _draw_sun(horizon: float) -> void:
	var centre := Vector2(size.x * SUN_X_RATIO, size.y * SUN_Y_RATIO)
	var radius := size.y * SUN_RADIUS_RATIO
	ArtDraw.light_pool(
		self, centre, radius * 8.0, Color(1.0, 0.82, 0.52), 0.30, 1.0, SUN_GLOW_RINGS
	)
	draw_circle(centre, radius, Color(1.0, 0.93, 0.76))

func _draw_ridges(area: Rect2, horizon: float, haze: Color) -> void:
	var rock := ArtPalette.terrain(ArtPalette.BIOME_MOUNTAIN)
	for index in RIDGES.size():
		var layer: Array = RIDGES[index]
		var base_y := size.y * float(layer[0])
		var color := ArtPalette.fade_to_haze(
			Color(rock.far).darkened(0.30), haze, float(layer[3])
		)
		ArtDraw.ridge(
			self, area, base_y, size.y * float(layer[1]),
			size.x * float(layer[2]), float(index) * 340.0, color, 4100 + index * 17
		)

	# Uzakta bir şehir: menüde bile oyunun hedefi görünüyor. Yol
	# şeridiyle **aynı fırça** (bkz. ArtDraw.city_silhouette).
	ArtDraw.city_silhouette(
		self, Vector2(size.x * CITY_X_RATIO, horizon + size.y * 0.004),
		size.y * CITY_HEIGHT_RATIO,
		ArtPalette.fade_to_haze(Color(rock.far).darkened(0.46), haze, 0.30)
	)

## Ufkun altındaki zemin: menüde tek bir koyu kütle. Yol sahnesindeki
## katmanları buraya taşımak, menüyü bir sefer ekranına çevirirdi.
func _draw_ground(area: Rect2, horizon: float, haze: Color) -> void:
	var ground := ArtPalette.terrain(ArtPalette.BIOME_STEPPE)
	var near := Color(ground.near).darkened(0.62).lerp(ArtPalette.INK, 0.34)
	ArtDraw.gradient_band(
		self, Rect2(Vector2(0.0, horizon), Vector2(size.x, size.y - horizon)),
		ArtPalette.fade_to_haze(near.lightened(0.10), haze, 0.18), near
	)

## Karşı ışıkta bir kervan: atlı lider, tek öküzlü iki vagon ve aralarında
## yürüyenler. Yolun kolon kuralı burada da geçerli - her parça kendi
## genişliğini tüketiyor, sabit adım yok. Yol tarafı çift öküzden tek öküze
## döndüğünde (bkz. CLAUDE.md Art Rules) bu bağımsız siluet de aynı geçişi
## yaptı - iki kervan aynı hayvanı çekmeli.
func _draw_caravan(area: Rect2) -> void:
	var unit := size.y * CARAVAN_SCALE
	var ground_y := size.y * CARAVAN_GROUND_RATIO
	var ink := ArtPalette.INK.lerp(Color(0.10, 0.09, 0.12), 0.5)
	var cursor := area.size.x * CARAVAN_START_RATIO

	_silhouette_rider(Vector2(cursor, ground_y), unit * 1.25, ink)
	cursor += unit * 2.4

	for wagon in 2:
		_silhouette_walker(Vector2(cursor, ground_y), unit * 0.95, ink)
		cursor += unit * 1.5
		_silhouette_ox(Vector2(cursor, ground_y), unit * 0.72, ink)
		cursor += unit * 2.2
		_silhouette_wagon(Vector2(cursor, ground_y), unit * 1.5, ink)
		cursor += unit * 2.6

	_silhouette_walker(Vector2(cursor, ground_y), unit * 0.92, ink)

## Gövde **zemine kadar inmiyor**; ilk hâlinde iniyordu ve bacaklar onun
## *içine* çiziliyordu, yani siluet bir insan değil bir labut gibi
## okunuyordu. Siluette bir şekli okunur kılan, kütlenin kendisi değil
## kütleyi bölen boşluk.
func _silhouette_walker(base: Vector2, height: float, ink: Color) -> void:
	var w := height * 0.28
	var hip := base.y - height * 0.40
	ArtDraw.contact_shadow(self, base, w * 2.0, 0.30)
	draw_rect(Rect2(Vector2(base.x - w * 0.5, base.y - height * 0.80), Vector2(w, height * 0.40)), ink, true)
	draw_circle(Vector2(base.x, base.y - height * 0.87), height * 0.10, ink)
	# Bacaklar açık: kapalı bacak yine tek kütle demek. Öndeki adım
	# atıyor, arkadaki basıyor.
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(base.x - w * 0.22, hip),
			Vector2(base.x + w * 0.22, hip),
			Vector2(base.x + side * w * 0.52 + w * 0.13, base.y),
			Vector2(base.x + side * w * 0.52 - w * 0.13, base.y),
		]), ink)

## Bacak boyu **zeminden** hesaplanıyor. İlk hâlinde sabit bir orandı
## (`height * 0.52`) ve gövdenin altından başladığı için zemin çizgisinin
## altına taşıyordu: siluet bir attan çok dört ayaklı bir sehpa gibi
## okunuyordu.
func _silhouette_rider(base: Vector2, height: float, ink: Color) -> void:
	var body_w := height * 0.95
	var body_h := height * 0.30
	var back := base.y - height * 0.58
	var belly := back + body_h
	ArtDraw.contact_shadow(self, base, body_w * 1.1, 0.30)
	draw_rect(Rect2(Vector2(base.x - body_w * 0.5, back), Vector2(body_w, body_h)), ink, true)

	# Boyun öne ve yukarı doğru inceliyor, başı da taşıyor - dikdörtgen bir
	# boyun atı eşeğe çeviriyor.
	draw_colored_polygon(PackedVector2Array([
		Vector2(base.x + body_w * 0.30, back),
		Vector2(base.x + body_w * 0.50, back - height * 0.30),
		Vector2(base.x + body_w * 0.64, back - height * 0.28),
		Vector2(base.x + body_w * 0.48, back + body_h * 0.5),
	]), ink)
	draw_colored_polygon(PackedVector2Array([
		Vector2(base.x + body_w * 0.48, back - height * 0.32),
		Vector2(base.x + body_w * 0.78, back - height * 0.26),
		Vector2(base.x + body_w * 0.76, back - height * 0.17),
		Vector2(base.x + body_w * 0.48, back - height * 0.20),
	]), ink)

	for index in 4:
		var lx := base.x - body_w * 0.38 + float(index) * body_w * 0.25
		draw_rect(
			Rect2(Vector2(lx, belly), Vector2(height * 0.075, base.y - belly)), ink, true
		)

	# Binici: gövde + baş, atın sağrısının biraz önünde.
	var seat := base.x - body_w * 0.06
	draw_rect(Rect2(
		Vector2(seat - height * 0.09, back - height * 0.33), Vector2(height * 0.18, height * 0.33)
	), ink, true)
	draw_circle(Vector2(seat, back - height * 0.39), height * 0.095, ink)

func _silhouette_ox(base: Vector2, height: float, ink: Color) -> void:
	var body_w := height * 1.65
	var body_h := height * 0.58
	var back := base.y - height * 0.86
	ArtDraw.contact_shadow(self, base, body_w * 0.9, 0.28)
	# Omuz hörgücü siluetin kendisinde: üstüne yapıştırılan bir tümsek
	# hayvanın ensesine takılmış bir disk gibi duruyor (bkz. Art Rules).
	draw_colored_polygon(PackedVector2Array([
		Vector2(base.x - body_w * 0.5, back + body_h),
		Vector2(base.x - body_w * 0.46, back + body_h * 0.25),
		Vector2(base.x - body_w * 0.05, back - body_h * 0.18),
		Vector2(base.x + body_w * 0.28, back + body_h * 0.05),
		Vector2(base.x + body_w * 0.5, back + body_h * 0.30),
		Vector2(base.x + body_w * 0.5, back + body_h),
	]), ink)
	draw_colored_polygon(PackedVector2Array([
		Vector2(base.x + body_w * 0.42, back + body_h * 0.20),
		Vector2(base.x + body_w * 0.74, back + body_h * 0.10),
		Vector2(base.x + body_w * 0.80, back + body_h * 0.52),
		Vector2(base.x + body_w * 0.46, back + body_h * 0.56),
	]), ink)
	for index in 4:
		var lx := base.x - body_w * 0.34 + float(index) * body_w * 0.22
		draw_rect(
			Rect2(Vector2(lx, back + body_h), Vector2(height * 0.10, base.y - back - body_h)), ink, true
		)

## Oranlar ölçüldü. İlk hâlinde branda gövdeden yüksekti (toplam boy
## genişliğin 0.92'si) ve siluet bir mantar gibi okunuyordu: kocaman
## yuvarlak bir kütle, altında iki çentik. Bir kervan vagonu uzundur,
## yüksek değil - toplam boy genişliğin üçte ikisini geçmemeli.
## Siluette vagonu vagon yapan şey **omuz**: brandanın kasadan dar
## olması. Branda kasayla aynı genişlikteyken (0.48 ↔ 0.50) ikisi tek bir
## kemer oluyordu ve tekerlekler de aynı renkte olduğu için o kemerin
## altına kaynıyordu - ekranda bir tünel duruyordu, bir araba değil.
func _silhouette_wagon(base: Vector2, width: float, ink: Color) -> void:
	var body_h := width * 0.20
	var wheel_r := width * 0.19
	var bed := base.y - wheel_r * 1.15
	var canopy_half := width * 0.36
	ArtDraw.contact_shadow(self, base, width * 1.1, 0.30)
	draw_rect(Rect2(Vector2(base.x - width * 0.5, bed - body_h), Vector2(width, body_h)), ink, true)

	# Branda: basık bir yarım kubbe. Yay tabanda kapanıyor, taban kenarı
	# ayrıca eklenmiyor (bkz. Art Rules - üçgenleme sessizce başarısız olur).
	var points := PackedVector2Array()
	for step in 15:
		var angle := PI + float(step) / 14.0 * PI
		points.append(Vector2(
			base.x + cos(angle) * canopy_half,
			bed - body_h + sin(angle) * width * 0.30
		))
	draw_colored_polygon(points, ink)

	# Tekerlekler kasanın *altına* taşıyor ve aralarındaki boşluk açık
	# kalıyor; dolu bir alt kenar aracı bir sandığa çevirir.
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(base.x + side * width * 0.31, base.y - wheel_r), wheel_r, ink)
