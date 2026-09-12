class_name TravelBand
extends Control

## Yolun manzarası. Katmanlı bir paralaks şerit: gökyüzü, uzak sırtlar,
## orta sırtlar, ağaç hattı, su, zemin ve ön plan - hepsi `_draw()` ile.
##
## Öncesinde burada on dört `ColorRect` vardı: yedi "tepe" dikdörtgeni,
## on dört yol çizgisi, bir gökyüzü, bir zemin. Gerçek şikâyet doğrudur -
## öyle bir ekran Excel'de çizilmiş gibi duruyor ve daha kötüsü,
## *ilerleme hissi vermiyor*: birbirinin aynı on dört çizgi kayarken
## kervanın yol aldığı anlaşılmıyor.
##
## Üç kural bu dosyanın tamamını açıklıyor:
##
## 1. **Her şey dünya koordinatından üretiliyor, listeden değil.** Bir
##    katmanın nesneleri `hash(hücre indeksi)`'nden çıkıyor; ekran kayarken
##    yeni hücreler giriyor, çıkanlar unutuluyor. Sabit bir dizi başa
##    sardığında oyuncu tekrarı görüyor ve yol bir yürüyüş bandına
##    dönüşüyor.
## 2. **Arazi veriden geliyor** (`RouteTerrain`): bozkırdan ormana geçiş
##    renkle *ve* bitki örtüsüyle oluyor, ikisi aynı gün değişiyor.
## 3. **Hava da veriden geliyor** (`RouteWeather`): ekranda gördüğün
##    yağmur, yolu gerçekten yavaşlatan yağmurun aynısı.
##
## Kervan şeritte sabit durur, dünya onun altından akar; kervanı
## hareket ettirmek şeridin kenarına dayanırdı.

const BAND_HEIGHT: float = 320.0
const HORIZON_RATIO: float = 0.58

## Bir günlük yol kaç piksel. İlerleme hissinin ölçeği bu: küçük olursa
## yol akmıyor, büyük olursa manzara savruluyor.
const PIXELS_PER_DAY: float = 900.0

## Katman paralaks oranları. Uzak katman yavaş kayar - derinliğin tamamı
## bu farktan geliyor.
const PARALLAX_FAR: float = 0.10
const PARALLAX_MID: float = 0.26
const PARALLAX_TREES: float = 0.52
const PARALLAX_GROUND: float = 1.0
const PARALLAX_FORE: float = 1.55

## Hücre aralıkları (dünya pikseli). Bir hücrede en fazla bir nesne var.
const CELL_TREES: float = 120.0
const CELL_GROUND: float = 165.0
const CELL_FORE: float = 260.0

const CARAVAN_X_RATIO: float = 0.34

## Kamp ateşi.
const FIRE_FLICKER_SPEED: float = 9.0

## Yağmur ve sis. Damla sayısı yoğunlukla ölçekleniyor, en kötü havada
## bile Web hedefini boğmayacak kadar.
## Damlalar kısa ve çok: ilk ölçüde uzun ve seyrekti, ekranda yağmur
## değil cam çizikleri gibi duruyordu.
const RAIN_MAX_DROPS: int = 260
const RAIN_SPEED: float = 1250.0
const RAIN_SLANT: float = 0.30
const FOG_BANDS: int = 7

## Menzil taşları: yolda her gün bir taş. "Ne kadar yol aldım" sorusunun
## en okunur cevabı, ilerleme çubuğundan bağımsız olarak manzarada.
const MILESTONE_HEIGHT: float = 26.0

## Evre eşlemesi: saatin altı evresi paletin dört gökyüzüne düşüyor.
## Palet dört tutuluyor çünkü sabah/öğle ya da akşam/gece arasındaki fark
## gökyüzünde renk değil *ilerleme* farkı (bkz. ArtPalette.blend_sky).
const PHASE_SKY: Dictionary = {
	JourneyClock.Phase.DAWN: ArtPalette.PHASE_DAWN,
	JourneyClock.Phase.MORNING: ArtPalette.PHASE_DAY,
	JourneyClock.Phase.NOON: ArtPalette.PHASE_DAY,
	JourneyClock.Phase.AFTERNOON: ArtPalette.PHASE_DAY,
	JourneyClock.Phase.EVENING: ArtPalette.PHASE_DUSK,
	JourneyClock.Phase.NIGHT: ArtPalette.PHASE_NIGHT,
}

const PHASE_ORDER: Array = [
	JourneyClock.Phase.DAWN,
	JourneyClock.Phase.MORNING,
	JourneyClock.Phase.NOON,
	JourneyClock.Phase.AFTERNOON,
	JourneyClock.Phase.EVENING,
	JourneyClock.Phase.NIGHT,
]

var _terrain: RouteTerrain
var _weather: String = RouteWeather.CLEAR
var _weather_visuals: Dictionary = RouteWeather.visuals(RouteWeather.CLEAR)

var _sky: Dictionary = ArtPalette.sky(ArtPalette.PHASE_DAY)
var _light: Color = Color.WHITE
var _colors: Dictionary = ArtPalette.terrain(ArtPalette.BIOME_STEPPE)
var _biome: String = ArtPalette.BIOME_STEPPE
var _slope: float = 0.0
var _night_ratio: float = 0.0
var _sun_ratio: float = 0.5

