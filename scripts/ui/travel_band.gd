class_name TravelBand
extends Control

## Yol ekranının üstündeki manzara şeridi: gökyüzü ve zemin günün evresine
## göre renk değiştirir, işaretler kervan ilerledikçe kayar, kamp kurulunca
## ateş yanıp çevreyi aydınlatır.
##
## Sahne dosyası yok - PulseBar/CombatPanel deseninde kendini kodda kurar,
## yolculuk ekranının içine gömülür. Hâlâ ColorRect yer tutucularıyla
## (bkz. CLAUDE.md, sanat varlıkları Faz 8'in ayrı işi); buradaki her şey
## sprite geldiğinde değişecek ama arayüz sözleşmesi aynı kalabilir.
##
## Kervan şeritte sabit durur, dünya onun altından akar - ilerleme hissini
## veren şey bu (kervanı hareket ettirmek şeridin sonuna dayanırdı).

const BAND_HEIGHT: float = 150.0
const GROUND_RATIO: float = 0.62

## Zemin işaretleri: yol boyunca kayan çizgiler. Sayı ekranı doldurmaya
## yetecek kadar, kaydıkça başa sarıyorlar.
const MARKER_COUNT: int = 14
const MARKER_SPACING: float = 90.0
const MARKER_SIZE: Vector2 = Vector2(46.0, 5.0)

## Uzaktaki tepeler daha yavaş kayar - iki katmanlı basit bir paralaks,
## derinlik hissi için.
const HILL_COUNT: int = 7
const HILL_PARALLAX: float = 0.35

const CARAVAN_X_RATIO: float = 0.34
const WAGON_SIZE: Vector2 = Vector2(52.0, 34.0)
const FIGURE_SIZE: Vector2 = Vector2(14.0, 26.0)

## Kamp ateşi ve çevresine vurduğu ışık.
const FIRE_SIZE: Vector2 = Vector2(16.0, 20.0)
const FIRE_GLOW_SIZE: Vector2 = Vector2(260.0, 120.0)
const FIRE_FLICKER_SPEED: float = 9.0

## Evre paleti: [gökyüzü, zemin, kervanın üstüne vuran ışık]. Evreler
## arasında get_phase_progress ile yumuşak geçiliyor, yoksa saat başı
## renk zıplardı.
const PHASE_PALETTE: Dictionary = {
	JourneyClock.Phase.DAWN: [Color(0.55, 0.45, 0.52), Color(0.32, 0.28, 0.26), Color(0.92, 0.78, 0.72)],
	JourneyClock.Phase.MORNING: [Color(0.52, 0.68, 0.82), Color(0.38, 0.35, 0.26), Color(1.0, 0.98, 0.92)],
	JourneyClock.Phase.NOON: [Color(0.48, 0.70, 0.90), Color(0.42, 0.38, 0.28), Color(1.0, 1.0, 1.0)],
	JourneyClock.Phase.AFTERNOON: [Color(0.58, 0.64, 0.76), Color(0.40, 0.34, 0.25), Color(1.0, 0.95, 0.84)],
	JourneyClock.Phase.EVENING: [Color(0.62, 0.44, 0.40), Color(0.28, 0.24, 0.22), Color(0.96, 0.76, 0.62)],
	JourneyClock.Phase.NIGHT: [Color(0.10, 0.12, 0.22), Color(0.14, 0.13, 0.15), Color(0.42, 0.48, 0.68)],
}

## Evre sırası - bir evrenin "sonraki"si buradan bulunur (gece başa sarar).
const PHASE_ORDER: Array = [
	JourneyClock.Phase.DAWN,
	JourneyClock.Phase.MORNING,
	JourneyClock.Phase.NOON,
	JourneyClock.Phase.AFTERNOON,
	JourneyClock.Phase.EVENING,
	JourneyClock.Phase.NIGHT,
]

var _sky: ColorRect
var _ground: ColorRect
var _markers: Array[ColorRect] = []
var _hills: Array[ColorRect] = []
var _wagon: ColorRect
var _figures: Array[ColorRect] = []
var _fire: ColorRect
var _fire_glow: ColorRect
var _stars: Array[ColorRect] = []

var _scroll: float = 0.0
var _camping: bool = false
var _flicker: float = 0.0
var _light: Color = Color.WHITE

func _ready() -> void:
	custom_minimum_size = Vector2(0.0, BAND_HEIGHT)
	clip_contents = true
	_build()
	resized.connect(_layout)

func _build() -> void:
	_sky = ColorRect.new()
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sky)

	# Yıldızlar yalnızca gece görünür; konumları sabit, sönüp yanmıyorlar.
	for index in 18:
		var star := ColorRect.new()
		star.color = Color(1.0, 1.0, 0.94)
		star.size = Vector2(2.0, 2.0)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(star)
		_stars.append(star)

	for index in HILL_COUNT:
		var hill := ColorRect.new()
		hill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hill)
		_hills.append(hill)

	_ground = ColorRect.new()
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ground)

	for index in MARKER_COUNT:
		var marker := ColorRect.new()
		marker.size = MARKER_SIZE
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(marker)
		_markers.append(marker)

	# Ateşin ışığı kervanın altında durur ki gövdeleri yıkamasın.
	_fire_glow = ColorRect.new()
	_fire_glow.size = FIRE_GLOW_SIZE
	_fire_glow.visible = false
	_fire_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fire_glow)

	_wagon = ColorRect.new()
	_wagon.size = WAGON_SIZE
	_wagon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wagon)

	for index in 2:
		var figure := ColorRect.new()
		figure.size = FIGURE_SIZE
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(figure)
		_figures.append(figure)

	_fire = ColorRect.new()
	_fire.size = FIRE_SIZE
	_fire.visible = false
	_fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fire)

	_layout()

