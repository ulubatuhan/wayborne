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
## Kervanın sahiplendiği husky (bkz. GameSession.owned_dogs) ve satın
## alınan/eskortlu tüccarların yük eşekleri (bkz. owned_donkeys,
## owned_half_wagons) - ikisi de prosedürel silüet taşımıyor, doğrudan
## `BeastRig`in kendi derisinden çiziliyor (`_draw_beast_sprites`), çünkü
## sanatları zaten var ve bir prosedürel yedek bu iki tür için hiç
## kullanılmayacak.
const KIND_DOG: String = "dog"
const KIND_DONKEY: String = "donkey"

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

## Yürüyüşün hız payları (çevrim/s; bir çevrim = iki adım). Kervan koşmaz:
## en hızlısı tempolu yürüyüş. İnsan için 0.70 sakin bir kervan yürüyüşü
## (dakikada 84 adım), 0.95 tempolu yürüyüş (114) - bunun üstü koşudur ve
## yürüyüş kareleriyle oynatılınca bacaklar fırıl fırıl döner. Altı ağır
## aksak bir yürüyüş. Ekran bu bantta kalsın diye kervanın zemin hızı
## (yani manzara) kısılıyor, bacaklar hızlandırılmıyor - bkz. road_journey.
const WALK_CADENCE: float = 0.70
const BRISK_CADENCE: float = 0.95
const AMBLE_CADENCE: float = 0.40
## Hayvanların tempolu yürüyüş tavanı. Küçük hayvan sık adımlar; öküz ağır
## yürür. Kervanın zemin hızı içindeki en yavaş hayvanın tavanına da
## takılıyor: öküz vagonu koşturamaz.
const BEAST_BRISK_CADENCE: Dictionary = {
	"ox": 1.15, "horse": 1.25, "horse_white": 1.25, "donkey": 1.35,
	"husky": 2.00, "wolf": 1.60, "bear": 1.10, "boar": 1.50,
	"stag": 1.30, "deer": 1.45,
}
## Prosedürel dörtayaklının (`_draw_quad_leg`, `BeastRig.pose`) bir
## çevrimde katettiği yol: toynak yarım çevrimde `2 * stride` geri gidiyor,
## yani gövde çevrim başına `4 * stride` ilerliyor.
const QUAD_CYCLE_RATIO: float = 4.0 * 0.13

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

## Beyaz at, varsayılan kahve atın bir varyantı - aynı iskelet, aynı poz,
## `BeastRig.HORSE_WHITE`'ın kendi deri katmanları. "Bazen beyaz bazen
## kahve" tam bir yazı-tura değil, azınlıkta kalan bir varyant olsun diye
## %30. Zar `set_kind()`'ta bir kez atılıyor ve `_horse_species`'te
## saklanıyor - `_draw()` her karede çağrıldığı için zarı orada atmak her
## kareyi farklı bir ata çevirirdi (titreme). `set_kind()` bir figürün
## ömründe bir kez çağrılır (bkz. road_caravan.gd/world_hub.gd'nin
## `configure()`/`_build_*` desenleri), o yüzden seçim kalıcı.
const WHITE_HORSE_CHANCE: float = 0.3

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
## Bu figür bir at ise (KIND_HORSE/KIND_MOUNTED) hangi tür çizileceği -
## `set_kind()`'ta bir kez zarla belirlenir (bkz. WHITE_HORSE_CHANCE).
var _horse_species: String = ""
## Üstündeki, resmi olan kalemler (`Wardrobe.loadout_for`), alttan üste.
var _loadout: PackedStringArray = PackedStringArray()
## Savaşta silah sırtta değil elde (bkz. `_draw_held_weapon`): savaş
## figürü iskelete geçtiğinde arketipin silahı - kılıç, mızrak ve kalkan,
## yay - okunmaya devam etmeli, yoksa sınıflar silüetten ayırt edilemez.
var _combat_stance: bool = false
## Oynatılan aksiyon klibi (`FigureActions` adları: attack_swing, hit, dead…)
## ve klibin içindeki normalize zaman. Boşsa yürüyüş/duruş/savaş duruşu.
## Savaş paneli her karede damgalıyor (`CombatFigure.set_action`).
var _action_clip: String = ""
## Hayvan figürünün türü, verilmişse türün kendi tanımını ezer (yol
## karşılaşmasındaki kurt, ekran görüntüsü araçları).
var _beast_species: String = ""
var _action_u: float = 0.0

## Botun bileği tuttuğu kalem: yalnız çizme. Sandalet yalın ayak gibi yürür.
const ANKLE_LIMITING_SHOES: Array[String] = ["shoes_boots"]

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
	_scale = clampf(
		height_scale,
		CharacterData.height_scale_for(CharacterData.MIN_HEIGHT_CM) * 0.95,
		CharacterData.height_scale_for(CharacterData.MAX_HEIGHT_CM)
	)
	_skin = skin
	_carries_pack = carries_pack
	_outfit = outfit
	_body_variant = body_variant
	# Kare kümesi ~5 kat küçültülerek çiziliyor; mipmap'siz kenarlar kumlu.
	texture_filter = (
		CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if not body_variant.is_empty() and BodyFrames.for_body(body_variant) != null
		else CanvasItem.TEXTURE_FILTER_PARENT_NODE
	)
	if (kind == KIND_HORSE or kind == KIND_MOUNTED) and _horse_species.is_empty():
		_horse_species = BeastRig.HORSE_WHITE if randf() < WHITE_HORSE_CHANCE else BeastRig.HORSE
	queue_redraw()