var _progress: float = 0.0
var _day_position: float = 0.0
var _world_x: float = 0.0
var _camping: bool = false
var _time: float = 0.0

## Kervan katmanı: figürleri bu şerit değil `RoadCaravan` çiziyor, ama
## zemin çizgisini ondan o alıyor - ikisi ayrı hesaplarsa kervan yolun
## üstünde ya da altında yürüyor.
signal ground_line_changed(caravan_x: float, ground_y: float)

func _ready() -> void:
	custom_minimum_size = Vector2(0.0, BAND_HEIGHT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_announce_ground_line)

## Rotanın coğrafyası. Seferin başında bir kez veriliyor; `null` ise şerit
## bozkıra düşer (F1 sentetik seferi ve testler için).
func set_route(terrain: RouteTerrain) -> void:
	_terrain = terrain
	_refresh_terrain()

func set_weather(weather: String) -> void:
	if _weather == weather:
		return
	_weather = weather
	_weather_visuals = RouteWeather.visuals(weather)
	queue_redraw()

func get_weather() -> String:
	return _weather

## Yolun ne kadarının katedildiği (0-1) *ve* bunun gün cinsinden karşılığı.
## Gün gerekiyor çünkü arazi günle tanımlı; oran gerekiyor çünkü hedef
## şehir ufukta ona göre büyüyor.
func set_route_progress(progress: float, day_position: float = -1.0) -> void:
	_progress = clampf(progress, 0.0, 1.0)
	_day_position = day_position if day_position >= 0.0 else _progress * _route_days()
	_world_x = _day_position * PIXELS_PER_DAY
	_refresh_terrain()
	queue_redraw()

func set_phase(phase: JourneyClock.Phase, phase_progress: float) -> void:
	var from_key: String = PHASE_SKY.get(phase, ArtPalette.PHASE_DAY)
	var to_key: String = PHASE_SKY.get(_next_phase(phase), ArtPalette.PHASE_DAY)
	var blend := clampf(phase_progress, 0.0, 1.0)
	_sky = ArtPalette.blend_sky(from_key, to_key, blend)
	_light = Color(_sky.light)
	if _camping:
		_light = _light.lerp(ArtPalette.TORCH, 0.45)

	# Yıldızlar ve güneşin yüksekliği evreden türüyor; ayrı bir saat
	# hesabı tutmak ikisinin ayrışması demekti.
	var index := PHASE_ORDER.find(phase)
	var day_span := float(index) + blend
	_night_ratio = clampf(1.0 - Color(_sky.bottom).get_luminance() * 2.6, 0.0, 1.0)
	_sun_ratio = clampf(day_span / float(PHASE_ORDER.size()), 0.0, 1.0)
	queue_redraw()

func set_camping(camping: bool) -> void:
	if _camping == camping:
		return
	_camping = camping
	queue_redraw()

## Kervanın üstüne vuran ışık - figürler bunu okuyor.
func get_light() -> Color:
	return _light

func get_caravan_anchor() -> Vector2:
	return Vector2(size.x * CARAVAN_X_RATIO, _ground_y_at_screen(size.x * CARAVAN_X_RATIO))

func _process(delta: float) -> void:
	# Yağmur ve ateş kendi başına canlanıyor; hava açık ve kamp yoksa
	# yeniden çizmeye gerek yok (oyuncu yürüdükçe set_route_progress
	# zaten çağırıyor).
	if float(_weather_visuals.rain) <= 0.0 and not _camping:
		return
	_time += delta
	queue_redraw()

func _route_days() -> float:
	return float(_terrain.total_days) if _terrain != null else 1.0

func _refresh_terrain() -> void:
	if _terrain == null:
		_colors = ArtPalette.terrain(ArtPalette.BIOME_STEPPE)
		_biome = ArtPalette.BIOME_STEPPE
		_slope = 0.0
		return
	_colors = _terrain.terrain_colors_at(_day_position)
	_biome = _terrain.biome_at(_day_position)
	_slope = _terrain.slope_at(_day_position)

func _next_phase(phase: JourneyClock.Phase) -> JourneyClock.Phase:
	var index := PHASE_ORDER.find(phase)
	if index < 0:
		return phase
	return PHASE_ORDER[(index + 1) % PHASE_ORDER.size()]

# --- Çizim ---

func _draw() -> void:
	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, BAND_HEIGHT)
	var area := Rect2(Vector2.ZERO, Vector2(width, height))
	var horizon := height * HORIZON_RATIO

	_draw_sky(area, horizon)
	_draw_celestial(area, horizon)
	_draw_far_ridges(area, horizon)
	_draw_mid_ridges(area, horizon)
	if _biome == ArtPalette.BIOME_LAKE:
		_draw_lake(area, horizon)
	_draw_tree_line(area, horizon)
	_draw_ground(area, horizon)
	_draw_cities(area, horizon)
	_draw_stops(area, horizon)
	_draw_ground_props(area, horizon)
	_draw_milestones(area, horizon)
	_draw_foreground(area, horizon)
	if _camping:
		_draw_campfire(area)
	_draw_weather(area, horizon)
	ArtDraw.vignette(self, area, 0.07)
	_announce_ground_line()

