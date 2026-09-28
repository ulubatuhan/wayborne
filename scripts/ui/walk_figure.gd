class_name WalkFigure
extends Control

## Yolda yürüyen bir insan, bir at ya da atlı bir binici. Varlık dosyası
## yok; `CombatFigure` gibi her şey `_draw()` ile çiziliyor.
##
## Var olma sebebi doğrudan bir şikâyet: yoldaki karakterler "yerde süzülen
## dikdörtgenler" gibiydi. Bir dikdörtgen *durursa* yer tutucu olabilir,
## ama yürürse yalanı hemen anlaşılıyor - hareket eden bir şeyin bacağı
## olmalı.
##
## İnsan figürünün iskeleti `FigureRig`'de (kalça → diz → ayak iki eklemli
## çözülüyor; ayak yere basarken geride *kalıyor*, figür yerde kaymıyor).
## Giysi, zırh ve silah sprite'ları (`Wardrobe`) o iskeletin kemiklerine
## takılıyor - `set_loadout`. Resmi olmayan kalem prosedürel çizimde kalır.
##
## Palet `CombatFigure.ARCHETYPES`'ten geliyor: savaşta gördüğün muhafız
## yolda da aynı renklerde yürüyor. İki tablo tutmak ikisinin ayrışması
## demekti.

## Ne çiziliyor.
const KIND_PERSON: String = "person"
const KIND_MOUNTED: String = "mounted"
const KIND_HORSE: String = "horse"
const KIND_OX: String = "ox"

const HORSE_PHASES: Array[float] = [0.0, PI, PI * 0.5, PI * 1.5]

## Duruşa ve yürüyüşe geçiş süreleri. Figür durunca faz sıfıra atlıyordu:
## yarım adımdaki bacak tek karede yan yana geliyordu - kırık bir kare.
## Artık adımın genliği (`_motion`) sönüyor, ayaklar kendiliğinden
## toplanıyor. Kalkış daha kısa: yürümeye başlamak bir karar, durmak bir
## yavaşlama.
const REST_EASE_SECONDS: float = 0.25
const START_EASE_SECONDS: float = 0.12

## Öküzün başı her adımda hafifçe iner - yük çeken hayvanı duran bir
## heykelden ayıran şey (ikincil hareket). Figür boyuna oranlı.
const OX_NOD_RATIO: float = 0.018

## Atlı figürün iki parçasının payı. At, figür kutusunun yarısından biraz
## fazlası; binici at sırtından yukarıya kalan pay. Toplamı 1'i geçiyor,
## çünkü binicinin bacakları atın gövdesiyle örtüşüyor - örtüşmeyince
## eyerde oturmuyor, atın üstüne konmuş gibi duruyor.
const MOUNT_HORSE_RATIO: float = 0.66
const MOUNT_RIDER_RATIO: float = 0.62

const HORSE_COAT: Color = Color(0.36, 0.26, 0.19)
const HORSE_COAT_DARK: Color = Color(0.24, 0.17, 0.13)
const HORSE_MANE: Color = Color(0.16, 0.12, 0.10)
const OX_COAT: Color = Color(0.42, 0.36, 0.30)
const OX_HORN: Color = Color(0.80, 0.76, 0.66)

## Ten rengi `CharacterData`'dan geliyor, burada ikinci bir tablo yok:
## karakter oluşturmada seçilen ten yolda da aynı ten olmalı, yoksa seçim
## ekranda bir yere varmıyor.
const FALLBACK_SKIN: Color = Color(0.72, 0.56, 0.42)

