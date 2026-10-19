class_name TavernRoom
extends Control

## Canlı taverna (görev 9.4, kullanıcı isteği 2026-10-19): oda resmi bir kez
## render edilir (tools/ui_scenes/tavern_scene.py); içindeki insanlar oyunun
## kendi figürleri (`WalkFigure`, aynı iskelet ve giysi katmanları), ateş,
## mum ve fener her karede canlı çizilir.
##
## Kullanıcı notu: "mankenler canlı olmalı, önceden belirlenen rotasyonlarda
## hareketli ve rolleri olmalı". Her kişinin bir rotası var (`legs`: varılacak
## yer, orada ne kadar durduğu, durduğu yerde neyin arkasında kaldığı, ne
## yaptığı) ve rota döner:
## - meyhaneci tezgâhın arkasında siler, fıçıya gidip bardak doldurur, döner;
## - yardımcı tezgâhtan tepsiyi alır, masaları dolaşır, boş tepsiyle döner;
## - ozan şöminenin bir yanında çalar, sonra öbür yanına geçer;
## - konuklar masada içer; bir konuk kapıdan girer, boş yere oturur, bir süre
##   sonra kalkıp çıkar ve yerine başka biri gelir.
## Bir kişiye tıklamak (ya da "Sohbete başla" modunda üstüne gelmek)
## `person_chosen` gönderir: sohbetin kendisi tavern.gd'de, sistem N34'ün işi.
## Yerler `TavernLayout.ANCHORS` (resimle birlikte üretilir). Oda, bulunduğu
## alanı tam genişlikte örter (yanlar kırpılmaz, üst ve alt odağın çevresinden).
## Reduce Motion açıkken herkes yerinde durur; alev yalnız sabit çizilir.

signal person_chosen(character: CharacterData, role: String)

const BACKGROUND: String = "res://data/assets/ui/towns/tavern/background.jpg"
const ASPECT: float = 16.0 / 9.0
## Bir figürün kutusunda kişinin boyu kutunun bu payı (bkz. FigurePreview).
const PERSON_SHARE: float = 0.86
## Odanın dikey odağı (resim payı): alanın ortasına bu yükseklik gelir.
const FOCUS_Y: float = 0.47
## Yürüme hızı: saniyede boyunun bu payı kadar yol (sakin bir iç mekân yürüyüşü).
const WALK_BODIES_PER_SECOND: float = 0.55
const DRINK_PERIOD: float = 6.0
const DRINK_SECONDS: float = 1.6
const NOTE_PERIOD: float = 1.1
## Oturan kişi bankta: ayakta duran figür boyunun bu payı kadar aşağı iner,
## masa alt yarısını örttüğü için baş ve omuz oturan birinin yerinde kalır.
const SIT_DROP: float = 0.26
## Ozanın çalma duruşu ve o duruşta ellerin yeri (boyun yüzdesi, FigureActions).
const BARD_CLIP: String = "stance_melee"

const ROLE_BARTENDER: String = "bartender"
const ROLE_WAITRESS: String = "waitress"
const ROLE_BARD: String = "bard"
const ROLE_PATRON: String = "patron"
const ROLE_VISITOR: String = "visitor"
const ROLE_LABEL_KEYS: Dictionary = {
	ROLE_BARTENDER: "UI_TAVERN_ROLE_BARTENDER",
	ROLE_WAITRESS: "UI_TAVERN_ROLE_HELPER",
	ROLE_BARD: "UI_TAVERN_ROLE_BARD",
	ROLE_PATRON: "UI_TAVERN_ROLE_GUEST",
	ROLE_VISITOR: "UI_TAVERN_ROLE_GUEST",
}
const VILLAGER: String = "villager"

