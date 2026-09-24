class_name PortraitCameo
extends Control

## Bir kişinin pirinç madalyon içindeki portresi (P1): çerçeve bir doku,
## içindeki figür ise dünyada yürüyen `WalkFigure`'ın ta kendisi - boy, ten
## rengi, sınıf paleti ve kıyafet dahil. Portre ayrı bir resim olsaydı
## karakter oluşturmada seçilen boy ve kıyafet burada görünmezdi (bkz. Art
## Rules: "what character creation chose has to be visible").

const FRAME_FILE: String = "p1_cameo.png"
## Oval iç alan, çerçeve dokusuna oranla (p1_cameo.png üstünde ölçüldü):
## üstteki halka ve kalın pirinç kenar dışarıda kalıyor.
const INNER: Rect2 = Rect2(0.2, 0.2, 0.6, 0.66)

var _frame: TextureRect
var _figure: WalkFigure

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = WaybookTheme.picture(FRAME_FILE, 10.0)
	_frame.custom_minimum_size = Vector2.ZERO
	_frame.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_frame)
	_figure = WalkFigure.new()
	add_child(_figure)
	resized.connect(_layout)

## `height` cameonun toplam yüksekliği; genişlik dokunun oranından.
func setup(character: CharacterData, height: float) -> PortraitCameo:
	var tex_size := WaybookTheme.texture(FRAME_FILE).get_size()
	custom_minimum_size = Vector2(height * tex_size.x / tex_size.y, height)
	size = custom_minimum_size
	if character != null:
		_figure.set_kind(
			WalkFigure.KIND_PERSON, character.class_id,
			clampf(float(character.height_cm) / float(CharacterData.DEFAULT_HEIGHT_CM), 0.86, 1.14),
			CharacterData.get_skin_tone_color(character.skin_tone), false, character.outfit
		)
	_figure.visible = character != null
	_layout()
	return self

func _layout() -> void:
	_frame.position = Vector2.ZERO
	_frame.size = size
	var inner := Rect2(INNER.position * size, INNER.size * size)
	# Figür oval alanın alt kenarına basıyor; baş ile omuz ovalin ortasında.
	_figure.size = Vector2(inner.size.x * 0.8, inner.size.y * 0.95)
	_figure.position = Vector2(inner.position.x + inner.size.x * 0.1, inner.end.y - _figure.size.y)