var _kind: String = KIND_PERSON
var _archetype: Dictionary = {}
var _skin: Color = FALLBACK_SKIN
## Boy figürü gerçekten uzatıyor/kısaltıyor - karakter oluşturmada seçilen
## boy yolda görünmezse seçim bir metinden ibaret kalıyor.
var _scale: float = 1.0
var _phase: float = 0.0
var _facing: float = 1.0
var _tint: Color = Color.WHITE
var _moving: bool = true
## Yürüyüşün genliği (0 duruyor, 1 tam adım). Bütün yürüyüş formülleri
## bununla çarpılıyor; `_moving` yalnızca hedefi söylüyor.
var _motion: float = 1.0
## Rüzgâra eğilme (radyan, yürüme yönüne doğru pozitif). Yalnızca insan
## gövdesi eğiliyor - bkz. RoadCaravan.set_weather.
var _lean: float = 0.0
var _carries_pack: bool = false
## `CharacterData.outfit` - boş sözlük (tayfa, düşman reskin'i, oxen) hiçbir
## şeyi değiştirmez, figür tamamen sınıf/arketip paletinde kalır. Yalnızca
## karakter oluşturmada seçilen bir parça varsa o slotun rengi/kafa şekli
## bunun yerine geçer - bkz. OutfitCatalog'un çözümleyicileri.
var _outfit: Dictionary = {}
## `CharacterData.get_body_variant_id()`'in sonucu ya da boş (tayfa, düşman
## reskin'i, oxen) - boşsa ya da o varyantın sanatı henüz yoksa düz
## `Wardrobe.BODY_ID`'ye düşülür (bkz. `_effective_body_id`).
var _body_variant: String = ""
## Üstündeki, resmi olan kalemler (`Wardrobe.loadout_for`), alttan üste.
var _loadout: PackedStringArray = PackedStringArray()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## `archetype_id` `CombatFigure.ARCHETYPES` anahtarı; bilinmeyen bir id
## haydut paletine düşer (aynı kural savaş figüründe de var).
func set_kind(
	kind: String, archetype_id: String, height_scale: float = 1.0,
	skin: Color = FALLBACK_SKIN, carries_pack: bool = false, outfit: Dictionary = {},
	body_variant: String = ""
) -> void:
	_kind = kind
	_archetype = CombatFigure.ARCHETYPES.get(
		archetype_id, CombatFigure.ARCHETYPES["bandit"]
	)
	_scale = clampf(height_scale, 0.82, 1.18)
	_skin = skin
	_carries_pack = carries_pack
	_outfit = outfit
	_body_variant = body_variant
	queue_redraw()

## Giyilen sprite'lı kalemler. Kıyafet/ekipman değişince çağıran yeniden
## veriyor - figür karakteri tutmuyor, yalnızca ne giydiğini.
func set_loadout(loadout: PackedStringArray) -> void:
	_loadout = loadout
	queue_redraw()

## Durup bekleyen figür (önizleme, portre): yürüyüşün genliği sıfır, ayaklar
## yan yana - bir kerelik kolaylık, `advance(…, 0)`'ı taklit etmeden.
func set_standing() -> void:
	_moving = false
	_motion = 0.0
	queue_redraw()

## Yürüyüş fazını ilerletir. `speed` 0 ise figür duruyor: ayakları yere
## basıyor, gövdesi nefes alıyor kadar oynuyor. Faz dışarıdan sürülüyor,
## çünkü bütün kervan aynı tempoyu paylaşmalı ama aynı *anda* aynı adımı
## atmamalı (bkz. RoadCaravan'ın faz kaydırması).
func advance(delta: float, speed: float) -> void:
	_moving = absf(speed) > 0.01
	if _moving:
		_phase = fmod(_phase + delta * speed * TAU, TAU)
		_facing = 1.0 if speed >= 0.0 else -1.0
	_motion = ease_motion(_motion, _moving, delta)
	queue_redraw()

## Genliğin bir karelik adımı. Saf fonksiyon - test sahnesiz okuyabilsin.
## Durunca faz donuyor ama adımın boyu sönüyor, yani ayak yarım adımda
## kalmıyor, yerine süzülüyor.
static func ease_motion(current: float, moving: bool, delta: float) -> float:
	if moving:
		return minf(1.0, current + delta / START_EASE_SECONDS)
	return maxf(0.0, current - delta / REST_EASE_SECONDS)

func get_motion() -> float:
	return _motion

func set_lean(radians: float) -> void:
	if is_equal_approx(_lean, radians):
		return
	_lean = radians
	queue_redraw()

func set_phase_offset(offset: float) -> void:
	_phase = fmod(offset, TAU)

func set_facing(facing: float) -> void:
	_facing = 1.0 if facing >= 0.0 else -1.0

## Günün ışığı. Bütün figürler aynı ışığı yiyor, yoksa gece yürüyen kervan
## gündüz aydınlatılmış gibi duruyor.
func set_tint(tint: Color) -> void:
	if _tint == tint:
		return
	_tint = tint
	queue_redraw()