## Giysi takımları: [gömlek, pantolon, ayakkabı, ceket, şapka]; var olmayan
## parça atlanır (OutfitCatalog.get_piece).
const MALE_OUTFITS: Array = [
	["peasant_shirt", "peasant_pants", "peasant_shoes", "", ""],
	["linen_tunic", "wool_pants", "short_boots", "leather_vest", "felt_hat"],
	["laced_shirt", "cloth_trousers", "leather_boots", "wool_coat", ""],
	["fisherman_sweater", "viking_pants", "hobnail_boots", "", "knit_cap"],
	["quilted_tunic", "ranger_pants", "riding_boots", "", "wide_hat"],
]
const FEMALE_OUTFITS: Array = [
	["peasant_blouse", "long_skirt", "peasant_shoes", "", ""],
	["peasant_blouse", "tiered_skirt", "womens_ankle_boots", "", "head_veil"],
	["peasant_blouse", "pinafore_dress", "felt_shoes", "", ""],
	["bodice_top", "long_skirt", "womens_knee_boots", "", ""],
]
const SEATS: Array[String] = ["seat_a1", "seat_a2", "seat_b1", "seat_b2", "seat_c1", "seat_c2"]
const SEAT_TABLE: Dictionary = {
	"seat_a1": "table_a", "seat_a2": "table_a", "seat_b1": "table_b", "seat_b2": "table_b",
	"seat_c1": "table_c", "seat_c2": "table_c",
}
## Gelip giden konuğun oturabileceği yerler: koridora inen yolu başka bir
## masayı kesmeyen ön masalar.
const VISITOR_SEATS: Array[String] = ["seat_a1", "seat_a2", "seat_b1", "seat_b2"]

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
var _rng := RandomNumberGenerator.new()
## Yardımcının tepsisi dolu mu (tezgâhtan aldı, henüz dağıtmadı).
var _tray_full: bool = false
## Meyhanecinin doldurduğu bardak tezgâhta bekliyor mu.
var _counter_mug: bool = false

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

## Kişileri ve rotalarını günün tohumundan kurar (aynı gün aynı kalabalık).
func populate(location_id: String, day: int) -> void:
	_seed = hash("%s|%d" % [location_id, day])
	_plate.texture = TextureLoader.load_any(BACKGROUND)
	for actor in _actors:
		(actor.clip as Node).queue_free()
	_actors.clear()
	_rng.seed = _seed
	var bar := anchor_share("bartender")
	var pour := anchor_share("bar_pour")
	_add_actor(ROLE_BARTENDER, CharacterData.GENDER_MALE, CharacterData.BODY_WEIGHT_HEAVY, bar, [
		{"to": bar, "pause": 6.0, "cut": "counter_top", "act": "wipe"},
		{"to": pour, "pause": 4.0, "cut": "counter_top", "act": "pour"},
	])
	var pickup := anchor_share("pickup")
	_add_actor(ROLE_WAITRESS, CharacterData.GENDER_FEMALE, CharacterData.BODY_WEIGHT_LEAN, pickup, [
		{"to": pickup, "pause": 3.0, "cut": "", "act": "load"},
		{"to": anchor_share("serve_a"), "pause": 2.5, "cut": "", "act": "serve"},
		{"to": anchor_share("serve_b"), "pause": 2.5, "cut": "", "act": "serve_last"},
	])
	var stage_l := anchor_share("bard")
	var stage_r := anchor_share("bard_right")
	_add_actor(ROLE_BARD, CharacterData.GENDER_MALE, CharacterData.BODY_WEIGHT_LEAN, stage_l, [
		{"to": stage_l, "pause": 24.0, "cut": "", "act": "play"},
		{"to": stage_r, "pause": 24.0, "cut": "", "act": "play"},
	])
	# Gelip giden konuğun yerleri boş kalır; kalan her yerde biri oturur.
	var free_seats: Array[String] = []
	var pool: Array[String] = VISITOR_SEATS.duplicate()
	for k in _rng.randi_range(1, 2):
		var pick: String = pool[_rng.randi_range(0, pool.size() - 1)]
		pool.erase(pick)
		free_seats.append(pick)
	for seat in SEATS:
		if free_seats.has(seat):
			continue
		var gender := CharacterData.GENDER_MALE if _rng.randf() < 0.6 else CharacterData.GENDER_FEMALE
		_add_actor(ROLE_PATRON, gender, _rng.randi_range(0, 2), anchor_share(seat), [
			{"to": anchor_share(seat), "pause": 1.0e9, "cut": String(SEAT_TABLE[seat]), "act": "drink"},
		])
	var visitor_legs: Array = []
	var door := anchor_share("door")
	for seat in free_seats:
		# Masaların arkasındaki koridordan: kapı -> koridor -> bank -> koridor -> kapı.
		var aisle := anchor_share(seat.replace("seat_", "aisle_"))
		visitor_legs.append({"to": aisle, "pause": 0.0, "cut": "", "act": ""})
		visitor_legs.append({"to": anchor_share(seat), "pause": 26.0, "cut": String(SEAT_TABLE[seat]), "act": "drink"})
		visitor_legs.append({"to": aisle, "pause": 0.0, "cut": "", "act": ""})
		visitor_legs.append({"to": door, "pause": 8.0, "cut": "", "act": "gone"})
	var visitor_gender := CharacterData.GENDER_MALE if _rng.randf() < 0.5 else CharacterData.GENDER_FEMALE
	_add_actor(ROLE_VISITOR, visitor_gender, _rng.randi_range(0, 2), door, visitor_legs)
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

