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

## Hücre aralığı (dünya pikseli) ve paralaks: ön plan kervandan hızlı
## kayıyor, derinlik hissinin yarısı bu farktan geliyor.
const CELL: float = 130.0
const PARALLAX: float = 1.45

## Yol kenarındaki menzil taşları da burada: yolun *önündeki* bir
## işaret, kervanın arkasında kalırsa yerde çizilmiş bir leke gibi
## duruyor.
const MILESTONE_HEIGHT: float = 26.0
const PIXELS_PER_DAY: float = 900.0

## Aşağıdaki her şeyin tavanı. Bir çalı bundan yüksekse artık çalı
## değildir - kuralı sayıya bağlamak, ileride "biraz daha büyük olsun"
## diye kaydırılmasını zorlaştırıyor.
const MAX_PROP_HEIGHT_RATIO: float = 0.085

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
	_draw_low_props(area)
	_draw_milestones(area)

## Yolun bittiği yerin altındaki y. Eğim yolu döndürüyor, ön plan da o
## döndürülmüş çizgiyi izliyor.
func _road_y(x: float) -> float:
	var centred := (x - size.x * 0.5) / maxf(1.0, size.x)
	return _ground_y - centred * _slope * size.y * 0.16

func _draw_low_props(area: Rect2) -> void:
	var offset := -_world_x * PARALLAX
	var first := int(floor((-offset - CELL) / CELL))
	var last := int(ceil((-offset + area.size.x + CELL) / CELL))
	var ceiling := area.size.y * MAX_PROP_HEIGHT_RATIO
	var flora := Color(_colors.flora).darkened(0.22) * _light
	var stone := Color(_colors.near).lerp(Color(_colors.accent), 0.28) * _light
	var soil := Color(_colors.near).darkened(0.18) * _light

	for cell in range(first, last + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("fore|%d" % cell)
		var count := 1 + int(rng.randf() * 3.0)
		for slot in count:
			var x := float(cell) * CELL + offset + rng.randf_range(-70.0, 70.0)
			if x < -120.0 or x > area.size.x + 120.0:
				continue
			# Yalnızca yolun *altı*: en yakın şerit. Üstü uzak, oraya
			# yüksek nesneler gidiyor (bkz. TravelBand._draw_ground_props).
			#
			# Aralık dar çünkü görünür alan dar: yol şeridin %84'ünde
			# bitiyor, altında yetmiş piksel kalıyor. İlk ölçüde
			# 0.10-0.34 yazıyordu ve nesnelerin çoğu ekranın altına
			# taşıp kırpılıyordu - aşağısı bomboş görünüyordu.
			var y := _road_y(x) + area.size.y * rng.randf_range(0.02, 0.14)
			var base := Vector2(x, y)
			var roll := rng.randf()
			if roll < 0.16 and _wetness > 0.0:
				# Yağmurda su birikintisi: hava ile zeminin bağlandığı yer.
				ArtDraw.ellipse(
					self, base,
					Vector2(ceiling * rng.randf_range(0.9, 2.0), ceiling * 0.22),
					Color(0.58, 0.66, 0.72, 0.24 + _wetness * 0.26)
				)
			elif roll < 0.40:
				ArtDraw.rock(
					self, base, ceiling * rng.randf_range(0.5, 1.1),
					ceiling * rng.randf_range(0.28, 0.62), stone, cell * 19 + slot
				)
			elif roll < 0.86:
				ArtDraw.shrub(
					self, base, ceiling * rng.randf_range(0.6, 1.2),
					ceiling * rng.randf_range(0.45, 1.0), flora, cell * 31 + slot
				)
			else:
				# Çıplak toprak lekesi: her yerin yeşil olmaması gerekiyor.
				ArtDraw.ellipse(
					self, base, Vector2(ceiling * rng.randf_range(1.0, 2.2), ceiling * 0.20),
					soil
				)

## Yolda her gün bir taş: oyuncu ilerleme çubuğuna bakmadan da kaç gün
## kaldığını okuyor.
func _draw_milestones(area: Rect2) -> void:
	for day in range(1, _route_days + 1):
		var x := area.size.x * _caravan_x_ratio + (float(day) * PIXELS_PER_DAY - _world_x)
		if x < -40.0 or x > area.size.x + 40.0:
			continue
		var base := Vector2(x, _road_y(x) + area.size.y * 0.085)
		var h := MILESTONE_HEIGHT
		ArtDraw.inked(self, PackedVector2Array([
			base + Vector2(-h * 0.22, 0.0),
			base + Vector2(-h * 0.18, -h * 0.82),
			base + Vector2(0.0, -h),
			base + Vector2(h * 0.18, -h * 0.82),
			base + Vector2(h * 0.22, 0.0),
		]), Color(0.46, 0.44, 0.40) * _light, 1.2)
