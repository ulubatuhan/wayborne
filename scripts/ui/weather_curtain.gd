class_name WeatherCurtain
extends Control

## Gökten düşenin perdesi: yağmur, karla karışık, dolu, kar, tipi, sis.
## Ekranı **döşeyerek** kaplıyor - sprite sheet'ler yatayda ve dikeyde
## dikişsiz (`tools/efekt/uret.py`, sarmalı taşma), yani bir döşemenin
## kenarı komşusunun kenarına tam oturuyor.
##
## Dört kural:
##
## 1. **Perde hava sisteminin kendisinden geliyor, ekran kendi
##    uydurmuyor.** Hangi perde, hangi yoğunlukta: `RouteWeather.visuals`
##    ve çağıranın verdiği kar payı (`Temperature`'dan). Mekanik ve görsel
##    tek kaynaktan - yolu yavaşlatan yağmur ekranda görünenin aynısı.
## 2. **Derinlik üç düzlem, ve her düzlem sahnenin kendi katmanları
##    arasında duruyor** (kullanıcı, 2026-11-13: "tüm ekranın üstüne bir
##    yağmur filtresi geçirilmiş gibi"). İlk hâlde iki katman da dünyanın en
##    üstüne çiziliyordu; uzak yağmur bile ön plan otlarının önünden
##    geçiyordu, yani derinlik yalnız ölçek farkıydı ve göz onu camın
##    üstünde okuyordu. Şimdi:
##    - `Depth.FAR` şeridin çocuğu, kervandan önce: yalnız gökle yolun uzak
##      kenarı arasında, ince, soluk, yavaş; altında ufku griye çeken bir
##      perde (uzaktaki yağmur tek tek görünmez, havayı bulandırır).
##    - `Depth.MID` şeridin çocuğu, kervandan sonra ama ön plandan önce:
##      kervanın önünden geçer, yol yüzeyinde biter.
##    - `Depth.NEAR` dünyanın en üstünde, ön plan otlarının da önünde: az,
##      iri, hızlı - kameraya en yakın damla.
##    Yağış her düzlemde aynı (aynı resim, aynı kare); değişen ölçek,
##    saydamlık, kayma hızı ve dikey pencere. Sahte bir derinlik değil,
##    sahnenin gerçek katman sırası.
## 3. **Perde kervanla birlikte kayıyor.** Yatay kayma dünya x'inden
##    geliyor: kervan yürürken yağmur da geçiyor, dururken duruyor.
##    Sabit kayma, duran kervanın üstünde akan yağmur demekti. Yakın düzlem
##    daha hızlı kayar - parallaksın yönü manzarayla aynı.
## 4. **Pencerenin kenarı yumuşak.** Uzak düzlemin yağmuru yolun kenarında
##    bıçakla kesilmiş gibi bitseydi ekranda bir çizgi okunurdu; son payda
##    saydamlığı sıfıra iner.

enum Depth { FAR, MID, NEAR }

const SNOW_FULL: float = 0.60
const SLEET_FROM: float = 0.25

## `layers_for`'un iki girdisi: yakın (asıl yağış) ve uzak (bir derece hafifi).
const FAR_SCALE: float = 0.62
const FAR_ALPHA: float = 0.55
const FAR_PARALLAX: float = 0.45
const NEAR_PARALLAX: float = 1.0

## Düzlemlerin kendi ölçekleri. Uzak küçük (ince damla, sık), yol düzlemi
## kervanın boyunda, yakın iri ve seyrek (döşeme büyüdükçe birim alana düşen
## damla azalıyor - seyreklik ölçekten bedava geliyor).
const PLANE_FAR_SCALE: float = 0.60
const PLANE_MID_SCALE: float = 0.92
const PLANE_NEAR_SCALE: float = 2.3
## Kayma hızları: uzak manzaranın arka katmanlarına, yakın önündekine uyar.
const PLANE_FAR_PARALLAX: float = 0.30
const PLANE_NEAR_PARALLAX: float = 1.7
## Saydamlık çarpanları. Yakın düzlem ekranın tamamını örttüğü için düşük:
## asıl yağış yol düzleminde, yakındaki birkaç damla yalnız ölçek verir.
const PLANE_MID_ALPHA: float = 0.85
const PLANE_FAR_ALPHA: float = 0.65
const PLANE_NEAR_ALPHA: float = 0.36
## Uzak düzlemin bittiği yer: yolun ortasından bu kadar yukarısı (şerit
## yüksekliğinin payı) ve kenarın yumuşadığı pay.
const FAR_STOP_RATIO: float = 0.045
const FAR_FADE_RATIO: float = 0.10
## Yol düzleminin bittiği yer: yolun ortasının biraz altı (tekerleğin bastığı
## yer) - ön plan otunun arkasında kalan yağmur yere orada değer.
const MID_STOP_RATIO: float = 0.035
const MID_FADE_RATIO: float = 0.05
## Ufku bulandıran perdenin en yoğun saydamlığı (yağış 1'de).
const VEIL_ALPHA: float = 0.22

var plane: Depth = Depth.NEAR
var px_per_metre: float = 60.0
var world_x: float = 0.0

