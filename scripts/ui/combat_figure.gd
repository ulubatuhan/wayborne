class_name CombatFigure
extends Control

## Savaş alanındaki bir savaşçının çizilmiş silüeti. Varlık dosyası yok:
## her şey `_draw()` ile poligon olarak çiziliyor.
##
## Bunun yerine bir `ColorRect` vardı ve sonuç "Excel'de oyun yapıyoruz"
## gibi görünüyordu - haklı bir şikâyet. Renkli dikdörtgen bir yer tutucu
## olabilir ama *kimseyi* temsil etmiyor: dört sınıf ve dokuz düşman aynı
## kutuydu, silahı, duruşu, hacmi yoktu. Sprite geldiğinde bu dosya bir
## `TextureRect`'e yer açacak; o güne kadar oyuncunun karşısında en azından
## bir insan ya da bir hayvan duruyor.
##
## Çizim mantığı iki arketip üzerine kurulu: iki ayaklı (insan) ve dört
## ayaklı (hayvan). Geri kalan her şey - hacim, başlık, silah, palet -
## `ARCHETYPES` tablosundan geliyor, yani yeni bir düşman eklemek bir satır.

## Silüet yönü: oyuncu sağa, düşman sola bakar. İki safın karşı karşıya
## durduğu hissi bundan geliyor.
const HUMANOID: String = "humanoid"
const BEAST: String = "beast"

## Kıyafet/deri paletleri koyu ve doygunluğu düşük - DD'nin mürekkep
## hissine yaklaşmanın en ucuz yolu tonu kısmak.
const OUTLINE: Color = Color(0.06, 0.05, 0.06)
const SHADOW: Color = Color(0.0, 0.0, 0.0, 0.35)

const SKIN_WARM: Color = Color(0.72, 0.56, 0.42)
const SKIN_PALE: Color = Color(0.78, 0.65, 0.53)

## Her arketip: gövde tipi, hacim (0.8 ince - 1.3 iri), başlık, silah ve
## üç renk (kumaş, ikincil, metal/post).
const ARCHETYPES: Dictionary = {
	# --- Oyuncu sınıfları ---
	"guard": {
		"body": HUMANOID, "bulk": 1.15, "head": "helmet", "weapon": "spear_shield",
		"cloth": Color(0.34, 0.36, 0.33), "trim": Color(0.45, 0.40, 0.28),
		"metal": Color(0.62, 0.64, 0.66),
	},
	"hunter": {
		"body": HUMANOID, "bulk": 0.92, "head": "hood", "weapon": "bow",
		"cloth": Color(0.33, 0.30, 0.22), "trim": Color(0.48, 0.38, 0.24),
		"metal": Color(0.55, 0.50, 0.42),
	},
	"breaker": {
		"body": HUMANOID, "bulk": 1.28, "head": "bare", "weapon": "maul",
		"cloth": Color(0.40, 0.26, 0.22), "trim": Color(0.30, 0.22, 0.18),
		"metal": Color(0.50, 0.48, 0.46),
	},
	"clerk": {
		"body": HUMANOID, "bulk": 0.88, "head": "cap", "weapon": "staff",
		"cloth": Color(0.24, 0.26, 0.34), "trim": Color(0.52, 0.44, 0.24),
		"metal": Color(0.58, 0.52, 0.34),
	},
	# --- Haydutlar ---
	"bandit": {
		"body": HUMANOID, "bulk": 1.0, "head": "wrap", "weapon": "sword",
		"cloth": Color(0.30, 0.22, 0.20), "trim": Color(0.42, 0.26, 0.22),
		"metal": Color(0.58, 0.58, 0.60),
	},
	"bandit_cutter": {
		"body": HUMANOID, "bulk": 1.05, "head": "wrap", "weapon": "cleaver",
		"cloth": Color(0.26, 0.20, 0.20), "trim": Color(0.46, 0.24, 0.20),
		"metal": Color(0.60, 0.58, 0.56),
	},
	"bandit_archer": {
		"body": HUMANOID, "bulk": 0.90, "head": "hood", "weapon": "bow",
		"cloth": Color(0.24, 0.22, 0.24), "trim": Color(0.40, 0.28, 0.22),
		"metal": Color(0.52, 0.50, 0.48),
	},
	"bandit_leader": {
		"body": HUMANOID, "bulk": 1.20, "head": "helmet", "weapon": "sword",
		"cloth": Color(0.32, 0.16, 0.16), "trim": Color(0.56, 0.42, 0.20),
		"metal": Color(0.66, 0.64, 0.62),
	},
	# --- Muhafızlar ---
	"guard_sergeant": {
		"body": HUMANOID, "bulk": 1.22, "head": "helmet", "weapon": "spear_shield",
		"cloth": Color(0.22, 0.28, 0.36), "trim": Color(0.58, 0.48, 0.24),
		"metal": Color(0.70, 0.72, 0.74),
	},
	# --- Hayvanlar ---
	"wolf": {
		"body": BEAST, "bulk": 0.95, "head": "snout", "weapon": "none",
		"cloth": Color(0.34, 0.33, 0.32), "trim": Color(0.22, 0.21, 0.21),
		"metal": Color(0.80, 0.80, 0.78),
	},
	"bear": {
		"body": BEAST, "bulk": 1.35, "head": "snout", "weapon": "none",
		"cloth": Color(0.28, 0.21, 0.16), "trim": Color(0.18, 0.14, 0.11),
		"metal": Color(0.84, 0.82, 0.78),
	},
	"boar": {
		"body": BEAST, "bulk": 1.10, "head": "tusks", "weapon": "none",
		"cloth": Color(0.25, 0.22, 0.20), "trim": Color(0.16, 0.14, 0.13),
		"metal": Color(0.88, 0.86, 0.80),
	},
}

