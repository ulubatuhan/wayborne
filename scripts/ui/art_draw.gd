class_name ArtDraw
extends RefCounted

## Çizim dili: her ekranın aynı fırçalarla çizmesi için ortak yardımcılar.
##
## `ArtPalette` rengi söylüyor, bu dosya *nasıl* çizileceğini. Gradyan
## bantlar, silüet tepeler, ağaçlar, kayalar, çalılar, su, vinyet ve
## parçacıklar. Hepsi `CanvasItem`'a çiziyor, yani çağıran bir `Control`
## ya da `Node2D` olabilir.
##
## Godot'un `_draw()`'unda hazır gradyan yok; bantlar ince dilimlerle
## kuruluyor. Dilim sayısı gözle bant vermeyecek kadar yüksek ama
## yeniden çizim başına bir kez koşuyor, kare başına değil.

const GRADIENT_STEPS: int = 44

## Dikey gradyan bant - gökyüzü ve zemin bunun üzerine kurulu.
static func gradient_band(canvas: CanvasItem, area: Rect2, top: Color, bottom: Color) -> void:
	var steps := GRADIENT_STEPS
	var step_h := area.size.y / float(steps)
	for index in steps:
		var ratio := float(index) / float(maxi(1, steps - 1))
		canvas.draw_rect(
			Rect2(
				Vector2(area.position.x, area.position.y + step_h * float(index)),
				Vector2(area.size.x, step_h + 1.0)
			),
			top.lerp(bottom, ratio), true
		)

## Silüet tepe sırası. `seed_value` aynıysa aynı sırt çiziliyor, yani
## kamera kaydıkça tepeler zıplamıyor - paralaks katmanların olmazsa
## olmazı.
##
## `offset` katmanın kaydırması (paralaks), `amplitude` sırtın
## yüksekliği, `wavelength` tepelerin genişliği.
static func ridge(
	canvas: CanvasItem, area: Rect2, base_y: float, amplitude: float,
	wavelength: float, offset: float, color: Color, seed_value: int
) -> void:
	var points := PackedVector2Array()
	var step := maxf(8.0, wavelength * 0.12)
	var x := area.position.x - step
	points.append(Vector2(x, area.position.y + area.size.y))
	while x <= area.position.x + area.size.x + step:
		var phase := (x + offset) / maxf(1.0, wavelength)
		# İki farklı frekans üst üste: tek sinüs yapay bir dalga gibi
		# duruyor, ikisi birlikte sırt gibi duruyor.
		var height := (
			sin(phase * TAU + float(seed_value) * 0.37) * 0.62
			+ sin(phase * TAU * 2.3 + float(seed_value) * 1.11) * 0.38
		)
		points.append(Vector2(x, base_y - height * amplitude))
		x += step
	points.append(Vector2(x, area.position.y + area.size.y))
	canvas.draw_colored_polygon(points, color)

## Yuvarlak taçlı ağaç: gövde + üç örtüşen küme. Yassı-resimsel stilin
## en çok tekrarlanan parçası, o yüzden ucuz tutuldu.
static func tree(
	canvas: CanvasItem, base: Vector2, height: float,
	trunk_color: Color, leaf_color: Color
) -> void:
	var trunk_w := maxf(2.0, height * 0.085)
	canvas.draw_rect(
		Rect2(Vector2(base.x - trunk_w * 0.5, base.y - height * 0.52), Vector2(trunk_w, height * 0.52)),
		trunk_color, true
	)
	var crown := Vector2(base.x, base.y - height * 0.68)
	var r := height * 0.30
	ellipse(canvas, crown, Vector2(r * 1.05, r * 0.95), leaf_color)
	ellipse(canvas, crown + Vector2(-r * 0.62, r * 0.28), Vector2(r * 0.72, r * 0.62), leaf_color)
	ellipse(canvas, crown + Vector2(r * 0.62, r * 0.30), Vector2(r * 0.70, r * 0.60), leaf_color)
	# Tek yönden ışık: tacın sol üstü biraz açık.
	ellipse(
		canvas, crown + Vector2(-r * 0.26, -r * 0.30), Vector2(r * 0.44, r * 0.34),
		leaf_color.lightened(0.14)
	)

