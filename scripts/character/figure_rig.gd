class_name FigureRig
extends RefCounted

## Bir insan figürünün iskeleti: eklemler, kemikler ve kemiklerin çizim
## sırası. Yolda yürüyen figür (`WalkFigure`), savaş figürü (`CombatFigure`,
## sprite giyen biri için) ve karakter ekranının önizlemesi aynı pozu buradan
## okuyor - bir iskelet iki yerde çözülürse iki farklı iskelet olur (Art
## Rules'un "a shape drawn in two places" kuralı, kemikler için).
##
## Kemik sprite'ları (bkz. `Wardrobe`) `REF_H` yüksekliğindeki bir figür için
## çizilmiş kabul ediliyor: her parçanın PNG'sinde A ekleminin durduğu
## piksel (`pivot`) ve kemiğin dinlenme pozundaki yönü sabit. Çizim anında
## parça A eklemine oturuyor, kemiğin o anki yönüne dönüyor ve figürün boyu
## kadar ölçekleniyor - bkz. `part_transform`. Şablon PNG'leri
## `tests/render_wardrobe_templates.gd` aynı tablodan üretiyor.

## Sprite pikselinin figür yüksekliğine oranı: `h == REF_H` iken bir sprite
## pikseli bir ekran pikseli.
const REF_H: float = 512.0

## `WalkFigure`'ın yürüyüş sabitleri - adım ve diz payı figür boyuna oranlı.
const STRIDE_RATIO: float = 0.19
const LIFT_RATIO: float = 0.075
const BOB_RATIO: float = 0.018
const HIP_RATIO: float = 0.46
const TORSO_RATIO: float = 0.26
const THIGH_SHARE: float = 0.51
const SHIN_SHARE: float = 0.51
const UPPER_ARM_RATIO: float = 0.15
const FOREARM_RATIO: float = 0.14
const HAND_RATIO: float = 0.04
const FOOT_RATIO: float = 0.048
const SEATED_FOOT_RATIO: float = 0.045
## Elde tutulan silahın yön kemiği. Dinlenme pozunda dimdik aşağı sarkıyor
## (ressam kılıcı dik çiziyor), yürürken önkolla birlikte dönüyor.
const WEAPON_RATIO: float = 0.30
## Kol salınımının dinlenmedeki değeri (`motion` 0 iken `_arm`'ın açısı).
const REST_SWING: float = 0.35 * 0.55
## Silah önkolun dönüşünün yalnızca bu payı kadar dönüyor: tam payla kılıç
## her adımda 60 dereceye savruluyordu, yürüyüş eskrime dönüyordu (ölçüldü).
const WEAPON_SWING_SHARE: float = 0.35

const TORSO: String = "torso"
const HEAD: String = "head"
const WEAPON: String = "weapon"
const UPPER_ARM_BACK: String = "upper_arm_back"
const FOREARM_BACK: String = "forearm_back"
const HAND_BACK: String = "hand_back"
const THIGH_BACK: String = "thigh_back"
const SHIN_BACK: String = "shin_back"
const FOOT_BACK: String = "foot_back"
const THIGH_FRONT: String = "thigh_front"
const SHIN_FRONT: String = "shin_front"
const FOOT_FRONT: String = "foot_front"
const UPPER_ARM_FRONT: String = "upper_arm_front"
const FOREARM_FRONT: String = "forearm_front"
const HAND_FRONT: String = "hand_front"

## Arkadan öne. Arka kol gövdenin *arkasında* (yan görünüşte omzun öbür
## yanı), silah ön elin altında - parmaklar sapı sarsın diye.
const DRAW_ORDER: Array[String] = [
	UPPER_ARM_BACK, FOREARM_BACK, HAND_BACK,
	THIGH_BACK, SHIN_BACK, FOOT_BACK,
	THIGH_FRONT, SHIN_FRONT, FOOT_FRONT,
	TORSO, HEAD, WEAPON,
	UPPER_ARM_FRONT, FOREARM_FRONT, HAND_FRONT,
]