func set_combat_stance(on: bool) -> void:
	_combat_stance = on
	queue_redraw()

func set_action(clip: String, u: float = 0.0) -> void:
	if _action_clip == clip and is_equal_approx(_action_u, u):
		return
	_action_clip = clip
	_action_u = u
	queue_redraw()

func set_beast_species(species: String) -> void:
	_beast_species = species
	queue_redraw()

func get_action() -> String:
	return _action_clip

## Arketipin silah ailesi (`CombatFigure.ARCHETYPES[...].weapon`).
func weapon_kind() -> String:
	return String(_archetype.get("weapon", "none"))

## Hangi kare klibi çizilecek. Saf fonksiyon: test sahnesiz okuyabilsin.
## Sıra: binici > aksiyon > savaş duruşu (silah ailesine göre) > yürüyüş
## (heybeli, botlu, yalın) > duruş. Elde olmayan klip bir alttakine düşer.
static func pick_clip(
	available: PackedStringArray, seated: bool, motion: float, action: String,
	combat_stance: bool, weapon: String, carries_pack: bool, boots: bool
) -> String:
	if seated and available.has("ride"):
		return "ride"
	if not action.is_empty() and available.has(action):
		return action
	if combat_stance:
		var stance := String(FigureActions.clips_for_weapon(weapon).stance)
		return stance if available.has(stance) else "idle"
	if motion >= 0.5:
		if carries_pack and available.has("walk_laden"):
			return "walk_laden"
		if boots and available.has("walk_boots"):
			return "walk_boots"
		return "walk"
	return "idle"

func _wears_boots() -> bool:
	return str(_outfit.get(OutfitCatalog.SLOT_SHOES, "")) in ANKLE_LIMITING_SHOES

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
		# Yön işaretten, faz her zaman ileri: iskelet `facing`'e göre
		# aynalanıyor, yani sola yürüyen figür de fazını ileri sarmalı.
		# Fazı geri sarmak sola bakıp *geri geri* yürümekti (moonwalk) -
		# lider kolonda geriye giderken tam olarak bu görünüyordu.
		_phase = fmod(_phase + delta * absf(speed) * TAU, TAU)
		_facing = 1.0 if speed >= 0.0 else -1.0
	_motion = ease_motion(_motion, _moving, delta)
	queue_redraw()

## Zemine göre hızdan yürüyüş: kadans = zemin hızı / çevrim başına yol.
## Ayak böylece hiçbir hızda zeminde kaymıyor - ne öne (koşu bandı) ne
## geriye (moonwalk). `ground_px_s` figürün kendi pikselinde, işaret yön.
func advance_ground(delta: float, ground_px_s: float) -> void:
	advance(delta, cadence_for_ground(ground_px_s))

func cadence_for_ground(ground_px_s: float) -> float:
	var cycle := cycle_distance()
	if cycle <= 0.0 or absf(ground_px_s) < 0.5:
		return 0.0
	return ground_px_s / cycle

## Bir yürüyüş çevriminde gövdenin zemine göre katettiği yol (piksel).
## İnsan `FigureRig`in kendi adımından; hayvan, kareleri varsa karelerden
## ölçülen adımından (`BodyFrames.BEAST_WALK_CYCLE`).
func cycle_distance() -> float:
	var h := size.y
	if not _beast_species.is_empty() and _kind != KIND_PERSON and _kind != KIND_MOUNTED:
		return beast_cycle_distance(_beast_species, h)
	match _kind:
		KIND_MOUNTED:
			return beast_cycle_distance(_horse_species_or_default(), h * MOUNT_HORSE_RATIO)
		KIND_HORSE:
			return beast_cycle_distance(_horse_species_or_default(), h)
		KIND_OX:
			return beast_cycle_distance(BeastRig.OX, h)
		KIND_DOG:
			return beast_cycle_distance(BeastRig.HUSKY, h)
		KIND_DONKEY:
			return beast_cycle_distance(BeastRig.DONKEY, h)
	return FigureRig.CYCLE_DISTANCE_RATIO * h * _scale

## Bu figürün tempolu yürüyüşte zemine göre hızı (piksel/s): kervanın
## zemin hızının tavanı bunların en küçüğü.
func brisk_ground_speed() -> float:
	return brisk_cadence() * cycle_distance()

func brisk_cadence() -> float:
	var species := _walking_species()
	if species.is_empty():
		return BRISK_CADENCE
	return float(BEAST_BRISK_CADENCE.get(species, BRISK_CADENCE))