func _draw() -> void:
	var height := size.y
	if height <= 1.0:
		return
	match _kind:
		KIND_HORSE:
			_draw_quadruped(height, HORSE_COAT, HORSE_COAT_DARK, true)
		KIND_OX:
			_draw_quadruped(height, OX_COAT, OX_COAT.darkened(0.28), false)
		KIND_MOUNTED:
			# Biniciyi atın *sırtına* oturtuyoruz. İlk hâlinde oturma
			# yüksekliği elle kestirilmişti (`height - horse_h * 0.86`) ve
			# ekran görüntüsünde sonuç açıkça görülüyordu: adam atın
			# yirmi piksel üstünde havada duruyordu. Sırtın y'si artık
			# atı çizen fonksiyondan geliyor, tahminden değil.
			var horse_h := height * MOUNT_HORSE_RATIO
			var back_y := _draw_quadruped(horse_h, HORSE_COAT, HORSE_COAT_DARK, true)
			_draw_person(height * MOUNT_RIDER_RATIO, back_y, true)
		_:
			_draw_person(height, height, false)

# --- İki ayaklı ---

## İnsan figürü iskeletten (`FigureRig`) çiziliyor: önce eklemler çözülüyor,
## sonra `FigureRig.DRAW_ORDER`'daki her kemik için sırayla prosedürel
## uzuv ve o kemiğe takılan giysi/zırh/silah sprite'ları (`Wardrobe`). Bir
## kemiğin katmanları o kemikte kalıyor - ön kolun kolluğu gövdenin
## üstünde, arka kolunki altında - yani sprite'lar derinliği iskeletten
## miras alıyor.
##
## `ground_y` figürün bastığı çizgi; binicide bu eyerin üstü oluyor, yani
## aynı gövde hem yürüyen hem atlı için kullanılıyor.
func _draw_person(figure_h: float, ground_y: float, seated: bool) -> void:
	var h := figure_h * _scale
	var cx := size.x * 0.5
	var bulk: float = float(_archetype.get("bulk", 1.0))
	var joints := FigureRig.pose(
		Vector2(cx, ground_y), h, _phase, _motion, _facing, _lean, seated, bulk
	)
	var look := _person_colors()

	if not seated:
		# Yere düşen gölge figürü zemine oturtuyor; olmayınca hakikaten
		# havada süzülüyor gibi duruyor.
		ArtDraw.ellipse(
			self, Vector2(cx, ground_y), Vector2(h * 0.16, h * 0.028),
			Color(0.0, 0.0, 0.0, 0.26)
		)
	var weapon_sprite := Wardrobe.has_part(_loadout, "weapon")
	for bone in FigureRig.bones_for(seated):
		_draw_bone(bone, joints, h, bulk, seated, look, weapon_sprite)
		_draw_wardrobe(bone, joints, h)

## Kıyafet seçimi (ceket/gömlek/pantolon/ayakkabı/eldiven) burada devreye
## giriyor - hiçbiri seçilmemişse (`_outfit` boş, tayfa/düşman gibi) her
## çözümleyici verdiği fallback'i olduğu gibi geri döner, yani sistem
## hiç var olmadan önceki görünüm birebir korunur.
func _person_colors() -> Dictionary:
	var base_cloth: Color = _archetype.get("cloth", Color(0.3, 0.25, 0.22))
	return {
		"cloth": _tinted(OutfitCatalog.resolve_torso_color(_outfit, base_cloth)),
		"trim": _tinted(_archetype.get("trim", Color(0.4, 0.3, 0.22))),
		"metal": _tinted(_archetype.get("metal", ArtPalette.STEEL)),
		"skin": _tinted(_skin),
		"pants": _tinted(OutfitCatalog.resolve_color(_outfit, OutfitCatalog.SLOT_PANTS, base_cloth)),
		"shoes": _tinted(
			OutfitCatalog.resolve_color(_outfit, OutfitCatalog.SLOT_SHOES, base_cloth.darkened(0.35))
		),
		"gloves": _tinted(OutfitCatalog.resolve_color(_outfit, OutfitCatalog.SLOT_GLOVES, _skin)),
	}