## Kemik -> {a, b: eklem adı, part: sprite dosya adı, back: arka uzuv mu}.
## Arka ve ön uzuv aynı sprite'ı paylaşıyor (ressam bir bacak çiziyor);
## arka olan karartılarak çiziliyor - prosedürel figürün kuralıyla aynı.
const BONES: Dictionary = {
	TORSO: {"a": "shoulder", "b": "hip", "part": "torso", "back": false},
	HEAD: {"a": "shoulder", "b": "head", "part": "head", "back": false},
	WEAPON: {"a": "hand_front", "b": "weapon_tip", "part": "weapon", "back": false},
	UPPER_ARM_BACK: {"a": "shoulder", "b": "elbow_back", "part": "upper_arm", "back": true},
	FOREARM_BACK: {"a": "elbow_back", "b": "hand_back", "part": "forearm", "back": true},
	HAND_BACK: {"a": "hand_back", "b": "fingers_back", "part": "hand", "back": true},
	THIGH_BACK: {"a": "hip", "b": "knee_back", "part": "thigh", "back": true},
	SHIN_BACK: {"a": "knee_back", "b": "ankle_back", "part": "shin", "back": true},
	FOOT_BACK: {"a": "ankle_back", "b": "toe_back", "part": "foot", "back": true},
	THIGH_FRONT: {"a": "hip", "b": "knee_front", "part": "thigh", "back": false},
	SHIN_FRONT: {"a": "knee_front", "b": "ankle_front", "part": "shin", "back": false},
	FOOT_FRONT: {"a": "ankle_front", "b": "toe_front", "part": "foot", "back": false},
	UPPER_ARM_FRONT: {"a": "shoulder", "b": "elbow_front", "part": "upper_arm", "back": false},
	FOREARM_FRONT: {"a": "elbow_front", "b": "hand_front", "part": "forearm", "back": false},
	HAND_FRONT: {"a": "hand_front", "b": "fingers_front", "part": "hand", "back": false},
}

## Ressamın çizdiği dokuz parça: tuval boyutu ve A ekleminin pikseli
## (`REF_H` ölçeğinde). B'nin pikseli dinlenme pozundan çıkıyor
## (`part_rest_vector`), yani şablon ile oyun aynı sayıyı okuyor.
const PARTS: Dictionary = {
	"torso": {"canvas": Vector2i(192, 224), "pivot": Vector2(96, 40)},
	"head": {"canvas": Vector2i(160, 192), "pivot": Vector2(80, 164)},
	"upper_arm": {"canvas": Vector2i(112, 144), "pivot": Vector2(48, 24)},
	"forearm": {"canvas": Vector2i(128, 128), "pivot": Vector2(40, 20)},
	"hand": {"canvas": Vector2i(64, 64), "pivot": Vector2(24, 20)},
	"thigh": {"canvas": Vector2i(144, 176), "pivot": Vector2(56, 24)},
	"shin": {"canvas": Vector2i(144, 176), "pivot": Vector2(88, 24)},
	"foot": {"canvas": Vector2i(128, 64), "pivot": Vector2(40, 30)},
	"weapon": {"canvas": Vector2i(128, 384), "pivot": Vector2(64, 64)},
}
const PART_ORDER: Array[String] = [
	"head", "torso", "upper_arm", "forearm", "hand", "thigh", "shin", "foot", "weapon",
]

