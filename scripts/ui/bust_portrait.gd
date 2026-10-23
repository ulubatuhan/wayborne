class_name BustPortrait
extends Control

## Büst portresi (görev Y-G04): olay kartı illüstrasyonlarının dilinde, baş ve
## omuzlar. Resim ayrı bir boyama değil, kişinin dünyada yürüyen figürü
## (`WalkFigure`, duruşun yakın plan kümesi): ten, boy, saç, kıyafet ve zırh
## seçimi portrede de görünür (Art Rules: "what character creation chose has to
## be visible"). Üstüne iki gölgelendirici: figüre mürekkep tarama
## (bust_ink.gdshader), arkaya alacakaranlık yıkaması (bust_wash.gdshader).
##
## Çerçeveleme figürün kendi eklemlerinden: ilk çizimden sonra baş tepesi ve
## omuz okunur, figür baş-omuz aralığı portrenin `BUST_SPAN` payını tutacak
## kadar büyütülüp başı tepeye oturacak şekilde kaydırılır. Sabit oran boy ve
## şapka farkında başı kesiyordu.

const INK_SHADER: Shader = preload("res://scripts/ui/grim/bust_ink.gdshader")
const WASH_SHADER: Shader = preload("res://scripts/ui/grim/bust_wash.gdshader")
## Baş tepesinden omza kadar olan aralık portre yüksekliğinin bu payı.
const BUST_SPAN: float = 0.54
## Baş tepesinin portrenin üstünden payı (şapka ve saç için boşluk).
const TOP_MARGIN: float = 0.10
const FRAME_INK: Color = Color(0.07, 0.06, 0.05)
const FRAME_RULE: Color = Color(0.78, 0.66, 0.44, 0.55)

var _wash: ColorRect
var _figure: WalkFigure
var _border: Control
var _fitted: bool = false
var _fit_pass: int = 0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_wash = ColorRect.new()
	_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wash_mat := ShaderMaterial.new()
	wash_mat.shader = WASH_SHADER
	_wash.material = wash_mat
	add_child(_wash)
	_figure = WalkFigure.new()
	_figure.hd = true
	var ink := ShaderMaterial.new()
	ink.shader = INK_SHADER
	_figure.material = ink
	add_child(_figure)
	_border = Control.new()
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_border.draw.connect(_draw_border)
	add_child(_border)
	resized.connect(_relayout)

## Bir kişi; `archetype` boşsa sınıfı (silah sırtta görünmesin diye
## portrede "villager" yeterli, silah çerçeveye girmiyor).
func show_character(character: CharacterData) -> BustPortrait:
	if character == null:
		_figure.visible = false
		return self
	return show_look(character.get_height_scale(), CharacterData.get_skin_tone_color(character.skin_tone),
		character.get_appearance_outfit(), character.get_body_variant_id(), hash(character.character_name))

## Defterdeki bir ölünün saklanan görünüşü (CaravanLedger: `look`).
func show_snapshot(look: Dictionary) -> BustPortrait:
	if look.is_empty():
		_figure.visible = false
		return self
	var outfit: Dictionary = (look.get("outfit", {}) as Dictionary).duplicate()
	if look.has("hair_color") and outfit.has(OutfitCatalog.SLOT_HAIR):
		outfit[OutfitCatalog.HAIR_TINT_KEY] = OutfitCatalog.get_hair_color(int(look["hair_color"]))
	return show_look(CharacterData.height_scale_for(int(look.get("height_cm", CharacterData.DEFAULT_HEIGHT_CM))),
		CharacterData.get_skin_tone_color(int(look.get("skin_tone", 1))), outfit, str(look.get("body", "")),
		hash(str(look.get("name", ""))))

func show_look(height_scale: float, skin: Color, outfit: Dictionary, body_variant: String, seed_value: int = 0) -> BustPortrait:
	_figure.visible = true
	_figure.set_kind(WalkFigure.KIND_PERSON, "villager", height_scale, skin, false, outfit, body_variant)
	_figure.set_standing()
	_figure.set_facing(1.0)
	(_wash.material as ShaderMaterial).set_shader_parameter("seed", float(seed_value % 997))
	(_wash.material as ShaderMaterial).set_shader_parameter("warm_side", float(seed_value % 2))
	_fitted = false
	_fit_pass = 0
	_relayout()
	return self

## Çerçevesiz: başka bir çerçevenin (madalyon) içinde duran portre.
func set_bare(on: bool) -> void:
	_border.visible = not on

## Ölü biri: portre soluk ve gri (defterin üstü çizili satırı gibi).
func set_struck(on: bool) -> void:
	modulate = Color(0.78, 0.76, 0.74) if on else Color.WHITE
	(_figure.material as ShaderMaterial).set_shader_parameter("wash", 0.18 if on else 0.62)

func _relayout() -> void:
	_wash.position = Vector2.ZERO
	_wash.size = size
	_border.position = Vector2.ZERO
	_border.size = size
	_border.queue_redraw()
	if not _fitted:
		# İlk tahmin: baş-omuz bir figürün boyunun ~%17'si.
		var h := size.y * BUST_SPAN / 0.17
		_figure.size = Vector2(size.x * 2.0, h)
		_figure.position = Vector2(-size.x * 0.5, size.y * TOP_MARGIN - h * 0.03)
		set_process(true)

## Figür bir kez çizildikten sonra eklemlerinden çerçeve: iki geçiş (ölç,
## büyüt; yeniden ölç, kaydır).
func _process(_delta: float) -> void:
	if _fitted or not _figure.visible:
		set_process(false)
		return
	var joints := _figure.get_body_anchors()
	if not joints.has("head_top_hint") or not joints.has("front_shoulder"):
		return
	var top: Vector2 = joints["head_top_hint"]
	var shoulder: Vector2 = joints["front_shoulder"]
	var neck: Vector2 = joints.get("neck", shoulder)
	var span := maxf(shoulder.y - top.y, 1.0)
	if _fit_pass == 0:
		var r := size.y * BUST_SPAN / span
		var old := _figure.size
		_figure.size = old * r
		_fit_pass = 1
		_figure.queue_redraw()
		return
	_figure.position += Vector2(size.x * 0.5 - (_figure.position.x + neck.x),
		size.y * TOP_MARGIN - (_figure.position.y + top.y))
	_fitted = true
	set_process(false)

func _draw_border() -> void:
	var r := Rect2(Vector2.ZERO, _border.size)
	_border.draw_rect(r.grow(-1.0), FRAME_INK, false, 2.0)
	_border.draw_rect(r.grow(-4.0), FRAME_RULE, false, 1.0)
