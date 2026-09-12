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
## Yürüyüş iki eklemli çözülüyor (kalça → diz → ayak). Tek parça bir bacağı
## ileri geri sallamak "makas" gibi duruyor, dizi bükmek yürüyüş gibi
## duruyor; ayak yere basarken geride *kalıyor*, yani figür yerde kaymıyor.
## Sprite geldiğinde bu dosya bir `AnimatedSprite2D`'ye yer açar, ama
## arayüz (`set_kind`, `advance`, `set_tint`) aynı kalabilir.
##
## Palet `CombatFigure.ARCHETYPES`'ten geliyor: savaşta gördüğün muhafız
## yolda da aynı renklerde yürüyor. İki tablo tutmak ikisinin ayrışması
## demekti.

## Ne çiziliyor.
const KIND_PERSON: String = "person"
const KIND_MOUNTED: String = "mounted"
const KIND_HORSE: String = "horse"
const KIND_OX: String = "ox"

## Adım uzunluğu ve dizin bükülme payı figür yüksekliğine oranlı, yoksa
## kısa bir figür uzun adım atıyor gibi duruyor.
const STRIDE_RATIO: float = 0.19
const LIFT_RATIO: float = 0.075
const BOB_RATIO: float = 0.018

const HORSE_PHASES: Array[float] = [0.0, PI, PI * 0.5, PI * 1.5]

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
var _carries_pack: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## `archetype_id` `CombatFigure.ARCHETYPES` anahtarı; bilinmeyen bir id
## haydut paletine düşer (aynı kural savaş figüründe de var).
func set_kind(
	kind: String, archetype_id: String, height_scale: float = 1.0,
	skin: Color = FALLBACK_SKIN, carries_pack: bool = false
) -> void:
	_kind = kind
	_archetype = CombatFigure.ARCHETYPES.get(
		archetype_id, CombatFigure.ARCHETYPES["bandit"]
	)
	_scale = clampf(height_scale, 0.82, 1.18)
	_skin = skin
	_carries_pack = carries_pack
	queue_redraw()

## Yürüyüş fazını ilerletir. `speed` 0 ise figür duruyor: ayakları yere
## basıyor, gövdesi nefes alıyor kadar oynuyor. Faz dışarıdan sürülüyor,
## çünkü bütün kervan aynı tempoyu paylaşmalı ama aynı *anda* aynı adımı
## atmamalı (bkz. RoadCaravan'ın faz kaydırması).
func advance(delta: float, speed: float) -> void:
	var was_moving := _moving
	_moving = absf(speed) > 0.01
	if _moving:
		_phase = fmod(_phase + delta * speed * TAU, TAU)
		_facing = 1.0 if speed >= 0.0 else -1.0
	elif was_moving:
		# Durunca ayakları yan yana bırakıyoruz; yarım adımda donmuş bir
		# figür kırılmış gibi duruyor.
		_phase = 0.0
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

## `ground_y` figürün bastığı çizgi; binicide bu eyerin üstü oluyor, yani
## aynı gövde çizimi hem yürüyen hem atlı için kullanılıyor.
func _draw_person(figure_h: float, ground_y: float, seated: bool) -> void:
	var h := figure_h * _scale
	var cx := size.x * 0.5
	var cloth: Color = _tinted(_archetype.get("cloth", Color(0.3, 0.25, 0.22)))
	var trim: Color = _tinted(_archetype.get("trim", Color(0.4, 0.3, 0.22)))
	var metal: Color = _tinted(_archetype.get("metal", ArtPalette.STEEL))
	var skin := _tinted(_skin)
	var bulk: float = float(_archetype.get("bulk", 1.0))

	# Yürüyen figürde `ground_y` ayağın bastığı yer, o yüzden kalça
	# yukarıda. Oturan figürde `ground_y` **eyerin kendisi**, yani kalça
	# tam orada: ilk hâlinde ikisi aynı formülü kullanıyordu ve binici
	# atın kırk piksel üstünde havada duruyordu (ekran görüntüsünde
	# apaçık, yapısal testte görünmez).
	var hip := Vector2(cx, ground_y if seated else ground_y - h * 0.46)
	var bob := sin(_phase * 2.0) * h * BOB_RATIO if _moving else 0.0
	hip.y += bob

	if not seated:
		# Yere düşen gölge figürü zemine oturtuyor; olmayınca hakikaten
		# havada süzülüyor gibi duruyor.
		ArtDraw.ellipse(
			self, Vector2(cx, ground_y), Vector2(h * 0.16, h * 0.028),
			Color(0.0, 0.0, 0.0, 0.26)
		)
		_draw_leg(hip, ground_y, h, _phase + PI, cloth.darkened(0.28))
		_draw_leg(hip, ground_y, h, _phase, cloth)
	else:
		_draw_seated_legs(hip, h, cloth)

	var shoulder := hip + Vector2(0.0, -h * 0.26)
	# Gövde: omuzdan kalçaya doğru daralan bir gövde. Dikdörtgen yerine
	# çokgen olması silüeti tanınır kılıyor.
	var half_top := h * 0.098 * bulk
	var half_bottom := h * 0.076 * bulk
	ArtDraw.inked(self, PackedVector2Array([
		shoulder + Vector2(-half_top * _facing, 0.0),
		shoulder + Vector2(half_top * _facing, 0.0),
		hip + Vector2(half_bottom * _facing, h * 0.02),
		hip + Vector2(-half_bottom * _facing, h * 0.02),
	]), cloth, maxf(1.0, h * 0.012))

	# Pelerin/yük: sırtta asimetrik bir hacim. Kervanı "yüklü" gösteren şey.
	if _carries_pack:
		var back := shoulder + Vector2(-half_top * 1.1 * _facing, h * 0.02)
		ArtDraw.inked(self, PackedVector2Array([
			back,
			back + Vector2(-h * 0.075 * _facing, h * 0.03),
			back + Vector2(-h * 0.065 * _facing, h * 0.17),
			back + Vector2(h * 0.01 * _facing, h * 0.15),
		]), trim.darkened(0.15), maxf(1.0, h * 0.010))

	_draw_arm(shoulder, h, _phase, cloth.darkened(0.18), skin)
	_draw_head(shoulder, h, bulk, skin, cloth, trim, metal)
	_draw_arm(shoulder, h, _phase + PI, cloth, skin)
	_draw_slung_weapon(shoulder, h, metal, trim)

