class_name BeastRig
extends RefCounted

## Dört ayaklıların iskeleti: at, öküz, kurt, ayı, yaban domuzu. İnsan
## iskeleti (`FigureRig`) ne ise bu da hayvanlar için o - eklemler tek yerde
## çözülüyor, sprite parçaları kemiklere takılıyor.
##
## Beş tür aynı kemikleri paylaşıyor (gövde, boyun, baş, kuyruk, dört bacağın
## her biri üst/alt/ayak); farkı `SPECIES` tablosundaki oranlar yapıyor. Tek
## bir iskelet olması ressamın beş tür için aynı dokuz parçalık sayfayı
## boyaması demek.
##
## Resimler yolundan bulunuyor, liste yok:
##
##     data/assets/characters/beasts/<katman>/<parça>.png
##
## `<katman>` türün kendisi (`horse`) ya da onun üstüne binen bir takım
## (`horse_tack`: eyer, dizgin). Türün gövde resmi yoksa hayvan eskisi gibi
## prosedürel çiziliyor - resimler tür tür gelebilir.

## Sprite pikselinin figür yüksekliğine oranı. `h`, `WalkFigure`'ın dört
## ayaklı çiziminde kullandığı ölçünün aynısı (sırt yerden ~0.66h).
const REF_H: float = 256.0
const ROOT: String = "res://data/assets/characters/beasts/"

const HORSE: String = "horse"
const OX: String = "ox"
const WOLF: String = "wolf"
const BEAR: String = "bear"
const BOAR: String = "boar"

## Oranlar `h` cinsinden. `span` kalça tepesinden omuz tepesine, `back`
## sırtın yerden yüksekliği, `neck`/`head`/`tail` kemik vektörleri (sağa
## bakan hayvan için), `foot` ayak/toynak uzunluğu. `nod` başın adımda inişi
## (yük çeken öküz), `layers` türün üstüne binen takımlar.
const SPECIES: Dictionary = {
	HORSE: {
		"span": 0.83, "back": 0.66, "fore_drop": 0.08, "hind_drop": 0.10,
		"upper": 0.54, "lower": 0.54, "neck": Vector2(0.26, -0.22),
		"head": Vector2(0.14, 0.13), "tail": Vector2(-0.10, 0.22), "foot": 0.05,
		"nod": 0.0, "layers": ["horse_tack"],
	},
	OX: {
		"span": 0.78, "back": 0.62, "fore_drop": 0.08, "hind_drop": 0.10,
		"upper": 0.54, "lower": 0.54, "neck": Vector2(0.30, 0.12),
		"head": Vector2(0.14, 0.13), "tail": Vector2(-0.04, 0.30), "foot": 0.05,
		"nod": 0.018, "layers": ["ox_yoke"],
	},
	WOLF: {
		"span": 0.62, "back": 0.50, "fore_drop": 0.06, "hind_drop": 0.08,
		"upper": 0.52, "lower": 0.52, "neck": Vector2(0.14, -0.06),
		"head": Vector2(0.17, 0.03), "tail": Vector2(-0.22, 0.10), "foot": 0.07,
		"nod": 0.0, "layers": [],
	},
	BEAR: {
		"span": 0.62, "back": 0.58, "fore_drop": 0.08, "hind_drop": 0.10,
		"upper": 0.53, "lower": 0.52, "neck": Vector2(0.14, 0.0),
		"head": Vector2(0.16, 0.05), "tail": Vector2(-0.05, 0.03), "foot": 0.08,
		"nod": 0.0, "layers": [],
	},
	BOAR: {
		"span": 0.58, "back": 0.46, "fore_drop": 0.06, "hind_drop": 0.07,
		"upper": 0.55, "lower": 0.55, "neck": Vector2(0.10, 0.04),
		"head": Vector2(0.17, 0.08), "tail": Vector2(-0.06, 0.10), "foot": 0.05,
		"nod": 0.0, "layers": [],
	},
}
const SPECIES_ORDER: Array[String] = [HORSE, OX, WOLF, BEAR, BOAR]

## `WalkFigure`'ın eski dört ayaklı yürüyüşüyle aynı adım: dört vuruşlu
## yürüyüş, arka yakın - arka uzak - ön yakın - ön uzak.
const STRIDE_RATIO: float = 0.13
const LIFT_RATIO: float = 0.055
const BOB_RATIO: float = 0.012
const PHASES: Dictionary = {"hind_near": 0.0, "hind_far": PI, "fore_near": PI * 0.5, "fore_far": PI * 1.5}
## Kuyruğun yürürken salınımı, figür boyuna oranlı.
const TAIL_SWAY_RATIO: float = 0.02