## Bir kemiğin prosedürel uzvu. Sprite'ı olan kalem bunun üstüne biniyor;
## altta kalan çizgi, sprite'ın kapatmadığı eklem aralığını dolduruyor.
func _draw_bone(
	bone: String, joints: Dictionary, h: float, bulk: float, seated: bool,
	look: Dictionary, weapon_sprite: bool
) -> void:
	var spec: Dictionary = FigureRig.BONES[bone]
	var a: Vector2 = joints[spec.a]
	var b: Vector2 = joints[spec.b]
	var back := bool(spec.back)
	var leg_width := maxf(2.0, h * 0.042)
	var arm_width := maxf(1.6, h * 0.032)
	var leg_color: Color = (look.pants as Color).darkened(0.20 if seated else (0.28 if back else 0.0))
	var foot_color: Color = (look.shoes as Color).darkened(0.15 if seated else (0.28 if back else 0.0))
	var sleeve: Color = (look.cloth as Color).darkened(0.18) if back else look.cloth
	match String(spec.part):
		"thigh":
			draw_line(a, b, leg_color, leg_width)
		"shin":
			draw_line(a, b, leg_color, leg_width * 0.88)
		"foot":
			draw_line(a, b, foot_color, maxf(1.5, h * 0.022))
		"upper_arm":
			draw_line(a, b, sleeve, arm_width)
		"forearm":
			draw_line(a, b, sleeve, arm_width * 0.85)
		"hand":
			draw_circle(a, maxf(1.2, h * 0.020), look.gloves)
		"torso":
			_draw_torso(a, b, h, bulk, look)
		"head":
			var headgear := OutfitCatalog.resolve_headgear(_outfit, String(_archetype.get("head", "bare")))
			_draw_head(a, h, bulk, look.skin, look.cloth, look.trim, look.metal, headgear)
		"weapon":
			# Resmi olan silah elde taşınıyor (sprite'ı `_draw_wardrobe`
			# çiziyor); yoksa arketipin sırttaki silüeti kalıyor.
			if not weapon_sprite:
				_draw_slung_weapon(joints.shoulder, h, look.metal, look.trim)

## Gövde: omuzdan kalçaya daralan bir çokgen - dikdörtgen yerine çokgen
## olması silüeti tanınır kılıyor. Pelerin/yük sırtta asimetrik bir hacim:
## kervanı "yüklü" gösteren şey.
func _draw_torso(shoulder: Vector2, hip: Vector2, h: float, bulk: float, look: Dictionary) -> void:
	var half_top := h * 0.098 * bulk
	var half_bottom := h * 0.076 * bulk
	ArtDraw.inked(self, PackedVector2Array([
		shoulder + Vector2(-half_top * _facing, 0.0),
		shoulder + Vector2(half_top * _facing, 0.0),
		hip + Vector2(half_bottom * _facing, h * 0.02),
		hip + Vector2(-half_bottom * _facing, h * 0.02),
	]), look.cloth, maxf(1.0, h * 0.012))
	if _carries_pack:
		var back := shoulder + Vector2(-half_top * 1.1 * _facing, h * 0.02)
		ArtDraw.inked(self, PackedVector2Array([
			back,
			back + Vector2(-h * 0.075 * _facing, h * 0.03),
			back + Vector2(-h * 0.065 * _facing, h * 0.17),
			back + Vector2(h * 0.01 * _facing, h * 0.15),
		]), (look.trim as Color).darkened(0.15), maxf(1.0, h * 0.010))

