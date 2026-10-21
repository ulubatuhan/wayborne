class_name FigurePreview
extends Control

## Bir kişiyi boydan, duran pozda gösteren pencere: karakter oluşturmada
## kıyafet seçerken ve karakter ekranında kuşam değiştirirken. İçindeki figür
## yolda yürüyen `WalkFigure`'ın ta kendisi (aynı iskelet, aynı sprite
## katmanları) - önizleme ayrı bir çizim olsaydı ekranda seçilen, yolda
## görünenden sessizce sapardı (Art Rules: "what character creation chose has
## to be visible").

var _figure: WalkFigure

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_figure = WalkFigure.new()
	# Önizleme figürü büyük çiziyor: duruş karesinin yakın plan kümesi (Y-G12).
	_figure.hd = true
	add_child(_figure)
	resized.connect(_layout)

## `archetype` boşsa kişinin sınıfı (silahı sırtında); kadroda olmayanlar için
## "villager" (silahsız) verilir.
func show_character(character: CharacterData, archetype: String = "") -> void:
	if character == null:
		_figure.visible = false
		return
	show_look(
		character.class_id if archetype.is_empty() else archetype,
		character.get_height_scale(),
		CharacterData.get_skin_tone_color(character.skin_tone),
		character.get_appearance_outfit(), Wardrobe.loadout_of(character.outfit, character.equipped),
		character.get_body_variant_id()
	)

func show_look(
	archetype_id: String, height_scale: float, skin: Color, outfit: Dictionary,
	loadout: PackedStringArray, body_variant: String = ""
) -> void:
	_figure.visible = true
	_figure.set_kind(WalkFigure.KIND_PERSON, archetype_id, height_scale, skin, false, outfit, body_variant)
	_figure.set_loadout(loadout)
	_figure.set_standing()
	_figure.set_facing(1.0)
	_layout()

## Ağaçta olmayan bir önizlemenin boyutu `resized` göndermez; yerleştiren elle çağırır.
func refit() -> void:
	_layout()

func set_action(clip: String) -> void:
	_figure.set_action(clip)

func set_facing(direction: float) -> void:
	_figure.set_facing(direction)

func set_tint(tint: Color) -> void:
	_figure.set_tint(tint)

## Figür kareleri 320 px tuvalde render ediliyor; duruşun yakın plan kümesi
## (Y-G12) 3 katı. Önizleme yakın plan kümesini çiziyor; yine de figür bu boyu
## aşmaz (9.6 denetimi: 620 px'te normal kareler lekeye dönmüştü; yakın plan
## kümesi olmayan bir giysi normal kareye düşer).
const MAX_FIGURE_HEIGHT: float = 560.0
## 0 = sınır yok: konuşma penceresinin portresi figürü bilerek büyütüp belden
## yukarısını kırpıyor (DialoguePanel).
var max_figure_height: float = MAX_FIGURE_HEIGHT

## Figür pencerenin alt kenarına basıyor; boyu pencerenin yüksekliğinin bir
## payı, en uzun boy bile şapkasıyla sığsın diye.
func _layout() -> void:
	var height := size.y * 0.86
	if max_figure_height > 0.0:
		height = minf(height, max_figure_height)
	_figure.size = Vector2(size.x, height)
	_figure.position = Vector2(0.0, size.y - height)
