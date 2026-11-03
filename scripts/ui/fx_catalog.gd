class_name FxCatalog
extends RefCounted

## Efekt sprite sheet'lerinin tek kapısı: manifestoyu okur, dokuyu tembel
## yükler, bir karenin dokudaki dikdörtgenini verir.
##
## Efektler `tools/efekt/` ile üretiliyor - her biri resim değil **kod**
## (parçacık parametreleri), sprite sheet o kodun çıktısı. Rengi ya da
## yoğunluğu değiştirip `python3 tools/efekt/uret.py <id>` demek yeter;
## oyun tarafında hiçbir sayı yazılı değil, hepsi manifestodan geliyor.
##
## Kural, `PropArt` ile aynı: **bir efektin resmi yoksa `has()` yanlış
## döner ve çağıran sessizce çizmekten vazgeçer.** Sanat parça parça
## gelebilir; eksik bir doku oyunu durdurmaz.

const SHEET_DIR: String = "res://data/assets/fx/sheets/"
const MANIFEST: String = SHEET_DIR + "fx.json"

## Bir insanın boyu (metre). Efektin dünyadaki eni (`m`) bununla figür
## boyuna çevriliyor: ekran çözünürlüğü değişince efekt de büyüyor,
## çünkü figür de büyüyor (bkz. Prop Rules, "ölçek gerçek boy").
const PERSON_METRES: float = 1.73

static var _defs: Dictionary = {}
static var _textures: Dictionary = {}
static var _loaded: bool = false

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(MANIFEST):
		return
	var text := FileAccess.get_file_as_string(MANIFEST)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root: Dictionary = parsed
	var efektler: Variant = root.get("efektler", {})
	if typeof(efektler) == TYPE_DICTIONARY:
		_defs = efektler

static func ids() -> PackedStringArray:
	_ensure_loaded()
	var out := PackedStringArray()
	for key in _defs.keys():
		out.append(String(key))
	out.sort()
	return out

static func has(id: String) -> bool:
	_ensure_loaded()
	return _defs.has(id) and texture(id) != null

static func info(id: String) -> Dictionary:
	_ensure_loaded()
	var entry: Variant = _defs.get(id, {})
	return entry if typeof(entry) == TYPE_DICTIONARY else {}

static func texture(id: String) -> Texture2D:
	_ensure_loaded()
	if _textures.has(id):
		return _textures[id]
	var tex := TextureLoader.load_any(SHEET_DIR + id + ".png")
	_textures[id] = tex
	return tex

## Efektin bir turunun saniyesi. Tek seferlik efektler bu süre dolunca
## biter; döngülüler başa sarar.
static func duration(id: String) -> float:
	var d := info(id)
	if d.is_empty():
		return 0.0
	var fps := maxf(1.0, float(d.get("fps", 24)))
	return float(d.get("kare", 1)) / fps

static func is_loop(id: String) -> bool:
	return bool(info(id).get("dongu", false))

## Efektin kaç kare oynadığını değil, **hangi** kareyi göstereceğini
## söyler. Döngüde sarar, tek seferlikte son karede durur.
static func frame_at(id: String, elapsed: float) -> int:
	var d := info(id)
	if d.is_empty():
		return 0
	var count := int(d.get("kare", 1))
	if count <= 1:
		return 0
	var fps := maxf(1.0, float(d.get("fps", 24)))
	var index := int(floor(elapsed * fps))
	if bool(d.get("dongu", false)):
		return posmod(index, count)
	return clampi(index, 0, count - 1)

## Karenin dokudaki yeri. Kareler arasında `bosluk` piksel var: süzgeç
## komşu kareden piksel çekmesin diye (bkz. `tools/efekt/uret.py`).
static func region(id: String, frame: int) -> Rect2:
	var d := info(id)
	if d.is_empty():
		return Rect2()
	var w := float(d.get("en", 1))
	var h := float(d.get("boy", 1))
	var gap := float(d.get("bosluk", 0))
	var cols := maxi(1, int(d.get("sutun", 1)))
	var col := frame % cols
	var row := frame / cols
	return Rect2(
		Vector2(float(col) * (w + gap * 2.0) + gap, float(row) * (h + gap * 2.0) + gap),
		Vector2(w, h)
	)

## Efektin ekranda kaplayacağı dikdörtgen. `anchor` efektin **mili**nin
## oturacağı nokta: yerden fışkıran her şeyin mili alt-orta olduğu için
## ayak basma noktası doğrudan verilebiliyor.
static func rect_for(id: String, anchor: Vector2, px_per_metre: float, scale: float = 1.0) -> Rect2:
	var d := info(id)
	if d.is_empty():
		return Rect2()
	var width := float(d.get("m", 1.0)) * px_per_metre * scale
	var aspect := float(d.get("boy", 1)) / maxf(1.0, float(d.get("en", 1)))
	var size_px := Vector2(width, width * aspect)
	var pivot: Array = d.get("mil", [0.5, 1.0])
	var px := float(pivot[0]) if pivot.size() > 0 else 0.5
	var py := float(pivot[1]) if pivot.size() > 1 else 1.0
	return Rect2(anchor - Vector2(size_px.x * px, size_px.y * py), size_px)

static func can_flip(id: String) -> bool:
	return String(info(id).get("oklama", "yok")) == "x"

## Bir figürün boyundan piksel/metre. Efektler buradan ölçekleniyor, yani
## 1080p'de büyüyen kervanla birlikte sıçrama da büyüyor.
static func px_per_metre(figure_height: float) -> float:
	return maxf(1.0, figure_height) / PERSON_METRES

## Çizim. `draw_set_transform` kullanılmıyor: tuvalin o anki dönüşümü
## okunamıyor ve `RoadCaravan` dönüş aynalaması için kendi dönüşümünü
## kuruyor - üstüne yazmak onu bozardı (bkz. Prop Rules).
static func draw_frame(
	canvas: CanvasItem, id: String, rect: Rect2, frame: int,
	tint: Color = Color.WHITE, flip: bool = false
) -> void:
	var tex := texture(id)
	if tex == null or rect.size == Vector2.ZERO:
		return
	var src := region(id, frame)
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var u0 := src.position.x / size.x
	var v0 := src.position.y / size.y
	var u1 := src.end.x / size.x
	var v1 := src.end.y / size.y
	if flip:
		var swap := u0
		u0 = u1
		u1 = swap
	canvas.draw_polygon(
		PackedVector2Array([
			rect.position, Vector2(rect.end.x, rect.position.y),
			rect.end, Vector2(rect.position.x, rect.end.y),
		]),
		PackedColorArray([tint]),
		PackedVector2Array([
			Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1),
		]),
		tex
	)
