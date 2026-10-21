class_name TownsfolkLayer
extends Control

## Şehir ekranının halkı (görev Y-G10T, taslaklar y_g10t_sehir_halk_*): kervan
## şehre girmiyor, ama şehir boş da değil. Sahne elle kurulu küçük anlar,
## kalabalık değil: gece kapıda feneriyle bir bekçi, konuşan iki kişi, eve dönen
## bir yolcu; akşam ve gündüz bunlara tezgâhını toplayan satıcı, sandıkta oturan
## yaşlı, konuşan bir çift ve bir yolcu daha. Konumlar kasaba resminin payı
## (resimler aynı kamerayla render edildi, meydan hep alt şeritte).
##
## Kullanıcı notu (taslak turu): "insanların ışığı ortamdan aykırı" - her figür
## durduğu yerin ışığını alır (resmin o bölgesinin ortalama rengi), fenerin
## yanındaki sıcak bir yan ışık. Kişiler tohumdan: şehir ve gün aynıysa aynı
## insanlar.

const VILLAGER: String = "villager"
const SEATED_CLIP: String = "sit_box"
const CRATE_ART: String = "res://data/assets/props/crate/body.png"
const FIRELIT_SHADER: Shader = preload("res://scripts/ui/grim/firelit.gdshader")
## Figür kutusunun ne kadarını kişi dolduruyor (WalkFigure, FigurePreview ile aynı).
const PERSON_SHARE: float = 0.86
## Yürüyenin hızı: saniyede boyunun bu payı kadar (ağır, akşam yürüyüşü).
const WALK_BODIES_PER_SECOND: float = 0.45
const WALK_SPAN: float = 0.07
const ROLE_WATCH: String = "watch"
const ROLE_SEATED: String = "seated"
const ROLE_WALK: String = "walk"
## Taslak şeritsiz bir ekrandı: meydanın önü (y 0.865..0.995) oyunda alt şeridin
## (CityFront.STRIP_HEIGHT) altında kalıyor. Ayaklar şeridin üstüne sıkıştırılır;
## boy taslaktaki derinlikten gelir, kimse küçülmez.
const DRAFT_GROUND: Vector2 = Vector2(0.865, 0.995)
const GAME_GROUND: Vector2 = Vector2(0.835, 0.9)

## (resim x, resim y, kadın mı, rol). Taslağın sahneleri.
const NIGHT: Array = [
	[0.470, 0.865, false, ROLE_WATCH],
	[0.215, 0.950, false, ""],
	[0.250, 0.950, true, ""],
	[0.705, 0.975, false, ROLE_WALK],
]
const EVENING_EXTRA: Array = [
	[0.830, 0.940, true, "vendor"],
	[0.120, 0.985, false, ROLE_SEATED],
	[0.520, 0.870, true, ""],
	[0.548, 0.870, false, ""],
	[0.365, 0.995, true, ROLE_WALK],
]
const MALE_OUTFITS: Array = [
	["peasant_shirt", "peasant_pants", "peasant_shoes", "", ""],
	["linen_tunic", "wool_pants", "short_boots", "", "felt_cap"],
	["laced_shirt", "cloth_trousers", "leather_boots", "wool_coat", ""],
]
const FEMALE_OUTFITS: Array = [
	["peasant_blouse", "long_skirt", "peasant_shoes", "", ""],
	["peasant_blouse", "tiered_skirt", "womens_ankle_boots", "", "head_veil"],
	["peasant_blouse", "pinafore_dress", "felt_shoes", "", ""],
]

var _bg: TextureRect
var _sample: Image
var _people: Array[Dictionary] = []
var _lantern: bool = true

## `night`: yalnızca gece sahnesi; değilse akşam/gündüz sahnesi. `lantern`:
## bekçinin feneri yanıyor mu (akşam ve gece).
func setup(bg: TextureRect, night: bool, seed_text: String, lantern: bool = true) -> TownsfolkLayer:
	_lantern = lantern
	_bg = bg
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bg.texture != null:
		_sample = bg.texture.get_image()
		if _sample != null:
			if _sample.is_compressed():
				_sample.decompress()
			_sample.resize(192, 108, Image.INTERPOLATE_BILINEAR)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("townsfolk|" + seed_text)
	var scene: Array = NIGHT.duplicate()
	if not night:
		scene.append_array(EVENING_EXTRA)
	scene.sort_custom(func(a, b): return float(a[1]) < float(b[1]))
	for spot in scene:
		_add_person(spot, rng)
	resized.connect(_place)
	_place.call_deferred()
	return self