func role_of(index: int) -> String:
	return String(_actors[index].role) if index >= 0 and index < _actors.size() else ""

## Kişinin resimdeki yeri (pay); testler rotanın gerçekten yürüdüğünü okur.
func position_of(index: int) -> Vector2:
	return _actors[index].pos if index >= 0 and index < _actors.size() else Vector2.ZERO

## Rotayı `seconds` kadar ileri sarar (testler ve ekran görüntüsü için; ekran
## her karede aynı adımı atar).
func simulate(seconds: float, step: float = 0.1) -> void:
	var left := seconds
	while left > 0.0:
		var dt := minf(step, left)
		for actor in _actors:
			_advance_route(actor, dt)
		left -= dt
	_clock += seconds
	_place_actors()

func anchor_share(anchor: String) -> Vector2:
	var a: Dictionary = TavernLayout.ANCHORS.get(anchor, {"x": 0.5, "y": 0.5})
	return Vector2(float(a.x), float(a.y))

func _make_character(gender: int, weight: int, tag: String) -> CharacterData:
	var cultures := CultureCatalog.get_cultures()
	var culture = cultures[_rng.randi_range(0, cultures.size() - 1)]
	var names: Array = culture.name_pool
	var name_text := String(names[_rng.randi_range(0, names.size() - 1)]) if not names.is_empty() else "Yolcu"
	var character := CharacterData.create(
		name_text, culture.culture_id, CharacterStats.new(), _rng.randi_range(158, 186),
		_rng.randi_range(0, 3), ClassCatalog.GUARD, gender, weight
	)
	character.character_id = "tv_%d_%s" % [_seed, tag]
	character.backstory_id = CharacterData.backstory_for_id(character.character_id)
	var sets: Array = MALE_OUTFITS if gender == CharacterData.GENDER_MALE else FEMALE_OUTFITS
	var slots := [OutfitCatalog.SLOT_SHIRT, OutfitCatalog.SLOT_PANTS, OutfitCatalog.SLOT_SHOES, OutfitCatalog.SLOT_JACKET, OutfitCatalog.SLOT_HAT]
	var picked: Array = sets[_rng.randi_range(0, sets.size() - 1)]
	for i in slots.size():
		var piece := String(picked[i])
		if not piece.is_empty() and OutfitCatalog.get_piece(piece) != null:
			character.set_outfit_piece(slots[i], piece)
	return character

func _dress(figure: WalkFigure, character: CharacterData) -> void:
	figure.set_kind(
		WalkFigure.KIND_PERSON, VILLAGER, character.get_height_scale(),
		CharacterData.get_skin_tone_color(character.skin_tone), false, character.get_appearance_outfit(),
		character.get_body_variant_id()
	)
	figure.set_loadout(Wardrobe.loadout_of(character.outfit, character.equipped))
	figure.set_standing()
	# Odanın loş, sıcak ışığına uysun: figürler kehribara ve gölgeye çekilir.
	figure.set_tint(Color(0.74, 0.60, 0.48))