func _draw_sky(area: Rect2, horizon: float) -> void:
	var top := Color(_sky.top)
	var bottom := Color(_sky.bottom)
	var gloom := float(_weather_visuals.gloom)
	if gloom > 0.0:
		# Kapalı hava gökyüzünü karartmıyor, *griye* çekiyor: karartmak
		# geceyle karışıyordu.
		var lead := Color(0.36, 0.37, 0.39)
		top = top.lerp(lead.darkened(0.35), gloom)
		bottom = bottom.lerp(lead, gloom * 0.8)
	ArtDraw.gradient_band(
		self, Rect2(area.position, Vector2(area.size.x, horizon + 2.0)), top, bottom
	)

## Güneş/ay ufuk boyunca bir yay çiziyor. Gökyüzünde sabit bir nokta
## olmaması, zamanın aktığını renkten bağımsız olarak söylüyor.
func _draw_celestial(area: Rect2, horizon: float) -> void:
	var gloom := float(_weather_visuals.gloom)
	if gloom > 0.7:
		return

	if _night_ratio > 0.25:
		var rng := RandomNumberGenerator.new()
		rng.seed = 90210
		for _index in 40:
			var star := Vector2(rng.randf() * area.size.x, rng.randf() * horizon * 0.82)
			var twinkle := 0.55 + 0.45 * rng.randf()
			draw_circle(
				star, rng.randf_range(0.8, 1.7),
				Color(1.0, 1.0, 0.95, _night_ratio * twinkle * (1.0 - gloom))
			)

	var arc_x := area.size.x * (0.12 + _sun_ratio * 0.78)
	var arc_y := horizon - sin(_sun_ratio * PI) * horizon * 0.72 - horizon * 0.06
	var disc_r := area.size.y * 0.045
	var is_night := _night_ratio > 0.55
	var disc := Color(0.72, 0.78, 0.92) if is_night else Color(1.0, 0.93, 0.74)
	ArtDraw.light_pool(
		self, Vector2(arc_x, arc_y), disc_r * 5.0, disc,
		(0.16 if is_night else 0.30) * (1.0 - gloom), 1.0
	)
	draw_circle(Vector2(arc_x, arc_y), disc_r, Color(disc, (1.0 - gloom * 0.6)))
	if is_night:
		# Ay: diskin bir kenarını gökyüzü rengiyle kesip hilal yapıyoruz.
		draw_circle(
			Vector2(arc_x + disc_r * 0.42, arc_y - disc_r * 0.24), disc_r * 0.86,
			Color(_sky.top)
		)

## En uzak sırt: neredeyse pusun içinde. Dağ biyomunda belirgin yükseliyor,
## yani "dağa yaklaşıyoruz" hissi renkle değil siluetle geliyor.
func _draw_far_ridges(area: Rect2, horizon: float) -> void:
	# Pus payı ilk denemede 0.78'di ve sonuç ekranda görüldü: uzak sırt,
	# orta sırt ve uzak zemin aynı griye çöküyor, orman bile mavi-gri
	# duruyordu. Hava perspektifi *derinlik* vermeli, rengi silmemeli;
	# uzak katman artık biyomun rengini taşıyor, yalnızca daha soluk.
	var haze := Color(_sky.haze)
	var far := ArtPalette.fade_to_haze(Color(_colors.far), haze, 0.55)
	var amplitude := area.size.y * (0.20 if _biome == ArtPalette.BIOME_MOUNTAIN else 0.10)
	ArtDraw.ridge(
		self, area, horizon + area.size.y * 0.01, amplitude,
		area.size.x * 1.35, -_world_x * PARALLAX_FAR, far, 3
	)

func _draw_mid_ridges(area: Rect2, horizon: float) -> void:
	var haze := Color(_sky.haze)
	var mid := ArtPalette.fade_to_haze(Color(_colors.far), haze, 0.28)
	var amplitude := area.size.y * (0.15 if _biome == ArtPalette.BIOME_MOUNTAIN else 0.075)
	var base_y := horizon + area.size.y * 0.035
	var wavelength := area.size.x * 0.78
	var offset := -_world_x * PARALLAX_MID

	# Karlı tepe. Sıra **önce kar, sonra kaya**: `ridge` aşağıya doğru
	# dolduruyor, yani kayayı önce çizip karı sonra koymak dağın tamamını
	# beyaza boyuyordu (ekran görüntüsünde dağ değil dev bir kar duvarı
	# görünüyordu). Aynı tohum ve aynı dalga boyu ile karın sırtı biraz
	# daha yüksek olunca üstte ince bir kar bandı kalıyor - kalpak.
	if _biome == ArtPalette.BIOME_MOUNTAIN:
		ArtDraw.ridge(
			self, area, base_y, amplitude, wavelength, offset,
			ArtPalette.fade_to_haze(Color(0.84, 0.86, 0.90), haze, 0.30), 11
		)
		ArtDraw.ridge(
			self, area, base_y, amplitude * 0.84, wavelength, offset, mid, 11
		)
	else:
		ArtDraw.ridge(self, area, base_y, amplitude, wavelength, offset, mid, 11)