## İğne yapraklı ağaç - orman biyomunun kimliği bundan geliyor.
static func conifer(
	canvas: CanvasItem, base: Vector2, height: float,
	trunk_color: Color, leaf_color: Color
) -> void:
	var trunk_w := maxf(2.0, height * 0.06)
	canvas.draw_rect(
		Rect2(Vector2(base.x - trunk_w * 0.5, base.y - height * 0.22), Vector2(trunk_w, height * 0.22)),
		trunk_color, true
	)
	var tiers := 3
	for index in tiers:
		var ratio := float(index) / float(tiers)
		var tier_y := base.y - height * (0.20 + ratio * 0.62)
		var half := height * (0.26 - ratio * 0.07)
		var tip := height * 0.30
		canvas.draw_colored_polygon(
			PackedVector2Array([
				Vector2(base.x - half, tier_y),
				Vector2(base.x, tier_y - tip),
				Vector2(base.x + half, tier_y),
			]),
			leaf_color.darkened(ratio * 0.10)
		)

## Kaya: köşeli bir çokgen. Aynı `seed_value` aynı kayayı veriyor.
static func rock(
	canvas: CanvasItem, base: Vector2, width: float, height: float,
	color: Color, seed_value: int
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector2Array()
	var facets := 7
	for index in facets:
		var angle := PI + PI * float(index) / float(facets - 1)
		var wobble := 0.78 + rng.randf() * 0.30
		# Yayın iki ucu zaten taban çizgisinde (sin(PI) = sin(2PI) = 0),
		# o yüzden tabanı ayrıca eklemiyoruz: düzensiz `wobble` ile eklenen
		# köşeler yayın ucunu geçip şekli kendisiyle kesiştiriyor ve
		# üçgenleme sessizce düşüyor.
		points.append(base + Vector2(
			cos(angle) * width * 0.5 * wobble,
			sin(angle) * height * wobble
		))
	canvas.draw_colored_polygon(points, color)
	# Üst yüz ışığı alıyor.
	canvas.draw_colored_polygon(
		PackedVector2Array([
			base + Vector2(-width * 0.26, -height * 0.72),
			base + Vector2(width * 0.06, -height * 0.95),
			base + Vector2(width * 0.28, -height * 0.62),
			base + Vector2(-width * 0.04, -height * 0.58),
		]),
		color.lightened(0.16)
	)

## Çalı/ot kümesi: birkaç dikey çizgi. Zemin çizgisini "yaşayan" kılan
## en ucuz detay.
static func shrub(
	canvas: CanvasItem, base: Vector2, width: float, height: float,
	color: Color, seed_value: int
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var blades := 7
	for index in blades:
		var ratio := float(index) / float(blades - 1) - 0.5
		var blade_h := height * (0.55 + rng.randf() * 0.6)
		var lean := (rng.randf() - 0.5) * width * 0.45
		canvas.draw_line(
			base + Vector2(ratio * width, 0.0),
			base + Vector2(ratio * width + lean, -blade_h),
			color, maxf(1.0, width * 0.10)
		)

## Su yüzeyi: gradyan + yatay parlama çizgileri. Referans görsellerdeki
## gölün okunma sebebi bu çizgiler.
static func water(
	canvas: CanvasItem, area: Rect2, surface: Color, deep: Color,
	sparkle: Color, scroll: float, seed_value: int
) -> void:
	gradient_band(canvas, area, surface, deep)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rows := 14
	for index in rows:
		var ratio := float(index) / float(rows)
		var y := area.position.y + area.size.y * ratio
		var count := 3 + int(rng.randf() * 5.0)
		for _mark in count:
			var x := area.position.x + fmod(
				rng.randf() * area.size.x + scroll * (0.2 + ratio * 0.8),
				area.size.x
			)
			var length := area.size.x * (0.012 + rng.randf() * 0.03)
			canvas.draw_line(
				Vector2(x, y), Vector2(x + length, y),
				Color(sparkle.r, sparkle.g, sparkle.b, 0.10 + ratio * 0.22),
				maxf(1.0, area.size.y * 0.006)
			)

## Kenarlardan içe kararma. Her sahnede var, çünkü çerçeveyi o kapatıyor.
##
## İlk hâli iç içe *dikdörtgen konturları* çiziyordu ve ekran görüntüsünde
## sonucu belliydi: yumuşak bir kararma değil, sol ve sağ kenarda dizi dizi
## dikey çubuk. Kontur kalınlığı genişliğe oranlıydı, yani geniş bir şeritte
## çubuklar da kalınlaşıyordu. Şimdi her kenar kendi ince dilimleriyle
## karartılıyor - kenar başına doğrusal bir solma, çerçeve yok.
static func vignette(canvas: CanvasItem, area: Rect2, strength: float = 0.055) -> void:
	var steps := 18
	var side := area.size.x * 0.10
	var vertical := area.size.y * 0.16
	for index in steps:
		var ratio := float(index) / float(steps)
		var alpha := strength * (1.0 - ratio)
		var thickness_x := side / float(steps) + 1.0
		var thickness_y := vertical / float(steps) + 1.0
		var shade := Color(0.0, 0.0, 0.0, alpha)
		canvas.draw_rect(Rect2(
			Vector2(area.position.x + side * ratio, area.position.y),
			Vector2(thickness_x, area.size.y)
		), shade, true)
		canvas.draw_rect(Rect2(
			Vector2(area.position.x + area.size.x - side * ratio - thickness_x, area.position.y),
			Vector2(thickness_x, area.size.y)
		), shade, true)
		canvas.draw_rect(Rect2(
			Vector2(area.position.x, area.position.y + area.size.y - vertical * ratio - thickness_y),
			Vector2(area.size.x, thickness_y)
		), shade, true)

## Yumuşak ışık havuzu - meşale, kamp ateşi, pencere. Basık elips
## halkaları; yuvarlak bir küre "ışık" gibi durmuyor, yerden yansıyan
## basık bir havuz duruyor.
static func light_pool(
	canvas: CanvasItem, centre: Vector2, radius: float,
	color: Color, strength: float, flatten: float = 0.55
) -> void:
	var rings := 16
	for index in range(rings, 0, -1):
		var ratio := float(index) / float(rings)
		ellipse(
			canvas, centre, Vector2(radius * ratio, radius * ratio * flatten),
			Color(color.r, color.g, color.b, (1.0 - ratio) * strength)
		)

static func ellipse(canvas: CanvasItem, centre: Vector2, radii: Vector2, color: Color) -> void:
	canvas.draw_colored_polygon(ellipse_points(centre, radii), color)

static func ellipse_points(centre: Vector2, radii: Vector2, steps: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in steps:
		var angle := TAU * float(index) / float(steps)
		points.append(centre + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points

## Üstü kemerli branda örtülü kervan vagonu, yandan. `base` arka
## tekerleğin yere bastığı çizginin ortası.
##
## Buraya taşınmasının sebebi iki ekranda çizilmesi: yol şeridi ve şehir
## dışı yürüyüş alanı. İki kopya tutulunca aynı kervanın vagonu iki
## ekranda iki farklı şey oluyordu - `CaravanPlan.daily_consumption`'ın
## tek yerde durma gerekçesinin görsel karşılığı.
static func wagon(
	canvas: CanvasItem, base: Vector2, w: float, h: float,
	wheel_angle: float, tint: Color, with_load: bool = false
) -> void:
	var body := _tint(ArtPalette.WAGON_BODY, tint)
	var dark := _tint(ArtPalette.WAGON_BODY_DARK, tint)
	var cover := _tint(ArtPalette.WAGON_CANVAS, tint)
	var wheel := _tint(ArtPalette.WAGON_WHEEL, tint)
	var wheel_r := h * 0.34

	ellipse(canvas, base, Vector2(w * 0.55, h * 0.07), Color(0.0, 0.0, 0.0, 0.22))
	_wheel(canvas, Vector2(base.x - w * 0.30, base.y - wheel_r), wheel_r, wheel, wheel_angle)

	var bed_y := base.y - wheel_r * 1.35
	canvas.draw_rect(
		Rect2(Vector2(base.x - w * 0.5, bed_y - h * 0.16), Vector2(w, h * 0.16)), body, true
	)
	canvas.draw_line(
		Vector2(base.x - w * 0.5, bed_y), Vector2(base.x + w * 0.5, bed_y),
		dark, maxf(1.4, h * 0.05)
	)

	# Branda: kemerli bir kabuk. Yayın iki ucu zaten tabanda bittiği için
	# şekil kendiliğinden kapanıyor - tabanı ayrıca eklemek çakışan köşe
	# üretiyor ve Godot'un üçgenlemesi sessizce düşüyor.
	var hoop_top := bed_y - h * 0.16
	var arch := PackedVector2Array()
	var steps := 16
	for step in steps + 1:
		var ratio := float(step) / float(steps)
		var angle := PI * ratio
		arch.append(Vector2(
			base.x - cos(angle) * w * 0.44, hoop_top - sin(angle) * h * 0.62
		))
	inked(canvas, arch, cover, maxf(1.2, h * 0.035))
	for rib in 4:
		var ratio := 0.2 + float(rib) * 0.2
		var angle := PI * ratio
		canvas.draw_line(
			Vector2(base.x - cos(angle) * w * 0.44, hoop_top - sin(angle) * h * 0.62),
			Vector2(base.x - cos(angle) * w * 0.44, hoop_top),
			cover.darkened(0.16), maxf(1.0, h * 0.022)
		)

	# Arabacı: brandanın önünde oturan bir silüet. Vagonu süren birinin
	# olması "tayfa gerçekten var" demenin en ucuz yolu.
	var bench := Vector2(base.x + w * 0.34, hoop_top - h * 0.04)
	canvas.draw_circle(
		bench + Vector2(0.0, -h * 0.26), h * 0.075, _tint(Color(0.74, 0.60, 0.46), tint)
	)
	canvas.draw_colored_polygon(PackedVector2Array([
		bench + Vector2(-h * 0.09, -h * 0.20),
		bench + Vector2(h * 0.09, -h * 0.20),
		bench + Vector2(h * 0.07, 0.0),
		bench + Vector2(-h * 0.07, 0.0),
	]), _tint(Color(0.36, 0.32, 0.26), tint))

	_wheel(canvas, Vector2(base.x + w * 0.30, base.y - wheel_r), wheel_r, wheel, wheel_angle)

	# Arkadan sarkan denk: kervanın taşıdığı şey görünsün.
	if with_load:
		canvas.draw_rect(Rect2(
			Vector2(base.x - w * 0.54, bed_y - h * 0.34), Vector2(w * 0.16, h * 0.20)
		), _tint(ArtPalette.WAGON_LOAD, tint), true)

static func _wheel(
	canvas: CanvasItem, centre: Vector2, radius: float, color: Color, angle: float
) -> void:
	canvas.draw_arc(centre, radius, 0.0, TAU, 20, color, maxf(1.8, radius * 0.20))
	for spoke in 6:
		var a := angle + TAU * float(spoke) / 6.0
		canvas.draw_line(
			centre, centre + Vector2(cos(a), sin(a)) * radius * 0.86,
			color.lightened(0.12), maxf(1.0, radius * 0.10)
		)
	canvas.draw_circle(centre, radius * 0.16, color.darkened(0.2))

## Günün ışığı bütün çizimleri aynı şekilde çarpıyor.
static func _tint(color: Color, light: Color) -> Color:
	return Color(color.r * light.r, color.g * light.g, color.b * light.b, color.a)

## Dolgu + koyu kontur. Yassı-resimsel stilin "mürekkep" hissi bundan.
static func inked(canvas: CanvasItem, points: PackedVector2Array, fill: Color, width: float = 1.6) -> void:
	if points.size() < 3:
		return
	canvas.draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, ArtPalette.INK, width)