func _add_actor(role: String, gender: int, weight: int, start: Vector2, legs: Array) -> void:
	var character := _make_character(gender, weight, "%s%d" % [role, _actors.size()])
	var clip := Control.new()
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actor_layer.add_child(clip)
	var figure := WalkFigure.new()
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(figure)
	_dress(figure, character)
	var actor := {
		"role": role, "character": character, "figure": figure, "clip": clip,
		"pos": start, "legs": legs, "leg": 0, "wait": 0.0, "cut": "", "act": "",
		"phase": _rng.randf() * 10.0, "rect": Rect2(), "walking": true,
	}
	var first: Dictionary = legs[0]
	if start.distance_to(first.to) < 0.001:
		_arrive(actor, first)
		# Herkes rotasının başka bir anında başlasın: aynı anda kalkmasınlar.
		actor.wait = float(first.pause) * _rng.randf()
	elif role == ROLE_BARTENDER:
		actor.cut = "counter_top"
	_actors.append(actor)

# --- yerleşim ---

## Odayı alanın tamamına yayar: genişlik tam, fazla yükseklik odağın
## çevresinden kırpılır (alan resimden geniş kalırsa yükseklik tam olur).
static func cover_rect(area: Vector2, aspect: float, focus_y: float) -> Rect2:
	var w := area.x
	var h := w / aspect
	if h < area.y:
		h = area.y
		w = h * aspect
	var y := clampf(area.y * 0.5 - focus_y * h, area.y - h, 0.0)
	return Rect2(Vector2((area.x - w) * 0.5, y), Vector2(w, h))

## Derinlikte kişinin boyu (resim yüksekliğinin payı): arkadaki küçük, öndeki
## büyük. Doğru render'dan ölçülür (TavernLayout.DEPTH, düz zemin).
static func person_share_at(y: float) -> float:
	var d: Dictionary = TavernLayout.DEPTH
	return maxf(0.05, float(d.h0) + (y - float(d.y0)) * float(d.slope))

## Bir noktadan hedefe `dist` kadar yürür, hedefi aşmaz.
static func step_toward(from: Vector2, to: Vector2, dist: float) -> Vector2:
	var gap := to - from
	if gap.length() <= dist:
		return to
	return from + gap.normalized() * dist

func _layout() -> void:
	_plate_rect = cover_rect(size, ASPECT, FOCUS_Y)
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
	return share_px(anchor_share(anchor))

func share_px(share: Vector2) -> Vector2:
	return _plate_rect.position + share * _plate_rect.size

func person_px(anchor: String) -> float:
	var a: Dictionary = TavernLayout.ANCHORS.get(anchor, {"person_h": 0.15})
	return float(a.person_h) * _plate_rect.size.y

func _place_actors() -> void:
	if _plate_rect.size.y <= 0.0:
		return
	for actor in _actors:
		var foot := share_px(actor.pos)
		var h := person_share_at(actor.pos.y) * _plate_rect.size.y / PERSON_SHARE
		if String(actor.act) == "drink":
			foot.y += SIT_DROP * h * PERSON_SHARE
		var figure: WalkFigure = actor.figure
		figure.size = Vector2(h * 0.9, h)
		figure.position = Vector2.ZERO
		var clip: Control = actor.clip
		var cut := String(actor.cut)
		clip.position = foot - Vector2(h * 0.45, h)
		if cut.is_empty():
			clip.clip_contents = false
			clip.size = figure.size
		else:
			# Masa ya da tezgâh figürün alt yarısını örter: kutu masa üstünde kesilir.
			clip.clip_contents = true
			clip.size = Vector2(h * 0.9, maxf(1.0, at(cut).y - (foot.y - h)))
		clip.visible = String(actor.act) != "gone"
		actor.rect = Rect2(Vector2(foot.x - h * 0.3, foot.y - h * PERSON_SHARE), Vector2(h * 0.6, h * PERSON_SHARE))
	# Öndeki (ayağı aşağıda olan) sonra çizilir.
	var order := _actors.duplicate()
	order.sort_custom(func(a, b): return float(a.pos.y) < float(b.pos.y))
	for i in order.size():
		_actor_layer.move_child(order[i].clip, i)
	_front_fx.queue_redraw()

# --- rotalar ---

func _process(delta: float) -> void:
	var still := NodeUtil.reduce_motion(self)
	_clock += delta
	for actor in _actors:
		if still:
			(actor.figure as WalkFigure).advance(delta, 0.0)
		else:
			_advance_route(actor, delta)
	_place_actors()
	_back_fx.queue_redraw()
	_front_fx.queue_redraw()