## Bir pozun eklemleri. `ground` figürün ayaklarının bastığı noktanın x'i ve
## y'si; binicide y eyerin kendisi. `h` figür boyu (boy ölçeği dahil).
## `phase`/`motion` yürüyüşün fazı ve genliği (0 = duruyor), `facing` +1
## sağa, -1 sola. `bulk` başın hacmi (arketip).
static func pose(
	ground: Vector2, h: float, phase: float, motion: float, facing: float,
	lean: float = 0.0, seated: bool = false, bulk: float = 1.0, ankle_range: float = 0.0,
	classic: bool = false
) -> Dictionary:
	var joints := {}
	var hip := Vector2(ground.x, ground.y if seated else ground.y - h * HIP_RATIO)

	if seated:
		hip.y += sin(phase * 2.0) * h * BOB_RATIO * motion
		joints["hip"] = hip
		var knee := hip + Vector2(h * 0.10 * facing, h * 0.14)
		var ankle := knee + Vector2(-h * 0.02 * facing, h * 0.16)
		joints["knee_front"] = knee
		joints["ankle_front"] = ankle
		joints["toe_front"] = ankle + Vector2(h * SEATED_FOOT_RATIO * facing, 0.0)
	elif classic:
		hip.y += sin(phase * 2.0) * h * BOB_RATIO * motion
		joints["hip"] = hip
		_classic_leg(joints, "back", hip, ground.y, h, phase + PI, motion, facing)
		_classic_leg(joints, "front", hip, ground.y, h, phase, motion, facing)
	else:
		# Kalça bir bacak dik basarken (geçiş) yükselir, iki ayak yerdeyken
		# (çift destek) iner - `cos(2·faz)`, çift desteğin ortasında en
		# alçak. `sin` iken en alçak an çeyrek faz kaymıştı. Yükselme basan
		# bacağın boyuyla sınırlı (aşağıdaki erişim): dinlenme yüksekliğinde
		# diz ~20° kırık duruyor, geçişte kalça kalkmasa yürüyen çömelir.
		hip.y -= (1.0 - cos((phase - _double_support_mid()) * 2.0)) * 0.5 * h * BOB_RATIO * motion
		var back := _ankle_target(hip, ground.y, h, phase + PI, motion, facing, ankle_range)
		var front := _ankle_target(hip, ground.y, h, phase, motion, facing, ankle_range)
		# Bacak uzamaz: adım anında açık duran iki ayağa ancak kalça inerek
		# ulaşılır (FigureActions'ın açık duruşla aynı kuralı).
		var reach := h * HIP_RATIO * (THIGH_SHARE + SHIN_SHARE) * REACH_SHARE
		# Topuğu kalkmış (parmak ucunda) ayak kalçayı indirmez: ona yetişmek
		# için topuk biraz daha kalkar. Yoksa itişteki arka ayak öndeki dizi
		# kırdırıp bütün bedeni çömeltiyordu.
		for target in [back, front]:
			if float(target.pitch) < HEEL_FREE_PITCH:
				continue
			var ankle: Vector2 = target.ankle
			var dx := minf(absf(ankle.x - hip.x), reach * 0.999)
			hip.y = maxf(hip.y, ankle.y - sqrt(reach * reach - dx * dx))
		for target in [back, front]:
			if float(target.pitch) >= HEEL_FREE_PITCH:
				continue
			var ankle: Vector2 = target.ankle
			var dx := minf(absf(ankle.x - hip.x), reach * 0.999)
			ankle.y = minf(ankle.y, hip.y + sqrt(reach * reach - dx * dx))
			target.ankle = ankle
		joints["hip"] = hip
		_place_leg(joints, "back", hip, h, back, facing)
		_place_leg(joints, "front", hip, h, front, facing)

	var body_lean := lean * (0.5 if seated else 1.0)
	var shoulder := hip + Vector2(
		sin(body_lean) * h * TORSO_RATIO * facing, -cos(body_lean) * h * TORSO_RATIO
	)
	joints["shoulder"] = shoulder
	var radius := head_radius(h, bulk)
	joints["head"] = shoulder + Vector2(h * 0.012 * facing, -radius * 1.35)

	# Kollar çift desteğin ortasında en açık: bacaklar %60 basışla yürüyor,
	# adım anı topuk vuruşundan biraz sonra.
	var arm_phase := phase if classic or seated else phase - _double_support_mid()
	_arm(joints, "back", shoulder, h, arm_phase, motion, facing)
	var front_swing := _arm(joints, "front", shoulder, h, arm_phase + PI, motion, facing)
	var turn := (_forearm_offset(front_swing).angle() - _forearm_offset(REST_SWING).angle()) * WEAPON_SWING_SHARE
	var hang := Vector2.DOWN.rotated(turn)
	joints["weapon_tip"] = joints["hand_front"] + Vector2(hang.x * facing, hang.y) * h * WEAPON_RATIO
	return joints

