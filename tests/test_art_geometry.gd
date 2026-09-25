extends RefCounted

## Manzaranın **geometrisi**, görünüşü değil.
##
## Bu depoda yapısal testler yerleşimi doğrular, görünüşü asla - onun
## için ekran görüntüsü araçları var. Ama tek bir görsel kusur bir kez
## daha geri döndü ve sebebi geometrikti, dolayısıyla ölçülebilir:
## *"ağaçlar havada duruyor."* Ağacın tabanı bir formülden, üstünde
## durduğu sırtın çizilen kenarı başka bir formülden geliyordu. `ridge`
## sinüsü `step` aralıklarla örnekleyip aralarını **düz** çiziyor, yani
## gerçek kenar sinüsün kendisi değil o kırık çizgi; sürekli sinüsten
## hesaplanan bir taban sırtın tepesinde nesneyi havada bırakıyor.
##
## Burada iddia edilen şey tek: `ridge_y` her x'te `ridge`'in gerçekten
## çizdiği çokgenin kenarına düşüyor. Bir de kar başlığının kar
## çizgisinin altına taşmadığı - `ridge_snow`'un tamamı bu sınıra bağlı.

const EPSILON: float = 0.001

func suite_name() -> String:
	return "ArtGeometry"

func run(t) -> void:
	_test_ridge_y_lands_on_the_drawn_edge(t)
	_test_ridge_y_stays_inside_the_amplitude(t)
	_test_ridge_is_reproducible(t)
	_test_snow_never_reaches_below_the_snow_line(t)
	_test_a_low_ridge_gets_no_snow(t)
	_test_contact_shadow_is_flat(t)
	_test_vignette_strips_tile_without_overlap_or_gap(t)
	_test_vignette_bottom_strip_stops_at_side_strips(t)

func _area() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(1500.0, 460.0))

## Çizilen çokgenin üst kenarında, verilen x'teki y. Testin kendi
## interpolasyonu var çünkü doğrulanan tam da `ridge_y`'nin bu kenarla
## aynı fikirde olması.
func _edge_y(points: PackedVector2Array, x: float) -> float:
	# İlk ve son nokta tabana iniyor (çokgeni kapatan köşeler), üst kenar
	# aradakiler.
	for index in range(1, points.size() - 2):
		var a := points[index]
		var b := points[index + 1]
		if x >= a.x and x <= b.x:
			return lerpf(a.y, b.y, (x - a.x) / maxf(0.0001, b.x - a.x))
	return NAN

func _test_ridge_y_lands_on_the_drawn_edge(t) -> void:
	var area := _area()
	# Yol şeridinin zemin kenarı ve şehir dışının iki sırtı - hepsi
	# farklı dalga boyu/genlik, çünkü tuzak örneklemede.
	var cases := [
		{"base": 305.0, "amp": 10.1, "wave": 630.0, "offset": -412.0, "seed": 29},
		{"base": 362.0, "amp": 60.0, "wave": 684.0, "offset": 0.0, "seed": 11},
		{"base": 298.0, "amp": 116.0, "wave": 1296.0, "offset": -1800.0, "seed": 3},
	]
	for case in cases:
		var points := ArtDraw.ridge_points(
			area, case.base, case.amp, case.wave, case.offset, case.seed
		)
		var checked := 0
		for step in 200:
			var x := area.size.x * float(step) / 199.0
			var expected := _edge_y(points, x)
			if is_nan(expected):
				continue
			checked += 1
			t.almost(
				ArtDraw.ridge_y(
					area, case.base, case.amp, case.wave, case.offset, case.seed, x
				),
				expected,
				"ridge_y çizilen kenarın dışına düştü (dalga boyu %s, x %.1f)" % [case.wave, x],
				EPSILON
			)
		t.ok(checked > 150, "kenar örneklemesi x aralığını kapsamıyor")

func _test_ridge_y_stays_inside_the_amplitude(t) -> void:
	var area := _area()
	for step in 240:
		var x := -200.0 + area.size.x * 1.3 * float(step) / 239.0
		var y := ArtDraw.ridge_y(area, 300.0, 42.0, 520.0, -777.0, 17, x)
		t.ok(
			y >= 300.0 - 42.0 - EPSILON and y <= 300.0 + 42.0 + EPSILON,
			"sırt genliğinin dışına çıktı: %.3f" % y
		)

func _test_ridge_is_reproducible(t) -> void:
	var area := _area()
	var first := ArtDraw.ridge_points(area, 310.0, 30.0, 700.0, -120.0, 5)
	var second := ArtDraw.ridge_points(area, 310.0, 30.0, 700.0, -120.0, 5)
	t.eq(first.size(), second.size(), "aynı tohum farklı sayıda nokta verdi")
	for index in first.size():
		t.almost(
			first[index].y, second[index].y,
			"aynı tohum aynı sırtı vermedi - kamera kaydıkça tepeler zıplar", EPSILON
		)

