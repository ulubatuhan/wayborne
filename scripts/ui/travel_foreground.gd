class_name TravelForeground
extends Control

## Yolun **önündeki** şerit: kervanın kamera tarafında kalan her şey.
##
## Ayrı bir düğüm olmasının tek sebebi çizim sırası. Manzara şeridi
## (`TravelBand`) kendi `_draw()`'unda çiziyor, kervan onun *çocuğu*
## olduğu için üstüne biniyor - yani şeridin çizdiği hiçbir şey kervanın
## önüne geçemiyordu. Sonuç ekran görüntüsünde apaçıktı: figürler
## ağaçların üzerinde yürüyor gibi duruyordu, çünkü kameraya daha yakın
## olması gereken ağaç arkalarında kalıyordu. Bu katman kervandan
## *sonra* eklenmiş bir kardeş, o yüzden gerçekten önde.
##
## **Yolun altında yüksek bir şey olmaz.** Ağaç, çam, kaya kütlesi, dağ -
## hepsi yolun üst tarafında (uzakta). Aşağıda yalnızca çalı, ot, küçük
## taş, çamur ve su birikintisi var. Bunun sebebi perspektif: aşağısı
## kameraya en yakın yer, oraya konan bir ağaç bütün sahneyi kapatıyor
## ve zaten yolun önünde durduğu için kervanı da gizliyor.

## Hücre aralığı ve paralaks: ön plan kervandan hızlı kayıyor, derinlik
## hissinin yarısı bu farktan geliyor.
##
## Aralık **nesne boyundan türüyor**, sabit bir dünya pikseli değil. Sabit
## olduğu sürece 320 piksellik şeritte doğru çalışıyordu; yol ekranı tam
## ekrana geçip şerit ~990 piksel olunca nesne boyu üçe katlandı ama
## aralık 130'da kaldı - yani otlar ve su birikintileri birbirinin üstüne
## bindi. Boy ile sıklık aynı ölçekten gelmezse biri değiştiğinde öteki
## yalan söylüyor.
const CELL_PER_CEILING: float = 3.1
const PARALLAX: float = 1.45

## Yol kenarındaki menzil taşları da burada: yolun *önündeki* bir
## işaret, kervanın arkasında kalırsa yerde çizilmiş bir leke gibi
## duruyor.
const MILESTONE_HEIGHT: float = 26.0
const PIXELS_PER_DAY: float = 900.0

## --- Ön plan önlüğü ---
## Konsept görsellerin en güçlü kompozisyon aracı: karenin alt şeridi
## neredeyse siyah bir toprak bandı ve sahneyi o çerçeveliyor. Bizde
## yolun altı yolla aynı açık tondaydı, yani kare alttan *açılıyordu* -
## göz nereye bakacağını bilmiyor, kervan da zeminden ayrışmıyordu.
##
## Önlük yalnızca bir dolgu değil, bir derinlik kuralı: en yakın şerit en
## koyu olan. Üstündeki her şey (çalı, taş, su birikintisi) bu yüzden
## artık önlükten *açık* renkte çiziliyor - koyu zeminde koyu bir çalı
## görünmez.
const APRON_TOP_RATIO: float = 0.045
const APRON_DARKEN: float = 0.58
const APRON_INK_MIX: float = 0.30
## Alt kenara doğru bir tık daha koyu ikinci bir dilim: tek düz renk
## önlüğü bir dikdörtgen gibi gösteriyor, ikisi bir zemin gibi.
const APRON_FOOT_RATIO: float = 0.55
const APRON_FOOT_DARKEN: float = 0.34

## Aşağıdaki her şeyin tavanı. Bir çalı bundan yüksekse artık çalı
## değildir - kuralı sayıya bağlamak, ileride "biraz daha büyük olsun"
## diye kaydırılmasını zorlaştırıyor.
const MAX_PROP_HEIGHT_RATIO: float = 0.085

## Yan yana iki nesne arasındaki en az boşluk. Kolon yerleşimiyle aynı
## kural (bkz. RoadCaravan._walk_column): **her nesne kendi genişliğini
## tüketir**, bir sonraki ancak ondan sonra başlar - yoksa hücre başına
## 1-3 nesne üreten rastgele serpiştirme aynı noktaya iki çalı koyuyor.
const PROP_MIN_GAP_RATIO: float = 0.35

var _colors: Dictionary = ArtPalette.terrain(ArtPalette.BIOME_STEPPE)
var _light: Color = Color.WHITE
var _world_x: float = 0.0
var _ground_y: float = 0.0
var _slope: float = 0.0
var _wetness: float = 0.0
var _route_days: int = 1
var _caravan_x_ratio: float = 0.34

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