const BODY: String = "body"
const NECK: String = "neck"
const HEAD: String = "head"
const TAIL: String = "tail"

## Uzak bacaklar gövdenin arkasında, yakın bacaklar önünde; boyun ve baş en
## üstte (otlayan bir başın ön bacağın önüne düşmesi gibi).
const DRAW_ORDER: Array[String] = [
	"hind_far_upper", "hind_far_lower", "hind_far_foot",
	"fore_far_upper", "fore_far_lower", "fore_far_foot",
	TAIL, BODY,
	"hind_near_upper", "hind_near_lower", "hind_near_foot",
	"fore_near_upper", "fore_near_lower", "fore_near_foot",
	NECK, HEAD,
]

## Kemik -> {a, b: eklem, part: parça, far: uzak uzuv mu}. Uzak ve yakın
## bacak aynı resmi paylaşıyor; uzak olan karartılıyor (`Wardrobe.BACK_SHADE`)
## ya da `<parça>_far.png` varsa onu kullanıyor.
const BONES: Dictionary = {
	BODY: {"a": "hip_top", "b": "shoulder_top", "part": "body", "far": false},
	NECK: {"a": "neck_base", "b": "poll", "part": "neck", "far": false},
	HEAD: {"a": "poll", "b": "muzzle", "part": "head", "far": false},
	TAIL: {"a": "tail_root", "b": "tail_tip", "part": "tail", "far": false},
	"hind_far_upper": {"a": "hind_far_root", "b": "hind_far_knee", "part": "hind_upper", "far": true},
	"hind_far_lower": {"a": "hind_far_knee", "b": "hind_far_foot", "part": "hind_lower", "far": true},
	"hind_far_foot": {"a": "hind_far_foot", "b": "hind_far_toe", "part": "foot", "far": true},
	"fore_far_upper": {"a": "fore_far_root", "b": "fore_far_knee", "part": "fore_upper", "far": true},
	"fore_far_lower": {"a": "fore_far_knee", "b": "fore_far_foot", "part": "fore_lower", "far": true},
	"fore_far_foot": {"a": "fore_far_foot", "b": "fore_far_toe", "part": "foot", "far": true},
	"hind_near_upper": {"a": "hind_near_root", "b": "hind_near_knee", "part": "hind_upper", "far": false},
	"hind_near_lower": {"a": "hind_near_knee", "b": "hind_near_foot", "part": "hind_lower", "far": false},
	"hind_near_foot": {"a": "hind_near_foot", "b": "hind_near_toe", "part": "foot", "far": false},
	"fore_near_upper": {"a": "fore_near_root", "b": "fore_near_knee", "part": "fore_upper", "far": false},
	"fore_near_lower": {"a": "fore_near_knee", "b": "fore_near_foot", "part": "fore_lower", "far": false},
	"fore_near_foot": {"a": "fore_near_foot", "b": "fore_near_toe", "part": "foot", "far": false},
}

## Dokuz parça, `REF_H` ölçeğinde tuval ve A ekleminin pikseli. Tuvaller beş
## türün hepsini alacak kadar geniş (`test_beast_rig` her türün dinlenme
## pozunu tuvalin içinde doğruluyor), yani tek bir sayfa düzeni var:
## 3×3 hücre, hücre 384×256.
const PARTS: Dictionary = {
	"body": {"canvas": Vector2i(384, 224), "pivot": Vector2(80, 72)},
	"neck": {"canvas": Vector2i(224, 224), "pivot": Vector2(56, 150)},
	"head": {"canvas": Vector2i(224, 192), "pivot": Vector2(56, 72)},
	"tail": {"canvas": Vector2i(192, 224), "pivot": Vector2(136, 40)},
	"fore_upper": {"canvas": Vector2i(128, 192), "pivot": Vector2(64, 32)},
	"fore_lower": {"canvas": Vector2i(128, 192), "pivot": Vector2(64, 24)},
	"hind_upper": {"canvas": Vector2i(160, 192), "pivot": Vector2(80, 40)},
	"hind_lower": {"canvas": Vector2i(128, 192), "pivot": Vector2(64, 24)},
	"foot": {"canvas": Vector2i(128, 96), "pivot": Vector2(40, 72)},
}
const PART_ORDER: Array[String] = [
	"body", "neck", "head", "tail", "fore_upper", "fore_lower", "hind_upper", "hind_lower", "foot",
]
const CELL: Vector2i = Vector2i(384, 256)