## Göl: ufkun altında bir su bandı, karşı kıyısı puslu.
func _draw_lake(area: Rect2, horizon: float) -> void:
	# Su bandı zeminin *üstünde* kalmalı: ilk ölçüde ufkun 0.045'inden
	# başlayıp 0.16 yükseklikte çiziliyordu, ama zemin 0.075'ten aşağıyı
	# kaplıyor - yani gölün beş katı suyun içi görünmüyordu. Uzaktaki bir
	# göl zaten ince bir şerittir.
	var top := horizon - area.size.y * 0.008
	var water_rect := Rect2(
		Vector2(area.position.x, top), Vector2(area.size.x, area.size.y * 0.084)
	)
	ArtDraw.water(
		self, water_rect,
		ArtPalette.fade_to_haze(Color(_colors.accent), Color(_sky.haze), 0.35),
		Color(_colors.far).darkened(0.12), Color(_sky.light),
		-_world_x * PARALLAX_TREES, 7
	)

## Ağaç hattı: biyomun kimliği. Orman iğne yapraklı, bozkır seyrek ve
## bodur, bataklık cılız, dağ neredeyse çıplak.
func _draw_tree_line(area: Rect2, horizon: float) -> void:
	var haze := Color(_sky.haze)
	var flora := ArtPalette.fade_to_haze(Color(_colors.flora), haze, 0.16)
	var trunk := ArtPalette.fade_to_haze(Color(_colors.near).darkened(0.35), haze, 0.16)
	var base_y := horizon + area.size.y * 0.075
	var density := _tree_density()
	if density <= 0.0:
		return

	var offset := -_world_x * PARALLAX_TREES
	var first := int(floor((-offset - CELL_TREES) / CELL_TREES))
	var last := int(ceil((-offset + area.size.x + CELL_TREES) / CELL_TREES))
	for cell in range(first, last + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("trees|%d|%s" % [cell, _biome])
		if rng.randf() > density:
			continue
		var x := float(cell) * CELL_TREES + offset + rng.randf_range(-28.0, 28.0)
		if x < -60.0 or x > area.size.x + 60.0:
			continue
		var h := area.size.y * rng.randf_range(0.11, 0.20)
		var base := Vector2(x, base_y + rng.randf_range(-4.0, 6.0))
		match _biome:
			ArtPalette.BIOME_FOREST, ArtPalette.BIOME_MOUNTAIN:
				ArtDraw.conifer(self, base, h, trunk, flora)
			ArtPalette.BIOME_MARSH:
				ArtDraw.tree(self, base, h * 0.72, trunk, flora.darkened(0.1))
			_:
				ArtDraw.tree(self, base, h * 0.82, trunk, flora)

func _tree_density() -> float:
	match _biome:
		ArtPalette.BIOME_FOREST: return 0.92
		ArtPalette.BIOME_MARSH: return 0.45
		ArtPalette.BIOME_LAKE: return 0.38
		ArtPalette.BIOME_MOUNTAIN: return 0.30
		_: return 0.26

## Zemin: ufuktan aşağı bir gradyan, üstünde yolun kendisi. Yol eğimli -
## eğim `RouteTerrain`'den geliyor, yani dağa tırmanan yol gerçekten
## yukarı gidiyor.
func _draw_ground(area: Rect2, horizon: float) -> void:
	var ground_top := horizon + area.size.y * 0.075
	var far := ArtPalette.fade_to_haze(Color(_colors.far), Color(_sky.haze), 0.12)
	ArtDraw.gradient_band(
		self,
		Rect2(Vector2(area.position.x, ground_top), Vector2(area.size.x, area.size.y - ground_top + 2.0)),
		far, Color(_colors.near)
	)
	# Zeminin üst kenarı düz bir çizgiydi ve ekranı boydan boya kesiyordu -
	# manzaranın en yapay duran yeri orasıydı. Aynı `ridge` fırçasıyla
	# kırıyoruz, ama zeminin kendi rengiyle: bu bir tepe değil, çayırın
	# ufka değdiği kenar.
	ArtDraw.ridge(
		self, area, ground_top + area.size.y * 0.012, area.size.y * 0.022,
		area.size.x * 0.42, -_world_x * PARALLAX_TREES, far, 29
	)

	# Yol şeridi. İlk denemede rengi zeminden yalnızca %42 ayrılıyordu ve
	# ekran görüntüsünde yol *hiç görünmüyordu* - kervan tek renk bir
	# kahverengi zeminde yürüyordu. Yol artık hem daha açık hem daha az
	# doygun, iki yanında da koyu bir bank var: asıl okunurluk o
	# kenarlardan geliyor, yolun kendi renginden değil.
	var left_y := _ground_y_at_screen(0.0)
	var right_y := _ground_y_at_screen(area.size.x)
	var band := area.size.y * 0.085
	var near := Color(_colors.near)
	var road := near.lerp(Color(0.68, 0.60, 0.46), 0.62)
	var verge := near.darkened(0.30)

	for edge in [-1.0, 1.0]:
		var top := band * (-0.75 if edge < 0.0 else 1.0)
		var bottom := band * (-0.42 if edge < 0.0 else 1.42)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, left_y + top),
			Vector2(area.size.x, right_y + top),
			Vector2(area.size.x, right_y + bottom),
			Vector2(0.0, left_y + bottom),
		]), verge)

	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, left_y - band * 0.5),
		Vector2(area.size.x, right_y - band * 0.5),
		Vector2(area.size.x, right_y + band),
		Vector2(0.0, left_y + band),
	]), road)
	# Tekerlek izleri: yolun üstünde iki koyu şerit, dünya ile kayıyor.
	for lane in [-0.16, 0.22]:
		draw_line(
			Vector2(0.0, left_y + band * lane), Vector2(area.size.x, right_y + band * lane),
			road.darkened(0.26), maxf(1.5, band * 0.12)
		)
	# Çakıl: yolun dokusu. Dünya koordinatından üretiliyor, o yüzden
	# kervan durduğunda taşlar da duruyor.
	var pebble_rng := RandomNumberGenerator.new()
	pebble_rng.seed = 4771
	for _index in 26:
		var world_slot := pebble_rng.randf() * area.size.x
		var x := fposmod(world_slot - _world_x * PARALLAX_GROUND, area.size.x)
		var y := _ground_y_at_screen(x) + band * pebble_rng.randf_range(-0.35, 0.85)
		draw_circle(
			Vector2(x, y), pebble_rng.randf_range(0.8, 2.0),
			road.darkened(pebble_rng.randf_range(0.05, 0.30))
		)