## Bir kemiğe takılan sprite katmanları, alttan üste: ten (`Wardrobe.BODY_ID`,
## karakterin ten rengiyle çarpılıyor), sonra üstündeki kalemler.
func _draw_wardrobe(bone: String, joints: Dictionary, h: float) -> void:
	var spec: Dictionary = FigureRig.BONES[bone]
	var a: Vector2 = joints[spec.a]
	var b: Vector2 = joints[spec.b]
	var part := String(spec.part)
	var part_spec: Dictionary = FigureRig.PARTS[part]
	var xf := FigureRig.part_transform(
		part_spec.pivot, FigureRig.part_rest_vector(part), a, b, h, _facing
	)
	var drew := false
	var body_id := _body_variant if not _body_variant.is_empty() else Wardrobe.BODY_ID
	var layers := PackedStringArray([body_id])
	layers.append_array(_loadout)
	for item_id in layers:
		var found := Wardrobe.bone_texture(item_id, bone)
		var texture: Texture2D = found.texture
		if texture == null:
			continue
		var tone := _tint
		if item_id == body_id:
			tone = Color(_skin.r * _tint.r, _skin.g * _tint.g, _skin.b * _tint.b, _tint.a)
		if found.shade:
			tone = Color(tone.r * Wardrobe.BACK_SHADE.r, tone.g * Wardrobe.BACK_SHADE.g, tone.b * Wardrobe.BACK_SHADE.b, tone.a)
		draw_set_transform_matrix(xf)
		draw_texture(texture, Vector2.ZERO, tone)
		drew = true
	if drew:
		draw_set_transform_matrix(Transform2D.IDENTITY)

## `headgear` `OutfitCatalog.resolve_headgear()`'ın döndürdüğü
## `{kind, color, override}` - `override` false'sa `color` hiç okunmaz,
## her dal kendi eski (sınıf/arketip kaynaklı) rengini kullanır, yani
## kıyafetsiz bir figür bu sistemden önceki hâliyle birebir aynı kalır.
func _draw_head(
	shoulder: Vector2, h: float, bulk: float, skin: Color,
	cloth: Color, trim: Color, metal: Color, headgear: Dictionary
) -> void:
	var radius := h * 0.058 * (0.92 + bulk * 0.08)
	var centre := shoulder + Vector2(h * 0.012 * _facing, -radius * 1.35)
	# Boyun: baş ile gövde arasındaki boşluk figürü kopuk gösteriyordu.
	draw_line(
		shoulder + Vector2(0.0, -h * 0.005), centre + Vector2(0.0, radius * 0.7),
		skin.darkened(0.22), maxf(1.8, h * 0.030)
	)
	ArtDraw.ellipse(self, centre, Vector2(radius * 0.92, radius), skin)
	draw_arc(centre, radius, 0.0, TAU, 18, ArtPalette.INK, maxf(1.0, h * 0.010))

	var override: bool = headgear.get("override", false)
	var head_color: Color = _tinted(headgear.get("color", Color.WHITE))
	match String(headgear.get("kind", "bare")):
		"helmet":
			ArtDraw.inked(self, PackedVector2Array([
				centre + Vector2(-radius, -radius * 0.15),
				centre + Vector2(-radius * 0.7, -radius * 1.15),
				centre + Vector2(radius * 0.7, -radius * 1.15),
				centre + Vector2(radius, -radius * 0.15),
			]), head_color if override else metal, maxf(1.0, h * 0.009))
		"hood":
			ArtDraw.inked(self, PackedVector2Array([
				centre + Vector2(-radius * 1.15, radius * 0.35),
				centre + Vector2(-radius * 0.85, -radius * 1.2),
				centre + Vector2(radius * 0.55, -radius * 1.1),
				centre + Vector2(radius * 0.9, radius * 0.2),
				centre + Vector2(-radius * 0.2, radius * 0.5),
			]), head_color if override else cloth.darkened(0.18), maxf(1.0, h * 0.009))
		"wrap":
			draw_line(
				centre + Vector2(-radius, -radius * 0.4),
				centre + Vector2(radius, -radius * 0.55),
				head_color if override else trim, maxf(1.6, radius * 0.55)
			)
		"cap":
			draw_line(
				centre + Vector2(-radius * 0.95, -radius * 0.65),
				centre + Vector2(radius * 0.95, -radius * 0.65),
				head_color if override else trim, maxf(1.6, radius * 0.5)
			)
		_:
			# Saç: tek yönden ışık aldığı için tepesi biraz açık.
			ArtDraw.ellipse(
				self, centre + Vector2(0.0, -radius * 0.45),
				Vector2(radius * 0.95, radius * 0.62), ArtPalette.INK_SOFT
			)

