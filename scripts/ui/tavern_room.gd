class_name TavernRoom
extends Control

## Canlı taverna (görev 9.4, kullanıcı isteği 2026-10-19): oda resmi bir kez
## render edilir (tools/ui_scenes/tavern_scene.py); içindeki insanlar oyunun
## kendi figürleri (`WalkFigure`, aynı iskelet ve giysi katmanları), ateş,
## mum ve fener her karede canlı çizilir. Tezgâhçı bardak siler, garson tepsiyle
## masaları dolaşır, ozan lut çalar ve nota yükselir, masadakiler ara sıra
## bardak kaldırır. Bir kişiye tıklamak (ya da "Sohbete başla" modunda üstüne
## gelmek) `person_chosen` gönderir: sohbetin kendisi tavern.gd'de, sistem
## N34'ün işi. Yerler `TavernLayout.ANCHORS` (resimle birlikte üretilir).
## Reduce Motion açıkken yürüme, bardak ve ozan durur; alev yalnız sabit çizilir.

signal person_chosen(character: CharacterData, role: String)

const BACKGROUND: String = "res://data/assets/ui/towns/tavern/background.jpg"
const ASPECT: float = 16.0 / 9.0
## Bir figürün kutusunda kişinin boyu kutunun bu payı (bkz. FigurePreview).
const PERSON_SHARE: float = 0.86
const WALK_SECONDS: float = 7.0
const PAUSE_SECONDS: float = 2.2
const DRINK_PERIOD: float = 6.0
const DRINK_SECONDS: float = 1.6
const NOTE_PERIOD: float = 1.1

const ROLE_BARTENDER: String = "bartender"
const ROLE_WAITRESS: String = "waitress"
const ROLE_BARD: String = "bard"
const ROLE_PATRON: String = "patron"
const VILLAGER: String = "villager"

## Giysi takımları: [gömlek, pantolon, ayakkabı, ceket, şapka]; var olmayan
## parça atlanır (OutfitCatalog.get_piece).
const MALE_OUTFITS: Array = [
	["peasant_shirt", "peasant_pants", "peasant_shoes", "", ""],
	["linen_tunic", "wool_pants", "short_boots", "leather_vest", "felt_hat"],
	["laced_shirt", "cloth_trousers", "leather_boots", "wool_coat", ""],
]
const FEMALE_OUTFITS: Array = [
	["peasant_blouse", "long_skirt", "peasant_shoes", "", ""],
	["peasant_blouse", "tiered_skirt", "womens_ankle_boots", "", "head_veil"],
	["peasant_blouse", "pinafore_dress", "felt_shoes", "", ""],
]
const SEATS: Array[String] = ["seat_a1", "seat_a2", "seat_b1", "seat_b2", "seat_c1", "seat_c2"]
const SEAT_TABLE: Dictionary = {
	"seat_a1": "table_a", "seat_a2": "table_a", "seat_b1": "table_b", "seat_b2": "table_b",
	"seat_c1": "table_c", "seat_c2": "table_c",
}

var _plate: TextureRect
var _back_fx: Control
var _front_fx: Control
var _actor_layer: Control
var _actors: Array[Dictionary] = []
var _clock: float = 0.0
var _plate_rect: Rect2 = Rect2()
var _hovered: int = -1
var _chat_mode: bool = false
var _seed: int = 1

func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_plate = TextureRect.new()
	_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_plate.stretch_mode = TextureRect.STRETCH_SCALE
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)
	_back_fx = _FxLayer.new(self, false)
	add_child(_back_fx)
	_actor_layer = Control.new()
	_actor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_actor_layer)
	_front_fx = _FxLayer.new(self, true)
	add_child(_front_fx)
	resized.connect(_layout)
	mouse_exited.connect(func() -> void: _hovered = -1)