var _layers: Array[Dictionary] = []
var _time: float = 0.0
var _snowy: bool = false
var _veil: float = 0.0

func _init(on_plane: Depth = Depth.NEAR) -> void:
	plane = on_plane
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
## orası, perde onu yalnızca okuyor. Dönen liste düzlemden bağımsız; her
## düzlem kendi payını `plane_layers` ile çıkarır.
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
					"parallax": NEAR_PARALLAX, "role": "near"})
		# Uzak katman hep bir derece hafifi: sağanağın arkasında da yağmur
		# var ama orada incelip griye gidiyor.
		var far_id := _one_step_lighter(near_id)
		out.append({"id": far_id, "scale": FAR_SCALE, "alpha": clampf(rain, 0.0, 1.0) * FAR_ALPHA,
					"parallax": FAR_PARALLAX, "role": "far"})
	if fog > 0.12:
		out.append({"id": "fog_drift", "scale": 1.0, "alpha": clampf(fog, 0.0, 1.0),
					"parallax": FAR_PARALLAX * 0.6, "role": "fog"})
	# Resmi olmayan perde listeye girmez. Girseydi çağıran "perde var" diye
	# şeridin kendi prosedürel yağmurunu susturur ve ekranda hiç yağmur
	# kalmazdı - sanat eksikken oyunun sessizce bozulması (PropArt'ın
	# "resmi yoksa çağıran kendi çizimine düşer" kuralının ta kendisi).
	var kept: Array[Dictionary] = []
	for layer in out:
		if FxCatalog.has(String(layer.id)):
			kept.append(layer)
	return kept

## Bir düzlemin `layers_for` listesinden çizdiği pay. Uzak düzlem hafif
## yağışı ve sisi, yol düzlemi asıl yağışı (ve sisin yarısını), yakın düzlem
## yine asıl yağışı ama iri ve seyrek çizer.
static func plane_layers(layers: Array[Dictionary], on_plane: Depth) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for layer in layers:
		var role := String(layer.get("role", "near"))
		var copy: Dictionary = layer.duplicate()
		match on_plane:
			Depth.FAR:
				if role == "far":
					copy.scale = PLANE_FAR_SCALE
					copy.parallax = PLANE_FAR_PARALLAX
					# Küçülen döşeme birim alana düşen taneyi artırıyor; uzakta
					# tek tek tane değil bulanıklık görünür, saydamlığı perde
					# taşır (tipide ilk deneme arka planı düz bir duvarla örttü).
					copy.alpha = float(layer.alpha) * PLANE_FAR_ALPHA
				elif role == "fog":
					copy.parallax = PLANE_FAR_PARALLAX * 0.6
				else:
					continue
			Depth.MID:
				if role == "near":
					copy.scale = PLANE_MID_SCALE
					copy.alpha = float(layer.alpha) * PLANE_MID_ALPHA
					copy.parallax = 1.0
				elif role == "fog":
					copy.alpha = float(layer.alpha) * 0.4
					copy.parallax = 0.8
				else:
					continue
			Depth.NEAR:
				if role != "near":
					continue
				copy.scale = PLANE_NEAR_SCALE
				copy.alpha = float(layer.alpha) * PLANE_NEAR_ALPHA
				copy.parallax = PLANE_NEAR_PARALLAX
		out.append(copy)
	return out

static func _one_step_lighter(id: String) -> String:
	match id:
		"rain_heavy": return "rain_medium"
		"rain_medium": return "rain_light"
		"snow_heavy": return "snow_light"
		"blizzard": return "snow_heavy"
		"sleet": return "rain_light"
		_: return id

## `layers`: `layers_for`'un bütün listesi; düzlem kendi payını kendisi seçer.
## `snowy`: perdenin rengi (uzak düzlemin ufuk perdesi), `rain`: yoğunluğu.
func set_layers(layers: Array[Dictionary], rain: float = 0.0, snowy: bool = false) -> void:
	_layers = plane_layers(layers, plane)
	_snowy = snowy
	_veil = clampf(rain, 0.0, 1.0) if plane == Depth.FAR else 0.0
	visible = not _layers.is_empty() or _veil > 0.01
	set_process(visible)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

## Çizilecek dikdörtgen. Şeridin çocuğuysa şeridin görülen alanı (yakınlaşan
## şerit kendi dikdörtgeninden taşabiliyor), değilse kendisi.
func _area() -> Rect2:
	var parent := get_parent()
	if parent != null and parent.has_method("cover_rect"):
		return parent.call("cover_rect")
	return Rect2(Vector2.ZERO, size)

## Düzlemin dikey penceresi: [üst, alt, yumuşamanın başladığı y].
func _window(area: Rect2) -> Vector3:
	var top := area.position.y
	var bottom := area.end.y
	var parent := get_parent()
	if plane == Depth.NEAR or parent == null or not parent.has_method("road_line_y"):
		return Vector3(top, bottom, bottom)
	var road_y := float(parent.call("road_line_y"))
	var h := maxf(1.0, area.size.y)
	if plane == Depth.FAR:
		var stop := road_y - h * FAR_STOP_RATIO
		return Vector3(top, stop, stop - h * FAR_FADE_RATIO)
	var stop_mid := road_y + h * MID_STOP_RATIO
	return Vector3(top, stop_mid, stop_mid - h * MID_FADE_RATIO)

