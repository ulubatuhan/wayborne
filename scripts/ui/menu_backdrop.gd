class_name MenuBackdrop
extends Control

## Ana menünün arkasındaki manzara: alçak bir güneş, sırtlar, uzakta bir
## şehir ve yatay bir yol üzerinde yürüyen bir kervan silueti.
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

## Kervan silueti bir **yatay** yol üzerinde yürüyor. İlk sürüm yolu
## ufuktaki şehre daralan bir perspektif şerit olarak çizmişti ve kervan
## kendi biçimini hiç döndürmeden yalnızca yatay kayıyordu - sonuç yol dik
## bir çizgi gibi dururken kervan onun üstünde yatay süzülüyordu, ikisi
## aynı yöne gitmiyordu. Artık ikisi de aynı şey: yol `CARAVAN_GROUND_RATIO`
## yüksekliğinde yatay bir şerit, kervan da tam o yükseklikte (`ground_y`)
## yalnızca x ekseninde ilerliyor - "yoldan çıkma" geometrik olarak imkânsız,
## çünkü kervanın tabanı hep yolun kendisi.
const CARAVAN_GROUND_RATIO: float = 0.80
const CARAVAN_SCALE: float = 0.042
## Saniyede kaç `unit` ilerlediği - gerçek bir yürüyüş temposu gibi,
## ekran genişliğine göre değil figürün kendi boyuna göre ölçekli.
const CARAVAN_SPEED_UNITS_PER_SEC: float = 2.6
## Vagon sayısı: ilk ölçüde 2'ydi (bkz. eski "küçük" notu) - istenerek
## kalabalıklaştırıldı, bir kervan bir at ve iki vagondan daha uzun bir
## şey olmalı.
const CARAVAN_WAGON_COUNT: int = 4
## Yolun kalınlığı, ekran yüksekliğine oranlı - `TravelBand._draw_road`'un
## kendi bandıyla aynı mertebede.
const ROAD_BAND_RATIO: float = 0.05

## Döngünün ne kadarının geçtiği - `_process` besliyor, `_draw` okuyor.
## Menü tek bir örnek ve maliyeti bir avuç poligon, o yüzden her karede
## `queue_redraw()` burada da `RoadCaravan._process`'in yaptığı gibi ucuz.
var _time: float = 0.0

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

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

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

	var ground_y := size.y * CARAVAN_GROUND_RATIO
	_draw_road(ground_y)
	_draw_caravan(ground_y)
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

## Yolun kendisi: yatay bir şerit tam `ground_y`'de, ekranın tamamını
## kaplıyor - `TravelBand._draw_road`'un aynı mantığı (açık bir gövde,
## koyu bir bank arkasında), ama burada eğim yok: kervan da aynı yükseklikte
## yalnızca yatay ilerlediği için ikisi hep aynı çizgide kalıyor.
func _draw_road(ground_y: float) -> void:
	var ground := ArtPalette.terrain(ArtPalette.BIOME_STEPPE)
	var road := Color(ground.near).lerp(Color(0.68, 0.60, 0.46), 0.55).darkened(0.34)
	var verge := Color(ground.near).darkened(0.58)
	var band := size.y * ROAD_BAND_RATIO

	draw_rect(Rect2(Vector2(0.0, ground_y - band * 1.3), Vector2(size.x, band * 2.6)), verge)
	draw_rect(Rect2(Vector2(0.0, ground_y - band), Vector2(size.x, band * 2.0)), road)

## Karşı ışıkta bir kervan: atlı lider, tek öküzlü dört vagon ve aralarında
## yürüyenler - `CARAVAN_WAGON_COUNT`'un notu, kalabalık ve uzun olsun diye
## istenerek büyütüldü. Yolun kolon kuralı burada da geçerli - her parça
## kendi genişliğini tüketiyor, sabit adım yok.
##
## Her figür yerel (0,0) tabanına göre çiziliyor (kervanın kendi taban
## çizgisi, ekranın değil) - `draw_set_transform` tek bir konum ile bütün
## grubu `ground_y`'ye, `_time`'ın belirlediği x'e taşıyor. **Ölçek hep
## 1.0**: kervan yakınlaşıp uzaklaşmıyor, yol boyunca yürüyor - önceki
## sürümün perspektifle küçülmesi tam da şikâyet edilen şeydi, yol yatay
## dururken kervan diyagonal bir çizgi üstünde ilerliyormuş gibi görünen
## bir çelişki yaratıyordu.
##
## Ekrana **girip çıkarak** döngüleniyor, solmuyor: `span` ekran genişliği
## artı kervanın kendi toplam boyu, `_time * hız`'ın `span`'e göre modu bir
## x konumu veriyor - kervan sağdan girip soldan çıkıyor (ya da tersi,
## `fposmod`'un işaretine bağlı), her zaman ekranın dışında başlayıp dışında
## bitiyor, yani kaybolma anı hiç görünmüyor - önceki sürümün alfa
## solmasına hiç ihtiyaç yok.
func _draw_caravan(ground_y: float) -> void:
	var unit := size.y * CARAVAN_SCALE
	var ink := ArtPalette.INK.lerp(Color(0.10, 0.09, 0.12), 0.5)

	var total_width := _walk_caravan(unit, ink, false)
	var span := size.x + total_width
	var speed := unit * CARAVAN_SPEED_UNITS_PER_SEC
	var start_x := fposmod(_time * speed, span) - total_width

	draw_set_transform(Vector2(start_x, ground_y), 0.0, Vector2.ONE)
	_walk_caravan(unit, ink, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Kolonun tek aritmetiği: `place` kapalıyken yalnızca tüketilen genişliği
## ölçer, açıkken aynı sırayla gerçekten çizer - `RoadCaravan._walk_column`
## ile aynı disiplin (bkz. Art Rules: "measuring the column and placing it
## are the same function"), iki ayrı kopya iki farklı kervan üretirdi.
##
## Lider en **büyük** yerel x'te, kuyrukta değil öncü konumda: kervan +x
## yönünde yürüyor ve atın boynu da zaten +x'e bakıyor (bkz.
## `_silhouette_rider`), o yüzden vagonlar/tayfa önce, lider en sonda -
## yürüyüş yönünde en öndeki o.
func _walk_caravan(unit: float, ink: Color, place: bool) -> float:
	var cursor := 0.0

	for wagon in CARAVAN_WAGON_COUNT:
		if place:
			_silhouette_walker(Vector2(cursor, 0.0), unit * 0.95, ink)
		cursor += unit * 1.5
		if place:
			_silhouette_ox(Vector2(cursor, 0.0), unit * 0.72, ink)
		cursor += unit * 2.2
		if place:
			_silhouette_wagon(Vector2(cursor, 0.0), unit * 1.5, ink)
		cursor += unit * 2.6

	if place:
		_silhouette_walker(Vector2(cursor, 0.0), unit * 0.92, ink)
	cursor += unit * 2.4

	if place:
		_silhouette_rider(Vector2(cursor, 0.0), unit * 1.25, ink)

	return cursor

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
