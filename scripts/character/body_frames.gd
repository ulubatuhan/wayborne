class_name BodyFrames
extends Resource

## Bir beden varyantının (ör. body_male_average) önceden render edilmiş
## kareleri: her klip (yürüme/duruş/binici), her kare, beş derinlik katmanı
## (arka kol, arka bacak, gövde+baş, ön bacak, ön kol) ve katman başına dört
## tür resim - beden ve üstüne binen atlet/bra, şort, saç. Hepsi 3B'den aynı
## karede render edildiği için eklemlerde dikiş, kopuk el ya da kırık diz
## yok (eski parça mankeni her kemiği ayrı döndürüyordu). Üreten:
## tools/figure_pipeline/mesh/pack_frames.py; yol haritası POSTMORTEM.md.
##
## Resimler gri; oyun beden katmanını tenle, giysileri kendi renkleriyle
## çarpıyor - ten rengi seçimi ve kıyafet rengi böylece hâlâ çalışıyor.
## Konumlar render pikselinde, klibin çapasına göre (yürümede ayakların
## bastığı yer, binicide kalça); oyuna `scale_for(h)` ile geçiliyor.

const LAYERS: Array[String] = ["back_arm", "back_leg", "torso_head", "front_leg", "front_arm"]
const KIND_BODY: int = 0
const KIND_TOP: int = 1
const KIND_BOTTOM: int = 2
const KIND_HAIR: int = 3
const KINDS: int = 4
## FigureRig'de omuz yerden (HIP_RATIO + TORSO_RATIO) * h yukarıda; render'ın
## kendi omuz yüksekliği bu orana eşitlenerek ölçek bulunuyor - figürün oyundaki
## boyu (h, boy ölçeği dahil) eskisiyle aynı kalsın diye.
const SHOULDER_SHARE: float = FigureRig.HIP_RATIO + FigureRig.TORSO_RATIO
## İsimsiz tayfanın bedeni: karakter verisi yok, varsayılan erkek/orta.
const CREW_BODY: String = "body_male_average"

## Hayvan yürüyüş karelerinde bir çevrimde gövdenin katettiği yol, türün
## figür boyu (`h`) cinsinden. Kaynak animasyonların kendi adımı, render'dan
## **ölçüldü** (tools/figure_pipeline/qa/beast_stride.py: yere basan
## toynağın alt bandı kareden kareye ilintiyle izleniyor). Aynı araç
## insanın karelerinde 0.607 okuyor, rig'in kendi değeri 0.633 - ölçüm %4
## içinde. Ön ve arka bacak kaynak animasyonda aynı hızda gitmiyor (atın
## ön ayağı 0.47, arkası 0.59): dört bacağın ortalaması, kaymanın en az
## olduğu değer. Kadans bundan türüyor; tablo tahminle doldurulmamalı.
const BEAST_WALK_CYCLE: Dictionary = {
	"ox": 0.380, "horse": 0.531, "horse_white": 0.531, "donkey": 0.610,
	"husky": 0.390, "wolf": 0.545, "stag": 0.532, "deer": 0.462,
	"bear": 0.450, "boar": 0.445,
}

static func beast_walk_cycle(species: String) -> float:
	return float(BEAST_WALK_CYCLE.get(species, 0.5))

@export var pages: PackedStringArray
@export var clip_names: PackedStringArray
@export var clip_frames: PackedInt32Array
## Duruş karesinde omzun çapadan yüksekliği (render pikseli). Hayvan
## kümesinde (beast_<tür>) cidağonun yüksekliği.
@export var shoulder_px: float = 1.0
## `shoulder_px`'in figür boyundaki payı. 0: insan (`SHOULDER_SHARE`);
## hayvanda türün `BeastRig.SPECIES.back`'i (pack_beasts.py yazıyor).
@export var ref_share: float = 0.0
## Bir doku pikselinin render pikseli karşılığı. Beden 1 (tam çözünürlük);
## giysi kümeleri yarım çözünürlükte paketleniyor (pack_outfits.py), çizilen
## boyut `entry().size`'da bunu taşıyor - ofsetler hep render pikselinde.
@export var texel_scale: float = 1.0
## Kayıt başına 5 tamsayı: sayfa, x, y, w, h (w = 0: o katmanda o tür yok).
@export var rects: PackedInt32Array
## Kayıt başına resmin sol üst köşesi, klip çapasına göre (render pikseli).
@export var offsets: PackedVector2Array
@export var joint_names: PackedStringArray
## Kare başına joint_names sırasıyla eklemler, çapaya göre.
@export var joints: PackedVector2Array
## Kare başına elden silah ucuna yön (render ekranında, figür sağa bakarken;
## radyan) ve yay kirişinin çekilmişliği (0..1). FigureActions'tan gelir:
## kılıç savuruşta dönüyor, yay nişanda dik duruyor.
@export var weapon_angles: PackedFloat32Array
@export var draws: PackedFloat32Array

var _textures: Array[Texture2D] = []
var _clip_base: Dictionary = {}

static var _cache: Dictionary = {}

## Varyantın kare kümesi; yoksa null (çağıran eski parça mankenine düşer).
static func for_body(body_id: String) -> BodyFrames:
	if _cache.has(body_id):
		return _cache[body_id]
	var path := "res://data/assets/characters/frames/%s/frames.tres" % body_id
	var found: BodyFrames = null
	if ResourceLoader.exists(path):
		found = load(path) as BodyFrames
	_cache[body_id] = found
	return found