## Yolun ekrandaki y'si. Eğim yolu döndürüyor; kervan da bu çizgiye
## basıyor (bkz. ground_line_changed).
func _ground_y_at_screen(x: float) -> float:
	var height := maxf(size.y, BAND_HEIGHT)
	var base := height * HORIZON_RATIO + height * 0.26
	var centred := (x - size.x * 0.5) / maxf(1.0, size.x)
	return base - centred * _slope * height * 0.16

## Kalkılan ve varılacak şehir. Biri arkada küçülüyor, öteki önde
## büyüyor - ilerleme hissinin en okunur hâli, çünkü hedef *görünüyor*.
func _draw_cities(area: Rect2, horizon: float) -> void:
	var haze := Color(_sky.haze)
	var silhouette := ArtPalette.fade_to_haze(Color(_colors.far).darkened(0.25), haze, 0.55)

	if _progress > 0.42:
		# Hedef: yaklaştıkça hem büyüyor hem ekranın sağından ortasına
		# doğru geliyor.
		var near_ratio := clampf((_progress - 0.42) / 0.58, 0.0, 1.0)
		var scale := 0.32 + near_ratio * 0.85
		_draw_city_silhouette(
			Vector2(area.size.x * (0.96 - near_ratio * 0.22), horizon + area.size.y * 0.02),
			area.size.y * 0.14 * scale,
			ArtPalette.fade_to_haze(silhouette, haze, 0.55 - near_ratio * 0.35)
		)
	if _progress < 0.55:
		var behind := clampf(1.0 - _progress / 0.55, 0.0, 1.0)
		_draw_city_silhouette(
			Vector2(area.size.x * (0.04 + (1.0 - behind) * 0.10), horizon + area.size.y * 0.02),
			area.size.y * 0.13 * (0.30 + behind * 0.55), silhouette
		)

## Uzaktaki şehir: sur çizgisi, üç kule, bir kilise kulesi. Ayrıntı yok,
## çünkü ufukta ayrıntı pusun içinde kaybolur zaten.
func _draw_city_silhouette(base: Vector2, height: float, color: Color) -> void:
	var w := height * 2.1
	draw_rect(Rect2(base - Vector2(w * 0.5, height * 0.52), Vector2(w, height * 0.52)), color, true)
	var towers := [-0.36, 0.0, 0.34]
	for index in towers.size():
		var tx: float = base.x + w * float(towers[index])
		var th: float = height * (0.95 if index == 1 else 0.70)
		draw_rect(
			Rect2(Vector2(tx - height * 0.16, base.y - th), Vector2(height * 0.32, th)),
			color, true
		)
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - height * 0.20, base.y - th),
			Vector2(tx, base.y - th - height * 0.30),
			Vector2(tx + height * 0.20, base.y - th),
		]), color)

## Ara duraklar: köy, karakol, maden, geçit, sunak, köprü. Konumları gün
## cinsinden; ekranda ancak yakınına gelince görünüyorlar.
func _draw_stops(area: Rect2, horizon: float) -> void:
	if _terrain == null:
		return
	# Duraklar yolun *üstünde* duruyor, ağaç hattında değil: ilk hâlinde
	# ufka yakın bir bantta çiziliyorlardı ve bir köprü havada asılı bir
	# gri kemer gibi duruyordu. Bir de paralaks iki kez uygulanıyordu
	# (`world` içinde bir kez, çarpımda bir kez daha), yani duraklar yol
	# kaydıkça yanlış hızda süzülüyordu.
	for entry in _terrain.get_stops():
		var day := float(entry.day)
		var x := area.size.x * CARAVAN_X_RATIO + (day * PIXELS_PER_DAY - _world_x)
		if x < -180.0 or x > area.size.x + 180.0:
			continue
		# Yolun biraz gerisine oturuyorlar - kervan önlerinden geçiyor.
		var base := Vector2(x, _ground_y_at_screen(x) - area.size.y * 0.045)
		_draw_stop(String(entry.stop), base, area.size.y * 0.15)