## Resmin o noktasının ortam ışığı (taslaktaki `lit()`): bölgenin ortalaması,
## en parlak kanala göre yeniden ölçülmüş - renk sahnenin, parlaklık kısık.
func ambient_at(share: Vector2) -> Color:
	if _sample == null:
		return Color(0.6, 0.58, 0.55)
	var sum := Vector3.ZERO
	var count := 0
	var cx := int(share.x * _sample.get_width())
	var cy := int(share.y * _sample.get_height())
	for y in range(cy - 14, cy + 3):
		for x in range(cx - 6, cx + 7):
			if x < 0 or y < 0 or x >= _sample.get_width() or y >= _sample.get_height():
				continue
			var c := _sample.get_pixel(x, y)
			sum += Vector3(c.r, c.g, c.b)
			count += 1
	if count == 0:
		return Color(0.6, 0.58, 0.55)
	var mean := sum / float(count)
	var peak := maxf(0.001, maxf(mean.x, maxf(mean.y, mean.z)))
	var level := minf(1.0, peak * 2.0)
	var light := mean / peak * level
	light = Vector3(clampf(light.x, 0.06, 1.0), clampf(light.y, 0.06, 1.0), clampf(light.z, 0.06, 1.0)) * 0.7
	return Color(light.x, light.y, light.z)

func _add_person(spot: Array, rng: RandomNumberGenerator) -> void:
	var female := bool(spot[2])
	var role := String(spot[3])
	var gender := CharacterData.GENDER_FEMALE if female else CharacterData.GENDER_MALE
	var weight := rng.randi_range(0, 2)
	var figure := WalkFigure.new()
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outfits: Array = FEMALE_OUTFITS if female else MALE_OUTFITS
	var picked: Array = outfits[rng.randi_range(0, outfits.size() - 1)]
	var outfit := {}
	for piece_id in picked:
		var piece := OutfitCatalog.get_piece(String(piece_id))
		if piece != null and piece.fits(gender):
			outfit[piece.slot] = piece.piece_id
	figure.set_kind(WalkFigure.KIND_PERSON, VILLAGER, CharacterData.height_scale_for(rng.randi_range(158, 184)),
		CharacterData.get_skin_tone_color(rng.randi_range(0, 3)), false, outfit, Wardrobe.body_id_for(gender, weight))
	figure.set_standing()
	var at := Vector2(float(spot[0]), float(spot[1]))
	# Konuşan ikililer birbirine dönük: soldaki sağa bakar.
	figure.set_facing(1.0 if rng.randf() < 0.5 else -1.0)
	var person := {"figure": figure, "home": at, "pos": at, "role": role, "dir": -1.0, "crate": null, "glow": null}
	if role == ROLE_SEATED:
		figure.set_action(SEATED_CLIP)
		var crate := TextureRect.new()
		crate.texture = TextureLoader.load_any(CRATE_ART)
		crate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crate.stretch_mode = TextureRect.STRETCH_SCALE
		crate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crate.modulate = ambient_at(at)
		add_child(crate)
		person.crate = crate
	if role == ROLE_WATCH and _lantern:
		var lit := ShaderMaterial.new()
		lit.shader = FIRELIT_SHADER
		lit.set_shader_parameter("strength", 0.7)
		lit.set_shader_parameter("ambient", Vector3(ambient_at(at).r, ambient_at(at).g, ambient_at(at).b))
		figure.material = lit
		var glow := LanternGlow.new().setup(70.0, 0.55, rng.randf() * 10.0)
		add_child(glow)
		person.glow = glow
	else:
		figure.set_tint(ambient_at(at))
	add_child(figure)
	_people.append(person)
	_pair_facing()