static func head_radius(h: float, bulk: float = 1.0) -> float:
	return h * 0.058 * (0.92 + bulk * 0.08)

## Hangi kemiklerin bu pozda var olduğu: oturan binicinin arka bacağı yok.
static func bones_for(seated: bool) -> Array[String]:
	var result: Array[String] = []
	for bone in DRAW_ORDER:
		if seated and BONES[bone].back and String(BONES[bone].part) in ["thigh", "shin", "foot"]:
			continue
		result.append(bone)
	return result

## Kalça → diz → ayak. Ayağın hedefi hesaplanıyor, diz ondan çözülüyor; diz
## yürüme yönüne doğru bükülüyor (insan dizi öne kırılır).
##
## Faz zamanla artıyor (`WalkFigure.advance`) ve figür yerinde durup dünya
## altından kayıyor; yani havadaki ayak öne, yere basan ayak geriye gitmeli
## (ay yürüyüşü bunun tersiydi, bkz. tests/test_gait.gd). Faz [0, PI) havada,
## [PI, TAU) yerde.
##
## Yerde ayak sabit hızla geriye gider (zemin sabit hızla kayıyor; `cos`
## ile gidince basan ayak hızlanıp yavaşlıyor, kayıyordu). Havada ise ayak
## önce ARKADA kalkar - diz kırılır, topuk kalçaya doğru yükselir - ve en
## yükseğe hâlâ arkadayken çıkar (`SWING_PEAK`); sonra alçaktan öne uzanıp
## topuğuyla basar. Eski yolda ayak en yükseğe tam kalçanın altında çıkıyor,
## diz göğse kadar kalkıyordu (oyuncunun kare dizisiyle karşılaştırması).
const SWING_PEAK: float = 0.35
const SWING_X_EASE: float = 1.35
const REACH_SHARE: float = 0.997
## Topuğu bundan fazla kalkmış ayak kalçayı tutmaz, kalçaya göre kalkar.
const HEEL_FREE_PITCH: float = -0.12
## Bir adımın ne kadarı yerde (Winter: yürümede basış %60, salınım %40). Tam
## %50 iken çift destek anı yoktu: öndeki topuk değdiği anda arkadaki ayak
## parmak ucundan kalkmış oluyordu ve arka bacak her adım anında diz kırıp
## çömelmiş görünüyordu. Topuk vuruşu fazı yine PI (kollar ve boyama pozu ona
## bağlı).
const STANCE_SHARE: float = 0.6
## Bir tam çevrimde gövdenin yere göre ilerlediği yol (boyun kesri): basan
## ayak basış boyunca 2·adım geri gidiyor, basış da çevrimin STANCE_SHARE'i.
## Kadanslar (`RoadCaravan.STEP_RATE`, `WorldHub.STEP_PER_UNIT`) bundan.
const CYCLE_DISTANCE_RATIO: float = 2.0 * STRIDE_RATIO / STANCE_SHARE

## Çift destek aralığının ortası (topuk vuruşundan sonra): kalça en alçakta.
static func _double_support_mid() -> float:
	return TAU * (STANCE_SHARE - 0.5) * 0.5