## Yolda silah kullanılmıyor ama taşınıyor: sırttaki mızrak/yay silüeti
## kervanın korumalı olduğunu tek bakışta söylüyor.
func _draw_slung_weapon(shoulder: Vector2, h: float, metal: Color, trim: Color) -> void:
	match String(_archetype.get("weapon", "none")):
		"spear_shield", "staff":
			var top := shoulder + Vector2(-h * 0.10 * _facing, -h * 0.16)
			var bottom := shoulder + Vector2(h * 0.06 * _facing, h * 0.40)
			draw_line(top, bottom, trim.darkened(0.25), maxf(1.6, h * 0.018))
			draw_line(
				top, top + Vector2(h * 0.015 * _facing, -h * 0.045),
				metal, maxf(1.4, h * 0.016)
			)
		"bow":
			var hip_y := shoulder.y + h * 0.10
			draw_arc(
				Vector2(shoulder.x - h * 0.09 * _facing, hip_y), h * 0.15,
				-PI * 0.45, PI * 0.45, 12, trim.darkened(0.2), maxf(1.4, h * 0.014)
			)
		"sword", "cleaver":
			var grip := shoulder + Vector2(-h * 0.085 * _facing, h * 0.14)
			draw_line(
				grip, grip + Vector2(-h * 0.03 * _facing, h * 0.16),
				metal.darkened(0.15), maxf(1.4, h * 0.016)
			)
		"maul":
			var shaft_top := shoulder + Vector2(-h * 0.11 * _facing, -h * 0.10)
			draw_line(
				shaft_top, shaft_top + Vector2(h * 0.05 * _facing, h * 0.34),
				trim.darkened(0.3), maxf(1.8, h * 0.020)
			)
			draw_rect(
				Rect2(shaft_top - Vector2(h * 0.035, h * 0.05), Vector2(h * 0.07, h * 0.06)),
				metal, true
			)

# --- Dört ayaklı ---