func _draw_stop(stop: String, base: Vector2, height: float) -> void:
	var haze := Color(_sky.haze)
	var wall := ArtPalette.fade_to_haze(Color(0.48, 0.43, 0.36), haze, 0.30)
	var roof := ArtPalette.fade_to_haze(Color(0.38, 0.24, 0.20), haze, 0.30)
	var timber := ArtPalette.fade_to_haze(Color(0.30, 0.24, 0.18), haze, 0.30)
	var stone := ArtPalette.fade_to_haze(Color(0.46, 0.46, 0.48), haze, 0.30)

	match stop:
		RouteTerrain.STOP_HAMLET:
			for offset in [-0.7, 0.0, 0.75]:
				var h := height * (0.62 if is_zero_approx(offset) else 0.46)
				_draw_hut(base + Vector2(height * offset, 0.0), h, wall, roof)
		RouteTerrain.STOP_OUTPOST:
			_draw_hut(base, height * 0.60, stone, roof)
			# Gözetleme kulesi ve bayrak: karakolu köyden ayıran şey.
			var tower := base + Vector2(height * 0.8, 0.0)
			draw_rect(
				Rect2(tower - Vector2(height * 0.13, height * 1.05), Vector2(height * 0.26, height * 1.05)),
				stone, true
			)
			draw_line(
				tower + Vector2(0.0, -height * 1.05), tower + Vector2(0.0, -height * 1.38),
				timber, maxf(1.2, height * 0.04)
			)
			draw_colored_polygon(PackedVector2Array([
				tower + Vector2(0.0, -height * 1.36),
				tower + Vector2(height * 0.26, -height * 1.28),
				tower + Vector2(0.0, -height * 1.20),
			]), ArtPalette.fade_to_haze(ArtPalette.BLOOD, haze, 0.30))
		RouteTerrain.STOP_MINE:
			# Galeri ağzı + moloz yığını + iskele.
			draw_colored_polygon(PackedVector2Array([
				base + Vector2(-height * 0.55, 0.0),
				base + Vector2(-height * 0.30, -height * 0.62),
				base + Vector2(height * 0.30, -height * 0.62),
				base + Vector2(height * 0.55, 0.0),
			]), stone.darkened(0.25))
			draw_colored_polygon(PackedVector2Array([
				base + Vector2(-height * 0.20, 0.0),
				base + Vector2(-height * 0.16, -height * 0.38),
				base + Vector2(height * 0.16, -height * 0.38),
				base + Vector2(height * 0.20, 0.0),
			]), ArtPalette.INK)
			draw_line(
				base + Vector2(-height * 0.22, -height * 0.40),
				base + Vector2(height * 0.22, -height * 0.40),
				timber, maxf(1.2, height * 0.055)
			)
		RouteTerrain.STOP_PASS:
			# Geçit: iki kaya kütlesi arasında bir boşluk.
			ArtDraw.rock(self, base + Vector2(-height * 0.75, 0.0), height * 1.0, height * 0.95, stone, 21)
			ArtDraw.rock(self, base + Vector2(height * 0.80, 0.0), height * 1.1, height * 1.15, stone.darkened(0.08), 22)
		RouteTerrain.STOP_SHRINE:
			# Sunak: bir taş sütun ve üstünde kavis. Küçük, çünkü yol
			# kenarında.
			draw_rect(
				Rect2(base - Vector2(height * 0.13, height * 0.52), Vector2(height * 0.26, height * 0.52)),
				stone, true
			)
			draw_arc(
				base + Vector2(0.0, -height * 0.52), height * 0.20, PI, TAU, 12,
				ArtPalette.fade_to_haze(ArtPalette.GOLD_DIM, haze, 0.30), maxf(1.4, height * 0.05)
			)
		RouteTerrain.STOP_BRIDGE:
			# Taş köprü: tabliye, altında iki kemer, üstünde korkuluk
			# babaları. İlk hâli tek bir kemer yayı ve bir kalastı - bir
			# köprü değil, bir bahçe kapısı gibi duruyordu.
			var span := height * 2.0
			var deck := base.y - height * 0.30
			for side in [-1.0, 1.0]:
				draw_arc(
					Vector2(base.x + span * 0.24 * side, deck), span * 0.20,
					PI, TAU, 16, stone.darkened(0.30), maxf(2.0, height * 0.10)
				)
			draw_rect(Rect2(
				Vector2(base.x - span * 0.5, deck - height * 0.10),
				Vector2(span, height * 0.12)
			), stone, true)
			for post in 5:
				var px: float = base.x - span * 0.44 + span * 0.22 * float(post)
				draw_rect(Rect2(
					Vector2(px - height * 0.035, deck - height * 0.30),
					Vector2(height * 0.07, height * 0.20)
				), stone.lightened(0.08), true)
			draw_line(
				Vector2(base.x - span * 0.46, deck - height * 0.26),
				Vector2(base.x + span * 0.46, deck - height * 0.26),
				timber, maxf(1.4, height * 0.045)
			)

