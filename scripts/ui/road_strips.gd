class_name RoadStrips
extends RefCounted

## Yolun render edilmiş paralaks katmanları: şehir resimleriyle aynı hattan
## (Blender + mürekkep son işlemesi, bkz. tools/ui_scenes/road_scene.py ve
## road_post.py), biyom başına dört şerit - uzak sırt, orta ağaç hattı,
## zemin ve yol, yolun önü.
##
## Her şerit **yatayda dikişsiz** döşeniyor: render edilen sahne x'te
## periyotlu, yani şeridin sağ kenarı sol kenarının devamı. Dört katman
## dört ayrı periyotta ve dört ayrı paralaksla döndüğü için tekrar
## okunmuyor - "manzara listeden değil dünya koordinatından" kuralı.
##
## Resim yalnızca nötr gün ışığını taşıyor; saat, gece ve yağmur yolun
## kendi ışığıyla çarpılarak geliyor (`TravelBand.get_light`). Bir biyomun
## resmi yoksa `has_biome` yanlış döner ve şerit eski prosedürel çizimine
## düşer - Wardrobe'un "sanat parça parça gelebilir" kuralı.

const DIR := "res://data/assets/ui/road/"
const FAR := "far"
const MID := "mid"
const GROUND := "ground"
const FORE := "fore"
const LAYERS: Array[String] = [FAR, MID, GROUND, FORE]

## Render'ın kendi ölçüleri (road_scene.py LAYERS) - kırpma yalnızca üstten
## yapıldığı için alttan ölçülen pikseller her biyomda aynı.
##   anchor_px: katmanın zemin noktasının resmin altından yüksekliği;
##   road_px:   (zemin) yol merkezinin yüksekliği - kervan buna basıyor.
const SPEC := {
	FAR: {"anchor_px": 61.4},
	MID: {"anchor_px": 76.8},
	GROUND: {"anchor_px": 172.8, "road_px": 172.8},
	FORE: {"anchor_px": 435.2},
}

## Bir döşemenin ekrandaki genişliği, şerit yüksekliğinin katı. Zemininki
## fiziksel: render 40 m, yolda bir insan 1.73 m'de şeridin 0.094'ü, yani
## 40 m ≈ 2.17 × şerit. Öteki üçü derinlikten: orta katmanın 7 m'lik ağacı
## şeridin ~0.1'i (zemindeki bir insandan biraz büyük, uzakta), ön planın
## otu ~0.07'si. İlk denemede ağaçlar 0.3 ile kervanı eziyordu.
const TILE_WIDTH_RATIO := {FAR: 1.5, MID: 3.4, GROUND: 2.17, FORE: 1.3}

static var _cache: Dictionary = {}

static func path_of(biome: String, layer: String) -> String:
	return DIR + biome + "/" + layer + ".png"

## Biyomun dört katmanı da varsa doğru - yarım bir set prosedürelle
## karışırsa iki ayrı prodüksiyon görünür.
static func has_biome(biome: String) -> bool:
	for layer in LAYERS:
		if texture(biome, layer) == null:
			return false
	return true

static func texture(biome: String, layer: String) -> Texture2D:
	var key := biome + "/" + layer
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	var path := path_of(biome, layer)
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		# Henüz içe aktarılmamış (yeni render) - diskten oku.
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

## Ekran pikseli / resim pikseli.
static func scale_for(layer: String, band_height: float, tex: Texture2D) -> float:
	return band_height * float(TILE_WIDTH_RATIO[layer]) / float(maxi(1, tex.get_width()))

## Bir katmanı `cover` boyunca döşer. `anchor_y` katmanın zemin noktasının
## (zeminde: yol merkezinin) ekran y'si `x = 0`'da; `shear` x başına y
## değişimi (yolun eğimi). `scroll` dünyanın bu katmandaki kayması (paralaks
## uygulanmış).
static func draw_layer(
	canvas: CanvasItem, biome: String, layer: String, band_height: float,
	scroll: float, cover: Rect2, anchor_y: float, modulate: Color, shear: float = 0.0
) -> void:
	var tex := texture(biome, layer)
	if tex == null or modulate.a <= 0.0:
		return
	var k := scale_for(layer, band_height, tex)
	var tile_w := float(tex.get_width()) * k
	var tex_h := float(tex.get_height())
	var key := "road_px" if SPEC[layer].has("road_px") else "anchor_px"
	var above := (tex_h - float(SPEC[layer][key])) * k
	var below := float(SPEC[layer][key]) * k
	var x := cover.position.x - fposmod(cover.position.x + scroll, tile_w)
	var colors := PackedColorArray([modulate])
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	while x < cover.end.x:
		var x1 := x + tile_w
		var y0 := anchor_y + x * shear
		var y1 := anchor_y + x1 * shear
		canvas.draw_polygon(PackedVector2Array([
			Vector2(x, y0 - above), Vector2(x1, y1 - above),
			Vector2(x1, y1 + below), Vector2(x, y0 + below),
		]), colors, uvs, tex)
		x = x1

## İki biyom arası geçiş: önce eski, üstüne yenisi `ratio` saydamlıkla.
static func draw_blend(
	canvas: CanvasItem, blend: Dictionary, layer: String, band_height: float,
	scroll: float, cover: Rect2, anchor_y: float, modulate: Color, shear: float = 0.0
) -> void:
	var ratio := float(blend.get("ratio", 0.0))
	var from := String(blend.get("from", ""))
	var to := String(blend.get("to", from))
	# Zemin opak: eskisi tam, yenisi üstünde belirerek. Saydam katmanlarda
	# (ağaç, sırt) eskisi de söner, yoksa iki ormanın ağaçları üst üste.
	var base := modulate
	if layer != GROUND and to != from and has_biome(to):
		base.a *= 1.0 - ratio
	draw_layer(canvas, from, layer, band_height, scroll, cover, anchor_y, base, shear)
	if ratio > 0.0 and to != from and has_biome(to):
		var faded := modulate
		faded.a *= ratio
		draw_layer(canvas, to, layer, band_height, scroll, cover, anchor_y, faded, shear)