func _advance_route(actor: Dictionary, delta: float) -> void:
	var figure: WalkFigure = actor.figure
	var legs: Array = actor.legs
	var leg: Dictionary = legs[int(actor.leg)]
	if bool(actor.walking):
		var plate_size := _plate_rect.size if _plate_rect.size.y > 0.0 else Vector2(1920.0, 1080.0)
		var speed_px := person_share_at(actor.pos.y) * plate_size.y * WALK_BODIES_PER_SECOND
		var target: Vector2 = leg.to
		# Yatay ve dikey payın piksel karşılığı farklı: adım pikselde ölçülür.
		var from_px: Vector2 = actor.pos * plate_size
		var to_px: Vector2 = target * plate_size
		var next_px := step_toward(from_px, to_px, speed_px * delta)
		var dx := next_px.x - from_px.x
		if absf(dx) > 0.01:
			figure.set_facing(signf(dx))
		figure.advance_ground(delta, speed_px)
		actor.pos = next_px / plate_size
		if next_px.distance_to(to_px) < 0.5:
			actor.pos = target
			_arrive(actor, leg)
		return
	figure.advance(delta, 0.0)
	actor.wait = float(actor.wait) - delta
	if float(actor.wait) > 0.0:
		return
	var was_gone := String(actor.act) == "gone"
	actor.leg = (int(actor.leg) + 1) % legs.size()
	var next: Dictionary = legs[int(actor.leg)]
	if was_gone:
		_redress_visitor(actor)
	actor.act = ""
	# Tezgâhın arkasındaki yürüyüş de tezgâhın arkasında kalır.
	actor.cut = "counter_top" if actor.role == ROLE_BARTENDER else ""
	if Vector2(actor.pos).distance_to(next.to) < 0.001:
		_arrive(actor, next)
	else:
		actor.walking = true
		# Yürürken lavta sırtta: çalma duruşu biter.
		figure.set_action("")

func _arrive(actor: Dictionary, leg: Dictionary) -> void:
	actor.walking = false
	actor.wait = float(leg.pause)
	actor.cut = String(leg.cut)
	actor.act = String(leg.act)
	match String(actor.act):
		"pour":
			_counter_mug = true
		"load":
			_tray_full = true
			_counter_mug = false
		"serve_last":
			_tray_full = false
	var figure: WalkFigure = actor.figure
	if actor.role == ROLE_BARD:
		figure.set_facing(1.0 if Vector2(actor.pos).x < 0.5 else -1.0)
		# Çalarken kollar önde: ön el sapı, arka el gövdeyi tutar (savaş
		# duruşunun kolları; elinde silah yok, villager arketipi).
		figure.set_action(BARD_CLIP if String(actor.act) == "play" else "")
	elif not String(actor.cut).is_empty() and actor.role != ROLE_BARTENDER:
		# Masada oturan masaya döner.
		var table_x := at_table_x(actor)
		figure.set_facing(1.0 if Vector2(actor.pos).x < table_x else -1.0)

func at_table_x(actor: Dictionary) -> float:
	return anchor_share(String(actor.cut)).x