## Yürüyen bacakların türü; insan (yaya) için boş.
func _walking_species() -> String:
	if not _beast_species.is_empty() and _kind != KIND_PERSON and _kind != KIND_MOUNTED:
		return _beast_species
	match _kind:
		KIND_MOUNTED, KIND_HORSE:
			return _horse_species_or_default()
		KIND_OX:
			return BeastRig.OX
		KIND_DOG:
			return BeastRig.HUSKY
		KIND_DONKEY:
			return BeastRig.DONKEY
	return ""

func _horse_species_or_default() -> String:
	return _horse_species if not _horse_species.is_empty() else BeastRig.HORSE

## Türün çizildiği yola göre çevrim başına yolu. Kareler varsa onların
## ölçülmüş adımı, yoksa iskeletin (`BeastRig`) ya da prosedürel bacağın.
static func beast_cycle_distance(species: String, h: float) -> float:
	if BodyFrames.for_beast(species) != null:
		return BodyFrames.beast_walk_cycle(species) * h
	return QUAD_CYCLE_RATIO * h

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
	if not _beast_species.is_empty() and _kind != KIND_PERSON and _kind != KIND_MOUNTED:
		_draw_beast_sprites(_beast_species, height)
		return
	match _kind:
		KIND_HORSE:
			_draw_quadruped(height, HORSE_COAT, HORSE_COAT_DARK, true)
		KIND_OX:
			_draw_quadruped(height, OX_COAT, OX_COAT.darkened(0.28), false)
		KIND_DOG:
			_draw_beast_sprites(BeastRig.HUSKY, height)
		KIND_DONKEY:
			_draw_beast_sprites(BeastRig.DONKEY, height)
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
	var frames := BodyFrames.for_body(_body_variant) if not _body_variant.is_empty() else null
	if frames != null:
		_draw_person_frames(frames, figure_h * _scale, ground_y, seated)
		return
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
	var body_id := _body_id()
	for bone in FigureRig.bones_for(seated):
		# Manken bu kemiği kaplıyorsa prosedürel uzuv çizilmiyor - altında
		# kalıp kenarından taşan ikinci bir çizgi olurdu. Saç/şapka ve sırt
		# yükü ise gövdenin *üstünde* kalmalı, o yüzden mankenden sonra.
		if _draw_body_layer(bone, joints, h, look, body_id):
			_draw_bone_overlay(bone, joints, h, bulk, look)
		else:
			_draw_bone(bone, joints, h, bulk, seated, look, weapon_sprite)
		_draw_wardrobe(bone, joints, h)

## Önceden render edilmiş beden (`BodyFrames`, 3B'den): beş derinlik katmanı
## arkadan öne, her katmanda beden tenle, üstüne şort ve atlet/bra kendi
## renkleriyle. Eski parça mankeni her kemiği ayrı resim olarak döndürüyordu;
## dizde kırık, el pençe, ayak kama gibi duruyordu. Burada her kare tek bir
## 3B pozun render'ı, eklem kendiliğinden bütün.
##
## Saf manken: kask, arketip giysisi, saç yok (kullanıcı kararı - bunlar
## karakter yaratımında modül olarak eklenecek). Oyuncunun seçtiği kıyafetin
## rengi temel kuşamı boyar; seçilmiş bir başlık ve silah/sırt yükü
## render'ın kendi eklemlerine bağlanır.
const UNDERSHIRT_COLOR: Color = Color(0.78, 0.74, 0.64)
const SHORTS_COLOR: Color = Color(0.42, 0.34, 0.26)
const FRAME_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.26)

func _draw_person_frames(frames: BodyFrames, h: float, ground_y: float, seated: bool) -> void:
	var clip := pick_clip(frames.clip_names, seated, _motion, _action_clip, _combat_stance,
		weapon_kind(), _carries_pack, _wears_boots())
	if not frames.has_clip(clip):
		clip = "idle"
	var cycles := clip in ["walk", "walk_boots", "walk_laden", "ride"]
	var frame := frames.frame_for_phase(clip, _phase) if cycles else frames.frame_for_time(clip, _action_u)
	var k := frames.scale_for(h)
	var origin := Vector2(size.x * 0.5, ground_y)
	var xf := Transform2D(_lean * _facing, Vector2(k * _facing, k), 0.0, origin)
	if not seated:
		ArtDraw.ellipse(self, origin, Vector2(h * 0.16, h * 0.028), FRAME_SHADOW)
	var tones := frame_tones(_tinted(_skin), _outfit, _tint)
	var joints := {}
	var raw := frames.frame_joints(clip, frame)
	for name in raw:
		joints[name] = xf * Vector2(raw[name])
	var look := _person_colors()
	var wdata := frames.frame_weapon(clip, frame)
	# Silah yönü render uzayında (figür sağa bakıyor); ayna ve eğim xf'te.
	var wdir := xf.basis_xform(Vector2.from_angle(float(wdata.angle))).normalized()
	# Ölü ve yerdeki el silahı bırakmış: kalkan ve mızrak havada kalıyordu.
	var fallen := _action_clip in ["dead", "downed"]
	var held := (_combat_stance or not _action_clip.is_empty()) and not fallen
	for layer in BodyFrames.LAYERS.size():
		if seated and BodyFrames.LAYERS[layer] == "back_leg":
			continue  # atın arkasında kalıyor (FigureRig.bones_for(true) ile aynı kural)
		if BodyFrames.LAYERS[layer] == "front_arm" and held:
			_draw_frame_weapon(joints, h, look, wdir, float(wdata.draw))
		if BodyFrames.LAYERS[layer] == "torso_head" and not fallen:
			_draw_frame_back_items(joints, h, look, held)
		draw_set_transform_matrix(xf)
		for kind in [BodyFrames.KIND_BODY, BodyFrames.KIND_BOTTOM, BodyFrames.KIND_TOP]:
			var e := frames.entry(clip, frame, layer, kind)
			if e.is_empty():
				continue
			var region: Rect2 = e.region
			draw_texture_rect_region(e.texture, Rect2(e.offset, region.size), region, tones[kind])
		draw_set_transform_matrix(Transform2D.IDENTITY)
		if BodyFrames.LAYERS[layer] == "torso_head":
			_draw_frame_extras(joints, h, look)

