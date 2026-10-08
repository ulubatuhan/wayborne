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
	add_child(_figure)
	resized.connect(_layout)

func show_character(character: CharacterData) -> void:
	if character == null:
		_figure.visible = false
		return
	show_look(
		character.class_id,
		character.get_height_scale(),
		CharacterData.get_skin_tone_color(character.skin_tone),
		character.outfit, Wardrobe.loadout_of(character.outfit, character.equipped),
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

## Figür pencerenin alt kenarına basıyor; boyu pencerenin yüksekliğinin bir
## payı, en uzun boy bile şapkasıyla sığsın diye.
func _layout() -> void:
	_figure.size = Vector2(size.x, size.y * 0.86)
	_figure.position = Vector2(0.0, size.y - _figure.size.y)