func _layout() -> void:
	if _sky == null:
		return
	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, BAND_HEIGHT)
	var horizon := height * GROUND_RATIO

	_sky.position = Vector2.ZERO
	_sky.size = Vector2(width, horizon)
	_ground.position = Vector2(0.0, horizon)
	_ground.size = Vector2(width, height - horizon)

	for index in _stars.size():
		# Sabit ama düzensiz bir dağılım - rastgele sayı üretmeden.
		var fx := fposmod(float(index) * 137.0, width)
		var fy := fposmod(float(index) * 53.0, maxf(horizon - 12.0, 1.0))
		_stars[index].position = Vector2(fx, fy)

	var caravan_x := width * CARAVAN_X_RATIO
	_wagon.position = Vector2(caravan_x, horizon - WAGON_SIZE.y)
	for index in _figures.size():
		_figures[index].position = Vector2(
			caravan_x + WAGON_SIZE.x + 10.0 + float(index) * 20.0,
			horizon - FIGURE_SIZE.y
		)
	_fire.position = Vector2(caravan_x - 46.0, horizon - FIRE_SIZE.y)
	_fire_glow.position = Vector2(
		_fire.position.x + FIRE_SIZE.x * 0.5 - FIRE_GLOW_SIZE.x * 0.5,
		horizon - FIRE_GLOW_SIZE.y * 0.72
	)

func _process(delta: float) -> void:
	if not _camping:
		return
	# Ateş yalnızca kamp kurulunca canlanır; titremesi ambiyansın kendisi.
	_flicker += delta * FIRE_FLICKER_SPEED
	var pulse := 0.82 + 0.18 * sin(_flicker)
	_fire.color = Color(1.0, 0.62, 0.22, pulse)
	_fire_glow.color = Color(1.0, 0.66, 0.32, 0.10 + 0.05 * sin(_flicker * 0.6))

## Günün evresini ve evre içi ilerlemeyi uygular - renkler bir sonraki
## evreye doğru sürekli kayar, saat başı zıplamaz.
func set_phase(phase: JourneyClock.Phase, phase_progress: float) -> void:
	var current: Array = PHASE_PALETTE[phase]
	var next: Array = PHASE_PALETTE[_next_phase(phase)]
	var blend := clampf(phase_progress, 0.0, 1.0)

	var sky_color: Color = (current[0] as Color).lerp(next[0] as Color, blend)
	var ground_color: Color = (current[1] as Color).lerp(next[1] as Color, blend)
	_light = (current[2] as Color).lerp(next[2] as Color, blend)

	_sky.color = sky_color
	_ground.color = ground_color

	for marker in _markers:
		marker.color = ground_color.lightened(0.14)
	for index in _hills.size():
		# Uzaktaki tepeler gökyüzüne biraz karışır - havanın derinliği.
		_hills[index].color = ground_color.lerp(sky_color, 0.45)

	var starlight := clampf(1.0 - sky_color.get_luminance() * 3.2, 0.0, 1.0)
	for star in _stars:
		star.modulate.a = starlight

	_apply_light()

func _next_phase(phase: JourneyClock.Phase) -> JourneyClock.Phase:
	var index := PHASE_ORDER.find(phase)
	if index < 0:
		return phase
	return PHASE_ORDER[(index + 1) % PHASE_ORDER.size()]

## Kervanın ve yoldaşların üstüne günün ışığını vurur; kamptaysa ateşin
## sıcak ışığı baskın gelir.
func _apply_light() -> void:
	var tint := _light
	if _camping:
		tint = tint.lerp(Color(1.0, 0.72, 0.42), 0.55)
	_wagon.color = Color(0.55, 0.38, 0.22) * tint
	for index in _figures.size():
		var base := Color(0.82, 0.72, 0.55) if index == 0 else Color(0.72, 0.64, 0.52)
		_figures[index].color = base * tint

## Yolun ne kadarının katedildiği (0.0-1.0). Dünya kervanın altından akar:
## işaretler ve tepeler buna göre kayar, kervan yerinde durur.
func set_route_progress(progress: float) -> void:
	_scroll = clampf(progress, 0.0, 1.0)
	_reposition_scrolling_parts()

func _reposition_scrolling_parts() -> void:
	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, BAND_HEIGHT)
	var horizon := height * GROUND_RATIO

	# Yol boyunca toplam kayma; işaretler sona gelince başa sarar.
	var travelled := _scroll * MARKER_SPACING * float(MARKER_COUNT) * 6.0

	for index in _markers.size():
		var base := float(index) * MARKER_SPACING
		var x := fposmod(base - travelled, MARKER_SPACING * float(MARKER_COUNT))
		_markers[index].position = Vector2(x, horizon + 14.0 + fposmod(float(index) * 11.0, 16.0))

	var hill_spacing := width / float(maxi(1, HILL_COUNT - 1))
	for index in _hills.size():
		var hill_height := 26.0 + fposmod(float(index) * 37.0, 30.0)
		var base_x := float(index) * hill_spacing
		var x := fposmod(base_x - travelled * HILL_PARALLAX, width + hill_spacing) - hill_spacing * 0.5
		_hills[index].size = Vector2(hill_spacing * 1.3, hill_height)
		_hills[index].position = Vector2(x, horizon - hill_height)

## Kamp kurulduğunda ateş yanar ve çevre ısınır; kalkınca söner.
func set_camping(camping: bool) -> void:
	if _camping == camping:
		return
	_camping = camping
	_fire.visible = camping
	_fire_glow.visible = camping
	if not camping:
		_flicker = 0.0
	_apply_light()
