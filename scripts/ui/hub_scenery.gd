class_name HubScenery
extends Node2D

## Şehrin dışındaki kır - kervanın şehir kapısına yürüdüğü şerit.
##
## Öncesinde iki `ColorRect` (bir gökyüzü, bir zemin) ve on dört çizgiden
## oluşuyordu. Yol ekranıyla aynı şikâyet, aynı sebep: renkli
## dikdörtgenler bir yer tutucu olabilir ama bir manzara değil.
##
## Yol şeridinden (`TravelBand`) ayrı bir dosya olmasının sebebi kamera:
## burada kamera dünyanın üstünde geziyor (`Node2D`, gerçek dünya
## koordinatları), orada dünya kervanın altından akıyor (`Control`, sabit
## bir şerit). Paralaks ikisinde farklı çalışıyor, ama **palet ve
## fırçalar aynı** (`ArtPalette` / `ArtDraw`) - ikisi bir oyun gibi
## görünmesi buradan geliyor.
##
## Her şey bir kez çiziliyor: manzara durağan, kamera hareket ediyor.
## Bu yüzden `_process` yok - aynı şeyi her karede yeniden çizmek Web
## hedefinde bedava değil.
##
## **İki katman var ve ikisi ayrı düğüm.** `LAYER_BACK` yolun üstündeki
## her şeyi çiziyor (gökyüzü, sırtlar, zemin, yol, ağaçlar) ve kervanın
## arkasında duruyor; `LAYER_FRONT` yolun altındaki alçak şeyleri
## çiziyor ve kervanın *önünde* duruyor. Tek katman olduğunda iki kusur
## birden çıkıyordu: yolun altına düşen ağaçlar kameraya en yakın yeri
## kapatıyordu, ve hepsi kervanın arkasında kaldığı için figürler
## ağaçların üzerinde yürüyor gibi duruyordu.
##
## **Yolun altında yüksek bir şey olmaz.** Aşağıda yalnızca çalı, ot,
## küçük taş, çamur ve su birikintisi; ağaç, kaya kütlesi ve dağ hep
## yukarıda.

## Kır her zaman şehrin çevresi: bozkırdan biraz daha yeşil, çünkü şehir
## ekilebilir toprağın olduğu yere kurulur.
const BIOME: String = ArtPalette.BIOME_STEPPE

const SKY_TOP_RATIO: float = 0.0
const HORIZON_RATIO: float = 0.62

## Ağaç/kaya/çalı aralıkları (dünya pikseli).
const CELL_FAR_TREES: float = 210.0
const CELL_NEAR: float = 150.0

const LAYER_BACK: String = "back"
const LAYER_FRONT: String = "front"

## Yolun altındaki hiçbir şey bundan yüksek olamaz. Kuralı bir sayıya
## bağlamak, ileride "biraz daha büyük olsun" diye kaydırılmasını
## zorlaştırıyor.
const MAX_FRONT_HEIGHT: float = 46.0

var _area: Rect2 = Rect2()
var _ground_y: float = 0.0
var _seed: int = 0
var _layer: String = LAYER_BACK

func setup(
	area: Rect2, ground_y: float, city_id: String, layer: String = LAYER_BACK
) -> void:
	_area = area
	_ground_y = ground_y
	_layer = layer
	# Manzara şehirden şehre değişiyor: aynı kapıya her seferinde aynı
	# ağaçların arasından yürüyorsun, ama başka bir şehirde başka
	# ağaçlar var.
	_seed = hash("hub|%s" % city_id)
	queue_redraw()

func _draw() -> void:
	if _area.size.x <= 0.0:
		return
	if _layer == LAYER_FRONT:
		_draw_front()
		return
	var sky := ArtPalette.sky(ArtPalette.PHASE_DAY)
	var colors := ArtPalette.terrain(BIOME)
	var haze := Color(sky.haze)

	# Gökyüzü ufka kadar.
	ArtDraw.gradient_band(
		self,
		Rect2(_area.position, Vector2(_area.size.x, _ground_y - _area.position.y)),
		Color(sky.top), Color(sky.bottom)
	)

	# İki sırt: uzak olan pusun içinde, yakın olan araziyi taşıyor.
	ArtDraw.ridge(
		self, _area, _ground_y - 24.0, 96.0, _area.size.x * 0.30, 0.0,
		ArtPalette.fade_to_haze(Color(colors.far), haze, 0.52), _seed + 3
	)
	ArtDraw.ridge(
		self, _area, _ground_y - 6.0, 54.0, _area.size.x * 0.16, 0.0,
		ArtPalette.fade_to_haze(Color(colors.far), haze, 0.26), _seed + 11
	)

	# Zemin.
	ArtDraw.gradient_band(
		self,
		Rect2(
			Vector2(_area.position.x, _ground_y),
			Vector2(_area.size.x, _area.position.y + _area.size.y - _ground_y)
		),
		ArtPalette.fade_to_haze(Color(colors.far), haze, 0.10), Color(colors.near)
	)

	_draw_road()
	_draw_flora(colors, haze)

