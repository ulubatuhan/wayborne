class_name PortraitCameo
extends Control

## Bir kişinin pirinç madalyon içindeki portresi (P1): çerçeve bir doku,
## içinde kişinin büstü (`BustPortrait`, Y-G04) - dünyada yürüyen figürün
## yakın planı, boy, ten, saç ve kıyafet dahil. Portre ayrı bir resim olsaydı
## karakter oluşturmada seçilen boy ve kıyafet burada görünmezdi (bkz. Art
## Rules: "what character creation chose has to be visible"). Eskiden ovalin
## içinde tam boy küçük bir figür duruyordu; yüz okunmuyordu. Çerçevenin içi
## opak (kâğıt), o yüzden büst çerçevenin üstünde ve oval bir maskenin
## (`clip_children`) içinde çiziliyor.

const FRAME_FILE: String = "p1_cameo.png"
## Oval iç alan, çerçeve dokusuna oranla (p1_cameo.png üstünde ölçüldü):
## üstteki halka ve kalın pirinç kenar dışarıda kalıyor.
const INNER: Rect2 = Rect2(0.2, 0.2, 0.6, 0.66)

var _frame: TextureRect
var _mask: Control
var _bust: BustPortrait

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = WaybookTheme.picture(FRAME_FILE, 10.0)
	_frame.custom_minimum_size = Vector2.ZERO
	_frame.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_frame)
	_mask = Control.new()
	_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_mask.draw.connect(_draw_mask)
	add_child(_mask)
	_bust = BustPortrait.new()
	_bust.set_bare(true)
	_mask.add_child(_bust)
	resized.connect(_layout)

## `height` cameonun toplam yüksekliği; genişlik dokunun oranından.
func setup(character: CharacterData, height: float) -> PortraitCameo:
	var tex_size := WaybookTheme.texture(FRAME_FILE).get_size()
	custom_minimum_size = Vector2(height * tex_size.x / tex_size.y, height)
	size = custom_minimum_size
	_layout()
	_bust.show_character(character)
	_bust.visible = character != null
	return self

func _layout() -> void:
	_frame.position = Vector2.ZERO
	_frame.size = size
	var inner := Rect2(INNER.position * size, INNER.size * size)
	_mask.position = inner.position
	_mask.size = inner.size
	_mask.queue_redraw()
	_bust.position = Vector2.ZERO
	_bust.size = inner.size

func _draw_mask() -> void:
	var c := _mask.size * 0.5
	var points := PackedVector2Array()
	for i in 48:
		var a := TAU * float(i) / 48.0
		points.append(c + Vector2(cos(a) * c.x, sin(a) * c.y))
	_mask.draw_colored_polygon(points, Color.WHITE)