## At ve öküz aynı iskeleti paylaşıyor: dört bacak, gövde, boyun, baş.
## Fark hacim, renk ve boynuz/yal. Türün resmi geldiyse (`BeastRig`) hayvan
## iskeletten sprite'larla çiziliyor; aşağıdaki prosedürel çizim resmi henüz
## gelmemiş türün.
##
## Sırtın y'sini döndürüyor: atlı figür biniciyi oraya oturtuyor.
func _draw_quadruped(figure_h: float, coat: Color, shade: Color, is_horse: bool) -> float:
	var species := BeastRig.HORSE if is_horse else BeastRig.OX
	if BeastRig.has_sprites(species):
		return _draw_beast_sprites(species, figure_h)
	var h := figure_h
	var ground_y := size.y
	var cx := size.x * 0.5
	var body_len := h * (1.22 if is_horse else 1.14)
	var back_y := ground_y - h * 0.66
	var body := Color(coat)
	var dark := Color(shade)
	body = _tinted(body)
	dark = _tinted(dark)

	ArtDraw.ellipse(
		self, Vector2(cx, ground_y), Vector2(body_len * 0.52, h * 0.030),
		Color(0.0, 0.0, 0.0, 0.24)
	)

	var front_x := cx + body_len * 0.34 * _facing
	var rear_x := cx - body_len * 0.34 * _facing
	# Arka bacaklar önce: öndeki gövde onları kısmen kapatınca derinlik
	# oluşuyor.
	for index in 2:
		_draw_quad_leg(
			Vector2(rear_x, back_y + h * 0.10), ground_y, h,
			_phase + HORSE_PHASES[index], dark if index == 0 else dark.darkened(0.15)
		)
	for index in 2:
		_draw_quad_leg(
			Vector2(front_x, back_y + h * 0.08), ground_y, h,
			_phase + HORSE_PHASES[index + 2], dark if index == 0 else dark.darkened(0.15)
		)

	# Gövde derin: ilk ölçüde sırt ile karın arası boyun uzunluğundan
	# kısaydı ve hayvan deveye benziyordu. Bir at derin göğüslüdür.
	var bob := sin(_phase * 2.0) * h * 0.012 * _motion
	var outline := PackedVector2Array([
		Vector2(rear_x - h * 0.12 * _facing, back_y + h * 0.10 + bob),
		Vector2(rear_x - h * 0.02 * _facing, back_y - h * 0.02 + bob),
		Vector2(cx, back_y - h * 0.05 + bob),
	])
	if not is_horse:
		# Omuz hörgücü **sırt çizgisinin kendisi**, gövdenin üstüne konmuş
		# bir leke değil. Önce açık renkli, konturu olmayan bir elipsti -
		# hayvanın mürekkeple çizilmemiş tek parçası - ve ekranda hörgüç
		# değil, öküzün ensesine yapıştırılmış soluk bir disk gibi
		# duruyordu. Bir hörgücü hörgüç yapan şey siluetteki kambur.
		outline.append(Vector2(cx + body_len * 0.13 * _facing, back_y - h * 0.10 + bob))
		outline.append(Vector2(front_x - h * 0.06 * _facing, back_y - h * 0.17 + bob))
		# Hörgüçten boyna **yumuşak** iniş. Doğrudan atın omuz noktasına
		# düşmek 0.17h'lik bir uçurum bırakıyordu ve hörgücün önünde
		# çentik gibi duruyordu.
		outline.append(Vector2(front_x + h * 0.04 * _facing, back_y - h * 0.07 + bob))
	else:
		outline.append(Vector2(front_x, back_y - h * 0.01 + bob))
	outline.append(Vector2(front_x + h * 0.11 * _facing, back_y + h * 0.16 + bob))
	outline.append(Vector2(front_x * 0.6 + cx * 0.4, back_y + h * 0.34 + bob))
	outline.append(Vector2(cx, back_y + h * 0.36 + bob))
	outline.append(Vector2(rear_x - h * 0.04 * _facing, back_y + h * 0.30 + bob))
	ArtDraw.inked(self, outline, body, maxf(1.2, h * 0.012))

	# Boyun kısa ve kalın, baş büyük: ikisi de ilk denemede ince ve
	# küçüktü, o yüzden silüet at değil lama okuyordu.
	# Boyun ve baş. İki tur ölçüm gerekti ve ikisi de ekran görüntüsünden
	# çıktı: önce baş öne-aşağı uzuyordu (geyik), sonra boyun dikleşip
	# baş tepeye çıktı (lama). Bir atın boynu omuzdan ~40 derece
	# yükselir ve **baş boynun ucundan aşağı sarkar** - asıl at okuyan
	# şey o kırılma.
	# Atın başı omuz hizasının *üstünde*, öküzün *altında* - iki hayvanı
	# ayıran en güçlü ipucu bu. İlk ölçüde ikisi de yukarıdaydı ve öküz
	# başsız kahverengi bir levha gibi duruyordu: başı omuz hizasında
	# olduğu için gövdeye karışıyordu.
	var neck_base := Vector2(front_x + h * 0.04 * _facing, back_y + h * 0.02 + bob)
	var nod := 0.0 if is_horse else _motion * OX_NOD_RATIO * h * maxf(0.0, sin(_phase * 2.0))
	var poll := neck_base + Vector2(
		h * (0.26 if is_horse else 0.30) * _facing,
		h * (-0.22 if is_horse else 0.12) + nod
	)
	ArtDraw.inked(self, PackedVector2Array([
		neck_base + Vector2(-h * 0.10 * _facing, h * 0.02),
		neck_base + Vector2(h * 0.04 * _facing, -h * 0.08),
		poll + Vector2(-h * 0.03 * _facing, -h * 0.05),
		poll + Vector2(h * 0.05 * _facing, h * 0.06),
		neck_base + Vector2(h * 0.10 * _facing, h * 0.20),
	]), body, maxf(1.2, h * 0.011))

	# Baş: alından burna doğru aşağı eğik bir dörtgen.
	var muzzle := poll + Vector2(h * 0.14 * _facing, h * 0.13)
	ArtDraw.inked(self, PackedVector2Array([
		poll + Vector2(-h * 0.04 * _facing, -h * 0.06),
		poll + Vector2(h * 0.07 * _facing, -h * 0.03),
		muzzle + Vector2(h * 0.04 * _facing, 0.0),
		muzzle + Vector2(-h * 0.03 * _facing, h * 0.03),
	]), body, maxf(1.0, h * 0.010))
	# Kulak ve göz.
	draw_line(
		poll + Vector2(-h * 0.01 * _facing, -h * 0.05),
		poll + Vector2(-h * 0.03 * _facing, -h * 0.13),
		body.darkened(0.18), maxf(1.2, h * 0.018)
	)
	draw_circle(
		poll + Vector2(h * 0.035 * _facing, h * 0.005),
		maxf(1.2, h * 0.016), ArtPalette.INK
	)

	if not is_horse:
		# Hörgücün üstüne düşen ışık - yalnızca hacim ipucu, şeklin
		# kendisi yukarıda siluetten geliyor. Gövdenin *içinde* kalıyor,
		# o yüzden kontursuz olması burada doğru.
		ArtDraw.ellipse(
			self, Vector2(front_x - h * 0.04 * _facing, back_y - h * 0.11 + bob),
			Vector2(h * 0.10, h * 0.035), body.lightened(0.07)
		)

	if is_horse:
		# Yal: omuzdan ense üstüne. Atı öküzden ayıran ikinci ipucu.
		draw_line(
			neck_base + Vector2(h * 0.02 * _facing, -h * 0.06),
			poll + Vector2(-h * 0.02 * _facing, -h * 0.06),
			_tinted(HORSE_MANE), maxf(1.8, h * 0.045)
		)
		# Kuyruk: yürürken hafifçe sallanıyor, duran attan ayıran detay.
		var tail := Vector2(rear_x - h * 0.09 * _facing, back_y + h * 0.06 + bob)
		draw_line(
			tail, tail + Vector2(-h * 0.10 * _facing, h * 0.22 + sin(_phase) * h * 0.02),
			_tinted(HORSE_MANE), maxf(1.6, h * 0.030)
		)
	else:
		for side in [-1.0, 1.0]:
			draw_line(
				poll + Vector2(-h * 0.01 * _facing, -h * 0.05),
				poll + Vector2((-h * 0.01 + h * 0.10 * side) * _facing, -h * 0.15),
				_tinted(OX_HORN), maxf(1.4, h * 0.020)
			)

	return back_y + bob

