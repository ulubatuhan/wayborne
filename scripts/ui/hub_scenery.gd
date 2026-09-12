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

## Kır her zaman şehrin çevresi: bozkırdan biraz daha yeşil, çünkü şehir
## ekilebilir toprağın olduğu yere kurulur.
const BIOME: String = ArtPalette.BIOME_STEPPE

const SKY_TOP_RATIO: float = 0.0
const HORIZON_RATIO: float = 0.62

## Ağaç/kaya/çalı aralıkları (dünya pikseli).
const CELL_FAR_TREES: float = 210.0
const CELL_NEAR: float = 150.0

var _area: Rect2 = Rect2()
var _ground_y: float = 0.0
var _seed: int = 0

func setup(area: Rect2, ground_y: float, city_id: String) -> void:
	_area = area
	_ground_y = ground_y
	# Manzara şehirden şehre değişiyor: aynı kapıya her seferinde aynı
	# ağaçların arasından yürüyorsun, ama başka bir şehirde başka
	# ağaçlar var.
	_seed = hash("hub|%s" % city_id)
	queue_redraw()

func _draw() -> void:
	if _area.size.x <= 0.0:
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

## Bitki örtüsü iki katmanda: yolun *gerisinde* (ufka doğru, soluk ve
## küçük) ve yolun *önünde* (koyu, büyük, kervanın önünden geçiyor).
func _draw_flora(colors: Dictionary, haze: Color) -> void:
	var far_flora := ArtPalette.fade_to_haze(Color(colors.flora), haze, 0.22)
	var far_trunk := ArtPalette.fade_to_haze(Color(colors.near).darkened(0.40), haze, 0.22)
	var count := int(_area.size.x / CELL_FAR_TREES)
	for index in count:
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed + index * 31
		if rng.randf() > 0.68:
			continue
		var x := _area.position.x + float(index) * CELL_FAR_TREES + rng.randf_range(-60.0, 60.0)
		var base := Vector2(x, _ground_y - rng.randf_range(14.0, 42.0))
		if rng.randf() < 0.35:
			ArtDraw.conifer(self, base, rng.randf_range(90.0, 150.0), far_trunk, far_flora)
		else:
			ArtDraw.tree(self, base, rng.randf_range(80.0, 130.0), far_trunk, far_flora)

	var near_count := int(_area.size.x / CELL_NEAR)
	for index in near_count:
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed + index * 57 + 9
		var roll := rng.randf()
		var x := _area.position.x + float(index) * CELL_NEAR + rng.randf_range(-50.0, 50.0)
		var base := Vector2(x, _ground_y + rng.randf_range(84.0, 190.0))
		if roll < 0.26:
			ArtDraw.rock(
				self, base, rng.randf_range(50.0, 96.0), rng.randf_range(28.0, 54.0),
				Color(colors.near).lerp(Color(colors.accent), 0.30), _seed + index
			)
		elif roll < 0.72:
			ArtDraw.shrub(
				self, base, rng.randf_range(50.0, 90.0), rng.randf_range(34.0, 62.0),
				Color(colors.flora).darkened(0.18), _seed + index * 7
			)
		else:
			ArtDraw.tree(
				self, base, rng.randf_range(150.0, 230.0),
				Color(colors.near).darkened(0.48), Color(colors.flora).darkened(0.08)
			)