## Kişileri günün tohumundan kurar (aynı gün aynı kalabalık).
func populate(location_id: String, day: int) -> void:
	_seed = hash("%s|%d" % [location_id, day])
	_plate.texture = TextureLoader.load_any(BACKGROUND)
	for actor in _actors:
		(actor.clip as Node).queue_free()
	_actors.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	_add_actor(ROLE_BARTENDER, "bartender", CharacterData.GENDER_MALE, CharacterData.BODY_WEIGHT_HEAVY, rng, "counter_top")
	_add_actor(ROLE_WAITRESS, "waitress_left", CharacterData.GENDER_FEMALE, CharacterData.BODY_WEIGHT_LEAN, rng, "")
	_add_actor(ROLE_BARD, "bard", CharacterData.GENDER_MALE, CharacterData.BODY_WEIGHT_LEAN, rng, "")
	var seats := SEATS.duplicate()
	for i in range(seats.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = seats[i]
		seats[i] = seats[j]
		seats[j] = tmp
	var occupied := rng.randi_range(4, 6)
	for k in occupied:
		var gender := CharacterData.GENDER_MALE if rng.randf() < 0.6 else CharacterData.GENDER_FEMALE
		_add_actor(ROLE_PATRON, String(seats[k]), gender, rng.randi_range(0, 2), rng, SEAT_TABLE[seats[k]])
	_layout()
	set_process(true)

func set_chat_mode(on: bool) -> void:
	_chat_mode = on
	if not on:
		_hovered = -1
	_front_fx.queue_redraw()

func is_chat_mode() -> bool:
	return _chat_mode

func get_actor_count() -> int:
	return _actors.size()

## Bir kişinin (sohbet balonu için) figür kutusu.
func figure_of(index: int) -> Control:
	return _actors[index].figure if index >= 0 and index < _actors.size() else null

func character_of(index: int) -> CharacterData:
	return _actors[index].character if index >= 0 and index < _actors.size() else null

func _add_actor(role: String, anchor: String, gender: int, weight: int, rng: RandomNumberGenerator, cut_at: String) -> void:
	var cultures := CultureCatalog.get_cultures()
	var culture = cultures[rng.randi_range(0, cultures.size() - 1)]
	var pool: Array = culture.name_pool
	var name_text := String(pool[rng.randi_range(0, pool.size() - 1)]) if not pool.is_empty() else "Yolcu"
	var character := CharacterData.create(
		name_text, culture.culture_id, CharacterStats.new(), rng.randi_range(158, 184),
		rng.randi_range(0, 3), ClassCatalog.GUARD, gender, weight
	)
	character.character_id = "tv_%d_%s" % [_seed, anchor]
	character.backstory_id = CharacterData.backstory_for_id(character.character_id)
	var sets: Array = MALE_OUTFITS if gender == CharacterData.GENDER_MALE else FEMALE_OUTFITS
	var slots := [OutfitCatalog.SLOT_SHIRT, OutfitCatalog.SLOT_PANTS, OutfitCatalog.SLOT_SHOES, OutfitCatalog.SLOT_JACKET, OutfitCatalog.SLOT_HAT]
	var picked: Array = sets[rng.randi_range(0, sets.size() - 1)]
	for i in slots.size():
		var piece := String(picked[i])
		if not piece.is_empty() and OutfitCatalog.get_piece(piece) != null:
			character.set_outfit_piece(slots[i], piece)
	var clip := Control.new()
	clip.clip_contents = not cut_at.is_empty()
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actor_layer.add_child(clip)
	var figure := WalkFigure.new()
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(figure)
	figure.set_kind(
		WalkFigure.KIND_PERSON, VILLAGER, character.get_height_scale(),
		CharacterData.get_skin_tone_color(character.skin_tone), false, character.get_appearance_outfit(),
		character.get_body_variant_id()
	)
	figure.set_loadout(Wardrobe.loadout_of(character.outfit, character.equipped))
	figure.set_standing()
	# Odanın sıcak ışığına uysun: figürler hafifçe kehribara çekilir.
	figure.set_tint(Color(0.92, 0.80, 0.68))
	_actors.append({
		"role": role, "anchor": anchor, "cut_at": cut_at, "character": character, "figure": figure, "clip": clip,
		"phase": rng.randf() * 10.0, "facing": 1.0, "rect": Rect2(), "walk_u": rng.randf(),
	})

# --- yerleşim ---

func _layout() -> void:
	var fit := minf(size.x, size.y * ASPECT)
	_plate_rect = Rect2((size - Vector2(fit, fit / ASPECT)) * 0.5, Vector2(fit, fit / ASPECT))
	_plate.position = _plate_rect.position
	_plate.size = _plate_rect.size
	for layer in [_back_fx, _front_fx]:
		layer.position = Vector2.ZERO
		layer.size = size
	_actor_layer.position = Vector2.ZERO
	_actor_layer.size = size
	_place_actors()

## Plaka payı (0-1) -> bu kontrolün pikseli.
func at(anchor: String) -> Vector2:
	var a: Dictionary = TavernLayout.ANCHORS.get(anchor, {"x": 0.5, "y": 0.5})
	return _plate_rect.position + Vector2(float(a.x) * _plate_rect.size.x, float(a.y) * _plate_rect.size.y)

func person_px(anchor: String) -> float:
	var a: Dictionary = TavernLayout.ANCHORS.get(anchor, {"person_h": 0.15})
	return float(a.person_h) * _plate_rect.size.y

func _place_actors() -> void:
	for actor in _actors:
		var foot := _foot_of(actor)
		var h := person_px(String(actor.anchor)) / PERSON_SHARE
		var figure: WalkFigure = actor.figure
		figure.size = Vector2(h * 0.9, h)
		var clip: Control = actor.clip
		var cut := String(actor.cut_at)
		if cut.is_empty():
			clip.position = foot - Vector2(h * 0.45, h)
			clip.size = figure.size
			figure.position = Vector2.ZERO
		else:
			# Masa ya da tezgâh figürün alt yarısını örter: kutu masa üstünde kesilir.
			var table_y := at(cut).y
			clip.position = Vector2(foot.x - h * 0.45, foot.y - h)
			clip.size = Vector2(h * 0.9, maxf(1.0, table_y - (foot.y - h)))
			figure.position = Vector2.ZERO
		actor.rect = Rect2(Vector2(foot.x - h * 0.3, foot.y - h * PERSON_SHARE), Vector2(h * 0.6, h * PERSON_SHARE))
	_front_fx.queue_redraw()

func _foot_of(actor: Dictionary) -> Vector2:
	if actor.role == ROLE_WAITRESS:
		return _waitress_foot(actor)
	return at(String(actor.anchor))

## Garsonun yürüyüşü: iki uç arasında gidip gelir, uçlarda durur.
static func walk_progress(u: float) -> Vector3:
	# u 0..1 bir tur: ileri, bekle, geri, bekle. (ilerleme 0..1, yön, duruyor mu)
	var move := WALK_SECONDS
	var total := 2.0 * (move + PAUSE_SECONDS)
	var t := fposmod(u, 1.0) * total
	if t < move:
		return Vector3(t / move, 1.0, 0.0)
	t -= move
	if t < PAUSE_SECONDS:
		return Vector3(1.0, 1.0, 1.0)
	t -= PAUSE_SECONDS
	if t < move:
		return Vector3(1.0 - t / move, -1.0, 0.0)
	return Vector3(0.0, -1.0, 1.0)

func _waitress_foot(actor: Dictionary) -> Vector2:
	var prog := walk_progress(float(actor.walk_u))
	return at("waitress_left").lerp(at("waitress_right"), clampf(prog.x, 0.0, 1.0))

# --- canlandırma ---

func _process(delta: float) -> void:
	var still := NodeUtil.reduce_motion(self)
	_clock += delta
	for actor in _actors:
		var figure: WalkFigure = actor.figure
		if actor.role == ROLE_WAITRESS and not still:
			var total := 2.0 * (WALK_SECONDS + PAUSE_SECONDS)
			actor.walk_u = fposmod(float(actor.walk_u) + delta / total, 1.0)
			var prog := walk_progress(float(actor.walk_u))
			figure.set_facing(prog.y)
			if prog.z > 0.5:
				figure.advance(delta, 0.0)
			else:
				var span := at("waitress_right").x - at("waitress_left").x
				figure.advance_ground(delta, prog.y * span / WALK_SECONDS)
		else:
			figure.advance(delta, 0.0)
	_place_actors()
	_back_fx.queue_redraw()
	_front_fx.queue_redraw()

# --- girdi ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hit := _actor_at(event.position)
		if hit != _hovered:
			_hovered = hit
			_front_fx.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit := _actor_at(event.position)
		if hit >= 0:
			person_chosen.emit(_actors[hit].character, String(_actors[hit].role))

func _actor_at(point: Vector2) -> int:
	# Öndeki önce: aşağıdaki (ayağı daha aşağıda) kişi üstte çizilir.
	var best := -1
	var best_foot := -1.0e9
	for i in _actors.size():
		var rect: Rect2 = _actors[i].rect
		if rect.has_point(point) and rect.end.y > best_foot:
			best = i
			best_foot = rect.end.y
	return best

## Ateş, mum ve fener için: titremenin saf fonksiyonu.
static func flicker(t: float, seed_offset: float) -> float:
	return 0.78 + 0.14 * sin(t * 7.3 + seed_offset) + 0.08 * sin(t * 13.1 + seed_offset * 1.7)

## Bardağın yüksekliği (0 masada, 1 ağız hizasında): bir içiş döngüsü.
static func drink_lift(t: float, phase: float) -> float:
	var local := fposmod(t + phase, DRINK_PERIOD)
	if local >= DRINK_SECONDS:
		return 0.0
	var u := local / DRINK_SECONDS
	# Kalk, ağız hizasında bekle, in: yumuşak bir zarf.
	return smoothstep(0.0, 1.0, minf(1.0, minf(u / 0.35, (1.0 - u) / 0.35)))

# --- canlı çizim katmanları ---

class _FxLayer extends Control:
	var room: TavernRoom
	var front: bool

	func _init(owner_room: TavernRoom, is_front: bool) -> void:
		room = owner_room
		front = is_front
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if front:
			room._draw_front(self)
		else:
			room._draw_back(self)

func _draw_back(c: Control) -> void:
	var t := _clock
	var moving := not NodeUtil.reduce_motion(self)
	var fire := at("fire")
	var unit := _plate_rect.size.y
	# Ateşin ışığı: ocağın çevresinde nefes alan bir hale.
	var glow := flicker(t if moving else 0.0, 0.0)
	for i in 4:
		var r := unit * (0.10 + 0.07 * float(i)) * (0.9 + 0.2 * glow)
		c.draw_circle(fire + Vector2(0, -unit * 0.02), r, Color(1.0, 0.55, 0.2, 0.05 + 0.02 * float(3 - i)))
	# Alevler: yedi dil, her biri kendi hızında dalgalanan eğri kenarlı damla.
	var phase_t := t if moving else 0.0
	for k in 7:
		var seed_offset := float(k) * 1.9
		var w := unit * (0.026 + 0.007 * float(k % 3))
		var h := unit * (0.070 + 0.034 * flicker(phase_t, seed_offset)) * (1.0 - 0.18 * absf(float(k) - 3.0) / 3.0)
		var x := fire.x + (float(k) - 3.0) * unit * 0.0135
		var sway := sin(phase_t * 5.0 + seed_offset) * unit * 0.007
		var base := Vector2(x, fire.y + unit * 0.014)
		c.draw_colored_polygon(_flame_shape(base, w, h, sway), Color(1.0, 0.42 + 0.12 * float(k % 2), 0.10, 0.92))
		c.draw_colored_polygon(_flame_shape(base, w * 0.62, h * 0.72, sway * 0.7), Color(1.0, 0.72, 0.28, 0.95))
		c.draw_colored_polygon(_flame_shape(base, w * 0.30, h * 0.42, sway * 0.4), Color(1.0, 0.94, 0.66, 0.95))
	# Kıvılcımlar: yukarı süzülür, söner.
	if moving:
		for s in 7:
			var life := fposmod(t * 0.55 + float(s) * 0.37, 1.0)
			var sx := fire.x + sin(float(s) * 4.1 + t * 0.9) * unit * 0.035
			var sy := fire.y - life * unit * 0.20
			c.draw_circle(Vector2(sx, sy), unit * 0.0025, Color(1.0, 0.7, 0.3, (1.0 - life) * 0.9))
	# Mumlar ve fenerler
	for key in ["candle_a", "candle_b", "candle_c"]:
		_draw_flame(c, at(key), unit * 0.012, t, key.hash() % 7)
	for key in ["lantern_l", "lantern_r"]:
		var p := at(key)
		var f := flicker(t if moving else 0.0, float(key.hash() % 5))
		for i in 3:
			c.draw_circle(p, unit * (0.05 + 0.035 * float(i)) * f, Color(1.0, 0.7, 0.35, 0.05 + 0.025 * float(2 - i)))

## Alev damlası: tabanda geniş, uca doğru eğri daralır; uç `sway` kadar yana kayar.
static func _flame_shape(base: Vector2, w: float, h: float, sway: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 8
	for i in range(steps + 1):
		var u := float(i) / float(steps)
		pts.append(base + Vector2(-w * (1.0 - pow(u, 1.6)) * (0.35 + 0.65 * sin(u * PI * 0.5 + 0.8)) + sway * u * u, -h * u))
	for i in range(steps, -1, -1):
		var u := float(i) / float(steps)
		pts.append(base + Vector2(w * (1.0 - pow(u, 1.6)) * (0.35 + 0.65 * sin(u * PI * 0.5 + 0.8)) + sway * u * u, -h * u))
	return pts

func _draw_flame(c: Control, p: Vector2, size_px: float, t: float, seed_offset: int) -> void:
	var f := flicker(t if not NodeUtil.reduce_motion(self) else 0.0, float(seed_offset))
	var pts := PackedVector2Array([p + Vector2(-size_px * 0.6, 0), p + Vector2(0, -size_px * 2.2 * f), p + Vector2(size_px * 0.6, 0)])
	c.draw_circle(p + Vector2(0, -size_px * 0.8), size_px * 3.0 * f, Color(1.0, 0.7, 0.3, 0.10))
	c.draw_colored_polygon(pts, Color(1.0, 0.8, 0.35, 0.95))

func _draw_front(c: Control) -> void:
	var t := _clock
	var moving := not NodeUtil.reduce_motion(self)
	var unit := _plate_rect.size.y
	for i in _actors.size():
		var actor: Dictionary = _actors[i]
		var rect: Rect2 = actor.rect
		match String(actor.role):
			ROLE_BARTENDER:
				# Tezgâhta bir bardak ve bez: sağa sola siliniyor.
				var top := at("counter_top")
				var wipe := sin((t if moving else 0.0) * 1.6) * unit * 0.03
				_draw_mug(c, Vector2(top.x + wipe + unit * 0.05, top.y), unit * 0.014)
			ROLE_WAITRESS:
				# Tepsi: belin önünde, üstünde iki bardak.
				var tray := Vector2(rect.position.x + rect.size.x * (0.5 + 0.35 * float(actor.figure.get_facing())), rect.position.y + rect.size.y * 0.52)
				c.draw_rect(Rect2(tray + Vector2(-unit * 0.034, 0), Vector2(unit * 0.068, unit * 0.005)), Color(0.62, 0.46, 0.22))
				_draw_mug(c, tray + Vector2(-unit * 0.014, 0), unit * 0.011)
				_draw_mug(c, tray + Vector2(unit * 0.014, 0), unit * 0.011)
			ROLE_BARD:
				_draw_lute(c, actor, unit, t if moving else 0.0)
			ROLE_PATRON:
				var table := at(String(SEAT_TABLE[actor.anchor]))
				var lift := drink_lift(t if moving else 0.0, float(actor.phase)) if moving else 0.0
				var rest := Vector2(rect.position.x + rect.size.x * 0.5 + unit * 0.035, table.y + unit * 0.004)
				var mouth := Vector2(rect.position.x + rect.size.x * 0.55, rect.position.y + rect.size.y * 0.16)
				_draw_mug(c, rest.lerp(mouth, lift), unit * 0.012)
		if _hovered == i:
			_draw_name(c, actor, rect)
	if _chat_mode:
		for i in _actors.size():
			var rect: Rect2 = _actors[i].rect
			var ring := Rect2(Vector2(rect.position.x + rect.size.x * 0.1, rect.end.y - unit * 0.012), Vector2(rect.size.x * 0.8, unit * 0.022))
			c.draw_arc(ring.get_center(), ring.size.x * 0.5, 0.0, TAU, 28, Color(0.93, 0.66, 0.32, 0.9 if _hovered == i else 0.45), 2.0)

func _draw_mug(c: Control, p: Vector2, s: float) -> void:
	c.draw_rect(Rect2(p + Vector2(-s, -s * 1.6), Vector2(s * 2.0, s * 1.6)), Color(0.55, 0.38, 0.2))
	c.draw_rect(Rect2(p + Vector2(-s, -s * 1.6), Vector2(s * 2.0, s * 1.6)), Color(0.05, 0.04, 0.04), false, 1.5)
	c.draw_rect(Rect2(p + Vector2(-s * 0.9, -s * 1.7), Vector2(s * 1.8, s * 0.4)), Color(0.95, 0.9, 0.75))
	c.draw_arc(p + Vector2(s * 1.1, -s * 0.8), s * 0.6, -PI * 0.5, PI * 0.5, 8, Color(0.05, 0.04, 0.04), 1.5)

func _draw_lute(c: Control, actor: Dictionary, unit: float, t: float) -> void:
	var rect: Rect2 = actor.rect
	var centre := Vector2(rect.position.x + rect.size.x * 0.52, rect.position.y + rect.size.y * 0.52)
	var strum := sin(t * 5.0) * 0.06
	c.draw_set_transform(centre, -0.5 + strum, Vector2.ONE)
	var s := unit * 0.021
	c.draw_circle(Vector2.ZERO, s, Color(0.55, 0.36, 0.18))
	c.draw_arc(Vector2.ZERO, s, 0.0, TAU, 20, Color(0.05, 0.04, 0.04), 2.0)
	c.draw_circle(Vector2.ZERO, s * 0.28, Color(0.08, 0.05, 0.03))
	c.draw_rect(Rect2(Vector2(s * 0.7, -s * 0.12), Vector2(s * 1.9, s * 0.24)), Color(0.35, 0.22, 0.10))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Notalar: lutun üstünden yükselir, kaybolur; glif değil, çizilmiş (UiIcon kuralı).
	if t > 0.0:
		for k in 3:
			var life := fposmod(t / NOTE_PERIOD * 0.5 + float(k) / 3.0, 1.0)
			var np := centre + Vector2(unit * 0.03 + sin(life * 6.0 + float(k)) * unit * 0.012, -unit * 0.05 - life * unit * 0.14)
			var a := (1.0 - life) * 0.85
			c.draw_circle(np, unit * 0.0075, Color(0.95, 0.88, 0.7, a))
			c.draw_line(np + Vector2(unit * 0.0065, 0), np + Vector2(unit * 0.0065, -unit * 0.028), Color(0.95, 0.88, 0.7, a), 1.5)

func _draw_name(c: Control, actor: Dictionary, rect: Rect2) -> void:
	var character: CharacterData = actor.character
	var font := ThemeDB.fallback_font
	var text := character.character_name
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
	var at_point := Vector2(rect.position.x + rect.size.x * 0.5 - width * 0.5, rect.position.y - 8.0)
	c.draw_rect(Rect2(at_point + Vector2(-6, -17), Vector2(width + 12, 22)), Color(0.04, 0.03, 0.03, 0.8))
	c.draw_string(font, at_point, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, ArtPalette.UI_TEXT)
