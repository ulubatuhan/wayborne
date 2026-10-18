class_name PropArt
extends RefCounted

## Render edilmiş eşyaların (vagon, kapı, değirmen, bina, kamp, silah) tek
## çizim kapısı. Eşyalar `tools/figure_pipeline/props/`'tan figürlerle aynı
## ışıkta ve aynı dört tonda geliyor; burada yalnız yerleştiriliyor.
##
## Ölçek her çağıranın kendi ölçüsünden: `k` oyun pikseli / render pikseli.
## Render metre başına `ppm` piksel, yani bir eşyayı gerçek boyuyla çizmek
## için `k = (oyun pikseli / metre) / ppm` (bkz. `scale_for_height`).
##
## Bir resim yoksa her fonksiyon sessizce hiçbir şey yapmıyor ve `has()`
## yanlış dönüyor; çağıran prosedürel çizimine düşüyor - sanat bir eşya
## bir eşya gelebilsin diye (Wardrobe'un aynı kuralı).
##
## Döndürme ve eğme `draw_set_transform` ile değil, köşeleri hesaplanmış bir
## çokgenle: çağıranlar (RoadCaravan'ın dönüş aynalaması) kendi dönüşümünü
## kurmuş olabiliyor ve tuvalin o anki dönüşümü okunamıyor - üstüne yazmak
## onu bozardı.

const SHEET_PATH := "res://data/assets/props/props.tres"
const DIR := "res://data/assets/props/"
const QUAD_UV := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]

static var _sheet: Dictionary = {}
static var _loaded: bool = false
static var _textures: Dictionary = {}

static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	if not ResourceLoader.exists(SHEET_PATH):
		return
	var res := load(SHEET_PATH)
	if res != null and "props" in res:
		_sheet = res.props

static func has(id: String) -> bool:
	_ensure()
	return _sheet.has(id)

static func info(id: String) -> Dictionary:
	_ensure()
	return _sheet.get(id, {})

static func ids() -> Array:
	_ensure()
	return _sheet.keys()

static func has_layer(id: String, layer: String) -> bool:
	return info(id).get("layers", {}).has(layer)

static func texture(id: String, layer: String) -> Texture2D:
	var key := id + "/" + layer
	if _textures.has(key):
		return _textures[key]
	var path := DIR + key + ".png"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = TextureLoader.with_mipmaps(load(path) as Texture2D)
	_textures[key] = tex
	return tex

static func ppm(id: String) -> float:
	return float(info(id).get("ppm", 100.0))

## Gerçek boyu `metres` olan şeyi ekranda `pixels` yüksekliğinde çizmek
## için gereken k.
static func scale_for_height(id: String, pixels: float, metres: float) -> float:
	return pixels / maxf(metres, 0.001) / ppm(id)

## Eşyanın metre cinsinden boyutu (x derinlik, y genişlik, z yükseklik).
static func size_m(id: String) -> Vector3:
	var s: Array = info(id).get("size_m", [0, 0, 0])
	return Vector3(float(s[0]), float(s[1]), float(s[2]))

## Katmanın oyun koordinatındaki dikdörtgeni; `base` çapa (yere bastığı orta).
static func layer_rect(id: String, layer: String, base: Vector2, k: float, flip: bool = false) -> Rect2:
	var tex := texture(id, layer)
	var at: Array = info(id).get("layers", {}).get(layer, [])
	if tex == null or at.size() < 2:
		return Rect2()
	var tl := Vector2(float(at[0]), float(at[1])) * k
	var sz := Vector2(tex.get_width(), tex.get_height()) * k
	if flip:
		tl.x = -tl.x - sz.x
	return Rect2(base + tl, sz)

static func pivot(id: String, name: String, base: Vector2, k: float, flip: bool = false) -> Vector2:
	var p: Array = info(id).get("pivots", {}).get(name, [0, 0])
	var v := Vector2(float(p[0]), float(p[1])) * k
	if flip:
		v.x = -v.x
	return base + v

## Bütün eşyanın (bütün katmanlarının) dikdörtgeni.
static func bounds(id: String, base: Vector2, k: float, flip: bool = false) -> Rect2:
	var out := Rect2()
	var first := true
	for layer in info(id).get("layers", {}).keys():
		var r := layer_rect(id, layer, base, k, flip)
		if r.size == Vector2.ZERO:
			continue
		out = r if first else out.merge(r)
		first = false
	return out