## Kapıdan çıkan konuğun yerine başka biri gelir: yeni ad, yeni kılık.
func _redress_visitor(actor: Dictionary) -> void:
	var gender := CharacterData.GENDER_MALE if _rng.randf() < 0.55 else CharacterData.GENDER_FEMALE
	var character := _make_character(gender, _rng.randi_range(0, 2), "visitor%d" % _rng.randi())
	actor.character = character
	_dress(actor.figure, character)

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
		if String(_actors[i].act) == "gone":
			continue
		var rect: Rect2 = _actors[i].rect
		if rect.has_point(point) and rect.end.y > best_foot:
			best = i
			best_foot = rect.end.y
	return best

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
	if _counter_mug:
		_draw_mug(c, at("counter_top") + Vector2(unit * 0.11, 0), unit * 0.012)
	for i in _actors.size():
		var actor: Dictionary = _actors[i]
		if String(actor.act) == "gone":
			continue
		var rect: Rect2 = actor.rect
		# Bardak, tepsi: kişinin boyuna göre (bir bardak boyun ~%7'si).
		var s := person_share_at(actor.pos.y) * unit * 0.034
		match String(actor.role):
			ROLE_BARTENDER:
				var top := at("counter_top")
				var hand := Vector2(rect.position.x + rect.size.x * 0.5, top.y)
				if String(actor.act) == "wipe":
					# Bez: tezgâhta sağa sola.
					var wipe := sin((t if moving else 0.0) * 2.2) * unit * 0.02
					c.draw_rect(Rect2(hand + Vector2(wipe - s, -s * 0.5), Vector2(s * 2.2, s * 0.6)), Color(0.86, 0.82, 0.70))
				elif String(actor.act) == "pour":
					_draw_mug(c, hand + Vector2(s * 1.5, 0), s)
			ROLE_WAITRESS:
				# Tepsi: belin önünde; doluyken üstünde iki bardak.
				var facing := float((actor.figure as WalkFigure).get_facing())
				var tray := Vector2(rect.position.x + rect.size.x * (0.5 + 0.45 * facing), rect.position.y + rect.size.y * 0.50)
				c.draw_rect(Rect2(tray + Vector2(-s * 2.6, 0), Vector2(s * 5.2, s * 0.45)), Color(0.62, 0.46, 0.22))
				if _tray_full:
					_draw_mug(c, tray + Vector2(-s * 1.2, 0), s * 0.9)
					_draw_mug(c, tray + Vector2(s * 1.2, 0), s * 0.9)
			ROLE_BARD:
				if String(actor.act) == "play":
					_draw_lute(c, actor, t if moving else 0.0)
			ROLE_PATRON, ROLE_VISITOR:
				if String(actor.act) == "drink":
					var table := at(String(actor.cut))
					var lift := drink_lift(t, float(actor.phase)) if moving else 0.0
					var facing := float((actor.figure as WalkFigure).get_facing())
					var rest := Vector2(rect.position.x + rect.size.x * (0.5 + 0.55 * facing), table.y + unit * 0.004)
					var mouth := Vector2(rect.position.x + rect.size.x * (0.5 + 0.2 * facing), rect.position.y + rect.size.y * 0.16)
					_draw_mug(c, rest.lerp(mouth, lift), s)
		if _hovered == i:
			_draw_name(c, actor, rect)
	if _chat_mode:
		for i in _actors.size():
			if String(_actors[i].act) == "gone":
				continue
			var rect: Rect2 = _actors[i].rect
			var ring := Rect2(Vector2(rect.position.x + rect.size.x * 0.1, rect.end.y - unit * 0.012), Vector2(rect.size.x * 0.8, unit * 0.022))
			c.draw_arc(ring.get_center(), ring.size.x * 0.5, 0.0, TAU, 28, Color(0.93, 0.66, 0.32, 0.9 if _hovered == i else 0.45), 2.0)

func _draw_mug(c: Control, p: Vector2, s: float) -> void:
	c.draw_rect(Rect2(p + Vector2(-s, -s * 1.6), Vector2(s * 2.0, s * 1.6)), Color(0.55, 0.38, 0.2))
	c.draw_rect(Rect2(p + Vector2(-s, -s * 1.6), Vector2(s * 2.0, s * 1.6)), Color(0.05, 0.04, 0.04), false, 1.5)
	c.draw_rect(Rect2(p + Vector2(-s * 0.9, -s * 1.7), Vector2(s * 1.8, s * 0.4)), Color(0.95, 0.9, 0.75))
	c.draw_arc(p + Vector2(s * 1.1, -s * 0.8), s * 0.6, -PI * 0.5, PI * 0.5, 8, Color(0.05, 0.04, 0.04), 1.5)