## Bacağın o anki evresi: salınımda mı, ve evrenin içindeki ilerleme (0..1).
## Basış PI'da başlıyor ve TAU*STANCE_SHARE sürüyor; kalan salınım.
static func gait_stage(phase: float) -> Dictionary:
	var stance_len := TAU * STANCE_SHARE
	var since_strike := fposmod(phase - PI, TAU)
	if since_strike < stance_len:
		return {"swing": false, "t": since_strike / stance_len}
	return {"swing": true, "t": (since_strike - stance_len) / (TAU - stance_len)}

static func _ankle_target(
	hip: Vector2, ground_y: float, h: float, phase: float, motion: float,
	facing: float, ankle_range: float
) -> Dictionary:
	var stride := h * STRIDE_RATIO * motion
	var lift := h * LIFT_RATIO * motion
	var stage := gait_stage(phase)
	var t := float(stage.t)
	# Basan ayak +stride'dan -stride'a sabit hızla geri gider; havadaki ayak
	# geri döner. Bütün iz `_stance_center` kadar kaydırılıyor.
	var x: float
	var y := ground_y
	if stage.swing:
		x = lerpf(-1.0, 1.0, (1.0 - cos(PI * pow(t, SWING_X_EASE))) * 0.5) * stride
		y -= sin(PI * pow(t, log(0.5) / log(SWING_PEAK))) * lift
	else:
		x = (1.0 - 2.0 * t) * stride
	x += _stance_center(stride)
	var ankle := Vector2(hip.x + x * facing, y)
	var pitch := foot_pitch(phase) * ankle_range * motion
	if pitch < 0.0:
		# Topuk kalkıyor, parmak yerde kalıyor: ayak bileği parmağın etrafında
		# yükselir. Aksi halde parmak zemine gömülür ve render tüm bedeni iter.
		ankle.y = minf(ankle.y, ground_y - h * FOOT_RATIO * sin(-pitch))
	return {"ankle": ankle, "pitch": pitch}

## Karşı topuk değdiği anda (basışın 0.5/STANCE_SHARE'i) arkadaki ayak
## +stride·(1-1/STANCE_SHARE)'de; iki ayağın ortası kalçanın altına gelsin
## diye iz bu kadar kaydırılıyor.
static func _stance_center(stride: float) -> float:
	var trailing := 1.0 - 2.0 * (0.5 / STANCE_SHARE)
	return -(1.0 + trailing) * 0.5 * stride

static func _place_leg(joints: Dictionary, side: String, hip: Vector2, h: float, target: Dictionary, facing: float) -> void:
	var leg := h * HIP_RATIO
	var ankle: Vector2 = target.ankle
	var pitch := float(target.pitch)
	joints["knee_" + side] = solve_joint(hip, ankle, leg * THIGH_SHARE, leg * SHIN_SHARE, -facing)
	joints["ankle_" + side] = ankle
	joints["toe_" + side] = ankle + Vector2(cos(pitch) * facing, -sin(pitch)) * h * FOOT_RATIO

## Eski yürüyüş: yalnız boyama pozu (`paint_pose`) için. O poz ressamlarla
## sözleşme (`rig_spec.json` `paint_joints`); değişirse çizilmiş her kuşam
## geçersiz olur, o yüzden yürüyüş düzeltildiğinde o eklemler yerinde kaldı.
static func _classic_leg(
	joints: Dictionary, side: String, hip: Vector2, ground_y: float, h: float,
	phase: float, motion: float, facing: float
) -> void:
	var leg_len := ground_y - hip.y
	var stride := h * STRIDE_RATIO * motion
	var lift := h * LIFT_RATIO * motion
	var ankle := Vector2(
		hip.x - cos(phase) * stride * facing,
		ground_y - maxf(0.0, sin(phase)) * lift
	)
	joints["knee_" + side] = solve_joint(
		hip, ankle, leg_len * THIGH_SHARE, leg_len * SHIN_SHARE, -facing
	)
	joints["ankle_" + side] = ankle
	joints["toe_" + side] = ankle + Vector2(facing, 0.0) * h * FOOT_RATIO