## İkili duranlar birbirine baksın (aynı derinlikte, yan yana duranlar).
func _pair_facing() -> void:
	for a in _people:
		for b in _people:
			if a == b or String(a.role) != "" or String(b.role) != "":
				continue
			var pa: Vector2 = a.home
			var pb: Vector2 = b.home
			if absf(pa.y - pb.y) < 0.01 and absf(pa.x - pb.x) < 0.06:
				(a.figure as WalkFigure).set_facing(1.0 if pa.x < pb.x else -1.0)

## Kasaba resmi ekranı örtecek biçimde ölçekli (KEEP_ASPECT_COVERED).
func image_to_screen(share: Vector2) -> Vector2:
	var img := Vector2(_bg.texture.get_size()) if _bg != null and _bg.texture != null else Vector2(1920, 1080)
	var view := size
	var k := maxf(view.x / img.x, view.y / img.y)
	return (view - img * k) * 0.5 + share * img * k

func _image_height() -> float:
	var img := Vector2(_bg.texture.get_size()) if _bg != null and _bg.texture != null else Vector2(1920, 1080)
	return img.y * maxf(size.x / img.x, size.y / img.y)

## Taslağın zemin satırından oyunun zemin satırına (bkz. DRAFT_GROUND).
static func ground_y(draft_y: float) -> float:
	var u := clampf((draft_y - DRAFT_GROUND.x) / (DRAFT_GROUND.y - DRAFT_GROUND.x), 0.0, 1.0)
	return lerpf(GAME_GROUND.x, GAME_GROUND.y, u)

## Derinlikte boy (resim yüksekliğinin payı): taslaktaki ölçek, meydanın
## arkasında küçük, önünde büyük.
static func person_share_at(y: float) -> float:
	var depth := clampf((y - 0.84) / 0.18, 0.0, 1.0)
	return 0.12 + depth * 0.07

func _place() -> void:
	if size.y <= 0.0:
		return
	var image_h := _image_height()
	for person in _people:
		var pos: Vector2 = person.pos
		var foot := image_to_screen(Vector2(pos.x, ground_y(pos.y)))
		var h := person_share_at(pos.y) * image_h / PERSON_SHARE
		var figure: WalkFigure = person.figure
		figure.size = Vector2(h * 0.9, h)
		figure.position = foot - Vector2(h * 0.45, h)
		if person.crate != null:
			var crate: TextureRect = person.crate
			var ch := h * PERSON_SHARE * 0.3
			crate.size = Vector2(ch * 1.1, ch)
			crate.position = Vector2(foot.x - h * 0.1 - ch * 0.55, foot.y - ch + 4.0)
		if person.glow != null:
			var glow: LanternGlow = person.glow
			var facing := 1.0 if figure.get_facing() >= 0.0 else -1.0
			var lamp := foot + Vector2(facing * h * 0.2, -h * PERSON_SHARE * 0.5)
			glow.position = lamp - glow.size * 0.5
			var lit: ShaderMaterial = figure.material
			lit.set_shader_parameter("fire", lamp)
			lit.set_shader_parameter("radius", h * 0.6)

func _process(delta: float) -> void:
	var still := NodeUtil.reduce_motion(self)
	var image_h := _image_height()
	for person in _people:
		if String(person.role) != ROLE_WALK:
			continue
		var figure: WalkFigure = person.figure
		if still or image_h <= 0.0:
			figure.advance(delta, 0.0)
			continue
		# Bir yolcu meydanın kenarında gidip geliyor: aynı adımda, ayak kaymadan.
		var home: Vector2 = person.home
		var pos: Vector2 = person.pos
		var speed_px := person_share_at(pos.y) * image_h * WALK_BODIES_PER_SECOND
		var img_w := image_h * 16.0 / 9.0
		pos.x += float(person.dir) * speed_px * delta / img_w
		if absf(pos.x - home.x) > WALK_SPAN:
			person.dir = -float(person.dir)
			pos.x = home.x + signf(pos.x - home.x) * WALK_SPAN
		person.pos = pos
		figure.advance_ground(delta, float(person.dir) * speed_px)
	_place()