## Kalça → diz → ayak. Ayağın *hedefi* hesaplanıyor, diz ondan çözülüyor;
## tersi (dizi sallamak) ayağı yerde kaydırıyor.
func _draw_leg(hip: Vector2, ground_y: float, h: float, phase: float, color: Color) -> void:
	var leg_len := ground_y - hip.y
	var stride := h * STRIDE_RATIO if _moving else 0.0
	var lift := h * LIFT_RATIO if _moving else 0.0
	var foot := Vector2(
		hip.x + cos(phase) * stride * _facing,
		ground_y - maxf(0.0, sin(phase)) * lift
	)
	var thigh := leg_len * 0.52
	var shin := leg_len * 0.52
	var knee := _solve_joint(hip, foot, thigh, shin, _facing)

	var width := maxf(2.0, h * 0.042)
	draw_line(hip, knee, color, width)
	draw_line(knee, foot, color, width * 0.88)
	# Ayak: yürüyüşün okunmasını sağlayan en küçük detay.
	draw_line(
		foot, foot + Vector2(h * 0.048 * _facing, 0.0),
		color.darkened(0.35), maxf(1.5, h * 0.022)
	)

## Atlı oturuyor: bacaklar eyerden aşağı sarkıyor, yürüyüş fazı bacağa
## değil atın ritmine bağlı.
func _draw_seated_legs(hip: Vector2, h: float, color: Color) -> void:
	var width := maxf(2.0, h * 0.042)
	var knee := hip + Vector2(h * 0.10 * _facing, h * 0.14)
	var foot := knee + Vector2(-h * 0.02 * _facing, h * 0.16)
	draw_line(hip, knee, color.darkened(0.20), width)
	draw_line(knee, foot, color.darkened(0.20), width * 0.88)
	draw_line(
		foot, foot + Vector2(h * 0.045 * _facing, 0.0),
		color.darkened(0.40), maxf(1.5, h * 0.022)
	)

func _draw_arm(shoulder: Vector2, h: float, phase: float, color: Color, skin: Color) -> void:
	var swing := (sin(phase) if _moving else 0.35) * 0.55
	var upper := h * 0.15
	var lower := h * 0.14
	var elbow := shoulder + Vector2(
		sin(swing) * upper * _facing, cos(swing * 0.6) * upper
	)
	var hand := elbow + Vector2(
		sin(swing * 1.5 + 0.4) * lower * _facing, cos(swing * 0.4) * lower
	)
	var width := maxf(1.6, h * 0.032)
	draw_line(shoulder, elbow, color, width)
	draw_line(elbow, hand, color, width * 0.85)
	draw_circle(hand, maxf(1.2, h * 0.020), skin)