func has_clip(clip: String) -> bool:
	_index_clips()
	return _clip_base.has(clip)

func frame_count(clip: String) -> int:
	_index_clips()
	return int(clip_frames[clip_names.find(clip)]) if _clip_base.has(clip) else 0

## Fazdan kare: klibin karesi i, fazı TAU*i/N olan poz (export_clips.gd).
func frame_for_phase(clip: String, phase: float) -> int:
	var n := frame_count(clip)
	if n <= 1:
		return 0
	return posmod(int(round(phase / TAU * float(n))), n)

func scale_for(h: float) -> float:
	var share := ref_share if ref_share > 0.0 else SHOULDER_SHARE
	return share * h / maxf(shoulder_px, 1.0)

## Hayvan kare kümesi (`beast_<tür>`), yoksa null.
static func for_beast(species: String) -> BodyFrames:
	return for_body("beast_" + species)

## Bütün katmanları arkadan öne, tek tonla çizer (hayvan: renk resimde,
## ton yalnızca durum/ışık çarpanı). Döner: karenin eklemleri, `xf` ile.
func draw_all(ci: CanvasItem, clip: String, frame: int, xf: Transform2D, tone: Color) -> Dictionary:
	ci.draw_set_transform_matrix(xf)
	for layer in LAYERS.size():
		var e := entry(clip, frame, layer, KIND_BODY)
		if e.is_empty():
			continue
		var region: Rect2 = e.region
		ci.draw_texture_rect_region(e.texture, Rect2(e.offset, e.size), region, tone)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	var out := {}
	var raw := frame_joints(clip, frame)
	for name in raw:
		out[name] = xf * Vector2(raw[name])
	return out

## Hayvanın savaş/yürüyüş klibi: kare kümesinin adları (walk, idle, attack,
## hit, dead, downed). Savunma hayvanda darbe klibiyle oynar.
static func beast_clip(state: String, fall: float, role: String, motion: float) -> String:
	if state == "dead" or state == "downed":
		return state if fall >= 1.0 else "hit"
	match role:
		"attack":
			return "attack"
		"hit", "defend":
			return "hit"
	return "walk" if motion >= 0.5 else "idle"

## Sayfalar mipmap'li yükleniyor: render ~5 kat küçültülerek çiziliyor ve
## mipmap'siz küçültme kenarları kumlu yapıyor. Mipmap içe aktarma ayarıyla
## açılamıyor (.import dosyaları depoda yok, CI varsayılanla üretiyor), o
## yüzden çalışma anında üretiliyor - sayfa başına bir kez, önbellekte.
func texture(page: int) -> Texture2D:
	if _textures.is_empty():
		for p in pages:
			_textures.append(_with_mipmaps(load(p) as Texture2D))
	return _textures[page]

static func _with_mipmaps(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var image := tex.get_image()
	if image == null or image.is_compressed():
		return tex
	if not image.has_mipmaps():
		image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

## {texture, region: Rect2, offset: Vector2, size: Vector2} ya da boş
## sözlük. `size` çizilecek boyut, render pikselinde (bkz. texel_scale).
func entry(clip: String, frame: int, layer: int, kind: int) -> Dictionary:
	_index_clips()
	if not _clip_base.has(clip):
		return {}
	var i := ((int(_clip_base[clip]) + frame) * LAYERS.size() + layer) * KINDS + kind
	var r := i * 5
	if r + 4 >= rects.size() or rects[r + 3] <= 0:
		return {}
	return {
		"texture": texture(rects[r]),
		"region": Rect2(rects[r + 1], rects[r + 2], rects[r + 3], rects[r + 4]),
		"offset": offsets[i],
		"size": Vector2(rects[r + 3], rects[r + 4]) * texel_scale,
	}

## Karenin eklemleri, çapaya göre render pikselinde.
func frame_joints(clip: String, frame: int) -> Dictionary:
	_index_clips()
	var out := {}
	if not _clip_base.has(clip):
		return out
	var base := (int(_clip_base[clip]) + frame) * joint_names.size()
	for k in joint_names.size():
		out[joint_names[k]] = joints[base + k]
	return out

## Karenin silah yönü ve kiriş çekilmişliği; eski paketlerde (alan yok)
## silah dik yukarı, kiriş gevşek.
func frame_weapon(clip: String, frame: int) -> Dictionary:
	_index_clips()
	var out := {"angle": -PI * 0.5, "draw": 0.0}
	if not _clip_base.has(clip):
		return out
	var i := int(_clip_base[clip]) + frame
	if i < weapon_angles.size():
		out.angle = weapon_angles[i]
	if i < draws.size():
		out.draw = draws[i]
	return out

## Normalize zamandan (0..1) aksiyon klibinin karesi.
func frame_for_time(clip: String, u: float) -> int:
	var n := frame_count(clip)
	return clampi(int(round(clampf(u, 0.0, 1.0) * float(n - 1))), 0, maxi(0, n - 1))

func _index_clips() -> void:
	if not _clip_base.is_empty():
		return
	var acc := 0
	for k in clip_names.size():
		_clip_base[clip_names[k]] = acc
		acc += int(clip_frames[k])