## Katman türü başına renk: beden ten, alt şort, üst atlet/bra. Seçilmiş
## pantolon/gömlek-ceket rengi temel kuşamın yerine geçer (OutfitCatalog'un
## aynı çözümleyicileri). Saf fonksiyon - test sahnesiz okuyabilsin.
static func frame_tones(skin: Color, outfit: Dictionary, light: Color) -> Dictionary:
	var top := OutfitCatalog.resolve_torso_color(outfit, UNDERSHIRT_COLOR)
	var bottom := OutfitCatalog.resolve_color(outfit, OutfitCatalog.SLOT_PANTS, SHORTS_COLOR)
	return {
		BodyFrames.KIND_BODY: skin,
		BodyFrames.KIND_TOP: top * light,
		BodyFrames.KIND_BOTTOM: bottom * light,
	}

## Sırtta taşınanlar gövde katmanından ÖNCE: gövdenin arkasında kalırlar.
## Önce sonra çiziliyordu ve sırttaki mızrak göğsün önünden geçiyordu.
func _draw_frame_back_items(joints: Dictionary, h: float, look: Dictionary, held: bool) -> void:
	if not joints.has("shoulder"):
		return
	if not joints.has("back_upper"):
		# Sırt işareti olmayan eski paket: omuzdan tahmin.
		_draw_pack(joints.shoulder, h, 1.0, look)
		if not held and not Wardrobe.has_part(_loadout, "weapon"):
			_draw_slung_weapon(joints.shoulder, h, look.metal, look.trim)
		return
	var spine := back_frame(joints.back_upper, joints.back_lower, _facing)
	if _carries_pack:
		ArtDraw.inked(self, pack_outline(spine, h), (look.trim as Color).darkened(0.15), maxf(1.0, h * 0.010))
	if not held and not Wardrobe.has_part(_loadout, "weapon"):
		_draw_slung_on_back(spine, h, look)

## Sırt çizgisi: 3B render'ın sırt yüzeyinden iki nokta (kürek ve bel
## hizası). Döner: üst, alt, yukarı (bele -> küreğe) ve dışa (sırttan
## arkaya) birim vektörler. Sırtta taşınan her şey bu çerçeveye oturur -
## eskiden omuzdan sabit ofsetle çiziliyordu ve yay sırtın arkasında havada
## asılı duruyordu.
static func back_frame(upper: Vector2, lower: Vector2, facing: float) -> Dictionary:
	var up := (upper - lower).normalized()
	if up == Vector2.ZERO:
		up = Vector2.UP
	var out := Vector2(-up.y, up.x)
	if out.x * facing > 0.0:
		out = -out
	return {"upper": upper, "lower": lower, "up": up, "out": out}

## Heybe: sırta yaslanan, küreğin biraz üstünden belin altına inen torba.
static func pack_outline(spine: Dictionary, h: float) -> PackedVector2Array:
	var up: Vector2 = spine.up
	var out: Vector2 = spine.out
	var top: Vector2 = spine.upper + up * h * 0.06
	var bottom: Vector2 = spine.lower - up * h * 0.03
	return PackedVector2Array([
		top + out * h * 0.004,
		top + out * h * 0.085,
		bottom + out * h * 0.095,
		bottom + out * h * 0.004,
	])