const FALLBACK_KIND: String = "bandit"

var _kind: String = FALLBACK_KIND
var _face_right: bool = true
## "normal" / "downed" / "dead" / "deaths_door"
var _state: String = "normal"
## Arka mevkiler biraz küçük ve koyu çizilir - saf derinliği hissi.
var _depth: float = 0.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## `kind` sınıf ya da düşman kimliği; tanınmayan bir kimlik haydut
## silüetine düşer, yani yeni bir düşman çizimsiz kalmaz.
func setup(kind: String, face_right: bool, state: String, depth: float) -> void:
	_kind = kind if ARCHETYPES.has(kind) else FALLBACK_KIND
	_face_right = face_right
	_state = state
	_depth = clampf(depth, 0.0, 1.0)
	queue_redraw()

func _archetype() -> Dictionary:
	return ARCHETYPES[_kind]

## Duruma göre palet: düşen soluk ve grileşmiş, ölü neredeyse siyah,
## kıyıdaki kızıla çalıyor. Renk tek başına anlam taşımıyor (kutunun
## kenarı ve durum işareti de var), ama silüete bakan oyuncu durumu
## okuyabilmeli.
func _tint(base: Color) -> Color:
	match _state:
		"dead":
			return base.lerp(Color(0.05, 0.04, 0.05), 0.78)
		"downed":
			var grey := (base.r + base.g + base.b) / 3.0
			return Color(grey, grey, grey).lerp(base, 0.25).darkened(0.35)
		"deaths_door":
			return base.lerp(Color(0.58, 0.10, 0.10), 0.45)
	# Arka mevkiler hafifçe karartılır: ışık önden geliyor.
	return base.darkened(_depth * 0.28)

func _draw() -> void:
	var box := size
	if box.x <= 4.0 or box.y <= 4.0:
		return
	var archetype := _archetype()
	var bulk: float = float(archetype.bulk) * (1.0 - _depth * 0.10)

	_draw_ground_shadow(box, bulk)
	if String(archetype.body) == BEAST:
		_draw_beast(box, archetype, bulk)
	else:
		_draw_humanoid(box, archetype, bulk)

func _draw_ground_shadow(box: Vector2, bulk: float) -> void:
	var width := box.x * 0.62 * bulk
	var height := box.y * 0.055
	var centre := Vector2(box.x * 0.5, box.y - height * 0.8)
	_draw_ellipse(centre, Vector2(width * 0.5, height * 0.5), SHADOW)

# --- İki ayaklı ---