## Kervanın yürüdüğü yol: iki yanında koyu bank, üstünde tekerlek izleri.
## Yolun okunması banklardan geliyor, kendi renginden değil (aynı ders
## yol ekranında da alındı).
func _draw_road() -> void:
	var colors := ArtPalette.terrain(BIOME)
	var near := Color(colors.near)
	var road := near.lerp(Color(0.68, 0.60, 0.46), 0.62)
	var band := 74.0

	draw_rect(Rect2(
		Vector2(_area.position.x, _ground_y - band * 0.16),
		Vector2(_area.size.x, band * 1.5)
	), near.darkened(0.28), true)
	draw_rect(Rect2(
		Vector2(_area.position.x, _ground_y - band * 0.06),
		Vector2(_area.size.x, band)
	), road, true)
	for lane in [0.26, 0.62]:
		draw_line(
			Vector2(_area.position.x, _ground_y + band * lane),
			Vector2(_area.position.x + _area.size.x, _ground_y + band * lane),
			road.darkened(0.24), 3.0
		)

	# Çakıl: yolun dokusu.
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + 77
	for _index in 120:
		var x := _area.position.x + rng.randf() * _area.size.x
		draw_circle(
			Vector2(x, _ground_y + band * rng.randf_range(-0.02, 0.92)),
			rng.randf_range(1.2, 3.0), road.darkened(rng.randf_range(0.05, 0.30))
		)

## Yolun **üstündeki** bitki örtüsü: ağaçlar ve çamlar. Hepsi uzak
## kenarda, çünkü aşağısı kameraya en yakın yer ve oraya konan bir ağaç
## hem sahneyi hem kervanı kapatıyor.
func _draw_flora(colors: Dictionary, haze: Color) -> void:
	var far_flora := ArtPalette.fade_to_haze(Color(colors.flora), haze, 0.22)
	var far_trunk := ArtPalette.fade_to_haze(Color(colors.near).darkened(0.40), haze, 0.22)
	var count := int(_area.size.x / CELL_FAR_TREES)
	for index in count:
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed + index * 31
		if rng.randf() > 0.72:
			continue
		var x := _area.position.x + float(index) * CELL_FAR_TREES + rng.randf_range(-60.0, 60.0)
		var base := Vector2(x, _ground_y - rng.randf_range(18.0, 58.0))
		if rng.randf() < 0.35:
			ArtDraw.conifer(self, base, rng.randf_range(100.0, 170.0), far_trunk, far_flora)
		else:
			ArtDraw.tree(self, base, rng.randf_range(90.0, 145.0), far_trunk, far_flora)

## Yolun **altı**: kervanın önünde kalan şerit. Yalnızca alçak şeyler -
## çalı, ot, küçük taş, çamur lekesi.
func _draw_front() -> void:
	var colors := ArtPalette.terrain(BIOME)
	var flora := Color(colors.flora).darkened(0.20)
	var stone := Color(colors.near).lerp(Color(colors.accent), 0.28)
	var soil := Color(colors.near).darkened(0.20)
	var count := int(_area.size.x / CELL_NEAR)
	for index in count:
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed + index * 57 + 9
		var slots := 1 + int(rng.randf() * 2.0)
		for slot in slots:
			var x := _area.position.x + float(index) * CELL_NEAR + rng.randf_range(-60.0, 60.0)
			var base := Vector2(x, _ground_y + rng.randf_range(96.0, 230.0))
			var roll := rng.randf()
			if roll < 0.24:
				ArtDraw.rock(
					self, base, rng.randf_range(24.0, MAX_FRONT_HEIGHT),
					rng.randf_range(12.0, MAX_FRONT_HEIGHT * 0.55), stone,
					_seed + index * 7 + slot
				)
			elif roll < 0.82:
				ArtDraw.shrub(
					self, base, rng.randf_range(30.0, MAX_FRONT_HEIGHT),
					rng.randf_range(20.0, MAX_FRONT_HEIGHT), flora,
					_seed + index * 13 + slot
				)
			else:
				ArtDraw.ellipse(
					self, base,
					Vector2(rng.randf_range(30.0, 70.0), rng.randf_range(6.0, 13.0)), soil
				)