## Kar başlığının tamamı kar çizgisinin **üstünde**. Bu sınır olmadan
## `ridge_snow` dağın tamamını beyaza boyuyor - bu depoda bir kez oldu.
func _test_snow_never_reaches_below_the_snow_line(t) -> void:
	var area := _area()
	var base := 298.0
	var amplitude := 69.0
	var snow_line := base - amplitude * 0.42
	# Salınım payı: kar sınırı bilerek düz değil (bkz. snow_runs).
	var slack := amplitude * 0.10 + EPSILON
	var runs := ArtDraw.snow_runs(area, base, amplitude, 1170.0, -900.0, 11, snow_line)
	t.ok(runs.size() > 0, "karlı tepede hiç kar yok")
	for polygon in runs:
		for point in polygon:
			t.ok(
				point.y <= snow_line + slack,
				"kar, kar çizgisinin altına taştı: %.2f > %.2f" % [point.y, snow_line + slack]
			)

func _test_a_low_ridge_gets_no_snow(t) -> void:
	var area := _area()
	# Kar çizgisi sırtın en yüksek noktasının da üstünde: alçak tepe
	# karsız kalmalı, yoksa "kar" bir yükseklik göstergesi değil, her
	# sırta sürülen bir badana olur.
	var runs := ArtDraw.snow_runs(area, 300.0, 40.0, 900.0, 0.0, 11, 300.0 - 41.0)
	t.eq(runs.size(), 0, "kar çizgisinin altındaki sırt kar tuttu")

func _test_contact_shadow_is_flat(t) -> void:
	# Gölge basık olmalı: yuvarlak bir leke yerde duran bir gölge değil,
	# nesnenin altına konmuş bir top gibi duruyor.
	var points := ArtDraw.ellipse_points(Vector2(100.0, 200.0), Vector2(30.0, 30.0 * 0.32))
	var min_y := INF
	var max_y := -INF
	var min_x := INF
	var max_x := -INF
	for point in points:
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
	t.ok(
		(max_x - min_x) > (max_y - min_y) * 2.0,
		"temas gölgesi basık değil"
	)

## Eski `vignette()` her dilimi `+1.0` genişletiyordu - komşusuyla 1 px
## çakışıp o pikselde alfayı iki katına çıkarıyordu (ölçülen belirti:
## ~13 px'te bir koyu dikey/yatay çizgi). `vignette_strips()`'in ürettiği
## dilimler artık ne çakışmalı ne boşluklu olmalı - `vignette_strips()`
## sırayı [sol, sağ, alt] × steps olarak döndürüyor (bkz. kendi kaynağı).
func _test_vignette_strips_tile_without_overlap_or_gap(t) -> void:
	var area := Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0))
	var strips := ArtDraw.vignette_strips(area, 0.055)
	var left := []
	var right := []
	var bottom := []
	for index in strips.size():
		match index % 3:
			0: left.append(strips[index].rect)
			1: right.append(strips[index].rect)
			2: bottom.append(strips[index].rect)
	left.sort_custom(func(a, b): return a.position.x < b.position.x)
	right.sort_custom(func(a, b): return a.position.x < b.position.x)
	bottom.sort_custom(func(a, b): return a.position.y < b.position.y)
	for group in [left, right, bottom]:
		var axis_is_x: bool = group != bottom
		for i in range(group.size() - 1):
			var current: Rect2 = group[i]
			var next: Rect2 = group[i + 1]
			if axis_is_x:
				t.almost(
					next.position.x, current.position.x + current.size.x,
					"vignette dilimi çakışıyor ya da boşluk bırakıyor (x)", 0.01
				)
			else:
				t.almost(
					next.position.y, current.position.y + current.size.y,
					"vignette dilimi çakışıyor ya da boşluk bırakıyor (y)", 0.01
				)

## Alt şerit sol/sağ şeritlerin kapladığı sütunlara taşarsa köşelerde alfa
## iki kez toplanır (çift koyu köşe). Her alt dilim tam olarak yan
## şeritlerin iç kenarları arasında kalmalı.
func _test_vignette_bottom_strip_stops_at_side_strips(t) -> void:
	var area := Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0))
	var side := area.size.x * ArtDraw.VIGNETTE_SIDE_RATIO
	var strips := ArtDraw.vignette_strips(area, 0.055)
	var checked := 0
	for index in strips.size():
		if index % 3 != 2:
			continue
		var rect: Rect2 = strips[index].rect
		t.almost(rect.position.x, area.position.x + side, "alt şerit sol köşeye taşıyor", 0.01)
		t.almost(
			rect.position.x + rect.size.x, area.position.x + area.size.x - side,
			"alt şerit sağ köşeye taşıyor", 0.01
		)
		checked += 1
	t.ok(checked == ArtDraw.VIGNETTE_STEPS, "alt şerit sayısı beklenenden farklı")