## Şerit her yeniden çizildiğinde durumunu buraya aktarıyor: iki ayrı
## yerde hesaplanan bir zemin çizgisi, kervanın havada yürümesiyle aynı
## sınıf hata.
func sync_state(
	colors: Dictionary, light: Color, world_x: float, ground_y: float,
	slope: float, wetness: float, route_days: int, caravan_x_ratio: float
) -> void:
	# Çapa ön ayarına güvenmiyoruz - **bu tuzak bu depoda üçüncü kez**
	# çıktı (OnboardingPanel, RoadCaravan, şimdi burası). `PRESET_FULL_RECT`
	# boyutu ancak ebeveyn *yeniden boyutlanınca* çocuğa geçiriyor; şerit
	# kendi boyunu biz eklenmeden önce aldığı için o bildirim hiç gelmiyor
	# ve katman (0,0) boyunda kalıp hiçbir şey çizmiyordu. Ekran
	# görüntüsünde belirtisi "yolun altı bomboş" idi.
	var host := get_parent_control()
	if host != null and host.size != size:
		size = host.size

	_colors = colors
	_light = light
	_world_x = world_x
	_ground_y = ground_y
	_slope = slope
	_wetness = wetness
	_route_days = maxi(1, route_days)
	_caravan_x_ratio = caravan_x_ratio
	queue_redraw()

func _draw() -> void:
	if size.y <= 1.0 or _ground_y <= 0.0:
		return
	var area := Rect2(Vector2.ZERO, size)
	# Önlük en altta ve **ilk**: üstündeki her şey ona basıyor.
	_draw_apron(area)
	_draw_low_props(area)
	_draw_milestones(area)

## Yolun hemen altından karenin dibine kadar inen koyu toprak bandı.
## Eğimi yolun kendi eğimi - ayrı hesaplanırsa yol bir yere, önlük başka
## bir yere bakar.
func _draw_apron(area: Rect2) -> void:
	var top_offset := area.size.y * APRON_TOP_RATIO
	var left := _road_y(0.0) + top_offset
	var right := _road_y(area.size.x) + top_offset
	var bottom := area.size.y

	var earth := _apron_color()
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, left), Vector2(area.size.x, right),
		Vector2(area.size.x, bottom), Vector2(0.0, bottom),
	]), earth)

	var foot := lerpf(left, bottom, APRON_FOOT_RATIO)
	var foot_right := lerpf(right, bottom, APRON_FOOT_RATIO)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, foot), Vector2(area.size.x, foot_right),
		Vector2(area.size.x, bottom), Vector2(0.0, bottom),
	]), earth.darkened(APRON_FOOT_DARKEN))

## Önlüğün rengi - biyomun kendi toprağından türüyor, yani bozkırda başka
## ormanda başka, ama her zaman sahnenin en koyu tonu.
func _apron_color() -> Color:
	var base := Color(_colors.near).darkened(APRON_DARKEN)
	return base.lerp(ArtPalette.INK, APRON_INK_MIX) * _light

## Yolun bittiği yerin altındaki y. Eğim yolu döndürüyor, ön plan da o
## döndürülmüş çizgiyi izliyor.
func _road_y(x: float) -> float:
	var centred := (x - size.x * 0.5) / maxf(1.0, size.x)
	return _ground_y - centred * _slope * size.y * 0.16