## Yürürken ayağın eğimi (radyan, + = parmak yukarı), bir adım boyunca:
## topuk vuruşunda parmak yukarıda, basışta düz, itişte topuk kalkık (parmak
## aşağıda), salınımda zemini sıyırmamak için hafif yukarı. Faz `_leg`'inkiyle
## aynı: [0, PI) havada, [PI, TAU) yerde. Çarpan `ankle_range`: yalın ayak 1,
## bot bileği tuttuğu için daha az (`BOOT_ANKLE_RANGE`); 0 eski düz ayak -
## boyama pozu (`paint_pose`) ve parça sanatı bu yüzden değişmiyor.
const TOE_OFF_PITCH: float = -0.55
const HEEL_STRIKE_PITCH: float = 0.26
const SWING_PITCH: float = 0.08
const BOOT_ANKLE_RANGE: float = 0.35

static func foot_pitch(phase: float) -> float:
	var stage := gait_stage(phase)
	var t := float(stage.t)
	if stage.swing:
		# Ayak arkada kalkarken parmak hâlâ aşağıda (itişin devamı); ancak
		# öne uzanırken kalkar. Erken düzleşen ayak, arkada havadaki topukla
		# "diz çökmüş" bir figür çiziyordu.
		if t < 0.6:
			return lerpf(TOE_OFF_PITCH, SWING_PITCH, smoothstep(0.1, 0.6, t))
		return lerpf(SWING_PITCH, HEEL_STRIKE_PITCH, smoothstep(0.6, 1.0, t))
	if t < 0.15:
		return lerpf(HEEL_STRIKE_PITCH, 0.0, smoothstep(0.0, 1.0, t / 0.15))
	if t > 0.65:
		return lerpf(0.0, TOE_OFF_PITCH, smoothstep(0.65, 1.0, t))
	return 0.0

## Omuz → dirsek → el. Salınımı döndürüyor: elde tutulan silah onu okuyor.
## Salınım `-cos(phase)`: bacak `-cos` ile gidiyor, kol karşı bacakla aynı
## anda öne geliyor ve en açık anı adım anına (iki ayak yerde) düşüyor. `sin`
## iken kollar en açık hâline bacaklar yan yana geçerken varıyordu.
static func _arm(
	joints: Dictionary, side: String, shoulder: Vector2, h: float,
	phase: float, motion: float, facing: float
) -> float:
	var swing := lerpf(0.35, -cos(phase), motion) * 0.55
	var upper := h * UPPER_ARM_RATIO
	var lower := h * FOREARM_RATIO
	var elbow := shoulder + Vector2(sin(swing) * upper * facing, cos(swing * 0.6) * upper)
	var forearm := _forearm_offset(swing)
	var hand := elbow + Vector2(forearm.x * facing, forearm.y) * lower
	joints["elbow_" + side] = elbow
	joints["hand_" + side] = hand
	joints["fingers_" + side] = hand + (hand - elbow).normalized() * h * HAND_RATIO
	return swing

## Önkolun yönü (sağa bakan figür için, birim değil ama yönü doğru).
static func _forearm_offset(swing: float) -> Vector2:
	return Vector2(sin(swing * 1.5 + 0.4), cos(swing * 0.4))

## İki kemikli eklem çözümü: `root` ile `tip` arasındaki mesafeye göre orta
## eklemin yerini bulur. Ulaşılamayan hedefte uzuv geriliyor.
static func solve_joint(
	root: Vector2, tip: Vector2, bone_a: float, bone_b: float, bend: float
) -> Vector2:
	var to_tip := tip - root
	var distance := clampf(to_tip.length(), 0.001, bone_a + bone_b - 0.001)
	var direction := to_tip.normalized() if to_tip.length() > 0.001 else Vector2.DOWN
	var along := (distance * distance + bone_a * bone_a - bone_b * bone_b) / (2.0 * distance)
	var across := sqrt(maxf(0.0, bone_a * bone_a - along * along))
	var normal := Vector2(-direction.y, direction.x) * signf(bend if bend != 0.0 else 1.0)
	return root + direction * along + normal * across