func _draw_humanoid(box: Vector2, archetype: Dictionary, bulk: float) -> void:
	var cloth := _tint(archetype.cloth)
	var trim := _tint(archetype.trim)
	var metal := _tint(archetype.metal)
	var skin := _tint(SKIN_WARM if _kind.begins_with("bandit") else SKIN_PALE)

	var cx := box.x * 0.5
	var ground := box.y * 0.955
	var head_r := box.x * 0.135 * bulk
	var shoulder_y := box.y * 0.30
	var hip_y := box.y * 0.62
	var half_shoulder := box.x * 0.20 * bulk
	var half_hip := box.x * 0.145 * bulk
	var lean := (1.0 if _face_right else -1.0) * box.x * 0.02

	# Düşmüş bir figür ayakta durmaz: öne doğru çöker.
	if _state == "downed" or _state == "dead":
		_draw_fallen(box, cloth, trim, skin, bulk)
		return

	# Bacaklar
	var leg_top := hip_y
	var leg_w := box.x * 0.072 * bulk
	_filled(_quad(
		Vector2(cx - half_hip * 0.75, leg_top), Vector2(cx - half_hip * 0.75 + leg_w, leg_top),
		Vector2(cx - leg_w * 0.4, ground), Vector2(cx - leg_w * 1.5, ground)
	), trim.darkened(0.18))
	_filled(_quad(
		Vector2(cx + half_hip * 0.75 - leg_w, leg_top), Vector2(cx + half_hip * 0.75, leg_top),
		Vector2(cx + leg_w * 1.5, ground), Vector2(cx + leg_w * 0.4, ground)
	), trim.darkened(0.30))

	# Pelerin (lider/kalem efendisi) - gövdenin arkasına
	if String(archetype.head) == "cap" or _kind == "bandit_leader":
		var back := -1.0 if _face_right else 1.0
		_filled(_quad(
			Vector2(cx + back * half_shoulder * 0.4, shoulder_y - head_r * 0.3),
			Vector2(cx + back * half_shoulder * 1.15, shoulder_y + box.y * 0.04),
			Vector2(cx + back * half_shoulder * 1.35, ground - box.y * 0.02),
			Vector2(cx + back * half_shoulder * 0.15, ground - box.y * 0.02)
		), trim.darkened(0.42))

	# Gövde: omuzdan kalçaya daralan gövde
	var torso := _quad(
		Vector2(cx - half_shoulder + lean, shoulder_y),
		Vector2(cx + half_shoulder + lean, shoulder_y),
		Vector2(cx + half_hip, hip_y),
		Vector2(cx - half_hip, hip_y)
	)
	_outlined(torso, cloth)

	# Kemer
	draw_rect(Rect2(
		Vector2(cx - half_hip * 1.05, hip_y - box.y * 0.035),
		Vector2(half_hip * 2.1, box.y * 0.032)
	), trim, true)

	# Silah kolu ve silah - önce silah, sonra el
	_draw_weapon(box, String(archetype.weapon), metal, trim, bulk)

	# Baş
	var head_c := Vector2(cx + lean * 1.4, shoulder_y - head_r * 0.95)
	_draw_ellipse(head_c, Vector2(head_r, head_r * 1.06), skin)
	_draw_ellipse_outline(head_c, Vector2(head_r, head_r * 1.06), OUTLINE, 1.5)
	_draw_headgear(String(archetype.head), head_c, head_r, cloth, trim, metal)

	# Kenar ışığı: bakan tarafa ince bir çizgi. Mürekkep hissinin
	# yarısı buradan geliyor.
	var rim := 1.0 if _face_right else -1.0
	draw_line(
		Vector2(cx + rim * half_shoulder + lean, shoulder_y + box.y * 0.01),
		Vector2(cx + rim * half_hip, hip_y - box.y * 0.01),
		Color(1, 1, 1, 0.16), 2.0
	)

## Düşen figür: yerde yatan bir yığın. Ayakta soluk bir figür "düşmüş"
## okunmuyordu, duruş değişmeli.
func _draw_fallen(box: Vector2, cloth: Color, trim: Color, skin: Color, bulk: float) -> void:
	var ground := box.y * 0.94
	var cx := box.x * 0.5
	var body_w := box.x * 0.66 * bulk
	var body_h := box.y * 0.17
	_draw_ellipse(Vector2(cx, ground - body_h * 0.5), Vector2(body_w * 0.5, body_h * 0.5), cloth)
	var head_r := box.x * 0.10 * bulk
	var side := 1.0 if _face_right else -1.0
	_draw_ellipse(
		Vector2(cx + side * body_w * 0.42, ground - body_h * 0.75),
		Vector2(head_r, head_r * 0.95), skin
	)
	draw_line(
		Vector2(cx - side * body_w * 0.45, ground - body_h * 0.35),
		Vector2(cx - side * body_w * 0.62, ground - box.y * 0.01),
		trim, 3.0
	)