func _draw() -> void:
	var area := _area()
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return
	var window := _window(area)
	if _veil > 0.01:
		_draw_veil(area, window)
	for layer in _layers:
		_draw_layer(layer, area, window)

## Uzaktaki yağış tek tek görünmez, havayı bulandırır: ufkun çevresinde
## yoğunlaşan, yukarıda ve yolun kenarında sıfıra inen soğuk bir perde.
func _draw_veil(area: Rect2, window: Vector3) -> void:
	var colour := ArtPalette.PRECIP_VEIL_SNOW if _snowy else ArtPalette.PRECIP_VEIL_RAIN
	var peak := Color(colour, VEIL_ALPHA * _veil)
	var clear := Color(colour, 0.0)
	var top := window.x
	var bottom := window.y
	var thick := top + (bottom - top) * 0.62
	var x0 := area.position.x
	var x1 := area.end.x
	draw_polygon(PackedVector2Array([Vector2(x0, top), Vector2(x1, top), Vector2(x1, thick), Vector2(x0, thick)]),
		PackedColorArray([clear, clear, peak, peak]))
	draw_polygon(PackedVector2Array([Vector2(x0, thick), Vector2(x1, thick), Vector2(x1, bottom), Vector2(x0, bottom)]),
		PackedColorArray([peak, peak, clear, clear]))

func _draw_layer(layer: Dictionary, area: Rect2, window: Vector3) -> void:
	var id: String = layer.id
	if not FxCatalog.has(id):
		return
	var tex := FxCatalog.texture(id)
	if tex == null:
		return
	var info := FxCatalog.info(id)
	var tile_w := float(info.get("m", 5.0)) * px_per_metre * float(layer.scale)
	if tile_w < 8.0:
		return
	var tile_h := tile_w * float(info.get("boy", 1)) / maxf(1.0, float(info.get("en", 1)))
	var src := FxCatalog.region(id, FxCatalog.frame_at(id, _time))
	var tex_size := tex.get_size()
	var uv := Rect2(src.position / tex_size, src.size / tex_size)
	var alpha := clampf(float(layer.alpha), 0.0, 1.0)
	# Kayma dünya x'inden; `fposmod` ile ilk döşeme hep alanın soluna
	# düşer, yani kervan ne kadar yol alırsa alsın döşeme sayısı sabit.
	var shift := fposmod(-world_x * float(layer.parallax), tile_w)
	var x := area.position.x + shift - tile_w
	var first_row := floorf((window.x - area.position.y) / tile_h)
	while x < area.end.x:
		var y := area.position.y + first_row * tile_h
		while y < window.y:
			_tile(tex, uv, Rect2(x, y, tile_w, tile_h), alpha, window)
			y += tile_h
		x += tile_w

## Bir döşemeyi pencereye kırparak çizer: pencerenin dışı yok, yumuşama
## payında saydamlık sıfıra iner (köşe renkleriyle, ikinci bir dörtgen).
func _tile(tex: Texture2D, uv: Rect2, rect: Rect2, alpha: float, window: Vector3) -> void:
	var y0 := maxf(rect.position.y, window.x)
	var y1 := minf(rect.end.y, window.y)
	if y1 <= y0:
		return
	var fade_at := window.z
	if y0 < fade_at:
		_quad(tex, uv, rect, y0, minf(y1, fade_at), alpha, alpha)
	if y1 > fade_at:
		var span := maxf(1.0, window.y - fade_at)
		var a0 := alpha * clampf((window.y - maxf(y0, fade_at)) / span, 0.0, 1.0)
		var a1 := alpha * clampf((window.y - y1) / span, 0.0, 1.0)
		_quad(tex, uv, rect, maxf(y0, fade_at), y1, a0, a1)

func _quad(tex: Texture2D, uv: Rect2, rect: Rect2, ya: float, yb: float, alpha_a: float, alpha_b: float) -> void:
	if yb <= ya or (alpha_a <= 0.0 and alpha_b <= 0.0):
		return
	var va := uv.position.y + (ya - rect.position.y) / rect.size.y * uv.size.y
	var vb := uv.position.y + (yb - rect.position.y) / rect.size.y * uv.size.y
	var ca := Color(1.0, 1.0, 1.0, alpha_a)
	var cb := Color(1.0, 1.0, 1.0, alpha_b)
	draw_polygon(
		PackedVector2Array([
			Vector2(rect.position.x, ya), Vector2(rect.end.x, ya),
			Vector2(rect.end.x, yb), Vector2(rect.position.x, yb),
		]),
		PackedColorArray([ca, ca, cb, cb]),
		PackedVector2Array([
			Vector2(uv.position.x, va), Vector2(uv.end.x, va),
			Vector2(uv.end.x, vb), Vector2(uv.position.x, vb),
		]),
		tex
	)