static func draw_layer(
	canvas: CanvasItem, id: String, layer: String, base: Vector2, k: float,
	tint: Color = Color.WHITE, flip: bool = false
) -> void:
	var r := layer_rect(id, layer, base, k, flip)
	if r.size == Vector2.ZERO:
		return
	_quad(canvas, texture(id, layer), [
		r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y),
	], tint, flip)

## Katmanı `pivot_name` mili etrafında `angle` kadar döndürerek çizer
## (tekerlek, değirmen kanadı).
static func draw_layer_rotated(
	canvas: CanvasItem, id: String, layer: String, base: Vector2, k: float,
	pivot_name: String, angle: float, tint: Color = Color.WHITE, flip: bool = false
) -> void:
	var r := layer_rect(id, layer, base, k, flip)
	if r.size == Vector2.ZERO:
		return
	var c := pivot(id, pivot_name, base, k, flip)
	var a := -angle if flip else angle
	var corners := []
	for p in [r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]:
		corners.append(c + (p - c).rotated(a))
	_quad(canvas, texture(id, layer), corners, tint, flip)

## Katmanı tabanı sabit, tepesi `sway` piksel yana kayacak şekilde eğer
## (branda): kemer eğiliyor, kaymıyor.
static func draw_layer_skewed(
	canvas: CanvasItem, id: String, layer: String, base: Vector2, k: float,
	sway: float, tint: Color = Color.WHITE, flip: bool = false
) -> void:
	var r := layer_rect(id, layer, base, k, flip)
	if r.size == Vector2.ZERO:
		return
	var s := -sway if flip else sway
	_quad(canvas, texture(id, layer), [
		r.position + Vector2(s, 0), r.position + Vector2(r.size.x + s, 0), r.end,
		r.position + Vector2(0, r.size.y),
	], tint, flip)

static func _quad(canvas: CanvasItem, tex: Texture2D, corners: Array, tint: Color, flip: bool) -> void:
	if tex == null:
		return
	var uvs := PackedVector2Array()
	for uv in QUAD_UV:
		uvs.append(Vector2(1.0 - uv.x, uv.y) if flip else uv)
	canvas.draw_polygon(PackedVector2Array(corners), PackedColorArray([tint]), uvs, tex)

## Duvarın arkasında kalan katmanlar (kapı kanadı) önce, gerisi sırayla.
const BEHIND_LAYERS := ["gate"]

## Bütün katmanları durağan çizer (dönen/kalkan parçası olmayan eşya ya
## da o parçası o an durgun olan).
static func draw_all(
	canvas: CanvasItem, id: String, base: Vector2, k: float,
	tint: Color = Color.WHITE, flip: bool = false
) -> void:
	var layers: Array = info(id).get("layers", {}).keys()
	for layer in layers:
		if layer in BEHIND_LAYERS:
			draw_layer(canvas, id, layer, base, k, tint, flip)
	for layer in layers:
		if not layer in BEHIND_LAYERS:
			draw_layer(canvas, id, layer, base, k, tint, flip)

## Katmanı iki nokta arasına gerer: resmin alt ortası `from_pt`, üst ortası
## `to_pt` (silahlar dik render edildi, sap altta). En boyla orantılı
## ölçekleniyor. `mirror` sola bakan figürün elindeki silahı aynalar -
## baltanın ağzı ve kılıcın sırtı yön değiştirsin.
static func draw_between(
	canvas: CanvasItem, id: String, layer: String, from_pt: Vector2, to_pt: Vector2,
	tint: Color = Color.WHITE, mirror: bool = false
) -> void:
	var tex := texture(id, layer)
	if tex == null:
		return
	var axis := to_pt - from_pt
	var length := axis.length()
	if length < 0.5:
		return
	var up := axis / length
	var side := Vector2(-up.y, up.x) * (length * float(tex.get_width()) / float(tex.get_height()) * 0.5)
	# Köşeler sol üst, sağ üst, sağ alt, sol alt (QUAD_UV sırası).
	_quad(canvas, tex, [to_pt - side, to_pt + side, from_pt + side, from_pt - side], tint, mirror)

## Bir silahın gerçek boyu (metre) - pakette render edildiği en uzun ölçü.
static func long_side_m(id: String) -> float:
	var s := size_m(id)
	return maxf(s.x, maxf(s.y, s.z))