## Yolda taşınan silah sırtın kendisine oturur: yay sırt boyunca (gövdeye
## değerek, kirişi dışta), mızrak/asa/gürz sırta çapraz, kılıç belde.
## Uçlar `slung_points()`'ten - test aynı sayıları okuyor.
func _draw_slung_on_back(spine: Dictionary, h: float, look: Dictionary) -> void:
	var metal: Color = look.metal
	var trim: Color = look.trim
	var pts := slung_points(weapon_kind(), spine, h)
	if pts.is_empty():
		return
	match weapon_kind():
		"bow":
			var stave := _bezier(pts.top, pts.bulge, pts.bottom, 12)
			draw_polyline(stave, ArtPalette.INK, maxf(2.2, h * 0.020))
			draw_polyline(stave, trim.darkened(0.2), maxf(1.4, h * 0.013))
			draw_line(pts.top, pts.bottom, Color(0.85, 0.82, 0.74, 0.8), maxf(1.0, h * 0.004))
		"spear_shield", "staff":
			draw_line(pts.top, pts.bottom, trim.darkened(0.25), maxf(1.6, h * 0.018))
			if weapon_kind() == "spear_shield":
				draw_line(pts.top, pts.top + (pts.top - pts.bottom).normalized() * h * 0.045, metal, maxf(1.4, h * 0.016))
		"maul":
			draw_line(pts.top, pts.bottom, trim.darkened(0.3), maxf(1.8, h * 0.020))
			var head_dir: Vector2 = (pts.top - pts.bottom).normalized()
			var side := Vector2(-head_dir.y, head_dir.x) * h * 0.035
			draw_colored_polygon(PackedVector2Array([
				pts.top - side, pts.top + side, pts.top + side + head_dir * h * 0.06, pts.top - side + head_dir * h * 0.06,
			]), metal)
		"sword", "cleaver":
			draw_line(pts.top, pts.bottom, ArtPalette.INK, maxf(2.4, h * 0.022))
			draw_line(pts.top, pts.bottom, metal.darkened(0.15), maxf(1.4, h * 0.016))

## Sırttaki silahın uç noktaları, sırt çerçevesinde. Boş: taşınan silah yok.
static func slung_points(weapon: String, spine: Dictionary, h: float) -> Dictionary:
	var up: Vector2 = spine.up
	var out: Vector2 = spine.out
	var mid: Vector2 = (Vector2(spine.upper) + Vector2(spine.lower)) * 0.5
	match weapon:
		"bow":
			# Yay sırta değiyor: orta noktası sırt yüzeyinde, kollar sırt boyunca.
			var c := mid + out * h * 0.012
			return {"top": c + up * h * 0.20 + out * h * 0.012, "bottom": c - up * h * 0.20 + out * h * 0.012,
				"bulge": c - out * h * 0.004 + out * h * 0.05}
		"spear_shield", "staff", "maul":
			var tilt := up.rotated(0.35 * signf(out.x))
			var c2 := mid + out * h * 0.02
			return {"top": c2 + tilt * h * 0.32, "bottom": c2 - tilt * h * 0.26}
		"sword", "cleaver":
			var hilt: Vector2 = Vector2(spine.lower) + out * h * 0.015
			return {"top": hilt, "bottom": hilt + (-up + out * 0.55).normalized() * h * 0.18}
	return {}