## Lavta ozanın elinde: gövde arka elin (karın önü), sap ön elin içinden
## yukarı-ileri uzanır, burgu kutusu geriye kırılır. Yerleri figürün kendi
## duruşundan (FigureActions.pose) okunur: lavta havada değil, elde.
## Çalarken gövde hafifçe sallanır, notalar yükselir (glif değil, çizilmiş).
func _draw_lute(c: Control, actor: Dictionary, t: float) -> void:
	var figure: WalkFigure = actor.figure
	var clip: Control = actor.clip
	var facing := float(figure.get_facing())
	var ph := figure.person_height() * PERSON_SHARE
	var foot := clip.position + Vector2(figure.size.x * 0.5, figure.size.y)
	var joints := FigureActions.pose(BARD_CLIP, 0, Vector2.ZERO, 100.0, 1.0)
	var unit := ph / 100.0
	var back_hand: Vector2 = joints.get("hand_back", Vector2(18, -47))
	var front_hand: Vector2 = joints.get("hand_front", Vector2(25, -56))
	var strum := sin(t * 6.0) * 0.6
	var body := foot + Vector2((back_hand.x + 2.0) * facing, back_hand.y + 3.0 + strum) * unit
	var grip := foot + Vector2(front_hand.x * facing, front_hand.y) * unit
	var axis := (grip - body).normalized()
	var neck_end := grip + axis * 9.0 * unit
	var angle := axis.angle()
	# Gövde: neck tarafı dar, öbür ucu geniş armut.
	var pear := PackedVector2Array()
	for k in 28:
		var a := TAU * float(k) / 28.0
		var along := cos(a) * 9.0 * unit
		var across := sin(a) * 6.8 * unit * (1.0 - 0.35 * maxf(0.0, cos(a)))
		pear.append(body + Vector2(along, across).rotated(angle))
	var neck := PackedVector2Array([
		body + Vector2(5.0 * unit, -1.0 * unit).rotated(angle), neck_end + Vector2(0.0, -0.9 * unit).rotated(angle),
		neck_end + Vector2(0.0, 0.9 * unit).rotated(angle), body + Vector2(5.0 * unit, 1.0 * unit).rotated(angle),
	])
	c.draw_colored_polygon(neck, Color(0.24, 0.15, 0.07))
	# Burgu kutusu: sapın ucundan geriye kırık kısa bir parça.
	var peg_dir := axis.rotated(-1.1 * facing)
	c.draw_line(neck_end, neck_end + peg_dir * 3.6 * unit, Color(0.20, 0.12, 0.06), 1.7 * unit)
	c.draw_colored_polygon(pear, Color(0.56, 0.34, 0.15))
	pear.append(pear[0])
	c.draw_polyline(pear, Color(0.07, 0.05, 0.04), maxf(1.0, 0.5 * unit))
	c.draw_circle(body + Vector2(1.6 * unit, 0.0).rotated(angle), 1.5 * unit, Color(0.10, 0.06, 0.03))
	for s in [-0.5, 0.5]:
		c.draw_line(body + Vector2(-4.5 * unit, s * unit).rotated(angle), neck_end + Vector2(0.0, s * 0.6 * unit).rotated(angle), Color(0.85, 0.80, 0.68, 0.7), 1.0)
	if t > 0.0:
		for k in 3:
			var life := fposmod(t / NOTE_PERIOD * 0.5 + float(k) / 3.0, 1.0)
			var np := body + Vector2((6.0 + sin(life * 6.0 + float(k)) * 2.0) * facing, -18.0 - life * 30.0) * unit
			var alpha := (1.0 - life) * 0.85
			c.draw_circle(np, 1.2 * unit, Color(0.95, 0.88, 0.7, alpha))
			c.draw_line(np + Vector2(1.1 * unit, 0), np + Vector2(1.1 * unit, -4.6 * unit), Color(0.95, 0.88, 0.7, alpha), 1.5)

## İsim etiketi: rolü ve adı (referanstaki "Ozan" etiketi gibi).
func _draw_name(c: Control, actor: Dictionary, rect: Rect2) -> void:
	var character: CharacterData = actor.character
	var font := ThemeDB.fallback_font
	var text := "%s · %s" % [tr(String(ROLE_LABEL_KEYS.get(actor.role, "UI_TAVERN_ROLE_GUEST"))), character.character_name]
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
	var at_point := Vector2(rect.position.x + rect.size.x * 0.5 - width * 0.5, rect.position.y - 8.0)
	c.draw_rect(Rect2(at_point + Vector2(-6, -17), Vector2(width + 12, 22)), Color(0.04, 0.03, 0.03, 0.8))
	c.draw_string(font, at_point, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, ArtPalette.UI_TEXT)