func _draw_headgear(
	head: String, centre: Vector2, radius: float,
	cloth: Color, trim: Color, metal: Color
) -> void:
	match head:
		"helmet":
			_draw_arc_cap(centre, radius * 1.12, metal)
			draw_line(
				Vector2(centre.x - radius, centre.y + radius * 0.18),
				Vector2(centre.x + radius, centre.y + radius * 0.18),
				metal.darkened(0.3), 2.0
			)
		"hood":
			_filled(_quad(
				Vector2(centre.x - radius * 1.35, centre.y + radius * 0.55),
				Vector2(centre.x, centre.y - radius * 1.5),
				Vector2(centre.x + radius * 1.35, centre.y + radius * 0.55),
				Vector2(centre.x, centre.y + radius * 0.2)
			), cloth.darkened(0.22))
		"wrap":
			draw_rect(Rect2(
				Vector2(centre.x - radius, centre.y - radius * 0.55),
				Vector2(radius * 2.0, radius * 0.52)
			), trim, true)
		"cap":
			draw_rect(Rect2(
				Vector2(centre.x - radius * 0.95, centre.y - radius * 1.25),
				Vector2(radius * 1.9, radius * 0.62)
			), cloth.darkened(0.2), true)
		_:
			# Başı açık: saç bir kavis olarak.
			_draw_arc_cap(centre, radius * 1.02, cloth.darkened(0.5))

func _draw_weapon(
	box: Vector2, weapon: String, metal: Color, trim: Color, bulk: float
) -> void:
	var side := 1.0 if _face_right else -1.0
	var hand := Vector2(
		box.x * 0.5 + side * box.x * 0.24 * bulk,
		box.y * 0.46
	)
	match weapon:
		"sword":
			draw_line(hand, hand + Vector2(side * box.x * 0.06, -box.y * 0.30), metal, 4.0)
			draw_line(
				hand + Vector2(-side * box.x * 0.05, 0.0),
				hand + Vector2(side * box.x * 0.05, 0.0), trim, 4.0
			)
		"cleaver":
			_filled(_quad(
				hand + Vector2(0.0, -box.y * 0.06),
				hand + Vector2(side * box.x * 0.20, -box.y * 0.20),
				hand + Vector2(side * box.x * 0.24, -box.y * 0.06),
				hand + Vector2(side * box.x * 0.04, box.y * 0.01)
			), metal)
		"maul":
			draw_line(hand, hand + Vector2(side * box.x * 0.10, -box.y * 0.26), trim, 5.0)
			draw_rect(Rect2(
				hand + Vector2(side * box.x * 0.02, -box.y * 0.34),
				Vector2(box.x * 0.17, box.y * 0.09)
			), metal, true)
		"spear_shield":
			draw_line(
				hand + Vector2(side * box.x * 0.02, box.y * 0.16),
				hand + Vector2(side * box.x * 0.02, -box.y * 0.40), trim, 4.0
			)
			_filled(_quad(
				hand + Vector2(side * box.x * 0.02, -box.y * 0.40),
				hand + Vector2(side * box.x * 0.07, -box.y * 0.33),
				hand + Vector2(side * box.x * 0.02, -box.y * 0.29),
				hand + Vector2(side * box.x * -0.03, -box.y * 0.33)
			), metal)
			# Kalkan: gövdenin ön kenarında, aşağıda ve dar. Daha büyük ve
			# yukarıdayken göğsün üstünde bir balon gibi duruyordu.
			var shield_c := Vector2(box.x * 0.5 + side * box.x * 0.155, box.y * 0.50)
			_draw_ellipse(shield_c, Vector2(box.x * 0.085, box.y * 0.105), metal.darkened(0.30))
			_draw_ellipse_outline(shield_c, Vector2(box.x * 0.085, box.y * 0.105), OUTLINE, 1.5)
		"bow":
			draw_arc(
				hand + Vector2(side * box.x * 0.02, -box.y * 0.06),
				box.y * 0.17,
				(-PI * 0.5 if side > 0.0 else PI * 0.5) - PI * 0.45,
				(-PI * 0.5 if side > 0.0 else PI * 0.5) + PI * 0.45,
				18, trim, 3.0
			)
		"staff":
			draw_line(
				hand + Vector2(0.0, box.y * 0.18),
				hand + Vector2(0.0, -box.y * 0.40), trim, 4.0
			)
			draw_circle(hand + Vector2(0.0, -box.y * 0.42), box.x * 0.035, metal)

# --- Dört ayaklı ---