static func _bezier(a: Vector2, c: Vector2, b: Vector2, steps: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / float(steps)
		pts.append(a.lerp(c, t).lerp(c.lerp(b, t), t))
	return pts

## Kare kümesinin elindeki silah: yönü karenin kendi verisinden (`wdir`,
## FigureActions'ın `weapon` açısı), kiriş çekilmişliği `draw`. Kılıç
## savuruşta döner, yay nişanda dik durup kirişi arka ele gelir.
func _draw_frame_weapon(joints: Dictionary, h: float, look: Dictionary, wdir: Vector2, draw_amount: float) -> void:
	if not joints.has("hand_front"):
		return
	var hand: Vector2 = joints.hand_front
	var metal: Color = look.metal
	var trim: Color = look.trim
	var ink_w := maxf(1.0, h * 0.008)
	var side := Vector2(-wdir.y, wdir.x)
	match weapon_kind():
		"sword":
			var tip := hand + wdir * h * FigureRig.WEAPON_RATIO
			draw_line(hand, tip, ArtPalette.INK, maxf(2.6, h * 0.022))
			draw_line(hand, tip, metal, maxf(1.6, h * 0.014))
			draw_line(hand + wdir * h * 0.02 - side * h * 0.035, hand + wdir * h * 0.02 + side * h * 0.035, trim, maxf(2.0, h * 0.016))
		"cleaver":
			var front := side if side.x * _facing > 0.0 else -side
			ArtDraw.inked(self, PackedVector2Array([
				hand + wdir * h * 0.05, hand + wdir * h * 0.21 + front * h * 0.03,
				hand + wdir * h * 0.17 + front * h * 0.10, hand + wdir * h * 0.04 + front * h * 0.05,
			]), metal, ink_w)
		"maul":
			var head := hand + wdir * h * FigureRig.WEAPON_RATIO
			draw_line(hand - wdir * h * 0.05, head, trim.darkened(0.25), maxf(2.4, h * 0.020))
			ArtDraw.inked(self, PackedVector2Array([
				head - side * h * 0.06 - wdir * h * 0.02, head + side * h * 0.06 - wdir * h * 0.02,
				head + side * h * 0.06 + wdir * h * 0.05, head - side * h * 0.06 + wdir * h * 0.05,
			]), metal, ink_w)
		"spear_shield":
			var top := hand + wdir * h * 0.52
			draw_line(hand - wdir * h * 0.16, top, trim.darkened(0.2), maxf(2.0, h * 0.016))
			ArtDraw.inked(self, PackedVector2Array([
				top, top + wdir * h * 0.06 + side * h * 0.025, top + wdir * h * 0.10,
				top + wdir * h * 0.06 - side * h * 0.025,
			]), metal, ink_w)
			if joints.has("hip"):
				var shield: Vector2 = Vector2(joints.shoulder).lerp(joints.hip, 0.55) + Vector2(0.075 * _facing, 0.0) * h
				ArtDraw.ellipse(self, shield, Vector2(0.055, 0.105) * h, metal.darkened(0.30))
				draw_arc(shield, 0.105 * h, 0.0, TAU, 20, ArtPalette.INK, ink_w)
		"bow":
			var pts := bow_points(hand, wdir, h, _facing, joints.get("hand_back", hand), draw_amount)
			var stave := _bezier(pts.top, pts.bulge, pts.bottom, 14)
			draw_polyline(stave, ArtPalette.INK, maxf(2.6, h * 0.022))
			draw_polyline(stave, trim.darkened(0.15), maxf(1.6, h * 0.015))
			var string_col := Color(0.85, 0.82, 0.74, 0.85)
			draw_line(pts.top, pts.nock, string_col, maxf(1.0, h * 0.004))
			draw_line(pts.nock, pts.bottom, string_col, maxf(1.0, h * 0.004))
			if draw_amount > 0.3:
				var shaft_end: Vector2 = pts.nock + (hand - pts.nock).normalized() * ((hand - pts.nock).length() + h * 0.05)
				draw_line(pts.nock, shaft_end, trim.lightened(0.2), maxf(1.0, h * 0.006))
				draw_line(shaft_end, shaft_end + (shaft_end - pts.nock).normalized() * h * 0.025, metal, maxf(1.4, h * 0.010))
		"staff":
			var staff_top := hand + wdir * h * 0.46
			draw_line(hand - wdir * h * 0.20, staff_top, trim.darkened(0.2), maxf(2.2, h * 0.018))
			draw_circle(staff_top, 0.03 * h, metal)
			draw_arc(staff_top, 0.03 * h, 0.0, TAU, 12, ArtPalette.INK, ink_w)

## Yay: gövde `wdir` boyunca elin iki yanında, hedefe doğru kavisli; kiriş
## çekilmişken orta noktası (gez) arka ele gelir.
static func bow_points(hand: Vector2, wdir: Vector2, h: float, facing: float, hand_back: Vector2, draw_amount: float) -> Dictionary:
	var fwd := Vector2(-wdir.y, wdir.x)
	if fwd.x * facing < 0.0:
		fwd = -fwd
	var top := hand + wdir * h * 0.20 - fwd * h * 0.02
	var bottom := hand - wdir * h * 0.20 - fwd * h * 0.02
	var rest_nock := (top + bottom) * 0.5
	return {"top": top, "bottom": bottom, "bulge": hand + fwd * h * 0.07,
		"nock": rest_nock.lerp(hand_back, clampf(draw_amount, 0.0, 1.0))}

## Gövdenin üstüne binen tek şey: oyuncu seçtiyse başlık. Arketipin kaskı YOK.
func _draw_frame_extras(joints: Dictionary, h: float, look: Dictionary) -> void:
	if _carries_pack and joints.has("back_upper") and joints.has("hand_front"):
		# Heybenin askısı omzun önünden ön ele: yük taşıyan yürüyüşte el askıyı tutuyor.
		var spine := back_frame(joints.back_upper, joints.back_lower, _facing)
		var strap_top: Vector2 = Vector2(spine.upper) + Vector2(spine.up) * h * 0.03 + Vector2(spine.out) * h * 0.01
		draw_polyline(PackedVector2Array([strap_top, joints.shoulder, joints.hand_front]),
			(look.trim as Color).darkened(0.35), maxf(1.0, h * 0.008))
	if not joints.has("head_top"):
		return
	var headgear := OutfitCatalog.resolve_headgear(_outfit, "none")
	if bool(headgear.override):
		var top: Vector2 = joints.head_top
		var radius := FigureRig.head_radius(h)
		var centre := top + (Vector2(joints.neck) - top).normalized() * radius
		_draw_headgear(centre, radius, h, look.cloth, look.trim, look.metal, headgear)

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
			if weapon_sprite:
				pass
			elif _combat_stance:
				_draw_held_weapon(joints, h, look)
			else:
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
	_draw_pack(shoulder, h, bulk, look)

## Sırttaki yük: gövdenin üstünde, mankenin de üstünde.
func _draw_pack(shoulder: Vector2, h: float, bulk: float, look: Dictionary) -> void:
	var half_top := h * 0.098 * bulk
	if _carries_pack:
		var back := shoulder + Vector2(-half_top * 1.1 * _facing, h * 0.02)
		ArtDraw.inked(self, PackedVector2Array([
			back,
			back + Vector2(-h * 0.075 * _facing, h * 0.03),
			back + Vector2(-h * 0.065 * _facing, h * 0.17),
			back + Vector2(h * 0.01 * _facing, h * 0.15),
		]), (look.trim as Color).darkened(0.15), maxf(1.0, h * 0.010))

## Mankenin kimliği: karakterin cinsiyet/kilo varyantı, yoksa düz beden.
func _body_id() -> String:
	return _body_variant if not _body_variant.is_empty() else Wardrobe.BODY_ID

## Mankenin bu kemiğe düşen parçası, üstünde ne giyiliyorsa onun rengiyle
## çarpılarak. Beden açık gri boyalı (hacim gölgede), yani gömlek gövdeye ve
## kollara, pantolon bacaklara, ayakkabı ayağa, ten baş ve ele düşüyor - bir
## giysinin kendi resmi geldiğinde onun altında doğru biçimde bir beden
## zaten var. Çizdiyse true.
func _draw_body_layer(bone: String, joints: Dictionary, h: float, look: Dictionary, body_id: String) -> bool:
	var found := Wardrobe.bone_texture(body_id, bone)
	var texture: Texture2D = found.texture
	if texture == null:
		return false
	var spec: Dictionary = FigureRig.BONES[bone]
	var part := String(spec.part)
	var tone := _body_tone(part, look)
	if found.shade:
		tone = Color(tone.r * Wardrobe.BACK_SHADE.r, tone.g * Wardrobe.BACK_SHADE.g, tone.b * Wardrobe.BACK_SHADE.b, tone.a)
	draw_set_transform_matrix(_part_xf(bone, joints, h))
	draw_texture(texture, Vector2.ZERO, tone)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	return true

## Bir beden parçasının rengi. `look`'taki renkler `_tinted` - günün ışığı
## zaten içinde.
static func _body_tone(part: String, look: Dictionary) -> Color:
	match part:
		"torso", "upper_arm", "forearm":
			return look.cloth
		"thigh", "shin":
			return look.pants
		"foot":
			return look.shoes
		"hand":
			return look.gloves
	return look.skin

## Mankenin üstüne binen prosedürel izler: saç ya da başlık, sırt yükü.
func _draw_bone_overlay(bone: String, joints: Dictionary, h: float, bulk: float, look: Dictionary) -> void:
	match String(FigureRig.BONES[bone].part):
		"head":
			var radius := h * 0.058 * (0.92 + bulk * 0.08)
			var centre: Vector2 = joints.shoulder + Vector2(h * 0.012 * _facing, -radius * 1.35)
			var headgear := OutfitCatalog.resolve_headgear(_outfit, String(_archetype.get("head", "bare")))
			_draw_headgear(centre, radius, h, look.cloth, look.trim, look.metal, headgear)
		"torso":
			_draw_pack(joints.shoulder, h, bulk, look)

func _part_xf(bone: String, joints: Dictionary, h: float) -> Transform2D:
	var spec: Dictionary = FigureRig.BONES[bone]
	var part := String(spec.part)
	return FigureRig.part_transform(
		FigureRig.PARTS[part].pivot, FigureRig.part_rest_vector(part),
		joints[spec.a], joints[spec.b], h, _facing
	)

## Üstteki kalemlerin sprite katmanları, alttan üste (beden `_draw_body_layer`).
func _draw_wardrobe(bone: String, joints: Dictionary, h: float) -> void:
	if _loadout.is_empty():
		return
	var xf := _part_xf(bone, joints, h)
	var drew := false
	for item_id in _loadout:
		var found := Wardrobe.bone_texture(item_id, bone)
		var texture: Texture2D = found.texture
		if texture == null:
			continue
		var tone := _tint
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
	_draw_headgear(centre, radius, h, cloth, trim, metal, headgear)

## Saç ya da başlık - prosedürel başın da mankenin başının da üstünde.
func _draw_headgear(
	centre: Vector2, radius: float, h: float, cloth: Color, trim: Color, metal: Color,
	headgear: Dictionary
) -> void:
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

## Savaşta arketipin silahı elde, kabzası ön elde (bu kemik ön koldan önce
## çiziliyor, parmaklar kabzanın üstüne kapanıyor). Biçimler savaş
## silüetinin eski prosedürel silahlarıyla aynı - kılıç yukarı-ileri, mızrak
## dik, kalkan göğsün ön kenarında - yalnızca iskeletin eline bağlı.
func _draw_held_weapon(joints: Dictionary, h: float, look: Dictionary) -> void:
	var hand: Vector2 = joints.hand_front
	var f := _facing
	var metal: Color = look.metal
	var trim: Color = look.trim
	var ink_w := maxf(1.0, h * 0.008)
	match String(_archetype.get("weapon", "none")):
		"sword":
			var tip := hand + Vector2(0.10 * f, -0.30) * h
			draw_line(hand, tip, ArtPalette.INK, maxf(2.6, h * 0.022))
			draw_line(hand, tip, metal, maxf(1.6, h * 0.014))
			draw_line(hand + Vector2(-0.035 * f, 0.012) * h, hand + Vector2(0.035 * f, -0.012) * h, trim, maxf(2.0, h * 0.016))
		"cleaver":
			ArtDraw.inked(self, PackedVector2Array([
				hand + Vector2(0.0, -0.05) * h, hand + Vector2(0.13 * f, -0.19) * h,
				hand + Vector2(0.17 * f, -0.08) * h, hand + Vector2(0.03 * f, 0.01) * h,
			]), metal, ink_w)
		"maul":
			var head := hand + Vector2(0.08 * f, -0.30) * h
			draw_line(hand + Vector2(-0.01 * f, 0.05) * h, head, trim.darkened(0.25), maxf(2.4, h * 0.020))
			ArtDraw.inked(self, PackedVector2Array([
				head + Vector2(-0.06, -0.035) * h, head + Vector2(0.06, -0.045) * h,
				head + Vector2(0.065, 0.025) * h, head + Vector2(-0.055, 0.035) * h,
			]), metal, ink_w)
		"spear_shield":
			var top := hand + Vector2(0.02 * f, -0.52) * h
			draw_line(hand + Vector2(0.0, 0.16) * h, top, trim.darkened(0.2), maxf(2.0, h * 0.016))
			ArtDraw.inked(self, PackedVector2Array([
				top, top + Vector2(0.025 * f, 0.06) * h, top + Vector2(0.0, 0.10) * h,
				top + Vector2(-0.025 * f, 0.06) * h,
			]), metal, ink_w)
			var shield: Vector2 = joints.shoulder.lerp(joints.hip, 0.55) + Vector2(0.075 * f, 0.0) * h
			ArtDraw.ellipse(self, shield, Vector2(0.055, 0.105) * h, metal.darkened(0.30))
			draw_arc(shield, 0.105 * h, 0.0, TAU, 20, ArtPalette.INK, ink_w)
		"bow":
			var centre := hand + Vector2(0.02 * f, -0.05) * h
			var facing_angle := 0.0 if f > 0.0 else PI
			draw_arc(centre, 0.20 * h, facing_angle - PI * 0.42, facing_angle + PI * 0.42, 18, trim.darkened(0.15), maxf(2.0, h * 0.016))
			var string_top := centre + Vector2(cos(facing_angle - PI * 0.42), sin(facing_angle - PI * 0.42)) * 0.20 * h
			var string_bottom := centre + Vector2(cos(facing_angle + PI * 0.42), sin(facing_angle + PI * 0.42)) * 0.20 * h
			draw_line(string_top, string_bottom, Color(0.85, 0.82, 0.74, 0.8), maxf(1.0, h * 0.004))
		"staff":
			var staff_top := hand + Vector2(0.01 * f, -0.46) * h
			draw_line(hand + Vector2(0.0, 0.20) * h, staff_top, trim.darkened(0.2), maxf(2.2, h * 0.018))
			draw_circle(staff_top, 0.03 * h, metal)
			draw_arc(staff_top, 0.03 * h, 0.0, TAU, 12, ArtPalette.INK, ink_w)

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
	var species := (_horse_species if not _horse_species.is_empty() else BeastRig.HORSE) if is_horse else BeastRig.OX
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
	var frames := BodyFrames.for_beast(species)
	if frames != null:
		return _draw_beast_frames(frames, h)
	var ground := Vector2(size.x * 0.5, size.y)
	var joints := BeastRig.draw_pose(species, ground, h, _phase, _motion, _facing)
	var span := h * BeastRig.body_span(species)
	ArtDraw.ellipse(self, ground, Vector2(span * 0.75, h * 0.030), Color(0.0, 0.0, 0.0, 0.24))
	BeastRig.draw_species(self, species, joints, h, _facing, _tint)
	return (joints.saddle as Vector2).y

## Hayvanın 3B'den render edilmiş kareleri (`BodyFrames`, beast_<tür>):
## insanla aynı beş katman - uzak bacaklar, gövde, yakın bacaklar - ve aynı
## ışık; yürüyüş/duruş/saldırı/darbe/ölü modelin kendi animasyonundan.
## Döner: eyerin y'si (binici oraya oturuyor).
func _draw_beast_frames(frames: BodyFrames, h: float) -> float:
	var clip := BodyFrames.beast_clip("", 1.0, "", _motion)
	if not _action_clip.is_empty() and frames.has_clip(_action_clip):
		clip = _action_clip
	var frame := frames.frame_for_phase(clip, _phase) if clip == "walk" else frames.frame_for_time(clip, _action_u)
	var k := frames.scale_for(h)
	var origin := Vector2(size.x * 0.5, size.y)
	ArtDraw.ellipse(self, origin, Vector2(h * 0.5, h * 0.030), Color(0.0, 0.0, 0.0, 0.24))
	var joints := frames.draw_all(self, clip, frame, Transform2D(0.0, Vector2(k * _facing, k), 0.0, origin), _tint)
	return (joints.get("saddle", origin - Vector2(0.0, h * 0.6)) as Vector2).y

func _draw_quad_leg(
	shoulder: Vector2, ground_y: float, h: float, phase: float, color: Color
) -> void:
	var stride := h * 0.13 * _motion
	var lift := h * 0.055 * _motion
	# -cos: yerdeki toynak (sin < 0) geriye gidiyor. cos ile öne gidiyordu -
	# insanların uzun süre yaptığı ay yürüyüşünün aynısı (bkz. test_gait).
	var hoof := Vector2(
		shoulder.x - cos(phase) * stride * _facing,
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