static var _cache: Dictionary = {}
static var root_path: String = ROOT

static func spec_of(species: String) -> Dictionary:
	return SPECIES.get(species, SPECIES[HORSE])

## Bir pozun eklemleri. `ground` gövde ortasının altındaki yer noktası, `h`
## figür ölçüsü, `phase`/`motion` yürüyüşün fazı ve genliği (0 duruyor),
## `facing` +1 sağa.
static func pose(
	species: String, ground: Vector2, h: float, phase: float, motion: float, facing: float
) -> Dictionary:
	var s := spec_of(species)
	var joints := {}
	var bob := sin(phase * 2.0) * h * BOB_RATIO * motion
	var back_y := ground.y - h * float(s.back) + bob
	var half := h * float(s.span) * 0.5
	joints["hip_top"] = Vector2(ground.x - half * facing, back_y)
	joints["shoulder_top"] = Vector2(ground.x + half * facing, back_y)
	joints["saddle"] = Vector2(ground.x, back_y)
	for side in ["near", "far"]:
		_leg(joints, s, "fore", side, ground.y, h, phase, motion, facing)
		_leg(joints, s, "hind", side, ground.y, h, phase, motion, facing)

	var neck_base: Vector2 = joints.shoulder_top + Vector2(h * 0.04 * facing, h * 0.02)
	var nod := float(s.nod) * h * motion * maxf(0.0, sin(phase * 2.0))
	var neck: Vector2 = s.neck
	var poll := neck_base + Vector2(neck.x * facing, neck.y) * h + Vector2(0.0, nod)
	var head: Vector2 = s.head
	joints["neck_base"] = neck_base
	joints["poll"] = poll
	joints["muzzle"] = poll + Vector2(head.x * facing, head.y) * h

	var tail_root: Vector2 = joints.hip_top + Vector2(-h * 0.09 * facing, h * 0.06)
	var tail: Vector2 = s.tail
	var sway := sin(phase) * h * TAIL_SWAY_RATIO * motion
	joints["tail_root"] = tail_root
	joints["tail_tip"] = tail_root + Vector2(tail.x * facing, tail.y) * h + Vector2(0.0, sway)
	return joints

## Omuz/kalça → diz → ayak. Ön bacağın dizi öne, arka bacağın dizi (topuk)
## geriye kırılıyor: arkayı da öne bükmek ilk sprite'ta hayvanı ters
## bacaklı gösterirdi - insandaki tavuk bacağı hatasının dört ayaklısı.
static func _leg(
	joints: Dictionary, s: Dictionary, end: String, side: String, ground_y: float,
	h: float, phase: float, motion: float, facing: float
) -> void:
	var fore := end == "fore"
	var top: Vector2 = joints.shoulder_top if fore else joints.hip_top
	var root := top + Vector2(0.0, h * float(s.fore_drop if fore else s.hind_drop))
	var leg_phase := phase + float(PHASES["%s_%s" % [end, side]])
	var foot := Vector2(
		root.x + cos(leg_phase) * h * STRIDE_RATIO * motion * facing,
		ground_y - maxf(0.0, sin(leg_phase)) * h * LIFT_RATIO * motion
	)
	var leg_len := ground_y - root.y
	var key := "%s_%s_" % [end, side]
	joints[key + "root"] = root
	joints[key + "knee"] = FigureRig.solve_joint(
		root, foot, leg_len * float(s.upper), leg_len * float(s.lower), -facing if fore else facing
	)
	joints[key + "foot"] = foot
	joints[key + "toe"] = foot + Vector2(h * float(s.foot) * facing, 0.0)

## Bütün bir hayvan resmi bu pozda boyanıyor (`tools/beast_cut.py` onu
## kemiklere kesiyor): yarım adımda, dört bacak birbirinden ayrı. Dinlenme
## pozunda uzak bacak yakın bacağın tam arkasında kalıyor - öyle boyanmış
## bir resimden uzak bacak çıkarılamaz.
const PAINT_PHASE: float = PI * 0.25