func _draw_head(
	shoulder: Vector2, h: float, bulk: float, skin: Color,
	cloth: Color, trim: Color, metal: Color
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

	match String(_archetype.get("head", "bare")):
		"helmet":
			ArtDraw.inked(self, PackedVector2Array([
				centre + Vector2(-radius, -radius * 0.15),
				centre + Vector2(-radius * 0.7, -radius * 1.15),
				centre + Vector2(radius * 0.7, -radius * 1.15),
				centre + Vector2(radius, -radius * 0.15),
			]), metal, maxf(1.0, h * 0.009))
		"hood":
			ArtDraw.inked(self, PackedVector2Array([
				centre + Vector2(-radius * 1.15, radius * 0.35),
				centre + Vector2(-radius * 0.85, -radius * 1.2),
				centre + Vector2(radius * 0.55, -radius * 1.1),
				centre + Vector2(radius * 0.9, radius * 0.2),
				centre + Vector2(-radius * 0.2, radius * 0.5),
			]), cloth.darkened(0.18), maxf(1.0, h * 0.009))
		"wrap":
			draw_line(
				centre + Vector2(-radius, -radius * 0.4),
				centre + Vector2(radius, -radius * 0.55),
				trim, maxf(1.6, radius * 0.55)
			)
		"cap":
			draw_line(
				centre + Vector2(-radius * 0.95, -radius * 0.65),
				centre + Vector2(radius * 0.95, -radius * 0.65),
				trim, maxf(1.6, radius * 0.5)
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
## Fark hacim, renk ve boynuz/yal.
##
## Sırtın y'sini döndürüyor: atlı figür biniciyi oraya oturtuyor.
func _draw_quadruped(figure_h: float, coat: Color, shade: Color, is_horse: bool) -> float:
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
	var bob := sin(_phase * 2.0) * h * 0.012 if _moving else 0.0
	ArtDraw.inked(self, PackedVector2Array([
		Vector2(rear_x - h * 0.12 * _facing, back_y + h * 0.10 + bob),
		Vector2(rear_x - h * 0.02 * _facing, back_y - h * 0.02 + bob),
		Vector2(cx, back_y - h * 0.05 + bob),
		Vector2(front_x, back_y - h * 0.01 + bob),
		Vector2(front_x + h * 0.11 * _facing, back_y + h * 0.16 + bob),
		Vector2(front_x * 0.6 + cx * 0.4, back_y + h * 0.34 + bob),
		Vector2(cx, back_y + h * 0.36 + bob),
		Vector2(rear_x - h * 0.04 * _facing, back_y + h * 0.30 + bob),
	]), body, maxf(1.2, h * 0.012))

	# Boyun kısa ve kalın, baş büyük: ikisi de ilk denemede ince ve
	# küçüktü, o yüzden silüet at değil lama okuyordu.
	# Baş boynun *ucunda ve yukarıda*: ilk ölçüde baş öne ve aşağı
	# uzuyordu, o yüzden silüet at değil geyik/deve okuyordu. Bir at
	# başını omuz hizasının üstünde taşır.
	var neck_base := Vector2(front_x + h * 0.04 * _facing, back_y + h * 0.02 + bob)
	var head := neck_base + Vector2(
		h * (0.15 if is_horse else 0.19) * _facing,
		-h * (0.30 if is_horse else 0.08)
	)
	ArtDraw.inked(self, PackedVector2Array([
		neck_base + Vector2(-h * 0.08 * _facing, h * 0.02),
		neck_base + Vector2(h * 0.02 * _facing, -h * 0.06),
		head + Vector2(-h * 0.04 * _facing, -h * 0.04),
		head + Vector2(h * 0.03 * _facing, h * 0.09),
		neck_base + Vector2(h * 0.06 * _facing, h * 0.20),
	]), body, maxf(1.2, h * 0.011))
	ArtDraw.inked(self, PackedVector2Array([
		head + Vector2(-h * 0.07 * _facing, -h * 0.07),
		head + Vector2(h * 0.16 * _facing, -h * 0.03),
		head + Vector2(h * 0.18 * _facing, h * 0.07),
		head + Vector2(-h * 0.05 * _facing, h * 0.08),
	]), body, maxf(1.0, h * 0.010))
	draw_circle(head + Vector2(h * 0.02 * _facing, -h * 0.015), maxf(1.2, h * 0.017), ArtPalette.INK)

	if is_horse:
		draw_line(
			neck_base + Vector2(h * 0.01 * _facing, -h * 0.05),
			head + Vector2(-h * 0.04 * _facing, -h * 0.05),
			_tinted(HORSE_MANE), maxf(1.8, h * 0.040)
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
				head + Vector2(-h * 0.02 * _facing, -h * 0.05),
				head + Vector2((-h * 0.02 + h * 0.09 * side) * _facing, -h * 0.13),
				_tinted(OX_HORN), maxf(1.4, h * 0.018)
			)

	return back_y + bob

func _draw_quad_leg(
	shoulder: Vector2, ground_y: float, h: float, phase: float, color: Color
) -> void:
	var stride := h * 0.13 if _moving else 0.0
	var lift := h * 0.055 if _moving else 0.0
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
	var to_tip := tip - root
	var distance := clampf(to_tip.length(), 0.001, bone_a + bone_b - 0.001)
	var direction := to_tip.normalized() if to_tip.length() > 0.001 else Vector2.DOWN
	var along := (distance * distance + bone_a * bone_a - bone_b * bone_b) / (2.0 * distance)
	var across := sqrt(maxf(0.0, bone_a * bone_a - along * along))
	var normal := Vector2(-direction.y, direction.x) * signf(bend if bend != 0.0 else 1.0)
	return root + direction * along + normal * across

## Işık figürün bütün renklerini çarpıyor: gece kervanı da geceye ait
## görünüyor.
func _tinted(color: Color) -> Color:
	return Color(
		color.r * _tint.r, color.g * _tint.g, color.b * _tint.b, color.a
	)
