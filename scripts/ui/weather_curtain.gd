class_name WeatherCurtain
extends Control

## Gökten düşenin perdesi: yağmur, karla karışık, dolu, kar, tipi, sis.
## Ekranı **döşeyerek** kaplıyor - sprite sheet'ler yatayda ve dikeyde
## dikişsiz (`tools/efekt/uret.py`, sarmalı taşma), yani bir döşemenin
## kenarı komşusunun kenarına tam oturuyor.
##
## Üç kural:
##
## 1. **Perde hava sisteminin kendisinden geliyor, ekran kendi
##    uydurmuyor.** Hangi perde, hangi yoğunlukta: `RouteWeather.visuals`
##    ve çağıranın verdiği kar payı (`Temperature`'dan). Mekanik ve görsel
##    tek kaynaktan - yolu yavaşlatan yağmur ekranda görünenin aynısı.
## 2. **Derinlik iki katman.** Uzak perde küçük, soluk ve yavaş; yakın
##    perde büyük, belirgin ve hızlı. Tek katman cam önüne yapıştırılmış
##    bir doku gibi duruyor; iki katman arasındaki hız farkı yağmuru
##    sahnenin *içine* koyuyor.
## 3. **Perde kervanla birlikte kayıyor.** Yatay kayma dünya x'inden
##    geliyor: kervan yürürken yağmur da geçiyor, dururken duruyor.
##    Sabit kayma, duran kervanın üstünde akan yağmur demekti.

const SNOW_FULL: float = 0.60
const SLEET_FROM: float = 0.25

## Uzak katman: ölçeği küçük (damla ince görünür), soluk, yavaş kayar.
const FAR_SCALE: float = 0.62
const FAR_ALPHA: float = 0.55
const FAR_PARALLAX: float = 0.45
const NEAR_PARALLAX: float = 1.0

var px_per_metre: float = 60.0
var world_x: float = 0.0

var _layers: Array[Dictionary] = []
var _time: float = 0.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func set_px_per_metre(value: float) -> void:
	var next := maxf(1.0, value)
	if not is_equal_approx(next, px_per_metre):
		px_per_metre = next
		queue_redraw()

func set_world_x(value: float) -> void:
	if not is_equal_approx(value, world_x):
		world_x = value
		queue_redraw()

func layer_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for layer in _layers:
		out.append(String(layer.id))
	return out

## Hangi perdenin düşeceği. `rain` ve `fog` `RouteWeather.visuals`'tan,
## `snow_share` `Temperature`'dan (0 yağmur, 1 kar): sıcaklığın tek sahibi
## orası, perde onu yalnızca okuyor.
static func layers_for(rain: float, fog: float, snow_share: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if rain > 0.01:
		var heavy := rain >= 0.85
		var near_id := ""
		if snow_share >= SNOW_FULL:
			near_id = "blizzard" if heavy else ("snow_heavy" if rain >= 0.5 else "snow_light")
		elif snow_share >= SLEET_FROM:
			near_id = "sleet"
		else:
			near_id = "rain_heavy" if heavy else ("rain_medium" if rain >= 0.4 else "rain_light")
		out.append({"id": near_id, "scale": 1.0, "alpha": clampf(0.55 + rain * 0.45, 0.0, 1.0),
					"parallax": NEAR_PARALLAX})
		# Uzak katman hep bir derece hafifi: sağanağın arkasında da yağmur
		# var ama orada incelip griye gidiyor.
		var far_id := _one_step_lighter(near_id)
		out.append({"id": far_id, "scale": FAR_SCALE, "alpha": clampf(rain, 0.0, 1.0) * FAR_ALPHA,
					"parallax": FAR_PARALLAX})
	if fog > 0.12:
		out.append({"id": "fog_drift", "scale": 1.0, "alpha": clampf(fog, 0.0, 1.0),
					"parallax": FAR_PARALLAX * 0.6})
	# Resmi olmayan perde listeye girmez. Girseydi çağıran "perde var" diye
	# şeridin kendi prosedürel yağmurunu susturur ve ekranda hiç yağmur
	# kalmazdı - sanat eksikken oyunun sessizce bozulması (PropArt'ın
	# "resmi yoksa çağıran kendi çizimine düşer" kuralının ta kendisi).
	var kept: Array[Dictionary] = []
	for layer in out:
		if FxCatalog.has(String(layer.id)):
			kept.append(layer)
	return kept

static func _one_step_lighter(id: String) -> String:
	match id:
		"rain_heavy": return "rain_medium"
		"rain_medium": return "rain_light"
		"snow_heavy": return "snow_light"
		"blizzard": return "snow_heavy"
		"sleet": return "rain_light"
		_: return id

func set_layers(layers: Array[Dictionary]) -> void:
	_layers = layers
	visible = not layers.is_empty()
	set_process(visible)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	for layer in _layers:
		_draw_layer(layer)

func _draw_layer(layer: Dictionary) -> void:
	var id: String = layer.id
	if not FxCatalog.has(id):
		return
	var info := FxCatalog.info(id)
	var tile_w := float(info.get("m", 5.0)) * px_per_metre * float(layer.scale)
	if tile_w < 8.0:
		return
	var tile_h := tile_w * float(info.get("boy", 1)) / maxf(1.0, float(info.get("en", 1)))
	var frame := FxCatalog.frame_at(id, _time)
	var tint := Color(1.0, 1.0, 1.0, clampf(float(layer.alpha), 0.0, 1.0))
	# Kayma dünya x'inden; `fposmod` ile ilk döşeme hep ekranın soluna
	# düşer, yani kervan ne kadar yol alırsa alsın döşeme sayısı sabit.
	var shift := fposmod(-world_x * float(layer.parallax), tile_w)
	var cols := int(ceil(size.x / tile_w)) + 1
	var rows := int(ceil(size.y / tile_h)) + 1
	for row in rows:
		for col in cols:
			var pos := Vector2(shift - tile_w + float(col) * tile_w, float(row) * tile_h)
			FxCatalog.draw_frame(self, id, Rect2(pos, Vector2(tile_w, tile_h)), frame, tint)