func _draw_hut(base: Vector2, height: float, wall: Color, roof: Color) -> void:
	var half := height * 0.46
	draw_rect(Rect2(base - Vector2(half, height * 0.62), Vector2(half * 2.0, height * 0.62)), wall, true)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-half * 1.18, -height * 0.60),
		base + Vector2(0.0, -height * 1.02),
		base + Vector2(half * 1.18, -height * 0.60),
	]), roof)
	# Pencere: geceyse içi yanıyor. Yolda gördüğün ilk sıcak ışık bu.
	var glow := ArtPalette.TORCH if _night_ratio > 0.4 else wall.darkened(0.4)
	draw_rect(
		Rect2(base - Vector2(half * 0.22, height * 0.42), Vector2(half * 0.44, height * 0.20)),
		Color(glow, 0.55 + _night_ratio * 0.45), true
	)

## Zemin üstü bitki/kaya: yolun iki yanı. Paralaksı tam, yani kervanla
## aynı hızda kayıyor - yere basan şeyler bunlar.
func _draw_ground_props(area: Rect2, horizon: float) -> void:
	var offset := -_world_x * PARALLAX_GROUND
	var first := int(floor((-offset - CELL_GROUND) / CELL_GROUND))
	var last := int(ceil((-offset + area.size.x + CELL_GROUND) / CELL_GROUND))
	var flora := Color(_colors.flora)
	var near := Color(_colors.near)
	for cell in range(first, last + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("ground|%d|%s" % [cell, _biome])
		var roll := rng.randf()
		var x := float(cell) * CELL_GROUND + offset + rng.randf_range(-50.0, 50.0)
		if x < -70.0 or x > area.size.x + 70.0:
			continue
		# Yolun üstünde değil kenarında: hangi tarafta olduğu da rastgele.
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		var y := _ground_y_at_screen(x) + area.size.y * 0.085 * side * rng.randf_range(0.9, 2.1)
		var base := Vector2(x, y)
		if roll < 0.30:
			ArtDraw.rock(
				self, base, area.size.y * rng.randf_range(0.03, 0.07),
				area.size.y * rng.randf_range(0.025, 0.055),
				near.lerp(Color(_colors.accent), 0.35), cell * 31 + 7
			)
		elif roll < 0.78:
			ArtDraw.shrub(
				self, base, area.size.y * rng.randf_range(0.035, 0.075),
				area.size.y * rng.randf_range(0.035, 0.075), flora, cell * 17 + 3
			)
		else:
			# Yol kenarındaki ağaç da biyomun ağacı olmalı: ilk hâlinde
			# hep yuvarlak taçlıydı, yani çam ormanının ortasında
			# meyve ağaçları bitiyordu.
			var height := area.size.y * rng.randf_range(0.14, 0.24)
			if _biome == ArtPalette.BIOME_FOREST or _biome == ArtPalette.BIOME_MOUNTAIN:
				ArtDraw.conifer(self, base, height * 1.15, near.darkened(0.45), flora)
			else:
				ArtDraw.tree(self, base, height, near.darkened(0.45), flora.lightened(0.05))

## Menzil taşları: yolda her gün bir taş, üstünde kalan gün. Oyuncu
## ilerleme çubuğuna bakmadan da kaç gün kaldığını okuyor.
func _draw_milestones(area: Rect2, horizon: float) -> void:
	var days := int(ceil(_route_days()))
	for day in range(1, days + 1):
		var world := float(day) * PIXELS_PER_DAY - _world_x
		var x := area.size.x * CARAVAN_X_RATIO + world
		if x < -40.0 or x > area.size.x + 40.0:
			continue
		var base := Vector2(x, _ground_y_at_screen(x) + area.size.y * 0.055)
		var h := MILESTONE_HEIGHT
		# Taş kireç beyazı değil, aşınmış kaya. İlk denemede parlak beyazdı
		# ve yol boyunca dizili mezar taşları gibi duruyordu.
		ArtDraw.inked(self, PackedVector2Array([
			base + Vector2(-h * 0.22, 0.0),
			base + Vector2(-h * 0.18, -h * 0.82),
			base + Vector2(0.0, -h),
			base + Vector2(h * 0.18, -h * 0.82),
			base + Vector2(h * 0.22, 0.0),
		]), Color(0.46, 0.44, 0.40) * _light, 1.2)

## Ön plan: ekranın alt kenarından taşan, hızlı kayan siluetler. Derinlik
## hissinin yarısı buradan - kameranın önünde bir şey olmalı.
func _draw_foreground(area: Rect2, horizon: float) -> void:
	var offset := -_world_x * PARALLAX_FORE
	var first := int(floor((-offset - CELL_FORE) / CELL_FORE))
	var last := int(ceil((-offset + area.size.x + CELL_FORE) / CELL_FORE))
	# İlk denemede bunlar %55 karartılmıştı ve ekranın altında simsiyah
	# lekeler halinde duruyordu - ön plan değil, yanık bir çalı çırpı
	# gibi. Ön plan koyu olmalı ama zeminin *rengini* taşımalı.
	var dark := Color(_colors.near).darkened(0.34)
	for cell in range(first, last + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("fore|%d" % cell)
		if rng.randf() > 0.55:
			continue
		var x := float(cell) * CELL_FORE + offset + rng.randf_range(-80.0, 80.0)
		if x < -160.0 or x > area.size.x + 160.0:
			continue
		var base := Vector2(x, area.size.y + area.size.y * rng.randf_range(0.06, 0.16))
		if rng.randf() < 0.45:
			ArtDraw.rock(self, base, area.size.y * 0.20, area.size.y * 0.13, dark, cell * 13)
		else:
			ArtDraw.shrub(
				self, base, area.size.y * 0.17, area.size.y * 0.15,
				Color(_colors.flora).darkened(0.30), cell * 29
			)

func _draw_campfire(area: Rect2) -> void:
	# Ateş kolonun *önünde*: ilk konumu kervanın içindeydi ve vagonun
	# arkasında kalıyordu, yani gece karesinde ateş görünmüyordu.
	var anchor := get_caravan_anchor()
	var fire := anchor + Vector2(area.size.x * 0.055, area.size.y * 0.02)
	var flicker := 0.82 + 0.18 * sin(_time * FIRE_FLICKER_SPEED)
	ArtDraw.light_pool(
		self, fire, area.size.y * 0.42, ArtPalette.TORCH, 0.085 * flicker, 0.48
	)
	# Odun + alev: alev üç dilim, en içi en açık.
	for side in [-1.0, 1.0]:
		draw_line(
			fire + Vector2(-14.0 * side, 2.0), fire + Vector2(9.0 * side, -7.0),
			Color(0.32, 0.24, 0.18), 3.5
		)
	var h := 22.0 * flicker
	draw_colored_polygon(PackedVector2Array([
		fire + Vector2(-8.0, 0.0), fire + Vector2(0.0, -h), fire + Vector2(8.0, 0.0),
	]), Color(0.92, 0.42, 0.16, 0.92))
	draw_colored_polygon(PackedVector2Array([
		fire + Vector2(-4.5, 0.0), fire + Vector2(0.5, -h * 0.66), fire + Vector2(4.5, 0.0),
	]), Color(1.0, 0.82, 0.40, 0.95))

## Hava. Üç katman: kasvet gökyüzünde (bkz. _draw_sky), sis ufukta,
## yağmur her yerde. Yoğunluklar `RouteWeather.visuals`'tan - ekran kendi
## sayısını uydurmuyor.
func _draw_weather(area: Rect2, horizon: float) -> void:
	var fog := float(_weather_visuals.fog)
	if fog > 0.0:
		var haze := Color(_sky.haze)
		# Sis bantları: ufka yakın olan en yoğun, aşağı indikçe açılıyor.
		# Tek bir düz katman "ekranın üstüne beyaz koymak" gibi duruyordu.
		for index in FOG_BANDS:
			var ratio := float(index) / float(FOG_BANDS - 1)
			var y := horizon - area.size.y * 0.06 + ratio * area.size.y * 0.52
			var band_h := area.size.y * 0.11
			var drift := sin(_time * 0.12 + float(index) * 1.3) * area.size.x * 0.02
			draw_rect(
				Rect2(Vector2(drift - area.size.x * 0.05, y), Vector2(area.size.x * 1.1, band_h)),
				Color(haze.r, haze.g, haze.b, fog * 0.20 * (1.0 - ratio * 0.55)), true
			)

	var rain := float(_weather_visuals.rain)
	if rain <= 0.0:
		return
	var drops := int(RAIN_MAX_DROPS * rain)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31337
	var color := Color(0.74, 0.80, 0.88, 0.30 + rain * 0.22)
	for _index in drops:
		var speed := rng.randf_range(0.75, 1.35)
		var x0 := rng.randf() * area.size.x * 1.3 - area.size.x * 0.15
		var y0 := fposmod(
			rng.randf() * area.size.y + _time * RAIN_SPEED * speed, area.size.y
		)
		var length := area.size.y * rng.randf_range(0.035, 0.075) * (0.6 + rain * 0.6)
		draw_line(
			Vector2(x0, y0), Vector2(x0 - length * RAIN_SLANT, y0 + length),
			color, maxf(1.0, rain * 1.4)
		)
	# Yerde sıçrama: yağmurun yola değdiğini gösteren şey.
	var splash_rng := RandomNumberGenerator.new()
	splash_rng.seed = int(_time * 14.0)
	for _index in int(10.0 * rain):
		var sx := splash_rng.randf() * area.size.x
		draw_arc(
			Vector2(sx, _ground_y_at_screen(sx)), splash_rng.randf_range(2.0, 5.0),
			PI, TAU, 6, Color(0.80, 0.86, 0.92, 0.35), 1.2
		)

func _announce_ground_line() -> void:
	var x := size.x * CARAVAN_X_RATIO
	ground_line_changed.emit(x, _ground_y_at_screen(x))
