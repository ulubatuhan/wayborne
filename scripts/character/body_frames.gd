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

@export var pages: PackedStringArray
@export var clip_names: PackedStringArray
@export var clip_frames: PackedInt32Array
## Duruş karesinde omzun çapadan yüksekliği (render pikseli).
@export var shoulder_px: float = 1.0
## Kayıt başına 5 tamsayı: sayfa, x, y, w, h (w = 0: o katmanda o tür yok).
@export var rects: PackedInt32Array
## Kayıt başına resmin sol üst köşesi, klip çapasına göre (render pikseli).
@export var offsets: PackedVector2Array
@export var joint_names: PackedStringArray
## Kare başına joint_names sırasıyla eklemler, çapaya göre.
@export var joints: PackedVector2Array

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
	return SHOULDER_SHARE * h / maxf(shoulder_px, 1.0)

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

## {texture, region: Rect2, offset: Vector2} ya da boş sözlük.
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

func _index_clips() -> void:
	if not _clip_base.is_empty():
		return
	var acc := 0
	for k in clip_names.size():
		_clip_base[clip_names[k]] = acc
		acc += int(clip_frames[k])