## İki geçiş, ve ayrım bir kural: **yassı lekeler zemindir, ayakta duran
## nesneler onun üstünde durur.** Su birikintisi ve çıplak toprak yere
## *boyanmış* şeyler - birbirlerine karışmaları doğal, hatta iki
## birikintinin birleşmesi gerçekçi. Çalı ve taş ise hacim: aynı noktada
## iki tanesi bir kütle gibi okunuyor ve ekranda tam olarak bu görüldü
## (otlar ve su birikintileri üst üste binmişti - birikinti otun *üstüne*
## çiziliyordu, çünkü ikisi tek bir sırada karışıktı).
func _draw_low_props(area: Rect2) -> void:
	var offset := -_world_x * PARALLAX
	var ceiling := area.size.y * MAX_PROP_HEIGHT_RATIO
	var cell_size := ceiling * CELL_PER_CEILING
	var first := int(floor((-offset - cell_size) / cell_size))
	var last := int(ceil((-offset + area.size.x + cell_size) / cell_size))
	# **Önlüğe göre açık.** Eskiden hepsi zeminden koyuydu ve zemin de
	# açıktı; önlük gelince aynı renkler koyu üstünde koyu kaldı, yani
	# yolun altı yine boş göründü. Referans nokta artık önlüğün kendisi.
	var apron := _apron_color()
	var flora := apron.lerp(Color(_colors.flora), 0.72).lightened(0.10)
	var stone := apron.lerp(Color(_colors.accent), 0.55).lightened(0.16)
	var soil := apron.lightened(0.14)

	var marks: Array[Dictionary] = []
	var props: Array[Dictionary] = []
	for cell in range(first, last + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("fore|%d" % cell)
		var count := 1 + int(rng.randf() * 3.0)
		for slot in count:
			var x := float(cell) * cell_size + offset + rng.randf_range(
				-cell_size * 0.54, cell_size * 0.54
			)
			if x < -cell_size or x > area.size.x + cell_size:
				continue
			# Yalnızca yolun *altı*: en yakın şerit. Üstü uzak, oraya
			# yüksek nesneler gidiyor (bkz. TravelBand._draw_ground_props).
			#
			# Aralık yolun altında kalan şeride oranlı, katmanın tamamına
			# değil: ilk ölçüde 0.02-0.14 sabit oranı kullanılıyordu ve
			# şerit uzayınca nesneler ekranın altına taşıyordu.
			var y := _road_y(x) + (area.size.y - _ground_y) * rng.randf_range(0.10, 0.62)
			var base := Vector2(x, y)
			var roll := rng.randf()
			if roll < 0.16 and _wetness > 0.0:
				marks.append({
					"base": base, "wide": ceiling * rng.randf_range(0.9, 2.0),
					"color": Color(0.58, 0.66, 0.72, 0.24 + _wetness * 0.26),
				})
			elif roll < 0.40:
				props.append({
					"base": base, "kind": "rock", "color": stone,
					"wide": ceiling * rng.randf_range(0.5, 1.1),
					"tall": ceiling * rng.randf_range(0.28, 0.62),
					"seed": cell * 19 + slot,
				})
			elif roll < 0.86:
				props.append({
					"base": base, "kind": "shrub", "color": flora,
					"wide": ceiling * rng.randf_range(0.6, 1.2),
					"tall": ceiling * rng.randf_range(0.45, 1.0),
					"seed": cell * 31 + slot,
				})
			else:
				# Çıplak toprak lekesi: her yerin yeşil olmaması gerekiyor.
				marks.append({
					"base": base, "wide": ceiling * rng.randf_range(1.0, 2.2),
					"color": soil,
				})

	for mark in marks:
		var mark_base: Vector2 = mark.base
		var mark_wide: float = mark.wide
		ArtDraw.ellipse(
			self, mark_base, Vector2(mark_wide, ceiling * 0.20), mark.color
		)

	# Ayakta duranlar soldan sağa yürünüyor ve her biri kendi genişliğini
	# tüketiyor; sığmayan eleniyor. Sıralama şart: hücreler artan sırada
	# üretiliyor ama hücre içindeki serpiştirme sırayı bozuyor.
	props.sort_custom(func(a, b): return float(a.base.x) < float(b.base.x))
	var occupied := -INF
	for prop in props:
		var prop_base: Vector2 = prop.base
		var prop_wide: float = prop.wide
		if prop_base.x - prop_wide * 0.5 < occupied:
			continue
		occupied = prop_base.x + prop_wide * 0.5 + ceiling * PROP_MIN_GAP_RATIO
		if prop.kind == "rock":
			ArtDraw.contact_shadow(self, prop_base, prop_wide * 1.2, 0.17)
			ArtDraw.rock(self, prop_base, prop_wide, prop.tall, prop.color, prop.seed)
		else:
			ArtDraw.contact_shadow(self, prop_base, prop_wide * 1.1, 0.14)
			ArtDraw.shrub(self, prop_base, prop_wide, prop.tall, prop.color, prop.seed)

## Yolda her gün bir taş: oyuncu ilerleme çubuğuna bakmadan da kaç gün
## kaldığını okuyor.
func _draw_milestones(area: Rect2) -> void:
	for day in range(1, _route_days + 1):
		var x := area.size.x * _caravan_x_ratio + (float(day) * PIXELS_PER_DAY - _world_x)
		if x < -40.0 or x > area.size.x + 40.0:
			continue
		var base := Vector2(x, _road_y(x) + area.size.y * 0.085)
		var h := MILESTONE_HEIGHT
		ArtDraw.contact_shadow(self, base, h * 0.70, 0.20)
		ArtDraw.inked(self, PackedVector2Array([
			base + Vector2(-h * 0.22, 0.0),
			base + Vector2(-h * 0.18, -h * 0.82),
			base + Vector2(0.0, -h),
			base + Vector2(h * 0.18, -h * 0.82),
			base + Vector2(h * 0.22, 0.0),
		]), Color(0.46, 0.44, 0.40) * _light, 1.2)