## Dinlenme pozu: `REF_H` boyunda, duran, sağa bakan, eğilmemiş figür.
## Parça sprite'larının çizildiği poz bu.
static func rest_pose() -> Dictionary:
	return pose(Vector2.ZERO, REF_H, 0.0, 0.0, 1.0)

## Boyama pozu: bütün olarak çizilen bir kuşamın (bkz. tools/wardrobe_cut.py)
## üstüne oturduğu poz. Dinlenme pozunda arka uzuv tam olarak ön uzvun
## arkasına gizleniyor, yani oradan kesilen bir ceketin arka kolu diye bir
## şey yok - `BeastRig.PAINT_PHASE` de aynı sebeple var.
##
## Bacaklar ve kollar ikisi de `-cos(phase)` ile salınıyor, yani en geniş
## anları aynı faz: `PI`, ön ayak öne basarken (adım anı). Eskiden kollar
## `sin` ile gidiyordu ve bu poz iki ayrı fazdan birleştiriliyordu; yürüyüş
## düzeltilince (bkz. `_leg`) iki faz da `PI` oldu ve eklemler 0,01 px'e
## kadar eskisiyle aynı kaldı - poz ressamlarla olan sözleşme
## (`rig_spec.json` `paint_joints`), değişirse çizilmiş her kuşam geçersiz.
const PAINT_LEG_PHASE: float = PI
const PAINT_ARM_PHASE: float = PI

static func paint_pose() -> Dictionary:
	var joints := pose(Vector2.ZERO, REF_H, PAINT_LEG_PHASE, 1.0, 1.0, 0.0, false, 1.0, 0.0, true)
	var arms := pose(Vector2.ZERO, REF_H, PAINT_ARM_PHASE, 1.0, 1.0, 0.0, false, 1.0, 0.0, true)
	for joint in ["elbow_back", "hand_back", "fingers_back",
			"elbow_front", "hand_front", "fingers_front", "weapon_tip"]:
		joints[joint] = arms[joint]
	return joints

## Bir parçanın PNG'sinde A'dan B'ye vektör (piksel). Arka ve ön uzvun
## dinlenme yönü aynı olduğu için ön kemikten okunuyor.
static func part_rest_vector(part: String) -> Vector2:
	var rest := rest_pose()
	for bone in DRAW_ORDER:
		var spec: Dictionary = BONES[bone]
		if spec.part == part and not spec.back:
			return rest[spec.b] - rest[spec.a]
	return Vector2.DOWN

## Parçanın PNG uzayından dünya uzayına dönüşüm. PNG'deki `pivot` A
## eklemine oturuyor, dinlenme yönü (`rest_vector`) kemiğin o anki yönüne
## dönüyor, ölçek `h / ref_h` (hayvan iskeleti kendi `REF_H`'ını veriyor).
## Sola bakan figürde parça aynalanıyor - rig zaten eklemleri aynalıyor,
## sprite da onunla aynalanmalı.
static func part_transform(
	pivot: Vector2, rest_vector: Vector2, a_world: Vector2, b_world: Vector2,
	h: float, facing: float, ref_h: float = REF_H
) -> Transform2D:
	var mirror := 1.0 if facing >= 0.0 else -1.0
	var scale := h / ref_h
	var rest_m := Vector2(rest_vector.x * mirror, rest_vector.y)
	var theta := 0.0
	if (b_world - a_world).length() > 0.0001 and rest_m.length() > 0.0001:
		theta = (b_world - a_world).angle() - rest_m.angle()
	var x_axis := Vector2(cos(theta), sin(theta)) * scale * mirror
	var y_axis := Vector2(-sin(theta), cos(theta)) * scale
	var origin := a_world - (x_axis * pivot.x + y_axis * pivot.y)
	return Transform2D(x_axis, y_axis, origin)