## Resmi gelmiş tür iskeletten (`BeastRig`) çiziliyor; biniciyi eyere
## oturtan y yine iskeletten geliyor, tahminden değil.
func _draw_beast_sprites(species: String, h: float) -> float:
	var ground := Vector2(size.x * 0.5, size.y)
	var joints := BeastRig.draw_pose(species, ground, h, _phase, _motion, _facing)
	var span := h * BeastRig.body_span(species)
	ArtDraw.ellipse(self, ground, Vector2(span * 0.75, h * 0.030), Color(0.0, 0.0, 0.0, 0.24))
	BeastRig.draw_species(self, species, joints, h, _facing, _tint)
	return (joints.saddle as Vector2).y

func _draw_quad_leg(
	shoulder: Vector2, ground_y: float, h: float, phase: float, color: Color
) -> void:
	var stride := h * 0.13 * _motion
	var lift := h * 0.055 * _motion
	var hoof := Vector2(
		shoulder.x + cos(phase) * stride * _facing,
		ground_y - maxf(0.0, sin(phase)) * lift
	)
	var leg_len := ground_y - shoulder.y
	var knee := _solve_joint(shoulder, hoof, leg_len * 0.54, leg_len * 0.54, -_facing)
	# Bacaklar ilk hâlinde çöp kadar inceydi ve hayvan örümcek gibi
	# duruyordu: kalınlık gövdenin hacmine oranlı olmalı, sabit bir
	# piksele değil.
	var width := maxf(2.4, h * 0.075)
	draw_line(shoulder, knee, color, width)
	draw_line(knee, hoof, color.darkened(0.12), width * 0.66)

# --- Ortak ---

## İki kemikli eklem çözümü: `root` ile `tip` arasındaki mesafeye göre
## orta eklemin yerini bulur. Ulaşılamayan hedefte bacağı geriyoruz
## (kırılmış bir eklem çizmek yerine).
func _solve_joint(
	root: Vector2, tip: Vector2, bone_a: float, bone_b: float, bend: float
) -> Vector2:
	return FigureRig.solve_joint(root, tip, bone_a, bone_b, bend)

## Işık figürün bütün renklerini çarpıyor: gece kervanı da geceye ait
## görünüyor.
func _tinted(color: Color) -> Color:
	return Color(
		color.r * _tint.r, color.g * _tint.g, color.b * _tint.b, color.a
	)