static func paint_pose(species: String) -> Dictionary:
	return pose(species, Vector2.ZERO, REF_H, PAINT_PHASE, 1.0, 1.0)

## Dinlenme pozu: `REF_H` ölçeğinde duran, sağa bakan hayvan.
static func rest_pose(species: String) -> Dictionary:
	return pose(species, Vector2.ZERO, REF_H, 0.0, 0.0, 1.0)

## Parçanın PNG'sinde A'dan B'ye vektör - türe göre (bir kurdun boynu atınkinden kısa).
static func part_rest_vector(species: String, part: String) -> Vector2:
	var rest := rest_pose(species)
	for bone in DRAW_ORDER:
		var spec: Dictionary = BONES[bone]
		if spec.part == part and not spec.far:
			return rest[spec.b] - rest[spec.a]
	return Vector2.RIGHT

static func part_transform(
	species: String, part: String, a_world: Vector2, b_world: Vector2, h: float, facing: float
) -> Transform2D:
	return FigureRig.part_transform(
		PARTS[part].pivot, part_rest_vector(species, part), a_world, b_world, h, facing, REF_H
	)

## Dinlenme pozunun kapladığı kutu, `h` = 1 için (sağa bakan, yer orijinde).
## Savaş kutusu hayvanı bu kutuya sığdırıyor.
static func extent(species: String) -> Rect2:
	var rest := pose(species, Vector2.ZERO, 1.0, 0.0, 0.0, 1.0)
	var box := Rect2(Vector2.ZERO, Vector2.ZERO)
	for point in rest.values():
		box = box.expand(point)
	# Kulak, boynuz ve gövde hacmi eklemlerin dışına taşıyor.
	return box.grow_individual(0.06, 0.14, 0.08, 0.0)

# --- Resimler ---

static func part_texture(layer: String, part: String) -> Texture2D:
	var key := "%s/%s" % [layer, part]
	if _cache.has(key):
		return _cache[key]
	var path := "%s%s.png" % [root_path, key]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path)
	elif FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture

## Tür sprite'la çizilir mi: gövdesinin resmi varsa. Yarım bir hayvanı
## (yalnızca baş) prosedürel gövdeye yapıştırmak iki çizim dilini karıştırırdı.
static func has_sprites(species: String) -> bool:
	return part_texture(species, "body") != null

## Türün ve resmi olan takımlarının katmanları, alttan üste.
static func layers_for(species: String) -> PackedStringArray:
	var result := PackedStringArray([species])
	for layer in spec_of(species).layers:
		for part in PART_ORDER:
			if part_texture(layer, part) != null:
				result.append(layer)
				break
	return result

static func bone_texture(layer: String, bone: String) -> Dictionary:
	var spec: Dictionary = BONES[bone]
	var part := String(spec.part)
	if bool(spec.far):
		var own := part_texture(layer, part + "_far")
		if own != null:
			return {"texture": own, "shade": false}
	return {"texture": part_texture(layer, part), "shade": bool(spec.far)}

## Bütün katmanları kemik kemik çiziyor. `tone` ışık ve durum rengi, çarpan.
## Her kemikte katmanlar alttan üste: eyer atın gövdesinin, boyunduruk
## öküzün boynunun üstünde. `base` çağıranın o anki çizim dönüşümü (savaş
## figürünün hamlesi/sarsıntısı) - sonunda ona dönülüyor, kimliğe değil.
static func draw_sprites(
	canvas: CanvasItem, species: String, joints: Dictionary, h: float, facing: float, tone: Color,
	base: Transform2D = Transform2D.IDENTITY
) -> void:
	var layers := layers_for(species)
	for bone in DRAW_ORDER:
		var spec: Dictionary = BONES[bone]
		var xf := part_transform(species, String(spec.part), joints[spec.a], joints[spec.b], h, facing)
		for layer in layers:
			var found := bone_texture(layer, bone)
			var texture: Texture2D = found.texture
			if texture == null:
				continue
			var shade := tone
			if found.shade:
				shade = Color(
					tone.r * Wardrobe.BACK_SHADE.r, tone.g * Wardrobe.BACK_SHADE.g,
					tone.b * Wardrobe.BACK_SHADE.b, tone.a
				)
			canvas.draw_set_transform_matrix(base * xf)
			canvas.draw_texture(texture, Vector2.ZERO, shade)
	canvas.draw_set_transform_matrix(base)

static func clear_cache() -> void:
	_cache.clear()