func _draw_beast(box: Vector2, archetype: Dictionary, bulk: float) -> void:
	var fur := _tint(archetype.cloth)
	var dark := _tint(archetype.trim)
	var tooth := _tint(archetype.metal)

	if _state == "downed" or _state == "dead":
		_draw_fallen(box, fur, dark, fur, bulk)
		return

	var side := 1.0 if _face_right else -1.0
	var ground := box.y * 0.95
	var body_h := box.y * 0.26 * bulk
	var body_w := box.x * 0.78 * bulk
	var body_y := ground - box.y * 0.20 - body_h * 0.5
	var cx := box.x * 0.5 - side * box.x * 0.04

	# Bacaklar: önce arka çift (koyu), sonra ön çift
	for index in 4:
		var front := index >= 2
		var offset := (0.30 if front else -0.28) * body_w
		var jitter := (0.05 if index % 2 == 0 else -0.05) * body_w
		var top := Vector2(cx + side * offset + jitter, body_y + body_h * 0.25)
		draw_line(
			top, Vector2(top.x + side * box.x * 0.02, ground),
			dark if not front else fur.darkened(0.12), box.x * 0.055 * bulk
		)

	# Gövde
	_draw_ellipse(Vector2(cx, body_y), Vector2(body_w * 0.5, body_h * 0.5), fur)

	# Kuyruk
	draw_line(
		Vector2(cx - side * body_w * 0.48, body_y - body_h * 0.1),
		Vector2(cx - side * body_w * 0.72, body_y - body_h * 0.55),
		dark, box.x * 0.035
	)

	# Baş + burun
	var head_c := Vector2(cx + side * body_w * 0.52, body_y - body_h * 0.32)
	var head_r := box.x * 0.115 * bulk
	_draw_ellipse(head_c, Vector2(head_r, head_r * 0.92), fur)
	_filled(_quad(
		head_c + Vector2(side * head_r * 0.5, -head_r * 0.15),
		head_c + Vector2(side * head_r * 1.7, head_r * 0.10),
		head_c + Vector2(side * head_r * 1.7, head_r * 0.45),
		head_c + Vector2(side * head_r * 0.5, head_r * 0.50)
	), fur.darkened(0.14))

	# Kulaklar
	for ear_side in [-1.0, 1.0]:
		_filled(_tri(
			head_c + Vector2(ear_side * head_r * 0.45, -head_r * 0.55),
			head_c + Vector2(ear_side * head_r * 0.75, -head_r * 1.35),
			head_c + Vector2(ear_side * head_r * 0.05, -head_r * 0.75)
		), dark)

	# Göz: tek bir parlak nokta - hayvanı "canlı" kılan en ucuz detay
	draw_circle(
		head_c + Vector2(side * head_r * 0.42, -head_r * 0.15),
		maxf(1.5, head_r * 0.13), Color(0.95, 0.86, 0.55, 0.9)
	)

	if String(archetype.head) == "tusks":
		for tusk_dir in [-1.0, 1.0]:
			draw_line(
				head_c + Vector2(side * head_r * 1.5, head_r * 0.35),
				head_c + Vector2(side * head_r * (1.5 + 0.35), head_r * (0.35 + tusk_dir * 0.5)),
				tooth, 2.5
			)
	else:
		# Diş sırası
		draw_line(
			head_c + Vector2(side * head_r * 1.15, head_r * 0.44),
			head_c + Vector2(side * head_r * 1.66, head_r * 0.40),
			tooth, 2.0
		)

# --- Çizim yardımcıları ---

func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, b, c, d])

func _tri(a: Vector2, b: Vector2, c: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, b, c])

func _filled(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)

## Dolgu + koyu kontur: "mürekkeplenmiş" silüet hissi bundan geliyor.
func _outlined(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, OUTLINE, 1.6)

func _draw_ellipse(centre: Vector2, radii: Vector2, color: Color) -> void:
	draw_colored_polygon(_ellipse_points(centre, radii), color)

func _draw_ellipse_outline(centre: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var points := _ellipse_points(centre, radii)
	points.append(points[0])
	draw_polyline(points, color, width)

func _ellipse_points(centre: Vector2, radii: Vector2, steps: int = 22) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in steps:
		var angle := TAU * float(index) / float(steps)
		points.append(centre + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points

## Başlığın üst kavisi - miğfer/saç için yarım elips.
func _draw_arc_cap(centre: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 15:
		var angle := PI + PI * float(index) / 14.0
		points.append(centre + Vector2(cos(angle) * radius, sin(angle) * radius * 1.05))
	points.append(centre + Vector2(radius, 0.0))
	points.append(centre + Vector2(-radius, 0.0))
	draw_colored_polygon(points, color)
